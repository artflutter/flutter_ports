# Phase 7 progress

This file records the progress of phase 7 (Controllers). A new session reads it first and
continues from "Next action". The prompt of the phase is
[phase7/kickstart-prompt.md](phase7/kickstart-prompt.md). The last commit of the phase deletes
this file and the folder `doc/phase7/`.

## State

Current step of the Method: 3 (Port workflow), wave 1.

| Unit | Status | Files | Last green check |
|---|---|---|---|
| Before you start: `upstream:check` | done | — | 2026-10-20: exit 0 |
| Before you start: module-start check (upstream-tracking.md §4.3) | done | — | 2026-10-20: no tag after v4.5.1. `origin/master` is the pin `7169e651`. No commit after the pin. The ledger has the 3 rows of the phase 7 paths (#12238, #12155, #12328) |
| Environment (x64 Node.js, Chart.js at the pin, moment packages) | done | `phase7/env-setup.sh` | 2026-10-20: `scale_chart_harness_reference.mjs` gives byte-identical data |
| Scout: probe harness | done | `phase7/probe/` | 2026-10-21: self-test, 62 of 62 Dart-run cases pass or are `unsupported` in the mode `all` |
| Scout: classification of the cases | done | `phase7/classification/` | 2026-10-21: 536 records, coverage check of the critic |
| Performance: before figures at `0e0ab93` (Pixel 8a, iPhone if wired) | done | `phase7/perf/before.md`, `phase7/perf/before/` | 2026-10-21: Pixel 8a (bench 3 runs, `CASES=axes` 3 runs, 14 stress scenarios) and iPhone 17 Pro (bench 2 runs, N=5000) |
| Scout: type members and dependencies of each controller | done | `phase7/members-cartesian.md`, `phase7/members-radial.md` | 2026-10-21 |
| Design panels: ADRs 0027-0031 | done | `phase7/design/<topic>/`, `phase7/design/work-plan.md`, `phase7/design/consistency.md`, `adr/0027`-`0031` | 2026-10-21: consistency critic |
| Wave 1: S1, S2, S3, U0, U-bar, W1-int (`phase7/design/work-plan.md` §1) | done | `phase7/review/wave1/W1-int-report.md` lists the files | 2026-10-21: full gate, reuse lint, `gallery:build:web`, `gallery:build:android`. `controller.bar` spec 51/55 pass, 0 fail. Lift check: 62 of 122 wave 1 records pass, the other 60 are the L1 list |
| Wave 2: U-line, U-bubble, U-doughnut, U-polarArea, U-radar, L1, A1, W2-int (work plan §2) | done | `phase7/review/wave2/W2-int-report.md` lists the files | 2026-10-21: full gate, reuse lint, both gallery builds. `test:cases` 572 passed, 0 failed. Lift check wave 1: 122/122 |
| Wave 3: U-scatter, U-pie, L2, X-fix (D11), W3-int (work plan §3) | done, committed locally, not pushed (CI on Windows is red since `7674512`) | `phase7/review/wave3/W3-int-report.md` lists the files | 2026-10-21: full gate, reuse lint, both gallery builds. `test:cases` 813 passed, 0 failed. Lift check waves 1-2: 508/508. 16 records left for L3 |
| Design panels: ADR 0032 (fdlibm `sin`/`cos` at the behavior sites) and ADR 0033 (radial centers `double?`) | not started | `phase7/design/trig/`, `phase7/design/radial-center/` | — |
| Push of `7674512` | done 2026-10-21. CI run 39544591156: failure on test (windows-latest): one hit of the doughnut case `parsed: object items with the default key` (point 2, query 4 on the border of two symmetric arcs). Fix: D13, unit H-fix after wave 3 | — | pre-push: dart2js and dart2wasm in the VS Code integrated browser (flutter_chartjs 3525 pass, chartjs_test_utils 49 pass), gallery wasm loads, diagnostics clean |
| Push of `4eda459`, `c802f9b`, `436663f` | done 2026-10-21. CI run 39534455808 of `436663f`: success | — | pre-push: dart2js and dart2wasm in the VS Code integrated browser (flutter_chartjs 3479 pass, chartjs_test_utils 49 pass), gallery wasm loads, diagnostics clean |

## Decisions

- D1 (2026-10-21): `controller.bar.tests.js:1426`, `:1442` and `:1538` get `phase7`, not `blocked: plugin.legend`. They pass in the probe mode `none`, as the 49 other cases with a non-empty `changedBy`. Record: `phase7/classification/summary.md` §8.
- D3 (2026-10-21): the gallery controls are full-width Material segmented buttons, and the chart of each page is in view at load (a rule of the user). Commit `4eda459` changed the stress tab. The gallery panel (ADR 0031) applies the rule to the new pages.
- D4 (2026-10-21): the CI job `fixtures` keeps the submodule checkout and `FIXTURES_REQUIRED=1` of the phase scope and `porting-flow.md` §3. The runner compares the SHA-256 of each upstream fixture file with the manifest. Record: Chart.js ADR 0029 §3 item 5, §11.
- D5 (2026-10-21): `stacksOf` (ADR 0027, unit S3) lands in any case, because it removes a throw that upstream does not have. S3 records its figures in `performance.md` §13.1.
- D6 (2026-10-21): the one-read rule of line and scatter (ADR 0027 Open 4) lands. It keeps each upstream statement and gains 22-24 ns (AOT) and 33-36 ns (wasm) for each point.
- D7 (2026-10-21): `jsToString` gives the `Date.prototype.toString` text without the zone name. `lib/src/js/` is port-only, so no `differences.md` row (Chart.js ADR 0009: display text only). Record: ADR 0027.
- D8 (2026-10-21): the hit items of the controller reference data are JSON text lines, not Dart literals: 23 bar cases need about 3.8 MB as text and about 11.7 MB as literals. The items compare exactly. Record: ADR 0030 §3 item 6.
- D9 (2026-10-21): U0 result of TS §1.2 item 5: the 8 phase 6 generators with `registerPhase7` give byte-identical data, so they keep `registerPhase6`.
- D10 (2026-10-21), replaces D6: line and scatter keep the parsed values only inside one pass of `updateElements` (the 3-read form). The U-line review proved that a scriptable option can write `ctx.parsed` between two passes, so the cross-pass local changes the segments. Record: ADR 0027 §8 and Open 4 (W3-int aligns the text).
- D11 (2026-10-21): a fix unit X-fix in wave 3 corrects the NaN reset position of a new radar or polar area point (upstream `undefined`), the `TypeError` of a string `data` in `_dataCheck`, and the legend `onClick` key after an insert (a fix, or a `DIVERGES` row with a phase 8 re-check). Each with a probe.
- D12 (2026-10-21): U-pie takes the axis-id rule of the doughnut tests. W3-int removes the pie skip of `controller.doughnut.tests.js:4`, moves the IV §7.1 test to a polar area chart and aligns the proposed ADRs 0027-0031 and the specs with the code.
- D13 (2026-10-21): the controller generators drop each ill-conditioned hit query: a query whose hit list in Node.js changes when the point moves by ±1e-6 px in x or y. Reason: CI on Windows found another arc on a border of two symmetric arcs (last-bit `sin`/`cos`). Unit H-fix runs after wave 3 and before its commit: `controller_chart_common.mjs`, all controller data files, ADR 0030 §5.
- D14 (2026-10-21): two design panels before the push of wave 3: ADR 0032 (an fdlibm port of `sin` and `cos` at the sites that change a protected result; it changes the rule of accepted Chart.js ADR 0010 for `sin`/`cos`) and ADR 0033 (`double? xCenter`/`yCenter` of `types.RadialLinearScale`; it supersedes accepted Chart.js ADR 0025 §5 on acceptance). Reason: the U-pie review proved a hit difference from a 1-ulp `sin`, and X-fix changed the center type. D13 waits for ADR 0032: if the fdlibm `sin`/`cos` remove the Windows difference, the border queries stay.
- D2 (2026-10-21): the Design step has five panels, one ADR (proposed) each: 0027 parsed data of the controllers, 0028 controller interfaces and values, 0029 fixture smoke runner, 0030 test strategy, 0031 gallery. Reason: the open choices of `members-*.md` and of the prompt group into these five topics.

## Inputs

- `phase7/kickstart-prompt.md`: the prompt of the phase.
- `phase7/env-setup.sh`: the build of the reference environment.
- `phase7/probe/`: the probe harness (`run_spec.mjs`, `compare.mjs`, `README.md`, `selftest.md`). It runs an upstream spec file in the x64 Node.js with and without the plugins.
- `phase7/classification/<group>.json`, `all.json` and `summary.md`: the classification of the cases. The raw probe outputs (`classification/raw/**/*.json`, 9.1 MB) are not committed. `probe/compare.mjs` makes them again (see `probe/README.md`). The two variant spec files in `classification/raw/` are committed evidence.
- `phase7/perf/before.md`: the figures of the modes `chart` and `axes` and of the frameless benchmark before phase 7 changes the gallery. A resume that finds it missing records it again from a worktree of `0e0ab93`.
- `phase7/review/wave<N>/<unit>-report.md` and `<unit>-review.md`: the report and the adversarial review of each unit. `phase7/tools/lift_check.py`: the lift check of TS §4.1 (`python3 -I doc/phase7/tools/lift_check.py doc/phase7/classification/all.json <flutter test --reporter json output> <wave> --list`).
- `phase7/design/work-plan.md`: the units of steps 3-7, their files, specs, tests and gates. `phase7/design/<topic>/spec.md`: the implementation specs. `phase7/design/consistency.md`: the cross-topic findings.
- `phase7/members-cartesian.md` and `phase7/members-radial.md`: the dependency inventory of the controllers.

## Environment

Run `zsh packages/flutter_chartjs/doc/phase7/env-setup.sh <scratchpad>/env` from the repository
root. The script downloads `node-v24.12.0-darwin-x64.tar.gz` and compares it with
`SHASUMS256.txt` (SHA-256
`b82ea4c62fd08e250cab59d625e75d77cc5b0a3d60c6698ebee4545c88a169c5`). It clones Chart.js at
`7169e65147a47f3720957a6f156a33c838ab9f57` into `<scratchpad>/env/chartjs-build` and builds it
with `corepack pnpm`. The build of 2026-10-20 gave `dist/chart.js` with the SHA-256
`bc550e26bbb4efa6dcc19fe8ec942327930306a9ef8b63f0ec44d650a7745e17` and `dist/chunks/index.js`
with `87b29e4c0d409eff30f9d9108feba6291c080e23641382e91fbf5fc125ff1977`. The script installs
moment 2.29.4, moment-timezone 0.5.42 and chartjs-adapter-moment 1.0.1 into
`<scratchpad>/env/moment/node_modules`. The fsevents build error of the pnpm install is an
optional macOS package. It does not change the build.

Run a generator with
`/usr/bin/arch -x86_64 <scratchpad>/env/node-v24.12.0-darwin-x64/bin/node <script> <scratchpad>/env/chartjs-build/dist/chart.js`.

## Next action

Run the design panels of D14 (ADRs 0032 and 0033), implement them, push wave 3 when CI on Windows can pass, then step 4 (work plan §4). A panel whose `phase7/design/<topic>/spec.md` exists is done.
