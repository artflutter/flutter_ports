// Ported from d3-random v3.0.1 src/irwinHall.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/irwinHall.js` of d3-random 3.0.1.
library;

import 'dart:typed_data';

import 'package:flutter_d3_random_port/src/defaultSource.dart';

/// Precomputes exact `(fullSteps, remainder)` matching upstream's
/// `for (var i = n; i > 1; --i)` loop.
(int, double) irwinHallSteps(double nd) {
  var full = 0;
  var rem = nd;
  while (rem > 1.0) {
    ++full;
    rem -= 1.0;
  }
  return (full, rem);
}

// DIVERGES(d3-random): adapt-random-typed-api, typed callable factory class
// with .source(RandomSource) and typed batch helpers.
// DIVERGES(d3-random): adapt-random-fast-forms, integer loop counter with
// precomputed fractional remainder and direct fill loop.
/// Factory for Irwin-Hall distribution generators (sum of `n` independent
/// uniform `[0, 1)` variates).
final class const RandomIrwinHall(final RandomSource _source) {
  /// Creates a [RandomIrwinHall] factory backed by [_source].
  this;

  /// Returns a generator for Irwin-Hall distributed numbers with parameter [n].
  RandomGenerator call(num n) {
    final nd = n.toDouble();
    if (nd <= 0.0) return () => 0.0;
    final (full, rem) = irwinHallSteps(nd);
    final src = _source;
    if (rem == 1.0) {
      return () {
        var sum = 0.0;
        for (var k = 0; k < full; ++k) {
          sum += src();
        }
        return sum + src();
      };
    }
    return () {
      var sum = 0.0;
      for (var k = 0; k < full; ++k) {
        sum += src();
      }
      return sum + rem * src();
    };
  }

  /// Returns a new [RandomIrwinHall] factory using [source].
  RandomIrwinHall source(RandomSource source) => RandomIrwinHall(source);

  /// Fills [target] with Irwin-Hall distributed draws.
  void fill(Float64List target, num n) {
    final nd = n.toDouble();
    final len = target.length;
    if (nd <= 0.0) {
      target.fillRange(0, len, 0);
      return;
    }
    final (full, rem) = irwinHallSteps(nd);
    final src = _source;
    if (rem == 1.0) {
      for (var i = 0; i < len; ++i) {
        var sum = 0.0;
        for (var k = 0; k < full; ++k) {
          sum += src();
        }
        target[i] = sum + src();
      }
    } else {
      for (var i = 0; i < len; ++i) {
        var sum = 0.0;
        for (var k = 0; k < full; ++k) {
          sum += src();
        }
        target[i] = sum + rem * src();
      }
    }
  }

  /// Allocates a [Float64List] of [count] Irwin-Hall distributed draws.
  Float64List sample(int count, num n) {
    final out = Float64List(count);
    fill(out, n);
    return out;
  }
}

/// Irwin-Hall distribution generator factory backed by [defaultRandomSource].
const RandomIrwinHall randomIrwinHall = RandomIrwinHall(defaultRandomSource);
