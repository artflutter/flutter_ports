// Ported from d3-shape v3.2.0 src/stack.js (ISC, Mike Bostock).

/// Port of `src/stack.js` of d3-shape 3.2.0: [Stack], [StackSeries],
/// [StackPoint], and [stack].
library;

import 'package:flutter_d3_shape_port/src/array.dart';
import 'package:flutter_d3_shape_port/src/offset/none.dart';
import 'package:flutter_d3_shape_port/src/order/none.dart';

/// Key list accessor for [Stack].
typedef StackKeysAccessor<D, K> = Iterable<K> Function(List<D> data);

/// Value accessor for [Stack].
typedef StackValueAccessor<D, K> = double Function(
  D d,
  K key,
  int i,
  List<D> data,
);

/// Series ordering function for [Stack].
typedef StackOrder = List<int> Function(List<StackSeries<Object?, Object?>> s);

/// Baseline offset function for [Stack].
typedef StackOffset = void Function(
  List<StackSeries<Object?, Object?>> series,
  List<int> order,
);

/// A single stacked `[y0, y1]` point with its originating datum [data].
// DIVERGES(d3-shape): adapt-shape-typed-api, typed StackPoint class.
final class StackPoint<D>(
  double y0,
  double y1,

  /// Originating datum (`point.data`).
  final D data,
) {
  /// Creates a stacked point `[y0, y1]` associated with [data].
  this;

  /// Lower baseline value (`point[0]`).
  double y0 = y0;

  /// Upper topline value (`point[1]`).
  double y1 = y1;

  /// Reads [y0] for index `0` or [y1] for index `1`.
  double operator [](int index) => index == 0 ? y0 : y1;

  /// Writes [y0] for index `0` or [y1] for index `1`.
  void operator []=(int index, double value) {
    if (index == 0) {
      y0 = value;
    } else {
      y1 = value;
    }
  }

  @override
  String toString() => '[$y0, $y1]';
}

/// One series produced by [Stack], holding [key], post-ordering [index], and
/// stacked [points].
// DIVERGES(d3-shape): adapt-shape-typed-api, typed StackSeries class.
final class StackSeries<D, K>(
  /// Series key (`series.key`).
  final K key,

  /// Stacked points for each datum.
  final List<StackPoint<D>> points, {
  int index = 0,
}) {
  /// Creates a stack series for [key] and [points].
  this;

  /// Post-ordering series index (`series.index`).
  int index = index;

  /// Number of points in this series.
  int get length => points.length;

  /// Returns the point at index [i].
  StackPoint<D> operator [](int i) => points[i];

  /// Creates a series from raw `(y0, y1)` pairs (useful for standalone
  /// offset/order calls).
  static StackSeries<Null, Null> fromPairs(
    List<(double, double)> pairs, {
    int index = 0,
  }) => StackSeries<Null, Null>(null, [
    for (final (y0, y1) in pairs) StackPoint<Null>(y0, y1, null),
  ], index: index);
}

double _defaultStackValue<D, K>(D d, K key, int i, List<D> data) {
  if (d is Map) {
    final v = d[key];
    return v is num ? v.toDouble() : double.nan;
  }
  if (d is List && key is int) {
    final v = d[key];
    return v is num ? v.toDouble() : double.nan;
  }
  throw ArgumentError.value(
    d,
    'd',
    'Expected Map or List datum, or set a custom stack value accessor',
  );
}

Iterable<K> _emptyKeys<D, K>(List<D> _) => const [];

/// `stack.js:15` `stack`: generates stacked series for streamgraphs, stacked
/// bar charts, and stacked area charts.
// DIVERGES(d3-shape): adapt-shape-typed-api, typed generic Stack class.
final class Stack<D, K>() {
  /// Creates a stack generator with default accessors.
  this;

  StackKeysAccessor<D, K> _keys = _emptyKeys;
  List<K>? _keysConst = const [];

  StackValueAccessor<D, K> _value = _defaultStackValue;
  double? _valueConst;

  StackOrder _order = stackOrderNone;
  StackOffset _offset = stackOffsetNone;

  /// Computes stacked series for [data].
  // DIVERGES(d3-shape): adapt-shape-fast-forms, cached constant keys.
  List<StackSeries<D, K>> call(Iterable<D> data) {
    final list = shapeArray(data);
    final keyList = _keysConst ?? List<K>.of(_keys(list), growable: false);
    final n = keyList.length;
    final m = list.length;
    if (n == 0) return const [];

    final valConst = _valueConst;
    final valFn = _value;

    final sz = List<StackSeries<D, K>>.generate(n, (i) {
      final key = keyList[i];
      final pts = List<StackPoint<D>>.generate(m, (j) {
        final d = list[j];
        return StackPoint<D>(0, valConst ?? valFn(d, key, j, list), d);
      }, growable: false);
      return StackSeries<D, K>(key, pts);
    }, growable: false);

    final oz = _order(sz);
    for (var i = 0; i < n; ++i) {
      sz[oz[i]].index = i;
    }

    _offset(sz, oz);
    return sz;
  }

  /// Current keys accessor.
  StackKeysAccessor<D, K> get keys => _keys;

  /// Sets the keys accessor.
  set keys(StackKeysAccessor<D, K> fn) {
    _keys = fn;
    _keysConst = null;
  }

  /// Sets a constant list of keys.
  void keysConst(Iterable<K> values) {
    final copy = List<K>.of(values, growable: false);
    _keys = (_) => copy;
    _keysConst = copy;
  }

  /// Current value accessor.
  StackValueAccessor<D, K> get value => _value;

  /// Sets the value accessor.
  set value(StackValueAccessor<D, K> fn) {
    _value = fn;
    _valueConst = null;
  }

  /// Sets a constant numeric value.
  void valueConst(double v) {
    _value = (_, _, _, _) => v;
    _valueConst = v;
  }

  /// Current series order function.
  StackOrder get order => _order;

  /// Sets the series order function (`null` resets to [stackOrderNone]).
  set order(StackOrder? fn) => _order = fn ?? stackOrderNone;

  /// Sets a constant series order array.
  void orderConst(Iterable<int> order) {
    final copy = List<int>.of(order, growable: false);
    _order = (_) => copy;
  }

  /// Current baseline offset function.
  StackOffset get offset => _offset;

  /// Sets the baseline offset function (`null` resets to [stackOffsetNone]).
  set offset(StackOffset? fn) => _offset = fn ?? stackOffsetNone;
}

/// `stack.js:15` default export: creates a new [Stack] generator.
Stack<D, K> stack<D, K>({
  Iterable<K>? keys,
  StackOrder? order,
  StackOffset? offset,
}) {
  final s = Stack<D, K>();
  if (keys != null) s.keysConst(keys);
  if (order != null) s.order = order;
  if (offset != null) s.offset = offset;
  return s;
}
