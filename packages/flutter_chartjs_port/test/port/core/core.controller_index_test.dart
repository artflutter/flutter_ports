// Original code, not ported from Chart.js: tests of the index parameters.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0052, section 10: the six visibility and meta methods of
// `Chart` take a `num` index at the public boundary and convert it with
// `toDouble()` at the entry (rows `adapt-chart-index-parameters` and
// `adapt-types-chart-index-parameters` of differences.md). An `int` index,
// for example the `datasetIndex` of a `ChartHit`, gives the result of the
// `double` index of the same value. Inside, the numbers stay `double`
// (Chart.js ADR 0045, section 7).

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
  group('adapt-chart-index-parameters', () {
    testWidgets('getDatasetMeta, isDatasetVisible and setDatasetVisibility '
        'take an int variable', (tester) async {
      final chart = _chart();
      const datasetIndex = 1;
      expect(
        chart.getDatasetMeta(datasetIndex),
        same(chart.getDatasetMeta(1.0)),
      );
      expect(chart.getDatasetMeta(datasetIndex).index, isA<double>());
      expect(chart.isDatasetVisible(datasetIndex), isTrue);
      chart.setDatasetVisibility(datasetIndex, false);
      expect(chart.isDatasetVisible(1.0), isFalse);
      expect(chart.isDatasetVisible(datasetIndex), isFalse);
      chart.setDatasetVisibility(datasetIndex, true);
      expect(chart.isDatasetVisible(datasetIndex), isTrue);

      // A meta of an index without a dataset keeps a double index
      // (core.controller.js:833-850).
      const missing = 5;
      final meta = chart.getDatasetMeta(missing);
      expect(meta.index, 5.0);
      expect(meta.index, isA<double>());
    });

    testWidgets('hide and show take int variables, also for a data index', (
      tester,
    ) async {
      final chart = _chart();
      const datasetIndex = 0;
      const dataIndex = 2;
      chart.hide(datasetIndex);
      expect(chart.isDatasetVisible(0.0), isFalse);
      chart.show(datasetIndex);
      expect(chart.isDatasetVisible(0.0), isTrue);

      chart.hide(datasetIndex, dataIndex);
      expect(chart.getDatasetMeta(0.0).data[2].hidden, isTrue);
      chart.show(datasetIndex, dataIndex);
      expect(chart.getDatasetMeta(0.0).data[2].hidden, isFalse);
    });

    testWidgets('getDataVisibility takes an int variable: the key of '
        "toggleDataVisibility is '1'", (tester) async {
      final chart = _chart();
      const index = 1;
      expect(chart.getDataVisibility(index), isTrue);
      chart.toggleDataVisibility(1.0);
      expect(chart.getDataVisibility(index), isFalse);
      expect(chart.getDataVisibility(1.0), isFalse);
      expect(chart.getDataVisibility(0), isTrue);
    });
  });

  group('adapt-types-chart-index-parameters', () {
    testWidgets('the interface types.Chart takes int variables', (
      tester,
    ) async {
      final types.Chart chart = _chart();
      const datasetIndex = 1;
      expect(
        chart.getDatasetMeta(datasetIndex),
        same(chart.getDatasetMeta(1.0)),
      );
      expect(chart.isDatasetVisible(datasetIndex), isTrue);
      chart.hide(datasetIndex);
      expect(chart.isDatasetVisible(datasetIndex), isFalse);
      chart.show(datasetIndex);
      expect(chart.isDatasetVisible(datasetIndex), isTrue);
      expect(chart.getDataVisibility(datasetIndex), isTrue);
    });
  });
}
