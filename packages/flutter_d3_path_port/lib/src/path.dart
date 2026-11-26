// Ported from d3-path v3.1.0 src/path.js (ISC, Mike Bostock).

/// Port of `src/path.js` of d3-path 3.1.0: [Path], [path] and [pathRound].
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_path_port/src/canvas_path.dart';

const double _pi = math.pi;
const double _tau = 2 * _pi;
const double _epsilon = 1e-6;
const double _tauEpsilon = _tau - _epsilon;

/// Whether the code compiles to JavaScript (dart2js or DDC), where native JS
/// strings and `double.toString()` already use the engine's Dragonbox/rope
/// fast paths.
const bool _isWasm = bool.fromEnvironment('dart.tool.dart2wasm');
const bool _isJs = bool.fromEnvironment('dart.library.js_interop') && !_isWasm;

/// Exact IEEE-754 integer range where `double.toInt()` is lossless across
/// Dart VM, dart2js and dart2wasm.
const double _maxSafeInt = 9007199254740992; // 2^53

/// Threshold below which every negative IEEE-754 double is already an integer.
const double _minRoundableNeg = -4503599627370496; // -2^52

/// Direct integer-scaled decimal threshold for `pathRound(0..6)`.
///
/// For `|q| < 1e15` and `0 <= digits <= 6`: `q` and `10^digits` are exact in
/// IEEE-754 binary64, `|q / 10^digits|` stays inside `[1e-6, 1e15)` (never
/// scientific notation in JS), and `ulp(q / 10^digits) < 0.25 * 10^-digits`,
/// so emitting the decimal digits of `q` directly is bit-identical to
/// `String(Math.round(x * 10^d) / 10^d)`.
const double _maxDirectRoundQ = 1000000000000000;

const List<int> _pow10Int = [1, 10, 100, 1000, 10000, 100000, 1000000];

const List<double> _pow10Double = [
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

/// Shared empty buffer used on dart2js so constructing [Path] allocates no
/// typed array.
final Uint8List _emptyBuf = Uint8List(0);

/// Shared dummy StringBuffer used on AOT/Wasm so constructing [Path] allocates
/// no StringBuffer.
final StringBuffer _dummyJsBuf = StringBuffer();

/// Two-digit ASCII lookup table (`'00'..'99'`).
final Uint8List _digitPairs = () {
  final t = Uint8List(200);
  for (var i = 0; i < 100; i++) {
    t[i * 2] = 0x30 + (i ~/ 10);
    t[i * 2 + 1] = 0x30 + (i % 10);
  }
  return t;
}();

/// JavaScript `Math.round(v)`: rounds halves toward `+∞`.
@pragma('vm:prefer-inline')
double _jsRound(double v) {
  if (v >= 0) return v.roundToDouble();
  if (v > _minRoundableNeg) return (v + 0.5).floorToDouble();
  return v;
}

/// Formats [x] as a JavaScript/SVG number string on dart2js (and fallback).
@pragma('vm:prefer-inline')
String _jsNumberText(double x) {
  if (_isJs) {
    return x == 0 ? '0' : x.toString();
  }
  if (x == 0) return '0';
  if (x >= -_maxSafeInt && x <= _maxSafeInt) {
    final t = x.truncateToDouble();
    if (x == t) return x.toInt().toString();
  }
  return x.toString();
}

// ---------------------------------------------------------------------------
// Clean-room Ryū binary64 shortest-decimal ASCII emitter (native AOT & Wasm).
//
// Based on Ulf Adams, "Ryū: Fast Float-to-String Conversion" (PLDI 2018).
// Tables of 125-bit powers of 5 are generated lazily from BigInt into five
// 30-bit limbs per entry so every 55×125 multiply fits in signed 64-bit Dart
// ints without overflow.
// ---------------------------------------------------------------------------

const int _mask30 = 0x3FFFFFFF;
const int _pow5InvBitcount = 125;
const int _pow5Bitcount = 125;
const int _pow5InvMax = 342;
const int _pow5Max = 326;

final Float64List _f64Scratch = Float64List(1);
final Uint32List _u32Scratch = _f64Scratch.buffer.asUint32List();
final int _hiWordIndex = Endian.host == Endian.little ? 1 : 0;
final int _loWordIndex = Endian.host == Endian.little ? 0 : 1;

@pragma('vm:prefer-inline')
int _pow5Bits(int e) => e == 0 ? 1 : ((e * 1217359) >> 19) + 1;

@pragma('vm:prefer-inline')
int _log10Pow2(int e) => (e * 78913) >> 18;

@pragma('vm:prefer-inline')
int _log10Pow5(int e) => (e * 732923) >> 20;

/// Lazily computed `floor(2^(_pow5InvBitcount + pow5Bits(q) - 1) / 5^q) + 1`
/// split into five 30-bit limbs per entry.
final Uint32List _pow5InvSplit = () {
  final out = Uint32List((_pow5InvMax + 1) * 5);
  var p5 = BigInt.one;
  final five = BigInt.from(5);
  final mask = BigInt.from(_mask30);
  for (var q = 0; q <= _pow5InvMax; q++) {
    final bits = _pow5Bits(q);
    final k = _pow5InvBitcount + bits - 1;
    final val = (BigInt.one << k) ~/ p5 + BigInt.one;
    final base = q * 5;
    out[base] = (val & mask).toInt();
    out[base + 1] = ((val >> 30) & mask).toInt();
    out[base + 2] = ((val >> 60) & mask).toInt();
    out[base + 3] = ((val >> 90) & mask).toInt();
    out[base + 4] = (val >> 120).toInt();
    p5 *= five;
  }
  return out;
}();

/// Lazily computed `floor(5^i / 2^(pow5Bits(i) - _pow5Bitcount))` split into
/// five 30-bit limbs per entry.
final Uint32List _pow5Split = () {
  final out = Uint32List((_pow5Max + 1) * 5);
  var p5 = BigInt.one;
  final five = BigInt.from(5);
  final mask = BigInt.from(_mask30);
  for (var i = 0; i <= _pow5Max; i++) {
    final shift = _pow5Bits(i) - _pow5Bitcount;
    final val = shift >= 0 ? (p5 >> shift) : (p5 << -shift);
    final base = i * 5;
    out[base] = (val & mask).toInt();
    out[base + 1] = ((val >> 30) & mask).toInt();
    out[base + 2] = ((val >> 60) & mask).toInt();
    out[base + 3] = ((val >> 90) & mask).toInt();
    out[base + 4] = (val >> 120).toInt();
    p5 *= five;
  }
  return out;
}();

@pragma('vm:prefer-inline')
bool _multipleOfPowerOf5(int value, int p) {
  var v = value;
  var count = 0;
  while (true) {
    final q = v ~/ 5;
    if (v - q * 5 != 0) break;
    v = q;
    count++;
  }
  return count >= p;
}

@pragma('vm:prefer-inline')
bool _multipleOfPowerOf2(int value, int p) => (value & ((1 << p) - 1)) == 0;

@pragma('vm:prefer-inline')
int _extractShifted(int p5, int p4, int p3, int shift) {
  if (shift >= 120) {
    return ((p5 << 30) | p4) >> (shift - 120);
  }
  return (((p5 << 30) | p4) << (120 - shift)) | (p3 >> (shift - 90));
}

@pragma('vm:prefer-inline')
int _decimalLength17(int v) {
  if (v >= 10000000000000000) return 17;
  if (v >= 1000000000000000) return 16;
  if (v >= 100000000000000) return 15;
  if (v >= 10000000000000) return 14;
  if (v >= 1000000000000) return 13;
  if (v >= 100000000000) return 12;
  if (v >= 10000000000) return 11;
  if (v >= 1000000000) return 10;
  if (v >= 100000000) return 9;
  if (v >= 10000000) return 8;
  if (v >= 1000000) return 7;
  if (v >= 100000) return 6;
  if (v >= 10000) return 5;
  if (v >= 1000) return 4;
  if (v >= 100) return 3;
  if (v >= 10) return 2;
  return 1;
}

/// Writes exactly 4 decimal digits for `0 <= v < 10000` at `buf[pos..pos+3]`
/// using multiply-shift (zero divisions).
@pragma('vm:prefer-inline')
void _write4Fixed(Uint8List buf, Uint8List pairs, int pos, int v) {
  final hi = (v * 5243) >> 19;
  final lo = v - hi * 100;
  final p0 = hi << 1;
  final p1 = lo << 1;
  buf[pos] = pairs[p0];
  buf[pos + 1] = pairs[p0 + 1];
  buf[pos + 2] = pairs[p1];
  buf[pos + 3] = pairs[p1 + 1];
}

/// Writes exactly 8 decimal digits for `0 <= v < 100000000` at
/// `buf[pos..pos+7]` using multiply-shift (zero divisions).
@pragma('vm:prefer-inline')
void _write8Fixed(Uint8List buf, Uint8List pairs, int pos, int v) {
  final top4 = (v * 1759218605) >> 44;
  final bot4 = v - top4 * 10000;
  _write4Fixed(buf, pairs, pos, top4);
  _write4Fixed(buf, pairs, pos + 4, bot4);
}

/// Writes `0 <= v < 10000` at `buf[pos..]` and returns the new write index.
@pragma('vm:prefer-inline')
int _writeUnder10000(Uint8List buf, Uint8List pairs, int pos, int v) {
  if (v < 10) {
    buf[pos] = 0x30 + v;
    return pos + 1;
  }
  if (v < 100) {
    final p = v << 1;
    buf[pos] = pairs[p];
    buf[pos + 1] = pairs[p + 1];
    return pos + 2;
  }
  if (v < 1000) {
    final d0 = (v * 5243) >> 19;
    final p = (v - d0 * 100) << 1;
    buf[pos] = 0x30 + d0;
    buf[pos + 1] = pairs[p];
    buf[pos + 2] = pairs[p + 1];
    return pos + 3;
  }
  _write4Fixed(buf, pairs, pos, v);
  return pos + 4;
}

/// Writes a non-negative integer `0 <= v < 10^17` at `buf[pos..]` using at
/// most 1 division (2 for `>= 10^16`) and returns the new write index.
@pragma('vm:prefer-inline')
int _writeUintFast(Uint8List buf, Uint8List pairs, int pos, int v) {
  if (v < 10000) return _writeUnder10000(buf, pairs, pos, v);
  if (v < 100000000) {
    final hi = (v * 1759218605) >> 44;
    final lo = v - hi * 10000;
    final p = _writeUnder10000(buf, pairs, pos, hi);
    _write4Fixed(buf, pairs, p, lo);
    return p + 4;
  }
  final hi = v ~/ 100000000;
  final lo = v - hi * 100000000;
  int p;
  if (hi < 10000) {
    p = _writeUnder10000(buf, pairs, pos, hi);
  } else if (hi < 100000000) {
    final hi4 = (hi * 1759218605) >> 44;
    final lo4 = hi - hi4 * 10000;
    p = _writeUnder10000(buf, pairs, pos, hi4);
    _write4Fixed(buf, pairs, p, lo4);
    p += 4;
  } else {
    final hi2 = hi ~/ 100000000;
    final mid = hi - hi2 * 100000000;
    p = _writeUnder10000(buf, pairs, pos, hi2);
    _write8Fixed(buf, pairs, p, mid);
    p += 8;
  }
  _write8Fixed(buf, pairs, p, lo);
  return p + 8;
}

/// `path.js:26` `Path`: serializes Canvas 2D path commands to an SVG path
/// string.
// DIVERGES(d3-path): adapt-path-typed-args, typed int? digits and RangeError.
// DIVERGES(d3-path): adapt-path-fast-forms, Uint8List ASCII buffer + Ryū d2s.
class Path([int? digits]) implements CanvasPath {
  /// `path.js:27` `constructor(digits)`: creates a new path serializer.
  ///
  /// When [digits] is `null` or greater than 15, coordinates keep full
  /// precision. Otherwise coordinates are rounded to [digits] decimal places.
  /// Throws a [RangeError] if [digits] is negative.
  this;

  static int _initDigits(int? digits) {
    if (digits == null) return -1;
    if (digits < 0) {
      throw RangeError.value(digits, 'digits', 'invalid digits: $digits');
    }
    if (digits > 15) return -1;
    return digits;
  }

  static double _initScale(int? digits) {
    if (digits == null || digits > 15) return 0;
    if (digits < 0) return 0;
    return _pow10Double[digits];
  }

  static int _initScaleInt(int? digits) {
    if (digits == null || digits < 0 || digits > 6) return 0;
    return _pow10Int[digits];
  }

  final int _digits = _initDigits(digits);
  final double _k = _initScale(digits);
  final int _scaleInt = _initScaleInt(digits);

  // Native AOT / Wasm ASCII byte buffer (empty singleton on dart2js).
  Uint8List _buf = _isJs ? _emptyBuf : Uint8List(256);
  int _len = 0;

  // dart2js native StringBuffer accumulator (shared dummy on AOT / Wasm).
  final StringBuffer _jsBuf = _isJs ? StringBuffer() : _dummyJsBuf;

  double _x0 = 0;
  double _y0 = 0;
  double _x1 = 0;
  double _y1 = 0;
  bool _hasStart = false;
  bool _hasEnd = false;

  @pragma('vm:prefer-inline')
  String _fmtJs(double x) => _jsNumberText(_k == 0 ? x : _jsRound(x * _k) / _k);

  @pragma('vm:prefer-inline')
  void _ensure(int extra) {
    final needed = _len + extra;
    if (needed <= _buf.length) return;
    _grow(needed);
  }

  void _grow(int needed) {
    var cap = _buf.length;
    while (cap < needed) {
      cap <<= 1;
    }
    final next = Uint8List(cap)..setRange(0, _len, _buf);
    _buf = next;
  }

  @pragma('vm:prefer-inline')
  void _writeAscii(String s) {
    final n = s.length;
    _ensure(n);
    for (var i = 0; i < n; i++) {
      _buf[_len++] = s.codeUnitAt(i);
    }
  }

  /// Writes the exact ECMAScript/SVG representation of [x] into [_buf]
  /// (assumes at least 32 bytes free in [_buf]).
  @pragma('vm:prefer-inline')
  void _writeNum(double x) {
    if (_digits >= 0) {
      _writeRounded(x);
      return;
    }
    _writeFull(x);
  }

  @pragma('vm:prefer-inline')
  void _writeRounded(double x) {
    final qd = _jsRound(x * _k);
    final scaleInt = _scaleInt;
    if (scaleInt != 0 && qd > -_maxDirectRoundQ && qd < _maxDirectRoundQ) {
      var q = qd.toInt();
      if (q == 0) {
        _buf[_len++] = 0x30;
        return;
      }
      final buf = _buf;
      if (q < 0) {
        buf[_len++] = 0x2D;
        q = -q;
      }
      final d = _digits;
      if (d == 0) {
        _len = _writeUintFast(buf, _digitPairs, _len, q);
        return;
      }
      final whole = q ~/ scaleInt;
      var frac = q - whole * scaleInt;
      _len = _writeUintFast(buf, _digitPairs, _len, whole);
      if (frac == 0) return;
      buf[_len++] = 0x2E; // '.'
      if (d == 3) {
        final d0 = (frac * 5243) >> 19;
        final rem = frac - d0 * 100;
        buf[_len++] = 0x30 + d0;
        if (rem != 0) {
          final d1 = (rem * 205) >> 11;
          final d2 = rem - d1 * 10;
          buf[_len++] = 0x30 + d1;
          if (d2 != 0) buf[_len++] = 0x30 + d2;
        }
        return;
      }
      var width = d;
      while (frac % 10 == 0) {
        frac ~/= 10;
        width--;
      }
      final end = _len + width;
      for (var pos = end - 1; pos >= _len; pos--) {
        final next = frac ~/ 10;
        buf[pos] = 0x30 + (frac - next * 10);
        frac = next;
      }
      _len = end;
      return;
    }
    _writeFull(qd / _k);
  }

  @pragma('vm:prefer-inline')
  void _writeFull(double x) {
    if (x == 0) {
      _buf[_len++] = 0x30;
      return;
    }
    var v = x;
    if (v < 0) {
      _buf[_len++] = 0x2D;
      v = -v;
    }
    if (v <= _maxSafeInt) {
      final t = v.truncateToDouble();
      if (v == t) {
        _len = _writeUintFast(_buf, _digitPairs, _len, v.toInt());
        return;
      }
    }
    _writeRyuPositive(v);
  }

  /// Writes a positive non-integer (or > 2^53 / non-finite) double [v] into
  /// [_buf] with ECMAScript shortest-decimal semantics.
  void _writeRyuPositive(double v) {
    _f64Scratch[0] = v;
    final hi = _u32Scratch[_hiWordIndex];
    final lo = _u32Scratch[_loWordIndex];
    final ieeeExp = (hi >> 20) & 0x7FF;
    final ieeeMant = ((hi & 0xFFFFF) << 32) | lo;

    if (ieeeExp == 0x7FF) {
      if (ieeeMant != 0) {
        if (_len > 0 && _buf[_len - 1] == 0x2D) _len--;
        _writeAscii('NaN');
      } else {
        _writeAscii('Infinity');
      }
      return;
    }

    final int e2;
    final int m2;
    if (ieeeExp == 0) {
      e2 = -1076;
      m2 = ieeeMant;
    } else {
      e2 = ieeeExp - 1077;
      m2 = (1 << 52) | ieeeMant;
    }
    final acceptBounds = (m2 & 1) == 0;
    final mv = m2 << 2;
    final mmShift = (ieeeMant != 0 || ieeeExp <= 1) ? 1 : 0;

    if (e2 >= 0) {
      _writeRyuLarge(e2, mv, mmShift, acceptBounds: acceptBounds);
      return;
    }

    // Hot path: e2 < 0 (all fractional doubles and all doubles < 2^54).
    final negE2 = -e2;
    final q = _log10Pow5(negE2) - (negE2 > 1 ? 1 : 0);
    final e10 = q + e2;
    final i = negE2 - q;
    final k = _pow5Bits(i) - _pow5Bitcount;
    final shift = q - k;
    final base = i * 5;
    final table = _pow5Split;
    final m0 = table[base];
    final m1 = table[base + 1];
    final m2l = table[base + 2];
    final m3 = table[base + 3];
    final m4 = table[base + 4];

    final v0 = mv & _mask30;
    final v1 = mv >> 30;

    final s0 = v0 * m0;
    final s1 = (s0 >> 30) + v0 * m1 + v1 * m0;
    final s2 = (s1 >> 30) + v0 * m2l + v1 * m1;
    final s3 = (s2 >> 30) + v0 * m3 + v1 * m2l;
    final s4 = (s3 >> 30) + v0 * m4 + v1 * m3;
    final s5 = (s4 >> 30) + v1 * m4;

    final p0 = s0 & _mask30;
    final p1 = s1 & _mask30;
    final p2 = s2 & _mask30;
    final p3 = s3 & _mask30;
    final p4 = s4 & _mask30;

    var vr = _extractShifted(s5, p4, p3, shift);

    final c0p = p0 + (m0 << 1);
    final c1p = (c0p >> 30) + p1 + (m1 << 1);
    final c2p = (c1p >> 30) + p2 + (m2l << 1);
    final c3p = (c2p >> 30) + p3 + (m3 << 1);
    final c4p = (c3p >> 30) + p4 + (m4 << 1);
    var vp = _extractShifted(
      s5 + (c4p >> 30),
      c4p & _mask30,
      c3p & _mask30,
      shift,
    );

    final b0 = p0 - (m0 << mmShift);
    final b1 = (b0 >> 30) + p1 - (m1 << mmShift);
    final b2 = (b1 >> 30) + p2 - (m2l << mmShift);
    final b3 = (b2 >> 30) + p3 - (m3 << mmShift);
    final b4 = (b3 >> 30) + p4 - (m4 << mmShift);
    var vm = _extractShifted(
      s5 + (b4 >> 30),
      b4 & _mask30,
      b3 & _mask30,
      shift,
    );

    if (q <= 1) {
      _writeRyuTrailingZeros(
        vr,
        acceptBounds ? vp : vp - 1,
        vm,
        e10,
        acceptBounds: acceptBounds,
        vrIsTrailingZeros: true,
        vmIsTrailingZeros: acceptBounds && mmShift == 1,
      );
      return;
    }
    if (q < 63 && _multipleOfPowerOf2(mv, q)) {
      _writeRyuTrailingZeros(
        vr,
        vp,
        vm,
        e10,
        acceptBounds: acceptBounds,
        vrIsTrailingZeros: true,
        vmIsTrailingZeros: false,
      );
      return;
    }

    var removed = 0;
    var roundUp = false;
    final vpDiv100 = vp ~/ 100;
    final vmDiv100 = vm ~/ 100;
    if (vpDiv100 > vmDiv100) {
      final vrDiv100 = vr ~/ 100;
      final vrMod100 = vr - vrDiv100 * 100;
      roundUp = vrMod100 >= 50;
      vr = vrDiv100;
      vp = vpDiv100;
      vm = vmDiv100;
      removed = 2;
    }
    while (true) {
      final vpDiv10 = vp ~/ 10;
      final vmDiv10 = vm ~/ 10;
      if (vpDiv10 <= vmDiv10) break;
      final vrDiv10 = vr ~/ 10;
      final vrMod10 = vr - vrDiv10 * 10;
      roundUp = vrMod10 >= 5;
      vr = vrDiv10;
      vp = vpDiv10;
      vm = vmDiv10;
      removed++;
    }
    final output = vr + ((vr == vm) || roundUp ? 1 : 0);
    _writeDecimalEcmascript(output, e10 + removed);
  }

  /// Cold path of Ryū for large doubles (`e2 >= 0`, i.e. `v >= 2^54`).
  void _writeRyuLarge(
    int e2,
    int mv,
    int mmShift, {
    required bool acceptBounds,
  }) {
    final q = _log10Pow2(e2) - (e2 > 3 ? 1 : 0);
    final e10 = q;
    final k = _pow5InvBitcount + _pow5Bits(q) - 1;
    final shift = -e2 + q + k;
    final base = q * 5;
    final table = _pow5InvSplit;
    final m0 = table[base];
    final m1 = table[base + 1];
    final m2l = table[base + 2];
    final m3 = table[base + 3];
    final m4 = table[base + 4];

    final v0 = mv & _mask30;
    final v1 = mv >> 30;

    final s0 = v0 * m0;
    final s1 = (s0 >> 30) + v0 * m1 + v1 * m0;
    final s2 = (s1 >> 30) + v0 * m2l + v1 * m1;
    final s3 = (s2 >> 30) + v0 * m3 + v1 * m2l;
    final s4 = (s3 >> 30) + v0 * m4 + v1 * m3;
    final s5 = (s4 >> 30) + v1 * m4;

    final p0 = s0 & _mask30;
    final p1 = s1 & _mask30;
    final p2 = s2 & _mask30;
    final p3 = s3 & _mask30;
    final p4 = s4 & _mask30;

    final vr = _extractShifted(s5, p4, p3, shift);

    final c0p = p0 + (m0 << 1);
    final c1p = (c0p >> 30) + p1 + (m1 << 1);
    final c2p = (c1p >> 30) + p2 + (m2l << 1);
    final c3p = (c2p >> 30) + p3 + (m3 << 1);
    final c4p = (c3p >> 30) + p4 + (m4 << 1);
    var vp = _extractShifted(
      s5 + (c4p >> 30),
      c4p & _mask30,
      c3p & _mask30,
      shift,
    );

    final b0 = p0 - (m0 << mmShift);
    final b1 = (b0 >> 30) + p1 - (m1 << mmShift);
    final b2 = (b1 >> 30) + p2 - (m2l << mmShift);
    final b3 = (b2 >> 30) + p3 - (m3 << mmShift);
    final b4 = (b3 >> 30) + p4 - (m4 << mmShift);
    final vm = _extractShifted(
      s5 + (b4 >> 30),
      b4 & _mask30,
      b3 & _mask30,
      shift,
    );

    var vrZeros = false;
    var vmZeros = false;
    if (q <= 21) {
      if (mv % 5 == 0) {
        vrZeros = _multipleOfPowerOf5(mv, q);
      } else if (acceptBounds) {
        vmZeros = _multipleOfPowerOf5(mv - 1 - mmShift, q);
      } else if (_multipleOfPowerOf5(mv + 2, q)) {
        vp--;
      }
    }

    _writeRyuTrailingZeros(
      vr,
      vp,
      vm,
      e10,
      acceptBounds: acceptBounds,
      vrIsTrailingZeros: vrZeros,
      vmIsTrailingZeros: vmZeros,
    );
  }

  void _writeRyuTrailingZeros(
    int vrInit,
    int vpInit,
    int vmInit,
    int e10, {
    required bool acceptBounds,
    required bool vrIsTrailingZeros,
    required bool vmIsTrailingZeros,
  }) {
    var vr = vrInit;
    var vp = vpInit;
    var vm = vmInit;
    var vrZeros = vrIsTrailingZeros;
    var vmZeros = vmIsTrailingZeros;
    var removed = 0;
    var lastRemovedDigit = 0;

    if (vrZeros || vmZeros) {
      while (true) {
        final vpDiv10 = vp ~/ 10;
        final vmDiv10 = vm ~/ 10;
        if (vpDiv10 <= vmDiv10) break;
        final vmMod10 = vm - vmDiv10 * 10;
        final vrDiv10 = vr ~/ 10;
        final vrMod10 = vr - vrDiv10 * 10;
        vmZeros = vmZeros && vmMod10 == 0;
        vrZeros = vrZeros && lastRemovedDigit == 0;
        lastRemovedDigit = vrMod10;
        vr = vrDiv10;
        vp = vpDiv10;
        vm = vmDiv10;
        removed++;
      }
      if (vmZeros) {
        while (true) {
          final vmDiv10 = vm ~/ 10;
          if (vm - vmDiv10 * 10 != 0) break;
          final vpDiv10 = vp ~/ 10;
          final vrDiv10 = vr ~/ 10;
          final vrMod10 = vr - vrDiv10 * 10;
          vrZeros = vrZeros && lastRemovedDigit == 0;
          lastRemovedDigit = vrMod10;
          vr = vrDiv10;
          vp = vpDiv10;
          vm = vmDiv10;
          removed++;
        }
      }
      if (vrZeros && lastRemovedDigit == 5 && vr.isEven) {
        lastRemovedDigit = 4;
      }
      final output =
          vr +
          ((vr == vm && (!acceptBounds || !vmZeros)) || lastRemovedDigit >= 5
              ? 1
              : 0);
      _writeDecimalEcmascript(output, e10 + removed);
      return;
    }

    var roundUp = false;
    final vpDiv100 = vp ~/ 100;
    final vmDiv100 = vm ~/ 100;
    if (vpDiv100 > vmDiv100) {
      final vrDiv100 = vr ~/ 100;
      final vrMod100 = vr - vrDiv100 * 100;
      roundUp = vrMod100 >= 50;
      vr = vrDiv100;
      vp = vpDiv100;
      vm = vmDiv100;
      removed = 2;
    }
    while (true) {
      final vpDiv10 = vp ~/ 10;
      final vmDiv10 = vm ~/ 10;
      if (vpDiv10 <= vmDiv10) break;
      final vrDiv10 = vr ~/ 10;
      final vrMod10 = vr - vrDiv10 * 10;
      roundUp = vrMod10 >= 5;
      vr = vrDiv10;
      vp = vpDiv10;
      vm = vmDiv10;
      removed++;
    }
    final output = vr + ((vr == vm) || roundUp ? 1 : 0);
    _writeDecimalEcmascript(output, e10 + removed);
  }

  /// Writes [output] * 10^[exp] into [_buf] using ECMAScript
  /// `Number.prototype.toString()` formatting rules.
  @pragma('vm:prefer-inline')
  void _writeDecimalEcmascript(int output, int exp) {
    final olength = _decimalLength17(output);
    final n = exp + olength;
    final buf = _buf;
    final pairs = _digitPairs;

    if (n > 0 && n <= 21) {
      if (olength <= n) {
        _len = _writeUintFast(buf, pairs, _len, output);
        for (var i = olength; i < n; i++) {
          buf[_len++] = 0x30;
        }
        return;
      }
      final start = _len;
      _len = _writeUintFast(buf, pairs, start + 1, output);
      for (var i = 0; i < n; i++) {
        buf[start + i] = buf[start + 1 + i];
      }
      buf[start + n] = 0x2E; // '.'
      return;
    }

    if (n > -6 && n <= 0) {
      buf[_len++] = 0x30;
      buf[_len++] = 0x2E;
      for (var i = 0; i < -n; i++) {
        buf[_len++] = 0x30;
      }
      _len = _writeUintFast(buf, pairs, _len, output);
      return;
    }

    // Scientific notation: d[.ddd]e[+-]exp
    if (olength == 1) {
      buf[_len++] = 0x30 + output;
    } else {
      final start = _len;
      _len = _writeUintFast(buf, pairs, start + 1, output);
      buf[start] = buf[start + 1];
      buf[start + 1] = 0x2E;
    }
    buf[_len++] = 0x65; // 'e'
    final sciExp = n - 1;
    if (sciExp < 0) {
      buf[_len++] = 0x2D;
      _len = _writeUnder10000(buf, pairs, _len, -sciExp);
    } else {
      buf[_len++] = 0x2B;
      _len = _writeUnder10000(buf, pairs, _len, sciExp);
    }
  }

  /// `path.js:33` `moveTo(x, y)`.
  @override
  void moveTo(double x, double y) {
    _x0 = _x1 = x;
    _y0 = _y1 = y;
    _hasStart = true;
    _hasEnd = true;
    if (_isJs) {
      _jsBuf.write('M${_fmtJs(x)},${_fmtJs(y)}');
      return;
    }
    _ensure(68);
    _buf[_len++] = 0x4D; // 'M'
    _writeNum(x);
    _buf[_len++] = 0x2C; // ','
    _writeNum(y);
  }

  /// `path.js:36` `closePath()`.
  @override
  void closePath() {
    if (_hasEnd) {
      _x1 = _x0;
      _y1 = _y0;
      _hasEnd = _hasStart;
      if (_isJs) {
        _jsBuf.write('Z');
        return;
      }
      _ensure(1);
      _buf[_len++] = 0x5A; // 'Z'
    }
  }

  /// `path.js:42` `lineTo(x, y)`.
  @override
  void lineTo(double x, double y) {
    _x1 = x;
    _y1 = y;
    _hasEnd = true;
    if (_isJs) {
      _jsBuf.write('L${_fmtJs(x)},${_fmtJs(y)}');
      return;
    }
    _ensure(68);
    _buf[_len++] = 0x4C; // 'L'
    _writeNum(x);
    _buf[_len++] = 0x2C; // ','
    _writeNum(y);
  }

  /// `path.js:45` `quadraticCurveTo(x1, y1, x, y)`.
  @override
  void quadraticCurveTo(double x1, double y1, double x, double y) {
    _x1 = x;
    _y1 = y;
    _hasEnd = true;
    if (_isJs) {
      _jsBuf.write('Q${_fmtJs(x1)},${_fmtJs(y1)},${_fmtJs(x)},${_fmtJs(y)}');
      return;
    }
    _ensure(136);
    _buf[_len++] = 0x51; // 'Q'
    _writeNum(x1);
    _buf[_len++] = 0x2C;
    _writeNum(y1);
    _buf[_len++] = 0x2C;
    _writeNum(x);
    _buf[_len++] = 0x2C;
    _writeNum(y);
  }

  /// `path.js:48` `bezierCurveTo(x1, y1, x2, y2, x, y)`.
  @override
  void bezierCurveTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x,
    double y,
  ) {
    _x1 = x;
    _y1 = y;
    _hasEnd = true;
    if (_isJs) {
      _jsBuf.write(
        'C${_fmtJs(x1)},${_fmtJs(y1)},${_fmtJs(x2)},'
        '${_fmtJs(y2)},${_fmtJs(x)},${_fmtJs(y)}',
      );
      return;
    }
    _ensure(204);
    _buf[_len++] = 0x43; // 'C'
    _writeNum(x1);
    _buf[_len++] = 0x2C;
    _writeNum(y1);
    _buf[_len++] = 0x2C;
    _writeNum(x2);
    _buf[_len++] = 0x2C;
    _writeNum(y2);
    _buf[_len++] = 0x2C;
    _writeNum(x);
    _buf[_len++] = 0x2C;
    _writeNum(y);
  }

  /// `path.js:51` `arcTo(x1, y1, x2, y2, r)`.
  @override
  void arcTo(double x1, double y1, double x2, double y2, double r) {
    if (r < 0) {
      throw RangeError.value(r, 'r', 'negative radius: $r');
    }

    final x0 = _x1;
    final y0 = _y1;
    final x21 = x2 - x1;
    final y21 = y2 - y1;
    final x01 = x0 - x1;
    final y01 = y0 - y1;
    final l01_2 = x01 * x01 + y01 * y01;

    if (!_hasEnd) {
      _x1 = x1;
      _y1 = y1;
      _hasEnd = true;
      if (_isJs) {
        _jsBuf.write('M${_fmtJs(x1)},${_fmtJs(y1)}');
        return;
      }
      _ensure(68);
      _buf[_len++] = 0x4D;
      _writeNum(x1);
      _buf[_len++] = 0x2C;
      _writeNum(y1);
    } else if (!(l01_2 > _epsilon)) {
      return;
    } else if (!((y01 * x21 - y21 * x01).abs() > _epsilon) ||
        r == 0 ||
        r.isNaN) {
      _x1 = x1;
      _y1 = y1;
      _hasEnd = true;
      if (_isJs) {
        _jsBuf.write('L${_fmtJs(x1)},${_fmtJs(y1)}');
        return;
      }
      _ensure(68);
      _buf[_len++] = 0x4C;
      _writeNum(x1);
      _buf[_len++] = 0x2C;
      _writeNum(y1);
    } else {
      // DIVERGES(d3-path): platform-path-math-last-bit, dart:math acos/tan.
      final x20 = x2 - x0;
      final y20 = y2 - y0;
      final l21_2 = x21 * x21 + y21 * y21;
      final l20_2 = x20 * x20 + y20 * y20;
      final l21 = math.sqrt(l21_2);
      final l01 = math.sqrt(l01_2);
      final l =
          r *
          math.tan(
            (_pi - math.acos((l21_2 + l01_2 - l20_2) / (2 * l21 * l01))) / 2,
          );
      final t01 = l / l01;
      final t21 = l / l21;

      final ex = x1 + t21 * x21;
      final ey = y1 + t21 * y21;
      _x1 = ex;
      _y1 = ey;
      _hasEnd = true;
      final sweep = y01 * x20 > x01 * y20;

      if (_isJs) {
        final jsBuf = _jsBuf;
        if ((t01 - 1).abs() > _epsilon) {
          jsBuf.write('L${_fmtJs(x1 + t01 * x01)},${_fmtJs(y1 + t01 * y01)}');
        }
        final rs = _fmtJs(r);
        jsBuf.write(
          'A$rs,$rs,0,0,${sweep ? 1 : 0},${_fmtJs(ex)},${_fmtJs(ey)}',
        );
        return;
      }

      _ensure(220);
      if ((t01 - 1).abs() > _epsilon) {
        _buf[_len++] = 0x4C;
        _writeNum(x1 + t01 * x01);
        _buf[_len++] = 0x2C;
        _writeNum(y1 + t01 * y01);
      }
      _buf[_len++] = 0x41; // 'A'
      final rStart = _len;
      _writeNum(r);
      final rLen = _len - rStart;
      _buf[_len++] = 0x2C;
      for (var i = 0; i < rLen; i++) {
        _buf[_len++] = _buf[rStart + i];
      }
      _buf[_len++] = 0x2C;
      _buf[_len++] = 0x30;
      _buf[_len++] = 0x2C;
      _buf[_len++] = 0x30;
      _buf[_len++] = 0x2C;
      _buf[_len++] = sweep ? 0x31 : 0x30;
      _buf[_len++] = 0x2C;
      _writeNum(ex);
      _buf[_len++] = 0x2C;
      _writeNum(ey);
    }
  }

  /// `path.js:100` `arc(x, y, r, a0, a1, ccw)`.
  // DIVERGES(d3-path): adapt-path-typed-args, typed bool ccw parameter.
  @override
  void arc(
    double x,
    double y,
    double r,
    double a0,
    double a1, [
    bool ccw = false,
  ]) {
    if (r < 0) {
      throw RangeError.value(r, 'r', 'negative radius: $r');
    }

    // DIVERGES(d3-path): platform-path-math-last-bit, dart:math cos/sin.
    final dx = r * math.cos(a0);
    final dy = r * math.sin(a0);
    final x0 = x + dx;
    final y0 = y + dy;
    var da = ccw ? a0 - a1 : a1 - a0;

    if (_isJs) {
      final jsBuf = _jsBuf;
      final cw = ccw ? '0' : '1';
      if (!_hasEnd) {
        jsBuf.write('M${_fmtJs(x0)},${_fmtJs(y0)}');
      } else if ((_x1 - x0).abs() > _epsilon || (_y1 - y0).abs() > _epsilon) {
        jsBuf.write('L${_fmtJs(x0)},${_fmtJs(y0)}');
      }
      if (r == 0 || r.isNaN) return;
      if (da < 0) da = da.remainder(_tau) + _tau;
      if (da > _tauEpsilon) {
        _x1 = x0;
        _y1 = y0;
        _hasEnd = true;
        final rs = _fmtJs(r);
        jsBuf.write(
          'A$rs,$rs,0,1,$cw,${_fmtJs(x - dx)},${_fmtJs(y - dy)}'
          'A$rs,$rs,0,1,$cw,${_fmtJs(x0)},${_fmtJs(y0)}',
        );
      } else if (da > _epsilon) {
        final ex = x + r * math.cos(a1);
        final ey = y + r * math.sin(a1);
        _x1 = ex;
        _y1 = ey;
        _hasEnd = true;
        final rs = _fmtJs(r);
        jsBuf.write(
          'A$rs,$rs,0,${da >= _pi ? 1 : 0},$cw,${_fmtJs(ex)},${_fmtJs(ey)}',
        );
      }
      return;
    }

    _ensure(340);
    final cwByte = ccw ? 0x30 : 0x31;

    if (!_hasEnd) {
      _buf[_len++] = 0x4D; // 'M'
      _writeNum(x0);
      _buf[_len++] = 0x2C;
      _writeNum(y0);
    } else if ((_x1 - x0).abs() > _epsilon || (_y1 - y0).abs() > _epsilon) {
      _buf[_len++] = 0x4C; // 'L'
      _writeNum(x0);
      _buf[_len++] = 0x2C;
      _writeNum(y0);
    }

    if (r == 0 || r.isNaN) return;

    if (da < 0) da = da.remainder(_tau) + _tau;

    if (da > _tauEpsilon) {
      _x1 = x0;
      _y1 = y0;
      _hasEnd = true;
      final aStart = _len;
      _buf[_len++] = 0x41; // 'A'
      final rStart = _len;
      _writeNum(r);
      final rLen = _len - rStart;
      _buf[_len++] = 0x2C;
      for (var i = 0; i < rLen; i++) {
        _buf[_len++] = _buf[rStart + i];
      }
      _buf[_len++] = 0x2C;
      _buf[_len++] = 0x30;
      _buf[_len++] = 0x2C;
      _buf[_len++] = 0x31;
      _buf[_len++] = 0x2C;
      _buf[_len++] = cwByte;
      _buf[_len++] = 0x2C;
      final prefixLen = _len - aStart;
      _writeNum(x - dx);
      _buf[_len++] = 0x2C;
      _writeNum(y - dy);
      for (var i = 0; i < prefixLen; i++) {
        _buf[_len++] = _buf[aStart + i];
      }
      _writeNum(x0);
      _buf[_len++] = 0x2C;
      _writeNum(y0);
    } else if (da > _epsilon) {
      final ex = x + r * math.cos(a1);
      final ey = y + r * math.sin(a1);
      _x1 = ex;
      _y1 = ey;
      _hasEnd = true;
      _buf[_len++] = 0x41; // 'A'
      final rStart = _len;
      _writeNum(r);
      final rLen = _len - rStart;
      _buf[_len++] = 0x2C;
      for (var i = 0; i < rLen; i++) {
        _buf[_len++] = _buf[rStart + i];
      }
      _buf[_len++] = 0x2C;
      _buf[_len++] = 0x30;
      _buf[_len++] = 0x2C;
      _buf[_len++] = da >= _pi ? 0x31 : 0x30;
      _buf[_len++] = 0x2C;
      _buf[_len++] = cwByte;
      _buf[_len++] = 0x2C;
      _writeNum(ex);
      _buf[_len++] = 0x2C;
      _writeNum(ey);
    }
  }

  /// `path.js:139` `rect(x, y, w, h)`.
  @override
  void rect(double x, double y, double w, double h) {
    _x0 = _x1 = x;
    _y0 = _y1 = y;
    _hasStart = true;
    _hasEnd = true;
    if (_isJs) {
      _jsBuf.write(
        'M${_fmtJs(x)},${_fmtJs(y)}h${_fmtJs(w)}v${_fmtJs(h)}h${_fmtJs(-w)}Z',
      );
      return;
    }
    _ensure(176);
    _buf[_len++] = 0x4D; // 'M'
    _writeNum(x);
    _buf[_len++] = 0x2C; // ','
    _writeNum(y);
    _buf[_len++] = 0x68; // 'h'
    _writeNum(w);
    _buf[_len++] = 0x76; // 'v'
    _writeNum(h);
    _buf[_len++] = 0x68; // 'h'
    _writeNum(-w);
    _buf[_len++] = 0x5A; // 'Z'
  }

  /// `path.js:142` `toString()`.
  @override
  String toString() {
    if (_isJs) return _jsBuf.toString();
    return _len == 0 ? '' : String.fromCharCodes(_buf, 0, _len);
  }
}

/// `path.js:147` `path()`: constructs a new [Path] serializer with full
/// precision.
Path path() => Path();

/// `path.js:154` `pathRound(digits = 3)`: constructs a new [Path] serializer
/// rounding coordinates to at most [digits] decimal places.
// DIVERGES(d3-path): adapt-path-typed-args, non-nullable int digits = 3.
Path pathRound([int digits = 3]) => Path(digits);
