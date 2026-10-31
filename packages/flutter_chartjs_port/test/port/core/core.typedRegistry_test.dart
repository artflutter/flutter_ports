// Original code, not ported from Chart.js: TypedRegistry cases with no spec.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.typedRegistry.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart' show JsFunction;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:test/test.dart';

import 'registry_observe.dart';
import 'registry_reference.dart';

// Upstream has no spec for src/core/core.typedRegistry.js (AGENTS.md rule
// 3). core.registry.tests.js reaches it only through Chart.register. These
// tests run the scenarios of tool/reference/registry_reference.mjs on a new
// TypedRegistry each (Chart.js ADR 0020, section 12): the strict
// `isForType`, the parent that registers first, the statics that a subclass
// inherits, a duplicate `id`, the routes and descriptors, the key order of
// `items`, the errors and `unregister`. The expected lines come from the
// pinned sources in Node.js v24.22.1 on arm64. The harness restores
// `defaults`, `overrides` and `descriptors` after each test (setUpSpecs).
//
// A class `X extends Y {}` of the generator is a class value with the class
// value of `Y` as its superclass. Its static properties are writes through
// `operator []=`, as the generator writes them after the class (Chart.js
// ADR 0020, section 8).

/// The stand-in base class of the controllers in this pure test: a class
/// value with the static `defaults` and no `id`, as DatasetController
/// (core.datasetController.js:239-249). `core.datasetController.dart` is not
/// a pure layer.
final JsClass _tBase = JsClass(
  'TBase',
  statics: {'defaults': <String, Object?>{}},
);

/// The class value `class <name> extends <superclass> {}` with the static
/// properties [statics], written after the class in their order.
JsClass _class(
  String name, {
  JsClass? superclass,
  Map<String, Object?> statics = const {},
}) {
  final value = JsClass(name, superclass: superclass);
  statics.forEach((key, v) => value[key] = v);
  return value;
}

/// The value of [id] in [registry]: [undefined] for Dart `null`.
Object? _get(TypedRegistry registry, Object? id) =>
    registry.get(id) ?? undefined;

void main() {
  setUpSpecs();

  test('the reference comes from Node.js v24.22.1 on arm64', () {
    expect(registryReferenceNode, 'v24.22.1');
    expect(registryReferenceArch, 'arm64');
  });

  test('isForType is strict and has the Object root', () {
    final o = Observations();
    final elements = TypedRegistry(Element.jsClass, 'telements');
    final controllers = TypedRegistry(_tBase, 'tdatasets', true);
    final plugins = TypedRegistry(jsObjectClass, 'tplugins');
    final tPointSub = _class('TPointSub', superclass: PointElement.jsClass);
    final tPlain = _class('TPlain');
    final tSub = _class('TSub', superclass: _tBase);
    final values = <(String, Object?)>[
      ('Element', Element.jsClass),
      ('PointElement', PointElement.jsClass),
      ('TPointSub', tPointSub),
      ('TPlain', tPlain),
      ('TBase', _tBase),
      ('TSub', tSub),
      ('Object', jsObjectClass),
      ('map', <String, Object?>{'id': 'x'}),
      ('string', 'str'),
      ('number', 5.0),
      ('boolean', true),
      ('arrow', () => 1.0),
      ('null', null),
      ('undefined', undefined),
    ];
    for (final (name, value) in values) {
      final results = [elements, controllers, plugins].map((reg) {
        var result = '';
        final e = error(() => result = '${reg.isForType(value)}');
        return e == 'ok' ? result : e;
      });
      o.observe(name, results.join(' '));
    }
    expect(o.text, registryReference['typedRegistry isForType']);
  });

  test('a parent with id and defaults registers first', () {
    final o = Observations();
    final reg = TypedRegistry(Element.jsClass, 'elements');
    final tParent = o.label(
      _class(
        'TParent',
        superclass: Element.jsClass,
        statics: {
          'id': 'tparent',
          'defaults': <String, Object?>{
            'a': 1.0,
            'nested': <String, Object?>{'b': 2.0},
          },
        },
      ),
      'TParent',
    );
    final tChild = o.label(
      _class(
        'TChild',
        superclass: tParent,
        statics: {
          'id': 'tchild',
          'defaults': <String, Object?>{
            'nested': <String, Object?>{'c': 3.0},
            'd': 4.0,
          },
        },
      ),
      'TChild',
    );
    o
      ..observe('scope', reg.register(tChild))
      ..observe('items', o.json(jsObjectKeys(reg.items)))
      ..observe('tparent', o.json(_get(reg, 'tparent')))
      ..observe('tchild', o.json(_get(reg, 'tchild')))
      ..observe(
        'defaults.elements.tparent',
        o.json(at(defaults, 'elements.tparent')),
      )
      ..observe(
        'defaults.elements.tchild',
        o.json(at(defaults, 'elements.tchild')),
      )
      ..observe('again', reg.register(tChild))
      ..observe('parent again', reg.register(tParent))
      ..observe('items after', o.json(jsObjectKeys(reg.items)));
    expect(o.text, registryReference['typedRegistry parent first']);
  });

  test('a subclass reads the statics of its superclass', () {
    final o = Observations();
    final reg = TypedRegistry(_tBase, 'tdatasets', true);
    final tCtl = o.label(
      _class(
        'TCtl',
        superclass: _tBase,
        statics: {
          'id': 'tctl',
          'defaults': <String, Object?>{
            'x': 1.0,
            'sub': <String, Object?>{'y': 2.0},
          },
          'overrides': <String, Object?>{'o': 1.0},
          'descriptors': <String, Object?>{
            '_scriptable': false,
            'sub': <String, Object?>{'_indexable': false},
          },
        },
      ),
      'TCtl',
    );
    final tPie = o.label(
      _class('TPie', superclass: tCtl, statics: {'id': 'tpie'}),
      'TPie',
    );
    o
      ..observe('scope', reg.register(tPie))
      ..observe('items', o.json(jsObjectKeys(reg.items)))
      ..observe('defaults.tdatasets', o.json(defaults['tdatasets']))
      ..observe('overrides.tctl', o.json(overrides['tctl']))
      ..observe('overrides.tpie', o.json(overrides['tpie']))
      ..observe('descriptors.tdatasets', o.json(descriptors['tdatasets']))
      ..observe(
        'overrides.tpie is TCtl.overrides',
        '${identical(overrides['tpie'], tCtl['overrides'])}',
      );
    expect(o.text, registryReference['typedRegistry inherited statics']);
  });

  test('a duplicate id keeps the first class value', () {
    final o = Observations();
    final reg = TypedRegistry(Element.jsClass, 'elements');
    final tDupA = o.label(
      _class(
        'TDupA',
        superclass: Element.jsClass,
        statics: {
          'id': 'tdup',
          'defaults': <String, Object?>{'a': 1.0},
        },
      ),
      'TDupA',
    );
    final tDupB = o.label(
      _class(
        'TDupB',
        superclass: Element.jsClass,
        statics: {
          'id': 'tdup',
          'defaults': <String, Object?>{'b': 2.0},
        },
      ),
      'TDupB',
    );
    o
      ..observe('first', reg.register(tDupA))
      ..observe('second', reg.register(tDupB))
      ..observe('get', o.json(_get(reg, 'tdup')))
      ..observe(
        'defaults.elements.tdup',
        o.json(at(defaults, 'elements.tdup')),
      );
    expect(o.text, registryReference['typedRegistry duplicate id']);
  });

  test('the routes and the descriptors of a component', () {
    final o = Observations();
    final reg = TypedRegistry(Element.jsClass, 'elements');
    final tRouted = _class(
      'TRouted',
      superclass: Element.jsClass,
      statics: {
        'id': 'trouted',
        'defaults': <String, Object?>{'own': 1.0},
        'defaultRoutes': <String, Object?>{
          'backgroundColor': 'color',
          'sub.borderColor': 'elements.trouted.own',
        },
        'descriptors': <String, Object?>{
          '_scriptable': true,
          'sub': <String, Object?>{'_indexable': false},
        },
      },
    );
    reg.register(tRouted);
    final scope = at(defaults, 'elements.trouted')! as JsObjectFace;
    o
      ..observe('keys', o.json(jsObjectKeys(scope)))
      ..observe('defaults.elements.trouted', o.json(scope))
      ..observe('backgroundColor', o.json(scope['backgroundColor']))
      ..observe('sub.borderColor', o.json(at(scope, 'sub.borderColor')))
      ..observe(
        'descriptors.elements.trouted',
        o.json(at(descriptors, 'elements.trouted')),
      );
    defaults['color'] = 'red';
    scope['own'] = 7.0;
    o
      ..observe('backgroundColor after', o.json(scope['backgroundColor']))
      ..observe('sub.borderColor after', o.json(at(scope, 'sub.borderColor')));
    expect(o.text, registryReference['typedRegistry routes and descriptors']);
  });

  test('the routes of a List, a string, a number and a number target', () {
    final o = Observations();
    final reg = TypedRegistry(Element.jsClass, 'elements');
    for (final (name, routes) in <(String, Object?)>[
      ('list', ['color']),
      ('string', 'ab'),
      ('number', 5.0),
      ('not a string', <String, Object?>{'backgroundColor': 5.0}),
    ]) {
      final tr = _class(
        'TR',
        superclass: Element.jsClass,
        statics: {
          'id': 'troutes-$name',
          'defaults': <String, Object?>{},
          'defaultRoutes': routes,
        },
      );
      o
        ..observe(name, error(() => reg.register(tr)))
        ..observe(
          '$name keys',
          o.json(
            jsObjectKeys(
              jsGet(defaults['elements'], 'troutes-$name'),
            ),
          ),
        );
    }
    expect(o.text, registryReference['typedRegistry routes of other values']);
  });

  test('the current defaults of the scope keep their key order', () {
    final o = Observations();
    final reg = TypedRegistry(Element.jsClass, 'elements');
    defaults.set('elements.tpre', <String, Object?>{'z': 0.0, 'a': 9.0});
    final before = at(defaults, 'elements.tpre');
    final tPre = _class(
      'TPre',
      superclass: Element.jsClass,
      statics: {
        'id': 'tpre',
        'defaults': <String, Object?>{'a': 1.0, 'b': 2.0},
      },
    );
    reg.register(tPre);
    o
      ..observe('defaults.elements.tpre', o.json(at(defaults, 'elements.tpre')))
      ..observe(
        'same object',
        '${identical(at(defaults, 'elements.tpre'), before)}',
      );
    expect(o.text, registryReference['typedRegistry existing defaults']);
  });

  test('the keys of items are in the Object.keys order', () {
    final o = Observations();
    final reg = TypedRegistry(jsObjectClass, 'tplugins');
    final plugins = <Map<String, Object?>>[
      {'id': 'zz'},
      {'id': '7'},
      {'id': 'a'},
      {'id': 10.0},
    ];
    for (var i = 0; i < plugins.length; i++) {
      o.label(plugins[i], 'p$i');
    }
    for (final plugin in plugins) {
      o.observe('register ${o.json(plugin['id'])}', reg.register(plugin));
    }
    o
      ..observe('items', o.json(jsObjectKeys(reg.items)))
      ..observe('defaults.tplugins', o.json(defaults['tplugins']))
      ..observe('get 10', o.json(_get(reg, 10.0)))
      ..observe('get "10"', o.json(_get(reg, '10')))
      ..observe('get 7', o.json(_get(reg, 7.0)))
      ..observe('get absent', o.json(_get(reg, 'absent')))
      ..observe('get undefined', o.json(_get(reg, undefined)));
    expect(o.text, registryReference['typedRegistry key order']);
  });

  test('register throws for null, undefined and a falsy id', () {
    final o = Observations();
    final reg = TypedRegistry(jsObjectClass, 'tplugins');
    for (final (name, value) in <(String, Object?)>[
      ('null', null),
      ('undefined', undefined),
      ('number', 5.0),
      ('string', 'str'),
      ('empty map', <String, Object?>{}),
      ('empty id', <String, Object?>{'id': ''}),
      ('zero id', <String, Object?>{'id': 0.0}),
      ('class without id', JsClass('NoId')),
      (
        'list',
        [
          <String, Object?>{'id': 'x'},
        ],
      ),
    ]) {
      o.observe(name, error(() => reg.register(value)));
    }
    o.observe('items', o.json(jsObjectKeys(reg.items)));
    expect(o.text, registryReference['typedRegistry register errors']);
  });

  /// The lines of `unregister` in the port. The scope `defaults.tarr` is a
  /// List: upstream gives `ok`, and the port throws a [TypeError] (group
  /// `adapt-defaults-scope-object`).
  String unregisterLines() {
    final o = Observations();
    final reg = TypedRegistry(_tBase, 'tunreg', true);
    final tU = _class(
      'TU',
      superclass: _tBase,
      statics: {
        'id': 'tu',
        'defaults': <String, Object?>{'a': 1.0},
        'overrides': <String, Object?>{'o': 1.0},
      },
    );
    reg.register(tU);
    o
      ..observe('items before', o.json(jsObjectKeys(reg.items)))
      ..observe('defaults before', has(defaults['tunreg'], 'tu'))
      ..observe('overrides before', has(overrides, 'tu'))
      ..observe('unregister', error(() => reg.unregister(tU)))
      ..observe('items after', o.json(jsObjectKeys(reg.items)))
      ..observe('defaults after', has(defaults['tunreg'], 'tu'))
      ..observe('overrides after', has(overrides, 'tu'))
      ..observe('again', error(() => reg.unregister(tU)))
      ..observe(
        'not registered',
        error(() => reg.unregister(<String, Object?>{'id': 'other'})),
      )
      ..observe('null', error(() => reg.unregister(null)))
      ..observe('undefined', error(() => reg.unregister(undefined)))
      ..observe(
        'missing scope',
        error(
          () => TypedRegistry(
            _tBase,
            'tmissing',
          ).unregister(<String, Object?>{'id': 'x'}),
        ),
      )
      ..observe(
        'empty scope',
        error(
          () => TypedRegistry(_tBase, '').unregister(<String, Object?>{
            'id': 'x',
          }),
        ),
      );
    defaults['tprim'] = 5.0;
    o.observe(
      'number scope',
      error(
        () => TypedRegistry(
          _tBase,
          'tprim',
        ).unregister(<String, Object?>{'id': 'x'}),
      ),
    );
    defaults['tarr'] = <Object?>[];
    o.observe(
      'list scope',
      error(
        () => TypedRegistry(
          _tBase,
          'tarr',
        ).unregister(<String, Object?>{'id': 'x'}),
      ),
    );
    return o.text;
  }

  test('unregister removes the item, its defaults and its overrides', () {
    // The last line is the hunk of the group adapt-defaults-scope-object.
    expect(
      unregisterLines(),
      registryReference['typedRegistry unregister']!.replaceFirst(
        'list scope: ok',
        'list scope: TypeError',
      ),
    );
  });

  test('a plugin Map with defaults, routes and descriptors', () {
    final o = Observations();
    final reg = TypedRegistry(jsObjectClass, 'tplugins2');
    final plugin = <String, Object?>{
      'id': 'tmap',
      'defaults': <String, Object?>{'x': 1.0},
      'defaultRoutes': <String, Object?>{'y': 'color'},
      'descriptors': <String, Object?>{'_scriptable': false},
    };
    o
      ..observe('scope', reg.register(plugin))
      ..observe(
        'keys',
        o.json(
          jsObjectKeys(at(defaults, 'tplugins2.tmap')),
        ),
      )
      ..observe(
        'defaults.tplugins2.tmap',
        o.json(at(defaults, 'tplugins2.tmap')),
      )
      ..observe('descriptors.tplugins2', o.json(descriptors['tplugins2']));
    expect(o.text, registryReference['typedRegistry plugin map']);
  });

  test('a parent without defaults is not a component', () {
    final o = Observations();
    final reg = TypedRegistry(jsObjectClass, 'tplugins3');
    final tNoDef = _class('TNoDef', statics: {'id': 'tnodef'});
    final tKid = _class('TKid', superclass: tNoDef, statics: {'id': 'tkid'});
    o
      ..observe('scope', reg.register(tKid))
      ..observe('items', o.json(jsObjectKeys(reg.items)));
    expect(o.text, registryReference['typedRegistry parent without defaults']);
  });

  group('adapt-defaults-scope-object', () {
    test('unregister needs a Map at defaults[scope]', () {
      // Upstream tests `id in defaults[scope]` on any object
      // (core.typedRegistry.js:75): a List scope gives no throw. The port
      // needs a Map there, as for each defaults scope.
      expect(
        registryReference['typedRegistry unregister'],
        endsWith('list scope: ok'),
      );
      expect(unregisterLines(), endsWith('list scope: TypeError'));
      defaults['tarr2'] = <Object?>[];
      expect(
        () => TypedRegistry(_tBase, 'tarr2').unregister(<String, Object?>{}),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('js-semantics-function-source', () {
    // core.typedRegistry.js:38 throws `'class does not have id: ' + item`.
    // JavaScript prints the source of a function, for example `() => 1`.
    // jsToString of a Dart closure, a JsFunction or another Dart object is
    // its Dart toString(), whose text differs between the VM and the web
    // compilers. The throw is the same.
    final plugins = TypedRegistry(jsObjectClass, 'tfunctions');

    for (final (name, item) in <(String, Object)>[
      ('a closure', () => 1),
      ('a JsFunction', JsFunction((Object? self) => self)),
      ('a Dart object', PointElement()),
    ]) {
      test('$name gives the Dart text in the register error', () {
        expect(
          () => plugins.register(item),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              allOf(
                startsWith('class does not have id: '),
                isNot('class does not have id: () => 1'),
                isNot('class does not have id: [object Object]'),
                endsWith(item.toString()),
              ),
            ),
          ),
        );
      });
    }
  });
}
