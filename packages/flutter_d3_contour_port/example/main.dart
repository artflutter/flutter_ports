// Original code, not ported from d3-contour: package example.

// Example prints results to stdout.
// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:flutter_d3_contour_port/flutter_d3_contour_port.dart';

void main() {
  // 1. Marching-squares contours on a 5×5 scalar peak grid.
  const n = 5;
  final grid = Float64List(n * n);
  for (var y = 0; y < n; ++y) {
    for (var x = 0; x < n; ++x) {
      final dx = x - 2.0;
      final dy = y - 2.0;
      grid[y * n + x] = 10.0 - (dx * dx + dy * dy);
    }
  }
  final iso = contours(size: (n, n), thresholdsValues: <double>[4, 7, 9]);
  for (final mp in iso(grid)) {
    print('Contour value=${mp.value}: ${mp.coordinates.length} polygon(s)');
  }

  // 2. 2D kernel density estimation on typed point records.
  final density = contourDensityPoints(
    size: (200, 200),
    bandwidth: 15,
    thresholdsCount: 5,
  );
  final levels = density(const <(double, double)>[
    (60, 70),
    (64, 72),
    (58, 68),
    (140, 130),
    (142, 128),
  ]);
  print('Density contours: ${levels.length} level(s)');
}
