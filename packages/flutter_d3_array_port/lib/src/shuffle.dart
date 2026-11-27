// Ported from d3-array v3.2.4 src/shuffle.js (ISC, Mike Bostock).

/// Port of `src/shuffle.js` of d3-array 3.2.4.
library;

import 'dart:math' as math;

final math.Random _defaultRandom = math.Random();

/// A callable generic Fisher-Yates shuffler parameterized by a uniform random
/// source returning doubles in `[0, 1)`.
// DIVERGES(d3-array): adapt-array-typed-api, generic callable Shuffler class
// so a single shuffler(random) instance shuffles lists of any element type T.
final class Shuffler(final double Function() _random) {
  /// Creates a [Shuffler] backed by [_random].
  this;

  /// Shuffles [array] in-place over `[i0, i1)` and returns [array].
  List<T> call<T>(List<T> array, [int i0 = 0, int? i1]) {
    final start = i0;
    final end = i1 ?? array.length;
    var m = end - start;
    while (m > 0) {
      final i = (_random() * m--).floor();
      final a = m + start;
      final b = i + start;
      final t = array[a];
      array[a] = array[b];
      array[b] = t;
    }
    return array;
  }
}

/// Returns a [Shuffler] backed by the specified [random] generator.
Shuffler shuffler(double Function() random) => Shuffler(random);

/// Randomizes the order of [array] in-place over `[i0, i1)` using the
/// Fisher-Yates shuffle and returns [array].
// DIVERGES(d3-array): adapt-array-fast-forms, uses Random.nextInt directly
// on the default shuffle hot path.
List<T> shuffle<T>(List<T> array, [int i0 = 0, int? i1]) {
  final start = i0;
  final end = i1 ?? array.length;
  var m = end - start;
  while (m > 0) {
    final i = _defaultRandom.nextInt(m--);
    final a = m + start;
    final b = i + start;
    final t = array[a];
    array[a] = array[b];
    array[b] = t;
  }
  return array;
}
