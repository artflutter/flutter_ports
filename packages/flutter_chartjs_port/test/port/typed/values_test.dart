// Original code, not ported from Chart.js: tests of the typed value types.
@TestOn('vm')
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0052, section 7: the constants of the value types of the core
// in the typed API, `==` of equal values and the dot shorthands. An
// interaction mode is an `InteractionMode` object of the core, and a fill a
// `FillTarget` (Chart.js ADR 0140).
//
// VM only: the test imports the app library, which imports dart:ui.

/// [value], as a value that is not a constant.
T _runtime<T>(T value) => value;

void main() {
  group('ChartPosition', () {
    test('the six positions of LayoutPosition', () {
      const positions = <ChartPosition>[
        .top,
        .left,
        .bottom,
        .right,
        .center,
        .chartArea,
      ];
      expect(
        [for (final p in positions) p.name],
        ['top', 'left', 'bottom', 'right', 'center', 'chartArea'],
      );
    });
  });

  group('ChartAlign', () {
    test('the three values of Align', () {
      const aligns = <ChartAlign>[.start, .center, .end];
      expect([for (final a in aligns) a.name], ['start', 'center', 'end']);
    });
  });

  group('InteractionMode', () {
    test('the dot shorthands give the mode objects of the core', () {
      const interaction = ChartInteraction(mode: IndexInteractionMode());
      const tooltip = ChartTooltip(mode: DatasetInteractionMode());
      expect(interaction.mode, same(const IndexInteractionMode()));
      expect(tooltip.mode, same(const DatasetInteractionMode()));
      expect(
        const ChartInteraction(mode: XInteractionMode()),
        const ChartInteraction(mode: XInteractionMode()),
      );
      expect(
        const ChartInteraction(mode: XInteractionMode()),
        isNot(const ChartInteraction(mode: YInteractionMode())),
      );
    });
  });

  group('FillTarget', () {
    // Chart.js ADR 0140: each value of `fill` is a FillTarget, and the dot
    // shorthands give the members.
    test('the members give the forms of the option', () {
      const fills = <FillTarget>[
        .none,
        .toOrigin,
        .toStart,
        .toEnd,
        .toStacked,
        .shape,
        .toPrevious,
        .toNext,
      ];
      expect(fills.map((f) => f.runtimeType), [
        NoFill,
        OriginFill,
        StartFill,
        EndFill,
        StackFill,
        ShapeFill,
        RelativeFill,
        RelativeFill,
      ]);
      expect(FillTarget.toPrevious, FillTarget.toRelative(_runtime(-1)));
      expect(FillTarget.toNext, FillTarget.toRelative(_runtime(1)));
      expect(const FillTarget.toDataset(2), const DatasetFill(2));
      expect(const FillTarget.toValue(25), const ValueFill(25));
    });

    test('equal fills are ==, others are not', () {
      final value = FillTarget.toValue(_runtime(25));
      expect(value, const FillTarget.toValue(25));
      expect(value.hashCode, const FillTarget.toValue(25).hashCode);
      expect(value, isNot(const FillTarget.toValue(26)));
      expect(FillTarget.toRelative(_runtime(1)), FillTarget.toNext);
      expect(FillTarget.toDataset(_runtime(1)), isNot(FillTarget.toNext));
    });

    test('a split keeps its target and its colors', () {
      const red = ChartPaint.solid(Color(0xFFFF0000));
      final split = FillTarget.toOrigin.split(above: red);
      expect(split, isA<SplitFill>());
      split as SplitFill;
      expect(split.target, FillTarget.toOrigin);
      expect(split.above, red);
      expect(split.below, isNull);
      expect(split, FillTarget.toOrigin.split(above: red));
      // A split of a split keeps the target: it never holds a split.
      final again = split.split(below: red) as SplitFill;
      expect(again.target, FillTarget.toOrigin);
      expect(again.above, isNull);
      expect(again.below, red);
    });
  });

  group('TimeUnit', () {
    // core.adapters.ts:10: the 9 units of the union, in its order.
    test('the constants name the 9 units of the union', () {
      const units = <TimeUnit>[
        .millisecond,
        .second,
        .minute,
        .hour,
        .day,
        .week,
        .month,
        .quarter,
        .year,
      ];
      expect(units.map((unit) => unit.name), [
        'millisecond',
        'second',
        'minute',
        'hour',
        'day',
        'week',
        'month',
        'quarter',
        'year',
      ]);
    });
  });
}
