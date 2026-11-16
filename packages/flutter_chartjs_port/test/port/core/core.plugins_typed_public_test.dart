// Original code, not ported from Chart.js: a native plugin from the public API.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

// The native plugin API of Chart.js ADRs 0108, 0144 and 0148 for a plugin of
// an add-on port: this file imports only the public libraries of the
// package and the harness. The plugin has the hooks of the plugin object of
// chartjs-plugin-zoom (`src/plugin.ts:64-152` of chartjs-plugin-zoom) in its
// order. It is a `ChartPlugin`: each hook gets the public `Chart`, with no
// cast. Its options are one immutable `PluginOptions` object.

/// The options of the test plugin: the defaults, then the options of the
/// chart over them (Chart.js ADR 0148).
final class const _ZoomLikeOptions({
  final String? mode,
  final double? speed,
  final _Nested? nested,
  @override final List<String>? events,
}) extends PluginOptions<_ZoomLikeOptions> {
  @override
  String get pluginId => 'zoomLike';

  @override
  _ZoomLikeOptions merge(_ZoomLikeOptions over) => _ZoomLikeOptions(
    mode: over.mode ?? mode,
    speed: over.speed ?? speed,
    nested: switch ((nested, over.nested)) {
      (final a?, final b?) => a.merge(b),
      (final a, final b) => b ?? a,
    },
    events: over.events ?? events,
  );
}

/// A nested options object of [_ZoomLikeOptions].
final class const _Nested({final bool? enabled}) {
  /// These options with each field that [over] sets.
  _Nested merge(_Nested over) => _Nested(enabled: over.enabled ?? enabled);
}

/// The hook calls of the plugins of this file, in call order.
final List<String> _calls = <String>[];

/// The charts of the hook calls, in call order.
final List<Chart> _charts = <Chart>[];

/// The options of the hook calls, in call order.
final List<_ZoomLikeOptions> _options = <_ZoomLikeOptions>[];

/// Records a call of [hook].
void _record(String hook, Chart chart, _ZoomLikeOptions options) {
  _calls.add(hook);
  _charts.add(chart);
  _options.add(options);
}

/// Whether [_beforeEvent] cancels the event.
bool _cancelEvents = false;

/// The event types of the calls of [_beforeEvent].
final List<String> _events = <String>[];

void _start(Chart chart, PluginHookArgs args, _ZoomLikeOptions options) {
  _record('start', chart, options);
}

bool _beforeEvent(Chart chart, EventHookArgs args, _ZoomLikeOptions options) {
  _record('beforeEvent', chart, options);
  _events.add(args.event.type);
  return !_cancelEvents;
}

bool _beforeUpdate(Chart chart, UpdateHookArgs args, _ZoomLikeOptions options) {
  _record('beforeUpdate ${args.mode}', chart, options);
  return true;
}

bool _beforeDatasetsDraw(
  Chart chart,
  PluginHookArgs args,
  _ZoomLikeOptions options,
) {
  _record('beforeDatasetsDraw', chart, options);
  return true;
}

void _afterDatasetsDraw(
  Chart chart,
  PluginHookArgs args,
  _ZoomLikeOptions options,
) {
  _record('afterDatasetsDraw', chart, options);
}

bool _beforeDraw(Chart chart, PluginHookArgs args, _ZoomLikeOptions options) {
  _record('beforeDraw', chart, options);
  return true;
}

void _afterDraw(Chart chart, PluginHookArgs args, _ZoomLikeOptions options) {
  _record('afterDraw', chart, options);
}

void _stop(Chart chart, PluginHookArgs args, _ZoomLikeOptions options) {
  _record('stop', chart, options);
}

/// A plugin with the hooks of the zoom plugin object, in its order.
ChartPlugin<_ZoomLikeOptions> _zoomLike({bool supportsDataUpdates = true}) =>
    ChartPlugin<_ZoomLikeOptions>(
      id: 'zoomLike',
      defaults: const _ZoomLikeOptions(
        mode: 'xy',
        speed: 0.1,
        nested: _Nested(enabled: false),
      ),
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
/// [onHover] is the option `onHover`, when it is not Dart `null`. [events]
/// is the option `events` of the plugin (Chart.js ADR 0150).
Map<String, Object?> _config({
  List<Plugin<Object?>> plugins = const [],
  Object? onHover,
  List<String>? events,
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
      'zoomLike': _ZoomLikeOptions(
        speed: 0.5,
        nested: const _Nested(enabled: true),
        events: events,
      ),
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
      expect(_calls[1], 'beforeUpdate null');
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

      // The options of the chart merge over the defaults of the plugin.
      final options = _options.first;
      expect(options.mode, 'xy');
      expect(options.speed, 0.5);
      expect(options.nested?.enabled, isTrue);

      _calls.clear();
      chart.update(const UpdateMode('zoom'));
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

    testWidgets('gets only the events of its events option', (tester) async {
      // `(plugin.options.events || this.options.events).includes(type)`
      // (core.controller.js:1170): the field of the options object.
      final chart = acquireChart(
        _config(plugins: [_zoomLike()], events: const ['click']),
      );
      await triggerMouseEvent(chart, 'mousemove', <String, Object?>{
        'x': 256,
        'y': 256,
      });
      expect(_events, isEmpty);
      await triggerMouseEvent(chart, 'click', <String, Object?>{
        'x': 256,
        'y': 256,
      });
      expect(_events, ['click']);
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
      expect(_calls.first, 'beforeUpdate null');
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
