// Original code, not ported from Chart.js: the segment styles of the tests.

/// The line option `segment` of the reference data of the generators
/// (Chart.js ADR 0142).
///
/// Upstream, `segment` is an object of scriptable options. The port holds a
/// [LineSegmentStyle] of typed functions. A `segment` Map of a reference
/// config holds the typed functions of the test file in place of the
/// `'fn:<name>'` texts ([nativeSegmentStyle]). An observation of upstream
/// reads the keys of the resolved segment object through the dataset
/// context; the port has no such object. Thus both sides compare as the
/// names of the keys that hold a function ([withSegmentMarkers] and
/// [segmentStyleMarker]).
library;

import 'dart:ui' show StrokeCap, StrokeJoin;

import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableLineSegmentContext;
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_chartjs_port/src/types/line_segment_style.dart';

/// The keys of a segment style, in the order of the fields of
/// [LineSegmentStyle].
const List<String> _segmentKeys = [
  'borderColor',
  'backgroundColor',
  'borderWidth',
  'borderDash',
  'borderDashOffset',
  'borderCapStyle',
  'borderJoinStyle',
];

/// The [LineSegmentStyle] of a `segment` Map whose values are typed
/// functions of the test file. Another key throws.
LineSegmentStyle nativeSegmentStyle(Map<String, Object?> segment) {
  final unknown = segment.keys.where((key) => !_segmentKeys.contains(key));
  if (unknown.isNotEmpty) {
    throw ArgumentError.value(segment, 'segment', 'Unknown keys $unknown');
  }
  return LineSegmentStyle(
    borderColor:
        segment['borderColor']
            as ChartPaint? Function(ScriptableLineSegmentContext)?,
    backgroundColor:
        segment['backgroundColor']
            as ChartPaint? Function(ScriptableLineSegmentContext)?,
    borderWidth:
        segment['borderWidth']
            as double? Function(ScriptableLineSegmentContext)?,
    borderDash:
        segment['borderDash']
            as List<double>? Function(ScriptableLineSegmentContext)?,
    borderDashOffset:
        segment['borderDashOffset']
            as double? Function(ScriptableLineSegmentContext)?,
    borderCapStyle:
        segment['borderCapStyle']
            as StrokeCap? Function(ScriptableLineSegmentContext)?,
    borderJoinStyle:
        segment['borderJoinStyle']
            as StrokeJoin? Function(ScriptableLineSegmentContext)?,
  );
}

/// The marker of [style]: the names of its functions, as
/// [LineSegmentStyle.toString] gives them.
String segmentStyleMarker(LineSegmentStyle style) => style.toString();

/// [reference] with each Map under a key `segment` replaced by the marker
/// of its keys, at any depth: the form of [segmentStyleMarker].
Object? withSegmentMarkers(Object? reference) => switch (reference) {
  final Map<String, Object?> map => <String, Object?>{
    for (final MapEntry(:key, :value) in map.entries)
      key: key == 'segment' && value is Map<String, Object?>
          ? 'LineSegmentStyle(${[for (final name in _segmentKeys)
              if (value.containsKey(name)) name].join(', ')})'
          : withSegmentMarkers(value),
  },
  final List<Object?> list => [
    for (final item in list) withSegmentMarkers(item),
  ],
  _ => reference,
};
