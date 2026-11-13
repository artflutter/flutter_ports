// Original code, not ported from chartjs-chart-sankey: the public library.
/// The sankey chart type of chartjs-chart-sankey for `flutter_chartjs_port`.
///
/// Register the two components once, before the first sankey chart. Then
/// give a chart the type `sankey`:
///
/// ```dart
/// Chart.register(sankeyRegisterables);
///
/// ChartView.raw(
///   config: <String, Object?>{
///     'type': 'sankey',
///     'data': <String, Object?>{
///       'datasets': <Object?>[
///         <String, Object?>{
///           'data': <Object?>[
///             const SankeyDataPoint(from: 'a', to: 'b', flow: 10),
///             const SankeyDataPoint(from: 'a', to: 'c', flow: 5),
///           ],
///         },
///       ],
///     },
///   },
/// );
/// ```
///
/// The element class has the upstream name `Flow`, which is also the name
/// of a Flutter widget. A library that imports Flutter and needs the class
/// imports this library with a prefix, or imports Flutter with `hide Flow`
/// (host-seams.md, seam S21). [sankeyRegisterables] registers the chart type
/// with no use of the name.
library;

import 'package:flutter_chartjs_chart_sankey_port/src/controller.dart';
import 'package:flutter_chartjs_chart_sankey_port/src/flow.dart';
import 'package:flutter_chartjs_port/chartjs.dart' show JsClass;

export 'src/index.esm.dart';
export 'src/upstream.dart';

/// The two components of the chart type, for `Chart.register`: the class
/// values of the controller `sankey` and of the element `flow`.
///
/// Upstream registers them at the import of its script entry
/// (`src/index.ts:6`). A Dart import runs no code.
final List<JsClass> sankeyRegisterables = List.unmodifiable([
  SankeyController.jsClass,
  Flow.jsClass,
]);
