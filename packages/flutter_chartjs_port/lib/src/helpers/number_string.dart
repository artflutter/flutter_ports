// Original code, not ported from Chart.js: the text of a number.

/// The text of a number in a label, a key or a message (Chart.js ADR 0176).
library;

/// The text of the number [x], as Chart.js writes a number into a string:
/// `'12'`, `'0.000001'`, `'1e+21'`, `'1.5e-7'`, and `'0'` for both `0` and
/// `-0`.
///
/// Dart's `toString()` gives the shortest digits that read back as [x] and
/// the same notation on the VM, dart2js and dart2wasm. Only the VM and
/// dart2wasm add `.0` to an integral value in plain notation, and give
/// `'-0.0'` for -0. This function removes both.
String numberString(num x) {
  final d = x.toDouble();
  if (d == 0) return '0';
  // Below 2^53 the shortest round-trip digits of an integral value are its
  // exact digits. Above it, Chart.js pads the shortest digits with zeros
  // (2^60 gives '1152921504606847000'), so int.toString gives other digits.
  // NaN and the infinities fail the first test.
  if (d == d.truncateToDouble() && d.abs() < 9007199254740992) {
    return d.toInt().toString();
  }
  final s = d.toString();
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}
