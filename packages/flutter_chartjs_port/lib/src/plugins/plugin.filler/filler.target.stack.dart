// Ported from Chart.js v4.6.1 src/plugins/plugin.filler/filler.target.stack.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-stack-exact-points, guarded exact-point experiment.

/// Port of `src/plugins/plugin.filler/filler.target.stack.js`.
///
/// `filler.target.stack.js:7` imports `LineElement` from
/// `elements/index.js`, which also exports `PointElement`. This file
/// imports `element.line.dart` and `element.point.dart`.
///
/// `line.interpolate` gives Dart `null`, a point element of the line, an
/// `InterpolatedPoint` or a `List` of them. The port wraps each result that
/// is not a point element in a `PointElement` with the properties of the
/// upstream value: `x` and `y` of a plain point, and no property for an
/// Array (Chart.js ADR 0040, section 2, the difference
/// `adapt-line-points-elements`).
///
/// This library is a pure layer (Chart.js ADR 0038, section 9).
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:meta/meta.dart';

/// filler.target.stack.js:15 `_buildStackLine(source)`.
///
/// @param {{ chart: Chart; scale: Scale; index: number; line: LineElement; }}
/// source
/// @return {LineElement}
///
/// A source without a scale throws a [TypeError] at the read of
/// `scale.getMatchingVisibleMetas`, as upstream. A point index of a
/// segment past the end of `line.points` is the `undefined` of upstream,
/// and `findPoint` throws a [TypeError] for it.
ILineElement buildStackLine(FillerSource source) {
  final scale = source.scale;
  final index = source.index;
  final line = source.line;
  final points = <IPointElement>[];
  final segments = line.segments;
  final sourcePoints = line.points;
  final linesBelow = _getLinesBelow(scale!, index)
    ..add(createBoundaryLine((x: null, y: scale.bottom), line));

  final search = StackPointSearch.create(
    line,
    sourcePoints,
    segments,
    linesBelow.length - 1,
  );

  for (var i = 0; i < segments.length; i++) {
    final segment = segments[i];
    for (var j = segment.start; j <= segment.end; j++) {
      _addPointsBelow(
        points,
        j < sourcePoints.length ? sourcePoints[j.toInt()] : null,
        linesBelow,
        search,
      );
    }
  }
  return LineElement(<String, Object?>{
    'points': points,
    'options': <String, Object?>{},
  });
}

/// filler.target.stack.js:37 `getLinesBelow(scale, index)`.
///
/// @param {Scale} scale
/// @param {number} index
/// @return {LineElement[]}
///
/// The items are the `dataset` elements of the metas: Dart `null` for the
/// JS `null` of a meta without one. The boundary line of
/// filler.target.stack.js:21 can be Dart `null` too.
List<IElement?> _getLinesBelow(IScale scale, int index) {
  final below = <IElement?>[];
  final metas = scale.getMatchingVisibleMetas('line');

  for (var i = 0; i < metas.length; i++) {
    final meta = metas[i];
    if (meta.index == index) {
      break;
    }
    if (!(meta.hidden ?? false)) {
      below.insert(0, meta.dataset);
    }
  }
  return below;
}

/// filler.target.stack.js:58 `addPointsBelow(points, sourcePoint,
/// linesBelow)`.
///
/// @param {PointElement[]} points
/// @param {PointElement} sourcePoint
/// @param {LineElement[]} linesBelow
///
/// Dart `null` for [sourcePoint] is the `undefined` of an index past the
/// end of the points.
void _addPointsBelow(
  List<IPointElement> points,
  IPointElement? sourcePoint,
  List<IElement?> linesBelow,
  StackPointSearch? search,
) {
  final postponed = <IPointElement>[];
  for (var j = 0; j < linesBelow.length; j++) {
    final line = linesBelow[j];
    final (:first, :last, :point) =
        search?.find(j, line, sourcePoint) ??
        _findPoint(line, sourcePoint, 'x');

    if (point == null || (first && last)) {
      continue;
    }
    if (first) {
      // First point of a segment -> need to add another point before this,
      postponed.insert(0, point);
    } else {
      points.add(point);
      if (!last) {
        // In the middle of a segment, no need to add more points.
        break;
      }
    }
  }
  points.addAll(postponed);
}

/// filler.target.stack.js:87 `findPoint(line, sourcePoint, property)`.
///
/// @param {LineElement} line
/// @param {PointElement} sourcePoint
/// @param {string} property
/// @returns {{point?: PointElement, first?: boolean, last?: boolean}}
///
/// [line] is cast to `types.LineElement` at the call of `interpolate`: Dart
/// `null` or another element throws a [TypeError]. Upstream throws for
/// `undefined` and for an element without `interpolate`, and reads an
/// element with the line API by name (the row
/// `adapt-filler-target-classes`). Dart `null` for [sourcePoint] throws the
/// [TypeError] of the read `point[property]` of `undefined`
/// (element.line.js:353). The upstream `{}` is the record with `false`,
/// `false` and Dart `null`.
({bool first, bool last, IPointElement? point}) _findPoint(
  Object? line,
  IPointElement? sourcePoint,
  String property,
) {
  // DIVERGES(chartjs): adapt-filler-target-classes, a line below is a cast.
  final target = line! as ILineElement;
  final point = stackResultPoint(
    target.interpolate(sourcePoint ?? (throw TypeError()), property),
  );
  if (point == null) {
    return (first: false, last: false, point: null);
  }

  final pointValue = point[property];
  final segments = target.segments;
  final linePoints = target.points;
  var first = false;
  var last = false;
  for (var i = 0; i < segments.length; i++) {
    final segment = segments[i];
    final firstValue = linePoints[segment.start.toInt()][property];
    final lastValue = linePoints[segment.end.toInt()][property];
    if (isBetween(pointValue, firstValue, lastValue)) {
      first = pointValue == firstValue;
      last = pointValue == lastValue;
      break;
    }
  }
  return (first: first, last: last, point: point);
}

/// The result of `line.interpolate` (filler.target.stack.js:88) as a point
/// of the stack line (Chart.js ADR 0040, section 2).
///
/// - Dart `null` (JS `undefined`) stays `null`.
/// - A `types.PointElement` stays the same object (:69, :71).
/// - A plain point becomes a `PointElement` with its `x` and `y`. A Dart
///   `null` member is JS `null`, and `?? 0` is its `ToNumber`.
/// - A `List` becomes a `PointElement` with no property set: a JS Array has
///   no `x`, `y`, `angle`, `skip` or `stop`.
///
/// It is not an upstream function. The tests read it.
// DIVERGES(chartjs): adapt-line-points-elements, the results are points.
@visibleForTesting
IPointElement? stackResultPoint(Object? result) => switch (result) {
  null => null,
  final IPointElement point => point,
  final Point point =>
    PointElement()
      ..x = point.x ?? 0
      ..y = point.y ?? 0,
  _ => PointElement(),
};
