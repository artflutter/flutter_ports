// Ported from d3-geo v3.1.1 test/snapshots.js (ISC, Mike Bostock).

// DIVERGES(d3-geo): adapt-geo-snapshot-numerical, returns projection + land
// geometry pairs for web-safe numerical checks instead of Node canvas PNGs.

import 'package:flutter_d3_geo_port/d3_geo.dart';

import 'data/us_land_data.dart';
import 'data/world_land_data.dart';

const double snapshotWidth = 960;
const double snapshotHeight = 500;

Map<String, (GeoProjector Function(), GeoJsonObject Function())>
get geoSnapshots =>
    <String, (GeoProjector Function(), GeoJsonObject Function())>{
      'azimuthalEqualArea': (
        () => geoAzimuthalEqualArea()..precision = 0.1,
        () => worldLandFeature,
      ),
      'azimuthalEquidistant': (
        () => geoAzimuthalEquidistant()..precision = 0.1,
        () => worldLandFeature,
      ),
      'conicConformal': (
        () => geoConicConformal()..precision = 0.1,
        () => worldLandFeature,
      ),
      'conicEqualArea': (
        () => geoConicEqualArea()..precision = 0.1,
        () => worldLandFeature,
      ),
      'conicEquidistant': (
        () => geoConicEquidistant()..precision = 0.1,
        () => worldLandFeature,
      ),
      'equalEarth': (
        () => geoEqualEarth()..precision = 0.1,
        () => worldLandFeature,
      ),
      'equirectangular': (
        () => geoEquirectangular()..precision = 0.1,
        () => worldLandFeature,
      ),
      'gnomonic': (
        () => geoGnomonic()..precision = 0.1,
        () => worldLandFeature,
      ),
      'mercator': (
        () => geoMercator()..precision = 0.1,
        () => worldLandFeature,
      ),
      'naturalEarth1': (
        () => geoNaturalEarth1()..precision = 0.1,
        () => worldLandFeature,
      ),
      'angleorient30': (
        () => geoEquirectangular()
          ..clipAngle = 90
          ..angle = -30
          ..precision = 0.1
          ..fitExtent(const (
            (0, 0),
            (snapshotWidth, snapshotHeight),
          ), const GeoSphere()),
        () => worldLandFeature,
      ),
      'orthographic': (
        () => geoOrthographic()..precision = 0.1,
        () => worldLandFeature,
      ),
      'stereographic': (
        () => geoStereographic()..precision = 0.1,
        () => worldLandFeature,
      ),
      'transverseMercator': (
        () => geoTransverseMercator()..precision = 0.1,
        () => worldLandFeature,
      ),
      'albers': (() => geoAlbers()..precision = 0.1, () => usLandFeature),
      'albersUsa': (() => geoAlbersUsa()..precision = 0.1, () => usLandFeature),
    };
