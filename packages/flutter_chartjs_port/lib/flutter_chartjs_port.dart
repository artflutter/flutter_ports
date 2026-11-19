// Original code, not ported from Chart.js: the public library of the package.
/// Chart.js for Flutter: the widget `ChartView`, the theme API, the typed API
/// and the chart API. Register the components first:
/// `Chart.register(registerables)`.
///
/// A native Dart port of [Chart.js](https://www.chartjs.org). The library
/// exports `package:flutter_chartjs_port/chartjs.dart`, each file of
/// `lib/src/`, without the names that Flutter also has: `Animation`,
/// `Element`, `FilterCallback`, `Title` and `Tooltip`. A file of an app or of
/// the package imports it next to `package:flutter/widgets.dart` with no
/// prefix. A file that needs one of the five names imports `chartjs.dart`
/// with a prefix.
///
/// The typed API (Chart.js ADR 0052) gives typed values, callback details
/// with `int` indexes and views of the chart objects. The library exports
/// it next to the Chart.js names: its names take none of them.
///
/// Register the components before the first chart, as the ESM entry of
/// Chart.js asks: `Chart.register(registerables)`, or a List of the class
/// values and plugin Maps of the chart types of the app. The palette of a
/// theme needs the `colors` plugin.
///
/// The roadmap and the parity tracker are in the `doc/` folder of the
/// repository:
/// https://github.com/artflutter/flutter_ports/tree/main/packages/flutter_chartjs_port/doc
library;

export 'package:flutter_chartjs_port/chartjs.dart'
    hide Animation, Element, FilterCallback, Title, Tooltip;
export 'package:flutter_kurkle_color_port/flutter_kurkle_color_port.dart'
    hide color;
