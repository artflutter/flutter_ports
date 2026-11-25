// Original code, not ported from Chart.js: TypedRegistry cases with no spec.
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:test/test.dart';

import '../../support/color_json.dart';
import 'registry_observe.dart';
import 'registry_reference.dart' as frozen show registryReference;
import 'registry_reference.dart' hide registryReference;

// Upstream has no spec for src/core/core.typedRegistry.js (AGENTS.md rule
// 3). core.registry.tests.js reaches it only through Chart.register. These
// tests run the scenarios of tool/reference/registry_reference.mjs on a new
// TypedRegistry each: the parent that registers first, a duplicate `id`,
// the routes and descriptors, the key order of `items`, an empty id and
// `unregister`. The expected lines come from the pinned sources in Node.js
// v24.22.1 on arm64. The harness restores `defaults`, `overrides` and
// `descriptors` after each test (setUpSpecs).
//
// A class `X extends Y {}` of the generator is a typed component with the
// component of `Y` as its `parent` (Chart.js ADR 0204). The scenarios of a
// JS class semantic with no typed form have no test here: `isForType`, the
// statics that a subclass inherits, the routes that are not a Map of
// strings, the ids and items that are not components, and a parent without
// defaults (row adapt-typed-components).

/// A component of this pure test: the stand-in of a controller, with
/// `overrides`. `core.datasetController.dart` is not a pure layer.
final class _TComponent({
  required super.id,
  required super.defaults,

  /// `static overrides`.
  @override final ChartOptionsScope? overrides,
}) extends ChartComponent {
  /// A test component.
  this;

  /// A test component has no parent.
  @override
  _TComponent? get parent => null;
}

/// An element type with the id [id] and the defaults [defaults], a Map.
ElementType _element(
  String id,
  Map<String, Object?> defaults, {
  ElementType? parent,
  Map<String, String>? defaultRoutes,
  Map<String, Object?>? descriptors,
}) => ElementType(
  id: id,
  defaults: scopeFromMap(GenericElementOptionsScope(), defaults),
  parent: parent,
  defaultRoutes: defaultRoutes,
  descriptors: descriptors == null
      ? null
      : scopeFromMap(DescriptorsScope(), descriptors),
  create: Element.new,
);

/// The value of [id] in [registry]: [undefined] for Dart `null`.
Object? _get(TypedRegistry<IChartComponent> registry, String id) =>
    registry.get(id) ?? undefined;

/// [reference] without the lines that start with one of [labels]: the
/// observations that have no typed form.
String _without(String reference, List<String> labels) => reference
    .split('\n')
    .where((line) => !labels.any((label) => line.startsWith('$label: ')))
    .join('\n');

void main() {
  setUpSpecs();

  test('the reference comes from Node.js v24.22.1 on arm64', () {
    expect(registryReferenceNode, 'v24.22.1');
    expect(registryReferenceArch, 'arm64');
  });

  test('a parent with id and defaults registers first', () {
    final o = Observations();
    final reg = TypedRegistry<ElementType>('elements');
    final tParent = o.label(
      _element('tparent', {
        'a': 1.0,
        'nested': <String, Object?>{'b': 2.0},
      }),
      'TParent',
    );
    final tChild = o.label(
      _element('tchild', {
        'nested': <String, Object?>{'c': 3.0},
        'd': 4.0,
      }, parent: tParent),
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

  test('a duplicate id keeps the first component', () {
    final o = Observations();
    final reg = TypedRegistry<ElementType>('elements');
    final tDupA = o.label(_element('tdup', {'a': 1.0}), 'TDupA');
    final tDupB = o.label(_element('tdup', {'b': 2.0}), 'TDupB');
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
    final reg = TypedRegistry<ElementType>('elements');
    final tRouted = _element(
      'trouted',
      {'own': 1.0},
      defaultRoutes: {
        'backgroundColor': 'color',
        'sub.borderColor': 'elements.trouted.own',
      },
      descriptors: {
        '_scriptable': true,
        'sub': <String, Object?>{'_indexable': false},
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
    defaults['color'] = const ChartPaint.solid(ui.Color.fromRGBO(255, 0, 0, 1));
    scope['own'] = 7.0;
    o
      ..observe('backgroundColor after', o.json(scope['backgroundColor']))
      ..observe('sub.borderColor after', o.json(at(scope, 'sub.borderColor')));
    expect(o.text, registryReference['typedRegistry routes and descriptors']);
  });

  test('the current defaults of the scope keep their key order', () {
    final o = Observations();
    final reg = TypedRegistry<ElementType>('elements');
    defaults.set('elements.tpre', <String, Object?>{'z': 0.0, 'a': 9.0});
    final before = at(defaults, 'elements.tpre');
    reg.register(_element('tpre', {'a': 1.0, 'b': 2.0}));
    o
      ..observe('defaults.elements.tpre', o.json(at(defaults, 'elements.tpre')))
      ..observe(
        'same object',
        '${identical(at(defaults, 'elements.tpre'), before)}',
      );
    expect(o.text, registryReference['typedRegistry existing defaults']);
  });

  test('the keys of items are in the Object.keys order', () {
    // The id 10 of the generator is the string '10': an id is a String.
    final o = Observations();
    final reg = TypedRegistry<Plugin<Object?>>('tplugins');
    final plugins = [
      for (final id in ['zz', '7', 'a', '10']) Plugin<Object?>(id: id),
    ];
    for (var i = 0; i < plugins.length; i++) {
      o.label(plugins[i], 'p$i');
    }
    for (final plugin in plugins) {
      final id = plugin.id == '10' ? '10' : o.json(plugin.id);
      o.observe('register $id', reg.register(plugin));
    }
    o
      ..observe('items', o.json(jsObjectKeys(reg.items)))
      ..observe('defaults.tplugins', o.json(defaults['tplugins']))
      ..observe('get 10', o.json(_get(reg, '10')))
      ..observe('get "10"', o.json(_get(reg, '10')))
      ..observe('get 7', o.json(_get(reg, '7')))
      ..observe('get absent', o.json(_get(reg, 'absent')));
    expect(
      o.text,
      _without(registryReference['typedRegistry key order']!, [
        'get undefined',
      ]),
    );
  });

  test('register throws for an empty id', () {
    // core.typedRegistry.js:37-39: an id that is falsy throws.
    final reg = TypedRegistry<ElementType>('elements');
    expect(
      () => reg.register(_element('', {})),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          startsWith('class does not have id: '),
        ),
      ),
    );
    expect(reg.items, isEmpty);
  });

  /// The lines of `unregister` in the port. The scope `defaults.tarr` is a
  /// List: upstream gives `ok`, and the port throws a [TypeError] (group
  /// `adapt-defaults-scope-object`).
  String unregisterLines() {
    final o = Observations();
    final reg = TypedRegistry<_TComponent>('tunreg', true);
    _TComponent component(String id) =>
        _TComponent(id: id, defaults: GenericDatasetOptionsScope());
    final tU = _TComponent(
      id: 'tu',
      defaults: scopeFromMap(GenericDatasetOptionsScope(), {'a': 1.0}),
      overrides: scopeFromMap(ChartOptionsScope(), {'o': 1.0}),
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
        error(() => reg.unregister(component('other'))),
      )
      ..observe(
        'missing scope',
        error(
          () =>
              TypedRegistry<_TComponent>('tmissing').unregister(component('x')),
        ),
      )
      ..observe(
        'empty scope',
        error(() => TypedRegistry<_TComponent>('').unregister(component('x'))),
      );
    defaults['tprim'] = 5.0;
    o.observe(
      'number scope',
      error(
        () => TypedRegistry<_TComponent>('tprim').unregister(component('x')),
      ),
    );
    defaults['tarr'] = <Object?>[];
    o.observe(
      'list scope',
      error(
        () => TypedRegistry<_TComponent>('tarr').unregister(component('x')),
      ),
    );
    return o.text;
  }

  /// The reference lines of `unregister` that have a typed form: an item
  /// is a component, never `null` or `undefined`.
  String unregisterReference() => _without(
    registryReference['typedRegistry unregister']!,
    ['null', 'undefined'],
  );

  test('unregister removes the item, its defaults and its overrides', () {
    // The last line is the hunk of the group adapt-defaults-scope-object.
    expect(
      unregisterLines(),
      unregisterReference().replaceFirst(
        'list scope: ok',
        'list scope: TypeError',
      ),
    );
  });

  test('a plugin with defaults, routes and descriptors', () {
    final o = Observations();
    final reg = TypedRegistry<Plugin<Object?>>('tplugins2');
    final plugin = Plugin<Object?>(
      id: 'tmap',
      defaults: scopeFromMap(GenericElementOptionsScope(), {'x': 1.0}),
      defaultRoutes: const {'y': 'color'},
      descriptors: scopeFromMap(DescriptorsScope(), {'_scriptable': false}),
    );
    o
      ..observe('scope', reg.register(plugin))
      ..observe('keys', o.json(jsObjectKeys(at(defaults, 'tplugins2.tmap'))))
      ..observe(
        'defaults.tplugins2.tmap',
        o.json(at(defaults, 'tplugins2.tmap')),
      )
      ..observe('descriptors.tplugins2', o.json(descriptors['tplugins2']));
    expect(o.text, registryReference['typedRegistry plugin map']);
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
        () => TypedRegistry<_TComponent>('tarr2').unregister(
          _TComponent(id: 'x', defaults: GenericDatasetOptionsScope()),
        ),
        throwsA(isA<TypeError>()),
      );
    });
  });
}

final Map<String, String> registryReference = {
  for (final entry in frozen.registryReference.entries)
    entry.key: referenceColorTokens(entry.value),
};
