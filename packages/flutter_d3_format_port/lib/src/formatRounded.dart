// Ported from d3-format v3.1.2 src/formatRounded.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/formatRounded.js` of d3-format 3.1.2.
library;

import 'package:flutter_d3_format_port/src/formatDecimal.dart';

// DIVERGES(d3-format): adapt-format-js-number-strings, 0 formats as '0'
// DIVERGES(d3-format): adapt-format-fast-forms, direct decimal part formatting

/// Formats [x] rounded to [p] significant digits in fixed decimal notation
/// (without scientific notation).
String formatRounded(double x, int p) {
  final d = formatDecimalParts(x, p);
  if (d == null) return x == 0 ? '0' : x.toString();
  final coefficient = d.$1;
  final exponent = d.$2;
  if (exponent < 0) {
    return '0.${'0' * (-exponent - 1)}$coefficient';
  }
  if (coefficient.length > exponent + 1) {
    return '${coefficient.substring(0, exponent + 1)}.'
        '${coefficient.substring(exponent + 1)}';
  }
  return '$coefficient${'0' * (exponent - coefficient.length + 1)}';
}
