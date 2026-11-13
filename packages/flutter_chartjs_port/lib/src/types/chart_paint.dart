// Original code, not ported from Chart.js: native chart paint values.

/// Paint values selected by native tooltip callbacks (Chart.js ADR 0125).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/src/types/color.dart'
    show CanvasGradient, CanvasPattern;

/// The renderer interprets these values; they cannot mutate canvas state.
sealed class const ChartPaint() {
  /// A solid Flutter color.
  const factory ChartPaint.solid(Color color) = SolidChartPaint;

  /// A native canvas gradient, retained by identity.
  const factory ChartPaint.gradient(CanvasGradient gradient) =
      GradientChartPaint;

  /// A native canvas pattern, retained by identity.
  const factory ChartPaint.pattern(CanvasPattern pattern) = PatternChartPaint;

  /// Keeps the resolved baseline paint of the tooltip item.
  const factory ChartPaint.unchanged() = UnchangedChartPaint;
}

/// A solid color value.
final class const SolidChartPaint(
  /// The native color.
  final Color color,
) extends ChartPaint {
  /// Creates the native paint value.
  this;
}

/// A gradient handle.
final class const GradientChartPaint(
  /// The native gradient.
  final CanvasGradient gradient,
) extends ChartPaint {
  /// Creates the native paint value.
  this;
}

/// A pattern handle.
final class const PatternChartPaint(
  /// The native pattern.
  final CanvasPattern pattern,
) extends ChartPaint {
  /// Creates the native paint value.
  this;
}

/// Selects the current item's resolved baseline paint.
final class const UnchangedChartPaint() extends ChartPaint {
  /// Creates the native paint value.
  this;
}

/// The native canvas style, or null to leave the current paint unchanged.
Object? chartPaintValue(ChartPaint paint) => switch (paint) {
  SolidChartPaint(:final color) => color,
  GradientChartPaint(:final gradient) => gradient,
  PatternChartPaint(:final pattern) => pattern,
  UnchangedChartPaint() => null,
};

/// Classifies an already-native canvas style at the element boundary.
ChartPaint chartPaintOf(Object? value) => switch (value) {
  final Color color => ChartPaint.solid(color),
  final CanvasGradient gradient => ChartPaint.gradient(gradient),
  final CanvasPattern pattern => ChartPaint.pattern(pattern),
  _ => const ChartPaint.unchanged(),
};
