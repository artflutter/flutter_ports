// Ported from Chart.js v4.6.1 test/specs/global.namespace.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_test/flutter_test.dart';

// The namespace spec has no chart: each case is a `test()` case. It runs on
// the VM, because core.controller.dart reaches the platform layer (Chart.js
// ADR 0041, section 12). It does not call setUpSpecs(): it has no pure
// case.
//
// `Chart instanceof Function` (:4) is the constructor tear-off of the Dart
// class: `Chart.new` is a Function. The other cases read the statics that
// the UMD bundle writes on `Chart` (src/index.umd.ts:30-47). The port has no
// UMD bundle (Chart.js ADR 0120): Dart has no global object, and an app
// imports the public libraries. Thus these cases do not apply.

void main() {
  // global.namespace.tests.js:1
  group('Chart namespace', () {
    // :2
    group('Chart', () {
      // :3-5
      test('should a function (constructor)', () {
        expect(Chart.new, isA<Function>());
      });

      // :6-22
      test(
        'should define "core" properties',
        () {},
        skip: 'n/a: the port has no UMD bundle (Chart.js ADR 0120)',
      );
    });

    // :25
    group('Chart.elements', () {
      // :26-31
      test(
        'should contains "elements" classes',
        () {},
        skip: 'n/a: the port has no UMD bundle (Chart.js ADR 0120)',
      );
    });

    // :34
    group('Chart.helpers', () {
      // :35-37
      test(
        'should be an object',
        () {},
        skip: 'n/a: the port has no UMD bundle (Chart.js ADR 0120)',
      );
    });
  });
}
