// Ported from d3-format v3.1.2 src/precisionPrefix.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/precisionPrefix.js` of d3-format 3.1.2.
library;

import 'dart:math' as math;

import 'package:flutter_d3_format_port/src/exponent.dart';

// DIVERGES(d3-format): adapt-format-typed-api, returns int? for NaN/0/Inf

/// Returns a suggested decimal precision for use with `formatPrefix` given the
/// specified numeric [step] and reference [value], or `null` if either is `0`,
/// `NaN`, or infinite.
int? precisionPrefix(num step, num value) {
  final eStep = formatExponent(step.toDouble().abs());
  final eValue = formatExponent(value);
  if (eStep == null || eValue == null) return null;
  return math.max(
    0,
    math.max(-8, math.min(8, (eValue / 3).floor())) * 3 - eStep,
  );
}
