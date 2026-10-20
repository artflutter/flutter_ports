# Phase 7 progress

This file records the progress of phase 7 (Controllers). A new session reads it first and
continues from "Next action". The prompt of the phase is
[phase7/kickstart-prompt.md](phase7/kickstart-prompt.md). The last commit of the phase deletes
this file and the folder `doc/phase7/`.

## State

Current step of the Method: 2 (Design).

| Unit | Status | Files | Last green check |
|---|---|---|---|
| Before you start: `upstream:check` | done | — | 2026-10-20: exit 0 |
| Before you start: module-start check (upstream-tracking.md §4.3) | done | — | 2026-10-20: no tag after v4.5.1. `origin/master` is the pin `7169e651`. No commit after the pin. The ledger has the 3 rows of the phase 7 paths (#12238, #12155, #12328) |
| Environment (x64 Node.js, Chart.js at the pin, moment packages) | done | `phase7/env-setup.sh` | 2026-10-20: `scale_chart_harness_reference.mjs` gives byte-identical data |
| Scout: probe harness | done | `phase7/probe/` | 2026-10-21: self-test, 62 of 62 Dart-run cases pass or are `unsupported` in the mode `all` |
| Scout: classification of the cases | done | `phase7/classification/` | 2026-10-21: 536 records, coverage check of the critic |
| Performance: before figures at `0e0ab93` (Pixel 8a, iPhone if wired) | in progress (background agent) | `phase7/perf/before.md`, `phase7/perf/before/` | — |
| Scout: type members and dependencies of each controller | done | `phase7/members-cartesian.md`, `phase7/members-radial.md` | 2026-10-21 |
| Design panels: ADRs 0027-0031 | in progress (workflow `phase7-design`) | `phase7/design/<topic>/`, `adr/0027`-`0031` | — |

## Decisions

- D1 (2026-10-21): `controller.bar.tests.js:1426`, `:1442` and `:1538` get `phase7`, not `blocked: plugin.legend`. They pass in the probe mode `none`, as the 49 other cases with a non-empty `changedBy`. Record: `phase7/classification/summary.md` §8.
- D2 (2026-10-21): the Design step has five panels, one ADR (proposed) each: 0027 parsed data of the controllers, 0028 controller interfaces and values, 0029 fixture smoke runner, 0030 test strategy, 0031 gallery. Reason: the open choices of `members-*.md` and of the prompt group into these five topics.

## Inputs

- `phase7/kickstart-prompt.md`: the prompt of the phase.
- `phase7/env-setup.sh`: the build of the reference environment.
- `phase7/probe/`: the probe harness (`run_spec.mjs`, `compare.mjs`, `README.md`, `selftest.md`). It runs an upstream spec file in the x64 Node.js with and without the plugins.
- `phase7/classification/<group>.json`, `all.json` and `summary.md`: the classification of the cases. The raw probe outputs (`classification/raw/**/*.json`, 9.1 MB) are not committed. `probe/compare.mjs` makes them again (see `probe/README.md`). The two variant spec files in `classification/raw/` are committed evidence.
- `phase7/perf/before.md`: the figures of the modes `chart` and `axes` and of the frameless benchmark before phase 7 changes the gallery. A resume that finds it missing records it again from a worktree of `0e0ab93`.
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

Run the five design panels (Method step 2). A panel whose `phase7/design/<topic>/spec.md` exists is done.
