// Ported from d3-format v3.1.2 src/exponent.js (ISC, Mike Bostock).

/// Port of `src/exponent.js` of d3-format 3.1.2.
library;

import 'package:flutter_d3_format_port/src/formatDecimal.dart';

// DIVERGES(d3-format): adapt-format-typed-api, returns int? for NaN/0/Inf

/// Returns the base-10 exponent of [x], or `null` if [x] is `0`, `NaN`, or
/// infinite.
int? formatExponent(num x) {
  final parts = formatDecimalParts(x.toDouble().abs());
  return parts?.$2;
}
