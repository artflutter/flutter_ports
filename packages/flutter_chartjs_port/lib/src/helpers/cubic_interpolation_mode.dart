// Original code, not ported from Chart.js: the cubic interpolation modes.

/// The value of the line option `cubicInterpolationMode` (row
/// `adapt-cubic-interpolation-mode-objects`).
///
/// Upstream holds a keyword, `'default'` or `'monotone'` (index.d.ts:1984).
/// `_updateBezierControlPoints` (helpers.curve.ts:200) and the line element
/// (element.line.js:33, 188, 200 and 301) compare it as text. In the port,
/// the option holds a `CubicInterpolationMode`, also in a raw config: an
/// object with the methods `drawsCurves` and `updateControlPoints`.
/// `DefaultCubicInterpolationMode` and `MonotoneCubicInterpolationMode` of
/// `helpers.curve.dart` are the two modes of upstream. An app or a plugin
/// gives its own mode as a subclass, with no registration.
///
/// This library is a pure layer.
library;

import 'package:flutter_chartjs_port/src/types/geometric.dart' show SplinePoint;

/// The mode of the control points of a curved line: the option
/// `cubicInterpolationMode`.
///
/// ```dart
/// final class StraightCubicInterpolationMode extends CubicInterpolationMode {
///   const StraightCubicInterpolationMode();
///
///   @override
///   bool drawsCurves(Object? tension) => true;
///
///   @override
///   void updateControlPoints(
///     List<SplinePoint> points, {
///     required double tension,
///     required bool loop,
///     required String indexAxis,
///   }) {
///     for (final point in points) {
///       point
///         ..cp1x = point.x
///         ..cp1y = point.y
///         ..cp2x = point.x
///         ..cp2y = point.y;
///     }
///   }
/// }
/// ```
abstract class CubicInterpolationMode {
  /// A mode.
  const CubicInterpolationMode();

  /// Whether a line of this mode with the option `tension` [tension] draws
  /// curves through its control points. Upstream: `options.tension ||
  /// options.cubicInterpolationMode === 'monotone'` (element.line.js:33,
  /// 188, 200 and 301). A line that draws no curves draws straight lines
  /// and reads no control points.
  bool drawsCurves(Object? tension);

  /// Writes `cp1x`, `cp1y`, `cp2x` and `cp2y` of each point of [points]
  /// (helpers.curve.ts:200-217).
  ///
  /// [points] are the points that the line draws through: with the option
  /// `spanGaps`, the skipped points are out. [tension] is the `ToNumber` of
  /// the option `tension`. [loop] is true for a closed line, for example
  /// the line of a radar chart. [indexAxis] is the index axis of the
  /// dataset: `'x'`, `'y'`, or `'r'` for the fill of a radar chart.
  void updateControlPoints(
    List<SplinePoint> points, {
    required double tension,
    required bool loop,
    required String indexAxis,
  });

  /// The mode of [value], the value of the option, or Dart `null` for a
  /// value that is not a [CubicInterpolationMode]. Upstream takes the
  /// default mode for each value that is not `'monotone'`. A keyword of
  /// Chart.js is not a mode: a debug build stops on it.
  static CubicInterpolationMode? of(Object? value) {
    assert(
      value is! String,
      'The option cubicInterpolationMode takes a CubicInterpolationMode, '
      'not the name "$value".',
    );
    return value is CubicInterpolationMode ? value : null;
  }
}
