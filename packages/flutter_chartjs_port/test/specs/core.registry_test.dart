// Ported from Chart.js v4.5.1+7169e651 test/specs/core.registry.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

// The spec registers classes of flutter_chartjs_port, which does not export
// lib/src yet.
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_test/flutter_test.dart';

// The registry spec has no chart: each case calls `Chart.register`,
// `Chart.unregister` and the registry of `Chart.registry`. It runs on the
// VM, because core.controller.dart reaches the platform layer (Chart.js ADR
// 0020, section 10).
//
// A class `class X extends Y {}` of the spec is a class value: `JsClass('X',
// superclass: Y.jsClass)`. A static property that the spec writes after the
// class is a write with `operator []=` (Chart.js ADR 0020, section 8).
// `Chart.DatasetController`, `Chart.Scale` and `Chart.Element` are the class
// values `DatasetController.jsClass`, `Scale.jsClass` and `Element.jsClass`.
//
// A rest argument list is one List: `Chart.register(A, B)` is
// `Chart.register([a, b])`, and `Chart.register([A, B])` is
// `Chart.register([[a, b]])` (Chart.js ADR 0020, section 6). `new Error(m)`
// is a StateError with the message m. `toEqual` of a class compares by
// identity, and `toEqual` of an object compares the keys and values.
// `not.toBeDefined()` is the `undefined` sentinel.

/// `Chart.defaults[scope][key]`, the JS member read.
Object? _defaults(String scope, String key) =>
    jsGet(Chart.defaults[scope], key);

/// `Chart.overrides[key]`.
Object? _overrides(String key) => jsGet(Chart.overrides, key);

/// `toThrow(new Error(message))`.
Matcher _throwsError(String message) => throwsA(
  isA<StateError>().having((error) => error.message, 'message', message),
);

void main() {
  group('Chart.registry', () {
    test('should handle an ES6 controller extension', () {
      final customController = JsClass(
        'CustomController',
        superclass: DatasetController.jsClass,
      );
      customController['id'] = 'custom';
      customController['defaults'] = <String, Object?>{'foo': 'bar'};
      customController['overrides'] = <String, Object?>{'bar': 'foo'};
      Chart.register([customController]);

      expect(Chart.registry.getController('custom'), customController);
      expect(_defaults('datasets', 'custom'), customController['defaults']);
      expect(_overrides('custom'), customController['overrides']);

      Chart.unregister([customController]);

      expect(() {
        Chart.registry.getController('custom');
      }, _throwsError('"custom" is not a registered controller.'));
      expect(_overrides('custom'), same(undefined));
      expect(_defaults('datasets', 'custom'), same(undefined));
    });

    test('should handle an ES6 scale extension', () {
      final customScale = JsClass('CustomScale', superclass: Scale.jsClass);
      customScale['id'] = 'es6Scale';
      customScale['defaults'] = <String, Object?>{'foo': 'bar'};
      Chart.register([customScale]);

      expect(Chart.registry.getScale('es6Scale'), customScale);
      expect(_defaults('scales', 'es6Scale'), customScale['defaults']);

      Chart.unregister([customScale]);

      expect(() {
        Chart.registry.getScale('es6Scale');
      }, _throwsError('"es6Scale" is not a registered scale.'));
      expect(_defaults('scales', 'es6Scale'), same(undefined));
    });

    test('should handle an ES6 element extension', () {
      final customElement = JsClass(
        'CustomElement',
        superclass: Element.jsClass,
      );
      customElement['id'] = 'es6element';
      customElement['defaults'] = <String, Object?>{'foo': 'bar'};
      Chart.register([customElement]);

      expect(Chart.registry.getElement('es6element'), customElement);
      expect(_defaults('elements', 'es6element'), customElement['defaults']);

      Chart.unregister([customElement]);

      expect(() {
        Chart.registry.getElement('es6element');
      }, _throwsError('"es6element" is not a registered element.'));
      expect(_defaults('elements', 'es6element'), same(undefined));
    });

    test('should handle an ES6 plugin', () {
      final customPlugin = JsClass('CustomPlugin');
      customPlugin['id'] = 'es6plugin';
      customPlugin['defaults'] = <String, Object?>{'foo': 'bar'};
      Chart.register([customPlugin]);

      expect(Chart.registry.getPlugin('es6plugin'), customPlugin);
      expect(_defaults('plugins', 'es6plugin'), customPlugin['defaults']);

      Chart.unregister([customPlugin]);

      expect(() {
        Chart.registry.getPlugin('es6plugin');
      }, _throwsError('"es6plugin" is not a registered plugin.'));
      expect(_defaults('plugins', 'es6plugin'), same(undefined));
    });

    test('should not accept an object without id', () {
      expect(() {
        Chart.register([
          <String, Object?>{'foo': 'bar'},
        ]);
      }, _throwsError('class does not have id: bar'));

      final faultyPlugin = JsClass('FaultyPlugin');

      expect(() {
        Chart.register([faultyPlugin]);
      }, _throwsError('class does not have id: class FaultyPlugin {}'));
    });

    test(
      'should not fail when unregistering an object that is not registered',
      () {
        expect(() {
          Chart.unregister([
            <String, Object?>{'id': 'foo'},
          ]);
        }, returnsNormally);
      },
    );

    group('Should allow registering explicitly', () {
      final customExtension = JsClass('customExtension');
      customExtension['id'] = 'custom';
      customExtension['defaults'] = <String, Object?>{'prop': true};

      test('as controller', () {
        Chart.registry.addControllers([customExtension]);

        expect(Chart.registry.getController('custom'), customExtension);
        expect(_defaults('datasets', 'custom'), customExtension['defaults']);

        Chart.registry.removeControllers([customExtension]);

        expect(() {
          Chart.registry.getController('custom');
        }, _throwsError('"custom" is not a registered controller.'));
        expect(_defaults('datasets', 'custom'), same(undefined));
      });

      test('as scale', () {
        Chart.registry.addScales([customExtension]);

        expect(Chart.registry.getScale('custom'), customExtension);
        expect(_defaults('scales', 'custom'), customExtension['defaults']);

        Chart.registry.removeScales([customExtension]);

        expect(() {
          Chart.registry.getScale('custom');
        }, _throwsError('"custom" is not a registered scale.'));
        expect(_defaults('scales', 'custom'), same(undefined));
      });

      test('as element', () {
        Chart.registry.addElements([customExtension]);

        expect(Chart.registry.getElement('custom'), customExtension);
        expect(_defaults('elements', 'custom'), customExtension['defaults']);

        Chart.registry.removeElements([customExtension]);

        expect(() {
          Chart.registry.getElement('custom');
        }, _throwsError('"custom" is not a registered element.'));
        expect(_defaults('elements', 'custom'), same(undefined));
      });

      test('as plugin', () {
        Chart.registry.addPlugins([customExtension]);

        expect(Chart.registry.getPlugin('custom'), customExtension);
        expect(_defaults('plugins', 'custom'), customExtension['defaults']);

        Chart.registry.removePlugins([customExtension]);

        expect(() {
          Chart.registry.getPlugin('custom');
        }, _throwsError('"custom" is not a registered plugin.'));
        expect(_defaults('plugins', 'custom'), same(undefined));
      });
    });

    test('should fire before/after callbacks', () {
      var beforeRegisterCount = 0;
      var afterRegisterCount = 0;
      var beforeUnregisterCount = 0;
      var afterUnregisterCount = 0;
      final custom = JsClass('custom');
      custom['id'] = 'custom';
      custom['beforeRegister'] = () => beforeRegisterCount++;
      custom['afterRegister'] = () => afterRegisterCount++;
      custom['beforeUnregister'] = () => beforeUnregisterCount++;
      custom['afterUnregister'] = () => afterUnregisterCount++;

      Chart.registry.addControllers([custom]);
      expect(beforeRegisterCount, 1, reason: 'beforeRegister');
      expect(afterRegisterCount, 1, reason: 'afterRegister');
      Chart.registry.removeControllers([custom]);
      expect(beforeUnregisterCount, 1, reason: 'beforeUnregister');
      expect(afterUnregisterCount, 1, reason: 'afterUnregister');

      Chart.registry.addScales([custom]);
      expect(beforeRegisterCount, 2, reason: 'beforeRegister');
      expect(afterRegisterCount, 2, reason: 'afterRegister');
      Chart.registry.removeScales([custom]);
      expect(beforeUnregisterCount, 2, reason: 'beforeUnregister');
      expect(afterUnregisterCount, 2, reason: 'afterUnregister');

      Chart.registry.addElements([custom]);
      expect(beforeRegisterCount, 3, reason: 'beforeRegister');
      expect(afterRegisterCount, 3, reason: 'afterRegister');
      Chart.registry.removeElements([custom]);
      expect(beforeUnregisterCount, 3, reason: 'beforeUnregister');
      expect(afterUnregisterCount, 3, reason: 'afterUnregister');

      Chart.register([custom]);
      expect(beforeRegisterCount, 4, reason: 'beforeRegister');
      expect(afterRegisterCount, 4, reason: 'afterRegister');
      Chart.unregister([custom]);
      expect(beforeUnregisterCount, 4, reason: 'beforeUnregister');
      expect(afterUnregisterCount, 4, reason: 'afterUnregister');
    });

    test('should preserve existing defaults', () {
      (Chart.defaults['datasets']! as Map<String, Object?>)['test'] =
          <String, Object?>{'test1': true, 'test3': false};
      Chart.overrides['test'] = <String, Object?>{
        'testA': true,
        'testC': false,
      };

      final testController = JsClass(
        'testController',
        superclass: DatasetController.jsClass,
      );
      testController['id'] = 'test';
      testController['defaults'] = <String, Object?>{
        'test1': false,
        'test2': true,
      };
      testController['overrides'] = <String, Object?>{
        'testA': false,
        'testB': true,
      };

      Chart.register([testController]);
      expect(_defaults('datasets', 'test'), {
        'test1': false,
        'test2': true,
        'test3': false,
      });
      expect(_overrides('test'), {
        'testA': false,
        'testB': true,
        'testC': false,
      });

      Chart.unregister([testController]);
      expect(_defaults('datasets', 'test'), same(undefined));
      expect(_overrides('test'), same(undefined));
    });

    group('should handle multiple items', () {
      final test1 = JsClass('test1', superclass: DatasetController.jsClass);
      test1['id'] = 'test1';
      final test2 = JsClass('test2', superclass: Scale.jsClass);
      test2['id'] = 'test2';

      test('separately', () {
        Chart.register([test1, test2]);
        expect(Chart.registry.getController('test1'), test1);
        expect(Chart.registry.getScale('test2'), test2);
        Chart.unregister([test1, test2]);
        expect(() {
          Chart.registry.getController('test1');
        }, throwsA(anything));
        expect(() {
          Chart.registry.getScale('test2');
        }, throwsA(anything));
      });

      test('as array', () {
        Chart.register([
          [test1, test2],
        ]);
        expect(Chart.registry.getController('test1'), test1);
        expect(Chart.registry.getScale('test2'), test2);
        Chart.unregister([
          [test1, test2],
        ]);
        expect(() {
          Chart.registry.getController('test1');
        }, throwsA(anything));
        expect(() {
          Chart.registry.getScale('test2');
        }, throwsA(anything));
      });

      test('as object', () {
        Chart.register([
          <String, Object?>{'test1': test1, 'test2': test2},
        ]);
        expect(Chart.registry.getController('test1'), test1);
        expect(Chart.registry.getScale('test2'), test2);
        Chart.unregister([
          <String, Object?>{'test1': test1, 'test2': test2},
        ]);
        expect(() {
          Chart.registry.getController('test1');
        }, throwsA(anything));
        expect(() {
          Chart.registry.getScale('test2');
        }, throwsA(anything));
      });
    });
  });
}
