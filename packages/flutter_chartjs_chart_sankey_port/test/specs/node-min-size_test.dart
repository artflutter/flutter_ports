// Ported from chartjs-chart-sankey v0.19.1 test/specs/node-min-size.spec.js (MIT, Jukka Kurkela).
// ignore_for_file: file_names
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart'
    show MockContext, createMockContext;
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart' show Chart;
import 'package:flutter_test/flutter_test.dart';

// One huge node and several tiny ones in the same column, matching issue 87's
// shape (a report with flows of 0.37 and 85024 landing in the same column).
List<Object?> _data() => <Object?>[
  <String, Object?>{'flow': 85024, 'from': 'Huge', 'to': 'Sink'},
  <String, Object?>{'flow': 0.37, 'from': 'Tiny A', 'to': 'Sink'},
  <String, Object?>{'flow': 0.5, 'from': 'Tiny B', 'to': 'Sink'},
  <String, Object?>{'flow': 0.9, 'from': 'Tiny C', 'to': 'Sink'},
];

const double _nodeWidth = 10;

Chart _buildSankeyWithMinSize(Object? nodeMinSize) => acquireChart(
  {
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': _data(),
          'nodeMinSize': nodeMinSize,
          'nodeWidth': _nodeWidth,
        },
      ],
    },
    'options': <String, Object?>{
      'animation': false,
      'maintainAspectRatio': false,
    },
    'type': 'sankey',
  },
  {
    'canvas': <String, Object?>{'height': 400, 'width': 800},
  },
);

typedef _Rect = ({double height, double width, double x, double y});

/// `vi.spyOn(chart.ctx, 'fillRect')`, then `chart.draw()`: the controller
/// draws its nodes, flows and labels on a recording context. The mock
/// context of the harness has no `resetTransform` for the clear of
/// `chart.draw()`, and only the controller calls `fillRect` in these charts.
MockContext _drawRecorded(Chart chart) {
  final recording = createMockContext();
  final ctx = chart.ctx;
  chart.ctx = recording;
  chart.getDatasetMeta(0).controller!.draw();
  chart.ctx = ctx;
  return recording;
}

// Node bars are drawn as square-ish rects of width `nodeWidth`; flows are
// much wider/taller. Filtering by width isolates the fillRect calls that draw
// node bars.
List<_Rect> _nodeBarRects(MockContext recording) => [
  for (final call in recording.getCalls())
    if (call['name'] == 'fillRect')
      if (call['args']!
          case [
            final double x,
            final double y,
            final double width,
            final double height,
          ]
          when width == _nodeWidth)
        (height: height, width: width, x: x, y: y),
];

_Rect _closestByCenter(List<_Rect> rects, double expectedCenter) =>
    rects.reduce((closest, rect) {
      final center = rect.y + rect.height / 2;
      final closestCenter = closest.y + closest.height / 2;
      return (center - expectedCenter).abs() <
              (closestCenter - expectedCenter).abs()
          ? rect
          : closest;
    });

SankeyNode _node(Chart chart, String key) =>
    (chart.getDatasetMeta(0).controller! as SankeyController).nodes[key]!;

void main() {
  group('nodeMinSize', () {
    testWidgets('calls a function-form nodeMinSize with a SankeyNode, not a '
        'Chart.js scriptable context', (tester) async {
      final seenNodes = <Object?>[];

      _buildSankeyWithMinSize((Object? node) {
        seenNodes.add(node);
        return 6;
      });

      // The dataset-level `_scriptable: true` default would make Chart.js
      // call this itself with its own ScriptableContext (which has `chart`
      // and `dataIndex`) before the controller ever sees the raw option. The
      // sankey-specific `nodeMinSize` descriptor exception is what makes
      // `node` below a real SankeyNode instead.
      expect(seenNodes.length, greaterThan(0));
      for (final node in seenNodes) {
        // A SankeyNode is a class of the port: it has a `key` and no member
        // of a scriptable context.
        expect(node, isA<SankeyNode>());
      }
    });

    testWidgets('stretches a tiny node bar to at least nodeMinSize CSS '
        'pixels, centered on its natural position', (tester) async {
      const minSize = 6.0;

      // Baseline: without a minimum, Tiny A's bar is a fraction of a pixel
      // tall (flow 0.37 against ~85026 total flow over ~394 usable px).
      final chartWithoutMin = _buildSankeyWithMinSize(0);
      final fillRectWithoutMin = _drawRecorded(chartWithoutMin);
      final tinyAWithoutMin = _node(chartWithoutMin, 'Tiny A');
      final yScaleWithoutMin = chartWithoutMin.scales['y']!;
      final naturalCenter = yScaleWithoutMin.getPixelForValue(
        (tinyAWithoutMin.y ?? 0) + tinyAWithoutMin.size / 2,
      );
      final naturalRect = _closestByCenter(
        _nodeBarRects(fillRectWithoutMin),
        naturalCenter,
      );
      expect(naturalRect.height, lessThan(1));

      // With the minimum, the same node's bar reaches at least minSize, and
      // stays centered on the same natural position (within the 1px
      // tolerance of comparing float pixel math against a fresh chart
      // instance).
      final chart = _buildSankeyWithMinSize(minSize);
      final fillRect = _drawRecorded(chart);
      final tinyA = _node(chart, 'Tiny A');
      final yScale = chart.scales['y']!;
      final expectedCenter = yScale.getPixelForValue(
        (tinyA.y ?? 0) + tinyA.size / 2,
      );
      final stretchedRect = _closestByCenter(
        _nodeBarRects(fillRect),
        expectedCenter,
      );

      expect(stretchedRect.height, greaterThanOrEqualTo(minSize - 1e-6));
      expect(
        stretchedRect.y + stretchedRect.height / 2,
        closeTo(expectedCenter, 0.05),
      );
    });
  });
}
