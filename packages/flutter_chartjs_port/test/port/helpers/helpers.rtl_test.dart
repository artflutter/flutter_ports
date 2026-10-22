// Original code, not ported from Chart.js: helpers.rtl cases with no spec.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.rtl.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:test/test.dart';

// Upstream has no spec for helpers.rtl.ts (AGENTS.md rule 3). The expected
// values come from src/helpers/helpers.rtl.ts at v4.5.1, run with type
// stripping in Node.js v24.12.0 on x64. The text direction cases follow the
// DOM rules of CSSStyleDeclaration.setProperty, which [_Style] models.

/// A map-backed `CSSStyleDeclaration` with the DOM rules of `setProperty`:
/// a priority other than `''` and `'important'` does nothing, a `direction`
/// value that does not parse does nothing, and an empty value removes the
/// property. It records the arguments of each `setProperty` call.
final class _Style implements CSSStyleDeclaration {
  final Map<String, (String, String)> _properties = {};

  final List<List<String?>> calls = [];

  static const _directions = {
    'ltr',
    'rtl',
    'inherit',
    'initial',
    'unset',
    'revert',
    'revert-layer',
  };

  @override
  String getPropertyValue(String property) => _properties[property]?.$1 ?? '';

  @override
  String getPropertyPriority(String property) =>
      _properties[property]?.$2 ?? '';

  @override
  void setProperty(String property, String? value, [String? priority]) {
    calls.add([property, value, priority]);
    final important = priority?.toLowerCase() == 'important';
    if (priority != null && priority.isNotEmpty && !important) return;
    if (value == null || value.isEmpty) {
      _properties.remove(property);
      return;
    }
    if (property == 'direction' && !_directions.contains(value)) return;
    _properties[property] = (value, important ? 'important' : '');
  }
}

/// A canvas element that has only a style.
final class _Canvas implements HTMLCanvasElement {
  @override
  final _Style style = _Style();

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A mock context with a canvas.
final class _Context extends MockContext {
  @override
  final _Canvas canvas = _Canvas();

  _Style get style => canvas.style;
}

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

  group('overrideTextDirection', () {
    test("sets the direction with priority 'important'", () {
      final ctx = _Context();
      overrideTextDirection(ctx, 'rtl');
      expect(ctx.style.getPropertyValue('direction'), 'rtl');
      expect(ctx.style.getPropertyPriority('direction'), 'important');
      expect(prevTextDirectionOf(ctx), ['', '']);
    });

    test('keeps the previous value and priority', () {
      final ctx = _Context();
      ctx.style.setProperty('direction', 'ltr');
      overrideTextDirection(ctx, 'rtl');
      expect(prevTextDirectionOf(ctx), ['ltr', '']);
      overrideTextDirection(ctx, 'ltr');
      expect(prevTextDirectionOf(ctx), ['rtl', 'important']);
    });

    test("does nothing for a value other than 'ltr' and 'rtl'", () {
      for (final direction in <Object?>[undefined, null, 'auto', 'RTL', 1]) {
        final ctx = _Context();
        overrideTextDirection(ctx, direction);
        expect(ctx.style.calls, isEmpty, reason: '$direction');
        expect(prevTextDirectionOf(ctx), isNull, reason: '$direction');
      }
    });
  });

  group('restoreTextDirection', () {
    test('does nothing for undefined', () {
      final ctx = _Context();
      overrideTextDirection(ctx, 'rtl');
      restoreTextDirection(ctx);
      // The explicit argument undefined, as an absent key gives it.
      // ignore: avoid_redundant_argument_values
      restoreTextDirection(ctx, undefined);
      expect(ctx.style.calls, hasLength(1));
      expect(prevTextDirectionOf(ctx), ['', '']);
    });

    test('puts back the value and priority of overrideTextDirection', () {
      final ctx = _Context();
      ctx.style.setProperty('direction', 'ltr');
      overrideTextDirection(ctx, 'rtl');
      restoreTextDirection(ctx, prevTextDirectionOf(ctx));
      expect(ctx.style.calls.last, ['direction', 'ltr', '']);
      expect(ctx.style.getPropertyValue('direction'), 'ltr');
      expect(ctx.style.getPropertyPriority('direction'), '');
      expect(prevTextDirectionOf(ctx), isNull);
    });

    test('removes a direction that was not set', () {
      final ctx = _Context();
      overrideTextDirection(ctx, 'ltr');
      restoreTextDirection(ctx, const ['', '']);
      expect(ctx.style.getPropertyValue('direction'), '');
    });

    test('keeps the override for the direction String that callers pass', () {
      // plugin.legend.js:437 and plugin.tooltip.js:1087 pass
      // options.textDirection. original[0] and original[1] of 'rtl' are 'r'
      // and 't', and the DOM ignores the priority 't'.
      final ctx = _Context();
      overrideTextDirection(ctx, 'rtl');
      restoreTextDirection(ctx, 'rtl');
      expect(ctx.style.calls.last, ['direction', 'r', 't']);
      expect(ctx.style.getPropertyValue('direction'), 'rtl');
      expect(ctx.style.getPropertyPriority('direction'), 'important');
      expect(prevTextDirectionOf(ctx), isNull);
    });

    test('converts undefined members with ToString', () {
      // ['ltr'][1] is undefined: the priority is the default ''. [][0] is
      // undefined: the value is 'undefined', which does not parse.
      final ctx = _Context();
      restoreTextDirection(ctx, const ['ltr']);
      expect(ctx.style.calls.last, ['direction', 'ltr', '']);
      restoreTextDirection(ctx, const <String>[]);
      expect(ctx.style.calls.last, ['direction', 'undefined', '']);
      expect(ctx.style.getPropertyValue('direction'), 'ltr');
    });

    test('throws for null after it deletes prevTextDirection', () {
      final ctx = _Context();
      overrideTextDirection(ctx, 'rtl');
      expect(() => restoreTextDirection(ctx, null), throwsA(isA<TypeError>()));
      expect(prevTextDirectionOf(ctx), isNull);
    });
  });
}
