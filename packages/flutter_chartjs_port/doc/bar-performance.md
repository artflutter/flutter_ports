# Bar update and animation performance investigation

Implementation follow-up: bounded canvas recordings are now implemented in
[ADR 0066](adr/0066-bounded-canvas-recordings.md).
[Performance.md §33](performance.md#33-bounded-native-recordings-for-dense-bar-charts)
records the production comparison and foreground FPS. The analysis below is the
original investigation; its bar-index memo remains an unguarded prototype.

2026-11-02. The 20,000-bar workload has **two separate CPU bottlenecks**:
per-bar index/group discovery during updates, and Flutter's `drawPicture` when
painting the recorded bars into the host. The latter dominates looping animation.
Axis layout and animation interpolation are much smaller costs in this scene.

This investigation retains measurements, profiles and isolated prototypes. It
makes no production runtime or gallery configuration change. The next
implementation should address picture recording/painting first, then guarded
bar-index planning. Neither reducing the item count nor disabling animations is
required to investigate those improvements.

[Evidence, harnesses and reproduction](benchmarks/bar-pipeline/README.md).

## Reproduction and frame budget

The screenshot selects `chart`, `bar`, N=20000, M=0, `upd`. Its dataset update is
43.00 ms, layout 0.71 ms, and dataset draw 14.24 ms. At 60 Hz the entire frame has
16.67 ms. Dataset updating alone exceeds that budget.

The local reproduction uses the existing stress configuration: one bar dataset,
hidden category x/linear y axes, fixed y bounds, shared options, border width 1,
and the default bar grouping/spacing. Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 /
Dart 3.13.7, arm64 profile AOT, Impeller, 800 × 480, DPR 1. The baseline includes
the current axis optimizations. Two final sweeps use forward/reverse case order;
each cell has 800 ms warmup and seven 200 ms batches. No builds/tests ran alongside
timing. The library source hashes stayed unchanged throughout.

| N | Update, excluding draw | Draw inside update | Host paint/record completion | Full update call |
| ---: | ---: | ---: | ---: | ---: |
| 1000 | 1.954 ms | 0.679 ms | 1.700 ms | 4.333 ms |
| 5000 | 9.955 ms | 3.604 ms | 4.886 ms | 18.444 ms |
| 20000 | 41.323 ms | 13.145 ms | 51.482 ms | 105.950 ms |

Full calls sum the three components within each process before taking their
median. They exclude data writes, widget construction, raster work and vsync.
They are not measured FPS. At N=20000, draw-only costs 63.986 ms and a looping
animation frame costs 63.721 ms; the latter consists of 1.513 ms animator work,
13.165 ms draw and 49.043 ms host paint/completion. Improving the update path alone
cannot repair animation FPS.

The existing benchmark's `end` label can be misleading: it includes
`UiCanvasContext.paint`, which calls `Canvas.drawPicture`, as well as both
recording completion and disposal. It does not mean 51 ms in `endRecording`.
Likewise the stress chart's draw stopwatch does not cover this host paint work.
Do not add Flutter build timing to the chart's subphase timings; those intervals
can overlap.

## 1. Native picture painting is the largest opportunity

Separate fresh 10-second CPU profiles put `Canvas.drawPicture` at **50.2%** of
update samples and **77.6%** of animation samples. These inclusive shares overlap
with their callers and are not allocation counts.

The inspected local Flutter source provides the path:

- `engine/src/flutter/lib/ui/painting/canvas.cc`, `Canvas::drawPicture`.
- `engine/src/flutter/display_list/dl_builder.cc`, `DrawDisplayList`.
- `engine/src/flutter/display_list/geometry/dl_rtree.cc`,
  `searchAndConsolidateRects`.
- `engine/src/flutter/display_list/geometry/dl_region.cc`, `setRects`.

The checkout is framework revision `737ba8f885dc774b53b442759999a312c9461e4e`,
engine `cf636b1dfb`. When both display lists have spatial indexes, `DrawDisplayList`
queries the child's bounds and consolidates them into a region. Region construction
sorts by top, inserts into an active list by left, and scans active spans. Many
thin bars with different tops are expensive inputs. The Dart profile does not
symbolize time inside that native algorithm; the attribution is supported by
this source inspection and the following independent reproduction.

A minimal `dart:ui` test, with no Chart.js objects, draws the same deterministic
sequence of thin rectangles. Each result below is the median of two processes.
“Full native call” includes drawing, picture completion, painting into a second
recorder and disposing pictures. The chunked case retains every rectangle in the
same order, in pictures of at most 256 rectangles.

| N | One picture: drawPicture | Chunks: drawPicture | One picture: full native call | Chunks: full native call |
| ---: | ---: | ---: | ---: | ---: |
| 1000 | 1.899 ms | 1.213 ms | 2.257 ms | 1.519 ms |
| 5000 | 3.632 ms | 0.933 ms | 4.525 ms | 1.862 ms |
| 20000 | 50.367 ms | 3.443 ms | 53.941 ms | 7.210 ms |

At N=20000, the native full-call reduction is **86.6%**. Ending the original inner
recording takes about 0.1 ms: the expensive step is embedding its picture. A clip
around the original recording does not resolve the cost.

Twelve local Impeller raster comparisons find **zero differing RGBA channels**
between one picture and chunks: N=1000/5000/20000, opaque/translucent paint,
overlapping/disjoint rectangles, with fractional translation and clipping.
This verifies the rectangle experiment, not the full Canvas 2D implementation.

**Implementation direction:** bound the work per recorded picture while retaining
paint order and existing canvas state. The current bridge already has multiple
pictures and replays clips when starting a recorder. However, it flattens after
more than eight pictures. Simply inserting a split would trigger rasterization
and defeat the purpose. A production design must distinguish chunks of one
recording from accumulated paint generations, preserve the memory bound, and
cover full/partial clears, resize, nested clips, transforms, global composite
operations, layers, gradients/patterns, circle batching and snapshots. Native
paint and `_rasterize` both embed pictures and need consideration.

A combined prebuilt path also makes the CPU embedding cost tiny, but its path
construction is excluded and independent antialiasing/overdraw is not preserved
by assumption. It is a ceiling experiment, not the recommended implementation.

## 2. Repeated bar-index discovery dominates dataset updating

In the update profile, `_calculateBarIndexPixels` has 20.4% of full-call samples,
including `_getAxis` at 11.4% and `getStackIndex` at 3.5%. `_getAxis` repeatedly
allocates dictionaries/key lists, walks datasets and searches scales. Even the
one-dataset scene performs two axis-list discoveries and three first-scale
searches per bar: about 40,000 and 60,000 respectively per update. Stack discovery
also repeats per bar despite `skipNull` being false.

An isolated copy of `BarController` caches axes, the first scale id and the
non-indexed stack index for one `updateElements` pass. It is registered under a
separate id and has **no production compatibility guard**.

| N | Baseline update | Prototype update | Baseline full call | Prototype full call |
| ---: | ---: | ---: | ---: | ---: |
| 1000 | 1.954 ms | 1.056 ms | 4.333 ms | 3.409 ms |
| 5000 | 9.955 ms | 5.055 ms | 18.444 ms | 12.936 ms |
| 20000 | 41.323 ms | 23.425 ms | 105.950 ms | 88.864 ms |

The N=20000 update reduction is **43.3%**, but the full-call reduction is only
**16.1%** while picture painting remains expensive. Retain the tradeoff: draw
inside the prototype update increases from 13.145 to 14.791 ms. Both process
comparisons still improve the full call; this is not a production acceptance run.

Two temporary geometry tests compare all seven checked properties of every bar
at N=1000 and 20000, through four synchronized updates including resize. They pass.
They do not establish callback/subclass equivalence.

**Implementation direction:** a plan scoped to an update, with exact built-in
controller/native-container guards, preserving unknown objects, custom getters,
subclasses and scriptable mutation paths. `skipNull: true` requires data-index
specific stack decisions; it cannot use one stack index. Visibility, dataset/axis
order and stack changes must invalidate a plan. Avoid treating shared element
options alone as proof that no user code can run during the pass.

This revisits the earlier experiment in performance.md §13.7. Its old rejection
and the new draw-component increase should remain visible. Judge a guarded
implementation using paired full-call measurements and meaningful fallback
controls, then update its ADR/divergence record.

## 3. Configuration changes are insufficient by themselves

The initial full scan below is one process, rather than the final paired sweep.
All entries use N=20000. These alternatives change configuration or animation
semantics and are not default changes.

| Configuration | Update/tick | Draw | Paint/completion | Full call |
| --- | ---: | ---: | ---: | ---: |
| Original update | 40.275 | 13.181 | 50.512 | 103.968 |
| `grouped: false` | 27.766 | 13.250 | 50.811 | 91.827 |
| Fixed `barThickness` | 35.646 | 24.927 | 190.315 | 250.888 |
| `borderWidth: 0` | 39.754 | 9.903 | 50.937 | 100.594 |
| Original animation | 1.328 | 12.952 | 49.243 | 63.523 |
| Animate only `y` | 0.426 | 12.852 | 49.278 | 62.556 |

Values are ms. `grouped: false` removes work for this single-dataset scene, but
changes layout for grouped multi-dataset charts. Removing borders modestly
improves drawing and changes appearance; picture painting remains dominant.

Fixed thickness is particularly harmful here: the ruler ratio becomes 1, so
`inflateAmount: 'auto'` becomes 0.33 instead of 0. That activates per-bar clipping
and makes picture painting much more expensive. Fixed thickness with explicit
zero inflation was not measured; do not generalize this result to every thickness
configuration.

The looping animation keeps about 39,710 active objects in the original probe,
including 20,000 with a non-finite height endpoint from reset. The vertical bar's
rendered bounds use y/base, so this height is not the visible bar height. Animating
only y eliminates that work but saves under 1 ms of a roughly 64 ms frame. A global
change that drops those animations would require checking public animation/property
semantics; it is not the priority fix.

## Recommended implementation order and limits

1. Implement and validate bounded native recordings. Measure the actual stress
   host, raster time, memory and snapshots, not just the rectangle microbenchmark.
2. Implement a guarded per-update bar-index plan. Keep dynamic and custom paths
   live and test mutations, hidden/grouped/stacked datasets and both orientations.
3. Profile the remainder: per-bar drawing is still about 13 ms. The native direct
   rectangle recording is around 3.5–3.8 ms; canvas/element preparation is another
   opportunity. The ruler/sample-size path and parsing are smaller update targets.
4. Recheck actual gallery FPS on macOS, Android and web. Keep all bars, callbacks,
   hits, animation semantics and compositing unless a user explicitly chooses a
   configuration/aggregation tradeoff.

The two prototype savings are **not additive measured chart gains**. No combined
production candidate, real-frame FPS improvement, mobile/web result or 60 FPS
claim is made here. Full package/fixture/browser suites were not rerun because
production code was unchanged. The retained build, profiling, pixel and geometry
checks validate the investigation's narrower claims.
