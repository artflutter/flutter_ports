// Original code, not ported from Chart.js: tests of the built-in set-up.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.typedRegistry.dart';
import 'package:flutter_chartjs_port/src/elements/element.arc.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:test/test.dart';

// setUpBuiltins and removeBuiltins of pure.dart (Chart.js ADR 0022, section
// 8, `harness-register-builtins`). flutter_test_config.dart of
// flutter_chartjs_port registers the built-in components with them before
// main(). This package has no such config: each test calls them itself, and
// the restore of setUpSpecs puts back the scopes after it. The file is a
// pure layer: it runs on the VM, dart2js and dart2wasm.

/// The keys of `defaults.elements`.
Iterable<String> _elementDefaults() =>
    (defaults['elements']! as Map<String, Object?>).keys;

void main() {
  setUpSpecs();

  test('removeBuiltins does nothing without setUpBuiltins', () {
    final keys = defaults.keys.toList();
    removeBuiltins();
    expect(defaults.keys, keys);
    expect(_elementDefaults(), isEmpty);
  });

  test('setUpBuiltins registers, and removeBuiltins puts back the scopes of '
      'the modules', () {
    final builtins = TypedRegistry(Element.jsClass, 'elements');
    final descriptorKeys = descriptors.keys.toList();
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
    expect(descriptors.containsKey('elements'), isTrue);

    removeBuiltins();
    expect(log, ['register', 'unregister']);
    expect(builtins.items, isEmpty);
    expect(_elementDefaults(), isEmpty);
    expect(descriptors.keys, descriptorKeys);

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
    expect(descriptors.containsKey('elements'), isFalse);
  });
}
