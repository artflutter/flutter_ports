# Prepared indexed styles and native indexed-color bars

2026-11-03. Baseline `ba58aa8`; production changes in
[ADR 0078](../../adr/0078-prepared-indexed-options.md).

## Final production measurements

Native macOS profile AOT, moving data, 800×480 DPR1. Times are milliseconds.
Each result averages two independent process medians. Full CPU sums update,
draw and paint-end medians within each process; it is not a full-call percentile.

| Case | N | Update before → after | Full CPU before → after | Full reduction |
| --- | ---: | ---: | ---: | ---: |
| Indexed line | 5000 | 6.325 → 5.669 | 7.575 → 6.890 | 9.0% |
| Indexed bar | 5000 | 10.231 → 2.467 | 13.249 → 5.266 | 60.2% |
| Indexed radar | 5000 | 7.718 → 7.252 | 10.324 → 10.018 | 3.0% |
| Indexed bar | 20000 | 47.624 → 16.178 | 59.316 → 28.512 | 51.9% |

Indexed-line gains repeat at 9.1%/9.0%; indexed bars at 60.6%/59.9%, and dense
indexed bars at 53.1%/50.8%. Radar full-call results are inconsistent between
pairs (-0.7%/+6.6%); do not claim a reliable radar full-call improvement.

| Control, N=5000 | Full CPU before → after | Full reduction |
| --- | ---: | ---: |
| Static line | 1.542 → 1.555 | -0.9% |
| Scriptable line | 14.384 → 14.733 | -2.4% |
| Static bar | 4.133 → 4.057 | 1.8% |
| Scriptable bar | 19.090 → 19.069 | 0.1% |
| Static radar | 4.065 → 4.091 | -0.6% |
| Scriptable radar | 17.704 → 17.369 | 1.9% |

Negative reduction means slower. The scriptable-line control is 0.349ms/2.4%
slower on average, in both pairs. These controls are retained, not discarded.
Callbacks still execute 5006 times per update for line and 5001 for bar/radar
(including the initial update in the denominator). No callback optimization or
allocation-rate claim is made. The 20000-bar result does not establish 60 FPS.

## What changed

The native indexed plan prepares static scalar fields once, copies its private
template, and fills only live indexed fields per element. Ordinary scope/key
discovery and context refresh remain. This is why the general point-path gain
is much smaller than the earlier simplified prototype estimated.

For native numeric bars in mode none, indexed background/border colors can also
use the existing bulk geometry writer. After the first ordinary bar, the entire
remainder is qualified before writes: native classes and containers, ordinary
context/data reads, static grid/geometry settings, no active bars and no user
callbacks. Each bar still gets a refreshed context, fresh options and independent
skipped-edge state. Other indexed geometry and custom/scriptable behavior retain
the ordinary path. There is no new public API and no cross-update equality cache.

## Protocol and evidence

`a1/b1/b2/a2.json` contain the 5000-element matrix; `dense-*` contains the 20000-bar
follow-up. Each process uses 800ms warmup and seven 200ms batches, A/B/B/A order,
with reversed case order in B2/A2. There are 40 final timing cells. Data simulation
is outside the timers. No tests or builds ran during timing.

The reused baseline is the production A binary from update-estimates. Its unused
diagnostic module and frame-only harness change do not affect these update cases.
Candidate uses the production library and the saved probe with diagnostic modes
removed. The case suffix `baseline` is the runner's legacy label in both apps;
there are no prototype switches in the candidate library.

`referenceMatches` in the timing output checks that a repeated update on unchanged
data retains the observed geometry/styles. In these production runs it is a
smoke check, not an independent ordinary-path oracle. Differential correctness
comes from the permanent tests: an ordinary Config subclass for options and a
chart that disables bulk writes for geometry, styles and context observations.
`notifies` includes the untimed final smoke-check update.

`summary.json` retains paired results. `metadata.json` records toolchain, source
patch and binary hashes. `candidate.patch` records implementation and regression
changes. The library's only post-build edit was an explanatory `js-ok` comment.
`style-only.json.gz` and `pre-class-guard.json.gz` retain development measurements;
they are not mixed into the final results.

## Validation

- 10,886 workspace tests passed with Melos package concurrency two; the existing
  upstream skips remain. No experimental runner flag.
- 46 focused VM regressions passed, including native bar activation, fresh
  options, color/data mutation, contexts, foreign values, list getters, active
  bars, indexed geometry and a custom element-class id getter.
- 230 focused tests passed on each of JavaScript and WebAssembly, including
  native bulk-plan eligibility and existing config/resolver semantics.
- Workspace analysis, format check, parity generation and all port checks pass.

The compressed logs and validation.json retain these checks. The full browser,
fixture and golden suites were not run for this change. No pixels, raster time,
mobile performance, web performance or steady FPS are claimed.

## Reproduction

Restore probe.dart.txt to `.dart_tool/prepared_options/probe.dart`. In a baseline
checkout and then the candidate checkout, build from `apps/chartjs_gallery`:

```
flutter build macos --profile --no-pub -t ../../.dart_tool/prepared_options/probe.dart
```

Save separate app copies as `/tmp/options-estimate-a.app` and
`/tmp/prepared-options-b.app`. Sign only these temporary copies using the
[category-layout entitlement recipe](../category-layout/README.md). Restore
run.py.txt and report.py.txt to `.dart_tool/prepared_options/` without `.txt`.
From the repository root, with builds/tests idle:

```
python3 .dart_tool/prepared_options/run.py
python3 .dart_tool/prepared_options/report.py
```

The runner writes working results in `.dart_tool/prepared_options`; the reporter
updates the evidence files here. Public gallery behavior can be exercised in
Stress with the bar chart and Indexed colors enabled.
