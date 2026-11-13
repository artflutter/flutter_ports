// Original code, not ported from @kurkle/color: the public library.
/// A native Dart port of @kurkle/color 0.3.2: color parsing and
/// manipulation.
///
/// The library exports the names of `src/index.esm.js`: the class `Color`,
/// the object `RGBA`, the default export as `color`, and the functions of
/// the modules `byte`, `hex`, `hue`, `names` and `rgb`.
///
/// ```dart
/// final c = Color(const ui.Color(0xFF3366CC)).lighten(0.2);
/// print(c.hexString());
/// print(hexParse('#36c')?.r);
/// ```
///
/// The `Color` constructor takes a Flutter `Color`, an `RGBA`, a `Map` with
/// the keys `r`, `g`, `b` and `a`, or a list `[r, g, b]` or `[r, g, b, a]`.
/// It takes no CSS text: `hexParse`, `nameParse`, `rgbParse` and `hueParse`
/// read the text forms. Dart `null` stands for the JS `undefined` of the
/// upstream API: an input that gives no color, and a result that has none.
library;

export 'package:flutter_kurkle_color_port/src/index.esm.dart';
export 'package:flutter_kurkle_color_port/src/upstream.dart';
