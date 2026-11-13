// Original code, not ported from Chart.js: the scale option border.
@TestOn('vm')
library;

import 'dart:ui' show Color;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart' show createMockContext;
import 'package:flutter_chartjs_port/src/core/core.config.dart'
    show themeConfigKey;
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableScaleContext;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show ScaleOptionsScope;
import 'package:flutter_chartjs_port/src/theme/compile.dart'
    show compileChartTheme;
import 'package:flutter_chartjs_port/src/types/axis_border.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_test/flutter_test.dart';

// The scale option border holds one ScaleBorder (Chart.js ADR 0141, row
// adapt-native-scale-border): the scopes merge it field by field, a
// cartesian scale reads the default borderColor for an absent color (the
// value of the upstream route `scale.border.color`), and the radial scale
// has its own RadialAxisBorder.

const Color _red = Color(0xFFFF0000);
const Color _blue = Color(0xFF0000FF);

/// The default borderColor of core.defaults.js:42.
const Color _defaultBorderColor = Color.fromRGBO(0, 0, 0, 0.1);

/// A line chart with the x scale [x] and the theme [theme].
Chart _cartesian(Map<String, Object?> x, {Object? theme}) =>
    acquireChart(<String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'labels': <Object?>['a', 'b', 'c', 'd'],
        'datasets': <Object?>[
          <String, Object?>{
            'data': <Object?>[1, 2, 3, 4],
          },
        ],
      },
      'options': <String, Object?>{
        'scales': <String, Object?>{
          'x': <String, Object?>{'type': 'category', ...x},
        },
      },
      themeConfigKey: ?theme,
    });

/// The calls of the canvas of the x scale of [chart] in one draw.
List<Map<String, Object?>> _xCalls(Chart chart) {
  final ctx = createMockContext();
  chart.scales['x']!.ctx = ctx;
  chart.draw();
  return ctx.getCalls();
}

/// The first argument of each call [name] of [calls].
List<Object?> _args(List<Map<String, Object?>> calls, String name) => [
  for (final call in calls)
    if (call['name'] == name) (call['args']! as List<Object?>).first,
];

void main() {
  group('a cartesian scale', () {
    testWidgets('an absent color draws the default borderColor', (
      tester,
    ) async {
      // The grid draws no line: the only stroke of the x scale is the border.
      final chart = _cartesian(<String, Object?>{
        'grid': <String, Object?>{'display': false},
      });
      expect(
        chart.scales['x']!.options.border,
        const AxisBorder(display: true, dash: [], dashOffset: 0, width: 1),
      );
      expect(_args(_xCalls(chart), 'setStrokeStyle'), [_defaultBorderColor]);

      // A new default borderColor reaches the border at the next update, as
      // the route of upstream does.
      defaults.borderColor = const ChartPaint.solid(_red);
      chart.update();
      expect(_args(_xCalls(chart), 'setStrokeStyle'), [_red]);
    });

    testWidgets('the theme gives the border color', (tester) async {
      final chart = _cartesian(<String, Object?>{
        'grid': <String, Object?>{'display': false},
      }, theme: compileChartTheme(borderColor: _blue));
      expect(
        chart.scales['x']!.options.border,
        const AxisBorder(
          display: true,
          color: ChartPaint.solid(_blue),
          dash: [],
          dashOffset: 0,
          width: 1,
        ),
      );
      expect(_args(_xCalls(chart), 'setStrokeStyle'), [_blue]);
    });

    testWidgets('a user border merges with the defaults field by field', (
      tester,
    ) async {
      final chart = _cartesian(<String, Object?>{
        'grid': <String, Object?>{'display': false},
        'border': const AxisBorder(width: 3, color: ChartPaint.solid(_red)),
      }, theme: compileChartTheme(borderColor: _blue));
      expect(
        chart.scales['x']!.options.border,
        const AxisBorder(
          display: true,
          color: ChartPaint.solid(_red),
          dash: [],
          dashOffset: 0,
          width: 3,
        ),
      );
      final calls = _xCalls(chart);
      expect(_args(calls, 'setLineWidth'), [3]);
      expect(_args(calls, 'setStrokeStyle'), [_red]);
    });

    testWidgets('display false and width 0 draw no axis line', (tester) async {
      for (final border in const [
        AxisBorder(display: false),
        AxisBorder(width: 0),
      ]) {
        final chart = _cartesian(<String, Object?>{
          'grid': <String, Object?>{'display': false},
          'border': border,
        });
        expect(_args(_xCalls(chart), 'stroke'), isEmpty, reason: '$border');
      }
    });

    testWidgets('a border function gets the scale and each tick context', (
      tester,
    ) async {
      final indexes = <Object?>[];
      AxisBorder border(ScriptableScaleContext context) {
        indexes.add(context.index);
        return AxisBorder(
          dash: jsToNumber(context.index).remainder(2) == 0
              ? const <double>[6, 3]
              : const <double>[],
        );
      }

      // No tick mark: each dash of the x scale is the dash of a grid line.
      final chart = _cartesian(<String, Object?>{
        'border': border,
        'grid': <String, Object?>{'drawTicks': false},
      });
      // The first draw computes the grid line items (core.scale.js:1460):
      // the ticks a, b, c and d. The grid line of each tick takes the dash
      // of its context.
      final calls = _xCalls(chart);
      expect(indexes.whereType<int>().toSet(), {0, 1, 2, 3});
      final dashes = _args(calls, 'setLineDash');
      expect(dashes.take(4), [
        [6, 3],
        <double>[],
        [6, 3],
        <double>[],
      ]);
    });
  });

  group('the radial linear scale', () {
    Chart radar(Map<String, Object?> r, {Object? theme}) =>
        acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'labels': <Object?>['a', 'b', 'c'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 2, 3],
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{'r': r},
          },
          themeConfigKey: ?theme,
        });

    testWidgets('never gets the AxisBorder of the defaults or the theme', (
      tester,
    ) async {
      const radialDefault = RadialAxisBorder(dash: [], dashOffset: 0);
      expect(
        radar(<String, Object?>{}).scales['r']!.options.border,
        radialDefault,
      );
      expect(
        radar(
          <String, Object?>{},
          theme: compileChartTheme(borderColor: _blue),
        ).scales['r']!.options.border,
        radialDefault,
      );
      // An AxisBorder in `defaults.scale` stays out of the radial scale.
      (defaults.lookup(OptionKey.scale)!.raw! as ScaleOptionsScope).border =
          const AxisBorder(width: 7);
      expect(
        radar(<String, Object?>{}).scales['r']!.options.border,
        radialDefault,
      );
    });

    testWidgets('a user border merges with the radial defaults', (
      tester,
    ) async {
      final chart = radar(<String, Object?>{
        'border': const RadialAxisBorder(dash: [4, 2]),
      });
      expect(
        chart.scales['r']!.options.border,
        const RadialAxisBorder(dash: [4, 2], dashOffset: 0),
      );
    });
  });
}
