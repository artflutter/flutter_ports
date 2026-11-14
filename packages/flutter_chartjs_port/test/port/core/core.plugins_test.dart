// Original code, not ported from Chart.js: PluginService cases with no chart.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/core/core.plugins.dart';
import 'package:flutter_chartjs_port/src/core/core.registry.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ContextObject, createContext;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/plugin.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/color_json.dart';
import '../../support/mode_json.dart';
import 'registry_observe.dart';
import 'registry_reference.dart' as frozen show registryReference;
import 'registry_reference.dart' hide registryReference;

// The 19 cases of core.plugin.tests.js run on charts of acquireChart. These
// tests cover the PluginService of
// src/core/core.plugins.js on a fake chart with the scenarios of
// tool/reference/registry_reference.mjs (Chart.js ADR 0020, section 12): the
// cancel rules, a hook that a plugin gets after the descriptors exist, the
// hook order, the install, start, stop and uninstall hooks, the plugin
// options, the filter, the options of the config and the errors of the
// inline plugins. The expected lines come from the pinned sources in Node.js
// v24.22.1 on arm64.
//
// A plugin is a native Plugin (Chart.js ADR 0144, differences.md row
// `adapt-typed-plugins`). The reference plugins are objects with the custom
// hook `hook`, which has no field: the hook `reset` takes its place, and the
// expected lines name it. The kind of a hook is the `args.cancelable` of
// upstream. The reference scenarios of `this`, of hook values that are not
// functions, of plugins without an id and of the cancel flag have no native
// form: the hooks get no `this`, a hook field has the type of its hook, the
// id is a required String, and the kind of the hook replaces the flag.
//
// A test that registers a plugin in the singleton `registry` unregisters it
// at its end (Chart.js ADR 0022, section 8).

/// A fake chart: the `Config` of [config], and `getContext()` as
/// `core.controller.js:1083-1085` gives it. The other members of
/// `types.Chart` throw.
final class _Chart(Object? config) implements types.Chart {
  @override
  final Config config = Config(config);

  /// core.controller.js:1084 `$context`.
  ContextObject? _context;

  @override
  ContextObject getContext() =>
      _context ??= createContext(null, {'chart': this, 'type': 'chart'});

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A call of a hook of [_logPlugin]: the hook, the labels of the plugin and
/// of the chart, and the JSON of the arguments.
typedef _Record = ({
  String hook,
  String? plugin,
  String? chart,
  String args,
  String options,
});

/// The record [r] as an observation: all fields.
String _full(_Record r) =>
    '${r.hook} ${r.plugin} ${r.chart} ${r.args} ${r.options}';

/// The record [r] as an observation: the hook and the plugin.
String _short(_Record r) => '${r.hook} ${r.plugin}';

/// Gives [plugin] a hook of [hook] that runs [body].
void _setHook(
  Plugin<Object?> plugin,
  PluginHook<PluginHookArgs> hook,
  void Function(types.Chart chart, Object args, Object? options) body,
) {
  switch (hook) {
    case PluginHook.install:
      plugin.install = body;
    case PluginHook.start:
      plugin.start = body;
    case PluginHook.stop:
      plugin.stop = body;
    case PluginHook.uninstall:
      plugin.uninstall = body;
    case PluginHook.beforeInit:
      plugin.beforeInit = body;
    case PluginHook.afterDestroy:
      plugin.afterDestroy = body;
    case PluginHook.reset:
      plugin.reset = body;
    case _:
      throw ArgumentError.value(hook, 'hook', 'has no case');
  }
}

/// A plugin with the id [id], the label [id] and the fields [defaults] and
/// [scopes], whose hooks [hooks] add a record of each call to [log].
Plugin<Object?> _logPlugin(
  Observations o,
  List<_Record> log,
  String id,
  List<PluginHook<PluginHookArgs>> hooks, {
  AnyObject? defaults,
  List<String>? scopes,
}) {
  final plugin = Plugin<Object?>(
    id: id,
    defaults: defaults,
    additionalOptionScopes: scopes,
  );
  for (final hook in hooks) {
    _setHook(plugin, hook, (chart, args, options) {
      log.add((
        hook: hook.jsName,
        plugin: id,
        chart: o.labelOf(chart),
        // The `{}` of upstream: the arguments without fields.
        args: args.runtimeType == PluginHookArgs ? '{}' : o.json(args),
        options: o.json(options),
      ));
    });
  }
  return plugin;
}

/// A fake chart of [config], with the label `chart`.
_Chart _chart(Observations o, Object? config) =>
    o.label(_Chart(config), 'chart');

/// `String(result)` of a notify: Dart `null` is `undefined`.
String _result(Object? result) => '${result ?? 'undefined'}';

/// The reference text [text] with the hook `reset` in place of the custom
/// hook `hook` of the reference plugins.
String _resetHook(String text) => text.replaceAll('log: hook ', 'log: reset ');

void main() {
  setUpSpecs();

  test('the reference comes from Node.js v24.22.1 on arm64', () {
    expect(registryReferenceNode, 'v24.22.1');
    expect(registryReferenceArch, 'arm64');
  });

  test('a cancelable hook stops the loop at the first false', () {
    // The cases `cancelable` and `not cancelable` of the reference
    // `plugins cancel`: the kind of the hook is the flag of upstream.
    String run(List<bool> results) {
      final called = <int>[];
      final plugins = [
        for (var i = 0; i < results.length; i++)
          Plugin<Object?>(
            id: 'p$i',
            beforeRender: (chart, args, options) {
              called.add(i);
              return results[i];
            },
            afterRender: (chart, args, options) => called.add(-i),
          ),
      ];
      final chart = _Chart(<String, Object?>{'plugins': plugins});
      final service = PluginService()..notify(chart, PluginHook.beforeInit);
      final before = service.notify(chart, PluginHook.beforeRender);
      final after = service.notify(chart, PluginHook.afterRender);
      return '$called $before $after';
    }

    expect(
      run([true, true, false, true]),
      '[0, 1, 2, 0, -1, -2, -3] false true',
    );
    expect(run([true, true]), '[0, 1, 0, -1] true true');
  });

  test('a hook that the plugin gets later runs at the next notify', () {
    final o = Observations();
    final log = <String>[];
    final plugin = Plugin<Object?>(id: 'late');
    final chart = _chart(o, <String, Object?>{
      'plugins': [plugin],
    });
    final service = PluginService()..notify(chart, PluginHook.beforeInit);
    o.observe('before', _result(service.notify(chart, PluginHook.reset)));
    plugin.reset = (chart, args, options) => log.add('first late');
    o.observe('first', _result(service.notify(chart, PluginHook.reset)));
    plugin.beforeRender = (chart, args, options) {
      log.add('second late');
      return false;
    };
    o.observe(
      'second',
      _result(service.notify(chart, PluginHook.beforeRender)),
    );
    for (final line in log) {
      o.observe('log', line);
    }
    expect(o.text, registryReference['plugins late hook']);
  });

  test('the hooks run in the Object.keys order of the items', () {
    final o = Observations();
    final log = <_Record>[];
    final registered = [
      for (final id in ['zz', '7', 'a'])
        _logPlugin(o, log, id, [PluginHook.reset]),
    ];
    registry.add(registered);
    addTearDown(() => registry.remove(registered));
    final local1 = _logPlugin(o, log, 'local1', [PluginHook.reset]);
    final local0 = _logPlugin(o, log, 'local0', [PluginHook.reset]);
    final chart = _chart(o, <String, Object?>{
      'plugins': [local1, registered[0], local0, local1],
    });
    final service = PluginService()
      ..notify(chart, PluginHook.beforeInit)
      ..notify(chart, PluginHook.reset);
    for (final record in log) {
      o.observe('log', _short(record));
    }
    // Only the plugins of this test: the harness can register built-in
    // plugins in the singleton (Chart.js ADR 0022, section 8).
    const ids = {'7', 'zz', 'a', 'local1', 'local0'};
    o.observe(
      'cache',
      o.json([
        for (final d in service.cache!)
          if (ids.contains(d.plugin.id)) d.plugin.id,
      ]),
    );
    registry.remove(registered);
    expect(o.text, _resetHook(registryReference['plugins order']!));
  });

  test('install, start, stop and uninstall', () {
    final o = Observations();
    final log = <_Record>[];
    const hooks = [
      PluginHook.install,
      PluginHook.start,
      PluginHook.stop,
      PluginHook.uninstall,
      PluginHook.beforeInit,
      PluginHook.afterDestroy,
      PluginHook.reset,
    ];
    final a = _logPlugin(o, log, 'a', hooks);
    final b = _logPlugin(o, log, 'b', hooks);
    final chart = _chart(o, <String, Object?>{
      'plugins': [a, b],
      'options': <String, Object?>{
        'plugins': <String, Object?>{'b': false},
      },
    });
    final service = PluginService();
    void step(String name, Object? Function() body) {
      final result = body();
      o.observe(name, _result(result));
      for (final record in log) {
        o.observe('log', _full(record));
      }
      log.clear();
    }

    step('hook before init', () => service.notify(chart, PluginHook.reset));
    step('beforeInit', () => service.notify(chart, PluginHook.beforeInit));
    step('hook', () => service.notify(chart, PluginHook.reset));
    step('cache', () => o.json([for (final d in service.cache!) d.plugin.id]));
    (chart.config.options as AnyObject)['plugins'] = <String, Object?>{
      'a': false,
    };
    service.invalidate();
    step('hook after a change', () => service.notify(chart, PluginHook.reset));
    service
      ..invalidate()
      ..invalidate();
    step(
      'hook after a double invalidate',
      () => service.notify(chart, PluginHook.reset),
    );
    step('afterDestroy', () => service.notify(chart, PluginHook.afterDestroy));
    step('hook after destroy', () => service.notify(chart, PluginHook.reset));
    expect(o.text, _resetHook(registryReference['plugins lifecycle']!));
  });

  test('the options of the plugins', () {
    // The reference plugins `anon1` and `anon2` have no id: a native plugin
    // has one, so their lines go.
    final o = Observations();
    final log = <_Record>[];
    final popt = _logPlugin(
      o,
      log,
      'popt',
      [PluginHook.reset],
      defaults: <String, Object?>{
        'a': 1.0,
        'nested': <String, Object?>{'b': 2.0},
      },
    );
    registry.add([popt]);
    addTearDown(() => registry.remove([popt]));
    final plocal = _logPlugin(
      o,
      log,
      'plocal',
      [PluginHook.reset],
      defaults: <String, Object?>{'c': 3.0},
    );
    final padd = _logPlugin(
      o,
      log,
      'padd',
      [PluginHook.reset],
      scopes: ['interaction'],
    );
    final pfn = _logPlugin(o, log, 'pfn', [PluginHook.reset]);
    void run(String name, Object? pluginOptions) {
      final chart = _chart(o, <String, Object?>{
        'type': 'tplug',
        'plugins': [plocal, padd, pfn],
        'options': <String, Object?>{'plugins': pluginOptions},
      });
      final service = PluginService()..notify(chart, PluginHook.beforeInit);
      o.observe(name, _result(service.notify(chart, PluginHook.reset)));
      for (final record in log) {
        o.observe('log', '${record.plugin} ${record.options}');
      }
      log.clear();
    }

    run('object', <String, Object?>{
      'popt': <String, Object?>{'a': 5.0},
      'plocal': <String, Object?>{'d': 4.0},
      'pfn': <String, Object?>{'f': () => 1.0},
    });
    run('true', <String, Object?>{'popt': true, 'plocal': true});
    run('undefined', undefined);
    run('false', false);
    run('false for one id', <String, Object?>{'popt': false, 'padd': false});
    run('null for one id', <String, Object?>{'plocal': null});
    registry.remove([popt]);
    final expected = [
      for (final line in registryReference['plugins options']!.split('\n'))
        if (!line.startsWith('log: anon')) line,
    ].join('\n');
    expect(o.text, expected);
  });

  test('the filter of notify', () {
    final o = Observations();
    final log = <_Record>[];
    final a = _logPlugin(o, log, 'a', [PluginHook.reset]);
    final b = _logPlugin(o, log, 'b', [PluginHook.reset]);
    final chart = _chart(o, <String, Object?>{
      'plugins': [a, b],
    });
    final service = PluginService()..notify(chart, PluginHook.beforeInit);
    o.observe(
      'result',
      _result(
        service.notify(
          chart,
          PluginHook.reset,
          const PluginHookArgs(),
          (d) => d.plugin.id == 'b',
        ),
      ),
    );
    for (final record in log) {
      o.observe('log', _short(record));
    }
    expect(o.text, _resetHook(registryReference['plugins filter']!));
  });

  test('the errors of the inline plugins', () {
    // `number: ok` upstream: a number has no hook. A value that is not a
    // Plugin stops a debug build (Chart.js ADR 0144).
    final o = Observations();
    for (final (name, value) in <(String, List<Object?>)>[
      ('null', [null]),
      ('undefined', [undefined]),
      ('number', [5.0]),
    ]) {
      final chart = _chart(o, <String, Object?>{'plugins': value});
      final service = PluginService();
      o.observe(
        name,
        error(() => service.notify(chart, PluginHook.beforeInit)),
      );
    }
    expect(
      o.text,
      registryReference['plugins local errors']!.replaceFirst(
        'number: ok',
        'number: _AssertionError',
      ),
    );
  });

  test('the descriptors of a notify before install', () {
    final chart = _Chart(<String, Object?>{});
    final service = PluginService();
    expect(service.notify(chart, PluginHook.reset), isNull);
    expect(service.cache, isNull);
    expect(service.notify(chart, PluginHook.beforeInit), isTrue);
    expect(service.cache, isEmpty);
  });

  group('adapt-config-objects', () {
    /// The lines of the options of the config in the port.
    String configOptionLines() {
      final o = Observations();
      for (final (name, value) in <(String, Object?)>[
        ('undefined', undefined),
        ('false', false),
        ('null', null),
      ]) {
        final log = <_Record>[];
        final a = _logPlugin(o, log, 'a', [PluginHook.reset]);
        final chart = _chart(o, <String, Object?>{
          'plugins': [a],
        });
        final service = PluginService()..notify(chart, PluginHook.beforeInit);
        chart.config.options = value;
        service.invalidate();
        o
          ..observe(name, error(() => service.notify(chart, PluginHook.reset)))
          ..observe('$name calls', '${log.length}');
      }
      return o.text;
    }

    test('new descriptors read the options getter of the config', () {
      // Upstream reads `config.options && config.options.plugins`
      // (core.plugins.js:103): `undefined` gives `{}`, and `false` gives no
      // descriptors. The getter of the port throws a TypeError for each
      // value that is not a Map, until `config.update()`. Both throw for
      // `null`.
      expect(registryReference['plugins config options'], '''
undefined: ok
undefined calls: 1
false: ok
false calls: 0
null: TypeError
null calls: 0''');
      expect(configOptionLines(), '''
undefined: TypeError
undefined calls: 0
false: TypeError
false calls: 0
null: TypeError
null calls: 0''');
    });
  });

  // The native dispatch of Chart.js ADR 0144 (differences.md row
  // `adapt-typed-plugins`).
  group('adapt-typed-plugins', () {
    test('a plugin gets its hooks with the typed arguments', () {
      final calls = <String>[];
      final plugin = Plugin<Object?>(
        id: 'typed',
        install: (chart, args, options) =>
            calls.add('install ${args.runtimeType}'),
        beforeUpdate: (chart, args, options) {
          calls.add('beforeUpdate ${args.mode}');
          return false;
        },
        resize: (chart, args, options) =>
            calls.add('resize ${args.size.width} ${args.size.height}'),
      );
      final chart = _Chart(<String, Object?>{
        'plugins': [plugin],
      });
      final service = PluginService();
      expect(service.notify(chart, PluginHook.beforeInit), isTrue);
      expect(
        service.notify(
          chart,
          PluginHook.beforeUpdate,
          UpdateHookArgs(mode: 'resize'),
        ),
        isFalse,
      );
      expect(
        service.notify(
          chart,
          PluginHook.resize,
          ResizeHookArgs(size: (width: 2.0, height: 3.0)),
        ),
        isTrue,
      );
      expect(calls, [
        'install PluginHookArgs',
        'beforeUpdate resize',
        'resize 2.0 3.0',
      ]);
      // A hook whose argument class is not PluginHookArgs needs its
      // arguments.
      expect(
        () => service.notify(chart, PluginHook.resize),
        throwsArgumentError,
      );
    });

    test('a plugin gets the args object by identity', () {
      // core.plugin.tests.js:3-16: notifyPlugins gives each plugin the same
      // args object.
      final seen = <Object>[];
      final plugins = [
        for (final id in ['a', 'b'])
          Plugin<Object?>(
            id: id,
            afterUpdate: (chart, args, options) => seen.add(args),
          ),
      ];
      final chart = _Chart(<String, Object?>{'plugins': plugins});
      final service = PluginService()..notify(chart, PluginHook.beforeInit);
      final args = UpdateHookArgs(mode: 'user');
      expect(service.notify(chart, PluginHook.afterUpdate, args), isTrue);
      expect(seen, [same(args), same(args)]);
    });

    test('the options factory makes the options of each hook', () {
      final seen = <Object?>[];
      final plugin = Plugin<String>(
        id: 'opts',
        options: (view) => 'view ${view.runtimeType}',
        afterDraw: (chart, args, options) => seen.add(options),
      );
      final chart = _Chart(<String, Object?>{
        'plugins': [plugin],
      });
      final service = PluginService()..notify(chart, PluginHook.beforeInit);
      expect(service.notify(chart, PluginHook.afterDraw), isTrue);
      expect(seen, ['view OptionView']);
    });

    test('a value that is not a Plugin stops a debug build', () {
      final chart = _Chart(<String, Object?>{
        'plugins': [
          <String, Object?>{'id': 'map', 'afterDraw': () {}},
        ],
      });
      expect(
        () => PluginService().notify(chart, PluginHook.beforeInit),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => registry.add([
          <String, Object?>{'id': 'map', 'afterDraw': () {}},
        ]),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

final Map<String, String> registryReference = {
  for (final entry in frozen.registryReference.entries)
    entry.key: withModeMarkers(referenceColorTokens(entry.value)),
};
