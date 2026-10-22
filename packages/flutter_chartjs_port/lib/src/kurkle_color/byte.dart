// Ported from @kurkle/color v0.3.2 src/byte.js (MIT, Jukka Kurkela).

/// Port of `src/byte.js` of @kurkle/color 0.3.2: the conversions between a
/// byte (0..255), a percent (0..100) and a normalized value (0..1).
///
/// @packageDocumentation
/// @module utils
library;

import 'package:flutter_chartjs_port/src/js/js_math.dart';

/// byte.js:10 `round`.
///
/// Rounds decimal to nearest integer. `v + 0.5 | 0` truncates toward zero
/// (ToInt32), so it is not `Math.round` for a negative [v]: `round(-50.5)` is
/// -50, and `round(-0.7)` is 0.
double round(double v) {
  return jsToInt32(v + 0.5);
}

/// byte.js:14 `lim`.
double lim(double v, double l, double h) => jsMax(jsMin(v, h), l);

/// byte.js:20 `p2b`.
///
/// convert percent to byte 0..255
double p2b(double v) {
  return lim(round(v * 2.55), 0, 255);
}

/// byte.js:28 `b2p`.
///
/// convert byte to percet 0..100
double b2p(double v) {
  return lim(round(v / 2.55), 0, 100);
}

/// byte.js:36 `n2b`.
///
/// convert normalized to byte 0..255
double n2b(double v) {
  return lim(round(v * 255), 0, 255);
}

/// byte.js:44 `b2n`.
///
/// convert byte to normalized 0..1
double b2n(double v) {
  return lim(round(v / 2.55) / 100, 0, 1);
}

/// byte.js:52 `n2p`.
///
/// convert normalized to percent 0..100
double n2p(double v) {
  return lim(round(v * 100), 0, 100);
}
