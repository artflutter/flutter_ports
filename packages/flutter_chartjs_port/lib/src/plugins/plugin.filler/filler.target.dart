// Ported from Chart.js v4.6.1 src/plugins/plugin.filler/filler.target.js (MIT, Chart.js Contributors).

/// Port of `src/plugins/plugin.filler/filler.target.js`.
///
/// The target of `_getTarget` is a `types.LineElement` (a boundary line, a
/// stack line, or the `dataset` element of another meta), a [SimpleArc],
/// `true` (`'shape'`) or Dart `null` (Chart.js ADR 0040, section 4).
///
/// `computeCircularBoundary` makes a plain object for each record of
/// `getPointPositionForValue` (filler.target.js:91). The port makes a
/// `PointElement` with `x`, `y` and `angle` (Chart.js ADR 0040, section 1,
/// the difference `adapt-line-points-elements`). Thus this file imports
/// `element.point.dart`, which `filler.target.js` does not import. The
/// filler reads no `xCenter` and no `yCenter` (Chart.js ADR 0040, section
/// 9).
///
/// This library is a pure layer (Chart.js ADR 0038, section 9).
library;

// DIVERGES(chartjs): adapt-line-points-elements, the wraps make point elements.
import 'package:flutter_chartjs_port/chartjs_core.dart';

/// filler.target.js:13 `_getTarget(source)`.
///
/// The result is a `types.LineElement`, another `types.Element` (the
/// `dataset` element of a meta whose controller is not a line), a
/// [SimpleArc], `true` or Dart `null`.
Object? getTarget(FillerSource source) {
  final chart = source.chart;
  final fill = source.fill;
  final line = source.line;

  // DIVERGES(chartjs): adapt-fill-target-objects, a dataset index is a class.
  if (fill case DatasetFill(:final index)) {
    return _getLineByIndex(chart, index);
  }

  if (fill is StackFill) {
    return buildStackLine(source);
  }

  if (fill is ShapeFill) {
    return true;
  }

  final boundary = _computeBoundary(source);

  if (boundary is SimpleArc) {
    return boundary;
  }

  return createBoundaryLine(boundary, line);
}

/// filler.target.js:41 `getLineByIndex(chart, index)`.
///
/// @param {Chart} chart
/// @param {number} index
///
/// `getDatasetMeta` always gives a meta. Dart `null` is the JS `null` of a
/// hidden dataset, and of a meta without a `dataset` element.
IElement? _getLineByIndex(IChart chart, int index) {
  final meta = chart.getDatasetMeta(index);
  final visible = chart.isDatasetVisible(index);
  return visible ? meta.dataset : null;
}

/// filler.target.js:47 `computeBoundary(source)`.
///
/// `scale.getPointPositionForValue` is the type test of a radial linear
/// scale. Dart `null` for the scale is `source.scale || {}`.
Object? _computeBoundary(FillerSource source) {
  final scale = source.scale;

  if (scale is IRadialLinearScale) {
    return _computeCircularBoundary(source, scale);
  }
  return _computeLinearBoundary(source);
}

/// filler.target.js:57 `computeLinearBoundary(source)`.
///
/// Dart `null` for the scale is the default `{}` of `{scale = {}, fill} =
/// source`. The result is the record `{x, y}` or Dart `null`.
({double? x, double? y})? _computeLinearBoundary(FillerSource source) {
  final scale = source.scale;
  final fill = source.fill;
  final pixel = getTargetPixel(fill, scale);

  if (isFinite(pixel)) {
    final horizontal = scale!.isHorizontal();

    return (x: horizontal ? pixel : null, y: horizontal ? null : pixel);
  }

  return null;
}

/// filler.target.js:73 `computeCircularBoundary(source)`.
///
/// The result is a [SimpleArc] on a circular grid, else the points of the
/// polygon as point elements.
Object _computeCircularBoundary(FillerSource source, IRadialLinearScale scale) {
  final fill = source.fill;
  final options = scale.options;
  final length = scale.getLabels().length;
  final start = jsTruthy(optionOf(options, OptionKey.reverse))
      ? scale.max
      : scale.min;
  final value = getTargetValue(fill, scale, start);
  final target = <IPointElement>[];

  if (jsTruthy(
    optionOf(optionOf(options, OptionKey.grid), OptionKey.circular),
  )) {
    final center = scale.getPointPositionForValue(0, start);
    return SimpleArc(
      x: center.x,
      y: center.y,
      radius: scale.getDistanceFromCenterForValue(value),
    );
  }

  for (var i = 0; i < length; ++i) {
    final p = scale.getPointPositionForValue(i, value);
    // DIVERGES(chartjs): adapt-line-points-elements, {x, y, angle} is a point.
    target.add(
      PointElement()
        ..x = p.x
        ..y = p.y
        ..angle = p.angle,
    );
  }
  return target;
}
