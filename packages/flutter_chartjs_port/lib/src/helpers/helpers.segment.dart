// Ported from Chart.js v4.6.1 src/helpers/helpers.segment.js (MIT, Chart.js Contributors).
// Upstream reassigns the parameters start and loop of solidSegments, and s
// and e of addStyle. The port keeps these assignments.
// ignore_for_file: parameter_assignments

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
/// `line.options` and `segmentOptions` are option values (Chart.js ADR
/// 0043). Their reads go through [jsGet], which keeps JS `undefined` apart
/// from JS `null`.
library;

import 'dart:convert';

import 'package:flutter_chartjs_port/src/helpers/helpers.color.dart'
    show isPatternOrGradient;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show angleBetween, angleDiff, isBetween, normalizeAngle;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show createContext;
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';

/// helpers.segment.js:8 `@typedef Segment`: the plain object
/// `{start, end, loop, style}` that this file makes.
///
/// A segment of `solidSegments` and of `_computeSegments` with `spanGaps`
/// has no `style` key. Upstream reads it as `undefined`, and [style] is Dart
/// `null` (see [Segment.style]).
final class _Segment implements Segment {
  _Segment({
    required this.start,
    required this.end,
    required this.loop,
    this.style,
  });

  @override
  final double start;

  @override
  final double end;

  @override
  final bool loop;

  @override
  final Object? style;
}

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
  return (
    between: isBetween,
    compare: (a, b) => a - b,
    normalize: (x) => x,
  );
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
/// [segmentOptions] is the option value `line.options.segment` (Chart.js ADR
/// 0043). Its default is the [undefined] sentinel.
List<Segment> computeSegments(
  LineElement line, [
  Object? segmentOptions = undefined,
]) {
  final points = line.points;
  final spanGaps = jsGet(line.options, 'spanGaps');
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
List<Segment> _splitByStyles(
  LineElement line,
  List<Segment> segments,
  List<PointElement> points,
  Object? segmentOptions,
) {
  if (!jsTruthy(segmentOptions) ||
      !jsTruthy(jsGet(segmentOptions, 'setContext')) ||
      !jsTruthy(points)) {
    return segments;
  }
  return _doSplitByStyles(line, segments, points, segmentOptions);
}

/// helpers.segment.js:279 `doSplitByStyles`.
///
/// @param {LineElement} line
/// @param {Segment[]} segments
/// @param {PointElement[]} points
/// @param {object} [segmentOptions]
/// @return {Segment[]}
///
/// `segmentOptions.setContext(ctx)` is [jsCall] with `segmentOptions` as
/// `this`. A `null` `line._datasetIndex` is JS `undefined` (see
/// [LineElement.datasetIndex]). The context gets it as the [undefined]
/// sentinel.
List<Segment> _doSplitByStyles(
  LineElement line,
  List<Segment> segments,
  List<PointElement> points,
  Object? segmentOptions,
) {
  final chartContext = line.chart!.getContext();
  final baseStyle = _readStyle(line.options);
  // Upstream: const {_datasetIndex: datasetIndex, options: {spanGaps}} = line;
  final datasetIndex = line.datasetIndex;
  final spanGaps = jsGet(line.options, 'spanGaps');
  final count = points.length.toDouble();
  final result = <Segment>[];
  var prevStyle = baseStyle;
  var start = segments[0].start;
  var i = start;

  // The upstream signature.
  // ignore: avoid_positional_boolean_parameters
  void addStyle(double s, double e, bool l, AnyObject st) {
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
    AnyObject style;
    for (i = start + 1; i <= segment.end; i++) {
      final pt = points[i.remainder(count).toInt()];
      style = _readStyle(
        jsCall(
          jsGet(segmentOptions, 'setContext'),
          [
            createContext(chartContext, <String, Object?>{
              'type': 'segment',
              'p0': prev,
              'p1': pt,
              'p0DataIndex': (i - 1).remainder(count),
              'p1DataIndex': i.remainder(count),
              'datasetIndex': datasetIndex ?? undefined,
            }),
          ],
          thisArg: segmentOptions,
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

/// helpers.segment.js:337 `readStyle`.
///
/// Each key is an own key of the result. A value that [options] does not
/// resolve is the [undefined] sentinel, as in the upstream object literal.
AnyObject _readStyle(Object? options) {
  return <String, Object?>{
    'backgroundColor': jsGet(options, 'backgroundColor'),
    'borderCapStyle': jsGet(options, 'borderCapStyle'),
    'borderDash': jsGet(options, 'borderDash'),
    'borderDashOffset': jsGet(options, 'borderDashOffset'),
    'borderJoinStyle': jsGet(options, 'borderJoinStyle'),
    'borderWidth': jsGet(options, 'borderWidth'),
    'borderColor': jsGet(options, 'borderColor'),
  };
}

/// helpers.segment.js:349 `styleChanged`.
///
/// `cache.includes(value)` and `cache.indexOf(value)` compare objects by
/// identity, as SameValueZero and `===` do for objects. The replacer gives
/// the index as a JS number.
bool _styleChanged(AnyObject style, AnyObject? prevStyle) {
  if (prevStyle == null) {
    return false;
  }
  final cache = <Object?>[];
  Object? replacer(String key, Object? value) {
    if (!isPatternOrGradient(value)) {
      return value;
    }
    if (!cache.any((cached) => identical(cached, value))) {
      cache.add(value);
    }
    return cache.indexWhere((cached) => identical(cached, value)).toDouble();
  }

  return _jsonStringify(style, replacer) != _jsonStringify(prevStyle, replacer);
}

/// `JSON.stringify(value, replacer)` (ECMA-262 `SerializeJSONProperty`) for
/// the values of a style object, or `null` where JSON.stringify returns
/// `undefined`.
///
/// `styleChanged` only compares two results. The replacer gets each key and
/// value, also the root value with the key `''`. Then:
/// - Dart `null` gives `null`. The [undefined] sentinel and a function value
///   give no result: an object leaves out the key, and an array writes
///   `null`.
/// - A number gives `String(number)`, and NaN and the infinities give
///   `null`.
/// - A `List` is an array. A `Map` is an object with the keys of
///   [jsObjectKeys].
/// - Any other object gives `{}`.
///
/// No style value has a `toJSON` method. A cycle overflows the stack, where
/// JavaScript throws a `TypeError`.
String? _jsonStringify(
  Object? value,
  Object? Function(String key, Object? value) replacer,
) => _serializeJsonProperty('', value, replacer);

/// ECMA-262 `SerializeJSONProperty(state, key, holder)` with a replacer
/// function. See [_jsonStringify].
String? _serializeJsonProperty(
  String key,
  Object? value,
  Object? Function(String key, Object? value) replacer,
) {
  final replaced = replacer(key, value);
  return switch (replaced) {
    null => 'null',
    Undefined() => null,
    final bool b => b ? 'true' : 'false',
    final num n => n.isFinite ? jsNumberToString(n) : 'null',
    final String s => _quote(s),
    final List<Object?> list => _serializeJsonArray(list, replacer),
    final Map<String, Object?> map => _serializeJsonObject(map, replacer),
    _ when jsIsFunction(replaced) => null,
    // DIVERGES(chartjs): js-semantics-segment-style-json, a leaf gives {}.
    _ => '{}',
  };
}

/// ECMA-262 `SerializeJSONArray` with a replacer function. A missing element
/// result is `null`.
String _serializeJsonArray(
  List<Object?> list,
  Object? Function(String key, Object? value) replacer,
) {
  final partial = <String>[];
  for (var i = 0; i < list.length; i++) {
    final json = _serializeJsonProperty(jsNumberToString(i), list[i], replacer);
    partial.add(json ?? 'null');
  }
  return '[${partial.join(',')}]';
}

/// ECMA-262 `SerializeJSONObject` with a replacer function. The keys are
/// [jsObjectKeys] (`EnumerableOwnProperties`). A key without a result is
/// left out.
String _serializeJsonObject(
  Map<String, Object?> map,
  Object? Function(String key, Object? value) replacer,
) {
  final partial = <String>[];
  for (final key in jsObjectKeys(map)) {
    final json = _serializeJsonProperty(key, map[key], replacer);
    if (json != null) {
      partial.add('${_quote(key)}:$json');
    }
  }
  return '{${partial.join(',')}}';
}

/// `QuoteJSONString` (ECMA-262) of [s]: the JSON string literal of [s].
///
/// Only a code unit below U+0020, `"`, `\` or a surrogate (U+D800 to U+DFFF)
/// can need an escape. When [s] has none of these code units, the result is
/// [s] between double quotes. Else [jsonEncode] gives the result. It writes
/// the same text as JSON.stringify, also for a lone surrogate. Thus this
/// step does not change the result. It only removes the [jsonEncode] call
/// for most keys and values.
String _quote(String s) {
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (c < 0x20 || c == 0x22 || c == 0x5C || (c >= 0xD800 && c <= 0xDFFF)) {
      return jsonEncode(s);
    }
  }
  return '"$s"';
}
