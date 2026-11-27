// Ported from d3-array v3.2.4 src/bisector.js (ISC, Mike Bostock).

/// Port of `src/bisector.js` of d3-array 3.2.4.
library;

import 'package:flutter_d3_array_port/src/ascending.dart';
import 'package:flutter_d3_array_port/src/descending.dart';

/// A typed binary-search bisector over lists of `T` searched by keys of `X`.
// DIVERGES(d3-array): adapt-array-typed-api, strongly typed Bisector<T, X>
// class with explicit accessor (bisector) and comparator (bisectorCompare /
// bisectorComparator) factories instead of JS Function.length sniffing.
final class const Bisector<T, X>._({
  required final bool Function(X x) _isDefined,
  required final num Function(T d, X x) _compare,
  required final num Function(T d, X x) _delta,
}) {
  /// Creates a [Bisector] from explicit comparison and delta functions.
  this;

  /// Returns the insertion point for [x] in sorted [a] to maintain sorted
  /// order, placing [x] before any existing entries equal to [x].
  int left(List<T> a, X x, [int lo = 0, int? hi]) {
    var l = lo;
    var h = hi ?? a.length;
    if (l < h) {
      if (!_isDefined(x)) return h;
      do {
        final mid = (l + h) >>> 1;
        if (_compare(a[mid], x) < 0) {
          l = mid + 1;
        } else {
          h = mid;
        }
      } while (l < h);
    }
    return l;
  }

  /// Returns the insertion point for [x] in sorted [a] to maintain sorted
  /// order, placing [x] after any existing entries equal to [x].
  int right(List<T> a, X x, [int lo = 0, int? hi]) {
    var l = lo;
    var h = hi ?? a.length;
    if (l < h) {
      if (!_isDefined(x)) return h;
      do {
        final mid = (l + h) >>> 1;
        if (_compare(a[mid], x) <= 0) {
          l = mid + 1;
        } else {
          h = mid;
        }
      } while (l < h);
    }
    return l;
  }

  /// Returns the index of the value closest to [x] in sorted [a].
  int center(List<T> a, X x, [int lo = 0, int? hi]) {
    final h = hi ?? a.length;
    final i = left(a, x, lo, h - 1);
    return i > lo && _delta(a[i - 1], x) > -_delta(a[i], x) ? i - 1 : i;
  }
}

bool _alwaysDefined<X>(X _) => true;

double _defaultDelta<X extends Comparable<Object>>(X? a, X? b) {
  if (a == null || b == null) return double.nan;
  if (a is num && b is num) return a.toDouble() - b.toDouble();
  if (a is DateTime && b is DateTime) {
    return (a.millisecondsSinceEpoch - b.millisecondsSinceEpoch).toDouble();
  }
  return ascending<X>(a, b);
}

/// Creates a [Bisector] using a typed key [accessor].
///
/// For [Bisector.center], pass [delta] for custom key types; for `num` and
/// `DateTime` keys the difference is computed automatically.
Bisector<T, X> bisector<T, X extends Comparable<Object>>(
  X? Function(T d) accessor, {
  double Function(X? a, X? b)? delta,
}) {
  final deltaFn = delta ?? _defaultDelta<X>;
  return Bisector<T, X>._(
    isDefined: (x) => ascending<X>(x, x) == 0,
    compare: (d, x) => ascending<X>(accessor(d), x),
    delta: (d, x) => deltaFn(accessor(d), x),
  );
}

/// Creates a [Bisector] using a typed nullable key [accessor].
Bisector<T, X?> bisectorNullable<T, X extends Comparable<Object>>(
  X? Function(T d) accessor, {
  double Function(X? a, X? b)? delta,
}) {
  final deltaFn = delta ?? _defaultDelta<X>;
  return Bisector<T, X?>._(
    isDefined: (x) => ascending<X>(x, x) == 0,
    compare: (d, x) => ascending<X>(accessor(d), x),
    delta: (d, x) => deltaFn(accessor(d), x),
  );
}

/// Creates a [Bisector] using an asymmetric comparator `compare(d, x)`.
Bisector<T, X> bisectorCompare<T, X>(
  num Function(T d, X x) compare, {
  bool Function(X x)? isDefined,
}) {
  return Bisector<T, X>._(
    isDefined: isDefined ?? _alwaysDefined<X>,
    compare: compare,
    delta: compare,
  );
}

/// Creates a [Bisector] using a symmetric comparator `compare(a, b)`.
///
/// Recognizes [ascending] and [descending] to check self-comparability of `x`
/// (returning `hi` when `x` is `null` or `NaN`), matching upstream.
Bisector<T, T> bisectorComparator<T>(num Function(T a, T b) compare) {
  final checkSelf =
      identical(compare, ascending) || identical(compare, descending);
  return Bisector<T, T>._(
    isDefined: checkSelf ? (x) => compare(x, x) == 0 : _alwaysDefined<T>,
    compare: compare,
    delta: compare,
  );
}
