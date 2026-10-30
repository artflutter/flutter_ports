// Original code, not ported from Chart.js: PluginService cases with no chart.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/core/core.plugins.dart';
import 'package:flutter_chartjs_port/src/core/core.registry.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show createContext;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/plugin.dart';
import 'package:flutter_test/flutter_test.dart';

import 'registry_observe.dart';
import 'registry_reference.dart';

// The 19 cases of core.plugin.tests.js run on charts of acquireChart. These
// tests cover the PluginService of
// src/core/core.plugins.js on a fake chart with the scenarios of
// tool/reference/registry_reference.mjs (Chart.js ADR 0020, section 12): the
// cancel rules, a hook that a plugin gets after the descriptors exist, the
// `this` of a hook, the values that are not functions, the hook order, the
// install, start, stop and uninstall hooks, the plugin options, the filter,
// the options of the config and the errors of the inline plugins. The
// expected lines come from the pinned sources in Node.js v24.22.1 on arm64.
//
// A test that registers a plugin in the singleton `registry` unregisters it
// at its end (Chart.js ADR 0022, section 8).

/// A fake chart: the `Config` of [config], and `getContext()` as
/// `core.controller.js:1083-1085` gives it. The other members of
/// `types.Chart` throw.
final class _Chart implements types.Chart {
  _Chart(Object? config) : config = Config(config);

  @override
  final Config config;

  /// core.controller.js:1084 `$context`.
  AnyObject? _context;

  @override
  AnyObject getContext() => _context ??= createContext(null, {
    'chart': this,
    'type': 'chart',
  });

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A call of a hook of [_logPlugin]: the labels of `this` and of the chart,
/// and the JSON of the arguments.
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

/// A plugin Map with the label [name] and the entries [extra], whose hooks
/// [hooks] add a record of each call to [log].
AnyObject _logPlugin(
  Observations o,
  List<_Record> log,
  String name,
  List<String> hooks, [
  AnyObject extra = const {},
]) {
  final plugin = <String, Object?>{...extra};
  for (final hook in hooks) {
    plugin[hook] = JsFunction((
      Object? self,
      Object? chart,
      Object? args,
      Object? options,
    ) {
      log.add((
        hook: hook,
        plugin: o.labelOf(self),
        chart: o.labelOf(chart),
        args: o.json(args),
        options: o.json(options),
      ));
    });
  }
  return o.label(plugin, name);
}

/// A fake chart of [config], with the label `chart`.
_Chart _chart(Observations o, Object? config) =>
    o.label(_Chart(config), 'chart');

/// `String(result)` of a notify: Dart `null` is `undefined`.
String _result(Object? result) => '${result ?? 'undefined'}';

void main() {
  setUpSpecs();

  test('the reference comes from Node.js v24.22.1 on arm64', () {
    expect(registryReferenceNode, 'v24.22.1');
    expect(registryReferenceArch, 'arm64');
  });

  test('only false with a truthy cancelable stops the loop', () {
    final o = Observations();
    String run(List<Object?> values, AnyObject? args, {bool before = false}) {
      final called = <double>[];
      final plugins = [
        for (var i = 0; i < values.length; i++)
          <String, Object?>{
            'hook': (Object? chart, Object? a) {
              called.add(i.toDouble());
              if (before && i == 0) (a! as AnyObject)['cancelable'] = false;
              return values[i];
            },
          },
      ];
      final chart = _chart(o, <String, Object?>{'plugins': plugins});
      final service = PluginService()..notify(chart, 'beforeInit');
      final result = service.notify(chart, 'hook', args);
      return '${o.json(called)} ${_result(result)}';
    }

    final results = <Object?>[undefined, null, 0.0, true, 1.0, false, 'x'];
    o
      ..observe('cancelable', run(results, {'cancelable': true}))
      ..observe('not cancelable', run(results, {'cancelable': false}))
      ..observe('no args', run(results, null))
      ..observe('truthy cancelable', run([false, 'x'], {'cancelable': 1.0}))
      ..observe(
        'cleared cancelable',
        run([false, 'x'], {'cancelable': true}, before: true),
      )
      ..observe('string false', run(['false', false], {'cancelable': true}));
    expect(o.text, registryReference['plugins cancel']);
  });

  test('a hook that the plugin gets later runs at the next notify', () {
    final o = Observations();
    final log = <String>[];
    final plugin = o.label(<String, Object?>{'id': 'late'}, 'late');
    final chart = _chart(o, <String, Object?>{
      'plugins': [plugin],
    });
    final service = PluginService()..notify(chart, 'beforeInit');
    o.observe('before', _result(service.notify(chart, 'hook')));
    plugin['hook'] = JsFunction((Object? self) {
      log.add('first ${o.labelOf(self)}');
    });
    o.observe('first', _result(service.notify(chart, 'hook')));
    plugin['hook'] = JsFunction((Object? self) {
      log.add('second ${o.labelOf(self)}');
      return false;
    });
    o.observe(
      'second',
      _result(service.notify(chart, 'hook', {'cancelable': true})),
    );
    for (final line in log) {
      o.observe('log', line);
    }
    expect(o.text, registryReference['plugins late hook']);
  });

  test('a hook gets the Map or the class value as this', () {
    final o = Observations();
    final log = <String>[];
    final map = o.label(<String, Object?>{'id': 'pmap'}, 'pmap');
    map['hook'] = JsFunction((Object? self) {
      log.add('map ${o.labelOf(self)}');
    });
    final pClass = o.label(JsClass('PClass'), 'PClass')
      ..['id'] = 'pclass'
      ..['hook'] = JsFunction((Object? self) {
        log.add('class ${o.labelOf(self)}');
      });
    final chart = _chart(o, <String, Object?>{
      'plugins': [map, pClass],
    });
    PluginService()
      ..notify(chart, 'beforeInit')
      ..notify(chart, 'hook');
    for (final line in log) {
      o.observe('log', line);
    }
    expect(o.text, registryReference['plugins this']);
  });

  /// The lines of the hook values in the port.
  String hookValueLines() {
    final o = Observations();
    final values = <Object?>[5.0, 'str', <String, Object?>{}, null, true];
    final plugins = [
      for (var i = 0; i < values.length; i++)
        o.label(<String, Object?>{'id': 'pv$i', 'hook': values[i]}, 'pv$i'),
    ];
    final chart = _chart(o, <String, Object?>{'plugins': plugins});
    final service = PluginService()..notify(chart, 'beforeInit');
    o.observe('values', error(() => service.notify(chart, 'hook')));
    final classHook = <String, Object?>{
      'id': 'pclasshook',
      'hook': JsClass('PHook'),
    };
    final chart2 = _chart(o, <String, Object?>{
      'plugins': [classHook],
    });
    final service2 = PluginService()..notify(chart2, 'beforeInit');
    o.observe('class value', error(() => service2.notify(chart2, 'hook')));
    return o.text;
  }

  test('a value that is not a function gives no call', () {
    // A class value as a hook: jsCall throws an ArgumentError, where
    // JavaScript throws a TypeError for the call of a class constructor
    // without `new` (Chart.js ADR 0020, section 2).
    expect(
      hookValueLines(),
      registryReference['plugins hook values']!.replaceFirst(
        'class value: TypeError',
        'class value: ArgumentError',
      ),
    );
  });

  test('the hooks run in the Object.keys order of the items', () {
    final o = Observations();
    final log = <_Record>[];
    final registered = [
      for (final id in ['zz', '7', 'a'])
        _logPlugin(o, log, id, ['hook'], {'id': id}),
    ];
    registry.add(registered);
    addTearDown(() => registry.remove(registered));
    final local1 = _logPlugin(o, log, 'local1', ['hook'], {'id': 'local1'});
    final local0 = _logPlugin(o, log, 'local0', ['hook'], {'id': 'local0'});
    final chart = _chart(o, <String, Object?>{
      'plugins': [local1, registered[0], local0, local1],
    });
    final service = PluginService()
      ..notify(chart, 'beforeInit')
      ..notify(chart, 'hook');
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
          if (ids.contains(jsGet(d.plugin, 'id'))) jsGet(d.plugin, 'id'),
      ]),
    );
    registry.remove(registered);
    expect(o.text, registryReference['plugins order']);
  });

  test('install, start, stop and uninstall', () {
    final o = Observations();
    final log = <_Record>[];
    const hooks = [
      'install',
      'start',
      'stop',
      'uninstall',
      'beforeInit',
      'afterDestroy',
      'hook',
    ];
    final a = _logPlugin(o, log, 'a', hooks, {'id': 'a'});
    final b = _logPlugin(o, log, 'b', hooks, {'id': 'b'});
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

    step('hook before init', () => service.notify(chart, 'hook'));
    step('beforeInit', () => service.notify(chart, 'beforeInit'));
    step('hook', () => service.notify(chart, 'hook'));
    step(
      'cache',
      () => o.json([for (final d in service.cache!) jsGet(d.plugin, 'id')]),
    );
    chart.config.options['plugins'] = <String, Object?>{'a': false};
    service.invalidate();
    step('hook after a change', () => service.notify(chart, 'hook'));
    service
      ..invalidate()
      ..invalidate();
    step('hook after a double invalidate', () => service.notify(chart, 'hook'));
    step('afterDestroy', () => service.notify(chart, 'afterDestroy'));
    step('hook after destroy', () => service.notify(chart, 'hook'));
    expect(o.text, registryReference['plugins lifecycle']);
  });

  test('the options of the plugins', () {
    final o = Observations();
    final log = <_Record>[];
    final popt = _logPlugin(
      o,
      log,
      'popt',
      ['hook'],
      {
        'id': 'popt',
        'defaults': <String, Object?>{
          'a': 1.0,
          'nested': <String, Object?>{'b': 2.0},
        },
      },
    );
    registry.add([popt]);
    addTearDown(() => registry.remove([popt]));
    final plocal = _logPlugin(
      o,
      log,
      'plocal',
      ['hook'],
      {
        'id': 'plocal',
        'defaults': <String, Object?>{'c': 3.0},
      },
    );
    final padd = _logPlugin(
      o,
      log,
      'padd',
      ['hook'],
      {
        'id': 'padd',
        'additionalOptionScopes': ['interaction'],
      },
    );
    final pfn = _logPlugin(o, log, 'pfn', ['hook'], {'id': 'pfn'});
    final anon1 = _logPlugin(
      o,
      log,
      'anon1',
      ['hook'],
      {
        'defaults': <String, Object?>{'x': 1.0},
      },
    );
    final anon2 = _logPlugin(
      o,
      log,
      'anon2',
      ['hook'],
      {
        'defaults': <String, Object?>{'y': 2.0},
      },
    );
    void run(String name, Object? pluginOptions) {
      final chart = _chart(o, <String, Object?>{
        'type': 'tplug',
        'plugins': [plocal, padd, pfn, anon1, anon2],
        'options': <String, Object?>{'plugins': pluginOptions},
      });
      final service = PluginService()..notify(chart, 'beforeInit');
      o.observe(name, _result(service.notify(chart, 'hook')));
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
    expect(o.text, registryReference['plugins options']);
  });

  test('the filter of notify', () {
    final o = Observations();
    final log = <_Record>[];
    final a = _logPlugin(o, log, 'a', ['hook'], {'id': 'a'});
    final b = _logPlugin(o, log, 'b', ['hook'], {'id': 'b'});
    final chart = _chart(o, <String, Object?>{
      'plugins': [a, b],
    });
    final service = PluginService()..notify(chart, 'beforeInit');
    o.observe(
      'result',
      _result(
        service.notify(
          chart,
          'hook',
          <String, Object?>{},
          (d) => jsGet(d.plugin, 'id') == 'b',
        ),
      ),
    );
    for (final record in log) {
      o.observe('log', _short(record));
    }
    expect(o.text, registryReference['plugins filter']);
  });

  test('the errors of the inline plugins', () {
    final o = Observations();
    for (final (name, value) in <(String, List<Object?>)>[
      ('null', [null]),
      ('undefined', [undefined]),
      ('number', [5.0]),
    ]) {
      final chart = _chart(o, <String, Object?>{'plugins': value});
      final service = PluginService();
      o.observe(name, error(() => service.notify(chart, 'beforeInit')));
    }
    expect(o.text, registryReference['plugins local errors']);
  });

  test('the descriptors of a notify before install', () {
    final chart = _Chart(<String, Object?>{});
    final service = PluginService();
    expect(service.notify(chart, 'hook'), isNull);
    expect(service.cache, isNull);
    expect(service.notify(chart, 'beforeInit'), isTrue);
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
        final a = _logPlugin(o, log, 'a', ['hook'], {'id': 'a'});
        final chart = _chart(o, <String, Object?>{
          'plugins': [a],
        });
        final service = PluginService()..notify(chart, 'beforeInit');
        chart.config.options = value;
        service.invalidate();
        o
          ..observe(name, error(() => service.notify(chart, 'hook')))
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

  // The typed dispatch of Chart.js ADR 0054 §12 (differences.md row
  // `adapt-typed-plugins`).
  group('adapt-typed-plugins', () {
    test('a typed plugin gets its hooks with the typed arguments', () {
      final calls = <String>[];
      final plugin = Plugin()
        ..id = 'typed'
        ..install = (chart, args, options) {
          calls.add('install ${args.runtimeType}');
          return null;
        }
        ..beforeUpdate = (chart, args, options) {
          calls.add('beforeUpdate ${args.mode} ${args.cancelable}');
          return false;
        }
        ..afterDatasetUpdate = (chart, args, options) {
          calls.add('afterDatasetUpdate ${args.index} ${args.cancelable}');
          return null;
        };
      final chart = _Chart(<String, Object?>{
        'plugins': [plugin],
      });
      final service = PluginService();
      expect(service.notify(chart, 'beforeInit'), isTrue);
      final update = UpdateHookArgs(mode: 'resize', cancelable: true);
      expect(service.notify(chart, 'beforeUpdate', update), isFalse);
      // Not cancelable: the false result does not stop the notify.
      expect(
        service.notify(chart, 'beforeUpdate', UpdateHookArgs(mode: 'none')),
        isTrue,
      );
      final dataset = DatasetUpdateHookArgs(
        meta: null,
        index: 2,
        mode: 'm',
        cancelable: false,
      );
      expect(service.notify(chart, 'afterDatasetUpdate', dataset), isTrue);
      expect(calls, [
        'install PluginHookArgs',
        'beforeUpdate resize true',
        'beforeUpdate none false',
        'afterDatasetUpdate 2.0 false',
      ]);
      // The narrow case of the row adapt-typed-plugins: a hook function
      // that is typed for its argument class throws a TypeError for an args
      // object of another class.
      expect(
        () => service.notify(chart, 'afterDatasetUpdate'),
        throwsA(isA<TypeError>()),
      );
    });

    test('a hook of another type has JS arity, with this the plugin', () {
      final calls = <Object?>[];
      final plugin = Plugin()..id = 'raw';
      // One parameter: not the type of the hook.
      plugin['afterInit'] = calls.add;
      plugin['myHook'] = JsFunction(
        (Object? self, Object? chart, Object? args) => calls.add(self),
      );
      final chart = _Chart(<String, Object?>{
        'plugins': [plugin],
      });
      final service = PluginService()..notify(chart, 'beforeInit');
      expect(plugin.afterInit, isNull);
      expect(service.notify(chart, 'afterInit'), isTrue);
      expect(service.notify(chart, 'myHook'), isTrue);
      expect(calls, [same(chart), same(plugin)]);
    });

    test('a user plugin gets the args object of the user for a hook', () {
      // core.plugin.tests.js:3-16: notifyPlugins gives each plugin the same
      // args object. A Map plugin and a hook of JS arity of a typed plugin
      // get the Map of the user for the built-in name beforeUpdate.
      final seen = <Object?>[];
      final map = <String, Object?>{
        'id': 'map',
        'beforeUpdate': JsFunction(
          (Object? self, Object? chart, Object? args) => seen.add(args),
        ),
      };
      final plugin = Plugin()..id = 'typed';
      plugin['beforeUpdate'] = JsFunction(
        (Object? self, Object? chart, Object? args) => seen.add(args),
      );
      final chart = _Chart(<String, Object?>{
        'plugins': [map, plugin],
      });
      final service = PluginService()..notify(chart, 'beforeInit');
      final args = <String, Object?>{'mode': 'user'};
      expect(service.notify(chart, 'beforeUpdate', args), isTrue);
      expect(seen, hasLength(2));
      expect(identical(seen[0], args), isTrue);
      expect(identical(seen[1], args), isTrue);
    });

    test('a custom hook name gets the args object of the user', () {
      final seen = <Object?>[];
      final map = <String, Object?>{
        'id': 'map',
        'myHook': JsFunction(
          (Object? self, Object? chart, Object? args) => seen.add(args),
        ),
      };
      final chart = _Chart(<String, Object?>{
        'plugins': [map],
      });
      final service = PluginService()..notify(chart, 'beforeInit');
      final args = <String, Object?>{'a': 1};
      expect(service.notify(chart, 'myHook', args), isTrue);
      expect(seen, hasLength(1));
      expect(identical(seen.single, args), isTrue);
    });

    test('a Map plugin reads map[hook] at each notify', () {
      final calls = <String>[];
      final map = <String, Object?>{'id': 'map'};
      final chart = _Chart(<String, Object?>{
        'plugins': [map],
      });
      final service = PluginService()..notify(chart, 'beforeInit');
      expect(service.notify(chart, 'beforeDraw'), isTrue);
      // A hook of three parameters, as a Map plugin of user code has.
      // ignore: avoid_types_on_closure_parameters
      map['beforeDraw'] = (Object? chart, Object? args, Object? options) {
        calls.add('beforeDraw ${jsGet(args, 'cancelable')}');
        return false;
      };
      expect(
        service.notify(
          chart,
          'beforeDraw',
          CancelableHookArgs(cancelable: true),
        ),
        isFalse,
      );
      expect(calls, ['beforeDraw true']);
    });
  });
}
