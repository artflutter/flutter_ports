// Ported from d3-delaunay v6.0.4 src/polygon.js (ISC, Observable, Inc.).

/// Port of `src/polygon.js` of d3-delaunay 6.0.4: [CanvasPath] sink recording
/// closed polygons as typed `List<(double, double)>`.
library;

import 'package:flutter_d3_path_port/d3_path.dart';

/// `polygon.js:1` `Polygon`: collects `moveTo`/`lineTo`/`closePath` commands
/// into a closed `List<(double, double)>`.
// DIVERGES(d3-delaunay): adapt-delaunay-typed-api, typed (double, double) ring.
class DelaunayPolygon() implements CanvasPath {
  /// Creates an empty [DelaunayPolygon] recorder.
  this;

  final List<(double, double)> _points = <(double, double)>[];

  @override
  void moveTo(double x, double y) {
    _points.add((x, y));
  }

  @override
  void closePath() {
    if (_points.isNotEmpty) {
      _points.add(_points[0]);
    }
  }

  @override
  void lineTo(double x, double y) {
    _points.add((x, y));
  }

  @override
  void quadraticCurveTo(double x1, double y1, double x, double y) {
    throw UnsupportedError('DelaunayPolygon does not implement curves');
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
    throw UnsupportedError('DelaunayPolygon does not implement curves');
  }

  @override
  void arcTo(double x1, double y1, double x2, double y2, double r) {
    throw UnsupportedError('DelaunayPolygon does not implement arcs');
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
    throw UnsupportedError('DelaunayPolygon does not implement arcs');
  }

  @override
  void rect(double x, double y, double w, double h) {
    _points
      ..add((x, y))
      ..add((x + w, y))
      ..add((x + w, y + h))
      ..add((x, y + h))
      ..add((x, y));
  }

  /// `polygon.js:14` `value()`: returns the collected polygon vertices, or
  /// `null` if empty.
  List<(double, double)>? value() => _points.isEmpty ? null : _points;
}
