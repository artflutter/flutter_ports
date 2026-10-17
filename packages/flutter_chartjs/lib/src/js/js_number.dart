// Original code, not ported from Chart.js: JS number coercion as in V8.

/// The JavaScript number coercions (`ToNumber`, `parseFloat`, `isNaN`,
/// `isFinite`) over the Dart values that stand for JavaScript values
/// (Chart.js ADR 0002, porting-flow.md 2.3).
///
/// The value mapping: `null` is JS `null`, `bool` is a boolean, `num` is a
/// number, `String` is a string, `List` is an array, `Symbol` is a symbol and
/// any other object is an object whose `toString()` is its primitive value.
/// Dart has no `undefined`; until the options ADR adds its sentinel, a caller
/// that reads an absent key passes `double.nan` or tests the key itself.
library;

/// ECMAScript `ToNumber(value)`, the coercion of unary `+` and `Number()`.
///
/// Throws an [ArgumentError] for a [Symbol], where JavaScript throws a
/// `TypeError`.
double jsToNumber(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value == null) return 0;
  if (value is bool) return value ? 1 : 0;
  if (value is String) return _stringToNumber(value);
  return _stringToNumber(_toPrimitiveString(value));
}

/// The global `parseFloat(value)`: the longest decimal prefix of
/// `String(value)` after leading white space, or NaN.
///
/// Throws an [ArgumentError] for a [Symbol], where JavaScript throws a
/// `TypeError`.
double jsParseFloat(Object? value) {
  if (value is num) {
    // String(-0) is '0'; String(x) reads back as x for every other number.
    return value == 0 ? 0 : value.toDouble();
  }
  final string = switch (value) {
    null => 'null',
    final bool b => '$b',
    final String s => s,
    final Object o => _toPrimitiveString(o),
  };
  final match = _decimalPrefix.matchAsPrefix(string, _skipWhiteSpace(string));
  if (match == null) return double.nan;
  return _decimalValue(match[0]!);
}

/// The global `isNaN(value)`: whether `ToNumber(value)` is NaN.
bool jsIsNaN(Object? value) => jsToNumber(value).isNaN;

/// The global `isFinite(value)`: whether `ToNumber(value)` is finite.
bool jsIsFinite(Object? value) => jsToNumber(value).isFinite;

/// `StrDecimalLiteral` (ECMAScript 7.1.4.1), without white space.
final RegExp _decimalPrefix = RegExp(
  r'[+-]?(?:Infinity|(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?)',
);
final RegExp _decimalLiteral = RegExp(
  r'^[+-]?(?:Infinity|(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?)$',
);
final RegExp _hexLiteral = RegExp(r'^0[xX]([0-9a-fA-F]+)$');
final RegExp _octalLiteral = RegExp(r'^0[oO]([0-7]+)$');
final RegExp _binaryLiteral = RegExp(r'^0[bB]([01]+)$');

/// `StringToNumber(string)` (ECMAScript 7.1.4.1.1).
double _stringToNumber(String string) {
  var end = string.length;
  while (end > 0 && _isWhiteSpace(string.codeUnitAt(end - 1))) {
    end--;
  }
  final start = end == 0 ? 0 : _skipWhiteSpace(string);
  final literal = string.substring(start, end);
  if (literal.isEmpty) return 0;
  if (_decimalLiteral.hasMatch(literal)) return _decimalValue(literal);
  for (final (pattern, radix) in [
    (_hexLiteral, 16),
    (_octalLiteral, 8),
    (_binaryLiteral, 2),
  ]) {
    final match = pattern.firstMatch(literal);
    // BigInt.toDouble rounds to nearest, ties to even, as JavaScript does.
    if (match != null) return BigInt.parse(match[1]!, radix: radix).toDouble();
  }
  return double.nan;
}

/// The value of a string that matches `StrDecimalLiteral`.
double _decimalValue(String literal) {
  if (literal.endsWith('Infinity')) {
    return literal.startsWith('-') ? double.negativeInfinity : double.infinity;
  }
  // double.parse rounds correctly on every platform.
  return double.parse(literal);
}

/// The index of the first character of [string] that is not
/// `StrWhiteSpaceChar`.
int _skipWhiteSpace(String string) {
  var start = 0;
  while (start < string.length && _isWhiteSpace(string.codeUnitAt(start))) {
    start++;
  }
  return start;
}

/// `StrWhiteSpaceChar`: `WhiteSpace` or `LineTerminator` (ECMAScript 12.2,
/// 12.3). Not `String.trim`, which also removes U+0085.
bool _isWhiteSpace(int c) =>
    c == 0x09 ||
    c == 0x0A ||
    c == 0x0B ||
    c == 0x0C ||
    c == 0x0D ||
    c == 0x20 ||
    c == 0xA0 ||
    c == 0x1680 ||
    (c >= 0x2000 && c <= 0x200A) ||
    c == 0x2028 ||
    c == 0x2029 ||
    c == 0x202F ||
    c == 0x205F ||
    c == 0x3000 ||
    c == 0xFEFF;

/// The string that `ToPrimitive` gives for an object: the join of an array,
/// else `toString()`.
///
/// Numbers in an array use Dart's `toString()`. It differs from JavaScript
/// `Number.prototype.toString` only in a trailing `.0` and in `-0.0`, and no
/// numeric parse of the result sees either difference.
String _toPrimitiveString(Object value) => switch (value) {
  final Symbol s => throw ArgumentError.value(
    s,
    'value',
    'Cannot convert a Symbol value to a number or string',
  ),
  final List<Object?> list => list.map(_joinElement).join(','),
  _ => value.toString(),
};

/// `ToString(element)` inside `Array.prototype.join`, where null is empty.
String _joinElement(Object? element) => switch (element) {
  null => '',
  final num n => n == 0 ? '0' : n.toDouble().toString(),
  final Object o => o is String || o is bool ? '$o' : _toPrimitiveString(o),
};
