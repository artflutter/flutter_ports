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
Color? color(String specifier) {
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
  String formatHex() => '#${hex2(r)}${hex2(g)}${hex2(b)}';

  /// color.js:279 `rgb_formatHex8`.
  @override
  String formatHex8() =>
      '#${hex2(r)}${hex2(g)}${hex2(b)}'
      '${hex2((opacity.isNaN ? 1 : opacity) * 255)}';

  /// color.js:283 `rgb_formatRgb`.
  @override
  String formatRgb() {
    final a = clampa(opacity);
    return '${a == 1 ? 'rgb(' : 'rgba('}${clampi(r)}, ${clampi(g)}, '
        '${clampi(b)}${a == 1 ? ')' : ', ${numberText(a)})'}';
  }
}

/// color.js:288 `clampa(opacity)`: an undefined opacity is 1, other values
/// clamp to [0, 1].
double clampa(double opacity) =>
    opacity.isNaN ? 1 : math.max(0, math.min(1, opacity));

/// color.js:292 `clampi(value)`: [value] rounded and clamped to [0, 255]. An
/// undefined value is 0.
///
/// `Math.round` rounds a half up and `roundToDouble` rounds it away from 0.
/// The two differ only below 0, where the clamp gives 0.
int clampi(double value) {
  final v = value.roundToDouble();
  return v > 0 ? (v < 255 ? v.toInt() : 255) : 0;
}

/// color.js:296 `hex(value)`: [value] as two lowercase hexadecimal digits,
/// after [clampi].
String hex2(double value) {
  final v = clampi(value);
  return (v < 16 ? '0' : '') + v.toRadixString(16);
}

/// The text of the number [x] in a CSS text of a color: a whole number with
/// no fraction (`0` also for -0), any other number as [double.toString].
/// The color formats give only numbers in [0, 360] to it.
String numberText(double x) =>
    x == x.truncateToDouble() ? x.toInt().toString() : x.toString();

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
  final r = c.r / 255;
  final g = c.g / 255;
  final b = c.b / 255;
  final min = math.min(r, math.min(g, b));
  final max = math.max(r, math.max(g, b));
  var h = double.nan;
  var s = max - min;
  final l = (max + min) / 2;
  // `if (s)`: s is neither 0 nor NaN.
  if (s != 0 && !s.isNaN) {
    if (r == max) {
      h = (g - b) / s + (g < b ? 6 : 0);
    } else if (g == max) {
      h = (b - r) / s + 2;
    } else {
      h = (r - g) / s + 4;
    }
    s /= l < 0.5 ? max + min : 2 - max - min;
    h *= 60;
  } else {
    s = l > 0 && l < 1 ? 0 : h;
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
    final h = this.h.remainder(360) + (this.h < 0 ? 360 : 0);
    final s = h.isNaN || this.s.isNaN ? 0 : this.s;
    final l = this.l;
    final m2 = l + (l < 0.5 ? l : 1 - l) * s;
    final m1 = 2 * l - m2;
    return Rgb(
      hsl2rgb(h >= 240 ? h - 240 : h + 120, m1, m2),
      hsl2rgb(h, m1, m2),
      hsl2rgb(h < 120 ? h + 240 : h - 120, m1, m2),
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
    return '${a == 1 ? 'hsl(' : 'hsla('}${numberText(clamph(h))}, '
        '${numberText(clampt(s) * 100)}%, ${numberText(clampt(l) * 100)}%'
        '${a == 1 ? ')' : ', ${numberText(a)})'}';
  }
}

/// color.js:381 `clamph(value)`: [value] in [0, 360). An undefined value is
/// 0.
double clamph(double value) {
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
    (h < 60
        ? m1 + (m2 - m1) * h / 60
        : h < 180
        ? m2
        : h < 240
        ? m1 + (m2 - m1) * (240 - h) / 60
        : m1) *
    255;
