// Ported from chartjs-chart-sankey v0.19.1 src/labels.test.ts (MIT, Jukka Kurkela).
@TestOn('vm')
library;

import 'dart:ui' show Color, Offset, TextAlign;

import 'package:flutter_chartjs_chart_sankey_port/src/labels.dart';
import 'package:flutter_chartjs_chart_sankey_port/src/types.dart';
import 'package:flutter_chartjs_port/chartjs.dart'
    show ChartGradient, ChartPaint, ChartTextStyle;
import 'package:test/test.dart';

import '../support/fake_context.dart';

final SankeyNode _node = SankeyNode('A');

const ChartPaint _black = ChartPaint.solid(Color(0xFF000000));
const ChartPaint _red = ChartPaint.solid(Color(0xFFFF0000));

FakeContext _createContext() => FakeContext(20);

DrawLabelOptions _createOptions({
  Object? backgroundColor,
  SankeyLabelPosition position = SankeyLabelPosition.auto,
}) => DrawLabelOptions(
  autoPosition: SankeyLabelPosition.right,
  backgroundColor: backgroundColor,
  borderRadius: 0,
  borderWidth: 1,
  color: _black,
  // `{lineHeight: 10, size: 10, string: '10px Arial'}`.
  font: const ChartTextStyle(fontFamily: 'Arial', fontSize: 10, height: 1),
  height: 20,
  lineOffset: 5,
  padding: 4,
  position: position,
  width: 10,
  x: 20,
  y: 20,
);

void main() {
  group('node labels', () {
    test('resolves static, mapped, and callback options', () {
      final mapped = <String, Object?>{'A': SankeyLabelPosition.right};

      expect(
        resolveNodeOption<SankeyLabelPosition>(SankeyLabelPosition.left, _node),
        SankeyLabelPosition.left,
      );
      expect(
        resolveNodeOption<SankeyLabelPosition>(mapped, _node),
        SankeyLabelPosition.right,
      );
      expect(
        resolveNodeOption<SankeyLabelPosition>(
          (SankeyNode item) => item.key == 'A'
              ? SankeyLabelPosition.top
              : SankeyLabelPosition.bottom,
          _node,
        ),
        SankeyLabelPosition.top,
      );
    });

    test('returns a CanvasGradient-like object as-is instead of indexing '
        'into it', () {
      // A gradient of the host is a `ChartGradient`: an object that is not a
      // Map, so the read by the node key does not apply.
      const gradient = ChartGradient.linear(Offset.zero, Offset(1, 0), [
        Color(0xFFFF0000),
        Color(0xFF008000),
      ]);

      expect(resolveNodeOption<Object>(gradient, _node), same(gradient));
    });

    test('uses the right side for auto-positioned nodes in the left half', () {
      final ctx = _createContext();

      drawLabel(ctx, 'A', _createOptions());

      expect(ctx.textAlign, TextAlign.left);
      expect(ctx.callsOf('fillText'), [
        ['A', 35.0, 30.0, null],
      ]);
    });

    test('draws a padded background behind a centered label', () {
      final ctx = _createContext();

      drawLabel(
        ctx,
        'A',
        _createOptions(
          backgroundColor: _red,
          position: SankeyLabelPosition.center,
        ),
      );

      expect(ctx.callsOf('fillRect'), [
        [11.0, 21.0, 28.0, 18.0],
      ]);
      expect(ctx.callsOf('fillText'), [
        ['A', 25.0, 30.0, null],
      ]);
    });
  });
}
