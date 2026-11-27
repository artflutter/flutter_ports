// Ported from d3-delaunay v6.0.4 src/path.js (ISC, Observable, Inc.).

/// Port of `src/path.js` of d3-delaunay 6.0.4: lightweight SVG path string
/// serializer implementing [CanvasPath].
library;

import 'package:flutter_d3_path_port/d3_path.dart';

const double _epsilon = 1e-6;
const double _maxSafeInt = 9007199254740992; // 2^53

String _fmtNum(double x) {
  if (x == 0) return '0';
  if (x >= -_maxSafeInt && x <= _maxSafeInt) {
    final t = x.truncateToDouble();
    if (x == t) return x.toInt().toString();
  }
  return x.toString();
}

/// `path.js:3` `Path`: SVG path string recorder used by `Delaunay.render*ToSvg`
/// and `Voronoi.render*ToSvg`.
///
/// Delegates line/move/rect/close serialization to `flutter_d3_path_port`'s
/// Ryū ASCII byte-buffer [Path] for fast SVG output on AOT and Wasm, while
/// matching `d3-delaunay`'s exact two-half-arc circle syntax in [arc].
// DIVERGES(d3-delaunay): adapt-delaunay-typed-api, implements CanvasPath.
// DIVERGES(d3-delaunay): adapt-delaunay-fast-forms, delegates to d3-path Path.
class DelaunayPath() implements CanvasPath {
  /// Creates an empty [DelaunayPath].
  this;

  final Path _fastPath = Path();
  StringBuffer? _arcBuf;
  double? _x0;
  double? _y0;
  double? _x1;
  double? _y1;
  bool _hasCommands = false;

  @override
  void moveTo(double x, double y) {
    _hasCommands = true;
    _x0 = _x1 = x;
    _y0 = _y1 = y;
    final buf = _arcBuf;
    if (buf != null) {
      buf
        ..write('M')
        ..write(_fmtNum(x))
        ..write(',')
        ..write(_fmtNum(y));
    } else {
      _fastPath.moveTo(x, y);
    }
  }

  @override
  void closePath() {
    if (_x1 != null) {
      _x1 = _x0;
      _y1 = _y0;
      final buf = _arcBuf;
      if (buf != null) {
        buf.write('Z');
      } else {
        _fastPath.closePath();
      }
    }
  }

  @override
  void lineTo(double x, double y) {
    _hasCommands = true;
    _x1 = x;
    _y1 = y;
    final buf = _arcBuf;
    if (buf != null) {
      buf
        ..write('L')
        ..write(_fmtNum(x))
        ..write(',')
        ..write(_fmtNum(y));
    } else {
      _fastPath.lineTo(x, y);
    }
  }

  @override
  void quadraticCurveTo(double x1, double y1, double x, double y) {
    _hasCommands = true;
    _x1 = x;
    _y1 = y;
    final buf = _arcBuf;
    if (buf != null) {
      buf
        ..write('Q')
        ..write(_fmtNum(x1))
        ..write(',')
        ..write(_fmtNum(y1))
        ..write(',')
        ..write(_fmtNum(x))
        ..write(',')
        ..write(_fmtNum(y));
    } else {
      _fastPath.quadraticCurveTo(x1, y1, x, y);
    }
  }

  @override
  void bezierCurveTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x,
    double y,
  ) {
    _hasCommands = true;
    _x1 = x;
    _y1 = y;
    final buf = _arcBuf;
    if (buf != null) {
      buf
        ..write('C')
        ..write(_fmtNum(x1))
        ..write(',')
        ..write(_fmtNum(y1))
        ..write(',')
        ..write(_fmtNum(x2))
        ..write(',')
        ..write(_fmtNum(y2))
        ..write(',')
        ..write(_fmtNum(x))
        ..write(',')
        ..write(_fmtNum(y));
    } else {
      _fastPath.bezierCurveTo(x1, y1, x2, y2, x, y);
    }
  }

  @override
  void arcTo(double x1, double y1, double x2, double y2, double r) {
    throw UnsupportedError('DelaunayPath does not implement arcTo');
  }

  @override
  void arc(
    double x,
    double y,
    double r,
    double a0,
    double a1, [
    bool ccw = false,
  ]) {
    final x0 = x + r;
    final y0 = y;
    if (r < 0) throw RangeError.value(r, 'r', 'negative radius');
    final buf = _arcBuf ??= StringBuffer(_fastPath.toString());
    if (_x1 == null) {
      _hasCommands = true;
      buf
        ..write('M')
        ..write(_fmtNum(x0))
        ..write(',')
        ..write(_fmtNum(y0));
    } else if ((_x1! - x0).abs() > _epsilon || (_y1! - y0).abs() > _epsilon) {
      _hasCommands = true;
      buf
        ..write('L')
        ..write(_fmtNum(x0))
        ..write(',')
        ..write(_fmtNum(y0));
    }
    if (r == 0) return;
    _hasCommands = true;
    _x1 = x0;
    _y1 = y0;
    final rs = _fmtNum(r);
    final ys = _fmtNum(y);
    buf
      ..write('A')
      ..write(rs)
      ..write(',')
      ..write(rs)
      ..write(',0,1,1,')
      ..write(_fmtNum(x - r))
      ..write(',')
      ..write(ys)
      ..write('A')
      ..write(rs)
      ..write(',')
      ..write(rs)
      ..write(',0,1,1,')
      ..write(_fmtNum(x0))
      ..write(',')
      ..write(_fmtNum(y0));
  }

  @override
  void rect(double x, double y, double w, double h) {
    _hasCommands = true;
    _x0 = _x1 = x;
    _y0 = _y1 = y;
    final buf = _arcBuf;
    if (buf != null) {
      buf
        ..write('M')
        ..write(_fmtNum(x))
        ..write(',')
        ..write(_fmtNum(y))
        ..write('h')
        ..write(_fmtNum(w))
        ..write('v')
        ..write(_fmtNum(h))
        ..write('h')
        ..write(_fmtNum(-w))
        ..write('Z');
    } else {
      _fastPath.rect(x, y, w, h);
    }
  }

  /// `path.js:34` `value()`: returns the accumulated SVG path string, or
  /// `null` if no commands were recorded.
  String? value() {
    if (!_hasCommands) return null;
    final buf = _arcBuf;
    if (buf != null) return buf.isEmpty ? null : buf.toString();
    final s = _fastPath.toString();
    return s.isEmpty ? null : s;
  }
}
