// Ported from d3-geo v3.1.1 test/path/test-context.js (ISC, Mike Bostock).

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:flutter_d3_path_port/d3_path.dart';

// Test value-object helpers are immutable const classes without package:meta.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

sealed class const TestPathOp();

final class const TestMoveTo(final int x, final int y) extends TestPathOp {
  @override
  bool operator ==(Object other) =>
      other is TestMoveTo && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash('moveTo', x, y);

  @override
  String toString() => 'moveTo($x, $y)';
}

final class const TestLineTo(final int x, final int y) extends TestPathOp {
  @override
  bool operator ==(Object other) =>
      other is TestLineTo && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash('lineTo', x, y);

  @override
  String toString() => 'lineTo($x, $y)';
}

final class const TestArc(final int x, final int y, final double r)
    extends TestPathOp {
  @override
  bool operator ==(Object other) =>
      other is TestArc && other.x == x && other.y == y && other.r == r;

  @override
  int get hashCode => Object.hash('arc', x, y, r);

  @override
  String toString() => 'arc($x, $y, $r)';
}

final class const TestClosePath() extends TestPathOp {
  @override
  bool operator ==(Object other) => other is TestClosePath;

  @override
  int get hashCode => 'closePath'.hashCode;

  @override
  String toString() => 'closePath()';
}

final class TestContext() implements CanvasPath {
  List<TestPathOp> _buffer = <TestPathOp>[];

  @override
  void arc(
    double x,
    double y,
    double r,
    double a0,
    double a1, [
    bool ccw = false,
  ]) {
    _buffer.add(TestArc(geoJsRound(x).toInt(), geoJsRound(y).toInt(), r));
  }

  @override
  void moveTo(double x, double y) {
    _buffer.add(TestMoveTo(geoJsRound(x).toInt(), geoJsRound(y).toInt()));
  }

  @override
  void lineTo(double x, double y) {
    _buffer.add(TestLineTo(geoJsRound(x).toInt(), geoJsRound(y).toInt()));
  }

  @override
  void closePath() {
    _buffer.add(const TestClosePath());
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
  void rect(double x, double y, double w, double h) {}

  List<TestPathOp> result() {
    final res = _buffer;
    _buffer = <TestPathOp>[];
    return res;
  }
}

TestContext testContext() => TestContext();
