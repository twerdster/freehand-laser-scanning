# Freehand Laser Scanning maintenance

Read SUMMARY.md, README.md, NOTICE.md, and docs/PROVENANCE.md before making project changes. This repository archives laser scanning research source, not Freehand Voxel Carving.

## Source policy

Preserve historical source and author notices. Keep meaningful versions in history/ separate from the current archived iOS source. Imported file provenance belongs in docs/SOURCE_MANIFEST.json with logical relative origins, original/published SHA-256, and exact edit categories. Never add private backup paths, account identifiers, email/message metadata, raw mail/archives, signing material, application keys, or user IDE state.

The PointCloud sample under Scanner/ has its own MIT license; retain it in each snapshot. The separate proprietary SDK header/library and vendor dependencies are not covered by that sample grant and remain excluded. Preserve Kitware's Apache 2.0 notices and the full license, Kroon's BSD notice, Kovesi's inline notices, and Mian's research-use terms. Do not add a blanket license or import omitted third-party helpers without a matching grant.

## Verification

Preserve imported source bytes, including historical whitespace and line endings. `.gitattributes` disables line-ending conversion for imported trees and lists exact archived files exempt from whitespace diagnostics. Do not broaden those exceptions to documentation, new scripts, or new source. Keep normal whitespace checks for newly authored files.

Run `python3 scripts/verify_sources.py` after source changes. It reads source/config/manifest files without executing research code. Parse all `.m` files with MISS_HIT 0.9.44 when changing MATLAB source; use a task-scoped environment. Parse `.plist`/`.pbxproj` files with Apple `plutil -lint` when changing iOS project configuration. Record exact scope/results in docs/VALIDATION.md.

Archival scripts expect historical external data and may write outputs or clear MATLAB workspace state. Do not run them as a routine smoke test. A successful parser/hash check is not a claim of MATLAB execution, iOS buildability, hardware validation, or benchmark reproduction.

Before every commit, review SUMMARY.md and this file and explicitly update both or record why no update is needed. Keep publication status and validation statements accurate. Use `twerdster/freehand-laser-scanning` and its `main` branch as the canonical repository. Verify a permitted account before publishing, preserve normal history, and read back the public commit and source tree after pushing. Link the repository from the Freehand Laser publication and Code & Data entry only after that readback.
