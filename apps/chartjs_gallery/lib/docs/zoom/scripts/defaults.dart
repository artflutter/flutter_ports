// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 docs/scripts/defaults.js (MIT, chartjs-plugin-zoom contributors).

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    show InteractionAxis;

/// The options that the docs of chartjs-plugin-zoom set for each chart
/// (`docs/scripts/defaults.js:3-17`), written into the options of one chart.
///
/// Upstream writes them into the global `defaults` of Chart.js
/// (`defaults.set`) once for the docs site. The gallery has other pages,
/// whose charts keep the defaults of Chart.js. Thus each sample of the page
/// "Zoom and pan" calls this function on its own `options`, with the result
/// of the docs:
///
/// - `datasets.line.tension: 0.4` (`:4-8`) applies to a line dataset. The
///   four samples have none.
/// - `interaction` (`:9-13`) gives `axis: 'x'` and `intersect: false`. The
///   chart options outrank the `overrides` of a controller, and the defaults
///   do not: the line `mode: 'nearest'` (`:10`) is the mode of the Chart.js
///   defaults of Chart.js v4.6.1 (src/core/core.defaults.js:66-67), and
///   the override `mode: 'point'` of the scatter controller
///   (src/controllers/controller.scatter.js:23-27) wins over it in the
///   docs. So the options leave out `mode`, and each chart keeps the
///   mode of the docs.
/// - `plugins.legend: false` (`:14-16`) turns the legend off.
///
/// Like `defaults.set` (a `merge`), a key of the defaults goes into the
/// options; the options of a sample set none of these keys.
void setZoomDocsDefaults(Map<String, Object?> options) {
  _object(_object(options, 'datasets'), 'line')['tension'] = 0.4;
  _object(options, 'interaction')
    ..['axis'] = InteractionAxis.x
    ..['intersect'] = false;
  _object(options, 'plugins')['legend'] = false;
}

/// `target[key]`, a new object first when [target] has none.
Map<String, Object?> _object(Map<String, Object?> target, String key) =>
    (target[key] ??= <String, Object?>{}) as Map<String, Object?>;
