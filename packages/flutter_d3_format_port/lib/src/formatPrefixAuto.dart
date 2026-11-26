// Ported from d3-format v3.1.2 src/formatPrefixAuto.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/formatPrefixAuto.js` of d3-format 3.1.2.
library;

import 'dart:math' as math;

import 'package:flutter_d3_format_port/src/formatDecimal.dart';

// DIVERGES(d3-format): adapt-format-js-number-strings, p<=0 unrounded parts
// DIVERGES(d3-format): adapt-format-fast-forms, direct exponential slice

/// The SI prefix exponent computed by the most recent call to
/// [formatPrefixAuto], or `null` if the value was `0`, `NaN`, or infinite.
int? prefixExponent;

/// Formats [x] with [p] significant digits scaled to an automatic SI prefix,
/// storing the chosen multiple-of-3 exponent in [prefixExponent].
String formatPrefixAuto(double x, int p) {
  final d = formatDecimalParts(x, p);
  if (d == null) {
    prefixExponent = null;
    return x.toStringAsPrecision(p);
  }
  final coefficient = d.$1;
  final exponent = d.$2;
  final pe = math.max(-8, math.min(8, (exponent / 3).floor())) * 3;
  prefixExponent = pe;
  final i = exponent - pe + 1;
  final n = coefficient.length;
  if (i == n) return coefficient;
  if (i > n) return '$coefficient${'0' * (i - n)}';
  if (i > 0) {
    return '${coefficient.substring(0, i)}.${coefficient.substring(i)}';
  }
  final sub = formatDecimalParts(x, math.max(0, p + i - 1))!;
  return '0.${'0' * (-i)}${sub.$1}'; // less than 1y!
}
