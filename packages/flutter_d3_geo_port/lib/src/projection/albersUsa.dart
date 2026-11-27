// Ported from d3-geo v3.1.1 src/projection/albersUsa.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/projection/albersUsa.js` of d3-geo 3.1.1:
/// [GeoAlbersUsaProjection] and [geoAlbersUsa].
library;

import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/projection/albers.dart';
import 'package:flutter_d3_geo_port/src/projection/conic.dart';
import 'package:flutter_d3_geo_port/src/projection/conicEqualArea.dart';
import 'package:flutter_d3_geo_port/src/projection/fit.dart';
import 'package:flutter_d3_geo_port/src/stream.dart';

final class _MultiplexStream(final List<GeoStream> _streams) extends GeoStream {
  @override
  void point(double x, double y, [double? z]) {
    for (var i = 0, n = _streams.length; i < n; ++i) {
      _streams[i].point(x, y, z);
    }
  }

  @override
  void sphere() {
    for (var i = 0, n = _streams.length; i < n; ++i) {
      _streams[i].sphere();
    }
  }

  @override
  void lineStart() {
    for (var i = 0, n = _streams.length; i < n; ++i) {
      _streams[i].lineStart();
    }
  }

  @override
  void lineEnd() {
    for (var i = 0, n = _streams.length; i < n; ++i) {
      _streams[i].lineEnd();
    }
  }

  @override
  void polygonStart() {
    for (var i = 0, n = _streams.length; i < n; ++i) {
      _streams[i].polygonStart();
    }
  }

  @override
  void polygonEnd() {
    for (var i = 0, n = _streams.length; i < n; ++i) {
      _streams[i].polygonEnd();
    }
  }
}

/// `projection/albersUsa.js:25` `geoAlbersUsa`: composite United States Albers
/// projection (Lower 48, Alaska, Hawaii).
// DIVERGES(d3-geo): adapt-geo-fast-forms, direct clipped point projection in
// call() bypasses per-point stream dispatch across the three sub-projections.
final class GeoAlbersUsaProjection() implements GeoProjector {
  /// Creates a [GeoAlbersUsaProjection] configured for 960×500.
  this {
    scale = 1070;
  }

  final GeoConicProjection _lower48 = geoAlbers();
  final GeoConicProjection _alaska = geoConicEqualArea()
    ..rotate = const (154, 0, 0)
    ..center = const (-2, 58.5)
    ..parallels = const (55, 65);
  final GeoConicProjection _hawaii = geoConicEqualArea()
    ..rotate = const (157, 0, 0)
    ..center = const (-3, 19.9)
    ..parallels = const (8, 18);

  double _lX0 = 0;
  double _lY0 = 0;
  double _lX1 = 0;
  double _lY1 = 0;
  double _aX0 = 0;
  double _aY0 = 0;
  double _aX1 = 0;
  double _aY1 = 0;
  double _hX0 = 0;
  double _hY0 = 0;
  double _hX1 = 0;
  double _hY1 = 0;

  GeoStream? _cache;
  GeoStream? _cacheStream;

  void _reset() {
    _cache = null;
    _cacheStream = null;
  }

  @override
  GeoPosition? call(GeoPosition coordinates) {
    final x = coordinates.$1;
    final y = coordinates.$2;
    return _lower48.projectClipped(x, y, _lX0, _lY0, _lX1, _lY1) ??
        _alaska.projectClipped(x, y, _aX0, _aY0, _aX1, _aY1) ??
        _hawaii.projectClipped(x, y, _hX0, _hY0, _hX1, _hY1);
  }

  @override
  bool get canInvert => true;

  @override
  GeoPosition? invert(GeoPosition coordinates) {
    final k = _lower48.scale;
    final t = _lower48.translate;
    final x = (coordinates.$1 - t.$1) / k;
    final y = (coordinates.$2 - t.$2) / k;
    final region = y >= 0.120 && y < 0.234 && x >= -0.425 && x < -0.214
        ? _alaska
        : y >= 0.166 && y < 0.234 && x >= -0.214 && x < -0.115
        ? _hawaii
        : _lower48;
    return region.invert(coordinates);
  }

  @override
  GeoStream stream(GeoStream sink) {
    if (_cache != null && identical(_cacheStream, sink)) return _cache!;
    _cacheStream = sink;
    return _cache = _MultiplexStream(<GeoStream>[
      _lower48.stream(sink),
      _alaska.stream(sink),
      _hawaii.stream(sink),
    ]);
  }

  /// Adaptive resampling threshold in pixels.
  double get precision => _lower48.precision;

  /// Sets the adaptive resampling threshold on all three sub-projections.
  set precision(double value) {
    _lower48.precision = value;
    _alaska.precision = value;
    _hawaii.precision = value;
    _reset();
  }

  @override
  double get scale => _lower48.scale;

  @override
  set scale(double value) {
    _lower48.scale = value;
    _alaska.scale = value * 0.35;
    _hawaii.scale = value;
    translate = _lower48.translate;
  }

  @override
  GeoPosition get translate => _lower48.translate;

  @override
  set translate(GeoPosition value) {
    final k = _lower48.scale;
    final x = value.$1;
    final y = value.$2;

    _lX0 = x - 0.455 * k;
    _lY0 = y - 0.238 * k;
    _lX1 = x + 0.455 * k;
    _lY1 = y + 0.238 * k;
    _lower48
      ..translate = value
      ..clipExtent = ((_lX0, _lY0), (_lX1, _lY1));

    _aX0 = x - 0.425 * k + geoEpsilon;
    _aY0 = y + 0.120 * k + geoEpsilon;
    _aX1 = x - 0.214 * k - geoEpsilon;
    _aY1 = y + 0.234 * k - geoEpsilon;
    _alaska
      ..translate = (x - 0.307 * k, y + 0.201 * k)
      ..clipExtent = ((_aX0, _aY0), (_aX1, _aY1));

    _hX0 = x - 0.214 * k + geoEpsilon;
    _hY0 = y + 0.166 * k + geoEpsilon;
    _hX1 = x - 0.115 * k - geoEpsilon;
    _hY1 = y + 0.234 * k - geoEpsilon;
    _hawaii
      ..translate = (x - 0.205 * k, y + 0.212 * k)
      ..clipExtent = ((_hX0, _hY0), (_hX1, _hY1));

    _reset();
  }

  @override
  bool get hasClipExtent => false;

  @override
  GeoExtent? get clipExtent => null;

  @override
  set clipExtent(GeoExtent? value) {}

  @override
  void fitExtent(GeoExtent extent, GeoJsonObject object) =>
      geoFitExtent(this, extent, object);

  @override
  void fitSize(GeoPosition size, GeoJsonObject object) =>
      geoFitSize(this, size, object);

  @override
  void fitWidth(double width, GeoJsonObject object) =>
      geoFitWidth(this, width, object);

  @override
  void fitHeight(double height, GeoJsonObject object) =>
      geoFitHeight(this, height, object);
}

/// `projection/albersUsa.js:25` `geoAlbersUsa()`: creates a new
/// [GeoAlbersUsaProjection].
GeoAlbersUsaProjection geoAlbersUsa() => GeoAlbersUsaProjection();
