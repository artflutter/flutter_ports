// Ported from d3-array v3.2.4 test/shuffle-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

/// Deterministic LCG matching `d3-random`'s `randomLcg` (Numerical Recipes
/// parameters, 32-bit signed state).
double Function() _randomLcg(double seed) {
  const mul = 0x19660d;
  const inc = 0x3c6ef35f;
  const eps = 1 / 0x100000000;
  var state = (0 <= seed && seed < 1 ? seed / eps : seed.abs())
      .truncate()
      .toSigned(32);
  return () {
    state = (mul * state + inc).toSigned(32);
    return eps * state.toUnsigned(32);
  };
}

void main() {
  test('shuffle(array) shuffles the array in-place', () {
    final numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    final shuffleFn = shuffler(_randomLcg(0.9051667019185816));
    expect(identical(shuffleFn(numbers), numbers), isTrue);
    expect(pairs(numbers).any((p) => p.$1 > p.$2), isTrue);
  });

  test('shuffler(random)(array) shuffles the array in-place', () {
    final numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    final shuffleFn = shuffler(_randomLcg(0.9051667019185816));
    expect(identical(shuffleFn(numbers), numbers), isTrue);
    expect(numbers, [7, 4, 5, 3, 9, 0, 6, 1, 2, 8]);
  });

  test(
    'shuffler(random)(array, start) shuffles the subset array[start:] in-place',
    () {
      final numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
      final shuffleFn = shuffler(_randomLcg(0.9051667019185816));
      expect(identical(shuffleFn(numbers, 4), numbers), isTrue);
      expect(numbers, [0, 1, 2, 3, 8, 7, 6, 4, 5, 9]);
    },
  );

  test(
    'shuffler(random)(array, start, end) shuffles the subset array[start:end] '
    'in-place',
    () {
      final numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
      final shuffleFn = shuffler(_randomLcg(0.9051667019185816));
      expect(identical(shuffleFn(numbers, 3, 8), numbers), isTrue);
      expect(numbers, [0, 1, 2, 5, 6, 3, 4, 7, 8, 9]);
    },
  );
}
