// Original code, not ported from Chart.js: tests of lib/src/js/js_number.dart.
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:test/test.dart';

// The expected values come from Node.js v24.12.0 (V8 13.6): Number(s) and
// parseFloat(s) for each string.

/// Matches a double with the same value as [expected], where -0 differs from
/// +0 and NaN matches NaN, as `Object.is` does.
Matcher _isSameNumber(double expected) => predicate<double>(
  (actual) => expected.isNaN
      ? actual.isNaN
      : actual == expected && actual.isNegative == expected.isNegative,
  'Object.is($expected)',
);

const double _nan = double.nan;
const double _inf = double.infinity;

/// JavaScript `StrWhiteSpaceChar` characters, with both ends of U+2000-U+200A.
final String _whiteSpace = String.fromCharCodes(const [
  0x09, 0x0B, 0x0C, 0x20, 0xA0, 0xFEFF, 0x1680, 0x2000, 0x200A, 0x202F, //
  0x205F, 0x3000, 0x0A, 0x0D, 0x2028, 0x2029,
]);

/// A string, `Number(string)` and `parseFloat(string)`.
final List<(String, double, double)> _strings = [
  ('', 0, _nan),
  (' ', 0, _nan),
  ('123', 123, 123),
  (' 12 ', 12, 12),
  ('12px', _nan, 12),
  ('0x10', 16, 0),
  ('0X1f', 31, 0),
  ('0o17', 15, 0),
  ('0b101', 5, 0),
  ('-0x10', _nan, -0),
  ('0x', _nan, 0),
  ('1e3', 1000, 1000),
  ('1E-3', 0.001, 0.001),
  ('.5', 0.5, 0.5),
  ('5.', 5, 5),
  ('.', _nan, _nan),
  ('+.5e-3', 0.0005, 0.0005),
  ('-0', -0, -0),
  ('+Infinity', _inf, _inf),
  ('-Infinity', -_inf, -_inf),
  ('Infinity', _inf, _inf),
  ('infinity', _nan, _nan),
  ('NaN', _nan, _nan),
  ('1_000', _nan, 1),
  ('00012', 12, 12),
  ('1e', _nan, 1),
  ('1e+', _nan, 1),
  ('--1', _nan, _nan),
  ('+-1', _nan, _nan),
  ('${_whiteSpace}42$_whiteSpace', 42, 42),
  ('\u008542', _nan, _nan),
  ('\u180E42', _nan, _nan),
  ('1,2', _nan, 1),
  ('0x20000000000005', 9007199254740996, 0),
  ('1e400', _inf, _inf),
  ('-1e400', -_inf, -_inf),
  ('2e-400', 0, 0),
  ('0.1e1', 1, 1),
  ('\u0663', _nan, _nan),
];

void main() {
  group('jsToNumber', () {
    for (final (string, number, _) in _strings) {
      test('Number(${_quote(string)}) is $number', () {
        expect(jsToNumber(string), _isSameNumber(number));
      });
    }

    test('converts null, booleans and numbers', () {
      expect(jsToNumber(null), _isSameNumber(0));
      expect(jsToNumber(true), 1);
      expect(jsToNumber(false), _isSameNumber(0));
      expect(jsToNumber(7), 7);
      expect(jsToNumber(-0.0), _isSameNumber(-0));
    });

    test('converts arrays through their join', () {
      expect(jsToNumber(<Object?>[]), _isSameNumber(0));
      expect(jsToNumber([5]), 5);
      expect(
        jsToNumber([
          [5],
        ]),
        5,
      );
      expect(jsToNumber([1, 2]), isNaN);
      expect(jsToNumber([null]), _isSameNumber(0));
      expect(jsToNumber([true]), isNaN);
      expect(jsToNumber([-0.0]), _isSameNumber(0));
    });

    test('gives NaN for other objects', () {
      expect(jsToNumber(<String, Object?>{}), isNaN);
      expect(jsToNumber(Object()), isNaN);
    });

    test('throws for a symbol, as JavaScript does', () {
      expect(() => jsToNumber(Symbol.empty), throwsArgumentError);
    });
  });

  group('jsParseFloat', () {
    for (final (string, _, number) in _strings) {
      test('parseFloat(${_quote(string)}) is $number', () {
        expect(jsParseFloat(string), _isSameNumber(number));
      });
    }

    test('converts other values to strings first', () {
      expect(jsParseFloat(null), isNaN);
      expect(jsParseFloat(true), isNaN);
      expect(jsParseFloat(<String, Object?>{}), isNaN);
      expect(jsParseFloat(-0.0), _isSameNumber(0));
      expect(jsParseFloat(1e21), 1e21);
      expect(jsParseFloat(1e-7), 1e-7);
      expect(jsParseFloat([1.5, 2]), 1.5);
      expect(jsParseFloat(<Object?>[]), isNaN);
      expect(jsParseFloat([-0.0]), _isSameNumber(0));
    });

    test('throws for a symbol, as JavaScript does', () {
      expect(() => jsParseFloat(Symbol.empty), throwsArgumentError);
    });
  });

  group('jsIsNaN and jsIsFinite', () {
    test('coerce their argument', () {
      expect(jsIsNaN('abc'), isTrue);
      expect(jsIsNaN('12'), isFalse);
      expect(jsIsNaN(null), isFalse);
      expect(jsIsFinite('Infinity'), isFalse);
      expect(jsIsFinite(' 12 '), isTrue);
      expect(jsIsFinite(null), isTrue);
      expect(jsIsFinite(double.nan), isFalse);
    });
  });
}

/// [string] as a JavaScript string literal with escapes, for test names.
String _quote(String string) {
  final escaped = string.runes.map((rune) {
    if (rune >= 0x20 && rune < 0x7f) return String.fromCharCode(rune);
    return '\\u${rune.toRadixString(16).padLeft(4, '0')}';
  }).join();
  return "'$escaped'";
}
