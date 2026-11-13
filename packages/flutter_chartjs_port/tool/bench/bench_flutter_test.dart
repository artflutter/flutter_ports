// Original code, not ported from Chart.js: the benchmarks of non-pure helpers.
@TestOn('vm')
library;

// Runs the core micro-benchmarks and helpers.extras through Flutter.
//
//   cd packages/flutter_chartjs_port && \
//     flutter test tool/bench/bench_flutter_test.dart --reporter=silent
//
// `--dart-define=filter=<regexp>` and the other defines of
// `src/harness.dart` apply. These are JIT measurements with assertions enabled.

import 'package:flutter_chartjs_port/src/helpers/helpers.extras.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bench.dart' as core;
import 'src/harness.dart';

/// A scale `{axis, getUserBounds, getPixelForValue}`.
final class _Scale(
  @override final ScaleAxis axis,
  final ({double min, double max, bool minDefined, bool maxDefined}) bounds,
) implements Scale {
  @override
  ({double min, double max, bool minDefined, bool maxDefined})
  getUserBounds() => bounds;

  @override
  double getPixelForValue(Object? value, [int? index]) => jsToNumber(value) * 3;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A point element `{x, y}`. The control points are NaN, which stands for
/// JS `undefined` (`SplinePoint`).
final class _Point(@override final double x, @override final double y)
    implements PointElement {
  @override
  Map<String, Object?>? get options => null;

  @override
  bool? get skip => null;

  @override
  bool? get stop => null;

  @override
  double cp1x = double.nan;

  @override
  double cp1y = double.nan;

  @override
  double cp2x = double.nan;

  @override
  double cp2y = double.nan;

  // The members of Chart.js ADR 0028 that this test does not read.
  @override
  bool get active => false;

  @override
  Object? get hidden => undefined;

  @override
  double size([Object? options]) => throw UnsupportedError('size');
}

/// A dataset meta object.
final class _Meta(
  @override final Scale? iScale,
  @override final Scale? vScale,
  @override final List<Map<String, Object?>> parsed,
) implements ChartMeta {
  @override
  bool get sorted => true;

  @override
  Element? get dataset => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<BenchCase> _extrasCases() => [
  BenchCase('data', 'extras/visible_points_100k', () {
    const count = 100000;
    final meta = _Meta(
      _Scale(const XAxis(), (
        min: 40000.5,
        max: 60000.5,
        minDefined: true,
        maxDefined: true,
      )),
      _Scale(const YAxis(), (
        min: double.negativeInfinity,
        max: double.infinity,
        minDefined: false,
        maxDefined: false,
      )),
      [
        for (var i = 0; i < count; i++)
          <String, Object?>{'x': i.toDouble(), 'y': (i % 31).toDouble()},
      ],
    );
    final points = <PointElement>[
      for (var i = 0; i < count; i++) _Point(i * 3.0, (i % 31).toDouble()),
    ];
    return (n) {
      var acc = 0;
      for (var i = 0; i < n; i++) {
        acc += getStartAndCountOfVisiblePoints(meta, points, false).count;
      }
      return acc;
    };
  }, per: '_getStartAndCountOfVisiblePoints, 100k sorted points, zoomed'),
];

void main() {
  test('bench', () {
    core.main(const ['--target=flutter-test-jit']);
    runBench(
      _extrasCases(),
      parseSettings(const ['--target=flutter-test-jit']),
    );
  }, timeout: Timeout.none);
}
