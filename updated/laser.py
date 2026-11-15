"""Adapted Freehand Laser stages: paired filters, cubic ridge fit and triangulation.

Algorithm/source mapping is in README.md. This module does not estimate camera
poses. Coordinates are zero-based (u right, v down); camera +Z forward, metres.
"""
import math
from pathlib import Path
import re

import numpy as np
from scipy import ndimage

SCALES = (0.5, 1.0, 1.5, 2.0)
ANGLES = (80, 90, 100)
FIT = np.linalg.pinv(np.vander(np.arange(-2.0, 3.0), 4))


def paired_kernels(sigma, angle):
    """Centered 11x11 sampled derivatives of shifted Gaussians; L1 normalized.

    Regenerates the recovered construction, rather than silently treating the
    archived, partially initialized/differently labelled C arrays as corrected.
    """
    if not math.isfinite(sigma) or sigma <= 0:
        raise ValueError('sigma must be finite and positive')
    y, x = np.mgrid[-5:6, -5:6]
    theta = math.radians(angle)
    u, v = x * math.cos(theta) + y * math.sin(theta), -x * math.sin(theta) + y * math.cos(theta)
    left = (u + sigma) * np.exp(-((u + sigma)**2 + v**2) / (2 * sigma**2)) / sigma**2
    right = -(u - sigma) * np.exp(-((u - sigma)**2 + v**2) / (2 * sigma**2)) / sigma**2
    return left / np.abs(left).sum(), right / np.abs(right).sum()


def archived_kernels():
    """Literal C initializer semantics, including zero-filled trailing elements."""
    text = (Path(__file__).resolve().parents[1] / 'ios/Scanner/PointCloudSample/kernels.h').read_text()
    result = []
    for suffix in ('05', '1', '15', '2'):
        for angle in ANGLES:
            pair = []
            for side in ('elx', 'erx'):
                name = f'{side}{angle}s{suffix}'
                match = re.search(r'float\s+' + name + r'\[121\]\s*=\s*\{(.*?)\}', text, re.S)
                if not match:
                    raise ValueError(f'Archived kernel missing: {name}')
                values = [float(v) for v in match.group(1).split(',') if v.strip()]
                if len(values) > 121:
                    raise ValueError('Oversized archived initializer')
                pair.append(np.pad(values, (0, 121-len(values))).reshape(11, 11))
            result.append(pair)
    return result


def filter_response(image, bank='rebuilt', gamma=12.0):
    a = np.asarray(image, dtype=float)
    if a.ndim != 2 or min(a.shape) < 11 or not np.isfinite(a).all() or a.min() < 0 or a.max() > 255:
        raise ValueError('Expected a finite grayscale image in [0,255], at least 11x11')
    if gamma <= 0 or not math.isfinite(gamma):
        raise ValueError('gamma must be finite and positive')
    a = 255 * (a / 255)**gamma
    if bank == 'rebuilt':
        pairs = [paired_kernels(s, t) for s in SCALES for t in ANGLES]
    elif bank == 'archived':
        pairs = archived_kernels()
    else:
        raise ValueError('Unknown kernel bank')
    response = np.zeros(a.shape)
    for left, right in pairs:
        # vImageConvolve_PlanarF is checked independently by the native harness.
        l = ndimage.convolve(a, left, mode='constant')
        r = ndimage.convolve(a, right, mode='constant')
        response = np.maximum(response, np.minimum(np.maximum(l, 0), np.maximum(r, 0)))
    # Border policy is explicit: no samples whose filter footprint crosses image edge.
    response[:5] = response[-5:] = 0
    response[:, :5] = response[:, -5:] = 0
    return response


def cubic_peak(values, max_offset=0.7):
    y = np.asarray(values, dtype=float)
    if y.shape != (5,) or not np.isfinite(y).all():
        return None
    a, b, c, _ = FIT @ y
    tolerance = max(1.0, np.max(np.abs(y))) * 1e-10
    if abs(a) < tolerance:
        roots = [-c / (2*b)] if abs(b) > tolerance else []
    elif 4*b*b-12*a*c >= 0:
        roots = [(-2*b + sign * math.sqrt(4*b*b-12*a*c)) / (6*a) for sign in (-1, 1)]
    else:
        roots = []
    maxima = [float(r) for r in roots if abs(r) <= max_offset and 6*a*r+2*b < -tolerance]
    return min(maxima, key=abs) if maxima else None


def extract_line(image, threshold=8.0, bank='rebuilt'):
    if not math.isfinite(threshold) or threshold <= 0:
        raise ValueError('threshold must be finite and positive')
    response = filter_response(image, bank)
    points = []
    for u in range(5, response.shape[1]-5):
        v = int(np.argmax(response[:, u]))
        if response[v, u] < threshold or not 5 <= v < response.shape[0]-5:
            continue
        offset = cubic_peak(response[v-2:v+3, u])
        if offset is not None:
            points.append((u, v + offset))
    return np.asarray(points, dtype=float).reshape(-1, 2), response


def validate_rig(K, camera_to_world):
    K, T = np.asarray(K, dtype=float), np.asarray(camera_to_world, dtype=float)
    if K.shape != (3, 3) or T.shape != (4, 4) or not np.isfinite(K).all() or not np.isfinite(T).all():
        raise ValueError('Expected finite 3x3 intrinsics and 4x4 camera-to-world transform')
    if not np.allclose(K[2], (0, 0, 1)) or min(K[0, 0], K[1, 1]) <= 0 or abs(np.linalg.det(K)) < 1e-12:
        raise ValueError('Invalid pinhole intrinsics')
    R = T[:3, :3]
    if not np.allclose(T[3], (0, 0, 0, 1)) or not np.allclose(R.T @ R, np.eye(3), atol=1e-7) or not np.isclose(np.linalg.det(R), 1):
        raise ValueError('Pose must be a rigid right-handed camera-to-world transform')
    return K, T


def reconstruct(pixels, K, plane_camera, camera_to_world, min_cosine=0.03, max_depth=3.0):
    K, T = validate_rig(K, camera_to_world)
    uv = np.asarray(pixels, dtype=float)
    plane = np.asarray(plane_camera, dtype=float)
    if uv.ndim != 2 or uv.shape[1] != 2 or not np.isfinite(uv).all() or plane.shape != (4,) or not np.isfinite(plane).all() or np.linalg.norm(plane[:3]) < 1e-12:
        raise ValueError('Invalid pixels or camera-frame plane')
    if not 0 < min_cosine < 1 or not math.isfinite(max_depth) or max_depth <= 0:
        raise ValueError('Invalid conditioning/depth limits')
    q = np.linalg.solve(K, np.column_stack((uv, np.ones(len(uv)))).T).T
    denom = q @ plane[:3]
    cosine = np.abs(denom) / (np.linalg.norm(q, axis=1) * np.linalg.norm(plane[:3]))
    with np.errstate(divide='ignore', invalid='ignore'):
        alpha = -plane[3] / denom
    good = (cosine >= min_cosine) & (alpha > 0) & (alpha <= max_depth) & np.isfinite(alpha)
    points = (q[good] * alpha[good, None]) @ T[:3, :3].T + T[:3, 3]
    return points, good


def calibration_points(pixels, K, camera_to_world, board_world):
    """Intersect observed rays with a known board; return CAMERA coordinates.

    Generalizes the recovered world's y=0 board; the fitted laser plane stays
    attached to the camera, not the world.
    """
    K, T = validate_rig(K, camera_to_world)
    board = np.asarray(board_world, dtype=float)
    if board.shape != (4,) or not np.isfinite(board).all() or np.linalg.norm(board[:3]) < 1e-12:
        raise ValueError('Invalid board plane')
    camera_plane = np.r_[T[:3, :3].T @ board[:3], board[:3] @ T[:3, 3] + board[3]]
    return reconstruct(pixels, K, camera_plane, np.eye(4))


def fit_plane(points):
    p = np.asarray(points, dtype=float)
    if p.ndim != 2 or p.shape[1] != 3 or len(p) < 4 or not np.isfinite(p).all():
        raise ValueError('At least four finite 3D calibration points required')
    center = p.mean(axis=0)
    spread = np.linalg.svd(p-center, compute_uv=False)
    if spread[0] < 1e-6 or spread[1]/spread[0] < .01:
        raise ValueError('Calibration points are collinear/near-collinear; vary rig pose')
    _, _, vt = np.linalg.svd(np.column_stack((p-center, np.ones(len(p)))), full_matrices=False)
    plane = vt[-1]
    plane[3] -= plane[:3] @ center
    plane /= np.linalg.norm(plane[:3])
    if plane[np.argmax(np.abs(plane[:3]))] < 0:
        plane = -plane
    return plane
