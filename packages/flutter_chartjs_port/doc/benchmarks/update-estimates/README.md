# Estimates for the remaining indexed/scriptable update costs

2026-11-03, baseline `ba58aa8`. Production library code is unchanged. These are
controlled **estimation prototypes**, not proposed drop-in production patches.
They establish attainable costs for these inputs, not compatibility with arbitrary
callbacks, custom components, dynamic descriptors or plugin mutations.

## What was measured

The current stress chart configuration, native 800×480/DPR1, moving data, static
or alternating indexed blue/pink colors, or the equivalent simple color callback.
Line, bar and radar use N=5000; the dense follow-up uses 20000 indexed bars.

- **setup:** cache element scope keys, prefixes, scopes and the enumerated default
  keys for one controller configure/update pass. Original resolution still runs.
- **styles:** resolve the first data-element options normally per mode/pass, then
  clone that template and resolve only backgroundColor for each item. Contexts
  still refresh and options remain fresh. The template does not persist across
  full updates. All other style values are known static in these scenes.
- **bulk:** let the existing native bulk-bar geometry writer run with a sample of
  the uniform geometry-affecting style fields, while resolving each bar's own
  options and color. It does not share the varying colors/options between bars.
- **setup_bulk / styles_bulk:** measured combinations, not added percentages.
- **data:** bypass only the context-independent-style eligibility check for the
  known indexed-bar scene, then use the existing updateData lifecycle. All other
  checks still run. Both measurements select it without fallback. This bypass
  is unsafe as a general implementation and must not be shipped as written.

The sources are in an isolated checkout. The added perf_estimate.dart module
contains only the diagnostic mode and activation counters. Baseline A has no
library modifications besides this unused module. Prototype B retains mode-0
controls, allowing the instrumentation overhead to be checked.

## Results at 5000 items

Times are milliseconds. Update excludes drawing; full CPU includes update, draw,
and native paint/record completion. Each value is the mean of two process medians.

| Case / prototype | Update before → after | Full CPU before → after | Full reduction |
| --- | ---: | ---: | ---: |
| Indexed line / setup | 6.189 → 5.189 | 7.370 → 6.259 | 15.1% |
| Callback line / setup | 12.976 → 11.761 | 14.216 → 12.965 | 8.8% |
| Indexed bar / setup | 9.797 → 8.664 | 12.714 → 11.546 | 9.2% |
| Callback bar / setup | 15.473 → 14.380 | 18.300 → 17.374 | 5.1% |
| Indexed line / styles | 6.189 → 1.671 | 7.370 → 2.781 | 62.3% |
| Callback line / styles | 12.976 → 2.175 | 14.216 → 3.289 | 76.9% |
| Indexed bar / styles | 9.797 → 5.027 | 12.714 → 7.816 | 38.5% |
| Callback bar / styles | 15.473 → 5.521 | 18.300 → 8.344 | 54.4% |
| Indexed bar / bulk | 9.797 → 7.205 | 12.714 → 10.092 | 20.6% |
| Callback bar / bulk | 15.473 → 12.876 | 18.300 → 15.822 | 13.5% |
| Indexed bar / setup_bulk | 9.797 → 5.796 | 12.714 → 8.609 | 32.3% |
| Indexed bar / styles_bulk | 9.797 → 2.502 | 12.714 → 5.268 | 58.6% |
| Callback bar / styles_bulk | 15.473 → 2.990 | 18.300 → 5.725 | 68.7% |
| Indexed radar / styles | 7.364 → 2.417 | 9.803 → 4.965 | 49.4% |
| Callback radar / styles | 14.428 → 3.212 | 17.139 → 5.675 | 66.9% |
| Indexed bar / data | 9.797 → 9.011 | 12.714 → 11.911 | 6.3% |

The largest gains repeat in both orders. For example, the callback-line styles
prototype saves 76.6% / 77.1% of full CPU, and indexed-bar styles_bulk saves
58.6% / 58.5%. See summary.json for all paired results and controls.

## Dense indexed bars

At 20000 bars, baseline update is 43.340ms and full CPU is 54.140ms.
Setup plus bulk reduces them to 28.021 / 39.359ms. Styles plus bulk reduces them
to **14.348 / 25.754ms**, a 52.4% full-call reduction (53.0% / 51.8% in the two
pairs). Every parsed/geometry/style comparison passes. This is still over a
16.67ms CPU budget and does not establish steady 60 FPS.

## What the fresh profiles say

The three baseline captures place these inclusive shares of all samples under
option resolution:

- Indexed line: DatasetController._resolveElementOptions 68.4%; getContext 13.5%,
  ContextObject._claim 6.8%, indexed-plan fill 9.8% and _getResolver 8.6%.
- Callback line: _resolveElementOptions 83.7%; _needContextKeys 12.0% and
  _getResolver 9.7%.
- Indexed bar: _resolveElementOptions 41.3%; bar index/value geometry 10.2% / 3.1%.

These shares overlap with their callers and are not allocation percentages.
The profiles include the data simulation outside the phase stopwatches, so their
percentage denominator differs from the timing table.

## Interpretation and limits

The strongest direction is a prepared native style path, first for indexed colors
with static remaining style fields. Callback preparation has large potential for
simple pure color callbacks, but preserving arbitrary mutation/dependency/order
semantics is harder. Bulk geometry for color-varying bars is another independently
measured opportunity. Setup caching alone gives a useful but smaller improvement.
Simply broadening updateData's style gate saves much less in this scene.

Production guards, invalidation, fallback transitions and cross-platform behavior
have not been implemented or benchmarked. These are optimistic controlled-case
figures, not promised shipping gains. None of the prototypes relies on comparing
color lists between builds; they either prepare within an update or use the
existing explicit data-only contract in a separately identified case.

Prototype mode-0 full-call means remain within 3% of production for the main
matrix. Static style controls are small on average; the reversed static-line
style control has a 10.6% / roughly 0.16ms regression that does not repeat in the
forward pair. It remains recorded, not discarded. A production candidate must
pass its own controls with the real guards in place.

No pixel, complete context/option-identity, arbitrary-callback, subclass or plugin
mutation equivalence is claimed. No raster, FPS, web/mobile performance or steady
60-FPS claim is made. No production source change or full regression-suite run
was needed for this investigation.

## Evidence and reproduction

- a1/a2.json are production baseline processes; b1/b2.json contain the prototypes
  and instrumented baseline. dense-* retains the 20k follow-up.
- summary.json contains mean timings and paired gains; validation.json records
  all 84 passing parsed-data/geometry/selected-style comparisons, unchanged
  callback counts, activation counters and the data-only fallback counts.
- Callback counts include the initial chart update: 5006 per update for line,
  5001 for bar/radar, identical across variants. The prototypes do not gain speed
  by skipping color callbacks. Geometry/style comparisons run outside timing
  against a subsequent ordinary full update of the same current data.
- The `notifies` field includes that extra validation update because the existing
  harness reads it afterward; it is not a count of timed notifications. Activation
  and callback counters are captured before validation.
- profile-*.json.gz are raw 10-second VM CPU samples from the production binary;
  summary companions contain nonzero function counts.
- probe.dart.txt, perf_estimate.dart.txt and patch.py.txt reproduce the experiment;
  prototype.patch records the complete isolated diff including the small harness
  change that keeps simulation outside frame/data-only timers too.

Create an isolated checkout at the recorded commit. Copy probe.dart to
`.dart_tool/estimate/probe.dart`, and perf_estimate.dart to the package's
`lib/src/core/perf_estimate.dart`. Apply only the harness change first:
`_Loop.iterate` calls change for both update and frame cases. Build baseline A from
`apps/chartjs_gallery` with:

```
flutter build macos --profile -t ../../.dart_tool/estimate/probe.dart
```

Save the app as `/tmp/options-estimate-a.app`. Apply patch.py from the isolated
checkout's `.dart_tool/estimate/`, rebuild, and save B as
`/tmp/options-estimate-b.app`. Sign only the temporary copies using the
[category-layout recipe](../category-layout/README.md).

Restore run.py, report.py and capture.dart into the working repository's
`.dart_tool/perf_estimate/`. Run sequentially, with no concurrent builds/tests:

```
python3 .dart_tool/perf_estimate/run.py measure
python3 .dart_tool/perf_estimate/run.py dense
python3 .dart_tool/perf_estimate/run.py profile
python3 .dart_tool/perf_estimate/report.py
```

The matrix uses 800ms warmup and seven 200ms batches, with reversed order in B2/A2.
Full CPU sums the phase medians per process before taking the mean; it is not a
full-call percentile. Profiles wait five seconds after VM connection, clear CPU
samples, and then capture ten seconds. Rendering is native profile AOT on
macOS 27.0.1 arm64 / Flutter 3.47.8 / Dart 3.13.7, 800×480 DPR1.
