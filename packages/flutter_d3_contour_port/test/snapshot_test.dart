// Ported from d3-contour v4.0.2 test/snapshot.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart' show extentBy, nice, ticks;
import 'package:flutter_d3_contour_port/d3_contour.dart';
import 'package:test/test.dart';

import 'data/faithful_data.dart';

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
  // DIVERGES(d3-contour): harness-contour-snapshots, SVG DOM snapshot
  // rendering requires d3-axis/d3-geo/d3-scale/d3-selection/jsdom; the
  // underlying contourDensity geometry for both snapshot scenarios is verified
  // directly on all platforms including web.
  test('snapshot faithfulContours', () {
    const width = 960.0;
    const height = 500.0;
    final x = _linearRangeRound(
      extentBy(faithfulData, (d) => d.waiting)!,
      40,
      width - 30,
    );
    final y = _linearRangeRound(
      extentBy(faithfulData, (d) => d.eruptions)!,
      height - 30,
      20,
    );
    final result = contourDensity<FaithfulRow>(
      x: (d) => x(d.waiting),
      y: (d) => y(d.eruptions),
      size: (width, height),
      bandwidth: 30,
      thresholdsCount: 30,
    )(faithfulData);

    expect(result, hasLength(29));
    expect(result.first.value, closeTo(0.0002, 1e-12));
    expect(result.last.value, closeTo(0.0058, 1e-12));
    for (final c in result) {
      expect(c.coordinates, isNotEmpty);
      for (final poly in c.coordinates) {
        for (final ring in poly) {
          expect(ring.first, ring.last);
        }
      }
    }
  });

  test('snapshot faithfulContour', () {
    const width = 960.0;
    const height = 500.0;
    final x = _linearRangeRound(
      extentBy(faithfulData, (d) => d.waiting)!,
      40,
      width - 30,
    );
    final y = _linearRangeRound(
      extentBy(faithfulData, (d) => d.eruptions)!,
      height - 30,
      20,
    );
    final contour = contourDensity<FaithfulRow>(
      x: (d) => x(d.waiting),
      y: (d) => y(d.eruptions),
      size: (width, height),
      bandwidth: 30,
    ).contours(faithfulData);

    final thresholds = ticks(0, contour.max, 30).sublist(1);
    expect(thresholds, hasLength(29));
    for (final t in thresholds) {
      final c = contour(t);
      expect(c.value, t);
      expect(c.coordinates, isNotEmpty);
      for (final poly in c.coordinates) {
        for (final ring in poly) {
          expect(ring.first, ring.last);
        }
      }
    }
  });
}
