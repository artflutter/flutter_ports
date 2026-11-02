# Ordinary rectangular bar drawing evidence

2026-11-02. [ADR 0067](../../adr/0067-scalar-bar-geometry.md) replaces temporary
geometry objects with scalar locals for a guarded ordinary bar. The canvas calls
remain identical. See [performance.md §34](../../performance.md#34-scalar-geometry-for-ordinary-bar-drawing).

## Baseline, candidate and reproduction

Baseline: commit `1d37d64` plus `baseline.patch`, the validated ADR 0066 canvas
recording change. Candidate: add `candidate.patch` (element.bar.dart only).
`metadata.json` records source hashes, toolchain and hardware. Apple M3 Max,
macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7, arm64 profile AOT, Impeller,
800×480 at DPR 1.

Copy `probe.dart.txt`, `native.dart.txt` and `controller.dart.txt` into
`.dart_tool/bar_impl/` at repository root, dropping `.txt`. These are the shared
investigation harness; the copied controller/index-memo prototype is imported but
unused by all cases reported here. Always use the explicit selectors from
`measure_final.py.txt`: `update,draw,anim` for bars. The legacy `baseline` label
matches the harness's line selector and is not used.

From `apps/chartjs_gallery`:

```
flutter build macos --profile -t ../../.dart_tool/bar_impl/probe.dart --dart-define=SECONDS=25
```

Keep separate app copies. The scripts use `/tmp/bar-implementation-b.app` for
the baseline (the previous optimization's candidate) and `/tmp/bar-draw-final.app`
for the final candidate. Ad-hoc sign these temporary copies using the
[category benchmark recipe](../category-layout/README.md) and its entitlements.
Repository signing stays unchanged. Adapt fixed local paths in the scripts.

## Measurements

The prewritten protocol is `protocol.md`. Final comparisons use A/B/B/A, seven
200 ms batches after 800 ms warmup, without concurrent builds/tests. Full calls
sum update/tick, draw and host paint/completion within each process before taking
the median across its two runs. Raw measurements are in `measurements.json.gz`;
`summary.json` includes components and both individual pair changes.

The primary cases are bar update, draw and looping animation at N=1000/5000/20000.
Controls at N=1000/5000 are rounded bars, fixed thickness/automatic inflation,
line and bubble updates, and doughnut drawing. Both final 20k draw and animation
pairs exceed the 10% full-call gain gate. No control has a repeatable regression
above both 5% and 0.1 ms. The full update reduction varies between its two pairs
(0.6% and 9.3%); the draw/animation improvements are the primary result.

The archive also retains the initial quick comparison and the complete
preliminary scalar series. The final version adds explicit fallbacks for
non-positive outer dimensions and negative-zero inflation, preserving the
original signed-zero canvas arguments. Only the final series is summarized.

`profile-before.json.gz` contains a fresh 10-second CPU sample of 20k bar drawing
on the baseline, after warmup. `profile-summary.json` retains its inclusive
shares (which overlap): boundingRects 13.4%, rectangle path preparation 12.8%,
native drawRect about 29%. `capture.py.txt` and `profile.dart.txt` reproduce the
VM-service capture; profiling is separate from the timing series.

## Foreground frames

`stress.py.txt` selects the existing StressProfileApp at N=20000/M=0, update or
looping animation. Each scenario runs for 25 seconds. It activates the exact
process through NSRunningApplication and logs `active=true`. The existing app
summary excludes startup. `stress-*.log` and `stress.json` retain build/raster
figures and every complete one-second window.

The foreground comparison is one process per operation/variant: updates
15.15 → 16.28 FPS, animation 48.88 → 58.43 FPS. The candidate animation has 18
complete timing windows; the other cells have 24. This difference in coverage is
retained, not hidden or treated as an equally sized statistical sample. The
candidate animation's average build time is 16.50 ms and its build P90 17.26 ms,
so this is not a sustained 60 FPS claim. No mobile/web FPS result is inferred.

## Correctness

`test/port/elements/element.bar_rectangular_test.dart` has ten tests. A subclass
uses the unchanged draw path. The main trace grid compares 3,456 call sequences
across orientation, every skipped-edge mask, border width, bar size and base.
Additional cases cover signed zeros, undefined/non-finite/overflow dimensions,
foreign options, raw/custom objects, getter ordering and effectful equality.
There are 108 exact RGBA pixel twins with transparency, fractional transforms,
clipping, restored styles and a stroke of the retained current path.

`browser_probe.dart.txt` is the test without its VM annotation. Copy it temporarily
to `test/port/elements/bar_draw_browser_probe_test.dart` in the package, run it
with `flutter test --platform chrome` and then `--platform chrome --wasm`, and
remove the copy before repository checks. Its relative pixel-compare helper
import requires that directory. Both browser runs pass all ten tests.

`validation.json` and compressed logs record the full workspace, browser,
fixture, analysis, parity, format and port checks. No golden image is updated.
The older bounded-recording optimization is retained unchanged; this change adds
no renderer capability, aggregation or cross-frame geometry cache.
