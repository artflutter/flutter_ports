// Original code, not ported from Chart.js: exact-point stack search experiment.

import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.segment.dart'
    show nativeSegmentType;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// Allows differential tests to run the original stack search unchanged.
@visibleForTesting
bool stackPointSearchEnabled = true;

final _pointListTypes = <Type>{
  <types.PointElement>[].runtimeType,
  List<types.PointElement>.empty().runtimeType,
  <PointElement>[].runtimeType,
  List<PointElement>.empty().runtimeType,
};
final _segmentListTypes = <Type>{
  <types.Segment>[].runtimeType,
  List<types.Segment>.empty().runtimeType,
};

/// Search state owned by one synchronous buildStackLine call, never by a chart.
/// It only bypasses interpolation for exact samples of an ordinary target line.
final class StackPointSearch {
  StackPointSearch._(int count) : _slots = List<_Cursor?>.filled(count, null);

  /// A foreign source/list/segment can run user code while the stack is built.
  /// Preserve its reads and side effects by using the original algorithm.
  static StackPointSearch? create(
    types.LineElement line,
    List<types.PointElement> points,
    List<types.Segment> segments,
    int targetCount,
  ) {
    if (!stackPointSearchEnabled ||
        line.runtimeType != LineElement ||
        !_pointListTypes.contains(points.runtimeType) ||
        !_segmentListTypes.contains(segments.runtimeType) ||
        points.any((point) => point.runtimeType != PointElement) ||
        segments.any((segment) => segment.runtimeType != nativeSegmentType)) {
      return null;
    }
    return StackPointSearch._(targetCount);
  }

  final List<_Cursor?> _slots;
  bool _enabled = true;

  /// Returns null to run the original interpolate call. The final boundary
  /// line is port-created and excluded from the slots; it needs no index.
  ({bool first, bool last, types.PointElement point})? find(
    int index,
    types.Element? target,
    types.PointElement? source,
  ) {
    if (!_enabled || index >= _slots.length) return null;
    if (source == null || source.runtimeType != PointElement) {
      _enabled = false;
      return null;
    }
    var cursor = _slots[index];
    if (cursor == null) {
      cursor = _Cursor.create(target);
      if (cursor == null) {
        // A fallback may invoke user code that mutates previously indexed
        // targets. Disable all reuse before entering that code.
        _enabled = false;
        return null;
      }
      _slots[index] = cursor;
    }
    return cursor.find(source.x);
  }
}

final class _Cursor {
  _Cursor(this.points);

  final List<types.PointElement> points;
  int _index = 0;
  double _last = double.negativeInfinity;

  static _Cursor? create(types.Element? target) {
    if (target.runtimeType != LineElement) return null;
    final line = target! as LineElement;
    final options = line.options;
    if (options.runtimeType != LineOptions) return null;
    final resolved = options! as LineOptions;
    bool primitive(Object? value) =>
        value == null ||
        value is Undefined ||
        value is num ||
        value is bool ||
        value is String;
    // The fallback for a nonmatching x must also be free of user callbacks.
    if (!primitive(resolved.steppedValue) ||
        !primitive(resolved.tensionValue) ||
        !primitive(resolved.cubicInterpolationModeValue) ||
        !(resolved.segmentValue == null ||
            resolved.segmentValue is Undefined ||
            identical(resolved.segmentValue, false))) {
      return null;
    }
    final points = line.points;
    if (!_pointListTypes.contains(points.runtimeType) || points.length < 4) {
      return null;
    }
    // Check types before reading fields: subclasses can override getters.
    if (points.any((point) => point.runtimeType != PointElement)) return null;
    final segments = line.segments;
    if (!_segmentListTypes.contains(segments.runtimeType) ||
        segments.length != 1 ||
        segments.single.runtimeType != nativeSegmentType) {
      return null;
    }
    final segment = segments.single;
    if (segment.loop ||
        segment.start != 0 ||
        segment.end != points.length - 1) {
      return null;
    }
    var previous = double.negativeInfinity;
    for (final point in points) {
      final x = point.x;
      if (!x.isFinite || (point.skip ?? false)) return null;
      if (previous.isFinite) {
        // Leave a conservative margin around isBetween's 1e-6 tolerance.
        // Exact hits then produce one [i, i] segment, never neighboring hits.
        final margin = 1e-5 + (x.abs() + previous.abs()) * 1e-12;
        if (!(x - previous > margin)) return null;
      }
      previous = x;
    }
    return _Cursor(points);
  }

  ({bool first, bool last, types.PointElement point})? find(double x) {
    if (!x.isFinite) return null;
    var index = _index;
    if (x < _last) {
      var low = 0;
      var high = points.length;
      while (low < high) {
        final middle = (low + high) >> 1;
        if (points[middle].x < x) {
          low = middle + 1;
        } else {
          high = middle;
        }
      }
      index = low;
    } else {
      while (index < points.length && points[index].x < x) {
        index++;
      }
    }
    _index = index;
    _last = x;
    if (index == points.length || points[index].x != x) return null;
    return (
      first: index == 0,
      last: index == points.length - 1,
      point: points[index],
    );
  }
}
