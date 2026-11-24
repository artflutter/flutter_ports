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
// - Each config is a typed `ChartConfig` with a `DecimationOptions` in
//   `pluginOptions` (Chart.js ADR 0194).
// - The first case has the upstream `scales` key at the root of the config,
//   where Chart.js does not read it: the x scale is the default category
//   scale and the parsing is on, so the plugin returns early
//   (plugin.decimation.js:231, :236). A typed config has no root key: it
//   gives the linear axis in the options. The parsing stays on, so the plugin
//   still returns early and the data keep their 10 items.

/// The data of :6-16.
List<DataPoint> _originalData() => [
  for (var i = 0; i < 10; i++) DataPoint(i.toDouble(), i.toDouble()),
];

/// `chart.data.datasets[0].data`.
List<Object?> _data(Chart chart) =>
    jsGet((jsGet(chart.data, 'datasets')! as List<Object?>)[0], 'data')!
        as List<Object?>;

/// The acquireChart options of a canvas and a wrapper of [width] x
/// [height] (the second argument of `acquireChart`, not a chart config).
///
/// The attributes `height` and `width` of the wrapper `div` of upstream have
/// no effect on its layout: the wrapper is a static block box (Chart.js ADR
/// 0200).
AcquireOptions _canvas(int width, int height) => AcquireOptions(
  canvas: HarnessCanvas(width: width, height: height),
  wrapper: const HarnessBox(),
);

/// The acquireChart options of a canvas of [width] x [height].
AcquireOptions _canvasOnly(int width, int height) => AcquireOptions(
  canvas: HarnessCanvas(width: width, height: height),
);

void main() {
  group('Plugin.decimation', () {
    group('auto', fixture.specs('plugin.decimation'));

    group('lttb', () {
      testWidgets('should draw all element if sample is greater than data '
          'based on canvas width', (tester) async {
        final chart = acquireChartRoot(
          lowerForTest(
            ChartConfig(
              datasets: [
                LineDataset(data: .points(_originalData()), label: 'dataset1'),
              ],
              scales: const [LinearAxis(.x, min: 0, max: 9)],
              pluginOptions: const [
                DecimationOptions(
                  enabled: true,
                  algorithm: LttbDecimationAlgorithm(),
                  samples: 100,
                ),
              ],
            ),
          ),
          _canvas(1, 1),
        );

        expect(_data(chart).length, 10);
      });

      testWidgets('should draw the specified number of elements based on '
          'canvas width', (tester) async {
        final chart = acquireChartRoot(
          lowerForTest(
            ChartConfig(
              datasets: [
                LineDataset(data: .points(_originalData()), label: 'dataset1'),
              ],
              scales: const [LinearAxis(.x, min: 0, max: 9)],
              parsing: false,
              pluginOptions: const [
                DecimationOptions(
                  enabled: true,
                  algorithm: LttbDecimationAlgorithm(),
                  samples: 7,
                ),
              ],
            ),
          ),
          _canvas(1, 1),
        );

        expect(_data(chart).length, 7);
      });

      testWidgets('should draw the specified number of elements based on '
          'threshold', (tester) async {
        final chart = acquireChartRoot(
          lowerForTest(
            ChartConfig(
              datasets: [
                LineDataset(data: .points(_originalData()), label: 'dataset1'),
              ],
              scales: const [LinearAxis(.x)],
              parsing: false,
              pluginOptions: const [
                DecimationOptions(
                  enabled: true,
                  algorithm: LttbDecimationAlgorithm(),
                  samples: 5,
                  threshold: 7,
                ),
              ],
            ),
          ),
          _canvas(100, 100),
        );

        expect(_data(chart).length, 5);
      });

      testWidgets('should draw all element only in range', (tester) async {
        final originalData = _originalData();
        final chart = acquireChartRoot(
          lowerForTest(
            ChartConfig(
              datasets: [
                LineDataset(data: .points(originalData), label: 'dataset1'),
              ],
              scales: const [LinearAxis(.x, min: 3, max: 6)],
              parsing: false,
              pluginOptions: const [
                DecimationOptions(
                  enabled: true,
                  algorithm: LttbDecimationAlgorithm(),
                  samples: 7,
                ),
              ],
            ),
          ),
          _canvas(1, 1),
        );

        // Data range is 4 (3->6) and the first point is added
        const expectedPoints = 5;
        final data = _data(chart);
        expect(data.length, expectedPoints);
        expect((data[0]! as ParsedItem).x, originalData[2].x);
        expect((data[1]! as ParsedItem).x, originalData[3].x);
        expect((data[2]! as ParsedItem).x, originalData[4].x);
        expect((data[3]! as ParsedItem).x, originalData[5].x);
        expect((data[4]! as ParsedItem).x, originalData[6].x);
      });

      testWidgets('should not crash with uneven points', (tester) async {
        final data = <DataPoint>[];
        for (var i = 0; i < 15552; i++) {
          data.add(DataPoint(i.toDouble(), i.toDouble()));
        }

        Chart createChart() => acquireChartRoot(
          lowerForTest(
            ChartConfig(
              datasets: [LineDataset(data: .points(data))],
              scales: const [LinearAxis(.x)],
              devicePixelRatio: 1.25,
              parsing: false,
              pluginOptions: const [
                DecimationOptions(
                  enabled: true,
                  algorithm: LttbDecimationAlgorithm(),
                ),
              ],
            ),
          ),
          _canvasOnly(511, 511),
        );
        expect(createChart, returnsNormally);
      });
    });
  });
}
