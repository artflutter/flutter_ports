# Native line coordinate-cache verification

2026-11-05. [ADR 0086](../../adr/0086-weak-point-coordinate-cache.md), following
[the indexed-update triage](../indexed-update-triage/README.md). Baseline runtime
is ADR 0085 / fd6e040; f87900a adds the triage documentation. Native macOS profile
AOT on Apple M3 Max, Flutter 3.47.8 / Dart 3.13.7.

## Implementation

A controller-owned array remembers accepted native coordinate maps by weak
identity, at absolute point indexes. It fills at most 1,024 new entries per
prepared loop. Stable input warms gradually; replaced maps take ordinary
classification. Slot count follows point count and unsupported paths clear the
array. Old maps are not strongly retained. No coordinate or option value is
cached, and there is no second input scan.

Unlike the isolated prototype, the implementation keeps the classifier's
last-type state local to each update. A warm hit also clears any preceding
custom type from that state so later custom classifications preserve ordinary
reads. SDK implementation classification still uses the existing native
container contract. All coordinate checks, routes, option-plan guards, geometry,
context setters, callbacks and fallback order remain live. Data-only eligibility
is unchanged. Only point_options.dart and controller.line.dart change at runtime.

## Validation

The final workspace VM run passes 11,068 tests. New cases cover the fill budget,
mixed and completely replaced input, constructor representations, growth/shrink,
partial ranges, live null/undefined/foreign coordinates, routed scopes, custom
runtimeType observations and exceptions. Chart twins warm the cache, then change
styles, modes and data topology, execute active callbacks that mutate later
points, throw and recover. They compare geometry, options and context contents
against the ordinary path.

Two early JavaScript runs exposed a test-fixture assumption: typed Map.of and
spread-created maps can have a different implementation type from literals on
DDC. The existing guard intentionally rejects those representations when absent
from its allowlist. The budget fixture now uses the stress workload's supported
Map<String, Object?> representation. A separate test compares each constructor's
cached and uncached eligibility. The production allowlist was not broadened.
The six focused JavaScript cache tests pass; rejected attempts are archived.

Both full browser suites pass: 4,157 chart-port tests plus 55 test-utils tests
on each of JavaScript and WebAssembly (4,212 per backend). Formatting, analysis,
spec cases, fixtures, regenerated parity and all seven port checks pass. No
macOS golden files were updated. Native measurements are recorded below.

## Measurement protocol

Both binaries use identical temporary gallery instrumentation and an anchored
1100×900 window on the built-in display (ID 1, maximum 120 Hz, DPR2), with a
1036×520 chart viewport. Visibility, occlusion, screen and size changes are logged
and invalidate a run. No system refresh setting changes. Builds, tests and CPU
profiling are idle during ordinary frame measurements.

Matched A/B/B/A comparisons run 20k indexed points, connections off/on and 200
static labels, eight seconds per cell, excluding the first two seconds. A
replacement workload swaps every raw map in a beforeUpdate hook on both builds.
Static and scriptable controls run separately. The final matrix covers 96 cells:
four operations × three color modes × connections off/on × 0/50/200 static labels
(72), plus 200 rotating labels (24). Matrix cells run six seconds, excluding two.
Up to two lowest-FPS misses receive twelve-second matched A/B/B/A repeats.

Mean UI averages post-warmup readouts; p90 uses delivered FrameTimings. Individual
process percentiles are retained rather than pooled. A near-60 screen means
mean FPS ≥59 and UI/raster p90 ≤16.67 ms. It is not a sustained-60 guarantee.

Initial-frame diagnostics retain the first 60 delivered FrameTimings of each
fresh process, including initial widget/chart work. They are separate from the
steady-state comparison and do not establish a universal startup latency.
GC-only captures disable CPU sampling and compare equal final-five-second
windows of complete UI frames; GC intervals on the UI thread are unioned.
Heap snapshots describe current objects, not allocation rates or total retained
memory after collection. No forced GC is requested.

## Results

**The bounded cache reduces indexed-update UI work by 27–30% in the matched
stable-map measurements.** It does not establish every-mode 60 FPS.

| Workload | Connected | Mean UI before → after | Reduction | UI p90 before → after |
| --- | --- | ---: | ---: | --- |
| plain | off | 13.22 → 9.21 ms | 30.3% | 14.34 / 14.37 → 10.32 / 10.23 ms |
| plain | on | 14.94 → 10.89 ms | 27.1% | 16.05 / 16.86 → 11.99 / 12.05 ms |
| churn | off | 17.46 → 17.05 ms | 2.3% | 20.25 / 20.45 → 20.15 / 20.30 ms |
| churn | on | 19.49 → 19.14 ms | 1.8% | 22.96 / 21.50 → 21.83 / 22.01 ms |

Replacement-data means are slightly lower in this sample, with comparable p90s;
there is no measured regression like the uncapped prototype's 7–11% penalty.
Do not interpret these small differences as a promised churn speedup. Static and
scriptable controls are effectively unchanged: mean UI 6.79→6.84 ms and
14.35→14.40 ms respectively.

All 32 indexed-color cells in the 96-case matrix meet the near-60 screen. Overall,
90/96 pass, with 38,232 captured frame timings. Six connected scriptable cells
miss: full update with 0/200 static labels, and data-only fallback with 0/50/200
static or 200 rotating labels. Their FPS ranges 57.2–58.6; worst UI p90 is 17.41 ms.
The worst raster p90 in the whole matrix is 2.43 ms. Data-only requests all retain
full-update fallback.

| Labels | Operation | Cases | FPS range | Worst UI p90 ms |
| --- | --- | ---: | ---: | ---: |
| 0/50/200 static | redraw | 18 | 120.0–120.0 | 5.19 |
| 0/50/200 static | full update | 18 | 58.5–120.0 | 16.62 |
| 0/50/200 static | data-only fallback | 18 | 57.9–120.0 | 17.41 |
| 0/50/200 static | animation | 18 | 119.0–120.0 | 8.40 |
| 200 rotating | redraw | 6 | 119.5–120.0 | 5.31 |
| 200 rotating | full update | 6 | 59.5–120.0 | 15.95 |
| 200 rotating | data-only fallback | 6 | 57.2–120.0 | 16.98 |
| 200 rotating | animation | 6 | 119.0–120.0 | 8.48 |

The slowest two cells were repeated for twelve seconds in A/B/B/A order. Both
baseline and candidate then run about 60 FPS: 59.8–60.0 with rotating labels and
60.0–60.5 without labels. UI p90 stays within 14.56–15.52 ms. These misses vary
near the budget; the repeat provides no evidence of a cache regression, and no
basis for a universal sustained-60 claim. Do not compare matrix pass counts with
an older session as if they were a matched baseline.

An earlier animation batch became occluded and was rejected in full. The valid
rerun and all accepted comparisons retained the prescribed display/viewport.
Rejected visibility logs remain archived separately.

## Initial frames, CPU and memory

For fresh stable-map processes, the first 60 delivered UI frames average
13.46–14.56 ms before and 10.86–10.94 ms after. Their UI p90 changes from
14.40–15.71 to 13.06–13.12 ms. Initial maximums are 34.91–37.74 ms before and
31.00–31.39 ms after: initial construction still exceeds one 60-Hz frame.
These samples include widget/chart setup and gradual cache fill.

The final CPU capture contains 9,683 samples. Runtime-type retrieval appears in
about 0.12% of sampled stacks, versus 28.1% in the triage baseline profile.
NativePointCoordinates.accepts accounts for 6.8%; PointOptions.clone for 1.4%.
Inclusive percentages overlap; the main change is avoiding repeated native-type
retrieval, not eliminating coordinate checks or fresh options.

Equal final-five-second GC-only windows contain 298 baseline and 385 candidate
frames. Mean GC-labelled UI time changes 1.72→1.61 ms/frame; the slowest-decile
mean changes 2.66→2.58 ms. This modest change does not explain the roughly 4 ms
ordinary-frame improvement. Diagnostic and ordinary timings are not combined.

The candidate end snapshot has 19,999 weak-reference objects (639,968 bytes),
versus one (32 bytes) at baseline: 19,998 additional entries, matching the 20k
points less two ordinary warmup points. The cache object is 32 bytes; its slot
array additionally holds 20k reference slots. These are object-class snapshot
figures, not a precise total process-memory delta. Cache fill allocations are
bounded per loop, and weak targets do not retain replaced user maps.

## Reproduction and artifacts

metadata.json identifies both binaries and every library source hash. Restore
saved scripts under .dart_tool/native_map_cache and the probe under
/tmp/indexed-triage-work/.dart_tool/indexed_triage. Use an isolated workspace at
f87900a with the pinned SDK/dependencies, the saved native host and churn harness
patch, following the triage setup. build.py baseline restores library files from
f87900a; build.py production copies the implementation under review. Both build
and sign temporary profile apps. frames.py runs ordinary timings under
caffeinate; capture.py/profile.dart run diagnostic captures afterward.

summary.json retains individual process rows, controls, all matrix cells,
initial-frame samples and repeat results. visibility.json preserves host events;
validation.json records the final required checks. Compressed raw profiles,
timelines, heap snapshots, logs and probe sources accompany the report.
