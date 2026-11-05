// Original code, not ported from Chart.js: guarded compound baseline fills.

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_partitioned_fill.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.segment.dart'
    show createBoundarySegment;
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// Differential benchmark/test switch; not a chart option.
@visibleForTesting
bool partitionedBaselineFillEnabled = const bool.fromEnvironment(
  'CHARTJS_PARTITIONED_BASELINE_FILL',
  defaultValue: true,
);

/// Successful optimized fills, for differential verification.
@visibleForTesting
int partitionedBaselineFillDraws = 0;

final Type _nativeSegment = createBoundarySegment(0, 0).runtimeType;
final Type _growablePoints = <types.PointElement>[].runtimeType;
final Type _fixedPoints = List<types.PointElement>.empty().runtimeType;

bool _nativePoints(List<types.PointElement> points) =>
    points.runtimeType == _growablePoints || points.runtimeType == _fixedPoints;

/// Try a full, ascending, unstyled cubic line against a private horizontal
/// origin/start/end boundary. Runs only after the original path was built.
/// No custom point/list/option getters are evaluated during preflight.
bool tryPartitionedBaselineFill(
  CanvasRenderingContext2D ctx, {
  required types.LineElement line,
  required Object target,
  required types.Segment source,
  required types.PointElement start,
  required types.PointElement end,
}) {
  if (!partitionedBaselineFillEnabled ||
      ctx is! PartitionedFillCanvas ||
      line.runtimeType != LineElement ||
      target.runtimeType != LineElement ||
      source.runtimeType != _nativeSegment) {
    return false;
  }
  final nativeLine = line as LineElement;
  final boundary = target as LineElement;
  final points = nativeLine.points;
  final bounds = boundary.points;
  final options = nativeLine.options;
  if (!_nativePoints(points) ||
      !_nativePoints(bounds) ||
      points.length < 1024 ||
      bounds.length != 2 ||
      nativeLine.loop == true ||
      nativeLine.decimated ||
      boundary.loop == true ||
      source.loop ||
      source.style != null ||
      source.start != 0 ||
      source.end != points.length - 1 ||
      options is! LineOptions ||
      options.isForeign(OptionKey.tension) ||
      options.isForeign(OptionKey.stepped) ||
      options.isForeign(OptionKey.cubicInterpolationMode) ||
      !options.tension.isFinite ||
      options.tension <= 0 ||
      options.stepped != false ||
      options.cubicInterpolationMode != 'default' ||
      start.runtimeType != PointElement ||
      end.runtimeType != PointElement ||
      bounds.any((p) => p.runtimeType != PointElement) ||
      points.any((p) => p.runtimeType != PointElement)) {
    return false;
  }
  final first = points.first;
  final last = points.last;
  final baseline = bounds.first.y;
  if (!baseline.isFinite ||
      bounds.last.y != baseline ||
      bounds.first.x != first.x ||
      bounds.last.x != last.x ||
      bounds.first.x + (bounds.last.x - bounds.first.x) != last.x ||
      start.x != first.x ||
      end.x != last.x ||
      first.y == baseline) {
    return false;
  }
  final above = first.y < baseline;
  bool sameSide(double y) => above ? y <= baseline : y >= baseline;
  var variation = 0.0;
  var minY = first.y;
  var maxY = first.y;
  for (var i = 0; i < points.length; i++) {
    final p = points[i];
    if ((p.skip ?? false) ||
        (p.stop ?? false) ||
        !p.x.isFinite ||
        !p.y.isFinite ||
        !sameSide(p.y)) {
      return false;
    }
    if (p.y < minY) minY = p.y;
    if (p.y > maxY) maxY = p.y;
    if (i == 0) continue;
    final previous = points[i - 1];
    variation += (p.y - previous.y).abs();
    if (!(p.x > previous.x) ||
        !previous.cp2x.isFinite ||
        !previous.cp2y.isFinite ||
        !p.cp1x.isFinite ||
        !p.cp1y.isFinite ||
        previous.cp2x < previous.x ||
        previous.cp2x > p.x ||
        p.cp1x < previous.x ||
        p.cp1x > p.x ||
        !sameSide(previous.cp2y) ||
        !sameSide(p.cp1y)) {
      return false;
    }
  }
  // Flat, monotone and gently varying curves should not pay for a second path.
  // This conservative workload guard targets repeated vertical oscillation.
  if (!variation.isFinite || variation <= 16 * (maxY - minY)) return false;
  final drawn = (ctx as PartitionedFillCanvas).tryFillPartitionedPath((path) {
    const chunk = 32;
    for (var begin = 0; begin < points.length - 1; begin += chunk) {
      final limit = (begin + chunk).clamp(0, points.length - 1);
      final head = points[begin];
      path.moveTo(head.x, head.y);
      for (var i = begin + 1; i <= limit; i++) {
        final previous = points[i - 1];
        final p = points[i];
        path.bezierCurveTo(
          previous.cp2x,
          previous.cp2y,
          p.cp1x,
          p.cp1y,
          p.x,
          p.y,
        );
      }
      path
        ..lineTo(points[limit].x, baseline)
        ..lineTo(head.x, baseline)
        ..closePath();
    }
  });
  if (drawn) partitionedBaselineFillDraws++;
  return drawn;
}
