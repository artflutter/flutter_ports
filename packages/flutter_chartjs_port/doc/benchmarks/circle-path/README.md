# Scalar circles and compact native paths

2026-11-04. [ADR 0084](../../adr/0084-scalar-circles-and-compact-paths.md).
Baseline is the ADR 0083 production tree, including earlier uncommitted work.
Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7, native profile AOT.

## Implemented behavior

The native canvas reads recognized circle geometry as scalar doubles and passes
those values directly to batching. The existing singleCircle record getter is
preserved for observers. Circle recognition, transforms, state, paint setup,
batching limits, quantization, fill/stroke order and fallback calls are unchanged.

Path2D packs unobserved move/line/close commands into private Float64/code buffers.
Native conversion replays those scalars directly into the exact UiPathBuilder,
without constructing one command object per segment. Complex commands and the
first read of commands materialize an ordinary growable command list. That list
has stable identity and receives every subsequent append. Observing commands
pays this one-time materialization cost; this pass does not claim that custom
or command-inspecting consumers are faster.

Public replay retains the original loop and platform-specific list mutation
behavior. Internal replay is used only by uiPathOf with its known synchronous
native builder. Cache/version behavior, including the existing same-length list
mutation behavior, remains. No callback-visible object is pooled. No chart,
option, data-only or sorted-data eligibility guard changes.

## Rendering and compatibility validation

All **300 native baseline/candidate RGBA comparisons are byte-identical**:
216 circle scenes and 84 path scenes. Coverage includes DPR1/2, small/large
circles, alpha and indexed colors, rotation/nonuniform scale, clipping, dashes,
open/closed/mixed paths, exposed/compact storage, command mutation and paths
with 20,000 line segments. Native probes wait two seconds for startup before
rendering, following the startup finding in §52. Hashes and the full probe are
retained. Existing native canvas tests additionally cover invalid geometry,
compositing, recording boundaries and shape fallbacks.

Regressions pin stable command-list identity, retained command objects, appends
and clearing after observation, non-finite/signed-zero coordinates, live command
replacement during replay, count changes and native cache invalidation. Custom
replay is compared with the original loop, not a stronger cross-platform
iterator contract. An exact pre-change Path2D copy confirms that JavaScript
already visits a command appended by a callback; VM self-replay retains its
concurrent-modification error. Negative zero is parsed at runtime in the test
because the JavaScript constant path canonicalized its earlier literal.

## Matched native frame measurements

Both builds use the same frame/pixel probe and floating, visible native host.
The chart is 1036×520/DPR2 in an 1100×900 window, with 20,000 points. Each case
runs eight seconds, excluding the first two seconds. Rows require at least four
readouts, 25 captured timings, the exact viewport and no post-startup recorded
visibility interruption. Builds/tests are idle during measurement.

The matrix has 20 cases per build: scriptable redraw/full-update/animation ×
connections off/on × 0/200 rotating labels, plus static/indexed update/animation
controls with 200 rotating labels. Zero-label rotation has no visible effect.
Data-only is not repeated: its guards/lifecycle are unchanged and the previous
stress cases use full-update fallback. This is not a new 96-cell all-mode matrix.

Mean UI is the mean of post-warmup readouts. UI p90 uses delivered FrameTimings;
late timing batches can be absent. These short local runs are not sustained or
cross-device guarantees. Display rates are not capped at 60. Absolute costs
vary across processes; use matched comparisons and retain all original rows.

| Operation | Colors | Connected | Labels | Mean UI ms before → after | UI p90 ms before → after | FPS before → after |
| --- | --- | --- | ---: | ---: | ---: | ---: |
| draw | scriptable | off | 0 | 5.06 → 4.41 | 5.12 → 4.46 | 60.0 → 60.0 |
| draw | scriptable | off | 200 | 5.98 → 5.88 | 6.16 → 6.10 | 60.0 → 60.0 |
| draw | scriptable | on | 0 | 5.13 → 4.37 | 5.21 → 4.42 | 60.0 → 60.0 |
| draw | scriptable | on | 200 | 6.00 → 5.35 | 6.16 → 5.47 | 60.0 → 60.0 |
| update | scriptable | off | 0 | 15.43 → 13.14 | 18.15 → 13.48 | 60.0 → 59.8 |
| update | scriptable | off | 200 | 15.90 → 14.74 | 18.19 → 16.80 | 59.5 → 60.0 |
| update | scriptable | on | 0 | 20.05 → 17.69 | 23.26 → 20.82 | 45.7 → 52.5 |
| update | scriptable | on | 200 | 22.35 → 18.55 | 25.35 → 21.89 | 40.6 → 49.3 |
| animate | scriptable | off | 0 | 9.38 → 7.53 | 9.43 → 7.82 | 60.0 → 60.0 |
| animate | scriptable | off | 200 | 10.94 → 8.61 | 10.89 → 8.98 | 59.0 → 60.0 |
| animate | scriptable | on | 0 | 15.70 → 11.26 | 26.06 → 15.36 | 52.1 → 60.1 |
| animate | scriptable | on | 200 | 13.05 → 11.35 | 18.84 → 14.25 | 59.7 → 59.8 |
| update | static | off | 200 | 7.56 → 6.72 | 7.94 → 6.88 | 60.0 → 60.0 |
| update | static | on | 200 | 8.77 → 7.99 | 8.95 → 8.43 | 59.9 → 59.8 |
| animate | static | off | 200 | 6.32 → 5.76 | 6.42 → 5.77 | 60.0 → 60.0 |
| animate | static | on | 200 | 7.98 → 7.72 | 8.67 → 11.61 | 59.8 → 60.0 |
| update | indexed | off | 200 | 15.57 → 14.58 | 16.93 → 16.26 | 59.7 → 59.8 |
| update | indexed | on | 200 | 18.90 → 15.97 | 21.52 → 17.64 | 48.5 → 59.3 |
| animate | indexed | off | 200 | 8.04 → 7.82 | 8.14 → 8.13 | 107.6 → 60.0 |
| animate | indexed | on | 200 | 10.17 → 11.19 | 10.74 → 13.94 | 91.6 → 59.9 |

All paired mean UI values improve except the first connected indexed-animation
control (10.17→11.19 ms). Its separate A/B/B/A repeat is preserved below; no row
has been discarded because it was unfavorable.

## Longer heavy-case repeats

Twelve seconds per case, A1/B1/B2/A2. A means baseline; B means production.
Both scenes use connected scriptable points and 200 rotating labels.

| Operation | Run | Mean UI ms | UI p90 ms | FPS |
| --- | --- | ---: | ---: | ---: |
| update | a1 | 19.08 | 21.32 | 49.2 |
| update | b1 | 16.22 | 18.13 | 59.0 |
| update | b2 | 16.67 | 18.48 | 57.8 |
| update | a2 | 19.01 | 21.26 | 49.2 |
| animate | a1 | 11.17 | 14.91 | 60.0 |
| animate | b1 | 9.93 | 13.20 | 60.0 |
| animate | b2 | 11.13 | 14.83 | 59.8 |
| animate | a2 | 11.71 | 16.09 | 60.0 |

Across the two process means, heavy full update falls **19.04→16.44 ms (13.7%)**.
Both pairs improve by about 12.3–15.0%. UI p90 falls from 21.26–21.32 ms to
18.13–18.48 ms. FPS moves from about 49 to 58–59. The earlier eight-second matrix
also improves, but has different absolute costs; both sets remain in the evidence.

Heavy animation falls **11.44→10.53 ms (8.0%)**. Its two paired changes vary
substantially, about 4.9–11.1%; the result is not an identical gain in every run.

The indexed-animation control repeat measures baseline mean UI 11.79/12.33 ms
and production 10.31/10.17 ms. UI p90 is 16.23/17.33 versus 13.13/13.07 ms.
The initial slowdown does not reproduce; the repeat averages improve about 15%.
The original control remains in the table and raw data.

## GC and slow frames

Separate baseline/candidate traces disable CPU sampling and enable Dart/GC
streams. After four seconds of warmup, each capture spans roughly 16 seconds.
Only complete retained Flutter UI Frame events are analyzed. Overlapping/nested
GC-labelled intervals on the UI thread are unioned; background-worker GC is
excluded. The bounded VM timeline retains different durations in each process,
so the report also compares the same final three seconds of each capture.

These are diagnostic timeline durations, not the uninstrumented frame readouts
above. Timeline/GC collection can affect execution; neither table is substituted
for the ordinary frame comparison. No forced GC is requested.

| GC-only trace | Retained seconds / frames | Mean UI Frame ms | Mean GC ms/frame | Slowest-decile mean GC ms | UI Frame p90 ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| gc-a-update | 6.97 / 340 | 19.33 | 5.16 | 9.49 | 21.78 |
| gc-b-update | 10.43 / 573 | 17.47 | 3.74 | 7.96 | 19.83 |
| gc-a-animate | 5.81 / 348 | 10.87 | 1.68 | 5.98 | 14.94 |
| gc-b-animate | 6.89 / 414 | 10.23 | 1.59 | 5.42 | 13.70 |

Heavy-update mean GC-labelled UI time falls **5.16→3.74 ms/frame (about 28%)**.
The slowest-decile mean GC time also falls, 9.49→7.96 ms. This supports lower
allocation/collection pressure in the changed workload, but is not a count of
allocations or a guarantee that each collection becomes shorter.

| Final three seconds | Frames | Mean GC ms/frame | Slowest-decile mean GC ms | UI Frame p90 ms |
| --- | ---: | ---: | ---: | ---: |
| gc-a-update | 144 | 5.38 | 10.68 | 22.29 |
| gc-b-update | 163 | 3.83 | 6.74 | 19.58 |
| gc-a-animate | 180 | 1.64 | 5.74 | 15.01 |
| gc-b-animate | 180 | 1.62 | 5.60 | 14.12 |

The equal-duration update comparison also improves: mean GC 5.38→3.83 ms/frame,
slowest-decile GC 10.68→6.74 ms, UI Frame p90 22.29→19.58 ms. Animation mean GC
changes only slightly (1.68→1.59 ms over the retained traces; 1.64→1.62 ms in the
matched windows). **No substantial animation-GC reduction is claimed.** Its
ordinary frame timings improve, but allocator work outside the changed circle/
path representation remains.

Heap accumulated counters still equal current counters. These are snapshots,
not bytes/frame or objects/frame measurements. Raw heap/timeline data and the
analysis script are retained for inspection. The remaining GC and callback/
context/element-update costs have not been eliminated.

## Result and validation scope

**60 FPS in every mode remains unmet.** Repeated connected full updates average
near the 16.67 ms budget but their UI p90 remains 18.13–18.48 ms, without comfortable
headroom. The first matrix includes a 21.89 ms p90 for that same heavy case.
This implementation is an incremental reduction, not completion of the target.

- 11,034 workspace VM tests passed; 58 focused canvas/path tests passed again
  after finalizing the replay oracle and signed-zero test.
- 247 focused tests passed on each of JavaScript and WebAssembly.
- Fixture validation passed across 26 files. Workspace analysis and formatting,
  parity generation and all seven port checks passed.
- 300 native RGBA comparisons matched exactly. All 40 initial paired cells,
  eight heavy repeat cells and four indexed-control repeat cells passed viewport,
  sample-count and visibility checks. Four separate GC captures passed checks.
- Production source hashes match the compiled candidate snapshot. The preserved
  baseline matches the library before this pass. No experiment switches exist
  in the production library.

No full browser, golden or mobile suite was run. A local Mac does not update
the platform-pinned goldens. Data-only support remains separate work.

## Reproduction and artifacts

Use isolated workspace copies with the pinned SDK and lockfile. Apply
baseline-overlay.patch to the delivered three runtime files for the baseline;
earlier ADRs remain. Restore probe.dart.txt and pixels.dart.txt under
.dart_tool/circle_path, and use the saved MainFlutterWindow.swift.txt. From the
isolated apps/chartjs_gallery build both variants with:

`flutter build macos --profile --no-pub --target ../../.dart_tool/circle_path/probe.dart`

Copy them to /tmp/circle-path-baseline.app and /tmp/circle-path-production.app,
and ad-hoc sign the temporary copies with ../category-layout/probe.entitlements.
Restore scripts under .dart_tool/circle_path. Run pixels.py, frames.py and
indexed_repeat.py sequentially with builds/tests idle, under caffeinate. Then
run gc_capture.py with gc_profile.dart; CPU sampling stays disabled. analyze_gc.py
and report.py reproduce the numeric summaries. Native test baselines and browser
replay investigation logs remain archived alongside successful validation.

metadata.json records source/framework hashes and protocols. summary.json retains
all frame pairs, repeats and GC per-frame intersections; pixel-comparison.json
retains all scene hashes. Compressed results, logs, timeline/heap captures and
window events preserve the raw evidence. The baseline overlay reverses only this pass; earlier and unrelated user
changes remain.
