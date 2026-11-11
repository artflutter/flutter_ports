// Original code, not ported from Chart.js: guarded compound baseline fills.

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_partitioned_fill.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_chartjs_port/src/elements/line_dense_curve.dart'
    show writeDenseCurve;
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

/// Keeps the original path of [line] out of the engine when a partitioned fill
/// can replace its draw. It reads only the class and the length of the native
/// list. A fill that the partition declines reads the same path.
void deferPathOfPartitionedFill(
  CanvasRenderingContext2D ctx,
  types.LineElement line,
) {
  if (partitionedBaselineFillEnabled &&
      ctx is PartitionedFillCanvas &&
      line.runtimeType == LineElement) {
    final canvas = ctx as PartitionedFillCanvas;
    final points = (line as LineElement).points;
    if (_nativePoints(points) &&
        points.length >= canvas.deferredFillMinPoints) {
      canvas.deferCurrentPath();
    }
  }
}

/// Try a full, ascending, unstyled cubic line against a private horizontal
/// origin/start/end boundary. Runs after the commands of the original path, and
/// reads no state of that path. No custom point/list/option getters are
/// evaluated during preflight.
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
      !(ctx as PartitionedFillCanvas).takesPartitionedFill ||
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
  // The partitions take the merged curves of the line (Chart.js ADR 0114):
  // the vertices of the original path, cut into a partition after each 32
  // commands. Null when the line writes its curves as upstream does.
  final denseScale = denseCurveScaleOfLine(nativeLine, ctx);
  final drawn = (ctx as PartitionedFillCanvas).tryFillPartitionedPath((path) {
    if (denseScale != null) {
      final parts = _MergedPartitions(path, baseline);
      writeDenseCurve(
        parts,
        points,
        start: 0,
        count: points.length.toDouble(),
        ilen: (points.length - 1).toDouble(),
        reverse: false,
        move: true,
        scale: denseScale,
      );
      parts.finish();
      return;
    }
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

/// The path of a line with merged curves (Chart.js ADR 0114), cut into the
/// partitions of [tryPartitionedBaselineFill]. After each 32
/// commands it closes a partition over the baseline and starts the next one at
/// the same vertex.
final class _MergedPartitions implements CanvasPath {
  _MergedPartitions(this._path, this._baseline);

  static const int _commands = 32;

  final CanvasPath _path;
  final double _baseline;
  double _headX = 0;
  int _count = 0;
  double _x = 0;

  void _close() {
    _path
      ..lineTo(_x, _baseline)
      ..lineTo(_headX, _baseline)
      ..closePath();
  }

  void _after(double x, double y) {
    _x = x;
    if (++_count < _commands) return;
    _close();
    _path.moveTo(x, y);
    _headX = x;
    _count = 0;
  }

  /// Closes the last partition.
  void finish() {
    if (_count > 0) _close();
    _count = 0;
  }

  @override
  void moveTo(double x, double y) {
    _path.moveTo(x, y);
    _headX = _x = x;
    _count = 0;
  }

  @override
  void lineTo(double x, double y) {
    _path.lineTo(x, y);
    _after(x, y);
  }

  @override
  void bezierCurveTo(
    double cp1x,
    double cp1y,
    double cp2x,
    double cp2y,
    double x,
    double y,
  ) {
    _path.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
    _after(x, y);
  }

  @override
  void closePath() => throw UnsupportedError('closePath');

  @override
  void quadraticCurveTo(double cpx, double cpy, double x, double y) =>
      throw UnsupportedError('quadraticCurveTo');

  @override
  void arc(
    double x,
    double y,
    double radius,
    double startAngle,
    double endAngle, [
    bool counterclockwise = false,
  ]) => throw UnsupportedError('arc');

  @override
  void arcTo(double x1, double y1, double x2, double y2, double radius) =>
      throw UnsupportedError('arcTo');

  @override
  void ellipse(
    double x,
    double y,
    double radiusX,
    double radiusY,
    double rotation,
    double startAngle,
    double endAngle, [
    bool counterclockwise = false,
  ]) => throw UnsupportedError('ellipse');

  @override
  void rect(double x, double y, double w, double h) =>
      throw UnsupportedError('rect');

  @override
  void roundRect(double x, double y, double w, double h, [Object? radii]) =>
      throw UnsupportedError('roundRect');
}
