// Ported from d3-array v3.2.4 src/union.js (ISC, Mike Bostock).

/// Port of `src/union.js` of d3-array 3.2.4.
library;

@pragma('vm:prefer-inline')
bool _isNaN<T>(T value) => value is num && value.isNaN;

/// Returns a new [Set] containing every distinct value that appears in any of
/// [others], preserving first-seen order (with `SameValueZero` `NaN`
/// deduplication).
// DIVERGES(d3-array): adapt-array-typed-api, returns native Dart Set<T> and
// takes Iterable<Iterable<T>> (plus union2 for two iterables).
Set<T> union<T>(Iterable<Iterable<T>> others) {
  final set = <T>{};
  var hasNaN = false;
  for (final other in others) {
    for (final o in other) {
      if (_isNaN(o)) {
        if (!hasNaN) {
          hasNaN = true;
          set.add(o);
        }
      } else {
        set.add(o);
      }
    }
  }
  return set;
}

/// Returns a new [Set] containing every distinct value in [a] or [b].
Set<T> union2<T>(Iterable<T> a, Iterable<T> b) => union<T>(<Iterable<T>>[a, b]);
