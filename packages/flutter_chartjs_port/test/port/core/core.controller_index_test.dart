// Original code, not ported from Chart.js: tests of the index parameters.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

// The six visibility and meta methods of `Chart` take an `int` index, as
// each index of the chart does (row `adapt-int-indexes` of differences.md).
// The `datasetIndex` and the `index` of an `ActiveElement` go to them as
// they are.

/// A bar chart with two datasets of three values.
Chart _chart() => acquireChart(<String, Object?>{
  'type': 'bar',
  'data': <String, Object?>{
    'labels': <Object?>['a', 'b', 'c'],
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[1, 2, 3],
      },
      <String, Object?>{
        'data': <Object?>[4, 5, 6],
      },
    ],
  },
  'options': <String, Object?>{'animation': false},
});

void main() {
  group('adapt-int-indexes', () {
    testWidgets('getDatasetMeta, isDatasetVisible and setDatasetVisibility '
        'take an int variable', (tester) async {
      final chart = _chart();
      const datasetIndex = 1;
      expect(chart.getDatasetMeta(datasetIndex), same(chart.getDatasetMeta(1)));
      expect(chart.getDatasetMeta(datasetIndex).index, isA<int>());
      expect(chart.isDatasetVisible(datasetIndex), isTrue);
      chart.setDatasetVisibility(datasetIndex, false);
      expect(chart.isDatasetVisible(1), isFalse);
      expect(chart.isDatasetVisible(datasetIndex), isFalse);
      chart.setDatasetVisibility(datasetIndex, true);
      expect(chart.isDatasetVisible(datasetIndex), isTrue);

      // A meta of an index without a dataset keeps its index
      // (core.controller.js:833-850).
      const missing = 5;
      final meta = chart.getDatasetMeta(missing);
      expect(meta.index, 5);
    });

    testWidgets('hide and show take int variables, also for a data index', (
      tester,
    ) async {
      final chart = _chart();
      const datasetIndex = 0;
      const dataIndex = 2;
      chart.hide(datasetIndex);
      expect(chart.isDatasetVisible(0), isFalse);
      chart.show(datasetIndex);
      expect(chart.isDatasetVisible(0), isTrue);

      chart.hide(datasetIndex, dataIndex);
      expect(chart.getDatasetMeta(0).data[2].hidden, isTrue);
      chart.show(datasetIndex, dataIndex);
      expect(chart.getDatasetMeta(0).data[2].hidden, isFalse);
    });

    testWidgets('getDataVisibility takes an int variable: the key of '
        "toggleDataVisibility is '1'", (tester) async {
      final chart = _chart();
      const index = 1;
      expect(chart.getDataVisibility(index), isTrue);
      chart.toggleDataVisibility(1);
      expect(chart.getDataVisibility(index), isFalse);
      expect(chart.getDataVisibility(1), isFalse);
      expect(chart.getDataVisibility(0), isTrue);
    });
  });

  group('adapt-int-indexes, the interface', () {
    testWidgets('the interface types.Chart takes int variables', (
      tester,
    ) async {
      final types.Chart chart = _chart();
      const datasetIndex = 1;
      expect(chart.getDatasetMeta(datasetIndex), same(chart.getDatasetMeta(1)));
      expect(chart.isDatasetVisible(datasetIndex), isTrue);
      chart.hide(datasetIndex);
      expect(chart.isDatasetVisible(datasetIndex), isFalse);
      chart.show(datasetIndex);
      expect(chart.isDatasetVisible(datasetIndex), isTrue);
      expect(chart.getDataVisibility(datasetIndex), isTrue);
    });
  });
}
