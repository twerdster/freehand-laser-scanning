# Freehand Laser Scanning Using Mobile Phone

Research code for **Ron Slossberg, Aaron Wetzler, and Ron Kimmel, BMVC 2015**, [DOI: 10.5244/C.29.88](https://doi.org/10.5244/C.29.88). A mobile phone tracks its motion while a rigidly attached line laser sweeps across the scene. Multiscale paired filters locate the stripe; a calibrated laser plane and camera rays recover 3D points in world coordinates. The [paper](https://www.bmva-archive.org.uk/bmvc/2015/papers/paper088/paper088.pdf) and [original demonstration](https://www.youtube.com/watch?v=_Nr1Jh4NsFs) describe the research system.

The recovered historical code is preserved alongside a **runnable adapter and synthetic test application**. The adapter executes extraction, calibration and reconstruction on generated images, with Python and a native iOS simulator replay app. Camera poses are explicitly supplied; the excluded proprietary tracker and historical hardware pipeline are not replaced or claimed to work.

![Generated camera frames, detected laser ridges and paired-filter responses](updated/artifacts/frames-and-response.png)

## Run the reconstruction stages

```sh
python3 -m venv .venv
.venv/bin/pip install -r updated/requirements.txt
.venv/bin/python -m updated.run_simulation
.venv/bin/python -m updated.run_checks
```

The default check command includes macOS Accelerate/native parity and ASan/UBSan execution. On other platforms use `--python-only` to run the portable numerical tests. See [updated/README.md](updated/README.md) for the unsigned simulator build, coordinate conventions, exact adaptations, outputs and limits. The iOS 18.1 simulator app was installed and run; its [2094 computed points match the desktop output](updated/validation/simulator-parity.json).

Six generated calibration views estimate the camera-attached laser plane. Five views each of a sloped plane, sphere and folded surface test reconstruction with image noise and occlusion. A bright non-laser stripe and a pose-timing mismatch expose failure modes. The committed 160×120 fixture contains 22 PNGs and all required metadata; no external data or model is needed. The app computes its point clouds from the PNGs and poses rather than loading a precomputed PLY.

| Synthetic scene | Accepted points | Surface RMSE |
| --- | ---: | ---: |
| Sloped plane | 727 | 2.82 mm |
| Sphere | 489 | 2.03 mm |
| Folded surface | 728 | 2.70 mm |
| Bright non-laser distractor | 150 | 744.43 mm |

These are software simulation results, **not the paper’s measurements or real scanner accuracy**. [Metrics](updated/artifacts/metrics.json) also include continuous true-curve row/Euclidean 3D errors, visible-column precision/recall, false accepted samples without visible truth, and pose sensitivity. All accepted points enter the surface metrics; curve errors retain large mismatches where same-column ground truth exists. [Plots](updated/artifacts/geometry-and-errors.png), a [PLY](updated/artifacts/reconstruction.ply) and [per-frame points](updated/artifacts/desktop-points.json) make the output inspectable.

## Recovered research source

Recovered in November 2026 from the authors’ preserved research backup and historical Git objects. This is the **laser scanning** project; Freehand Voxel Carving is a separate student project.

| Directory | Contents |
| --- | --- |
| [updated](updated/) | Runnable adapted stages, independent synthetic generator, tests, results and native simulator app |
| [matlab/experiments](matlab/experiments/) | Original extraction, calibration geometry, reconstruction experiments and MEX C source |
| [matlab/classifier](matlab/classifier/) | Historical classification cross-validation wrappers |
| [matlab/third_party](matlab/third_party/) | Separately licensed registration, plane-fitting and mesh helpers |
| [ios/Scanner](ios/Scanner/) | Sanitized 2014 iOS sample-derived implementation and its original MIT notice |
| [history/ios](history/ios/) | Selected source/config snapshots from six recovered 2013–2014 commits |
| [history/diskonkey-cpp](history/diskonkey-cpp/) | Separately preserved older C++ variant |

Historical entry points include [lineExtract.m](matlab/experiments/lineExtract.m), [findRealWorldPointLaser.m](matlab/experiments/findRealWorldPointLaser.m) and [PointCloudApplication.mm](ios/Scanner/PointCloudSample/PointCloudApplication.mm). All 181 imported source/config/license instances retain their published hashes. The adapter is separate and documents changed kernels, thresholds, guards and coordinate handling.

An actual unsigned Xcode 16.1 build of the historical app failed on absent resources and also reported obsolete deployment/architecture warnings; further proprietary dependencies remain excluded. MATLAB/Octave and the original recordings/calibration data were unavailable. [Build evidence](docs/BUILD_ATTEMPT_2026-11-15.md), [dependencies](docs/DEPENDENCIES.md) and [validation](docs/VALIDATION.md) distinguish archival checks, the failed historical build and the runnable adapter. No paper benchmark, live capture or physical-device validation is claimed.

The new adapter and generated assets have a [scoped MIT license](updated/LICENSE). Historical files retain their individual terms: the [iOS sample](ios/Scanner/LICENSE) is MIT, Kitware helpers Apache 2.0, and imported MATLAB helpers have their own notices. The PointCloud SDK is not redistributed. See [NOTICE](NOTICE.md), [provenance](docs/PROVENANCE.md), [source manifest](docs/SOURCE_MANIFEST.json) and [adapter source mapping](updated/README.md).

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
