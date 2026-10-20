// Original code, not ported from Chart.js: Registry cases with no spec.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/core/core.datasetController.dart';
import 'package:flutter_chartjs/src/core/core.defaults.dart';
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/core/core.registry.dart';
import 'package:flutter_chartjs/src/core/core.scale.dart';
import 'package:flutter_chartjs/src/elements/element.arc.dart';
import 'package:flutter_chartjs/src/elements/element.bar.dart';
import 'package:flutter_chartjs/src/elements/element.line.dart';
import 'package:flutter_chartjs/src/elements/element.point.dart';
import 'package:flutter_chartjs/src/js/js_array.dart';
import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_function.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_test/flutter_test.dart';

import 'registry_observe.dart';
import 'registry_reference.dart';

// The 15 cases of core.registry.tests.js call Chart.register and read
// Chart.registry (core.controller, a later group). These tests cover the
// Registry of src/core/core.registry.js with the scenarios of
// tool/reference/registry_reference.mjs (Chart.js ADR 0020, section 12):
// the registry of each kind of item, the base classes, the List and Map
// items, the values that are not items, the register callbacks and their
// `this`, the getters, the namespace `elements` and the singleton. The
// expected lines come from the pinned sources in Node.js v24.12.0 on x64.
//
// Each test makes a new Registry, except the test of the singleton, which
// unregisters its item, as core.registry.tests.js does (Chart.js ADR 0022,
// section 8). A rest argument list `reg.add(A, B)` is `reg.add([a, b])`
// (Chart.js ADR 0020, section 6).

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

/// The keys of the items of [registry] in the `Object.keys` order.
List<String> _keys(Map<String, Object> items) => jsObjectKeys(items);

void main() {
  setUpSpecs();

  test('the reference comes from Node.js v24.12.0 on x64', () {
    expect(registryReferenceNode, 'v24.12.0');
    expect(registryReferenceArch, 'x64');
  });

  test('each kind of item goes to its registry', () {
    final o = Observations();
    final reg = Registry();
    final rCtl = _class(
      'RCtl',
      superclass: DatasetController.jsClass,
      statics: {'id': 'rctl'},
    );
    final rScale = _class(
      'RScale',
      superclass: Scale.jsClass,
      statics: {'id': 'rscale'},
    );
    final rElem = _class(
      'RElem',
      superclass: Element.jsClass,
      statics: {'id': 'relem'},
    );
    final rPlug = _class('RPlug', statics: {'id': 'rplug'});
    final rMap = <String, Object?>{'id': 'rmap'};
    reg.add([rCtl, rScale, rElem, rPlug, rMap]);
    o
      ..observe('controllers', o.json(_keys(reg.controllers.items)))
      ..observe('scales', o.json(_keys(reg.scales.items)))
      ..observe('elements', o.json(_keys(reg.elements.items)))
      ..observe('plugins', o.json(_keys(reg.plugins.items)))
      ..observe('overrides.rctl', o.json(overrides['rctl']))
      ..observe('defaults.datasets.rctl', o.json(at(defaults, 'datasets.rctl')))
      ..observe(
        'defaults.scales.rscale',
        o.json(at(defaults, 'scales.rscale')),
      );
    reg.remove([rCtl, rScale, rElem, rPlug, rMap]);
    o
      ..observe('controllers after', o.json(_keys(reg.controllers.items)))
      ..observe('plugins after', o.json(_keys(reg.plugins.items)))
      ..observe('overrides.rctl after', has(overrides, 'rctl'));
    expect(o.text, registryReference['registry routing']);
  });

  test('the base classes have no id', () {
    // The message has the source text of the class upstream. Only its start
    // is the same (differences.md js-semantics-class-source).
    final o = Observations();
    final reg = Registry();
    for (final (name, value) in [
      ('DatasetController', DatasetController.jsClass),
      ('Scale', Scale.jsClass),
      ('Element', Element.jsClass),
    ]) {
      final result = error(() => reg.add([value]));
      final start = 'Error: class does not have id: class $name';
      o.observe(name, result.startsWith(start) ? start : result);
    }
    o.observe('plugins', o.json(_keys(reg.plugins.items)));
    expect(o.text, registryReference['registry base classes']);
  });

  test('a List and a Map of items, and a Map with an id', () {
    final o = Observations();
    final reg = Registry();
    final ra = o.label(<String, Object?>{'id': 'ra'}, 'ra');
    final rb = o.label(<String, Object?>{'id': 'rb'}, 'rb');
    final rc = o.label(<String, Object?>{'id': 'rc'}, 'rc');
    final rd = o.label(<String, Object?>{'id': 'rd'}, 'rd');
    final re = o.label(<String, Object?>{'id': 're'}, 're');
    reg.add([
      [ra, rb],
      <String, Object?>{'k2': rc, '10': rd, 'k1': re},
    ]);
    o.observe('plugins', o.json(_keys(reg.plugins.items)));
    final withId = o.label(<String, Object?>{
      'id': 'rwithid',
      'k': o.label(<String, Object?>{'id': 'rf'}, 'rf'),
    }, 'rwithid');
    reg.add([withId]);
    o.observe('with id', o.json(_keys(reg.plugins.items)));
    final rCtl2 = _class(
      'RCtl2',
      superclass: DatasetController.jsClass,
      statics: {'id': 'rctl2'},
    );
    final rplug2 = o.label(<String, Object?>{'id': 'rplug2'}, 'rplug2');
    reg.add([
      <String, Object?>{'a': rCtl2, 'b': rplug2},
    ]);
    o
      ..observe('mixed controllers', o.json(_keys(reg.controllers.items)))
      ..observe('mixed plugins', o.json(_keys(reg.plugins.items)));
    reg.remove([
      [ra, rb],
      <String, Object?>{'k2': rc, '10': rd, 'k1': re},
      withId,
      <String, Object?>{'a': rCtl2, 'b': rplug2},
    ]);
    o
      ..observe('controllers after', o.json(_keys(reg.controllers.items)))
      ..observe('plugins after', o.json(_keys(reg.plugins.items)));
    expect(o.text, registryReference['registry loopables']);
  });

  test('values that are not items', () {
    final o = Observations();
    final reg = Registry();
    for (final (name, value) in <(String, Object?)>[
      ('number', 5.0),
      ('string', 'ab'),
      ('boolean', true),
      ('empty map', <String, Object?>{}),
      ('arrow', () => 1.0),
      ('null', null),
      ('undefined', undefined),
      ('map of a string', <String, Object?>{'foo': 'bar'}),
      ('map of a number', <String, Object?>{'n': 5.0}),
      ('list of null', <Object?>[null]),
      (
        'nested list',
        [
          [
            <String, Object?>{'id': 'rn1'},
          ],
        ],
      ),
      (
        'list',
        [
          <String, Object?>{'id': 'rn2'},
        ],
      ),
    ]) {
      o.observe(name, error(() => reg.add([value])));
    }
    o
      ..observe('plugins', o.json(_keys(reg.plugins.items)))
      ..observe('remove null', error(() => reg.remove([null])))
      ..observe(
        'remove map',
        error(
          () => reg.remove([
            <String, Object?>{'id': 'rnone'},
          ]),
        ),
      );
    expect(o.text, registryReference['registry items of other values']);
  });

  test('the register callbacks get the component as this', () {
    final o = Observations();
    final reg = Registry();
    final log = <String>[];
    void callbacks(Object target) {
      for (final name in const [
        'beforeRegister',
        'afterRegister',
        'beforeUnregister',
        'afterUnregister',
      ]) {
        final callback = JsFunction((Object? self) {
          final id = jsGet(self, 'id');
          log.add(
            '$name ${o.labelOf(self)} ${has(reg.plugins.items, id)}'
            ' ${has(reg.elements.items, id)}',
          );
        });
        switch (target) {
          case final JsClass value:
            value[name] = callback;
          case final Map<String, Object?> map:
            map[name] = callback;
        }
      }
    }

    final rCb = o.label(_class('RCb', statics: {'id': 'rcb'}), 'RCb');
    callbacks(rCb);
    final rCbSub = o.label(
      _class('RCbSub', superclass: rCb, statics: {'id': 'rcbsub'}),
      'RCbSub',
    );
    final map = o.label(<String, Object?>{'id': 'rcbmap'}, 'rcbmap');
    callbacks(map);
    final rCbP = o.label(
      _class('RCbP', superclass: Element.jsClass, statics: {'id': 'rcbp'}),
      'RCbP',
    );
    callbacks(rCbP);
    final rCbC = o.label(
      _class('RCbC', superclass: rCbP, statics: {'id': 'rcbc'}),
      'RCbC',
    );
    reg
      ..add([rCbSub, rCb, map, rCbC])
      ..remove([rCbSub, map, rCbC]);
    for (final line in log) {
      o.observe('log', line);
    }
    o
      ..observe('elements', o.json(_keys(reg.elements.items)))
      ..observe('plugins', o.json(_keys(reg.plugins.items)));
    reg.remove([rCb, rCbP]);
    expect(o.text, registryReference['registry callbacks']);
  });

  test('the getters, and the explicit registries', () {
    final o = Observations();
    final reg = Registry();
    o
      ..observe('controller', error(() => reg.getController('nope')))
      ..observe('element', error(() => reg.getElement(undefined)))
      ..observe('plugin', error(() => reg.getPlugin(5.0)))
      ..observe('scale', error(() => reg.getScale(null)));
    final rExt = o.label(
      _class(
        'RExt',
        statics: {
          'id': 'rext',
          'defaults': <String, Object?>{'prop': true},
        },
      ),
      'RExt',
    );
    for (final (name, add, get, remove) in [
      (
        'controller',
        reg.addControllers,
        reg.getController,
        reg.removeControllers,
      ),
      ('element', reg.addElements, reg.getElement, reg.removeElements),
      ('plugin', reg.addPlugins, reg.getPlugin, reg.removePlugins),
      ('scale', reg.addScales, reg.getScale, reg.removeScales),
    ]) {
      add([rExt]);
      o.observe('$name get', o.json(get('rext')));
      remove([rExt]);
      o.observe('$name after', error(() => get('rext')));
    }
    expect(o.text, registryReference['registry getters']);
  });

  /// The namespace `elements` of the bundle: a Map with the export names in
  /// code unit order (Chart.js ADR 0020, section 6).
  Map<String, Object?> elementsNamespace() => Map.unmodifiable({
    'ArcElement': ArcElement.jsClass,
    'BarElement': BarElement.jsClass,
    'LineElement': LineElement.jsClass,
    'PointElement': PointElement.jsClass,
  });

  /// The lines of the namespace scenario in the port.
  String namespaceLines() {
    final o = Observations();
    final reg = Registry();
    final elements = elementsNamespace();
    final empty = Map<String, Object?>.unmodifiable(<String, Object?>{});
    o.observe('keys', o.json(jsObjectKeys(elements)));
    reg.add([empty, empty, elements, empty]);
    o
      ..observe('elements', o.json(_keys(reg.elements.items)))
      ..observe(
        'as a list',
        error(
          () => reg.add([
            [empty, empty, elements, empty],
          ]),
        ),
      );
    return o.text;
  }

  test('the namespace elements registers in code unit order', () {
    // `Chart.register(registerables)` of upstream is
    // `Chart.register([registerables])`. The namespace objects of the
    // bundle have a null prototype: `'id' in null` throws a TypeError.
    // Here a namespace is a Map, so `register` throws its StateError. Both
    // throw at the first namespace, before a write (Chart.js ADR 0020,
    // section 6).
    expect(
      namespaceLines(),
      registryReference['registry elements namespace']!.replaceFirst(
        'as a list: TypeError',
        'as a list: Error: class does not have id: [object Object]',
      ),
    );
  });

  test('the singleton', () {
    final o = Observations();
    final plugin = <String, Object?>{'id': 'rsingle'};
    o.observe(
      'is a Registry',
      '${isA<Registry>().matches(registry, <Object?, Object?>{})}',
    );
    registry.add([plugin]);
    addTearDown(() => registry.remove([plugin]));
    o.observe('get', '${identical(registry.getPlugin('rsingle'), plugin)}');
    registry.remove([plugin]);
    o.observe('after', error(() => registry.getPlugin('rsingle')));
    expect(o.text, registryReference['registry singleton']);
  });

  test('the four registries of the base class values', () {
    final reg = Registry();
    expect(reg.controllers.type, same(DatasetController.jsClass));
    expect(reg.controllers.scope, 'datasets');
    expect(reg.controllers.override, isTrue);
    expect(reg.elements.type, same(Element.jsClass));
    expect(reg.elements.scope, 'elements');
    expect(reg.elements.override, isFalse);
    expect(reg.plugins.type, same(jsObjectClass));
    expect(reg.plugins.scope, 'plugins');
    expect(reg.scales.type, same(Scale.jsClass));
    expect(reg.scales.scope, 'scales');
    // The statics that the registry reads from the base classes
    // (core.datasetController.js:239-249, core.element.ts:8-9).
    expect(DatasetController.jsClass.has('id'), isFalse);
    expect(
      DatasetController.jsClass['defaults'],
      same(DatasetController.defaults),
    );
    expect(Scale.jsClass.superclass, same(Element.jsClass));
    expect(Scale.jsClass.has('id'), isFalse);
    expect(Scale.jsClass['defaults'], same(Element.defaults));
    expect(Element.jsClass['defaultRoutes'], same(undefined));
  });
}
