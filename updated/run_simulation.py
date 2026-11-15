"""Generate bounded fixtures, execute recovered-stage adapters and score geometry."""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image

from . import laser, synthetic, truth

ROOT = Path(__file__).resolve().parent


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, allow_nan=False)+'\n')


def stats(error):
    e = np.asarray(error)*1000
    return {'count': len(e), 'surface_rmse_mm': float(np.sqrt(np.mean(e**2))) if len(e) else None,
            'surface_median_mm': float(np.median(e)) if len(e) else None,
            'surface_p95_mm': float(np.percentile(e, 95)) if len(e) else None,
            'surface_max_mm': float(np.max(e)) if len(e) else None}


def evaluate(spec, fixtures):
    K = np.asarray(spec['intrinsics'])
    calibration = []
    extracted = {}
    for frame in spec['calibration']:
        image = np.asarray(Image.open(fixtures/frame['file']).convert('L'))
        pixels, response = laser.extract_line(image, spec['threshold'])
        points, _ = laser.calibration_points(pixels, K, frame['camera_to_world'], spec['calibration_board_world'])
        calibration.extend(points)
        extracted[frame['id']] = (image, pixels, response, points)
    calibration = np.asarray(calibration)
    plane = laser.fit_plane(calibration)
    laser_truth = np.asarray(spec['ground_truth_laser_plane_camera'])
    laser_truth /= np.linalg.norm(laser_truth[:3])
    if laser_truth[:3] @ plane[:3] < 0:
        laser_truth = -laser_truth
    report = {'schema': 1, 'scope': 'Synthetic adapter validation; not a reproduction of BMVC 2015 measurements',
              'image_size': [spec['width'], spec['height']], 'threshold': spec['threshold'],
              'kernel_bank': 'rebuilt centered 11x11, L1 normalized',
              'calibration': {'frames': len(spec['calibration']), 'points': len(calibration),
                              'fitted_plane_camera': plane.tolist(),
                              'normal_error_degrees': float(np.degrees(np.arccos(np.clip(plane[:3] @ laser_truth[:3], -1, 1)))),
                              'offset_error_mm': float(abs(plane[3]-laser_truth[3])*1000),
                              'fit_residual_rmse_mm': float(np.sqrt(np.mean((calibration @ plane[:3]+plane[3])**2))*1000)},
              'frames': [], 'scenes': {}, 'sensitivity': {}}
    all_points, colors, by_scene = [], [], {}
    numerical = {'calibration_plane': plane.tolist(), 'frames': []}
    for i, frame in enumerate(spec['scans']):
        image = np.asarray(Image.open(fixtures/frame['file']).convert('L'))
        pixels, response = laser.extract_line(image, spec['threshold'])
        points, good = laser.reconstruct(pixels, K, plane, frame['camera_to_world'])
        error = synthetic.surface_distance(points, frame['scene'])
        row = {'id': frame['id'], 'scene': frame['scene'], 'occlusion': frame['occlusion'],
               'distractor': frame['distractor'], 'extracted_pixels': len(pixels),
               'rejected_geometry': int((~good).sum()), 'interior_columns': spec['width']-10,
               **stats(error), 'curve': truth.score_curve(frame, K, pixels[good], points)}
        report['frames'].append(row)
        numerical['frames'].append({'id': frame['id'], 'pixels': pixels.tolist(), 'points': points.tolist()})
        extracted[frame['id']] = (image, pixels, response, points)
        if not frame['distractor']:
            by_scene.setdefault(frame['scene'], []).extend(error)
            all_points.extend(points)
            colors.extend([[int(i*47%205+50), int(i*83%205+50), int(i*131%205+50)]]*len(points))
    for name, errors in by_scene.items():
        rows = [f for f in report['frames'] if f['scene'] == name and not f['distractor']]
        report['scenes'][name] = {**stats(errors), 'frames': len(rows),
                                 'accepted_per_interior_column': sum(f['count'] for f in rows)/sum(f['interior_columns'] for f in rows)}
    # Errors in supplied external tracking must remain visible; no pose tracker is implemented.
    frame = spec['scans'][2]
    uv = extracted[frame['id']][1]
    for label, T in [('correct_pose', frame['camera_to_world']),
                     ('one_frame_pose_offset', spec['scans'][3]['camera_to_world'])]:
        points, _ = laser.reconstruct(uv, K, plane, T)
        report['sensitivity'][label] = stats(synthetic.surface_distance(points, frame['scene']))
    scaled = np.asarray(frame['camera_to_world']).copy()
    scaled[:3, 3] *= 1.2
    points, _ = laser.reconstruct(uv, K, plane, scaled)
    report['sensitivity']['translation_scale_plus_20_percent'] = stats(synthetic.surface_distance(points, frame['scene']))
    # A marker-size error scales the external metric board and pose translations.
    # Image formation remains unchanged; the reconstruction receives the wrong scale.
    scale = 1.05
    wrong_board = np.asarray(spec['calibration_board_world']).copy()
    wrong_board[3] *= scale
    wrong_calibration = []
    for calibration_frame in spec['calibration']:
        wrong_pose = np.asarray(calibration_frame['camera_to_world']).copy()
        wrong_pose[:3, 3] *= scale
        observations = extracted[calibration_frame['id']][1]
        wrong_calibration.extend(laser.calibration_points(observations, K, wrong_pose, wrong_board)[0])
    wrong_plane = laser.fit_plane(wrong_calibration)
    wrong_pose = np.asarray(frame['camera_to_world']).copy()
    wrong_pose[:3, 3] *= scale
    points, _ = laser.reconstruct(uv, K, wrong_plane, wrong_pose)
    report['sensitivity']['external_metric_scale_plus_5_percent'] = stats(synthetic.surface_distance(points, frame['scene']))
    # Literal archived-bank diagnostic is intentionally separate from rebuilt-bank results.
    image = extracted[frame['id']][0]
    old_uv, _ = laser.extract_line(image, spec['threshold'], bank='archived')
    old_points, _ = laser.reconstruct(old_uv, K, plane, frame['camera_to_world'])
    report['archived_bank_diagnostic'] = {'frame': frame['id'], **stats(synthetic.surface_distance(old_points, frame['scene'])),
                                          'note': 'Literal zero-filled C arrays; modern column peak/guards and rebuilt-bank calibration still used. Not a historical app execution.'}
    return report, numerical, extracted, np.asarray(all_points), np.asarray(colors)


def write_ply(path, points, colors):
    with path.open('w') as stream:
        stream.write('ply\nformat ascii 1.0\ncomment Synthetic scenes; colors identify frames, not recovered texture\n')
        stream.write(f'element vertex {len(points)}\nproperty float x\nproperty float y\nproperty float z\nproperty uchar red\nproperty uchar green\nproperty uchar blue\nend_header\n')
        for point, color in zip(points, colors):
            stream.write(' '.join(f'{x:.8f}' for x in point)+' '+' '.join(str(int(x)) for x in color)+'\n')


def plots(spec, report, extracted, output):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    chosen = ['calibration-02', 'plane-02', 'sphere-02', 'fold-03', 'plane-distractor']
    figure, axes = plt.subplots(2, len(chosen), figsize=(13, 4.5), constrained_layout=True)
    for column, name in enumerate(chosen):
        image, pixels, response, _ = extracted[name]
        axes[0, column].imshow(image, cmap='gray', vmin=0, vmax=255)
        axes[0, column].scatter(pixels[:, 0], pixels[:, 1], s=1, c='#ff4949')
        axes[0, column].set_title(name, fontsize=9)
        axes[1, column].imshow(response, cmap='magma', vmin=0, vmax=120)
        for row in range(2):
            axes[row, column].set_axis_off()
    figure.suptitle('Generated camera frames + detected ridge (top); paired-filter response (bottom)')
    figure.savefig(output/'frames-and-response.png', dpi=140)
    plt.close(figure)
    figure, axes = plt.subplots(1, 3, figsize=(12, 4), constrained_layout=True)
    for ax, scene in zip(axes, ('plane', 'sphere', 'fold')):
        for frame in spec['scans']:
            if frame['scene'] != scene or frame['distractor']:
                continue
            points = extracted[frame['id']][3]
            error = synthetic.surface_distance(points, scene)*1000
            m = ax.scatter(points[:, 0], points[:, 2], c=error, s=4, cmap='viridis', vmin=0, vmax=8)
        x = np.linspace(-.5, .5, 200)
        if scene == 'sphere':
            theta = np.linspace(0, 2*np.pi, 200)
            ax.plot(.4*np.cos(theta), 1.25+.4*np.sin(theta), ':', color='gray', label='truth cross-section y=0')
        else:
            z = 1+.18*x if scene == 'plane' else 1+.45*np.abs(x)
            ax.plot(x, z, ':', color='gray', label='truth cross-section y=0')
        ax.set_title(f"{scene}: {report['scenes'][scene]['surface_rmse_mm']:.2f} mm RMSE")
        ax.set_xlabel('world X (m)'); ax.set_ylabel('world Z (m)')
        ax.invert_yaxis(); ax.legend(fontsize=7)
    figure.colorbar(m, ax=axes, label='Distance to analytic surface (mm)', shrink=.7)
    figure.savefig(output/'geometry-and-errors.png', dpi=150)
    plt.close(figure)
    labels = ['plane', 'sphere', 'fold', 'distractor', 'pose offset']
    values = [report['scenes'][s]['surface_rmse_mm'] for s in labels[:3]]+[report['frames'][-1]['surface_rmse_mm'], report['sensitivity']['one_frame_pose_offset']['surface_rmse_mm']]
    figure, ax = plt.subplots(figsize=(7, 3), constrained_layout=True)
    bars = ax.bar(labels, values, color=['#267a9c']*3+['#ba4b3a']*2)
    ax.set_yscale('log'); ax.set_ylabel('Surface RMSE (mm, log scale)'); ax.set_title('Successful scenes and deliberate failure/sensitivity cases')
    ax.bar_label(bars, fmt='%.2f', padding=3); ax.set_ylim(.8, 1800)
    figure.savefig(output/'error-summary.png', dpi=140); plt.close(figure)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--fixtures', type=Path, default=ROOT/'fixtures')
    parser.add_argument('--output', type=Path, default=ROOT/'artifacts')
    parser.add_argument('--no-plots', action='store_true')
    args = parser.parse_args()
    args.fixtures.mkdir(parents=True, exist_ok=True); args.output.mkdir(parents=True, exist_ok=True)
    spec = synthetic.specification()
    for frame in spec['calibration']+spec['scans']:
        frame['file'] = frame['id']+'.png'
        image = synthetic.render(frame['scene'], np.asarray(frame['camera_to_world']), frame['seed'], frame['noise'], frame['occlusion'], frame['distractor'])
        Image.fromarray(image).save(args.fixtures/frame['file'])
        frame['sha256'] = hashlib.sha256((args.fixtures/frame['file']).read_bytes()).hexdigest()
    write_json(args.fixtures/'sequence.json', spec)
    report, numerical, extracted, points, colors = evaluate(spec, args.fixtures)
    write_json(args.output/'metrics.json', report)
    write_json(args.output/'desktop-points.json', numerical)
    write_ply(args.output/'reconstruction.ply', points, colors)
    for scene in ('plane', 'sphere', 'fold'):
        scene_points, scene_colors = [], []
        for i, frame in enumerate(spec['scans']):
            if frame['scene'] == scene and not frame['distractor']:
                cloud = extracted[frame['id']][3]
                scene_points.extend(cloud)
                scene_colors.extend([[int(i*47%205+50), int(i*83%205+50), int(i*131%205+50)]]*len(cloud))
        write_ply(args.output/(scene+'.ply'), scene_points, scene_colors)
    if not args.no_plots:
        plots(spec, report, extracted, args.output)
    print(json.dumps({'calibration': report['calibration'], 'scenes': report['scenes'], 'sensitivity': report['sensitivity'], 'distractor': report['frames'][-1]}, indent=2))

if __name__ == '__main__':
    main()
