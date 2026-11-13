// Original code, not ported from Chart.js: the scale option border.

/// The values of the scale option `border` (Chart.js ADR 0141, row
/// `adapt-native-scale-border`): [ScaleBorder], [AxisBorder] and
/// [RadialAxisBorder].
library;

import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:meta/meta.dart' show immutable;

/// The value of the scale option `border` (index.d.ts:3042
/// `BorderOptions`).
///
/// A cartesian axis takes an [AxisBorder], and the radial linear axis a
/// [RadialAxisBorder]. The option also takes a function of the scale
/// context that gives a border:
///
/// ```dart
/// const border = AxisBorder(color: ChartPaint.solid(Color(0xFF0000FF)));
/// LinearAxis(border: border);
/// <String, Object?>{'type': 'linear', 'border': border};
/// ```
@immutable
abstract class const ScaleBorder() {
  /// A border of a subclass.
  this;

  /// This border with the fields of [other] over it.
  ///
  /// The scopes of a chart combine through this method, as two fonts do with
  /// `TextStyle.merge`. A border of the same class merges field by field: a
  /// field of [other] that is not null wins. A border of another class
  /// replaces this one, and Dart `null` keeps it.
  ScaleBorder merge(ScaleBorder? other);
}

/// The axis line of a cartesian axis (category, linear, logarithmic, time
/// and time series): the scale option `border`.
///
/// A field that is null is not set: the chart takes the value of the next
/// scope, and at last the default of Chart.js. The default color is the
/// chart default `borderColor`.
///
/// ```dart
/// LinearAxis(border: const AxisBorder(display: false));
/// LinearAxis(border: const AxisBorder(width: 2, dash: [4, 4]));
/// ```
final class const AxisBorder({
  /// Whether the chart draws the axis line: `display`. The default is
  /// `true`.
  final bool? display,

  /// The color of the axis line: `color`. The default is the chart default
  /// `borderColor`.
  final ChartPaint? color,

  /// The width of the axis line in pixels: `width`. The default is 1.
  final double? width,

  /// The dash of the grid lines: `dash`, the lengths of the dashes and the
  /// gaps. The default is a solid line.
  final List<double>? dash,

  /// The offset of the dash of the grid lines: `dashOffset`. The default is
  /// 0.
  final double? dashOffset,

  /// The z index of the axis line: `z`. The default is 0.
  final double? z,
}) extends ScaleBorder {
  /// An axis line with the given fields.
  this;

  @override
  ScaleBorder merge(ScaleBorder? other) => switch (other) {
    null => this,
    AxisBorder() => AxisBorder(
      display: other.display ?? display,
      color: other.color ?? color,
      width: other.width ?? width,
      dash: other.dash ?? dash,
      dashOffset: other.dashOffset ?? dashOffset,
      z: other.z ?? z,
    ),
    _ => other,
  };

  /// A copy of this border with the given fields.
  AxisBorder copyWith({
    bool? display,
    ChartPaint? color,
    double? width,
    List<double>? dash,
    double? dashOffset,
    double? z,
  }) => AxisBorder(
    display: display ?? this.display,
    color: color ?? this.color,
    width: width ?? this.width,
    dash: dash ?? this.dash,
    dashOffset: dashOffset ?? this.dashOffset,
    z: z ?? this.z,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AxisBorder &&
          other.display == display &&
          other.color == color &&
          other.width == width &&
          _sameDash(other.dash, dash) &&
          other.dashOffset == dashOffset &&
          other.z == z;

  @override
  int get hashCode =>
      Object.hash(display, color, width, _dashHash(dash), dashOffset, z);

  @override
  String toString() =>
      'AxisBorder(display: $display, color: $color, width: $width, '
      'dash: $dash, dashOffset: $dashOffset, z: $z)';
}

/// The dash of the circles and the polygons of the grid of the radial
/// linear axis: the scale option `border`. The radial axis has no axis line.
///
/// ```dart
/// RadialLinearAxis(border: const RadialAxisBorder(dash: [2, 2]));
/// ```
final class const RadialAxisBorder({
  /// The dash of the grid lines: `dash`, the lengths of the dashes and the
  /// gaps. The default is a solid line.
  final List<double>? dash,

  /// The offset of the dash of the grid lines: `dashOffset`. The default is
  /// 0.
  final double? dashOffset,
}) extends ScaleBorder {
  /// A grid dash with the given fields.
  this;

  @override
  ScaleBorder merge(ScaleBorder? other) => switch (other) {
    null => this,
    RadialAxisBorder() => RadialAxisBorder(
      dash: other.dash ?? dash,
      dashOffset: other.dashOffset ?? dashOffset,
    ),
    _ => other,
  };

  /// A copy of this border with the given fields.
  RadialAxisBorder copyWith({List<double>? dash, double? dashOffset}) =>
      RadialAxisBorder(
        dash: dash ?? this.dash,
        dashOffset: dashOffset ?? this.dashOffset,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadialAxisBorder &&
          _sameDash(other.dash, dash) &&
          other.dashOffset == dashOffset;

  @override
  int get hashCode => Object.hash(_dashHash(dash), dashOffset);

  @override
  String toString() => 'RadialAxisBorder(dash: $dash, dashOffset: $dashOffset)';
}

/// Whether the dashes [a] and [b] have the same lengths.
bool _sameDash(List<double>? a, List<double>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The hash of the dash [dash], from its lengths.
int _dashHash(List<double>? dash) =>
    dash == null ? null.hashCode : Object.hashAll(dash);
