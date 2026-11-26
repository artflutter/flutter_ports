// Ported from d3-format v3.1.2 src/formatTypes.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/formatTypes.js` of d3-format 3.1.2.
library;

import 'package:flutter_d3_format_port/src/formatDecimal.dart';
import 'package:flutter_d3_format_port/src/formatPrefixAuto.dart';
import 'package:flutter_d3_format_port/src/formatRounded.dart';

// DIVERGES(d3-format): adapt-format-typed-api, numeric radix and String c
// DIVERGES(d3-format): adapt-format-js-number-strings, BigInt radix >= 2^53

const double _maxSafeInt = 9007199254740992;

/// Formats [x] rounded to an integer in base [radix] (2, 8, or 16), matching
/// JavaScript `Math.round(x).toString(radix)`.
String formatRadix(double x, int radix, {bool uppercase = false}) {
  if (!x.isFinite) {
    final text = x.toString();
    return uppercase ? text.toUpperCase() : text;
  }
  final r = jsRound(x);
  if (r == 0) return '0';
  final String text;
  if (r.abs() < _maxSafeInt) {
    text = r.toInt().toRadixString(radix);
  } else {
    text = BigInt.from(r).toRadixString(radix);
  }
  return uppercase ? text.toUpperCase() : text;
}

/// Formatter function signature for numeric format types.
typedef FormatTypeFunction = String Function(double x, int p);

/// Map of supported `d3-format` type codes to their numeric formatters.
final Map<String, FormatTypeFunction> formatTypes = {
  '%': (x, p) => (x * 100).toStringAsFixed(p),
  'b': (x, _) => formatRadix(x, 2),
  'c': (x, _) => formatJsNumberString(x),
  'd': (x, _) => formatDecimal(x),
  'e': (x, p) => x.toStringAsExponential(p),
  'f': (x, p) => x.toStringAsFixed(p),
  'g': (x, p) => x.toStringAsPrecision(p),
  'o': (x, _) => formatRadix(x, 8),
  'p': (x, p) => formatRounded(x * 100, p),
  'r': formatRounded,
  's': formatPrefixAuto,
  'X': (x, _) => formatRadix(x, 16, uppercase: true),
  'x': (x, _) => formatRadix(x, 16),
};

/// Formats a numeric value as a JavaScript-style string (without trailing `.0`
/// for whole numbers and `'0'` for `-0.0`).
String formatJsNumberString(num x) {
  if (x is int) return x.toString();
  final d = x.toDouble();
  if (d == 0) return '0';
  if (!d.isFinite) return d.toString();
  if (d.abs() < _maxSafeInt && d.truncateToDouble() == d) {
    return d.toInt().toString();
  }
  return d.toString();
}
