// Original code, not ported from Chart.js: tests of the built-in set-up.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.typedRegistry.dart';
import 'package:flutter_chartjs_port/src/elements/element.arc.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:test/test.dart';

// setUpBuiltins and removeBuiltins of pure.dart (Chart.js ADR 0022, section
// 8, `harness-register-builtins`). flutter_test_config.dart of
// flutter_chartjs_port registers the built-in components with them before
// main(). This package has no such config: each test calls them itself, and
// the restore of setUpSpecs puts back the scopes after it. The file is a
// pure layer: it runs on the VM, dart2js and dart2wasm.

/// The keys of `defaults.elements`.
Iterable<String> _elementDefaults() =>
    (defaults['elements']! as JsObjectFace).jsKeys();

void main() {
  setUpSpecs();

  test('removeBuiltins does nothing without setUpBuiltins', () {
    final keys = defaults.jsKeys();
    removeBuiltins();
    expect(defaults.jsKeys(), keys);
    expect(_elementDefaults(), isEmpty);
  });

  test('setUpBuiltins registers, and removeBuiltins puts back the scopes of '
      'the modules', () {
    final builtins = TypedRegistry(Element.jsClass, 'elements');
    final descriptorKeys = descriptors.jsKeys();
    final log = <String>[];

    setUpBuiltins(
      () {
        log.add('register');
        builtins
          ..register(ArcElement.jsClass)
          ..register(PointElement.jsClass);
      },
      () {
        log.add('unregister');
        builtins
          ..unregister(ArcElement.jsClass)
          ..unregister(PointElement.jsClass);
      },
    );
    expect(log, ['register']);
    expect(_elementDefaults(), ['arc', 'point']);
    expect(descriptors.jsHas('elements'), isTrue);

    removeBuiltins();
    expect(log, ['register', 'unregister']);
    expect(builtins.items, isEmpty);
    expect(_elementDefaults(), isEmpty);
    expect(descriptors.jsKeys(), descriptorKeys);

    // A registration of the test file through a new TypedRegistry routes
    // the element defaults again without a throw.
    TypedRegistry(Element.jsClass, 'elements').register(PointElement.jsClass);
    expect(_elementDefaults(), ['point']);

    // The removal runs once.
    removeBuiltins();
    expect(log, ['register', 'unregister']);
    expect(_elementDefaults(), ['point']);
  });

  test('the next test finds the scopes of the modules', () {
    expect(_elementDefaults(), isEmpty);
    expect(descriptors.jsHas('elements'), isFalse);
  });

  // Chart.js ADR 0041, section 6 item 3. flutter_test_config.dart of
  // flutter_chartjs_port registers the plugins in setUpBuiltins and then
  // writes `defaults.plugins.colors.enabled = false` (test/index.js:25-28).
  // removeBuiltins puts back the scopes of before the registration, so a
  // pure-layer file has no colors plugin and no colors line to undo. The
  // plugin here is a stand-in with the id and the defaults of
  // plugin.colors.ts:93-99, because plugin.colors.dart is not a pure layer.
  test('removeBuiltins removes the colors plugin and the colors line', () {
    final plugins = TypedRegistry(jsObjectClass, 'plugins');
    final colors = <String, Object?>{
      'id': 'colors',
      'defaults': <String, Object?>{'enabled': true, 'forceOverride': false},
    };
    setUpBuiltins(
      () => plugins.register(colors),
      () => plugins.unregister(colors),
    );
    // The colors line of flutter_test_config.dart.
    ((defaults['plugins']! as JsObjectFace)['colors']!
            as JsObjectFace)['enabled'] =
        false;
    expect(jsGet(jsGet(defaults['plugins'], 'colors'), 'enabled'), isFalse);

    removeBuiltins();
    expect(plugins.items, isEmpty);
    expect((defaults['plugins']! as JsObjectFace).jsKeys(), isEmpty);
    expect((defaults['plugins']! as JsObjectFace).jsHas('colors'), isFalse);
  });
}
