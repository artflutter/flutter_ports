# Chart benchmark lab

A separate Flutter app for comparing **Chart.js port, fl_chart, Graphic and
Syncfusion** through their public widget APIs. It is part of the root Dart pub
workspace and does not modify the chart library or the existing gallery.

## Run

From the repository root:

```sh
flutter pub get
dart run melos run benchmark:macos  # native profile mode
# Browser preview; native profile mode is the measurement baseline:
dart run melos run benchmark:web
```

Or run from this directory with `flutter run --profile -d <device>`. Android,
iOS, macOS and web platform scaffolds are included. iOS device builds require
your usual signing setup. `benchmark:build:web` produces a WebAssembly build
with JavaScript fallback.

The macOS window opens on the built-in display when available. For a particular
display, set `BENCH_DISPLAY_ID` to its macOS display ID. The window stays movable
and resizable; changing displays or viewport invalidates an active capture.

VS Code Run and Debug includes `chart_benchmark_lab` and
`chart_benchmark_lab (profile)` in the root `.vscode/launch.json`. The profile
configuration targets native macOS.

## Controls

- **Library selector:** mounts one engine at a time. Settings stay selected;
  changing engines resets data to the same seed/step and clears live metrics.
- **Chart type:** line, vertical bar, scatter or pie for every library.
- **Dataset slider:** 100–20,000 actual input items, with 100/1k/5k/20k presets.
  The slider commits on release. The harness never downsamples or caps one
  library's data differently.
- **Features:** line markers, smooth lines, area fill, axis labels, grid,
  alternating item colors, tooltips, 0/50/200 overlay labels and label rotation.
  Inapplicable controls are disabled; their values are excluded from the
  effective configuration exported with a result.
- **Live data:** a new deterministic dataset snapshot per display tick.
  Native transition animations are disabled for all libraries.
- **Recreate chart:** dispose/remount the selected chart on every tick with
  unchanged data. This intentionally measures initialization/recreation, not
  a cached no-op rebuild or a renderer-only redraw.
- **Run/Pause:** inspect rolling metrics. **Capture 10s/30s:** discard two seconds
  of warmup, collect a fixed window, drain delayed engine timings, and save a row.
  Cancelling a capture saves no result. Settings are locked during captures.
- **Capture all 10s/30s:** run every library sequentially with the same setup.
  Duration is per library; each gets its own two-second warmup and timing drain
  (about 53 seconds total at 10s). Progress names the active engine and shows
  1/4 through 4/4. Cancel, hide, scroll or resize stops the whole batch; already
  completed rows remain. Missing engine timings stop the batch without fake rows.
- **Saved comparisons:** filter by matching effective configuration, capture
  duration, viewport, DPR and display rate. Libraries are deliberately excluded
  from this comparison key. Copy all captures as JSON, with individual settings
  and package versions; unlike runs are never silently averaged.

On macOS, native hidden/occluded/minimized-window events cancel captures. App
lifecycle visibility loss, scrolling the chart, resizing, changing displays or
DPR also invalidate measurement. The full chart must be inside its scroll viewport
before a run starts. On other platforms, lifecycle and viewport checks apply.
Avoid interacting with tooltips during captures unless that is intentionally
part of your workload.

## What the metrics mean

**Use FPS and frame interval for end-to-end comparison.** Some libraries defer
work to timers or post-frame callbacks; that work can block the UI thread while
falling outside the engine's reported build-duration phase.

- **FPS:** delivered Flutter engine frames per measured second, from
  `FrameTiming`, not ticker callback count or physical presentation feedback.
  Captures use the entire requested measured duration as the denominator,
  including stalls. Live readouts estimate cadence from recent vsync timestamps.
- **Frame interval p90:** gaps between engine frames, including deferred work
  and stalls. A single-frame window has no interval estimate.
- **UI frame p90/mean:** engine build-phase durations. This is not all Dart CPU
  time and is not sufficient by itself to rank asynchronous renderers.
- **Raster p90/mean:** engine raster-phase durations, independent of UI work.
- **Over budget:** a UI/raster phase over 16.67 ms, or a preceding frame gap over
  17.67 ms. The 1 ms cadence tolerance avoids classifying normal 60-Hz timestamp
  rounding as a missed frame. JSON also includes cadence-only percentage, maxima
  and sample count. UI and raster durations are not added together.

Measurements include common data generation, public-widget data adaptation,
layout, chart work and the small shared readout overhead. No backend is given
an internal imperative renderer shortcut. Chart.js uses its typed `ChartView`;
FL Chart, Graphic and Syncfusion use their public chart widgets. Chart.js
line/scatter use `parsing: false`: the generator already supplies sorted, finite
numeric XY points. This is recorded in each capture's `engineOptions`; bar and
pie retain their default parsing. Graphic receives
only variables required for the selected chart/features; line/scatter do not
pay for an unused categorical domain. The common overlay painter draws the same
text workload each tick in its own repaint boundary.

All adapters receive one series of the same seeded, sorted x/y values in a fixed
0–100 domain (positive y values are also used for pie proportions). Color,
line width, marker size, outer viewport and label counts are controlled. Native
spline, axis, tooltip and fill implementations differ; this is logical feature
comparison, not pixel-identical rendering or identical internal algorithms.
Library-internal optimizations remain enabled. These results are not directly
interchangeable with the gallery's imperative/core-only stress timings.

Debug mode is visibly identified. Use profile/release builds for comparisons.
Browser engine timing availability varies; absent timings display dashes and
cannot produce a valid capture. No synthetic frame timings are invented.

## Packages and licensing

Dependencies are pinned in this app and the root `pubspec.lock`:

| Library | Version |
| --- | --- |
| flutter_chartjs_port | workspace 0.1.0 |
| fl_chart | 1.3.0 |
| graphic | 2.7.0 |
| syncfusion_flutter_charts | 35.1.43 |

Syncfusion is included with the project owner's confirmation of an eligible
license. Running/distributing it requires a valid Syncfusion community or
commercial license. The dependency is not vendored or relicensed by this app.
Other libraries retain their own licenses. To identify a port revision in JSON,
pass `--dart-define=SOURCE_REVISION=<git-sha>` when building/running.

## Verification

```sh
flutter test apps/chart_benchmark_lab/test
# Native UI/rendering and real frame-timing smoke driver:
cd apps/chart_benchmark_lab
flutter run --profile -d macos -t tool/smoke.dart
```

The smoke driver renders all 16 library/type combinations, saves native
screenshots, and captures a 20k-item line run for each library. It exits with a
JSON success/failure result. By default it uses the app-accessible temporary
directory printed to stdout. `BENCH_OUTPUT` selects another output directory. The
standard macOS sandbox may restrict filesystem exports; for test-only artifact
collection, use a temporary app copy signed with the repository's existing
benchmark entitlements, or a directory accessible to the app. Production
sandbox settings are unchanged. These short smoke captures verify functionality,
not a published performance ranking.

Tests cover deterministic full-size data, warmup/stale/end-window filtering,
frame-gap accounting, effective comparison keys, all adapters, phone/desktop
layouts, library-switch persistence, capture locks and cancellation boundaries.
