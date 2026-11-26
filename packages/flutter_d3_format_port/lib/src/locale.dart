// Ported from d3-format v3.1.2 src/locale.js (ISC, Mike Bostock).

/// Port of `src/locale.js` of d3-format 3.1.2.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_format_port/src/exponent.dart';
import 'package:flutter_d3_format_port/src/formatDecimal.dart';
import 'package:flutter_d3_format_port/src/formatGroup.dart';
import 'package:flutter_d3_format_port/src/formatNumerals.dart';
import 'package:flutter_d3_format_port/src/formatPrefixAuto.dart';
import 'package:flutter_d3_format_port/src/formatRounded.dart';
import 'package:flutter_d3_format_port/src/formatSpecifier.dart';
import 'package:flutter_d3_format_port/src/formatTrim.dart';
import 'package:flutter_d3_format_port/src/formatTypes.dart';

// DIVERGES(d3-format): adapt-format-typed-api, typed locale and NumberFormat
// DIVERGES(d3-format): adapt-format-fast-forms, direct buffer & fast paths

const bool _isWasm = bool.fromEnvironment('dart.tool.dart2wasm');
const bool _isJs = bool.fromEnvironment('dart.library.js_interop') && !_isWasm;

const List<String> _prefixes = [
  'y',
  'z',
  'a',
  'f',
  'p',
  'n',
  'µ',
  'm',
  '',
  'k',
  'M',
  'G',
  'T',
  'P',
  'E',
  'Z',
  'Y',
];

const List<int> _prefixCodes = [
  121, // y
  122, // z
  97, // a
  102, // f
  112, // p
  110, // n
  181, // µ
  109, // m
  0, // ''
  107, // k
  77, // M
  71, // G
  84, // T
  80, // P
  69, // E
  90, // Z
  89, // Y
];

const List<double> _prefixScales = [
  1e24,
  1e21,
  1e18,
  1e15,
  1e12,
  1e9,
  1e6,
  1e3,
  1.0,
  1e-3,
  1e-6,
  1e-9,
  1e-12,
  1e-15,
  1e-18,
  1e-21,
  1e-24,
];

const List<int> _pow10Int = [1, 10, 100, 1000, 10000, 100000, 1000000];

const List<double> _pow10Double = [
  1.0,
  10.0,
  100.0,
  1000.0,
  10000.0,
  100000.0,
  1000000.0,
];

/// Max `abs(x)` for direct integer-scaled fixed formatting so `y = x * 10^p`
/// stays `< 1e12` (`0.5 * ulp(y) < 1.25e-4`), guaranteeing exact tie checks.
const List<double> _maxFastFixed = [9e14, 9e10, 9e9, 9e8, 9e7, 9e6, 9e5];

const double _maxFastInt = 4503599627370496; // 2^52

const int _typePercent = 1;
const int _typeB = 2;
const int _typeC = 3;
const int _typeD = 4;
const int _typeE = 5;
const int _typeF = 6;
const int _typeG = 7;
const int _typeO = 8;
const int _typeP = 9;
const int _typeR = 10;
const int _typeS = 11;
const int _typeXUpper = 12;
const int _typeXLower = 13;

const int _alignRight = 0;
const int _alignLeft = 1;
const int _alignEqual = 2;
const int _alignCenter = 3;

const int _signMinus = 0;
const int _signPlus = 1;
const int _signParen = 2;
const int _signSpace = 3;

const List<int> _hexLowerCodes = [
  48, 49, 50, 51, 52, 53, 54, 55, 56, 57, // 0-9
  97, 98, 99, 100, 101, 102, // a-f
];

const List<int> _hexUpperCodes = [
  48, 49, 50, 51, 52, 53, 54, 55, 56, 57, // 0-9
  65, 66, 67, 68, 69, 70, // A-F
];

/// Reusable single-isolate UTF-16 output scratch buffer.
final Uint16List _buf = Uint16List(256);

/// Reusable single-isolate Latin-1 output scratch buffer for 1-byte strings on
/// VM AOT (skips the UTF-16 scan in `String.fromCharCodes`).
final Uint8List _buf8 = Uint8List(256);

int _typeCodeOf(String type) {
  if (type.length != 1) return 0;
  return switch (type.codeUnitAt(0)) {
    37 => _typePercent, // %
    98 => _typeB, // b
    99 => _typeC, // c
    100 => _typeD, // d
    101 => _typeE, // e
    102 => _typeF, // f
    103 => _typeG, // g
    111 => _typeO, // o
    112 => _typeP, // p
    114 => _typeR, // r
    115 => _typeS, // s
    88 => _typeXUpper, // X
    120 => _typeXLower, // x
    _ => 0,
  };
}

/// Immutable locale configuration for [formatLocale] and `formatDefaultLocale`.
final class const FormatLocaleDefinition({
  /// The decimal point (e.g., `'.'`).
  final String decimal = '.',

  /// The group separator (e.g., `','`), or `null` to disable grouping.
  final String? thousands,

  /// The array of group sizes (e.g., `[3]`), cycled as needed, or `null` to
  /// disable grouping.
  final List<int>? grouping,

  /// The currency `(prefix, suffix)` pair (e.g., `('\$', '')`), or `null` for
  /// empty currency affixes.
  final (String, String)? currency,

  /// Optional list of 10 strings replacing ASCII digits `'0'`–`'9'`.
  final List<String>? numerals,

  /// The percent sign (default `'%'`).
  final String percent = '%',

  /// The minus sign (default `'\u2212'`, `'−'`).
  final String minus = '\u2212',

  /// The not-a-number string (default `'NaN'`).
  final String nan = 'NaN',
}) {
  /// Creates a [FormatLocaleDefinition].
  this;

  /// Creates a [FormatLocaleDefinition] from a decoded upstream JSON map.
  factory fromJson(Map<String, Object?> json) {
    final groupingRaw = json['grouping'] as List<Object?>?;
    final currencyRaw = json['currency'] as List<Object?>?;
    final numeralsRaw = json['numerals'] as List<Object?>?;
    return FormatLocaleDefinition(
      decimal: json['decimal'] as String? ?? '.',
      thousands: json['thousands'] as String?,
      grouping: groupingRaw?.map((e) => (e! as num).toInt()).toList(),
      currency: currencyRaw == null
          ? null
          : (currencyRaw[0]! as String, currencyRaw[1]! as String),
      numerals: numeralsRaw?.map((e) => e! as String).toList(),
      percent: json['percent'] as String? ?? '%',
      minus: json['minus'] as String? ?? '\u2212',
      nan: json['nan'] as String? ?? 'NaN',
    );
  }
}

/// Returns `true` when [s] is a numeric string whose parsed value is `0`
/// (equivalent to `+value === 0` in JavaScript without parsing `0xeee` as 0).
@pragma('vm:prefer-inline')
bool _isFormattedZero(String s) {
  final n = s.length;
  if (n == 0) return false;
  var sawZero = false;
  for (var i = 0; i < n; ++i) {
    final c = s.codeUnitAt(i);
    if (c == 48) {
      sawZero = true;
    } else if (c == 46) {
      continue;
    } else if ((c == 101 || c == 69) && sawZero) {
      return true;
    } else {
      return false;
    }
  }
  return sawZero;
}

@pragma('vm:prefer-inline')
int _writeStringBackwards(
  Uint16List buf,
  int pos,
  String s,
  Uint16List? numeralCodes,
) {
  if (numeralCodes == null) {
    for (var i = s.length - 1; i >= 0; --i) {
      buf[--pos] = s.codeUnitAt(i);
    }
  } else {
    for (var i = s.length - 1; i >= 0; --i) {
      final c = s.codeUnitAt(i);
      buf[--pos] = (c >= 48 && c <= 57) ? numeralCodes[c - 48] : c;
    }
  }
  return pos;
}

@pragma('vm:prefer-inline')
int _writeStringForward(
  Uint16List buf,
  int pos,
  String s,
  Uint16List? numeralCodes,
) {
  if (numeralCodes == null) {
    for (var i = 0; i < s.length; ++i) {
      buf[pos++] = s.codeUnitAt(i);
    }
  } else {
    for (var i = 0; i < s.length; ++i) {
      final c = s.codeUnitAt(i);
      buf[pos++] = (c >= 48 && c <= 57) ? numeralCodes[c - 48] : c;
    }
  }
  return pos;
}

/// A compiled number formatter returned by [FormatLocale.format] or
/// [FormatLocale.formatPrefix].
///
/// Implements [call] taking `num` (so it tears off to `String Function(num)`
/// and `String Function(double)`), [formatChar] for non-numeric `'c'` strings,
/// and [toString] returning the normalized specifier string.
final class NumberFormat._({
  /// The parsed [FormatSpecifier] used to build this formatter.
  required final FormatSpecifier specifier,
  required final FormatLocale _locale,
  required final int _typeCode,
  required final int _precision,
  required final int? _width,
  required final String _fill,
  required final int _fillCode,
  required final int _alignCode,
  required final int _signCode,
  required final bool _zero,
  required final bool _comma,
  required final bool _trim,
  required final bool _maybeSuffix,
  required final String _basePrefix,
  required final String _baseSuffix,
  required final String _posPrefix,
  required final String _negPrefix,
  required final String _negSuffix,
  required final double _scale,
  required final bool _isInvalidPrefixScale,
  required final bool _useDirectBuffer,
  required final bool _isPlainUnadorned,
  required final bool _posLatin1,
}) {
  /// Formats [value] according to this formatter's specifier and locale.
  String call(num value) {
    if (_isInvalidPrefixScale) return _formatSlow(double.nan);
    if (_typeCode == _typeC) {
      return _finish(
        _basePrefix,
        '',
        '${formatJsNumberString(value)}$_baseSuffix',
      );
    }

    final d = _scale == 1.0 ? value.toDouble() : _scale * value.toDouble();
    final isNeg = d < 0 || (d == 0 && d.isNegative);
    if (!d.isFinite) {
      return _formatSlow(d);
    }

    final absD = d == 0 ? 0.0 : (isNeg ? -d : d);

    // Fast unadorned paths (no comma, no width, standard decimal, no numerals,
    // no affixes, default '-' sign).
    if (_isPlainUnadorned) {
      if (_typeCode == _typeD && _isJs && absD < _maxFastInt) {
        final q = absD.round();
        if (isNeg && q != 0) return '${_locale._minus}$q';
        return '$q';
      }
      if (_typeCode == _typeF && _isJs) {
        var s = absD.toStringAsFixed(_precision);
        if (_trim) s = formatTrim(s);
        if (isNeg && !_isFormattedZero(s)) return '${_locale._minus}$s';
        return s;
      }
      if (_typeCode == _typeE) {
        var s = absD.toStringAsExponential(_precision);
        if (_trim) s = formatTrim(s);
        if (isNeg && !_isFormattedZero(s)) return '${_locale._minus}$s';
        return s;
      }
      if (_typeCode == _typeG) {
        var s = absD.toStringAsPrecision(_precision);
        if (_trim) s = formatTrim(s);
        if (isNeg && !_isFormattedZero(s)) return '${_locale._minus}$s';
        return s;
      }
      if (_typeCode == _typeR) {
        var s = formatRounded(absD, _precision);
        if (_trim) s = formatTrim(s);
        if (isNeg && !_isFormattedZero(s)) return '${_locale._minus}$s';
        return s;
      }
    }

    if (_isJs &&
        _typeCode == _typePercent &&
        !_comma &&
        _width == null &&
        _locale._decimalCode == 46 &&
        _locale._numerals == null &&
        _signCode == _signMinus &&
        _basePrefix.isEmpty) {
      var s = (absD * 100.0).toStringAsFixed(_precision);
      if (_trim) s = formatTrim(s);
      if (isNeg && !_isFormattedZero(s)) {
        return '${_locale._minus}$s$_baseSuffix';
      }
      return '$s$_baseSuffix';
    }

    if (_useDirectBuffer) {
      if (_typeCode == _typeD) {
        if (absD < _maxFastInt) {
          final q = absD.round();
          return _emitIntFrac(
            q,
            0,
            0,
            isNeg && (q != 0 || _signCode == _signPlus),
          );
        }
      } else if (_typeCode == _typeF || _typeCode == _typePercent) {
        final scaled = _typeCode == _typePercent ? absD * 100.0 : absD;
        final p = _precision;
        if (p <= 6 && scaled < _maxFastFixed[p]) {
          if (p == 0) {
            final q = scaled.round();
            return _emitIntFrac(
              q,
              0,
              0,
              isNeg && (q != 0 || _signCode == _signPlus),
            );
          }
          final y = scaled * _pow10Double[p];
          final fl = y.floorToDouble();
          final frac = y - fl;
          final dist = frac - 0.5;
          if (dist > 2e-4 || dist < -2e-4) {
            final q = frac >= 0.5 ? fl.toInt() + 1 : fl.toInt();
            final div = _pow10Int[p];
            final intPart = q ~/ div;
            final fracPart = q - intPart * div;
            return _emitIntFrac(
              intPart,
              fracPart,
              p,
              isNeg && (q != 0 || _signCode == _signPlus),
            );
          }
        }
      } else if (_typeCode == _typeS) {
        final fastSi = _formatSiFast(absD, isNeg);
        if (fastSi != null) return fastSi;
      } else if ((_typeCode == _typeXLower ||
              _typeCode == _typeXUpper ||
              _typeCode == _typeB ||
              _typeCode == _typeO) &&
          !_comma &&
          absD < _maxFastInt) {
        return _emitRadixFast(absD.round(), isNeg);
      }
    }

    return _formatSlow(d);
  }

  /// Formats a string/character [value] (intended for the `'c'` type).
  String formatChar(String value) =>
      _finish(_basePrefix, '', '$value$_baseSuffix');

  @override
  String toString() => specifier.toString();

  String _emitIntFrac(
    int intPart,
    int rawFracPart,
    int rawFracDigits,
    bool neg,
  ) {
    var fracPart = rawFracPart;
    var fracDigits = rawFracDigits;
    if (_trim && fracDigits > 0) {
      while (fracDigits > 0 && fracPart % 10 == 0) {
        fracPart ~/= 10;
        fracDigits--;
      }
    }

    final prefix = neg ? _negPrefix : _posPrefix;
    final suffix = neg ? _negSuffix : _baseSuffix;
    final numCodes = _locale._numeralCodes;
    final buf = _buf;
    final w = _width;

    // Fast path: no padding width.
    if (w == null) {
      // Latin-1 byte fast path (allocates _OneByteString directly on VM AOT).
      if (numCodes == null &&
          !neg &&
          _posLatin1 &&
          _locale._decimalCode <= 0xff &&
          (!_comma ||
              !_locale._hasGrouping ||
              _locale._thousandsCode <= 0xff)) {
        final b8 = _buf8;
        var pos = 256;
        for (var i = suffix.length - 1; i >= 0; --i) {
          b8[--pos] = suffix.codeUnitAt(i);
        }
        if (fracDigits > 0) {
          var fp = fracPart;
          for (var k = 0; k < fracDigits; ++k) {
            final digit = fp % 10;
            fp ~/= 10;
            b8[--pos] = 48 + digit;
          }
          b8[--pos] = _locale._decimalCode;
        }
        if (!_comma || !_locale._hasGrouping) {
          var q = intPart;
          do {
            final digit = q % 10;
            q ~/= 10;
            b8[--pos] = 48 + digit;
          } while (q > 0);
        } else if (_locale._singleGroup3) {
          final sep = _locale._thousandsCode;
          var q = intPart;
          var count = 0;
          do {
            if (count == 3) {
              b8[--pos] = sep;
              count = 0;
            }
            final digit = q % 10;
            q ~/= 10;
            b8[--pos] = 48 + digit;
            count++;
          } while (q > 0);
        } else {
          final grouping = _locale._grouping!;
          final gLen = grouping.length;
          final sep = _locale._thousandsCode;
          var gIdx = 0;
          var gRem = grouping[0];
          var q = intPart;
          if (gRem > 0) {
            do {
              if (gRem == 0) {
                b8[--pos] = sep;
                gIdx++;
                if (gIdx == gLen) gIdx = 0;
                gRem = grouping[gIdx];
                if (gRem <= 0) break;
              }
              final digit = q % 10;
              q ~/= 10;
              b8[--pos] = 48 + digit;
              gRem--;
            } while (q > 0);
          }
        }
        for (var i = prefix.length - 1; i >= 0; --i) {
          b8[--pos] = prefix.codeUnitAt(i);
        }
        return String.fromCharCodes(b8, pos, 256);
      }

      var pos = 256;
      if (suffix.isNotEmpty) {
        pos = _writeStringBackwards(buf, pos, suffix, numCodes);
      }
      if (fracDigits > 0) {
        var fp = fracPart;
        for (var k = 0; k < fracDigits; ++k) {
          final digit = fp % 10;
          fp ~/= 10;
          buf[--pos] = numCodes == null ? 48 + digit : numCodes[digit];
        }
        buf[--pos] = _locale._decimalCode;
      }
      pos = _writeIntBackwards(buf, pos, intPart, _comma, null, numCodes);
      if (prefix.isNotEmpty) {
        pos = _writeStringBackwards(buf, pos, prefix, numCodes);
      }
      return String.fromCharCodes(buf, pos, 256);
    }

    // Padded path (w != null && w <= 160).
    // First emit the tail (decimal + frac + suffix) into [tailStart..256).
    var tailPos = 256;
    if (suffix.isNotEmpty) {
      tailPos = _writeStringBackwards(buf, tailPos, suffix, numCodes);
    }
    if (fracDigits > 0) {
      var fp = fracPart;
      for (var k = 0; k < fracDigits; ++k) {
        final digit = fp % 10;
        fp ~/= 10;
        buf[--tailPos] = numCodes == null ? 48 + digit : numCodes[digit];
      }
      buf[--tailPos] = _locale._decimalCode;
    }
    final tailLen = 256 - tailPos;

    if (_zero) {
      // Zero padding goes after prefix and before digits; if comma, grouping
      // applies after padding with width bound `w - tailLen`.
      if (!_comma || !_locale._hasGrouping) {
        var pos = tailPos;
        pos = _writeIntBackwards(buf, pos, intPart, false, null, numCodes);
        final zeroCode = numCodes == null ? 48 : numCodes[0];
        final targetPos = 256 - w + prefix.length;
        while (pos > targetPos) {
          buf[--pos] = zeroCode;
        }
        if (prefix.isNotEmpty) {
          pos = _writeStringBackwards(buf, pos, prefix, numCodes);
        }
        return String.fromCharCodes(buf, pos, 256);
      }

      // Comma + zero padding: check if unpadded length already >= w.
      // First write raw digits (unpadded) to measure length.
      const rawEnd = 128;
      var rawStart = _writeIntBackwards(
        buf,
        rawEnd,
        intPart,
        false,
        null,
        null,
      );
      final rawDigitsLen = rawEnd - rawStart;
      final unpaddedLen = prefix.length + rawDigitsLen + tailLen;
      final padCount = w - unpaddedLen;
      final int? groupWidth;
      if (padCount > 0) {
        for (var k = 0; k < padCount; ++k) {
          buf[--rawStart] = 48;
        }
        groupWidth = w - tailLen;
      } else {
        groupWidth = null;
      }
      var pos = _writeGroupedFromSlice(
        buf,
        rawStart,
        rawEnd,
        tailPos,
        groupWidth,
        numCodes,
      );
      if (prefix.isNotEmpty) {
        pos = _writeStringBackwards(buf, pos, prefix, numCodes);
      }
      return String.fromCharCodes(buf, pos, 256);
    }

    // Non-zero fill padding: grouping happens before padding.
    var pos = _writeIntBackwards(buf, tailPos, intPart, _comma, null, numCodes);
    final bodyLen = 256 - pos;
    final totalLen = prefix.length + bodyLen;
    if (totalLen >= w) {
      if (prefix.isNotEmpty) {
        pos = _writeStringBackwards(buf, pos, prefix, numCodes);
      }
      return String.fromCharCodes(buf, pos, 256);
    }

    final padLen = w - totalLen;
    final fillCode = numCodes != null && _fillCode >= 48 && _fillCode <= 57
        ? numCodes[_fillCode - 48]
        : _fillCode;

    if (_alignCode == _alignRight) {
      if (prefix.isNotEmpty) {
        pos = _writeStringBackwards(buf, pos, prefix, numCodes);
      }
      for (var k = 0; k < padLen; ++k) {
        buf[--pos] = fillCode;
      }
      return String.fromCharCodes(buf, pos, 256);
    }
    if (_alignCode == _alignEqual) {
      for (var k = 0; k < padLen; ++k) {
        buf[--pos] = fillCode;
      }
      if (prefix.isNotEmpty) {
        pos = _writeStringBackwards(buf, pos, prefix, numCodes);
      }
      return String.fromCharCodes(buf, pos, 256);
    }

    // Left ('<') or Center ('^'): assemble forward starting at 0.
    // Move body [pos..256) safely since pos >= 256 - w >= 96.
    final bodyStart = pos;
    var out = 0;
    final leftPad = _alignCode == _alignCenter ? (padLen >> 1) : 0;
    final rightPad = padLen - leftPad;
    for (var k = 0; k < leftPad; ++k) {
      buf[out++] = fillCode;
    }
    if (prefix.isNotEmpty) {
      out = _writeStringForward(buf, out, prefix, numCodes);
    }
    for (var k = bodyStart; k < 256; ++k) {
      buf[out++] = buf[k];
    }
    for (var k = 0; k < rightPad; ++k) {
      buf[out++] = fillCode;
    }
    return String.fromCharCodes(buf, 0, out);
  }

  @pragma('vm:prefer-inline')
  int _writeIntBackwards(
    Uint16List buf,
    int pos,
    int value,
    bool doGroup,
    int? groupWidth,
    Uint16List? numCodes,
  ) {
    if (!doGroup || !_locale._hasGrouping) {
      var q = value;
      do {
        final digit = q % 10;
        q ~/= 10;
        buf[--pos] = numCodes == null ? 48 + digit : numCodes[digit];
      } while (q > 0);
      return pos;
    }

    final sep = _locale._thousandsCode;
    if (_locale._singleGroup3 && groupWidth == null) {
      var q = value;
      var count = 0;
      do {
        if (count == 3) {
          buf[--pos] = sep;
          count = 0;
        }
        final digit = q % 10;
        q ~/= 10;
        buf[--pos] = numCodes == null ? 48 + digit : numCodes[digit];
        count++;
      } while (q > 0);
      return pos;
    }

    // General grouping pattern (e.g. en-IN [3, 2, 2, ...]).
    final grouping = _locale._grouping!;
    final gLen = grouping.length;
    var gIdx = 0;
    var gRem = grouping[0];
    if (gRem <= 0) return pos;
    var q = value;
    do {
      if (gRem == 0) {
        buf[--pos] = sep;
        gIdx++;
        if (gIdx == gLen) gIdx = 0;
        gRem = grouping[gIdx];
        if (gRem <= 0) break;
      }
      final digit = q % 10;
      q ~/= 10;
      buf[--pos] = numCodes == null ? 48 + digit : numCodes[digit];
      gRem--;
    } while (q > 0);
    return pos;
  }

  int _writeGroupedFromSlice(
    Uint16List buf,
    int srcStart,
    int srcEnd,
    int dstPos,
    int? width,
    Uint16List? numCodes,
  ) {
    final grouping = _locale._grouping!;
    final gLen = grouping.length;
    final sep = _locale._thousandsCode;
    var pos = dstPos;
    var i = srcEnd;
    var j = 0;
    var g = grouping[0];
    var length = 0;
    var first = true;
    while (i > srcStart && g > 0) {
      if (width != null && length + g + 1 > width) {
        g = math.max(1, width - length);
      }
      if (!first) buf[--pos] = sep;
      first = false;
      final segStart = i - g < srcStart ? srcStart : i - g;
      for (var k = i - 1; k >= segStart; --k) {
        final c = buf[k];
        buf[--pos] = numCodes == null ? c : numCodes[c - 48];
      }
      i -= g;
      length += g + 1;
      if (width != null && length > width) break;
      j++;
      if (j == gLen) j = 0;
      g = grouping[j];
    }
    return pos;
  }

  String _emitRadixFast(int q, bool isNeg) {
    final neg = isNeg && (q != 0 || _signCode == _signPlus);
    final prefix = neg ? _negPrefix : _posPrefix;
    final suffix = neg ? _negSuffix : _baseSuffix;
    final numCodes = _locale._numeralCodes;
    final buf = _buf;

    var pos = 256;
    if (suffix.isNotEmpty) {
      pos = _writeStringBackwards(buf, pos, suffix, numCodes);
    }

    var v = q;
    if (_typeCode == _typeXLower) {
      do {
        final c = _hexLowerCodes[v & 15];
        v >>>= 4;
        buf[--pos] = (numCodes != null && c <= 57) ? numCodes[c - 48] : c;
      } while (v != 0);
    } else if (_typeCode == _typeXUpper) {
      do {
        final c = _hexUpperCodes[v & 15];
        v >>>= 4;
        buf[--pos] = (numCodes != null && c <= 57) ? numCodes[c - 48] : c;
      } while (v != 0);
    } else if (_typeCode == _typeB) {
      do {
        final digit = v & 1;
        v >>>= 1;
        buf[--pos] = numCodes == null ? 48 + digit : numCodes[digit];
      } while (v != 0);
    } else {
      do {
        final digit = v & 7;
        v >>>= 3;
        buf[--pos] = numCodes == null ? 48 + digit : numCodes[digit];
      } while (v != 0);
    }

    final w = _width;
    if (w == null) {
      if (prefix.isNotEmpty) {
        pos = _writeStringBackwards(buf, pos, prefix, numCodes);
      }
      return String.fromCharCodes(buf, pos, 256);
    }

    final totalLen = prefix.length + (256 - pos);
    if (totalLen >= w) {
      if (prefix.isNotEmpty) {
        pos = _writeStringBackwards(buf, pos, prefix, numCodes);
      }
      return String.fromCharCodes(buf, pos, 256);
    }

    final padLen = w - totalLen;
    final fillCode = numCodes != null && _fillCode >= 48 && _fillCode <= 57
        ? numCodes[_fillCode - 48]
        : _fillCode;

    if (_alignCode == _alignEqual) {
      for (var k = 0; k < padLen; ++k) {
        buf[--pos] = fillCode;
      }
      if (prefix.isNotEmpty) {
        pos = _writeStringBackwards(buf, pos, prefix, numCodes);
      }
      return String.fromCharCodes(buf, pos, 256);
    }
    if (_alignCode == _alignRight) {
      if (prefix.isNotEmpty) {
        pos = _writeStringBackwards(buf, pos, prefix, numCodes);
      }
      for (var k = 0; k < padLen; ++k) {
        buf[--pos] = fillCode;
      }
      return String.fromCharCodes(buf, pos, 256);
    }

    final bodyStart = pos;
    var out = 0;
    final leftPad = _alignCode == _alignCenter ? (padLen >> 1) : 0;
    final rightPad = padLen - leftPad;
    for (var k = 0; k < leftPad; ++k) {
      buf[out++] = fillCode;
    }
    if (prefix.isNotEmpty) {
      out = _writeStringForward(buf, out, prefix, numCodes);
    }
    for (var k = bodyStart; k < 256; ++k) {
      buf[out++] = buf[k];
    }
    for (var k = 0; k < rightPad; ++k) {
      buf[out++] = fillCode;
    }
    return String.fromCharCodes(buf, 0, out);
  }

  /// Fused SI-prefix formatting for finite `absD > 0` without global state
  /// mutation or intermediate string slicing.
  String? _formatSiFast(double absD, bool isNeg) {
    if (absD == 0 || _width != null || _comma) return null;
    final p = _precision;
    final expStr = absD.toStringAsExponential(p - 1);
    final eIdx = expStr.indexOf('e');
    final exp = parseExponentAt(expStr, eIdx + 1);
    final idx = math.max(-8, math.min(8, (exp / 3).floor()));
    final pe = idx * 3;
    final dotPos = exp - pe + 1;
    // Fast path covers all normal SI ranges where 1 <= dotPos <= p
    // (1e-24..1e26) and also integer-scaled up to 12 trailing zeros.
    if (dotPos <= 0 || dotPos > p + 12) return null;

    final nDigits = eIdx == 1 ? 1 : eIdx - 1;
    final prefix = isNeg ? _negPrefix : _posPrefix;
    final suffix = isNeg ? _negSuffix : _baseSuffix;
    final siCode = _prefixCodes[8 + idx];
    final numCodes = _locale._numeralCodes;
    final buf = _buf;
    var pos = 0;

    if (prefix.isNotEmpty) {
      pos = _writeStringForward(buf, pos, prefix, numCodes);
    }

    if (dotPos >= nDigits) {
      // Pure integer mantissa with optional trailing zeros.
      var c = expStr.codeUnitAt(0);
      buf[pos++] = numCodes == null ? c : numCodes[c - 48];
      for (var k = 2; k < eIdx; ++k) {
        c = expStr.codeUnitAt(k);
        buf[pos++] = numCodes == null ? c : numCodes[c - 48];
      }
      final zeroCode = numCodes == null ? 48 : numCodes[0];
      for (var k = nDigits; k < dotPos; ++k) {
        buf[pos++] = zeroCode;
      }
    } else {
      // Integer part: first `dotPos` significant digits.
      var c = expStr.codeUnitAt(0);
      buf[pos++] = numCodes == null ? c : numCodes[c - 48];
      for (var k = 1; k < dotPos; ++k) {
        c = expStr.codeUnitAt(k + 1);
        buf[pos++] = numCodes == null ? c : numCodes[c - 48];
      }
      // Fractional part: remaining digits `dotPos .. nDigits - 1`.
      var lastFrac = nDigits - 1;
      if (_trim) {
        while (lastFrac >= dotPos && expStr.codeUnitAt(lastFrac + 1) == 48) {
          lastFrac--;
        }
      }
      if (lastFrac >= dotPos) {
        buf[pos++] = _locale._decimalCode;
        for (var k = dotPos; k <= lastFrac; ++k) {
          c = expStr.codeUnitAt(k + 1);
          buf[pos++] = numCodes == null ? c : numCodes[c - 48];
        }
      }
    }

    if (siCode != 0) {
      buf[pos++] = siCode;
    }
    if (suffix.isNotEmpty) {
      pos = _writeStringForward(buf, pos, suffix, numCodes);
    }
    return String.fromCharCodes(buf, 0, pos);
  }

  String _formatSlow(double d) {
    var valueNegative = d < 0 || (d == 0 && d.isNegative);
    final isNan = d.isNaN;

    var value = isNan
        ? _locale._nan
        : _formatByType(d == 0 ? 0.0 : d.abs(), _precision);

    if (_trim) value = formatTrim(value);

    if (valueNegative && _isFormattedZero(value) && _signCode != _signPlus) {
      valueNegative = false;
    }

    final valuePrefix = valueNegative ? _negPrefix : _posPrefix;
    final siSuffix = (_typeCode == _typeS && !isNan && prefixExponent != null)
        ? _prefixes[8 + prefixExponent! ~/ 3]
        : '';
    var valueSuffix = '$siSuffix${valueNegative ? _negSuffix : _baseSuffix}';

    if (_maybeSuffix) {
      final n = value.length;
      for (var i = 0; i < n; ++i) {
        final c = value.codeUnitAt(i);
        if (c < 48 || c > 57) {
          final tail = c == 46
              ? '${_locale._decimal}${value.substring(i + 1)}'
              : value.substring(i);
          valueSuffix = '$tail$valueSuffix';
          value = value.substring(0, i);
          break;
        }
      }
    }

    return _finish(valuePrefix, value, valueSuffix);
  }

  String _formatByType(double x, int p) => switch (_typeCode) {
    _typePercent => (x * 100).toStringAsFixed(p),
    _typeB => formatRadix(x, 2),
    _typeC => formatJsNumberString(x),
    _typeD => formatDecimal(x),
    _typeE => x.toStringAsExponential(p),
    _typeF => x.toStringAsFixed(p),
    _typeG => x.toStringAsPrecision(p),
    _typeO => formatRadix(x, 8),
    _typeP => formatRounded(x * 100, p),
    _typeR => formatRounded(x, p),
    _typeS => formatPrefixAuto(x, p),
    _typeXUpper => formatRadix(x, 16, uppercase: true),
    _typeXLower => formatRadix(x, 16),
    _ => x.toStringAsPrecision(p),
  };

  String _finish(String valuePrefix, String rawValue, String valueSuffix) {
    var value = rawValue;
    final group = _locale._group;
    if (_comma && !_zero && group != null) {
      value = group(value, null);
    }

    final w = _width;
    final length = valuePrefix.length + value.length + valueSuffix.length;
    var padding = (w != null && length < w) ? _fill * (w - length) : '';

    if (_comma && _zero && group != null) {
      value = group(
        '$padding$value',
        padding.isNotEmpty ? w! - valueSuffix.length : null,
      );
      padding = '';
    }

    final String result;
    if (padding.isEmpty) {
      result = '$valuePrefix$value$valueSuffix';
    } else {
      switch (_alignCode) {
        case _alignLeft:
          result = '$valuePrefix$value$valueSuffix$padding';
        case _alignEqual:
          result = '$valuePrefix$padding$value$valueSuffix';
        case _alignCenter:
          final half = padding.length >> 1;
          final left = padding.substring(0, half);
          final right = padding.substring(half);
          result = '$left$valuePrefix$value$valueSuffix$right';
        default:
          result = '$padding$valuePrefix$value$valueSuffix';
      }
    }

    final numerals = _locale._numerals;
    return numerals == null ? result : numerals(result);
  }
}

/// A locale-bound factory producing [NumberFormat] instances.
final class FormatLocale(
  /// The locale definition backing this locale.
  final FormatLocaleDefinition definition,
) {
  /// Creates a [FormatLocale] from [definition].
  this;

  late final String Function(String value, int? width)? _group =
      definition.grouping == null || definition.thousands == null
      ? null
      : formatGroup(definition.grouping!, definition.thousands!);
  final List<int>? _grouping = definition.grouping;
  final bool _hasGrouping =
      definition.grouping != null &&
      definition.grouping!.isNotEmpty &&
      definition.thousands != null;
  final bool _singleGroup3 =
      definition.grouping != null &&
      definition.grouping!.length == 1 &&
      definition.grouping![0] == 3;
  final int _thousandsCode =
      definition.thousands != null && definition.thousands!.length == 1
      ? definition.thousands!.codeUnitAt(0)
      : -1;
  final String _currencyPrefix = definition.currency?.$1 ?? '';
  final String _currencySuffix = definition.currency?.$2 ?? '';
  final String _decimal = definition.decimal;
  final int _decimalCode = definition.decimal.length == 1
      ? definition.decimal.codeUnitAt(0)
      : -1;
  late final String Function(String value)? _numerals =
      definition.numerals == null ? null : formatNumerals(definition.numerals!);
  late final Uint16List? _numeralCodes = _buildNumeralCodes(
    definition.numerals,
  );
  final bool _hasMultiUnitNumerals =
      definition.numerals != null &&
      (definition.numerals!.length < 10 ||
          definition.numerals!.take(10).any((s) => s.length != 1));
  final String _percent = definition.percent;
  final String _minus = definition.minus;
  final String _nan = definition.nan;

  static Uint16List? _buildNumeralCodes(List<String>? numerals) {
    if (numerals == null || numerals.length < 10) return null;
    for (var i = 0; i < 10; ++i) {
      if (numerals[i].length != 1) return null;
    }
    final codes = Uint16List(10);
    for (var i = 0; i < 10; ++i) {
      codes[i] = numerals[i].codeUnitAt(0);
    }
    return codes;
  }

  /// Returns a new [NumberFormat] for the given string [specifier].
  NumberFormat format(
    String specifier, {
    String prefix = '',
    String suffix = '',
  }) => _newFormat(formatSpecifier(specifier), prefix: prefix, suffix: suffix);

  /// Returns a new [NumberFormat] for a pre-parsed [FormatSpecifier].
  NumberFormat formatFromSpecifier(
    FormatSpecifier specifier, {
    String prefix = '',
    String suffix = '',
  }) => _newFormat(
    FormatSpecifier.normalized(specifier),
    prefix: prefix,
    suffix: suffix,
  );

  /// Returns a new [NumberFormat] equivalent to [format], except that formatted
  /// values are converted to the SI prefix units appropriate for [value].
  NumberFormat formatPrefix(String specifier, num value) =>
      formatPrefixFromSpecifier(formatSpecifier(specifier), value);

  /// Returns a new [NumberFormat] for a pre-parsed [FormatSpecifier] converted
  /// to the SI prefix units appropriate for [value].
  NumberFormat formatPrefixFromSpecifier(FormatSpecifier specifier, num value) {
    final exp = formatExponent(value);
    final normalized = FormatSpecifier.normalized(specifier)..type = 'f';
    if (exp == null) {
      return _newFormat(normalized, isInvalidPrefixScale: true);
    }
    final idx = math.max(-8, math.min(8, (exp / 3).floor()));
    return _newFormat(
      normalized,
      suffix: _prefixes[8 + idx],
      scale: _prefixScales[8 + idx],
    );
  }

  NumberFormat _newFormat(
    FormatSpecifier specifier, {
    String prefix = '',
    String suffix = '',
    double scale = 1.0,
    bool isInvalidPrefixScale = false,
  }) {
    var fill = specifier.fill;
    var align = specifier.align;
    final sign = specifier.sign;
    final symbol = specifier.symbol;
    var zero = specifier.zero;
    final width = specifier.width;
    var comma = specifier.comma;
    var precision = specifier.precision;
    var trim = specifier.trim;
    var type = specifier.type;

    var typeCode = _typeCodeOf(type);
    if (type == 'n') {
      comma = true;
      type = 'g';
      typeCode = _typeG;
    } else if (typeCode == 0) {
      precision ??= 12;
      trim = true;
      type = 'g';
      typeCode = _typeG;
    }

    if (zero || (fill == '0' && align == '=')) {
      zero = true;
      fill = '0';
      align = '=';
    }

    final isRadix =
        typeCode == _typeB ||
        typeCode == _typeO ||
        typeCode == _typeXLower ||
        typeCode == _typeXUpper;
    final basePrefix =
        prefix +
        (symbol == r'$'
            ? _currencyPrefix
            : (symbol == '#' && isRadix)
            ? '0${type.toLowerCase()}'
            : '');
    final baseSuffix =
        (symbol == r'$'
            ? _currencySuffix
            : (typeCode == _typePercent || typeCode == _typeP)
            ? _percent
            : '') +
        suffix;

    final maybeSuffix =
        typeCode == _typeD ||
        typeCode == _typeE ||
        typeCode == _typeF ||
        typeCode == _typeG ||
        typeCode == _typeP ||
        typeCode == _typeR ||
        typeCode == _typeS ||
        typeCode == _typePercent;

    final int clampedPrecision;
    if (precision == null) {
      clampedPrecision = 6;
    } else if (typeCode == _typeG ||
        typeCode == _typeP ||
        typeCode == _typeR ||
        typeCode == _typeS) {
      clampedPrecision = math.max(1, math.min(21, precision));
    } else {
      clampedPrecision = math.max(0, math.min(20, precision));
    }

    final alignCode = switch (align) {
      '<' => _alignLeft,
      '=' => _alignEqual,
      '^' => _alignCenter,
      _ => _alignRight,
    };

    final signCode = switch (sign) {
      '+' => _signPlus,
      '(' => _signParen,
      ' ' => _signSpace,
      _ => _signMinus,
    };

    final posSign = signCode == _signMinus || signCode == _signParen
        ? ''
        : sign;
    final negSign = signCode == _signParen ? '(' : _minus;
    final posPrefix = posSign.isEmpty
        ? basePrefix
        : (basePrefix.isEmpty ? posSign : '$posSign$basePrefix');
    final negPrefix = basePrefix.isEmpty ? negSign : '$negSign$basePrefix';
    final negSuffix = signCode == _signParen
        ? (baseSuffix.isEmpty ? ')' : '$baseSuffix)')
        : baseSuffix;

    final fillCode = fill.length == 1 ? fill.codeUnitAt(0) : -1;
    final useDirectBuffer =
        !_isJs &&
        !_hasMultiUnitNumerals &&
        _decimalCode >= 0 &&
        (!comma || !_hasGrouping || _thousandsCode >= 0) &&
        (width == null || (width <= 120 && fillCode >= 0)) &&
        (posPrefix.length + negPrefix.length + negSuffix.length <= 64);

    final posLatin1 = !_isJs && _isLatin1(posPrefix) && _isLatin1(baseSuffix);

    final isPlainUnadorned =
        !comma &&
        width == null &&
        _decimalCode == 46 &&
        _numerals == null &&
        signCode == _signMinus &&
        basePrefix.isEmpty &&
        baseSuffix.isEmpty;

    return NumberFormat._(
      specifier: specifier,
      locale: this,
      typeCode: typeCode,
      precision: clampedPrecision,
      width: width,
      fill: fill,
      fillCode: fillCode,
      alignCode: alignCode,
      signCode: signCode,
      zero: zero,
      comma: comma,
      trim: trim,
      maybeSuffix: maybeSuffix,
      basePrefix: basePrefix,
      baseSuffix: baseSuffix,
      posPrefix: posPrefix,
      negPrefix: negPrefix,
      negSuffix: negSuffix,
      scale: scale,
      isInvalidPrefixScale: isInvalidPrefixScale,
      useDirectBuffer: useDirectBuffer,
      isPlainUnadorned: isPlainUnadorned,
      posLatin1: posLatin1,
    );
  }
}

bool _isLatin1(String s) {
  for (var i = 0; i < s.length; ++i) {
    if (s.codeUnitAt(i) > 0xff) return false;
  }
  return true;
}

/// Returns a [FormatLocale] for the specified [definition].
FormatLocale formatLocale(FormatLocaleDefinition definition) =>
    FormatLocale(definition);
