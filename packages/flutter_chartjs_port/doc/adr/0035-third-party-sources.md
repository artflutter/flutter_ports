# Chart.js ADR 0035: Third-party sources

- Status: accepted (2026-10-21)
- Date: 2026-10-21
- Supersedes: [Chart.js ADR 0011](0011-third-party-sources.md)
- Related: [ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md) (the pin of each
  upstream), [ADR 0006](../../../../docs/adr/0006-follow-upstream-between-releases.md) (the
  commit pin), [Chart.js ADR 0032](0032-js-numeric-semantics.md) (the fdlibm ports, the reference
  engine), [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) (no pixelmatch),
  [Chart.js ADR 0026](0026-number-formatting-on-package-intl.md) (no ICU),
  [Chart.js ADR 0015](0015-text.md) (the test font),
  [upstream-tracking.md](../upstream-tracking.md) §2.4 and §5 (the commit pin, the bump
  procedure)

## Context

[ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md) pins the upstream of each port as a
reference-only shallow submodule under `third_party/`. The Chart.js port also translates code from
three other projects:

| Project | Version | License, holder | What the port takes |
|---|---|---|---|
| `@kurkle/color` | 0.3.2 | MIT, Jukka Kurkela | the color library that `helpers.color.ts` wraps |
| chartjs-test-utils | 0.4.0 | MIT, chartjs-test-utils Contributors | the spec harness |
| fdlibm | 5.3 | SunPro, Sun Microsystems, Inc. | `Math.log10`, `Math.atan2`, `Math.sin` and `Math.cos` |

Chart.js ADR 0005 gave the first list, with pixelmatch 5.3.0. Chart.js ADR 0011 (accepted
2026-10-19) superseded it without pixelmatch: Chart.js ADR 0009 removed the image comparison, and
Chart.js ADR 0008 removed the ICU code. Since then, three facts changed:
- ADR 0006 allows a commit pin in a release drought. On 2026-10-20, the Chart.js submodule
  moved from the tag `v4.5.1` to the commit pin `7169e651`. This commit was the newest `master`
  commit with green upstream CI ([upstream-tracking.md](../upstream-tracking.md) §2.4). The tag
  `v4.5.1` is commit `9c5cf9f`.
- Chart.js ADR 0032 ports `Math.sin` and `Math.cos` from fdlibm 5.3. It adds seven netlib files
  and `fdlibm_trig.dart`. The fdlibm entry of `port_sources.yaml`, the `REUSE.toml` table of the
  fdlibm Dart ports and the fdlibm component of the package `LICENSE` list them.
- The harness has a test font, Liberation Sans 2.1.5 (SIL OFL 1.1, Chart.js ADR 0015). The font
  files are unchanged, so they are not ported code.

This ADR states the complete current decision. It supersedes Chart.js ADR 0011. Its Decision
keeps the item numbers of Chart.js ADR 0011.

**Versions.** The lockfile of Chart.js at the pin selects the versions:
- `@kurkle/color`: `^0.3.0` in `package.json`, locked to 0.3.2 in `pnpm-lock.yaml`. npm resolves
  `^0.3.0` to 0.3.4 now.
- chartjs-test-utils: `^0.4.0` in `package.json`, locked to 0.4.0. chartjs-test-utils v1.0.0
  (2026-10-11) uses Vitest and pixelmatch 7.

fdlibm has no git repository. netlib serves its files.

**Notices.** The license files at the two tags have these copyright lines:
- `Copyright (c) 2018-2021 Jukka Kurkela` (`LICENSE.md` at `v0.3.2`)
- `Copyright (c) 2020 chartjs-test-utils Contributors`

The fdlibm files carry `Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.` and
the SunPro permission notice.

**Dev-time use.** Tool 4 (the upstream manifest) runs the `describe` bodies of the upstream specs
in a Node.js `vm`. The reference generators run JS builtins and a build of Chart.js at the pin in
Node.js.

**Other ports.** The D3 port pins 34 submodules in its own
`packages/flutter_d3_port/tool/port_sources.yaml` (D3 ADR 0001). This ADR does not cover them.

## Decision

1. **Submodules.** Each source with a git repository is a reference-only shallow submodule:

   | Path | Project | Pin | Commit |
   |---|---|---|---|
   | `third_party/Chart.js` | Chart.js | the commit pin `v4.5.1+7169e651` | `7169e65147a47f3720957a6f156a33c838ab9f57` |
   | `third_party/kurkle-color` | `@kurkle/color` | the tag `v0.3.2` | `eb0d1db` |
   | `third_party/chartjs-test-utils` | chartjs-test-utils | the tag `v0.4.0` | `8c02987` |

   - `.gitmodules` lists these submodules, each with `shallow = true`. The analysis excludes them
     (`third_party/**` in `analysis_options.yaml`). `dart run melos run upstream` clones every
     `third_party` submodule at its pin, at depth 1.
   - A Chart.js release pin is the tag `v<version>`. A Chart.js commit pin is a full commit after
     the last release. Its version is `<last version>+<sha8>`, for example `4.5.1+7169e651`.
     `chartJsVersion` holds this version, and each header names `v<last version>+<sha8>`. The
     gitlink must start with `<sha8>`, and the tag `v<last version>` must exist. The gitlink must
     not be the commit of the tag `v<last version>`, because a pin at the tag commit is a release
     pin. `Chart.version`
     stays the version of `package.json` (`chartJsPackageVersion`). The next release tag ends the
     commit pin.
2. **Copies.** A source without a git repository is a reference-only copy of its release files in
   `third_party/<name>/`. The copy stays unchanged. `third_party/fdlibm/` holds these netlib
   fdlibm 5.3 files, and no other file: `e_log.c`, `e_log10.c`, `s_atan.c`, `e_atan2.c`,
   `s_sin.c`, `s_cos.c`, `k_sin.c`, `k_cos.c`, `e_rem_pio2.c`, `k_rem_pio2.c` and `s_scalbn.c`.
   The copies are part of this tree. Thus `REUSE.toml` annotates them.
3. **Source list.** `packages/flutter_chartjs_port/tool/port_sources.yaml` has one entry for each
   project: Chart.js, fdlibm, `@kurkle/color` and chartjs-test-utils. An entry holds the header
   name, the version, the source of that version, the URL, the language, the SPDX ID, the holder,
   the pin, the Dart targets and the source files at the pin.
   - For a submodule, the pin has a `ref` and a `commit`. For a tag pin, `ref` is the tag. For a
     commit pin, `ref` and `commit` are both the full commit, because a branch name moves.
   - Tool 2 (`check:headers`) compares each `// Ported from` header with this file, the `LICENSE`
     of the package that contains the file and `REUSE.toml`. It reports an older header version
     as stale and another commit of the same release as an error. It also compares each submodule
     gitlink with the `commit` of its entry.
   - Tool 3 (`check:js-semantics`) examines the files whose header names a `js` project of this
     file.
4. **Targets.**

   | Project | Dart target |
   |---|---|
   | Chart.js | `src/` to `packages/flutter_chartjs_port/lib/src/`, `test/specs/` to `test/specs/`, `test/fixtures/` to `test/fixtures/hand/`, `test/index.js` to `test/flutter_test_config.dart` |
   | `@kurkle/color` | `src/` to `packages/flutter_chartjs_port/lib/src/kurkle_color/`, `packed.js` to `lib/src/kurkle_color/packed.dart`, `test/index.js` to `test/kurkle_color/index_test.dart` |
   | chartjs-test-utils | `src/` to `packages/chartjs_test_utils/lib/src/` |
   | fdlibm | `e_log.c` and `e_log10.c` to `packages/flutter_chartjs_port/lib/src/js/fdlibm_log.dart`, `s_atan.c` and `e_atan2.c` to `fdlibm_atan.dart`, and `s_sin.c`, `s_cos.c`, `k_sin.c`, `k_cos.c`, `e_rem_pio2.c`, `k_rem_pio2.c` and `s_scalbn.c` to `fdlibm_trig.dart` |

5. **Versions follow Chart.js.** A submodule moves only in a Chart.js bump PR. `@kurkle/color` and
   chartjs-test-utils move to the versions that the new Chart.js lockfile selects
   ([upstream-tracking.md](../upstream-tracking.md) §5).
   - A bump to a tag or to a commit pin updates the gitlink and `chartJsVersion` in the same
     change. It also updates the Chart.js `version`, `ref` and `commit` of `port_sources.yaml`.
   - A move of `@kurkle/color` or chartjs-test-utils updates the gitlink and the `version`,
     `ref`, `commit` and `version_source` of its entry in the same change. It also restamps the
     headers of its ports.
   - fdlibm stays at 5.3 while the reference engine computes these builtins with fdlibm 5.3 code.
     The reference engine is V8 in the x64 build of Node.js v24.12.0.
6. **Licensing.** AGENTS.md Licensing applies to each source. The notice is the copyright line of
   the license file at the pin.
   - `packages/flutter_chartjs_port/LICENSE` has the MIT text with the lines of Chart.js Contributors,
     Jukka Kurkela and the port. It has the fdlibm 5.3 notice as a separate SunPro component. That
     component names the three fdlibm Dart files and the eleven C files.
   - `packages/chartjs_test_utils/LICENSE` has the MIT text with the lines of chartjs-test-utils
     Contributors and the port. It has the OFL-1.1 notice of the test font as a separate
     component.
   - `LICENSES/` holds `MIT.txt` and `SunPro.txt` for the port, and `OFL-1.1.txt` for the test
     font. The Chart.js port and its harness need no ISC and no Unicode-3.0 text. The other files
     of `LICENSES/` are for the gallery icons (`BSD-3-Clause.txt`) and the D3 port (`ISC.txt`).
   - `REUSE.toml` has a table for the package, for the harness, for `third_party/fdlibm/**`, for
     the three fdlibm Dart ports, for the `@kurkle/color` port and for the test font. The last
     matching table wins. Thus each table lists every holder of its paths.
7. **Reference only.** These rules apply to each source, submodule or copy:
   - Dart code never imports a reference source.
   - No tool builds a reference source inside `third_party/`. A tool that needs a built upstream
     builds it in a throwaway clone outside the repository, at the pinned commit.
   - No package ships a reference source. A published archive contains no `third_party/` file.
   - `reuse lint` does not examine the submodules, because they are not part of this tree. A copy
     is part of the tree, so `REUSE.toml` annotates it (item 2).
   - Dev-time tools can read and evaluate reference sources, for example the specs, the
     JavaScript code and the fixture files. The upstream manifest tool records the hash of each
     fixture config and PNG. No tool compares pixels with these PNGs.
8. **New sources.** Code from a project that is not in the list needs these parts in the same
   change:
   - an entry in `port_sources.yaml`
   - its notice in the package `LICENSE`
   - a `REUSE.toml` table
   - the header of AGENTS.md rule 2

   A source with a git repository also needs a submodule. Never copy code from GPL or otherwise
   incompatible projects.

## Alternatives considered

- **The newest releases** (`@kurkle/color` 0.3.4, chartjs-test-utils 1.0.0). Rejected. The
  Chart.js lockfile at the pin locks the older versions. Its specs and fixture thresholds come
  from them.
- **Only release tags for Chart.js.** Rejected (ADR 0006). Without a new tag, the improvements on
  `master` wait for an unknown time. The started modules then need a second port.
- **V8's `ieee754.cc` as the fdlibm source.** Rejected. It adds a V8 BSD notice. The netlib files
  give the same bits under the fdlibm notice only.
- **The glibc trig code of Chrome as the source of `sin` and `cos`.** Rejected. It is LGPL-2.1,
  and Node.js does not use it.
- **Flutter `Color` and `Color.lerp` instead of a port of `@kurkle/color`.** Rejected. A color
  transition calls `mix`, which weights the two colors by their alpha difference and rounds each
  channel to a byte. `Color.lerp` interpolates each channel linearly, with no weight and no
  rounding. Chart.js also parses CSS color strings, and eight spec files compare color strings.
- **A pixelmatch port for an image comparison against the upstream PNGs.** Rejected (Chart.js ADR
  0034). It needs an ISC notice, a ledger of one row for each fixture PNG (667 at the pin) and
  a fixtures job pinned to the Skia renderer on Linux. Its only result is pixel equality with
  Chrome.
- **A copy of the ICU number-format files.** Rejected (Chart.js ADR 0026). It needs a Unicode-3.0
  notice, two `REUSE.toml` tables and a `port_sources.yaml` entry. Its only result is exact
  equality of display strings with V8.

## Consequences

- Contributors read each source at its pinned version, as they read Chart.js.
- A plain `git clone` downloads no submodule. `dart run melos run upstream` clones them.
- `upstream:check` compares the Chart.js gitlink with `chartJsVersion`, for a tag pin and for a
  commit pin. `check:headers` compares each submodule gitlink with its `commit` in
  `port_sources.yaml`.
- `upstream:check` fails on a submodule of `.gitmodules` that no entry of a
  `tool/port_sources.yaml` pins.
- A new fdlibm port changes these files in the same change:
  - its netlib files go to `third_party/fdlibm/`
  - its targets and files go to the fdlibm entry of `port_sources.yaml`
  - its Dart file goes to the `REUSE.toml` table of the fdlibm ports
  - its file names go to the fdlibm component of the package `LICENSE`
- The `@kurkle/color` notice is `Copyright (c) 2018-2021 Jukka Kurkela`, from `LICENSE.md` at
  `v0.3.2`. The AGENTS.md Licensing example uses this line.
