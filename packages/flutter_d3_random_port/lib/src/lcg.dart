// Ported from d3-random v3.0.1 src/lcg.js (ISC, Mike Bostock).

/// Port of `src/lcg.js` of d3-random 3.0.1.
library;

import 'package:flutter_d3_random_port/src/defaultSource.dart';

// https://en.wikipedia.org/wiki/Linear_congruential_generator#Parameters_in_common_use
const int _mul = 0x19660D;
const int _inc = 0x3C6EF35F;
const double _eps = 1.0 / 0x100000000;
const double _two32 = 4294967296;

int _toUint32(double x) {
  if (!x.isFinite || x == 0.0) return 0;
  final truncated = x.truncateToDouble();
  final mod = truncated.remainder(_two32);
  final unsigned = mod < 0.0 ? mod + _two32 : mod;
  return unsigned.toInt() & 0xffffffff;
}

final class _LcgState(var int _state) {
  @pragma('vm:prefer-inline')
  double next() {
    final s = (_mul * _state + _inc) & 0xffffffff;
    _state = s;
    return _eps * s;
  }
}

// DIVERGES(d3-random): adapt-random-typed-api, typed RandomSource return type
// and cross-platform exact 32-bit unsigned modular arithmetic.
// DIVERGES(d3-random): adapt-random-fast-forms, unboxed 32-bit unsigned state
// field safe across 64-bit native ints and 53-bit IEEE 754 JS doubles.
/// Returns a deterministic linear congruential generator (LCG) producing
/// pseudorandom doubles uniformly distributed on `[0, 1)`.
///
/// A [seed] may be given as a real number in `[0, 1)` or any integer (of which
/// the lower 32 bits of its absolute value are used). If omitted or `null`, a
/// seed is chosen using [defaultRandomSource].
RandomSource randomLcg([num? seed]) {
  final s = seed == null ? defaultRandomSource() : seed.toDouble();
  final initial = _toUint32(0.0 <= s && s < 1.0 ? s / _eps : s.abs());
  return _LcgState(initial).next;
}
