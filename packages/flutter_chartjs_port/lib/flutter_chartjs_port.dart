// Original code, not ported from Chart.js: the public library of the package.
/// Chart.js for Flutter: the widget `ChartView`, the theme API, the typed API
/// and the chart API. Register the components first:
/// `Chart.register(registerables)`.
///
/// A native Dart port of [Chart.js](https://www.chartjs.org) (Chart.js ADR
/// 0048, section 5). A file of an app imports this library next to
/// `package:flutter/widgets.dart` or `material.dart` with no prefix: it
/// exports `package:flutter_chartjs_port/chartjs.dart` without `Animation`
/// and `Element`, the two names that Flutter also has. Code that extends
/// Chart.js imports `chartjs.dart` and `helpers.dart` with a prefix.
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

export 'package:flutter_chartjs_port/chartjs.dart' hide Animation, Element;
export 'package:flutter_chartjs_port/src/theme/chart_theme.dart'
    show ChartTheme;
export 'package:flutter_chartjs_port/src/theme/theme_data.dart'
    show ChartThemeData;
export 'package:flutter_chartjs_port/src/typed/typed.dart';
export 'package:flutter_chartjs_port/src/widgets/chart_view.dart'
    show ChartView;
