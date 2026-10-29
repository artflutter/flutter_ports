// Ported from Chart.js v4.6.1 test/specs/core.defaults.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:test/test.dart';

// `Chart.defaults` is the default export of core.defaults.js, [defaults].

/// The JavaScript property read `object[key]` on an object (a Map): an
/// absent key gives [undefined].
Object? _get(Object? object, String key) {
  final map = object! as Map<String, Object?>;
  return map.containsKey(key) ? map[key] : undefined;
}

void main() {
  setUpSpecs();
  group('Chart.defaults', () {
    group('.set', () {
      test(
        'Should set defaults directly to root when scope is not provided',
        () {
          expect(_get(defaults, 'test'), same(undefined));
          defaults.set(<String, Object?>{'test': true});
          expect(_get(defaults, 'test'), true);
          defaults.remove('test');
        },
      );

      test('Should create scope when it does not exist', () {
        expect(_get(defaults, 'test'), same(undefined));
        defaults.set('test', <String, Object?>{'value': true});
        expect(_get(_get(defaults, 'test'), 'value'), true);
        defaults.remove('test');
      });
    });

    group('.route', () {
      test('Should read the source, but not change it', () {
        expect(_get(defaults, 'testscope'), same(undefined));

        defaults
          ..set('testscope', <String, Object?>{'test': true})
          ..route('testscope', 'test2', 'testscope', 'test');

        expect(_get(_get(defaults, 'testscope'), 'test'), true);
        expect(_get(_get(defaults, 'testscope'), 'test2'), true);

        defaults.set('testscope', <String, Object?>{'test2': false});
        expect(_get(_get(defaults, 'testscope'), 'test'), true);
        expect(_get(_get(defaults, 'testscope'), 'test2'), false);

        defaults.set('testscope', <String, Object?>{'test2': undefined});
        expect(_get(_get(defaults, 'testscope'), 'test2'), true);

        defaults.remove('testscope');
      });
    });
  });
}
