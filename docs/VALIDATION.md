# Validation records — November 2026

The initial 2026-11-14 source release was checked without executing historical experiments or the iOS application. The separate 2026-11-15 runtime/build work is recorded below.

| Check | Result | Scope |
| --- | --- | --- |
| Imported source integrity | 181 files matched published SHA-256 and size | Every file listed in SOURCE_MANIFEST.json |
| Publication review | Passed | Eight application-key replacements; seven project files with signing settings cleared; five project files with private build paths replaced; one older source with email-export recipient removed |
| Sample-license coverage | Passed | MIT notice retained beside the current sample, all six Git snapshots, and the older C++ backup variant |
| MATLAB parse/lint | All 18 `.m` files passed MISS_HIT 0.9.44 | Syntax/static lint only; no MATLAB/Octave execution |
| Apple configuration parsing | All 14 `.plist`/`.pbxproj` files passed `plutil -lint` | Property-list/project syntax; not an Xcode build |

Historical source whitespace and line endings are retained to preserve provenance; documentation and new verification code receive separate whitespace checks. Git attributes disable line-ending conversion for imported trees.

The Xcode path placeholders are quoted so the sanitized project files remain valid property lists. Original/published hashes make those publication edits explicit. [APPLE_PROJECT_VALIDATION.json](APPLE_PROJECT_VALIDATION.json) records the files parsed.

## Repeat the checks

```sh
python3 scripts/verify_sources.py
python3 -m venv /tmp/freehand-source-check
/tmp/freehand-source-check/bin/pip install miss-hit==0.9.44
/tmp/freehand-source-check/bin/mh_lint --single --ignore-config --brief matlab
find ios history -type f \( -name '*.plist' -o -name '*.pbxproj' \) -exec plutil -lint -- {} \;
```

`verify_sources.py` is a read-only integrity/publication check. It does not import or execute the research programs. MISS_HIT is an independent static parser/linter; a passing result does not establish the correctness of numerical results or availability of data/dependencies.

For the initial source release, no MEX compilation, MATLAB execution, Xcode compilation, signing, device test, live capture or paper-result reproduction was performed. The historical code and required external inputs are described in [DEPENDENCIES.md](DEPENDENCIES.md).


## Adapted software execution — 2026-11-15

The historical unsigned iOS build was actually attempted and **failed**, exit 65; see [exact scope and blockers](BUILD_ATTEMPT_2026-11-15.md). No original MATLAB execution or live camera/laser validation was possible.

The separate [updated adapter](../updated/README.md) ran on independently ray-cast calibration/scan images. [checks.json](../updated/validation/checks.json) records 17 passing tests, all 22 frames through native Accelerate/Python filtering and peak comparisons, full calibration/reconstruction parity, an ASan/UBSan fixture execution with 16 invalid-input and three ray-rejection assertions and no diagnostics, fresh/stored numerical metrics equality, exact package versions and tested source/fixture SHA-256. The native sanitizer harness processes 895 calibration and 2094 scan points, including the deliberately false distractor. These counts describe accepted samples, not ground-truth accuracy.

The new unsigned SwiftUI/SceneKit simulator app built successfully with Xcode 16.1/iOS 18.1 simulator SDK. It was installed and run on an iPhone 16 / iOS 18.1 simulator. [Simulator parity](../updated/validation/simulator-parity.json) matched all 16 scan frames/2094 points to desktop results (maximum world-coordinate difference 8.4e-9 m, ridge-coordinate difference 1.74e-7 px). [UI evidence](../updated/validation/simulator-ui.json) records frame selection, accumulation, distractor warning, framing, button rotation and reset. Drag is implemented but remains unverified by the automation tool; the buttons provide verified rotation. Termination followed by removal of only the app’s generated validation output and a fresh relaunch recreated byte-identical output (SHA-256 recorded in the UI evidence) and passed numerical comparison again. Its compiled C core computes outputs from bundled source PNGs and supplied poses; it does not load the desktop PLY. Synthetic scene metrics, including failure cases and continuous true-curve correspondence errors, are in [metrics.json](../updated/artifacts/metrics.json). They do not reproduce the BMVC benchmark or establish real scanner accuracy.

The 181 imported source/config/license instances still pass their original manifest verifier. Newly authored files remain separately scoped; no archived source was changed to obtain these runtime results.
