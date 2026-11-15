#!/usr/bin/env python3
"""Render actual synthetic Freehand inputs/ridges/points; no numerical outputs changed.

Needs NumPy, SciPy, Pillow and ffmpeg. Presentation cursor and orthographic orbit
reveal already-computed samples; they do not invent sensor frames or new points.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import platform
import subprocess
import sys

import numpy as np
import scipy
from PIL import Image, ImageDraw, ImageFont, ImageSequence
import PIL

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from updated.laser import filter_response

BG = '#0b1320'
CARD = '#111e2e'
BORDER = '#24364a'
TEXT = '#eef4f7'
MUTED = '#a7b6c7'
TEAL = (64, 192, 204)
GOLD = (255, 194, 100)
SCENES = ('plane', 'sphere', 'fold')
TITLES = {'plane': 'Sloped plane', 'sphere': 'Sphere', 'fold': 'Folded surface'}
W, H, DURATION = 1000, 600, 80


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def locate_font(bold=False):
    candidates = ['/System/Library/Fonts/Supplemental/Arial Bold.ttf' if bold else '/System/Library/Fonts/Supplemental/Arial.ttf',
                  '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf' if bold else '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf']
    for name in candidates:
        if Path(name).exists():
            return Path(name)
    raise SystemExit('Specify installed --font-regular and --font-bold TrueType fonts')


class Painter:
    def __init__(self, regular, bold):
        self.regular, self.bold = regular, bold
        self.fonts = {}
    def font(self, size, bold=False):
        key = (size, bold)
        if key not in self.fonts:
            self.fonts[key] = ImageFont.truetype(str(self.bold if bold else self.regular), size)
        return self.fonts[key]
    def text(self, draw, xy, text, size=20, color=TEXT, bold=False):
        draw.text(xy, text, font=self.font(size, bold), fill=color)
    def center(self, draw, box, text, size=20, color=TEXT, bold=False):
        font = self.font(size, bold)
        bounds = draw.textbbox((0, 0), text, font=font)
        draw.text(((box[0]+box[2]-bounds[2])/2, box[1]), text, font=font, fill=color)


def load_data():
    sequence = json.loads((ROOT/'updated/fixtures/sequence.json').read_text())
    points = json.loads((ROOT/'updated/artifacts/desktop-points.json').read_text())
    metrics = json.loads((ROOT/'updated/artifacts/metrics.json').read_text())
    records = {f['id']: f for f in points['frames']}
    rows = {f['id']: f for f in metrics['frames']}
    frames = {}
    for f in sequence['scans']:
        path = ROOT/'updated/fixtures'/f['file']
        assert sha(path) == f['sha256']
        image = Image.open(path).convert('L')
        record = records[f['id']]
        uv, xyz = np.array(record['pixels']), np.array(record['points'])
        # This fixture has no geometry rejections; preserve the existing correspondence.
        assert len(uv) == len(xyz) == rows[f['id']]['count']
        assert rows[f['id']]['rejected_geometry'] == 0
        response = filter_response(np.asarray(image))
        value = np.clip(response/120, 0, 1)[..., None]
        rgb = np.uint8(np.clip(np.array([10, 26, 40])+value*np.array([38, 179, 172]), 0, 255))
        frames[f['id']] = {'spec': f, 'image': image.convert('RGB'), 'response': Image.fromarray(rgb), 'uv': uv, 'xyz': xyz}
    return sequence, metrics, frames


def rotation(yaw, pitch=.38):
    c, s = np.cos(yaw), np.sin(yaw)
    cy, sy = np.cos(pitch), np.sin(pitch)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]]) @ np.array([[1, 0, 0], [0, cy, -sy], [0, sy, cy]])


def display_xyz(points):
    return np.asarray(points)*np.array([1, -1, -1])


def setup_cloud(full_points, width, height):
    display = display_xyz(full_points)
    center = (display.min(0)+display.max(0))/2
    samples = np.concatenate([(display-center) @ rotation(y).T for y in np.linspace(-.5, .9, 40)])
    span = samples[:, :2].max(0)-samples[:, :2].min(0)
    scale = min(width*.88/span[0], height*.78/span[1])
    return {'center': center, 'scale': scale, 'low': full_points.min(0), 'high': full_points.max(0)}


def cloud_image(groups, settings, yaw, size=(364, 228)):
    ss = 2
    image = Image.new('RGB', (size[0]*ss, size[1]*ss), CARD)
    draw = ImageDraw.Draw(image)
    R = rotation(yaw)
    def project(points):
        p = (display_xyz(points)-settings['center']) @ R.T
        return np.column_stack((size[0]/2+p[:, 0]*settings['scale'], size[1]/2-p[:, 1]*settings['scale'], p[:, 2]))
    low, high = settings['low'], settings['high']
    # A display reference grid, not an estimated surface or fabricated mesh.
    floor = high[1]+.025
    for x in np.linspace(low[0], high[0], 5):
        line = project([[x, floor, low[2]], [x, floor, high[2]]])
        draw.line([(int(a*ss), int(b*ss)) for a, b in line[:, :2]], fill='#293c50', width=ss)
    for z in np.linspace(low[2], high[2], 5):
        line = project([[low[0], floor, z], [high[0], floor, z]])
        draw.line([(int(a*ss), int(b*ss)) for a, b in line[:, :2]], fill='#293c50', width=ss)
    dots = []
    for points, color, current in groups:
        if len(points):
            dots.extend((point, color, current) for point in project(points))
    for (x, y, depth), color, current in sorted(dots, key=lambda item: item[0][2]):
        radius = (1.65 if current else 1.35)*ss
        x, y = x*ss, y*ss
        draw.ellipse((x-radius, y-radius, x+radius, y+radius), fill=color)
    return image.resize(size, Image.Resampling.LANCZOS)


def paste_frame(canvas, frame, box, fraction, response=False):
    image = frame['response'] if response else frame['image']
    width, height = box[2]-box[0], box[3]-box[1]
    canvas.paste(image.resize((width, height), Image.Resampling.LANCZOS), box[:2])
    draw = ImageDraw.Draw(canvas)
    cutoff = 5+149*fraction
    shown = frame['uv'][frame['uv'][:, 0] <= cutoff]
    if response:
        for u, v in shown:
            x, y = box[0]+(u+.5)/160*width, box[1]+(v+.5)/120*height
            draw.ellipse((x-1.35, y-1.35, x+1.35, y+1.35), fill=GOLD)
    if fraction < 1:
        x = box[0]+(cutoff+.5)/160*width
        draw.line((x, box[1], x, box[3]), fill=GOLD, width=1)
    return int(len(shown)), cutoff


def hero_frames(painter, metrics, frames, scratch):
    directory = scratch/'hero-frames'; directory.mkdir(parents=True, exist_ok=True)
    trace = []
    for scene_index, scene in enumerate(SCENES):
        source = [frames[f'{scene}-{i:02}'] for i in range(5)]
        full = np.concatenate([f['xyz'] for f in source])
        settings = setup_cloud(full, 364, 228)
        for step in range(50):
            orbit = step >= 30
            view = 4 if orbit else step//6
            fraction = 1. if orbit else (step%6+1)/6
            shown = source[view]['uv'][:, 0] <= 5+149*fraction
            groups = [(source[i]['xyz'], (65+8*i, 153+8*i, 187+7*i), False) for i in range(view)]
            groups += [(source[view]['xyz'][shown], GOLD, True)]
            count = sum(len(p) for p, _, _ in groups)
            yaw = -.48+1.34*(step-30)/19 if orbit else -.48
            canvas = Image.new('RGB', (W, H), BG); draw = ImageDraw.Draw(canvas)
            painter.text(draw, (24, 20), 'Freehand Laser Scanning', 36, bold=True)
            draw.rounded_rectangle((779, 27, 976, 58), radius=7, fill='#1e3946')
            painter.center(draw, (779, 33, 976, 58), 'SYNTHETIC REPLAY', 16, TEAL, True)
            painter.text(draw, (24, 72), 'From camera pixels to a 3D point cloud', 22, MUTED)
            for j, name in enumerate(SCENES):
                left = 24+j*180
                draw.rounded_rectangle((left, 115, left+164, 151), radius=8, fill='#23454f' if j == scene_index else CARD)
                painter.center(draw, (left, 122, left+164, 151), TITLES[name], 19, TEXT if j == scene_index else MUTED, j == scene_index)
            status = 'INSPECT THE CLOUD' if orbit else f'VIEW {view+1} / 5'
            painter.text(draw, (690, 123), status, 18, GOLD if orbit else MUTED, True)
            for left, right, title in [(24, 290, '1  Camera frame'), (306, 572, '2  Laser ridge'), (588, 976, '3  Accumulate in 3D')]:
                draw.rounded_rectangle((left, 176, right, 475), radius=12, fill=CARD, outline=BORDER)
                painter.text(draw, (left+12, 190), title, 22, bold=True)
            n, cutoff = paste_frame(canvas, source[view], (36, 239, 278, 421), fraction)
            paste_frame(canvas, source[view], (318, 239, 560, 421), fraction, response=True)
            painter.text(draw, (36, 440), '160 x 120 input PNG', 17, MUTED)
            painter.text(draw, (318, 440), 'Response + subpixel peaks', 17, MUTED)
            canvas.paste(cloud_image(groups, settings, yaw), (600, 230))
            draw = ImageDraw.Draw(canvas)
            draw.ellipse((606, 452, 614, 460), fill=TEAL); painter.text(draw, (621, 448), 'earlier views', 15, MUTED)
            draw.ellipse((790, 452, 798, 460), fill=GOLD); painter.text(draw, (805, 448), 'current view', 15, MUTED)
            # Visible source-view progress, independent of presentation FPS.
            for k in range(5):
                x = 36+k*48
                draw.rounded_rectangle((x, 429, x+40, 432), radius=1, fill=TEAL if k < view else GOLD if k == view else BORDER)
            painter.text(draw, (24, 503), 'Extract. Triangulate. Accumulate.', 26, bold=True)
            painter.text(draw, (24, 543), 'Calibrated laser plane + supplied camera poses', 19, MUTED)
            painter.text(draw, (605, 497), f'{count:,} reconstructed points', 24, GOLD, True)
            if orbit:
                rmse = metrics['scenes'][scene]['surface_rmse_mm']
                painter.text(draw, (605, 532), f'{rmse:.2f} mm surface RMSE', 20, MUTED)
            else:
                painter.text(draw, (605, 532), 'Adding the current source view', 19, MUTED)
            painter.text(draw, (24, 577), 'Synthetic software result; colors identify views. Cursor reveals existing samples, not new camera frames.', 14, MUTED)
            index = scene_index*50+step
            canvas.save(directory/f'{index:03}.png')
            trace.append({'frame': index, 'scene': scene, 'source_id': source[view]['spec']['id'],
                          'source_png_sha256': source[view]['spec']['sha256'], 'presentation_fraction': fraction,
                          'cutoff_column': cutoff, 'visible_current_points': n, 'accumulated_points': count,
                          'orthographic_yaw_radians': yaw, 'metric_visible': orbit})
    return directory, trace


def encode(directory, output, duration, colors=128):
    seconds = 150*duration/1000
    palette = directory.parent/(directory.name+'-palette.png')
    subprocess.run(['ffmpeg', '-y', '-v', 'error', '-framerate', f'1000/{duration}', '-t', str(seconds), '-i', str(directory/'%03d.png'),
                    '-vf', f'palettegen=max_colors={colors}:stats_mode=diff', '-frames:v', '1', str(palette)], check=True)
    subprocess.run(['ffmpeg', '-y', '-v', 'error', '-framerate', f'1000/{duration}', '-t', str(seconds), '-i', str(directory/'%03d.png'), '-i', str(palette),
                    '-lavfi', 'paletteuse=dither=bayer:bayer_scale=3:diff_mode=rectangle', '-loop', '0', str(output)], check=True)


def inspect_gif(path, scratch):
    decoded = scratch/'decoded'; decoded.mkdir(exist_ok=True)
    gif = Image.open(path)
    hashes, durations = [], []
    chosen = [0, 8, 23, 32, 49, 50, 73, 91, 99, 100, 123, 141, 149]
    sheet = Image.new('RGB', (4*350, 4*232), '#f5f7f8')
    draw = ImageDraw.Draw(sheet)
    for i, frame in enumerate(ImageSequence.Iterator(gif)):
        rgb = frame.convert('RGB')
        hashes.append(hashlib.sha256(rgb.tobytes()).hexdigest())
        durations.append(frame.info.get('duration', 0))
        if i in chosen:
            rgb.save(decoded/f'{i:03}.png')
            j = chosen.index(i)
            thumb = rgb.resize((350, 210), Image.Resampling.LANCZOS)
            sheet.paste(thumb, ((j%4)*350, (j//4)*232))
            draw.text(((j%4)*350+6, (j//4)*232+212), f'frame {i:03} / {i*DURATION/1000:.2f}s', fill='black')
    sheet.save(scratch/'hero-contactsheet.png')
    return {'width': gif.width, 'height': gif.height, 'frames': len(hashes), 'duration_ms': sum(durations),
            'unique_decoded_frames': len(set(hashes)), 'loop': gif.info.get('loop'),
            'frame_duration_ms_values': sorted(set(durations)), 'byte_count': path.stat().st_size,
            'sha256': sha(path), 'decoded_rgb_sha256': hashes}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--scratch', type=Path, required=True, help='Native scratch directory for bounded PNG frames and contact sheet')
    parser.add_argument('--output', type=Path, default=ROOT/'media')
    parser.add_argument('--font-regular', type=Path)
    parser.add_argument('--font-bold', type=Path)
    args = parser.parse_args()
    args.scratch.mkdir(parents=True, exist_ok=True); args.output.mkdir(parents=True, exist_ok=True)
    regular, bold = args.font_regular or locate_font(), args.font_bold or locate_font(True)
    sequence, metrics, frames = load_data()
    folder, trace = hero_frames(Painter(regular, bold), metrics, frames, args.scratch)
    output = args.output/'freehand-laser-demo.gif'
    encode(folder, output, DURATION)
    result = inspect_gif(output, args.scratch)
    assert result['frames'] == 150 and result['duration_ms'] == 12000 and result['unique_decoded_frames'] == 150
    assert result['loop'] == 0 and result['byte_count'] <= 5_000_000
    Image.open(args.scratch/'decoded/091.png').save(args.output/'freehand-laser-poster.png')
    trace_path = args.output/'frame-provenance.json'; trace_path.write_text(json.dumps(trace, indent=2)+'\n')
    sources = ['scripts/render_demo.py', 'updated/laser.py', 'updated/fixtures/sequence.json', 'updated/artifacts/desktop-points.json', 'updated/artifacts/metrics.json']
    inputs = {name: sha(ROOT/name) for name in sources}
    inputs.update({'updated/fixtures/'+f['file']: f['sha256'] for f in sequence['scans'] if not f['distractor']})
    report = {'schema': 1, 'scope': 'Deterministic presentation of actual synthetic inputs and stored reconstruction output; no numerical/core/app changes',
              'environment': {'python': platform.python_version(), 'numpy': np.__version__, 'scipy': scipy.__version__, 'pillow': PIL.__version__,
                              'ffmpeg': subprocess.check_output(['ffmpeg', '-version'], text=True).splitlines()[0]},
              'fonts': [{'name': p.name, 'sha256': sha(p)} for p in (regular, bold)],
              'input_sha256': inputs, 'hero': result, 'frame_provenance_sha256': sha(trace_path),
              'poster_sha256': sha(args.output/'freehand-laser-poster.png'),
              'presentation': {'views_per_scene': 5, 'scenes': list(SCENES), 'point_sets': 'Existing per-frame XYZ samples only; no interpolated point positions',
                               'cursor': 'Reveals columns of an existing source frame; it is not sensor FPS', 'camera': 'Orthographic display orbit; stored coordinates unchanged',
                               'colors': 'Current source view gold, earlier views teal; not photometric texture',
                               'metrics': 'Full-scene surface RMSE shown only after all five source views are present'},
              'checks': {'all_input_png_hashes_match': True, 'decoded_all_frames': True, 'dimensions_frames_timing_loop_and_size_pass': True},
              'inspection': 'Contact sheet and decoded frames written to scratch; visual review required separately'}
    (args.output/'validation.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps({k: v for k, v in result.items() if k != 'decoded_rgb_sha256'}, indent=2))

if __name__ == '__main__': main()
