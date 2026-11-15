// Ported from d3-color v3.1.0 src/color.js (ISC, Mike Bostock).

/// Port of `src/color.js` of d3-color 3.1.0: the base class [Color], the
/// CSS parser [color], and the RGB and HSL color spaces [Rgb] and [Hsl].
///
/// The port uses the native forms of D3 ADR 0007. A channel is a `double`
/// field, and NaN marks an undefined channel, as upstream. The upstream
/// factories `rgb` and `hsl` overload on their argument count. Here, the form
/// with channels is the constructor of the class, `X.from` converts a
/// [Color], and `X.parse` reads a CSS text.
library;

import 'dart:math' as math;
import 'dart:typed_data';

/// color.js:5 `darker`: the default factor of `darker()` in RGB, HSL and
/// Cubehelix.
const double darker = 0.7;

/// color.js:6 `brighter`.
const double brighter = 1 / darker;

// The methods `brighter` and `darker` of the color classes hide the two
// constants in the class bodies. The classes read them through these names.
const double _darker = darker;
const double _brighter = brighter;

/// color.js:8 `reI`.
const String _reI = r'\s*([+-]?\d+)\s*';

/// color.js:9 `reN`.
const String _reN = r'\s*([+-]?(?:\d*\.)?\d+(?:[eE][+-]?\d+)?)\s*';

/// color.js:10 `reP`.
const String _reP = r'\s*([+-]?(?:\d*\.)?\d+(?:[eE][+-]?\d+)?)%\s*';

/// color.js:11 `reHex`.
final RegExp _reHex = RegExp(r'^#([0-9a-f]{3,8})$');

/// color.js:12 `reRgbInteger`.
final RegExp _reRgbInteger = RegExp('^rgb\\($_reI,$_reI,$_reI\\)\$');

/// color.js:13 `reRgbPercent`.
final RegExp _reRgbPercent = RegExp('^rgb\\($_reP,$_reP,$_reP\\)\$');

/// color.js:14 `reRgbaInteger`.
final RegExp _reRgbaInteger = RegExp('^rgba\\($_reI,$_reI,$_reI,$_reN\\)\$');

/// color.js:15 `reRgbaPercent`.
final RegExp _reRgbaPercent = RegExp('^rgba\\($_reP,$_reP,$_reP,$_reN\\)\$');

/// color.js:16 `reHslPercent`.
final RegExp _reHslPercent = RegExp('^hsl\\($_reN,$_reP,$_reP\\)\$');

/// color.js:17 `reHslaPercent`.
final RegExp _reHslaPercent = RegExp('^hsla\\($_reN,$_reP,$_reP,$_reN\\)\$');

/// color.js:19 `named`: the CSS color names and their 24-bit RGB values.
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

/// color.js:3 `Color`, the base class of each color space. The upstream
/// factory `color` is also this class: `x instanceof color` is `x is Color`.
///
/// A color is mutable: each channel is a field that code can write, as
/// upstream.
// DIVERGES(d3-color): adapt-color-base-class, abstract members, typed copy.
abstract class Color() {
  /// A color with no channels: each subclass declares its channels.
  this;

  /// The opacity in [0, 1]. NaN is undefined, and the formats read it as 1.
  abstract double opacity;

  /// color.js:171 `copy(channels)`: a new color of the same space with the
  /// channels of this color, and the given channels in place of them.
  Color copy({double? opacity});

  /// color.js:174 `displayable()`: whether the color is in the RGB gamut and
  /// the opacity is in [0, 1].
  bool displayable() => rgb().displayable();

  /// color.js:177 `hex()`, deprecated upstream: [formatHex].
  // Upstream keeps the deprecated alias in 3.1.0, so the port keeps it too.
  // ignore: remove_deprecations_in_breaking_versions
  @Deprecated('Use formatHex.')
  String hex() => formatHex();

  /// color.js:178 `formatHex()`: the CSS text `#rrggbb`.
  String formatHex() => rgb().formatHex();

  /// color.js:179 `formatHex8()`: the CSS text `#rrggbbaa`.
  String formatHex8() => rgb().formatHex8();

  /// color.js:180 `formatHsl()`: the CSS text `hsl(…)` or `hsla(…)`.
  String formatHsl() => hslConvert(this).formatHsl();

  /// color.js:181 `formatRgb()`: the CSS text `rgb(…)` or `rgba(…)`.
  String formatRgb() => rgb().formatRgb();

  /// color.js:182 `toString()`: [formatRgb].
  @override
  String toString() => formatRgb();

  /// The `rgb()` of each color space: this color in RGB.
  Rgb rgb();

  /// The `brighter(k)` of each color space: a brighter copy of this color.
  /// A null [k] is 1.
  Color brighter([double? k]);

  /// The `darker(k)` of each color space: a darker copy of this color. A
  /// null [k] is 1.
  Color darker([double? k]);
}

/// color.js:201 `color(format)`: the color of the CSS text [specifier], or null
/// when the text is not a CSS color of d3-color.
///
/// The text can be a hexadecimal color of 3, 4, 6 or 8 digits, an `rgb(…)`,
/// `rgba(…)`, `hsl(…)` or `hsla(…)` function, a CSS color name or
/// `transparent`. The case and the white space around the text do not
/// count. The result is an [Rgb] or an [Hsl].
///
/// The port reads a text of ASCII code units in one pass, with the grammar of
/// the upstream patterns. A text with another code unit takes the upstream
/// lines, so that the Unicode rules of `trim()`, `toLowerCase()` and `\s`
/// stay those of upstream.
Color? color(String specifier) {
  // DIVERGES(d3-color): adapt-color-parse-scan, one pass over ASCII texts.
  final s = specifier;
  var i = 0;
  var end = s.length;
  // trim(): the ASCII white space of String.prototype.trim.
  while (i < end && _isSpace(s.codeUnitAt(i))) {
    i++;
  }
  while (end > i && _isSpace(s.codeUnitAt(end - 1))) {
    end--;
  }
  if (i == end) return null;
  final first = s.codeUnitAt(i);
  // Another character can be white space of trim() or of `\s`, or change in
  // toLowerCase(): the upstream lines read the text.
  if (first >= 0x80 || s.codeUnitAt(end - 1) >= 0x80) return _colorRegExp(s);
  if (first == 0x23) return _scanHex(s, i + 1, end); // #
  final f = first | 0x20;
  if ((f == 0x72 || f == 0x68) && end - i >= 5) {
    // rgb( rgba( hsl( hsla(
    final c1 = s.codeUnitAt(i + 1) | 0x20;
    final c2 = s.codeUnitAt(i + 2) | 0x20;
    if (f == 0x72 ? c1 == 0x67 && c2 == 0x62 : c1 == 0x73 && c2 == 0x6c) {
      final c3 = s.codeUnitAt(i + 3);
      if (c3 == 0x28) {
        return f == 0x72
            ? _scanRgb(s, i + 4, end, false)
            : _scanHsl(s, i + 4, end, false);
      }
      if ((c3 | 0x20) == 0x61 && s.codeUnitAt(i + 4) == 0x28) {
        return f == 0x72
            ? _scanRgb(s, i + 5, end, true)
            : _scanHsl(s, i + 5, end, true);
      }
    }
  }
  return _scanNamed(s, i, end);
}

/// Whether the code unit [c] is ASCII white space of `trim()` and of the
/// RegExp class `\s`: U+0009 to U+000D and U+0020.
bool _isSpace(int c) => c <= 0x20 && (c == 0x20 || c >= 0x09 && c <= 0x0d);

/// The result of [color] for a text that failed the grammar at the code unit
/// [_at] of [s]: null when that code unit is ASCII, because each code unit
/// before it is ASCII, so no upstream pattern can match. Else the upstream
/// lines decide.
Color? _failed(String s) => s.codeUnitAt(_at) >= 0x80 ? _colorRegExp(s) : null;

/// `reHex` and the hexadecimal branch of [color]: the digits of `#` from [p]
/// to [end], read as nibbles.
Color? _scanHex(String s, int p, int end) {
  // `[0-9a-f]{3,8}`: a ninth digit fails too.
  final l = end - p;
  final stop = l < 9 ? end : p + 9;
  var n = 0;
  for (var k = p; k < stop; k++) {
    final c = s.codeUnitAt(k);
    var d = c - 0x30;
    if (d < 0 || d > 9) {
      d = (c | 0x20) - 0x57;
      if (d < 10 || d > 15) return c >= 0x80 ? _colorRegExp(s) : null;
    }
    n = n * 16 + d;
  }
  return l == 6
      ? rgbn(n) // #ff0000
      : l == 3
      ? Rgb(
          ((n >> 8 & 0xf) | (n >> 4 & 0xf0)).toDouble(),
          ((n >> 4 & 0xf) | (n & 0xf0)).toDouble(),
          (((n & 0xf) << 4) | (n & 0xf)).toDouble(),
        ) // #f00
      : l == 8
      ? rgba(
          (n >> 24 & 0xff).toDouble(),
          (n >> 16 & 0xff).toDouble(),
          (n >> 8 & 0xff).toDouble(),
          (n & 0xff) / 0xff,
        ) // #ff000000
      : l == 4
      ? rgba(
          ((n >> 12 & 0xf) | (n >> 8 & 0xf0)).toDouble(),
          ((n >> 8 & 0xf) | (n >> 4 & 0xf0)).toDouble(),
          ((n >> 4 & 0xf) | (n & 0xf0)).toDouble(),
          (((n & 0xf) << 4) | (n & 0xf)) / 0xff,
        ) // #f000
      : null; // invalid hex
}

/// `reRgbInteger`, `reRgbPercent`, `reRgbaInteger` and `reRgbaPercent`: the
/// arguments of `rgb(` or `rgba(` (with [alpha]) from [p], and `)` at
/// [end] - 1.
Color? _scanRgb(String s, int p, int end, bool alpha) {
  final last = end - 1;
  if (s.codeUnitAt(last) != 0x29) return null; // )
  final r = _arg(s, p);
  if (r.isNaN) return _failed(s);
  final form = _form;
  if (form == _formNumber || s.codeUnitAt(_at) != 0x2c) return null;
  final g = _arg(s, _at + 1);
  if (g.isNaN) return _failed(s);
  if (_form != form || s.codeUnitAt(_at) != 0x2c) return null;
  final b = _arg(s, _at + 1);
  if (b.isNaN) return _failed(s);
  if (_form != form) return null;
  if (!alpha) {
    if (_at != last) return null;
    // rgb(255, 0, 0) and rgb(100%, 0%, 0%)
    return form == _formInteger
        ? Rgb(r, g, b)
        : Rgb(r * 255 / 100, g * 255 / 100, b * 255 / 100);
  }
  if (s.codeUnitAt(_at) != 0x2c) return null;
  final a = _arg(s, _at + 1);
  if (a.isNaN) return _failed(s);
  if (_form == _formPercent || _at != last) return null;
  // rgba(255, 0, 0, 1) and rgb(100%, 0%, 0%, 1)
  return form == _formInteger
      ? rgba(r, g, b, a)
      : rgba(r * 255 / 100, g * 255 / 100, b * 255 / 100, a);
}

/// `reHslPercent` and `reHslaPercent`: the arguments of `hsl(` or `hsla(`
/// (with [alpha]) from [p], and `)` at [end] - 1.
Color? _scanHsl(String s, int p, int end, bool alpha) {
  final last = end - 1;
  if (s.codeUnitAt(last) != 0x29) return null; // )
  final h = _arg(s, p);
  if (h.isNaN) return _failed(s);
  if (_form == _formPercent || s.codeUnitAt(_at) != 0x2c) return null;
  final sat = _arg(s, _at + 1);
  if (sat.isNaN) return _failed(s);
  if (_form != _formPercent || s.codeUnitAt(_at) != 0x2c) return null;
  final l = _arg(s, _at + 1);
  if (l.isNaN) return _failed(s);
  if (_form != _formPercent) return null;
  if (!alpha) {
    if (_at != last) return null;
    return hsla(h, sat / 100, l / 100, 1); // hsl(120, 50%, 50%)
  }
  if (s.codeUnitAt(_at) != 0x2c) return null;
  final a = _arg(s, _at + 1);
  if (a.isNaN) return _failed(s);
  if (_form == _formPercent || _at != last) return null;
  return hsla(h, sat / 100, l / 100, a); // hsla(120, 50%, 50%, 1)
}

/// The form of the last argument of [_arg]: `[+-]?\d+` (of `reI`).
const int _formInteger = 0;

/// The form of the last argument of [_arg]: another number of `reN`.
const int _formNumber = 1;

/// The form of the last argument of [_arg]: a number with `%` (of `reP`).
const int _formPercent = 2;

/// The position where the last [_arg] stopped: the first code unit after its
/// white space, or the code unit where it failed.
int _at = 0;

/// The form of the last argument of [_arg]: [_formInteger], [_formNumber] or
/// [_formPercent].
int _form = _formInteger;

/// The exact powers of ten of a double: 1e0 to 1e22.
const List<double> _pow10 = [
  1e0, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e11, 1e12, //
  1e13, 1e14, 1e15, 1e16, 1e17, 1e18, 1e19, 1e20, 1e21, 1e22,
];

/// One argument of a functional form from [from]: `\s*`, a number of `reN`,
/// an optional `%` and `\s*`. Gives the number, with [_at] at the code unit
/// after it and [_form]. Gives NaN with [_at] at the code unit that fails the
/// grammar, or at a code unit outside ASCII after the number. The `)` at the
/// end of the text ends each loop, so no loop tests the length.
///
/// A number with at most 15 significant digits and a power of ten up to 22
/// is one IEEE multiplication or division of two exact doubles, which rounds
/// correctly, as [double.parse] does. Each other number is [double.parse].
double _arg(String s, int from) {
  var p = from;
  var c = s.codeUnitAt(p);
  while (_isSpace(c)) {
    c = s.codeUnitAt(++p);
  }
  final start = p;
  final negative = c == 0x2d;
  if (negative || c == 0x2b) c = s.codeUnitAt(++p); // - +
  // The digits as an integer, where the leading zeros add nothing. Below
  // 1e15, it has at most 15 significant digits and is exact; a 16th digit
  // makes it 1e15 or more, and then it takes no more digits.
  var m = 0;
  final whole = p;
  var d = c - 0x30;
  while (d >= 0 && d <= 9) {
    if (m < 1000000000000000) m = m * 10 + d;
    d = (c = s.codeUnitAt(++p)) - 0x30;
  }
  var form = _formInteger;
  var frac = 0;
  if (c == 0x2e) {
    // (?:\d*\.)?\d+
    form = _formNumber;
    final point = ++p;
    d = (c = s.codeUnitAt(p)) - 0x30;
    while (d >= 0 && d <= 9) {
      if (m < 1000000000000000) {
        m = m * 10 + d;
        frac++;
      }
      d = (c = s.codeUnitAt(++p)) - 0x30;
    }
    if (p == point) {
      _at = p;
      return double.nan;
    }
  } else if (p == whole) {
    _at = p;
    return double.nan;
  }
  var exponent = 0;
  var huge = false;
  if ((c | 0x20) == 0x65) {
    // (?:[eE][+-]?\d+)?
    form = _formNumber;
    c = s.codeUnitAt(++p);
    final down = c == 0x2d;
    if (down || c == 0x2b) c = s.codeUnitAt(++p);
    final digits = p;
    d = c - 0x30;
    while (d >= 0 && d <= 9) {
      if (exponent < 100000) {
        exponent = exponent * 10 + d;
      } else {
        huge = true;
      }
      d = (c = s.codeUnitAt(++p)) - 0x30;
    }
    if (p == digits) {
      _at = p;
      return double.nan;
    }
    if (down) exponent = -exponent;
  }
  final stop = p;
  if (c == 0x25) {
    form = _formPercent;
    c = s.codeUnitAt(++p);
  }
  while (_isSpace(c)) {
    c = s.codeUnitAt(++p);
  }
  _at = p;
  if (c >= 0x80) return double.nan;
  _form = form;
  // DIVERGES(d3-color): adapt-color-parse-number, exact path of double.parse.
  if (m == 0) return negative ? -0.0 : 0.0;
  if (m < 1000000000000000 && !huge) {
    final e = exponent - frac;
    if (e == 0) return negative ? -m.toDouble() : m.toDouble();
    if (e > 0 && e <= 22) {
      final v = m.toDouble() * _pow10[e];
      return negative ? -v : v;
    }
    if (e < 0 && e >= -22) {
      final v = m.toDouble() / _pow10[-e];
      return negative ? -v : v;
    }
  }
  return double.parse(s.substring(start, stop));
}

/// The names of [_named] and `transparent` in a table of open addressing by
/// a hash of the lowercase code units, so that a name of any case needs no
/// lowercase copy.
final class _NamedTable() {
  /// Puts each name into the table.
  this {
    final names = [..._named.keys, 'transparent'];
    for (var e = 0; e < names.length; e++) {
      final name = names[e];
      final h = _hash(name, 0, name.length);
      var slot = h & _mask;
      while (slots[slot] != 0) {
        slot = (slot + 1) & _mask;
      }
      slots[slot] = e + 1;
      keys.add(name);
      hashes.add(h);
      final value = _named[name];
      colors.add(
        value == null
            ? Rgb(double.nan, double.nan, double.nan, 0)
            : rgbn(value),
      );
    }
  }

  static const int _mask = 1023;

  /// The entry of each slot plus one: 0 is an empty slot.
  final List<int> slots = List<int>.filled(_mask + 1, 0);

  /// The name of each entry, in lowercase.
  final List<String> keys = [];

  /// The hash of each entry.
  final List<int> hashes = [];

  /// The color of each entry, which [color] copies.
  final List<Rgb> colors = [];

  /// The hash of the code units of [s] from [p] to [end], each lowercase.
  static int _hash(String s, int p, int end) {
    var h = 0;
    for (var k = p; k < end; k++) {
      h = (h * 31 + (s.codeUnitAt(k) | 0x20)) & 0x3fffffff;
    }
    return h;
  }

  /// The entry of the letters of [s] from [p] to [end] with the hash [h], or
  /// -1.
  int find(String s, int p, int end, int h) {
    final l = end - p;
    var slot = h & _mask;
    for (;;) {
      final e = slots[slot] - 1;
      if (e < 0) return -1;
      if (hashes[e] == h) {
        final key = keys[e];
        if (key.length == l) {
          var k = 0;
          while (k < l && (s.codeUnitAt(p + k) | 0x20) == key.codeUnitAt(k)) {
            k++;
          }
          if (k == l) return e;
        }
      }
      slot = (slot + 1) & _mask;
    }
  }
}

/// The table of [_named], made at its first use.
final _NamedTable _namedTable = _NamedTable();

/// `named` and `transparent`: the name from [p] to [end], in any case.
Color? _scanNamed(String s, int p, int end) {
  // DIVERGES(d3-color): adapt-color-named-table, names with no lowercase copy.
  var h = 0;
  for (var k = p; k < end; k++) {
    final c = s.codeUnitAt(k);
    final l = c | 0x20;
    if (l < 0x61 || l > 0x7a) return c >= 0x80 ? _colorRegExp(s) : null;
    h = (h * 31 + l) & 0x3fffffff;
  }
  final table = _namedTable;
  final e = table.find(s, p, end, h);
  if (e < 0) return null;
  final c = table.colors[e];
  return Rgb(c.r, c.g, c.b, c.opacity);
}

/// The upstream lines of color.js:201 `color(format)`, for a text with a
/// code unit outside ASCII.
Color? _colorRegExp(String specifier) {
  // DIVERGES(d3-color): platform-color-trim-lowercase, U+0085 and U+0130.
  if (_trimLowercaseDiffers(specifier)) return null;
  RegExpMatch? m;
  final format = specifier.trim().toLowerCase();
  if ((m = _reHex.firstMatch(format)) != null) {
    final digits = m!.group(1)!;
    final l = digits.length;
    final n = int.parse(digits, radix: 16);
    return l == 6
        ? rgbn(n) // #ff0000
        : l == 3
        ? Rgb(
            ((n >> 8 & 0xf) | (n >> 4 & 0xf0)).toDouble(),
            ((n >> 4 & 0xf) | (n & 0xf0)).toDouble(),
            (((n & 0xf) << 4) | (n & 0xf)).toDouble(),
          ) // #f00
        : l == 8
        ? rgba(
            (n >> 24 & 0xff).toDouble(),
            (n >> 16 & 0xff).toDouble(),
            (n >> 8 & 0xff).toDouble(),
            (n & 0xff) / 0xff,
          ) // #ff000000
        : l == 4
        ? rgba(
            ((n >> 12 & 0xf) | (n >> 8 & 0xf0)).toDouble(),
            ((n >> 8 & 0xf) | (n >> 4 & 0xf0)).toDouble(),
            ((n >> 4 & 0xf) | (n & 0xf0)).toDouble(),
            (((n & 0xf) << 4) | (n & 0xf)) / 0xff,
          ) // #f000
        : null; // invalid hex
  }
  if ((m = _reRgbInteger.firstMatch(format)) != null) {
    // rgb(255, 0, 0)
    return Rgb(_number(m!, 1), _number(m, 2), _number(m, 3));
  }
  if ((m = _reRgbPercent.firstMatch(format)) != null) {
    // rgb(100%, 0%, 0%)
    return Rgb(
      _number(m!, 1) * 255 / 100,
      _number(m, 2) * 255 / 100,
      _number(m, 3) * 255 / 100,
    );
  }
  if ((m = _reRgbaInteger.firstMatch(format)) != null) {
    // rgba(255, 0, 0, 1)
    return rgba(_number(m!, 1), _number(m, 2), _number(m, 3), _number(m, 4));
  }
  if ((m = _reRgbaPercent.firstMatch(format)) != null) {
    // rgb(100%, 0%, 0%, 1)
    return rgba(
      _number(m!, 1) * 255 / 100,
      _number(m, 2) * 255 / 100,
      _number(m, 3) * 255 / 100,
      _number(m, 4),
    );
  }
  if ((m = _reHslPercent.firstMatch(format)) != null) {
    // hsl(120, 50%, 50%)
    return hsla(_number(m!, 1), _number(m, 2) / 100, _number(m, 3) / 100, 1);
  }
  if ((m = _reHslaPercent.firstMatch(format)) != null) {
    // hsla(120, 50%, 50%, 1)
    return hsla(
      _number(m!, 1),
      _number(m, 2) / 100,
      _number(m, 3) / 100,
      _number(m, 4),
    );
  }
  final named = _named[format];
  if (named != null) return rgbn(named);
  return format == 'transparent'
      ? Rgb(double.nan, double.nan, double.nan, 0)
      : null;
}

/// Whether [text] has one of the two characters where Dart `trim()` and
/// `toLowerCase()` differ from JavaScript in a way that changes the result of
/// [color]. Dart `trim()` removes U+0085, and the Dart VM lowercases U+0130
/// to `i`. JavaScript keeps U+0085 and lowercases U+0130 to `i` and U+0307. No
/// upstream pattern or name matches these texts, so upstream returns null for
/// each of them.
bool _trimLowercaseDiffers(String text) {
  for (var i = 0; i < text.length; i++) {
    final c = text.codeUnitAt(i);
    if (c == 0x85 || c == 0x130) return true;
  }
  return false;
}

/// The number of the group [index] of [m]. The groups of the patterns hold
/// only decimal numbers, which [double.parse] reads.
double _number(RegExpMatch m, int index) => double.parse(m.group(index)!);

/// color.js:220 `rgbn(n)`: the opaque color of the 24-bit value [n].
Rgb rgbn(int n) => Rgb(
  (n >> 16 & 0xff).toDouble(),
  (n >> 8 & 0xff).toDouble(),
  (n & 0xff).toDouble(),
);

/// color.js:224 `rgba(r, g, b, a)`: an opacity at or below 0 makes the
/// channels undefined.
Rgb rgba(double r, double g, double b, double a) =>
    a <= 0 ? Rgb(double.nan, double.nan, double.nan, a) : Rgb(r, g, b, a);

/// color.js:229 `rgbConvert(o)`: a new [Rgb] with the channels of [o] in
/// RGB. A null [o] (a CSS text that did not parse) gives undefined channels
/// and an undefined opacity.
Rgb rgbConvert(Color? o) {
  if (o == null) return Rgb(double.nan, double.nan, double.nan, double.nan);
  final c = o.rgb();
  return Rgb(c.r, c.g, c.b, c.opacity);
}

/// color.js:240 `Rgb` and the factory `rgb` (color.js:236): a color in the
/// sRGB space. Each channel is in [0, 255] for a color in the gamut.
// DIVERGES(d3-color): adapt-color-factories, constructors for the overloads.
class Rgb(
  /// The red channel.
  var double r,

  /// The green channel.
  var double g,

  /// The blue channel.
  var double b, [
  @override var double opacity = 1,
]) extends Color {
  /// `rgb(r, g, b[, opacity])`. The channels are not rounded or clamped.
  this;

  /// `rgb(color)`: a new [Rgb] with the channels of [color] in RGB.
  factory from(Color color) => rgbConvert(color);

  /// `rgb(specifier)`: the color of the CSS text [specifier] in RGB. A text
  /// that [color] does not read gives undefined channels and opacity.
  factory parse(String specifier) {
    final o = color(specifier);
    return o is Rgb ? o : rgbConvert(o);
  }

  @override
  Rgb copy({double? r, double? g, double? b, double? opacity}) =>
      Rgb(r ?? this.r, g ?? this.g, b ?? this.b, opacity ?? this.opacity);

  /// color.js:248 `brighter(k)`.
  @override
  Rgb brighter([double? k]) {
    final f = k == null ? _brighter : math.pow(_brighter, k).toDouble();
    return Rgb(r * f, g * f, b * f, opacity);
  }

  /// color.js:252 `darker(k)`.
  @override
  Rgb darker([double? k]) {
    final f = k == null ? _darker : math.pow(_darker, k).toDouble();
    return Rgb(r * f, g * f, b * f, opacity);
  }

  /// color.js:256 `rgb()`: this color.
  @override
  Rgb rgb() => this;

  /// color.js:259 `clamp()`: a copy with the channels rounded and clamped to
  /// [0, 255], and the opacity clamped to [0, 1].
  Rgb clamp() => Rgb(
    clampi(r).toDouble(),
    clampi(g).toDouble(),
    clampi(b).toDouble(),
    clampa(opacity),
  );

  /// color.js:262 `displayable()`.
  @override
  bool displayable() =>
      (-0.5 <= r && r < 255.5) &&
      (-0.5 <= g && g < 255.5) &&
      (-0.5 <= b && b < 255.5) &&
      (0 <= opacity && opacity <= 1);

  /// color.js:275 `rgb_formatHex`.
  @override
  String formatHex() {
    if (_joinStrings) return '#${hex2(r)}${hex2(g)}${hex2(b)}';
    // DIVERGES(d3-color): adapt-color-format-units, the code units of the text.
    return _hexText(clampi(r), clampi(g), clampi(b), -1);
  }

  /// color.js:279 `rgb_formatHex8`.
  @override
  String formatHex8() {
    if (_joinStrings) {
      return '#${hex2(r)}${hex2(g)}${hex2(b)}'
          '${hex2((opacity.isNaN ? 1 : opacity) * 255)}';
    }
    // DIVERGES(d3-color): adapt-color-format-units, the code units of the text.
    final x = clampi(r);
    final y = clampi(g);
    final z = clampi(b);
    return _hexText(x, y, z, clampi((opacity.isNaN ? 1 : opacity) * 255));
  }

  /// color.js:283 `rgb_formatRgb`.
  @override
  String formatRgb() {
    final a = clampa(opacity);
    if (_joinStrings) {
      // DIVERGES(d3-color): adapt-color-format-units, the texts of 0 to 255.
      return '${a == 1 ? 'rgb(' : 'rgba('}${_decimalTexts[clampi(r)]}, '
          '${_decimalTexts[clampi(g)]}, ${_decimalTexts[clampi(b)]}'
          '${a == 1 ? ')' : ', ${numberText(a)})'}';
    }
    // DIVERGES(d3-color): adapt-color-format-units, the code units of the text.
    final x = clampi(r);
    final y = clampi(g);
    final z = clampi(b);
    final units = _units;
    var p = _putOpen(units, 0x72, 0x67, 0x62, alpha: a != 1); // rgb( or rgba(
    p = _putInteger(units, p, x);
    p = _putInteger(units, _putSeparator(units, p), y);
    p = _putInteger(units, _putSeparator(units, p), z);
    if (a != 1) p = _putNumber(units, _putSeparator(units, p), a);
    units[p++] = 0x29; // )
    return String.fromCharCodes(units, 0, p);
  }
}

/// color.js:288 `clampa(opacity)`: an undefined opacity is 1, other values
/// clamp to [0, 1].
double clampa(double opacity) =>
    opacity.isNaN ? 1 : math.max(0, math.min(1, opacity));

/// color.js:292 `clampi(value)`: [value] rounded and clamped to [0, 255]. An
/// undefined value is 0.
///
/// `Math.round(value) || 0` is 0 for a value below 0.5, NaN included, and
/// 255 or more for a value from 254.5. In between, `Math.round(value)` is
/// the floor of `value + 0.5`, and the double sum `value + 0.5` never rounds
/// across a whole number for a value from 0.5, so its truncation is the
/// result.
int clampi(double value) {
  // DIVERGES(d3-color): adapt-color-clamp-compare, compares, no Math.round.
  if (!(value >= 0.5)) return 0;
  if (value >= 254.5) return 255;
  return (value + 0.5).toInt();
}

/// color.js:296 `hex(value)`: [value] as two lowercase hexadecimal digits,
/// after [clampi].
String hex2(double value) {
  // DIVERGES(d3-color): adapt-color-hex-table, the 256 texts in a table.
  return _hexTexts[clampi(value)];
}

/// The texts of [hex2]: `00` to `ff`.
final List<String> _hexTexts = [
  for (var v = 0; v < 256; v++) _hexDigits[v >> 4] + _hexDigits[v & 15],
];

/// The lowercase hexadecimal digits.
const String _hexDigits = '0123456789abcdef';

/// The text of the number [x] in a CSS text of a color: a whole number with
/// no fraction (`0` also for -0), any other number as [double.toString].
/// The color formats give only numbers in [0, 360] to it.
///
/// The text of a number k / 100 comes from the digits of k, with no
/// conversion of the double ([_hundredths]).
String numberText(double x) {
  // DIVERGES(d3-color): adapt-color-number-text, the digits of k / 100.
  final k = _hundredths(x);
  if (k >= 0) {
    final whole = k ~/ 100;
    final fraction = k - whole * 100;
    return fraction == 0
        ? _decimalTexts[whole]
        : '${_decimalTexts[whole]}${_fractionTexts[fraction]}';
  }
  return x == x.truncateToDouble() ? x.toInt().toString() : x.toString();
}

/// The whole number k in [0, 36000] when [x] is the double nearest to
/// k / 100, else -1.
///
/// The double division `k / 100` gives the double nearest to k / 100, so
/// the test is exact. Such an [x] has the text of the decimal k / 100 with
/// no trailing zero: that decimal reads back as [x], and each other decimal
/// with as few digits is a multiple of 0.01 away from it, much more than the
/// gap of two doubles below 360. Thus it is the shortest text of [x], the
/// text of JavaScript and of [double.toString].
int _hundredths(double x) {
  if (x >= 0 && x <= 360) {
    final k = (x * 100 + 0.5).toInt();
    if (k / 100 == x) return k;
  }
  return -1;
}

/// The decimal texts of 0 to 360: the whole part of [numberText], and the
/// channels of [Rgb.formatRgb] in JavaScript.
final List<String> _decimalTexts = [for (var v = 0; v <= 360; v++) '$v'];

/// The texts of the fraction f / 100 for f in [1, 99], with no trailing
/// zero: `.01` to `.99`, and `.1` for 10. The item 0 is not read.
final List<String> _fractionTexts = [
  for (var f = 0; f < 100; f++)
    if (f % 10 == 0) '.${f ~/ 10}' else '.${f ~/ 10}${f % 10}',
];

/// Whether the code runs as JavaScript (dart2js or DDC). There, the formats
/// join strings, as upstream: the JavaScript engine joins them fast. On the
/// VM and in WebAssembly, the formats write code units into [_units].
const bool _joinStrings =
    bool.fromEnvironment('dart.library.js_interop') && !_wasm;

/// Whether the code runs as WebAssembly (dart2wasm).
const bool _wasm = bool.fromEnvironment('dart.tool.dart2wasm');

/// The code units of the text of a format, before [String.fromCharCodes]
/// makes the string: one byte each on the VM (a one-byte string), two bytes
/// in WebAssembly (a JavaScript string).
///
/// A format reads each channel before it writes into the buffer, so no code
/// of a subclass runs between the writes. 128 code units hold the longest
/// text: `hsla(` with four numbers of at most 24 characters.
final List<int> _units = _wasm ? Uint16List(128) : Uint8List(128);

/// Writes `#` and the hexadecimal digits of the channels [r], [g], [b] in
/// [0, 255] into [_units], and of [a] unless it is -1, and gives the text.
String _hexText(int r, int g, int b, int a) {
  final units = _units;
  units[0] = 0x23; // #
  _putHex(units, 1, r);
  _putHex(units, 3, g);
  _putHex(units, 5, b);
  if (a < 0) return String.fromCharCodes(units, 0, 7);
  _putHex(units, 7, a);
  return String.fromCharCodes(units, 0, 9);
}

/// Writes the two hexadecimal digits of [v] in [0, 255] at [p] of [units].
void _putHex(List<int> units, int p, int v) {
  units[p] = _hexDigits.codeUnitAt(v >> 4);
  units[p + 1] = _hexDigits.codeUnitAt(v & 15);
}

/// Writes the three letters [c0], [c1] and [c2] of a function name, `a` when
/// [alpha], and `(` at the start of [units], and gives the next position.
int _putOpen(List<int> units, int c0, int c1, int c2, {required bool alpha}) {
  units[0] = c0;
  units[1] = c1;
  units[2] = c2;
  if (!alpha) {
    units[3] = 0x28; // (
    return 4;
  }
  units[3] = 0x61; // a
  units[4] = 0x28; // (
  return 5;
}

/// Writes `, ` at [p] of [units] and gives the next position.
int _putSeparator(List<int> units, int p) {
  units[p] = 0x2c; // ,
  units[p + 1] = 0x20; // space
  return p + 2;
}

/// Writes the decimal digits of [v] in [0, 999] at [p] of [units] and gives
/// the next position.
int _putInteger(List<int> units, int p, int v) {
  if (v < 10) {
    units[p] = 0x30 + v;
    return p + 1;
  }
  var q = p;
  var rest = v;
  if (v >= 100) {
    final hundreds = v ~/ 100;
    units[q++] = 0x30 + hundreds;
    rest -= hundreds * 100;
  }
  final tens = rest ~/ 10;
  units[q] = 0x30 + tens;
  units[q + 1] = 0x30 + rest - tens * 10;
  return q + 2;
}

/// Writes [numberText] of [x] at [p] of [units] and gives the next position.
int _putNumber(List<int> units, int p, double x) {
  final k = _hundredths(x);
  if (k < 0) {
    final text = numberText(x);
    final n = text.length;
    for (var i = 0; i < n; i++) {
      units[p + i] = text.codeUnitAt(i);
    }
    return p + n;
  }
  final whole = k ~/ 100;
  final fraction = k - whole * 100;
  final q = _putInteger(units, p, whole);
  if (fraction == 0) return q;
  final tenths = fraction ~/ 10;
  final hundredths = fraction - tenths * 10;
  units[q] = 0x2e; // .
  units[q + 1] = 0x30 + tenths;
  if (hundredths == 0) return q + 2;
  units[q + 2] = 0x30 + hundredths;
  return q + 3;
}

/// color.js:301 `hsla(h, s, l, a)`: the [Hsl] of a parsed CSS text. An
/// opacity at or below 0 makes the channels undefined, a lightness outside
/// (0, 1) makes the hue and the saturation undefined, and a saturation at or
/// below 0 makes the hue undefined.
Hsl hsla(double h, double s, double l, double a) {
  const nan = double.nan;
  if (a <= 0) return Hsl(nan, nan, nan, a);
  if (l <= 0 || l >= 1) return Hsl(nan, nan, l, a);
  if (s <= 0) return Hsl(nan, s, l, a);
  return Hsl(h, s, l, a);
}

/// color.js:308 `hslConvert(o)`: a new [Hsl] with the channels of [o] in
/// HSL. A null [o] gives undefined channels and an undefined opacity.
Hsl hslConvert(Color? o) {
  if (o is Hsl) return Hsl(o.h, o.s, o.l, o.opacity);
  if (o == null) return Hsl(double.nan, double.nan, double.nan, double.nan);
  final c = o.rgb();
  final r = c.r / 255.0;
  final g = c.g / 255.0;
  final b = c.b / 255.0;
  final min = math.min(r, math.min(g, b));
  final max = math.max(r, math.max(g, b));
  var h = double.nan;
  var s = max - min;
  final l = (max + min) / 2.0;
  // `if (s)`: s is neither 0 nor NaN.
  if (s != 0.0 && !s.isNaN) {
    if (r == max) {
      h = (g - b) / s + (g < b ? 6.0 : 0.0);
    } else if (g == max) {
      h = (b - r) / s + 2.0;
    } else {
      h = (r - g) / s + 4.0;
    }
    s /= l < 0.5 ? max + min : 2.0 - max - min;
    h *= 60.0;
  } else {
    s = l > 0.0 && l < 1.0 ? 0 : h;
  }
  return Hsl(h, s, l, c.opacity);
}

/// color.js:338 `Hsl` and the factory `hsl` (color.js:334): a color in the
/// HSL space. The hue is in degrees, the saturation and the lightness in
/// [0, 1].
// DIVERGES(d3-color): adapt-color-factories, constructors for the overloads.
class Hsl(
  /// The hue in degrees.
  var double h,

  /// The saturation.
  var double s,

  /// The lightness.
  var double l, [
  @override var double opacity = 1,
]) extends Color {
  /// `hsl(h, s, l[, opacity])`. The hue does not wrap and the channels do
  /// not clamp.
  this;

  /// `hsl(color)`: a new [Hsl] with the channels of [color] in HSL.
  factory from(Color color) => hslConvert(color);

  /// `hsl(specifier)`: the color of the CSS text [specifier] in HSL. A text
  /// that [color] does not read gives undefined channels and opacity.
  factory parse(String specifier) {
    final o = color(specifier);
    return o is Hsl ? o : hslConvert(o);
  }

  @override
  Hsl copy({double? h, double? s, double? l, double? opacity}) =>
      Hsl(h ?? this.h, s ?? this.s, l ?? this.l, opacity ?? this.opacity);

  /// color.js:346 `brighter(k)`.
  @override
  Hsl brighter([double? k]) {
    final f = k == null ? _brighter : math.pow(_brighter, k).toDouble();
    return Hsl(h, s, l * f, opacity);
  }

  /// color.js:350 `darker(k)`.
  @override
  Hsl darker([double? k]) {
    final f = k == null ? _darker : math.pow(_darker, k).toDouble();
    return Hsl(h, s, l * f, opacity);
  }

  /// color.js:354 `rgb()`.
  @override
  Rgb rgb() {
    // JavaScript `%` is the truncated remainder: Dart `remainder`.
    final h0 = this.h;
    // DIVERGES(d3-color): adapt-color-hsl-hue-wrap, no remainder below 360.
    final h =
        (h0 > -360.0 && h0 < 360.0 ? h0 : h0.remainder(360.0)) +
        (h0 < 0.0 ? 360.0 : 0.0);
    final s = h.isNaN || this.s.isNaN ? 0.0 : this.s;
    final l = this.l;
    final m2 = l + (l < 0.5 ? l : 1.0 - l) * s;
    final m1 = 2.0 * l - m2;
    return Rgb(
      hsl2rgb(h >= 240.0 ? h - 240.0 : h + 120.0, m1, m2),
      hsl2rgb(h, m1, m2),
      hsl2rgb(h < 120.0 ? h + 240.0 : h - 120.0, m1, m2),
      opacity,
    );
  }

  /// color.js:367 `clamp()`: a copy with the hue in [0, 360), the saturation
  /// and the lightness in [0, 1], and the opacity in [0, 1].
  Hsl clamp() => Hsl(clamph(h), clampt(s), clampt(l), clampa(opacity));

  /// color.js:370 `displayable()`.
  @override
  bool displayable() =>
      (0 <= s && s <= 1 || s.isNaN) &&
      (0 <= l && l <= 1) &&
      (0 <= opacity && opacity <= 1);

  /// color.js:375 `formatHsl()`.
  @override
  String formatHsl() {
    final a = clampa(opacity);
    if (_joinStrings) {
      return '${a == 1 ? 'hsl(' : 'hsla('}${numberText(clamph(h))}, '
          '${numberText(clampt(s) * 100)}%, ${numberText(clampt(l) * 100)}%'
          '${a == 1 ? ')' : ', ${numberText(a)})'}';
    }
    // DIVERGES(d3-color): adapt-color-format-units, the code units of the text.
    final hue = clamph(h);
    final saturation = clampt(s) * 100;
    final lightness = clampt(l) * 100;
    final units = _units;
    var p = _putOpen(units, 0x68, 0x73, 0x6c, alpha: a != 1); // hsl( or hsla(
    p = _putNumber(units, p, hue);
    p = _putNumber(units, _putSeparator(units, p), saturation);
    units[p++] = 0x25; // %
    p = _putNumber(units, _putSeparator(units, p), lightness);
    units[p++] = 0x25; // %
    if (a != 1) p = _putNumber(units, _putSeparator(units, p), a);
    units[p++] = 0x29; // )
    return String.fromCharCodes(units, 0, p);
  }
}

/// color.js:381 `clamph(value)`: [value] in [0, 360). An undefined value is
/// 0.
double clamph(double value) {
  // DIVERGES(d3-color): adapt-color-clamp-compare, no % for a hue in (0, 360).
  if (value > 0 && value < 360) return value;
  // `value || 0`: NaN and -0 are 0.
  final v = (value.isNaN || value == 0 ? 0.0 : value).remainder(360);
  return v < 0 ? v + 360 : v;
}

/// color.js:386 `clampt(value)`: [value] in [0, 1]. An undefined value is 0.
double clampt(double value) =>
    math.max(0, math.min(1, value.isNaN ? 0 : value));

/// color.js:391 `hsl2rgb(h, m1, m2)`: one RGB channel of an HSL color, from
/// FvD 13.37, CSS Color Module Level 3.
double hsl2rgb(double h, double m1, double m2) =>
    (h < 60.0
        ? m1 + (m2 - m1) * h / 60.0
        : h < 180.0
        ? m2
        : h < 240.0
        ? m1 + (m2 - m1) * (240.0 - h) / 60.0
        : m1) *
    255.0;
