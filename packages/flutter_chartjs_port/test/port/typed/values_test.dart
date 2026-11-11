// Original code, not ported from Chart.js: tests of the typed value types.
@TestOn('vm')
library;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0052, section 7: the constants and the option value of each
// value type of lib/src/typed/values.dart, `==` of equal values and the dot
// shorthands. An interaction mode is an `InteractionMode` object of the core.
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
        [
          'top',
          'left',
          'bottom',
          'right',
          'center',
          'chartArea',
        ],
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

  group('ChartPointStyle', () {
    test('the 10 names of PointStyle and none', () {
      const styles = <ChartPointStyle>[
        .circle,
        .cross,
        .crossRot,
        .dash,
        .line,
        .rect,
        .rectRounded,
        .rectRot,
        .star,
        .triangle,
        .none,
      ];
      expect(
        [for (final s in styles) s.optionValue],
        [
          'circle',
          'cross',
          'crossRot',
          'dash',
          'line',
          'rect',
          'rectRounded',
          'rectRot',
          'star',
          'triangle',
          false,
        ],
      );
    });
  });

  group('ChartFill', () {
    test('the names and none', () {
      const fills = <ChartFill>[.origin, .start, .end, .stack, .shape, .none];
      expect(
        [for (final f in fills) f.optionValue],
        [
          'origin',
          'start',
          'end',
          'stack',
          'shape',
          false,
        ],
      );
    });

    test('an absolute dataset index is the number', () {
      expect(const ChartFill.dataset(0).optionValue, 0);
      expect(const ChartFill.dataset(2).optionValue, 2);
    });

    test('a relative index is a signed string', () {
      expect(const ChartFill.relative(1).optionValue, '+1');
      expect(const ChartFill.relative(-1).optionValue, '-1');
      expect(const ChartFill.relative(-12).optionValue, '-12');
    });

    test('a value is a new Map {value: n} at each read', () {
      const fill = ChartFill.value(25);
      final first = fill.optionValue;
      expect(first, <String, Object?>{'value': 25});
      expect(first, isA<Map<String, Object?>>());
      expect(fill.optionValue, isNot(same(first)));
    });

    test('equal fills are ==, others are not', () {
      final value = ChartFill.value(_runtime(25));
      expect(value, const ChartFill.value(25));
      expect(value.hashCode, const ChartFill.value(25).hashCode);
      expect(value, isNot(const ChartFill.value(26)));
      expect(ChartFill.relative(_runtime(1)), const ChartFill.relative(1));
      expect(
        ChartFill.dataset(_runtime(1)),
        isNot(const ChartFill.relative(1)),
      );
    });
  });

  group('ChartLength', () {
    test('pixels give the number', () {
      expect(const ChartLength.pixels(0).optionValue, 0);
      expect(const ChartLength.pixels(12.5).optionValue, 12.5);
    });

    test('a percent gives the JS form of the number with %', () {
      expect(const ChartLength.percent(50).optionValue, '50%');
      expect(const ChartLength.percent(12.5).optionValue, '12.5%');
      expect(const ChartLength.percent(100).optionValue, '100%');
    });

    test('equal lengths are ==, a percent is not a pixel count', () {
      final percent = ChartLength.percent(_runtime(50));
      expect(percent, const ChartLength.percent(50));
      expect(percent.hashCode, const ChartLength.percent(50).hashCode);
      expect(ChartLength.pixels(_runtime(50)), const ChartLength.pixels(50));
      expect(percent, isNot(const ChartLength.pixels(50)));
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
      expect(units, [
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

    test('a unit is its String, also a custom unit', () {
      const String day = TimeUnit.day;
      expect(day, 'day');
      expect(const TimeUnit('fortnight').name, 'fortnight');
      expect(TimeUnit(_runtime('day')), TimeUnit.day);
    });
  });
}
