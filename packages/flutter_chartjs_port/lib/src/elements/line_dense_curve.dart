// Original code, not ported from Chart.js: merged curves of a dense line.

/// The merge of the narrow curves of a dense line (Chart.js ADR 0114).
///
/// A line with curves gives the engine one cubic curve for each point. At
/// 20,000 points on 2,000 bitmap pixels, one curve covers a tenth of a pixel,
/// and the stroke of these curves is the largest raster cost of a line chart.
/// A straight line of the same data is cheap: `_fastPathSegment` of
/// `element.line.dart` (upstream `fastPathSegment`) merges the points of one
/// pixel column into at most four line commands. Upstream has no such merge
/// for a curve.
///
/// [writeDenseCurve] writes a run of points as `_pathSegment` does, with one
/// difference: a curve that is not wider than [denseCurveThreshold] bitmap
/// pixels (its two ends and its two control points) goes out as lines through
/// its start, its extremes in y and its end. These points are on the curve,
/// so a peak keeps its height, and the lines stay inside the x range of the
/// curve: an edge moves sideways by at most the threshold. Then the vertices
/// of one bitmap pixel column merge into at most four vertices (the first,
/// the one with the smallest y, the one with the largest y and the last, in
/// the order of the path, each at its own place), when the column has more
/// than [_mergeAbove] vertices after its first. Each other curve goes out
/// unchanged.
///
/// This library is a pure layer.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_chartjs_port/src/canvas/canvas.dart' show CanvasPath;
import 'package:flutter_chartjs_port/src/canvas/canvas_dense_curve.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart'
    show PointElement;
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show bezierCurveTo;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// Differential test switch of Chart.js ADR 0114; not a chart option. With it
/// off, each curve goes out as upstream writes it.
@visibleForTesting
bool denseCurveMergeEnabled = const bool.fromEnvironment(
  'CHARTJS_DENSE_CURVE_MERGE',
  defaultValue: true,
);

/// The largest width of a curve that goes out as lines, in bitmap pixels. A
/// line of even x steps starts to merge at 2 points for each bitmap pixel.
const double denseCurveThreshold = .5;

/// A bitmap pixel column merges when it has more vertices than this after its
/// first one. The merge writes at most 3 commands after the first vertex, so
/// it never adds a command.
const int _mergeAbove = 3;

/// The count of the curves that [writeDenseCurve] wrote as lines, for
/// differential tests.
@visibleForTesting
int denseCurvesMerged = 0;

/// The bitmap scale of x of [ctx] for the merge, or null: the switch is off,
/// or [ctx] is not a context that takes the merged geometry (a recording
/// context, a context of user code, a transform that is not axis aligned, a
/// shadow).
double? denseCurveScaleOf(CanvasPath ctx) =>
    denseCurveMergeEnabled && ctx is DenseCurveCanvas
    ? (ctx as DenseCurveCanvas).denseCurveScale
    : null;

/// Whether the curve from [previous] to [point] is narrow: each number is
/// finite, both points are of the class [PointElement] itself, and the two
/// ends and the two control points lie within [width] units of x.
@pragma('vm:prefer-inline')
bool _narrow(
  types.PointElement previous,
  types.PointElement point,
  double c1x,
  double c1y,
  double c2x,
  double c2y,
  double width,
) {
  final x0 = previous.x;
  final x3 = point.x;
  var lo = x0;
  var hi = x0;
  if (c1x < lo) {
    lo = c1x;
  } else if (c1x > hi) {
    hi = c1x;
  }
  if (c2x < lo) {
    lo = c2x;
  } else if (c2x > hi) {
    hi = c2x;
  }
  if (x3 < lo) {
    lo = x3;
  } else if (x3 > hi) {
    hi = x3;
  }
  // The sum is not finite when one number is not finite.
  return hi - lo <= width &&
      (x0 + c1x + c2x + x3 + previous.y + c1y + c2y + point.y).isFinite &&
      previous is PointElement &&
      previous.typedWrites &&
      point is PointElement &&
      point.typedWrites;
}

/// Writes the points of a run to [ctx], as the loop of `_pathSegment` of
/// `element.line.dart` does for a line with curves and no loop: [start],
/// [count], [ilen], [reverse] and [move] are its values. [scale] is the count
/// of bitmap pixels of one unit of x.
///
/// With [keepEnds], the first and the last curve of the run go out unchanged:
/// the caps of a stroke follow their tangents.
///
/// True when at least one curve went out as lines.
bool writeDenseCurve(
  CanvasPath ctx,
  List<types.PointElement> points, {
  required double start,
  required double count,
  required double ilen,
  required bool reverse,
  required bool move,
  required double scale,
  bool keepEnds = true,
}) {
  final writer = _DenseWriter(ctx, scale);
  final width = denseCurveThreshold / scale;
  var first = move;
  var curves = 0;
  var replaced = 0;
  types.PointElement? prev;

  for (var i = 0.0; i <= ilen; ++i) {
    final point =
        points[(start + (reverse ? ilen - i : i)).remainder(count).toInt()];

    if (point.skip ?? false) {
      // If there is a skipped point inside a segment, spanGaps must be true
      continue;
    } else if (first) {
      final x = point.x;
      final y = point.y;
      ctx.moveTo(x, y);
      writer.restart(x, y);
      first = false;
    } else if (prev == null) {
      // `lineMethod(ctx, undefined, point)` of a run with `move: false`: a
      // line.
      writer.settle();
      final x = point.x;
      final y = point.y;
      ctx.lineTo(x, y);
      writer.restart(x, y);
    } else {
      final c1x = reverse ? prev.cp1x : prev.cp2x;
      final c1y = reverse ? prev.cp1y : prev.cp2y;
      final c2x = reverse ? point.cp2x : point.cp1x;
      final c2y = reverse ? point.cp2y : point.cp1y;
      curves++;
      if ((keepEnds && (curves == 1 || i == ilen)) ||
          !_narrow(prev, point, c1x, c1y, c2x, c2y, width)) {
        // The curve starts at the current point of the path.
        writer.settle();
        bezierCurveTo(ctx, prev, point, reverse);
        writer.restart(point.x, point.y);
      } else {
        final x0 = prev.x;
        final y0 = prev.y;
        final x3 = point.x;
        final y3 = point.y;
        // A control point past the y of both ends: the curve has an extreme
        // past its ends.
        if (y0 < y3
            ? (c1y < y0 || c1y > y3 || c2y < y0 || c2y > y3)
            : (c1y < y3 || c1y > y0 || c2y < y3 || c2y > y0)) {
          // y'(t) / 3 = a (1 - t)^2 + 2 b (1 - t) t + c t^2.
          final a = c1y - y0;
          final b = c2y - c1y;
          final c = y3 - c2y;
          final qa = a - 2 * b + c;
          final qb = 2 * (b - a);
          var t1 = double.nan;
          var t2 = double.nan;
          if (qa == 0) {
            if (qb != 0) t1 = -a / qb;
          } else {
            final disc = qb * qb - 4 * qa * a;
            if (disc > 0) {
              final root = math.sqrt(disc);
              final q = -0.5 * (qb < 0 ? qb - root : qb + root);
              t1 = q / qa;
              if (q != 0) t2 = a / q;
              if (t2 < t1) {
                final t = t1;
                t1 = t2;
                t2 = t;
              }
            }
          }
          if (t1 > 0 && t1 < 1) {
            final m = 1 - t1;
            final w0 = m * m * m;
            final w1 = 3 * m * m * t1;
            final w2 = 3 * m * t1 * t1;
            final w3 = t1 * t1 * t1;
            writer.vertex(
              w0 * x0 + w1 * c1x + w2 * c2x + w3 * x3,
              w0 * y0 + w1 * c1y + w2 * c2y + w3 * y3,
            );
          }
          if (t2 > 0 && t2 < 1) {
            final m = 1 - t2;
            final w0 = m * m * m;
            final w1 = 3 * m * m * t2;
            final w2 = 3 * m * t2 * t2;
            final w3 = t2 * t2 * t2;
            writer.vertex(
              w0 * x0 + w1 * c1x + w2 * c2x + w3 * x3,
              w0 * y0 + w1 * c1y + w2 * c2y + w3 * y3,
            );
          }
        }
        writer.vertex(x3, y3);
        replaced++;
      }
    }

    prev = point;
  }
  writer.settle();
  denseCurvesMerged += replaced;
  return replaced > 0;
}

/// The vertices of the narrow curves of a run, by bitmap pixel column.
final class _DenseWriter {
  _DenseWriter(this._ctx, this._scale);

  final CanvasPath _ctx;
  final double _scale;

  /// The vertices of the column after its first one, until the column merges.
  final Float64List _kept = Float64List(_mergeAbove * 2);

  // The column of the pending vertices, and the count of the vertices after
  // its first one. The first vertex has the index 0.
  double _column = double.nan;
  int _extra = 0;
  bool _merged = false;
  double _minX = 0;
  double _minY = 0;
  int _minIndex = 0;
  double _maxX = 0;
  double _maxY = 0;
  int _maxIndex = 0;
  double _lastX = 0;
  double _lastY = 0;

  /// Starts the columns again at (x, y), the current point of the path.
  void restart(double x, double y) {
    _column = (x * _scale).floorToDouble();
    _extra = 0;
    _merged = false;
    _minX = _maxX = _lastX = x;
    _minY = _maxY = _lastY = y;
    _minIndex = _maxIndex = 0;
  }

  /// A vertex of a narrow curve.
  void vertex(double x, double y) {
    final column = (x * _scale).floorToDouble();
    if (column != _column) {
      settle();
      // Draw line to next x-position, using the first (or only) y-value in
      // that group, as the upstream fast path does.
      _ctx.lineTo(x, y);
      _column = column;
      _minX = _maxX = x;
      _minY = _maxY = y;
      _minIndex = _maxIndex = 0;
    } else {
      if (_extra < _mergeAbove) {
        _kept[_extra * 2] = x;
        _kept[_extra * 2 + 1] = y;
      } else {
        _merged = true;
      }
      _extra++;
      if (y < _minY) {
        _minX = x;
        _minY = y;
        _minIndex = _extra;
      } else if (y > _maxY) {
        _maxX = x;
        _maxY = y;
        _maxIndex = _extra;
      }
    }
    _lastX = x;
    _lastY = y;
  }

  /// Writes the pending vertices of the column: the current point of the path
  /// is then the last vertex. The callers are the next column, a curve that
  /// goes out unchanged, and the end of the run.
  void settle() {
    final extra = _extra;
    if (extra == 0) return;
    final ctx = _ctx;
    if (!_merged) {
      final kept = _kept;
      for (var k = 0; k < extra; k++) {
        ctx.lineTo(kept[k * 2], kept[k * 2 + 1]);
      }
    } else {
      // The two extremes in the order of the path, then the last vertex. The
      // first vertex (index 0) is on the path.
      final minFirst = _minIndex < _maxIndex;
      final a = minFirst ? _minIndex : _maxIndex;
      final b = minFirst ? _maxIndex : _minIndex;
      if (a != 0 && a != extra) {
        ctx.lineTo(minFirst ? _minX : _maxX, minFirst ? _minY : _maxY);
      }
      if (b != a && b != extra) {
        ctx.lineTo(minFirst ? _maxX : _minX, minFirst ? _maxY : _minY);
      }
      ctx.lineTo(_lastX, _lastY);
    }
    _merged = false;
    _extra = 0;
  }
}
