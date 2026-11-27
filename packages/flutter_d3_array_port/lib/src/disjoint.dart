// Ported from d3-array v3.2.4 src/disjoint.js (ISC, Mike Bostock).

/// Port of `src/disjoint.js` of d3-array 3.2.4.
library;

@pragma('vm:prefer-inline')
bool _isNaN<T>(T value) => value is num && value.isNaN;

/// Returns `true` if [values] and [other] have no shared elements (lazily
/// consuming [other] until a match is found).
// DIVERGES(d3-array): adapt-array-typed-api, uses native Dart value-equal
// Set<T> with SameValueZero NaN handling.
bool disjoint<T>(Iterable<T> values, Iterable<T> other) {
  final iterator = other.iterator;
  final seen = <T>{};
  var seenNaN = false;
  for (final v in values) {
    final vNaN = _isNaN(v);
    if (vNaN ? seenNaN : seen.contains(v)) return false;
    while (iterator.moveNext()) {
      final value = iterator.current;
      final valNaN = _isNaN(value);
      if (vNaN ? valNaN : (!valNaN && v == value)) return false;
      if (valNaN) {
        seenNaN = true;
      } else {
        seen.add(value);
      }
    }
  }
  return true;
}
