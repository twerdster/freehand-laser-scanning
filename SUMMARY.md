# Freehand Laser Scanning: project state

Historical source for Ron Slossberg, Aaron Wetzler, and Ron Kimmel's BMVC 2015 laser-scanning work. Keep this project distinct from Freehand Voxel Carving.

The November 2026 recovery imports MATLAB experiments, classification wrappers, separately licensed MATLAB helpers, a sanitized 2014 iOS MIT sample-derived implementation, six historical source/config snapshots, and a separate older C++ backup variant. Original and published file hashes and edit categories are in docs/SOURCE_MANIFEST.json. Source commit metadata is in docs/HISTORY.json.

The scoped Scanner/LICENSE and Scanner/README explicitly grant MIT rights to the sample. Retain that license in each source snapshot. The root SDK agreement is separate: PointCloud.h, libpointcloud.a, vendor binaries/frameworks, resource packs, raw Git containers, and user IDE metadata stay excluded. Kitware viewer helpers are Apache 2.0; MATLAB helpers retain their own notices, including Mian's research-use restriction. No new blanket repository license is assigned.

The original Git object store lacks one tree and six blobs. All selected source/config blobs were readable. Embedded SDK keys, developer signing settings, private machine paths, and a hardcoded email-export recipient are removed from publication copies. Do not replace sanitized files with raw recovery copies or publish raw history without repeating the review.

Original source bytes and line endings are preserved. `.gitattributes` exempts only the individually listed imported historical files from whitespace diagnostics; documentation and new verification scripts retain normal checks. Published hashes remain authoritative.

Validation: all 18 MATLAB files parsed/linted with MISS_HIT 0.9.44. Source/hash/publication checks and Apple property-list/project parsing are recorded in docs/VALIDATION.md. No MATLAB execution, iOS build, device operation, or scientific reproduction is claimed. See docs/DEPENDENCIES.md for missing input data and dependencies.

The canonical public destination is `twerdster/freehand-laser-scanning` on `main`. The reviewed initial publication contains 181 imported source/config/license instances and the accompanying documentation and offline verifier. Independent audit matched published hashes and available original hashes, confirmed the documented redactions, and found no remaining actionable publication issue. Preserve normal history and verify public content after pushing. Before any commit, review this file and SKILL.md against the final staged contents and update them if scope/status changes. Website links belong in the Freehand Laser publication and Code & Data entry, separately from Freehand Voxel Carving.
