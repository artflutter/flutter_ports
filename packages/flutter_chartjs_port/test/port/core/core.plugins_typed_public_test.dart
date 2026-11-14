// Original code, not ported from Chart.js: a native plugin from the public API.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/helpers.dart' show ContextResolver;
import 'package:flutter_chartjs_port/js_semantics.dart';
import 'package:flutter_test/flutter_test.dart';

// The native plugin API of Chart.js ADRs 0108 and 0144 for a plugin of an
// add-on port: this file imports only the public libraries of the package
// and the harness. The plugin has the hooks of the plugin object of
// chartjs-plugin-zoom (`src/plugin.ts:64-152` of chartjs-plugin-zoom) in its
// order. Each hook declares its chart as `Object` and casts it to `Chart`
// once, because the hook type names the internal chart interface.

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

/// The event types of the calls of [_beforeEvent].
final List<String> _events = <String>[];

void _start(Object chart, PluginHookArgs args, ContextResolver options) {
  _record('start', chart, options);
}

bool _beforeEvent(Object chart, EventHookArgs args, ContextResolver options) {
  _record('beforeEvent', chart, options);
  _events.add(args.event.type);
  return !_cancelEvents;
}

bool _beforeUpdate(Object chart, UpdateHookArgs args, ContextResolver options) {
  _record('beforeUpdate ${args.mode}', chart, options);
  return true;
}

bool _beforeDatasetsDraw(
  Object chart,
  PluginHookArgs args,
  ContextResolver options,
) {
  _record('beforeDatasetsDraw', chart, options);
  return true;
}

void _afterDatasetsDraw(
  Object chart,
  PluginHookArgs args,
  ContextResolver options,
) {
  _record('afterDatasetsDraw', chart, options);
}

bool _beforeDraw(Object chart, PluginHookArgs args, ContextResolver options) {
  _record('beforeDraw', chart, options);
  return true;
}

void _afterDraw(Object chart, PluginHookArgs args, ContextResolver options) {
  _record('afterDraw', chart, options);
}

void _stop(Object chart, PluginHookArgs args, ContextResolver options) {
  _record('stop', chart, options);
}

/// A plugin with the hooks of the zoom plugin object, in its order.
Plugin<ContextResolver> _zoomLike({bool supportsDataUpdates = true}) =>
    Plugin<ContextResolver>(
      id: 'zoomLike',
      defaults: <String, Object?>{
        'mode': 'xy',
        'speed': 0.1,
        'nested': <String, Object?>{'enabled': false},
      },
      start: _start,
      beforeEvent: _beforeEvent,
      beforeUpdate: _beforeUpdate,
      beforeDatasetsDraw: _beforeDatasetsDraw,
      afterDatasetsDraw: _afterDatasetsDraw,
      beforeDraw: _beforeDraw,
      afterDraw: _afterDraw,
      stop: _stop,
      supportsDataUpdates: supportsDataUpdates,
    );

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

  group('a native plugin of the public API', () {
    test('keeps its id and its hooks in typed fields', () {
      final plugin = _zoomLike();
      expect(plugin.id, 'zoomLike');
      // A hook declared with `Object chart` has the type of the hook.
      expect(
        _beforeEvent,
        isA<CancelableHookFunction<EventHookArgs, ContextResolver>>(),
      );
      expect(
        _afterDraw,
        isA<PluginHookFunction<PluginHookArgs, ContextResolver>>(),
      );
      expect(plugin.start, same(_start));
      expect(plugin.beforeEvent, same(_beforeEvent));
      expect(plugin.beforeUpdate, same(_beforeUpdate));
      expect(plugin.beforeDatasetsDraw, same(_beforeDatasetsDraw));
      expect(plugin.afterDraw, same(_afterDraw));
      expect(plugin.stop, same(_stop));
      expect(plugin.afterEvent, isNull);
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
      expect(_events, ['mousemove']);
      expect(hovers, 1);

      _cancelEvents = true;
      await triggerMouseEvent(chart, 'mousemove', <String, Object?>{
        'x': 260,
        'y': 260,
      });
      expect(_events, hasLength(2));
      expect(hovers, 1);
    });

    testWidgets('calls a hook that a field write replaces', (tester) async {
      final plugin = _zoomLike();
      final chart = acquireChart(_config(plugins: [plugin]));

      final typed = <Object>[];
      final original = plugin.beforeUpdate;
      plugin.beforeUpdate = (chart, args, options) {
        typed.add(args);
        return true;
      };
      _calls.clear();
      chart.update();
      expect(typed, hasLength(1));
      expect(typed.single, isA<UpdateHookArgs>());
      expect(_calls, isNot(contains(startsWith('beforeUpdate'))));

      plugin.beforeUpdate = original;
      _calls.clear();
      chart.update();
      expect(_calls.first, 'beforeUpdate undefined');
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
