# Library-wide performance audit

2026-11-03. Reviewed the current implementation at `bd3f8b5`, including ADR 0074
incremental updates. No production code was changed. The strongest remaining
shared bottleneck is **element-option resolution when any option needs a data
context**. The next priorities are full-update cache invalidation and the common
canvas/element drawing paths. Dataset metadata lookup is a real scaling issue,
but is smaller than configuration work in the measured many-dataset scene.

This is a profiling investigation, not an upstream JavaScript speed comparison
or proof that every measured cost can be removed while preserving behavior.
Several costs follow Chart.js semantics; optimization needs guarded native paths.

[Raw evidence, source snapshots and reproduction](benchmarks/library-audit/README.md).

Implementation follow-up: [ADR 0076](adr/0076-indexed-element-options.md) adds a
guarded native indexed point/bar option plan. The findings below are the original
baseline; [the implementation evidence](benchmarks/indexed-options/README.md)
records the improvement and its fallback controls.


## Measurement scope

- macOS 27.0.1, arm64, Flutter 3.47.8 / Dart 3.13.7, profile AOT, native canvas.
- Existing gallery frameless harness, 800 × 480, DPR 1. Seven 200 ms batches
  after 800 ms warmup; two processes with forward/reverse case order.
- 70 timing cells: all eight chart types at 1,000 and 5,000 elements, indexed
  and scriptable line options, same-color controls for three chart types, and
  a fixed-total-point dataset-count sweep. Seven separate 10-second CPU captures.
- `update` below excludes drawing. `draw` and `paint/end` are separate CPU costs.
  Full CPU estimates sum phase medians within each process, then average the
  two processes. They are not a median of individual full calls or frame percentiles.
- Source simulation/writes are outside benchmark phase timings. CPU profiles
  include the surrounding loop, including these writes. Inclusive profile shares
  overlap and must not be added together.
- No concurrent builds/tests during timing. No raster, vsync, widget rebuild,
  interaction-latency, mobile, web or multi-chart dashboard timings were collected.
  These measurements do not establish FPS or a cross-platform speed ratio.

## 1. Highest priority: one dynamic option makes all element options expensive

A static color, a one-entry indexed color list and a callback returning that
same color produce these update costs at 5,000 elements:

| Chart | Static color | One-entry list | Constant callback | List/static |
| --- | ---: | ---: | ---: | ---: |
| Line | 0.571 ms | 12.329 ms | 12.227 ms | 21.6× |
| Bar | 1.277 ms | 15.170 ms | 14.927 ms | 11.9× |
| Radar | 1.754 ms | 14.144 ms | 13.742 ms | 8.1× |

The corresponding full CPU estimates for static → indexed are 1.403 → 13.264 ms
(line), 4.006 → 18.163 ms (bar), and 3.840 → 16.473 ms (radar). A constant-returning
callback still needs to run, but these controls isolate substantial framework
work around it. The indexed case invokes no user color callback.

The original alternating-color line cases independently reproduce the result:
0.588 ms static, 12.120 ms indexed, 12.382 ms scriptable. In the indexed profile,
`DatasetController.resolveDataElementOptions` accounts for **84.0%** of all
samples, `Config.resolveElementNamedOptions` for 74.1%, `_needContextKeys` for
13.0%, `OptionView.readKey` for 30.3%, and `_Cache.set` for 8.8%.

The source chain is:

- [DatasetController._resolveElementOptions](../lib/src/core/core.datasetController.dart),
  lines 1919–1983: cache reuse requires `$shared`; otherwise it constructs
  prefixes, discovers option keys, obtains scopes and resolves a fresh result
  for each element. Bars also lose eligibility for their shared-option bulk path.
- [Config.resolveElementNamedOptions](../lib/src/core/core.config.dart),
  lines 812–850: scans descriptors, attaches contextual views, then reads and
  stores **every** option, even when only background color varies.
- [OptionView and its cache](../lib/src/helpers/helpers.config.dart): the typed
  API still performs generic slot access, descriptor dispatch and cache handling.
  `Subtype1TestCache` and `Subtype2TestCache` have 8.4% and 3.5% self samples;
  string equality has 8.1%. These are runtime work across this path, not evidence
  of one expensive user callback.
- [DatasetController.getContext](../lib/src/core/core.datasetController.dart),
  line 1842, refreshes six context fields per element. Each typed setter calls
  [ContextObject._claim](../lib/src/helpers/helpers.options.dart), line 588,
  which searches a string list. `_claim` has 3.7% inclusive samples here.

**Recommended investigation:** prepare the ordered element-key/descriptor work
once per valid resolution generation; distinguish static fields from fields
requiring a context; specialize native indexable values before tackling arbitrary
callbacks. Keep callback invocation order, dependencies on other options, routes,
custom objects and mutation visibility. A callback may change options or parsed
values, so blindly memoizing its result or hoisting all reads is incorrect.

This is the best first target because the same base controller/resolver serves
all built-in chart types. The measured ratios above apply to the three tested
controls, not automatically to the remaining five types.

## 2. Full updates repeatedly discard useful configuration work

[Chart._updateFull](../lib/src/core/core.controller.dart), line 1508, starts with
`config.update()`, rebuilds chart options, updates scales and invalidates plugins.
[Config.update/clearCache](../lib/src/core/core.config.dart), lines 526–535,
clear both scope and resolver caches. Each
[DatasetController.configure](../lib/src/core/core.datasetController.dart), line
1310, recreates its option view and clears element-option and animation caches.
This repeats even for a static configuration in `update('none')`.

At a fixed **5,000 total points**, with static styles, hidden fixed scales,
animations off and plugins disabled:

| Datasets | Points per dataset | Update CPU | Full CPU estimate |
| ---: | ---: | ---: | ---: |
| 1 | 5,000 | 0.518 ms | 1.355 ms |
| 10 | 500 | 0.984 ms | 1.815 ms |
| 100 | 50 | 5.653 ms | 6.558 ms |
| 500 | 10 | 28.812 ms | 30.351 ms |

The 500-dataset profile attributes **30.2%** to `_mergeScaleConfig` and **44.8%**
to `_resolveElementOptions`. They are distinct major branches of full updating.
Thus this workload is primarily configuration-bound despite having few points
per series. This sweep repeats an unchanged configuration/data payload; it is
specifically a measurement of the full lifecycle, not moving-data simulation.

`Chart.updateData()` already addresses part of this problem. It must not be
reported as missing. The remaining access/coverage gap is that
[ChartView._update](../lib/src/widgets/chart_view.dart), lines 623–680, always
calls `chart.update(...)` after applying config changes. A typed config with new
data does not automatically select the incremental lifecycle; `updateMode: 'none'`
also remains a full update. Users can call `updateData()` imperatively.

The incremental contract intentionally falls back for unsupported plugins,
active animations, unsuitable ranges/settings, structural changes and custom
components. Function-valued settings are also generally excluded by
[staticDataUpdateOptions](../lib/src/core/data_update.dart), line 115. These
restrictions preserve semantics; bypassing them is not a performance fix.

**Recommended investigation:** explicit widget-level data-only updates for
eligible typed configurations, plus generation/version tracking for stable
configuration. Preserve the full raw-mutation lifecycle. Benchmark many datasets
as well as many points. An opt-in data-only mode must specify animation and plugin
behavior; it cannot silently replace default animated updates.

## 3. Shared drawing infrastructure remains a substantial cost

Current baseline measurements at 5,000 elements:

| Chart | Update | Draw | Paint/end | Drawing share of full CPU estimate |
| --- | ---: | ---: | ---: | ---: |
| Line, static | 0.588 ms | 0.632 ms | 0.203 ms | 59% |
| Bar | 1.257 ms | 2.011 ms | 0.710 ms | 68% |
| Bubble | 3.596 ms | 2.621 ms | 1.889 ms | 56% |
| Pie | 1.488 ms | 7.522 ms | 0.383 ms | 84% |
| Doughnut | 1.503 ms | 9.066 ms | 0.524 ms | 86% |
| Polar area | 2.587 ms | 7.546 ms | 1.276 ms | 77% |

The static line profile places 38.7% of samples under `PointElement.draw`, 25.7%
under `drawPointLegend`, and 12.4% under `CircleBatch.flush`. Although native
circle batching exists, each point still traverses generic point-style and
Canvas-2D preparation before reaching it. See
[helpers.canvas.dart](../lib/src/helpers/helpers.canvas.dart), line 297, and
[canvas_ui_batch.dart](../lib/src/canvas/canvas_ui_batch.dart).

For bubbles, `CircleBatch._drawDirect` has 21.3% inclusive samples: differing
radii break same-radius runs, so the ordinary circle path remains material.
This is not evidence that the existing batch optimization is broken.

Pie profiling puts 73.9% under `ArcElement.draw`, including 43.6% under border
drawing and 10.9% under `UiPathBuilder._replay`. Native `drawPath` and `drawArc`
account for 17.8% and 13.3% respectively. See
[element.arc.dart](../lib/src/elements/element.arc.dart), line 1534, and
[canvas_ui_path.dart](../lib/src/canvas/canvas_ui_path.dart).

**Recommended investigation:** guarded direct point/arc commands for ordinary
native elements, following the existing native rectangular-bar approach. Measure
bridge preparation separately from native draw/recording cost. Preserve paint
order, clipping, transforms, alpha, borders and hit geometry. Arbitrarily combining
paths, sorting by style or reducing point counts changes semantics. Display-density
reduction is a separate explicit product feature, not a transparent optimization.

The prior unbounded-picture and bar-axis-discovery problems have already received
production fixes. This audit does not revive their historical timings as current
bottlenecks. Existing bar drawing still has a native cost: the bar profile places
39.1% under `tryDrawRectBar` and 17.7% under host paint.

## 4. Allocation and copying deserve a focused follow-up

There are concrete repeated allocations, but this audit does **not** establish
an allocation rate or GC percentage:

- `_Cache` promotes after eight entries to a `Uint16List` covering all **334**
  `OptionKey` values: **668 bytes of payload**, plus object overhead, key/value
  lists and a name map. Short-lived contextual views can reach this threshold.
  Reducing cache construction should accompany finding 1; simply changing the
  threshold could trade allocation for slower lookup.
- `_cloneIfNotShared` copies resolved options on cache hits for controllers that
  do not share them. The static scatter update costs 1.192 ms against 0.588 ms
  for the comparable static line scene. That difference has multiple causes and
  is not a measured clone-only saving.
- Bubble parsing eagerly calls `resolveDataElementOptions` as the fallback
  argument even when `r` is supplied, then overflow computation and element
  updating resolve options again. Its override clones shared options before
  applying the per-point radius. See
  [controller.bubble.dart](../lib/src/controllers/controller.bubble.dart), lines
  188–243 and 346–372. The override has **22.8%** inclusive samples in the bubble
  profile. This is total resolution work, not 22.8% allocation/GC.
- Primitive parsing still constructs fresh parsed records. The guarded primitive
  parser already exists; fresh records are partly an observable identity choice.

**Recommended investigation:** compact per-view caches, presence bits for typed
context fields, and guarded reduction of repeated option copies/resolution.
Do not share mutable option objects or reuse parsed records without checking
public identity, mutation and callback behavior.

Six fixed-count allocation probes requested VM allocation profiles before/after
20 updates. All `accumulatedSize` fields equaled `bytesCurrent`, including runtime
classes, and totals did not provide valid cumulative allocation deltas. Their raw
outputs are retained and explicitly excluded from allocation-rate claims.

## 5. Dataset metadata lookup adds quadratic work

[Chart.getDatasetMeta](../lib/src/core/core.controller.dart), line 2177, searches
`metasets` backwards by dataset identity. Repeated for every dataset, one complete
lookup sweep has O(D²) comparisons. Full updates perform several such sweeps;
the incremental path also calls it per dataset.

Measured time for one lookup of every dataset, averaged across 100 sweeps:

| Dataset count | Sweep time |
| ---: | ---: |
| 10 | 0.605 µs |
| 100 | 15.880 µs |
| 500 | 290.160 µs |

The 500-dataset CPU profile places **2.7%** in `getDatasetMeta`. This is a valid
shared improvement target, but much smaller than the cache rebuilding in finding
2. Small timings are exploratory and have no separate confidence interval.

**Recommended investigation:** an identity-indexed metadata table or a guarded
current-index shortcut. Preserve reordering, deletion and the last-match behavior
when a dataset object occurs more than once. Do not substitute `metasets[index]`
without those checks.

## Implementation order and validation

Start with native indexed-option resolution, then configuration retention and
widget access to incremental updates. Next address common point/arc preparation.
Treat metadata indexing and compact context/cache storage as supporting changes,
not substitutes for the large shared paths.

For each candidate, keep an unchanged full-call control and measure the complete
supported/fallback matrix. Add callback mutation, default-route, custom-component,
option identity and plugin lifecycle checks before accepting a speedup. Repeat on
Android and both web backends; Dart type-test, allocation and native rendering
costs are platform-dependent.

The investigation changed no production source and did not rerun the entire
parity/fixture suite. A focused temporary test compares all 5,000 elements after
three synchronized data changes for each same-color control: parsed values,
geometry and selected styles. This validates those controls, not pixel parity or
any proposed optimization. No golden files were written.
