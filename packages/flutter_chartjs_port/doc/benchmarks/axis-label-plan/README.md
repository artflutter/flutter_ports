# Guarded category label-plan evidence

2026-11-02. See ADR 0064 and performance.md §30. Baseline is `8bcbe47` plus
`baseline.patch`, including the two earlier retained optimizations. `candidate.patch`
records this implementation's runtime changes. The gallery timing wrappers opt in
only to ordinary data/config getters; stress settings, point count, sampling and
auto-ranging are unchanged.

## CPU comparison

Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7, arm64 profile AOT,
Impeller, 800 × 480 at DPR 1. The same `../category-layout/probe.dart.txt` runs
category/logarithmic and linear/logarithmic, N=1000/5000/20000, update and draw.
Nine 250 ms batches follow 1000 ms warmup. Process order A/B/B/A; no builds/tests
run while timing. The prewritten gate is in protocol.md. All process results are
retained in measurements.json.gz; summary.json reports medians and paired gains.
The primary 20k category case improves 66.0% and 67.6% in update CPU, and 52.0%
and 53.0% in full-call CPU. All tick values/labels, rotation and bounds match.

preliminary.json.gz retains the earlier measurement-only candidate before the native
label-source path. Final validation also tightened custom-tick-list, DDC native-map
and in-flight getter-mutation guards. These preserve the eligible benchmark path;
the ABBA numbers are measurements of the main implementation, not a separately
remeasured speed claim for each guard. runtime-hashes.json identifies final source.

Reproduce using the probe and temporary app signing/launch recipe from
../category-layout/README.md. The baseline and candidate are independent builds;
do not modify production settings to emulate the freeze-layout experiments.

## Real stress screen

Build `lib/main_stress.dart` in profile mode with MODE=axes, SCENARIO=20000x0,
CALL=update, SCALE=category, YSCALE=logarithmic, SECONDS=30, WINDOWS=1. Foreground
the app through Launch Services (open -n -a), rather than relying on a background
executable launch. stress-foreground.log/json record the valid warmed run:
60 FPS, 44 ticks, rotation 50°, average build 10.76 ms and raster 1.02 ms.
The background attempt is retained separately; its summary had zero usable FPS
samples and was not used for performance claims. Transport URLs are omitted.

This is a 30-second local profile-mode result, not a debug/mobile/web FPS guarantee.
Startup is excluded by the stress runner's existing warmup. Axis work is reduced
to 2.37 ms in that screen, not to zero: fresh ticks/contexts and automatic y limits
remain. The implementation preserves the lifecycle instead of freezing geometry.

## Correctness and browser reproduction

The permanent axis_label_plan_test.dart twins compare cached and uncached charts
including every point position. They cover labels, fonts, bounds, resize, tick
options, custom callbacks/lists/scales/getters, context reconstruction and font
notifications. category_label_source_test.dart checks native and custom container
guards. tick_font_cache_test.dart adds a regression for a getter mutating an earlier
font field while toFont is in progress; a mixed result must not poison the memo.

The repository's normal browser selector excludes framework-using scale tests.
For this change the same integration test was additionally run on Chrome JS and
Wasm through browser_probe.dart.txt. Copy it temporarily to
`test/port/core/axis_label_plan_browser_probe_test.dart`, then run:

```
flutter test --platform chrome test/port/core/axis_label_plan_browser_probe_test.dart test/port/core/category_label_source_test.dart test/port/core/tick_font_cache_test.dart
flutter test --platform chrome --wasm test/port/core/axis_label_plan_browser_probe_test.dart test/port/core/category_label_source_test.dart test/port/core/tick_font_cache_test.dart
```

Remove the temporary probe before the normal import guard. The source initializes
bindings and registers built-ins explicitly. validation.json records the final
suite and guard outcomes. No local golden files were written.
