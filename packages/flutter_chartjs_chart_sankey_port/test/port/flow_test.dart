// Original code, not ported from chartjs-chart-sankey: the shared gradients.
@TestOn('vm')
library;

import 'dart:ui' show Color, Offset;

import 'package:flutter_chartjs_chart_sankey_port/src/flow.dart';
import 'package:flutter_chartjs_chart_sankey_port/src/types.dart';
import 'package:flutter_chartjs_port/chartjs.dart'
    show ChartPaint, LinearChartGradient;
import 'package:test/test.dart';

import '../support/fake_context.dart';

const Color _red = Color(0xFFFF0000);
const Color _green = Color(0xFF008000);

Map<String, Object?> _options({
  Color from = _red,
  double alpha = 0.5,
  SankeyOrientation orientation = SankeyOrientation.horizontal,
}) => <String, Object?>{
  'alpha': alpha,
  'colorFrom': ChartPaint.solid(from),
  'colorMode': SankeyColorMode.gradient,
  'colorTo': const ChartPaint.solid(_green),
  'flowColor': null,
  'flowLabels': <String, Object?>{'display': false},
  'orientation': orientation,
};

/// The fill of a flow from ([x], [y]) to ([x2], [y2]) after its draw.
Object _fillOf(
  Map<String, Object?> options, {
  double x = 10,
  double x2 = 110,
  double y = 0,
  double y2 = 40,
}) {
  final context = FakeContext(14);
  Flow(<String, Object?>{
    'flow': 5,
    'height': 10,
    'options': options,
    'width': 10,
    'x': x,
    'x2': x2,
    'y': y,
    'y2': y2,
  }).draw(context);
  expect(context.strokeStyle, same(context.fillStyle));
  return context.fillStyle!;
}

void main() {
  // Row adapt-sankey-shared-gradients of doc/differences.md.
  group('the gradient of a flow', () {
    test('has the ends and the colors of the flow', () {
      final fill = _fillOf(_options()) as LinearChartGradient;

      expect(fill.from, const Offset(10, 0));
      expect(fill.to, const Offset(110, 0));
      expect(fill.colors, [
        _red.withValues(alpha: 0.5),
        _green.withValues(alpha: 0.5),
      ]);
      expect(fill.stops, isNull);
    });

    test('is one object for the flows with equal ends and colors', () {
      // The flows between two columns differ only in y.
      final first = _fillOf(_options());
      final second = _fillOf(_options(), y: 60, y2: 5);

      expect(second, same(first));
    });

    test('is another object for other ends, colors or alpha', () {
      final first = _fillOf(_options());

      expect(_fillOf(_options(), x2: 210), isNot(same(first)));
      expect(_fillOf(_options(), x: 20), isNot(same(first)));
      expect(_fillOf(_options(alpha: 0.25)), isNot(same(first)));
      expect(
        _fillOf(_options(from: const Color(0xFF0000FF))),
        isNot(same(first)),
      );
    });

    test('follows y for a vertical flow', () {
      final options = _options(orientation: SankeyOrientation.vertical);
      final fill = _fillOf(options) as LinearChartGradient;

      expect(fill.from, Offset.zero);
      expect(fill.to, const Offset(0, 40));
      // A horizontal flow with the same numbers has another gradient.
      expect(_fillOf(_options(), x: 0, x2: 40), isNot(same(_fillOf(options))));
      expect(_fillOf(options, x: 70, x2: 5), same(fill));
    });

    test('stays right after more gradients than the cache holds', () {
      for (var i = 0; i < 600; i++) {
        final fill = _fillOf(_options(), x2: 1000.0 + i) as LinearChartGradient;
        expect(fill.to, Offset(1000.0 + i, 0));
      }
      final fill = _fillOf(_options()) as LinearChartGradient;
      expect(fill.to, const Offset(110, 0));
    });

    test('has colors that no caller can change', () {
      final fill = _fillOf(_options()) as LinearChartGradient;

      expect(() => fill.colors[0] = _green, throwsUnsupportedError);
    });
  });
}
