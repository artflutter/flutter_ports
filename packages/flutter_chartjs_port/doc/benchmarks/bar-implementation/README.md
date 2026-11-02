# Bounded native recordings: implementation evidence

2026-11-02. Production change: ADR 0066, `canvas_ui.dart` only. Baseline `1d37d64`;
candidate `candidate.patch`. The bar-index memo from the investigation is not
installed. See [performance.md §33](../../performance.md#33-bounded-native-recordings-for-dense-bar-charts).

## Build and reproduce

Copy `probe.dart.txt`, `native.dart.txt`, and `controller.dart.txt` into
`.dart_tool/bar_impl/` at repository root, removing `.txt`. The controller is the
old investigation prototype, imported by the harness but unused by every measured
implementation case. From `apps/chartjs_gallery`, build:

```
flutter build macos --profile -t ../../.dart_tool/bar_impl/probe.dart --dart-define=SECONDS=25
```

Keep separate baseline/candidate app copies at `/tmp/bar-implementation-a.app` and
`/tmp/bar-implementation-b.app`. Ad-hoc sign only those temporary copies with
`../category-layout/probe.entitlements` using the
[existing recipe](../category-layout/README.md). Repository signing is unchanged.
`metadata.json` records the platform, canvas size and runtime source hashes.

`measure.py.txt` and `measure_update.py.txt` run the A/B/B/A process series.
No builds/tests ran alongside timing. Each cell has 800 ms warmup and seven
200 ms batches. The full-call metric sums update, draw and host paint/record
completion in each process before taking the median across its two runs.
`summary.json` contains the per-pair comparisons, components and aggregates.
`measurements.json.gz` retains every raw process result.

Use **`BAR_VARIANTS=update,draw,anim`** for the primary bar workloads and
`BAR_N=1000,5000,20000`. The first script's generic `baseline` label accidentally
matched its `contains('line')` selection: those rows are additional line controls,
not bar updates. They are retained but excluded from bar-update figures. The
separate explicit `update` A/B/B/A series selects the intended bars, confirmed by
its bar geometry/tick observations. Draw and animation were bars in both series.
The extra 20k line control has no regression (5.3445 → 5.135 ms).

The declared controls use N=1000/5000: line update/draw, bubble update, doughnut
draw and fixed-thickness bar update. No control exceeds both 5% and 0.1 ms of
repeatable full-call regression. All predeclared 20k gain thresholds pass.

## Actual foreground FPS

`BAR_MODE=stress` selects the existing `StressProfileApp`, with the real stress
widget, N=20000, M=0 and bar type; `BAR_CALL=update` or `anim` selects the operation.
The build define above sets each scenario to 25 seconds. This uses the gallery
window, not the frameless benchmark's 800×480 recording. Its existing summary
excludes startup; build/raster timings and one-second windows are retained.

`stress_foreground.py.txt` activates the exact launched process through
NSRunningApplication and records `active=true`. `stress-fg-*.log` contains the
four final runs, with 24–25 one-second windows each. `foreground-activation.log`
records activation and summaries; `stress.json` stores the parsed summaries.
Final FPS is 8.33 → 15.00 for updates and 12.72 → 49.42 for animation.
These are one process per variant/operation on this Mac, not a cross-device FPS
promise. No 60 FPS result is claimed.

`stress-*.log` without `fg-` and `stress.py.txt` retain the preliminary activation
by application path. Its two candidate runs have shortened timing windows and
are not the reported foreground comparison. This prompted process-specific
activation and a fresh complete series.

## Validation

The permanent `test/port/canvas/canvas_ui_chunks_test.dart` has 32 tests. The
mixed-operation twins use invisible off-canvas source-over padding to force
boundaries while preserving exactly the visible instructions of a short unsplit
reference. They cover all 26 composite operations at a fractional host scale,
gradients, patterns, text, images, strokes, current-path continuity, nested clips,
partial clears and transforms. Separate tests cover reference-native pixels,
retention/flattening, unchanged repaints, clear, resize, snapshots and circle runs.

`browser_probe.dart.txt` is the same file without the VM annotation. For browser
validation, copy it temporarily to `test/port/canvas/chunks_browser_probe_test.dart`
inside `packages/flutter_chartjs_port`, run `flutter test` on it with
`--platform chrome` and then `--platform chrome --wasm`, and remove it before
normal repository checks. Flutter's web test compiler requires this test-root
location; initial attempts outside that root could not compile and ran no tests.
Both final browser runs pass all 32 cases.

`validation.json` and the compressed validation logs record the final checks.
No golden image was updated. The runtime diff remains one canvas file; the
measured candidate and final source differ only in comment wrapping for lint.
