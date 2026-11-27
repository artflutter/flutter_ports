// Original code, not ported from d3-array: twin tests for faster forms.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

double _refSum(Iterable<num?> values) {
  var s = 0.0;
  for (final v in values) {
    if (v != null && v != 0 && v == v) s += v.toDouble();
  }
  return s;
}

double? _refMean(Iterable<num?> values) {
  var c = 0;
  var s = 0.0;
  for (final v in values) {
    if (v != null && v >= v) {
      ++c;
      s += v.toDouble();
    }
  }
  return c > 0 ? s / c : null;
}

double? _refVariance(Iterable<num?> values) {
  var c = 0;
  var m = 0.0;
  var s = 0.0;
  for (final v in values) {
    if (v != null && v >= v) {
      final d = v.toDouble() - m;
      m += d / ++c;
      s += d * (v.toDouble() - m);
    }
  }
  return c > 1 ? s / (c - 1) : null;
}

void _refBlurPass(
  List<double> target,
  List<double> source,
  int start,
  int stop,
  int step,
  double radius,
) {
  final r0 = radius.floor();
  final last = stop - step;
  if (last < start) return;
  final w = 2.0 * radius + 1.0;
  if (r0 == radius) {
    var sum = r0 * source[start];
    final s = step * r0;
    for (var i = start; i < start + s; i += step) {
      sum += source[math.min(last, i)];
    }
    for (var i = start; i <= last; i += step) {
      sum += source[math.min(last, i + s)];
      target[i] = sum / w;
      sum -= source[math.max(start, i - s)];
    }
  } else {
    final t = radius - r0;
    var sum = r0 * source[start];
    final s0 = step * r0;
    final s1 = s0 + step;
    for (var i = start; i < start + s0; i += step) {
      sum += source[math.min(last, i)];
    }
    for (var i = start; i <= last; i += step) {
      sum += source[math.min(last, i + s0)];
      target[i] =
          (sum +
              t *
                  (source[math.max(start, i - s1)] +
                      source[math.min(last, i + s1)])) /
          w;
      sum -= source[math.max(start, i - s0)];
    }
  }
}

List<double> _refBlur1(List<double> input, double r) {
  final v = List<double>.of(input);
  if (v.isEmpty || r == 0) return v;
  final temp = List<double>.of(v);
  _refBlurPass(v, temp, 0, v.length, 1, r);
  _refBlurPass(temp, v, 0, v.length, 1, r);
  _refBlurPass(v, temp, 0, v.length, 1, r);
  return v;
}

void main() {
  test(
    'Float64List, List<double>, List<int>, and Iterable fast paths match',
    () {
      final ints = <int>[3, -7, 15, 0, 42, -12, 8, 8, 99, -1];
      final doubles = <double>[for (final x in ints) x.toDouble()];
      final f64 = Float64List.fromList(doubles);
      final nums = <num>[...ints];
      final iter = doubles.map((x) => x);

      expect(count(f64), count(iter));
      expect(count(doubles), count(iter));
      expect(count(ints), count(iter));
      expect(count(nums), count(iter));

      expect(sum(f64), _refSum(iter));
      expect(sum(doubles), _refSum(iter));
      expect(sum(ints), _refSum(iter));
      expect(sum(nums), _refSum(iter));

      expect(fsum(f64), fsum(iter));
      expect(fsum(doubles), fsum(iter));
      expect(fsum(ints), fsum(iter));
      expect(fsum(nums), fsum(iter));

      expect(cumsum(f64), cumsum(iter));
      expect(cumsum(doubles), cumsum(iter));
      expect(fcumsum(f64), fcumsum(iter));
      expect(fcumsum(doubles), fcumsum(iter));

      expect(mean(f64), _refMean(iter));
      expect(mean(doubles), _refMean(iter));
      expect(mean(ints), _refMean(iter));
      expect(mean(nums), _refMean(iter));

      expect(variance(f64), _refVariance(iter));
      expect(variance(doubles), _refVariance(iter));
      expect(variance(ints), _refVariance(iter));

      expect(min(f64), min(iter));
      expect(min(doubles), min(iter));
      expect(min(ints), -12);
      expect(max(f64), max(iter));
      expect(max(doubles), max(iter));
      expect(max(ints), 99);
      expect(extent(f64), extent(iter));
      expect(extent(doubles), extent(iter));
      expect(extent(ints), (-12, 99));

      for (final p in <double>[0, 0.25, 0.5, 0.75, 1]) {
        expect(quantile(f64, p), quantile(iter, p));
        expect(quantile(doubles, p), quantile(iter, p));
        expect(quantile(ints, p), quantile(iter, p));
      }

      expect(sort(f64), sort(iter));
      expect(sort(doubles), sort(iter));
      expect(sort(ints), <int>[-12, -7, -1, 0, 3, 8, 8, 15, 42, 99]);
    },
  );

  test('Float64List and List<double> fast paths handle NaNs identically', () {
    final doubles = <double>[double.nan, 4.5, double.nan, -2.5, 10, double.nan];
    final f64 = Float64List.fromList(doubles);
    final iter = doubles.map((x) => x);

    expect(count(f64), 3);
    expect(count(doubles), 3);
    expect(sum(f64), sum(iter));
    expect(fsum(f64), fsum(iter));
    expect(mean(f64), mean(iter));
    expect(variance(f64), variance(iter));
    expect(min(f64), -2.5);
    expect(max(f64), 10.0);
    expect(extent(f64), (-2.5, 10.0));
    expect(minIndex(f64), 3);
    expect(maxIndex(f64), 4);
    expect(quantile(f64, 0.5), quantile(iter, 0.5));
  });

  test(
    'bisect fast paths match generic bisector across Float64List/double/int',
    () {
      final ints = <int>[1, 2, 2, 4, 7, 10, 15];
      final doubles = <double>[for (final x in ints) x.toDouble()];
      final f64 = Float64List.fromList(doubles);
      final gen = bisector<double, double>((d) => d);

      for (final x in <double>[-5, 1, 2, 3, 7, 15, 20, double.nan]) {
        expect(bisectLeft(f64, x), gen.left(doubles, x));
        expect(bisectRight(f64, x), gen.right(doubles, x));
        expect(bisectLeft(doubles, x), gen.left(doubles, x));
        expect(bisectRight(doubles, x), gen.right(doubles, x));
      }
      for (final x in <int>[-5, 1, 2, 3, 7, 15, 20]) {
        expect(bisectLeft(ints, x), bisectLeft(doubles, x.toDouble()));
        expect(bisectRight(ints, x), bisectRight(doubles, x.toDouble()));
      }
    },
  );

  test(
    'branch-split blur matches literal upstream blur across lengths & radii',
    () {
      for (final n in <int>[1, 2, 3, 5, 11, 32, 100]) {
        final input = List<double>.generate(
          n,
          (i) => (i * 17 % 23).toDouble() - 5.0,
        );
        for (final r in <double>[0, 0.25, 0.5, 1, 1.5, 2, 3, 4.75, 10]) {
          final actual = blur(List<double>.of(input), r);
          final expected = _refBlur1(input, r);
          expect(actual.length, expected.length);
          for (var i = 0; i < n; ++i) {
            expect(actual[i], closeTo(expected[i], 1e-12));
          }
        }
      }
    },
  );

  test(
    'quickselectFloat64NoNaN matches sorted order on large arrays (>600)',
    () {
      final rng = math.Random(12345);
      final data = Float64List.fromList(
        List<double>.generate(1500, (_) => rng.nextDouble() * 1000 - 500),
      );
      final sorted = List<double>.of(data)..sort();
      for (final k in <int>[0, 1, 17, 375, 749, 750, 1125, 1498, 1499]) {
        final copy = Float64List.fromList(data);
        quickselect(copy, k);
        expect(copy[k], sorted[k]);
        for (var i = 0; i < k; ++i) {
          expect(copy[i], lessThanOrEqualTo(copy[k]));
        }
        for (var i = k + 1; i < copy.length; ++i) {
          expect(copy[i], greaterThanOrEqualTo(copy[k]));
        }
      }
    },
  );
}
