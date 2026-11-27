// Ported from d3-geo v3.1.1 src/projection/index.js (ISC, Mike Bostock).

/// Port of `src/projection/index.js` of d3-geo 3.1.1: [GeoProjection],
/// [geoProjection], and [geoProjectionMutator].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/clip/antimeridian.dart';
import 'package:flutter_d3_geo_port/src/clip/circle.dart';
import 'package:flutter_d3_geo_port/src/clip/rectangle.dart';
import 'package:flutter_d3_geo_port/src/compose.dart';
import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/projection/conicEqualArea.dart';
import 'package:flutter_d3_geo_port/src/projection/equalEarth.dart';
import 'package:flutter_d3_geo_port/src/projection/fit.dart';
import 'package:flutter_d3_geo_port/src/projection/mercator.dart';
import 'package:flutter_d3_geo_port/src/projection/naturalEarth1.dart';
import 'package:flutter_d3_geo_port/src/projection/orthographic.dart';
import 'package:flutter_d3_geo_port/src/projection/resample.dart';
import 'package:flutter_d3_geo_port/src/rotation.dart';
import 'package:flutter_d3_geo_port/src/stream.dart';
import 'package:flutter_d3_geo_port/src/transform.dart';

// Equal Earth polynomial constants (matching equalEarth.dart).
const double _eeA1 = 1.340264;
const double _eeA2 = -0.081106;
const double _eeA3 = 0.000893;
const double _eeA4 = 0.003796;
final double _eeM = math.sqrt(3) / 2;

const int _rawGeneric = 0;
const int _rawOrthographic = 1;
const int _rawMercator = 2;
const int _rawEqualEarth = 3;
const int _rawNaturalEarth1 = 4;
const int _rawConicEqualArea = 5;

// DIVERGES(d3-geo): adapt-geo-fast-forms, fuses degree-to-radian conversion and
// spherical rotation into a single unboxed stream transform (zero per-point
// record allocations).
final class _TransformRadiansRotateStream(
  super.stream,
  final int _rotMode,
  final double _rotDl,
  final double _cosPhi,
  final double _sinPhi,
  final double _cosGamma,
  final double _sinGamma,
) extends GeoTransformStream {
  @override
  void point(double x, double y, [double? z]) {
    var l = x * geoRadians;
    final p = y * geoRadians;
    if (_rotMode == 0) {
      if (l.abs() > geoPi) l -= geoJsRound(l / geoTau) * geoTau;
      stream.point(l, p);
    } else if (_rotMode == 1) {
      l += _rotDl;
      if (l.abs() > geoPi) l -= geoJsRound(l / geoTau) * geoTau;
      stream.point(l, p);
    } else {
      if (_rotMode == 3) {
        l += _rotDl;
        if (l.abs() > geoPi) l -= geoJsRound(l / geoTau) * geoTau;
      }
      final cosPhi = math.cos(p);
      final cx = math.cos(l) * cosPhi;
      final cy = math.sin(l) * cosPhi;
      final cz = math.sin(p);
      final k = cz * _cosPhi + cx * _sinPhi;
      stream.point(
        math.atan2(cy * _cosGamma - k * _sinGamma, cx * _cosPhi - cz * _sinPhi),
        geoAsin(k * _cosGamma + cy * _sinGamma),
      );
    }
  }
}

final class _ScaleTranslate(
  final double _k,
  final double _dx,
  final double _dy,
  final double _sx,
  final double _sy,
) implements GeoRawProjection {
  @override
  @pragma('vm:prefer-inline')
  GeoPosition call(double x, double y) =>
      (_dx + _k * x * _sx, _dy - _k * y * _sy);

  @override
  bool get canInvert => true;

  @override
  @pragma('vm:prefer-inline')
  GeoPosition invert(double x, double y) =>
      ((x - _dx) / _k * _sx, (_dy - y) / _k * _sy);
}

final class _ScaleTranslateRotate(
  double k,
  final double _dx,
  final double _dy,
  final double _sx,
  final double _sy,
  double alpha,
) implements GeoRawProjection {
  this {
    final cosAlpha = math.cos(alpha);
    final sinAlpha = math.sin(alpha);
    _a = cosAlpha * k;
    _b = sinAlpha * k;
    _ai = cosAlpha / k;
    _bi = sinAlpha / k;
    _ci = (sinAlpha * _dy - cosAlpha * _dx) / k;
    _fi = (sinAlpha * _dx + cosAlpha * _dy) / k;
  }

  late final double _a;
  late final double _b;
  late final double _ai;
  late final double _bi;
  late final double _ci;
  late final double _fi;

  @override
  @pragma('vm:prefer-inline')
  GeoPosition call(double x, double y) {
    final xs = x * _sx;
    final ys = y * _sy;
    return (_a * xs - _b * ys + _dx, _dy - _b * xs - _a * ys);
  }

  @override
  bool get canInvert => true;

  @override
  @pragma('vm:prefer-inline')
  GeoPosition invert(double x, double y) =>
      (_sx * (_ai * x - _bi * y + _ci), _sy * (_fi - _bi * x - _ai * y));
}

GeoRawProjection _scaleTranslateRotate(
  double k,
  double dx,
  double dy,
  double sx,
  double sy,
  double alpha,
) => alpha == 0
    ? _ScaleTranslate(k, dx, dy, sx, sy)
    : _ScaleTranslateRotate(k, dx, dy, sx, sy, alpha);

/// A configurable geographic projection wrapping a [GeoRawProjection]
/// (`projection/index.js:62`, D3 ADR 0024).
// DIVERGES(d3-geo): adapt-geo-typed-api, typed GeoProjection class with
// property getters/setters replaces JS dual-purpose closure functions.
// DIVERGES(d3-geo): adapt-geo-fast-forms, stores unboxed rotation, affine, and
// raw-projection fast-path fields to avoid intermediate record allocations.
class GeoProjection(GeoRawProjection project) implements GeoProjector {
  /// Creates a [GeoProjection] wrapping [project].
  this {
    recenter();
  }

  GeoRawProjection _project = project;
  int _rawKind = _rawGeneric;
  double _cn = 0;
  double _cc = 0;
  double _cr0 = 0;

  double _k = 150;
  double _x = 480;
  double _y = 250;
  double _lambda = 0;
  double _phi = 0;
  double _deltaLambda = 0;
  double _deltaPhi = 0;
  double _deltaGamma = 0;

  // Unboxed spherical rotation fields (0=id, 1=dl, 2=pg, 3=dl+pg).
  int _rotMode = 0;
  double _rotDl = 0;
  double _rotCosPhi = 1;
  double _rotSinPhi = 0;
  double _rotCosGamma = 1;
  double _rotSinGamma = 0;

  // Unboxed affine transform fields.
  double _tDx = 480;
  double _tDy = 250;
  double _tA = 150;
  double _tB = 150;
  bool _hasAlpha = false;

  late GeoRawProjection _rotate;
  double _alpha = 0;
  double _sx = 1;
  double _sy = 1;
  double? _theta;
  GeoStreamTransformer _preclip = geoClipAntimeridian;
  double? _x0;
  double _y0 = 0;
  double _x1 = 0;
  double _y1 = 0;
  GeoStreamTransformer _postclip = geoStreamIdentity;
  double _delta2 = 0.5;
  late GeoStreamTransformer _projectResample;
  late GeoRawProjection _projectTransform;
  late GeoRawProjection _projectRotateTransform;
  GeoStream? _cache;
  GeoStream? _cacheStream;

  /// Replaces the underlying raw projection (used by mutators such as conic
  /// parallels).
  void setRawProjection(GeoRawProjection project) {
    _project = project;
    recenter();
  }

  /// Recomputes affine scale/translate/rotate composition and clears the
  /// stream cache.
  void recenter() {
    if (identical(_project, geoOrthographicRaw)) {
      _rawKind = _rawOrthographic;
    } else if (identical(_project, geoMercatorRaw)) {
      _rawKind = _rawMercator;
    } else if (identical(_project, geoEqualEarthRaw)) {
      _rawKind = _rawEqualEarth;
    } else if (identical(_project, geoNaturalEarth1Raw)) {
      _rawKind = _rawNaturalEarth1;
    } else if (_project is GeoConicEqualAreaRaw) {
      final c = _project as GeoConicEqualAreaRaw;
      _rawKind = _rawConicEqualArea;
      _cn = c.n;
      _cc = c.c;
      _cr0 = c.r0;
    } else {
      _rawKind = _rawGeneric;
    }

    final rawCenter = _project(_lambda, _phi);
    final center = _scaleTranslateRotate(_k, 0, 0, _sx, _sy, _alpha)(
      rawCenter.$1,
      rawCenter.$2,
    );
    _tDx = _x - center.$1;
    _tDy = _y - center.$2;
    _hasAlpha = _alpha != 0;
    if (_hasAlpha) {
      _tA = math.cos(_alpha) * _k;
      _tB = math.sin(_alpha) * _k;
    } else {
      _tA = _k * _sx;
      _tB = _k * _sy;
    }

    final transform = _scaleTranslateRotate(_k, _tDx, _tDy, _sx, _sy, _alpha);

    final dl = _deltaLambda.remainder(geoTau);
    _rotDl = dl;
    final hasPg = _deltaPhi != 0 || _deltaGamma != 0;
    if (hasPg) {
      _rotCosPhi = math.cos(_deltaPhi);
      _rotSinPhi = math.sin(_deltaPhi);
      _rotCosGamma = math.cos(_deltaGamma);
      _rotSinGamma = math.sin(_deltaGamma);
      _rotMode = dl != 0 ? 3 : 2;
    } else {
      _rotMode = dl != 0 ? 1 : 0;
    }

    _rotate = geoRotateRadians(_deltaLambda, _deltaPhi, _deltaGamma);
    _projectTransform = geoCompose(_project, transform);
    _projectRotateTransform = geoCompose(_rotate, _projectTransform);
    _projectResample = geoResampleAffine(
      _project,
      _k,
      _tDx,
      _tDy,
      _sx,
      _sy,
      _alpha,
      _delta2,
    );
    reset();
  }

  /// Clears the cached projection stream.
  void reset() {
    _cache = null;
    _cacheStream = null;
  }

  /// Projects `(lon, lat)` in degrees and returns the screen position only if
  /// it falls inside `[x0, x1] × [y0, y1]`, otherwise returns `null` without
  /// allocating a record on a miss.
  // DIVERGES(d3-geo): adapt-geo-fast-forms, unboxed point-in-clip-box fast path
  // for composite projections such as geoAlbersUsa.
  @pragma('vm:prefer-inline')
  GeoPosition? projectClipped(
    double lon,
    double lat,
    double x0,
    double y0,
    double x1,
    double y1,
  ) {
    var l = lon * geoRadians;
    var p = lat * geoRadians;
    if (_rotMode == 0) {
      if (l.abs() > geoPi) l -= geoJsRound(l / geoTau) * geoTau;
    } else if (_rotMode == 1) {
      l += _rotDl;
      if (l.abs() > geoPi) l -= geoJsRound(l / geoTau) * geoTau;
    } else {
      if (_rotMode == 3) {
        l += _rotDl;
        if (l.abs() > geoPi) l -= geoJsRound(l / geoTau) * geoTau;
      }
      final cosPhi = math.cos(p);
      final cx = math.cos(l) * cosPhi;
      final cy = math.sin(l) * cosPhi;
      final cz = math.sin(p);
      final k = cz * _rotCosPhi + cx * _rotSinPhi;
      l = math.atan2(
        cy * _rotCosGamma - k * _rotSinGamma,
        cx * _rotCosPhi - cz * _rotSinPhi,
      );
      p = geoAsin(k * _rotCosGamma + cy * _rotSinGamma);
    }

    final double rx;
    final double ry;
    switch (_rawKind) {
      case _rawOrthographic:
        rx = math.cos(p) * math.sin(l);
        ry = math.sin(p);
      case _rawMercator:
        rx = l;
        ry = math.log(math.tan((geoHalfPi + p) / 2));
      case _rawEqualEarth:
        final el = geoAsin(_eeM * math.sin(p));
        final l2 = el * el;
        final l6 = l2 * l2 * l2;
        rx =
            l *
            math.cos(el) /
            (_eeM *
                (_eeA1 + 3 * _eeA2 * l2 + l6 * (7 * _eeA3 + 9 * _eeA4 * l2)));
        ry = el * (_eeA1 + _eeA2 * l2 + l6 * (_eeA3 + _eeA4 * l2));
      case _rawNaturalEarth1:
        final phi2 = p * p;
        final phi4 = phi2 * phi2;
        rx =
            l *
            (0.8707 -
                0.131979 * phi2 +
                phi4 *
                    (-0.013791 + phi4 * (0.003971 * phi2 - 0.001529 * phi4)));
        ry =
            p *
            (1.007226 +
                phi2 *
                    (0.015085 +
                        phi4 *
                            (-0.044475 + 0.028874 * phi2 - 0.005916 * phi4)));
      case _rawConicEqualArea:
        final r = math.sqrt(_cc - 2 * _cn * math.sin(p)) / _cn;
        final nx = l * _cn;
        rx = r * math.sin(nx);
        ry = _cr0 - r * math.cos(nx);
      default:
        final q = _project(l, p);
        rx = q.$1;
        ry = q.$2;
    }

    final double sx;
    final double sy;
    if (_hasAlpha) {
      final xs = rx * _sx;
      final ys = ry * _sy;
      sx = _tA * xs - _tB * ys + _tDx;
      sy = _tDy - _tB * xs - _tA * ys;
    } else {
      sx = _tDx + _tA * rx;
      sy = _tDy - _tB * ry;
    }
    if (x0 <= sx && sx <= x1 && y0 <= sy && sy <= y1) {
      return (sx, sy);
    }
    return null;
  }

  @override
  GeoPosition? call(GeoPosition coordinates) {
    var l = coordinates.$1 * geoRadians;
    var p = coordinates.$2 * geoRadians;
    if (_rotMode == 0) {
      if (l.abs() > geoPi) l -= geoJsRound(l / geoTau) * geoTau;
    } else if (_rotMode == 1) {
      l += _rotDl;
      if (l.abs() > geoPi) l -= geoJsRound(l / geoTau) * geoTau;
    } else {
      if (_rotMode == 3) {
        l += _rotDl;
        if (l.abs() > geoPi) l -= geoJsRound(l / geoTau) * geoTau;
      }
      final cosPhi = math.cos(p);
      final cx = math.cos(l) * cosPhi;
      final cy = math.sin(l) * cosPhi;
      final cz = math.sin(p);
      final k = cz * _rotCosPhi + cx * _rotSinPhi;
      l = math.atan2(
        cy * _rotCosGamma - k * _rotSinGamma,
        cx * _rotCosPhi - cz * _rotSinPhi,
      );
      p = geoAsin(k * _rotCosGamma + cy * _rotSinGamma);
    }

    final double rx;
    final double ry;
    switch (_rawKind) {
      case _rawOrthographic:
        rx = math.cos(p) * math.sin(l);
        ry = math.sin(p);
      case _rawMercator:
        rx = l;
        ry = math.log(math.tan((geoHalfPi + p) / 2));
      case _rawEqualEarth:
        final el = geoAsin(_eeM * math.sin(p));
        final l2 = el * el;
        final l6 = l2 * l2 * l2;
        rx =
            l *
            math.cos(el) /
            (_eeM *
                (_eeA1 + 3 * _eeA2 * l2 + l6 * (7 * _eeA3 + 9 * _eeA4 * l2)));
        ry = el * (_eeA1 + _eeA2 * l2 + l6 * (_eeA3 + _eeA4 * l2));
      case _rawNaturalEarth1:
        final phi2 = p * p;
        final phi4 = phi2 * phi2;
        rx =
            l *
            (0.8707 -
                0.131979 * phi2 +
                phi4 *
                    (-0.013791 + phi4 * (0.003971 * phi2 - 0.001529 * phi4)));
        ry =
            p *
            (1.007226 +
                phi2 *
                    (0.015085 +
                        phi4 *
                            (-0.044475 + 0.028874 * phi2 - 0.005916 * phi4)));
      case _rawConicEqualArea:
        final r = math.sqrt(_cc - 2 * _cn * math.sin(p)) / _cn;
        final nx = l * _cn;
        rx = r * math.sin(nx);
        ry = _cr0 - r * math.cos(nx);
      default:
        final q = _project(l, p);
        rx = q.$1;
        ry = q.$2;
    }

    if (_hasAlpha) {
      final xs = rx * _sx;
      final ys = ry * _sy;
      return (_tA * xs - _tB * ys + _tDx, _tDy - _tB * xs - _tA * ys);
    }
    return (_tDx + _tA * rx, _tDy - _tB * ry);
  }

  @override
  bool get canInvert => _project.canInvert;

  @override
  GeoPosition? invert(GeoPosition point) {
    if (!_project.canInvert) return null;
    final p = _projectRotateTransform.invert(point.$1, point.$2);
    if (p == null) return null;
    return (p.$1 * geoDegrees, p.$2 * geoDegrees);
  }

  @override
  GeoStream stream(GeoStream sink) {
    if (_cache != null && identical(_cacheStream, sink)) return _cache!;
    _cacheStream = sink;
    return _cache = _TransformRadiansRotateStream(
      _preclip(_projectResample(_postclip(sink))),
      _rotMode,
      _rotDl,
      _rotCosPhi,
      _rotSinPhi,
      _rotCosGamma,
      _rotSinGamma,
    );
  }

  /// Current spherical pre-clipping [GeoStreamTransformer].
  GeoStreamTransformer get preclip => _preclip;

  /// Sets a custom spherical pre-clipping transformer (clears [clipAngle]).
  set preclip(GeoStreamTransformer value) {
    _preclip = value;
    _theta = null;
    reset();
  }

  /// Current planar post-clipping [GeoStreamTransformer].
  GeoStreamTransformer get postclip => _postclip;

  /// Sets a custom planar post-clipping transformer (clears [clipExtent]).
  set postclip(GeoStreamTransformer value) {
    _postclip = value;
    _x0 = null;
    reset();
  }

  /// Small-circle clip angle in degrees, or `null` when antimeridian / custom
  /// pre-clipping is active.
  double? get clipAngle => _theta == null ? null : _theta! * geoDegrees;

  /// Sets the small-circle clip angle in degrees (`null` or `0` switches back
  /// to [geoClipAntimeridian]).
  set clipAngle(double? degrees) {
    if (degrees != null && degrees != 0 && !degrees.isNaN) {
      final rad = degrees * geoRadians;
      _theta = rad;
      _preclip = geoClipCircle(rad);
    } else {
      _theta = null;
      _preclip = geoClipAntimeridian;
    }
    reset();
  }

  @override
  bool get hasClipExtent => true;

  @override
  GeoExtent? get clipExtent => _x0 == null ? null : ((_x0!, _y0), (_x1, _y1));

  @override
  set clipExtent(GeoExtent? value) {
    if (value == null) {
      _x0 = null;
      _postclip = geoStreamIdentity;
    } else {
      _x0 = value.$1.$1;
      _y0 = value.$1.$2;
      _x1 = value.$2.$1;
      _y1 = value.$2.$2;
      _postclip = geoClipRectangle(_x0!, _y0, _x1, _y1);
    }
    reset();
  }

  @override
  double get scale => _k;

  @override
  set scale(double value) {
    _k = value;
    recenter();
  }

  @override
  GeoPosition get translate => (_x, _y);

  @override
  set translate(GeoPosition value) {
    _x = value.$1;
    _y = value.$2;
    recenter();
  }

  /// Projection center `(lon, lat)` in degrees (defaults to `(0, 0)`).
  GeoPosition get center => (_lambda * geoDegrees, _phi * geoDegrees);

  /// Sets the projection center `(lon, lat)` in degrees.
  set center(GeoPosition value) {
    _lambda = value.$1.remainder(360) * geoRadians;
    _phi = value.$2.remainder(360) * geoRadians;
    recenter();
  }

  /// Three-axis spherical rotation `(lambda, phi, gamma)` in degrees.
  GeoRotationAngles get rotate => (
    _deltaLambda * geoDegrees,
    _deltaPhi * geoDegrees,
    _deltaGamma * geoDegrees,
  );

  /// Sets the three-axis spherical rotation `(lambda, phi, gamma)` in degrees.
  set rotate(GeoRotationAngles value) {
    _deltaLambda = value.$1.remainder(360) * geoRadians;
    _deltaPhi = value.$2.remainder(360) * geoRadians;
    _deltaGamma = value.$3.remainder(360) * geoRadians;
    recenter();
  }

  /// Convenience method setting two- or three-axis rotation `(lambda, phi,
  /// [gamma])` in degrees.
  void rotateTo(double lambda, double phi, [double gamma = 0]) {
    rotate = (lambda, phi, gamma);
  }

  /// Post-projection planar rotation angle in degrees (defaults to `0`).
  double get angle => _alpha * geoDegrees;

  /// Sets the post-projection planar rotation angle in degrees.
  set angle(double degrees) {
    _alpha = degrees.remainder(360) * geoRadians;
    recenter();
  }

  /// Whether the projected x-axis is reflected.
  bool get reflectX => _sx < 0;

  /// Sets whether the projected x-axis is reflected.
  set reflectX(bool value) {
    _sx = value ? -1 : 1;
    recenter();
  }

  /// Whether the projected y-axis is reflected.
  bool get reflectY => _sy < 0;

  /// Sets whether the projected y-axis is reflected.
  set reflectY(bool value) {
    _sy = value ? -1 : 1;
    recenter();
  }

  /// Adaptive resampling threshold in pixels (defaults to `sqrt(0.5)`).
  double get precision => math.sqrt(_delta2);

  /// Sets the adaptive resampling threshold in pixels (`0` disables
  /// resampling).
  set precision(double value) {
    _delta2 = value * value;
    _projectResample = geoResampleAffine(
      _project,
      _k,
      _tDx,
      _tDy,
      _sx,
      _sy,
      _alpha,
      _delta2,
    );
    reset();
  }

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

/// `projection/index.js:58` `geoProjection(project)`: constructs a new
/// [GeoProjection] from the raw projection [project].
GeoProjection geoProjection(GeoRawProjection project) => GeoProjection(project);

/// `projection/index.js:62` `geoProjectionMutator(projectAt)`: returns a
/// strongly typed mutator function updating a shared [GeoProjection] when
/// invoked with parameter record [A].
GeoProjection Function(A args) geoProjectionMutator<A>(
  GeoRawProjection Function(A args) projectAt,
) {
  GeoProjection? proj;
  return (A args) {
    final raw = projectAt(args);
    if (proj == null) {
      return proj = GeoProjection(raw);
    }
    proj!.setRawProjection(raw);
    return proj!;
  };
}
