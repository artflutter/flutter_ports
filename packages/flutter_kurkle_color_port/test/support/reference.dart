// Original code, not ported from @kurkle/color: the test references.

/// The references of the color tests: [cssColor], the string branch of the
/// upstream `Color` constructor, and [referenceToInt32], the `x | 0` of
/// JavaScript computed with [BigInt], apart from the code under test.
library;

import 'package:flutter_kurkle_color_port/flutter_kurkle_color_port.dart';

/// color.js:90 `hexParse(input) || nameParse(input) || functionParse(input)`
/// for a CSS text [input]. Another input goes to the [Color] constructor,
/// which takes no text (row `adapt-direct-colors`).
Color cssColor(Object? input) {
  if (input is! String) return Color(input);
  final rgba =
      hexParse(input) ??
      nameParse(input) ??
      (input.isNotEmpty && input.codeUnitAt(0) == 114
          ? rgbParse(input)
          : hueParse(input));
  return rgba == null ? Color(null) : Color.fromRgbaBytes(rgba);
}

/// ECMAScript ToInt32([x]), as a double: NaN and the infinities give 0,
/// other values truncate toward zero and wrap modulo 2^32.
double referenceToInt32(double x) {
  if (!x.isFinite) return 0;
  final wrapped = BigInt.from(x.truncateToDouble()).toSigned(32);
  return wrapped.toDouble() + 0;
}
