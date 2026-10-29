// Ported from Chart.js v4.6.1 test/specs/core.helpers.tests.js (MIT, Chart.js Contributors).
import 'dart:convert';

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart' as helpers;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:test/test.dart';

// The spec reads `window.Chart.helpers` in a beforeAll. Here `helpers` is the
// import prefix of helpers.core.

/// `object.key`: a read of [key], which is undefined in JavaScript if
/// [object] does not own it. A Map has no prototype, so no key is inherited.
Object? _get(Map<String, Object?> object, String key) =>
    object.containsKey(key) ? object[key] : undefined;

void main() {
  setUpSpecs();
  group('Core helper tests', () {
    test('should generate integer ids', () {
      final uid = helpers.uid();
      // jasmine.any(Number)
      expect(uid, isA<double>());
      expect(helpers.uid(), uid + 1);
      expect(helpers.uid(), uid + 2);
      expect(helpers.uid(), uid + 3);
    });

    group('clone', () {
      // Dart has no prototypes, so a key cannot pollute a shared prototype.
      // The port keeps the upstream behavior: clone copies the key
      // `__proto__` as an own key, as JavaScript does on its target without
      // a prototype (Object.create(null)). The case checks the two upstream
      // facts on the Dart values.
      test('should not allow prototype pollution', () {
        final source = jsonDecode(
          '{"__proto__":{"polluted": true}}',
        ) as Map<String, Object?>;
        final test = helpers.clone(source)! as Map<String, Object?>;
        // test.prototype
        expect(_get(test, 'prototype'), same(undefined));
        // Object.prototype.polluted: Dart has no shared prototype that a key
        // can change. The upstream outcome on the Dart values: `__proto__` is
        // an own key of the copy, as on the Object.create(null) target of
        // upstream. The copy does not share an object with the source, and
        // the source does not change.
        expect(test.keys, ['__proto__']);
        expect(test['__proto__'], {'polluted': true});
        expect(test['__proto__'], isNot(same(source['__proto__'])));
        expect(source, {
          '__proto__': {'polluted': true},
        });
      });
    });
  });
}
