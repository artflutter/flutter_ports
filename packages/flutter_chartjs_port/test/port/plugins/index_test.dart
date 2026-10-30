// Original code, not ported from Chart.js: the plugin hook dispatch of src/plugins/index.js.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.registry.dart' show registry;
import 'package:flutter_chartjs_port/src/core/core.scale.dart' show Scale;
import 'package:flutter_chartjs_port/src/index.dart' show plugins;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_class.dart' show JsClass;
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsToString;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/plugin.dart'
    show PluginHook, PluginHookFunction;
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart';
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
// namespace `plugins` and the registry order. A function key gives its count
// of positional parameters: the `length` of the JS function and the count
// that the Dart function takes. A hook of the `Plugin` interface is a typed
// hook function `(chart, args, options)` (Chart.js ADR 0054 §12, which
// supersedes the upstream parameter counts of the hooks of Chart.js ADR
// 0038, section 3): both sides give it as `<key>(hook)`, the Dart side for a
// function of the hook type with 3 parameters ([_hookText]).
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

/// The hook names of the interface `Plugin` (src/types/index.d.ts:856-1164)
/// in source order, then the two hooks of `ExtendedPlugin`
/// (src/types/index.d.ts:2764-2787): `HOOKS` of the generator.
const List<String> _hooks = [
  'install',
  'start',
  'stop',
  'beforeInit',
  'afterInit',
  'beforeUpdate',
  'afterUpdate',
  'beforeElementsUpdate',
  'reset',
  'beforeDatasetsUpdate',
  'afterDatasetsUpdate',
  'beforeDatasetUpdate',
  'afterDatasetUpdate',
  'beforeLayout',
  'beforeDataLimits',
  'afterDataLimits',
  'beforeBuildTicks',
  'afterBuildTicks',
  'afterLayout',
  'beforeRender',
  'afterRender',
  'beforeDraw',
  'afterDraw',
  'beforeDatasetsDraw',
  'afterDatasetsDraw',
  'beforeDatasetDraw',
  'afterDatasetDraw',
  'beforeEvent',
  'afterEvent',
  'resize',
  'beforeDestroy',
  'afterDestroy',
  'uninstall',
  'beforeTooltipDraw',
  'afterTooltipDraw',
];

/// The hooks whose args have the dataset `index`.
const Set<String> _indexHooks = {
  'beforeDatasetUpdate',
  'afterDatasetUpdate',
  'beforeDatasetDraw',
  'afterDatasetDraw',
};

/// The hooks whose args are the context of a scale (core.scale.js:534-537).
const Set<String> _scaleHooks = {
  'beforeDataLimits',
  'afterDataLimits',
  'beforeBuildTicks',
  'afterBuildTicks',
};

/// The hooks whose args have the `event`.
const Set<String> _eventHooks = {'beforeEvent', 'afterEvent'};

/// The hooks whose args have the update `mode`.
const Set<String> _modeHooks = {
  'beforeUpdate',
  'afterUpdate',
  'beforeDatasetsUpdate',
  'afterDatasetsUpdate',
  'beforeDatasetUpdate',
  'afterDatasetUpdate',
};

/// `detail(hook, args)` of the generator: [hook], then `:<detail>` for the
/// `index` of a dataset hook, the `id` of the `scale` of a scale hook, the
/// `type` of the `event` of an event hook and the `ToString` of the `mode`
/// of an update hook.
String _detail(String hook, Object? args) {
  final text = StringBuffer(hook);
  if (_indexHooks.contains(hook)) {
    text.write(':${jsToString(jsGet(args, 'index'))}');
  }
  if (_scaleHooks.contains(hook)) {
    text.write(':${(jsGet(args, 'scale')! as Scale).id}');
  }
  if (_eventHooks.contains(hook)) {
    text.write(':${(jsGet(args, 'event')! as types.ChartEvent).type}');
  }
  if (_modeHooks.contains(hook)) {
    text.write(':${jsToString(jsGet(args, 'mode'))}');
  }
  return text.toString();
}

/// The counts of positional arguments, from 0 to 4, that [f] takes with no
/// named argument (the arity test of `jsCall`). A parameter of type `Never`
/// accepts every parameter type.
List<int> _counts(Function f) => [
  if (f is Object? Function()) 0,
  if (f is Object? Function(Never)) 1,
  if (f is Object? Function(Never, Never)) 2,
  if (f is Object? Function(Never, Never, Never)) 3,
  if (f is Object? Function(Never, Never, Never, Never)) 4,
];

/// `keyText(plugin, key)` of the generator: `<key>(<count>)` for a closure,
/// `<key>: class` for a class value, else the key. A closure that takes
/// more than one count gives the counts with `|`, and fails the comparison.
/// A hook of the `Plugin` interface gives `<key>(hook)` for a typed hook
/// function ([_hookText]).
String _keyText(AnyObject plugin, String key) => switch (plugin[key]) {
  final JsClass _ => '$key: class',
  final Function f when PluginHook.of(key) != null => _hookText(key, f),
  final Function f => '$key(${_counts(f).join('|')})',
  _ => key,
};

/// The text of the hook [key] with the function [f]: `<key>(hook)` for a
/// function of the hook type `(chart, args, options)` that takes exactly 3
/// arguments (Chart.js ADR 0054 §12), else the counts of [f].
String _hookText(String key, Function f) =>
    f is PluginHookFunction<Never> && _counts(f).join('|') == '3'
    ? '$key(hook)'
    : '$key(${_counts(f).join('|')})';

/// The reference text of a key: `<key>(hook)` for a hook of the `Plugin`
/// interface (the JS `length` of the hook is no behavior of Chart.js:
/// Chart.js ADR 0054 §12), else the text of the generator.
String _referenceKeyText(String text) {
  final open = text.indexOf('(');
  if (open < 0 || !text.endsWith(')')) return text;
  final key = text.substring(0, open);
  return PluginHook.of(key) != null ? '$key(hook)' : text;
}

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

/// A recording closure for the hook [key] of the plugin [id]: it adds the
/// hook text to [calls] and calls [f] with the same arguments. It takes the
/// count of positional arguments of [f]. The generator gives `{}` as the
/// args of a hook with one parameter, as `_notify` gives `args || {}`.
///
/// A typed hook function (Chart.js ADR 0054 §12) takes the 3 arguments of
/// the hook type: its recording closure takes them too, and records the
/// args as the generator does for the upstream count [upstream] of the
/// hook.
Function _recording(
  String id,
  String key,
  Function f,
  List<String> calls,
  int? upstream,
) {
  final counts = _counts(f);
  expect(counts, hasLength(1), reason: 'the parameters of $id.$key');
  if (f is PluginHookFunction<Never> && PluginHook.of(key) != null) {
    expect(upstream, isNotNull, reason: 'the upstream count of $id.$key');
    return (Object? chart, Object? args, Object? options) {
      calls.add(
        '$id.${_detail(key, upstream == 1 ? const <String, Object?>{} : args)}',
      );
      return Function.apply(f, [chart, args, options]);
    };
  }
  return switch (counts.single) {
    1 => (Object? chart) {
      calls.add('$id.${_detail(key, const <String, Object?>{})}');
      return Function.apply(f, [chart]);
    },
    2 => (Object? chart, Object? args) {
      calls.add('$id.${_detail(key, args)}');
      return Function.apply(f, [chart, args]);
    },
    3 => (Object? chart, Object? args, Object? options) {
      calls.add('$id.${_detail(key, args)}');
      return Function.apply(f, [chart, args, options]);
    },
    final n => throw StateError('$id.$key takes $n arguments'),
  };
}

/// Replaces each hook of each plugin object of the namespace `plugins` with
/// a [_recording] closure, and restores the hooks with `addTearDown`.
void _recordHooks(List<String> calls) {
  final upstream = _upstreamCounts();
  for (final name in jsObjectKeys(plugins)) {
    final plugin = plugins[name]! as AnyObject;
    final id = plugin['id']! as String;
    for (final key in jsObjectKeys(plugin)) {
      final value = plugin[key];
      if (value is! Function) {
        continue;
      }
      plugin[key] = _recording(id, key, value, calls, upstream[id]?[key]);
      addTearDown(() => plugin[key] = value);
    }
  }
}

/// The inline plugin `recorder`: a closure for each of [_hooks] that adds
/// the hook text to [notifies].
AnyObject _recorder(List<String> notifies) => <String, Object?>{
  'id': 'recorder',
  for (final hook in _hooks)
    hook: (Object? chart, Object? args, Object? options) {
      notifies.add(_detail(hook, args));
    },
};

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
      [
        'three datasets, a title and a fill',
        'plugins false',
      ],
    );
  });

  group('plugin objects', () {
    // Each case of the generator records the same plugin objects and the
    // same registry.
    test('the keys of each plugin object', () {
      final keys = [
        for (final name in jsObjectKeys(plugins))
          <String, Object?>{
            'id': (plugins[name]! as AnyObject)['id'],
            'keys': [
              for (final key in jsObjectKeys(plugins[name]! as AnyObject))
                _keyText(plugins[name]! as AnyObject, key),
            ],
          },
      ];
      for (final c in pluginDispatchReference) {
        expect(
          keys,
          [
            for (final plugin
                in (c.expected['plugins']! as List<Object?>)
                    .cast<Map<String, Object?>>())
              <String, Object?>{
                'id': plugin['id'],
                'keys': [
                  for (final text in plugin['keys']! as List<Object?>)
                    _referenceKeyText(text! as String),
                ],
              },
          ],
          reason: c.name,
        );
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
        final plugin = plugins[name]! as AnyObject;
        expect(
          registry.getPlugin(plugin['id']! as String),
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
        _recordHooks(calls);
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
