# Attribution and license scope

Research attribution: Ron Slossberg, Aaron Wetzler, and Ron Kimmel, *Freehand Laser Scanning Using Mobile Phone*, BMVC 2015, DOI [10.5244/C.29.88](https://doi.org/10.5244/C.29.88).

Original file notices are retained. This archive does not assign a new blanket software license or imply that the paper's authors own every bundled helper.

- **PointCloud sample-derived application:** the recovered `Scanner/LICENSE` grants MIT rights, copyright 2012 13th Lab AB. `Scanner/README` expressly identifies the sample project as MIT. This scoped sample license accompanies `ios/Scanner/` and every historical sample snapshot. The SDK's separate binary/API/header agreement does not replace the sample's explicit MIT grant. The SDK itself is excluded.
- **Kitware VES viewer helpers:** `MyGestureHandler.h/.mm` and `MyGLKViewController.h/.mm` retain copyright 2011 Kitware, Inc. and Apache License 2.0 notices. The full [Apache 2.0 license](LICENSES/Apache-2.0.txt) is included. No full VES/Kiwi framework is bundled.
- **Dirk-Jan Kroon registration helpers:** `matlab/third_party/kroon/` retains the recovered 2009 two-clause BSD license. `ICP_finite.m`, `movepoints.m`, and the accompanying `fminlbfgs.m` were recovered with that license from the same original package.
- **Peter Kovesi plane fitting:** `ransacfitplane.m` retains its inline permissive notices, including the notices for its local support functions.
- **Ajmal Saeed Mian mesh helper:** `pointCloud2mesh.m` permits research use, modification, and distribution with acknowledgement and its copyright information. That research-use condition is retained; it is not represented as unrestricted open source.
- **Other research scripts and classification wrappers:** retained as historical research source without adding a new license. Third-party helpers without recovered redistribution permission were omitted and listed in the source manifest.

Publication copies replace the embedded SDK application key with an obvious placeholder and clear developer signing identities, team/profile settings, machine-specific build paths, and a hardcoded email-export recipient. These edits do not grant SDK access or establish buildability. Original unmodified recovery evidence remains outside this public repository.

The new `updated/` adapter, simulator, replay app, tests and generated synthetic data have a separate scoped [MIT license](updated/LICENSE), including the original 13th Lab attribution for the sample-derived filter combination. This grant does not relicense any historical source or imported helper outside `updated/`. The adapter uses newly authored kernels, guards and wrappers; its exact differences from the archived implementation are described in [updated/README.md](updated/README.md).

The new explanatory GIF, media documentation and `scripts/render_demo.py` have their own scoped [MIT license](media/LICENSE). They visualize existing synthetic adapter output; no original report figures, real capture photographs, demonstration footage or font files are bundled into that media.

The complex-object `showcase/` software has a separate scoped [MIT license](showcase/LICENSE), with shared mesh helper/recipe/test notices in [HELPER-LICENSE](showcase/HELPER-LICENSE). Its Stanford Dragon source asset, derived camera observations, reconstructed point clouds and new GIF/poster retain [Stanford’s research/free-redistribution terms](showcase/STANFORD-ASSET-TERMS.md), including source acknowledgement and a commercial-permission requirement. They are excluded from the software MIT grants. Stanford University Computer Graphics Laboratory is credited; source archive README, normalized-mesh provenance and checksum-pinned regeneration are included. No new blanket asset license is assigned.
