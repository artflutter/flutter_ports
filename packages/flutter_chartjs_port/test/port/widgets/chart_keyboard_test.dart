// Original code, not ported from Chart.js: tests of the keyboard of ChartView.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart' show triggerMouseEvent;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_chartjs_port/src/platform/platform.flutter.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/widgets/chart_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart' show drawCalls;

// Chart.js ADR 0051: the keyboard of ChartView. The chart is one focus stop
// (section 1). The keys move a virtual mouse over the targets of section 2
// with the table of section 3: each move is a `mousemove` at the target
// point through `dispatchCanvasEvent` (section 4). The key events of
// `options.events` go to the canvas listeners first (section 5), and the
// widget plugin `$chartView` draws the focus ring (section 6).
//
// The oracle of a key move is a mouse at the same point: `triggerMouseEvent`
// of chartjs_test_utils on a second ChartView of the same config and the
// same size. flutter_test_config.dart registers the built-in components:
// each chart has the legend and the tooltip.

/// The tag of the legend group in [_Target].
const int _legend = -1;

/// A target: the group ([_legend] or a dataset index) and the item index.
typedef _Target = (int group, int item);

/// A key and the target that it reaches.
typedef _Move = (LogicalKeyboardKey key, _Target target);

/// The moves of the oracle test: each key of the table of section 3 that
/// moves, on a chart with 2 legend items or more and 2 datasets of 3
/// values.
const List<_Move> _moves = [
  (LogicalKeyboardKey.arrowDown, (_legend, 0)),
  (LogicalKeyboardKey.arrowRight, (_legend, 1)),
  (LogicalKeyboardKey.arrowDown, (0, 1)),
  (LogicalKeyboardKey.arrowRight, (0, 2)),
  (LogicalKeyboardKey.arrowLeft, (0, 1)),
  (LogicalKeyboardKey.end, (0, 2)),
  (LogicalKeyboardKey.home, (0, 0)),
  (LogicalKeyboardKey.arrowDown, (1, 0)),
  (LogicalKeyboardKey.arrowUp, (0, 0)),
  (LogicalKeyboardKey.arrowUp, (_legend, 0)),
];

/// A chart config of [type]: labels `a` to `c`, 2 datasets, no animation,
/// no aspect ratio. The legend logs its `onHover` and `onLeave` calls in
/// [log]. [options] and [legend] add keys to the options and to the legend
/// options.
Map<String, Object?> _config(
  String type, {
  List<String>? log,
  Map<String, Object?> options = const {},
  Map<String, Object?> legend = const {},
  List<Object?>? plugins,
}) {
  void entry(String name, Object? e, Object? item) {
    log?.add('$name ${(e! as types.ChartEvent).type} ${jsGet(item, 'text')}');
  }

  return <String, Object?>{
    'type': type,
    'data': <String, Object?>{
      'labels': <Object?>['a', 'b', 'c'],
      'datasets': <Object?>[
        <String, Object?>{
          'label': 'd0',
          'data': <Object?>[3, 5, 4],
        },
        <String, Object?>{
          'label': 'd1',
          'data': <Object?>[4, 2, 5],
        },
      ],
    },
    'options': <String, Object?>{
      'animation': false,
      'maintainAspectRatio': false,
      'plugins': <String, Object?>{
        'legend': <String, Object?>{
          'onHover': (Object? e, Object? item, Object? legend) =>
              entry('hover', e, item),
          'onLeave': (Object? e, Object? item, Object? legend) =>
              entry('leave', e, item),
          ...legend,
        },
      },
      ...options,
    },
    'plugins': ?plugins,
  };
}

/// The chart of [config] in a box of 400 x 280 at the top left.
Widget _view(
  Map<String, Object?> config, {
  FocusNode? focusNode,
  bool autofocus = false,
  ValueChanged<Chart>? onChartCreated,
}) => SizedBox(
  width: 400,
  height: 280,
  child: ChartView.raw(
    config: config,
    focusNode: focusNode,
    autofocus: autofocus,
    onChartCreated: onChartCreated,
  ),
);

/// [child] at the top left of the test view.
Widget _top(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(alignment: Alignment.topLeft, child: child),
);

/// The keyboard chart over the oracle chart.
Widget _pair(Widget keys, Widget mouse) => _top(
  Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [keys, mouse],
  ),
);

/// The point of [target] on [chart]: the center of a legend hit box, read
/// through `types.LegendElement`, or the final center of an element.
({double x, double y}) _point(Chart chart, _Target target) {
  final (group, item) = target;
  if (group == _legend) {
    final box = chart.legend!.legendHitBoxes[item];
    double read(String key) => (box[key]! as num).toDouble();
    return (
      x: read('left') + read('width') / 2,
      y: read('top') + read('height') / 2,
    );
  }
  final element = chart.getDatasetMeta(group).data[item] as types.VisualElement;
  final center = element.getCenterPoint(true);
  return (x: center.x!, y: center.y!);
}

/// The point of [target] on [chart] as the plain object of
/// `triggerMouseEvent`.
AnyObject _at(Chart chart, _Target target) {
  final (:x, :y) = _point(chart, target);
  return <String, Object?>{'x': x, 'y': y};
}

/// The active items of a list of `getActiveElements()`.
List<String> _items(List<types.ActiveElement> active) => [
  for (final item in active) '${item.datasetIndex}:${item.index}',
];

/// The state that a mouse gives: the active elements, the tooltip items and
/// the legend callbacks of [log].
Map<String, Object?> _state(Chart chart, List<String> log) => {
  'active': _items(chart.getActiveElements()),
  'tooltip': _items(chart.tooltip!.getActiveElements()),
  'legend': List.of(log),
};

/// Sends [key] (down and up) and pumps the frame of the throttled events.
/// Gives whether the down event was handled.
Future<bool> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  final handled = await tester.sendKeyEvent(key);
  await tester.pump(const Duration(milliseconds: 16));
  return handled;
}

/// Two charts of [type] in [_pair]: the keyboard chart, focused, and the
/// oracle chart, with their legend logs.
final class _Charts {
  _Charts(this.type, {this.options = const {}, this.legend = const {}});

  final String type;
  final Map<String, Object?> options;
  final Map<String, Object?> legend;
  final FocusNode node = FocusNode(debugLabel: 'keys');
  final List<String> keysLog = [];
  final List<String> mouseLog = [];
  late Chart keys;
  late Chart mouse;

  Future<void> pump(WidgetTester tester) async {
    addTearDown(node.dispose);
    await tester.pumpWidget(
      _pair(
        _view(
          _config(type, log: keysLog, options: options, legend: legend),
          focusNode: node,
          onChartCreated: (chart) => keys = chart,
        ),
        _view(
          _config(type, log: mouseLog, options: options, legend: legend),
          onChartCreated: (chart) => mouse = chart,
        ),
      ),
    );
    node.requestFocus();
    await tester.pump();
  }

  /// [key] on the keyboard chart, then the mouse event [type] at [target] on
  /// the oracle chart.
  Future<void> both(
    WidgetTester tester,
    LogicalKeyboardKey key,
    String type,
    _Target target,
  ) async {
    await _key(tester, key);
    await triggerMouseEvent(mouse, type, _at(mouse, target));
  }

  /// [key] on the keyboard chart, then a `mouseout` at (-1, -1), outside the
  /// oracle chart: a real mouse that leaves the canvas (section 3).
  Future<void> leave(WidgetTester tester, LogicalKeyboardKey key) async {
    await _key(tester, key);
    await triggerMouseEvent(mouse, 'mouseout', <String, Object?>{
      'x': -1.0,
      'y': -1.0,
    });
  }

  Map<String, Object?> get keysState => _state(keys, keysLog);
  Map<String, Object?> get mouseState => _state(mouse, mouseLog);
}

/// The calls of the focus ring in one draw of [chart]: the last 6 calls of
/// the draw, from `save` to `restore`, when the fifth one is a `strokeRect`
/// after a `setLineDash`. Empty with no ring.
List<Object?> _ring(Chart chart) {
  final calls = [
    for (final call in drawCalls(chart))
      [jsGet(call, 'name'), ...(jsGet(call, 'args')! as List<Object?>)],
  ];
  if (calls.length < 6) return const [];
  final ring = calls.sublist(calls.length - 6);
  return ring[3].first == 'setLineDash' && ring[4].first == 'strokeRect'
      ? ring
      : const [];
}

/// The ring calls of section 6 for the rectangle ([x], [y], [w], [h]).
List<Object?> _ringCalls(double x, double y, double w, double h) => [
  ['save'],
  ['setStrokeStyle', '#666'],
  ['setLineWidth', 2.0],
  [
    'setLineDash',
    <double>[],
  ],
  ['strokeRect', x, y, w, h],
  ['restore'],
];

/// Sets the highlight strategy of the focus manager for one test.
void _highlight(FocusHighlightStrategy strategy) {
  FocusManager.instance.highlightStrategy = strategy;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

void main() {
  group('the keys give the state of a mouse at the target', () {
    for (final type in ['bar', 'line', 'doughnut', 'radar']) {
      testWidgets(type, (tester) async {
        final charts = _Charts(type);
        await charts.pump(tester);
        for (final (key, target) in _moves) {
          await charts.both(tester, key, 'mousemove', target);
          final keys = charts.keysState;
          expect(keys, charts.mouseState, reason: '$key to $target');
          if (target.$1 == _legend) {
            expect(charts.keysLog.last, startsWith('hover mousemove'));
          } else {
            expect(keys['active'], isNotEmpty, reason: '$key to $target');
          }
        }
        // Escape on legend item 0: `mouseout` outside the canvas, and the
        // legend calls `onLeave`.
        await charts.leave(tester, LogicalKeyboardKey.escape);
        expect(charts.keysLog.last, startsWith('leave mouseout'));
        expect(charts.keysState, charts.mouseState);
      });
    }

    testWidgets("the mode 'index' gives all datasets at the index", (
      tester,
    ) async {
      final charts = _Charts(
        'bar',
        options: <String, Object?>{
          'interaction': <String, Object?>{'mode': 'index'},
        },
      );
      await charts.pump(tester);
      await charts.both(
        tester,
        LogicalKeyboardKey.arrowDown,
        'mousemove',
        (_legend, 0),
      );
      await charts.both(
        tester,
        LogicalKeyboardKey.arrowRight,
        'mousemove',
        (_legend, 1),
      );
      await charts.both(
        tester,
        LogicalKeyboardKey.arrowDown,
        'mousemove',
        (0, 1),
      );
      expect(charts.keysState, charts.mouseState);
      expect(charts.keysState['active'], ['0.0:1.0', '1.0:1.0']);
      expect(charts.keysState['tooltip'], ['0.0:1.0', '1.0:1.0']);
    });
  });

  group('click', () {
    testWidgets('Enter and Space on legend item 1 toggle its dataset, and '
        'Down then skips a hidden dataset', (tester) async {
      final charts = _Charts('bar');
      await charts.pump(tester);
      final chart = charts.keys;
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(await _key(tester, LogicalKeyboardKey.enter), isTrue);
      expect(chart.isDatasetVisible(1), isFalse);
      expect(await _key(tester, LogicalKeyboardKey.space), isTrue);
      expect(chart.isDatasetVisible(1), isTrue);

      // Legend item 0 hides the dataset 0. Down goes to the dataset 1.
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(chart.isDatasetVisible(0), isFalse);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_items(chart.getActiveElements()), ['1.0:0.0']);
    });

    testWidgets('doughnut: Enter on legend item 1 toggles its data index', (
      tester,
    ) async {
      final charts = _Charts('doughnut');
      await charts.pump(tester);
      final chart = charts.keys;
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(chart.getDataVisibility(1), isFalse);
      expect(chart.isDatasetVisible(1), isTrue);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(chart.getDataVisibility(1), isTrue);
    });

    testWidgets('a custom legend onClick gets legendItems[1]', (tester) async {
      final clicks = <(Object?, types.LegendElement)>[];
      final charts = _Charts(
        'bar',
        legend: <String, Object?>{
          'onClick': (Object? e, Object? item, types.LegendElement legend) =>
              clicks.add((item, legend)),
        },
      );
      await charts.pump(tester);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(clicks, hasLength(1));
      final (item, legend) = clicks.single;
      expect(legend, same(charts.keys.legend));
      expect(item, same(legend.legendItems![1]));
      // The custom onClick hides nothing.
      expect(charts.keys.isDatasetVisible(1), isTrue);
    });

    testWidgets('Enter on an element calls options.onClick with the elements '
        'of a mouse click there', (tester) async {
      final keysClicks = <List<String>>[];
      final mouseClicks = <List<String>>[];
      Map<String, Object?> config(List<List<String>> log) => _config(
        'bar',
        options: <String, Object?>{
          'onClick': (
            types.ChartEvent event,
            List<types.ActiveElement> active,
            Chart chart,
          ) => log.add([event.type, ..._items(active)]),
        },
      );
      final keysConfig = config(keysClicks);
      final mouseConfig = config(mouseClicks);
      final node = FocusNode();
      addTearDown(node.dispose);
      late Chart mouse;
      await tester.pumpWidget(
        _pair(
          _view(keysConfig, focusNode: node),
          _view(mouseConfig, onChartCreated: (chart) => mouse = chart),
        ),
      );
      node.requestFocus();
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.enter);
      await triggerMouseEvent(mouse, 'click', _at(mouse, (0, 0)));
      expect(keysClicks, [
        ['click', '0.0:0.0'],
      ]);
      expect(keysClicks, mouseClicks);
    });

    testWidgets('a repeat of Enter gives no second click', (tester) async {
      var clicks = 0;
      final charts = _Charts(
        'bar',
        legend: <String, Object?>{
          'onClick': (Object? e, Object? item, Object? legend) => clicks++,
        },
      );
      await charts.pump(tester);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(await tester.sendKeyDownEvent(LogicalKeyboardKey.enter), isTrue);
      expect(
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter),
        isTrue,
      );
      expect(
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter),
        isTrue,
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 16));
      expect(clicks, 1);
    });
  });

  group('options.events', () {
    testWidgets("events: ['click'] gives no active element on a move, and "
        'Enter still clicks', (tester) async {
      final clicks = <List<String>>[];
      final charts = _Charts(
        'bar',
        options: <String, Object?>{
          'events': <Object?>['click'],
          'onClick': (
            types.ChartEvent event,
            List<types.ActiveElement> active,
            Chart chart,
          ) => clicks.add(_items(active)),
        },
      );
      await charts.pump(tester);
      expect(await _key(tester, LogicalKeyboardKey.arrowDown), isTrue);
      expect(await _key(tester, LogicalKeyboardKey.arrowDown), isTrue);
      expect(charts.keys.getActiveElements(), isEmpty);
      expect(charts.keys.tooltip!.getActiveElements(), isEmpty);
      expect(charts.keysLog, isEmpty);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(clicks, [
        ['0.0:0.0'],
      ]);
    });

    testWidgets('keydown, keypress and keyup reach beforeEvent with NaN x and '
        'y, and the keydown comes before the mousemove of its key', (
      tester,
    ) async {
      final events = <String>[];
      final config = _config(
        'bar',
        options: <String, Object?>{
          'events': <Object?>[
            'mousemove',
            'mouseout',
            'click',
            'keydown',
            'keypress',
            'keyup',
          ],
        },
        plugins: [
          <String, Object?>{
            'id': 'events',
            'beforeEvent': (Object? chart, Object? args, Object? options) {
              final event = jsGet(args, 'event')! as types.ChartEvent;
              events.add('${event.type} ${event.x} ${event.y}');
            },
          },
        ],
      );
      final node = FocusNode();
      addTearDown(node.dispose);
      late Chart chart;
      await tester.pumpWidget(
        _top(
          _view(config, focusNode: node, onChartCreated: (c) => chart = c),
        ),
      );
      node.requestFocus();
      await tester.pump();

      await _key(tester, LogicalKeyboardKey.arrowDown);
      final (:x, :y) = _point(chart, (_legend, 0));
      expect(events, [
        'keydown NaN NaN',
        'mousemove ${x.round().toDouble()} ${y.round().toDouble()}',
        'keyup NaN NaN',
      ]);

      // A character key gives keypress too. The table ignores it.
      events.clear();
      expect(await _key(tester, LogicalKeyboardKey.keyA), isFalse);
      expect(events, ['keydown NaN NaN', 'keypress NaN NaN', 'keyup NaN NaN']);
    });

    testWidgets('without key types in events, no key event reaches the '
        'chart', (tester) async {
      final events = <String>[];
      final config = _config(
        'bar',
        plugins: [
          <String, Object?>{
            'id': 'events',
            'beforeEvent': (Object? chart, Object? args, Object? options) {
              events.add((jsGet(args, 'event')! as types.ChartEvent).type);
            },
          },
        ],
      );
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(_top(_view(config, focusNode: node)));
      node.requestFocus();
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.keyA);
      expect(events, ['mousemove']);
      final canvas = tester
          .renderObject<RenderChartHost>(find.byType(ChartHost))
          .canvas;
      for (final type in ['keydown', 'keypress', 'keyup']) {
        expect(hasCanvasEventListener(canvas, type), isFalse);
      }
    });
  });

  group('Escape, the focus loss and the ignored keys', () {
    testWidgets('Escape clears the hover and the tooltip', (tester) async {
      final charts = _Charts('line');
      await charts.pump(tester);
      await charts.both(
        tester,
        LogicalKeyboardKey.arrowDown,
        'mousemove',
        (_legend, 0),
      );
      await charts.both(
        tester,
        LogicalKeyboardKey.arrowDown,
        'mousemove',
        (0, 0),
      );
      expect(charts.keys.getActiveElements(), isNotEmpty);
      expect(charts.keys.tooltip!.getActiveElements(), isNotEmpty);
      await charts.leave(tester, LogicalKeyboardKey.escape);
      expect(charts.keys.getActiveElements(), isEmpty);
      expect(charts.keys.tooltip!.getActiveElements(), isEmpty);
      expect(charts.keysState, charts.mouseState);
      // The target is gone: Left is ignored.
      expect(await _key(tester, LogicalKeyboardKey.arrowLeft), isFalse);
    });

    testWidgets('the focus loss clears the hover and the tooltip', (
      tester,
    ) async {
      final charts = _Charts('bar');
      await charts.pump(tester);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(charts.keys.getActiveElements(), isNotEmpty);
      charts.node.unfocus();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(charts.keys.getActiveElements(), isEmpty);
      expect(charts.keys.tooltip!.getActiveElements(), isEmpty);
      // The focus comes back with no target.
      charts.node.requestFocus();
      await tester.pump();
      expect(await _key(tester, LogicalKeyboardKey.arrowUp), isFalse);
    });

    testWidgets('the focus loss on a legend item calls the legend onLeave', (
      tester,
    ) async {
      final charts = _Charts('line');
      await charts.pump(tester);
      await charts.both(
        tester,
        LogicalKeyboardKey.arrowDown,
        'mousemove',
        (_legend, 0),
      );
      expect(charts.keysLog.last, startsWith('hover mousemove'));
      charts.node.unfocus();
      await tester.pump();
      await triggerMouseEvent(charts.mouse, 'mouseout', <String, Object?>{
        'x': -1.0,
        'y': -1.0,
      });
      expect(charts.keysLog.last, startsWith('leave mouseout'));
      expect(charts.keysState, charts.mouseState);
    });

    testWidgets('with no target, Left, Up, Home, End, Enter, Space and Escape '
        'are ignored', (tester) async {
      final charts = _Charts('bar');
      await charts.pump(tester);
      for (final key in [
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.home,
        LogicalKeyboardKey.end,
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.space,
        LogicalKeyboardKey.escape,
      ]) {
        expect(await _key(tester, key), isFalse, reason: '$key');
      }
      expect(charts.keys.getActiveElements(), isEmpty);
      expect(charts.keysLog, isEmpty);
    });

    testWidgets('a key with a modifier is ignored', (tester) async {
      final charts = _Charts('bar');
      await charts.pump(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      expect(await _key(tester, LogicalKeyboardKey.arrowDown), isFalse);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(charts.keysLog, isEmpty);
      expect(await _key(tester, LogicalKeyboardKey.arrowDown), isTrue);
    });

    testWidgets('Escape with no target reaches an ancestor DismissIntent', (
      tester,
    ) async {
      var dismissed = 0;
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (context, child) => Actions(
            actions: <Type, Action<Intent>>{
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (intent) => dismissed++,
              ),
            },
            child: Align(
              alignment: Alignment.topLeft,
              child: _view(_config('bar'), focusNode: node),
            ),
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.escape);
      expect(dismissed, 1);
      // With a target, the chart takes Escape.
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(await _key(tester, LogicalKeyboardKey.escape), isTrue);
      expect(dismissed, 1);
      await _key(tester, LogicalKeyboardKey.escape);
      expect(dismissed, 2);
      expect(node.hasPrimaryFocus, isTrue);
    });

    testWidgets('at the last target, Right moves the focus to the next '
        'focusable', (tester) async {
      final node = FocusNode(debugLabel: 'chart');
      final next = FocusNode(debugLabel: 'next');
      addTearDown(node.dispose);
      addTearDown(next.dispose);
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (context, child) => Align(
            alignment: Alignment.topLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _view(_config('bar'), focusNode: node),
                Focus(
                  focusNode: next,
                  child: const SizedBox(width: 50, height: 50),
                ),
              ],
            ),
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      expect(await _key(tester, LogicalKeyboardKey.arrowDown), isTrue);
      expect(await _key(tester, LogicalKeyboardKey.arrowRight), isTrue);
      expect(node.hasPrimaryFocus, isTrue);
      // Legend item 1 is the last target of the legend group.
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(next.hasPrimaryFocus, isTrue);
      expect(node.hasFocus, isFalse);
    });

    testWidgets('a new chart has no target', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final config = _config('bar');
      await tester.pumpWidget(_top(_view(config, focusNode: node)));
      node.requestFocus();
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(await _key(tester, LogicalKeyboardKey.arrowLeft), isTrue);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      // A new platform makes a new chart (Chart.js ADR 0049, section 4).
      await tester.pumpWidget(
        _top(
          _view({
            ...config,
            'platform': FlutterPlatform.jsClass,
          }, focusNode: node),
        ),
      );
      await tester.pump();
      expect(await _key(tester, LogicalKeyboardKey.arrowLeft), isFalse);
    });
  });

  group('the focus stop', () {
    /// A native app with the focus stops [first], [chart] and [next] in a
    /// row. [first] has the focus.
    Future<void> app(
      WidgetTester tester,
      Widget chart,
      FocusNode first,
      FocusNode next,
    ) async {
      Widget stop(FocusNode node) =>
          Focus(focusNode: node, child: const SizedBox(width: 50, height: 50));
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (context, child) => Align(
            alignment: Alignment.topLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [stop(first), chart, stop(next)],
            ),
          ),
        ),
      );
      first.requestFocus();
      await tester.pump();
    }

    testWidgets('Tab stops at the chart', (tester) async {
      final first = FocusNode();
      final node = FocusNode();
      final next = FocusNode();
      addTearDown(first.dispose);
      addTearDown(node.dispose);
      addTearDown(next.dispose);
      await app(tester, _view(_config('bar'), focusNode: node), first, next);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(node.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(next.hasPrimaryFocus, isTrue);
    });

    testWidgets('ExcludeFocus and a node that cannot take the focus give no '
        'stop', (tester) async {
      final first = FocusNode();
      final next = FocusNode();
      addTearDown(first.dispose);
      addTearDown(next.dispose);
      await app(
        tester,
        ExcludeFocus(child: _view(_config('bar'))),
        first,
        next,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(next.hasPrimaryFocus, isTrue);

      final node = FocusNode(canRequestFocus: false);
      addTearDown(node.dispose);
      await app(tester, _view(_config('bar'), focusNode: node), first, next);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(next.hasPrimaryFocus, isTrue);
      expect(node.hasFocus, isFalse);
    });

    testWidgets('the diagnostics name the focus node and autofocus', (
      tester,
    ) async {
      final node = FocusNode(debugLabel: 'chart');
      addTearDown(node.dispose);
      List<String> properties(Diagnosticable object) => [
        for (final property in object.toDiagnosticsNode().getProperties())
          if (!property.isFiltered(DiagnosticLevel.info)) property.toString(),
      ];
      expect(
        properties(
          ChartView.raw(config: const {}, focusNode: node, autofocus: true),
        ),
        [
          'type: null',
          startsWith('focusNode: FocusNode#'),
          'autofocus',
        ],
      );
      expect(properties(const ChartView.raw(config: {})), ['type: null']);
    });

    testWidgets('autofocus focuses the chart at its first build', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _top(_view(_config('bar'), focusNode: node, autofocus: true)),
      );
      await tester.pump();
      expect(node.hasPrimaryFocus, isTrue);
    });

    testWidgets('a setState in onHover of a key move and in onComplete of the '
        'render of a focus change does not throw', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      late StateSetter setOuter;
      var label = '';
      var completes = 0;
      // The hooks of the start run in the layout of the host, where a
      // setState fails (Chart.js ADR 0049, section 6). The test arms the
      // callbacks after the start.
      var armed = false;
      final config = _config(
        'bar',
        options: <String, Object?>{
          'animation': <String, Object?>{
            'duration': 0,
            'onComplete': (Object? context) {
              completes++;
              if (armed) setOuter(() => label = 'complete $completes');
            },
          },
          'onHover':
              (
                types.ChartEvent event,
                List<types.ActiveElement> active,
                Chart chart,
              ) {
                if (armed) setOuter(() => label = 'hover ${active.length}');
              },
        },
      );
      await tester.pumpWidget(
        _top(
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _view(config, focusNode: node),
                  Text(label),
                ],
              );
            },
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      armed = true;
      final before = completes;
      node.requestFocus();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(completes, before + 1);
      await tester.pump();
      expect(find.text('complete ${before + 1}'), findsOneWidget);

      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(tester.takeException(), isNull);
      await tester.pump();
      expect(find.text('hover 1'), findsOneWidget);
    });
  });

  group('the focus ring', () {
    testWidgets('a legend target and no target have the ring, a data target '
        'has none', (tester) async {
      _highlight(FocusHighlightStrategy.alwaysTraditional);
      final renders = <String>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      late Chart chart;
      final config = _config(
        'bar',
        plugins: [
          <String, Object?>{
            'id': 'renders',
            'afterRender': (Object? chart, Object? args, Object? options) =>
                renders.add('render'),
          },
        ],
      );
      await tester.pumpWidget(
        _top(
          _view(config, focusNode: node, onChartCreated: (c) => chart = c),
        ),
      );
      expect(_ring(chart), isEmpty);

      renders.clear();
      node.requestFocus();
      await tester.pump();
      // A focus change calls render().
      expect(renders, ['render']);
      expect(_ring(chart), _ringCalls(1, 1, 398, 278));

      Object? box(int item, String key) =>
          chart.legend!.legendHitBoxes[item][key];
      double ring(int item, String key, double add) =>
          (box(item, key)! as num).toDouble() + add;
      List<Object?> legendRing(int item) => _ringCalls(
        ring(item, 'left', -3),
        ring(item, 'top', -3),
        ring(item, 'width', 6),
        ring(item, 'height', 6),
      );

      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_ring(chart), legendRing(0));
      // A new ring rectangle calls render().
      renders.clear();
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(renders, ['render']);
      expect(_ring(chart), legendRing(1));

      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_ring(chart), isEmpty);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_ring(chart), legendRing(1));
      await _key(tester, LogicalKeyboardKey.escape);
      expect(_ring(chart), _ringCalls(1, 1, 398, 278));

      // The touch highlight mode has no ring.
      renders.clear();
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      expect(renders, ['render']);
      expect(_ring(chart), isEmpty);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      expect(_ring(chart), _ringCalls(1, 1, 398, 278));

      // No focus, no ring.
      node.unfocus();
      await tester.pump();
      expect(_ring(chart), isEmpty);
    });

    testWidgets('the ring takes the resolved options.color, and '
        r'plugins.$chartView: false turns it off', (tester) async {
      _highlight(FocusHighlightStrategy.alwaysTraditional);
      final node = FocusNode();
      addTearDown(node.dispose);
      late Chart chart;
      Widget build(Map<String, Object?> options) => _top(
        _view(
          _config('bar', options: options),
          focusNode: node,
          onChartCreated: (c) => chart = c,
        ),
      );
      await tester.pumpWidget(build(<String, Object?>{'color': '#123456'}));
      node.requestFocus();
      await tester.pump();
      final calls = _ring(chart);
      expect(calls[1], ['setStrokeStyle', '#123456']);

      await tester.pumpWidget(
        build(<String, Object?>{
          'plugins': <String, Object?>{r'$chartView': false},
        }),
      );
      await tester.pump();
      expect(_ring(chart), isEmpty);
    });
  });
}
