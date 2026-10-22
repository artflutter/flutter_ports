# Chart.js ADR 0011: Third-party sources

- Status: accepted (2026-10-19)
- Superseded by: [Chart.js ADR 0035](0035-third-party-sources.md) (2026-10-21)
- Date: 2026-10-19
- Supersedes: [Chart.js ADR 0005](0005-third-party-sources.md)
- Related: [ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md) (the pin of each
  upstream), [Chart.js ADR 0008](0008-number-formatting-on-package-intl.md) (no ICU),
  [Chart.js ADR 0009](0009-no-display-only-js-exactness.md) (no pixelmatch),
  [Chart.js ADR 0010](0010-js-numeric-semantics.md) (the fdlibm ports)

## Context

[ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md) pins the upstream of each port as a
reference-only shallow submodule under `third_party/`, at a release tag. For Chart.js, that is
`third_party/Chart.js` at `v4.5.1` (commit `9c5cf9f`).

The Chart.js port also translates code from three other projects:

| Project | Version | License, holder | What the port takes |
|---|---|---|---|
| `@kurkle/color` | 0.3.2 | MIT, Jukka Kurkela | the color library that `helpers.color.ts` wraps |
| chartjs-test-utils | 0.4.0 | MIT, chartjs-test-utils Contributors | the spec harness |
| fdlibm | 5.3 | SunPro, Sun Microsystems, Inc. | `Math.log10` and `Math.atan2` ([Chart.js ADR 0010](0010-js-numeric-semantics.md)) |

Chart.js ADR 0005 (accepted 2026-10-18) gave the first list. It also had pixelmatch 5.3.0 (ISC,
Mapbox) for the image comparison of the harness. Later decisions removed code from that list:
- [Chart.js ADR 0009](0009-no-display-only-js-exactness.md) removed the image comparison. The port
  has no pixelmatch code. The phase 2 cleanup removed `third_party/pixelmatch`, its
  `.gitmodules` entry and its `port_sources.yaml` entry. It also removed the fdlibm ports of
  `sin`, `cos` and `pow` and their eight netlib files.
- [Chart.js ADR 0008](0008-number-formatting-on-package-intl.md) formats numbers with package:intl.
  The port has no ICU or CLDR code, and no Unicode-3.0 notice.

This ADR states the complete current decision. It supersedes Chart.js ADR 0005.

**Versions.** The Chart.js v4.5.1 lockfile selects the versions:
- `@kurkle/color`: `^0.3.0` (`package.json:76`), locked to 0.3.2 (`pnpm-lock.yaml:2069`). npm
  resolves `^0.3.0` to 0.3.4 now.
- chartjs-test-utils: `^0.4.0` (`package.json:90`), locked to 0.4.0 (`pnpm-lock.yaml:4986`).
  chartjs-test-utils v1.0.0 (2026-10-11) uses Vitest and pixelmatch 7.

fdlibm has no git repository. netlib serves its files.

**Tags and notices.** `git ls-remote` (2026-10-17) gave the tag commits in the Decision table.
The license files at the two tags have these copyright lines:
- `Copyright (c) 2018-2021 Jukka Kurkela` (`LICENSE.md` at `v0.3.2`)
- `Copyright (c) 2020 chartjs-test-utils Contributors`

The fdlibm files carry `Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.` and
the SunPro permission notice.

**Dev-time use.** Dev-time tools read and run reference sources. Tool 4 (the upstream manifest)
runs the `describe` bodies of the upstream specs in a Node.js `vm`. The reference generators of
[Chart.js ADR 0010](0010-js-numeric-semantics.md) run JS builtins in Node.js.

## Decision

1. **Submodules.** Each source with a git repository is a reference-only shallow submodule at its
   release tag:

   | Path | Project | Tag | Commit |
   |---|---|---|---|
   | `third_party/Chart.js` | Chart.js | `v4.5.1` | `9c5cf9f` |
   | `third_party/kurkle-color` | `@kurkle/color` | `v0.3.2` | `eb0d1db` |
   | `third_party/chartjs-test-utils` | chartjs-test-utils | `v0.4.0` | `8c02987` |

   `.gitmodules` lists these three submodules, each with `shallow = true`. The analysis excludes
   them (`third_party/**` in `analysis_options.yaml`). `dart run melos run upstream` clones every
   `third_party` submodule at its pin.
2. **Copies.** A source without a git repository is a reference-only copy of its release files in
   `third_party/<name>/`. The copy stays unchanged. `third_party/fdlibm/` holds the netlib fdlibm
   5.3 files `e_log.c`, `e_log10.c`, `s_atan.c` and `e_atan2.c`, and no other file. The copies are
   part of this tree. Thus `REUSE.toml` annotates them.
3. **Source list.** `packages/flutter_chartjs_port/tool/port_sources.yaml` has one entry for each
   project: Chart.js, fdlibm, `@kurkle/color` and chartjs-test-utils. An entry holds the header
   name, the version, the source of that version, the URL, the language, the SPDX ID, the holder,
   the pin, the Dart targets and the source files at the pin. Tool 2 (`check:headers`) compares
   each `// Ported from` header with this file, the `LICENSE` of the package that contains the
   file and `REUSE.toml`. It also compares each submodule gitlink with the `commit` of its entry.
   Tool 3 (`check:js-semantics`) examines the files whose header names a `js` project of this
   file.
4. **Targets.**

   | Project | Dart target |
   |---|---|
   | `@kurkle/color` | `packages/flutter_chartjs_port/lib/src/kurkle_color/`, `packed.js` to `lib/src/kurkle_color/packed.dart`, `test/index.js` to `test/kurkle_color/index_test.dart` |
   | chartjs-test-utils | `packages/chartjs_test_utils/lib/src/` |
   | fdlibm | `e_log.c` and `e_log10.c` to `packages/flutter_chartjs_port/lib/src/js/fdlibm_log.dart`; `s_atan.c` and `e_atan2.c` to `fdlibm_atan.dart` |

5. **Versions follow Chart.js.** A submodule moves only in a Chart.js bump PR. It moves to the
   version that the new Chart.js lockfile selects ([upstream-tracking.md](../upstream-tracking.md)
   §5, step 10). fdlibm stays at 5.3 while the reference engine of
   [Chart.js ADR 0010](0010-js-numeric-semantics.md) uses it.
6. **Licensing.** AGENTS.md Licensing applies to each source. The notice is the copyright line of
   the license file at the pin.
   - `packages/flutter_chartjs_port/LICENSE` has the MIT text with the lines of Chart.js Contributors,
     Jukka Kurkela and the port. It has the fdlibm 5.3 notice as a separate SunPro component.
   - `packages/chartjs_test_utils/LICENSE` has the MIT text with the lines of chartjs-test-utils
     Contributors and the port.
   - `LICENSES/` holds `MIT.txt`, `SunPro.txt` and `BSD-3-Clause.txt`. No ISC and no Unicode-3.0
     text is necessary.
   - `REUSE.toml` has a table for the package, for the harness, for `third_party/fdlibm/**`, for
     the two fdlibm Dart ports and for the `@kurkle/color` port. The last matching table wins.
     Thus each table lists every holder of its paths.
7. **Reference only.** The rules of [ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md)
   apply to each source, submodule or copy:
   - Dart code never imports a reference source.
   - No tool builds a reference source inside `third_party/`. A tool that needs a built upstream
     builds it in a throwaway clone outside the repository.
   - No package ships a reference source. A published archive contains no `third_party/` file.
   - Dev-time tools can read and evaluate reference sources, for example the specs, the
     JavaScript code and the fixture files. The upstream manifest tool records the hash of each
     fixture PNG. No tool compares pixels with these PNGs.
8. **New sources.** Code from a project that is not in the list needs, in the same change, an
   entry in `port_sources.yaml`, its notice in the package `LICENSE`, a `REUSE.toml` table and the
   header of AGENTS.md rule 2. A source with a git repository also needs a submodule. Never copy
   code from GPL or otherwise incompatible projects.

## Alternatives considered

- **The newest releases** (`@kurkle/color` 0.3.4, chartjs-test-utils 1.0.0). Rejected. Chart.js
  v4.5.1 locks the older versions. Its specs and fixture thresholds come from them.
- **V8's `ieee754.cc` as the fdlibm source.** Rejected. It adds a V8 BSD notice
  ([Chart.js ADR 0010](0010-js-numeric-semantics.md)).
- **Flutter `Color` and `Color.lerp` instead of a port of `@kurkle/color`.** Rejected. A color
  transition calls `mix` (`core.animation.js:19`). `mix` weights the two colors by their alpha
  difference and rounds each channel to a byte (`kurkle-color/src/color.js:157-172`).
  `Color.lerp` interpolates each channel linearly, with no weight and no rounding. Chart.js also
  parses CSS color strings. Its transitions write `hexString()` values. Eight spec files compare
  color strings, for example `core.animation.tests.js`.
- **A pixelmatch port for an image comparison against the upstream PNGs.** Rejected
  ([Chart.js ADR 0009](0009-no-display-only-js-exactness.md)). It needs an ISC notice, a ledger
  of 662 PNGs and a fixtures job pinned to the Skia renderer on Linux. Its only result is pixel
  equality with Chrome.
- **A copy of the ICU number-format files.** Rejected
  ([Chart.js ADR 0008](0008-number-formatting-on-package-intl.md)). It needs a Unicode-3.0
  notice, two `REUSE.toml` tables and a `port_sources.yaml` entry. Its only result is exact
  equality of display strings with V8.

## Consequences

- Contributors read each source at its pinned version, as they read Chart.js.
- `.gitmodules` lists three submodules. A plain `git clone` downloads none of them.
- `upstream:check` compares the Chart.js tag with `chartJsVersion`. `check:headers` compares each
  submodule gitlink with its `commit` in `port_sources.yaml`.
- A new fdlibm port adds its netlib files to `third_party/fdlibm/`, its targets and files to the
  fdlibm entry of `port_sources.yaml`, and its Dart file to the `REUSE.toml` table of the fdlibm
  ports.
- The `@kurkle/color` notice is `Copyright (c) 2018-2021 Jukka Kurkela`, from `LICENSE.md` at
  `v0.3.2`. The AGENTS.md Licensing example uses this line.
