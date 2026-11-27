// Ported from d3-random v3.0.1 src/bates.js (ISC, Mike Bostock).

/// Port of `src/bates.js` of d3-random 3.0.1.
library;

import 'dart:typed_data';

import 'package:flutter_d3_random_port/src/defaultSource.dart';
import 'package:flutter_d3_random_port/src/irwinHall.dart';

// DIVERGES(d3-random): adapt-random-typed-api, typed callable factory class
// with .source(RandomSource) and typed batch helpers.
// DIVERGES(d3-random): adapt-random-fast-forms, inlined integer Irwin-Hall
// summation loop eliminating nested closure call and direct fill loop.
/// Factory for Bates distribution generators (mean of `n` independent uniform
/// `[0, 1)` variates).
final class const RandomBates(final RandomSource _source) {
  /// Creates a [RandomBates] factory backed by [_source].
  this;

  /// Returns a generator for Bates distributed numbers with parameter [n].
  ///
  /// When [n] is `0`, returns the underlying uniform source directly.
  RandomGenerator call(num n) {
    final nd = n.toDouble();
    if (nd == 0.0) return _source;
    if (nd < 0.0) return () => 0.0 / nd;
    final (full, rem) = irwinHallSteps(nd);
    final src = _source;
    if (rem == 1.0) {
      return () {
        var sum = 0.0;
        for (var k = 0; k < full; ++k) {
          sum += src();
        }
        return (sum + src()) / nd;
      };
    }
    return () {
      var sum = 0.0;
      for (var k = 0; k < full; ++k) {
        sum += src();
      }
      return (sum + rem * src()) / nd;
    };
  }

  /// Returns a new [RandomBates] factory using [source].
  RandomBates source(RandomSource source) => RandomBates(source);

  /// Fills [target] with Bates distributed draws.
  void fill(Float64List target, num n) {
    final nd = n.toDouble();
    final len = target.length;
    final src = _source;
    if (nd == 0.0) {
      for (var i = 0; i < len; ++i) {
        target[i] = src();
      }
      return;
    }
    if (nd < 0.0) {
      target.fillRange(0, len, 0.0 / nd);
      return;
    }
    final (full, rem) = irwinHallSteps(nd);
    if (rem == 1.0) {
      for (var i = 0; i < len; ++i) {
        var sum = 0.0;
        for (var k = 0; k < full; ++k) {
          sum += src();
        }
        target[i] = (sum + src()) / nd;
      }
    } else {
      for (var i = 0; i < len; ++i) {
        var sum = 0.0;
        for (var k = 0; k < full; ++k) {
          sum += src();
        }
        target[i] = (sum + rem * src()) / nd;
      }
    }
  }

  /// Allocates a [Float64List] of [count] Bates distributed draws.
  Float64List sample(int count, num n) {
    final out = Float64List(count);
    fill(out, n);
    return out;
  }
}

/// Bates distribution generator factory backed by [defaultRandomSource].
const RandomBates randomBates = RandomBates(defaultRandomSource);
