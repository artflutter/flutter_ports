// Ported from d3-contour v4.0.2 test/density-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart' show extentBy, nice, ticks;
import 'package:flutter_d3_contour_port/d3_contour.dart';
import 'package:test/test.dart';

import 'asserts.dart';
import 'data/faithful_data.dart';

/// Port of `d3-polygon`'s `polygonCentroid` for ring verification.
(double, double) _polygonCentroid(List<(double, double)> polygon) {
  final n = polygon.length;
  var x = 0.0;
  var y = 0.0;
  var b = polygon[n - 1];
  var k = 0.0;
  for (var i = 0; i < n; ++i) {
    final a = b;
    b = polygon[i];
    final c = a.$1 * b.$2 - b.$1 * a.$2;
    k += c;
    x += (a.$1 + b.$1) * c;
    y += (a.$2 + b.$2) * c;
  }
  k *= 3;
  return (x / k, y / k);
}

/// JavaScript `Math.round` (halves toward `+Infinity`) matching
/// `d3-scale`'s `scaleLinear().rangeRound(...)`.
double _jsRound(double x) {
  if (!x.isFinite || x == 0) return x;
  if (x > 0) return x.roundToDouble();
  final f = x.floorToDouble();
  if (x - f >= 0.5) {
    final r = f + 1.0;
    return r == 0 ? 0.0 : r;
  }
  return f;
}

double Function(double) _linearRangeRound(
  (double, double) domain,
  double r0,
  double r1,
) {
  final (d0, d1) = nice(domain.$1, domain.$2, 10);
  final span = d1 - d0;
  final rSpan = r1 - r0;
  return (double v) => _jsRound(r0 + ((v - d0) / span) * rSpan);
}

void main() {
  test('density.size(…) validates the specified size', () {
    expect((contourDensityPoints()..size = (1, 2)).size, (1.0, 2.0));
    expect((contourDensityPoints()..size = (0, 0)).size, (0.0, 0.0));
    expect((contourDensityPoints()..size = (1.5, 2.5)).size, (1.5, 2.5));
    expect(
      () => contourDensityPoints()..size = (0, -1),
      throwsA(
        isA<RangeError>().having(
          (e) => e.message,
          'message',
          contains('invalid size'),
        ),
      ),
    );
  });

  test('contourDensity(data) returns the expected result for empty data', () {
    final c = contourDensityPoints();
    expect(c(const <(double, double)>[]), isEmpty);
  });

  test('contourDensity(data) returns contours centered on a point', () {
    final c = contourDensityPoints(thresholdsValues: <double>[0.00001, 0.0001]);
    for (final p in const <(double, double)>[(100, 100), (100.5, 102)]) {
      final contour = c(<(double, double)>[p]);
      expect(contour, hasLength(2));
      for (final b in contour) {
        final a = _polygonCentroid(b.coordinates[0][0]);
        assertInDelta(a.$1, p.$1, 0.1);
        assertInDelta(a.$2, p.$2, 0.1);
      }
    }
  });

  test('contourDensity.thresholds(values[])(data) returns contours for the '
      'given values', () {
    const points = <(double, double)>[(1, 0), (0, 1), (1, 1)];
    final c = contourDensityPoints();
    final c1 = c(points);
    final values1 = c1.map((d) => d.value).toList();
    final c2 = (c..thresholdsValues = values1)(points);
    final values2 = c2.map((d) => d.value).toList();
    expect(values2, values1);
  });

  test('contourDensity.weight(…) accepts NaN weights', () {
    const points = <(double, double, double)>[
      (1, 0, 1),
      (0, 1, -2),
      (1, 1, double.nan),
    ];
    final c = contourDensity<(double, double, double)>(
      x: (d) => d.$1,
      y: (d) => d.$2,
      weight: (d) => d.$3,
    )(points);
    expect(c, hasLength(24));
  });

  test('contourDensity.thresholds(values[])(data) returns contours for the '
      'given values at a different cellSize', () {
    const points = <(double, double)>[(1, 0), (0, 1), (1, 1)];
    final c = contourDensityPoints(cellSize: 16);
    final c1 = c(points);
    final values1 = c1.map((d) => d.value).toList();
    final c2 = (c..thresholdsValues = values1)(points);
    final values2 = c2.map((d) => d.value).toList();
    expect(values2, values1);
  });

  test('contourDensity(data) returns nice default thresholds', () {
    const width = 960.0;
    const height = 500.0;
    const marginTop = 20.0;
    const marginRight = 30.0;
    const marginBottom = 30.0;
    const marginLeft = 40.0;

    final x = _linearRangeRound(
      extentBy(faithfulData, (d) => d.waiting)!,
      marginLeft,
      width - marginRight,
    );
    final y = _linearRangeRound(
      extentBy(faithfulData, (d) => d.eruptions)!,
      height - marginBottom,
      marginTop,
    );

    final contour = contourDensity<FaithfulRow>(
      x: (d) => x(d.waiting),
      y: (d) => y(d.eruptions),
      size: (width, height),
      bandwidth: 30,
    )(faithfulData);

    expect(contour.map((c) => c.value).toList(), ticks(0.0002, 0.0059, 30));
  });

  test(
    'contourDensity.contours(data) preserves the specified threshold exactly',
    () {
      const width = 960.0;
      const height = 500.0;
      const marginTop = 20.0;
      const marginRight = 30.0;
      const marginBottom = 30.0;
      const marginLeft = 40.0;

      final x = _linearRangeRound(
        extentBy(faithfulData, (d) => d.waiting)!,
        marginLeft,
        width - marginRight,
      );
      final y = _linearRangeRound(
        extentBy(faithfulData, (d) => d.eruptions)!,
        height - marginBottom,
        marginTop,
      );

      final contour = contourDensity<FaithfulRow>(
        x: (d) => x(d.waiting),
        y: (d) => y(d.eruptions),
        size: (width, height),
        bandwidth: 30,
      ).contours(faithfulData);

      for (final value in ticks(0.0002, 0.006, 30)) {
        expect(contour(value).value, value);
      }
    },
  );
}
