// Original code, not ported from Chart.js: helpers.rtl cases with no spec.
import 'package:flutter_chartjs/src/helpers/helpers.rtl.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:test/test.dart';

// Upstream has no spec for helpers.rtl.ts (AGENTS.md rule 3). The expected
// values come from src/helpers/helpers.rtl.ts at v4.5.1, run with type
// stripping in Node.js v24.12.0 on x64.

void main() {
  group('getRtlAdapter', () {
    test('returns the right-to-left adapter for a truthy rtl', () {
      // getRtlAdapter(v, 10, 100).x(30) for the falsy values undefined,
      // null, 0, -0, NaN and '', and the truthy values 1, 'x', {} and [].
      const falsy = <Object?>[undefined, null, 0, -0.0, double.nan, ''];
      final truthy = <Object?>[1, 'x', <String, Object?>{}, <Object?>[]];
      for (final value in falsy) {
        expect(getRtlAdapter(value, 10, 100).x(30), 30, reason: '$value');
      }
      for (final value in truthy) {
        expect(getRtlAdapter(value, 10, 100).x(30), 90, reason: '$value');
      }
      expect(getRtlAdapter(true, 10, 100).x(30), 90);
      expect(getRtlAdapter(false, 10, 100).x(30), 30);
    });

    test('returns a new right-to-left adapter on each call', () {
      expect(
        identical(getRtlAdapter(true, 0, 0), getRtlAdapter(true, 0, 0)),
        isFalse,
      );
    });
  });

  group('the right-to-left adapter', () {
    test('mirrors x in the rectangle', () {
      final adapter = getRtlAdapter(true, 10, 100);
      expect(adapter.x(30), 90);
      expect(adapter.x(0), 120);
      expect(adapter.x(120), 0);
    });

    test('setWidth changes the width that x uses', () {
      final adapter = getRtlAdapter(true, 10, 100)..setWidth(50);
      expect(adapter.x(30), 40);
    });

    test('textAlign swaps left and right', () {
      final adapter = getRtlAdapter(true, 10, 100);
      expect(adapter.textAlign('center'), 'center');
      expect(adapter.textAlign('left'), 'right');
      expect(adapter.textAlign('right'), 'left');
      // A value other than 'center' and 'right' gives 'right'.
      expect(adapter.textAlign('start'), 'right');
      expect(adapter.textAlign('end'), 'right');
      expect(adapter.textAlign(undefined), 'right');
      expect(adapter.textAlign(null), 'right');
    });

    test('xPlus subtracts and leftForLtr subtracts the width', () {
      final adapter = getRtlAdapter(true, 10, 100);
      expect(adapter.xPlus(30, 5), 25);
      expect(adapter.leftForLtr(30, 5), 25);
    });
  });

  group('the left-to-right adapter', () {
    test('returns x', () {
      final adapter = getRtlAdapter(false, 10, 100);
      expect(adapter.x(30), 30);
    });

    test('setWidth does nothing', () {
      final adapter = getRtlAdapter(false, 10, 100)..setWidth(50);
      expect(adapter.x(30), 30);
    });

    test('textAlign returns its argument', () {
      final adapter = getRtlAdapter(false, 10, 100);
      expect(adapter.textAlign('center'), 'center');
      expect(adapter.textAlign('left'), 'left');
      expect(adapter.textAlign('right'), 'right');
      expect(adapter.textAlign('start'), 'start');
      expect(identical(adapter.textAlign(undefined), undefined), isTrue);
    });

    test('xPlus adds and leftForLtr returns x', () {
      final adapter = getRtlAdapter(false, 10, 100);
      expect(adapter.xPlus(30, 5), 35);
      expect(adapter.leftForLtr(30, 5), 30);
    });
  });
}
