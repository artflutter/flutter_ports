// Ported from d3-array v3.2.4 src/blur.js (ISC, Mike Bostock).

/// Port of `src/blur.js` of d3-array 3.2.4: [blur], [blur2], and [blurImage].
library;

import 'dart:typed_data';

/// A 2D scalar grid for [blur2].
// DIVERGES(d3-array): adapt-array-typed-api, typed Blur2Data class instead of
// untyped JS object `{data, width, height}`.
final class Blur2Data({
  /// Row-major scalar grid values (mutated in-place by [blur2]).
  required final List<double> data,

  /// Number of columns.
  required final int width,
  int? height,
}) {
  /// Creates a [Blur2Data] grid. If [height] is omitted, it is computed as
  /// `data.length ~/ width` (or `0` when `width <= 0`).
  this;

  /// Number of rows.
  final int height = height ?? (width > 0 ? data.length ~/ width : 0);
}

/// An RGBA pixel buffer for [blurImage].
// DIVERGES(d3-array): adapt-array-typed-api, typed BlurImageData class backed
// by Uint8ClampedList instead of untyped JS ImageData.
final class BlurImageData({
  /// Row-major interleaved RGBA byte buffer (mutated in-place by [blurImage]).
  required final Uint8ClampedList data,

  /// Image width in pixels.
  required final int width,
  int? height,
}) {
  /// Creates a [BlurImageData] buffer. If [height] is omitted, it is computed
  /// as `data.length ~/ (width * 4)` (or `0` when `width <= 0`).
  this;

  /// Image height in pixels.
  final int height = height ?? (width > 0 ? data.length ~/ (width * 4) : 0);
}

/// ECMAScript `ToUint8Clamp` round-half-to-even clamping matching JS
/// `Uint8ClampedArray` assignment.
@pragma('vm:prefer-inline')
int _clampUint8(double v) {
  if (!(v > 0.0)) return 0;
  if (v >= 255.0) return 255;
  final f = v.floor();
  final rem = v - f;
  if (rem > 0.5) return f + 1;
  if (rem < 0.5) return f;
  return f.isOdd ? f + 1 : f;
}

void _bluriFloat64(
  Float64List target,
  Float64List source,
  int start,
  int stop,
  int step,
  int radius,
) {
  final last = stop - step;
  if (last < start) return;
  final w = (2 * radius + 1).toDouble();
  final s = step * radius;
  var sum = radius * source[start];
  final initEnd = start + s;
  for (var i = start; i < initEnd; i += step) {
    sum += source[i < last ? i : last];
  }
  // DIVERGES(d3-array): adapt-array-fast-forms, specialized Float64List
  // branch-split sliding window with exact `sum / w` IEEE-754 division.
  final innerStart = start + s;
  final innerEnd = last - s;
  if (innerStart <= innerEnd) {
    final sStart = source[start];
    final sLast = source[last];
    var i = start;
    for (; i < innerStart; i += step) {
      sum += source[i + s];
      target[i] = sum / w;
      sum -= sStart;
    }
    for (; i <= innerEnd; i += step) {
      sum += source[i + s];
      target[i] = sum / w;
      sum -= source[i - s];
    }
    for (; i <= last; i += step) {
      sum += sLast;
      target[i] = sum / w;
      sum -= source[i - s];
    }
  } else {
    for (var i = start; i <= last; i += step) {
      final hi = i + s;
      final lo = i - s;
      sum += source[hi < last ? hi : last];
      target[i] = sum / w;
      sum -= source[lo > start ? lo : start];
    }
  }
}

void _blurfFloat64(
  Float64List target,
  Float64List source,
  int start,
  int stop,
  int step,
  double radius,
) {
  final r0 = radius.floor();
  if (r0 == radius) {
    _bluriFloat64(target, source, start, stop, step, r0);
    return;
  }
  final last = stop - step;
  if (last < start) return;
  final t = radius - r0;
  final w = 2.0 * radius + 1.0;
  final s0 = step * r0;
  final s1 = s0 + step;
  var sum = r0 * source[start];
  final initEnd = start + s0;
  for (var i = start; i < initEnd; i += step) {
    sum += source[i < last ? i : last];
  }
  final innerStart = start + s1;
  final innerEnd = last - s1;
  if (innerStart <= innerEnd) {
    var i = start;
    for (; i < innerStart; i += step) {
      final hi0 = i + s0;
      final lo0 = i - s0;
      final lo1 = i - s1;
      sum += source[hi0 < last ? hi0 : last];
      target[i] =
          (sum + t * (source[lo1 > start ? lo1 : start] + source[i + s1])) / w;
      sum -= source[lo0 > start ? lo0 : start];
    }
    for (; i <= innerEnd; i += step) {
      sum += source[i + s0];
      target[i] = (sum + t * (source[i - s1] + source[i + s1])) / w;
      sum -= source[i - s0];
    }
    for (; i <= last; i += step) {
      final hi0 = i + s0;
      final hi1 = i + s1;
      final lo0 = i - s0;
      sum += source[hi0 < last ? hi0 : last];
      target[i] =
          (sum + t * (source[i - s1] + source[hi1 < last ? hi1 : last])) / w;
      sum -= source[lo0 > start ? lo0 : start];
    }
  } else {
    for (var i = start; i <= last; i += step) {
      final hi0 = i + s0;
      final lo0 = i - s0;
      final hi1 = i + s1;
      final lo1 = i - s1;
      sum += source[hi0 < last ? hi0 : last];
      target[i] =
          (sum +
              t *
                  (source[lo1 > start ? lo1 : start] +
                      source[hi1 < last ? hi1 : last])) /
          w;
      sum -= source[lo0 > start ? lo0 : start];
    }
  }
}

void _bluriDouble(
  List<double> target,
  List<double> source,
  int start,
  int stop,
  int step,
  int radius,
) {
  final last = stop - step;
  if (last < start) return;
  final w = (2 * radius + 1).toDouble();
  final s = step * radius;
  var sum = radius * source[start];
  final initEnd = start + s;
  for (var i = start; i < initEnd; i += step) {
    sum += source[i < last ? i : last];
  }
  final innerStart = start + s;
  final innerEnd = last - s;
  if (innerStart <= innerEnd) {
    final sStart = source[start];
    final sLast = source[last];
    var i = start;
    for (; i < innerStart; i += step) {
      sum += source[i + s];
      target[i] = sum / w;
      sum -= sStart;
    }
    for (; i <= innerEnd; i += step) {
      sum += source[i + s];
      target[i] = sum / w;
      sum -= source[i - s];
    }
    for (; i <= last; i += step) {
      sum += sLast;
      target[i] = sum / w;
      sum -= source[i - s];
    }
  } else {
    for (var i = start; i <= last; i += step) {
      final hi = i + s;
      final lo = i - s;
      sum += source[hi < last ? hi : last];
      target[i] = sum / w;
      sum -= source[lo > start ? lo : start];
    }
  }
}

void _blurfDouble(
  List<double> target,
  List<double> source,
  int start,
  int stop,
  int step,
  double radius,
) {
  final r0 = radius.floor();
  if (r0 == radius) {
    _bluriDouble(target, source, start, stop, step, r0);
    return;
  }
  final last = stop - step;
  if (last < start) return;
  final t = radius - r0;
  final w = 2.0 * radius + 1.0;
  final s0 = step * r0;
  final s1 = s0 + step;
  var sum = r0 * source[start];
  final initEnd = start + s0;
  for (var i = start; i < initEnd; i += step) {
    sum += source[i < last ? i : last];
  }
  final innerStart = start + s1;
  final innerEnd = last - s1;
  if (innerStart <= innerEnd) {
    var i = start;
    for (; i < innerStart; i += step) {
      final hi0 = i + s0;
      final lo0 = i - s0;
      final lo1 = i - s1;
      sum += source[hi0 < last ? hi0 : last];
      target[i] =
          (sum + t * (source[lo1 > start ? lo1 : start] + source[i + s1])) / w;
      sum -= source[lo0 > start ? lo0 : start];
    }
    for (; i <= innerEnd; i += step) {
      sum += source[i + s0];
      target[i] = (sum + t * (source[i - s1] + source[i + s1])) / w;
      sum -= source[i - s0];
    }
    for (; i <= last; i += step) {
      final hi0 = i + s0;
      final hi1 = i + s1;
      final lo0 = i - s0;
      sum += source[hi0 < last ? hi0 : last];
      target[i] =
          (sum + t * (source[i - s1] + source[hi1 < last ? hi1 : last])) / w;
      sum -= source[lo0 > start ? lo0 : start];
    }
  } else {
    for (var i = start; i <= last; i += step) {
      final hi0 = i + s0;
      final lo0 = i - s0;
      final hi1 = i + s1;
      final lo1 = i - s1;
      sum += source[hi0 < last ? hi0 : last];
      target[i] =
          (sum +
              t *
                  (source[lo1 > start ? lo1 : start] +
                      source[hi1 < last ? hi1 : last])) /
          w;
      sum -= source[lo0 > start ? lo0 : start];
    }
  }
}

void _bluriUint8(
  Uint8ClampedList target,
  Uint8ClampedList source,
  int start,
  int stop,
  int step,
  int radius,
) {
  final last = stop - step;
  if (last < start) return;
  final w = (2 * radius + 1).toDouble();
  final s = step * radius;
  var sum = radius * source[start];
  final initEnd = start + s;
  for (var i = start; i < initEnd; i += step) {
    sum += source[i < last ? i : last];
  }
  for (var i = start; i <= last; i += step) {
    final hi = i + s;
    final lo = i - s;
    sum += source[hi < last ? hi : last];
    target[i] = _clampUint8(sum / w);
    sum -= source[lo > start ? lo : start];
  }
}

void _blurfUint8(
  Uint8ClampedList target,
  Uint8ClampedList source,
  int start,
  int stop,
  int step,
  double radius,
) {
  final r0 = radius.floor();
  if (r0 == radius) {
    _bluriUint8(target, source, start, stop, step, r0);
    return;
  }
  final last = stop - step;
  if (last < start) return;
  final t = radius - r0;
  final w = 2.0 * radius + 1.0;
  final s0 = step * r0;
  final s1 = s0 + step;
  var sum = (r0 * source[start]).toDouble();
  final initEnd = start + s0;
  for (var i = start; i < initEnd; i += step) {
    sum += source[i < last ? i : last];
  }
  for (var i = start; i <= last; i += step) {
    final hi0 = i + s0;
    final lo0 = i - s0;
    final hi1 = i + s1;
    final lo1 = i - s1;
    sum += source[hi0 < last ? hi0 : last];
    target[i] = _clampUint8(
      (sum +
              t *
                  (source[lo1 > start ? lo1 : start] +
                      source[hi1 < last ? hi1 : last])) /
          w,
    );
    sum -= source[lo0 > start ? lo0 : start];
  }
}

void _blurhFloat64(
  Float64List target,
  Float64List source,
  int w,
  int h,
  double radius,
) {
  final n = w * h;
  final r0 = radius.floor();
  if (r0 == radius) {
    for (var y = 0; y < n; y += w) {
      _bluriFloat64(target, source, y, y + w, 1, r0);
    }
  } else {
    for (var y = 0; y < n; y += w) {
      _blurfFloat64(target, source, y, y + w, 1, radius);
    }
  }
}

void _blurvFloat64(
  Float64List target,
  Float64List source,
  int w,
  int h,
  double radius,
) {
  final n = w * h;
  final r0 = radius.floor();
  if (r0 == radius) {
    for (var x = 0; x < w; ++x) {
      _bluriFloat64(target, source, x, x + n, w, r0);
    }
  } else {
    for (var x = 0; x < w; ++x) {
      _blurfFloat64(target, source, x, x + n, w, radius);
    }
  }
}

void _blurhDouble(
  List<double> target,
  List<double> source,
  int w,
  int h,
  double radius,
) {
  final n = w * h;
  for (var y = 0; y < n; y += w) {
    _blurfDouble(target, source, y, y + w, 1, radius);
  }
}

void _blurvDouble(
  List<double> target,
  List<double> source,
  int w,
  int h,
  double radius,
) {
  final n = w * h;
  for (var x = 0; x < w; ++x) {
    _blurfDouble(target, source, x, x + n, w, radius);
  }
}

void _blurChannelPass(
  Uint8ClampedList target,
  Uint8ClampedList source,
  int start,
  int stop,
  int step,
  double radius,
) {
  final s = start << 2;
  final e = stop << 2;
  final st = step << 2;
  _blurfUint8(target, source, s + 0, e + 0, st, radius);
  _blurfUint8(target, source, s + 1, e + 1, st, radius);
  _blurfUint8(target, source, s + 2, e + 2, st, radius);
  _blurfUint8(target, source, s + 3, e + 3, st, radius);
}

void _blurhImage(
  Uint8ClampedList target,
  Uint8ClampedList source,
  int w,
  int h,
  double radius,
) {
  final n = w * h;
  for (var y = 0; y < n; y += w) {
    _blurChannelPass(target, source, y, y + w, 1, radius);
  }
}

void _blurvImage(
  Uint8ClampedList target,
  Uint8ClampedList source,
  int w,
  int h,
  double radius,
) {
  final n = w * h;
  for (var x = 0; x < w; ++x) {
    _blurChannelPass(target, source, x, x + n, w, radius);
  }
}

/// Blurs [values] in-place with an approximate Gaussian kernel of radius [r]
/// (3 box-blur passes) and returns [values].
List<double> blur(List<double> values, double r) {
  if (!(r >= 0)) throw RangeError('invalid r');
  final length = values.length;
  if (length == 0 || r == 0) return values;
  if (values is Float64List) {
    final temp = Float64List.fromList(values);
    _blurfFloat64(values, temp, 0, length, 1, r);
    _blurfFloat64(temp, values, 0, length, 1, r);
    _blurfFloat64(values, temp, 0, length, 1, r);
    return values;
  }
  final temp = Float64List.fromList(values);
  _blurfDouble(values, temp, 0, length, 1, r);
  _blurfDouble(temp, values, 0, length, 1, r);
  _blurfDouble(values, temp, 0, length, 1, r);
  return values;
}

/// Blurs a 2D scalar grid [data] in-place with horizontal radius [rx] and
/// vertical radius [ry] (defaulting to [rx]) and returns [data].
Blur2Data blur2(Blur2Data data, double rx, [double? ry]) {
  final rY = ry ?? rx;
  if (!(rx >= 0)) throw RangeError('invalid rx');
  if (!(rY >= 0)) throw RangeError('invalid ry');
  final values = data.data;
  final width = data.width;
  final height = data.height;
  if (width < 0) throw RangeError('invalid width');
  if (height < 0) throw RangeError('invalid height');
  if (width == 0 || height == 0 || (rx == 0 && rY == 0)) return data;
  if (values is Float64List) {
    final temp = Float64List.fromList(values);
    if (rx > 0 && rY > 0) {
      _blurhFloat64(temp, values, width, height, rx);
      _blurhFloat64(values, temp, width, height, rx);
      _blurhFloat64(temp, values, width, height, rx);
      _blurvFloat64(values, temp, width, height, rY);
      _blurvFloat64(temp, values, width, height, rY);
      _blurvFloat64(values, temp, width, height, rY);
    } else if (rx > 0) {
      _blurhFloat64(values, temp, width, height, rx);
      _blurhFloat64(temp, values, width, height, rx);
      _blurhFloat64(values, temp, width, height, rx);
    } else {
      _blurvFloat64(values, temp, width, height, rY);
      _blurvFloat64(temp, values, width, height, rY);
      _blurvFloat64(values, temp, width, height, rY);
    }
    return data;
  }
  final temp = Float64List.fromList(values);
  if (rx > 0 && rY > 0) {
    _blurhDouble(temp, values, width, height, rx);
    _blurhDouble(values, temp, width, height, rx);
    _blurhDouble(temp, values, width, height, rx);
    _blurvDouble(values, temp, width, height, rY);
    _blurvDouble(temp, values, width, height, rY);
    _blurvDouble(values, temp, width, height, rY);
  } else if (rx > 0) {
    _blurhDouble(values, temp, width, height, rx);
    _blurhDouble(temp, values, width, height, rx);
    _blurhDouble(values, temp, width, height, rx);
  } else {
    _blurvDouble(values, temp, width, height, rY);
    _blurvDouble(temp, values, width, height, rY);
    _blurvDouble(values, temp, width, height, rY);
  }
  return data;
}

/// Blurs an RGBA image buffer [data] in-place with horizontal radius [rx] and
/// vertical radius [ry] (defaulting to [rx]) and returns [data].
BlurImageData blurImage(BlurImageData data, double rx, [double? ry]) {
  final rY = ry ?? rx;
  if (!(rx >= 0)) throw RangeError('invalid rx');
  if (!(rY >= 0)) throw RangeError('invalid ry');
  final values = data.data;
  final width = data.width;
  final height = data.height;
  if (width < 0) throw RangeError('invalid width');
  if (height < 0) throw RangeError('invalid height');
  if (width == 0 || height == 0 || (rx == 0 && rY == 0)) return data;
  final temp = Uint8ClampedList.fromList(values);
  if (rx > 0 && rY > 0) {
    _blurhImage(temp, values, width, height, rx);
    _blurhImage(values, temp, width, height, rx);
    _blurhImage(temp, values, width, height, rx);
    _blurvImage(values, temp, width, height, rY);
    _blurvImage(temp, values, width, height, rY);
    _blurvImage(values, temp, width, height, rY);
  } else if (rx > 0) {
    _blurhImage(values, temp, width, height, rx);
    _blurhImage(temp, values, width, height, rx);
    _blurhImage(values, temp, width, height, rx);
  } else {
    _blurvImage(values, temp, width, height, rY);
    _blurvImage(temp, values, width, height, rY);
    _blurvImage(values, temp, width, height, rY);
  }
  return data;
}
