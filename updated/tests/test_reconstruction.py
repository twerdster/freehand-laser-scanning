import hashlib
import json
import os
from pathlib import Path
import unittest

import numpy as np
from PIL import Image

from updated import laser, synthetic, truth
from updated.native_bridge import Native
from updated.run_simulation import evaluate

ROOT = Path(__file__).resolve().parents[1]
SPEC = json.loads((ROOT/'fixtures/sequence.json').read_text())


class ReconstructionTests(unittest.TestCase):
    def test_forward_generation_is_reproducible_and_hashes_match(self):
        for f in SPEC['calibration']+SPEC['scans']:
            generated = synthetic.render(f['scene'], np.array(f['camera_to_world']), f['seed'], f['noise'], f['occlusion'], f['distractor'])
            file = ROOT/'fixtures'/f['file']
            np.testing.assert_array_equal(np.asarray(Image.open(file)), generated)
            self.assertEqual(hashlib.sha256(file.read_bytes()).hexdigest(), f['sha256'])

    def test_cubic_quadratic_limit_and_flat_rejection(self):
        x = np.arange(-2., 3.)
        self.assertAlmostEqual(laser.cubic_peak(10-(x-.23)**2), .23)
        self.assertIsNone(laser.cubic_peak(np.ones(5)))
        self.assertIsNone(laser.cubic_peak(10+(x-.2)**2))
        self.assertIsNone(laser.cubic_peak([0, 1, np.nan, 1, 0]))
        self.assertIsNone(laser.cubic_peak(10-(x-1.2)**2))

    def test_no_signal_and_border_ridge_are_rejected(self):
        self.assertEqual(len(laser.extract_line(np.zeros((120, 160)))[0]), 0)
        image = np.zeros((120, 160)); image[0:2] = 255
        self.assertEqual(len(laser.extract_line(image)[0]), 0)

    def test_invalid_images_and_thresholds(self):
        for image in (np.zeros((4, 4)), np.full((12, 12), np.nan), np.full((12, 12), 256)):
            with self.assertRaises(ValueError): laser.extract_line(image)
        with self.assertRaises(ValueError): laser.extract_line(np.zeros((12, 12)), 0)

    def test_literal_source_bank_is_separate(self):
        old = laser.archived_kernels()
        self.assertEqual(len(old), 12)
        self.assertTrue(all(a.shape == (11, 11) for pair in old for a in pair))
        # Diagnostic of actual archived initializers, not an assumption that names imply rotations.
        np.testing.assert_array_equal(old[0][0], old[1][0])
        self.assertFalse(np.array_equal(old[0][0], laser.paired_kernels(.5, 80)[0]))

    def test_known_geometry_and_camera_world_convention(self):
        T = synthetic.pose(.1, -.2, .3, pitch=.1, yaw=-.2)
        plane = np.array([0., 0., 1., -1.])
        uv = np.array([[79.5, 59.5], [95.5, 43.5]])
        p, good = laser.reconstruct(uv, synthetic.K, plane, T)
        np.testing.assert_array_equal(good, [True, True])
        camera = np.array([[0., 0., 1.], [.1, -.1, 1.]])
        np.testing.assert_allclose(p, camera @ T[:3, :3].T+T[:3, 3], atol=1e-12)

    def test_grazing_behind_and_over_depth_rejected(self):
        uv = np.array([[79.5, 59.5]])
        for plane in ([1, 0, 0, -.3], [0, 0, 1, .3], [0, 0, 1, -4]):
            p, good = laser.reconstruct(uv, synthetic.K, plane, np.eye(4))
            self.assertEqual(len(p), 0); self.assertFalse(good[0])

    def test_invalid_rigs_and_transposed_pose(self):
        uv = np.array([[79.5, 59.5]])
        wrong = []
        for axis in range(3):
            t = np.eye(4); t[axis, axis] = -1; wrong.append(t)
        t = np.eye(4); t[0, 0] = 1.1; wrong.append(t)
        t = synthetic.pose(.1, .2, .3).T; wrong.append(t)
        t = np.eye(4); t[0, 0] = np.nan; wrong.append(t)
        for T in wrong:
            with self.assertRaises(ValueError): laser.reconstruct(uv, synthetic.K, synthetic.LASER, T)
        k = synthetic.K.copy(); k[0, 0] = -160
        with self.assertRaises(ValueError): laser.reconstruct(uv, k, synthetic.LASER, np.eye(4))

    def test_calibration_is_camera_frame_not_world(self):
        T = synthetic.pose(.02, -.1, .15, pitch=.06, yaw=.03)
        uv, _ = laser.extract_line(synthetic.render('board', T))
        p, good = laser.calibration_points(uv, synthetic.K, T, synthetic.BOARD)
        world = p @ T[:3, :3].T+T[:3, 3]
        np.testing.assert_allclose(world[:, 2], 1, atol=1e-12)
        self.assertGreater(np.max(np.abs(p[:, 2]-1)), .1)
        self.assertTrue(good.all())

    def test_calibration_degeneracy_and_single_pose_noise(self):
        for p in (np.zeros((5, 3)), np.column_stack((np.arange(10), np.zeros((10, 2))))):
            with self.assertRaises(ValueError): laser.fit_plane(p)
        f = SPEC['calibration'][0]
        uv, _ = laser.extract_line(np.asarray(Image.open(ROOT/'fixtures'/f['file'])))
        p, _ = laser.calibration_points(uv, synthetic.K, f['camera_to_world'], synthetic.BOARD)
        with self.assertRaises(ValueError): laser.fit_plane(p)

    def test_end_to_end_geometry_failure_and_timing_metrics(self):
        report, _, _, _, _ = evaluate(SPEC, ROOT/'fixtures')
        self.assertLess(report['calibration']['normal_error_degrees'], .1)
        for scene in ('plane', 'sphere', 'fold'):
            self.assertLess(report['scenes'][scene]['surface_rmse_mm'], 3.2)
            self.assertGreater(report['scenes'][scene]['count'], 450)
        self.assertGreater(report['frames'][-1]['surface_rmse_mm'], 500)
        self.assertGreater(report['sensitivity']['one_frame_pose_offset']['surface_rmse_mm'], 2*report['sensitivity']['correct_pose']['surface_rmse_mm'])
        self.assertGreater(report['sensitivity']['external_metric_scale_plus_5_percent']['surface_rmse_mm'], 40)

    def test_occlusion_reduces_accepted_columns(self):
        T = synthetic.pose()
        clean = laser.extract_line(synthetic.render('plane', T))[0]
        occluded = laser.extract_line(synthetic.render('plane', T, occlusion=True))[0]
        self.assertGreater(len(clean)-len(occluded), 10)
        self.assertEqual(np.sum((occluded[:, 0] >= 69) & (occluded[:, 0] <= 81)), 0)

    def test_independent_continuous_curve_truth(self):
        frame = SPEC['scans'][2]
        curve = truth.ridge_curve(frame, synthetic.K)
        self.assertEqual(len(curve), 150)
        T = np.asarray(frame['camera_to_world'])
        for _, point in curve.values():
            self.assertLess(synthetic.surface_distance([point], 'plane')[0], 1e-12)
            camera = (point-T[:3, 3]) @ T[:3, :3]
            self.assertLess(abs(camera @ synthetic.LASER[:3]+synthetic.LASER[3]), 1e-10)
        occluded = truth.ridge_curve({**frame, 'occlusion': True}, synthetic.K)
        self.assertEqual(len(occluded), 129)
        # A prediction at a wrong row remains in the RMSE; matching does not trim it.
        row, point = curve[80]
        result = truth.score_curve(frame, synthetic.K, [[80, row+10]], [point+[0, .1, 0]])
        self.assertAlmostEqual(result['row_rmse_px_on_truth_columns'], 10)
        self.assertAlmostEqual(result['curve_point_rmse_mm_on_truth_columns'], 100)
        self.assertEqual(result['matched_within_1px'], 0)


@unittest.skipUnless(os.environ.get('FREEHAND_NATIVE_LIB'), 'Native Accelerate core not requested')
class NativeParityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.native = Native(os.environ['FREEHAND_NATIVE_LIB'])

    def test_all_actual_frames_filter_and_subpixel_parity(self):
        for frame in SPEC['calibration']+SPEC['scans']:
            image = np.asarray(Image.open(ROOT/'fixtures'/frame['file']))
            pixels, response = laser.extract_line(image)
            np.testing.assert_allclose(self.native.response(image), response, atol=3e-5, rtol=1e-5)
            np.testing.assert_allclose(self.native.extract(image), pixels, atol=2e-5, rtol=0)

    def test_full_native_calibration_and_reconstruction(self):
        python_points, native_points = [], []
        for frame in SPEC['calibration']:
            image = np.asarray(Image.open(ROOT/'fixtures'/frame['file']))
            uv, _ = laser.extract_line(image)
            python_points.extend(laser.calibration_points(uv, synthetic.K, frame['camera_to_world'], synthetic.BOARD)[0])
            native_points.extend(self.native.points(self.native.extract(image), synthetic.K, synthetic.BOARD, frame['camera_to_world'], calibration=True))
        pp, pn = laser.fit_plane(python_points), self.native.fit(native_points)
        np.testing.assert_allclose(pp, pn, atol=1e-7, rtol=0)
        for frame in SPEC['scans']:
            image = np.asarray(Image.open(ROOT/'fixtures'/frame['file']))
            uv, _ = laser.extract_line(image)
            expected, _ = laser.reconstruct(uv, synthetic.K, pp, frame['camera_to_world'])
            actual = self.native.points(self.native.extract(image), synthetic.K, pn, frame['camera_to_world'])
            np.testing.assert_allclose(actual, expected, atol=1e-6, rtol=0)

    def test_native_rejects_invalid_rigs_and_data(self):
        uv = np.array([[79.5, 59.5]])
        for index, value in ((0, -1.), (5, 1.2), (3, np.nan)):
            T = np.eye(4); T.flat[index] = value
            with self.assertRaises(ValueError): self.native.points(uv, synthetic.K, synthetic.LASER, T)
        k = synthetic.K.copy(); k[0, 0] = -160
        with self.assertRaises(ValueError): self.native.points(uv, k, synthetic.LASER, np.eye(4))
        with self.assertRaises(ValueError): self.native.points([[np.nan, 2]], synthetic.K, synthetic.LASER, np.eye(4))
        with self.assertRaises(ValueError): self.native.fit(np.zeros((10, 3)))
        with self.assertRaises(ValueError): self.native.fit(np.full((10, 3), np.nan))
        f = SPEC['calibration'][0]
        uv = self.native.extract(np.asarray(Image.open(ROOT/'fixtures'/f['file'])))
        single_pose = self.native.points(uv, synthetic.K, synthetic.BOARD, f['camera_to_world'], calibration=True)
        with self.assertRaises(ValueError): self.native.fit(single_pose)
        for plane in ([1, 0, 0, -.3], [0, 0, 1, .3], [0, 0, 1, -4]):
            self.assertEqual(len(self.native.points([[79.5, 59.5]], synthetic.K, plane, np.eye(4))), 0)
        with self.assertRaises(ValueError): self.native.extract(np.full((12, 12), np.nan))
        self.assertEqual(self.native.lib.laser_calibration_points(None, 0, None, None, None, None), -1)
        self.assertEqual(self.native.lib.laser_fit_plane(None, 4, None), -1)

    def test_wrapper_rejects_malformed_shapes_before_ffi(self):
        uv = np.array([[79.5, 59.5]])
        for inputs in ((np.zeros((3, 1)), synthetic.K, synthetic.LASER, np.eye(4)),
                       (uv, np.eye(2), synthetic.LASER, np.eye(4)),
                       (uv, synthetic.K, np.ones(3), np.eye(4)),
                       (uv, synthetic.K, synthetic.LASER, np.eye(3))):
            with self.assertRaises(ValueError): self.native.points(*inputs)
            with self.assertRaises(ValueError): self.native.points(*inputs, calibration=True)
        for points in (np.ones((10, 2)), np.ones(12), np.ones((3, 3))):
            with self.assertRaises(ValueError): self.native.fit(points)
        for image in (np.ones(12), np.ones((12, 12, 3)), np.ones((4, 4))):
            with self.assertRaises(ValueError): self.native.extract(image)
            with self.assertRaises(ValueError): self.native.response(image)


if __name__ == '__main__': unittest.main()
