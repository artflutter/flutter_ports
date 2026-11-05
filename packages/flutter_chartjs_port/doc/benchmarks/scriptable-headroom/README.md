# Scriptable line headroom: prepared scalar resolution

2026-11-05. [ADR 0088](../../adr/0088-prepared-scalar-point-resolution.md).
Baseline runtime is 8ed395b / ADR 0087. Native macOS profile AOT, Apple M3 Max,
Flutter 3.47.8 / Dart 3.13.7.

## Profile and implementation

Fresh connected scriptable profiles contain 9,872 samples without labels and
10,329 with 200 labels. With labels, Config option resolution appears in 17.7%
of sampled stacks, scriptable resolution in 15.1%, scalar color resolution in
8.1%, and the stress callback itself in 4.9%. Source validation accounts for
6.2%, context refresh for 4.9%, point drawing for 18.3% and labels for 10.9%.
Inclusive percentages overlap; these are not additive time budgets.

The selected change captures a direct executor for an already-prepared native
scalar point-color plan. It avoids repeated general Config resolver setup and
the successful context/result record. The complete source validator still runs
before execution. Private-plan/key checks run before context; Config generation,
plan identity and original keys are checked after context. Callback and
non-scalar/mutation handling use the existing scalar executor/continuation.

A decline before context takes the existing general path. A failure after context
resumes its ordinary post-context branch with the exact observed context, without
calling either context factory again. Options remain fresh, and every required
callback still runs with its existing arguments/order. Two-argument/contextual
callbacks retain the general resolver. No result cache, sampling, drawing change
or data-only eligibility change is introduced. Only core.config.dart and
helpers.config.dart change at runtime.

An isolated prototype passed 86 focused regressions and improved matched means
about 1 ms. Final production measurements are separate below; prototype results
are retained, not pooled with them.

## Correctness validation

- 11,091 workspace VM tests passed.
- Both full browser suites passed: 4,180 port tests plus 55 test-utils tests on
  each of JavaScript and WebAssembly (4,235 per backend).
- Formatting, analysis, spec cases, fixtures, regenerated parity and all seven
  port checks passed. No macOS golden files were updated.
- Eighteen new native-vs-ordinary cases cover context-time clearing/writes/keys,
  prepared-context failure, replacement plans, callback-time middle/trailing
  fields, descriptors, deletion, cache clear, null/undefined/array/object returns,
  context/callback exceptions and reentrant resolution. Existing varying-color,
  native-plan and controller twins retain broader arity, view and mutation tests.

## Native protocol

The built-in display remains at ID 1, maximum 120 Hz, DPR2, with an anchored
1100×900 window and 1036×520 chart. Visibility, occlusion, display and size logs
invalidate a changed run. Tests/builds and CPU profiling are idle during ordinary
frame measurements. No system refresh settings change.

Matched A/B/B/A processes run 20k connected scriptable points with 200 static or
rotating labels, full update and data-only requests. Each cell runs twelve seconds,
excluding two as warmup. Static/indexed controls run separately. The complete
candidate matrix contains 96 cells: four operations × three color modes ×
connections off/on × 0/50/200 static labels (72), plus 200 rotating labels (24).
Matrix cells run six seconds, excluding two. Means average post-warmup readouts;
process p90s remain separate. A near-60 screen means mean FPS ≥59 and UI/raster
p90 ≤16.67 ms. It is not a sustained-60 or cross-device guarantee.

GC-only captures disable sampling and compare equal final-five-second windows
of complete UI frames, unioning GC intervals on the UI thread. Heap snapshots
are not allocation rates; no forced GC is requested. Diagnostic and ordinary
frame timings are not combined.

## Results

| Labels | Operation | Mean UI before → after ms | Reduction | UI p90 before → after ms |
| --- | --- | ---: | ---: | --- |
| static | update | 14.56 → 13.81 | 5.1% | 15.42 / 15.33 → 14.85 / 14.87 |
| static | data | 14.88 → 14.20 | 4.6% | 15.94 / 15.74 → 15.43 / 15.46 |
| rotating | update | 14.71 → 14.03 | 4.6% | 15.54 / 15.41 → 14.74 / 15.40 |
| rotating | data | 15.07 → 14.27 | 5.3% | 16.09 / 15.96 → 15.43 / 15.72 |

Final matched means improve 4.6–5.3%, about 0.7–0.8 ms. Candidate heavy-case FPS
ranges 61.5–64.3. Static/indexed controls remain close: 7.13→7.08 ms and
11.31→11.48 ms mean UI respectively. These small control differences are not a
new speedup claim.

The complete matrix has 38,433 captured timings. **95/96 cells meet the near-60
screen.** The sole miss is connected scriptable data-only fallback with 50 static
labels: 59.01 FPS, UI p90 16.904 ms. All data-only cells retain full-update fallback.
The largest raster p90 across the matrix is 2.44 ms.

| Labels | Operation | Cases | FPS range | Worst UI p90 ms |
| --- | --- | ---: | ---: | ---: |
| 0/50/200 static | redraw | 18 | 120.0–120.0 | 5.16 |
| 0/50/200 static | full update | 18 | 60.4–120.0 | 15.79 |
| 0/50/200 static | data-only fallback | 18 | 59.0–120.0 | 16.90 |
| 0/50/200 static | animation | 18 | 119.0–120.0 | 8.25 |
| 200 rotating | redraw | 6 | 119.5–120.0 | 5.13 |
| 200 rotating | full update | 6 | 59.2–120.0 | 16.55 |
| 200 rotating | data-only fallback | 6 | 59.5–120.0 | 16.03 |
| 200 rotating | animation | 6 | 112.2–120.0 | 9.44 |

The missed cell received a separate twelve-second A/B/B/A repeat. Baseline mean
UI was 14.47/14.19 ms, UI p90 15.56/14.85 ms and FPS about 59.9. Candidate mean UI
was 13.51/13.64 ms, UI p90 14.52/14.70 ms and FPS 63.9/63.3. The short-matrix miss
remains in the result: the repeat shows variability and improvement, not proof
that the miss cannot recur. The roughly 14 ms UI-p90 headroom target is **not
achieved across the heavy label cases**, and every-mode sustained 60 FPS remains
unproven. Matrix pass counts from different sessions are not matched speedups.

One candidate control and one rotating data-only batch became occluded and were
rejected, then rerun. All accepted visibility logs pass. Rejected raw results
remain separately archived and are excluded from summaries.

## CPU and GC evidence

The final CPU capture contains 10,309 samples. The general Config element
resolution route falls from about 17.7% inclusive in the baseline label profile
to 0.30%; general scriptable element resolution falls from 15.1% to 0.03%.
Its replacement prepared executor accounts for 15.7%, including context/callback
work. The scalar callback path remains at about 8.4% and the stress callback
at 4.8%. Inclusive shares overlap and cannot be subtracted as independent time
savings; they confirm the route change and continued callback execution.

Equal final-five-second GC-only windows contain 297 baseline and 310 candidate
UI frames. Mean GC-labelled UI time changes **2.09→1.73 ms/frame**; slowest-decile
mean changes 2.64→2.54 ms. That is consistent with avoiding temporary successful
resolution records, but it is not an allocation-rate measurement or a precise
causal decomposition of the ordinary-frame gain. GC tails remain material.


## Reproduction and artifacts

metadata.json records library and native framework hashes; validation.json has
the final required checks. summary.json retains matched runs, controls, every
matrix cell and the isolated prototype. visibility.json contains accepted host
events. Raw compressed CPU/GC/heap/frame captures and logs accompany the scripts.

Restore scripts under .dart_tool/scriptable_headroom and use the isolated workspace
/tmp/indexed-triage-work at the pinned SDK/dependencies. The saved native host,
probe/pixel support under its .dart_tool/indexed_triage and harness.patch follow
the earlier indexed-update triage setup. Baseline measurements reuse the verified
ADR 0087 binary; its full source manifest is retained. build.py baseline can
reconstruct it from 8ed395b at the same temporary app path. build.py production
copies the implementation into the isolated library and signs its profile app.
prototype.py uses the saved baseline helper/Config sources as its before inputs.
Run frames.py sequentially under caffeinate, then capture_final.py and
analyze_final.py for separate diagnostics, and report.py for the final summaries.
