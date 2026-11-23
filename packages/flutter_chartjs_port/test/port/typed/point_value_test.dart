// Original code, not ported from Chart.js: indexed and scriptable point values.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

// The point radius, the hover radius and the point style of the line,
// scatter and radar datasets take a ChartValue, as the point paints do
// (point_paint_test.dart): a constant, a value for each point or a function
// of the data context.

/// A dataset of one chart type with three points and the given point values.
typedef _Factory = Dataset Function({
  ChartValue<double>? pointRadius,
  ChartValue<double>? pointHoverRadius,
  ChartValue<PointStyle>? pointStyle,
});

void main() {
  final factories = <ChartKind, _Factory>{
    ChartKind.line: ({pointRadius, pointHoverRadius, pointStyle}) =>
        LineDataset(
          data: const .values([1, 2, 3]),
          pointRadius: pointRadius,
          pointHoverRadius: pointHoverRadius,
          pointStyle: pointStyle,
        ),
    ChartKind.scatter: ({pointRadius, pointHoverRadius, pointStyle}) =>
        ScatterDataset(
          data: .points([DataPoint(0, 1), DataPoint(1, 2), DataPoint(2, 3)]),
          pointRadius: pointRadius,
          pointHoverRadius: pointHoverRadius,
          pointStyle: pointStyle,
        ),
    ChartKind.radar: ({pointRadius, pointHoverRadius, pointStyle}) =>
        RadarDataset(
          data: const [1, 2, 3],
          pointRadius: pointRadius,
          pointHoverRadius: pointHoverRadius,
          pointStyle: pointStyle,
        ),
  };
  for (final MapEntry(key: kind, value: make) in factories.entries) {
    test('${kind.name}: each form lowers to its cell, with no call', () {
      var calls = 0;
      final constant = lowerDataset(
        make(
          pointRadius: const .constant(3),
          pointHoverRadius: const .constant(5),
          pointStyle: const .constant(RectPointStyle()),
        ),
        kind,
      );
      expect(constant.ownCell(OptionKey.pointRadius), isA<OptValue<double>>());
      expect(constant.ownCell(OptionKey.pointRadius)!.raw, 3);
      expect(constant.ownCell(OptionKey.pointHoverRadius)!.raw, 5);
      expect(
        constant.ownCell(OptionKey.pointStyle)!.raw,
        const RectPointStyle(),
      );

      const radii = [0.0, 8.5, 6.0];
      final indexed = lowerDataset(
        make(
          pointRadius: const .indexed(radii),
          pointHoverRadius: const .indexed(radii),
          pointStyle: const .indexed([CirclePointStyle(), RectPointStyle()]),
        ),
        kind,
      );
      final radiusCell = indexed.ownCell(OptionKey.pointRadius)!;
      expect(radiusCell, isA<OptList<double>>());
      expect(radiusCell.raw, radii);
      expect(radiusCell.raw, isNot(same(radii)), reason: 'a new List');
      expect(indexed.ownCell(OptionKey.pointHoverRadius)!.raw, radii);
      expect(indexed.ownCell(OptionKey.pointStyle)!.raw, const [
        CirclePointStyle(),
        RectPointStyle(),
      ]);

      final resolved = lowerDataset(
        make(
          pointRadius: .resolver((context) {
            calls++;
            return 1;
          }),
          pointStyle: .resolver((context) {
            calls++;
            return const CirclePointStyle();
          }),
        ),
        kind,
      );
      expect(
        resolved.ownCell(OptionKey.pointRadius),
        isA<OptFunction<double>>(),
      );
      expect(
        resolved.ownCell(OptionKey.pointStyle),
        isA<OptFunction<PointStyle>>(),
      );
      expect(calls, 0);
    });

    testWidgets('${kind.name}: indexed and scriptable point values resolve '
        'for each point, also under the pointer', (tester) async {
      final forms = <_Factory Function(_Factory)>[
        (make) =>
            ({pointRadius, pointHoverRadius, pointStyle}) => make(
              pointRadius: const .indexed([2, 7, 4]),
              pointHoverRadius: const .indexed([3, 9, 5]),
              pointStyle: const .indexed([
                CirclePointStyle(),
                RectPointStyle(),
                TrianglePointStyle(),
              ]),
            ),
        (make) =>
            ({pointRadius, pointHoverRadius, pointStyle}) => make(
              pointRadius: .resolver(
                (context) => const [2.0, 7.0, 4.0][context.dataIndex!],
              ),
              pointHoverRadius: .resolver(
                (context) => const [3.0, 9.0, 5.0][context.dataIndex!],
              ),
              pointStyle: .resolver(
                (context) => const <PointStyle>[
                  CirclePointStyle(),
                  RectPointStyle(),
                  TrianglePointStyle(),
                ][context.dataIndex!],
              ),
            ),
      ];
      const radius = [2.0, 7.0, 4.0];
      const hoverRadius = [3.0, 9.0, 5.0];
      const styles = <PointStyle>[
        CirclePointStyle(),
        RectPointStyle(),
        TrianglePointStyle(),
      ];
      for (final form in forms) {
        final chart = acquireChartRoot(
          ChartConfigLowering(
            ChartConfig(
              labels: const ['a', 'b', 'c'],
              datasets: [form(make)()],
              animation: ChartAnimation.none,
            ),
          ).lower(),
        );
        final meta = chart.getDatasetMeta(0);
        for (var i = 0; i < 3; i++) {
          final options = (meta.data[i] as PointElement).options!;
          expect((options as PointOptions).radius, radius[i]);
          expect(options.hoverRadius, hoverRadius[i]);
          expect(options['pointStyle'], styles[i]);
        }
        chart
          ..setActiveElements([const ActiveElement(datasetIndex: 0, index: 1)])
          ..update();
        final hovered = (meta.data[1] as PointElement).options!;
        expect((hovered as PointOptions).radius, hoverRadius[1]);
        releaseChart(chart);
      }
    });
  }
}
