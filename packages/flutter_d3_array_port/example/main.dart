// Original code, not ported from d3-array: package example.

// Example prints computed summaries.
// ignore_for_file: avoid_print

import 'package:flutter_d3_array_port/d3_array.dart';

void main() {
  final sample = <double>[12, 15, 18, 22, 22, 25, 29, 31, 35, 42, 48, 60];
  print('Extent:    ${extent(sample)}');
  print('Mean:      ${mean(sample)?.toStringAsFixed(2)}');
  print('Median:    ${median(sample)}');
  print('Deviation: ${deviation(sample)?.toStringAsFixed(2)}');
  print(
    'fsum:      ${fsum([0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1])}',
  );
  print('Ticks:     ${ticks(0, 60, 6)}');

  final bins = bin<double>(thresholdsCount: thresholdFreedmanDiaconis)(sample);
  for (final b in bins) {
    print('Bin [${b.x0}, ${b.x1}): count=${b.length}');
  }

  final records = <(String, String, double)>[
    ('North', 'Q1', 120),
    ('North', 'Q2', 180),
    ('South', 'Q1', 90),
    ('South', 'Q2', 150),
  ];
  final byRegion = rollup<(String, String, double), String, double>(
    records,
    (rows) => sumBy(rows, (r) => r.$3),
    (r) => r.$1,
  );
  print('Rollup:    $byRegion');
}
