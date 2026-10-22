# Chart.js ADR 0005: Third-party sources

- Status: accepted (2026-10-18)
- Date: 2026-10-17
- Superseded by: [Chart.js ADR 0011](0011-third-party-sources.md) (2026-10-19)

## Context

[ADR 0002](../../../../docs/adr/0002-pin-upstream-sources.md) pins the upstream of each port as a
shallow submodule under `third_party/`, at a release tag. It says that the submodule "is never
built, shipped or imported". [porting-flow.md](../porting-flow.md) §2.13 proposed this decision.
Its gate is phase 1, because the pilot ported fdlibm code.

The Chart.js port also translates code from four other projects:

| Project | Version | License, holder | What the port takes |
|---|---|---|---|
| `@kurkle/color` | 0.3.2 | MIT, Jukka Kurkela | the color library that `helpers.color.ts` wraps |
| chartjs-test-utils | 0.4.0 | MIT, chartjs-test-utils Contributors | the spec harness |
| pixelmatch | 5.3.0 | ISC, Mapbox | the image comparison of the harness |
| fdlibm | 5.3 | SunPro, Sun Microsystems, Inc. | `Math.log10`, `Math.atan2` and the next builtins ([Chart.js ADR 0002](0002-js-numeric-semantics.md)) |

The Chart.js v4.5.1 lockfile selects the first three versions:
- `@kurkle/color`: `^0.3.0` (`package.json:76`), locked to 0.3.2 (`pnpm-lock.yaml:2069`). npm
  resolves `^0.3.0` to 0.3.4 now.
- chartjs-test-utils: `^0.4.0` (`package.json:90`), locked to 0.4.0 (`pnpm-lock.yaml:4986`).
  chartjs-test-utils v1.0.0 (2026-10-11) uses Vitest and pixelmatch 7.
- pixelmatch: `^5.3.0` (`package.json:116`), locked to 5.3.0 (`pnpm-lock.yaml:129-131`).
  chartjs-test-utils 0.4.0 also depends on pixelmatch 5.3.0 (`:4996`).

fdlibm has no git repository. netlib serves its files.

`git ls-remote` (2026-10-17) gave the tag commits in the Decision table. The pixelmatch tag
`v5.3.0` is an annotated tag object, `c892aae`, on the commit `910cd5d`. The license files at the
three tags have these copyright lines:
- `Copyright (c) 2018-2021 Jukka Kurkela`
- `Copyright (c) 2020 chartjs-test-utils Contributors`
- `Copyright (c) 2019, Mapbox`

Dev-time tools read and run reference sources. The fixtures job reads the Chart.js PNGs. Tool 4
runs the `describe` bodies of the upstream specs in a Node.js `vm`. The reference generators of
Chart.js ADR 0002 run JS builtins in Node.js. ADR 0002 does not say whether "never built" covers
these uses.

## Decision

1. **Submodules.** Pin each non-Chart.js source that has a git repository as a reference-only
   shallow submodule at its release tag:

   | Path | Tag | Commit |
   |---|---|---|
   | `third_party/kurkle-color` | `v0.3.2` | `eb0d1db` |
   | `third_party/chartjs-test-utils` | `v0.4.0` | `8c02987` |
   | `third_party/pixelmatch` | `v5.3.0` | `910cd5d` |

   The analysis excludes them (`third_party/**` in `analysis_options.yaml`).
   `dart run melos run upstream` clones every `third_party` submodule at its pin.
2. **Copies.** A source without a git repository is a reference-only copy of its release files in
   `third_party/<name>/`. The copy stays unchanged. For fdlibm, `third_party/fdlibm/` holds the
   netlib files `e_log.c`, `e_log10.c`, `s_atan.c` and `e_atan2.c` (commit `421fc9f`). Each later
   fdlibm port adds its netlib files there. The copies are part of this tree. Thus `REUSE.toml`
   annotates them.
3. **Source list.** `packages/flutter_chartjs_port/tool/port_sources.yaml` has one entry for each
   project. An entry holds the header name, the version and the source of that version. It also
   holds the URL, the SPDX ID, the holder, the pin and the Dart target. Tool 2 compares each
   `// Ported from` header with this file, the package `LICENSE` and `REUSE.toml`.
4. **Targets.**

   | Project | Dart target |
   |---|---|
   | `@kurkle/color` | `packages/flutter_chartjs_port/lib/src/kurkle_color/` |
   | chartjs-test-utils | `packages/chartjs_test_utils/lib/src/` |
   | pixelmatch | `packages/chartjs_test_utils/lib/src/pixelmatch.dart` |
   | fdlibm | `packages/flutter_chartjs_port/lib/src/js/fdlibm_log.dart`, `fdlibm_atan.dart` and the next `fdlibm_*.dart` files |

5. **Versions follow Chart.js.** A submodule moves only in a Chart.js bump PR. It moves to the
   version that the new Chart.js lockfile selects ([upstream-tracking.md](../upstream-tracking.md)
   §5, step 10). fdlibm stays at 5.3 while the reference engine of Chart.js ADR 0002 uses it.
6. **Licensing.** AGENTS.md Licensing applies to each source. The notice is the copyright line of
   the license file at the pin. The notices of chartjs-test-utils and pixelmatch go in the
   `LICENSE` of `packages/chartjs_test_utils`. pixelmatch also adds `LICENSES/ISC.txt`
   ([porting-flow.md](../porting-flow.md) §3).
7. **Clarification of ADR 0002.** Dev-time tools can read and evaluate reference sources, for
   example the PNGs, the specs and the JavaScript code. Three limits stay:
   - Dart code never imports a reference source.
   - No tool builds a reference source inside `third_party/`. A tool that needs a built upstream
     builds it in a throwaway clone outside the repository
     ([ADR 0004](../../../../docs/adr/0004-follow-upstream-between-releases.md)).
   - No package ships a reference source. A published archive contains no `third_party/` file.
8. **Status line of ADR 0002.** When the maintainers accept this ADR, the status line of ADR 0002
   adds its name, for example `accepted; amended by ADR 0004 and Chart.js ADR 0005`. The body of
   ADR 0002 stays as it is.

## Alternatives considered

- **The newest releases** (`@kurkle/color` 0.3.4, chartjs-test-utils 1.0.0, pixelmatch 7).
  Rejected. Chart.js v4.5.1 locks the older versions. Its specs and fixture thresholds come from
  them. pixelmatch 7.2.0 changes 33 fixture results ([porting-flow.md](../porting-flow.md) §2.6).
- **V8's `ieee754.cc` as the fdlibm source.** Rejected. It adds a V8 BSD notice
  ([Chart.js ADR 0002](0002-js-numeric-semantics.md)).
- **Flutter `Color` and `Color.lerp` instead of a port of `@kurkle/color`.** Rejected. A color
  transition calls `mix` (`core.animation.js:19`). `mix` weights the two colors by their alpha
  difference and rounds each channel to a byte (`kurkle-color/src/color.js:157-172`).
  `Color.lerp` interpolates each channel linearly, with no weight and no rounding. Chart.js also
  parses CSS color strings. Its transitions write `hexString()` values. Eight spec files compare
  color strings, for example `core.animation.tests.js`.

## Consequences

- Contributors read each source at its pinned version, as they read Chart.js.
- `.gitmodules` lists four submodules. A plain `git clone` downloads none of them.
- `upstream:check` compares the Chart.js tag with `chartJsVersion`. `check:headers` compares each
  submodule gitlink with its `commit` in `port_sources.yaml`.
- Each new fdlibm port adds its netlib files to `third_party/fdlibm/`. It also adds its Dart file to
  the `REUSE.toml` annotation of the fdlibm ports.
- The `@kurkle/color` notice is `Copyright (c) 2018-2021 Jukka Kurkela`, from `LICENSE.md` at
  `v0.3.2`. The AGENTS.md Licensing example uses this line.
