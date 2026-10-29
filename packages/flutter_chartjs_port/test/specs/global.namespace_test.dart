// Ported from Chart.js v4.6.1 test/specs/global.namespace.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

// The spec reads Chart of flutter_chartjs_port, which does not export
// lib/src yet.
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_test/flutter_test.dart';

// The namespace spec has no chart: each case is a `test()` case. It runs on
// the VM, because core.controller.dart reaches the platform layer (Chart.js
// ADR 0041, section 12). It does not call setUpSpecs(): it has no pure
// case.
//
// `Chart instanceof Function` (:4) is the constructor tear-off of the Dart
// class: `Chart.new` is a Function. The other cases read the statics that
// the UMD entry writes on `Chart` (src/index.umd.ts:30-47): `Chart.helpers`,
// `Chart.Animation`, `Chart.platforms`, `Chart.elements` and the others.
// src/index.umd.ts is not ported (phase 9), so these cases skip as
// 'blocked: index.umd'. The stale-block check of tool 5 keeps them valid
// while the row src/index.umd.ts is not `ported`.

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
        skip: 'blocked: index.umd',
      );
    });

    // :25
    group('Chart.elements', () {
      // :26-31
      test(
        'should contains "elements" classes',
        () {},
        skip: 'blocked: index.umd',
      );
    });

    // :34
    group('Chart.helpers', () {
      // :35-37
      test('should be an object', () {}, skip: 'blocked: index.umd');
    });
  });
}
