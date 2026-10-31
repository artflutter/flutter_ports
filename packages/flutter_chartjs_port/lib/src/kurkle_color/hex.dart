// Ported from @kurkle/color v0.3.2 src/hex.js (MIT, Jukka Kurkela).

/// Port of `src/hex.js` of @kurkle/color 0.3.2: the hex notation `#rgb`,
/// `#rgba`, `#rrggbb` and `#rrggbbaa`.
///
/// Parsing keeps the small hex digits as integers. Invalid digits become 0
/// in bitwise channels, and NaN in short alpha. Formatting still converts
/// arbitrary channel values with ToInt32 before selecting their low bits.
///
/// @packageDocumentation
/// @module utils
library;

import 'dart:typed_data';

import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/index.esm.dart' show RGBA;

/// The upstream digit map as an integer; -1 marks an absent map entry.
int _digit(String str, int i) {
  // DIVERGES(chartjs): adapt-kurkle-hex-code-units, performance optimisations.
  final c = str.codeUnitAt(i);
  if (c >= 48 && c <= 57) return c - 48;
  final lower = c | 32;
  return lower >= 97 && lower <= 102 ? lower - 87 : -1;
}

/// ToInt32 of a map entry: an absent digit becomes 0.
int _nibble(String str, int i) {
  final digit = _digit(str, i);
  return digit < 0 ? 0 : digit;
}

/// Short alpha multiplies the map entry without ToInt32, retaining NaN.
double _shortAlpha(String str) {
  final digit = _digit(str, 4);
  return digit < 0 ? double.nan : (digit * 17).toDouble();
}

/// The ToInt32 value of [x] as an `int`, the operand of a JS bitwise
/// operator.
int _int32(double x) {
  // DIVERGES(chartjs): adapt-kurkle-color-strings, performance optimisations.
  if (x > -2147483649.0 && x < 2147483648.0) return x.toInt();
  return jsToInt32(x).toInt();
}

/// hex.js:48 `hexParse`.
///
/// Parse HEX to color. Dart `null` stands for the JS `undefined` result.
RGBA? hexParse(String str) {
  final len = str.length;
  RGBA? ret;
  // str[0] of '' is undefined.
  if (len > 0 && str.codeUnitAt(0) == 35) {
    if (len == 4 || len == 5) {
      ret = RGBA(
        r: (_nibble(str, 1) * 17).toDouble(),
        g: (_nibble(str, 2) * 17).toDouble(),
        b: (_nibble(str, 3) * 17).toDouble(),
        a: len == 5 ? _shortAlpha(str) : 255,
      );
    } else if (len == 7 || len == 9) {
      ret = RGBA(
        r: (_nibble(str, 1) << 4 | _nibble(str, 2)).toDouble(),
        g: (_nibble(str, 3) << 4 | _nibble(str, 4)).toDouble(),
        b: (_nibble(str, 5) << 4 | _nibble(str, 6)).toDouble(),
        a: len == 9 ? (_nibble(str, 7) << 4 | _nibble(str, 8)).toDouble() : 255,
      );
    }
  }
  return ret;
}

/// Hex digits use uppercase ASCII, as the upstream table does.
int _hexCode(int digit) => digit < 10 ? digit + 48 : digit + 55;

const bool _javascript =
    bool.fromEnvironment('dart.library.js_interop') &&
    !bool.fromEnvironment('dart.tool.dart2wasm');
const String _hexDigits = '0123456789ABCDEF';

/// hex.js:78 `hexString`.
String hexString(RGBA? v) {
  // DIVERGES(chartjs): adapt-kurkle-color-strings, performance optimisations.
  final r = _int32(v!.r) & 255;
  final g = _int32(v.g) & 255;
  final b = _int32(v.b) & 255;
  final a = _int32(v.a) & 255;
  final short =
      (r >> 4) == (r & 15) &&
      (g >> 4) == (g & 15) &&
      (b >> 4) == (b & 15) &&
      (a >> 4) == (a & 15);
  final alpha = v.a < 255;
  if (_javascript) {
    // dart2js benefits from native string concatenation rather than a buffer.
    if (short) {
      return '#${_hexDigits[r & 15]}${_hexDigits[g & 15]}'
          '${_hexDigits[b & 15]}${alpha ? _hexDigits[a & 15] : ''}';
    }
    return '#${_hexDigits[r >> 4]}${_hexDigits[r & 15]}'
        '${_hexDigits[g >> 4]}${_hexDigits[g & 15]}'
        '${_hexDigits[b >> 4]}${_hexDigits[b & 15]}'
        '${alpha ? '${_hexDigits[a >> 4]}${_hexDigits[a & 15]}' : ''}';
  }
  final codes = Uint8List(short ? (alpha ? 5 : 4) : (alpha ? 9 : 7));
  codes[0] = 35;
  if (short) {
    codes[1] = _hexCode(r & 15);
    codes[2] = _hexCode(g & 15);
    codes[3] = _hexCode(b & 15);
    if (alpha) codes[4] = _hexCode(a & 15);
  } else {
    codes[1] = _hexCode(r >> 4);
    codes[2] = _hexCode(r & 15);
    codes[3] = _hexCode(g >> 4);
    codes[4] = _hexCode(g & 15);
    codes[5] = _hexCode(b >> 4);
    codes[6] = _hexCode(b & 15);
    if (alpha) {
      codes[7] = _hexCode(a >> 4);
      codes[8] = _hexCode(a & 15);
    }
  }
  return String.fromCharCodes(codes);
}
