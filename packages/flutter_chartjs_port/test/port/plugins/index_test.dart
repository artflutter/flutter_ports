// Original code, not ported from Chart.js: the plugin hook dispatch of src/plugins/index.js.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.registry.dart' show registry;
import 'package:flutter_chartjs_port/src/core/core.scale.dart' show Scale;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show OptionView;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableScaleContext;
import 'package:flutter_chartjs_port/src/index.dart' show plugins;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsToString;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/plugin.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart';
import 'plugin_chart_harness.dart' show pluginHookNames;
import 'plugin_dispatch_reference.dart';

// The plugin hook dispatch with the seven plugins of src/plugins/index.js
// (Chart.js ADR 0038, sections 3, 10 and 11). The reference is
// tool/reference/plugin_dispatch_reference.mjs: a build of the pinned
// Chart.js in Node.js v24.22.1 on arm64 (Chart.js ADR 0045), with the
// built-in components registered and `colors.enabled: false` in the
// defaults (Chart.js ADR 0041, section 1), as flutter_test_config.dart
// registers them here.
//
// The group `plugin objects` compares the keys of each plugin object of the
// namespace `plugins` and the registry order. A plugin is a native [Plugin]
// (Chart.js ADR 0144): its keys are its fields, with no key order, and each
// hook is a field of the type of its hook. Both sides give a hook as
// `<key>(hook)`: the JS `length` of a hook is no behavior of Chart.js
// (Chart.js ADR 0054 §12). The native plugins have no field for the
// `_element` class of upstream and for the `destroy` of the decimation,
// which is no hook of the `Plugin` interface ([_removedKeys]).
//
// The group `dispatch` builds the chart of each case with acquireChart and
// runs its steps. Each hook of each plugin object is a recording closure
// (`calls`) that records the args of the hook as the generator does for the
// upstream count of parameters of the hook ([_upstreamCounts]). The inline
// plugin `recorder`, the last plugin of each notify, records the hooks that
// the plugin service gives it (`notifies`). A hook text has the details of
// `detail` of the generator ([_detail]). The steps `hover` and `mouseout`
// go through triggerMouseEvent (Chart.js ADR 0022, section 6). The
// generator calls `chart._eventHandler` with the same point.

/// The hooks of the generator by their JS names: `HOOKS` of the generator,
/// the hooks of the interface `Plugin` (src/types/index.d.ts:856-1164) and
/// the two hooks of `ExtendedPlugin` (src/types/index.d.ts:2764-2787).
final Map<String, PluginHook<Object>> _hooks = {
  for (final hook in PluginHook.values) hook.jsName: hook,
};

/// The keys of the upstream plugin objects that the native plugins of
/// Chart.js ADR 0144 have no field for: the class of the box (the classes
/// are `Legend.jsClass`, `Title.jsClass` and `Tooltip.jsClass`), and the
/// `destroy` of the decimation, which no chart calls.
const Set<String> _removedKeys = {'_element: class', 'destroy(1)'};

/// The hooks whose args have the dataset `index`.
const Set<PluginHook<Object>> _indexHooks = {
  PluginHook.beforeDatasetUpdate,
  PluginHook.afterDatasetUpdate,
  PluginHook.beforeDatasetDraw,
  PluginHook.afterDatasetDraw,
};

/// The hooks whose args are the context of a scale (core.scale.js:534-537).
const Set<PluginHook<Object>> _scaleHooks = {
  PluginHook.beforeDataLimits,
  PluginHook.afterDataLimits,
  PluginHook.beforeBuildTicks,
  PluginHook.afterBuildTicks,
};

/// The hooks whose args have the `event`.
const Set<PluginHook<Object>> _eventHooks = {
  PluginHook.beforeEvent,
  PluginHook.afterEvent,
};

/// The hooks whose args have the update `mode`.
const Set<PluginHook<Object>> _modeHooks = {
  PluginHook.beforeUpdate,
  PluginHook.afterUpdate,
  PluginHook.beforeDatasetsUpdate,
  PluginHook.afterDatasetsUpdate,
  PluginHook.beforeDatasetUpdate,
  PluginHook.afterDatasetUpdate,
};

/// `detail(hook, args)` of the generator: [hook], then `:<detail>` for the
/// `index` of a dataset hook, the `id` of the `scale` of a scale hook, the
/// `type` of the `event` of an event hook and the `ToString` of the `mode`
/// of an update hook. Dart `null` for [args] is the `{}` of the generator
/// for a hook with one parameter: its `index` and `mode` are `undefined`.
String _detail(PluginHook<Object> hook, Object? args) {
  final text = StringBuffer(hook.jsName);
  if (_indexHooks.contains(hook)) {
    final index = switch (args) {
      DatasetUpdateHookArgs(:final index) ||
      DatasetDrawHookArgs(:final index) => index,
      _ => undefined,
    };
    text.write(':${jsToString(index)}');
  }
  if (_scaleHooks.contains(hook)) {
    text.write(':${((args! as ScriptableScaleContext).scale! as Scale).id}');
  }
  if (_eventHooks.contains(hook)) {
    text.write(':${(args! as EventHookArgs).event.type}');
  }
  if (_modeHooks.contains(hook)) {
    final mode = switch (args) {
      UpdateHookArgs(:final mode) || DatasetUpdateHookArgs(:final mode) => mode,
      _ => undefined,
    };
    text.write(':${jsToString(mode)}');
  }
  return text.toString();
}

/// The reference text of a key: `<key>(hook)` for a hook of the `Plugin`
/// interface (the JS `length` of the hook is no behavior of Chart.js:
/// Chart.js ADR 0054 §12), else the text of the generator.
String _referenceKeyText(String text) {
  final open = text.indexOf('(');
  if (open < 0 || !text.endsWith(')')) return text;
  final key = text.substring(0, open);
  return _hooks.containsKey(key) ? '$key(hook)' : text;
}

/// The keys of the native plugin [plugin]: `id`, `<key>(hook)` for each
/// hook that it sets, and each other field of the upstream keys that it
/// sets, sorted: a native plugin has no key order.
List<String> _nativeKeys<O>(Plugin<O> plugin) => [
  'id',
  for (final hook in pluginHookNames(plugin)) '$hook(hook)',
  if (plugin.defaults != null) 'defaults',
  if (plugin.defaultRoutes != null) 'defaultRoutes',
  if (plugin.descriptors != null) 'descriptors',
  if (plugin.additionalOptionScopes != null) 'additionalOptionScopes',
  if (plugin.events != null) 'events',
]..sort();

/// [f] of the plugin object [plugin] of the namespace `plugins`, with the
/// options type of the plugin: a hook field is read through the type of its
/// plugin. A plugin with the options of an extension type is a
/// `Plugin<Object?>` at run time.
T _withPlugin<T>(Object? plugin, T Function<O>(Plugin<O> plugin) f) =>
    switch (plugin) {
      final Plugin<OptionView> p => f<OptionView>(p),
      final Plugin<Object?> p => f<Object?>(p),
      _ => throw ArgumentError.value(plugin, 'plugin', 'is not a Plugin'),
    };

/// The upstream count of parameters of each function key of each plugin of
/// the reference, by plugin id and key: the `length` of the JS function.
Map<String, Map<String, int>> _upstreamCounts() {
  final counts = <String, Map<String, int>>{};
  final plugins =
      pluginDispatchReference.first.expected['plugins']! as List<Object?>;
  for (final plugin in plugins) {
    final map = plugin! as Map<String, Object?>;
    final id = map['id']! as String;
    for (final text in map['keys']! as List<Object?>) {
      final match = RegExp(r'^(\w+)\((\d+)\)$').firstMatch(text! as String);
      if (match == null) continue;
      (counts[id] ??= {})[match[1]!] = int.parse(match[2]!);
    }
  }
  return counts;
}

/// Copies each hook field of [from] into [to].
void _copyHooks<O>(Plugin<O> to, Plugin<O> from) => to
  ..install = from.install
  ..start = from.start
  ..stop = from.stop
  ..beforeInit = from.beforeInit
  ..afterInit = from.afterInit
  ..beforeUpdate = from.beforeUpdate
  ..afterUpdate = from.afterUpdate
  ..beforeElementsUpdate = from.beforeElementsUpdate
  ..reset = from.reset
  ..beforeDatasetsUpdate = from.beforeDatasetsUpdate
  ..afterDatasetsUpdate = from.afterDatasetsUpdate
  ..beforeDatasetUpdate = from.beforeDatasetUpdate
  ..afterDatasetUpdate = from.afterDatasetUpdate
  ..beforeLayout = from.beforeLayout
  ..beforeDataLimits = from.beforeDataLimits
  ..afterDataLimits = from.afterDataLimits
  ..beforeBuildTicks = from.beforeBuildTicks
  ..afterBuildTicks = from.afterBuildTicks
  ..afterLayout = from.afterLayout
  ..beforeRender = from.beforeRender
  ..afterRender = from.afterRender
  ..beforeDraw = from.beforeDraw
  ..afterDraw = from.afterDraw
  ..beforeDatasetsDraw = from.beforeDatasetsDraw
  ..afterDatasetsDraw = from.afterDatasetsDraw
  ..beforeDatasetDraw = from.beforeDatasetDraw
  ..afterDatasetDraw = from.afterDatasetDraw
  ..beforeEvent = from.beforeEvent
  ..afterEvent = from.afterEvent
  ..resize = from.resize
  ..beforeDestroy = from.beforeDestroy
  ..afterDestroy = from.afterDestroy
  ..uninstall = from.uninstall
  ..beforeTooltipDraw = from.beforeTooltipDraw
  ..afterTooltipDraw = from.afterTooltipDraw;

/// Replaces each hook of [plugin] with a recording closure that adds the
/// hook text to [calls] and calls the hook with the same arguments, and
/// restores the hooks with `addTearDown`. The closure records the args as
/// the generator does for the upstream count of parameters of the hook in
/// [upstream]: the generator gives `{}` as the args of a hook with one
/// parameter, as `_notify` gives `args || {}`.
void _recordHooks<O>(
  Plugin<O> plugin,
  List<String> calls,
  Map<String, int>? upstream,
) {
  void record(PluginHook<Object> hook, Object args) {
    final count = upstream?[hook.jsName];
    expect(
      count,
      isNotNull,
      reason: 'the upstream count of ${plugin.id}.$hook',
    );
    calls.add('${plugin.id}.${_detail(hook, count == 1 ? null : args)}');
  }

  PluginHookFunction<A, O>? hook<A extends Object>(
    PluginHook<A> hook,
    PluginHookFunction<A, O>? f,
  ) => f == null
      ? null
      : (chart, args, options) {
          record(hook, args);
          f(chart, args, options);
        };
  CancelableHookFunction<A, O>? cancelable<A extends Object>(
    PluginHook<A> hook,
    CancelableHookFunction<A, O>? f,
  ) => f == null
      ? null
      : (chart, args, options) {
          record(hook, args);
          return f(chart, args, options);
        };

  final saved = Plugin<O>(id: plugin.id, options: plugin.options);
  _copyHooks(saved, plugin);
  _copyHooks(
    plugin,
    Plugin<O>(
      id: plugin.id,
      options: plugin.options,
      install: hook(PluginHook.install, plugin.install),
      start: hook(PluginHook.start, plugin.start),
      stop: hook(PluginHook.stop, plugin.stop),
      beforeInit: hook(PluginHook.beforeInit, plugin.beforeInit),
      afterInit: hook(PluginHook.afterInit, plugin.afterInit),
      beforeUpdate: cancelable(PluginHook.beforeUpdate, plugin.beforeUpdate),
      afterUpdate: hook(PluginHook.afterUpdate, plugin.afterUpdate),
      beforeElementsUpdate: hook(
        PluginHook.beforeElementsUpdate,
        plugin.beforeElementsUpdate,
      ),
      reset: hook(PluginHook.reset, plugin.reset),
      beforeDatasetsUpdate: cancelable(
        PluginHook.beforeDatasetsUpdate,
        plugin.beforeDatasetsUpdate,
      ),
      afterDatasetsUpdate: hook(
        PluginHook.afterDatasetsUpdate,
        plugin.afterDatasetsUpdate,
      ),
      beforeDatasetUpdate: cancelable(
        PluginHook.beforeDatasetUpdate,
        plugin.beforeDatasetUpdate,
      ),
      afterDatasetUpdate: hook(
        PluginHook.afterDatasetUpdate,
        plugin.afterDatasetUpdate,
      ),
      beforeLayout: cancelable(PluginHook.beforeLayout, plugin.beforeLayout),
      beforeDataLimits: hook(
        PluginHook.beforeDataLimits,
        plugin.beforeDataLimits,
      ),
      afterDataLimits: hook(PluginHook.afterDataLimits, plugin.afterDataLimits),
      beforeBuildTicks: hook(
        PluginHook.beforeBuildTicks,
        plugin.beforeBuildTicks,
      ),
      afterBuildTicks: hook(PluginHook.afterBuildTicks, plugin.afterBuildTicks),
      afterLayout: hook(PluginHook.afterLayout, plugin.afterLayout),
      beforeRender: cancelable(PluginHook.beforeRender, plugin.beforeRender),
      afterRender: hook(PluginHook.afterRender, plugin.afterRender),
      beforeDraw: cancelable(PluginHook.beforeDraw, plugin.beforeDraw),
      afterDraw: hook(PluginHook.afterDraw, plugin.afterDraw),
      beforeDatasetsDraw: cancelable(
        PluginHook.beforeDatasetsDraw,
        plugin.beforeDatasetsDraw,
      ),
      afterDatasetsDraw: hook(
        PluginHook.afterDatasetsDraw,
        plugin.afterDatasetsDraw,
      ),
      beforeDatasetDraw: cancelable(
        PluginHook.beforeDatasetDraw,
        plugin.beforeDatasetDraw,
      ),
      afterDatasetDraw: hook(
        PluginHook.afterDatasetDraw,
        plugin.afterDatasetDraw,
      ),
      beforeEvent: cancelable(PluginHook.beforeEvent, plugin.beforeEvent),
      afterEvent: hook(PluginHook.afterEvent, plugin.afterEvent),
      resize: hook(PluginHook.resize, plugin.resize),
      beforeDestroy: hook(PluginHook.beforeDestroy, plugin.beforeDestroy),
      afterDestroy: hook(PluginHook.afterDestroy, plugin.afterDestroy),
      uninstall: hook(PluginHook.uninstall, plugin.uninstall),
      beforeTooltipDraw: cancelable(
        PluginHook.beforeTooltipDraw,
        plugin.beforeTooltipDraw,
      ),
      afterTooltipDraw: hook(
        PluginHook.afterTooltipDraw,
        plugin.afterTooltipDraw,
      ),
    ),
  );
  addTearDown(() => _copyHooks(plugin, saved));
}

/// The inline plugin `recorder`: a closure for each hook of [_hooks] that
/// adds the hook text to [notifies].
Plugin<Object?> _recorder(List<String> notifies) {
  PluginHookFunction<A, Object?> hook<A extends Object>(PluginHook<A> hook) =>
      (chart, args, options) => notifies.add(_detail(hook, args));
  CancelableHookFunction<A, Object?> cancelable<A extends Object>(
    PluginHook<A> hook,
  ) => (chart, args, options) {
    notifies.add(_detail(hook, args));
    return true;
  };
  return Plugin<Object?>(
    id: 'recorder',
    install: hook(PluginHook.install),
    start: hook(PluginHook.start),
    stop: hook(PluginHook.stop),
    beforeInit: hook(PluginHook.beforeInit),
    afterInit: hook(PluginHook.afterInit),
    beforeUpdate: cancelable(PluginHook.beforeUpdate),
    afterUpdate: hook(PluginHook.afterUpdate),
    beforeElementsUpdate: hook(PluginHook.beforeElementsUpdate),
    reset: hook(PluginHook.reset),
    beforeDatasetsUpdate: cancelable(PluginHook.beforeDatasetsUpdate),
    afterDatasetsUpdate: hook(PluginHook.afterDatasetsUpdate),
    beforeDatasetUpdate: cancelable(PluginHook.beforeDatasetUpdate),
    afterDatasetUpdate: hook(PluginHook.afterDatasetUpdate),
    beforeLayout: cancelable(PluginHook.beforeLayout),
    beforeDataLimits: hook(PluginHook.beforeDataLimits),
    afterDataLimits: hook(PluginHook.afterDataLimits),
    beforeBuildTicks: hook(PluginHook.beforeBuildTicks),
    afterBuildTicks: hook(PluginHook.afterBuildTicks),
    afterLayout: hook(PluginHook.afterLayout),
    beforeRender: cancelable(PluginHook.beforeRender),
    afterRender: hook(PluginHook.afterRender),
    beforeDraw: cancelable(PluginHook.beforeDraw),
    afterDraw: hook(PluginHook.afterDraw),
    beforeDatasetsDraw: cancelable(PluginHook.beforeDatasetsDraw),
    afterDatasetsDraw: hook(PluginHook.afterDatasetsDraw),
    beforeDatasetDraw: cancelable(PluginHook.beforeDatasetDraw),
    afterDatasetDraw: hook(PluginHook.afterDatasetDraw),
    beforeEvent: cancelable(PluginHook.beforeEvent),
    afterEvent: hook(PluginHook.afterEvent),
    resize: hook(PluginHook.resize),
    beforeDestroy: hook(PluginHook.beforeDestroy),
    afterDestroy: hook(PluginHook.afterDestroy),
    uninstall: hook(PluginHook.uninstall),
    beforeTooltipDraw: cancelable(PluginHook.beforeTooltipDraw),
    afterTooltipDraw: hook(PluginHook.afterTooltipDraw),
  );
}

void main() {
  testReferenceOrigin(
    node: pluginDispatchReferenceNode,
    arch: pluginDispatchReferenceArch,
    dist: pluginDispatchReferenceDist,
    commit: pluginDispatchReferenceCommit,
  );
  testReferenceWidths(pluginDispatchReferenceWidths);

  test('the reference has the chart of Chart.js ADR 0038, section 11, and '
      'the chart with plugins false (section 10, config B)', () {
    expect(
      [for (final c in pluginDispatchReference) c.name],
      ['three datasets, a title and a fill', 'plugins false'],
    );
  });

  group('plugin objects', () {
    // Each case of the generator records the same plugin objects and the
    // same registry.
    test('the keys of each plugin object', () {
      final keys = [
        for (final name in jsObjectKeys(plugins))
          _withPlugin(
            plugins[name],
            <O>(plugin) => <String, Object?>{
              'id': plugin.id,
              'keys': _nativeKeys(plugin),
            },
          ),
      ];
      for (final c in pluginDispatchReference) {
        expect(keys, [
          for (final plugin
              in (c.expected['plugins']! as List<Object?>)
                  .cast<Map<String, Object?>>())
            <String, Object?>{
              'id': plugin['id'],
              'keys': [
                for (final text in plugin['keys']! as List<Object?>)
                  if (!_removedKeys.contains(text))
                    _referenceKeyText(text! as String),
              ]..sort(),
            },
        ], reason: c.name);
      }
    });

    test('the registry order and items', () {
      for (final c in pluginDispatchReference) {
        expect(
          jsObjectKeys(registry.plugins.items),
          c.expected['registry'],
          reason: c.name,
        );
      }
      for (final name in jsObjectKeys(plugins)) {
        final plugin = plugins[name]! as Plugin<Object?>;
        expect(
          registry.getPlugin(plugin.id),
          same(plugin),
          reason: 'the registry item of $name',
        );
      }
    });
  });

  group('dispatch', () {
    for (final c in pluginDispatchReference) {
      testWidgets(c.name, (tester) async {
        final calls = <String>[];
        final notifies = <String>[];
        final upstream = _upstreamCounts();
        for (final name in jsObjectKeys(plugins)) {
          _withPlugin(
            plugins[name],
            <O>(plugin) => _recordHooks(plugin, calls, upstream[plugin.id]),
          );
        }
        final config = copyReference(c.config)! as AnyObject;
        config['plugins'] = [_recorder(notifies)];
        final options = copyReference(c.options)! as AnyObject;
        Chart? chart;
        final steps = c.expected['steps']! as List<Object?>;
        for (var k = 0; k < steps.length; k++) {
          final step = steps[k]! as Map<String, Object?>;
          final action = step['do']! as List<Object?>;
          calls.clear();
          notifies.clear();
          switch (action) {
            case ['construct']:
              chart = acquireChart(config, options);
            case ['draw']:
              chart!.draw();
            case ['render']:
              chart!.render();
            case ['reset']:
              chart!.reset();
            case ['update']:
              chart!.update();
            case ['update', final String mode]:
              chart!.update(mode);
            case ['hover', final num x, final num y]:
              // The point of the generator: the rounded position of the
              // data element 2 of the dataset 0.
              final element = chart!.getDatasetMeta(0).data[2];
              expect(
                [element.x.roundToDouble(), element.y.roundToDouble()],
                [x, y],
                reason: 'step $k: the point of the hover',
              );
              await triggerMouseEvent(chart, 'mousemove', <String, Object?>{
                'x': x,
                'y': y,
              });
            case ['mouseout', final num x, final num y]:
              await triggerMouseEvent(chart!, 'mouseout', <String, Object?>{
                'x': x,
                'y': y,
              });
            case ['destroy']:
              chart!.destroy();
            default:
              fail('step $k: no step $action');
          }
          expect(calls, step['calls'], reason: 'step $k $action: the calls');
          expect(
            notifies,
            step['notifies'],
            reason: 'step $k $action: the notifies',
          );
        }
      });
    }
  });
}
