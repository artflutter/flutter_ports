// Original code, not ported from Chart.js: the load of core.defaults.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/core/core.defaults.dart';
import 'package:test/test.dart';

// The JavaScript import of src/core/core.defaults.js runs the constructor of
// the default export. It fills `descriptors` before any other read. The
// expected keys come from src/core/core.defaults.js at v4.5.1 in Node.js
// v24.12.0 on x64. This file does not call setUpSpecs: its set-up reads
// `defaults` before the test.
//
// Under flutter test, flutter_test_config.dart registers the built-in
// components before main() (harness-register-builtins). removeBuiltins()
// removes them again. Under dart test, it does nothing and reads nothing.

void main() {
  removeBuiltins();

  test('descriptors and overrides read before defaults are filled', () {
    expect(descriptors.keys, [
      '_scriptable',
      '_indexable',
      'hover',
      'interaction',
      'animation',
      'animations',
      'scale',
      'scales',
    ]);
    expect(overrides, isEmpty);
  });
}
