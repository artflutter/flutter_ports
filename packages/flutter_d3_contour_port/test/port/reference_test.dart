// Original code, not ported from d3-contour: Node.js reference parity tests.

import 'dart:typed_data';

import 'package:flutter_d3_array_port/d3_array.dart' show extentBy, nice;
import 'package:flutter_d3_contour_port/d3_contour.dart';
import 'package:test/test.dart';

import '../data/faithful_data.dart';
import 'd3_contour_reference.dart';

void _expectContourClose(
  ContourMultiPolygon actual,
  RefContour expected,
  double tol,
) {
  expect(actual.value, closeTo(expected.value, 1e-12));
  expect(actual.coordinates.length, expected.coordinates.length);
  for (var p = 0; p < expected.coordinates.length; ++p) {
    final aPoly = actual.coordinates[p];
    final ePoly = expected.coordinates[p];
    expect(aPoly.length, ePoly.length, reason: 'polygon $p ring count');
    for (var r = 0; r < ePoly.length; ++r) {
      final aRing = aPoly[r];
      final eRing = ePoly[r];
      expect(aRing.length, eRing.length, reason: 'polygon $p ring $r length');
      for (var i = 0; i < eRing.length; ++i) {
        expect(
          aRing[i].$1,
          closeTo(eRing[i].$1, tol),
          reason: 'p=$p r=$r i=$i x',
        );
        expect(
          aRing[i].$2,
          closeTo(eRing[i].$2, tol),
          reason: 'p=$p r=$r i=$i y',
        );
      }
    }
  }
}

void _expectSummaryClose(
  ContourMultiPolygon actual,
  RefContourSummary expected, {
  double coordTol = 1e-2,
}) {
  expect(actual.value, closeTo(expected.value, 1e-12));
  expect(actual.coordinates.length, expected.polygons);
  var rings = 0;
  var points = 0;
  var sumX = 0.0;
  var sumY = 0.0;
  for (final poly in actual.coordinates) {
    rings += poly.length;
    for (final ring in poly) {
      points += ring.length;
      for (final (x, y) in ring) {
        sumX += x;
        sumY += y;
      }
    }
  }
  expect(rings, expected.rings);
  expect(points, expected.points);
  expect(sumX, closeTo(expected.sumX, coordTol));
  expect(sumY, closeTo(expected.sumY, coordTol));
}

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

void main() {
  test('smooth contours on 24x18 multi-peak grid match Node.js v4.0.2', () {
    final gen = contours(size: (refPeaksW, refPeaksH), thresholdsCount: 8);
    final actual = gen(Float64List.fromList(refPeaksGrid));
    expect(actual.length, refPeaksSmooth.length);
    for (var i = 0; i < refPeaksSmooth.length; ++i) {
      _expectContourClose(actual[i], refPeaksSmooth[i], 1e-12);
    }
  });

  test('unsmoothed contours on 24x18 grid match Node.js v4.0.2 exactly', () {
    final gen = contours(
      size: (refPeaksW, refPeaksH),
      smooth: false,
      thresholdsValues: <double>[20, 50, 80],
    );
    final actual = gen(refPeaksGrid);
    expect(actual.length, refPeaksRaw.length);
    for (var i = 0; i < refPeaksRaw.length; ++i) {
      _expectContourClose(actual[i], refPeaksRaw[i], 0);
    }
  });

  test('saddle & NaN/Infinity grid contour matches Node.js v4.0.2', () {
    final gen = contours(size: (refSpecialW, refSpecialH));
    final actual = gen.contour(Float64List.fromList(refSpecialGrid), 0.4);
    _expectContourClose(actual, refSpecialContour, 1e-12);
  });

  test('contourDensity on faithful.tsv matches Node.js v4.0.2', () {
    const width = 960.0;
    const height = 500.0;
    final wExt = extentBy(faithfulData, (d) => d.waiting)!;
    final eExt = extentBy(faithfulData, (d) => d.eruptions)!;
    final (wd0, wd1) = nice(wExt.$1, wExt.$2, 10);
    final (ed0, ed1) = nice(eExt.$1, eExt.$2, 10);
    double sx(double v) =>
        _jsRound(40 + ((v - wd0) / (wd1 - wd0)) * (width - 30 - 40));
    double sy(double v) => _jsRound(
      height - 30 + ((v - ed0) / (ed1 - ed0)) * (20 - (height - 30)),
    );

    final density = contourDensity<FaithfulRow>(
      x: (d) => sx(d.waiting),
      y: (d) => sy(d.eruptions),
      size: (width, height),
      bandwidth: 30,
      thresholdsCount: 10,
    );

    final actual = density(faithfulData);
    expect(actual.length, refFaithfulContoursSummary.length);
    for (var i = 0; i < refFaithfulContoursSummary.length; ++i) {
      _expectSummaryClose(actual[i], refFaithfulContoursSummary[i]);
    }

    final evaluator = density.contours(faithfulData);
    expect(evaluator.max, closeTo(refFaithfulMax, 1e-7));
    _expectSummaryClose(evaluator(0.0025), refFaithfulSingleSummary);
  });

  test('weighted contourDensity with NaN weights matches Node.js v4.0.2', () {
    final density = contourDensity<(double, double, double)>(
      x: (d) => d.$1,
      y: (d) => d.$2,
      weight: (d) => d.$3,
      size: (200, 180),
      cellSize: 8,
      bandwidth: 18,
      thresholdsCount: 6,
    );
    final actual = density(refWeightedPoints);
    expect(actual.length, refWeightedDensitySummary.length);
    for (var i = 0; i < refWeightedDensitySummary.length; ++i) {
      _expectSummaryClose(actual[i], refWeightedDensitySummary[i]);
    }
  });

  test('toGeoJson produces typed GeoJSON MultiPolygon map', () {
    final c = contours(size: (4, 4))
        .contour(<double>[0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0], 0.5);
    final json = c.toGeoJson();
    expect(json['type'], 'MultiPolygon');
    expect(json['value'], 0.5);
    final coords = json['coordinates']! as List<List<List<List<double>>>>;
    expect(coords, hasLength(1));
    expect(coords[0], hasLength(1));
    expect(coords[0][0].first, coords[0][0].last);
  });
}
