// Ported from @kurkle/color v0.3.2 src/color.js (MIT, Jukka Kurkela).

// The methods of Color return this for chaining, as upstream does.
// ignore_for_file: avoid_returning_this

/// Port of `src/color.js` of @kurkle/color 0.3.2: the class [Color].
///
/// The methods `rgbString`, `hexString`, `hslString`, `rotate` and
/// `interpolate` have the names of the module functions that they call. In a
/// Dart class, a bare name finds the member first. Thus the imports of these
/// functions have a prefix with the name of their upstream module.
///
/// A [Color] whose input does not parse has no color: its `_rgb` is JS
/// `undefined`, Dart `null` here. The methods that read `_rgb` without a test
/// throw for such a color, as they throw a `TypeError` in JavaScript. A Dart
/// null check throws a `TypeError` too.
///
/// @packageDocumentation
/// @module index
library;

import 'package:flutter_chartjs/src/js/js_math.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/kurkle_color/byte.dart'
    show b2n, n2b, round;
import 'package:flutter_chartjs/src/kurkle_color/hex.dart' show hexParse;
import 'package:flutter_chartjs/src/kurkle_color/hex.dart'
    as hex_js
    show hexString;
import 'package:flutter_chartjs/src/kurkle_color/hue.dart'
    show hsl2rgb, hueParse, rgb2hsl;
import 'package:flutter_chartjs/src/kurkle_color/hue.dart'
    as hue_js
    show hslString, rotate;
import 'package:flutter_chartjs/src/kurkle_color/index.esm.dart' show RGBA;
import 'package:flutter_chartjs/src/kurkle_color/names.dart' show nameParse;
import 'package:flutter_chartjs/src/kurkle_color/rgb.dart' show rgbParse;
import 'package:flutter_chartjs/src/kurkle_color/rgb.dart'
    as rgb_js
    show rgbString;
import 'package:flutter_chartjs/src/kurkle_color/srgb.dart' as srgb_js;

/// color.js:24 `modHSL`.
///
/// Modify HSL properties. [i] is the index [0=h, 1=s, 2=l], and [ratio] the
/// ratio [0..1].
void _modHSL(RGBA? v, int i, double ratio) {
  if (v != null) {
    var tmp = rgb2hsl(v);
    tmp[i] = jsMax(
      0,
      jsMin(tmp[i] + tmp[i] * ratio, i == 0 ? 360 : 1),
    );
    tmp = hsl2rgb(tmp);
    v
      ..r = tmp[0]
      ..g = tmp[1]
      ..b = tmp[2];
  }
}

/// color.js:41 `clone`.
///
/// `v ? Object.assign(proto || {}, v) : v`. A falsy [v] gives Dart `null`.
/// The callers then throw, as JavaScript throws a `TypeError` when it sets
/// `a` on `null`, `undefined` or another falsy primitive in strict mode. A
/// truthy value that is not an [RGBA] or a `Map` has no own `r`, `g`, `b`
/// and `a`, so the copy changes nothing.
RGBA? _clone(Object? v, [RGBA? proto]) {
  if (!jsTruthy(v)) {
    return null;
  }
  // The members of `{}` are undefined, which ToNumber makes NaN.
  final target =
      proto ?? RGBA(r: double.nan, g: double.nan, b: double.nan, a: double.nan);
  // DIVERGES(chartjs): adapt-kurkle-rgba, copy r, g, b and a as numbers.
  if (v is RGBA) {
    target
      ..r = v.r
      ..g = v.g
      ..b = v.b
      ..a = v.a;
  } else if (v is Map) {
    if (v.containsKey('r')) target.r = jsToNumber(v['r']);
    if (v.containsKey('g')) target.g = jsToNumber(v['g']);
    if (v.containsKey('b')) target.b = jsToNumber(v['b']);
    if (v.containsKey('a')) target.a = jsToNumber(v['a']);
  }
  return target;
}

/// color.js:49 `fromObject`.
///
/// [input] is an RGBA object or a `List` (a JS array).
RGBA _fromObject(Object? input) {
  var v = RGBA(r: 0, g: 0, b: 0, a: 255);
  if (input is List) {
    if (input.length >= 3) {
      v = RGBA(
        // DIVERGES(chartjs): adapt-kurkle-rgba, ToNumber of r, g and b.
        r: jsToNumber(input[0]),
        g: jsToNumber(input[1]),
        b: jsToNumber(input[2]),
        a: 255,
      );
      if (input.length > 3) {
        v.a = n2b(jsToNumber(input[3]));
      }
    }
  } else {
    // A falsy input throws here, as `v.a` throws a TypeError in JavaScript.
    v = _clone(input, RGBA(r: 0, g: 0, b: 0, a: 1))!;
    v.a = n2b(v.a);
  }
  return v;
}

/// color.js:69 `functionParse`.
RGBA? _functionParse(String str) {
  // str.charAt(0) of '' is ''.
  if (str.startsWith('r')) {
    return rgbParse(str);
  }
  return hueParse(str);
}

/// `typeof value` for the Dart values that stand for JS values
/// (js_number.dart): `null` and every object that is not a function are
/// `'object'`.
String _typeOf(Object? value) => switch (value) {
  Undefined() => 'undefined',
  bool() => 'boolean',
  num() => 'number',
  String() => 'string',
  Symbol() => 'symbol',
  Function() => 'function',
  _ => 'object',
};

/// color.js:76 `Color`, the default export of `color.js`.
///
/// The color is mutable. Each manipulation method changes this color and
/// returns it.
class Color {
  /// color.js:81 `constructor`.
  ///
  /// [input] is a [Color], an RGBA object (an [RGBA] or a `Map` with the keys
  /// `r`, `g`, `b` and `a`), a CSS color string or a `List` `[r, g, b]` or
  /// `[r, g, b, a]`. The `a` of an object or a list is alpha [0..1].
  ///
  /// A [Color] input gives that instance, as the JS constructor returns it.
  /// Another input that is not an object or a string gives a color that is
  /// not [valid]. Dart `null` is JS `null`: as in JavaScript, it throws. Pass
  /// the `undefined` sentinel for JS `undefined`.
  factory Color(Object? input) {
    if (input is Color) {
      return input;
    }
    final type = _typeOf(input);
    RGBA? v;
    if (type == 'object') {
      v = _fromObject(input);
    } else if (input is String) {
      v = hexParse(input) ?? nameParse(input) ?? _functionParse(input);
    }
    return Color._(v);
  }

  Color._(this._rgb) : _valid = _rgb != null;

  /// color.js:96 `_rgb`. The [RGBA] with `a` as a byte [0..255]. Dart `null`
  /// stands for JS `undefined`: the input did not parse.
  RGBA? _rgb;

  /// color.js:98 `_valid`.
  final bool _valid;

  /// color.js:105 `valid`.
  ///
  /// `true` if this is a valid color
  bool get valid {
    return _valid;
  }

  /// color.js:112 `get rgb`.
  ///
  /// A copy of the color with `a` as alpha [0..1]. Dart `null` stands for JS
  /// `undefined`, the color of an input that did not parse.
  RGBA? get rgb {
    final v = _clone(_rgb);
    if (v != null) {
      v.a = b2n(v.a);
    }
    return v;
  }

  /// color.js:123 `set rgb`.
  ///
  /// [obj] is an RGBA object or a `List`, with `a` as alpha [0..1]. It
  /// does not change [valid].
  set rgb(Object? obj) {
    _rgb = _fromObject(obj);
  }

  /// color.js:131 `rgbString`.
  ///
  /// rgb(a) string. Dart `null` stands for JS `undefined`.
  String? rgbString() {
    return _valid ? rgb_js.rgbString(_rgb) : null;
  }

  /// color.js:139 `hexString`.
  ///
  /// hex string. Dart `null` stands for JS `undefined`.
  String? hexString() {
    return _valid ? hex_js.hexString(_rgb) : null;
  }

  /// color.js:147 `hslString`.
  ///
  /// hsl(a) string. Dart `null` stands for JS `undefined`.
  String? hslString() {
    return _valid ? hue_js.hslString(_rgb) : null;
  }

  /// color.js:157 `mix`.
  ///
  /// Mix another color to this color. [weight] is 0..1. Dart `null` stands
  /// for an `undefined` [color] or [weight]. Chart.js passes a number.
  Color mix(Color? color, [double? weight]) {
    if (color != null) {
      final c1 = rgb;
      final c2 = color.rgb;
      // weight === w2 ? 0.5 : weight, where w2 is still undefined.
      final p = weight ?? 0.5;
      final w = 2 * p - 1;
      final a = c1!.a - c2!.a;
      final w1 = ((w * a == -1 ? w : (w + a) / (1 + w * a)) + 1) / 2.0;
      final w2 = 1 - w1;
      // 0xFF & x: 255 & ToInt32(x).
      c1
        ..r = (0xFF & jsToInt32(w1 * c1.r + w2 * c2.r + 0.5).toInt()).toDouble()
        ..g = (0xFF & jsToInt32(w1 * c1.g + w2 * c2.g + 0.5).toInt()).toDouble()
        ..b = (0xFF & jsToInt32(w1 * c1.b + w2 * c2.b + 0.5).toInt()).toDouble()
        ..a = p * c1.a + (1 - p) * c2.a;
      rgb = c1;
    }
    return this;
  }

  /// color.js:182 `interpolate`.
  ///
  /// Interpolate a color value between this and [color]. [t] is 0..1.
  Color interpolate(Color? color, double t) {
    if (color != null) {
      _rgb = srgb_js.interpolate(_rgb!, color._rgb!, t);
    }
    return this;
  }

  /// color.js:193 `clone`.
  Color clone() {
    // `new Color(this.rgb)`: rgb is undefined for a color that did not
    // parse. The constructor takes Dart null as JS null, so pass the sentinel.
    return Color(rgb ?? undefined);
  }

  /// color.js:202 `alpha`.
  ///
  /// Set aplha. [a] is the alpha [0..1].
  Color alpha(double a) {
    _rgb!.a = n2b(a);
    return this;
  }

  /// color.js:212 `clearer`.
  ///
  /// Make clearer. [ratio] is 0..1.
  Color clearer(double ratio) {
    // const rgb = this._rgb; rgb.a *= 1 - ratio;
    _rgb!.a *= 1 - ratio;
    return this;
  }

  /// color.js:222 `greyscale`.
  ///
  /// Convert to grayscale.
  Color greyscale() {
    final rgb = _rgb!;
    // http://en.wikipedia.org/wiki/Grayscale#Converting_color_to_grayscale
    final val = round(rgb.r * 0.3 + rgb.g * 0.59 + rgb.b * 0.11);
    rgb
      ..r = val
      ..g = val
      ..b = val;
    return this;
  }

  /// color.js:235 `opaquer`.
  ///
  /// Opaquer. [ratio] is 0..1.
  Color opaquer(double ratio) {
    // const rgb = this._rgb; rgb.a *= 1 + ratio;
    _rgb!.a *= 1 + ratio;
    return this;
  }

  /// color.js:245 `negate`.
  ///
  /// Negates the rgb value.
  Color negate() {
    final v = _rgb!;
    v
      ..r = 255 - v.r
      ..g = 255 - v.g
      ..b = 255 - v.b;
    return this;
  }

  /// color.js:258 `lighten`.
  ///
  /// Lighten. [ratio] is 0..1.
  Color lighten(double ratio) {
    _modHSL(_rgb, 2, ratio);
    return this;
  }

  /// color.js:268 `darken`.
  ///
  /// Darken. [ratio] is 0..1.
  Color darken(double ratio) {
    _modHSL(_rgb, 2, -ratio);
    return this;
  }

  /// color.js:278 `saturate`.
  ///
  /// Saturate. [ratio] is 0..1.
  Color saturate(double ratio) {
    _modHSL(_rgb, 1, ratio);
    return this;
  }

  /// color.js:288 `desaturate`.
  ///
  /// Desaturate. [ratio] is 0..1.
  Color desaturate(double ratio) {
    _modHSL(_rgb, 1, -ratio);
    return this;
  }

  /// color.js:298 `rotate`.
  ///
  /// Rotate by [deg] degrees.
  Color rotate(double deg) {
    hue_js.rotate(_rgb!, deg);
    return this;
  }
}
