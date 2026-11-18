// Original code, not ported from d3-interpolate: the port against Node.js data.

/// Compares the d3-interpolate port with upstream d3-interpolate v3.0.1 in
/// Node.js v24.22.1 on arm64, the reference engine of the repository
/// (Chart.js ADR 0146). The data comes from
/// `tool/reference/d3_interpolate_reference.mjs`.
///
/// Each test runs the cases of one part through the public API and fails
/// with the whole list of its differences. The comparisons:
///
/// - A result of a path with only `+ - * /`, `sqrt`, `floor`, `round`,
///   `%`, `min` and `max` compares bit-exact: NaN equals NaN, and -0 differs
///   from +0.
/// - A result of a path with `exp`, `log`, `atan2`, `atan`, `sin`, `cos` or
///   `pow` (zoom, the `rotate` and `skewX` of `decompose`, an RGB or
///   Cubehelix gamma other than 1, and a color of another space that the
///   interpolator converts) compares within a relative 1e-12, or an absolute
///   1e-12 below 1 (the row `platform-interpolate-math-last-bit`). A whole
///   exponent is no exception: `pow(1 / 3, 3)` of the Cubehelix gamma 3
///   differs in the last bit on darwin-arm64.
/// - The `ux` and `uy` of the general case of `interpolateZoom` also allow
///   the cancellation of `cosh(r0) * tanh(rho * s + r0) - sinh(r0)`
///   (zoom.js:51): a last bit of `exp` there moves `u` by about
///   `eps * w0 / (rho2 * d1) * cosh(r0)`, which a small rho makes large
///   (`interpolateZoom.rho(0)` of `test/zoom-test.js`).
/// - A color result compares its space, its channels and its text
///   (`toString()`, which is `formatRgb()`). The text of an RGB or HSL result
///   with exact channels compares exactly; each other text compares its
///   numbers by the tolerance above, because `formatRgb()` of a Lab, HCL or
///   Cubehelix color takes `pow`, `sin` or `cos`.
/// - A date compares its microseconds since the epoch, truncated toward zero
///   to whole milliseconds, with the time value of Node.js: `setTime`
///   truncates the time toward zero (TimeClip), and the port keeps the
///   microseconds (the row `adapt-interpolate-date-value`).
/// - A transform result compares the six numbers that upstream prints. The
///   text loses the sign of a zero, so +0 equals -0 there.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

import 'd3_interpolate_reference.dart';

void main() {
  test('the data comes from the reference engine', () {
    expect(d3InterpolateReferenceNode, 'v24.22.1');
    expect(d3InterpolateReferenceArch, 'arm64');
  });

  test('interpolateNumber, interpolateRound, interpolateHue and interpolate '
      'of two numbers give the results of Node.js', () {
    final mismatches = <String>[];
    for (final c in numberCases) {
      final i = switch (c.interpolator) {
        'interpolateNumber' => interpolateNumber(c.a, c.b),
        'interpolateRound' => interpolateRound(c.a, c.b),
        'interpolateHue' => interpolateHue(c.a, c.b),
        'interpolate' => interpolate<double>(c.a, c.b),
        _ => throw ArgumentError.value(c.interpolator, 'interpolator'),
      };
      final label = '${c.interpolator}(${_number(c.a)}, ${_number(c.b)})';
      _compareAt(mismatches, label, ts.map(i).toList(), c.values, _exact);
    }
    _expectNone(mismatches);
  });

  test('interpolateBasis and interpolateBasisClosed give the results of '
      'Node.js', () {
    final mismatches = <String>[];
    for (final c in splineCases) {
      final i = switch (c.interpolator) {
        'interpolateBasis' => interpolateBasis(c.values),
        'interpolateBasisClosed' => interpolateBasisClosed(c.values),
        _ => throw ArgumentError.value(c.interpolator, 'interpolator'),
      };
      final label = '${c.interpolator}(${_numbers(c.values)})';
      _compareAt(mismatches, label, ts.map(i).toList(), c.results, _exact);
    }
    _expectNone(mismatches);
  });

  test('interpolateDiscrete gives the results of Node.js', () {
    final mismatches = <String>[];
    for (final c in discreteCases) {
      final i = interpolateDiscrete<double>(c.range);
      final label = 'interpolateDiscrete(${_numbers(c.range)})';
      _compareAt(mismatches, label, ts.map(i).toList(), c.results, _exact);
    }
    _expectNone(mismatches);
  });

  test('piecewise of numbers gives the results of Node.js', () {
    final mismatches = <String>[];
    for (final c in piecewiseCases) {
      final i = switch (c.interpolate) {
        'interpolate' => piecewise<double>(c.values),
        'interpolateNumber' => piecewise<double>(
          c.values,
          interpolate: interpolateNumber,
        ),
        'interpolateRound' => piecewise<double>(
          c.values,
          interpolate: interpolateRound,
        ),
        _ => throw ArgumentError.value(c.interpolate, 'interpolate'),
      };
      final label = c.interpolate == 'interpolate'
          ? 'piecewise(${_numbers(c.values)})'
          : 'piecewise(${_numbers(c.values)}, '
                'interpolate: ${c.interpolate})';
      _compareAt(mismatches, label, ts.map(i).toList(), c.results, _exact);
    }
    _expectNone(mismatches);
  });

  test('quantize gives the samples of Node.js', () {
    final mismatches = <String>[];
    for (final c in quantizeCases) {
      final i = switch (c.interpolator) {
        'interpolateNumber' => interpolateNumber(c.a, c.b),
        'interpolateRound' => interpolateRound(c.a, c.b),
        _ => throw ArgumentError.value(c.interpolator, 'interpolator'),
      };
      final label =
          'quantize(${c.interpolator}(${_number(c.a)}, ${_number(c.b)}), '
          '${c.n})';
      _compare(mismatches, label, quantize<double>(i, c.n), c.samples, _exact);
    }
    _expectNone(mismatches);
  });

  test('the color interpolators give the colors and the texts of Node.js', () {
    final mismatches = <String>[];
    for (final c in colorCases) {
      final start = _make(c.start);
      final end = _make(c.end);
      final gamma = c.gamma == 1 ? '' : '.gamma(${_number(c.gamma)})';
      final label =
          '${c.interpolator}$gamma(${_colorText(c.start)}, '
          '${_colorText(c.end)})';
      final i = switch (c.interpolator) {
        'interpolateRgb' =>
          c.gamma == 1
              ? interpolateRgb(start, end)
              : interpolateRgb.gamma(c.gamma)(start, end),
        'interpolateHsl' => interpolateHsl(start, end),
        'interpolateHslLong' => interpolateHslLong(start, end),
        'interpolateLab' => interpolateLab(start, end),
        'interpolateHcl' => interpolateHcl(start, end),
        'interpolateHclLong' => interpolateHclLong(start, end),
        'interpolateCubehelix' =>
          c.gamma == 1
              ? interpolateCubehelix(start, end)
              : interpolateCubehelix.gamma(c.gamma)(start, end),
        'interpolateCubehelixLong' =>
          c.gamma == 1
              ? interpolateCubehelixLong(start, end)
              : interpolateCubehelixLong.gamma(c.gamma)(start, end),
        'interpolate' => interpolate<Color>(start, end),
        _ => throw ArgumentError.value(c.interpolator, 'interpolator'),
      };
      _compareColors(
        mismatches,
        label,
        ts.map(i).toList(),
        c.space,
        c.channels,
        c.texts,
        exact: _exactColorCase(c),
      );
    }
    _expectNone(mismatches);
  });

  test('interpolateRgbBasis and interpolateRgbBasisClosed give the colors '
      'and the texts of Node.js', () {
    final mismatches = <String>[];
    for (final c in colorSplineCases) {
      final colors = c.colors.map(_make).toList();
      final label =
          '${c.interpolator}([${c.colors.map(_colorText).join(', ')}])';
      final i = switch (c.interpolator) {
        'interpolateRgbBasis' => interpolateRgbBasis(colors),
        'interpolateRgbBasisClosed' => interpolateRgbBasisClosed(colors),
        _ => throw ArgumentError.value(c.interpolator, 'interpolator'),
      };
      _compareColors(
        mismatches,
        label,
        ts.map(i).toList(),
        'rgb',
        c.channels,
        c.texts,
        exact: c.colors.every((color) => _exactToRgb(color.space)),
      );
    }
    _expectNone(mismatches);
  });

  test('interpolateDate and interpolate of two dates give the time values of '
      'Node.js', () {
    final mismatches = <String>[];
    for (final c in dateCases) {
      final a = DateTime.fromMillisecondsSinceEpoch(c.a, isUtc: true);
      final b = DateTime.fromMillisecondsSinceEpoch(c.b, isUtc: true);
      final i = switch (c.interpolator) {
        'interpolateDate' => interpolateDate(a, b),
        'interpolate' => interpolate<DateTime>(a, b),
        _ => throw ArgumentError.value(c.interpolator, 'interpolator'),
      };
      final label = '${c.interpolator}(${c.a} ms, ${c.b} ms)';
      for (var k = 0; k < ts.length; k++) {
        final actual = i(ts[k]).microsecondsSinceEpoch ~/ 1000;
        if (actual != c.times[k]) {
          mismatches.add(
            '$label(${_number(ts[k])}): expected ${c.times[k]} ms, '
            'actual $actual ms',
          );
        }
      }
    }
    _expectNone(mismatches);
  });

  test('interpolateNumberArray, interpolateArray and interpolate of a typed '
      'number list give the results of Node.js in one reused list', () {
    final mismatches = <String>[];
    for (final c in numberArrayCases) {
      final List<double> b = switch (c.type) {
        'Float64' => Float64List.fromList(c.b),
        'Float32' => Float32List.fromList(c.b),
        _ => throw ArgumentError.value(c.type, 'type'),
      };
      final i = switch (c.interpolator) {
        'interpolateNumberArray' => interpolateNumberArray(c.a, b),
        'interpolateArray' => interpolateArray<double>(c.a, b),
        'interpolate' => interpolate<List<double>>(c.a, b),
        _ => throw ArgumentError.value(c.interpolator, 'interpolator'),
      };
      final label =
          '${c.interpolator}(${_numbers(c.a)}, '
          '${c.type}List.fromList(${_numbers(c.b)}))';
      final results = <List<double>>[];
      List<double>? first;
      for (final t in ts) {
        final result = i(t);
        first ??= result;
        _expectSameList(mismatches, '$label(${_number(t)})', result, first);
        final typed = c.type == 'Float64'
            ? result is Float64List
            : result is Float32List;
        if (!typed) {
          mismatches.add(
            '$label(${_number(t)}): expected a ${c.type}List, '
            'actual a ${result.runtimeType}',
          );
        }
        results.add(List<double>.of(result));
      }
      _compareLists(mismatches, label, results, c.results, _exact);
    }
    _expectNone(mismatches);
  });

  test('interpolateArray and interpolate of two lists of numbers give the '
      'results of Node.js in one reused list', () {
    final mismatches = <String>[];
    for (final c in arrayCases) {
      final i = switch (c.interpolator) {
        'interpolateArray' => interpolateArray<double>(c.a, c.b),
        'interpolate' => interpolate<List<double>>(c.a, c.b),
        _ => throw ArgumentError.value(c.interpolator, 'interpolator'),
      };
      final label = '${c.interpolator}(${_numbers(c.a)}, ${_numbers(c.b)})';
      final results = <List<double>>[];
      List<double>? first;
      for (final t in ts) {
        final result = i(t);
        first ??= result;
        _expectSameList(mismatches, '$label(${_number(t)})', result, first);
        results.add(List<double>.of(result));
      }
      _compareLists(mismatches, label, results, c.results, _exact);
    }
    _expectNone(mismatches);
  });

  test('interpolateArray and interpolate of two lists of lists give the '
      'results of Node.js', () {
    final mismatches = <String>[];
    for (final c in nestedArrayCases) {
      final i = switch (c.interpolator) {
        'interpolateArray' => interpolateArray<List<double>>(c.a, c.b),
        'interpolate' => interpolate<List<List<double>>>(c.a, c.b),
        _ => throw ArgumentError.value(c.interpolator, 'interpolator'),
      };
      final label =
          '${c.interpolator}(${c.a.map(_numbers).toList()}, '
          '${c.b.map(_numbers).toList()})';
      for (var k = 0; k < ts.length; k++) {
        final result = i(ts[k]);
        _compareLists(
          mismatches,
          '$label(${_number(ts[k])})',
          [for (final item in result) List<double>.of(item)],
          c.results[k],
          _exact,
        );
      }
    }
    _expectNone(mismatches);
  });

  test('interpolateZoom gives the views and the duration of Node.js', () {
    final mismatches = <String>[];
    for (final c in zoomCases) {
      final rho = c.rho;
      final zoom = rho == null ? interpolateZoom : interpolateZoom.rho(rho);
      final i = zoom((c.p0[0], c.p0[1], c.p0[2]), (c.p1[0], c.p1[1], c.p1[2]));
      final name = rho == null
          ? 'interpolateZoom'
          : 'interpolateZoom.rho(${_number(rho)})';
      final label = '$name(${_numbers(c.p0)}, ${_numbers(c.p1)})';
      final condition = _zoomCondition(c);
      if (!_sameZoomDuration(condition, i.duration, c.duration)) {
        mismatches.add(
          '$label.duration: expected ${_number(c.duration)}, '
          'actual ${_number(i.duration)}',
        );
      }
      for (var k = 0; k < ts.length; k++) {
        final (ux, uy, w) = i(ts[k]);
        final actual = [ux, uy, w];
        final expected = c.views[k];
        if (!_sameZoomView(condition, ts[k], actual, expected)) {
          mismatches.add(
            '$label(${_number(ts[k])}): expected ${_numbers(expected)}, '
            'actual ${_numbers(actual)}',
          );
        }
      }
    }
    _expectNone(mismatches);
  });

  test('decompose gives the parts of Node.js', () {
    final mismatches = <String>[];
    for (final c in decomposeCases) {
      final m = c.matrix;
      final actual = _parts(decompose(m[0], m[1], m[2], m[3], m[4], m[5]));
      final label =
          'decompose${_numbers(m).replaceAll('[', '(').replaceAll(']', ')')}';
      // rotate and skewX come from atan2 and atan; the other parts from + - *
      // / and sqrt.
      for (var p = 0; p < _partNames.length; p++) {
        final same = p == 2 || p == 3 ? _near : _exact;
        if (!same(actual[p], c.parts[p])) {
          mismatches.add(
            '$label.${_partNames[p]}: expected ${_number(c.parts[p])}, '
            'actual ${_number(actual[p])}',
          );
        }
      }
    }
    _expectNone(mismatches);
  });

  test('interpolateTransform gives the parts of the texts of '
      'interpolateTransformSvg in Node.js', () {
    final mismatches = <String>[];
    for (final c in transformCases) {
      final a = _transformParts(c.partsA);
      final b = _transformParts(c.partsB);
      final i = interpolateTransform(a, b);
      final label =
          'interpolateTransform(${_numbers(c.partsA)}, ${_numbers(c.partsB)}) '
          '(the texts ${_quote(c.a)} and ${_quote(c.b)})';
      final results = [for (final t in ts) _parts(i(t))];
      _compareLists(mismatches, label, results, c.results, _sameNumber);
    }
    _expectNone(mismatches);
  });
}

/// The names of the six parts of a transform, in the order of the data.
const List<String> _partNames = [
  'translateX',
  'translateY',
  'rotate',
  'skewX',
  'scaleX',
  'scaleY',
];

/// The six parts of [p], in the order of the data.
List<double> _parts(TransformParts p) => [
  p.translateX,
  p.translateY,
  p.rotate,
  p.skewX,
  p.scaleX,
  p.scaleY,
];

/// The [TransformParts] of the six numbers [p] of the data.
TransformParts _transformParts(List<double> p) =>
    TransformParts(p[0], p[1], p[2], p[3], p[4], p[5]);

/// The color of the data [c].
Color _make(ColorValue c) {
  final x = c.channels;
  return switch (c.space) {
    'rgb' => Rgb(x[0], x[1], x[2], x[3]),
    'hsl' => Hsl(x[0], x[1], x[2], x[3]),
    'lab' => Lab(x[0], x[1], x[2], x[3]),
    'hcl' => Hcl(x[0], x[1], x[2], x[3]),
    'cubehelix' => Cubehelix(x[0], x[1], x[2], x[3]),
    _ => throw ArgumentError.value(c.space, 'space'),
  };
}

/// The space name of [c], as the generator writes it.
String _space(Color c) => switch (c) {
  Rgb() => 'rgb',
  Hsl() => 'hsl',
  Lab() => 'lab',
  Hcl() => 'hcl',
  Cubehelix() => 'cubehelix',
  _ => '${c.runtimeType}',
};

/// The channels of [c] in its own space, in the order of the generator.
List<double> _channels(Color c) => switch (c) {
  Rgb(:final r, :final g, :final b) => [r, g, b, c.opacity],
  Hsl(:final h, :final s, :final l) => [h, s, l, c.opacity],
  Lab(:final l, :final a, :final b) => [l, a, b, c.opacity],
  Hcl(:final h, c: final chroma, :final l) => [h, chroma, l, c.opacity],
  Cubehelix(:final h, :final s, :final l) => [h, s, l, c.opacity],
  _ => throw ArgumentError.value(c, 'c'),
};

/// Whether the conversion of a color of [space] to RGB or HSL has only
/// `+ - * /`, `%`, `min` and `max`.
bool _exactToRgb(String space) => space == 'rgb' || space == 'hsl';

/// Whether the channels of the results of [c] compare exactly: the
/// interpolator converts its colors with no `pow`, `atan2`, `sin` or `cos`,
/// and its gamma is 1 (`interpolateRgb.gamma(y)` takes `pow(x, y)` and
/// `pow(x, 1 / y)`, and the cubehelix gamma `pow(t, y)`).
bool _exactColorCase(ColorCase c) {
  bool both(bool Function(String space) test) =>
      test(c.start.space) && test(c.end.space);
  return switch (c.interpolator) {
    'interpolateRgb' || 'interpolate' => c.gamma == 1 && both(_exactToRgb),
    'interpolateHsl' || 'interpolateHslLong' => both(_exactToRgb),
    'interpolateLab' => both((s) => s == 'lab'),
    'interpolateHcl' || 'interpolateHclLong' => both((s) => s == 'hcl'),
    'interpolateCubehelix' ||
    'interpolateCubehelixLong' => c.gamma == 1 && both((s) => s == 'cubehelix'),
    _ => false,
  };
}

/// Compares the colors [actual] at each t with the expected [space],
/// [channels] and [texts]. Each call must give a new object. With [exact],
/// the channels compare by [_exact], and the text of an RGB or HSL result
/// compares exactly; else by [_near].
void _compareColors(
  List<String> mismatches,
  String label,
  List<Color> actual,
  String space,
  List<List<double>> channels,
  List<String> texts, {
  required bool exact,
}) {
  for (var k = 0; k < ts.length; k++) {
    final at = '$label(${_number(ts[k])})';
    final color = actual[k];
    if (k > 0 && identical(color, actual[k - 1])) {
      mismatches.add('$at: the same object as at the t before');
    }
    if (_space(color) != space) {
      mismatches.add('$at: expected a $space color, actual ${_space(color)}');
      continue;
    }
    _compare(
      mismatches,
      at,
      _channels(color),
      channels[k],
      exact ? _exact : _near,
    );
    final text = color.toString();
    final exactText = exact && (space == 'rgb' || space == 'hsl');
    if (exactText ? text != texts[k] : !_sameTextNear(text, texts[k])) {
      mismatches.add(
        '$at.toString(): expected ${_quote(texts[k])}, actual ${_quote(text)}',
      );
    }
  }
}

/// Adds a line to [mismatches] unless [actual] is the object [first]: an
/// array interpolator returns one list at each call, as upstream.
void _expectSameList(
  List<String> mismatches,
  String label,
  List<Object?> actual,
  List<Object?> first,
) {
  if (!identical(actual, first)) {
    mismatches.add('$label: a new list, not the list of the first call');
  }
}

/// Fails with each line of [mismatches], at most 60 of them.
void _expectNone(List<String> mismatches) {
  if (mismatches.isEmpty) return;
  const shown = 60;
  final more = mismatches.length > shown
      ? '\n… and ${mismatches.length - shown} more'
      : '';
  fail(
    '${mismatches.length} differences from Node.js:\n'
    '${mismatches.take(shown).join('\n')}$more',
  );
}

/// Adds a line to [mismatches] for each t where [actual] and [expected]
/// differ by [same].
void _compareAt(
  List<String> mismatches,
  String label,
  List<double> actual,
  List<double> expected,
  bool Function(double actual, double expected) same,
) {
  for (var k = 0; k < ts.length; k++) {
    if (!same(actual[k], expected[k])) {
      mismatches.add(
        '$label(${_number(ts[k])}): expected ${_number(expected[k])}, '
        'actual ${_number(actual[k])}',
      );
    }
  }
}

/// Adds a line to [mismatches] for each t where the list [actual] differs
/// from [expected] by [same].
void _compareLists(
  List<String> mismatches,
  String label,
  List<List<double>> actual,
  List<List<double>> expected,
  bool Function(double actual, double expected) same,
) {
  if (actual.length != expected.length) {
    mismatches.add(
      '$label: expected ${expected.length} items, actual ${actual.length}',
    );
    return;
  }
  for (var k = 0; k < actual.length; k++) {
    final at = expected.length == ts.length ? '(${_number(ts[k])})' : '[$k]';
    _compare(mismatches, '$label$at', actual[k], expected[k], same);
  }
}

/// Adds a line to [mismatches] when [actual] and [expected] differ by
/// [same].
void _compare(
  List<String> mismatches,
  String label,
  List<double> actual,
  List<double> expected,
  bool Function(double actual, double expected) same,
) {
  var equal = actual.length == expected.length;
  for (var i = 0; equal && i < actual.length; i++) {
    equal = same(actual[i], expected[i]);
  }
  if (!equal) {
    mismatches.add(
      '$label: expected ${_numbers(expected)}, actual ${_numbers(actual)}',
    );
  }
}

/// The bit-exact test: NaN equals NaN, and -0 differs from +0.
bool _exact(double actual, double expected) => expected.isNaN
    ? actual.isNaN
    : actual == expected && actual.isNegative == expected.isNegative;

/// The test of a number that a text printed: NaN equals NaN, and -0 equals
/// +0.
bool _sameNumber(double actual, double expected) =>
    expected.isNaN ? actual.isNaN : actual == expected;

/// The test of an `exp`, `log`, `atan2`, `atan`, `sin`, `cos` or `pow` path: a
/// relative 1e-12, or an absolute 1e-12 below 1. NaN and the infinities
/// compare exactly.
bool _near(double actual, double expected) {
  if (expected.isNaN) return actual.isNaN;
  if (expected.isInfinite || actual.isInfinite) return actual == expected;
  return (actual - expected).abs() <= 1e-12 * math.max(1, expected.abs());
}

/// The machine epsilon of a double, 2^-52.
const double _eps = 2.220446049250313e-16;

/// The condition of a case of `interpolateZoom` (zoom.js:20-57):
///
/// - `amplification`: `w0 / (rho2 * d1) * cosh(r0)`, the factor by which the
///   cancellation of `cosh(r0) * tanh(rho * s + r0) - sinh(r0)` (zoom.js:51)
///   multiplies a last bit of `exp`, as an error of `u`. It is 0 in the
///   special case of zoom.js:29, where `u` is `t`.
/// - `logs`: `|r0| + |r1|` (or `|log(w1 / w0)|`), the scale of the errors of
///   the logs in S.
/// - `span`: `|r1 - r0|` (or `|log(w1 / w0)|`), the difference that S
///   divides by rho.
/// - `dx` and `dy`: `|ux1 - ux0|` and `|uy1 - uy0|`, the factors of `u`.
typedef _ZoomCondition = ({
  double amplification,
  double logs,
  double span,
  double dx,
  double dy,
});

/// The [_ZoomCondition] of [c], with the lines of zoom.js in `dart:math`.
_ZoomCondition _zoomCondition(ZoomCase c) {
  final given = c.rho;
  final rho = given == null ? math.sqrt2 : math.max(1e-3, given);
  final rho2 = given == null ? 2.0 : rho * rho;
  final rho4 = given == null ? 4.0 : rho2 * rho2;
  final dx = c.p1[0] - c.p0[0];
  final dy = c.p1[1] - c.p0[1];
  final d2 = dx * dx + dy * dy;
  final w0 = c.p0[2];
  final w1 = c.p1[2];
  if (d2 < 1e-12) {
    final log = math.log(w1 / w0).abs();
    return (amplification: 0, logs: log, span: log, dx: dx.abs(), dy: dy.abs());
  }
  final d1 = math.sqrt(d2);
  final b0 = (w1 * w1 - w0 * w0 + rho4 * d2) / (2 * w0 * rho2 * d1);
  final b1 = (w1 * w1 - w0 * w0 - rho4 * d2) / (2 * w1 * rho2 * d1);
  final r0 = math.log(math.sqrt(b0 * b0 + 1) - b0);
  final r1 = math.log(math.sqrt(b1 * b1 + 1) - b1);
  final cosh = (math.exp(r0) + math.exp(-r0)) / 2;
  return (
    amplification: (w0 / (rho2 * d1) * cosh).abs(),
    logs: r0.abs() + r1.abs(),
    span: (r1 - r0).abs(),
    dx: dx.abs(),
    dy: dy.abs(),
  );
}

/// Whether the duration [actual] is [expected] within [_near] and the
/// relative error of `S = (r1 - r0) / rho`: a last bit of each log, over
/// the span.
bool _sameZoomDuration(_ZoomCondition z, double actual, double expected) {
  if (expected.isNaN) return actual.isNaN;
  if (expected.isInfinite || actual.isInfinite) return actual == expected;
  final relative = 1e-12 + (z.span == 0 ? 0 : 8 * _eps * z.logs / z.span);
  return (actual - expected).abs() <= relative * math.max(1, expected.abs());
}

/// Whether the view [actual] at [t] is [expected]: each number within
/// [_near], `ux` and `uy` also within the amplified error of `u` (16 last
/// bits for cosh, tanh, sinh and their products, and the error of `t * S`),
/// and `w` within the relative error of `t * S`.
bool _sameZoomView(
  _ZoomCondition z,
  double t,
  List<double> actual,
  List<double> expected,
) {
  final s = t.abs() * z.logs * _eps;
  final u = z.amplification * (16 * _eps + 4 * s);
  return _nearWithin(actual[0], expected[0], u * z.dx, 0) &&
      _nearWithin(actual[1], expected[1], u * z.dy, 0) &&
      _nearWithin(actual[2], expected[2], 0, 4 * s);
}

/// [_near] with an extra absolute tolerance [absolute] and an extra relative
/// tolerance [relative].
bool _nearWithin(
  double actual,
  double expected,
  double absolute,
  double relative,
) {
  if (expected.isNaN) return actual.isNaN;
  if (expected.isInfinite || actual.isInfinite) return actual == expected;
  return (actual - expected).abs() <=
      (1e-12 + relative) * math.max(1, expected.abs()) + absolute;
}

/// A number of a CSS text of d3-color.
final RegExp _cssNumber = RegExp(r'NaN|-?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?');

/// Whether the two CSS texts are equal, with their numbers compared by
/// [_near].
bool _sameTextNear(String actual, String expected) {
  if (actual == expected) return true;
  if (actual.replaceAll(_cssNumber, '#') !=
      expected.replaceAll(_cssNumber, '#')) {
    return false;
  }
  final a = _cssNumber.allMatches(actual).toList();
  final e = _cssNumber.allMatches(expected).toList();
  for (var i = 0; i < a.length; i++) {
    if (!_near(double.parse(a[i][0]!), double.parse(e[i][0]!))) return false;
  }
  return true;
}

/// A color of the data as the constructor call of its class.
String _colorText(ColorValue c) {
  final name = switch (c.space) {
    'rgb' => 'Rgb',
    'hsl' => 'Hsl',
    'lab' => 'Lab',
    'hcl' => 'Hcl',
    'cubehelix' => 'Cubehelix',
    _ => c.space,
  };
  return '$name(${c.channels.map(_number).join(', ')})';
}

/// A number of a message, with -0 and NaN by name.
String _number(double x) => x == 0 && x.isNegative ? '-0.0' : '$x';

/// A list of numbers of a message.
String _numbers(List<double> xs) => '[${xs.map(_number).join(', ')}]';

/// A text of a message in quotes.
String _quote(String s) => "'$s'";
