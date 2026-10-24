// Original code, not ported from Chart.js: chart host input reference tests.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.dom.dart';
import 'package:flutter_chartjs_port/src/index.dart' show defaults;
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart';
import 'chart_host_input_reference.dart';

// The input path of the legend and the tooltip against a build of the
// pinned Chart.js (Chart.js ADR 0037, section 17): the chart host, the
// throttled proxies, `_eventHandler`, the legend and the tooltip.
//
// The generator tool/reference/chart_host_input_reference.mjs runs each case
// on a line chart of the pinned build. It gives the DOM events that Chrome
// sends to the canvas for each gesture action (sections 6 to 9), and feeds
// the chart events of each frame to `_eventHandler` in the order of the
// throttle (section 11). This test makes the same chart with acquireChart
// and drives each action as a Flutter pointer event through the real
// ChartHost. The touch rules of the model come from the device check P4 of
// Chart.js ADR 0037 (sections 6 and 8): no event for a move with no change,
// no `touchmove` inside the slop limit, the cancel at the pan begin, the
// compatibility events of a tap at the down position (at the up position
// for a stylus, P4 row STN10) and of a long press at the down position,
// and the stylus as a touch-like kind. A step of a case is one frame: its
// actions, then one pump. The test compares after each step:
//
// - `dom`: the DOM events that the host sent to the canvas, as `[type, x,
//   y]` with the position of getRelativePosition. A listener of each type
//   of [_domTypes] records them. The host sends an event only for a type
//   with a listener, and no other host rule reads the listeners.
// - `events`: the chart events of the inline plugin `log`
//   (`beforeEvent`), as `[type, native type, x, y, replay]`.
// - `active`, `tooltip`: `chart.getActiveElements()` and
//   `chart.tooltip.getActiveElements()`, as `[datasetIndex, index]`.
// - `opacity`: `chart.tooltip.opacity`.
// - `legend`: the legend log of the step.
// - `visible`: `chart.isDatasetVisible(i)` of each dataset.
// - `lastEvent`: `chart._lastEvent` (`lastEvent` in the port, Chart.js ADR
//   0012) as `[type, native type, x, y]`, or null (input spec section
//   4.4).
//
// Each case ends with `chart.update()`, which replays `_lastEvent`
// (core.controller.js:529-532), and compares the chart events of that
// update (`replay`). Then releaseCharts unmounts the host: the
// compatibility mouse ends, and the count of the global pointer routes is
// the count before the first step (section 15, input spec section 4.4 case
// 14).

/// Each DOM event type that the host sends (Chart.js ADR 0037, section 6).
const List<String> _domTypes = [
  'pointerover',
  'pointerenter',
  'pointerdown',
  'pointermove',
  'pointerup',
  'pointercancel',
  'pointerout',
  'pointerleave',
  'touchstart',
  'touchmove',
  'touchend',
  'touchcancel',
  'mouseover',
  'mouseenter',
  'mousemove',
  'mousedown',
  'mouseup',
  'click',
  'mouseout',
  'mouseleave',
  'wheel',
];

/// The logs of one case.
final class _Logs {
  final List<NativeEvent> dom = [];
  final List<Object?> events = [];
  final List<String> legend = [];

  void clear() {
    dom.clear();
    events.clear();
    legend.clear();
  }
}

/// The named functions of the configs of the generator, with the same
/// bodies, for the logs [logs].
Map<String, Object?> _functions(_Logs logs) => {
  // (chart, args) => { const e = args.event; events.push([e.type,
  //   e.native.type, e.x, e.y, args.replay === true]); }
  'logEvent': (Object? chart, Object? args) {
    final e = jsGet(args, 'event')! as types.ChartEvent;
    logs.events.add([
      e.type,
      e.native!.type,
      e.x,
      e.y,
      jsGet(args, 'replay') == true,
    ]);
  },
  // (e, item) => { legend.push(`hover:${e.type}:${item.text}`); }
  'legendHover': (Object? e, Object? item) {
    logs.legend.add(_entry('hover', e, item));
  },
  // (e, item) => { legend.push(`leave:${e.type}:${item.text}`); }
  'legendLeave': (Object? e, Object? item) {
    logs.legend.add(_entry('leave', e, item));
  },
  // function (e, item, legendBox) {
  //   legend.push(`click:${e.type}:${item.text}`);
  //   C.Chart.defaults.plugins.legend.onClick.call(this, e, item,
  //     legendBox); }
  'legendClick': (Object? e, Object? item, Object? legendBox) {
    logs.legend.add(_entry('click', e, item));
    final legend = jsGet(jsGet(defaults, 'plugins'), 'legend');
    jsCall(jsGet(legend, 'onClick'), [e, item, legendBox]);
  },
};

/// `<name>:<e.type>:<item.text>`.
String _entry(String name, Object? e, Object? item) =>
    '$name:${(e! as types.ChartEvent).type}:'
    '${jsToString(jsGet(item, 'text'))}';

/// `[datasetIndex, index]` of each active element of [elements].
List<Object?> _activeItems(List<types.ActiveElement> elements) => [
  for (final element in elements) [element.datasetIndex, element.index],
];

/// The observation of [chart] after a step (the keys of the generator).
Map<String, Object?> _observe(Chart chart, _Logs logs) {
  final tooltip = chart.tooltip!;
  final lastEvent = chart.lastEvent;
  final datasets = chart.data['datasets']! as List<Object?>;
  return {
    'dom': [
      for (final native in logs.dom)
        () {
          final p = getRelativePosition(native, chart);
          return [native.type, p.x, p.y];
        }(),
    ],
    'events': List.of(logs.events),
    'active': _activeItems(chart.getActiveElements()),
    'tooltip': _activeItems(tooltip.getActiveElements()),
    'opacity': tooltip.opacity,
    'legend': List.of(logs.legend),
    'visible': [
      for (var d = 0; d < datasets.length; d++)
        chart.isDatasetVisible(d.toDouble()),
    ],
    'lastEvent': lastEvent == null
        ? null
        : [lastEvent.type, lastEvent.native!.type, lastEvent.x, lastEvent.y],
  };
}

/// The pointers of a case: one touch-like pointer and one mouse pointer at
/// a time, as in the generator. A `touchDown` action with the fourth item
/// `stylus` puts down a stylus, which gives the touch rows (Chart.js ADR
/// 0037, section 6).
final class _Pointers {
  _Pointers(this.tester, this.origin);

  final WidgetTester tester;

  /// The global position of the canvas origin.
  final Offset origin;

  TestGesture? touch;
  TestGesture? mouse;

  Offset _at(List<Object?> action) =>
      origin +
      Offset(
        (action[1]! as num).toDouble(),
        (action[2]! as num).toDouble(),
      );

  /// Runs the actions of [step] and pumps one frame. A `wait` action gives
  /// the duration of the pump. The generator keeps a `wait` alone in its
  /// step.
  Future<void> run(List<Object?> step) async {
    var wait = Duration.zero;
    for (final item in step) {
      final action = item! as List<Object?>;
      switch (action[0]) {
        case 'touchDown':
          expect(touch, isNull, reason: 'one touch pointer at a time');
          touch = await tester.startGesture(
            _at(action),
            kind: action.length > 3 && action[3] == 'stylus'
                ? PointerDeviceKind.stylus
                : PointerDeviceKind.touch,
          );
        case 'touchMove':
          await touch!.moveTo(_at(action));
        case 'touchUp':
          await touch!.up();
          touch = null;
        case 'wait':
          wait = Duration(milliseconds: (action[1]! as num).toInt());
        case 'mouseAdd':
          expect(mouse, isNull, reason: 'one mouse pointer at a time');
          mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
          await mouse!.addPointer(location: _at(action));
        case 'mouseMove':
          await mouse!.moveTo(_at(action));
        case 'mouseRemove':
          await mouse!.removePointer();
          mouse = null;
        default:
          throw ArgumentError.value(action[0], 'action', 'Not an action');
      }
    }
    await tester.pump(wait);
  }
}

void main() {
  testReferenceOrigin(
    node: chartHostInputReferenceNode,
    arch: chartHostInputReferenceArch,
    dist: chartHostInputReferenceDist,
    commit: chartHostInputReferenceCommit,
  );

  testReferenceWidths(chartHostInputReferenceWidths);

  for (final c in chartHostInputReference) {
    testWidgets(c.name, (tester) async {
      final logs = _Logs();
      final chart = acquireChart(
        copyReference(c.config, _functions(logs))! as AnyObject,
        copyReference(c.options)! as AnyObject,
      );
      final canvas = chart.canvas!;
      for (final type in _domTypes) {
        addCanvasEventListener(canvas, type, logs.dom.add);
      }
      await tester.pump();
      final host = tester.renderObject<RenderChartHost>(find.byType(ChartHost));
      expect((host.size.width, host.size.height), (512.0, 512.0));
      final routes = tester.binding.pointerRouter.debugGlobalRouteCount;
      expect(RenderChartHost.debugCompatibilityMouseOwner, isNull);
      // The model puts the cancel events of a pan at the client point
      // (0, 0), the canvas origin.
      expect(host.localToGlobal(Offset.zero), Offset.zero);
      final pointers = _Pointers(tester, host.localToGlobal(Offset.zero));

      final steps = c.expected['steps']! as List<Object?>;
      final observations = c.expected['observations']! as List<Object?>;
      expect(steps, hasLength(observations.length));
      for (var i = 0; i < steps.length; i++) {
        logs.clear();
        await pointers.run(steps[i]! as List<Object?>);
        final observed = _observe(chart, logs);
        final expected = observations[i]! as Map<String, Object?>;
        expect(observed.keys, expected.keys, reason: 'step $i: the keys');
        for (final key in expected.keys) {
          expect(
            observed[key],
            referenceMatcher(expected[key]),
            reason: 'step $i ${steps[i]}: $key',
          );
        }
      }

      logs.clear();
      chart.update();
      expect(
        logs.events,
        referenceMatcher(c.expected['replay']),
        reason: 'the replay of _lastEvent',
      );

      releaseCharts();
      await tester.pump();
      expect(find.byType(ChartHost), findsNothing);
      expect(RenderChartHost.debugCompatibilityMouseOwner, isNull);
      expect(tester.binding.pointerRouter.debugGlobalRouteCount, routes);
      if (pointers.touch case final touch?) {
        await touch.up();
      }
      if (pointers.mouse case final mouse?) {
        await mouse.removePointer();
      }
    });
  }
}
