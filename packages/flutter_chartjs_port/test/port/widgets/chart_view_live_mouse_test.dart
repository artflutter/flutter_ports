// Original code, not ported from Chart.js: the mouse of a live ChartView.
@TestOn('vm')
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart' hide Element;
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_chartjs_port/src/types/plugin.dart';
import 'package:flutter_chartjs_port/src/widgets/chart_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// The events and the draws of the chart since the last [clear].
final class _Log() {
  final List<String> events = <String>[];
  int draws = 0;

  void clear() {
    events.clear();
    draws = 0;
  }

  late final List<Object?> plugins = <Object?>[
    Plugin<Object?>(
      id: 'log',
      supportsDataUpdates: true,
      afterEvent: (chart, args, options) {
        events.add('${args.event.type} ${args.replay ? 'replay' : 'real'}');
      },
      afterDraw: (chart, args, options) {
        draws++;
      },
    ),
  ];
}

/// A new config object with new data, as a live chart gets in each frame.
Map<String, Object?> _config(_Log log, int step) => <String, Object?>{
  'type': 'line',
  'plugins': log.plugins,
  'data': <String, Object?>{
    'labels': const <Object?>['a', 'b', 'c'],
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[1, 2 + step * .001, 3],
        'pointRadius': 3,
      },
    ],
  },
  'options': <String, Object?>{
    'animation': false,
    'maintainAspectRatio': false,
    'scales': <String, Object?>{
      'y': <String, Object?>{'min': 0, 'max': 4},
    },
  },
};

Widget _view(_Log log, int step) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: 400,
      height: 300,
      child: ChartView.raw(updateMode: 'none', config: _config(log, step)),
    ),
  ),
);

Chart _chart(WidgetTester tester) => Chart.getChart(
  tester.renderObject<RenderChartHost>(find.byType(ChartHost)).canvas,
)!;

/// The global position of the point at [index].
Offset _point(WidgetTester tester, int index) {
  final point = _chart(tester).getDatasetMeta(0).data[index] as Element;
  return tester.getTopLeft(find.byType(ChartView)) + Offset(point.x, point.y);
}

Future<TestGesture> _mouse(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(mouse.removePointer);
  await mouse.addPointer(location: const Offset(399, 299));
  return mouse;
}

void main() {
  group('adapt-live-mouse-move', () {
    testWidgets('each frame of a live chart has one hover pass and one draw', (
      tester,
    ) async {
      final log = _Log();
      await tester.pumpWidget(_view(log, 0));
      await tester.pumpWidget(_view(log, 1));
      final mouse = await _mouse(tester);

      for (var step = 2; step < 8; step++) {
        await mouse.moveTo(_point(tester, 1) + Offset(step * .1, 0));
        log.clear();

        await tester.pumpWidget(_view(log, step));

        expect(log.events, ['mousemove replay'], reason: 'step $step');
        expect(log.draws, 1, reason: 'step $step');
        expect(_chart(tester).getActiveElements().single.index, 1);
        expect(_chart(tester).tooltip!.opacity, greaterThan(0));
      }
    });

    testWidgets('a chart with no config update handles the move in its frame', (
      tester,
    ) async {
      final log = _Log();
      await tester.pumpWidget(_view(log, 0));
      final mouse = await _mouse(tester);
      await mouse.moveTo(_point(tester, 1));
      log.clear();

      await tester.pump();

      expect(log.events, ['mousemove real']);
      expect(log.draws, 1);
      expect(_chart(tester).getActiveElements().single.index, 1);
    });

    testWidgets('a chart with an old config update handles the move in its '
        'frame', (tester) async {
      final log = _Log();
      await tester.pumpWidget(_view(log, 0));
      await tester.pumpWidget(_view(log, 1));
      await tester.pump(const Duration(milliseconds: 200));
      final mouse = await _mouse(tester);
      await mouse.moveTo(_point(tester, 1));
      log.clear();

      await tester.pump();

      expect(log.events, ['mousemove real']);
      expect(log.draws, 1);
    });

    testWidgets('a live chart that stops releases the move after its frame', (
      tester,
    ) async {
      final log = _Log();
      await tester.pumpWidget(_view(log, 0));
      await tester.pumpWidget(_view(log, 1));
      final mouse = await _mouse(tester);
      await mouse.moveTo(_point(tester, 1));
      log.clear();

      // No new config: no update takes the move in this frame.
      await tester.pump();

      expect(log.events, ['mousemove real']);
      expect(log.draws, 1);
      expect(_chart(tester).getActiveElements().single.index, 1);
    });
  });
}
