# Freehand Laser Scanning Using Mobile Phone

Historical research code for **Ron Slossberg, Aaron Wetzler, and Ron Kimmel, BMVC 2015**, [DOI: 10.5244/C.29.88](https://doi.org/10.5244/C.29.88). The method combines a mobile phone, a line laser, camera tracking, and multiscale line extraction to reconstruct a colored point cloud. The [BMVC proceedings](https://www.bmva-archive.org.uk/bmvc/2015/toc.html) record the publication; the [original demonstration](https://www.youtube.com/watch?v=_Nr1Jh4NsFs) shows the system.

Recovered in November 2026 from the authors' preserved research backup and historical Git objects. This is the **laser scanning** project. Freehand Voxel Carving is a separate student project.

| Directory | Contents |
| --- | --- |
| [matlab/experiments](matlab/experiments/) | Original laser extraction, calibration geometry, reconstruction experiments, and MATLAB MEX C source |
| [matlab/classifier](matlab/classifier/) | Cross-validation wrappers for historical classification experiments |
| [matlab/third_party](matlab/third_party/) | Separately attributed registration, plane fitting, and mesh helpers with recovered redistribution notices |
| [ios/Scanner](ios/Scanner/) | Sanitized 2014 iOS sample-derived implementation, Xcode project, and its original MIT notice |
| [history/ios](history/ios/) | Selected source/config snapshots from all six recovered 2013–2014 commits |
| [history/diskonkey-cpp](history/diskonkey-cpp/) | A separately preserved older C++ implementation variant |

The most direct entry points are [lineExtract.m](matlab/experiments/lineExtract.m), [findRealWorldPointLaser.m](matlab/experiments/findRealWorldPointLaser.m), and [PointCloudApplication.mm](ios/Scanner/PointCloudSample/PointCloudApplication.mm). Their historical behavior is preserved; no modern algorithm port is claimed.

Read [dependencies and build limits](docs/DEPENDENCIES.md) before trying the experiments. Historical recordings, calibration/training data, some helpers, proprietary SDK components, and some iOS resources are not included. This is an archival source release, not a standalone reproducible app or benchmark.

The iOS sample is explicitly MIT licensed in its [original scoped LICENSE](ios/Scanner/LICENSE) and [sample README](ios/Scanner/README). Its PointCloud SDK dependency has separate terms and is not redistributed here. Kitware viewer files retain Apache 2.0 notices; other imported helpers retain their individual terms. See [NOTICE](NOTICE.md). No new blanket license is applied to the research code.

See [provenance](docs/PROVENANCE.md), [source hashes and publication edits](docs/SOURCE_MANIFEST.json), and [validation](docs/VALIDATION.md). Static checks parsed all 18 MATLAB files and verified source hashes and sanitized project files. MATLAB execution, iOS compilation, hardware operation, and the paper's reported results have not been revalidated.

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
