// Original code, not ported from Chart.js: tests of the typed axes.
@TestOn('vm')
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0191: a typed config gives its axes as a List, each cartesian
// axis takes its direction, the lowering gives the scale ids, and a dataset
// names its axis by the axis object.
//
// VM only: the test imports the app library, which imports dart:ui.

const _right = LinearAxis(.y, position: .right);
const _top = LinearAxis(.x, position: .top);

ChartConfig _config({
  List<ChartAxis>? scales,
  ChartAxis? yAxis,
  ChartAxis? xAxis,
}) => ChartConfig(
  labels: const ['a', 'b', 'c'],
  datasets: [
    const LineDataset(data: [1, 2, 3]),
    LineDataset(data: const [30, 20, 10], xAxis: xAxis, yAxis: yAxis),
  ],
  scales: scales,
);

/// The `options.scales` scope of the lowering of [config].
ScaleOptionsByIdScope _scales(ChartConfig config) {
  final root = ChartConfigLowering(config).lower();
  final options = root.optionsCell!.raw! as ChartOptionsScope;
  return options.scalesCell!.raw! as ScaleOptionsByIdScope;
}

/// The dataset scope [index] of [root].
JsObjectFace _dataset(ChartConfigurationScope root, int index) {
  final data = root.dataCell!.raw! as ChartDataScope;
  final datasets = data.datasetsCell!.raw! as List<Object?>;
  return datasets[index]! as JsObjectFace;
}

Chart _chart(WidgetTester tester) => Chart.getChart(
  tester.renderObject<RenderChartHost>(find.byType(ChartHost)).canvas,
)!;

Widget _box(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: 300, height: 200, child: child),
  ),
);

void main() {
  group('the scale ids (item 3)', () {
    test('the first axis of a direction has the letter, the next ones a '
        'number', () {
      final ids = scaleIdsOf(const [
        CategoryAxis(.x),
        LinearAxis(.y),
        _right,
        _top,
        LinearAxis(.y, position: .left, reverse: true),
        RadialLinearAxis(),
      ]);
      expect(ids.values, ['x', 'y', 'y1', 'x1', 'y2', 'r']);
    });

    test('the lowering keeps the List order and writes the axis of a '
        'numbered id', () {
      final scales = _scales(
        _config(scales: const [LinearAxis(.y), _right, CategoryAxis(.x)]),
      );
      expect(scales.jsKeys(), ['y', 'y1', 'x']);
      final y1 = scales['y1']! as ScaleOptionsScope;
      expect(y1['axis'], isA<YAxis>());
      expect(y1['position'], ChartPosition.right);
      final y = scales['y']! as ScaleOptionsScope;
      expect(y.jsHas('axis'), isFalse);
    });

    test('two equal axes stop a debug build', () {
      expect(
        () => scaleIdsOf(const [LinearAxis(.y), LinearAxis(.y)]),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('the axis of a dataset (item 5)', () {
    test('an axis object gives the id of its axis', () {
      final root = ChartConfigLowering(
        _config(
          scales: const [LinearAxis(.y), _right, CategoryAxis(.x), _top],
          yAxis: _right,
          xAxis: _top,
        ),
      ).lower();
      expect(_dataset(root, 1)['yAxisID'], 'y1');
      expect(_dataset(root, 1)['xAxisID'], 'x1');
      expect(_dataset(root, 0).jsHas('yAxisID'), isFalse);
    });

    test('an equal axis object finds its axis', () {
      final root = ChartConfigLowering(
        _config(
          scales: const [LinearAxis(.y), _right],
          // A new object that is `==` to the axis of the List.
          yAxis: LinearAxis(.y, position: ChartPosition.values[3]),
        ),
      ).lower();
      expect(_dataset(root, 1)['yAxisID'], 'y1');
    });

    test('an axis that is not in scales stops a debug build', () {
      expect(
        () => ChartConfigLowering(
          _config(scales: const [LinearAxis(.y)], yAxis: _right),
        ).lower(),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a new order of the axes gives the dataset its new id', () {
      final lowering = ChartConfigLowering(
        _config(scales: const [LinearAxis(.y), _right], yAxis: _right),
      )..lower();
      final root = lowering.apply(
        _config(scales: const [_right, LinearAxis(.y)], yAxis: _right),
      );
      expect(_dataset(root, 1)['yAxisID'], 'y');
    });
  });

  group('the scales of the axes (item 6)', () {
    testWidgets('scaleOf gives the scale of an axis of the config', (
      tester,
    ) async {
      await tester.pumpWidget(
        _box(
          ChartView(
            config: _config(
              scales: const [CategoryAxis(.x), LinearAxis(.y), _right],
              yAxis: _right,
            ),
          ),
        ),
      );
      await tester.pump();
      final chart = _chart(tester);
      expect(chart.scaleIdOf(_right), 'y1');
      expect(chart.scaleOf(_right), same(chart.scales['y1']));
      expect(chart.scaleOf(const LinearAxis(.y)), same(chart.scales['y']));
      expect(chart.scaleOf(_top), isNull);
      // The second dataset draws on the right axis.
      expect(chart.getDatasetMeta(1).yAxisID, 'y1');
    });

    testWidgets('a raw config has no axis objects', (tester) async {
      // Chart.js writes into the config: it is not const.
      final config = <String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': ['a', 'b'],
          'datasets': [
            <String, Object?>{
              'data': [1, 2],
            },
          ],
        },
      };
      await tester.pumpWidget(_box(ChartView.raw(config: config)));
      await tester.pump();
      expect(_chart(tester).scaleIdOf(const LinearAxis(.y)), isNull);
    });
  });
}
