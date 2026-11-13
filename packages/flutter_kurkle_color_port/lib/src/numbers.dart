// Original code, not ported from @kurkle/color: the number forms of the color port.

/// The number forms that the JavaScript of @kurkle/color 0.3.2 relies on,
/// in plain Dart: the bitwise `x | 0`, the coercion of an input value to a
/// number, the test `if (x)` of a number and the text of a number in a CSS
/// string. `index.esm.dart` does not export this library.
library;

/// `x | 0` as an `int`: NaN and the infinities give 0, other values
/// truncate toward zero and wrap modulo 2^32 into [-2^31, 2^31).
@pragma('vm:prefer-inline')
int toInt32(double x) {
  // A value in (-2^31 - 1, 2^31) truncates to an int32: no wrap is needed.
  // NaN fails both tests.
  if (x > -2147483649.0 && x < 2147483648.0) return x.toInt();
  if (!x.isFinite) return 0;
  // remainder() is exact; the result has the sign of the truncated value.
  const twoTo32 = 4294967296.0;
  var low = x.truncateToDouble().remainder(twoTo32);
  if (low < 0) low += twoTo32;
  if (low >= 2147483648.0) low -= twoTo32;
  return low.toInt();
}

/// The number of an input value of a color object or list: a number, a
/// `bool` (1 or 0) or a decimal text. Dart `null` (an absent value) and any
/// other value give NaN.
double toNumber(Object? value) => switch (value) {
  final double d => d,
  final num n => n.toDouble(),
  final bool b => b ? 1 : 0,
  final String s => _textNumber(s.trim()),
  _ => double.nan,
};

/// The number of the trimmed text [s]: an empty text is 0, a text that
/// [double.tryParse] does not read is NaN.
double _textNumber(String s) =>
    s.isEmpty ? 0 : (_decimal.hasMatch(s) ? double.parse(s) : double.nan);

/// A decimal number with an optional sign and exponent.
final RegExp _decimal = RegExp(r'^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$');

/// Whether [value] is a number other than 0 and NaN: the test `if (value)`
/// of a number that can be absent.
bool isNonZero(double? value) => value != null && value != 0 && !value.isNaN;

/// The text of the number [x] in a CSS string: a whole number below 2^53
/// without a fraction (`255`, and `0` for -0), any other value as
/// [double.toString].
String numberText(double x) =>
    x == x.truncateToDouble() && x.abs() < 9007199254740992
    ? x.toInt().toString()
    : x.toString();
