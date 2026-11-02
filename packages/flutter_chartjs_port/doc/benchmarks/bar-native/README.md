# Native rectangular bar drawing evidence

Baseline: `5dafa22`, the validated canvas, scalar-geometry and bulk-update work.
Candidate: apply `candidate.patch` and place `canvas_rect_bar.dart.txt` at
`packages/flutter_chartjs_port/lib/src/canvas/canvas_rect_bar.dart`. See ADR 0070
and performance.md §37. This change reduces drawing preparation, not bar count.

## Reproduction

Copy `probe.dart.txt`, `native.dart.txt`, and `controller.dart.txt` to
`.dart_tool/bar_update/` at repository root, dropping `.txt`. The legacy controller
prototype is imported but never selected by these measurements. From the gallery:

```
flutter build macos --profile -t ../../.dart_tool/bar_update/probe.dart --dart-define=SECONDS=25
```

Keep separate app copies; sign only those copies using the temporary-app recipe
in ../category-layout/README.md. The scripts use `/tmp/bar-bulk-d.app` for the
baseline and `/tmp/bar-native-final.app` for the candidate. Use explicit selectors
from `measure.py.txt`, not the legacy generic `baseline` selector.

## Measurements

Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7, arm64 profile AOT,
Impeller, 800×480 at DPR 1. `protocol.md` predates the comparison. A/B/B/A, seven
200ms batches after 800ms warmup; no builds/tests alongside timing. Full-call
figures sum components within a process first, then take the median across its
two results. All raw runs and the initial quick comparison are in
`measurements.json.gz`; `summary.json` retains components and pair changes.

At 20k, full draw calls improve 20.1% (19.7% and 20.6% in the pairs), exceeding the
15% gate. Full updates improve 14.5%, animation CPU 19.8%. No control has a
repeatable regression above both 5% and 0.1ms. Rounded/inflated bars, other chart
types, multiple datasets, indexed stacks and scriptable colors are retained.

## Foreground runs

`stress.py.txt` launches 25-second real stress scenarios and checks process
activity periodically. The first baseline update run lost focus and yielded only
two complete windows; it is retained but excluded from the FPS comparison.
`stress_repeat.py.txt` reruns only that invalid baseline cell. All activity checks
in the replacement baseline and reported candidate cells are true, and each has
24 complete one-second windows. Logs and parsed summaries are retained.

The valid update comparison is 31.15 → 35.61 FPS, average build 27.11 → 24.05ms.
Animation stays 59.87 → 59.92 FPS while build falls 16.00 → 13.73ms. These are one
local profile process per cell; full 20k updates still do not reach 60 FPS. No
mobile/web FPS gain is inferred.

## Correctness

The 35 tests in `test/port/canvas/canvas_rect_bar_test.dart` prove activation,
identical fallback calls, exact pixels/state/current path for all 26 blend modes
(two orientations, thin/wide bars and three alpha values: 312 pixel pairs),
reflection, clips, caller gradients, subsequent path operations, reentrant
notifications, picture hooks, pending circles, chunk boundaries, errors and
snapshot/clear/disposal. Existing bar pixel and workspace tests also pass.

For browser validation, temporarily copy `browser_probe.dart.txt` to
`test/port/canvas/canvas_rect_bar_browser_probe_test.dart` in the package. Run it
with `flutter test --platform chrome`, then `--platform chrome --wasm`, and remove
the copy before repository checks. Both pass all 35 tests. Final validation is in
`validation.json` and compressed logs; no golden image was changed.

## Next optimization target

A separate 10.002-second VM CPU sample of the candidate profile build captures
6,598 samples during the 20k update workload after nine seconds of warmup.
No build or test runs concurrently. `next-update-profile.json.gz` retains the
raw sample; `profile_capture.py.txt` and `profile.dart.txt` retain its capture.
Place the Dart script at `.dart_tool/bar_scan/profile.dart` to use the capture
script. Profiling instrumentation is excluded from the A/B timing results.

Of the 5,658 samples inside `Chart.update`, parsing appears in 1,184 (20.9%).
Category parsing appears in 665, and `Scale.getLabels` in 582. These are inclusive,
overlapping counts, not additive costs or elapsed-time measurements. The bar
ruler appears in 948 samples (16.8%), including 373 in `arrayUnique`.

The next proposed change is guarded numeric/category parsing: obtain native
labels once per parse pass and avoid repeated generic category-label lookups for
exact built-in scales and native data containers. Preserve fresh parsed records,
key order and invalid-value behavior; custom scales, getters and unsupported
values retain ordinary parsing. This targets updates rather than animation-only
frames. No speedup is claimed until an A/B comparison validates it. Ruler
construction and deduplication are the next measured candidate after parsing.
