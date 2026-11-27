// Ported from d3-geo v3.1.1 src/graticule.js (ISC, Mike Bostock).

/// Port of `src/graticule.js` of d3-geo 3.1.1: [GeoGraticuleGenerator],
/// [geoGraticule], and [geoGraticule10].
library;

import 'package:flutter_d3_array_port/d3_array.dart' show range;
import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';

List<GeoPosition> Function(double x) _graticuleX(
  double y0,
  double y1,
  double dy,
) {
  final ys = <double>[...range(y0, y1 - geoEpsilon, dy), y1];
  return (double x) => <GeoPosition>[for (final y in ys) (x, y)];
}

List<GeoPosition> Function(double y) _graticuleY(
  double x0,
  double x1,
  double dx,
) {
  final xs = <double>[...range(x0, x1 - geoEpsilon, dx), x1];
  return (double y) => <GeoPosition>[for (final x in xs) (x, y)];
}

/// Typed geographic graticule generator (`graticule.js:14`, D3 ADR 0024).
// DIVERGES(d3-geo): adapt-geo-typed-api, typed properties and GeoJSON return
// types replace JS dual getter/setter functions and untyped objects.
final class GeoGraticuleGenerator() {
  /// Creates a [GeoGraticuleGenerator] with default extents, steps, and
  /// precision.
  this {
    extentMajor = const ((-180, -90 + geoEpsilon), (180, 90 - geoEpsilon));
    extentMinor = const ((-180, -80 - geoEpsilon), (180, 80 + geoEpsilon));
  }

  double _x0 = -180;
  double _y0 = -80 - geoEpsilon;
  double _x1 = 180;
  double _y1 = 80 + geoEpsilon;
  double _majorX0 = -180;
  double _majorY0 = -90 + geoEpsilon;
  double _majorX1 = 180;
  double _majorY1 = 90 - geoEpsilon;

  double _dx = 10;
  double _dy = 10;
  double _majorDx = 90;
  double _majorDy = 360;

  double _precision = 2.5;

  late List<GeoPosition> Function(double x) _xFn;
  late List<GeoPosition> Function(double y) _yFn;
  late List<GeoPosition> Function(double x) _majorXFn;
  late List<GeoPosition> Function(double y) _majorYFn;

  void _rebuildLines() {
    _xFn = _graticuleX(_y0, _y1, 90);
    _yFn = _graticuleY(_x0, _x1, _precision);
    _majorXFn = _graticuleX(_majorY0, _majorY1, 90);
    _majorYFn = _graticuleY(_majorX0, _majorX1, _precision);
  }

  List<List<GeoPosition>> _computeLines() => <List<GeoPosition>>[
    for (final x in range(
      (_majorX0 / _majorDx).ceil() * _majorDx,
      _majorX1,
      _majorDx,
    ))
      _majorXFn(x),
    for (final y in range(
      (_majorY0 / _majorDy).ceil() * _majorDy,
      _majorY1,
      _majorDy,
    ))
      _majorYFn(y),
    for (final x in range((_x0 / _dx).ceil() * _dx, _x1, _dx))
      if (x.remainder(_majorDx).abs() > geoEpsilon) _xFn(x),
    for (final y in range((_y0 / _dy).ceil() * _dy, _y1, _dy))
      if (y.remainder(_majorDy).abs() > geoEpsilon) _yFn(y),
  ];

  /// Returns a [GeoMultiLineString] representing all meridians and parallels.
  GeoMultiLineString call() => GeoMultiLineString(_computeLines());

  /// Returns a list of individual [GeoLineString] objects for each meridian
  /// and parallel.
  List<GeoLineString> lines() => <GeoLineString>[
    for (final coords in _computeLines()) GeoLineString(coords),
  ];

  /// Returns a [GeoPolygon] encompassing the major extent.
  GeoPolygon outline() {
    final ring = <GeoPosition>[
      ..._majorXFn(_majorX0),
      ..._majorYFn(_majorY1).skip(1),
      ..._majorXFn(_majorX1).reversed.skip(1),
      ..._majorYFn(_majorY0).reversed.skip(1),
    ];
    return GeoPolygon(<List<GeoPosition>>[ring]);
  }

  /// Current minor extent `((x0, y0), (x1, y1))`.
  GeoExtent get extent => extentMinor;

  /// Sets both [extentMajor] and [extentMinor].
  set extent(GeoExtent value) {
    extentMajor = value;
    extentMinor = value;
  }

  /// Major graticule extent `((X0, Y0), (X1, Y1))`.
  GeoExtent get extentMajor => ((_majorX0, _majorY0), (_majorX1, _majorY1));

  /// Sets the major graticule extent, normalizing `X0 <= X1` and `Y0 <= Y1`.
  set extentMajor(GeoExtent value) {
    var x0 = value.$1.$1;
    var y0 = value.$1.$2;
    var x1 = value.$2.$1;
    var y1 = value.$2.$2;
    if (x0 > x1) {
      final t = x0;
      x0 = x1;
      x1 = t;
    }
    if (y0 > y1) {
      final t = y0;
      y0 = y1;
      y1 = t;
    }
    _majorX0 = x0;
    _majorY0 = y0;
    _majorX1 = x1;
    _majorY1 = y1;
    _rebuildLines();
  }

  /// Minor graticule extent `((x0, y0), (x1, y1))`.
  GeoExtent get extentMinor => ((_x0, _y0), (_x1, _y1));

  /// Sets the minor graticule extent, normalizing `x0 <= x1` and `y0 <= y1`.
  set extentMinor(GeoExtent value) {
    var x0 = value.$1.$1;
    var y0 = value.$1.$2;
    var x1 = value.$2.$1;
    var y1 = value.$2.$2;
    if (x0 > x1) {
      final t = x0;
      x0 = x1;
      x1 = t;
    }
    if (y0 > y1) {
      final t = y0;
      y0 = y1;
      y1 = t;
    }
    _x0 = x0;
    _y0 = y0;
    _x1 = x1;
    _y1 = y1;
    _rebuildLines();
  }

  /// Current minor step `(dx, dy)`.
  GeoPosition get step => stepMinor;

  /// Sets both [stepMajor] and [stepMinor].
  set step(GeoPosition value) {
    stepMajor = value;
    stepMinor = value;
  }

  /// Major step `(DX, DY)` in degrees (defaults to `(90, 360)`).
  GeoPosition get stepMajor => (_majorDx, _majorDy);

  /// Sets the major step `(DX, DY)`.
  set stepMajor(GeoPosition value) {
    _majorDx = value.$1;
    _majorDy = value.$2;
  }

  /// Minor step `(dx, dy)` in degrees (defaults to `(10, 10)`).
  GeoPosition get stepMinor => (_dx, _dy);

  /// Sets the minor step `(dx, dy)`.
  set stepMinor(GeoPosition value) {
    _dx = value.$1;
    _dy = value.$2;
  }

  /// Angular precision in degrees (defaults to `2.5`).
  double get precision => _precision;

  /// Sets the angular [precision] in degrees.
  set precision(double value) {
    _precision = value;
    _rebuildLines();
  }
}

/// `graticule.js:14` `geoGraticule()`: creates a new [GeoGraticuleGenerator].
GeoGraticuleGenerator geoGraticule() => GeoGraticuleGenerator();

/// `graticule.js:103` `geoGraticule10()`: returns the default 10° graticule
/// [GeoMultiLineString].
GeoMultiLineString geoGraticule10() => geoGraticule()();
