// Ported from d3-geo v3.1.1 src/clip/antimeridian.js (ISC, Mike Bostock).

/// Port of `src/clip/antimeridian.js` of d3-geo 3.1.1: [geoClipAntimeridian].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/clip/index.dart';
import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/stream.dart';

bool _alwaysVisible(double lambda, double phi) => true;

final GeoStreamTransformer _clipAntimeridian = geoClip(
  _alwaysVisible,
  _ClipAntimeridianLine.new,
  _clipAntimeridianInterpolate,
  const (-geoPi, -geoHalfPi),
);

/// `clip/antimeridian.js:4` `geoClipAntimeridian`: a spherical clipping
/// [GeoStreamTransformer] that cuts lines and polygons crossing the
/// antimeridian (`±π`).
GeoStream geoClipAntimeridian(GeoStream sink) => _clipAntimeridian(sink);

final class _ClipAntimeridianLine(final GeoStream _stream)
    extends GeoClipLineStream {
  double _lambda0 = double.nan;
  double _phi0 = double.nan;
  double _sign0 = double.nan;
  int _clean = 1;

  @override
  void lineStart() {
    _stream.lineStart();
    _clean = 1;
  }

  @override
  void point(double x, double y, [double? z]) {
    var lambda1 = x;
    final phi1 = y;
    final sign1 = lambda1 > 0 ? geoPi : -geoPi;
    final delta = (lambda1 - _lambda0).abs();
    if ((delta - geoPi).abs() < geoEpsilon) {
      final polePhi = (_phi0 + phi1) / 2 > 0 ? geoHalfPi : -geoHalfPi;
      _phi0 = polePhi;
      _stream
        ..point(_lambda0, polePhi)
        ..point(_sign0, polePhi)
        ..lineEnd()
        ..lineStart()
        ..point(sign1, polePhi)
        ..point(lambda1, polePhi);
      _clean = 0;
    } else if (_sign0 != sign1 && delta >= geoPi) {
      if ((_lambda0 - _sign0).abs() < geoEpsilon) {
        _lambda0 -= _sign0 * geoEpsilon;
      }
      if ((lambda1 - sign1).abs() < geoEpsilon) {
        lambda1 -= sign1 * geoEpsilon;
      }
      _phi0 = _clipAntimeridianIntersect(_lambda0, _phi0, lambda1, phi1);
      _stream
        ..point(_sign0, _phi0)
        ..lineEnd()
        ..lineStart()
        ..point(sign1, _phi0);
      _clean = 0;
    }
    _lambda0 = lambda1;
    _phi0 = phi1;
    _stream.point(lambda1, phi1);
    _sign0 = sign1;
  }

  @override
  void lineEnd() {
    _stream.lineEnd();
    _lambda0 = double.nan;
    _phi0 = double.nan;
  }

  @override
  int clean() => 2 - _clean;
}

double _clipAntimeridianIntersect(
  double lambda0,
  double phi0,
  double lambda1,
  double phi1,
) {
  final sinLambda0Lambda1 = math.sin(lambda0 - lambda1);
  if (sinLambda0Lambda1.abs() > geoEpsilon) {
    final cosPhi0 = math.cos(phi0);
    final cosPhi1 = math.cos(phi1);
    return math.atan(
      (math.sin(phi0) * cosPhi1 * math.sin(lambda1) -
              math.sin(phi1) * cosPhi0 * math.sin(lambda0)) /
          (cosPhi0 * cosPhi1 * sinLambda0Lambda1),
    );
  }
  return (phi0 + phi1) / 2;
}

void _clipAntimeridianInterpolate(
  GeoPosition? from,
  GeoPosition? to,
  double direction,
  GeoStream stream,
) {
  if (from == null) {
    final phi = direction * geoHalfPi;
    stream
      ..point(-geoPi, phi)
      ..point(0, phi)
      ..point(geoPi, phi)
      ..point(geoPi, 0)
      ..point(geoPi, -phi)
      ..point(0, -phi)
      ..point(-geoPi, -phi)
      ..point(-geoPi, 0)
      ..point(-geoPi, phi);
  } else if ((from.$1 - to!.$1).abs() > geoEpsilon) {
    final lambda = from.$1 < to.$1 ? geoPi : -geoPi;
    final phi = direction * lambda / 2;
    stream
      ..point(-lambda, phi)
      ..point(0, phi)
      ..point(lambda, phi);
  } else {
    stream.point(to.$1, to.$2);
  }
}
