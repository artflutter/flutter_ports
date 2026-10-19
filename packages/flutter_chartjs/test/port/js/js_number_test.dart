// Original code, not ported from Chart.js: tests of lib/src/js/js_number.dart.
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:test/test.dart';

import 'number_to_string_reference.dart';

// The expected values come from Node.js v24.12.0 (V8 13.6): Number(s) and
// parseFloat(s) for each string, and the other results that the tests name.

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
  ('1e-400', 0, 0),
  ('+.5', 0.5, 0.5),
  ('1.e5', 100000, 100000),
  ('e5', _nan, _nan),
  ('+1e5', 100000, 100000),
  ('-.5e-0', -0.5, -0.5),
  ('-0.0e5', -0, -0),
  ('1.5e+3x', _nan, 1500),
  ('0012.50', 12.5, 12.5),
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
      expect(jsToNumber([undefined]), _isSameNumber(0));
      expect(jsToNumber([undefined, undefined]), isNaN);
      expect(jsToNumber([true]), isNaN);
      expect(jsToNumber([-0.0]), _isSameNumber(0));
    });

    test('reads decimal strings as StrDecimalLiteral does', () {
      // The VM checks every string of length 0-5 over the alphabet of the
      // fast path (813,616 strings). The web legs check length 0-3 and a
      // sample of length 4-8, to keep test:web fast.
      final strings = <String>[
        ..._allStrings(_isWeb ? 3 : 5),
        ..._sampleStrings(Random(5), 2000, 4, 8),
        ..._longDecimals(Random(7), 300),
        '1' * 64,
        '1' * 65,
        '9' * 400,
        '${'0' * 70}1.5',
        '1e400',
        '1e-400',
        '-0',
        '+.5',
        '1.e5',
        '.',
        'e5',
        '1e',
        '+-1',
      ];
      final mismatches = <String>[
        for (final string in strings)
          if (!_sameBits(jsToNumber(string), _decimalOracle(string)))
            '${_quote(string)}: ${jsToNumber(string)}',
      ];
      expect(mismatches, isEmpty);
    });

    test('gives NaN for undefined', () {
      expect(jsToNumber(undefined), isNaN);
    });

    test('gives NaN for other objects', () {
      expect(jsToNumber(<String, Object?>{}), isNaN);
      expect(jsToNumber(Object()), isNaN);
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
      expect(jsParseFloat(undefined), isNaN);
      expect(jsParseFloat(true), isNaN);
      expect(jsParseFloat(<String, Object?>{}), isNaN);
      expect(jsParseFloat(-0.0), _isSameNumber(0));
      expect(jsParseFloat(1e21), 1e21);
      expect(jsParseFloat(1e-7), 1e-7);
      expect(jsParseFloat([1.5, 2]), 1.5);
      expect(jsParseFloat(<Object?>[]), isNaN);
      expect(jsParseFloat([-0.0]), _isSameNumber(0));
    });
  });

  group('jsIsNaN and jsIsFinite', () {
    test('coerce their argument', () {
      expect(jsIsNaN('abc'), isTrue);
      expect(jsIsNaN('12'), isFalse);
      expect(jsIsNaN(null), isFalse);
      expect(jsIsNaN(undefined), isTrue);
      expect(jsIsFinite(undefined), isFalse);
      expect(jsIsFinite('Infinity'), isFalse);
      expect(jsIsFinite(' 12 '), isTrue);
      expect(jsIsFinite(null), isTrue);
      expect(jsIsFinite(double.nan), isFalse);
    });
  });

  group('jsTruthy', () {
    test('is false for the falsy values', () {
      for (final value in <Object?>[
        null,
        undefined,
        false,
        0,
        0.0,
        -0.0,
        double.nan,
        '',
      ]) {
        expect(jsTruthy(value), isFalse, reason: '$value');
      }
    });

    test('is true for other values', () {
      for (final value in <Object?>[
        true,
        1,
        -1,
        0.5,
        double.infinity,
        double.negativeInfinity,
        double.minPositive,
        '0',
        'false',
        ' ',
        <Object?>[],
        <String, Object?>{},
        Object(),
        Symbol.empty,
      ]) {
        expect(jsTruthy(value), isTrue, reason: '$value');
      }
    });
  });

  group('jsOrZero', () {
    test('gives 0 for a falsy value', () {
      for (final value in <Object?>[
        undefined,
        null,
        false,
        0,
        -0.0,
        double.nan,
        '',
      ]) {
        expect(jsOrZero(value), _isSameNumber(0), reason: '$value');
      }
    });

    test('gives the ToNumber of a truthy value', () {
      expect(jsOrZero(2), 2.0);
      expect(jsOrZero(-1.5), -1.5);
      expect(jsOrZero('3'), 3.0);
      expect(jsOrZero(true), 1.0);
      expect(jsOrZero(double.infinity), double.infinity);
      expect(jsOrZero('a'), isNaN);
      expect(jsOrZero(<Object?>[]), 0.0);
    });
  });

  group('jsToString', () {
    test('converts primitive values', () {
      expect(jsToString(null), 'null');
      expect(jsToString(undefined), 'undefined');
      expect(jsToString(true), 'true');
      expect(jsToString(false), 'false');
      expect(jsToString('a b'), 'a b');
      expect(jsToString(12), '12');
      expect(jsToString(12.0), '12');
      expect(jsToString(-0.0), '0');
      expect(jsToString(1e21), '1e+21');
    });

    test('joins arrays, where null and undefined are empty', () {
      expect(jsToString(<Object?>[]), '');
      expect(jsToString([1, undefined, null, 2]), '1,,,2');
      expect(jsToString([undefined, 1.5, -0.0, 1e21]), ',1.5,0,1e+21');
      expect(
        jsToString([
          1,
          [2, 3],
          'a',
          true,
        ]),
        '1,2,3,a,true',
      );
    });

    test('gives [object Object] for a plain object', () {
      expect(jsToString(<String, Object?>{'a': 1}), '[object Object]');
    });
  });

  group('jsNumberToString', () {
    final pairs = [
      for (final line in numberToStringReference.split('\n'))
        if (line.isNotEmpty) line.split(' '),
    ];

    test('has the generated number of inputs', () {
      expect(pairs, hasLength(10000));
    });

    test('equals V8 $numberToStringReferenceV8 on '
        '$numberToStringReferenceArch String(x) for every input', () {
      final mismatches = <String>[];
      for (final [input, expected] in pairs) {
        final actual = jsNumberToString(_fromHex(input));
        if (actual != expected) {
          mismatches.add('$input: expected $expected, got $actual');
        }
      }
      expect(mismatches, isEmpty);
    });

    test('formats the notation boundaries', () {
      const cases = <(num, String)>[
        (0, '0'),
        (-0.0, '0'),
        (double.nan, 'NaN'),
        (double.infinity, 'Infinity'),
        (double.negativeInfinity, '-Infinity'),
        (12, '12'),
        (12.0, '12'),
        (-12.5, '-12.5'),
        (0.1 + 0.2, '0.30000000000000004'),
        (0.000001, '0.000001'),
        (0.0000001, '1e-7'),
        (-0.00000015, '-1.5e-7'),
        (1e20, '100000000000000000000'),
        (123456789012345680000.0, '123456789012345680000'),
        (1e21, '1e+21'),
        (1.5e21, '1.5e+21'),
        (double.maxFinite, '1.7976931348623157e+308'),
        (double.minPositive, '5e-324'),
        (9007199254740991, '9007199254740991'),
        (-9007199254740991, '-9007199254740991'),
        (9007199254740992.0, '9007199254740992'),
        (-9007199254740992.0, '-9007199254740992'),
        (18014398509481984.0, '18014398509481984'),
        (1152921504606846976.0, '1152921504606847000'),
        (999999999999999900000.0, '999999999999999900000'),
        (-1e20, '-100000000000000000000'),
        (4503599627370495.5, '4503599627370495.5'),
        (255, '255'),
        (255.0, '255'),
        (-1.0, '-1'),
      ];
      for (final (x, expected) in cases) {
        expect(jsNumberToString(x), expected, reason: '$x');
      }
    });
  });
}

/// Whether the test runs on dart2js or dart2wasm.
const bool _isWeb = bool.fromEnvironment('dart.library.js_interop');

/// The characters of the fast path of `StringToNumber`.
const String _alphabet = '0123456789.+-eE';

/// `StrDecimalLiteral` alone, without white space.
final RegExp _strDecimalLiteral = RegExp(
  r'^[+-]?(?:Infinity|(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?)$',
);

/// `Number(string)` for a string without white space and without a
/// `0x`/`0o`/`0b` prefix: 0 for `''`, the value of a `StrDecimalLiteral`,
/// else NaN. This oracle does not use the code of `jsToNumber`.
double _decimalOracle(String string) {
  if (string.isEmpty) return 0;
  if (!_strDecimalLiteral.hasMatch(string)) return double.nan;
  if (string.endsWith('Infinity')) {
    return string.startsWith('-') ? double.negativeInfinity : double.infinity;
  }
  return double.parse(string);
}

/// Whether [a] and [b] have the same Float64 bits, or are both NaN.
bool _sameBits(double a, double b) {
  if (a.isNaN || b.isNaN) return a.isNaN && b.isNaN;
  final data = ByteData(16)
    ..setFloat64(0, a)
    ..setFloat64(8, b);
  return data.getUint32(0) == data.getUint32(8) &&
      data.getUint32(4) == data.getUint32(12);
}

/// Every string of length 0 to [maxLength] over [_alphabet].
Iterable<String> _allStrings(int maxLength) sync* {
  var level = [''];
  yield '';
  for (var length = 1; length <= maxLength; length++) {
    level = [
      for (final prefix in level)
        for (var i = 0; i < _alphabet.length; i++) prefix + _alphabet[i],
    ];
    yield* level;
  }
}

/// [count] random strings over [_alphabet], of length [min] to [max].
Iterable<String> _sampleStrings(Random random, int count, int min, int max) =>
    Iterable.generate(count, (_) {
      final length = min + random.nextInt(max - min + 1);
      return String.fromCharCodes([
        for (var i = 0; i < length; i++)
          _alphabet.codeUnitAt(random.nextInt(_alphabet.length)),
      ]);
    });

/// [count] random decimal literals of 1 to 100 digits, with a sign, a point
/// and an exponent at random. Some are longer than 64 characters.
Iterable<String> _longDecimals(Random random, int count) =>
    Iterable.generate(count, (_) {
      String digits(int length) => String.fromCharCodes([
        for (var i = 0; i < length; i++) 0x30 + random.nextInt(10),
      ]);
      final buffer = StringBuffer(['', '+', '-'][random.nextInt(3)])
        ..write(digits(1 + random.nextInt(60)));
      if (random.nextBool()) buffer.write('.${digits(random.nextInt(40))}');
      if (random.nextBool()) {
        buffer
          ..write('e${['', '+', '-'][random.nextInt(3)]}')
          ..write(digits(1 + random.nextInt(3)));
      }
      return buffer.toString();
    });

/// The double with the 16 hex digits [bits].
double _fromHex(String bits) {
  final words = ByteData(8)
    ..setUint32(0, int.parse(bits.substring(0, 8), radix: 16))
    ..setUint32(4, int.parse(bits.substring(8), radix: 16));
  return words.getFloat64(0);
}

/// [string] as a JavaScript string literal with escapes, for test names.
String _quote(String string) {
  final escaped = string.runes.map((rune) {
    if (rune >= 0x20 && rune < 0x7f) return String.fromCharCode(rune);
    return '\\u${rune.toRadixString(16).padLeft(4, '0')}';
  }).join();
  return "'$escaped'";
}
