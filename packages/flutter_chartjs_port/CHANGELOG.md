## 0.1.0

The first release: a native Dart port of Chart.js v4.6.1 for Flutter.

- **Upstream.** The package ports the Chart.js tag `v4.6.1` (commit `76d8cf89`) with no backport:
  no file of `lib/` has an upstream backport line, and the
  [upstream ledger](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_chartjs_port/doc/upstream-ledger.md)
  has no backport row. The changes of chartjs/Chart.js#12130, #12142, #12155, #12238 and #12283,
  which the earlier commit pin `4.5.1+7169e651` ported, are part of v4.6.1.
- **Chart.js.** The eight chart types with their dataset controllers (bar, bubble, doughnut,
  line, pie, polar area, radar and scatter), the four elements (arc, bar, line and point), the six
  scales (category, linear, logarithmic, time, timeseries and radial linear), the seven plugins
  (colors, decimation, filler, legend, subtitle, title and tooltip), the core (the configuration
  and the option resolver, the registry, the animations, the interaction modes, the layout and the
  events) and the public helpers. The color parser is a port of @kurkle/color 0.3.2.
- **`ChartView`.** The widget of one chart. It takes the Chart.js configuration as a Dart `Map`,
  starts the chart in its first layout, applies a new configuration after the frame, and takes
  its size from the constraints and the options `responsive`, `maintainAspectRatio` and
  `aspectRatio`.
- **Theming.** `ChartTheme` and `ChartThemeData`, with the presets `ChartThemeData.light()` (the
  Chart.js defaults) and `ChartThemeData.dark()`, and a theme switch at run time. A theme never
  changes `Chart.defaults`.
- **Accessibility.** The chart is one focus stop: the keyboard moves a virtual mouse over the
  legend items and the data elements. It is one semantics node with the text of `semanticLabel`.
  Under the reduced-motion setting of the platform (`MediaQuery.disableAnimations`), it animates
  nothing.
- **Dates.** A built-in date adapter with the rules of chartjs-adapter-moment 1.0.1 and ICU
  format patterns, in local time or in UTC (`setDefaultDateZone`).
- **Libraries.** `flutter_chartjs_port.dart` for apps, `chartjs.dart` for code that extends
  Chart.js (plugins, controllers and scales), and `helpers.dart` for the Chart.js helpers.
- **Differences.** The README lists the differences from Chart.js that an app can see: the date
  formats, the Dart collection types of a configuration, the data array changes and the missing
  DOM.

## 0.0.1

- Initial scaffold. Tracks Chart.js 4.5.1. Nothing renders yet.
