// Original code, not ported from Chart.js: the line option segment.

/// The value of the line option `segment` (Chart.js ADR 0142).
library;

import 'dart:ui' show StrokeCap, StrokeJoin;

import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableLineSegmentContext;
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsTruthy;
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:meta/meta.dart' show immutable, internal;

/// The style functions of the parts of a line: the value of the line option
/// `segment` (index.d.ts:2004, Chart.js ADR 0142).
///
/// A part goes from one point to the next. The line calls each function
/// that is not null with the context of each part, in the order of
/// `readStyle` (helpers.segment.js:337). A function that gives null keeps
/// the style of the line for that part, as `undefined` does upstream. A
/// field that is null keeps it for each part.
///
/// ```dart
/// LineDataset(
///   data: values,
///   segment: LineSegmentStyle(
///     // Red where the line goes down.
///     borderColor: (s) => values[s.p1DataIndex] < values[s.p0DataIndex]
///         ? const ChartPaint.solid(Color(0xFFFF0000))
///         : null,
///   ),
/// );
/// <String, Object?>{'data': values, 'segment': LineSegmentStyle(...)};
/// ```
@immutable
final class const LineSegmentStyle({
  /// The `borderColor` of a part.
  final ChartPaint? Function(ScriptableLineSegmentContext segment)? borderColor,

  /// The `backgroundColor` of a part: the fill of the area below it.
  final ChartPaint? Function(ScriptableLineSegmentContext segment)?
  backgroundColor,

  /// The `borderWidth` of a part.
  final double? Function(ScriptableLineSegmentContext segment)? borderWidth,

  /// The `borderDash` of a part.
  final List<double>? Function(ScriptableLineSegmentContext segment)?
  borderDash,

  /// The `borderDashOffset` of a part.
  final double? Function(ScriptableLineSegmentContext segment)?
  borderDashOffset,

  /// The `borderCapStyle` of a part.
  final StrokeCap? Function(ScriptableLineSegmentContext segment)?
  borderCapStyle,

  /// The `borderJoinStyle` of a part.
  final StrokeJoin? Function(ScriptableLineSegmentContext segment)?
  borderJoinStyle,
}) {
  /// The style functions of the parts of a line.
  this;

  /// This style with the functions of [other] over it: a field of [other]
  /// that is not null wins. The scopes of a chart combine so, as the keys of
  /// the segment objects of the scopes combine upstream.
  LineSegmentStyle merge(LineSegmentStyle? other) {
    if (other == null) return this;
    return LineSegmentStyle(
      borderColor: other.borderColor ?? borderColor,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderDash: other.borderDash ?? borderDash,
      borderDashOffset: other.borderDashOffset ?? borderDashOffset,
      borderCapStyle: other.borderCapStyle ?? borderCapStyle,
      borderJoinStyle: other.borderJoinStyle ?? borderJoinStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LineSegmentStyle &&
      other.borderColor == borderColor &&
      other.backgroundColor == backgroundColor &&
      other.borderWidth == borderWidth &&
      other.borderDash == borderDash &&
      other.borderDashOffset == borderDashOffset &&
      other.borderCapStyle == borderCapStyle &&
      other.borderJoinStyle == borderJoinStyle;

  @override
  int get hashCode => Object.hash(
    borderColor,
    backgroundColor,
    borderWidth,
    borderDash,
    borderDashOffset,
    borderCapStyle,
    borderJoinStyle,
  );

  @override
  String toString() {
    final names = [
      if (borderColor != null) 'borderColor',
      if (backgroundColor != null) 'backgroundColor',
      if (borderWidth != null) 'borderWidth',
      if (borderDash != null) 'borderDash',
      if (borderDashOffset != null) 'borderDashOffset',
      if (borderCapStyle != null) 'borderCapStyle',
      if (borderJoinStyle != null) 'borderJoinStyle',
    ];
    return 'LineSegmentStyle(${names.join(', ')})';
  }
}

/// The value of the option `segment` (Chart.js ADR 0142): a
/// [LineSegmentStyle], or Dart `null` for a falsy value, which upstream
/// takes as no segment styles (helpers.segment.js:266). A Map, a constant
/// or another truthy value stops a debug build, and a release build takes
/// it as no segment styles.
@internal
LineSegmentStyle? lineSegmentStyleOf(Object? value) {
  if (value is LineSegmentStyle) return value;
  assert(
    !jsTruthy(value),
    'The option segment takes a LineSegmentStyle, not $value.',
  );
  return null;
}
