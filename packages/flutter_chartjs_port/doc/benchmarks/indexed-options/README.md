# Native indexed element-option evidence

2026-11-03. [ADR 0076](../../adr/0076-indexed-element-options.md),
[performance.md §42](../../performance.md#42-cached-native-indexed-element-options).
Baseline: `bd3f8b5`, including the existing incremental-update implementation.
`metadata.json` identifies the toolchain and baseline/candidate library hashes.
`candidate.patch` contains the final production changes relative to that baseline.

## Final measurements

`a1.json`, `b1.json`, `b2.json`, `a2.json` are independent process results in
A/B/B/A order. A is the original implementation, B the optimized version. Each
runs the same 5000-element line/bar/radar scenes with a static color, a one-entry
list containing that color, and a callback returning that color. B2/A2 reverse
the case order. Each case warms for 800ms and measures seven 200ms batches.

`arc-*.json` are a separate A/B/B/A fallback control: `theme.switch`, doughnut,
N=1000. This exercises indexed arc options, which remain on ordinary resolution.
`summary.json` retains the individual paired gains and the aggregated results.
The full CPU estimate sums update/draw/paint-end phase medians within each
process before aggregating the two processes. It is not a full-call percentile.

Both process results and individual paired gains are retained. The mean is not
a precise universal gain; see summary.json for the final process comparisons. There is no claim about raster cost,
FPS, widget scheduling, release-vs-profile overhead, Android or web performance.
No tests/builds ran alongside the measured loops.

## Preliminary work retained

- `initial-measurements.json.gz`: useful indexed gains, but scriptable fallback
  regressed because each element retried eligibility and rebuilt probe lists.
- `second-measurements.json.gz`: caching rejected eligibility reduced that cost.
  The two `second-profile-*.json.gz` CPU captures then found native-list
  classification at 25.2% of indexed samples and 15.8% of scriptable samples.
  Generic `runtimeType` calls were a significant part of that cost.
- `third-measurements.json.gz`: the controller declares containers it creates,
  qualifying key-producing scopes only when their identity changes. The final
  revision additionally makes rejection conservative across key shapes and
  declines unsupported result classes before any list probes.

`pre-hardening-measurements.json.gz` retains the comparison before the final
large-integer rounding and Color-subclass/opaque-value regressions were added.
Those corrections were rechecked on VM, JS and Wasm and rebuilt for the final
comparison. These preliminary results are not mixed into the final comparison.

`pre-store-order-measurements.json.gz` retains the subsequent numeric/color
hardening run, before restoring the exact pre-context `$shared` store and removing
a duplicate fallback store. The final source has a differential regression for
context factories that observe or mutate the supplied result.

The final native path preserves context refresh, independent mutable options, live list
contents, raw numeric kinds and ordinary fallbacks. It does not promise static
color performance for indexed colors.

## Reproduction

Use the repository and toolchain in metadata. Restore `probe.dart.txt`,
`extra.dart.txt` and `verify_test.dart.txt` into `.dart_tool/library_audit/`, dropping
the `.txt` suffix. These are the same benchmark scenes used by the earlier
[library audit](../library-audit/README.md), with no production benchmark changes.

Build from `apps/chartjs_gallery`:

```
flutter build macos --profile -t ../../.dart_tool/library_audit/probe.dart --no-pub
```

Keep independently built copies at `/tmp/chart-library-audit-extra.app` (baseline)
and `/tmp/chart-indexed-options.app` (candidate). Sign only those temporary copies
using the [category-layout entitlement recipe](../category-layout/README.md).
The executable remains `Contents/MacOS/chartjs_gallery`. The production app's
signing and sandbox are unchanged.

Restore `measure.py.txt` and `report.py.txt` into `.dart_tool/indexed_options/`,
dropping `.txt`, and run sequentially from the repository root:

```
python3 .dart_tool/indexed_options/measure.py
python3 .dart_tool/indexed_options/report.py
```

Both scripts operate on that working directory; they do not overwrite this
committed evidence. The optional `profile.py.txt` and `capture.dart.txt` reproduce
10-second candidate CPU captures through the local VM service. They require
`PROFILE=1` in the launcher, as the retained script supplies.

After measurement, from the gallery directory:

```
flutter test ../../.dart_tool/library_audit/verify_test.dart --no-pub --reporter expanded
```

This checks all 5000 elements after three synchronized changes across nine scenes,
and explicitly confirms indexed-path activation for line/bar/radar. It compares
parsed values, geometry and selected styles, not raster pixels. The permanent
24-case framework-free suite lives in `test/port/core/indexed_element_options_test.dart`.

## Verification

The compressed logs retain workspace tests, the full JS/Wasm suites, focused
regressions, geometry/activation verification, analysis, formatting, fixtures,
parity generation and port checks. `validation.json` records completion and scope.
No public export list, generated option schema/output, golden image or upstream
pin changed. Existing gallery/design work was left intact.
