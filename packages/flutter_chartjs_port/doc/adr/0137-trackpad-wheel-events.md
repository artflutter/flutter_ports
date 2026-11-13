# Chart.js ADR 0137: trackpad gestures as `wheel` events

- Status: accepted (2026-11-13): its code and the tests of section Tests pass.
- Date: 2026-11-13
- Closes: Open 5 of [Chart.js ADR 0108](0108-input-surface-and-exports-for-add-on-plugins.md) (the
  trackpad of a native desktop app, seam H27 of the zoom port).

## Context

In Chrome on macOS, a two-finger trackpad scroll gives `wheel` events, and a trackpad pinch gives
`wheel` events with `ctrlKey`. Thus chartjs-plugin-zoom zooms with a trackpad in a browser.

Since Flutter 3.3, a native desktop app gives a trackpad gesture as pan-zoom pointer events
(`PointerPanZoomStartEvent`, `PointerPanZoomUpdateEvent`, `PointerPanZoomEndEvent`), not as
scroll signals. The host of the port mapped none of them, so a trackpad did not zoom or pan a
chart in a native macOS, Windows or Linux app.

## Decision

1. `RenderChartHost` maps each update of a trackpad gesture to one `wheel` event at the pointer:
   - a scroll step gives `deltaX` and `deltaY` of the opposite of the pan step;
   - a pinch step (a scale change) gives `deltaX` 0, `deltaY` -100 times the natural log of the
     scale step, and `ctrlKey` true.
2. At the start of a gesture, the host joins the gesture arena of the pointer. When a listener
   prevents the default of a `wheel` of the gesture, the host accepts the arena, so a scrollable
   ancestor does not scroll. At the end, the host gives up an arena that it did not accept.
3. `ChartHost.trackpadGestures` and `ChartView.trackpadGestures` (default true) turn the mapping
   off.

## Tests

- `test/port/platform/chart_host_test.dart`: a trackpad scroll and a pinch give the `wheel`
  fields, a prevented trackpad `wheel` keeps a parent `ListView` from scrolling and an unprevented
  one scrolls it, and `trackpadGestures: false` gives no `wheel`.
- `apps/chart_benchmark_lab/test/zoom_test.dart`: a trackpad pinch and a two-finger scroll zoom a
  chart of the Chart.js port with the zoom plugin.

## Consequences

- The zoom plugin zooms with a trackpad on macOS, Windows and Linux, as in Chrome.
- Each update of a gesture gives one `wheel`. The wheel zoom of the plugin steps by its `speed`
  for each event, so a trackpad zooms in many small steps, as in Chrome.
