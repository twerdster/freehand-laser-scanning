# Freehand Laser Scanning Using Mobile Phone

A smartphone and a cheap line laser become a handheld 3D scanner. The laser is rigidly attached to the phone: find its stripe in the camera image, intersect each pixel ray with the calibrated laser plane, then use the phone’s pose to combine the resulting points in world coordinates.

**Ron Slossberg, Aaron Wetzler and Ron Kimmel · BMVC 2015**

[Paper](https://www.bmva-archive.org.uk/bmvc/2015/papers/paper088/paper088.pdf) · [DOI](https://doi.org/10.5244/C.29.88) · [Original demonstration](https://www.youtube.com/watch?v=_Nr1Jh4NsFs)

![Synthetic camera frames become detected laser ridges and accumulated 3D point clouds](media/freehand-laser-demo.gif)

**New synthetic replay:** actual input PNGs, computed subpixel ridges and reconstructed points for a plane, sphere and folded surface. Camera poses are supplied. Gold marks the current view; teal marks earlier views. The display orbit changes only the viewpoint. [Animation details and reproducible script](media/README.md).

## How it works

1. **Find the stripe.** Paired Gaussian-derivative filters at several scales and orientations detect bright ridges. A five-sample cubic fit refines each center to subpixel precision.
2. **Recover depth.** Observations of a flat calibration board determine the laser plane relative to the camera. A detected pixel’s camera ray intersects that plane at a 3D point.
3. **Combine views.** Camera poses place each new line into the same world frame. The paper’s system also obtains surface color by reprojecting points into earlier images, before the laser illuminated them.

## Try it

Python 3.12+; run from the repository root:

```sh
python3 -m venv .venv
.venv/bin/pip install -r updated/requirements.txt
.venv/bin/python -m updated.run_simulation
.venv/bin/python -m updated.run_checks
```

The [runnable guide](updated/README.md) covers outputs, portable Python-only checks and the tested unsigned iOS simulator app. The app computes from source PNGs and poses. The [synthetic metrics](updated/artifacts/metrics.json) give surface RMSE of **2.82 / 2.03 / 2.70 mm** for the three scenes; a bright non-laser ridge produces **744 mm** error. Supplied poses, ideal camera geometry and synthetic images limit these results; they do not measure hardware accuracy.

The **paper’s separate experiments** report 4.48 and 2.25 mm RMSE for two front-side scans, after ICP alignment to reference models, using an iPhone 5s at roughly one metre and 720p. The original capture app depends on SDK components and resources excluded or missing here; live scanning and the paper’s benchmarks have not been reproduced here.

## Explore

- [Runnable stages, fixtures, plots and PLY clouds](updated/README.md)
- [Original MATLAB experiments](matlab/experiments/) and [iOS implementation](ios/Scanner/)
- [Source history/provenance](docs/PROVENANCE.md), [build limits](docs/DEPENDENCIES.md) and [validation](docs/VALIDATION.md)

Licensing is per component: the new adapter is [MIT](updated/LICENSE); historical code keeps its original terms. See [NOTICE](NOTICE.md).

```bibtex
@inproceedings{Slossberg2015Freehand,
  author = {Ron Slossberg and Aaron Wetzler and Ron Kimmel},
  title = {Freehand Laser Scanning Using Mobile Phone},
  booktitle = {Proceedings of the British Machine Vision Conference},
  year = {2015},
  pages = {88.1--88.10},
  doi = {10.5244/C.29.88}
}
```
