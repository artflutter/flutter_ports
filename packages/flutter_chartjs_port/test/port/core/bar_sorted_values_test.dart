// Original code, not ported from Chart.js: sorted bar-value parity tests.

import 'package:flutter_chartjs_port/src/core/bar_sorted_values.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart'
    show arrayUnique;
import 'package:test/test.dart';

void main() {
  final cases = <List<double>>[
    [],
    [1],
    [-0.0],
    [0],
    [-1, -0.0, 2],
    [1, 1],
    [-0.0, 0],
    [0, -0.0],
    [-1, -0.0, 0, 2],
    [-2, -2, -0.0, 3],
    [-0.0, 1, 1],
    [-3, -3, -2, -1, -1, 0, 2, 2],
    [-double.maxFinite, -double.maxFinite, 0, double.maxFinite],
  ];
  for (var i = 0; i < cases.length; i++) {
    test('matches Set values, signed zeros and identity, case $i', () {
      final input = List<double>.of(cases[i]);
      final before = List<double>.of(input);
      final expected = arrayUnique(input);
      final actual = uniqueSortedBarValues(input)!;
      expect(actual, expected);
      expect(identical(actual, input), identical(expected, input));
      for (var j = 0; j < actual.length; j++) {
        expect(actual[j].isNegative, expected[j].isNegative);
      }
      expect(input, before);
      for (var j = 0; j < input.length; j++) {
        expect(input[j].isNegative, before[j].isNegative);
      }
    });
  }

  test('unsorted or nonfinite inputs decline without mutation', () {
    for (final values in <List<double>>[
      [1, 0],
      [0, 1, 1, -1],
      [double.nan],
      [0, double.nan],
      [double.negativeInfinity, 0],
      [0, double.infinity],
    ]) {
      final before = [for (final value in values) value.toString()];
      expect(uniqueSortedBarValues(values), isNull);
      expect([for (final value in values) value.toString()], before);
    }
  });

  test('duplicate result stays growable and never aliases input', () {
    const input = <double>[1, 1, 2];
    final result = uniqueSortedBarValues(input)!..add(3);
    expect(result, [1, 2, 3]);
    expect(input, [1, 1, 2]);
  });

  test('dense native indexes retain the original list', () {
    final input = List<double>.generate(20000, (i) => i.toDouble());
    expect(uniqueSortedBarValues(input), same(input));
  });
}
