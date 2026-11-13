// Original code, not ported from Chart.js: point paint variant regressions.
@TestOn('vm')
library;

import 'dart:ui' show Color, Offset;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/options/opt.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/typed/datasets.dart' show lowerDataset;
import 'package:flutter_chartjs_port/src/typed/lower.dart'
    show ChartConfigLowering;
import 'package:flutter_test/flutter_test.dart';

const _red = ChartPaint.solid(Color(0xffff0000));
const _blue = ChartPaint.solid(Color(0xff0000ff));
const _gradient = ChartGradient.linear(Offset.zero, Offset(100, 0), [
  Color(0xffff0000),
  Color(0xff0000ff),
]);

void main() {
  final factories = <ChartKind, Dataset Function(ChartValue<ChartPaint>)>{
    ChartKind.line: (paint) => LineDataset(
      data: const [1, 2, 3],
      pointBackgroundColor: paint,
      pointBorderColor: paint,
      pointHoverBackgroundColor: paint,
      pointHoverBorderColor: paint,
    ),
    ChartKind.scatter: (paint) => ScatterDataset(
      points: [DataPoint(0, 1), DataPoint(1, 2), DataPoint(2, 3)],
      pointBackgroundColor: paint,
      pointBorderColor: paint,
      pointHoverBackgroundColor: paint,
      pointHoverBorderColor: paint,
    ),
    ChartKind.radar: (paint) => RadarDataset(
      data: const [1, 2, 3],
      pointBackgroundColor: paint,
      pointBorderColor: paint,
      pointHoverBackgroundColor: paint,
      pointHoverBorderColor: paint,
    ),
  };
  const keys = [
    OptionKey.pointBackgroundColor,
    OptionKey.pointBorderColor,
    OptionKey.pointHoverBackgroundColor,
    OptionKey.pointHoverBorderColor,
  ];
  for (final entry in factories.entries) {
    test('${entry.key.name}: lowering keeps all point paint variants lazy', () {
      var calls = 0;
      final values = <ChartValue<ChartPaint>>[
        const .constant(_gradient),
        const .indexed([_red, _blue]),
        .resolver((context) {
          calls++;
          return _gradient;
        }),
      ];
      for (var i = 0; i < values.length; i++) {
        final scope = lowerDataset(entry.value(values[i]), entry.key);
        for (final key in keys) {
          final cell = scope.ownCell(key);
          switch (i) {
            case 0:
              expect(cell, isA<OptValue<ChartPaint>>());
              expect(cell!.raw, same(_gradient));
            case 1:
              expect(cell, isA<OptList<ChartPaint>>());
              expect(cell!.raw, [_red, _blue]);
            case 2:
              expect(cell, isA<OptFunction<ChartPaint>>());
          }
        }
      }
      expect(calls, 0);
    });
    testWidgets('${entry.key.name}: indexed and scriptable point paints '
        'resolve in both modes', (tester) async {
      for (final value in <ChartValue<ChartPaint>>[
        const .indexed([_red, _gradient]),
        .resolver((context) => context.dataIndex!.isEven ? _red : _gradient),
      ]) {
        final chart = acquireChartRoot(
          ChartConfigLowering(
            ChartConfig(
              type: entry.key,
              labels: const ['a', 'b', 'c'],
              datasets: [entry.value(value)],
              animation: ChartAnimation.none,
            ),
          ).lower(),
        );
        final controller = chart.getDatasetMeta(0).controller!;
        for (var i = 0; i < 3; i++) {
          final expected = i.isEven ? _red : _gradient;
          for (final active in [false, true]) {
            final style = controller.getStyle(i, active) as JsObjectFace;
            expect(style['backgroundColor'], same(expected));
            expect(style['borderColor'], same(expected));
          }
        }
      }
    });
  }
}
