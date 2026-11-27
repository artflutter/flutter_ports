// Ported from d3-random v3.0.1 src/defaultSource.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/defaultSource.js` of d3-random 3.0.1.
library;

import 'dart:math' as math;
import 'dart:typed_data';

// DIVERGES(d3-random): adapt-random-typed-api, typed RandomSource,
// RandomGenerator, RandomIntGenerator typedefs, randomLog1p helper, and batch
// fill/sample extensions.
// DIVERGES(d3-random): adapt-random-fast-forms, specialized randomLog1m(u)
// for ln(1 - u) on u in [0, 1) avoiding unnecessary NaN/Inf branches and
// skipping Kahan division whenever 1 - u is exact.

/// A uniform pseudorandom number source returning values in `[0, 1)`.
typedef RandomSource = double Function();

/// A callable generator for continuous distributions returning `double` values.
typedef RandomGenerator = double Function();

/// A callable generator for discrete distributions returning `int` values.
typedef RandomIntGenerator = int Function();

final math.Random _defaultRng = math.Random();

/// The default uniform random source in `[0, 1)`, backed by `dart:math.Random`.
double defaultRandomSource() => _defaultRng.nextDouble();

/// Computes `ln(1 + x)` accurately for small `|x|`, matching ECMAScript
/// `Math.log1p(x)`.
double randomLog1p(double x) {
  if (x.isNaN || x < -1.0) return double.nan;
  if (x == -1.0) return double.negativeInfinity;
  if (x == 0.0 || x == double.infinity) return x;
  final u = 1.0 + x;
  if (u == 1.0) return x;
  return math.log(u) * (x / (u - 1.0));
}

/// Fast `ln(1 - u)` for `u` in `[0, 1)`.
///
/// Exact by Sterbenz's lemma for `u >= 0.5` and whenever `1.0 - (1.0 - u) == u`
/// (including all 32-bit LCG draws), falling back to Kahan's compensation for
/// sub-ulp small `u` from 53-bit sources.
@pragma('vm:prefer-inline')
double randomLog1m(double u) {
  final w = 1.0 - u;
  if (w == 1.0) return -u;
  final d = 1.0 - w;
  return d == u ? math.log(w) : math.log(w) * (u / d);
}

/// Typed batch sampling helpers on continuous [RandomGenerator] functions.
extension RandomGeneratorBatch on RandomGenerator {
  /// Fills [target] with draws from this generator.
  void fill(Float64List target) {
    final n = target.length;
    for (var i = 0; i < n; ++i) {
      target[i] = this();
    }
  }

  /// Allocates a [Float64List] of length [count] filled with draws from this
  /// generator.
  Float64List sample(int count) {
    final out = Float64List(count);
    fill(out);
    return out;
  }
}

/// Typed batch sampling helpers on discrete [RandomIntGenerator] functions.
extension RandomIntGeneratorBatch on RandomIntGenerator {
  /// Fills [target] with draws from this generator.
  void fill(Int32List target) {
    final n = target.length;
    for (var i = 0; i < n; ++i) {
      target[i] = this();
    }
  }

  /// Allocates an [Int32List] of length [count] filled with draws from this
  /// generator.
  Int32List sample(int count) {
    final out = Int32List(count);
    fill(out);
    return out;
  }
}
