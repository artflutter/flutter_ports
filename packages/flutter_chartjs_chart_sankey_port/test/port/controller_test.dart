// Original code, not ported from chartjs-chart-sankey: the hover color keys.
@TestOn('vm')
library;

import 'dart:ui' show Color;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart'
    show ActiveElement, Chart, ChartPaint, SolidChartPaint;
import 'package:flutter_chartjs_port/helpers.dart' show getHoverColor;
import 'package:flutter_chartjs_port/js_semantics.dart' show jsGet;
import 'package:flutter_test/flutter_test.dart';

const ChartPaint _red = ChartPaint.solid(Color(0xFFFF0000));
const ChartPaint _green = ChartPaint.solid(Color(0xFF008000));
const ChartPaint _orange = ChartPaint.solid(Color(0xFFFFA500));

Chart _chart(Map<String, Object?> dataset) => acquireChart({
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[
          const SankeyDataPoint(from: 'a', to: 'b', flow: 10),
          const SankeyDataPoint(from: 'a', to: 'c', flow: 5),
          const SankeyDataPoint(from: 'b', to: 'c', flow: 10),
        ],
        ...dataset,
      },
    ],
  },
  'options': <String, Object?>{'animation': false},
  'type': 'sankey',
});

Color _colorOf(Object? paint) => (paint! as SolidChartPaint).color;

void main() {
  // Row adapt-sankey-hover-color-keys of doc/differences.md.
  group('the hover color keys', () {
    testWidgets('the default options of a flow hold the hover functions', (
      tester,
    ) async {
      final chart = _chart({});
      final flow = chart.getDatasetMeta(0).data.first as Flow;

      expect(_colorOf(jsGet(flow.options, 'colorFrom')), _colorOf(_red));
      expect(jsGet(flow.options, 'hoverColorFrom'), isA<Function>());
      expect(jsGet(flow.options, 'hoverColorTo'), isA<Function>());
    });

    testWidgets('the active options have the default hover colors', (
      tester,
    ) async {
      final chart = _chart({});
      final controller = chart.getDatasetMeta(0).controller!;
      final active = controller.resolveDataElementOptions(0, 'active');

      expect(
        _colorOf(jsGet(active, 'colorFrom')),
        _colorOf(getHoverColor(_red)),
      );
      expect(
        _colorOf(jsGet(active, 'colorTo')),
        _colorOf(getHoverColor(_green)),
      );
    });

    testWidgets('an update calls no hover function', (tester) async {
      var hoverCalls = 0;
      var colorCalls = 0;
      final chart = _chart({
        'colorTo': (Object? context, Object? options) {
          colorCalls++;
          return _green;
        },
        'hoverColorFrom': (Object? context, Object? options) {
          hoverCalls++;
          return _orange;
        },
      });

      // A scriptable color still resolves for each of the three flows.
      expect(colorCalls, greaterThanOrEqualTo(3));
      expect(hoverCalls, 0);

      chart.update('none');
      expect(hoverCalls, 0);

      // The active mode reads the key as `colorFrom`, which is scriptable.
      final controller = chart.getDatasetMeta(0).controller!;
      final active = controller.resolveDataElementOptions(1, 'active');
      expect(_colorOf(jsGet(active, 'colorFrom')), _colorOf(_orange));
      expect(hoverCalls, 1);
    });

    testWidgets('a hover of a flow draws it with the hover colors', (
      tester,
    ) async {
      final chart = _chart({
        'hoverColorFrom': _orange,
        'hoverColorTo': _orange,
      });
      final flow = chart.getDatasetMeta(0).data.first as Flow;
      chart
        ..setActiveElements(const [ActiveElement(datasetIndex: 0, index: 0)])
        ..update('none');

      expect(flow.active, isTrue);
      expect(_colorOf(jsGet(flow.options, 'colorFrom')), _colorOf(_orange));
      expect(_colorOf(jsGet(flow.options, 'colorTo')), _colorOf(_orange));
    });
  });
}
