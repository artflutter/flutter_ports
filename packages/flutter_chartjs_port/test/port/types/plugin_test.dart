// Original code, not ported from Chart.js: tests of the typed plugin objects.

import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/plugin.dart';
import 'package:test/test.dart';

/// A chart for the calls: each member throws.
final class _Chart implements types.Chart {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // The typed plugins of Chart.js ADR 0054 §12.
  group('PluginHook', () {
    test('maps each JS name to its hook', () {
      for (final hook in PluginHook.values) {
        expect(PluginHook.of(hook.jsName), hook);
        expect(Plugin.fieldNames, contains(hook.jsName));
      }
      expect(PluginHook.values, hasLength(35));
      expect(PluginHook.of('myHook'), isNull);
    });
  });

  group('Plugin', () {
    test('keeps the fields in the order of the writes', () {
      final plugin = Plugin()
        ..id = 'p'
        ..afterDraw = ((chart, args, options) => null)
        ..defaults = {'a': 1}
        ..['custom'] = 2;
      expect(jsObjectKeys(plugin), ['id', 'afterDraw', 'defaults', 'custom']);
      expect(jsGet(plugin, 'id'), 'p');
      expect(jsGet(plugin, 'beforeDraw'), same(undefined));
      expect(plugin['beforeDraw'], same(undefined));
      expect(plugin.hookValue(PluginHook.beforeDraw), same(undefined));
      expect(plugin.hookValue(PluginHook.afterDraw), isA<Function>());
      expect(plugin['afterDraw'], isA<Function>());
      expect(plugin.jsDelete('afterDraw'), isTrue);
      expect(plugin.afterDraw, isNull);
      expect(jsObjectKeys(plugin), ['id', 'defaults', 'custom']);
    });

    test('a hook of another type is kept, and its typed getter is null', () {
      void raw(Object? chart) {}
      final plugin = Plugin()..['beforeUpdate'] = raw;
      expect(plugin.beforeUpdate, isNull);
      expect(plugin.hookValue(PluginHook.beforeUpdate), same(raw));
    });

    test('invokeHook calls a typed hook with its argument class', () {
      final chart = _Chart();
      final options = <String, Object?>{};
      final seen = <Object?>[];
      final plugin = Plugin()
        ..beforeEvent = (c, args, o) {
          seen
            ..add(args.event)
            ..add(args.replay)
            ..add(args.inChartArea);
          args.changed = true;
          return false;
        };
      final args = EventHookArgs(
        event: null,
        replay: undefined,
        cancelable: true,
        inChartArea: true,
      );
      final result = plugin.invokeHook(
        PluginHook.beforeEvent,
        plugin.hookValue(PluginHook.beforeEvent)!,
        chart,
        args,
        options,
      );
      expect(result, isFalse);
      expect(seen, [isNull, same(undefined), isTrue]);
      expect(jsObjectKeys(args), [
        'event',
        'replay',
        'cancelable',
        'inChartArea',
        'changed',
      ]);
      expect(args['changed'], isTrue);
    });

    test('invokeHook calls another function with JS arity', () {
      final chart = _Chart();
      final calls = <Object?>[];
      final plugin = Plugin();
      plugin['resize'] = JsFunction((Object? self, Object? c) {
        calls
          ..add(self)
          ..add(c);
      });
      plugin.invokeHook(
        PluginHook.resize,
        plugin.hookValue(PluginHook.resize)!,
        chart,
        ResizeHookArgs(size: const {'width': 1}),
        const {},
      );
      expect(calls, [same(plugin), same(chart)]);
    });
  });

  group('hook arguments', () {
    test('keep the key order of the upstream literals', () {
      expect(
        jsObjectKeys(UpdateHookArgs(mode: undefined, cancelable: true)),
        ['mode', 'cancelable'],
      );
      expect(jsObjectKeys(UpdateHookArgs(mode: 'none')), ['mode']);
      expect(jsGet(UpdateHookArgs(mode: undefined), 'mode'), same(undefined));
      final dataset = DatasetUpdateHookArgs(
        meta: null,
        index: 1,
        mode: 'm',
        cancelable: true,
      );
      expect(jsObjectKeys(dataset), ['meta', 'index', 'mode', 'cancelable']);
      dataset['cancelable'] = false;
      expect(dataset.cancelable, isFalse);
      expect(
        jsObjectKeys(DatasetDrawHookArgs(meta: null, index: 0)),
        ['meta', 'index'],
      );
      expect(jsObjectKeys(CancelableHookArgs(cancelable: true)), [
        'cancelable',
      ]);
      expect(jsObjectKeys(TooltipDrawHookArgs(tooltip: 1)), ['tooltip']);
      expect(jsObjectKeys(PluginHookArgs()), isEmpty);
    });

    test('a write by name of another type is foreign', () {
      final args = CancelableHookArgs(cancelable: true)..['cancelable'] = 0;
      expect(args.cancelable, isFalse);
      expect(args['cancelable'], 0);
    });
  });

  group('MapPlugin', () {
    test('reads map[hook] and calls it with JS arity', () {
      final calls = <Object?>[];
      final map = <String, Object?>{
        'afterInit': JsFunction(calls.add),
      };
      final plugin = MapPlugin(map);
      expect(plugin.hookValue('beforeInit'), isNull);
      plugin.invokeHook(
        plugin.hookValue('afterInit')!,
        _Chart(),
        PluginHookArgs(),
        const {},
      );
      expect(calls, [same(map)]);
    });
  });
}
