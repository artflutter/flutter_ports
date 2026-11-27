// Ported from d3-array v3.2.4 src/intersection.js (ISC, Mike Bostock).

/// Port of `src/intersection.js` of d3-array 3.2.4.
library;

@pragma('vm:prefer-inline')
bool _isNaN<T>(T value) => value is num && value.isNaN;

/// Returns a new [Set] containing every distinct value in [values] that also
/// appears in every iterable of [others].
// DIVERGES(d3-array): adapt-array-typed-api, returns native Dart Set<T> and
// takes Iterable<Iterable<T>> (plus intersection2 for two iterables).
Set<T> intersection<T>(Iterable<T> values, Iterable<Iterable<T>> others) {
  final base = <T>{};
  var baseHasNaN = false;
  for (final v in values) {
    if (_isNaN(v)) {
      if (!baseHasNaN) {
        baseHasNaN = true;
        base.add(v);
      }
    } else {
      base.add(v);
    }
  }
  final otherSets = <(Set<T>, bool)>[];
  for (final other in others) {
    final s = <T>{};
    var hasNaN = false;
    for (final v in other) {
      if (_isNaN(v)) {
        hasNaN = true;
      } else {
        s.add(v);
      }
    }
    otherSets.add((s, hasNaN));
  }
  final out = <T>{};
  for (final value in base) {
    final isNan = _isNaN(value);
    var keep = true;
    for (final (s, hasNaN) in otherSets) {
      if (isNan ? !hasNaN : !s.contains(value)) {
        keep = false;
        break;
      }
    }
    if (keep) out.add(value);
  }
  return out;
}

/// Returns a new [Set] containing every distinct value present in both [a] and
/// [b].
Set<T> intersection2<T>(Iterable<T> a, Iterable<T> b) =>
    intersection<T>(a, <Iterable<T>>[b]);
