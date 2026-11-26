// Ported from d3-format v3.1.2 src/precisionRound.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/precisionRound.js` of d3-format 3.1.2.
library;

import 'dart:math' as math;

import 'package:flutter_d3_format_port/src/exponent.dart';

// DIVERGES(d3-format): adapt-format-typed-api, returns int? for NaN/0/Inf

/// Returns a suggested decimal precision for format types that round to
/// significant digits given the specified numeric [step] and [max] values, or
/// `null` if [step] or `|max| - |step|` is `0`, `NaN`, or infinite.
int? precisionRound(num step, num max) {
  final s = step.toDouble().abs();
  final m = max.toDouble().abs() - s;
  final eStep = formatExponent(s);
  final eMax = formatExponent(m);
  if (eStep == null || eMax == null) return null;
  return math.max(0, eMax - eStep) + 1;
}
