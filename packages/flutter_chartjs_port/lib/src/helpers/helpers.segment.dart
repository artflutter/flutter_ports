// Ported from Chart.js v4.6.1 src/helpers/helpers.segment.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-typed-elements, typed styles of Chart.js ADR 0054.
// Upstream reassigns the parameters start and loop of solidSegments, and s
// and e of addStyle. The port keeps these assignments.
// ignore_for_file: parameter_assignments
// DIVERGES(chartjs): adapt-direct-colors, native segment color comparison.
// DIVERGES(chartjs): adapt-stack-exact-points, segment type identity.

/// Port of `src/helpers/helpers.segment.js`.
///
/// The upstream `@typedef` lines (helpers.segment.js:5-9) name `LineElement`,
/// `PointElement` and `Segment`. Their interfaces are in
/// `lib/src/types/index.dart` (Chart.js ADR 0003). A segment of this file is
/// a [Segment] object. The `bounds` objects are the records
/// `({String property, double start, double end})`, because ported code
/// only reads them.
///
/// Indices are `double` (Chart.js ADR 0045). A list read converts the index
/// with `toInt()`. Each index comes from a list length or from a segment of
/// the same points, so it is finite. JS `%` is Dart `remainder`.
///
/// `line.options` is an option value. Its reads go through [readOption] of
/// `helpers.config` (Chart.js ADR 0054 §4): the typed read of a resolver
/// view or of resolved element options, else the read by name. Each keeps
/// JS `undefined` apart from JS `null`. `segmentOptions` is a
/// [LineSegmentStyle], the native value of the option `segment` (Chart.js
/// ADR 0142). The style of a segment is a [SegmentStyle], an immutable
/// object with the keys of the object literal of `readStyle`.
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.color.dart'
    show isPatternOrGradient;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show readOption;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show angleBetween, angleDiff, isBetween, normalizeAngle;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableLineSegmentContext;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';
import 'package:flutter_chartjs_port/src/types/line_segment_style.dart';
import 'package:meta/meta.dart';

/// helpers.segment.js:8 `@typedef Segment`: the plain object
/// `{start, end, loop, style}` that this file makes.
///
/// A segment of `solidSegments` and of `_computeSegments` with `spanGaps`
/// has no `style` key. Upstream reads it as `undefined`, and [style] is Dart
/// `null` (see [Segment.style]).
final class _Segment({
  @override required final double start,
  @override required final double end,
  @override required final bool loop,
  @override final Object? style,
}) implements Segment;

/// Type identity for the stack guard without constructing a dummy line.
@internal
const Type nativeSegmentType = _Segment;

// DIVERGES(chartjs): adapt-boundary-segment-search, retain the native segment
// representation for exact bounds of a private, unstyled linear boundary.
/// An internal segment for validated, non-wrapping private boundary indices.
@internal
Segment createBoundarySegment(int start, int end) =>
    _Segment(start: start.toDouble(), end: end.toDouble(), loop: false);

/// The result of `propertyFn` (helpers.segment.js:13-23).
typedef _PropertyFn = ({
  bool Function(double, double, double) between,
  double Function(double, double) compare,
  double Function(double) normalize,
});

/// helpers.segment.js:11 `propertyFn`.
_PropertyFn _propertyFn(String property) {
  if (property == 'angle') {
    return (
      between: angleBetween,
      compare: angleDiff,
      normalize: normalizeAngle,
    );
  }
  return (between: isBetween, compare: (a, b) => a - b, normalize: (x) => x);
}

/// helpers.segment.js:26 `normalizeSegment`.
///
/// Upstream takes one object `{start, end, count, loop, style}`. The port
/// takes named parameters.
Segment _normalizeSegment({
  required double start,
  required double end,
  required double count,
  required bool loop,
  required Object? style,
}) {
  return _Segment(
    start: start.remainder(count),
    end: end.remainder(count),
    loop: loop && (end - start + 1).remainder(count) == 0,
    style: style,
  );
}

/// helpers.segment.js:35 `getSegment`.
({double start, double end, bool loop, Object? style}) _getSegment(
  Segment segment,
  List<PointElement> points,
  ({String property, double start, double end}) bounds,
) {
  final (:property, start: startBound, end: endBound) = bounds;
  final (:between, compare: _, :normalize) = _propertyFn(property);
  final count = points.length.toDouble();
  // Upstream: let {start, end, loop} = segment;
  var start = segment.start;
  var end = segment.end;
  final loop = segment.loop;

  if (loop) {
    start += count;
    end += count;
    for (var i = 0.0, ilen = count; i < ilen; ++i) {
      if (!between(
        normalize(points[start.remainder(count).toInt()][property]),
        startBound,
        endBound,
      )) {
        break;
      }
      start--;
      end--;
    }
    start = start.remainder(count);
    end = end.remainder(count);
  }

  if (end < start) {
    end += count;
  }
  return (start: start, end: end, loop: loop, style: segment.style);
}

final Type _growablePoints = <PointElement>[].runtimeType;
final Type _fixedPoints = List<PointElement>.empty().runtimeType;

/// Whether the loop of [boundSegment] gives one segment from [start] to [end]:
/// points of the built-in class with no skip and strictly ascending finite x,
/// bounds equal to the first and the last x, and no x before the last within
/// the epsilon of [isBetween] below the end bound, which would stop the loop
/// early.
/// It reads nothing of a point of another class.
bool _boundsCoverAscendingPoints(
  List<PointElement> points,
  double start,
  double end,
  double startBound,
  double endBound,
) {
  // A user list keeps the reads of the loop. A negative zero index keeps the
  // sign that the loop gives it.
  if (!start.isFinite ||
      !end.isFinite ||
      start.isNegative ||
      end.isNegative ||
      !startBound.isFinite ||
      !endBound.isFinite ||
      (points.runtimeType != _growablePoints &&
          points.runtimeType != _fixedPoints)) {
    return false;
  }
  final first = start.toInt();
  final last = end.toInt();
  if (first != start || last != end || first > last || last >= points.length) {
    return false;
  }
  var previous = startBound;
  for (var i = first; i <= last; i++) {
    final point = points[i];
    if (point is! PointElementWrites ||
        !(point as PointElementWrites).typedWrites ||
        (point.skip ?? false)) {
      return false;
    }
    final x = point.x;
    if (i == first ? x != startBound : !(x > previous)) return false;
    if (i == last) return x == endBound;
    if (i == last - 1 && endBound <= x + 1e-6) return false;
    previous = x;
  }
  return false;
}

/// helpers.segment.js:77 `_boundSegment`.
///
/// Returns the sub-segment(s) of a line segment that fall in the given bounds
/// @param {object} segment
/// @param {number} segment.start - start index of the segment, referring the
/// points array
/// @param {number} segment.end - end index of the segment, referring the
/// points array
/// @param {boolean} segment.loop - indicates that the segment is a loop
/// @param {object} `[segment.style]` - segment style
/// @param {PointElement[]} points - the points that this segment refers to
/// @param {object} [bounds]
/// @param {string} bounds.property - the property of a `PointElement` we are
/// bounding. `x`, `y` or `angle`.
/// @param {number} bounds.start - start value of the property
/// @param {number} bounds.end - end value of the property
/// @private
///
/// Dart `null` [bounds] stands for JS `undefined`. The property read
/// `point[property]` is the extension `PointElementProperty` of
/// `lib/src/types/index.dart`.
List<Segment> boundSegment(
  Segment segment,
  List<PointElement> points, [
  ({String property, double start, double end})? bounds,
]) {
  if (bounds == null) {
    return [segment];
  }

  final (:property, start: startBound, end: endBound) = bounds;
  final count = points.length.toDouble();
  final (:compare, :between, :normalize) = _propertyFn(property);
  final (:start, :end, :loop, :style) = _getSegment(segment, points, bounds);

  // DIVERGES(chartjs): adapt-bound-ascending-segment, one scan proves the
  // result of the loop below for a whole segment of ascending points.
  if (property == 'x' &&
      !loop &&
      _boundsCoverAscendingPoints(points, start, end, startBound, endBound)) {
    return [
      _normalizeSegment(
        start: start,
        end: end,
        loop: loop,
        count: count,
        style: style,
      ),
    ];
  }

  final result = <Segment>[];
  var inside = false;
  double? subStart;
  late double value;
  PointElement point;
  // prevValue starts JS `undefined`. The closures pass it to a number
  // function, which makes it NaN, so NaN stands for it there. But the `x`
  // and `y` getters of an element give NaN for `undefined`, and
  // `undefined === undefined` is true where `NaN === NaN` is false. Thus
  // prevUndefined keeps the `undefined` state for `value === prevValue`.
  var prevValue = double.nan;
  var prevUndefined = true;

  bool startIsBefore() =>
      between(startBound, prevValue, value) &&
      compare(startBound, prevValue) != 0;
  bool endIsBefore() =>
      compare(endBound, value) == 0 || between(endBound, prevValue, value);
  bool shouldStart() => inside || startIsBefore();
  bool shouldStop() => !inside || endIsBefore();

  for (var i = start, prev = start; i <= end; ++i) {
    point = points[i.remainder(count).toInt()];

    if (point.skip ?? false) {
      continue;
    }

    value = normalize(point[property]);
    // normalize keeps `undefined` for 'x' and 'y' (helpers.segment.js:22).
    // `_normalizeAngle(undefined)` is NaN.
    final valueUndefined =
        value.isNaN &&
        property != 'angle' &&
        switch (point) {
          final ElementPropertyRead element => identical(
            element[property],
            undefined,
          ),
          _ => false,
        };

    if (valueUndefined ? prevUndefined : value == prevValue) {
      continue;
    }

    inside = between(value, startBound, endBound);

    if (subStart == null && shouldStart()) {
      subStart = compare(value, startBound) == 0 ? i : prev;
    }

    if (subStart != null && shouldStop()) {
      result.add(
        _normalizeSegment(
          start: subStart,
          end: i,
          loop: loop,
          count: count,
          style: style,
        ),
      );
      subStart = null;
    }
    prev = i;
    prevValue = value;
    prevUndefined = valueUndefined;
  }

  if (subStart != null) {
    result.add(
      _normalizeSegment(
        start: subStart,
        end: end,
        loop: loop,
        count: count,
        style: style,
      ),
    );
  }

  return result;
}

/// helpers.segment.js:141 `_boundSegments`.
///
/// Returns the segments of the line that are inside given bounds
/// @param {LineElement} line
/// @param {object} [bounds]
/// @param {string} bounds.property - the property we are bounding with. `x`,
/// `y` or `angle`.
/// @param {number} bounds.start - start value of the `property`
/// @param {number} bounds.end - end value of the `property`
/// @private
///
/// Dart `null` [bounds] stands for JS `undefined`.
List<Segment> boundSegments(
  LineElement line, [
  ({String property, double start, double end})? bounds,
]) {
  final result = <Segment>[];
  final segments = line.segments;

  for (var i = 0; i < segments.length; i++) {
    final sub = boundSegment(segments[i], line.points, bounds);
    if (sub.isNotEmpty) {
      result.addAll(sub);
    }
  }
  return result;
}

/// helpers.segment.js:157 `findStartAndEnd`.
///
/// Find start and end index of a line.
///
/// [spanGaps] is the option value `line.options.spanGaps`: a `bool` or a
/// number (Chart.js ADR 0043).
({double start, double end}) _findStartAndEnd(
  List<PointElement> points,
  double count,
  bool loop,
  Object? spanGaps,
) {
  var start = 0.0;
  var end = count - 1;

  if (loop && !jsTruthy(spanGaps)) {
    // loop and not spanning gaps, first find a gap to start from
    while (start < count && !(points[start.toInt()].skip ?? false)) {
      start++;
    }
  }

  // find first non skipped point (after the first gap possibly)
  while (start < count && (points[start.toInt()].skip ?? false)) {
    start++;
  }

  // if we looped to count, start needs to be 0
  start = start.remainder(count);

  if (loop) {
    // loop will go past count, if start > 0
    end += start;
  }

  while (end > start && (points[end.remainder(count).toInt()].skip ?? false)) {
    end--;
  }

  // end could be more than count, normalize
  end = end.remainder(count);

  return (start: start, end: end);
}

/// helpers.segment.js:198 `solidSegments`.
///
/// Compute solid segments from Points, when spanGaps === false
/// @param {PointElement[]} points - the points
/// @param {number} start - start index
/// @param {number} max - max index (can go past count on a loop)
/// @param {boolean} loop - boolean indicating that this would be a loop if no
/// gaps are found
///
/// [start] is nullable because the body assigns `null` to it (:213), as
/// upstream does. A later `start % count` then gives 0, the result of
/// `ToNumber(null) % count`. This happens after a skipped point and a
/// `stop` point.
List<Segment> _solidSegments(
  List<PointElement> points,
  double? start,
  double max,
  bool loop,
) {
  final count = points.length.toDouble();
  final result = <Segment>[];
  var last = start;
  var prev = points[start!.toInt()];
  double end;

  for (end = start + 1; end <= max; ++end) {
    final cur = points[end.remainder(count).toInt()];
    if ((cur.skip ?? false) || (cur.stop ?? false)) {
      if (!(prev.skip ?? false)) {
        loop = false;
        result.add(
          _Segment(
            start: jsToNumber(start).remainder(count),
            end: (end - 1).remainder(count),
            loop: loop,
          ),
        );
        // Upstream: @ts-ignore
        start = last = (cur.stop ?? false) ? end : null;
      }
    } else {
      last = end;
      if (prev.skip ?? false) {
        start = end;
      }
    }
    prev = cur;
  }

  if (last != null) {
    result.add(
      _Segment(
        start: jsToNumber(start).remainder(count),
        end: last.remainder(count),
        loop: loop,
      ),
    );
  }

  return result;
}

/// helpers.segment.js:238 `_computeSegments`.
///
/// Compute the continuous segments that define the whole line
/// There can be skipped points within a segment, if spanGaps is true.
/// @param {LineElement} line
/// @param {object} [segmentOptions]
/// @return {Segment[]}
/// @private
///
/// [segmentOptions] is the option value `line.options.segment`: a
/// [LineSegmentStyle], or Dart `null` for no segment styles (Chart.js ADR
/// 0142).
List<Segment> computeSegments(
  LineElement line, [
  LineSegmentStyle? segmentOptions,
]) {
  final points = line.points;
  final spanGaps = readOption(line.options, OptionKey.spanGaps);
  final count = points.length.toDouble();

  if (count == 0) {
    return [];
  }

  final loop = line.loop ?? false;
  final (:start, :end) = _findStartAndEnd(points, count, loop, spanGaps);

  if (spanGaps == true) {
    return _splitByStyles(
      line,
      [_Segment(start: start, end: end, loop: loop)],
      points,
      segmentOptions,
    );
  }

  final max = end < start ? end + count : end;
  final completeLoop =
      (line.fullLoop ?? false) && start == 0 && end == count - 1;
  return _splitByStyles(
    line,
    _solidSegments(points, start, max, completeLoop),
    points,
    segmentOptions,
  );
}

/// helpers.segment.js:265 `splitByStyles`.
///
/// @param {Segment[]} segments
/// @param {PointElement[]} points
/// @param {object} [segmentOptions]
/// @return {Segment[]}
///
/// `!segmentOptions.setContext` is a [LineSegmentStyle] with no function
/// (Chart.js ADR 0142): no part can take another style. A List [points] is
/// always truthy.
// DIVERGES(chartjs): adapt-native-line-segment-style, a style with no function.
List<Segment> _splitByStyles(
  LineElement line,
  List<Segment> segments,
  List<PointElement> points,
  LineSegmentStyle? segmentOptions,
) {
  if (segmentOptions == null || !_hasFunctions(segmentOptions)) {
    return segments;
  }
  return _doSplitByStyles(line, segments, points, segmentOptions);
}

/// Whether [style] has a function.
bool _hasFunctions(LineSegmentStyle style) =>
    style.borderColor != null ||
    style.backgroundColor != null ||
    style.borderWidth != null ||
    style.borderDash != null ||
    style.borderDashOffset != null ||
    style.borderCapStyle != null ||
    style.borderJoinStyle != null;

/// helpers.segment.js:279 `doSplitByStyles`.
///
/// @param {LineElement} line
/// @param {Segment[]} segments
/// @param {PointElement[]} points
/// @param {object} [segmentOptions]
/// @return {Segment[]}
///
/// `readStyle(segmentOptions.setContext(ctx))` is [_readSegmentStyle]: it
/// calls each function of the [LineSegmentStyle] with the typed context of
/// the part (Chart.js ADR 0142). A `null` `line._datasetIndex` is JS
/// `undefined` (see [LineElement.datasetIndex]). The context gets it as the
/// [undefined] sentinel.
// DIVERGES(chartjs): adapt-native-line-segment-style, typed calls.
List<Segment> _doSplitByStyles(
  LineElement line,
  List<Segment> segments,
  List<PointElement> points,
  LineSegmentStyle segmentOptions,
) {
  final chartContext = line.chart!.getContext();
  final baseStyle = _readStyle(line.options);
  // Upstream: const {_datasetIndex: datasetIndex, options: {spanGaps}} = line;
  final datasetIndex = line.datasetIndex;
  final spanGaps = readOption(line.options, OptionKey.spanGaps);
  final count = points.length.toDouble();
  final result = <Segment>[];
  var prevStyle = baseStyle;
  var start = segments[0].start;
  var i = start;

  void addStyle(double s, double e, bool l, SegmentStyle st) {
    final dir = jsTruthy(spanGaps) ? -1.0 : 1.0;
    if (s == e) {
      return;
    }
    // Style can not start/end on a skipped point, adjust indices accordingly
    s += count;
    while (points[s.remainder(count).toInt()].skip ?? false) {
      s -= dir;
    }
    while (points[e.remainder(count).toInt()].skip ?? false) {
      e += dir;
    }
    if (s.remainder(count) != e.remainder(count)) {
      result.add(
        _Segment(
          start: s.remainder(count),
          end: e.remainder(count),
          loop: l,
          style: st,
        ),
      );
      prevStyle = st;
      start = e.remainder(count);
    }
  }

  for (final segment in segments) {
    start = jsTruthy(spanGaps) ? start : segment.start;
    var prev = points[start.remainder(count).toInt()];
    SegmentStyle style;
    for (i = start + 1; i <= segment.end; i++) {
      final pt = points[i.remainder(count).toInt()];
      style = _readSegmentStyle(
        segmentOptions,
        ScriptableLineSegmentContext.segment(
          chartContext,
          p0: prev,
          p1: pt,
          p0DataIndex: (i - 1).remainder(count).toInt(),
          p1DataIndex: i.remainder(count).toInt(),
          datasetIndex: datasetIndex,
        ),
      );
      if (_styleChanged(style, prevStyle)) {
        addStyle(start, i - 1, segment.loop, prevStyle);
      }
      prev = pt;
      prevStyle = style;
    }
    if (start < i - 1) {
      addStyle(start, i - 1, segment.loop, prevStyle);
    }
  }

  return result;
}

/// helpers.segment.js:337 `readStyle` of `segmentOptions.setContext(ctx)`
/// (helpers.segment.js:300): the style of one part (Chart.js ADR 0142).
///
/// The functions run in the order of the keys of the object literal of
/// `readStyle`, as the reads of the scriptable options of the resolver view
/// do upstream. An absent function and a null result give the [undefined]
/// sentinel, as a key that no segment scope has and a function that gives
/// `undefined` do upstream. The draw then takes the value of the line
/// options (`setStyle` of element.line.js:202, the filler).
SegmentStyle _readSegmentStyle(
  LineSegmentStyle segment,
  ScriptableLineSegmentContext context,
) {
  final backgroundColor = segment.backgroundColor?.call(context);
  final borderCapStyle = segment.borderCapStyle?.call(context);
  final borderDash = segment.borderDash?.call(context);
  final borderDashOffset = segment.borderDashOffset?.call(context);
  final borderJoinStyle = segment.borderJoinStyle?.call(context);
  final borderWidth = segment.borderWidth?.call(context);
  final borderColor = segment.borderColor?.call(context);
  return SegmentStyle(
    backgroundColor: backgroundColor ?? undefined,
    borderCapStyle: borderCapStyle ?? undefined,
    borderDash: borderDash ?? undefined,
    borderDashOffset: borderDashOffset ?? undefined,
    borderJoinStyle: borderJoinStyle ?? undefined,
    borderWidth: borderWidth ?? undefined,
    borderColor: borderColor ?? undefined,
  );
}

/// helpers.segment.js:337 `readStyle`.
///
/// A value that [options] does not resolve is the [undefined] sentinel, as
/// in the upstream object literal. [readOption] reads [options]: a resolver
/// view gives its typed read, resolved element options give their typed
/// fields.
SegmentStyle _readStyle(Object? options) {
  return SegmentStyle(
    backgroundColor: _styleColor(
      readOption(options, OptionKey.backgroundColor),
    ),
    borderCapStyle: readOption(options, OptionKey.borderCapStyle),
    borderDash: readOption(options, OptionKey.borderDash),
    borderDashOffset: readOption(options, OptionKey.borderDashOffset),
    borderJoinStyle: readOption(options, OptionKey.borderJoinStyle),
    borderWidth: readOption(options, OptionKey.borderWidth),
    borderColor: _styleColor(readOption(options, OptionKey.borderColor)),
  );
}

Object? _styleColor(Object? value) {
  if (value == null ||
      value is Undefined ||
      value is SolidChartPaint ||
      isPatternOrGradient(value)) {
    return value;
  }
  throw ArgumentError.value(value, 'segment color', 'Expected Flutter Color');
}

/// helpers.segment.js:337-347 the object literal of `readStyle`: the style
/// of a segment ([Segment.style]).
///
/// Each field holds the value of the option: the value of the line options,
/// the result of a function of a [LineSegmentStyle], or the [undefined]
/// sentinel. The draw takes the value of the line options for [undefined]
/// (element.line.js:202, filler.drawing.js:131).
///
/// `==` is the compare of `styleChanged` (helpers.segment.js:349): a
/// gradient or a pattern compares by identity, as the replacer of upstream
/// gives each one its index in a cache; a List compares item by item; NaN
/// equals NaN, as `JSON.stringify` writes each NaN the same; any other value
/// compares with `==` (Chart.js ADR 0142).
// DIVERGES(chartjs): adapt-native-line-segment-style, == for JSON.stringify.
@immutable
final class const SegmentStyle({
  /// `backgroundColor`.
  final Object? backgroundColor = undefined,

  /// `borderCapStyle`.
  final Object? borderCapStyle = undefined,

  /// `borderDash`.
  final Object? borderDash = undefined,

  /// `borderDashOffset`.
  final Object? borderDashOffset = undefined,

  /// `borderJoinStyle`.
  final Object? borderJoinStyle = undefined,

  /// `borderWidth`.
  final Object? borderWidth = undefined,

  /// `borderColor`.
  final Object? borderColor = undefined,
}) {
  /// A style with the given values; an absent value is [undefined].
  this;

  @override
  bool operator ==(Object other) =>
      other is SegmentStyle &&
      _sameStyleValue(backgroundColor, other.backgroundColor) &&
      _sameStyleValue(borderCapStyle, other.borderCapStyle) &&
      _sameStyleValue(borderDash, other.borderDash) &&
      _sameStyleValue(borderDashOffset, other.borderDashOffset) &&
      _sameStyleValue(borderJoinStyle, other.borderJoinStyle) &&
      _sameStyleValue(borderWidth, other.borderWidth) &&
      _sameStyleValue(borderColor, other.borderColor);

  @override
  int get hashCode => Object.hash(
    _styleValueHash(backgroundColor),
    _styleValueHash(borderCapStyle),
    _styleValueHash(borderDash),
    _styleValueHash(borderDashOffset),
    _styleValueHash(borderJoinStyle),
    _styleValueHash(borderWidth),
    _styleValueHash(borderColor),
  );

  @override
  String toString() =>
      'SegmentStyle(backgroundColor: $backgroundColor, '
      'borderCapStyle: $borderCapStyle, borderDash: $borderDash, '
      'borderDashOffset: $borderDashOffset, '
      'borderJoinStyle: $borderJoinStyle, borderWidth: $borderWidth, '
      'borderColor: $borderColor)';
}

/// Whether two values of a style field are the same for `styleChanged`.
bool _sameStyleValue(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (isPatternOrGradient(a) || isPatternOrGradient(b)) return false;
  if (a is double && b is double && a.isNaN && b.isNaN) return true;
  if (a is List<Object?> && b is List<Object?>) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_sameStyleValue(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

/// The hash of a value of a style field, equal for two values that
/// [_sameStyleValue] takes as the same.
int _styleValueHash(Object? value) => switch (value) {
  _ when isPatternOrGradient(value) => identityHashCode(value),
  final double d when d.isNaN => 0x7FF8,
  final List<Object?> list => Object.hashAll(list.map(_styleValueHash)),
  _ => value.hashCode,
};

/// helpers.segment.js:349 `styleChanged`: `JSON.stringify` of the two
/// styles with a replacer that gives each gradient and pattern its index in
/// a cache. The port compares the styles with [SegmentStyle.==] (Chart.js
/// ADR 0142).
// DIVERGES(chartjs): adapt-native-line-segment-style, == for JSON.stringify.
bool _styleChanged(SegmentStyle style, SegmentStyle? prevStyle) {
  if (prevStyle == null) {
    return false;
  }
  return style != prevStyle;
}
