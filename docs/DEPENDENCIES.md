# Historical dependencies and build limits

This archive has not been modernized into a standalone app. Read the scripts before running them: several use `clear all`, open plots, read fixed filenames, and write experimental outputs in the working directory.

## MATLAB experiments

The source uses MATLAB image/video processing and statistics facilities, including historical interfaces that may differ in current MATLAB releases. Classification wrappers include `knnclassify` and `NaiveBayes.fit`; cross-validation uses `parfor`. The two C files require MATLAB's MEX headers and toolchain. They have not been compiled here.

A historical path setup is:

```matlab
addpath(genpath('matlab'));
```

This only adds the source paths. It does not supply the required data or missing helpers. `lineExtract.m` expects recorded camera poses and a video; `lineExtractNew.m` expects a recording; `DecisionTreeMain.m` expects training/classification data; `gui.m` also expects its GUIDE figure and recording; registration/postprocessing scripts expect scan files and frame metadata. Those recordings, trained models, GUIDE layout, calibration tables, and scanner outputs are not distributed.

The original decision-tree training/prediction helpers credit Itamar Katz (December 2012), and depend on a separate TreeDataStructure library. No redistribution license was recovered for those files, so the six tree helper files and tree library are omitted. Their callers remain useful as historical experiment structure but are incomplete without separately authorized dependencies.

Other omitted third-party helpers are `quat2dcm.m`, `dcm2quat.m`, `read_ply.m`, `icp.m`, and `rgbtohsi.m`; attribution or purpose was present, but no applicable redistribution grant was recovered. The available Kroon ICP package, Kovesi plane fitting, and Mian mesh helper are included with their own terms. Do not interpret those notices as a license for unrelated helpers.

## iOS application

The historical project targets an early iOS/Xcode environment and uses Objective-C++, OpenGL ES, Accelerate/vImage, OpenCV, and the PointCloud SDK 1.3.1. The viewer helpers also reference VES/Kiwi. These are historical dependency names, not claims of current availability or compatibility.

The sample's MIT source is included. The PointCloud SDK's `PointCloud.h`, `libpointcloud.a`, vendor binary frameworks, third-party framework header trees, image-target models, branding images, and other resource packs are excluded. The Xcode project retains references so the original structure is visible, but those references are unresolved until appropriately licensed dependencies/resources are supplied. Some historical project or resource files may also be missing from the recovered Git tree.

Application-key literals are replaced with an obvious placeholder. Obtain any required SDK authorization independently and configure it only in a private local working copy. Signing identities, teams, and profiles are cleared. Build paths use `$(PROJECT_DIR)/Dependencies` placeholders where they originally referred to a developer's machine. An iOS build and device test require additional configuration and have not been performed.
