// Ported from d3-array v3.2.4 src/difference.js (ISC, Mike Bostock).

/// Port of `src/difference.js` of d3-array 3.2.4.
library;

@pragma('vm:prefer-inline')
bool _isNaN<T>(T value) => value is num && value.isNaN;

/// Returns a new [Set] containing every distinct value in [values] that does
/// not appear in any iterable of [others].
// DIVERGES(d3-array): adapt-array-typed-api, returns native Dart Set<T> and
// takes Iterable<Iterable<T>> (plus difference2 for two iterables).
Set<T> difference<T>(Iterable<T> values, Iterable<Iterable<T>> others) {
  final remove = <T>{};
  var removeNaN = false;
  for (final other in others) {
    for (final value in other) {
      if (_isNaN(value)) {
        removeNaN = true;
      } else {
        remove.add(value);
      }
    }
  }
  final out = <T>{};
  var outHasNaN = false;
  for (final value in values) {
    if (_isNaN(value)) {
      if (!removeNaN && !outHasNaN) {
        outHasNaN = true;
        out.add(value);
      }
    } else if (!remove.contains(value)) {
      out.add(value);
    }
  }
  return out;
}

/// Returns a new [Set] containing every distinct value in [a] that is not in
/// [b].
Set<T> difference2<T>(Iterable<T> a, Iterable<T> b) =>
    difference<T>(a, <Iterable<T>>[b]);
