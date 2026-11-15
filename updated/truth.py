"""Independent laser/surface curve truth, used only by desktop scoring.

For each camera column, bracket zero signed distance of a ray-cast surface hit
from the attached laser plane, then solve in continuous image row coordinates.
No detector response, fitted plane, extracted pixel or reconstruction call enters
this calculation. Occluded columns are excluded from visible-curve recall.
"""
import numpy as np
from scipy.optimize import brentq
from . import synthetic


def ridge_curve(frame, intrinsics):
    T = np.asarray(frame['camera_to_world'])
    def distances(u, rows):
        uv = np.column_stack((np.full(len(rows), u), rows))
        world, _ = synthetic.intersect(uv, intrinsics, T, frame['scene'])
        camera = (world-T[:3, 3]) @ T[:3, :3]
        return camera @ synthetic.LASER[:3]+synthetic.LASER[3]
    result = {}
    rows = np.arange(5., synthetic.HEIGHT-5., .5)
    for u in range(5, synthetic.WIDTH-5):
        if frame['occlusion'] and 65 <= u < 86:
            continue
        values = distances(u, rows)
        roots = []
        for i in np.flatnonzero(np.isfinite(values[:-1]) & np.isfinite(values[1:]) & (values[:-1]*values[1:] <= 0)):
            root = brentq(lambda v: distances(u, [v])[0], rows[i], rows[i+1], xtol=1e-11)
            if not roots or abs(root-roots[-1]) > 1e-6:
                roots.append(root)
        if len(roots) == 1:
            point, _ = synthetic.intersect([[u, roots[0]]], intrinsics, T, frame['scene'])
            result[u] = (roots[0], point[0])
    return result


def score_curve(frame, intrinsics, pixels, points):
    expected = ridge_curve(frame, intrinsics)
    errors, spatial, matches = [], [], 0
    for uv, point in zip(pixels, points):
        if int(uv[0]) in expected:
            row, truth_point = expected[int(uv[0])]
            error = abs(uv[1]-row)
            errors.append(error)
            spatial.append(np.linalg.norm(point-truth_point)*1000)
            matches += error <= 1
    return {'visible_truth_columns': len(expected), 'accepted_on_truth_columns': len(errors),
            'accepted_without_visible_truth': len(pixels)-len(errors),
            'missed_truth_columns': len(expected)-len(errors), 'matched_within_1px': int(matches),
            'recall_within_1px': matches/len(expected) if expected else None,
            'precision_within_1px': matches/len(pixels) if len(pixels) else None,
            'row_rmse_px_on_truth_columns': float(np.sqrt(np.mean(np.square(errors)))) if errors else None,
            'curve_point_rmse_mm_on_truth_columns': float(np.sqrt(np.mean(np.square(spatial)))) if spatial else None}
