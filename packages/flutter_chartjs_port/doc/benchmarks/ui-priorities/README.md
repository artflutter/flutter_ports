# UI-thread priorities: drawing, data-only eligibility and slow frames

2026-11-04. Follow-up to [native frame verification](../color-verification/README.md).
Baseline is the unchanged ADR 0083 production tree. This is an investigation:
all timers and configuration experiments are isolated under /tmp. No library or
gallery production behavior is changed, and no guard is removed.

Native macOS profile AOT, M3 Max, Flutter 3.47.8 / Dart 3.13.7, 20,000 points,
1036×520/DPR2. The visible temporary host records its occlusion state. Builds,
tests and measurements run separately. Different sessions have different
absolute timings; compare within a run, not against earlier absolute costs.

## 1. Drawing: point preparation is the largest measured block

Coarse timers surround the line draw, entire point loop, labels/title, batch
flush and chart draw. There is no per-point stopwatch. In the connected,
scriptable full update with 200 rotating labels:

| Timed block | Mean ms | Interpretation |
| --- | ---: | --- |
| Point loop | 6.181 | Marker processing, style/path work, batching and any GC occurring here |
| Connected line | 2.178 | Build/replay/stroke of the changing line |
| Labels | 1.778 | Includes the deferred circle-batch flush |
| Title | 0.188 | Remaining title work after the labels have flushed the batch |
| Whole Chart.draw | 10.354 | Parent duration; do not add it to child rows |
| Circle-batch flush | 0.957 | Nested in the label block; do not add it again |

With no overlay labels, the title is the first native drawing operation after
the point loop, and its timer includes that flush instead. The apparent title
cost is therefore not all text processing. The phase logs show one circle-batch
flush per measured chart draw in these scenes. Full rows are in phase-summary.json.

The connected line costs about 0.023 ms on redraw, 2.178 ms on full update and
1.247 ms during ongoing animation with 200 labels. Source inspection explains
this difference: LineController writes line.points during updates, invalidating
its Path2D. Animated lines invalidate the path too. A rebuilt Path2D allocates
LineToCommand objects and is replayed into a native path by uiPathOf. A stationary
redraw can reuse the converted path.

The independent unmodified-build CPU profile supports this split: heavy-update
sample stacks include point drawing in 24.5%, line drawing in 6.9%, and labels
in 10.0%. CircleBatch.flush appears in 5.4%, nested within drawing/label stacks.
These inclusive shares overlap and must not be added. Inlining and sampling
also mean they are not direct stopwatch durations.

**Best drawing candidates:** finish the guarded native-circle entry and reduce
its intermediate circle records/boxed-number work; then investigate the command
objects/replay needed for changing connected paths. The current allocation-runtime
samples include UiPathBuilder.singleCircle, UiCanvasContext._strokeCircle and
fill, as well as LineToCommand application. This locates allocation-related work;
it does not count allocated objects. Public/custom canvas behavior, path visibility,
transforms, clipping and fill/stroke order remain required invariants.

The previous direct-circle estimate remains a prototype estimate from a different
session. This investigation does not measure a new production speedup or establish
that those changes alone close the 60 FPS gap.

## 2. Data-only: the first blocker is intentional suggested x bounds

Every original stress case rejects updateData at `scale:x`. unitScales gives x
`suggestedMin: 0` / `suggestedMax: 1`, while y has explicit min/max. The native
linear scale's data-only guard requires explicit finite numeric bounds. Thus
the first rejection occurs before the controller/color eligibility checks.

A same-binary experiment with explicit x min/max gets past that guard:

| Color mode | Fixed bounds: data-only selected? | Remaining reason |
| --- | --- | --- |
| Static | Yes | No further rejection in this generated scene |
| Indexed | No | No context-independent cached element options |
| Scriptable | No | No context-independent cached options; static-settings validation also rejects the function |

**The fixed-bound shortcut is rejected as an optimization.** The gallery's
suggested bounds are deliberate: it supplies unsorted moving points with
parsing:false. The port follows upstream by setting meta.sorted=true for that
input mode. Explicit user bounds activate binary visible-range selection, which
assumes sorted data. A test with 20,000 points at x=0.5 and a single midpoint at
x=1 produces drawCount=10,000 under fixed bounds, versus 20,000 with suggested
bounds. This affects all three color modes, even when data-only falls back.
The ordinary moving field can clamp points to x=1, so it is a relevant edge case.

The experimental static update portion fell from 2.25→1.84 ms unconnected and
2.23→1.88 ms connected, but **these numbers are not an accepted performance win**:
the configuration is not correct for the workload. Original and experimental
rows remain in bounds-summary.json, explicitly marked rejected.

Six diagnostic tests against the unchanged production library confirm the exact
predicates and boundary behavior. With parsing:true, the same unsorted input is
recognized as unsorted, all 20,000 points remain in the draw range, and static
colors with fixed bounds can select data-only. Its parsing cost was not measured;
this is a correctness result, not a claim that it is faster. Indexed/scriptable
colors retain their separate eligibility restrictions.

**A sound extension needs two separate designs:** safe range/layout retention
for the existing unsorted workload, and eligibility for non-shared color options.
One possible range design proves that changing native numeric data leaves the
retained scale limits unchanged, while preserving the original observation and
hook order. A possible color extension distinguishes paint-only changes from
geometry-dependent options. Arbitrary scriptable callbacks still require live
contexts and mutation-safe behavior. Neither extension is implemented here.
Changing suggested bounds globally, pretending the data is sorted, sorting a
connected line, or bypassing the existing guards is not a valid substitute.

## 3. Updates and slow frames: GC is a substantial part of the tail

The fresh heavy-update CPU sample stacks still include:

| Work | Inclusive sample share |
| --- | ---: |
| LineController.updateElements | 40.2% |
| Config._resolveElementNamedOptions | 16.6% |
| Separate scalar-color loop | 7.8% |
| Prepared resolver validity check | 5.9% |
| Native context reader | 4.4% |
| Stress color callback | 4.5% |

These are overlapping parent/child shares, not additive costs. Map/key reads,
scalar writes, source validation, contexts and callback work remain. The stress
callback contains a modulo operation, visible in CPU samples; its cost is specific
to this callback and cannot be generalized to user callbacks. Removing required
checks or caching callback results would change behavior.

The VM timeline is bounded: although each CPU capture lasts about 16 seconds,
only the final 2.37–4.22 seconds of timeline events were retained in the first
four captures. We pair complete Flutter `Frame` events, identify the UI thread,
and union overlapping GC-labelled spans on that same thread. Background-worker
GC spans are excluded and nested GC phases are not double-counted. Flutter's
Frame event runs from handleBeginFrame through the end of handleDrawFrame.

| Profiled scene | Complete retained frames | Mean UI ms | Mean GC-labelled ms/frame | GC in slowest decile / other frames ms |
| --- | ---: | ---: | ---: | ---: |
| Heavy update | 187 | 18.96 | 4.70 | 7.40 / 4.39 |
| Unconnected update, no labels | 242 | 14.47 | 2.50 | 6.83 / 2.00 |
| Heavy redraw | 284 | 5.58 | 0.03 | 0.24 / 0.00 |
| Heavy animation | 243 | 9.71 | 0.93 | 4.84 / 0.48 |

In the two update captures and animation capture, higher GC-labelled time
accounts for approximately 89–90% of the slowest-decile versus other-frame mean
time difference. This is measured temporal accounting within short instrumented
traces. It does not identify which allocation caused each collection, prove the
same proportion over long runs, or guarantee that removing one allocation source
will remove that duration.

Two repeats disable CPU sampling and retain only Dart/GC timeline streams:

| GC-only control | Retained seconds / frames | Mean UI ms | Mean GC ms/frame | GC slowest decile / other ms |
| --- | ---: | ---: | ---: | ---: |
| Heavy update | 6.78 / 344 | 18.43 | 4.53 | 7.07 / 4.25 |
| Heavy animation | 5.78 / 346 | 11.16 | 1.72 | 6.22 / 1.22 |

Higher GC-labelled time accounts for 88.3% and 82.2%, respectively, of the
slow-frame versus other-frame mean duration gap in these repeats. The result
therefore persists without the CPU sampler. Timeline/GC observation remains
enabled, so these are not observer-free production timing runs.

Heap snapshots contain substantial PointOptions, lists, doubles, records and
line-command objects. However, the returned accumulated counters equal current
counters for every class, as in earlier investigations. **They are live-heap
snapshots, not allocation rates.** No objects/frame or bytes/frame claim is made.
The CPU allocation-runtime sample callers provide additional leads, not an
allocation census. No forced GC was requested during these captures.

**Priority:** reduce avoidable temporary objects in marker/path work, then
measure whether both average cost and GC-heavy slow frames improve. Fresh
user-visible options, observable paths and live contexts must retain their
semantics. Reuse of private scratch storage may be possible; blindly pooling
objects that callbacks can retain is not safe. The current results justify this
work ahead of another broad pass that only trims resolver dispatch.

## Validation, limitations and reproduction

- Unmodified production library hashes match the verified ADR 0083 build.
- Four CPU profiles, two GC-only repeats, 18 phase/fallback cases and 12 bound
  experiment cases are retained. Frame rows require the established viewport,
  at least four readouts and 25 timings; visibility logs have no post-startup
  interruption. Diagnostic timings are not substituted into the prior FPS matrix.
- Six focused unchanged-library tests cover three color modes with parsing
  enabled/disabled and both bound configurations, including the 20k-point omission.
- No production runtime changes, new public APIs or guard relaxations. The full
  VM/browser/fixture/golden suites were not repeated for this investigation.

CPU sampling, timeline collection, GC event delivery and phase timers can affect
execution. The new absolute costs must not be subtracted from the previous
29.12 ms p90 to predict an FPS result. The collected traces motivate candidates;
a production implementation still needs matched measurements and its own tests.

metadata.json has runtime and binary hashes. profile-summary.json has inclusive
functions, disjoint sample categories, per-frame GC intersections and heap
snapshots. Phase/bound summaries preserve all rows. Compressed captures, logs,
window events and the eligibility test output retain the evidence. The raw
CPU/timeline captures are large and are stored compressed.

For reproduction, use an isolated workspace with the pinned SDK and lockfile.
The unchanged profile captures run /tmp/color-verification-production.app from
§53 with capture.py/profile.dart; capture_gc.py disables CPU sampling. The
isolated-diagnostic.patch plus diagnostic_probe.dart.txt and the temporary native
window build the diagnostic target from apps/chartjs_gallery. phases.py runs the
first diagnostic app; bounds.py runs the variant with FIXED_X support, toggling
only that flag in one binary. The phase timers do not alter drawing calls.
Run eligibility_test.dart against the unchanged gallery workspace. The analyzer
and archive scripts reproduce the summaries. Temporary tools are saved as .txt;
restore their original suffixes under .dart_tool/ui_priorities when running them.
