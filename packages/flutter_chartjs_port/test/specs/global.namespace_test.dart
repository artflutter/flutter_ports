// Ported from Chart.js v4.6.1 test/specs/global.namespace.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

// The spec reads the UMD entry of lib/src, which no public library exports
// (Chart.js ADR 0048, section 1).
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/index.umd.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_test/flutter_test.dart';

// The namespace spec has no chart: each case is a `test()` case. It runs on
// the VM, because core.controller.dart reaches the platform layer (Chart.js
// ADR 0041, section 12). It does not call setUpSpecs(): it has no pure
// case.
//
// `Chart instanceof Function` (:4) is the constructor tear-off of the Dart
// class: `Chart.new` is a Function. The other cases read the statics that
// the UMD entry writes on `Chart` (src/index.umd.ts:30-47). The specs run on
// the UMD bundle (karma.conf.cjs:110). Thus `Chart` of these cases is
// `chartUmd` of lib/src/index.umd.dart, the class value of `Chart` after the
// body of the module. `x instanceof Function` is `jsIsFunction(x)`, true for
// a class value. `x instanceof Object` is `_isObject(x)`.

/// `value instanceof Object`: a value that is not null with the `typeof`
/// `object` or `function`.
bool _isObject(Object? value) {
  if (value == null) return false;
  final type = jsTypeof(value);
  return type == 'object' || type == 'function';
}

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
      test('should define "core" properties', () {
        expect(jsIsFunction(chartUmd), isTrue);
        expect(_isObject(jsGet(chartUmd, 'Animation')), isTrue);
        expect(_isObject(jsGet(chartUmd, 'Animations')), isTrue);
        expect(_isObject(jsGet(chartUmd, 'defaults')), isTrue);
        expect(_isObject(jsGet(chartUmd, 'Element')), isTrue);
        expect(_isObject(jsGet(chartUmd, 'Interaction')), isTrue);
        expect(_isObject(jsGet(chartUmd, 'layouts')), isTrue);

        final platforms = jsGet(chartUmd, 'platforms');
        expect(jsIsFunction(jsGet(platforms, 'BasePlatform')), isTrue);
        expect(jsIsFunction(jsGet(platforms, 'BasicPlatform')), isTrue);
        expect(jsIsFunction(jsGet(platforms, 'DomPlatform')), isTrue);

        expect(_isObject(jsGet(chartUmd, 'registry')), isTrue);
        expect(_isObject(jsGet(chartUmd, 'Scale')), isTrue);
        expect(_isObject(jsGet(chartUmd, 'Ticks')), isTrue);
      });
    });

    // :25
    group('Chart.elements', () {
      // :26-31
      test('should contains "elements" classes', () {
        final elements = jsGet(chartUmd, 'elements');
        expect(jsIsFunction(jsGet(elements, 'ArcElement')), isTrue);
        expect(jsIsFunction(jsGet(elements, 'BarElement')), isTrue);
        expect(jsIsFunction(jsGet(elements, 'LineElement')), isTrue);
        expect(jsIsFunction(jsGet(elements, 'PointElement')), isTrue);
      });
    });

    // :34
    group('Chart.helpers', () {
      // :35-37
      test('should be an object', () {
        expect(_isObject(jsGet(chartUmd, 'helpers')), isTrue);
      });
    });
  });
}
