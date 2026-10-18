// Ported from @kurkle/color v0.3.2 src/index.esm.js (MIT, Jukka Kurkela).

/// Port of `src/index.esm.js` of @kurkle/color 0.3.2, the entry of the
/// package for ported code.
///
/// Chart.js imports `{Color} from '@kurkle/color'` (helpers.color.ts:1). The
/// `exports.import` entry of the 0.3.2 `package.json` resolves that ES module
/// import to `dist/color.esm.js`, which rollup builds from this file. Thus
/// ported code imports this library.
///
/// `src/index.js` is the entry of the UMD build. It attaches every export to
/// the default function (`Object.assign(color.default, color)`). A Dart
/// function has no properties, so the port has no `index.dart`.
///
/// @packageDocumentation
/// @module index
library;

import 'package:flutter_chartjs/src/kurkle_color/color.dart';

export 'package:flutter_chartjs/src/kurkle_color/byte.dart';
export 'package:flutter_chartjs/src/kurkle_color/color.dart' show Color;
export 'package:flutter_chartjs/src/kurkle_color/hex.dart';
export 'package:flutter_chartjs/src/kurkle_color/hue.dart';
export 'package:flutter_chartjs/src/kurkle_color/names.dart';
export 'package:flutter_chartjs/src/kurkle_color/rgb.dart';

/// index.esm.js:16 `RGBA`, the color of a [Color].
///
/// The components `r`, `g` and `b` are bytes [0..255]. The JSDoc gives `a`
/// as alpha [0..1]. That is the scale of `Color.rgb`. Inside a [Color], `a`
/// is a byte [0..255], as in the results of the parse functions.
///
/// A JS object compares by identity. Thus the class has no `==`.
final class RGBA {
  /// The object literal `{r, g, b, a}`.
  RGBA({required this.r, required this.g, required this.b, required this.a});

  /// index.esm.js:17 `r`: red [0..255].
  double r;

  /// index.esm.js:18 `g`: green [0..255].
  double g;

  /// index.esm.js:19 `b`: blue [0..255].
  double b;

  /// index.esm.js:20 `a`: alpha [0..1], or a byte [0..255] inside a
  /// [Color].
  double a;
}

/// index.esm.js:29 the default export.
///
/// Construct new Color instance. JavaScript gives the function no name. The
/// port names it `color`.
Color color(Object? input) {
  return Color(input);
}
