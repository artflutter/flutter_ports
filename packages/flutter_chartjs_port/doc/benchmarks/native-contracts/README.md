# Shared native point contracts: verification

2026-11-05. [ADR 0087](../../adr/0087-shared-native-point-contracts.md).
Baseline is 93ef558 (ADR 0086). Apple M3 Max, native macOS profile AOT,
Flutter 3.47.8 / Dart 3.13.7.

## Scope

This refactor shares native chart/point/projection/class predicates and update
preparation prerequisites in point_options.dart. A separate controller-level
module, point_option_preparation.dart, owns common indexed preparation for line
and scatter, plus line resolver preparation. Exact-controller gates remain in
the controllers, where super.runtimeType cannot be replaced by a custom getter.
The scale/chart ownership check remains after the projection capability check.

NativePointResolution now owns its source validation and has a private executor.
Every resolve call validates before invoking the executor or either context
factory. Existing Config/resolver generation checks during callbacks remain.
There is no new eligibility, data scan, cache, projection algorithm or public
library API. This is a maintenance change; no speedup is claimed.

The contracts distinguish weak map identities from live capability/value checks,
and entry validation from callback-time generation checks. Activity is separate
from point capability so scatter overflow retains its original behavior. Line
and scatter retain their different parsed-read/activity observation order.
Bar-specific topology, grid and write contracts and data-only eligibility remain
unchanged. This consolidates the point-option family, not every optimization
into a single global native flag.

## Correctness

- 11,073 workspace VM tests passed, including 55 focused contract/resolver and
  line/scatter regression tests.
- Both full browser suites passed: 4,162 chart-port tests plus 55 test-utils tests
  on each of JavaScript and WebAssembly (4,217 per backend).
- Formatting, analysis, spec-case coverage, fixtures, regenerated parity and all
  seven port checks passed. No macOS golden files were updated.
- New tests check changing capability/class metadata, projection-versus-grid
  scope, plan validation before execution/context callbacks, and validator
  exceptions. Existing twins cover custom/active points, effectful coordinates,
  source mutation, invalidation during callbacks, routes, partial ranges, fresh
  options and context order, and warmed weak-cache lifecycle.

## Native regression protocol

Both binaries use the same temporary probe and window host on the built-in
Retina display (ID 1, maximum 120 Hz, DPR2): 1100×900 window and 1036×520 chart.
Visibility, occlusion, display and size changes invalidate a run. All accepted
host logs are retained. Builds/tests are idle during measurements; no CPU
profiling runs alongside frame timing.

For each of line and scatter, A/B/B/A processes cover full updates with 20k items,
200 static overlay labels, static/indexed/scriptable colors, and connections
off/on. Each cell runs eight seconds with two excluded as warmup: 48 measured
cells total. Means average post-warmup readouts; individual process p90 values
are retained rather than pooled. A separate twelve-second A/B/B/A repeat checks
the connected indexed line case because its broader comparison varied.

This is a targeted refactor-regression comparison, not a new 96-case line matrix
or a claim of every-mode 60 FPS. The preceding optimization's complete matrix
is in [coordinate-cache](../coordinate-cache/README.md).

## Measurements

| Chart | Colors | Connected | Mean UI before → after ms | Change |
| --- | --- | --- | ---: | ---: |
| line | static | off | 6.28 → 6.36 | +1.3% |
| line | static | on | 7.35 → 7.42 | +1.0% |
| line | indexed | off | 10.66 → 10.47 | -1.8% |
| line | indexed | on | 11.78 → 12.08 | +2.5% |
| line | scriptable | off | 14.53 → 13.84 | -4.8% |
| line | scriptable | on | 15.97 → 15.06 | -5.7% |
| scatter | static | off | 9.71 → 9.83 | +1.3% |
| scatter | static | on | 8.41 → 8.45 | +0.5% |
| scatter | indexed | off | 18.94 → 18.79 | -0.8% |
| scatter | indexed | on | 16.03 → 15.70 | -2.1% |
| scatter | scriptable | off | 46.05 → 46.41 | +0.8% |
| scatter | scriptable | on | 24.02 → 24.22 | +0.8% |

Positive change means more UI time. Most paired means differ by about 0–2.5%;
scriptable line means are lower in this sample, with substantial baseline run
variation. These small/variable differences are not evidence of a new speedup.
The separate connected-indexed line repeat is effectively flat: mean UI
11.03→11.01 ms, with baseline p90 12.15/12.24 ms and candidate 11.98/12.00 ms.
No consistent performance regression is demonstrated by these comparisons.

The first narrow-repeat process was briefly occluded and rejected. The complete
retry retained the prescribed visible window. Rejected raw logs are archived
separately and excluded from means and visibility validation of accepted runs.


## Reproduction

metadata.json records all baseline/candidate library hashes and native framework
hashes. validation.json records required check results; summary.json retains all
process rows, p90s and the narrow repeat; visibility.json preserves host events.
Compressed raw results and logs accompany saved scripts and native probe sources.

Restore scripts under .dart_tool/native_contracts, with the isolated workspace
at /tmp/indexed-triage-work, the saved probe/pixel support under its
.dart_tool/indexed_triage, and the saved native host plus harness.patch. Use the
pinned SDK and resolved workspace dependencies. build.py baseline restores the
library from 93ef558; build.py production copies the implementation under review.
Both create separately signed temporary profile apps. Run frames.py and repeat.py
sequentially under caffeinate, then report.py to verify hashes/visibility and
reproduce summaries. The existing triage report documents the host setup.
