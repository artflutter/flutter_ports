// Original code, not ported from Chart.js: JS number coercion as in V8.

/// The JavaScript coercions `ToNumber`, `ToBoolean` and `ToString`, the
/// globals `parseFloat`, `isNaN` and `isFinite`, `Number::toString`, the
/// form `value || 0`, the operator `+` and the relational comparison `a < b`
/// ([jsLessThan], Chart.js ADR 0036) over the Dart values that stand for
/// JavaScript values (Chart.js ADR 0032).
///
/// The value mapping: `null` is JS `null`, [undefined] is JS `undefined`
/// (Chart.js ADR 0006), `bool` is a boolean, `num` is a number, `String` is a
/// string, `List` is an array, `Map` is a plain object, `DateTime` is a
/// `Date` (Chart.js ADR 0024) and any other object is an object whose
/// `toString()` is its primitive value.
///
/// Dart `RegExp` follows ECMAScript: `\s` is `StrWhiteSpaceChar`, the white
/// space that `ToNumber` and `parseFloat` skip. `String.trim` differs: it
/// also removes U+0085.
library;

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

/// ECMAScript `ToNumber(value)`, the coercion of unary `+` and `Number()`.
///
/// A `DateTime` is a JS `Date`: its time value (Chart.js ADR 0024).
double jsToNumber(Object? value) => switch (value) {
  final double d => d,
  final num n => n.toDouble(),
  null => 0,
  Undefined() => double.nan,
  final bool b => b ? 1 : 0,
  final String s => _stringToNumber(s),
  final DateTime d => d.millisecondsSinceEpoch.toDouble(),
  _ => _stringToNumber(jsToString(value)),
};

/// The global `parseFloat(value)`: the longest decimal prefix of
/// `ToString(value)` after leading white space, or NaN.
double jsParseFloat(Object? value) {
  // String(-0) is '0'. String(x) reads back as x for every other number.
  if (value is num) return value == 0 ? 0 : value.toDouble();
  final match = _decimalPrefix.firstMatch(jsToString(value));
  return match == null ? double.nan : _decimalValue(match[1]!);
}

/// The global `isNaN(value)`: whether `ToNumber(value)` is NaN. For a
/// `double`, `x.isNaN` is the same test.
bool jsIsNaN(Object? value) => jsToNumber(value).isNaN;

/// The global `isFinite(value)`: whether `ToNumber(value)` is finite.
bool jsIsFinite(Object? value) => jsToNumber(value).isFinite;

/// ECMAScript `ToBoolean(value)`, the test of `if (value)`, `!value`,
/// `value || d` and `value && d`.
///
/// False for `null`, [undefined], `false`, `0`, `-0`, NaN and `''`. True for
/// every other value, also for an empty `List` or `Map`.
bool jsTruthy(Object? value) => switch (value) {
  null || Undefined() => false,
  final bool b => b,
  final num n => n != 0 && !n.isNaN,
  final String s => s.isNotEmpty,
  _ => true,
};

/// The JS form `value || 0` before arithmetic, for example
/// `options.radius || 0` (element.point.ts:83-85) and `options.offset || 0`
/// (element.arc.ts:472-473).
///
/// A falsy value ([jsTruthy]) gives 0. Another value gives its `ToNumber`
/// ([jsToNumber]), which the arithmetic after the read applies. Thus a
/// truthy value that is not a number, for example `'a'`, gives NaN.
double jsOrZero(Object? value) => jsTruthy(value) ? jsToNumber(value) : 0;

/// The JS operator `a + b` (`ApplyStringOrNumericBinaryOperator`,
/// ECMAScript 13.15.3) on two values of the value mapping, for example the
/// sum of a raw option value and a number:
/// `getTickMarkLength(options) + titleHeight` (core.scale.js:649).
///
/// `ToPrimitive` gives a string for a `String`, a `List`, a `Map`, a
/// `DateTime` (a JS `Date` with the hint `default`) and the other objects.
/// When one operand gives a string, `+` joins the [jsToString] of the two
/// operands: `100 + '5'` gives `'1005'`, and `'8' + 0` gives `'80'`. Else
/// `+` adds the [jsToNumber] of the two operands: `true + null` gives 1.
///
/// The result is a `double` or a `String`. A caller that uses the result as
/// a number applies [jsToNumber] to it, as the JS arithmetic or the canvas
/// call after the `+` does. Two doubles take the fast path: their sum.
Object jsAdd(Object? a, Object? b) {
  if (a is double && b is double) return a + b;
  return _isNumberPrimitive(a) && _isNumberPrimitive(b)
      ? jsToNumber(a) + jsToNumber(b)
      : jsToString(a) + jsToString(b);
}

/// Whether `ToPrimitive(value)` is not a string: `null`, [undefined], a
/// boolean or a number.
bool _isNumberPrimitive(Object? value) =>
    value == null || value is Undefined || value is bool || value is num;

/// The JavaScript relational comparison `a < b` (ECMAScript IsLessThan):
/// two numbers compare as numbers, two strings by their code units, and
/// other values by the `ToNumber` of their `ToPrimitive` with the hint
/// `number`. `a > b` is `jsLessThan(b, a)` (Chart.js ADR 0036).
bool jsLessThan(Object? a, Object? b) {
  if (a is num && b is num) return a < b;
  final pa = _toPrimitiveNumber(a);
  final pb = _toPrimitiveNumber(b);
  if (pa is String && pb is String) return pa.compareTo(pb) < 0;
  return jsToNumber(pa) < jsToNumber(pb);
}

/// `ToPrimitive(value, number)`: a `DateTime` (a JS `Date`) gives its time
/// value (`valueOf`); another object gives its [jsToString]. Thus an array
/// that contains a `DateTime` gives the `Date.prototype.toString` text of
/// that item: `[new Date(0)] < 'A'` is false.
Object? _toPrimitiveNumber(Object? value) => switch (value) {
  null || Undefined() || bool() || num() || String() => value,
  final DateTime date => jsToNumber(date),
  _ => jsToString(value),
};

/// ECMAScript `ToString(value)`, the coercion of `'' + value`, of a template
/// literal and of `String(value)`.
///
/// A number gives [jsNumberToString]. An array gives the join of its elements
/// with `,`, where `null` and [undefined] are empty. A cyclic array recurses
/// without end: chart data has no such array. A `Map` gives
/// `'[object Object]'`. A `DateTime` (a JS `Date`, Chart.js ADR 0024) gives
/// the text of `Date.prototype.toString` ([_dateToString]). Any other object
/// gives its `toString()`, which is `'undefined'` for [undefined]. A
/// function value (a Dart closure or a
/// `JsFunction`) and a Dart object that stands for a JS object, for example
/// an element, give their Dart text, where JavaScript gives the source of
/// the function or `'[object Object]'` (differences.md row
/// `js-semantics-function-source`).
String jsToString(Object? value) => switch (value) {
  null => 'null',
  final num n => jsNumberToString(n),
  final List<Object?> list =>
    list.map((e) => e == null || e is Undefined ? '' : jsToString(e)).join(','),
  Map<Object?, Object?>() => '[object Object]',
  final DateTime date => _dateToString(date),
  // DIVERGES(chartjs): js-semantics-function-source, the Dart toString().
  _ => value.toString(),
};

/// The weekday names of `DateString` (ECMAScript 21.4.4.41.2), from Monday,
/// the [DateTime.weekday] 1.
const List<String> _weekdayNames = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// The month names of `DateString` (ECMAScript 21.4.4.41.2), from January,
/// the [DateTime.month] 1.
const List<String> _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// `Date.prototype.toString` (ECMAScript 21.4.4.41, `ToDateString`): the
/// local time of [date] in the zone of the platform, as the engine uses its
/// local zone, for example
/// `'Thu Jan 01 1970 00:00:00 GMT+0000 (Coordinated Universal Time)'`.
///
/// The text is `DateString`, `TimeString` and `TimeZoneString`: the weekday,
/// the month, the day, the year with 4 digits or more (`'-0001'` for the
/// year -1, `'10000'`), the time, the offset as `GMT` with a sign and the
/// hours and minutes, and the zone name ([_zoneName]). The seconds of an
/// offset fall away, as in V8.
///
/// The zone name changes the width of the text. A `Date` label of a
/// category scale is measured through this text (`_computeLabelSizes`,
/// core.scale.js), so the name reaches the label sizes, the label rotation,
/// the scale size and the chart area (Chart.js ADR 0034). The offsets of
/// the platform follow the differences.md row `platform-date-local-offset`.
String _dateToString(DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  final year = local.year;
  final yearText =
      '${year < 0 ? '-' : ''}${year.abs().toString().padLeft(4, '0')}';
  final offset = local.timeZoneOffset.inMinutes;
  final offsetText =
      '${offset < 0 ? '-' : '+'}${two(offset.abs() ~/ 60)}'
      '${two(offset.abs() % 60)}';
  final name = _zoneName(local);
  return '${_weekdayNames[local.weekday - 1]} ${_monthNames[local.month - 1]} '
      '${two(local.day)} $yearText ${two(local.hour)}:${two(local.minute)}:'
      '${two(local.second)} GMT$offsetText${name == null ? '' : ' ($name)'}';
}

/// Whether the code runs compiled with dart2js or dart2wasm.
const bool _onWeb = bool.fromEnvironment('dart.library.js_interop');

/// The zone name of `TimeZoneString` for the local time [local], as V8 gives
/// it: the long ICU name, for example `'Coordinated Universal Time'`, or
/// `null` for no name.
///
/// dart2js and dart2wasm give the name in the parentheses of the
/// `Date.prototype.toString` of the engine as [DateTime.timeZoneName]. On
/// the VM, the name is the abbreviation of the operating system, for
/// example `'UTC'`, `'GMT'` or `'CET'`, or on Windows the name of the
/// Windows zone, `'Coordinated Universal Time'` for UTC. An abbreviation of
/// another zone does not give the ICU name: `'GMT'` in Europe/London is
/// `'Greenwich Mean Time'` in 2024 and `'British Summer Time'` in 1906 in
/// V8. Thus on the VM, only UTC gives the name. Other zones give no name
/// (differences.md row `platform-date-zone-name`).
String? _zoneName(DateTime local) {
  final name = local.timeZoneName;
  if (_onWeb) return name.isEmpty ? null : name;
  // DIVERGES(chartjs): platform-date-zone-name, no ICU name on the VM.
  final utc =
      local.timeZoneOffset == Duration.zero &&
      (name == 'UTC' || name == 'Coordinated Universal Time');
  return utc ? 'Coordinated Universal Time' : null;
}

/// ECMAScript `Number::toString(x, 10)`, the string of `String(x)` and
/// `'' + x` for a number: `'12'`, `'0.000001'`, `'1e+21'`, `'1.5e-7'`, and
/// `'0'` for both `0` and `-0`.
///
/// Dart's `toString()` gives the shortest digits that read back as [x] and
/// the notation of ECMAScript on the VM, dart2js and dart2wasm. Only the VM
/// and dart2wasm add `.0` to an integral value in plain notation, and give
/// `'-0.0'` for -0.
String jsNumberToString(num x) {
  final d = x.toDouble();
  if (d == 0) return '0';
  // Below 2^53 the shortest round-trip digits of an integral value are its
  // exact digits. Above it, JavaScript pads the shortest digits with zeros
  // (2^60 gives '1152921504606847000'), so int.toString gives other digits.
  // NaN and the infinities fail the first test.
  if (d == d.truncateToDouble() && d.abs() < 9007199254740992) {
    return d.toInt().toString();
  }
  final s = d.toString();
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/// `StrDecimalLiteral` (ECMAScript 7.1.4.1).
const String _decimal =
    r'[+-]?(?:Infinity|(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?)';

/// `StringNumericLiteral`: white space, then a decimal literal, a
/// `0x`/`0o`/`0b` literal or nothing, then white space. The digit class of
/// group 3 is wide. `BigInt.tryParse` rejects a digit outside the radix.
/// The `0x`/`0o`/`0b` literals cost one group and four lines. They keep a
/// data string such as `'0x10'` at 16, as `Number('0x10')` gives, and not
/// NaN, which removes the data point.
final RegExp _literal = RegExp(
  '^\\s*(?:($_decimal)|0([xXoObB])([0-9a-fA-F]+))?\\s*\$',
);

/// The prefix that `parseFloat` reads.
final RegExp _decimalPrefix = RegExp('^\\s*($_decimal)');

/// `StringToNumber(string)` (ECMAScript 7.1.4.1.1).
double _stringToNumber(String string) {
  final plain = _plainDecimal(string);
  if (plain != null) return plain;
  final match = _literal.firstMatch(string);
  if (match == null) return double.nan;
  if (match[1] != null) return _decimalValue(match[1]!);
  if (match[2] == null) return 0; // Only white space.
  final radix = switch (match[2]!.toLowerCase()) {
    'x' => 16,
    'o' => 8,
    _ => 2,
  };
  // BigInt.toDouble rounds to nearest, ties to even, as JavaScript does.
  return BigInt.tryParse(match[3]!, radix: radix)?.toDouble() ?? double.nan;
}

/// The value of a string that matches `StrDecimalLiteral`. `double.parse`
/// rounds correctly on every platform.
double _decimalValue(String literal) => literal.endsWith('Infinity')
    ? (literal.startsWith('-') ? double.negativeInfinity : double.infinity)
    : double.parse(literal);

/// The value of [string] when it has 1 to 64 characters, all of them in
/// `0-9 . + - e E`, and [double.tryParse] reads it. Else null, and the
/// `StringNumericLiteral` RegExp decides.
///
/// This path gives the same result as the RegExp path, because over this
/// alphabet each grammar of [double.tryParse] is `StrDecimalLiteral` without
/// `Infinity`: on the VM, the grammar of the Dart double literal; on dart2js
/// and dart2wasm, the guard RegExp
/// `[+-]?(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?` before `parseFloat`.
/// All of them round correctly. A string that the grammar rejects gives
/// null. The limit of 64 characters only bounds the scan.
double? _plainDecimal(String string) {
  final length = string.length;
  if (length == 0 || length > 64) return null;
  for (var i = 0; i < length; i++) {
    final allowed = switch (string.codeUnitAt(i)) {
      >= 0x30 && <= 0x39 => true, // 0-9
      0x2B || 0x2D || 0x2E || 0x45 || 0x65 => true, // + - . E e
      _ => false,
    };
    if (!allowed) return null;
  }
  return double.tryParse(string);
}
