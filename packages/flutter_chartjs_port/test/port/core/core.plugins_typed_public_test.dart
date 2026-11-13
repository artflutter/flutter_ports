// Original code, not ported from Chart.js: a typed plugin from the public API.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/js_semantics.dart';
import 'package:flutter_test/flutter_test.dart';

// The typed plugin API of Chart.js ADR 0108 for a plugin of an add-on port:
// this file imports only the public libraries of the package and the
// harness. The plugin has the keys of the plugin object of
// chartjs-plugin-zoom (`src/plugin.ts:64-152` of chartjs-plugin-zoom) in its
// order: typed hooks, and extras that `jsWrite` stores. Each hook declares
// its chart as `Object` and casts it to `Chart` once, because the hook type
// names the internal chart interface.

/// The hook calls of the plugins of this file, in call order.
final List<String> _calls = <String>[];

/// The charts of the hook calls, in call order.
final List<Chart> _charts = <Chart>[];

/// The options of the hook calls, in call order.
final List<Object> _options = <Object>[];

/// Records a call of [hook].
void _record(String hook, Object chart, Object options) {
  _calls.add(hook);
  _charts.add(chart as Chart);
  _options.add(options);
}

/// Whether [_beforeEvent] cancels the event.
bool _cancelEvents = false;

/// The event type and `cancelable` of the calls of [_beforeEvent], at the
/// call: the chart passes the same args object to `afterEvent` with
/// `cancelable: false` (core.controller.js:1178).
final List<(String?, bool)> _events = <(String?, bool)>[];

Object? _start(Object chart, PluginHookArgs args, Object options) {
  _record('start', chart, options);
  return null;
}

Object? _beforeEvent(Object chart, EventHookArgs args, Object options) {
  _record('beforeEvent', chart, options);
  _events.add((args.event?.type, args.cancelable));
  return _cancelEvents ? false : null;
}

Object? _beforeUpdate(Object chart, UpdateHookArgs args, Object options) {
  _record('beforeUpdate ${args.mode}', chart, options);
  return null;
}

Object? _beforeDatasetsDraw(
  Object chart,
  CancelableHookArgs args,
  Object options,
) {
  _record('beforeDatasetsDraw', chart, options);
  return null;
}

Object? _afterDatasetsDraw(Object chart, PluginHookArgs args, Object options) {
  _record('afterDatasetsDraw', chart, options);
  return null;
}

Object? _beforeDraw(Object chart, CancelableHookArgs args, Object options) {
  _record('beforeDraw', chart, options);
  return null;
}

Object? _afterDraw(Object chart, PluginHookArgs args, Object options) {
  _record('afterDraw', chart, options);
  return null;
}

Object? _stop(Object chart, PluginHookArgs args, Object options) {
  _record('stop', chart, options);
  return null;
}

/// The extras of the plugin: the function tables of chartjs-plugin-zoom.
final Map<String, Object?> _panFunctions = <String, Object?>{};
final Map<String, Object?> _zoomFunctions = <String, Object?>{};
final Map<String, Object?> _zoomRectFunctions = <String, Object?>{};

/// The keys of the plugin object of chartjs-plugin-zoom, in its order.
const List<String> _upstreamKeys = [
  'id',
  'version',
  'defaults',
  'start',
  'beforeEvent',
  'beforeUpdate',
  'beforeDatasetsDraw',
  'afterDatasetsDraw',
  'beforeDraw',
  'afterDraw',
  'stop',
  'panFunctions',
  'zoomFunctions',
  'zoomRectFunctions',
];

/// A plugin with the keys of the zoom plugin object, in its order.
Plugin _zoomLike({bool supportsDataUpdates = true}) =>
    Plugin(supportsDataUpdates: supportsDataUpdates)
      ..id = 'zoomLike'
      ..jsWrite('version', '2.2.0')
      ..defaults = <String, Object?>{
        'mode': 'xy',
        'speed': 0.1,
        'nested': <String, Object?>{'enabled': false},
      }
      ..start = _start
      ..beforeEvent = _beforeEvent
      ..beforeUpdate = _beforeUpdate
      ..beforeDatasetsDraw = _beforeDatasetsDraw
      ..afterDatasetsDraw = _afterDatasetsDraw
      ..beforeDraw = _beforeDraw
      ..afterDraw = _afterDraw
      ..stop = _stop
      ..jsWrite('panFunctions', _panFunctions)
      ..jsWrite('zoomFunctions', _zoomFunctions)
      ..jsWrite('zoomRectFunctions', _zoomRectFunctions);

/// A line chart with fixed value bounds, so that `updateData` can keep the
/// layout (Chart.js ADR 0074). [plugins] are the inline plugins, and
/// [onHover] is the option `onHover`, when it is not Dart `null`.
Map<String, Object?> _config({
  List<Object?> plugins = const [],
  Object? onHover,
}) => <String, Object?>{
  'type': 'line',
  'plugins': plugins,
  'data': <String, Object?>{
    'labels': <Object?>['a', 'b', 'c'],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'values',
        'data': <Object?>[1.0, 2.0, 3.0],
      },
    ],
  },
  'options': <String, Object?>{
    'onHover': ?onHover,
    'plugins': <String, Object?>{
      'zoomLike': <String, Object?>{
        'speed': 0.5,
        'nested': <String, Object?>{'enabled': true},
      },
    },
    'scales': <String, Object?>{
      'y': <String, Object?>{'min': 0.0, 'max': 4.0},
    },
  },
};

void main() {
  tearDown(releaseCharts);

  setUp(() {
    _calls.clear();
    _charts.clear();
    _options.clear();
    _events.clear();
    _cancelEvents = false;
  });

  group('a typed plugin of the public API', () {
    test('keeps the keys and the extras in insertion order', () {
      final plugin = _zoomLike();
      expect(plugin.jsKeys(), _upstreamKeys);
      expect(plugin.id, 'zoomLike');
      expect(plugin.jsRead('version'), '2.2.0');
      expect(plugin['panFunctions'], same(_panFunctions));
      expect(plugin.jsRead('zoomRectFunctions'), same(_zoomRectFunctions));
      expect(plugin.jsHas('zoomFunctions'), isTrue);
      expect(plugin.jsRead('afterEvent'), same(undefined));
      // A hook declared with `Object chart` has the type of the hook.
      expect(_beforeEvent, isA<PluginHookFunction<EventHookArgs>>());
      expect(_beforeEvent, isNot(isA<PluginHookFunction<PluginHookArgs>>()));
      expect(plugin.start, same(_start));
      expect(plugin.beforeEvent, same(_beforeEvent));
      expect(plugin.beforeUpdate, same(_beforeUpdate));
      expect(plugin.beforeDatasetsDraw, same(_beforeDatasetsDraw));
      expect(plugin.afterDraw, same(_afterDraw));
      expect(plugin.stop, same(_stop));
      // A write of a key that the plugin owns keeps its place.
      plugin.jsWrite('version', '2.2.1');
      expect(plugin.jsKeys(), _upstreamKeys);
      expect(plugin.jsDelete('version'), isTrue);
      expect(plugin.jsKeys(), [
        for (final key in _upstreamKeys)
          if (key != 'version') key,
      ]);
    });

    testWidgets('gets the typed calls of a registered plugin', (tester) async {
      final plugin = _zoomLike();
      Chart.register([plugin]);
      addTearDown(() => Chart.unregister([plugin]));

      final chart = acquireChart(_config());
      expect(_calls, isNotEmpty);
      expect(_calls.first, 'start');
      expect(_calls[1], 'beforeUpdate undefined');
      final draw = [
        'beforeDraw',
        'beforeDatasetsDraw',
        'afterDatasetsDraw',
        'afterDraw',
      ];
      expect(_calls.where(draw.contains).take(4), draw);
      for (final hookChart in _charts) {
        expect(hookChart, same(chart));
      }

      // The options are the plugin options of the chart over the defaults
      // of the plugin.
      final options = _options.first;
      expect(options, isA<JsObjectFace>());
      expect(jsGet(options, 'mode'), 'xy');
      expect(jsGet(options, 'speed'), 0.5);
      expect(jsGet(jsGet(options, 'nested'), 'enabled'), isTrue);

      _calls.clear();
      chart.update('zoom');
      expect(_calls.first, 'beforeUpdate zoom');

      _calls.clear();
      releaseChart(chart);
      expect(_calls, ['stop']);
    });

    testWidgets('cancels an event from beforeEvent', (tester) async {
      var hovers = 0;
      void onHover(Object? event, Object? active, Object? chart) => hovers++;
      final chart = acquireChart(
        _config(plugins: [_zoomLike()], onHover: onHover),
      );

      // A point in the chart area: `onHover` runs (core.controller.js:1223).
      await triggerMouseEvent(chart, 'mousemove', <String, Object?>{
        'x': 256,
        'y': 256,
      });
      expect(_events, hasLength(1));
      expect(_events.single, ('mousemove', true));
      expect(hovers, 1);

      _cancelEvents = true;
      await triggerMouseEvent(chart, 'mousemove', <String, Object?>{
        'x': 260,
        'y': 260,
      });
      expect(_events, hasLength(2));
      expect(hovers, 1);
    });

    testWidgets('calls a hook that jsWrite replaces, and keeps the key order', (
      tester,
    ) async {
      final plugin = _zoomLike();
      final chart = acquireChart(_config(plugins: [plugin]));

      // A spy with the type of the hook: a typed call.
      final typed = <Object>[];
      Object? spy(Object chart, UpdateHookArgs args, Object options) {
        typed.add(args);
        return null;
      }

      final original = plugin.jsRead('beforeUpdate');
      plugin.jsWrite('beforeUpdate', spy);
      expect(plugin.jsKeys(), _upstreamKeys);
      expect(plugin.beforeUpdate, same(spy));
      _calls.clear();
      chart.update();
      expect(typed, hasLength(1));
      expect(typed.single, isA<UpdateHookArgs>());
      expect(_calls, isNot(contains(startsWith('beforeUpdate'))));

      // A spy of another type: no typed hook, a call with JS arity.
      var untyped = 0;
      plugin.jsWrite('beforeUpdate', () => untyped++);
      expect(plugin.beforeUpdate, isNull);
      chart.update();
      expect(untyped, 1);

      plugin.jsWrite('beforeUpdate', original);
      expect(plugin.beforeUpdate, same(_beforeUpdate));
      _calls.clear();
      chart.update();
      expect(_calls.first, 'beforeUpdate undefined');
      expect(plugin.jsKeys(), _upstreamKeys);
    });

    for (final approved in [false, true]) {
      testWidgets('supportsDataUpdates: $approved '
          '${approved ? 'keeps' : 'does not keep'} the data-only update', (
        tester,
      ) async {
        final plugin = _zoomLike(supportsDataUpdates: approved);
        final config = _config(plugins: [plugin]);
        final chart = acquireChart(config);
        final dataset =
            ((config['data']! as Map<String, Object?>)['datasets']!
                        as List<Object?>)
                    .single!
                as Map<String, Object?>;
        (dataset['data']! as List<Object?>)[0] = 2.5;

        _calls.clear();
        expect(chart.updateData(), approved);
        expect(_calls.first, 'beforeUpdate none');
        expect(_calls, contains('afterDraw'));
        expect(chart.getDatasetMeta(0).data, hasLength(3));
      });
    }
  });
}
