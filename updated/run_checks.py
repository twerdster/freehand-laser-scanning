"""Meaningful numerical, native and sanitizer checks; scratch remains outside Git."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import struct
import subprocess
import sys
import tempfile
import unittest

import numpy as np
import scipy
import PIL
from PIL import Image
from .run_simulation import evaluate
from .native_bridge import Native
from . import laser

ROOT = Path(__file__).resolve().parent

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT/'validation/checks.json')
    parser.add_argument('--python-only', action='store_true', help='Skip the macOS Accelerate/compiler/sanitizer checks')
    args = parser.parse_args()
    if args.python_only:
        os.environ.pop('FREEHAND_NATIVE_LIB', None)
    commands = []
    with tempfile.TemporaryDirectory(prefix='freehand-checks-') as scratch:
        scratch = Path(scratch)
        if not args.python_only:
            if sys.platform != 'darwin':
                raise SystemExit('Native Accelerate tests require macOS; use --python-only elsewhere')
            command = ['clang', '-O2', '-dynamiclib', '-framework', 'Accelerate', str(ROOT/'native/laser_core.c'), '-o', str(scratch/'liblaser.dylib')]
            subprocess.run(command, check=True, capture_output=True, text=True)
            os.environ['FREEHAND_NATIVE_LIB'] = str(scratch/'liblaser.dylib')
            commands.append('clang -O2 -dynamiclib -framework Accelerate updated/native/laser_core.c -o <scratch>/liblaser.dylib')
        suite = unittest.defaultTestLoader.discover(str(ROOT/'tests'))
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        sanitizer = {'status': 'not requested'}
        parity = {'status': 'not requested'}
        if not args.python_only:
            native = Native(os.environ['FREEHAND_NATIVE_LIB'])
            spec = json.loads((ROOT/'fixtures/sequence.json').read_text())
            response_delta, pixel_delta = 0., 0.
            for frame in spec['calibration']+spec['scans']:
                image = np.asarray(Image.open(ROOT/'fixtures'/frame['file']))
                pixels, response = laser.extract_line(image, spec['threshold'])
                response_delta = max(response_delta, float(np.max(np.abs(native.response(image)-response))))
                native_pixels = native.extract(image, spec['threshold'])
                pixel_delta = max(pixel_delta, float(np.max(np.abs(native_pixels-pixels))))
            parity = {'frames': len(spec['calibration'])+len(spec['scans']), 'maximum_response_absolute_difference': response_delta,
                      'maximum_ridge_coordinate_difference_px': pixel_delta,
                      'point_comparison_test_tolerance_m': 1e-6, 'status': 'passed' if result.wasSuccessful() else 'failed'}
            command = ['clang', '-g', '-O1', '-fsanitize=address,undefined', '-fno-omit-frame-pointer', '-framework', 'Accelerate', str(ROOT/'tests/native_sanitizer.c'), str(ROOT/'native/laser_core.c'), '-o', str(scratch/'native-sanitizer')]
            subprocess.run(command, check=True, capture_output=True, text=True)
            spec = json.loads((ROOT/'fixtures/sequence.json').read_text())
            with (scratch/'fixtures.bin').open('wb') as stream:
                stream.write(struct.pack('=4I', spec['width'], spec['height'], len(spec['calibration'])+len(spec['scans']), len(spec['calibration'])))
                stream.write(np.array(spec['intrinsics'], dtype=np.float64).tobytes())
                stream.write(np.array(spec['calibration_board_world'], dtype=np.float64).tobytes())
                for f in spec['calibration']+spec['scans']:
                    stream.write(np.array(f['camera_to_world'], dtype=np.float64).tobytes())
                    stream.write(np.asarray(Image.open(ROOT/'fixtures'/f['file']), dtype=np.float32).tobytes())
            process = subprocess.run([str(scratch/'native-sanitizer'), str(scratch/'fixtures.bin')], capture_output=True, text=True, check=True)
            if process.stderr.strip():
                raise RuntimeError('Sanitizer produced unexpected diagnostics: '+process.stderr)
            sanitizer = {**json.loads(process.stdout), 'instrumentation': 'clang AddressSanitizer + UndefinedBehaviorSanitizer', 'diagnostics': 'none'}
            commands.append('clang -g -O1 -fsanitize=address,undefined -fno-omit-frame-pointer -framework Accelerate updated/tests/native_sanitizer.c updated/native/laser_core.c -o <scratch>/native-sanitizer')
        report, _, _, _, _ = evaluate(json.loads((ROOT/'fixtures/sequence.json').read_text()), ROOT/'fixtures')
        stored = json.loads((ROOT/'artifacts/metrics.json').read_text())
        artifact_delta = max(abs(stored['scenes'][name]['surface_rmse_mm']-report['scenes'][name]['surface_rmse_mm']) for name in report['scenes'])
        def compare(a, b):
            if isinstance(a, dict):
                if a.keys() != b.keys(): raise AssertionError('Artifact schema mismatch')
                return max(compare(a[k], b[k]) for k in a)
            if isinstance(a, list):
                if len(a) != len(b): raise AssertionError('Artifact list mismatch')
                return max((compare(x, y) for x, y in zip(a, b)), default=0)
            if isinstance(a, (int, float)) and not isinstance(a, bool): return abs(a-b)
            if a != b: raise AssertionError('Artifact field mismatch')
            return 0
        all_metrics_delta = compare(stored, report)
        hashes = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(ROOT.rglob('*')) if p.is_file() and p.suffix in ('.py', '.c', '.h', '.swift', '.pbxproj') and '__pycache__' not in p.parts}
        fixture_hashes = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((ROOT/'fixtures').iterdir()) if p.is_file()}
        evidence = {'schema': 1, 'scope': 'Synthetic software checks; no real scanner or paper benchmark',
                    'environment': {'python': platform.python_version(), 'numpy': np.__version__, 'scipy': scipy.__version__, 'pillow': PIL.__version__, 'platform': sys.platform, 'architecture': platform.machine()},
                    'tests_run': result.testsRun, 'failures': len(result.failures), 'errors': len(result.errors), 'skipped': len(result.skipped),
                    'sanitizer': sanitizer, 'native_frame_parity': parity, 'native_build_commands': commands,
                    'fresh_vs_stored_scene_rmse_max_delta_mm': artifact_delta, 'fresh_vs_stored_all_numeric_metrics_max_delta': all_metrics_delta,
                    'tested_source_sha256': hashes, 'tested_fixture_sha256': fixture_hashes}
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(evidence, indent=2)+'\n')
        if not result.wasSuccessful() or all_metrics_delta > 1e-8:
            raise SystemExit(1)

if __name__ == '__main__': main()
