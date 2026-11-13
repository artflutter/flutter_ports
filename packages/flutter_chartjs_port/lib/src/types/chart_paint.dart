// Original code, not ported from Chart.js: native chart paint values.

/// The paint of a chart color: a solid color, a gradient or a pattern
/// (Chart.js ADRs 0125 and 0128).
///
/// ```dart
/// const solid = ChartPaint.solid(Color(0xFF36A2EB));
/// const fade = ChartGradient.linear(
///   Offset.zero,
///   Offset(0, 200),
///   [Color(0xFF36A2EB), Color(0x0036A2EB)],
/// );
/// final tiles = ChartPattern(image);
/// const keep = ChartPaint.unchanged();
/// ```
library;

import 'dart:ui' show Color, Image, Offset, TileMode;

import 'package:flutter_chartjs_port/src/js/js_undefined.dart' show Undefined;
import 'package:meta/meta.dart' show immutable;

/// The renderer interprets these values; they cannot mutate canvas state.
@immutable
sealed class const ChartPaint() {
  /// A solid Flutter color.
  const factory ChartPaint.solid(Color color) = SolidChartPaint;

  /// Keeps the resolved baseline paint: the paint of the tooltip item, or
  /// the style of the canvas.
  const factory ChartPaint.unchanged() = UnchangedChartPaint;
}

/// A solid color value.
final class const SolidChartPaint(
  /// The native color.
  final Color color,
) extends ChartPaint {
  /// Creates the native paint value.
  this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SolidChartPaint && color == other.color;

  @override
  int get hashCode => Object.hash(SolidChartPaint, color);

  @override
  String toString() => 'ChartPaint.solid($color)';
}

/// A paint that the canvas draws with a shader: a [ChartGradient] or a
/// [ChartPattern].
///
/// Its coordinates are in the user space of the canvas at the draw, as the
/// coordinates of a path. The canvas builds the `dart:ui` shader for each
/// draw, with the transform of that draw. Treat the color and stop lists
/// as immutable configuration. The
/// canvas caches the shader by paint, list contents and transform: make a
/// gradient once and use it again.
sealed class const ChartShaderPaint() extends ChartPaint;

/// A gradient of [colors] in the user space of the canvas.
///
/// [stops] has one offset in [0, 1] for each color, in ascending order.
/// Without it, the colors have equal distances. A gradient with one color
/// is that color, and a gradient with no color paints nothing.
///
/// ```dart
/// const fade = ChartGradient.linear(
///   Offset.zero,
///   Offset(0, 200),
///   [Color(0xFF36A2EB), Color(0x0036A2EB)],
/// );
/// const glow = ChartGradient.radial(Offset(100, 100), 80, [
///   Color(0xFFFFFFFF),
///   Color(0xFF36A2EB),
/// ]);
/// const wheel = ChartGradient.sweep(
///   Offset(100, 100),
///   [Color(0xFFFF6384), Color(0xFF36A2EB), Color(0xFFFF6384)],
///   stops: [0, 0.5, 1],
/// );
/// ```
sealed class const ChartGradient() extends ChartShaderPaint {
  /// A gradient along the line from [from] to [to]. Equal points paint
  /// nothing.
  const factory ChartGradient.linear(
    Offset from,
    Offset to,
    List<Color> colors, {
    List<double>? stops,
  }) = LinearChartGradient;

  /// A gradient from the circle of [focal] and [focalRadius] to the circle
  /// of [center] and [radius]. Without [focal], both circles have the
  /// center [center]. Equal circles paint nothing.
  const factory ChartGradient.radial(
    Offset center,
    double radius,
    List<Color> colors, {
    List<double>? stops,
    Offset? focal,
    double focalRadius,
  }) = RadialChartGradient;

  /// A gradient around [center]. It starts at [startAngle], in radians
  /// clockwise from the positive x axis, and makes one full turn.
  const factory ChartGradient.sweep(
    Offset center,
    List<Color> colors, {
    List<double>? stops,
    double startAngle,
  }) = SweepChartGradient;

  /// The colors of the stops.
  List<Color> get colors;

  /// The offsets of the stops, or Dart `null` for equal distances.
  List<double>? get stops;
}

/// The gradient of [ChartGradient.linear].
final class const LinearChartGradient(
  /// The start point.
  final Offset from,

  /// The end point.
  final Offset to,
  @override final List<Color> colors, {
  @override final List<double>? stops,
}) extends ChartGradient {
  /// Creates the gradient.
  this;
}

/// The gradient of [ChartGradient.radial].
final class const RadialChartGradient(
  /// The center of the end circle.
  final Offset center,

  /// The radius of the end circle.
  final double radius,
  @override final List<Color> colors, {
  @override final List<double>? stops,

  /// The center of the start circle, or Dart `null` for [center].
  final Offset? focal,

  /// The radius of the start circle.
  final double focalRadius = 0,
}) extends ChartGradient {
  /// Creates the gradient.
  this;
}

/// The gradient of [ChartGradient.sweep].
final class const SweepChartGradient(
  /// The center.
  final Offset center,
  @override final List<Color> colors, {
  @override final List<double>? stops,

  /// The angle of the first color, in radians.
  final double startAngle = 0,
}) extends ChartGradient {
  /// Creates the gradient.
  this;
}

/// An image that repeats in the user space of the canvas, from the origin.
///
/// [tileModeX] and [tileModeY] give the tiles along each axis:
/// [TileMode.repeated] repeats the image, and [TileMode.decal] draws it
/// once.
///
/// ```dart
/// final stripes = ChartPattern(image);
/// final row = ChartPattern(image, tileModeY: TileMode.decal);
/// ```
final class const ChartPattern(
  /// The image of one tile.
  final Image image, {

  /// The tiles along x.
  final TileMode tileModeX = TileMode.repeated,

  /// The tiles along y.
  final TileMode tileModeY = TileMode.repeated,
}) extends ChartShaderPaint {
  /// Creates the pattern.
  this;
}

/// Selects the current item's resolved baseline paint.
final class const UnchangedChartPaint() extends ChartPaint {
  /// Creates the native paint value.
  this;
}

/// Reads an optional resolved paint. Absent values retain the current style.
/// Built-in legend/tooltip item generation uses `strict: false` for foreign
/// values left unresolved by user descriptors, retaining its baseline style.
ChartPaint chartPaintOf(Object? value, {bool strict = true}) => switch (value) {
  null || Undefined() => const ChartPaint.unchanged(),
  final ChartPaint paint => paint,
  _ when !strict => const ChartPaint.unchanged(),
  _ => throw ArgumentError.value(value, 'paint', 'Expected ChartPaint'),
};
