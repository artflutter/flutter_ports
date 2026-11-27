// Ported from d3-delaunay v6.0.4 test/context.js (ISC, Observable, Inc.).

import 'package:flutter_d3_path_port/d3_path.dart';

const double _maxSafeInt = 9007199254740992;

String _fmt(double x) {
  if (x == 0) return '0';
  if (x >= -_maxSafeInt && x <= _maxSafeInt) {
    final t = x.truncateToDouble();
    if (x == t) return x.toInt().toString();
  }
  return x.toString();
}

/// Minimal test [CanvasPath] recorder matching `test/context.js`.
class TestContext() implements CanvasPath {
  final StringBuffer _buf = StringBuffer();

  @override
  void moveTo(double x, double y) {
    _buf
      ..write('M')
      ..write(_fmt(x))
      ..write(',')
      ..write(_fmt(y));
  }

  @override
  void lineTo(double x, double y) {
    _buf
      ..write('L')
      ..write(_fmt(x))
      ..write(',')
      ..write(_fmt(y));
  }

  @override
  void closePath() {
    _buf.write('Z');
  }

  @override
  void quadraticCurveTo(double x1, double y1, double x, double y) {}

  @override
  void bezierCurveTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x,
    double y,
  ) {}

  @override
  void arcTo(double x1, double y1, double x2, double y2, double r) {}

  @override
  void arc(
    double x,
    double y,
    double r,
    double a0,
    double a1, [
    bool ccw = false,
  ]) {}

  @override
  void rect(double x, double y, double w, double h) {}

  @override
  String toString() {
    final result = _buf.toString();
    _buf.clear();
    return result;
  }
}
