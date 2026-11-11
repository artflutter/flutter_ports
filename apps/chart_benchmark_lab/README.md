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

The workflow `.github/workflows/pages.yaml` publishes one page of the lab for each
Flutter channel: <https://artflutter.github.io/flutter_ports/lab-stable/>,
<https://artflutter.github.io/flutter_ports/lab-beta/> and
<https://artflutter.github.io/flutter_ports/lab-master/>. A push to `main` that
changes the lab, the Chart.js port or its zoom port deploys all three pages. A
person can also start the workflow. Each run takes the newest release of stable
and of beta, and the head of the branch `master`. It does not read `.fvmrc`. The
lab resolves alone in these builds, as an app that uses the port. The root
`pubspec.lock` gives the first choice of versions. If a channel does not build, its
page shows that result, and the other pages still deploy.

git-cliff (`cliff.toml`) computes the lab version from the commits after the last
`lab/v*` tag, by Conventional Commits. A feature gives a new minor version, and
another commit gives a new patch version. Only a commit that changes the lab, the
Chart.js port or its zoom port counts. The three builds take the version through
`--build-name` and the workflow run number through `--build-number`. The bottom of
the page shows both values, for example `Lab version 0.2.0+41`. A deploy pushes the
tag of a new version. `git cliff --bumped-version` shows the next version on a local
machine.

GitHub Pages cannot send the COOP and COEP headers, so `web/isolate.js` adds them
through a service worker, on `github.io` only. The first visit reloads once.
`web/flutter_bootstrap.js` gives the Flutter loader no service worker settings,
because the worker of Flutter removes any other worker in its scope. The
header of a web run shows its mode: `WASM · THREADS`, `WASM · 1 THREAD`,
`JAVASCRIPT` or `JAVASCRIPT · NATIVE TEXT`. The exported JSON has the same text
as `webMode`. By default, the Flutter loader takes WebAssembly only in a Chromium
browser. `web/flutter_bootstrap.js` sets `wasmAllowList` for Firefox and Safari
too, and `web/isolate.js` also runs in them. Firefox before 147 and Safari
before 26.2 keep the JavaScript build.

`web/flutter_bootstrap.js` also sets `preferWebParagraph: true`
([flutter/flutter#172561](https://github.com/flutter/flutter/issues/172561),
from Flutter 3.50). With it, the browser lays out and draws the text with the
fonts of the system. The engine has that path only in CanvasKit, and only in a
browser with the Enhanced TextMetrics API. Chrome has the API behind the flag
`chrome://flags/#enable-experimental-web-platform-features`. A `--wasm` build
ignores the setting on skwasm. Thus the script gives a browser with the API the
JavaScript build with CanvasKit, and the header shows `JAVASCRIPT · NATIVE TEXT`.
For WebAssembly figures, turn off the flag. `dart run melos run benchmark:web`
starts Chrome with the API. Threads have the engine race of turned text
(`packages/flutter_chartjs_port/doc/performance.md` section 5), and the tag
`3.50.0-0.4.pre` does not hold the merge commit of the Flutter fix #194139.

The macOS window opens on the built-in display when available. For a particular
display, set `BENCH_DISPLAY_ID` to its macOS display ID. The window stays movable
and resizable; changing displays or viewport invalidates an active capture.

VS Code Run and Debug includes `chart_benchmark_lab`,
`chart_benchmark_lab (profile)` and `chart_benchmark_lab (profile, wasm)` in the
root `.vscode/launch.json`. Each one runs on the device of the VS Code picker. The
wasm configuration needs Chrome in the picker.

Run, Capture and Capture all first scroll the chart into view, because a test
measures only a chart in full view. Below 600 pixels of width, the header actions are
icons with tooltips, so that the chart fits below the header on a phone.

A note in the floating slot of the page (`lib/ui/page_note.dart`) stays in place
when the page scrolls. It says why a scroll or another outside cause stopped a test,
because the status line below the chart can be out of view. Otherwise, on the web,
it says why the page has its mode. It hides during a run, and a person can close it.

The header has a **Change log** button (`lib/ui/change_log.dart`). Add a line
there when a change moves a figure.

## The page around the chart

The page must stay smooth, and it must add little to the frames of a test. Each
section of `lib/ui/benchmark_page.dart` is one widget instance for the life of
the page. A section rebuilds through `_Selected` only when a value that it reads
changes. Thus a change of the controller builds only the sections that show it,
and a page rebuild never updates the chart. The `select` function of a section
must cover each value that its builder reads.

Repaint boundaries sit below each scroll view, around the plot and around the
sections that change often. A scroll frame records no paint, a chart frame records
only the chart, and a readout records only the readouts.

An idle chart stays mounted when the window changes size, also at the first layout.
The exception is a Graphic bar chart, which reads its bar width only when it mounts.
Each test still starts with a new chart. A settings tap with no change does nothing.

On the web, `web/index.html` shows a splash in the color of the page until the first
frame, so that a load shows no blank white page.

Two tools measure this:

- `test/page_work_test.dart` counts the widgets that build and the render objects
  that lay out and paint for each interaction, with budgets. It also compares the
  screen with a forced rebuild of each element after each state of the controller,
  and it fails when a section misses a value.
- `tool/perf_page.dart` runs the real page with a small chart, scripts each
  interaction and prints one `PAGE {json}` line for each, with the frame timings.
  Run it in profile mode: `flutter run --profile -t tool/perf_page.dart -d <device>`.
  A browser build posts its lines to `/line`, as the matrix does.

## Controls

- **Library selector:** mounts one engine at a time. Settings stay selected;
  changing engines resets data to the same seed/step and clears live metrics.
- **Chart type:** the eight Chart.js types: line, vertical bar, scatter, bubble,
  pie, doughnut, polar area and radar. Each library draws each type through its
  public API, with one exception. Syncfusion 35.1.43 has no radar or polar series.
  Thus its radar shows a message, and Run and Capture are not available for it.
  The harness does not draw a stand-in, because that would measure the stand-in.
- **Dataset slider:** 100–20,000 actual input items, with 100/1k/5k/20k presets.
  The slider commits on release. The harness never downsamples or caps one
  library's data differently.
- **Features:** point markers and area fill (line and radar), smooth lines (line
  only: fl_chart has no smooth radar), axis labels and grid (not for pie, doughnut
  or polar area), alternating item colors (not for line or radar), tooltips,
  a series shadow (sharp or blurred), 0/50/200 overlay labels and label
  rotation. The settings hide a control that does not apply; its value is
  excluded from the effective configuration exported with a result. A library
  that cannot draw the shadow of a chart type shows the reason, and a batch
  skips it.
- **Zoom and pan** (line, bar, scatter and bubble; the settings hide it for the
  other types): each library zooms and pans only the x axis, through its public
  API. A touch pinch or the mouse wheel zooms, and a drag pans a zoomed chart.
  Each library stays inside the data and zooms at most 100 times
  (`chartMaxZoom`, the default of Syncfusion). The Chart.js port uses the port of
  chartjs-plugin-zoom (`packages/flutter_chartjs_plugin_zoom_port`): the adapter
  registers the plugin only for a chart with zoom, so a run without zoom builds
  the same widgets as before and runs no hook of the plugin. fl_chart uses
  `transformationConfig` with `FlScaleAxis.horizontal`, Graphic the
  `horizontalRangeUpdater` of `RectCoord` from `Defaults.horizontalRangeEvent`,
  with the same bounds and without its double-tap reset, and Syncfusion
  `ZoomPanBehavior` with `ZoomMode.x`. The lab claims each wheel over a chart
  with zoom, so a wheel zoom does not scroll the page and does not stop a test:
  only the Chart.js port claims it by itself. Each test starts with a new chart
  at the full range; a zoom stays through the ticks of a live run, and a
  Recreate chart run starts each tick at the full range. A set zoom adds the key
  `zoom` to the settings, so saved runs without it keep their comparison keys,
  and a Chart.js capture records the plugin pin as `zoomPlugin` in its
  `engineOptions`. The libraries still differ in this input:
  - A desktop trackpad sends its pinch and its two-finger scroll as pan-zoom
    events, not as a wheel. A trackpad pinch zooms fl_chart and Graphic.
    Syncfusion reads each pan-zoom step as a wheel step by its vertical pan: a
    vertical two-finger scroll zooms it, and a pinch only zooms it out. The host
    of the Chart.js port maps no pan-zoom event (Chart.js ADR 0108 Open 5), so
    on the native macOS app a trackpad does not zoom or pan it. A trackpad
    scroll over the chart also scrolls the page. The web build, where the
    browser sends a trackpad scroll as a wheel, is not checked.
  - A pinch with one finger above the other zooms only fl_chart: the others
    read the horizontal spread of the fingers.
  - A Graphic pinch or wheel zoom grows the range on both sides alike, around
    the middle of the data, not at the fingers or the cursor.
  - fl_chart rods and Graphic bars keep their width in pixels when zoomed;
    Chart.js and Syncfusion bars grow.
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
  1/4 through 4/4. A batch skips a library that does not have the selected type,
  so a radar batch shows 1/3 through 3/3. Cancel, hide, scroll or resize stops the
  whole batch; already completed rows remain. Missing engine timings stop the batch
  without fake rows.
- **Saved comparisons:** filter by matching effective configuration and capture
  duration, so that a resize keeps the rows in view. Rows of another chart size,
  DPR or display rate stay visible with their size and rank apart. Libraries are
  deliberately excluded from this comparison key. Copy all captures as JSON, with
  individual settings and package versions; unlike runs are never silently
  averaged. The table ranks
  each setup on its own by FPS, then over budget, frame p90, and UI + raster p90.
  A difference inside a margin is a tie: 1% of FPS, 1 point of over budget, one
  display frame of frame p90 and 10% of the work. It marks the winner when at least
  two libraries of one setup differ, shows how many times each row is slower, and
  marks the best value of each column. A click on a column header sorts by that
  column.

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
line/scatter/bubble use `parsing: false`: the generator already supplies sorted,
finite numeric XY points, and each `DataPoint.bubble` gives its radius as a typed
field. This is recorded in each capture's `engineOptions`; the other types retain
their default parsing. The Chart.js adapter also sets the public
`ChartView.dataOnlyUpdates`, the data-only path of Chart.js ADR 0098: a tick that
changes only the data keeps the layout and the ticks. Each cell of the matrix
takes this path, both presets: the alternating colors of the full preset are a
native indexed style (Chart.js ADR 0100). A bubble tick also runs a layout when
its largest radius changes. `updateData` goes to a full update by itself for a
chart that does not qualify, for example with a color callback. Each capture's
`engineOptions` records it as `dataOnlyUpdates`, and the comparable-run key does
not include it.
`--dart-define=CHARTJS_DATA_ONLY_UPDATES=false` turns it off. Graphic receives
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

Bubble radii come from one shared formula: 2 px at the value 0 and 8 px at 100.
The four types after the first set use these public forms:

| Type | Chart.js port | fl_chart | Graphic | Syncfusion |
| --- | --- | --- | --- | --- |
| Bubble | `BubbleDataset` | `ScatterChart`, a radius for each spot | `PointMark`, a size for each tuple | `BubbleSeries` |
| Doughnut | `DoughnutDataset` | `PieChart` with a center space | `IntervalMark`, a polar radius range | `DoughnutSeries` |
| Polar area | `PolarAreaDataset` | `PieChart`, equal values, a radius for each section | `IntervalMark` in a polar coordinate (rose) | `PieSeries`, equal values, `pointRadiusMapper` |
| Radar | `RadarDataset` | `RadarChart` | `LineMark` in a polar coordinate, `loop: true` | none |

Slices fill 90% of half of the short side. A doughnut has its hole at 50% of its
outer radius. A radar fills 80%, because fl_chart fixes that share. A radar has one
spoke per item, at most 8 labels around it and circular rings at 25, 50, 75 and
100, in each library that has a radar. These native differences stay:

- Syncfusion scales a bubble by the largest size of the data, so its radii differ
  a little from the shared formula. Its segment draws at twice the radius that it
  gets, so the adapter gives it half of the range.
- `RadarChart` of fl_chart has no option for the radial range: it takes the range
  from the data, not from the fixed 0–100 domain. It has no tooltip, so the Tooltips
  setting enables only its touch handling. It always draws its grid and its points.
  Thus its grid and markers off are transparent or zero-size draws, not fewer calls.
- `RadarChart` of fl_chart scans all entries again for each entry that it places,
  so its work grows with the square of the item count.

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

The smoke driver renders all 31 library/type combinations that have a public
chart, saves native screenshots, and captures a 20k-item line run for each
library. It exits with a JSON success/failure result. By default it uses the app-accessible temporary
directory printed to stdout. `BENCH_OUTPUT` selects another output directory. The
standard macOS sandbox may restrict filesystem exports; for test-only artifact
collection, use a temporary app copy signed with the repository's existing
benchmark entitlements, or a directory accessible to the app. Production
sandbox settings are unchanged. These short smoke captures verify functionality,
not a published performance ranking.

Tests cover deterministic full-size data, warmup/stale/end-window filtering,
frame-gap accounting, effective comparison keys, all adapters, the missing radar
of Syncfusion, phone/desktop layouts, library-switch persistence, capture locks and
cancellation boundaries.
