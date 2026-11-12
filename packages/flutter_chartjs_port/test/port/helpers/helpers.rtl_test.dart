// Original code, not ported from Chart.js: helpers.rtl cases with no spec.
import 'dart:ui' show TextAlign, TextDirection;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.rtl.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/opt.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin_options.dart';
import 'package:test/test.dart';

// The adapter cases follow pinned upstream. Native direction restoration
// is the intentional fix of Chart.js ADR 0124 and upstream PR #12371.

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
      expect(adapter.textAlign(TextAlign.center), TextAlign.center);
      expect(adapter.textAlign(TextAlign.left), TextAlign.right);
      expect(adapter.textAlign(TextAlign.right), TextAlign.left);
      // A value other than center and right gives right. Dart null stands
      // for the undefined of a legend item without an align.
      expect(adapter.textAlign(TextAlign.start), TextAlign.right);
      expect(adapter.textAlign(TextAlign.end), TextAlign.right);
      expect(adapter.textAlign(null), TextAlign.right);
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
      expect(adapter.textAlign(TextAlign.center), TextAlign.center);
      expect(adapter.textAlign(TextAlign.left), TextAlign.left);
      expect(adapter.textAlign(TextAlign.right), TextAlign.right);
      expect(adapter.textAlign(TextAlign.start), TextAlign.start);
      expect(adapter.textAlign(null), isNull);
    });

    test('xPlus adds and leftForLtr returns x', () {
      final adapter = getRtlAdapter(false, 10, 100);
      expect(adapter.xPlus(30, 5), 35);
      expect(adapter.leftForLtr(30, 5), 30);
    });
  });

  group('native direction options', () {
    test('typed scopes and raw options retain the native enum', () {
      final legend = LegendOptionsScope()..textDirection = TextDirection.rtl;
      final tooltip = TooltipOptionsScope()..textDirection = TextDirection.ltr;
      expect(legend.textDirectionCell, isA<OptValue<TextDirection>>());
      expect(legend.readKey(OptionKey.textDirection), TextDirection.rtl);
      expect(LegendOptions(legend).textDirection, TextDirection.rtl);
      expect(TooltipOptions(tooltip).textDirection, TextDirection.ltr);
      expect(
        const LegendOptions({'textDirection': TextDirection.rtl}).textDirection,
        TextDirection.rtl,
      );
      expect(const LegendOptions({}).textDirection, isNull);
      expect(
        const TooltipOptions({'textDirection': null}).textDirection,
        isNull,
      );
    });

    test('a scriptable direction resolves at its context', () {
      final resolver = createResolver([
        {
          'textDirection': (Map<String, Object?> ctx, Object? _) =>
              ctx['rtl'] == true ? TextDirection.rtl : TextDirection.ltr,
        },
      ]);
      expect(
        LegendOptions(attachContext(resolver, {'rtl': true})).textDirection,
        TextDirection.rtl,
      );
      expect(
        LegendOptions(attachContext(resolver, {'rtl': false})).textDirection,
        TextDirection.ltr,
      );
    });

    test('old keywords and non-direction values stop a debug build', () {
      for (final value in <Object>['rtl', 'ltr', 'inherit', true, 1]) {
        expect(
          () => textDirectionOption(value),
          throwsA(isA<AssertionError>()),
        );
      }
    });
  });

  group('native text direction', () {
    test('an override returns and restores the previous direction', () {
      final ctx = createMockContext()..direction = TextDirection.ltr;
      final original = overrideTextDirection(ctx, TextDirection.rtl);
      expect(original, TextDirection.ltr);
      expect(ctx.direction, TextDirection.rtl);
      restoreTextDirection(ctx, original);
      expect(ctx.direction, TextDirection.ltr);
    });

    test('restores inheritance and keeps nested overrides independent', () {
      final ctx = createMockContext();
      final outer = overrideTextDirection(ctx, TextDirection.rtl);
      final inner = overrideTextDirection(ctx, TextDirection.ltr);
      restoreTextDirection(ctx, inner);
      expect(ctx.direction, TextDirection.rtl);
      restoreTextDirection(ctx, outer);
      expect(ctx.direction, isNull);
    });

    test('an absent override keeps the native direction', () {
      for (final initial in <TextDirection?>[null, ...TextDirection.values]) {
        final ctx = createMockContext()..direction = initial;
        final original = overrideTextDirection(ctx, null);
        expect(ctx.direction, initial);
        restoreTextDirection(ctx, original);
        expect(ctx.direction, initial);
      }
    });
  });
}
