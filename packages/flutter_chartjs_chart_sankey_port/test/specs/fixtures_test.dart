// Ported from chartjs-chart-sankey v0.19.1 test/specs/fixtures.spec.js (MIT, Jukka Kurkela).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart' show acquireChart;
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    show Flow, SankeyOrientation;
import 'package:flutter_chartjs_port/chartjs.dart' show Chart;
import 'package:flutter_chartjs_port/js_semantics.dart' show jsGet, jsMax;
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../fixtures/observe.dart' show RecordingContext;

void main() {
  group('fixtures', fixture.specs());

  group('index', () {
    test('should register controller and element', () {
      expect(Chart.registry.getController('sankey'), isNotNull);
      expect(Chart.registry.getElement('flow'), isNotNull);
    });

    testWidgets('should create a sankey chart without data', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'data': <String, Object?>{},
        'options': <String, Object?>{
          'plugins': <String, Object?>{
            'legend': <String, Object?>{'display': false},
            'title': <String, Object?>{
              'display': true,
              'text': 'OD pairs on hexagon level',
            },
          },
        },
        'type': 'sankey',
      });

      expect(chart.config.type, 'sankey');
      expect(jsGet(chart.data, 'datasets'), isEmpty);
    });

    testWidgets('should lay out a vertical sankey from top to bottom', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[
                <String, Object?>{'flow': 10, 'from': 'A', 'to': 'B'},
                <String, Object?>{'flow': 4, 'from': 'A', 'to': 'C'},
              ],
              // DIVERGES(sankey): adapt-sankey-option-enums, the enum value.
              'orientation': SankeyOrientation.vertical,
            },
          ],
        },
        'options': <String, Object?>{'animation': false},
        'type': 'sankey',
      });

      final flow = chart.getDatasetMeta(0).data[0] as Flow;
      expect(jsGet(flow.options, 'orientation'), SankeyOrientation.vertical);
      expect(flow.y, lessThan(flow.y2));
      expect(flow.width, greaterThan(0));
      expect(flow.height, 0);
    });

    testWidgets('should reserve space for custom node widths', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[
                <String, Object?>{'flow': 10, 'from': 'A', 'to': 'B'},
                <String, Object?>{'flow': 4, 'from': 'A', 'to': 'C'},
              ],
              'nodeWidth': 18,
            },
          ],
        },
        'options': <String, Object?>{'animation': false},
        'type': 'sankey',
      });
      // Vitest's spyOn calls through by default, unlike Jasmine's.
      //
      // The spy is a recording context in `chart.ctx`: the controller draws
      // its nodes on the context of the chart (controller.ts:540). It
      // records each call and draws nothing.
      final target = chart.ctx!;
      final spy = RecordingContext(target);
      chart.ctx = spy;
      addTearDown(() => chart.ctx = target);

      chart.draw();

      final rightEdges = [
        for (final call in spy.getCalls())
          if (call case {
            'name': 'fillRect',
            'args': [final double x, _, final double width, ...],
          })
            x + width,
      ];
      expect(rightEdges, isNotEmpty);
      expect(rightEdges.reduce(jsMax), closeTo(chart.width - 3, 0.000005));
    });
  });
}
