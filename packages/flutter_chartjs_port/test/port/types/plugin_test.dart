// Original code, not ported from Chart.js: tests of the native plugin objects.

import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/plugin.dart';
import 'package:test/test.dart';

/// A chart for the calls: each member throws.
final class _Chart() implements types.Chart {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // The native plugins of Chart.js ADR 0144.
  group('PluginHook', () {
    test('has the 35 hooks with distinct JS names', () {
      expect(PluginHook.values, hasLength(35));
      expect({
        for (final hook in PluginHook.values) hook.jsName,
      }, hasLength(35));
      expect(PluginHook.afterDraw.jsName, 'afterDraw');
    });

    test('is cancelable where upstream passes cancelable: true', () {
      // core.controller.js:490, :612, :649, :671, :684, :712, :766, :788,
      // :1167 and plugin.tooltip.js:1254.
      expect(
        [
          for (final hook in PluginHook.values)
            if (hook.cancelable) hook.jsName,
        ],
        [
          'beforeUpdate',
          'beforeDatasetsUpdate',
          'beforeDatasetUpdate',
          'beforeLayout',
          'beforeRender',
          'beforeDraw',
          'beforeDatasetsDraw',
          'beforeDatasetDraw',
          'beforeEvent',
          'beforeTooltipDraw',
        ],
      );
    });
  });

  group('Plugin', () {
    test('calls the field of the hook with the typed arguments', () {
      final chart = _Chart();
      final calls = <Object?>[];
      final plugin = Plugin<Object?>(
        id: 'p',
        afterUpdate: (c, args, options) => calls.add([c, args.mode, options]),
        beforeUpdate: (c, args, options) => false,
        resize: (c, args, options) => calls.add(args.size.width),
      );
      expect(
        plugin.notify(
          PluginHook.afterUpdate,
          chart,
          UpdateHookArgs(mode: 'm'),
          'view',
        ),
        isTrue,
      );
      expect(
        plugin.notify(
          PluginHook.beforeUpdate,
          chart,
          UpdateHookArgs(mode: 'm'),
          'view',
        ),
        isFalse,
      );
      expect(
        plugin.notify(
          PluginHook.resize,
          chart,
          ResizeHookArgs(size: (width: 4.0, height: 5.0)),
          'view',
        ),
        isTrue,
      );
      expect(calls, [
        [same(chart), 'm', 'view'],
        4.0,
      ]);
    });

    test('an absent hook continues', () {
      final plugin = Plugin<Object?>(id: 'p');
      for (final hook in [PluginHook.beforeDraw, PluginHook.afterDraw]) {
        expect(
          plugin.notify(hook, _Chart(), const PluginHookArgs(), 'view'),
          isTrue,
        );
      }
    });

    test('a hook field is writable', () {
      final calls = <String>[];
      final plugin = Plugin<Object?>(id: 'p');
      void draw() => plugin.notify(
        PluginHook.afterDraw,
        _Chart(),
        const PluginHookArgs(),
        1,
      );
      plugin.afterDraw = (chart, args, options) {
        calls.add('first');
      };
      draw();
      plugin.afterDraw = (chart, args, options) {
        calls.add('second');
      };
      draw();
      expect(calls, ['first', 'second']);
    });

    test('the data-only and range guards read the options', () {
      final plugin = Plugin<Object?>(
        id: 'p',
        supportsDataUpdates: true,
        dataUpdateGuard: (options) => options == 'ok',
      )..rangeUpdateGuard = (options) => options == 'range';
      expect(plugin.allowsDataUpdates('ok'), isTrue);
      expect(plugin.allowsDataUpdates('no'), isFalse);
      expect(plugin.allowsRangeUpdates('range'), isTrue);
      expect(plugin.allowsRangeUpdates('ok'), isFalse);
      final off = Plugin<Object?>(id: 'off');
      expect(off.allowsDataUpdates('ok'), isFalse);
      expect(off.allowsRangeUpdates('range'), isFalse);
    });

    test('keeps its metadata', () {
      final plugin = Plugin<Object?>(
        id: 'p',
        events: const ['click'],
        defaults: const <String, Object?>{'a': 1.0},
        defaultRoutes: const {'color': 'color'},
        additionalOptionScopes: const ['interaction'],
      );
      expect(plugin.id, 'p');
      expect(plugin.events, ['click']);
      expect(plugin.defaults, {'a': 1.0});
      expect(plugin.defaultRoutes, {'color': 'color'});
      expect(plugin.additionalOptionScopes, ['interaction']);
      expect('$plugin', 'Plugin(p)');
    });
  });

  group('hook arguments', () {
    test('keep their values, and a hook writes changed and inChartArea', () {
      final event = EventHookArgs(event: _Event(), replay: true);
      expect(event.replay, isTrue);
      expect(event.inChartArea, isFalse);
      expect(event.changed, isFalse);
      event
        ..inChartArea = true
        ..changed = true;
      expect(event.inChartArea, isTrue);
      expect(event.changed, isTrue);
      expect(UpdateHookArgs(mode: 'none').mode, 'none');
      expect(UpdateHookArgs(mode: 'none').layoutKept, isFalse);
    });
  });
}

/// An event for [EventHookArgs]: each member throws.
final class _Event() implements types.ChartEvent {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
