// Ported from chartjs-chart-sankey v0.19.1 docs/scripts/utils.js (MIT, Jukka Kurkela).

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    show ChartPaint, JsObjectFace;

const List<Color> _palette = [
  Color(0xFF4F8FBA),
  Color(0xFFF28E2B),
  Color(0xFF59A14F),
  Color(0xFFE15759),
  Color(0xFFB07AA1),
  Color(0xFF76B7B2),
];

/// The colors of the node names of one sample (`utils.js:1-9`): each new
/// name takes the next color of the palette.
///
/// Upstream keeps one Map for the page. The gallery makes one object for
/// each sample, so the colors of a sample do not change with the samples
/// that the user opened before.
final class SankeyDocsColors() {
  /// A new assignment of the palette, with no name.
  this;

  final Map<String, ChartPaint> _assigned = {};

  /// utils.js:4 `getColor(name)`.
  ChartPaint getColor(String name) => _assigned.putIfAbsent(
    name,
    () => ChartPaint.solid(_palette[_assigned.length % _palette.length]),
  );
}

/// `context.dataset.data[context.dataIndex]`: the data item of the
/// scriptable context [context], a Map of a sample.
Map<String, Object?> sankeyDataItemOf(Object? context) {
  final ctx = context! as JsObjectFace;
  final dataset = ctx['dataset']! as Map<String, Object?>;
  return (dataset['data']! as List<Object?>)[ctx['dataIndex']! as int]!
      as Map<String, Object?>;
}
