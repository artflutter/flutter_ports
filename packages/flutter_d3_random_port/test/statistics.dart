// Ported from d3-random v3.0.1 test/statistics.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_array_port/d3_array.dart';

double kurtosis(List<num> numbers) {
  final m = mean(numbers)!;
  var sum4 = 0.0;
  var sum2 = 0.0;
  final n = numbers.length;

  for (var i = 0; i < n; ++i) {
    final v = numbers[i] - m;
    sum2 += v * v;
    sum4 += v * v * v * v;
  }

  return (1.0 / n) * sum4 / math.pow((1.0 / n) * sum2, 2) - 3.0;
}

double skewness(List<num> numbers) {
  final m = mean(numbers)!;
  var sum3 = 0.0;
  var sum2 = 0.0;
  final n = numbers.length;

  for (var i = 0; i < n; ++i) {
    final v = numbers[i] - m;
    sum2 += v * v;
    sum3 += v * v * v;
  }

  return (1.0 / n) * sum3 / math.pow((1.0 / (n - 1)) * sum2, 3.0 / 2.0);
}
