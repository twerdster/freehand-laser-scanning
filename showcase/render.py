"""Animate actual image/ridge/XYZ scan outputs; no mesh is loaded by this renderer.

The presentation samples a 360-view sequence, then orbits the complete computed
cloud. The orbit, height colors and playback speed are display choices only.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import platform
import subprocess

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageSequence
import PIL

ROOT = Path(__file__).resolve().parent
W, H, DURATION = 1100, 650, 80
BUILD, ORBIT = 96, 48
BG, CARD = '#0a1420', '#101f2e'
TEXT, MUTED = '#edf5f7', '#a9becb'
TEAL, GOLD = (74, 213, 195), (255, 191, 97)


def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()


def font_path(bold=False):
    names = ['/System/Library/Fonts/Supplemental/Arial Bold.ttf' if bold else '/System/Library/Fonts/Supplemental/Arial.ttf',
             '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf' if bold else '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf']
    return next(Path(p) for p in names if Path(p).is_file())


class Painter:
    def __init__(self): self.fonts = {}
    def text(self, draw, xy, value, size=20, fill=TEXT, bold=False):
        key = (size, bold)
        if key not in self.fonts: self.fonts[key] = ImageFont.truetype(str(font_path(bold)), size)
        draw.text(xy, value, fill=fill, font=self.fonts[key])


def project(points, yaw, pitch=.20):
    right = np.array([math.cos(yaw), 0, -math.sin(yaw)])
    toward = np.array([math.sin(yaw)*math.cos(pitch), math.sin(pitch), math.cos(yaw)*math.cos(pitch)])
    up = np.cross(toward, right)
    return np.asarray(points) @ np.column_stack((right, up, toward))


def cloud(points, view, through, yaw, size=(654, 390)):
    # Fixed object-centered framing through all accumulation/orbit stages.
    # No truth mesh, smoothing, hole filling, meshing or new XYZ samples.
    selected = view <= through
    xyz = points[selected]
    ids = view[selected]
    q = project(xyz-np.array([0, .175, 0]), yaw)
    scale = 900.
    px = np.rint(size[0]/2+q[:, 0]*scale).astype(int)
    py = np.rint(size[1]/2-q[:, 1]*scale).astype(int)
    # Height and depth are visualization attributes, not recovered material color.
    h = np.clip(xyz[:, 1]/.35, 0, 1)
    colors = np.column_stack((45+70*h, 160+65*h, 205-55*h))
    light = .65+.35*np.clip((q[:, 2]+.24)/.48, 0, 1)
    colors = np.uint8(colors*light[:, None])
    colors[ids == through] = GOLD
    image = Image.new('RGB', size, CARD)
    draw = ImageDraw.Draw(image)
    # Sort far-to-near so a front point covers a back point; fixed 2px marks.
    for i in np.argsort(q[:, 2], kind='stable'):
        x, y = px[i], py[i]
        if 0 <= x < size[0] and 0 <= y < size[1]:
            draw.rectangle((x, y, x+1, y+1), fill=tuple(colors[i]))
    outside = int(np.count_nonzero((px < 0) | (px >= size[0]) | (py < 0) | (py >= size[1])))
    return image, outside


def frame(cache, data, metrics, number, painter):
    # Presentation samples traverse all360 views, retaining every earlier XYZ.
    # The final orbit always uses every accepted point.
    if number < BUILD:
        through = min(359, int(round(number*359/(BUILD-1))))
        stage, yaw = 'SWEEP + ACCUMULATE', -.12
        # Empty top/bottom views are real and remain in the source sequence.
        source = through
    else:
        through, source = 359, 36
        stage = 'THE COMPUTED SCAN · DISPLAY ORBIT'
        yaw = -.12+2*math.pi*(number-BUILD)/(ORBIT-1)
    image = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(image)
    painter.text(d, (30, 20), 'A line becomes a 3D scan', 30, bold=True)
    painter.text(d, (30, 59), 'Freehand Laser  /  Stanford Dragon synthetic experiment', 19, MUTED)
    painter.text(d, (30, 108), 'CAMERA PNG + DETECTED RIDGE', 18, TEAL, True)
    painter.text(d, (438, 108), stage, 18, TEAL, True)
    d.rounded_rectangle((20, 139, 416, 551), radius=12, fill=CARD)
    capture = Image.open(cache/'captures'/f'{source:04}.png').convert('RGB')
    capture = capture.resize((384, 288), Image.Resampling.BICUBIC)
    uv = data['uv'][data['view_index'] == source]
    cd = ImageDraw.Draw(capture)
    # Every dot is the actual subpixel ridge used by the reconstruction.
    for u, v in uv:
        x, y = u*1.2, v*1.2
        cd.ellipse((x-1, y-1, x+1, y+1), fill=GOLD)
    image.paste(capture, (26, 150))
    d = ImageDraw.Draw(image)
    view_label = 'View' if number < BUILD else 'Example view'
    painter.text(d, (34, 451), f'{view_label} {source+1:03d}/360  ·  pass {source//60+1}/6', 22, bold=True)
    painter.text(d, (34, 484), f'{len(uv)} subpixel stripe samples', 19, MUTED)
    painter.text(d, (34, 515), 'Camera + laser visibility rendered', 17, MUTED)
    d.rounded_rectangle((432, 139, 1086, 600), radius=12, fill=CARD)
    cloud_image, outside = cloud(data['xyz'], data['view_index'], through, yaw)
    image.paste(cloud_image, (432, 140))
    d = ImageDraw.Draw(image)
    count = int(np.count_nonzero(data['view_index'] <= through))
    painter.text(d, (450, 537), f'{count:,} reconstructed points', 25, bold=True)
    if number < BUILD:
        painter.text(d, (450, 573), 'Gold: current stripe  ·  blue/teal: accumulated', 17, MUTED)
    else:
        painter.text(d, (450, 573), 'All accepted points · no meshing or truth-based trimming', 17, MUTED)
    # Six pass segments show progression without suggesting live sensor frame rate.
    for p in range(6):
        x = 30+p*65
        progress = np.clip((through-p*60+1)/60, 0, 1)
        d.rounded_rectangle((x, 573, x+56, 579), radius=3, fill='#294354')
        if progress > 0: d.rounded_rectangle((x, 573, x+56*progress, 579), radius=3, fill=TEAL)
    painter.text(d, (30, 609), 'Synthetic PNGs + supplied poses  ·  fitted laser plane  ·  unchanged reconstruction core', 18, MUTED)
    provenance = {'index': number, 'source_view': source, 'capture_sha256': sha(cache/'captures'/f'{source:04}.png'),
                  'through_view': through, 'visible_point_count': count, 'yaw_radians': yaw,
                  'stage': stage, 'source_ridge_count': len(uv), 'outside_cloud_display': outside,
                  'outside_source_image': int(np.count_nonzero((uv[:, 0]<0)|(uv[:, 0]>=320)|(uv[:, 1]<0)|(uv[:, 1]>=240)))}
    return image, provenance


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cache', type=Path, required=True)
    parser.add_argument('--scratch', type=Path, required=True)
    parser.add_argument('--output', type=Path, default=ROOT)
    parser.add_argument('--preview', type=int, help='write one full-resolution preview instead of encoding')
    args = parser.parse_args()
    args.scratch.mkdir(parents=True, exist_ok=True); args.output.mkdir(parents=True, exist_ok=True)
    data = dict(np.load(args.cache/'reconstruction.npz', allow_pickle=False))
    metrics = json.loads((args.cache/'metrics.json').read_text())
    assert len(data['camera_to_world']) == 360 and len(data['xyz']) == metrics['points']
    painter = Painter()
    if args.preview is not None:
        image, record = frame(args.cache, data, metrics, args.preview, painter)
        path = args.scratch/f'preview-{args.preview:03}.png'; image.save(path); print(path); return
    provenance = []
    for i in range(BUILD+ORBIT):
        image, record = frame(args.cache, data, metrics, i, painter)
        image.save(args.scratch/f'{i:03}.png')
        provenance.append(record)
    command = ['ffmpeg', '-v', 'error', '-y', '-framerate', '12.5', '-i', str(args.scratch/'%03d.png'),
               '-filter_complex', '[0:v]split[a][b];[a]palettegen=max_colors=64:stats_mode=diff[p];[b][p]paletteuse=dither=none',
               '-loop', '0', str(args.output/'freehand-dragon.gif')]
    subprocess.run(command, check=True)
    poster, _ = frame(args.cache, data, metrics, BUILD+4, painter)
    poster.save(args.output/'freehand-dragon-poster.png')
    gif = Image.open(args.output/'freehand-dragon.gif')
    decoded = [{'index': i, 'duration_ms': f.info.get('duration'), 'rgb_sha256': hashlib.sha256(f.convert('RGB').tobytes()).hexdigest()}
               for i, f in enumerate(ImageSequence.Iterator(gif))]
    duration = (BUILD+ORBIT)*DURATION
    assert len(decoded) == BUILD+ORBIT and sum(f['duration_ms'] for f in decoded) == duration
    assert gif.info.get('loop') == 0 and gif.size == (W, H)
    report = {'schema': 1, 'scope': __doc__, 'size': [W, H], 'frames': len(decoded), 'duration_ms': duration,
              'source_views': 360, 'actual_points': len(data['xyz']), 'loop': 0,
              'gif_bytes': (args.output/'freehand-dragon.gif').stat().st_size,
              'gif_sha256': sha(args.output/'freehand-dragon.gif'), 'poster_sha256': sha(args.output/'freehand-dragon-poster.png'),
              'inputs': {'reconstruction.npz': sha(args.cache/'reconstruction.npz'), 'metrics.json': sha(args.cache/'metrics.json'),
                         'render.py': sha(Path(__file__)), 'font_regular': sha(font_path()), 'font_bold': sha(font_path(True))},
              'environment': {'python': platform.python_version(), 'numpy': np.__version__, 'pillow': PIL.__version__,
                              'ffmpeg': subprocess.run(['ffmpeg', '-version'], capture_output=True, text=True, check=True).stdout.splitlines()[0]},
              'frame_provenance': provenance, 'decoded_frames': decoded,
              'license': 'Stanford asset terms for derived media; new rendering software separately MIT'}
    (args.output/'validation/media.json').parent.mkdir(exist_ok=True)
    (args.output/'validation/media.json').write_text(json.dumps(report, indent=2)+'\n')
    # Contact sheet decoded from final GIF, not the higher quality input PNGs.
    sheet = Image.new('RGB', (W*2, H*3), BG)
    for j, index in enumerate((8, 36, 64, BUILD-1, BUILD+14, BUILD+34)):
        gif.seek(index); sheet.paste(gif.convert('RGB'), (j%2*W, j//2*H))
    sheet.save(args.scratch/'contact-sheet.png')
    print(json.dumps({k: v for k, v in report.items() if k not in ('frame_provenance', 'decoded_frames')}, indent=2))

if __name__ == '__main__': main()
