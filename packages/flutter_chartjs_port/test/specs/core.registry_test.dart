// Ported from Chart.js v4.6.1 test/specs/core.registry.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

// The spec registers classes of flutter_chartjs_port, which does not export
// lib/src yet.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/plugin_defaults.dart';

// The registry spec has no chart: each case calls `Chart.register`,
// `Chart.unregister` and the registry of `Chart.registry`. It runs on the
// VM, because core.controller.dart reaches the platform layer (Chart.js ADR
// 0020, section 10).
//
// A class `class X extends Chart.DatasetController {}` of the spec is a
// typed component: a `ControllerType`, a `ScaleType` or an `ElementType`
// (Chart.js ADR 0204). The static properties that the spec writes after the
// class are the arguments of its constructor, and a Map of options is a
// typed scope (`scopeFromMap`). A class with no Dart class of its own
// constructs its base class.
//
// A rest argument list is one Iterable: `Chart.register(A, B)` is
// `Chart.register([a, b])`. An array or an object of items has no typed
// form: the cases `as array` and `as object` skip with `diverges:
// adapt-typed-components`. `new Error(m)` is a StateError with the message
// m. `toEqual` of a class compares by identity, and `toEqual` of an object
// compares the keys and values: `equals` of the two Maps of `_plain`.
// `not.toBeDefined()` is the `undefined` sentinel.
//
// A plugin is a native `Plugin` (Chart.js ADR 0144): a class value or a Map
// in the registry of the plugins stops a debug build. A case that registers
// an object of upstream as a plugin registers a `Plugin` with its id and its
// defaults. The cases of a class plugin and of a plugin without id skip
// with `diverges: adapt-typed-plugins`.

/// `Chart.defaults[scope][key]`, the JS member read.
Object? _defaults(String scope, String key) =>
    jsGet(Chart.defaults[scope], key);

/// `Chart.overrides[key]`.
Object? _overrides(String key) => jsGet(Chart.overrides, key);

/// The keys and values of the option object [object]: a Map of the spec,
/// or a typed scope, read through its face.
Map<String, Object?> _plain(Object? object) => switch (object) {
  final Map<String, Object?> map => map,
  final JsObjectFace face => {for (final key in face.jsKeys()) key: face[key]},
  _ => throw ArgumentError.value(object, 'object', 'is not an object'),
};

/// `toThrow(new Error(message))`.
Matcher _throwsError(String message) => throwsA(
  isA<StateError>().having((error) => error.message, 'message', message),
);

void main() {
  group('Chart.registry', () {
    test('should handle an ES6 controller extension', () {
      final customController = ControllerType(
        id: 'custom',
        defaults: scopeFromMap(GenericDatasetOptionsScope(), {'foo': 'bar'}),
        overrides: scopeFromMap(ChartOptionsScope(), {'bar': 'foo'}),
        create: DatasetController.new,
      );
      Chart.register([customController]);

      expect(Chart.registry.getController('custom'), same(customController));
      expect(
        _plain(_defaults('datasets', 'custom')),
        equals(_plain(customController.defaults)),
      );
      expect(
        _plain(_overrides('custom')),
        equals(_plain(customController.overrides)),
      );

      Chart.unregister([customController]);

      expect(() {
        Chart.registry.getController('custom');
      }, _throwsError('"custom" is not a registered controller.'));
      expect(_overrides('custom'), same(undefined));
      expect(_defaults('datasets', 'custom'), same(undefined));
    });

    test('should handle an ES6 scale extension', () {
      final customScale = ScaleType(
        id: 'es6Scale',
        defaults: scopeFromMap(ScaleOptionsScope(), {'foo': 'bar'}),
        create: Scale.new,
      );
      Chart.register([customScale]);

      expect(Chart.registry.getScale('es6Scale'), same(customScale));
      expect(
        _plain(_defaults('scales', 'es6Scale')),
        equals(_plain(customScale.defaults)),
      );

      Chart.unregister([customScale]);

      expect(() {
        Chart.registry.getScale('es6Scale');
      }, _throwsError('"es6Scale" is not a registered scale.'));
      expect(_defaults('scales', 'es6Scale'), same(undefined));
    });

    test('should handle an ES6 element extension', () {
      final customElement = ElementType(
        id: 'es6element',
        defaults: scopeFromMap(GenericElementOptionsScope(), {'foo': 'bar'}),
        create: Element.new,
      );
      Chart.register([customElement]);

      expect(Chart.registry.getElement('es6element'), same(customElement));
      expect(
        _plain(_defaults('elements', 'es6element')),
        equals(_plain(customElement.defaults)),
      );

      Chart.unregister([customElement]);

      expect(() {
        Chart.registry.getElement('es6element');
      }, _throwsError('"es6element" is not a registered element.'));
      expect(_defaults('elements', 'es6element'), same(undefined));
    });

    // A class value is not a plugin: `Chart.register(CustomPlugin)` stops
    // a debug build. The case `as plugin` of `Should allow registering
    // explicitly` registers a `Plugin` with an id and defaults.
    test(
      'should handle an ES6 plugin',
      () {},
      skip: 'diverges: adapt-typed-plugins',
    );

    // `Plugin.id` is a required String. The object `{foo: 'bar'}` gives its
    // value `'bar'` to the registry of the plugins, and the class
    // `FaultyPlugin` is a class value: both are no `Plugin`, and they stop a
    // debug build, not with the error of a missing id.
    test(
      'should not accept an object without id',
      () {},
      skip: 'diverges: adapt-typed-plugins',
    );

    test(
      'should not fail when unregistering an object that is not registered',
      () {
        expect(() {
          Chart.unregister([Plugin<Object?>(id: 'foo')]);
        }, returnsNormally);
      },
    );

    group('Should allow registering explicitly', () {
      // `customExtension` of the spec has one typed component for each
      // registry, with its id and its defaults. The case `as plugin`
      // registers a native plugin with them (Chart.js ADR 0144).
      final extensionDefaults = <String, Object?>{'prop': true};
      final customController = ControllerType(
        id: 'custom',
        defaults: scopeFromMap(GenericDatasetOptionsScope(), extensionDefaults),
        create: DatasetController.new,
      );
      final customScale = ScaleType(
        id: 'custom',
        defaults: scopeFromMap(ScaleOptionsScope(), extensionDefaults),
        create: Scale.new,
      );
      final customElement = ElementType(
        id: 'custom',
        defaults: scopeFromMap(GenericElementOptionsScope(), extensionDefaults),
        create: Element.new,
      );
      final customPlugin = _CustomPlugin(pluginDefaults(extensionDefaults));

      test('as controller', () {
        Chart.registry.addControllers([customController]);

        expect(Chart.registry.getController('custom'), same(customController));
        expect(
          _plain(_defaults('datasets', 'custom')),
          equals(extensionDefaults),
        );

        Chart.registry.removeControllers([customController]);

        expect(() {
          Chart.registry.getController('custom');
        }, _throwsError('"custom" is not a registered controller.'));
        expect(_defaults('datasets', 'custom'), same(undefined));
      });

      test('as scale', () {
        Chart.registry.addScales([customScale]);

        expect(Chart.registry.getScale('custom'), same(customScale));
        expect(
          _plain(_defaults('scales', 'custom')),
          equals(extensionDefaults),
        );

        Chart.registry.removeScales([customScale]);

        expect(() {
          Chart.registry.getScale('custom');
        }, _throwsError('"custom" is not a registered scale.'));
        expect(_defaults('scales', 'custom'), same(undefined));
      });

      test('as element', () {
        Chart.registry.addElements([customElement]);

        expect(Chart.registry.getElement('custom'), same(customElement));
        expect(
          _plain(_defaults('elements', 'custom')),
          equals(extensionDefaults),
        );

        Chart.registry.removeElements([customElement]);

        expect(() {
          Chart.registry.getElement('custom');
        }, _throwsError('"custom" is not a registered element.'));
        expect(_defaults('elements', 'custom'), same(undefined));
      });

      test('as plugin', () {
        Chart.registry.addPlugins([customPlugin]);

        expect(Chart.registry.getPlugin<_CustomPlugin>(), customPlugin);
        expect(
          _plain(_defaults('plugins', 'custom')),
          equals(_plain(customPlugin.defaults)),
        );

        Chart.registry.removePlugins([customPlugin]);

        expect(() {
          Chart.registry.getPlugin<_CustomPlugin>();
          // DIVERGES(chartjs): adapt-typed-plugins, the type is the key.
        }, _throwsError('_CustomPlugin is not a registered plugin.'));
        expect(_defaults('plugins', 'custom'), same(undefined));
      });
    });

    test('should fire before/after callbacks', () {
      var beforeRegisterCount = 0;
      var afterRegisterCount = 0;
      var beforeUnregisterCount = 0;
      var afterUnregisterCount = 0;
      // `custom` of the spec has one typed component for each registry, with
      // the same hooks.
      void beforeRegister(ChartComponent _) => beforeRegisterCount++;
      void afterRegister(ChartComponent _) => afterRegisterCount++;
      void beforeUnregister(ChartComponent _) => beforeUnregisterCount++;
      void afterUnregister(ChartComponent _) => afterUnregisterCount++;
      final controller = ControllerType(
        id: 'custom',
        defaults: GenericDatasetOptionsScope(),
        beforeRegister: beforeRegister,
        afterRegister: afterRegister,
        beforeUnregister: beforeUnregister,
        afterUnregister: afterUnregister,
        create: DatasetController.new,
      );
      final scale = ScaleType(
        id: 'custom',
        defaults: ScaleOptionsScope(),
        beforeRegister: beforeRegister,
        afterRegister: afterRegister,
        beforeUnregister: beforeUnregister,
        afterUnregister: afterUnregister,
        create: Scale.new,
      );
      final element = ElementType(
        id: 'custom',
        defaults: GenericElementOptionsScope(),
        beforeRegister: beforeRegister,
        afterRegister: afterRegister,
        beforeUnregister: beforeUnregister,
        afterUnregister: afterUnregister,
        create: Element.new,
      );

      Chart.registry.addControllers([controller]);
      expect(beforeRegisterCount, 1, reason: 'beforeRegister');
      expect(afterRegisterCount, 1, reason: 'afterRegister');
      Chart.registry.removeControllers([controller]);
      expect(beforeUnregisterCount, 1, reason: 'beforeUnregister');
      expect(afterUnregisterCount, 1, reason: 'afterUnregister');

      Chart.registry.addScales([scale]);
      expect(beforeRegisterCount, 2, reason: 'beforeRegister');
      expect(afterRegisterCount, 2, reason: 'afterRegister');
      Chart.registry.removeScales([scale]);
      expect(beforeUnregisterCount, 2, reason: 'beforeUnregister');
      expect(afterUnregisterCount, 2, reason: 'afterUnregister');

      Chart.registry.addElements([element]);
      expect(beforeRegisterCount, 3, reason: 'beforeRegister');
      expect(afterRegisterCount, 3, reason: 'afterRegister');
      Chart.registry.removeElements([element]);
      expect(beforeUnregisterCount, 3, reason: 'beforeUnregister');
      expect(afterUnregisterCount, 3, reason: 'afterUnregister');

      // :198-203 `Chart.register(custom)` puts the class into the registry of
      // the plugins, the fallback registry. A plugin is a native `Plugin`
      // (Chart.js ADR 0144), which has no `beforeRegister`, `afterRegister`,
      // `beforeUnregister` and `afterUnregister`, and a typed component goes
      // to the registry of its type. Thus the case ends after the elements.
      // DIVERGES(chartjs): adapt-typed-plugins, no class value as a plugin.
    });

    test('should preserve existing defaults', () {
      (Chart.defaults['datasets']! as JsObjectFace)['test'] = <String, Object?>{
        'test1': true,
        'test3': false,
      };
      Chart.overrides['test'] = <String, Object?>{
        'testA': true,
        'testC': false,
      };

      final testController = ControllerType(
        id: 'test',
        defaults: scopeFromMap(GenericDatasetOptionsScope(), {
          'test1': false,
          'test2': true,
        }),
        overrides: scopeFromMap(ChartOptionsScope(), {
          'testA': false,
          'testB': true,
        }),
        create: DatasetController.new,
      );

      Chart.register([testController]);
      expect(
        _plain(_defaults('datasets', 'test')),
        equals(<String, Object?>{
          'test1': false,
          'test2': true,
          'test3': false,
        }),
      );
      expect(
        _plain(_overrides('test')),
        equals(<String, Object?>{
          'testA': false,
          'testB': true,
          'testC': false,
        }),
      );

      Chart.unregister([testController]);
      expect(_defaults('datasets', 'test'), same(undefined));
      expect(_overrides('test'), same(undefined));
    });

    group('should handle multiple items', () {
      final test1 = ControllerType(
        id: 'test1',
        defaults: GenericDatasetOptionsScope(),
        create: DatasetController.new,
      );
      final test2 = ScaleType(
        id: 'test2',
        defaults: ScaleOptionsScope(),
        create: Scale.new,
      );

      test('separately', () {
        Chart.register([test1, test2]);
        expect(Chart.registry.getController('test1'), same(test1));
        expect(Chart.registry.getScale('test2'), same(test2));
        Chart.unregister([test1, test2]);
        expect(() {
          Chart.registry.getController('test1');
        }, throwsA(anything));
        expect(() {
          Chart.registry.getScale('test2');
        }, throwsA(anything));
      });

      // `Chart.register([test1, test2])` and `Chart.register({test1,
      // test2})` give an array and an object of items. The registry takes
      // items only (Chart.js ADR 0204).
      test('as array', () {}, skip: 'diverges: adapt-typed-components');

      test('as object', () {}, skip: 'diverges: adapt-typed-components');
    });
  });
}

/// The plugin `custom` of the spec, a class of its own, so
/// `getPlugin<_CustomPlugin>()` finds it (row adapt-typed-plugins).
final class _CustomPlugin(PluginDefaults defaults) extends Plugin<Object?> {
  /// The plugin `custom` with [defaults].
  this : super(id: 'custom', defaults: defaults);
}
