// Ported from d3-format v3.1.2 src/precisionFixed.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/precisionFixed.js` of d3-format 3.1.2.
library;

import 'dart:math' as math;

import 'package:flutter_d3_format_port/src/exponent.dart';

// DIVERGES(d3-format): adapt-format-typed-api, returns int? for NaN/0/Inf

/// Returns a suggested decimal precision for fixed-point notation given the
/// specified numeric [step] value, or `null` if [step] is `0`, `NaN`, or
/// infinite.
int? precisionFixed(num step) {
  final e = formatExponent(step.toDouble().abs());
  if (e == null) return null;
  return math.max(0, -e);
}
