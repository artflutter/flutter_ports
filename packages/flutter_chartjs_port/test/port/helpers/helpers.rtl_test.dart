// Original code, not ported from Chart.js: helpers.rtl cases with no spec.
import 'dart:ui' show TextAlign, TextDirection;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:test/test.dart';

// The adapter cases follow pinned upstream. Native direction restoration
// is the intentional fix of Chart.js ADR 0124 and upstream PR #12371.

void main() {
  group('getRtlAdapter', () {
    test('returns the right-to-left adapter for rtl true', () {
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
    test('typed scopes, options objects and raw options retain the native '
        'enum', () {
      // The legend and the tooltip options are one object each (Chart.js
      // ADRs 0192 and 0193): the merge of the scopes keeps the enum of the
      // last scope that sets it.
      const legend = LegendOptions(textDirection: TextDirection.rtl);
      expect(legend.textDirection, TextDirection.rtl);
      expect(
        legend.merge(const LegendOptions()).textDirection,
        TextDirection.rtl,
      );
      expect(
        legend
            .merge(const LegendOptions(textDirection: TextDirection.ltr))
            .textDirection,
        TextDirection.ltr,
      );
      expect(const LegendOptions().textDirection, isNull);
      const tooltip = TooltipOptions(textDirection: TextDirection.ltr);
      expect(tooltip.textDirection, TextDirection.ltr);
      expect(
        tooltip.merge(const TooltipOptions()).textDirection,
        TextDirection.ltr,
      );
      expect(
        tooltip
            .merge(const TooltipOptions(textDirection: TextDirection.rtl))
            .textDirection,
        TextDirection.rtl,
      );
      expect(const TooltipOptions().textDirection, isNull);
      // Maps: the subject is the raw option value of a read.
      expect(textDirectionOption(TextDirection.rtl), TextDirection.rtl);
      expect(textDirectionOption(undefined), isNull);
    });

    test('a scriptable direction resolves at its context', () {
      // A Map: the subject is a scriptable option of a raw resolver.
      final resolver = createResolver([
        {
          'textDirection': (Object? ctx, Object? _) =>
              (ctx! as Map<String, Object?>)['rtl'] == true
              ? TextDirection.rtl
              : TextDirection.ltr,
        },
      ]);
      Object? direction(Map<String, Object?> context) => textDirectionOption(
        jsGet(attachContext(resolver, context), 'textDirection'),
      );
      expect(direction({'rtl': true}), TextDirection.rtl);
      expect(direction({'rtl': false}), TextDirection.ltr);
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
