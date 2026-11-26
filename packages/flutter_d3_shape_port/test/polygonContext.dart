// Ported from d3-shape v3.2.0 test/polygonContext.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_path_port/d3_path.dart';

/// `polygonContext.js:3` `polygonContext`: records polygon vertices emitted to
/// a [CanvasPath] and computes the absolute polygon area via the shoelace
/// formula (matching `d3-polygon`'s `polygonArea`).
final class PolygonContext() implements CanvasPath {
  /// Creates an empty [PolygonContext].
  this;

  List<(double, double)>? points;

  /// Absolute area of the recorded polygon.
  double area() {
    final pts = points!;
    final n = pts.length;
    if (n < 3) return 0;
    var a = pts[n - 1];
    var sum = 0.0;
    for (var i = 0; i < n; ++i) {
      final b = pts[i];
      sum += a.$2 * b.$1 - a.$1 * b.$2;
      a = b;
    }
    return (sum / 2).abs();
  }

  @override
  void moveTo(double x, double y) {
    points = [(x, y)];
  }

  @override
  void lineTo(double x, double y) {
    points!.add((x, y));
  }

  @override
  void rect(double x, double y, double w, double h) {
    points = [(x, y), (x + w, y), (x + w, y + h), (x, y + h)];
  }

  @override
  void closePath() {}

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
}

/// Creates a new [PolygonContext].
PolygonContext polygonContext() => PolygonContext();
