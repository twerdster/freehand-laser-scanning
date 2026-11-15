"""Independent forward image formation. Never imports the reconstruction core.

Pixel rays intersect analytic world surfaces; laser brightness depends on distance
of the hit to the camera-attached laser plane. Truth is used only for evaluation.
"""
import numpy as np

WIDTH, HEIGHT = 160, 120
K = np.array([[160., 0., 79.5], [0., 160., 59.5], [0., 0., 1.]])
LASER = np.array([0., 1., .3, -.3])
BOARD = np.array([0., 0., 1., -1.])


def pose(x=0., y=0., z=0., pitch=0., yaw=0.):
    cp, sp, cy, sy = np.cos(pitch), np.sin(pitch), np.cos(yaw), np.sin(yaw)
    rx = np.array([[1., 0., 0.], [0., cp, -sp], [0., sp, cp]])
    ry = np.array([[cy, 0., sy], [0., 1., 0.], [-sy, 0., cy]])
    result = np.eye(4)
    result[:3, :3], result[:3, 3] = ry @ rx, (x, y, z)
    return result


def rays(pixels, intrinsics, transform):
    uv = np.asarray(pixels)
    # Independent explicit pinhole forward ray, not reconstruction's solve(K,q).
    q = np.column_stack(((uv[:, 0]-intrinsics[0, 2])/intrinsics[0, 0],
                         (uv[:, 1]-intrinsics[1, 2])/intrinsics[1, 1], np.ones(len(uv))))
    return q @ transform[:3, :3].T, transform[:3, 3]


def intersect(pixels, intrinsics, transform, scene):
    directions, origin = rays(pixels, intrinsics, transform)
    if scene == 'sphere':
        center, radius = np.array([0., 0., 1.25]), .40
        delta = origin-center
        a, b = np.sum(directions**2, axis=1), 2*(directions @ delta)
        c = delta @ delta-radius**2
        disc = b*b-4*a*c
        depth = np.where(disc >= 0, (-b-np.sqrt(np.maximum(0, disc)))/(2*a), np.nan)
    else:
        planes = {'board': [(np.array([0., 0., 1.]), -1., 0)],
                  'plane': [(np.array([-.18, .08, 1.]), -1., 0)],
                  'fold': [(np.array([-.45, -.1, 1.]), -1., 1),
                           (np.array([.45, -.1, 1.]), -1., -1)]}[scene]
        depths = []
        for normal, offset, sign in planes:
            with np.errstate(divide='ignore', invalid='ignore'):
                z = -(normal @ origin+offset)/(directions @ normal)
            points = origin+z[:, None]*directions
            good = (z > 0) & (np.abs(points[:, 0]) < .7) & (np.abs(points[:, 1]) < .7)
            if sign:
                good &= sign*points[:, 0] >= 0
            depths.append(np.where(good, z, np.inf))
        depth = np.min(depths, axis=0)
        depth[~np.isfinite(depth)] = np.nan
    points = origin+depth[:, None]*directions
    return points, depth


def render(scene, transform, seed=0, noise=0., occlusion=False, distractor=False):
    yy, xx = np.mgrid[:HEIGHT, :WIDTH]
    pixels = np.column_stack((xx.ravel(), yy.ravel()))
    world, depth = intersect(pixels, K, transform, scene)
    camera = (world-transform[:3, 3]) @ transform[:3, :3]
    distance = (camera @ LASER[:3]+LASER[3])/np.linalg.norm(LASER[:3])
    # Physical 6 mm stripe width; no inverse reconstruction is used to draw it.
    stripe = np.exp(-.5*(distance/.006)**2).reshape(HEIGHT, WIDTH)
    stripe = np.nan_to_num(stripe)
    if occlusion:
        stripe[:, 65:86] = 0
    base = 18+3*np.sin(xx*.06)*np.cos(yy*.09)
    image = base+235*stripe
    if distractor:
        # A brighter non-laser ridge: intentionally indistinguishable locally.
        image = np.maximum(image, 18+237*np.exp(-.5*((yy-38)/1.25)**2))
    image += np.random.default_rng(seed).normal(0, noise, image.shape)
    return np.uint8(np.clip(np.rint(image), 0, 255))


def surface_distance(points, scene):
    p = np.asarray(points)
    if scene == 'sphere':
        return np.abs(np.linalg.norm(p-np.array([0., 0., 1.25]), axis=1)-.4)
    if scene in ('plane', 'board'):
        n = np.array([-.18, .08, 1.]) if scene == 'plane' else np.array([0., 0., 1.])
        return np.abs(p @ n-1)/np.linalg.norm(n)
    return np.abs(p[:, 2]-1-.45*np.abs(p[:, 0])-.1*p[:, 1])/np.sqrt(1+.45**2+.1**2)


def specification():
    calibrations = []
    for i, z in enumerate([0., .07, .14, .21, .10, .18]):
        calibrations.append({'id': f'calibration-{i:02}', 'scene': 'board',
                             'camera_to_world': pose(x=(i-2.5)*.006, z=z,
                                                     pitch=(i-2.5)*.022, yaw=(i%3-1)*.02).tolist(),
                             'seed': 100+i, 'noise': 1., 'occlusion': False, 'distractor': False})
    scans = []
    for scene in ('plane', 'sphere', 'fold'):
        for i, y in enumerate([-.20, -.10, 0., .10, .20]):
            scans.append({'id': f'{scene}-{i:02}', 'scene': scene,
                          'camera_to_world': pose(x=.02*np.sin(i), y=y,
                                                  pitch=(i-2)*.012, yaw=(i-2)*.015).tolist(),
                          'seed': 200+i, 'noise': 1.5, 'occlusion': i == 3,
                          'distractor': False})
    scans.append({**scans[2], 'id': 'plane-distractor', 'distractor': True})
    return {'schema': 1, 'units': 'metres', 'pixel_origin': 'zero-based',
            'camera_axes': '+X right, +Y down, +Z forward',
            'pose_convention': 'row-major camera-to-world rigid 4x4',
            'width': WIDTH, 'height': HEIGHT, 'intrinsics': K.tolist(),
            'calibration_board_world': BOARD.tolist(),
            'ground_truth_laser_plane_camera': LASER.tolist(),
            'threshold': 8., 'calibration': calibrations, 'scans': scans}
