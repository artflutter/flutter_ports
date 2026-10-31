// Original code, not ported from Chart.js: plugin reference test harness.

/// The harness of the port-only reference tests of the phase 8 plugins
/// (Chart.js ADR 0041, section 3): real charts against a build of the
/// pinned Chart.js.
///
/// The method is the method of `controller_chart_harness.dart` (Chart.js
/// ADR 0030). A generator `tool/reference/plugin_<name>_reference.mjs`
/// runs its cases through `runPluginCase` of
/// `tool/reference/plugin_chart_common.mjs`. A test file
/// `plugin.<name>_test.dart` runs the same cases with
/// [testPluginChartCases].
///
/// One observation is the controller observation without `hits` (the
/// option `hits: false`), with these keys after `datasets`:
///
/// - `boxes`: [observeBoxes].
/// - `plugins.<id>`: for each entry of the `observers` of the case set, the
///   result of the observer. Each plugin test file gives the observer of
///   its own plugin, with the same keys as the observer of its generator.
///   Thus this library needs no plugin class (Chart.js ADR 0041, section 3
///   item 2).
///
/// An observer reads `legendItems` through `types.LegendElement`, and
/// `legendHitBoxes`, `lineWidths` and `columnSizes` through a cast to
/// `Legend` (Chart.js ADR 0038, section 6). It reads the tooltip through
/// `types.TooltipModel` (Chart.js ADR 0039, section 14) and the title box
/// as `chart.titleBlock`. The values of an observer go through
/// `plainValue`. Never pass a resolver to `equals()`: compare through
/// `jsObjectKeys` and `jsGet`.
///
/// This library is not a test file. It is not a pure layer. A test that
/// imports it needs `@TestOn('vm')`.
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../controllers/controller_chart_harness.dart';
import '../scales/scale_chart_harness.dart';

/// The kind of the layout box [box] of [chart]: `legend` for
/// `chart.legend`, `title` for `chart.titleBlock`, the scale id for a scale
/// of `chart.scales`, and `subtitle` for each other box (`boxKind` of
/// plugin_chart_common.mjs). No plugin case adds a user box. The subtitle
/// map is private on both sides (plugin.subtitle.js:4, Chart.js ADR 0038,
/// section 5), so each other box is the subtitle.
String _boxKind(Chart chart, types.LayoutItem box) {
  if (identical(box, chart.legend)) {
    return 'legend';
  }
  if (identical(box, chart.titleBlock)) {
    return 'title';
  }
  for (final scale in chart.scales.values) {
    if (identical(box, scale)) {
      return scale.id;
    }
  }
  return 'subtitle';
}

/// The `boxes` observation of Chart.js ADR 0041 section 3 item 4
/// (`observeBoxes` of plugin_chart_common.mjs): each box of `chart.boxes`
/// in order, as `[kind, position, weight, fullSize, left, top, right,
/// bottom, width, height]`. The order is protected.
List<Object?> observeBoxes(Chart chart) => [
  for (final box in chart.boxes)
    [
      _boxKind(chart, box),
      box.position,
      box.weight,
      box.fullSize,
      box.left,
      box.top,
      box.right,
      box.bottom,
      box.width,
      box.height,
    ],
];

/// The observation keys of a plugin case after `datasets`
/// (`pluginObservation` of plugin_chart_common.mjs): `boxes`, and
/// `plugins.<id>` for each entry of [observers].
Map<String, Object?> Function(Chart chart) _pluginObservation(
  Map<String, Object? Function(Chart chart)> observers,
) =>
    (chart) => <String, Object?>{
      'boxes': observeBoxes(chart),
      for (final MapEntry(:key, :value) in observers.entries)
        'plugins.$key': value(chart),
    };

/// `testControllerChartCases` with `hits: false`. The observation is the
/// controller observation with `boxes` and, for each entry of [observers],
/// `plugins.<id>` (`runPluginCase` of plugin_chart_common.mjs). The plugin
/// test file gives its own observer. [functions], [extras], [theme] and
/// [errorTypes] are the parameters of `testControllerChartCases`.
void testPluginChartCases(
  List<ScaleChartCase> cases, {
  Map<String, Object? Function(Chart chart)> observers = const {},
  Map<String, Object?> functions = const {},
  Map<String, Object? Function(Chart chart)> extras = const {},
  Object? theme,
  Map<String, Matcher> errorTypes = const {},
}) => testControllerChartCases(
  cases,
  functions: functions,
  extras: extras,
  theme: theme,
  errorTypes: errorTypes,
  hits: false,
  observeExtra: _pluginObservation(observers),
);
