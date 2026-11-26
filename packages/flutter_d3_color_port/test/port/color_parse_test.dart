// Original code, not ported from d3-color: the twin test of the color parser.

/// The twin test of the rows `adapt-color-parse-scan`,
/// `adapt-color-parse-number` and `adapt-color-named-table`: [color] against
/// the plain translation of the upstream lines (`trim()`, `toLowerCase()`,
/// the six RegExps, `double.parse` and the Map `named`), kept here as
/// [_reference], on a large generated corpus of valid and invalid texts.
///
/// Each text compares the result: null or not, the class, and each channel
/// bit for bit (NaN equals NaN, -0 differs from +0).
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:test/test.dart';

void main() {
  test('color(text) equals the upstream lines on the generated corpus', () {
    final corpus = _corpus();
    expect(corpus.length, greaterThan(80000));
    final mismatches = <String>[];
    var colors = 0;
    for (final text in corpus) {
      final expected = _reference(text);
      final actual = color(text);
      if (expected != null) colors++;
      final problem = _difference(expected, actual);
      if (problem != null && mismatches.length < 20) {
        mismatches.add('${_quote(text)}: $problem');
      }
    }
    expect(mismatches, isEmpty);
    // The corpus has both valid and invalid texts in good numbers.
    expect(colors, greaterThan(corpus.length ~/ 5));
    expect(colors, lessThan(corpus.length * 4 ~/ 5));
  });

  test('each name and transparent, in any case', () {
    final r = _Random(7);
    for (final name in [..._named.keys, 'transparent']) {
      for (final text in [name, name.toUpperCase(), _upperSome(r, name)]) {
        expect(_difference(_reference(text), color(text)), isNull);
        expect(color(text), isNotNull);
      }
    }
  });

  test('the numbers equal double.parse of their text', () {
    final r = _Random(11);
    var numbers = 0;
    for (var k = 0; k < 20000; k++) {
      final text = _numberText(r);
      final number = double.tryParse(text);
      // The grammar of reN is a subset of the Dart grammar of double.parse.
      final alpha = color('rgba(1, 2, 3, $text)');
      final hue = color('hsl($text, 50%, 50%)');
      if (alpha == null) {
        expect(hue, isNull, reason: text);
        continue;
      }
      numbers++;
      expect(number, isNotNull, reason: text);
      expect(_same(alpha.opacity, number!), isTrue, reason: text);
      if (number.isFinite) {
        expect(_same((hue! as Hsl).h, number), isTrue, reason: text);
      }
    }
    expect(numbers, greaterThan(15000));
  });
}

/// The difference of [actual] from [expected], or null.
String? _difference(Color? expected, Color? actual) {
  if (expected == null || actual == null) {
    return expected == null && actual == null
        ? null
        : 'expected $expected, actual $actual';
  }
  final List<double> e;
  final List<double> a;
  if (expected is Rgb) {
    if (actual is! Rgb) return 'expected Rgb, actual ${actual.runtimeType}';
    e = [expected.r, expected.g, expected.b, expected.opacity];
    a = [actual.r, actual.g, actual.b, actual.opacity];
  } else {
    expected as Hsl;
    if (actual is! Hsl) return 'expected Hsl, actual ${actual.runtimeType}';
    e = [expected.h, expected.s, expected.l, expected.opacity];
    a = [actual.h, actual.s, actual.l, actual.opacity];
  }
  for (var k = 0; k < 4; k++) {
    if (!_same(e[k], a[k])) {
      return 'channel $k: expected ${e[k]}, actual ${a[k]}';
    }
  }
  return null;
}

/// Whether [a] and [b] are the same double: NaN equals NaN, and -0 differs
/// from +0.
bool _same(double a, double b) =>
    a.isNaN ? b.isNaN : a == b && a.isNegative == b.isNegative;

String _quote(String text) {
  final out = StringBuffer('"');
  for (final c in text.runes) {
    out.write(
      c >= 0x20 && c < 0x7f
          ? String.fromCharCode(c)
          : '\\u{${c.toRadixString(16)}}',
    );
  }
  return (out..write('"')).toString();
}

/// The Park-Miller generator, exact on each platform.
final class _Random(var int seed) {
  int next(int n) {
    seed = seed * 48271 % 2147483647;
    return seed % n;
  }

  bool chance(int percent) => next(100) < percent;

  T pick<T>(List<T> items) => items[next(items.length)];
}

/// The white space of the corpus: of trim() and of `\s`, U+0085, and code
/// units that are neither.
const List<String> _spaces = [
  ' ', ' ', ' ', '  ', '\t', '\n', '\r', '\v', '\f', '\u00a0', '\ufeff', //
  '\u2028', '\u2029', '\u1680', '\u2000', '\u200a', '\u202f', '\u205f',
  '\u3000', '\u0085', '\u200b', '\u180e', '\u001c', '\u001f', '\u0000',
];

/// The code units that the mutations insert.
const List<String> _noise = [
  '0', '1', '5', '9', 'a', 'f', 'g', 'e', 'E', 'k', 'x', 'A', 'F', 'Z', //
  '#', '(', ')', ',', '%', '.', '+', '-', ' ', '\t', ';', '/', '_', '@', '[',
  '`', '{', '\u00a0', '\ufeff', '\u2028', '\u0085', '\u0130', '\u0131',
  '\u212a', '\u017f', '\u00e9', '\u00c9', '\u03a3', '\u{1f600}', '\u0660',
  '\uff10',
];

String _mixCase(_Random r, String text) {
  final out = StringBuffer();
  for (final c in text.codeUnits) {
    final char = String.fromCharCode(c);
    if (!r.chance(30)) {
      out.write(char);
    } else if (c == 0x6b && r.chance(20)) {
      out.write('\u212a'); // KELVIN SIGN: toLowerCase gives k.
    } else if (c == 0x69 && r.chance(10)) {
      out.write('\u0130');
    } else {
      out.write(char.toUpperCase());
    }
  }
  return out.toString();
}

/// [text] with some ASCII lowercase letters in uppercase.
String _upperSome(_Random r, String text) => String.fromCharCodes([
  for (final c in text.codeUnits) c ^ (r.chance(50) ? 0x20 : 0),
]);

/// Some white space: mostly none or ASCII, at times another code unit.
String _space(_Random r) => r.chance(60) ? '' : _anySpace(r);

/// One white space: mostly ASCII, at times another code unit.
String _anySpace(_Random r) => r.chance(75)
    ? r.pick(const [' ', '  ', '\t', '\n', '\r', '\v', '\f'])
    : r.pick(_spaces);

String _digits(_Random r, int count) {
  final out = StringBuffer();
  for (var k = 0; k < count; k++) {
    out.write(r.next(10));
  }
  return out.toString();
}

/// A number text of `reN`, and some texts that are not.
String _numberText(_Random r) {
  final out = StringBuffer(r.pick(const ['', '', '', '+', '-']));
  final shape = r.next(10);
  final intDigits = shape < 2
      ? 0
      : shape < 8
      ? 1 + r.next(4)
      : 1 + r.next(22);
  if (r.chance(10)) out.write('0' * (1 + r.next(25)));
  out.write(_digits(r, intDigits));
  if (intDigits == 0 || r.chance(40)) {
    out
      ..write('.')
      ..write(
        r.chance(5)
            ? ''
            : _digits(r, r.chance(80) ? 1 + r.next(4) : r.next(25)),
      );
  }
  if (r.chance(25)) {
    out
      ..write(r.pick(const ['e', 'E']))
      ..write(r.pick(const ['', '', '+', '-']));
    final e = r.next(10);
    out.write(
      e < 1
          ? ''
          : e < 7
          ? '${r.next(30)}'
          : e < 9
          ? '${r.next(400)}'
          : '0' * r.next(3) + _digits(r, 1 + r.next(12)),
    );
  }
  if (r.chance(2)) {
    out.write(
      r.pick(const ['', '.', 'e', '..5', '-', '1e', 'NaN', 'Infinity', 'x']),
    );
  }
  return out.toString();
}

/// Some numbers of edge cases.
const List<String> _edgeNumbers = [
  '0', '-0', '+0', '0.0', '-0.0', '.0', '-.0', '00', '0e0', '-0e-5', //
  '0e99999999999', '-0e999999999999999', '1e22', '1e23', '1e-22', '1e-23',
  '9007199254740993', '999999999999999', '9999999999999999', '123456789012345',
  '1234567890123456', '0.1', '0.2', '0.3', '.5', '5', '255', '256', '-1',
  '1e308', '1.7976931348623157e308', '1.8e308', '1e400', '-1e400', '5e-324',
  '4.9e-324', '2e-324', '1e-400', '2.2250738585072014e-308', '1e-7', '100',
  '100.000000000000000000000', '0.000000000000000000000001', '1e+0',
  '1E-0',
  '123.456e2',
  '-123.456E-2',
  '0.9999999999999999',
  '1.0000000000000001',
  '1000000e-6', '0.000001e6', '42e000000000000000000001', '1e0000000000000022',
];

String _arg(_Random r, String kind) {
  final number = r.chance(15)
      ? r.pick(_edgeNumbers)
      : r.chance(40)
      ? _numberText(r)
      : '${r.chance(10) ? '-' : ''}${r.next(r.chance(50) ? 256 : 1001)}'
            '${r.chance(30) ? '.${r.next(10)}' : ''}';
  return '${_space(r)}$number${kind == '%' || r.chance(3) ? '%' : ''}'
      '${_space(r)}';
}

/// A functional form with valid or nearly valid arguments.
String _function(_Random r) {
  final name = r.pick(const ['rgb', 'rgba', 'hsl', 'hsla']);
  final percent = r.chance(50);
  final kinds = switch (name) {
    'rgb' => List.filled(3, percent ? '%' : '', growable: true),
    'rgba' => [...List.filled(3, percent ? '%' : ''), ''],
    'hsl' => ['', '%', '%'],
    _ => ['', '%', '%', ''],
  };
  if (r.chance(5)) kinds.removeLast();
  if (r.chance(5)) kinds.add(r.pick(const ['', '%']));
  final args = [for (final kind in kinds) _arg(r, kind)]
      .join(r.chance(2) ? ';' : ',');
  final head = r.chance(30) ? _mixCase(r, name) : name;
  return '$head${r.chance(2) ? ' ' : ''}($args${r.chance(2) ? '' : ')'}';
}

String _hexText(_Random r) {
  const digits = '0123456789abcdefABCDEF';
  final count = r.chance(80) ? r.pick(const [3, 4, 6, 8]) : r.next(12);
  final out = StringBuffer('#');
  for (var k = 0; k < count; k++) {
    out.write(digits[r.next(digits.length)]);
  }
  return out.toString();
}

/// One mutation of [text]: an insertion, a deletion, a replacement, a
/// duplication or a change of case.
String _mutate(_Random r, String text) {
  if (text.isEmpty) return r.pick(_noise);
  final at = r.next(text.length + 1);
  final within = at < text.length ? at : text.length - 1;
  switch (r.next(5)) {
    case 0:
      return text.substring(0, at) + r.pick(_noise) + text.substring(at);
    case 1:
      return text.substring(0, within) + text.substring(within + 1);
    case 2:
      return text.substring(0, within) +
          r.pick(_noise) +
          text.substring(within + 1);
    case 3:
      return text.substring(0, within + 1) + text.substring(within);
    default:
      return _mixCase(r, text);
  }
}

List<String> _corpus() {
  final r = _Random(42);
  final names = [..._named.keys, 'transparent'];
  final texts = <String>[
    '',
    ' ',
    '#',
    '(',
    ')',
    'rgb',
    'rgb(',
    'rgb()',
    'rgba(',
    'rgba()',
    'hsl()',
    'hsla()',
    'rgb(,,)',
    'transparent',
    'TRANSPARENT',
    'Black',
    'blac\u212a',
    '\u212ahaki',
    'whitesmoke\u00a0',
    '\u00a0#fff',
    '#fff\u2028',
    '#fff\u0085',
    '\u0085#fff',
    'rgb(1,2,3)\u0085',
    'l\u0130me',
    'rgb(1, 2,3',
    // An exponent past the cap of the exact path, with as many fraction
    // digits: 1e-100000 * 1e1000005 is Infinity, not 1.
    for (final n in ['0.${'0' * 99999}1e1000005', '1${'0' * 30}e-30'])
      'rgba(0, 0, 0, $n)',
    for (final n in _edgeNumbers) ...[
      'rgb($n, 0, 0)',
      'rgb($n%, 0%, 0%)',
      'rgba(0, 0, 0, $n)',
      'rgba(0%, 0%, 0%, $n)',
      'hsl($n, 50%, 50%)',
      'hsla(0, $n%, 50%, $n)',
    ],
  ];
  for (var k = 0; k < 80000; k++) {
    final base = switch (r.next(10)) {
      0 || 1 => _hexText(r),
      2 || 3 => _mixCase(r, r.pick(names)),
      4 => r.pick(const ['bostock', 'rgba', 'hsla', 'grey ish', 'red-ish']),
      _ => _function(r),
    };
    var text = base;
    final mutations = r.chance(50) ? 0 : 1 + r.next(3);
    for (var m = 0; m < mutations; m++) {
      text = _mutate(r, text);
    }
    if (r.chance(25)) text = '${_anySpace(r)}$text';
    if (r.chance(25)) text = '$text${_anySpace(r)}';
    texts.add(text);
  }
  return texts;
}

// The plain translation of the upstream lines of color.js:8-218.

const String _reI = r'\s*([+-]?\d+)\s*';
const String _reN = r'\s*([+-]?(?:\d*\.)?\d+(?:[eE][+-]?\d+)?)\s*';
const String _reP = r'\s*([+-]?(?:\d*\.)?\d+(?:[eE][+-]?\d+)?)%\s*';
final RegExp _reHex = RegExp(r'^#([0-9a-f]{3,8})$');
final RegExp _reRgbInteger = RegExp('^rgb\\($_reI,$_reI,$_reI\\)\$');
final RegExp _reRgbPercent = RegExp('^rgb\\($_reP,$_reP,$_reP\\)\$');
final RegExp _reRgbaInteger = RegExp('^rgba\\($_reI,$_reI,$_reI,$_reN\\)\$');
final RegExp _reRgbaPercent = RegExp('^rgba\\($_reP,$_reP,$_reP,$_reN\\)\$');
final RegExp _reHslPercent = RegExp('^hsl\\($_reN,$_reP,$_reP\\)\$');
final RegExp _reHslaPercent = RegExp('^hsla\\($_reN,$_reP,$_reP,$_reN\\)\$');

const Map<String, int> _named = {
  'aliceblue': 0xf0f8ff,
  'antiquewhite': 0xfaebd7,
  'aqua': 0x00ffff,
  'aquamarine': 0x7fffd4,
  'azure': 0xf0ffff,
  'beige': 0xf5f5dc,
  'bisque': 0xffe4c4,
  'black': 0x000000,
  'blanchedalmond': 0xffebcd,
  'blue': 0x0000ff,
  'blueviolet': 0x8a2be2,
  'brown': 0xa52a2a,
  'burlywood': 0xdeb887,
  'cadetblue': 0x5f9ea0,
  'chartreuse': 0x7fff00,
  'chocolate': 0xd2691e,
  'coral': 0xff7f50,
  'cornflowerblue': 0x6495ed,
  'cornsilk': 0xfff8dc,
  'crimson': 0xdc143c,
  'cyan': 0x00ffff,
  'darkblue': 0x00008b,
  'darkcyan': 0x008b8b,
  'darkgoldenrod': 0xb8860b,
  'darkgray': 0xa9a9a9,
  'darkgreen': 0x006400,
  'darkgrey': 0xa9a9a9,
  'darkkhaki': 0xbdb76b,
  'darkmagenta': 0x8b008b,
  'darkolivegreen': 0x556b2f,
  'darkorange': 0xff8c00,
  'darkorchid': 0x9932cc,
  'darkred': 0x8b0000,
  'darksalmon': 0xe9967a,
  'darkseagreen': 0x8fbc8f,
  'darkslateblue': 0x483d8b,
  'darkslategray': 0x2f4f4f,
  'darkslategrey': 0x2f4f4f,
  'darkturquoise': 0x00ced1,
  'darkviolet': 0x9400d3,
  'deeppink': 0xff1493,
  'deepskyblue': 0x00bfff,
  'dimgray': 0x696969,
  'dimgrey': 0x696969,
  'dodgerblue': 0x1e90ff,
  'firebrick': 0xb22222,
  'floralwhite': 0xfffaf0,
  'forestgreen': 0x228b22,
  'fuchsia': 0xff00ff,
  'gainsboro': 0xdcdcdc,
  'ghostwhite': 0xf8f8ff,
  'gold': 0xffd700,
  'goldenrod': 0xdaa520,
  'gray': 0x808080,
  'green': 0x008000,
  'greenyellow': 0xadff2f,
  'grey': 0x808080,
  'honeydew': 0xf0fff0,
  'hotpink': 0xff69b4,
  'indianred': 0xcd5c5c,
  'indigo': 0x4b0082,
  'ivory': 0xfffff0,
  'khaki': 0xf0e68c,
  'lavender': 0xe6e6fa,
  'lavenderblush': 0xfff0f5,
  'lawngreen': 0x7cfc00,
  'lemonchiffon': 0xfffacd,
  'lightblue': 0xadd8e6,
  'lightcoral': 0xf08080,
  'lightcyan': 0xe0ffff,
  'lightgoldenrodyellow': 0xfafad2,
  'lightgray': 0xd3d3d3,
  'lightgreen': 0x90ee90,
  'lightgrey': 0xd3d3d3,
  'lightpink': 0xffb6c1,
  'lightsalmon': 0xffa07a,
  'lightseagreen': 0x20b2aa,
  'lightskyblue': 0x87cefa,
  'lightslategray': 0x778899,
  'lightslategrey': 0x778899,
  'lightsteelblue': 0xb0c4de,
  'lightyellow': 0xffffe0,
  'lime': 0x00ff00,
  'limegreen': 0x32cd32,
  'linen': 0xfaf0e6,
  'magenta': 0xff00ff,
  'maroon': 0x800000,
  'mediumaquamarine': 0x66cdaa,
  'mediumblue': 0x0000cd,
  'mediumorchid': 0xba55d3,
  'mediumpurple': 0x9370db,
  'mediumseagreen': 0x3cb371,
  'mediumslateblue': 0x7b68ee,
  'mediumspringgreen': 0x00fa9a,
  'mediumturquoise': 0x48d1cc,
  'mediumvioletred': 0xc71585,
  'midnightblue': 0x191970,
  'mintcream': 0xf5fffa,
  'mistyrose': 0xffe4e1,
  'moccasin': 0xffe4b5,
  'navajowhite': 0xffdead,
  'navy': 0x000080,
  'oldlace': 0xfdf5e6,
  'olive': 0x808000,
  'olivedrab': 0x6b8e23,
  'orange': 0xffa500,
  'orangered': 0xff4500,
  'orchid': 0xda70d6,
  'palegoldenrod': 0xeee8aa,
  'palegreen': 0x98fb98,
  'paleturquoise': 0xafeeee,
  'palevioletred': 0xdb7093,
  'papayawhip': 0xffefd5,
  'peachpuff': 0xffdab9,
  'peru': 0xcd853f,
  'pink': 0xffc0cb,
  'plum': 0xdda0dd,
  'powderblue': 0xb0e0e6,
  'purple': 0x800080,
  'rebeccapurple': 0x663399,
  'red': 0xff0000,
  'rosybrown': 0xbc8f8f,
  'royalblue': 0x4169e1,
  'saddlebrown': 0x8b4513,
  'salmon': 0xfa8072,
  'sandybrown': 0xf4a460,
  'seagreen': 0x2e8b57,
  'seashell': 0xfff5ee,
  'sienna': 0xa0522d,
  'silver': 0xc0c0c0,
  'skyblue': 0x87ceeb,
  'slateblue': 0x6a5acd,
  'slategray': 0x708090,
  'slategrey': 0x708090,
  'snow': 0xfffafa,
  'springgreen': 0x00ff7f,
  'steelblue': 0x4682b4,
  'tan': 0xd2b48c,
  'teal': 0x008080,
  'thistle': 0xd8bfd8,
  'tomato': 0xff6347,
  'turquoise': 0x40e0d0,
  'violet': 0xee82ee,
  'wheat': 0xf5deb3,
  'white': 0xffffff,
  'whitesmoke': 0xf5f5f5,
  'yellow': 0xffff00,
  'yellowgreen': 0x9acd32,
};

Rgb _rgbn(int n) => Rgb(
  (n >> 16 & 0xff).toDouble(),
  (n >> 8 & 0xff).toDouble(),
  (n & 0xff).toDouble(),
);

Rgb _rgba(double r, double g, double b, double a) =>
    a <= 0 ? Rgb(double.nan, double.nan, double.nan, a) : Rgb(r, g, b, a);

Hsl _hsla(double h, double s, double l, double a) {
  const nan = double.nan;
  if (a <= 0) return Hsl(nan, nan, nan, a);
  if (l <= 0 || l >= 1) return Hsl(nan, nan, l, a);
  if (s <= 0) return Hsl(nan, s, l, a);
  return Hsl(h, s, l, a);
}

double _number(RegExpMatch m, int index) => double.parse(m.group(index)!);

/// The plain translation of color.js:201 `color(format)`, with the null of
/// the row `platform-color-trim-lowercase`.
Color? _reference(String specifier) {
  for (var i = 0; i < specifier.length; i++) {
    final c = specifier.codeUnitAt(i);
    if (c == 0x85 || c == 0x130) return null;
  }
  RegExpMatch? m;
  final format = specifier.trim().toLowerCase();
  if ((m = _reHex.firstMatch(format)) != null) {
    final digits = m!.group(1)!;
    final l = digits.length;
    final n = int.parse(digits, radix: 16);
    return l == 6
        ? _rgbn(n)
        : l == 3
        ? Rgb(
            ((n >> 8 & 0xf) | (n >> 4 & 0xf0)).toDouble(),
            ((n >> 4 & 0xf) | (n & 0xf0)).toDouble(),
            (((n & 0xf) << 4) | (n & 0xf)).toDouble(),
          )
        : l == 8
        ? _rgba(
            (n >> 24 & 0xff).toDouble(),
            (n >> 16 & 0xff).toDouble(),
            (n >> 8 & 0xff).toDouble(),
            (n & 0xff) / 0xff,
          )
        : l == 4
        ? _rgba(
            ((n >> 12 & 0xf) | (n >> 8 & 0xf0)).toDouble(),
            ((n >> 8 & 0xf) | (n >> 4 & 0xf0)).toDouble(),
            ((n >> 4 & 0xf) | (n & 0xf0)).toDouble(),
            (((n & 0xf) << 4) | (n & 0xf)) / 0xff,
          )
        : null;
  }
  if ((m = _reRgbInteger.firstMatch(format)) != null) {
    return Rgb(_number(m!, 1), _number(m, 2), _number(m, 3));
  }
  if ((m = _reRgbPercent.firstMatch(format)) != null) {
    return Rgb(
      _number(m!, 1) * 255 / 100,
      _number(m, 2) * 255 / 100,
      _number(m, 3) * 255 / 100,
    );
  }
  if ((m = _reRgbaInteger.firstMatch(format)) != null) {
    return _rgba(_number(m!, 1), _number(m, 2), _number(m, 3), _number(m, 4));
  }
  if ((m = _reRgbaPercent.firstMatch(format)) != null) {
    return _rgba(
      _number(m!, 1) * 255 / 100,
      _number(m, 2) * 255 / 100,
      _number(m, 3) * 255 / 100,
      _number(m, 4),
    );
  }
  if ((m = _reHslPercent.firstMatch(format)) != null) {
    return _hsla(_number(m!, 1), _number(m, 2) / 100, _number(m, 3) / 100, 1);
  }
  if ((m = _reHslaPercent.firstMatch(format)) != null) {
    return _hsla(
      _number(m!, 1),
      _number(m, 2) / 100,
      _number(m, 3) / 100,
      _number(m, 4),
    );
  }
  final named = _named[format];
  if (named != null) return _rgbn(named);
  return format == 'transparent'
      ? const Rgb(double.nan, double.nan, double.nan, 0)
      : null;
}
