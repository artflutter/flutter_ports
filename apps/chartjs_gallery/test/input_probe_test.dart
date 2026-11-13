// Original code, not ported from Chart.js: the tests of the input probe of Chart.js ADR 0112.
// The header text names the probe and the ADR, and has no URI.
// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:chartjs_gallery/main_input_probe.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The JSON of a line `PROBE {json}`.
Map<String, Object?> _probe(String line) {
  expect(line, startsWith('PROBE '));
  return jsonDecode(line.substring('PROBE '.length)) as Map<String, Object?>;
}

/// The statistics [key] of a [probe] line.
Map<String, Object?> _stats(Map<String, Object?> probe, String key) =>
    probe[key]! as Map<String, Object?>;

void main() {
  testWidgets('counts the input, the updates and the draws of each frame', (
    tester,
  ) async {
    final lines = <String>[];
    final saved = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null && message.startsWith('PROBE ')) lines.add(message);
    };
    addTearDown(() => debugPrint = saved);

    await tester.pumpWidget(const InputProbeApp());
    await tester.pumpAndSettle();
    final state = tester.state<InputProbePageState>(
      find.byType(InputProbePage),
    );
    final chart = state.chart!;

    // The first second: the first frames drew the chart.
    await tester.pump(const Duration(seconds: 1));
    expect(lines, hasLength(1));
    final start = _probe(lines.single);
    expect(start['points'], inputProbePoints);
    expect(_stats(start, 'draws')['max'], greaterThanOrEqualTo(1));
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('probe.summary'))).data,
      contains('draws: mean'),
    );
    // The report started a new window. Its frame is the rebuild of the
    // summary: it has no work.
    expect(state.recorder.frames.where((frame) => frame.active), isEmpty);

    final origin = tester.getTopLeft(find.byKey(const ValueKey('probe.host')));
    final area = chart.chartArea!;
    Offset at(double fx, double fy) =>
        origin +
        Offset(
          (area.left + fx * (area.right - area.left)).roundToDouble(),
          (area.top + fy * (area.bottom - area.top)).roundToDouble(),
        );

    // Two fingers go down in one frame.
    final first = TestPointer(); // the pointer 1
    final second = TestPointer(2);
    await tester.sendEventToBinding(first.down(at(0.4, 0.5)));
    await tester.sendEventToBinding(second.down(at(0.6, 0.5)));
    SchedulerBinding.instance.scheduleFrame();
    await tester.pump();
    expect(state.recorder.frames.last.movesByPointer, {1: 0, 2: 0});

    // Three moves in one frame, two of the first finger and one of the
    // second: each is one step of the pinch, with one update and its draw.
    await tester.sendEventToBinding(first.move(at(0.38, 0.5)));
    await tester.sendEventToBinding(second.move(at(0.62, 0.5)));
    await tester.sendEventToBinding(first.move(at(0.36, 0.5)));
    SchedulerBinding.instance.scheduleFrame();
    await tester.pump();
    final pinch = state.recorder.frames.last;
    expect(pinch.movesByPointer, {1: 2, 2: 1});
    expect(pinch.moves, 3);
    expect(pinch.updates, 3);
    expect(pinch.draws, greaterThanOrEqualTo(3));
    expect(pinch.scrolls, 0);

    // A finger that goes up still counts in its frame, with no move.
    await tester.sendEventToBinding(first.up());
    await tester.sendEventToBinding(second.up());
    SchedulerBinding.instance.scheduleFrame();
    await tester.pump();
    expect(state.recorder.frames.last.movesByPointer, {1: 0, 2: 0});
    SchedulerBinding.instance.scheduleFrame();
    await tester.pump();
    expect(state.recorder.frames.last.movesByPointer, isEmpty);

    // Two wheel events in one frame: two zoom steps.
    final mouse = TestPointer(3, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(mouse.addPointer(location: at(0.5, 0.5)));
    await tester.sendEventToBinding(mouse.hover(at(0.5, 0.5)));
    SchedulerBinding.instance.scheduleFrame();
    await tester.pump();
    await tester.sendEventToBinding(mouse.scroll(const Offset(0, -100)));
    await tester.sendEventToBinding(mouse.scroll(const Offset(0, -100)));
    SchedulerBinding.instance.scheduleFrame();
    await tester.pump();
    final wheel = state.recorder.frames.last;
    expect(wheel.scrolls, 2);
    expect(wheel.updates, 2);
    expect(wheel.draws, greaterThanOrEqualTo(2));
    expect(wheel.movesByPointer, isEmpty);
    await tester.sendEventToBinding(
      mouse.removePointer(location: at(0.5, 0.5)),
    );

    // Two trackpad updates in one frame: the host gives each as a wheel
    // (Chart.js ADR 0137), and each wheel zooms the chart.
    final pad = TestPointer(4, PointerDeviceKind.trackpad);
    await tester.sendEventToBinding(pad.panZoomStart(at(0.5, 0.5)));
    await tester.sendEventToBinding(
      pad.panZoomUpdate(at(0.5, 0.5), pan: const Offset(5, 0)),
    );
    await tester.sendEventToBinding(
      pad.panZoomUpdate(at(0.5, 0.5), pan: const Offset(10, 0)),
    );
    SchedulerBinding.instance.scheduleFrame();
    await tester.pump();
    final trackpad = state.recorder.frames.last;
    expect(trackpad.panZooms, 2);
    expect(trackpad.updates, 2);
    await tester.sendEventToBinding(pad.panZoomEnd());

    // The next second prints the counts of these frames.
    await tester.pump(const Duration(seconds: 1));
    expect(lines, hasLength(2));
    final probe = _probe(lines.last);
    expect(probe['pointers'], 2);
    expect(_stats(probe, 'movesPerPointer')['max'], 2);
    final hist = _stats(probe, 'movesPerPointer')['hist']! as List<Object?>;
    expect(hist.sublist(1), [1, 1, 0]);
    expect(_stats(probe, 'moves')['max'], 3);
    expect(_stats(probe, 'scrolls')['max'], 2);
    expect(_stats(probe, 'panZooms')['max'], 2);
    expect(_stats(probe, 'updates')['max'], 3);
    expect(_stats(probe, 'draws')['max'], greaterThanOrEqualTo(3));
    expect(probe['active'], lessThanOrEqualTo(probe['frames']! as int));
    expect(probe['frameNumbers'], hasLength(2));
    expect(probe, contains('buildMs'));

    // A second with no input and no chart work prints nothing.
    await tester.pump(const Duration(seconds: 1));
    expect(lines, hasLength(2));
  });

  test('the summary of the frames of one window', () {
    InputProbeFrame frame(
      Map<int, int> moves, {
      int scrolls = 0,
      int updates = 0,
      int draws = 0,
    }) => InputProbeFrame(
      number: 7,
      movesByPointer: moves,
      scrolls: scrolls,
      panZooms: 0,
      updates: updates,
      draws: draws,
    );

    final summary = inputProbeSummary([
      frame({1: 1, 2: 1}, updates: 2, draws: 2),
      frame({1: 4, 2: 2}, updates: 6, draws: 6),
      frame({}),
      frame({}, scrolls: 3, updates: 3, draws: 3),
    ], const []);

    expect(summary['frames'], 4);
    expect(summary['active'], 3);
    expect(summary['pointers'], 2);
    expect(summary['movesPerPointer'], {
      'mean': 2.0,
      'max': 4,
      'hist': [0, 2, 1, 1],
    });
    expect(summary['moves'], {
      'mean': 2.67,
      'max': 6,
      'hist': [1, 0, 1, 1],
    });
    expect(summary['scrolls'], {
      'mean': 1.0,
      'max': 3,
      'hist': [2, 0, 0, 1],
    });
    expect(summary['updates'], {
      'mean': 3.67,
      'max': 6,
      'hist': [0, 0, 1, 2],
    });
    expect(summary['buildMs'], isNull);
    expect(inputProbeText(summary), contains('3 of 4 frames with work'));
  });

  testWidgets('the plot area stays in place while the chart zooms and pans', (
    tester,
  ) async {
    await tester.pumpWidget(const InputProbeApp());
    await tester.pumpAndSettle();
    final chart = tester
        .state<InputProbePageState>(find.byType(InputProbePage))
        .chart!;
    (double, double, double, double) area() {
      final a = chart.chartArea!;
      return (a.left, a.top, a.right, a.bottom);
    }

    final first = area();
    final x = chart.scales['x']!;
    final y = chart.scales['y']!;
    final firstRange = (x.min, x.max, y.min, y.max);
    expect(y.width, inputProbeYAxisWidth);

    // Steps that give the bounds many decimals and new tick steps: without
    // the options of the probe, the axis sizes change in most of them. A
    // zoom by z sets the range to range * (2 - z), so each z stays below 2.
    final steps = <void Function()>[
      () => chart.pan(const PanAmount(x: 37.3, y: 11.7)),
      () => chart.zoom(const ZoomAmount.all(1.7)),
      () => chart.pan(const PanAmount(x: -123.9, y: -41.1)),
      () => chart.zoom(const ZoomAmount.all(1.4)),
      () => chart.pan(const PanAmount(x: 5.5, y: 77.7)),
      () => chart.zoom(const ZoomAmount.all(0.6)),
      () => chart.pan(const PanAmount(x: 301.1, y: -3.3)),
    ];
    for (final step in steps) {
      step();
      await tester.pump();
      expect(area(), first);
      expect(y.width, inputProbeYAxisWidth);
    }
    expect((x.min, x.max, y.min, y.max), isNot(firstRange));
  });
}
