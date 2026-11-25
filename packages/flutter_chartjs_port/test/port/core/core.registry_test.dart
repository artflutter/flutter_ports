// Original code, not ported from Chart.js: Registry cases with no spec.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/color_json.dart';
import '../../support/plugin_defaults.dart';
import 'registry_observe.dart';
import 'registry_reference.dart' as frozen show registryReference;
import 'registry_reference.dart' hide registryReference;

// The 15 cases of core.registry.tests.js call Chart.register and read
// Chart.registry (core.controller, a later group). These tests cover the
// Registry of src/core/core.registry.js with the scenarios of
// tool/reference/registry_reference.mjs: the registry of each kind of item,
// the register callbacks, the getters, the namespace `elements` and the
// singleton. The expected lines come from the pinned sources in Node.js
// v24.22.1 on arm64.
//
// An item is a typed component or a plugin (Chart.js ADR 0204). The
// scenarios with no typed form have no test here: the base classes without
// an id, the List and Map items and the values that are not items (row
// adapt-typed-components).
//
// Each test makes a new Registry, except the test of the singleton, which
// unregisters its item, as core.registry.tests.js does (Chart.js ADR 0022,
// section 8). A rest argument list `reg.add(A, B)` is `reg.add([a, b])`.

/// The keys of the items of [items] in the `Object.keys` order.
List<String> _keys(Map<String, Object> items) => jsObjectKeys(items);

/// [reference] without the lines that start with one of [labels]: the
/// observations that have no typed form.
String _without(String reference, List<String> labels) => reference
    .split('\n')
    .where((line) => !labels.any((label) => line.startsWith('$label: ')))
    .join('\n');

/// A controller type with the id [id] and the defaults [defaults].
ControllerType _controller(String id, [Map<String, Object?>? defaults]) =>
    ControllerType(
      id: id,
      defaults: scopeFromMap(GenericDatasetOptionsScope(), defaults),
      create: DatasetController.new,
    );

/// A scale type with the id [id] and the defaults [defaults].
ScaleType _scale(String id, [Map<String, Object?>? defaults]) => ScaleType(
  id: id,
  defaults: scopeFromMap(ScaleOptionsScope(), defaults),
  create: Scale.new,
);

/// An element type with the id [id], the defaults [defaults], the parent
/// [parent] and the register hooks [hook].
ElementType _element(
  String id, {
  Map<String, Object?>? defaults,
  ElementType? parent,
  ComponentHook Function(String name)? hook,
}) => ElementType(
  id: id,
  defaults: scopeFromMap(GenericElementOptionsScope(), defaults),
  parent: parent,
  beforeRegister: hook?.call('beforeRegister'),
  afterRegister: hook?.call('afterRegister'),
  beforeUnregister: hook?.call('beforeUnregister'),
  afterUnregister: hook?.call('afterUnregister'),
  create: Element.new,
);

void main() {
  setUpSpecs();

  test('the reference comes from Node.js v24.22.1 on arm64', () {
    expect(registryReferenceNode, 'v24.22.1');
    expect(registryReferenceArch, 'arm64');
  });

  test('each kind of item goes to its registry', () {
    final o = Observations();
    final reg = Registry();
    // A subclass with no own defaults has the defaults of its base class:
    // an empty scope.
    final rCtl = _controller('rctl');
    final rScale = _scale('rscale');
    final rElem = _element('relem');
    // The plugin class `RPlug` and the plugin Map of upstream are native
    // plugins with their ids (Chart.js ADR 0144).
    final rPlug = Plugin<Object?>(id: 'rplug');
    final rMap = Plugin<Object?>(id: 'rmap');
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

  test('the register callbacks get the component', () {
    final o = Observations();
    final reg = Registry();
    final log = <String>[];
    // The hook gets the component as its parameter (Chart.js ADR 0173).
    ComponentHook hook(String name) =>
        (component) => log.add(
          '$name ${o.labelOf(component)}'
          ' ${has(reg.plugins.items, component.id)}'
          ' ${has(reg.elements.items, component.id)}',
        );

    // Upstream `RCbC` inherits the callbacks of `RCbP`. A component has its
    // own hooks. The plugin class `RCb`, its subclass `RCbSub` and the
    // plugin Map `rcbmap` have callbacks upstream; a native plugin
    // (Chart.js ADR 0144) has none: the lines of the plugins go.
    final rCbP = o.label(_element('rcbp', hook: hook), 'RCbP');
    final rCbC = o.label(_element('rcbc', parent: rCbP, hook: hook), 'RCbC');
    reg
      ..add([rCbC])
      ..remove([rCbC]);
    for (final line in log) {
      o.observe('log', line);
    }
    o
      ..observe('elements', o.json(_keys(reg.elements.items)))
      ..observe('plugins', o.json(_keys(reg.plugins.items)));
    reg.remove([rCbP]);
    expect(
      o.text,
      [
        for (final line in registryReference['registry callbacks']!.split('\n'))
          if (line.startsWith('plugins: '))
            'plugins: []'
          else if (!line.startsWith('log: ') || line.contains(' RCbC '))
            line,
      ].join('\n'),
    );
  });

  test('the getters, and the explicit registries', () {
    // An id is a String: `undefined` and `null` are their `ToPropertyKey`.
    final o = Observations();
    final reg = Registry();
    o
      ..observe('controller', error(() => reg.getController('nope')))
      ..observe('element', error(() => reg.getElement('undefined')))
      ..observe('plugin', error(() => reg.getPlugin<_RExtPlugin>()))
      ..observe('scale', error(() => reg.getScale('null')));
    final extDefaults = <String, Object?>{'prop': true};
    final rExtController = o.label(_controller('rext', extDefaults), 'RExt');
    final rExtElement = o.label(
      _element('rext', defaults: extDefaults),
      'RExt',
    );
    final rExtScale = o.label(_scale('rext', extDefaults), 'RExt');
    // The plugin of the class `RExt` is a native plugin (Chart.js ADR 0144)
    // with the same id and defaults.
    final rExtPlugin = o.label(_RExtPlugin(), 'RExt');
    reg.addControllers([rExtController]);
    o.observe('controller get', o.json(reg.getController('rext')));
    reg.removeControllers([rExtController]);
    o
      ..observe('controller after', error(() => reg.getController('rext')))
      ..observe('element get', o.json(_registerGet(reg, rExtElement)))
      ..observe('element after', error(() => reg.getElement('rext')));
    reg.addPlugins([rExtPlugin]);
    o.observe('plugin get', o.json(reg.getPlugin<_RExtPlugin>()));
    reg.removePlugins([rExtPlugin]);
    o.observe('plugin after', error(() => reg.getPlugin<_RExtPlugin>()));
    reg.addScales([rExtScale]);
    o.observe('scale get', o.json(reg.getScale('rext')));
    reg.removeScales([rExtScale]);
    o.observe('scale after', error(() => reg.getScale('rext')));
    // The plugin type is the key of getPlugin (row adapt-typed-plugins).
    expect(
      o.text,
      registryReference['registry getters']!
          .replaceFirst(
            '"5" is not a registered plugin.',
            '_RExtPlugin is not a registered plugin.',
          )
          .replaceFirst(
            '"rext" is not a registered plugin.',
            '_RExtPlugin is not a registered plugin.',
          ),
    );
  });

  test('the namespace elements registers in code unit order', () {
    // `Chart.register(registerables)` of upstream takes the namespaces. The
    // port takes their items (Chart.js ADR 0204): the namespace has no
    // List form, so the line `as a list` goes.
    final o = Observations();
    final reg = Registry();
    o.observe('keys', o.json(jsObjectKeys(elements)));
    reg.add(elements.values);
    o.observe('elements', o.json(_keys(reg.elements.items)));
    expect(
      o.text,
      _without(registryReference['registry elements namespace']!, [
        'as a list',
      ]),
    );
  });

  test('the singleton', () {
    final o = Observations();
    final plugin = _RSinglePlugin();
    o.observe(
      'is a Registry',
      '${isA<Registry>().matches(registry, <Object?, Object?>{})}',
    );
    registry.add([plugin]);
    addTearDown(() => registry.remove([plugin]));
    o.observe(
      'get',
      '${identical(registry.getPlugin<_RSinglePlugin>(), plugin)}',
    );
    registry.remove([plugin]);
    o.observe('after', error(() => registry.getPlugin<_RSinglePlugin>()));
    // The plugin type is the key of getPlugin (row adapt-typed-plugins).
    expect(
      o.text,
      registryReference['registry singleton']!.replaceFirst(
        '"rsingle" is not a registered plugin.',
        '_RSinglePlugin is not a registered plugin.',
      ),
    );
  });

  test('the four registries', () {
    final reg = Registry();
    expect(reg.controllers.scope, 'datasets');
    expect(reg.controllers.override, isTrue);
    expect(reg.elements.scope, 'elements');
    expect(reg.elements.override, isFalse);
    expect(reg.plugins.scope, 'plugins');
    expect(reg.plugins.override, isFalse);
    expect(reg.scales.scope, 'scales');
    expect(reg.scales.override, isFalse);
  });
}

/// Registers [element] in [reg] and gives `reg.getElement` of its id, then
/// removes it again.
ElementType _registerGet(Registry reg, ElementType element) {
  reg.addElements([element]);
  final result = reg.getElement(element.id);
  reg.removeElements([element]);
  return result;
}

final Map<String, String> registryReference = {
  for (final entry in frozen.registryReference.entries)
    entry.key: referenceColorTokens(entry.value),
};

/// The plugin of the class `RExt`: a native plugin (Chart.js ADR 0144) of its
/// own class, so `getPlugin<_RExtPlugin>()` finds it.
final class _RExtPlugin() extends Plugin<Object?> {
  /// The plugin `rext` with the defaults of `RExt`.
  this
    : super(
        id: 'rext',
        defaults: pluginDefaults(<String, Object?>{'prop': true}),
      );
}

/// The plugin of the singleton scenario.
final class _RSinglePlugin() extends Plugin<Object?> {
  /// The plugin `rsingle`.
  this : super(id: 'rsingle');
}
