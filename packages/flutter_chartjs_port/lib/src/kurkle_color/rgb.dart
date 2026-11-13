// Ported from @kurkle/color v0.3.2 src/rgb.js (MIT, Jukka Kurkela).

/// Port of `src/rgb.js` of @kurkle/color 0.3.2: the functional notation
/// `rgb()` and `rgba()`.
///
/// Dart `RegExp` has the syntax and the semantics of JavaScript regular
/// expressions. A group that does not take part in the match is `undefined`
/// in JavaScript and `null` in Dart.
///
/// @packageDocumentation
/// @module utils
library;

import 'dart:typed_data';

import 'package:flutter_chartjs_port/src/kurkle_color/byte.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/index.esm.dart' show RGBA;
import 'package:flutter_chartjs_port/src/kurkle_color/numbers.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/simple_parse.dart';

/// rgb.js:15 `RGB_RE`.
final RegExp _rgbRe = RegExp(
  r'^rgba?\(\s*([-+.\d]+)(%)?[\s,]+([-+.e\d]+)(%)?[\s,]+([-+.e\d]+)(%)?(?:[\s,/]+([-+.e\d]+)(%)?)?\s*\)$',
);

// Native JS string concatenation is faster than copying an ASCII buffer.
const bool _javascript =
    bool.fromEnvironment('dart.library.js_interop') &&
    !bool.fromEnvironment('dart.tool.dart2wasm');

/// rgb.js:22 `rgbParse`.
///
/// Parse rgb(a) string to RGBA. Dart `null` stands for the JS `undefined`
/// result.
RGBA? rgbParse(String str) {
  // DIVERGES(chartjs): adapt-kurkle-simple-colors, performance optimisations.
  final start = _rgbStart(str);
  if (start != 0) {
    final simple = simpleColor(str, start, percentages: false);
    if (simple != null) {
      simple
        ..r = simple.r > 255 ? 255 : simple.r
        ..g = simple.g > 255 ? 255 : simple.g
        ..b = simple.b > 255 ? 255 : simple.b
        ..a = lim(simple.a * 255, 0, 255);
      return simple;
    }
  }
  final m = _rgbRe.firstMatch(str);
  var a = 255.0;
  double r;
  double g;
  double b;

  if (m == null) {
    return null;
  }

  // r is undefined
  // DIVERGES(chartjs): adapt-kurkle-decimal-groups, performance optimisations.
  if (m[7] != null) {
    final v = double.tryParse(m[7]!) ?? double.nan;
    a = m[8] != null ? p2b(v) : lim(v * 255, 0, 255);
  }

  r = double.tryParse(m[1]!) ?? double.nan;
  g = double.tryParse(m[3]!) ?? double.nan;
  b = double.tryParse(m[5]!) ?? double.nan;
  // 255 & x: ToInt32(x) & 255.
  r = (255 & toInt32(m[2] != null ? p2b(r) : lim(r, 0, 255))).toDouble();
  g = (255 & toInt32(m[4] != null ? p2b(g) : lim(g, 0, 255))).toDouble();
  b = (255 & toInt32(m[6] != null ? p2b(b) : lim(b, 0, 255))).toDouble();

  return RGBA(r: r, g: g, b: b, a: a);
}

/// rgb.js:56 `rgbString`.
///
/// Return rgb(a) string from color. Dart `null` stands for the JS
/// `undefined` color and result.
String? rgbString(RGBA? v) {
  if (v == null) return null;
  final alpha = v.a < 255;
  final r = v.r;
  final g = v.g;
  final b = v.b;
  final opacity = alpha ? b2n(v.a) : 0.0;
  // DIVERGES(chartjs): adapt-kurkle-color-strings, performance optimisations.
  if (!_javascript && _byte(r) && _byte(g) && _byte(b)) {
    final codes = Uint8List(32);
    codes[0] = 114;
    codes[1] = 103;
    codes[2] = 98;
    var i = 3;
    if (alpha) codes[i++] = 97;
    codes[i++] = 40;
    i = _writeByte(codes, i, r.toInt());
    codes[i++] = 44;
    codes[i++] = 32;
    i = _writeByte(codes, i, g.toInt());
    codes[i++] = 44;
    codes[i++] = 32;
    i = _writeByte(codes, i, b.toInt());
    if (alpha) {
      codes[i++] = 44;
      codes[i++] = 32;
      // b2n gives an integer percentage divided by 100. Recover that integer
      // without truncating a product such as 0.29 * 100 below 29.
      final percent = (opacity * 100 + 0.5).toInt();
      if (percent == 100) {
        codes[i++] = 49;
      } else {
        codes[i++] = 48;
        if (percent != 0) {
          codes[i++] = 46;
          final tens = percent ~/ 10;
          codes[i++] = 48 + tens;
          final ones = percent - tens * 10;
          if (ones != 0) codes[i++] = 48 + ones;
        }
      }
    }
    codes[i++] = 41;
    return String.fromCharCodes(codes, 0, i);
  }
  return alpha
      ? 'rgba(${numberText(r)}, ${numberText(g)}, '
            '${numberText(b)}, ${numberText(opacity)})'
      : 'rgb(${numberText(r)}, ${numberText(g)}, '
            '${numberText(b)})';
}

@pragma('vm:prefer-inline')
bool _byte(double v) => v >= 0 && v <= 255 && v == v.truncateToDouble();

@pragma('vm:prefer-inline')
int _writeByte(Uint8List out, int i, int value) {
  final hundreds = value ~/ 100;
  final tens = (value - hundreds * 100) ~/ 10;
  final ones = value - hundreds * 100 - tens * 10;
  if (value >= 100) out[i++] = 48 + hundreds;
  if (value >= 10) out[i++] = 48 + tens;
  out[i++] = 48 + ones;
  return i;
}

int _rgbStart(String s) {
  if (s.length < 4 ||
      s.codeUnitAt(0) != 114 ||
      s.codeUnitAt(1) != 103 ||
      s.codeUnitAt(2) != 98) {
    return 0;
  }
  if (s.codeUnitAt(3) == 40) return 4;
  return s.length >= 5 && s.codeUnitAt(3) == 97 && s.codeUnitAt(4) == 40
      ? 5
      : 0;
}
