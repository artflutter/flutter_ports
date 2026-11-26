// Original code, not ported from d3-format: twin tests for faster forms.

import 'dart:math' as math;

import 'package:flutter_d3_format_port/d3_format.dart';
import 'package:test/test.dart';

final RegExp _refSpecifierRe = RegExp(
  r'^(?:(.)?([<>=^]))?([+\-( ])?([$#])?(0)?(\d+)?(,)?(\.\d+)?(~)?([a-z%])?$',
  caseSensitive: false,
);

const List<String> _refPrefixes = [
  'y',
  'z',
  'a',
  'f',
  'p',
  'n',
  'µ',
  'm',
  '',
  'k',
  'M',
  'G',
  'T',
  'P',
  'E',
  'Z',
  'Y',
];

FormatSpecifier _referenceSpecifier(String specifier) {
  final m = _refSpecifierRe.firstMatch(specifier);
  if (m == null) throw FormatException('invalid format: $specifier');
  final w = m.group(6);
  final p = m.group(8);
  return FormatSpecifier(
    fill: m.group(1) ?? ' ',
    align: m.group(2) ?? '>',
    sign: m.group(3) ?? '-',
    symbol: m.group(4) ?? '',
    zero: m.group(5) != null,
    width: w == null ? null : int.parse(w),
    comma: m.group(7) != null,
    precision: p == null ? null : int.parse(p.substring(1)),
    trim: m.group(9) != null,
    type: m.group(10) ?? '',
  );
}

String Function(String, int?) _referenceGroup(
  List<int> grouping,
  String thousands,
) {
  return (String value, int? width) {
    if (grouping.isEmpty) return '';
    var i = value.length;
    final t = <String>[];
    var j = 0;
    var g = grouping[0];
    var length = 0;
    while (i > 0 && g > 0) {
      if (width != null && length + g + 1 > width) {
        g = math.max(1, width - length);
      }
      final end = i;
      i -= g;
      t.add(value.substring(i < 0 ? 0 : i, end));
      length += g + 1;
      if (width != null && length > width) break;
      j = (j + 1) % grouping.length;
      g = grouping[j];
    }
    return t.reversed.join(thousands);
  };
}

String Function(String) _referenceNumerals(List<String> numerals) {
  final re = RegExp('[0-9]');
  return (String value) => value.replaceAllMapped(
    re,
    (m) => numerals[m.group(0)!.codeUnitAt(0) - 48],
  );
}

/// Literal unoptimized upstream formatting algorithm for twin verification.
String Function(num) _referenceFormat(
  FormatLocaleDefinition def,
  String specStr,
) {
  final s = _referenceSpecifier(specStr);
  var fill = s.fill;
  var align = s.align;
  final sign = s.sign;
  final symbol = s.symbol;
  var zero = s.zero;
  final width = s.width;
  var comma = s.comma;
  var precision = s.precision;
  var trim = s.trim;
  var type = s.type;

  if (type == 'n') {
    comma = true;
    type = 'g';
  } else if (!formatTypes.containsKey(type)) {
    precision ??= 12;
    trim = true;
    type = 'g';
  }
  if (zero || (fill == '0' && align == '=')) {
    zero = true;
    fill = '0';
    align = '=';
  }

  final group = def.grouping == null || def.thousands == null
      ? null
      : _referenceGroup(def.grouping!, def.thousands!);
  final numerals = def.numerals == null
      ? null
      : _referenceNumerals(def.numerals!);
  final currencyPrefix = def.currency?.$1 ?? '';
  final currencySuffix = def.currency?.$2 ?? '';

  final prefix = symbol == r'$'
      ? currencyPrefix
      : (symbol == '#' &&
            (type == 'b' || type == 'o' || type == 'x' || type == 'X'))
      ? '0${type.toLowerCase()}'
      : '';
  final suffix = symbol == r'$'
      ? currencySuffix
      : (type == '%' || type == 'p')
      ? def.percent
      : '';

  final fn = formatTypes[type]!;
  final maybeSuffix = 'defgprs%'.contains(type);
  final clamped = precision == null
      ? 6
      : 'gprs'.contains(type)
      ? math.max(1, math.min(21, precision))
      : math.max(0, math.min(20, precision));

  return (num raw) {
    final d = raw.toDouble();
    var valueNegative = d < 0 || (d == 0 && d.isNegative);
    final isNan = d.isNaN;
    var value = isNan ? def.nan : fn(d == 0 ? 0.0 : d.abs(), clamped);
    if (trim) value = formatTrim(value);
    final parsed = double.tryParse(value);
    if (valueNegative && parsed == 0 && sign != '+') valueNegative = false;
    final valuePrefix =
        (valueNegative
            ? (sign == '(' ? sign : def.minus)
            : (sign == '-' || sign == '(' ? '' : sign)) +
        prefix;
    var valueSuffix =
        (type == 's' && !isNan && prefixExponent != null
            ? _refPrefixes[8 + prefixExponent! ~/ 3]
            : '') +
        suffix +
        (valueNegative && sign == '(' ? ')' : '');

    if (maybeSuffix) {
      for (var i = 0; i < value.length; ++i) {
        final c = value.codeUnitAt(i);
        if (c < 48 || c > 57) {
          final tail = c == 46
              ? '${def.decimal}${value.substring(i + 1)}'
              : value.substring(i);
          valueSuffix = '$tail$valueSuffix';
          value = value.substring(0, i);
          break;
        }
      }
    }

    if (comma && !zero && group != null) value = group(value, null);
    final len = valuePrefix.length + value.length + valueSuffix.length;
    var padding = (width != null && len < width) ? fill * (width - len) : '';
    if (comma && zero && group != null) {
      value = group(
        '$padding$value',
        padding.isNotEmpty ? width! - valueSuffix.length : null,
      );
      padding = '';
    }
    final String out;
    switch (align) {
      case '<':
        out = '$valuePrefix$value$valueSuffix$padding';
      case '=':
        out = '$valuePrefix$padding$value$valueSuffix';
      case '^':
        final half = padding.length >> 1;
        out =
            '${padding.substring(0, half)}$valuePrefix$value$valueSuffix'
            '${padding.substring(half)}';
      default:
        out = '$padding$valuePrefix$value$valueSuffix';
    }
    return numerals == null ? out : numerals(out);
  };
}

void main() {
  test(
    'single-pass formatSpecifier matches upstream RegExp on valid & invalid',
    () {
      const inputs = [
        '',
        'd',
        ',d',
        '0',
        '00',
        '012',
        '0=12',
        '<',
        '<<',
        '>=',
        '_>8d',
        '^21,.0%',
        r'=+$012,.2~f',
        ' ',
        ' >',
        'q',
        'Q',
        '%',
        '#016X',
        '.0g',
        '.30f',
        'foo',
        '.-2s',
        '.f',
        ',.',
        '  ',
        '+ ',
        '\n>',
        '\r<',
        '12.3.4f',
        '012,3d',
        '~',
      ];
      for (final s in inputs) {
        FormatSpecifier? ref;
        var refThrew = false;
        try {
          ref = _referenceSpecifier(s);
        } on FormatException {
          refThrew = true;
        }

        if (refThrew) {
          expect(() => formatSpecifier(s), throwsFormatException, reason: s);
        } else {
          final actual = formatSpecifier(s);
          expect(actual.fill, ref!.fill, reason: '$s.fill');
          expect(actual.align, ref.align, reason: '$s.align');
          expect(actual.sign, ref.sign, reason: '$s.sign');
          expect(actual.symbol, ref.symbol, reason: '$s.symbol');
          expect(actual.zero, ref.zero, reason: '$s.zero');
          expect(actual.width, ref.width, reason: '$s.width');
          expect(actual.comma, ref.comma, reason: '$s.comma');
          expect(actual.precision, ref.precision, reason: '$s.precision');
          expect(actual.trim, ref.trim, reason: '$s.trim');
          expect(actual.type, ref.type, reason: '$s.type');
          expect(actual.toString(), ref.toString(), reason: '$s.toString');
        }
      }
    },
  );

  test('fast formatGroup matches literal upstream list-reverse-join', () {
    const patterns = [
      [3],
      [2],
      [2, 3],
      [3, 2, 2, 2, 2, 2],
      <int>[],
    ];
    const seps = [',', ' ', '\u00a0', '٬', '::'];
    const values = [
      '',
      '0',
      '12',
      '123',
      '1234',
      '123456',
      '1234567890',
      '0000000',
      '000000000000',
    ];
    const widths = <int?>[null, 1, 2, 3, 4, 5, 6, 8, 12, 13, 21];

    for (final g in patterns) {
      for (final sep in seps) {
        final fast = formatGroup(g, sep);
        final ref = _referenceGroup(g, sep);
        for (final v in values) {
          for (final w in widths) {
            expect(fast(v, w), ref(v, w), reason: 'g=$g sep=$sep v=$v w=$w');
          }
        }
      }
    }
  });

  test(
    'fast formatNumerals matches RegExp for single- and multi-unit digits',
    () {
      const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      const multi = [
        '(0)',
        '(1)',
        '(2)',
        '(3)',
        '(4)',
        '(5)',
        '(6)',
        '(7)',
        '(8)',
        '(9)',
      ];
      const samples = [
        '',
        'no digits',
        '0',
        '−1,234,567.89',
        '0xdeadbeef',
        '1.23e+10',
        r'+$0,000,042.50',
      ];

      for (final numerals in [arabic, multi]) {
        final fast = formatNumerals(numerals);
        final ref = _referenceNumerals(numerals);
        for (final s in samples) {
          expect(fast(s), ref(s), reason: 's=$s');
        }
      }
    },
  );

  test(
    'fast NumberFormat paths match literal upstream algorithm across locales '
    'and ties',
    () {
      const locales = [localeEnUS, localeFrFR, localeEnIN, localeArAE];
      const specs = [
        '',
        'd',
        ',d',
        '08d',
        '+012,d',
        '_>8d',
        '^13,d',
        '<10,d',
        r'=+$12,d',
        '.0f',
        '.1f',
        '.2f',
        '.3f',
        '.6f',
        ',.2f',
        r'+$,.2f',
        r'($,.2f',
        '012,.2f',
        '<12,.2f',
        '^15,.2f',
        '=+12,.2f',
        '~f',
        '.2~f',
        '.0%',
        '.1%',
        '.2%',
        '~%',
        '012.1%',
        '.3e',
        '.4~e',
        '.6g',
        'n',
        '.3r',
        's',
        '.3s',
        '.4s',
        '~s',
        r'$.3s',
        'b',
        '#b',
        'o',
        '#o',
        'x',
        '#x',
        '#010x',
        'X',
        '#010X',
        '<12x',
        '^12X',
      ];
      final values = <double>[
        0,
        -1.0 * 0.0,
        0.005,
        0.145,
        0.245,
        0.5,
        1.005,
        1.5,
        2.5,
        35.855,
        -35.855,
        99.995,
        -99.995,
        0.00042,
        999.5,
        999500,
        123456.49,
        -123456.49,
        145500000,
        -12345678,
        0xdeadbeef.toDouble(),
        1e-12,
        -1e-12,
        1e-24,
        1e24,
        1e26,
        1e-27,
        1e30,
        double.infinity,
        double.negativeInfinity,
        double.nan,
      ];

      for (final def in locales) {
        final loc = formatLocale(def);
        for (final spec in specs) {
          final fast = loc.format(spec);
          final ref = _referenceFormat(def, spec);
          for (final v in values) {
            expect(
              fast(v),
              ref(v),
              reason: 'locale=${def.currency} spec=$spec v=$v',
            );
          }
        }
      }
    },
  );
}
