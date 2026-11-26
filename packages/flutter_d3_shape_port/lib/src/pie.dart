// Ported from d3-shape v3.2.0 src/pie.js (ISC, Mike Bostock).

/// Port of `src/pie.js` of d3-shape 3.2.0: [Pie], [PieArc], and [pie].
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_shape_port/src/arc.dart';
import 'package:flutter_d3_shape_port/src/array.dart';
import 'package:flutter_d3_shape_port/src/descending.dart';
import 'package:flutter_d3_shape_port/src/math.dart';

/// Value accessor for [Pie].
typedef PieValueAccessor<T> = double Function(T d, int i, List<T> data);

/// Angle accessor for [Pie] (`startAngle`, `endAngle`, `padAngle`).
typedef PieAngleAccessor<T> = double Function(List<T> data);

/// Value comparator for [Pie.sortValues].
typedef PieValueComparator = num Function(double a, double b);

/// Datum comparator for [Pie.sort].
typedef PieDataComparator<T> = num Function(T a, T b);

/// One slice produced by [Pie]. Implements [ArcDatum] so slices pass directly
/// into [Arc].
// DIVERGES(d3-shape): adapt-shape-typed-api, const PieArc implementing
// ArcDatum.
final class const PieArc<T>({
  /// Originating input datum.
  required final T data,

  /// Zero-based sorted order index of this arc.
  required final int index,

  /// Numeric value of this arc.
  required final double value,

  /// Start angle in radians.
  @override required final double startAngle,

  /// End angle in radians.
  @override required final double endAngle,

  /// Pad angle in radians.
  @override required final double padAngle,
}) implements ArcDatum {
  /// Creates a pie slice arc.
  this;

  @override
  double get innerRadius => 0;

  @override
  double get outerRadius => 0;

  @override
  // All fields are final and the class is const-immutable (no meta dep).
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is PieArc<T> &&
      data == other.data &&
      index == other.index &&
      value == other.value &&
      startAngle == other.startAngle &&
      endAngle == other.endAngle &&
      padAngle == other.padAngle;

  @override
  // All fields are final and the class is const-immutable (no meta dep).
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode =>
      Object.hash(data, index, value, startAngle, endAngle, padAngle);

  @override
  String toString() =>
      'PieArc(data: $data, index: $index, value: $value, '
      'startAngle: $startAngle, endAngle: $endAngle, padAngle: $padAngle)';
}

double _defaultPieValue<T>(T d, int i, List<T> data) {
  if (d is double) return d;
  if (d is num) return d.toDouble();
  if (d == null) return double.nan;
  throw ArgumentError.value(
    d,
    'd',
    'Expected num datum, or set a custom pie value accessor',
  );
}

double _zeroAngle<T>(List<T> _) => 0;
double _tauAngle<T>(List<T> _) => shapeTau;

/// `pie.js:7` `pie`: computes arc start and end angles for a pie or donut
/// chart.
// DIVERGES(d3-shape): adapt-shape-typed-api, typed generic Pie class.
final class Pie<T>() {
  /// Creates a pie layout generator with default accessors.
  this;

  PieValueAccessor<T> _value = _defaultPieValue;
  bool _defaultValue = true;
  double? _valueConst;

  PieAngleAccessor<T> _startAngle = _zeroAngle;
  double? _startAngleConst = 0;

  PieAngleAccessor<T> _endAngle = _tauAngle;
  double? _endAngleConst = shapeTau;

  PieAngleAccessor<T> _padAngle = _zeroAngle;
  double? _padAngleConst = 0;

  PieValueComparator? _sortValues = shapeDescending;
  bool _defaultSortValues = true;
  PieDataComparator<T>? _sort;

  /// Computes pie arc descriptors for [data], returned in input order.
  // DIVERGES(d3-shape): adapt-shape-fast-forms, unboxed Float64List/Int32List,
  // constant-accessor fast paths, and inline stable insertion sort for n <= 32.
  List<PieArc<T>> call(Iterable<T> data) {
    final list = shapeArray(data);
    final n = list.length;
    if (n == 0) return const [];

    var sum = 0.0;
    final index = Int32List(n);
    final values = Float64List(n);
    var a0 = _startAngleConst ?? _startAngle(list);
    final aEnd = _endAngleConst ?? _endAngle(list);
    final da = math.min(shapeTau, math.max(-shapeTau, aEnd - a0));
    final padRaw = _padAngleConst ?? _padAngle(list);
    final p = math.min(da.abs() / n, padRaw);
    final pa = p * (da < 0 ? -1 : 1);

    var hasNaN = false;
    final valConst = _valueConst;
    if (valConst != null) {
      hasNaN = valConst.isNaN;
      if (valConst > 0) sum = valConst * n;
      for (var i = 0; i < n; ++i) {
        index[i] = i;
        values[i] = valConst;
      }
    } else if (_defaultValue) {
      for (var i = 0; i < n; ++i) {
        index[i] = i;
        final d = list[i];
        final v = d is double ? d : _defaultPieValue(d, i, list);
        values[i] = v;
        if (v > 0) {
          sum += v;
        } else if (v.isNaN) {
          hasNaN = true;
        }
      }
    } else {
      final valFn = _value;
      for (var i = 0; i < n; ++i) {
        index[i] = i;
        final v = values[i] = valFn(list[i], i, list);
        if (v > 0) {
          sum += v;
        } else if (v.isNaN) {
          hasNaN = true;
        }
      }
    }

    // DIVERGES(d3-shape): adapt-shape-stable-sort, tie-break by original index.
    final sv = _sortValues;
    final sd = _sort;
    if (sv != null) {
      if (_defaultSortValues && !hasNaN && n <= 32) {
        // Stable descending insertion sort (zero closures).
        for (var i = 1; i < n; ++i) {
          final idx = index[i];
          final v = values[idx];
          var j = i - 1;
          while (j >= 0 && values[index[j]] < v) {
            index[j + 1] = index[j];
            --j;
          }
          index[j + 1] = idx;
        }
      } else {
        index.sort((i, j) {
          final c = sv(values[i], values[j]);
          return c < 0 ? -1 : (c > 0 ? 1 : i - j);
        });
      }
    } else if (sd != null) {
      index.sort((i, j) {
        final c = sd(list[i], list[j]);
        return c < 0 ? -1 : (c > 0 ? 1 : i - j);
      });
    }

    final k = sum != 0 ? (da - n * pa) / sum : 0.0;
    final j0 = index[0];
    final v0 = values[j0];
    final a1First = a0 + (v0 > 0 ? v0 * k : 0.0) + pa;
    final firstArc = PieArc<T>(
      data: list[j0],
      index: 0,
      value: v0,
      startAngle: a0,
      endAngle: a1First,
      padAngle: p,
    );
    a0 = a1First;

    final arcs = List<PieArc<T>>.filled(n, firstArc);
    for (var i = 1; i < n; ++i) {
      final j = index[i];
      final v = values[j];
      final a1 = a0 + (v > 0 ? v * k : 0.0) + pa;
      arcs[j] = PieArc<T>(
        data: list[j],
        index: i,
        value: v,
        startAngle: a0,
        endAngle: a1,
        padAngle: p,
      );
      a0 = a1;
    }

    return arcs;
  }

  /// Current value accessor.
  PieValueAccessor<T> get value => _value;

  /// Sets the value accessor.
  set value(PieValueAccessor<T> fn) {
    _value = fn;
    _defaultValue = identical(fn, _defaultPieValue);
    _valueConst = null;
  }

  /// Sets a constant numeric value.
  void valueConst(double v) {
    _value = (_, _, _) => v;
    _defaultValue = false;
    _valueConst = v;
  }

  /// Current value comparator (`null` if sorting by datum or unsorted).
  PieValueComparator? get sortValues => _sortValues;

  /// Sets the value comparator and clears [sort].
  set sortValues(PieValueComparator? fn) {
    _sortValues = fn;
    _defaultSortValues = identical(fn, shapeDescending);
    _sort = null;
  }

  /// Current datum comparator (`null` if sorting by value or unsorted).
  PieDataComparator<T>? get sort => _sort;

  /// Sets the datum comparator and clears [sortValues].
  set sort(PieDataComparator<T>? fn) {
    _sort = fn;
    _sortValues = null;
    _defaultSortValues = false;
  }

  /// Current start angle accessor.
  PieAngleAccessor<T> get startAngle => _startAngle;

  /// Sets the start angle accessor.
  set startAngle(PieAngleAccessor<T> fn) {
    _startAngle = fn;
    _startAngleConst = null;
  }

  /// Sets a constant start angle.
  void startAngleConst(double value) {
    _startAngle = (_) => value;
    _startAngleConst = value;
  }

  /// Current end angle accessor.
  PieAngleAccessor<T> get endAngle => _endAngle;

  /// Sets the end angle accessor.
  set endAngle(PieAngleAccessor<T> fn) {
    _endAngle = fn;
    _endAngleConst = null;
  }

  /// Sets a constant end angle.
  void endAngleConst(double value) {
    _endAngle = (_) => value;
    _endAngleConst = value;
  }

  /// Current pad angle accessor.
  PieAngleAccessor<T> get padAngle => _padAngle;

  /// Sets the pad angle accessor.
  set padAngle(PieAngleAccessor<T> fn) {
    _padAngle = fn;
    _padAngleConst = null;
  }

  /// Sets a constant pad angle.
  void padAngleConst(double value) {
    _padAngle = (_) => value;
    _padAngleConst = value;
  }
}

/// `pie.js:7` default export: creates a new [Pie] layout generator.
Pie<T> pie<T>({double? startAngle, double? endAngle, double? padAngle}) {
  final p = Pie<T>();
  if (startAngle != null) p.startAngleConst(startAngle);
  if (endAngle != null) p.endAngleConst(endAngle);
  if (padAngle != null) p.padAngleConst(padAngle);
  return p;
}
