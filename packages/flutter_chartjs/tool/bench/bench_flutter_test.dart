// Original code, not ported from Chart.js: the benchmarks of non-pure helpers.
@TestOn('vm')
library;

// `helpers.extras` imports `package:flutter`, so `dart run` and the web
// compilers do not build it. `flutter test` runs this file on the VM with
// JIT and assertions enabled:
//
//   cd packages/flutter_chartjs && \
//     flutter test tool/bench/bench_flutter_test.dart --reporter=silent
//
// `--dart-define=filter=<regexp>` and the other defines of
// `src/harness.dart` apply.

import 'package:flutter_chartjs/src/helpers/helpers.extras.dart';
import 'package:flutter_chartjs/src/types/index.dart';
import 'package:flutter_test/flutter_test.dart';

import 'src/harness.dart';

/// A scale `{axis, getUserBounds, getPixelForValue}`.
final class _Scale implements Scale {
  _Scale(this.axis, this.bounds);

  @override
  final String axis;

  final ({double min, double max, bool minDefined, bool maxDefined}) bounds;

  @override
  ({double min, double max, bool minDefined, bool maxDefined})
  getUserBounds() => bounds;

  @override
  double getPixelForValue(double value, [double? index]) => value * 3;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A point element `{x, y}`. The control points are NaN, which stands for
/// JS `undefined` (`SplinePoint`).
final class _Point implements PointElement {
  _Point(this.x, this.y);

  @override
  final double x;

  @override
  final double y;

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
}

/// A dataset meta object.
final class _Meta implements ChartMeta {
  _Meta(this.iScale, this.vScale, this.parsed);

  @override
  bool get sorted => true;

  @override
  final Scale? iScale;

  @override
  final Scale? vScale;

  @override
  final List<Map<String, Object?>> parsed;

  @override
  Element? get dataset => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<BenchCase> _extrasCases() => [
  BenchCase(
    'data',
    'extras/visible_points_100k',
    () {
      const count = 100000;
      final meta = _Meta(
        _Scale('x', (
          min: 40000.5,
          max: 60000.5,
          minDefined: true,
          maxDefined: true,
        )),
        _Scale('y', (
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
          acc += getStartAndCountOfVisiblePoints(
            meta,
            points,
            false,
          ).count.toInt();
        }
        return acc;
      };
    },
    per: '_getStartAndCountOfVisiblePoints, 100k sorted points, zoomed',
  ),
];

void main() {
  test('bench', () {
    runBench(
      _extrasCases(),
      parseSettings(const ['--target=flutter-test-jit']),
    );
  }, timeout: Timeout.none);
}
