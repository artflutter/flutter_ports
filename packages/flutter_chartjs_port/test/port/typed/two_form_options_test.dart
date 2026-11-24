// Original code, not ported from Chart.js: the second forms of typed options.
@TestOn('vm')
library;

import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

/// The lowered root of [config].
Object _root(ChartConfig config) => ChartConfigLowering(config).lower();

/// The dataset 0 of [root].
Object? _dataset0(Object root) =>
    (jsGet(jsGet(root, 'data'), 'datasets')! as List<Object?>)[0];

void main() {
  test('DatasetData.ranges lowers to [start, end] items and gaps', () {
    final ranges = <(num, num)?>[(1, 5), null, (2.5, 6)];
    final root = _root(
      ChartConfig(
        labels: const ['a', 'b', 'c'],
        datasets: [BarDataset(data: .ranges(ranges))],
      ),
    );
    expect(jsGet(_dataset0(root), 'data'), [
      [1.0, 5.0],
      null,
      [2.5, 6.0],
    ]);
    // The same List is the same value; a new List is a new value.
    expect(DatasetData.ranges(ranges), DatasetData.ranges(ranges));
    expect(
      DatasetData.ranges(ranges) == DatasetData.ranges([...ranges]),
      isFalse,
    );
  });

  test('borderRadiusCorners writes the object form of borderRadius', () {
    const corners = BorderRadius.vertical(top: Radius.circular(4));
    final root = _root(
      const ChartConfig(datasets: [BarDataset(borderRadiusCorners: corners)]),
    );
    expect(jsGet(_dataset0(root), 'borderRadius'), corners);
    expect(
      () => _root(
        const ChartConfig(
          datasets: [BarDataset(borderRadius: 2, borderRadiusCorners: corners)],
        ),
      ),
      throwsAssertionError,
    );
  });

  test('minIndex and maxIndex write the number form of min and max', () {
    final root = _root(
      const ChartConfig(
        datasets: [BarDataset()],
        scales: [CategoryAxis(.x, minIndex: 1, maxIndex: 3)],
      ),
    );
    final x = jsGet(jsGet(jsGet(root, 'options'), 'scales'), 'x');
    expect(jsGet(x, 'min'), 1);
    expect(jsGet(x, 'max'), 3);
    expect(
      () => _root(
        const ChartConfig(
          datasets: [BarDataset()],
          scales: [CategoryAxis(.x, min: 'a', minIndex: 1)],
        ),
      ),
      throwsAssertionError,
    );
  });

  test('LogarithmicAxis writes beginAtZero', () {
    final root = _root(
      const ChartConfig(
        datasets: [LineDataset()],
        scales: [LogarithmicAxis(.y, beginAtZero: true)],
      ),
    );
    final y = jsGet(jsGet(jsGet(root, 'options'), 'scales'), 'y');
    expect(jsGet(y, 'beginAtZero'), isTrue);
  });

  test('a dataset writes parsing, normalized and animation', () {
    final root = _root(
      const ChartConfig(
        datasets: [
          LineDataset(
            parsing: false,
            normalized: true,
            animation: ChartAnimation.none,
          ),
        ],
      ),
    );
    final dataset = _dataset0(root);
    expect(jsGet(dataset, 'parsing'), isFalse);
    expect(jsGet(dataset, 'normalized'), isTrue);
    expect(jsGet(dataset, 'animation'), isFalse);
  });

  test('borderWidths and borderWidthSides write the other border widths', () {
    final indexed = _root(
      const ChartConfig(
        datasets: [
          BarDataset(borderWidths: .indexed([2, 0])),
        ],
      ),
    );
    expect(jsGet(_dataset0(indexed), 'borderWidth'), [2.0, 0.0]);
    final sides = _root(
      const ChartConfig(
        datasets: [
          BarDataset(borderWidthSides: EdgeInsets.only(top: 6, left: 1)),
        ],
      ),
    );
    final width = jsGet(_dataset0(sides), 'borderWidth');
    expect(jsGet(width, 'top'), 6);
    expect(jsGet(width, 'left'), 1);
    expect(jsGet(width, 'bottom'), 0);
    expect(
      () => _root(
        const ChartConfig(
          datasets: [BarDataset(borderWidth: 1, borderWidths: .constant(2))],
        ),
      ),
      throwsAssertionError,
    );
  });

  test('autoPadding writes options.layout.autoPadding', () {
    final root = _root(
      const ChartConfig(datasets: [LineDataset()], autoPadding: false),
    );
    expect(
      jsGet(jsGet(jsGet(root, 'options'), 'layout'), 'autoPadding'),
      isFalse,
    );
  });

  test('borderFunction writes the function form of border', () {
    AxisBorder border(ScriptableScaleContext context) =>
        const AxisBorder(display: false);
    final root = _root(
      ChartConfig(
        datasets: const [LineDataset()],
        scales: [LinearAxis(.y, borderFunction: border)],
      ),
    );
    final y = jsGet(jsGet(jsGet(root, 'options'), 'scales'), 'y');
    expect(jsGet(y, 'border'), isA<Function>());
  });
}
