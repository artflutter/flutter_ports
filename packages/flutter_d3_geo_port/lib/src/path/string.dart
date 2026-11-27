// Ported from d3-geo v3.1.1 src/path/string.js (ISC, Mike Bostock).

/// Port of `src/path/string.js` of d3-geo 3.1.1: [GeoPathString].
library;

import 'dart:typed_data';

import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/path/context.dart';

const bool _isWasm = bool.fromEnvironment('dart.tool.dart2wasm');
const bool _isJs = bool.fromEnvironment('dart.library.js_interop') && !_isWasm;

const double _maxDirectRoundQ = 1000000000000000;

const List<int> _pow10Int = <int>[1, 10, 100, 1000, 10000, 100000, 1000000];

const List<double> _pow10 = <double>[
  1,
  10,
  100,
  1000,
  10000,
  100000,
  1000000,
  10000000,
  100000000,
  1000000000,
  10000000000,
  100000000000,
  1000000000000,
  10000000000000,
  100000000000000,
  1000000000000000,
];

/// Two-digit ASCII lookup table (`'00'..'99'`).
final Uint8List _digitPairs = () {
  final t = Uint8List(200);
  for (var i = 0; i < 100; ++i) {
    t[i * 2] = 0x30 + (i ~/ 10);
    t[i * 2 + 1] = 0x30 + (i % 10);
  }
  return t;
}();

/// Formats a double matching JavaScript `String(x)` (no trailing `.0` on
/// integers, `-0.0` formatted as `'0'`).
@pragma('vm:prefer-inline')
String _formatJsDouble(double v) {
  if (_isJs) {
    return v == 0 ? '0' : v.toString();
  }
  if (v == 0) return '0';
  if (!v.isFinite) {
    if (v.isNaN) return 'NaN';
    return v.isNegative ? '-Infinity' : 'Infinity';
  }
  final s = v.toString();
  if (s.endsWith('.0')) return s.substring(0, s.length - 2);
  return s;
}

@pragma('vm:prefer-inline')
String _formatValue(double v, double k) {
  if (k == 0) return _formatJsDouble(v);
  return _formatJsDouble(geoJsRound(v * k) / k);
}

/// `path/string.js:4` `PathString`: streams projected path geometry into an
/// SVG path data string with optional decimal rounding `digits`.
// DIVERGES(d3-geo): adapt-geo-fast-forms, writes direct ASCII bytes via
// integer-scaled rounding on native AOT/Wasm when 0 <= digits <= 6.
final class GeoPathString([int? digits]) extends GeoPathSink {
  /// Creates a [GeoPathString] with optional rounding [digits] (`null` for
  /// full precision; negative values throw [RangeError]).
  this {
    if (digits == null) {
      _k = 0;
      _digits = -1;
      _kInt = 0;
    } else if (digits < 0) {
      throw RangeError.value(digits, 'digits', 'invalid digits: $digits');
    } else if (digits > 15) {
      _k = 0;
      _digits = -1;
      _kInt = 0;
    } else {
      _k = _pow10[digits];
      _digits = digits <= 6 ? digits : -1;
      _kInt = digits <= 6 ? _pow10Int[digits] : 0;
    }
    _bytes = _isJs ? Uint8List(0) : Uint8List(256);
  }

  late final double _k;
  late final int _digits;
  late final int _kInt;
  double _radius = 4.5;
  int _line = -1;
  int _point = -1;

  // JS uses StringBuffer; AOT/Wasm writes ASCII bytes directly into _bytes.
  final StringBuffer _buf = StringBuffer();
  late Uint8List _bytes;
  int _len = 0;

  double? _cacheRadius;
  String _cacheCircle = '';
  Uint8List _cacheCircleBytes = Uint8List(0);

  @pragma('vm:prefer-inline')
  void _ensure(int extra) {
    final need = _len + extra;
    if (need <= _bytes.length) return;
    var cap = _bytes.length * 2;
    while (cap < need) {
      cap *= 2;
    }
    final next = Uint8List(cap)..setRange(0, _len, _bytes);
    _bytes = next;
  }

  @pragma('vm:prefer-inline')
  void _writeAsciiString(String s) {
    final n = s.length;
    _ensure(n);
    final b = _bytes;
    var p = _len;
    for (var i = 0; i < n; ++i) {
      b[p++] = s.codeUnitAt(i);
    }
    _len = p;
  }

  @pragma('vm:prefer-inline')
  void _writeUint(int value) {
    final b = _bytes;
    var p = _len;
    if (value < 10) {
      b[p++] = 0x30 + value;
      _len = p;
      return;
    }
    if (value < 100) {
      final idx = value * 2;
      b[p++] = _digitPairs[idx];
      b[p++] = _digitPairs[idx + 1];
      _len = p;
      return;
    }
    if (value < 1000) {
      final q = value ~/ 100;
      final r = (value - q * 100) * 2;
      b[p++] = 0x30 + q;
      b[p++] = _digitPairs[r];
      b[p++] = _digitPairs[r + 1];
      _len = p;
      return;
    }
    if (value < 10000) {
      final q = (value ~/ 100) * 2;
      final r = (value % 100) * 2;
      b[p++] = _digitPairs[q];
      b[p++] = _digitPairs[q + 1];
      b[p++] = _digitPairs[r];
      b[p++] = _digitPairs[r + 1];
      _len = p;
      return;
    }
    // General positive integer <= 1e15 (max 16 digits).
    var v = value;
    final start = p;
    while (v > 0) {
      final next = v ~/ 10;
      b[p++] = 0x30 + (v - next * 10);
      v = next;
    }
    var lo = start;
    var hi = p - 1;
    while (lo < hi) {
      final tmp = b[lo];
      b[lo++] = b[hi];
      b[hi--] = tmp;
    }
    _len = p;
  }

  @pragma('vm:prefer-inline')
  void _writeNumberByte(double v) {
    if (_digits >= 0) {
      final qd = geoJsRound(v * _k);
      if (qd.isFinite && qd.abs() < _maxDirectRoundQ) {
        var q = qd.toInt();
        if (q == 0) {
          _bytes[_len++] = 0x30;
          return;
        }
        if (q < 0) {
          _bytes[_len++] = 0x2D; // '-'
          q = -q;
        }
        final kInt = _kInt;
        if (kInt == 1) {
          _writeUint(q);
          return;
        }
        final intPart = q ~/ kInt;
        var frac = q - intPart * kInt;
        _writeUint(intPart);
        if (frac == 0) return;
        final b = _bytes;
        var p = _len;
        b[p++] = 0x2E; // '.'
        // Write fixed-width fractional digits then strip trailing '0's.
        final d = _digits;
        if (d == 3) {
          final d0 = frac ~/ 100;
          final r = frac - d0 * 100;
          b[p++] = 0x30 + d0;
          if (r != 0) {
            final idx = r * 2;
            b[p++] = _digitPairs[idx];
            final last = _digitPairs[idx + 1];
            if (last != 0x30) b[p++] = last;
          }
          _len = p;
          return;
        }
        var end = p + d;
        for (var i = end - 1; i >= p; --i) {
          final next = frac ~/ 10;
          b[i] = 0x30 + (frac - next * 10);
          frac = next;
        }
        while (end > p && b[end - 1] == 0x30) {
          --end;
        }
        _len = end;
        return;
      }
    }
    _writeAsciiString(_formatValue(v, _k));
  }

  @override
  void setPointRadius(double radius) {
    _radius = radius;
  }

  @override
  void polygonStart() {
    _line = 0;
  }

  @override
  void polygonEnd() {
    _line = -1;
  }

  @override
  void lineStart() {
    _point = 0;
  }

  @override
  void lineEnd() {
    if (_line == 0) {
      if (_isJs) {
        _buf.write('Z');
      } else {
        _ensure(1);
        _bytes[_len++] = 0x5A; // 'Z'
      }
    }
    _point = -1;
  }

  @override
  void point(double x, double y, [double? z]) {
    if (_isJs) {
      if (_point == 0) {
        _buf
          ..write('M')
          ..write(_formatValue(x, _k))
          ..write(',')
          ..write(_formatValue(y, _k));
        _point = 1;
      } else if (_point == 1) {
        _buf
          ..write('L')
          ..write(_formatValue(x, _k))
          ..write(',')
          ..write(_formatValue(y, _k));
      } else {
        _buf
          ..write('M')
          ..write(_formatValue(x, _k))
          ..write(',')
          ..write(_formatValue(y, _k));
        if (_radius != _cacheRadius) {
          final r = _radius;
          final rs = _formatValue(r, _k);
          final rNeg2 = _formatValue(-2 * r, _k);
          final rPos2 = _formatValue(2 * r, _k);
          _cacheRadius = r;
          _cacheCircle =
              'm0,${rs}a$rs,$rs 0 1,1 0,${rNeg2}a$rs,$rs 0 1,1 0,${rPos2}z';
        }
        _buf.write(_cacheCircle);
      }
      return;
    }

    if (_point == 0) {
      _ensure(64);
      _bytes[_len++] = 0x4D; // 'M'
      _writeNumberByte(x);
      _bytes[_len++] = 0x2C; // ','
      _writeNumberByte(y);
      _point = 1;
    } else if (_point == 1) {
      _ensure(64);
      _bytes[_len++] = 0x4C; // 'L'
      _writeNumberByte(x);
      _bytes[_len++] = 0x2C; // ','
      _writeNumberByte(y);
    } else {
      _ensure(64);
      _bytes[_len++] = 0x4D; // 'M'
      _writeNumberByte(x);
      _bytes[_len++] = 0x2C; // ','
      _writeNumberByte(y);
      if (_radius != _cacheRadius) {
        final r = _radius;
        final rs = _formatValue(r, _k);
        final rNeg2 = _formatValue(-2 * r, _k);
        final rPos2 = _formatValue(2 * r, _k);
        _cacheRadius = r;
        _cacheCircle =
            'm0,${rs}a$rs,$rs 0 1,1 0,${rNeg2}a$rs,$rs 0 1,1 0,${rPos2}z';
        _cacheCircleBytes = Uint8List.fromList(_cacheCircle.codeUnits);
      }
      final cn = _cacheCircleBytes.length;
      _ensure(cn);
      _bytes.setRange(_len, _len + cn, _cacheCircleBytes);
      _len += cn;
    }
  }

  @override
  String? result() {
    if (_isJs) {
      if (_buf.isEmpty) return null;
      final res = _buf.toString();
      _buf.clear();
      return res;
    }
    final len = _len;
    if (len == 0) return null;
    _len = 0;
    return String.fromCharCodes(_bytes, 0, len);
  }
}
