# Source provenance and recovery

This repository preserves source associated with *Freehand Laser Scanning Using Mobile Phone* by Ron Slossberg, Aaron Wetzler, and Ron Kimmel (BMVC 2015; [official proceedings](https://www.bmva-archive.org.uk/bmvc/2015/toc.html), [DOI](https://doi.org/10.5244/C.29.88)). The original demonstration is [available on YouTube](https://www.youtube.com/watch?v=_Nr1Jh4NsFs).

The authors' preserved research folder contained the paper source, MATLAB experiments, classifier experiments, sample videos, and an iOS application based on the 13th Lab PointCloud sample. The recovered paper source identifies the title and all three authors. A separate disk backup retained an older C++ application variant. Private storage paths, cloud identifiers, raw mail, account information, and backup containers are not part of this publication.

## Historical iOS source

The original working tree omitted important files that remained readable as Git blobs. Recovery selected source/config files directly from each sample directory, avoiding an unrelated missing framework subtree. This recovered `PointCloudApplication.mm`, its laser filtering/calibration/reconstruction logic, the application headers, kernels, camera interface, and other integration code.

[HISTORY.json](HISTORY.json) records six original commits with dates, subjects, and selected source filenames. The current `ios/Scanner/` copy corresponds to `0f12c88062bdd1e1b75223a1dd79a0c7de0c554f`, dated 2014-11-02. Earlier snapshots include the 2013 initialization, vImage/kernels changes, April 2014 mathematical fixes, and the November 2014 online-scanner/video changes. These are recovered snapshots rather than a transplanted original Git history: raw history would also carry SDK material, an application key, and user-specific files.

The original repository is incomplete. An integrity audit found one missing tree and six missing blobs, all sharing the object prefix `9d`. The three latest commits reference the missing framework subtree; the three oldest source-tree traversals completed. Every source/config blob selected for this publication was readable. This release does not claim to repair or reproduce the complete original SDK/framework repository.

## Publication edits and integrity

[SOURCE_MANIFEST.json](SOURCE_MANIFEST.json) records each imported file's logical original path, source commit when applicable, original SHA-256, published SHA-256, byte count, and edit categories. Unchanged files have matching hashes. Publication edits are limited to:

1. Replacing embedded SDK application keys with `REPLACE_WITH_YOUR_POINTCLOUD_APPLICATION_KEY` in application source variants.
2. Clearing Xcode signing identity, development-team, and provisioning-profile settings.
3. Replacing machine-specific build paths with a local dependency placeholder.
4. Removing the hardcoded email-export recipient from the older backup variant.

No source is executed by the recovery/verification process. Missing datasets and runtime dependencies are not fabricated. The disk-backup variant is kept separate because it differs from the Git versions.

The scoped `Scanner/LICENSE` and `Scanner/README` explicitly license the sample as MIT. The separately licensed PointCloud SDK header, SDK library, vendor binaries/frameworks, resource packs, raw Git objects, user IDE state, and unrelated backup content are not included. Third-party helpers without a recovered redistribution grant are listed as exclusions. See [NOTICE](../NOTICE.md) and [dependencies](DEPENDENCIES.md).
