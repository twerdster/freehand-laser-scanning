"""Compare simulator-produced PNG/pose computation with the desktop adapter."""
import argparse
import hashlib
import json
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parent


def compare(native, desktop):
    if len(native['frames']) != len(desktop['frames']):
        raise ValueError('Frame counts differ')
    maxima = {'ridge_px': 0., 'point_m': 0.}
    counts = {'frames': 0, 'pixels': 0, 'points': 0}
    for actual, expected in zip(native['frames'], desktop['frames']):
        if actual['id'] != expected['id']:
            raise ValueError('Frame identities/order differ')
        for field, label, width, tolerance in (('pixels', 'ridge_px', 2, 2e-5), ('points', 'point_m', 3, 1e-6)):
            a, e = np.asarray(actual[field]), np.asarray(expected[field])
            if a.shape != e.shape or a.ndim != 2 or a.shape[1] != width or not np.isfinite(a).all():
                raise ValueError('Invalid/mismatched native '+field)
            delta = float(np.max(np.abs(a-e), initial=0))
            maxima[label] = max(maxima[label], delta)
            if delta > tolerance:
                raise ValueError(f'{field} difference exceeds {tolerance}: {delta}')
            counts[field] += len(a)
        counts['frames'] += 1
    a, e = np.asarray(native['calibration_plane']), np.asarray(desktop['calibration_plane'])
    if a.shape != (4,) or not np.isfinite(a).all():
        raise ValueError('Invalid native plane')
    plane_delta = float(np.max(np.abs(a-e)))
    if plane_delta > 1e-7:
        raise ValueError('Calibration planes differ')
    return {'status': 'passed', **counts, 'maximum_ridge_coordinate_difference_px': maxima['ridge_px'],
            'maximum_world_coordinate_difference_m': maxima['point_m'], 'maximum_plane_coefficient_difference': plane_delta,
            'tolerances': {'ridge_px': 2e-5, 'world_coordinate_m': 1e-6, 'plane_coefficient': 1e-7}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('native', type=Path, help='Documents/native-validation.json exported by the simulator app')
    parser.add_argument('--desktop', type=Path, default=ROOT/'artifacts/desktop-points.json')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    report = compare(json.loads(args.native.read_text()), json.loads(args.desktop.read_text()))
    report.update({'native_output_sha256': hashlib.sha256(args.native.read_bytes()).hexdigest(),
                   'desktop_output_sha256': hashlib.sha256(args.desktop.read_bytes()).hexdigest(),
                   'scope': 'Same synthetic PNGs/poses through independently executed native app and desktop adapters; not real sensor validation'})
    text = json.dumps(report, indent=2)+'\n'
    if args.output:
        args.output.write_text(text)
    print(text, end='')

if __name__ == '__main__': main()
