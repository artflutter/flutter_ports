// Ported from d3-format v3.1.2 src/formatDecimal.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/formatDecimal.js` of d3-format 3.1.2.
library;

// DIVERGES(d3-format): adapt-format-js-number-strings, JS Math.round and >=1e21
// DIVERGES(d3-format): adapt-format-fast-forms, inline exponent digit parsing

/// Exact IEEE-754 integer boundary (`2^53`).
const double _maxSafeInt = 9007199254740992;

/// JavaScript `Math.round(x)`: rounds halves toward `+∞`.
@pragma('vm:prefer-inline')
double jsRound(double x) {
  if (!x.isFinite || x == 0) return x;
  if (x > 0) return x.roundToDouble();
  final f = x.floorToDouble();
  if (x - f >= 0.5) {
    final r = f + 1.0;
    return r == 0 ? 0.0 : r;
  }
  return f;
}

/// Formats [x] rounded to an integer decimal string matching JavaScript's
/// `Math.abs(x = Math.round(x)) >= 1e21 ? x.toLocaleString("en").replace(/,/g, "") : x.toString(10)`.
String formatDecimal(double x) {
  if (x.isNaN) return 'NaN';
  if (x.isInfinite) return x.isNegative ? '-∞' : '∞';
  final r = jsRound(x);
  if (r == 0) return '0';
  final absR = r.abs();
  if (absR < _maxSafeInt) {
    return r.toInt().toString();
  }
  final parts = formatDecimalParts(absR)!;
  final coeff = parts.$1;
  final exp = parts.$2;
  final zeros = exp - coeff.length + 1;
  final digits = zeros > 0 ? '$coeff${'0' * zeros}' : coeff;
  return r < 0 ? '-$digits' : digits;
}

/// Parses a signed decimal exponent from [s] starting at index [start].
@pragma('vm:prefer-inline')
int parseExponentAt(String s, int start) {
  final n = s.length;
  var i = start;
  var neg = false;
  final first = s.codeUnitAt(i);
  if (first == 45) {
    neg = true;
    i++;
  } else if (first == 43) {
    i++;
  }
  var val = 0;
  while (i < n) {
    val = val * 10 + (s.codeUnitAt(i) - 48);
    i++;
  }
  return neg ? -val : val;
}

/// Computes the decimal coefficient and exponent of the specified positive
/// finite number [x] with [p] significant digits (`p` in `[1, 21]`, or
/// `null` / `<= 0` for shortest representation).
///
/// For example, `formatDecimalParts(1.23)` returns `('123', 0)`.
(String, int)? formatDecimalParts(double x, [int? p]) {
  if (!x.isFinite || x == 0) return null;
  final s = (p != null && p > 0)
      ? x.toStringAsExponential(p - 1)
      : x.toStringAsExponential();
  final i = s.indexOf('e');
  final exp = parseExponentAt(s, i + 1);
  // The string returned by toStringAsExponential either has the form
  // \d\.\d+e[-+]\d+ (e.g., 1.2e+3) or \de[-+]\d+ (e.g., 1e+3).
  if (i == 1) {
    return (s.substring(0, 1), exp);
  }
  return ('${s[0]}${s.substring(2, i)}', exp);
}
