# Validation record — 2026-11-14

The source release was checked without executing the historical experiments or iOS application.

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

No MEX compilation, MATLAB execution, Xcode compilation, code signing, device test, live capture, reconstruction benchmark, or reproduction of paper results was performed. The historical code and required external inputs are described in [DEPENDENCIES.md](DEPENDENCIES.md).
