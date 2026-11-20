// Ported from Chart.js v4.6.1 test/specs/plugin.decimation.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;

// `Chart` is the class of core.controller.dart. Each case builds a chart, so
// the file runs on the VM, and each case is a `testWidgets` case with the
// harness of Chart.js ADR 0022, section 2.
//
// The spec forms:
// - `chart.data.datasets[0].data` is read with `jsGet`. The decimation
//   plugin keeps `data` as a plain entry with the value of the upstream
//   getter (differences.md row adapt-decimation-data-accessor).
// - `originalData` is a function: each case gets a new List of new item
//   DataPoints. Upstream shares the one array between the cases. No case
//   changes
//   the array or its items, so the results are the same.
// - `toBe` of a number is `expect` with the number.
// - The first case keeps the upstream `scales` key at the root of the
//   config, where Chart.js does not read it.

/// The data of :6-16.
List<DataPoint> _originalData() => [
  for (var i = 0; i < 10; i++) DataPoint(i.toDouble(), i.toDouble()),
];

/// `chart.data.datasets[0].data`.
List<Object?> _data(Chart chart) =>
    jsGet((jsGet(chart.data, 'datasets')! as List<Object?>)[0], 'data')!
        as List<Object?>;

/// The acquireChart options of a canvas and a wrapper of [width] x
/// [height].
AnyObject _canvas(int width, int height) => <String, Object?>{
  'canvas': <String, Object?>{'height': height, 'width': width},
  'wrapper': <String, Object?>{'height': height, 'width': width},
};

void main() {
  group('Plugin.decimation', () {
    group('auto', fixture.specs('plugin.decimation'));

    group('lttb', () {
      testWidgets('should draw all element if sample is greater than data '
          'based on canvas width', (tester) async {
        final chart = acquireChartRoot(
          (ChartConfigLowering(
              ChartConfig(
                type: ChartKind.line,
                datasets: [
                  LineDataset(points: _originalData(), label: 'dataset1'),
                ],
                extra: const {
                  'plugins': {
                    'decimation': <String, Object?>{
                      'enabled': true,
                      'algorithm': LttbDecimationAlgorithm(),
                      'samples': 100,
                    },
                  },
                },
              ),
            ).lower()
            ..['scales'] = <String, Object?>{
              'x': <String, Object?>{'type': 'linear', 'min': 0, 'max': 9},
            }),
          _canvas(1, 1),
        );

        expect(_data(chart).length, 10);
      });

      testWidgets('should draw the specified number of elements based on '
          'canvas width', (tester) async {
        final chart = acquireChartRoot(
          ChartConfigLowering(
            ChartConfig(
              type: ChartKind.line,
              datasets: [
                LineDataset(points: _originalData(), label: 'dataset1'),
              ],
              scales: const {'x': LinearAxis(min: 0, max: 9)},
              extra: const {
                'parsing': false,
                'plugins': {
                  'decimation': <String, Object?>{
                    'enabled': true,
                    'algorithm': LttbDecimationAlgorithm(),
                    'samples': 7,
                  },
                },
              },
            ),
          ).lower(),
          _canvas(1, 1),
        );

        expect(_data(chart).length, 7);
      });

      testWidgets('should draw the specified number of elements based on '
          'threshold', (tester) async {
        final chart = acquireChartRoot(
          ChartConfigLowering(
            ChartConfig(
              type: ChartKind.line,
              datasets: [
                LineDataset(points: _originalData(), label: 'dataset1'),
              ],
              scales: const {'x': LinearAxis()},
              extra: const {
                'parsing': false,
                'plugins': {
                  'decimation': <String, Object?>{
                    'enabled': true,
                    'algorithm': LttbDecimationAlgorithm(),
                    'samples': 5,
                    'threshold': 7,
                  },
                },
              },
            ),
          ).lower(),
          _canvas(100, 100),
        );

        expect(_data(chart).length, 5);
      });

      testWidgets('should draw all element only in range', (tester) async {
        final originalData = _originalData();
        final chart = acquireChartRoot(
          ChartConfigLowering(
            ChartConfig(
              type: ChartKind.line,
              datasets: [LineDataset(points: originalData, label: 'dataset1')],
              scales: const {'x': LinearAxis(min: 3, max: 6)},
              extra: const {
                'parsing': false,
                'plugins': {
                  'decimation': <String, Object?>{
                    'enabled': true,
                    'algorithm': LttbDecimationAlgorithm(),
                    'samples': 7,
                  },
                },
              },
            ),
          ).lower(),
          _canvas(1, 1),
        );

        // Data range is 4 (3->6) and the first point is added
        const expectedPoints = 5;
        final data = _data(chart);
        expect(data.length, expectedPoints);
        expect(jsGet(data[0], 'x'), jsGet(originalData[2], 'x'));
        expect(jsGet(data[1], 'x'), jsGet(originalData[3], 'x'));
        expect(jsGet(data[2], 'x'), jsGet(originalData[4], 'x'));
        expect(jsGet(data[3], 'x'), jsGet(originalData[5], 'x'));
        expect(jsGet(data[4], 'x'), jsGet(originalData[6], 'x'));
      });

      testWidgets('should not crash with uneven points', (tester) async {
        final data = <DataPoint>[];
        for (var i = 0; i < 15552; i++) {
          data.add(DataPoint(i.toDouble(), i.toDouble()));
        }

        Chart createChart() => acquireChartRoot(
          ChartConfigLowering(
            ChartConfig(
              type: ChartKind.line,
              datasets: [LineDataset(points: data)],
              scales: const {'x': LinearAxis()},
              extra: const {
                'devicePixelRatio': 1.25,
                'parsing': false,
                'plugins': {
                  'decimation': <String, Object?>{
                    'enabled': true,
                    'algorithm': LttbDecimationAlgorithm(),
                  },
                },
              },
            ),
          ).lower(),
          <String, Object?>{
            'canvas': <String, Object?>{'width': 511, 'height': 511},
          },
        );
        expect(createChart, returnsNormally);
      });
    });
  });
}
