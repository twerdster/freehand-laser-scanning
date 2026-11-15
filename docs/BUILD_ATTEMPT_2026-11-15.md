# Historical app build attempt and runnable adapter

On 2026-11-15, Xcode 16.1 (16B40) successfully listed the recovered `PointCloudSample` target/scheme. An actual unsigned generic iOS build was attempted, without editing the archived source or project:

```sh
xcodebuild -project ios/Scanner/PointCloudSample.xcodeproj \
  -scheme PointCloudSample -configuration Debug -sdk iphoneos \
  -destination 'generic/platform=iOS' -derivedDataPath <private-native-scratch> \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= \
  DEVELOPMENT_TEAM= ARCHS=arm64 ONLY_ACTIVE_ARCH=YES build
```

It exited **65 (`BUILD FAILED`)**. The observed build failures are absent resource inputs: `Resources/image_target_1.model`, `image_target_2.model`, `image_target_poster.model`, `ui.png`, `trackpoint.png`, `pointcloud-logo.png`, the old Icon/Default PNG variants, `PointCloudSample/fromPhone.ply`, and `PointCloudSample/en.lproj/InfoPlist.strings`. It also warned that deployment target 6.0 is outside the SDK’s supported range and arm64 does not match the project’s historical `VALID_ARCHS` (`armv7`, `armv7s`). This attempt did not reach a successful application compilation or link. No signing, provisioning or account operation was used.

Inspection separately establishes that the PointCloud SDK header/library, vendor frameworks, training assets and other dependencies listed in [DEPENDENCIES.md](DEPENDENCIES.md) are excluded or absent. Resource failures are not evidence that restoring those files alone would make this decade-old app build. No SDK replacement, fabricated camera tracker or speculative dependency download was used. Full build logs and DerivedData remain outside the public repository because they contain machine paths.

MATLAB/Octave was unavailable on the validation machine, and the historical recordings/calibration data/helpers remain missing. No original MATLAB script or MEX was executed. The previous static parse results remain valid and are separately scoped.

A new [adapted test path](../updated/README.md) reuses the recovered mathematical stages, supplies explicit synthetic poses and generates calibration/scan images independently. Its Python software tests, native Accelerate execution, sanitizer run and unsigned simulator build are recorded in `updated/validation/`. These results do not change the historical application’s failed build status or reproduce the paper’s measurements. All 181 imported source/config/license instances remain byte-for-byte at their published hashes.
