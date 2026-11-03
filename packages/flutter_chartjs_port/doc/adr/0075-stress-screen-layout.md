# Chart.js ADR 0075: Consistent stress-screen controls

- Status: implemented; widget layout and behavior validated.
- Date: 2026-11-03
- Supersedes: ADR 0031 §10 for the Stress tab only.

## Decision

Use one configuration order across stress targets: target, chart/drawing/plugin
choice, workload and operation. The primary targets are Charts, Drawing, Axes and
Plugins. Drawing groups the existing primitives, points/line, bars and arcs tests;
it remembers the last drawing selection. All existing modes stay. Interactive
Items choices are always 100, 1k, 5k and 20k across every target and type, with
1k selected initially. Switching
targets or types preserves the exact selected count, including custom counts
supplied by the profiling entry point.

Show readable chart names, including on narrow screens. Choice rows wrap while
keeping aligned segment widths and stable control keys. Other gallery pages
retain their original single-row/icon presentation by default. Keep Items and
Overlay labels together, with a compact icon-only rotation toggle beside
the overlay count on the same row, and name Redraw, Full update, Data only, Animate and
Interact explicitly. The short operation description explains what changes.

The test starts automatically when its chart is ready; the initial action is
Pause test. Explicit `autoStart: false` remains available to controlled tests.
Run/Pause and Options have text labels. Additional toggles use readable names in
an expandable Options area. Selecting Legend enables its legend; there is no
redundant Show legend toggle. Scripted benchmarks can still disable it for a
baseline measurement. Hover and Tooltip likewise enable their tooltip directly
without a Show tooltip toggle. Hide Options when the scene has no optional controls.
A compact FPS/UI-frame/raster summary precedes the
expandable Diagnostics section below the plot. Technical source descriptions,
full timings and measurement notes no longer compete with configuration.

The benchmark loops, chart configurations, scripted scenario counts, canvas-size calculation,
recording and timing instrumentation are unchanged. No chip, slider, dropdown
or horizontal-scroll navigation is introduced. The default chart host remains
fully visible at 412 x 915. Large text wraps and may scroll vertically.

## Validation

The existing stress tests cover behavior and the phone viewport for every plugin
scene. New tests cover readable labels, navigation, remembered drawing choice,
expandable controls/diagnostics and large-text wrapping. Desktop and phone
screenshots were inspected with real fonts; preview-only helpers were removed.

## Indexed-color follow-up

Chart Options includes Indexed colors beside Scriptable colors. Enabling either
clears the other; neither selected means static colors. Switching color forms
recreates the host for both canvas and ChartView while retaining the operation
and item count. Indexed colors use a native Color list with the same alternating
blue/pink values as the scriptable case. The profiling entry accepts INDEXED=1
and identifies indexed runs without changing existing default benchmark cases.
