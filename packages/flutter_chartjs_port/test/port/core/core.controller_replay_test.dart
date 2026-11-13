// Original code, not ported from Chart.js: one draw for an update replay.
@TestOn('vm')
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/platform/chart_host.dart'
    show dispatchCanvasEvent;
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
import 'package:flutter_chartjs_port/src/types/plugin.dart';
import 'package:flutter_test/flutter_test.dart';

/// The calls of each hook of the counting plugin, and of the callbacks.
final class _Counts() {
  final Map<String, int> _calls = <String, int>{};

  /// One entry for each `afterEvent`: the event type, and how it arrived.
  final List<String> events = <String>[];

  void hit(String name) => _calls[name] = this[name] + 1;

  int operator [](String name) => _calls[name] ?? 0;

  void clear() {
    _calls.clear();
    events.clear();
  }
}

const _hooks = <String>[
  'beforeRender',
  'beforeDraw',
  'afterDraw',
  'afterRender',
  'beforeEvent',
  'afterEvent',
];

/// A line chart with markers and the tooltip of the defaults. [animation] is
/// the `options.animation` of the chart. `false` is the form that the double
/// draw of upstream occurs with on each update.
Chart _chart(
  _Counts counts, {
  Object? animation = false,
  Map<String, Object?>? transitions,
  Map<String, Object?>? plugins,
}) => acquireChart(<String, Object?>{
  'type': 'line',
  'plugins': <Object?>[
    <String, Object?>{
      'id': 'counting',
      'supportsDataUpdates': true,
      for (final hook in _hooks)
        hook: (Object? chart, Object? args, Object? options) {
          counts.hit(hook);
          if (hook == 'afterEvent') {
            final event = args! as EventHookArgs;
            counts.events.add(
              '${event.event!.type} '
              '${event.replay == true ? 'replay' : 'real'}',
            );
          }
        },
    },
  ],
  'data': <String, Object?>{
    'labels': <Object?>['a', 'b', 'c'],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'values',
        'data': <Object?>[1, 2, 3],
        'pointRadius': 3,
      },
    ],
  },
  'options': <String, Object?>{
    'animation': animation,
    'transitions': ?transitions,
    'plugins': ?plugins,
    'onHover': (Object? event, Object? active, Object? chart) {
      counts.hit('onHover');
    },
    'scales': <String, Object?>{
      'y': <String, Object?>{'min': 0, 'max': 4},
    },
  },
});

/// Moves the mouse onto the second point. Each later update replays this
/// event, and then the counts start at zero.
Future<void> _hover(Chart chart, _Counts counts) async {
  final point = chart.getDatasetMeta(0).data[1] as Element;
  await triggerMouseEvent(chart, 'mousemove', <String, Object?>{
    'x': point.x,
    'y': point.y,
  });
  expect(chart.lastEvent, isNotNull);
  expect(chart.getActiveElements(), hasLength(1));
  counts.clear();
}

/// The RGBA bytes of the bitmap of [chart].
Future<Uint8List> _pixels(Chart chart) async {
  final url = await chart.toBase64Image();
  final png = Uri.parse(url).data!.contentAsBytes();
  final codec = await ui.instantiateImageCodec(png);
  final frame = await codec.getNextFrame();
  final data = (await frame.image.toByteData())!;
  frame.image.dispose();
  codec.dispose();
  return data.buffer.asUint8List();
}

void main() {
  tearDown(releaseCharts);

  group('adapt-replay-single-draw', () {
    testWidgets('update draws once and still replays the event', (
      tester,
    ) async {
      final counts = _Counts();
      final chart = _chart(counts);
      await _hover(chart, counts);

      chart.update('none');

      expect(counts['beforeEvent'], 1);
      expect(counts['afterEvent'], 1);
      expect(counts['onHover'], 1);
      expect(counts['beforeRender'], 1);
      expect(counts['beforeDraw'], 1);
      expect(counts['afterDraw'], 1);
      expect(counts['afterRender'], 1);
      expect(chart.getActiveElements(), hasLength(1));
      expect(chart.tooltip!.opacity, greaterThan(0));
    });

    testWidgets('updateData draws once and still replays the event', (
      tester,
    ) async {
      final counts = _Counts();
      final chart = _chart(counts);
      await _hover(chart, counts);
      chart.update('none');
      counts.clear();

      expect(chart.updateData(), isTrue);

      expect(counts['afterEvent'], 1);
      expect(counts['beforeRender'], 1);
      expect(counts['beforeDraw'], 1);
      expect(counts['afterDraw'], 1);
      expect(chart.getActiveElements(), hasLength(1));
    });

    testWidgets('onComplete runs once for an update with no animation', (
      tester,
    ) async {
      final counts = _Counts();
      final chart = _chart(
        counts,
        animation: <String, Object?>{
          'duration': 0,
          'onComplete': (Object? event) {
            counts.hit('onComplete');
          },
        },
        transitions: <String, Object?>{
          'active': <String, Object?>{
            'animation': <String, Object?>{'duration': 0},
          },
        },
        plugins: <String, Object?>{
          'tooltip': <String, Object?>{'animation': false},
        },
      );
      await _hover(chart, counts);

      chart.update('none');

      expect(counts['afterEvent'], 1);
      expect(counts['afterDraw'], 1);
      expect(counts['afterRender'], 1);
      expect(counts['onComplete'], 1);
    });

    testWidgets('a replay outside update draws by itself, as upstream', (
      tester,
    ) async {
      final counts = _Counts();
      final chart = _chart(counts);
      await _hover(chart, counts);

      chart.eventHandler(chart.lastEvent!, true);

      expect(counts['afterEvent'], 1);
      expect(counts['beforeRender'], 1);
      expect(counts['afterDraw'], 1);
    });

    testWidgets('a new mouse event still draws', (tester) async {
      final counts = _Counts();
      final chart = _chart(counts);
      await _hover(chart, counts);
      final point = chart.getDatasetMeta(0).data[2] as Element;

      await triggerMouseEvent(chart, 'mousemove', <String, Object?>{
        'x': point.x,
        'y': point.y,
      });

      expect(counts['afterEvent'], 1);
      expect(counts['afterDraw'], 1);
      expect(chart.getActiveElements().single.index, 2);
    });

    testWidgets('a queued animation keeps both render calls, as upstream', (
      tester,
    ) async {
      final counts = _Counts();
      // The elements leave their start animation before the mouse moves.
      final chart =
          _chart(counts, animation: <String, Object?>{'duration': 1000})
            ..stop()
            ..update('none');
      await _hover(chart, counts);

      chart.update();

      // The replay and the update each render. Each starts the animator, and
      // neither draws in this call (core.controller.js render).
      expect(counts['afterEvent'], 1);
      expect(counts['beforeRender'], 2);
      expect(counts['beforeDraw'], 0);
      chart.stop();
    });

    testWidgets('one draw gives the pixels of the two draws of upstream', (
      tester,
    ) async {
      final counts = _Counts();
      final chart = _chart(counts);
      await _hover(chart, counts);

      chart.update('none');
      expect(counts['afterDraw'], 1);
      final one = await tester.runAsync(() => _pixels(chart));

      // The second draw of upstream, on the same state.
      chart.draw();
      final two = await tester.runAsync(() => _pixels(chart));

      expect(chart.tooltip!.opacity, greaterThan(0));
      expect(one!.any((byte) => byte != 0), isTrue);
      expect(two, equals(one));
    });
  });

  group('adapt-live-mouse-move', () {
    /// A chart whose owner holds each mouse move for the update of its frame.
    Chart heldChart(_Counts counts, {Object? animation = false}) =>
        _chart(counts, animation: animation)..holdMouseMove = () => true;

    /// Sends the event to the canvas and runs the frame of its listener.
    Future<void> send(
      WidgetTester tester,
      Chart chart,
      String type,
      int index,
    ) async {
      final point = chart.getDatasetMeta(0).data[index] as Element;
      dispatchCanvasEvent(
        chart.canvas!,
        NativeEvent(
          type: type,
          offsetX: point.x,
          offsetY: point.y,
          target: chart.canvas,
        ),
      );
      await tester.pump();
    }

    testWidgets('update handles a held move as its one replay', (tester) async {
      final counts = _Counts();
      final chart = heldChart(counts);
      counts.clear();

      await send(tester, chart, 'mousemove', 1);
      expect(counts.events, isEmpty);
      expect(chart.getActiveElements(), isEmpty);

      chart.update('none');

      expect(counts.events, ['mousemove replay']);
      expect(counts['beforeRender'], 1);
      expect(counts['afterDraw'], 1);
      expect(chart.getActiveElements().single.index, 1);
      expect(chart.tooltip!.opacity, greaterThan(0));
      expect(chart.lastEvent, isNotNull);
    });

    testWidgets('updateData handles a held move as its one replay', (
      tester,
    ) async {
      final counts = _Counts();
      final chart = heldChart(counts);
      await send(tester, chart, 'mousemove', 1);
      counts.clear();

      expect(chart.updateData(), isTrue);

      expect(counts.events, ['mousemove replay']);
      expect(counts['afterDraw'], 1);
      expect(chart.getActiveElements().single.index, 1);
    });

    testWidgets('a release handles a held move once, as a real event', (
      tester,
    ) async {
      final counts = _Counts();
      final chart = heldChart(counts);
      counts.clear();
      await send(tester, chart, 'mousemove', 1);

      chart.releaseHeldMove();
      expect(counts.events, ['mousemove real']);
      expect(counts['afterDraw'], 1);
      expect(chart.getActiveElements().single.index, 1);

      chart.releaseHeldMove();
      expect(counts.events, ['mousemove real']);
    });

    testWidgets('another event type releases the held move first', (
      tester,
    ) async {
      final counts = _Counts();
      final chart = heldChart(counts);
      counts.clear();
      await send(tester, chart, 'mousemove', 1);

      await send(tester, chart, 'mouseout', 1);

      expect(counts.events, ['mousemove real', 'mouseout real']);
      expect(chart.getActiveElements(), isEmpty);
    });

    testWidgets('a queued animation does not hold the move', (tester) async {
      final counts = _Counts();
      // The elements leave their start animation before the mouse moves.
      final chart =
          heldChart(counts, animation: <String, Object?>{'duration': 1000})
            ..stop()
            ..update('none')
            ..update();
      counts.clear();

      await send(tester, chart, 'mousemove', 1);

      expect(counts.events, ['mousemove real']);
      chart.stop();
    });

    testWidgets('a held move ends the ignored replays of the tooltip', (
      tester,
    ) async {
      final counts = _Counts();
      final chart = heldChart(counts);
      final tooltip = chart.tooltip!
        ..setActiveElements(
          <Object?>[
            <String, Object?>{'datasetIndex': 0, 'index': 0},
          ],
          <String, Object?>{'x': 0, 'y': 0},
        );
      expect(tooltip.getActiveElements().single.index, 0);

      await send(tester, chart, 'mousemove', 2);
      chart.update('none');

      expect(tooltip.getActiveElements().single.index, 2);
    });

    testWidgets('destroy drops a held move', (tester) async {
      final counts = _Counts();
      final chart = heldChart(counts);
      await send(tester, chart, 'mousemove', 1);
      counts.clear();

      chart
        ..destroy()
        ..releaseHeldMove();

      expect(counts.events, isEmpty);
    });
  });
}
