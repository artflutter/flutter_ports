// Original code, not ported from @kurkle/color: the public library.
/// A native Dart port of @kurkle/color 0.3.2: color parsing and
/// manipulation.
///
/// The library exports each file of the port: the extension `KurkleColor`
/// with the methods of the upstream class `Color` on the Flutter `Color`, the
/// object `RGBA`, the default export as `color`, and the functions of the
/// modules `byte`, `hex`, `hue`, `names`, `packed`, `rgb` and `srgb`.
///
/// ```dart
/// final c = const Color(0xFF3366CC).lighten(0.2);
/// print(c.hexString());
/// print(hexParse('#36c')?.r);
/// ```
///
/// `KurkleColor.of` and `color` take a Flutter `Color`, an `RGBA`, a `Map`
/// with the keys `r`, `g`, `b` and `a`, or a list `[r, g, b]` or
/// `[r, g, b, a]`. They take no CSS text: `hexParse`, `nameParse`,
/// `rgbParse` and `hueParse` read the text forms. Dart `null` stands for the
/// JS `undefined` of the upstream API: an input that gives no color, and a
/// result that has none.
library;

export 'package:flutter_kurkle_color_port/src/byte.dart';
export 'package:flutter_kurkle_color_port/src/color.dart';
export 'package:flutter_kurkle_color_port/src/hex.dart';
export 'package:flutter_kurkle_color_port/src/hue.dart';
export 'package:flutter_kurkle_color_port/src/index.esm.dart';
export 'package:flutter_kurkle_color_port/src/names.dart';
export 'package:flutter_kurkle_color_port/src/numbers.dart';
export 'package:flutter_kurkle_color_port/src/packed.dart';
export 'package:flutter_kurkle_color_port/src/rgb.dart';
export 'package:flutter_kurkle_color_port/src/simple_parse.dart';
export 'package:flutter_kurkle_color_port/src/srgb.dart';
export 'package:flutter_kurkle_color_port/src/upstream.dart';
