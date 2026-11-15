"""Check the published point package by reprocessing PNGs, not loading mesh truth.

With --cache, replays all360 generated views and checks every recorded PNG hash.
The default public subset replays24 scans plus all8 calibration frames.
"""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import numpy as np
from PIL import Image
import PIL
import scipy

from updated import laser

ROOT = Path(__file__).resolve().parent


def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()


def run(folder, package):
    config = json.loads((folder/'configuration.json').read_text())
    calibration = json.loads((folder/'calibration.json').read_text())
    metrics = json.loads((folder/'metrics.json').read_text())
    data = dict(np.load(folder/'reconstruction.npz', allow_pickle=False))
    K = np.array(config['intrinsics'])
    checks = {}
    if package:
        manifest = json.loads((folder/'manifest.json').read_text())
        for name, expected in manifest['files'].items():
            assert sha(folder/name) == expected['sha256'], name
            assert (folder/name).stat().st_size == expected['bytes'], name
        checks['public_package_hashes_and_sizes'] = True
    board_points = []
    for record in calibration['frames']:
        path = folder/record['file']
        assert sha(path) == record['sha256']
        uv, _ = laser.extract_line(np.asarray(Image.open(path)))
        xyz, _ = laser.calibration_points(uv, K, record['camera_to_world'], calibration['board_world'])
        assert len(xyz) == record['board_points']
        board_points.extend(xyz)
    plane = laser.fit_plane(board_points)
    assert np.array_equal(plane, data['fitted_plane'])
    assert np.array_equal(plane, np.array(calibration['metrics']['fitted_plane_camera']))
    checks['eight_png_calibration_reproduces_fitted_plane_exactly'] = True
    all_xyz, all_uv, views = data['xyz'], data['uv'], data['view_index']
    assert all_xyz.shape == (metrics['points'], 3) and all_uv.shape == (len(all_xyz), 2)
    assert len(all_xyz) == 36560 and metrics['frames'] == 360
    assert np.isfinite(all_xyz).all() and np.isfinite(all_uv).all()
    assert data['camera_to_world'].shape == (360, 4, 4)
    assert np.all((all_uv[:, 0]>=5)&(all_uv[:, 0]<315)&(all_uv[:, 1]>=5)&(all_uv[:, 1]<235))
    checks['all_36560_points_finite_and_uv_inside_filter_border'] = True
    assert sha(folder/'reconstruction.npz') == metrics['reconstruction_npz_sha256']
    count, uv_error, xyz_error = 0, 0., 0.
    for record in metrics['frames_detail']:
        index = record['index']; mask = views == index
        assert record['points'] == int(mask.sum())
        pose = np.array(record['camera_to_world'])
        assert np.array_equal(pose, data['camera_to_world'][index])
        laser.validate_rig(K, pose)
        path = folder/record['capture']
        if not path.exists():
            assert package, f'missing full-cache source frame {index}'
            continue
        assert sha(path) == record['capture_sha256']
        uv, _ = laser.extract_line(np.asarray(Image.open(path)))
        xyz, good = laser.reconstruct(uv, K, plane, pose)
        uv = uv[good]
        assert uv.shape == all_uv[mask].shape and xyz.shape == all_xyz[mask].shape
        if len(uv):
            uv_error = max(uv_error, float(np.max(np.abs(uv-all_uv[mask]))))
            xyz_error = max(xyz_error, float(np.max(np.abs(xyz-all_xyz[mask]))))
        assert np.array_equal(uv, all_uv[mask]) and np.array_equal(xyz, all_xyz[mask]), index
        count += 1
    assert count == (24 if package else 360)
    checks['saved_png_to_uv_xyz_exact_replay_without_mesh_truth'] = True
    # No correspondence failures were silently discarded from surface scoring.
    assert metrics['point_to_surface']['count'] == len(all_xyz)
    assert metrics['same_ray_first_surface']['count']+metrics['rays_without_mesh_correspondence'] == len(all_xyz)
    assert metrics['rays_without_mesh_correspondence'] == sum(r['missed_surface_rays'] for r in metrics['frames_detail'])
    checks['all_accepted_points_retained_in_scoring_and_nohit_accounting'] = True
    # Independently verify the complete ASCII PLY, not just its declared count.
    lines = (folder/'reconstruction.ply').read_text().splitlines()
    end = lines.index('end_header')
    points = np.array([line.split()[:3] for line in lines[end+1:]], dtype=float)
    assert points.shape == all_xyz.shape and np.max(np.abs(points-all_xyz)) <= 5.01e-8
    checks['all_points_present_in_full_ply_at_declared_precision'] = True
    source_files = {'updated/laser.py': ROOT.parent/'updated/laser.py',
                    'showcase/checks.py': Path(__file__), 'showcase/generate.py': ROOT/'generate.py',
                    'showcase/mesh_scene.py': ROOT/'mesh_scene.py'}
    for name, path in [('generate.py', ROOT/'generate.py'), ('mesh_scene.py', ROOT/'mesh_scene.py'),
                       ('updated/laser.py', ROOT.parent/'updated/laser.py'), ('configuration.json', folder/'configuration.json'),
                       ('calibration.json', folder/'calibration.json')]:
        assert sha(path) == metrics['source_inputs'][name], name
    checks['generation_core_configuration_and_calibration_source_bindings'] = True
    return {'schema': 1, 'scope': __doc__, 'all_passed': True, 'checks': checks,
            'replayed_scan_pngs': count, 'replayed_calibration_pngs': len(calibration['frames']),
            'maximum_uv_absolute_difference_px': uv_error, 'maximum_xyz_absolute_difference_m': xyz_error,
            'points': len(all_xyz), 'versions': {'python': platform.python_version(), 'numpy': np.__version__,
                                               'scipy': scipy.__version__, 'pillow': PIL.__version__},
            'source_sha256': {name: sha(path) for name, path in source_files.items()},
            'input_sha256': {name: sha(folder/name) for name in ('configuration.json', 'calibration.json', 'metrics.json', 'reconstruction.npz', 'reconstruction.ply')}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cache', type=Path, help='full360-view generated cache; otherwise public subset')
    parser.add_argument('--output', type=Path, default=ROOT/'validation/replay.json')
    args = parser.parse_args()
    report = run(args.cache or ROOT/'data', package=args.cache is None)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report, indent=2))

if __name__ == '__main__': main()
