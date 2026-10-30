// Original code, not ported from Chart.js: tests of the option cell.

// The cell of Chart.js ADR 0054 §1: the three JS states of a key, the
// classification order of the resolver (undefined, null, function, array,
// object, plain value) and the foreign values.

import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:test/test.dart';

Object? _fn(Object? ctx) => ctx;

void main() {
  group('the three states', () {
    test('undefined and null are cells of every type', () {
      expect(classifyNumber(undefined), same(optUndefined));
      expect(classifyNumber(null), same(optNull));
      expect(classifyString(undefined).raw, same(undefined));
      expect(classifyBool(null).raw, isNull);
      const Opt<double> cell = optUndefined;
      expect(cell, isA<OptUndefined>());
    });
  });

  group('classifyNumber', () {
    test('a JS number is a double', () {
      final cell = classifyNumber(3);
      expect(cell, isA<OptValue<double>>());
      expect((cell as OptValue<double>).value, 3.0);
      expect(cell.value, isA<double>());
      expect(classifyNumber(double.nan).raw, isNaN);
    });

    test('a string is foreign', () {
      final cell = classifyNumber('5');
      expect(cell, isA<OptForeign<double>>());
      expect(cell.raw, '5');
    });

    test('a bool and an object are foreign', () {
      expect(classifyNumber(true), isA<OptForeign<double>>());
      expect(classifyNumber(DateTime.utc(2026)), isA<OptForeign<double>>());
    });
  });

  group('the order of the resolver', () {
    test('a function is a function cell for every shape', () {
      const js = JsFunction(_fn);
      final klass = JsClass('C');
      for (final value in <Object>[_fn, js, klass]) {
        expect(classifyNumber(value), isA<OptFunction<double>>());
        expect(classifyString(value).raw, same(value));
        expect(classifyUnion(value, ShapeBits.any), isA<OptFunction<Object>>());
      }
    });

    test('an array is a list cell with the same List', () {
      final list = <Object?>[1.0, 2.0];
      final cell = classifyNumber(list);
      expect(cell, isA<OptList<double>>());
      expect((cell as OptList<double>).items, same(list));
    });

    test('an object is a scope cell with the same object', () {
      final map = <String, Object?>{'a': 1.0};
      final scope = FontSpecScope();
      expect(classifyNumber(map).raw, same(map));
      expect(classifyNumber(map), isA<OptScope<double>>());
      expect(classifyScope<FontSpecScope>(scope).raw, same(scope));
      expect(classifyUnion(scope, ShapeBits.number), isA<OptScope<Object>>());
    });

    test('a plain value outside a scope shape is foreign', () {
      expect(classifyScope<FontSpecScope>('bold'), isA<OptForeign<Object?>>());
      expect(classifyScope<FontSpecScope>(false).raw, false);
    });
  });

  group('classifyUnion', () {
    test('the atoms of the mask take their values', () {
      const mask = ShapeBits.number | ShapeBits.string;
      expect(classifyUnion(2, mask), isA<OptValue<Object>>());
      expect(classifyUnion(2, mask).raw, 2.0);
      expect(classifyUnion('50%', mask), isA<OptValue<Object>>());
      expect(classifyUnion(true, mask), isA<OptForeign<Object>>());
    });

    test('any takes every plain value, a number as a double', () {
      final date = DateTime.utc(2026);
      expect(classifyUnion(date, ShapeBits.any).raw, same(date));
      expect(classifyUnion(7, ShapeBits.any).raw, isA<double>());
      expect(classifyUnion(false, ShapeBits.any), isA<OptValue<Object>>());
    });
  });

  group('classifyBool and classifyString', () {
    test('their own values, else foreign', () {
      expect(classifyBool(false), isA<OptValue<bool>>());
      expect(classifyBool(0), isA<OptForeign<bool>>());
      expect(classifyString('a'), isA<OptValue<String>>());
      expect(classifyString(1), isA<OptForeign<String>>());
    });
  });
}
