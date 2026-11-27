// Ported from d3-contour v4.0.2 src/density.js (ISC, Mike Bostock).

/// Port of `src/density.js` of d3-contour 4.0.2: [contourDensity],
/// [contourDensityPoints], [ContourDensity], and [DensityContours].
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_array_port/d3_array.dart'
    show Blur2Data, blur2, max, ticks;
import 'package:flutter_d3_contour_port/src/array.dart';
import 'package:flutter_d3_contour_port/src/ascending.dart';
import 'package:flutter_d3_contour_port/src/contours.dart';

/// A 1-argument numeric accessor for [ContourDensity].
typedef DensityAccessor<T> = double Function(T d);

/// A 3-argument indexed numeric accessor for [ContourDensity].
typedef DensityIndexedAccessor<T> = double Function(
  T d,
  int index,
  Iterable<T> data,
);

/// A reusable density contour evaluator returned by [ContourDensity.contours].
///
/// Precomputes the blurred 2D density grid once so arbitrary contour levels can
/// be queried via [call] and the peak density can be inspected via [max].
// DIVERGES(d3-contour): adapt-contour-typed-api, typed callable DensityContours
// class with a `max` getter instead of JS function with
// `Object.defineProperty`.
final class DensityContours._({
  required Float64List values,
  required int width,
  required int height,
  required double pow4k,
  required double scale,
  required double offset,
}) {
  final Float64List _values = values;
  final int _width = width;
  final int _height = height;
  final double _pow4k = pow4k;
  final double _scale = scale;
  final double _offset = offset;

  /// The maximum estimated density in the underlying grid
  /// (`max(values) / 4^k`).
  double get max => (maxValue(_values) ?? 0.0) / _pow4k;

  /// Computes a single density contour at exact threshold [value].
  ContourMultiPolygon call(double value) => buildDensityContourSingle(
    _values,
    _width,
    _height,
    value * _pow4k,
    value,
    _scale,
    _offset,
  );
}

/// Calls `d3-array`'s `max` without shadowing [DensityContours.max].
double? maxValue(List<double> values) => max<double>(values);

/// A configurable 2D kernel density contour estimator for data of type [T].
// DIVERGES(d3-contour): adapt-contour-typed-api, typed generic
// ContourDensity<T> class with explicit `x`, `y`, `weight`, `size`, `cellSize`,
// `bandwidth`, and typed threshold properties instead of untyped JS methods.
// DIVERGES(d3-contour): adapt-contour-fast-forms, Float64List splatting with
// hoisted accessor fast paths feeding blur2's specialized Float64List kernel
// and fused affine coordinate transform during ring materialization.
final class ContourDensity<T>({
  required DensityAccessor<T> x,
  required DensityAccessor<T> y,
  DensityAccessor<T>? weight,
  (num, num) size = (960, 500),
  num cellSize = 4,
  num? bandwidth,
  int? thresholdsCount,
  List<double>? thresholdsValues,
  ContourThresholdsValues? thresholdsGenerator,
  ContourThresholdsCount? thresholdsCountGenerator,
}) {
  /// Creates a [ContourDensity] estimator with typed [x] and [y] accessors.
  this {
    this.size = size;
    this.cellSize = cellSize;
    if (bandwidth != null) {
      this.bandwidth = bandwidth;
    } else {
      _resize();
    }
    if (thresholdsValues != null) {
      this.thresholdsValues = thresholdsValues;
    } else if (thresholdsGenerator != null) {
      this.thresholdsGenerator = thresholdsGenerator;
    } else if (thresholdsCountGenerator != null) {
      this.thresholdsCountGenerator = thresholdsCountGenerator;
    } else if (thresholdsCount != null) {
      this.thresholdsCount = thresholdsCount;
    }
  }

  DensityAccessor<T> _x = x;
  DensityIndexedAccessor<T>? _xIndexed;
  double? _xConst;

  DensityAccessor<T> _y = y;
  DensityIndexedAccessor<T>? _yIndexed;
  double? _yConst;

  DensityAccessor<T>? _weight = weight;
  DensityIndexedAccessor<T>? _weightIndexed;
  double? _weightConst;
  bool _isDefaultWeight = weight == null;

  double _dx = 960;
  double _dy = 500;
  double _r = 20; // blur radius
  int _k = 2; // log2(grid cell size)
  double _o = 60; // grid offset = r * 3
  int _n = 270; // grid width = (dx + o * 2) >> k
  int _m = 155; // grid height = (dy + o * 2) >> k

  int? _thresholdsCount = 20;
  List<double>? _thresholdsValues;
  ContourThresholdsValues? _thresholdsGenerator;
  ContourThresholdsCount? _thresholdsCountGenerator;

  void _resize() {
    _o = _r * 3.0;
    _n = (_dx + _o * 2.0).truncate() >> _k;
    _m = (_dy + _o * 2.0).truncate() >> _k;
  }

  /// The current 1-argument x-coordinate accessor.
  DensityAccessor<T> get x => _x;

  /// Sets a 1-argument x-coordinate accessor.
  set x(DensityAccessor<T> fn) {
    _x = fn;
    _xIndexed = null;
    _xConst = null;
  }

  /// Sets a 3-argument indexed x-coordinate accessor.
  void xIndexed(DensityIndexedAccessor<T> fn) {
    _xIndexed = fn;
    _xConst = null;
  }

  /// Sets a constant x-coordinate for all points.
  void xConst(num value) {
    final v = value.toDouble();
    _xConst = v;
    _xIndexed = null;
    _x = (_) => v;
  }

  /// The current 1-argument y-coordinate accessor.
  DensityAccessor<T> get y => _y;

  /// Sets a 1-argument y-coordinate accessor.
  set y(DensityAccessor<T> fn) {
    _y = fn;
    _yIndexed = null;
    _yConst = null;
  }

  /// Sets a 3-argument indexed y-coordinate accessor.
  void yIndexed(DensityIndexedAccessor<T> fn) {
    _yIndexed = fn;
    _yConst = null;
  }

  /// Sets a constant y-coordinate for all points.
  void yConst(num value) {
    final v = value.toDouble();
    _yConst = v;
    _yIndexed = null;
    _y = (_) => v;
  }

  /// The current 1-argument point weight accessor (defaults to returning `1`).
  DensityAccessor<T> get weight => _weight ?? _defaultWeight;

  double _defaultWeight(T _) => 1;

  /// Sets a 1-argument point weight accessor.
  set weight(DensityAccessor<T> fn) {
    _weight = fn;
    _weightIndexed = null;
    _weightConst = null;
    _isDefaultWeight = false;
  }

  /// Sets a 3-argument indexed point weight accessor.
  void weightIndexed(DensityIndexedAccessor<T> fn) {
    _weightIndexed = fn;
    _weightConst = null;
    _isDefaultWeight = false;
  }

  /// Sets a constant point weight for all points.
  void weightConst(num value) {
    final v = value.toDouble();
    _weightConst = v;
    _weightIndexed = null;
    _weight = (_) => v;
    _isDefaultWeight = v == 1.0;
  }

  /// The estimator bounds `(width, height)`.
  (double, double) get size => (_dx, _dy);

  /// Sets the estimator bounds `(width, height)`.
  ///
  /// Throws a [RangeError] if either dimension is negative or non-finite.
  set size((num, num) value) {
    final w = value.$1.toDouble();
    final h = value.$2.toDouble();
    if (!(w >= 0 && h >= 0) || !w.isFinite || !h.isFinite) {
      throw RangeError('invalid size');
    }
    _dx = w;
    _dy = h;
    _resize();
  }

  /// The grid cell size (a power of two, defaulting to `4`).
  int get cellSize => 1 << _k;

  /// Sets the grid cell size, rounded down to the nearest power of two.
  ///
  /// Throws a [RangeError] if [value] is less than `1` or non-finite.
  set cellSize(num value) {
    final v = value.toDouble();
    if (!(v >= 1) || !v.isFinite) {
      throw RangeError('invalid cell size');
    }
    _k = (math.log(v) / math.ln2).floor();
    _resize();
  }

  /// The standard deviation (bandwidth) of the Gaussian kernel.
  double get bandwidth => math.sqrt(_r * (_r + 1.0));

  /// Sets the standard deviation (bandwidth) of the Gaussian kernel.
  ///
  /// Throws a [RangeError] if [value] is negative or non-finite.
  set bandwidth(num value) {
    final v = value.toDouble();
    if (!(v >= 0) || !v.isFinite) {
      throw RangeError('invalid bandwidth');
    }
    _r = (math.sqrt(4.0 * v * v + 1.0) - 1.0) / 2.0;
    _resize();
  }

  /// The configured constant approximate threshold count, if any.
  int? get thresholdsCount => _thresholdsCount;

  /// Sets an approximate constant threshold count. Setting `null` restores the
  /// default count of `20`.
  set thresholdsCount(int? count) {
    _thresholdsCount = count ?? 20;
    _thresholdsValues = null;
    _thresholdsGenerator = null;
    _thresholdsCountGenerator = null;
  }

  /// The configured explicit threshold values (defensively copied), if any.
  List<double>? get thresholdsValues => _thresholdsValues;

  /// Sets explicit threshold values (defensively copied). Setting `null`
  /// restores the default count of `20`.
  set thresholdsValues(List<double>? values) {
    if (values == null) {
      _thresholdsValues = null;
      _thresholdsCount = 20;
      _thresholdsGenerator = null;
      _thresholdsCountGenerator = null;
    } else {
      _thresholdsValues = contourArraySlice(values);
      _thresholdsCount = null;
      _thresholdsGenerator = null;
      _thresholdsCountGenerator = null;
    }
  }

  /// The configured threshold values generator callback, if any.
  ContourThresholdsValues? get thresholdsGenerator => _thresholdsGenerator;

  /// Sets a threshold values generator callback. Setting `null` restores the
  /// default count of `20`.
  set thresholdsGenerator(ContourThresholdsValues? fn) {
    _thresholdsGenerator = fn;
    _thresholdsValues = null;
    _thresholdsCountGenerator = null;
    _thresholdsCount = fn == null ? 20 : null;
  }

  /// The configured threshold count generator callback, if any.
  ContourThresholdsCount? get thresholdsCountGenerator =>
      _thresholdsCountGenerator;

  /// Sets a threshold count generator callback. Setting `null` restores the
  /// default count of `20`.
  set thresholdsCountGenerator(ContourThresholdsCount? fn) {
    _thresholdsCountGenerator = fn;
    _thresholdsValues = null;
    _thresholdsGenerator = null;
    _thresholdsCount = fn == null ? 20 : null;
  }

  Float64List _grid(Iterable<T> data) {
    final n = _n;
    final m = _m;
    final len = n * m;
    final values = Float64List(len);
    if (len == 0) return values;

    final o = _o;
    final pow2k = 1.0 / (1 << _k);
    final nDouble = n.toDouble();
    final mDouble = m.toDouble();
    final nMinus1 = n - 1;
    final mMinus1 = m - 1;

    final xFn = _x;
    final xIdxFn = _xIndexed;
    final xConstVal = _xConst;
    final yFn = _y;
    final yIdxFn = _yIndexed;
    final yConstVal = _yConst;
    final wFn = _weight;
    final wIdxFn = _weightIndexed;
    final wConstVal = _weightConst;
    final defaultWeight = _isDefaultWeight;

    // Fast path: 1-arg x/y accessors with default unit weight.
    if (defaultWeight &&
        xIdxFn == null &&
        yIdxFn == null &&
        xConstVal == null &&
        yConstVal == null) {
      if (data is List<T>) {
        final count = data.length;
        for (var i = 0; i < count; ++i) {
          final d = data[i];
          final xi = (xFn(d) + o) * pow2k;
          final yi = (yFn(d) + o) * pow2k;
          if (xi >= 0 && xi < nDouble && yi >= 0 && yi < mDouble) {
            final x0 = xi.toInt();
            final y0 = yi.toInt();
            final xt = xi - x0 - 0.5;
            final yt = yi - y0 - 0.5;
            final oneMinusXt = 1.0 - xt;
            final oneMinusYt = 1.0 - yt;
            final idx00 = x0 + y0 * n;
            if (x0 < nMinus1 && y0 < mMinus1) {
              values[idx00] += oneMinusXt * oneMinusYt;
              values[idx00 + 1] += xt * oneMinusYt;
              values[idx00 + 1 + n] += xt * yt;
              values[idx00 + n] += oneMinusXt * yt;
            } else {
              values[idx00] += oneMinusXt * oneMinusYt;
              final idx10 = idx00 + 1;
              if (idx10 < len) values[idx10] += xt * oneMinusYt;
              final idx11 = idx00 + 1 + n;
              if (idx11 < len) values[idx11] += xt * yt;
              final idx01 = idx00 + n;
              if (idx01 < len) values[idx01] += oneMinusXt * yt;
            }
          }
        }
      } else {
        for (final d in data) {
          final xi = (xFn(d) + o) * pow2k;
          final yi = (yFn(d) + o) * pow2k;
          if (xi >= 0 && xi < nDouble && yi >= 0 && yi < mDouble) {
            final x0 = xi.toInt();
            final y0 = yi.toInt();
            final xt = xi - x0 - 0.5;
            final yt = yi - y0 - 0.5;
            final oneMinusXt = 1.0 - xt;
            final oneMinusYt = 1.0 - yt;
            final idx00 = x0 + y0 * n;
            if (x0 < nMinus1 && y0 < mMinus1) {
              values[idx00] += oneMinusXt * oneMinusYt;
              values[idx00 + 1] += xt * oneMinusYt;
              values[idx00 + 1 + n] += xt * yt;
              values[idx00 + n] += oneMinusXt * yt;
            } else {
              values[idx00] += oneMinusXt * oneMinusYt;
              final idx10 = idx00 + 1;
              if (idx10 < len) values[idx10] += xt * oneMinusYt;
              final idx11 = idx00 + 1 + n;
              if (idx11 < len) values[idx11] += xt * yt;
              final idx01 = idx00 + n;
              if (idx01 < len) values[idx01] += oneMinusXt * yt;
            }
          }
        }
      }
    } else if (xIdxFn == null &&
        yIdxFn == null &&
        wIdxFn == null &&
        xConstVal == null &&
        yConstVal == null &&
        wConstVal == null &&
        wFn != null &&
        data is List<T>) {
      // Fast path: 1-arg x/y/weight accessors on List<T>.
      final count = data.length;
      for (var i = 0; i < count; ++i) {
        final d = data[i];
        final wi = wFn(d);
        if (wi == 0 || wi.isNaN) continue;
        final xi = (xFn(d) + o) * pow2k;
        final yi = (yFn(d) + o) * pow2k;
        if (xi >= 0 && xi < nDouble && yi >= 0 && yi < mDouble) {
          final x0 = xi.toInt();
          final y0 = yi.toInt();
          final xt = xi - x0 - 0.5;
          final yt = yi - y0 - 0.5;
          final wYt = yt * wi;
          final wOneMinusYt = (1.0 - yt) * wi;
          final oneMinusXt = 1.0 - xt;
          final idx00 = x0 + y0 * n;
          if (x0 < nMinus1 && y0 < mMinus1) {
            values[idx00] += oneMinusXt * wOneMinusYt;
            values[idx00 + 1] += xt * wOneMinusYt;
            values[idx00 + 1 + n] += xt * wYt;
            values[idx00 + n] += oneMinusXt * wYt;
          } else {
            values[idx00] += oneMinusXt * wOneMinusYt;
            final idx10 = idx00 + 1;
            if (idx10 < len) values[idx10] += xt * wOneMinusYt;
            final idx11 = idx00 + 1 + n;
            if (idx11 < len) values[idx11] += xt * wYt;
            final idx01 = idx00 + n;
            if (idx01 < len) values[idx01] += oneMinusXt * wYt;
          }
        }
      }
    } else {
      var i = -1;
      for (final d in data) {
        ++i;
        final px = xConstVal ?? (xIdxFn != null ? xIdxFn(d, i, data) : xFn(d));
        final py = yConstVal ?? (yIdxFn != null ? yIdxFn(d, i, data) : yFn(d));
        final xi = (px + o) * pow2k;
        final yi = (py + o) * pow2k;
        final wi = defaultWeight
            ? 1.0
            : (wConstVal ?? (wIdxFn != null ? wIdxFn(d, i, data) : wFn!(d)));
        if (wi != 0 &&
            !wi.isNaN &&
            xi >= 0 &&
            xi < nDouble &&
            yi >= 0 &&
            yi < mDouble) {
          final x0 = xi.toInt();
          final y0 = yi.toInt();
          final xt = xi - x0 - 0.5;
          final yt = yi - y0 - 0.5;
          final idx00 = x0 + y0 * n;
          values[idx00] += (1.0 - xt) * (1.0 - yt) * wi;
          final idx10 = idx00 + 1;
          if (idx10 < len) values[idx10] += xt * (1.0 - yt) * wi;
          final idx11 = idx00 + 1 + n;
          if (idx11 < len) values[idx11] += xt * yt * wi;
          final idx01 = idx00 + n;
          if (idx01 < len) values[idx01] += (1.0 - xt) * yt * wi;
        }
      }
    }

    blur2(Blur2Data(data: values, width: n, height: m), _r * pow2k);
    return values;
  }

  /// Estimates density contour polygons for [data].
  List<ContourMultiPolygon> call(Iterable<T> data) {
    final values = _grid(data);
    final scale = (1 << _k).toDouble();
    final pow4k = scale * scale;
    final offset = _o;

    final List<double> tz;
    final explicitValues = _thresholdsValues;
    final valuesGen = _thresholdsGenerator;
    if (explicitValues != null) {
      tz = contourArraySlice(explicitValues)..sort(contourAscending);
    } else if (valuesGen != null) {
      tz = contourArraySlice(valuesGen(values))..sort(contourAscending);
    } else {
      final count = _thresholdsCount ?? _thresholdsCountGenerator!(values);
      final maxV = max<double>(values) ?? 0.0;
      tz = ticks(double.minPositive, maxV / pow4k, count);
    }

    return buildDensityContoursBatch(values, _n, _m, tz, pow4k, scale, offset);
  }

  /// Precomputes the blurred density grid for [data] and returns a reusable
  /// [DensityContours] evaluator with a [DensityContours.max] density getter.
  DensityContours contours(Iterable<T> data) {
    final values = _grid(data);
    final scale = (1 << _k).toDouble();
    final pow4k = scale * scale;
    return DensityContours._(
      values: values,
      width: _n,
      height: _m,
      pow4k: pow4k,
      scale: scale,
      offset: _o,
    );
  }
}

/// Constructs a 2D kernel density estimator [ContourDensity] for arbitrary
/// data elements of type [T] with explicit [x] and [y] accessors.
ContourDensity<T> contourDensity<T>({
  required DensityAccessor<T> x,
  required DensityAccessor<T> y,
  DensityAccessor<T>? weight,
  (num, num) size = (960, 500),
  num cellSize = 4,
  num? bandwidth,
  int? thresholdsCount,
  List<double>? thresholdsValues,
  ContourThresholdsValues? thresholdsGenerator,
  ContourThresholdsCount? thresholdsCountGenerator,
}) => ContourDensity<T>(
  x: x,
  y: y,
  weight: weight,
  size: size,
  cellSize: cellSize,
  bandwidth: bandwidth,
  thresholdsCount: thresholdsCount,
  thresholdsValues: thresholdsValues,
  thresholdsGenerator: thresholdsGenerator,
  thresholdsCountGenerator: thresholdsCountGenerator,
);

/// Constructs a 2D kernel density estimator [ContourDensity] for `(double,
/// double)` point records with default `x: (d) => d.$1` and `y: (d) => d.$2`
/// accessors.
ContourDensity<(double, double)> contourDensityPoints({
  DensityAccessor<(double, double)>? weight,
  (num, num) size = (960, 500),
  num cellSize = 4,
  num? bandwidth,
  int? thresholdsCount,
  List<double>? thresholdsValues,
  ContourThresholdsValues? thresholdsGenerator,
  ContourThresholdsCount? thresholdsCountGenerator,
}) => ContourDensity<(double, double)>(
  x: _pointX,
  y: _pointY,
  weight: weight,
  size: size,
  cellSize: cellSize,
  bandwidth: bandwidth,
  thresholdsCount: thresholdsCount,
  thresholdsValues: thresholdsValues,
  thresholdsGenerator: thresholdsGenerator,
  thresholdsCountGenerator: thresholdsCountGenerator,
);

double _pointX((double, double) d) => d.$1;
double _pointY((double, double) d) => d.$2;
