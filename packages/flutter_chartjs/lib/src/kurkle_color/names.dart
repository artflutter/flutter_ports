// Ported from @kurkle/color v0.3.2 src/names.js (MIT, Jukka Kurkela).

/// Port of `src/names.js` of @kurkle/color 0.3.2: the CSS color names.
///
/// @packageDocumentation
/// @module utils
library;

import 'package:flutter_chartjs/src/kurkle_color/index.esm.dart' show RGBA;
import 'package:flutter_chartjs/src/kurkle_color/packed.dart';

/// names.js:7 `names`. Dart `null` stands for JS `undefined`, the start
/// value.
Map<String, List<double>>? _names;

/// names.js:18 `nameParse`.
///
/// Parse color name. Dart `null` stands for the JS `undefined` result.
///
/// Upstream `names` is a plain object. A lookup on it also finds the members
/// of `Object.prototype`: in JavaScript, `nameParse('constructor')` and
/// `nameParse('__proto__')` give a color whose `r`, `g` and `b` are
/// `undefined`. Only these two names stay the same after `toLowerCase`. A
/// Dart `Map` has no prototype, so the port gives `null` for these names
/// (row `adapt-kurkle-names-proto` of `doc/differences.md`).
RGBA? nameParse(String str) {
  if (_names == null) {
    _names = unpack();
    _names!['transparent'] = [0, 0, 0, 0];
  }
  // JS toLowerCase maps U+0130 to 'i' + U+0307. The Dart VM maps it to 'i'
  // alone, and dart2js and dart2wasm map it as JS does. U+0130 is the only
  // unconditional one-to-many lowercase mapping, so the port maps it first
  // and gives the JS result on every target.
  // DIVERGES(chartjs): adapt-kurkle-names-proto, a Map lookup has no prototype.
  final a = _names![str.replaceAll('\u0130', 'i\u0307').toLowerCase()];
  return a == null
      ? null
      : RGBA(r: a[0], g: a[1], b: a[2], a: a.length == 4 ? a[3] : 255);
}
