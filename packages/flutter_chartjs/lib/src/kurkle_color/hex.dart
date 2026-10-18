// Ported from @kurkle/color v0.3.2 src/hex.js (MIT, Jukka Kurkela).

/// Port of `src/hex.js` of @kurkle/color 0.3.2: the hex notation `#rgb`,
/// `#rgba`, `#rrggbb` and `#rrggbbaa`.
///
/// The JS bitwise operators convert their operands with ToInt32. Thus each
/// operand goes through `jsToInt32` before the Dart `int` operator. All the
/// results are small and not negative, so they are the same on the VM,
/// dart2js and dart2wasm.
///
/// @packageDocumentation
/// @module utils
library;

import 'package:flutter_chartjs/src/js/js_math.dart';
import 'package:flutter_chartjs/src/kurkle_color/index.esm.dart' show RGBA;

/// hex.js:13 `map`.
const Map<String, double> _map = {
  '0': 0,
  '1': 1,
  '2': 2,
  '3': 3,
  '4': 4,
  '5': 5,
  '6': 6,
  '7': 7,
  '8': 8,
  '9': 9,
  'A': 10,
  'B': 11,
  'C': 12,
  'D': 13,
  'E': 14,
  'F': 15,
  'a': 10,
  'b': 11,
  'c': 12,
  'd': 13,
  'e': 14,
  'f': 15,
};

/// `map[str[i]]` as a number: `undefined` for a character that is not a hex
/// digit, which ToNumber makes NaN.
double _digit(String str, int i) => _map[str[i]] ?? double.nan;

/// The ToInt32 value of [x] as an `int`, the operand of a JS bitwise
/// operator.
int _int32(double x) => jsToInt32(x).toInt();

/// hex.js:18 `hex`.
final List<String> _hex = '0123456789ABCDEF'.split('');

/// hex.js:24 `h1`.
String _h1(double b) => _hex[_int32(b) & 0xF];

/// hex.js:30 `h2`.
String _h2(double b) => _hex[(_int32(b) & 0xF0) >> 4] + _hex[_int32(b) & 0xF];

/// hex.js:36 `eq`.
bool _eq(double b) => ((_int32(b) & 0xF0) >> 4) == (_int32(b) & 0xF);

/// hex.js:42 `isShort`.
bool _isShort(RGBA v) => _eq(v.r) && _eq(v.g) && _eq(v.b) && _eq(v.a);

/// hex.js:48 `hexParse`.
///
/// Parse HEX to color. Dart `null` stands for the JS `undefined` result.
RGBA? hexParse(String str) {
  final len = str.length;
  RGBA? ret;
  // str[0] of '' is undefined.
  if (len > 0 && str[0] == '#') {
    if (len == 4 || len == 5) {
      ret = RGBA(
        r: (255 & _int32(_digit(str, 1) * 17)).toDouble(),
        g: (255 & _int32(_digit(str, 2) * 17)).toDouble(),
        b: (255 & _int32(_digit(str, 3) * 17)).toDouble(),
        a: len == 5 ? _digit(str, 4) * 17 : 255,
      );
    } else if (len == 7 || len == 9) {
      ret = RGBA(
        r: (_int32(_digit(str, 1)) << 4 | _int32(_digit(str, 2))).toDouble(),
        g: (_int32(_digit(str, 3)) << 4 | _int32(_digit(str, 4))).toDouble(),
        b: (_int32(_digit(str, 5)) << 4 | _int32(_digit(str, 6))).toDouble(),
        a: len == 9
            ? (_int32(_digit(str, 7)) << 4 | _int32(_digit(str, 8))).toDouble()
            : 255,
      );
    }
  }
  return ret;
}

/// hex.js:71 `alpha`.
String _alpha(double a, String Function(double) f) => a < 255 ? f(a) : '';

/// hex.js:78 `hexString`.
///
/// Return HEX string from color. As upstream, `isShort(v)` reads `v` before
/// the test of `v`. Thus a missing color throws, as the JS `TypeError` does,
/// and the result is never `undefined`.
String hexString(RGBA? v) {
  final f = _isShort(v!) ? _h1 : _h2;
  // v ? '#' + ... : undefined. v is an object here, so the test is true.
  return '#${f(v.r)}${f(v.g)}${f(v.b)}${_alpha(v.a, f)}';
}
