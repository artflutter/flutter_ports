// Ported from Chart.js v4.5.1+7169e651 src/plugins/plugin.filler/filler.segment.js (MIT, Chart.js Contributors).

/// Port of `src/plugins/plugin.filler/filler.segment.js`.
///
/// The bounds object `{property, start, end}` is the record of
/// `helpers.segment.dart`. Dart `null` stands for the `undefined` of a loop
/// (Chart.js ADR 0040, section 3).
///
/// Upstream makes plain objects for the edges of `_segments` and for the
/// points of `_pointsFromSegments`. The port makes a `PointElement` with
/// only the properties of the plain object (Chart.js ADR 0040, sections 1
/// and 3, the difference `adapt-line-points-elements`). Thus this file
/// imports `element.point.dart`, which `filler.segment.js` does not import.
///
/// This library is a pure layer (Chart.js ADR 0038, section 9).
library;

// DIVERGES(chartjs): adapt-line-points-elements, the wraps make point elements.
import 'package:flutter_chartjs_port/src/elements/element.point.dart'
    show PointElement;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show normalizeAngle;
import 'package:flutter_chartjs_port/src/helpers/helpers.segment.dart'
    show boundSegment, boundSegments;
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsMax, jsMin;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// The bounds object of `_getBounds` (filler.segment.js:62).
typedef _Bounds = ({String property, double start, double end});

/// One part of `_segments` (filler.segment.js:18-23, :35-44).
///
/// `target` is a `types.Segment` of a line target, or the bounds record
/// (Dart `null` for `undefined`) of a target that is not a line
/// (filler.segment.js:15-24).
typedef FillPart = ({
  types.Segment source,
  Object? target,
  types.PointElement start,
  types.PointElement end,
});

/// filler.segment.js:3 `_segments(line, target, property)`.
///
/// [target] is a `types.LineElement`, a `SimpleArc`, `true` or another
/// value of `_getTarget`. `!target.segments` (:15) is the type test
/// `target is! types.LineElement` (Chart.js ADR 0040, section 4).
List<FillPart> segments(
  types.LineElement line,
  Object target,
  String property,
) {
  final segments = line.segments;
  final points = line.points;
  final tpoints = target is types.LineElement ? target.points : null;
  final parts = <FillPart>[];

  for (final segment in segments) {
    final start = segment.start;
    final end = findSegmentEnd(start, segment.end, points);

    final bounds = getBounds(
      property,
      points[start.toInt()],
      points[end.toInt()],
      segment.loop,
    );

    // DIVERGES(chartjs): adapt-filler-target-classes, a type test.
    if (target is! types.LineElement) {
      // Special case for boundary not supporting `segments` (simpleArc)
      // Bounds are provided as `target` for partial circle, or undefined for
      // full circle
      parts.add((
        source: segment,
        target: bounds,
        start: points[start.toInt()],
        end: points[end.toInt()],
      ));
      continue;
    }

    // Get all segments from `target` that intersect the bounds of current
    // segment of `line`
    final targetSegments = boundSegments(target, bounds);

    for (final tgt in targetSegments) {
      final subBounds = getBounds(
        property,
        tpoints![tgt.start.toInt()],
        tpoints[tgt.end.toInt()],
        tgt.loop,
      );
      final fillSources = boundSegment(segment, points, subBounds);

      for (final fillSource in fillSources) {
        parts.add((
          source: fillSource,
          target: tgt,
          // DIVERGES(chartjs): adapt-line-points-elements, an edge point.
          start: PointElement()
            ..[property] = _getEdge(bounds, subBounds, 'start', jsMax),
          // DIVERGES(chartjs): adapt-line-points-elements, an edge point.
          end: PointElement()
            ..[property] = _getEdge(bounds, subBounds, 'end', jsMin),
        ));
      }
    }
  }
  return parts;
}

/// filler.segment.js:51 `_getBounds(property, first, last, loop)`.
///
/// Dart `null` for the `undefined` of a loop. `first[property]` is the read
/// of `PointElementProperty`: NaN where upstream reads `undefined`, which
/// gives the same result in `_boundSegment` (Chart.js ADR 0040, section 3).
({String property, double start, double end})? getBounds(
  String property,
  types.PointElement first,
  types.PointElement last, [
  // The upstream signature.
  // ignore: avoid_positional_boolean_parameters
  bool? loop,
]) {
  if (loop ?? false) {
    return null;
  }
  var start = first[property];
  var end = last[property];

  if (property == 'angle') {
    start = normalizeAngle(start);
    end = normalizeAngle(end);
  }
  return (property: property, start: start, end: end);
}

/// filler.segment.js:65 `_pointsFromSegments(boundary, line)`.
///
/// Dart `null` for [boundary] is `boundary || {}`, and a Dart `null` member
/// is the default `null` of the destructuring.
List<types.PointElement> pointsFromSegments(
  ({double? x, double? y})? boundary,
  types.LineElement line,
) {
  final x = boundary?.x;
  final y = boundary?.y;
  final linePoints = line.points;
  final points = <types.PointElement>[];
  for (final segment in line.segments) {
    final start = segment.start;
    final end = findSegmentEnd(start, segment.end, linePoints);
    final first = linePoints[start.toInt()];
    final last = linePoints[end.toInt()];
    if (y != null) {
      // DIVERGES(chartjs): adapt-line-points-elements, {x, y} is a point.
      points
        ..add(
          PointElement()
            ..x = first.x
            ..y = y,
        )
        ..add(
          PointElement()
            ..x = last.x
            ..y = y,
        );
    } else if (x != null) {
      // DIVERGES(chartjs): adapt-line-points-elements, {x, y} is a point.
      points
        ..add(
          PointElement()
            ..x = x
            ..y = first.y,
        )
        ..add(
          PointElement()
            ..x = x
            ..y = last.y,
        );
    }
  }
  return points;
}

/// filler.segment.js:84 `_findSegmentEnd(start, end, points)`.
///
/// The getters `x` and `y` give NaN for the `undefined` state, as
/// `isNaN(undefined)` is true.
double findSegmentEnd(
  double start,
  double end,
  List<types.PointElement> points,
) {
  var result = end;
  for (; result > start; result--) {
    final point = points[result.toInt()];
    if (!point.x.isNaN && !point.y.isNaN) {
      break;
    }
  }
  return result;
}

/// filler.segment.js:94 `_getEdge(a, b, prop, fn)`. [prop] is `'start'` or
/// `'end'`.
double _getEdge(
  _Bounds? a,
  _Bounds? b,
  String prop,
  double Function(double a, double b) fn,
) {
  double edge(_Bounds bounds) => prop == 'start' ? bounds.start : bounds.end;
  if (a != null && b != null) {
    return fn(edge(a), edge(b));
  }
  return a != null
      ? edge(a)
      : b != null
      ? edge(b)
      : 0;
}
