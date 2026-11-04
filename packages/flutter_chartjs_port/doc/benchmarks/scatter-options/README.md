# Native scatter option-loop evidence

2026-11-03. [ADR 0079](../../adr/0079-scatter-point-options.md).
The baseline is the current ADR 0078 implementation, before scatter loop reuse:
ba58aa8 plus baseline.patch. These gains are additional to the earlier indexed
option and bar optimizations.

## Production results

Native macOS profile AOT, changing data, 800×480 DPR1. Milliseconds below average
two independent process medians. Full CPU sums update/draw/paint-end medians
within each process; it is not a full-call percentile.

| Indexed scatter | Update before → after | Full CPU before → after | Full reduction |
| --- | ---: | ---: | ---: |
| 5000 points | 16.249 → 4.503 | 17.531 → 5.644 | **67.8%** |
| 20000 points | 66.780 → 18.299 | 71.233 → 23.855 | **66.5%** |

Both run orders agree: 67.83%/67.79% at 5000, and 66.50%/66.52% at 20000. The
dense result remains over a 16.67ms CPU budget; it does not establish 60 FPS.

All controls at N=5000 are retained:

| Control | Full CPU before → after | Full reduction |
| --- | ---: | ---: |
| Static scatter | 2.179 → 2.200 | -1.0% |
| Scriptable scatter | 38.736 → 38.987 | -0.6% |
| Static line | 1.538 → 1.552 | -1.0% |
| Indexed line | 6.924 → 7.002 | -1.1% |
| Scriptable line | 14.412 → 14.648 | -1.6% |
| Static bar | 4.030 → 4.021 | 0.2% |
| Indexed bar | 5.303 → 5.357 | -1.0% |
| Scriptable bar | 19.450 → 18.878 | 2.9% |

Negative reduction means slower. These controls are close to baseline; no speed
claim is made for them. Scriptable callbacks still run 15001 times per update
for scatter, 5006 for line and 5001 for bar in this matrix.

## Implementation

Scatter resolves every point's options during overflow calculations as well as
position updates. After two ordinary resolutions warm the resolver, each loop
may capture a private static PointOptions template and native indexed color
lists. Context refresh still runs and every result remains fresh and unshared.
Color lists are validated once for each plan; data/element arrays are not
pre-scanned. Native point eligibility is checked as the loop reaches each point.

Overflow only copies raw/parsed entries into contexts and reads native point
sizes, so it needs no scan of coordinate values. Position updates classify each
current parsed item before its original coordinate reads. Unknown reads, active
callbacks or custom points discard the plan before user code executes. Reuse is
not resumed in the remainder. Plans never survive a function or plugin hook.

The production code retains ordinary context setters; it does not use the
unchecked context writes or per-configure validation cache of the prototypes.
The gallery timing wrapper explicitly declares that its native reads remain
ordinary; its timing and plugin-notification counters are unchanged.

## Protocol and correctness

A1/B1/B2/A2, with case order reversed in B2/A2, 800ms warmup and seven 200ms
batches. Separate profile app copies; no builds/tests during timing. Data motion
is outside the stopwatches. Forty timing cells cover line/scatter/bar and static,
indexed and scriptable styles, plus the dense indexed scatter follow-up.

The timing probe's `referenceMatches` is a repeated-update smoke check using the
same implementation. Independent behavior checks come from chart twins whose
reference chart disables the native point capability. They compare geometry,
complete options, selected context fields/key order, callback/getter traces and
explicit activation counters. They cover live colors/data, multiple datasets,
showLine, custom size mutation, effectful parsed values, active callbacks,
scriptable/indexed numeric options, partial ranges, custom scale projections,
custom element-class id getters and cast-before-resolution ordering.

- 10,899 workspace VM tests passed, using Melos package concurrency two.
- 13 focused new regressions passed.
- 233 focused tests passed on each of JavaScript and WebAssembly, including
  native-point coordinate/route guards and cached point-plan ownership.
- Workspace analysis, format check, parity generation and all port checks pass.

No full browser/fixture/golden suite was run for this change. No allocation,
pixel, raster-time, mobile/web performance or FPS claim is made. The saved probe
counts callback/iteration metadata before its untimed final update; `notifies`
includes that update.

## Evidence and reproduction

The JSON files retain all process results and paired comparisons. Compressed
logs retain the checks; validation.json records their scope. metadata.json
records the toolchain, baseline overlay and measured binary hashes. candidate.patch
contains the runtime changes over ba58aa8, the new point-loop module and its new
tests. It includes the baseline changes too; do not apply it on top of
baseline.patch.

For A, create a checkout at ba58aa8 and apply baseline.patch. For B, create a
separate checkout at ba58aa8 and apply candidate.patch. Restore probe.dart.txt as
`.dart_tool/prepared_options/probe.dart` in each. From `apps/chartjs_gallery`:

```
flutter build macos --profile --no-pub -t ../../.dart_tool/prepared_options/probe.dart
```

Save the apps at `/tmp/prepared-options-b.app` (A, the earlier production build)
and `/tmp/scatter-options-b.app` (B). Sign only the temporary copies with the
[category-layout recipe](../category-layout/README.md). Restore run.py.txt and
report.py.txt into `.dart_tool/scatter_options/` without `.txt`. From the main
checkout, with builds/tests idle:

```
python3 .dart_tool/scatter_options/run.py
python3 .dart_tool/scatter_options/report.py
```

The runner writes working results in `.dart_tool/scatter_options`; the reporter
updates this evidence directory. The same path is visible in Gallery → Stress →
Scatter → Indexed colors, using ordinary full updates.
