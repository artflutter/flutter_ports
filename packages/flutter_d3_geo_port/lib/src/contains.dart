// Ported from d3-geo v3.1.1 src/contains.js (ISC, Mike Bostock).

/// Port of `src/contains.js` of d3-geo 3.1.1: [geoContains].
library;

import 'package:flutter_d3_geo_port/src/distance.dart';
import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/polygonContains.dart';

bool _containsPoint(GeoPosition coordinates, GeoPosition point) =>
    geoDistance(coordinates, point) == 0;

bool _containsLine(List<GeoPosition> coordinates, GeoPosition point) {
  var ao = 0.0;
  for (var i = 0, n = coordinates.length; i < n; ++i) {
    final bo = geoDistance(coordinates[i], point);
    if (bo == 0) return true;
    if (i > 0) {
      final ab = geoDistance(coordinates[i], coordinates[i - 1]);
      if (ab > 0 && ao <= ab && bo <= ab) {
        final r = (ao - bo) / ab;
        if ((ao + bo - ab) * (1 - r * r) < geoEpsilon2 * ab) {
          return true;
        }
      }
    }
    ao = bo;
  }
  return false;
}

// DIVERGES(d3-geo): adapt-geo-fast-forms, delegates directly to
// geoPolygonContainsDegrees without allocating radian ring copies.
bool _containsPolygon(List<List<GeoPosition>> coordinates, GeoPosition point) =>
    geoPolygonContainsDegrees(coordinates, point.$1, point.$2);

bool _containsGeometry(GeoGeometry? geometry, GeoPosition point) {
  if (geometry == null) return false;
  switch (geometry) {
    case GeoSphere():
      return true;
    case GeoPoint(:final coordinates):
      return _containsPoint(coordinates, point);
    case GeoMultiPoint(:final coordinates):
      for (var i = 0, n = coordinates.length; i < n; ++i) {
        if (_containsPoint(coordinates[i], point)) return true;
      }
      return false;
    case GeoLineString(:final coordinates):
      return _containsLine(coordinates, point);
    case GeoMultiLineString(:final coordinates):
      for (var i = 0, n = coordinates.length; i < n; ++i) {
        if (_containsLine(coordinates[i], point)) return true;
      }
      return false;
    case GeoPolygon(:final coordinates):
      return _containsPolygon(coordinates, point);
    case GeoMultiPolygon(:final coordinates):
      for (var i = 0, n = coordinates.length; i < n; ++i) {
        if (_containsPolygon(coordinates[i], point)) return true;
      }
      return false;
    case GeoGeometryCollection(:final geometries):
      for (var i = 0, n = geometries.length; i < n; ++i) {
        if (_containsGeometry(geometries[i], point)) return true;
      }
      return false;
  }
}

/// `contains.js:93` `geoContains(object, point)`: returns `true` if and only if
/// the specified GeoJSON [object] contains [point] `(lon, lat)` in degrees.
// DIVERGES(d3-geo): adapt-geo-typed-api, typed GeoJsonObject and GeoPosition.
bool geoContains(GeoJsonObject? object, GeoPosition point) {
  if (object == null) return false;
  switch (object) {
    case GeoFeature<Object?>(:final geometry):
      return _containsGeometry(geometry, point);
    case GeoFeatureCollection<Object?>(:final features):
      for (var i = 0, n = features.length; i < n; ++i) {
        if (_containsGeometry(features[i].geometry, point)) return true;
      }
      return false;
    case final GeoGeometry geometry:
      return _containsGeometry(geometry, point);
  }
}
