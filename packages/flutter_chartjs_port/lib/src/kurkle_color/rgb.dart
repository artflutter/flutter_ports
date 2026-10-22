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

import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/byte.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/index.esm.dart' show RGBA;

/// rgb.js:15 `RGB_RE`.
final RegExp _rgbRe = RegExp(
  r'^rgba?\(\s*([-+.\d]+)(%)?[\s,]+([-+.e\d]+)(%)?[\s,]+([-+.e\d]+)(%)?(?:[\s,/]+([-+.e\d]+)(%)?)?\s*\)$',
);

/// rgb.js:22 `rgbParse`.
///
/// Parse rgb(a) string to RGBA. Dart `null` stands for the JS `undefined`
/// result.
RGBA? rgbParse(String str) {
  final m = _rgbRe.firstMatch(str);
  var a = 255.0;
  double r;
  double g;
  double b;

  if (m == null) {
    return null;
  }

  // r is undefined
  if (m[7] != null) {
    final v = jsToNumber(m[7]);
    a = m[8] != null ? p2b(v) : lim(v * 255, 0, 255);
  }

  r = jsToNumber(m[1]);
  g = jsToNumber(m[3]);
  b = jsToNumber(m[5]);
  // 255 & x: ToInt32(x) & 255.
  r = (255 & jsToInt32(m[2] != null ? p2b(r) : lim(r, 0, 255)).toInt())
      .toDouble();
  g = (255 & jsToInt32(m[4] != null ? p2b(g) : lim(g, 0, 255)).toInt())
      .toDouble();
  b = (255 & jsToInt32(m[6] != null ? p2b(b) : lim(b, 0, 255)).toInt())
      .toDouble();

  return RGBA(r: r, g: g, b: b, a: a);
}

/// rgb.js:56 `rgbString`.
///
/// Return rgb(a) string from color. Dart `null` stands for the JS
/// `undefined` color and result.
String? rgbString(RGBA? v) {
  return v == null
      ? null
      : (v.a < 255
            ? 'rgba(${jsNumberToString(v.r)}, ${jsNumberToString(v.g)}, '
                  '${jsNumberToString(v.b)}, ${jsNumberToString(b2n(v.a))})'
            : 'rgb(${jsNumberToString(v.r)}, ${jsNumberToString(v.g)}, '
                  '${jsNumberToString(v.b)})');
}
