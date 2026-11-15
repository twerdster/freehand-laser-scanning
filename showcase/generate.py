"""Render mesh observations, fit a laser plane, and scan through the existing core.

Truth mesh hits form independent camera images and score results only. No mesh
position, depth, visibility mask or face ID enters the inverse reconstruction.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import time

import numpy as np
from PIL import Image
from scipy.spatial import cKDTree

from updated import laser
from .mesh_scene import Scene, load_mesh, camera_rays, look_at

ROOT = Path(__file__).resolve().parent
WIDTH, HEIGHT = 320, 240
K = np.array([[340., 0., 159.5], [0., 340., 119.5], [0., 0., 1.]])
PLANE = np.array([0., 1., .14, -.10])
EMITTER = np.array([0., .10, 0.])
SIGMA = .0022
SEED = 20261115
MESH_SHA256 = 'b7e0fffaad4305e87490c12e186b3c3df0bb06b2a2e584c426e381a843ffbd49'


def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def write_json(path, value): path.write_text(json.dumps(value, indent=2, allow_nan=False)+'\n')

def scan_pose(azimuth, pitch, height, radius=.72):
    # For this fixed camera orientation, choose eye height so the actual rigid
    # plane intersects the object's vertical center axis at the requested height.
    sine, cosine = math.sin(pitch), math.cos(pitch)
    offset = (.10-radius*(.14*cosine-sine))/(cosine+.14*sine)
    eye = np.array([radius*math.sin(azimuth), height+offset, radius*math.cos(azimuth)])
    forward = np.array([-math.sin(azimuth)*cosine, -sine, -math.cos(azimuth)*cosine])
    return look_at(eye, eye+forward)


def calibrations():
    poses = []
    for i in range(8):
        eye = [(-1 if i%2 else 1)*(.035+.007*i), .38+.035*i, .46+.025*(i%4)]
        poses.append(look_at(eye, [.025*math.sin(i), 0, .03*math.cos(i)]))
    return poses


def finish_image(world, hits, normals, distance, visible, seed):
    rng = np.random.default_rng(seed)
    image = np.full(WIDTH*HEIGHT, 10.)
    light = np.array([.3, .75, 1.]); light /= np.linalg.norm(light)
    # Smooth diffuse context remains well below the laser response after gamma12.
    diffuse = np.abs(normals[hits] @ light)
    texture = 4*np.sin(world[hits, 0]*67)*np.cos(world[hits, 2]*81)
    base = 35+55*diffuse+texture
    stripe = np.exp(-.5*(distance[hits]/SIGMA)**2)*visible[hits]
    image[hits] = base+(255-base)*stripe
    image += rng.normal(0, .55, len(image))
    return np.uint8(np.clip(np.rint(image), 0, 255)).reshape(HEIGHT, WIDTH)


def board_image(T, seed):
    origin, directions = camera_rays(K, T, WIDTH, HEIGHT)
    with np.errstate(divide='ignore', invalid='ignore'): depth = -origin[1]/directions[:, 1]
    good = (depth > 0) & (depth < 3)
    world = origin+np.where(good, depth, 0)[:, None]*directions
    camera = (world-T[:3, 3]) @ T[:3, :3]
    distance = (camera @ PLANE[:3]+PLANE[3])/np.linalg.norm(PLANE[:3])
    normal = np.zeros_like(world); normal[:, 1] = 1
    return finish_image(world, good, normal, distance, good, seed)


def mesh_image(scene, T, seed):
    origin, directions = camera_rays(K, T, WIDTH, HEIGHT)
    depth, face, normals = scene.intersect(origin, directions)
    good = np.isfinite(depth)
    world = origin+np.where(good, depth, 0)[:, None]*directions
    camera = (world-T[:3, 3]) @ T[:3, :3]
    distance = (camera @ PLANE[:3]+PLANE[3])/np.linalg.norm(PLANE[:3])
    candidate = good & (np.abs(distance) < SIGMA*5)
    visible = np.zeros(len(depth), dtype=bool)
    emitter_world = T[:3, :3] @ EMITTER+T[:3, 3]
    if candidate.any(): visible[candidate] = scene.visible(emitter_world, world[candidate])
    image = finish_image(world, good, normals, distance, visible, seed)
    return image, {'camera_hit_pixels': int(good.sum()), 'near_laser_plane_pixels': int(candidate.sum()),
                   'laser_shadowed_pixels': int((candidate & ~visible).sum())}


def fit_calibration(cache):
    folder = cache/'calibration'; folder.mkdir(exist_ok=True)
    records, points = [], []
    for i, T in enumerate(calibrations()):
        path = folder/f'{i:03}.png'
        image = board_image(T, SEED+i)
        Image.fromarray(image).save(path)
        uv, _ = laser.extract_line(image)
        xyz, good = laser.calibration_points(uv, K, T, [0, 1, 0, 0])
        points.extend(xyz)
        records.append({'id': i, 'file': f'calibration/{i:03}.png', 'sha256': sha(path),
                        'camera_to_world': T.tolist(), 'observed_ridge_samples': len(uv), 'board_points': len(xyz)})
    points = np.asarray(points); fitted = laser.fit_plane(points)
    reference = PLANE/np.linalg.norm(PLANE[:3])
    if reference[:3] @ fitted[:3] < 0: reference = -reference
    metrics = {'frames': len(records), 'points': len(points), 'fitted_plane_camera': fitted.tolist(),
               'normal_error_degrees': float(np.degrees(np.arccos(np.clip(reference[:3] @ fitted[:3], -1, 1)))),
               'offset_error_mm': float(abs(reference[3]-fitted[3])*1000),
               'residual_rmse_mm': float(np.sqrt(np.mean((points @ fitted[:3]+fitted[3])**2))*1000)}
    return fitted, records, metrics


def surface_samples(vertices, faces, count=50000):
    rng = np.random.default_rng(SEED+901)
    tri = vertices[faces]
    area = np.linalg.norm(np.cross(tri[:, 1]-tri[:, 0], tri[:, 2]-tri[:, 0]), axis=1)/2
    indices = rng.choice(len(faces), count, p=area/area.sum())
    a, b = np.sqrt(rng.random(count)), rng.random(count)
    weights = np.column_stack((1-a, a*(1-b), a*b))
    return np.sum(tri[indices]*weights[..., None], axis=1)


def error_stats(error):
    mm = np.asarray(error)*1000
    return {'count': len(mm), 'rmse_mm': float(np.sqrt(np.mean(mm**2))) if len(mm) else None,
            'median_mm': float(np.median(mm)) if len(mm) else None,
            'p95_mm': float(np.percentile(mm, 95)) if len(mm) else None,
            'maximum_mm': float(np.max(mm)) if len(mm) else None}


def write_ply(path, points, indices):
    with path.open('w') as f:
        f.write('ply\nformat ascii 1.0\ncomment Computed scan points only; view colors are display colors\n')
        f.write(f'element vertex {len(points)}\nproperty float x\nproperty float y\nproperty float z\nproperty uchar red\nproperty uchar green\nproperty uchar blue\nend_header\n')
        for point, index in zip(points, indices):
            color = (50+int(index)%6*20, 120+int(index)%6*20, 190+int(index)%3*20)
            f.write(' '.join(f'{x:.7f}' for x in point)+' '+' '.join(map(str, color))+'\n')


def preview(cache, xyz, pass_index, scene):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from matplotlib import gridspec
    figure = plt.figure(figsize=(12, 6), constrained_layout=True)
    grid = gridspec.GridSpec(2, 3, figure=figure)
    for j, index in enumerate([12, 30, 47]):
        image = np.asarray(Image.open(cache/'captures'/f'{pass_index*60+index:04}.png'))
        ax = figure.add_subplot(grid[0, j]); ax.imshow(image, cmap='gray', vmin=0, vmax=255)
        ax.set_title(f'Actual source PNG · sweep {index+1}/60'); ax.set_axis_off()
    for j, az in enumerate([25, 90, 145]):
        ax = figure.add_subplot(grid[1, j], projection='3d')
        ax.scatter(xyz[:, 0], xyz[:, 2], xyz[:, 1], c=xyz[:, 1], s=.7, cmap='viridis', linewidths=0)
        ax.set_box_aspect((.5, .23, .35)); ax.view_init(elev=18, azim=az)
        ax.set_xlabel('X (m)'); ax.set_ylabel('Z (m)'); ax.set_zlabel('Y up (m)')
        ax.set_title(f'{len(xyz):,} actual reconstructed points')
    figure.suptitle('Stanford Dragon · one 60-view scan pass · supplied poses · no mesh points injected', fontsize=14)
    path = cache/f'preview-pass-{pass_index}.png'; figure.savefig(path, dpi=135); plt.close(figure)
    return path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mesh', type=Path, default=ROOT/'assets/dragon-normalized.npz')
    parser.add_argument('--cache', type=Path, required=True)
    parser.add_argument('--passes', type=int, default=6, choices=range(1, 7))
    parser.add_argument('--heights', type=int, default=60)
    args = parser.parse_args()
    if sha(args.mesh) != MESH_SHA256:
        raise ValueError('Expected the checksum-pinned Stanford Dragon; use showcase.prepare_mesh')
    args.cache.mkdir(parents=True, exist_ok=True)
    (args.cache/'captures').mkdir(exist_ok=True); (args.cache/'observations').mkdir(exist_ok=True)
    vertices, faces = load_mesh(args.mesh); scene = Scene(vertices, faces)
    config = {'schema': 1, 'asset': 'Stanford Dragon', 'mesh_sha256': sha(args.mesh),
              'width': WIDTH, 'height': HEIGHT, 'intrinsics': K.tolist(), 'seed': SEED,
              'laser_plane_camera_generation_only': PLANE.tolist(), 'laser_emitter_camera': EMITTER.tolist(),
              'laser_sigma_m': SIGMA, 'camera_radius_m': .72, 'heights': args.heights,
              'sweep_height_range_m': [-.02, .37], 'azimuths_radians': [i*math.pi/3 for i in range(6)],
              'pitch_down_radians': [0 if i%2 == 0 else math.radians(20) for i in range(6)],
              'units': 'metres', 'world': '+Y up, floorY0', 'camera': '+X right,+Y down,+Z forward',
              'inverse_policy': 'Existing strongest ridge per column; no truth/visibility mask passed to inverse'}
    config_path = args.cache/'configuration.json'
    if config_path.exists() and json.loads(config_path.read_text()) != config:
        raise ValueError('Cache has a different generation configuration; choose a new task folder')
    write_json(config_path, config)
    plane, calibration, calibration_metrics = fit_calibration(args.cache)
    write_json(args.cache/'calibration.json', {'frames': calibration, 'metrics': calibration_metrics, 'board_world': [0, 1, 0, 0]})
    print('calibration', json.dumps(calibration_metrics), flush=True)
    all_points, all_uv, all_views, rows, poses, ray_errors = [], [], [], [], [], []
    for p in range(args.passes):
        pass_points = []
        for h, height in enumerate(np.linspace(-.02, .37, args.heights)):
            index = p*args.heights+h
            T = scan_pose(p*math.pi/3, config['pitch_down_radians'][p], float(height))
            path = args.cache/'captures'/f'{index:04}.png'; saved = args.cache/'observations'/f'{index:04}.npz'
            start = time.monotonic()
            # Always regenerate and reprocess source PNGs. Cached observations
            # are outputs only and can never substitute for current extraction.
            image, forward = mesh_image(scene, T, SEED+100+index)
            Image.fromarray(image).save(path)
            uv, response = laser.extract_line(image)
            points, good = laser.reconstruct(uv, K, plane, T)
            uv = uv[good]
            np.savez_compressed(saved, uv=uv, xyz=points, forward=json.dumps(forward))
            distances = scene.distance(points)
            if len(uv):
                q = np.column_stack(((uv[:, 0]-K[0, 2])/K[0, 0], (uv[:, 1]-K[1, 2])/K[1, 1], np.ones(len(uv))))
                rays = q @ T[:3, :3].T
                depth, face, _ = scene.intersect(T[:3, 3], rays)
                matched = np.isfinite(depth)
                truth = T[:3, 3]+depth[matched, None]*rays[matched]
                correspondence = np.linalg.norm(points[matched]-truth, axis=1)
                ray_errors.extend(correspondence)
            else: matched = np.zeros(0, dtype=bool)
            row = {'index': index, 'pass': p, 'sweep': h, 'height_m': float(height), 'camera_to_world': T.tolist(),
                   'capture': f'captures/{index:04}.png', 'capture_sha256': sha(path), 'points': len(points),
                   'missed_surface_rays': int((~matched).sum()), 'point_surface_distance': error_stats(distances), **forward}
            rows.append(row); poses.append(T); all_points.extend(points); all_uv.extend(uv); all_views.extend([index]*len(points)); pass_points.extend(points)
            if h%10 == 0 or h == args.heights-1:
                print(f'pass {p+1}/6 sweep {h+1}/{args.heights}: {len(points)} points; {sum(r["points"] for r in rows)} total; {time.monotonic()-start:.2f}s', flush=True)
        if args.heights == 60:
            path = preview(args.cache, np.asarray(pass_points), p, scene)
            print('PREVIEW', path, flush=True)
    xyz, uv, view = np.asarray(all_points), np.asarray(all_uv), np.asarray(all_views, dtype=np.uint16)
    np.savez_compressed(args.cache/'reconstruction.npz', xyz=xyz, uv=uv, view_index=view, camera_to_world=np.array(poses), fitted_plane=plane)
    write_ply(args.cache/'reconstruction.ply', xyz, view)
    sample = surface_samples(vertices, faces)
    coverage, _ = cKDTree(xyz).query(sample, workers=-1)
    distances = scene.distance(xyz)
    report = {'schema': 1, 'scope': 'Synthetic scan of an independently ray-cast research mesh through existing inverse stages; poses supplied',
              'asset': 'Stanford Dragon', 'frames': len(rows), 'points': len(xyz), 'calibration': calibration_metrics,
              'point_to_surface': error_stats(distances), 'same_ray_first_surface': error_stats(ray_errors),
              'rays_without_mesh_correspondence': sum(r['missed_surface_rays'] for r in rows),
              'coverage': {'area_weighted_samples': len(sample), 'within_2mm_fraction': float(np.mean(coverage <= .002)),
                           'within_5mm_fraction': float(np.mean(coverage <= .005)), 'within_10mm_fraction': float(np.mean(coverage <= .010)),
                           'mesh_to_cloud_distance': error_stats(coverage), 'scope': 'Entire source mesh, including hidden undersides; deterministic triangle-area sampling'},
              'laser_occlusion': {'candidate_pixels': sum(r['near_laser_plane_pixels'] for r in rows),
                                  'shadowed_pixels': sum(r['laser_shadowed_pixels'] for r in rows)},
              'source_inputs': {'generate.py': sha(Path(__file__)), 'mesh_scene.py': sha(ROOT/'mesh_scene.py'),
                                'updated/laser.py': sha(ROOT.parent/'updated/laser.py'),
                                'configuration.json': sha(config_path), 'calibration.json': sha(args.cache/'calibration.json')},
              'frames_detail': rows, 'reconstruction_npz_sha256': sha(args.cache/'reconstruction.npz')}
    write_json(args.cache/'metrics.json', report)
    print('FINAL', json.dumps({k:v for k,v in report.items() if k != 'frames_detail'}), flush=True)

if __name__ == '__main__': main()
