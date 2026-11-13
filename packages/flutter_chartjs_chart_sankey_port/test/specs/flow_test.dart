// Ported from chartjs-chart-sankey v0.19.1 src/flow.test.ts (MIT, Jukka Kurkela).
@TestOn('vm')
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_chart_sankey_port/src/flow.dart';
import 'package:flutter_chartjs_chart_sankey_port/src/types.dart';
import 'package:flutter_chartjs_port/chartjs.dart'
    show ChartPaint, ElementPoint;
import 'package:flutter_chartjs_port/js_semantics.dart' show jsGet;
import 'package:test/test.dart';

import '../support/fake_context.dart';

const ChartPaint _black = ChartPaint.solid(Color(0xFF000000));
const ChartPaint _white = ChartPaint.solid(Color(0xFFFFFFFF));
const ChartPaint _red = ChartPaint.solid(Color(0xFFFF0000));
const ChartPaint _green = ChartPaint.solid(Color(0xFF008000));

/// `'#123456'`.
const Color _color123456 = Color(0xFF123456);

FakeContext _createContext() => FakeContext(14);

Map<String, Object?> _createOptions([ChartPaint? flowColor]) =>
    <String, Object?>{
      'alpha': 0.5,
      'colorFrom': _red,
      'colorMode': SankeyColorMode.gradient,
      'colorTo': _green,
      'flowColor': flowColor,
      'flowLabels': <String, Object?>{
        'borderRadius': 0.0,
        'color': _black,
        'display': false,
        'padding': 4.0,
        'position': SankeyLabelPosition.center,
      },
      'hoverColorFrom': _red,
      'hoverColorTo': _green,
      'orientation': SankeyOrientation.horizontal,
    };

void main() {
  group('Flow', () {
    test('uses flowColor independently from its node colors', () {
      final context = _createContext();
      final flow = Flow(<String, Object?>{
        'flow': 5,
        'height': 10,
        'options': _createOptions(const ChartPaint.solid(_color123456)),
        'x': 0,
        'x2': 100,
        'y': 0,
        'y2': 10,
      })..draw(context);

      // The mock context holds the color of a solid paint.
      expect(context.fillStyle, _color123456);
      expect(context.strokeStyle, _color123456);
      expect(jsGet(flow.options, 'colorFrom'), _red);
      expect(jsGet(flow.options, 'colorTo'), _green);
    });

    test('draws the flow value using the configured label options', () {
      final context = _createContext();
      final options = _createOptions(_red);
      options['flowLabels'] = <String, Object?>{
        'backgroundColor': _white,
        'borderRadius': 0.0,
        'color': _black,
        'display': true,
        'padding': 4.0,
        'position': SankeyLabelPosition.center,
      };
      Flow(<String, Object?>{
        'flow': 5,
        'height': 10,
        'options': options,
        'x': 0,
        'x2': 100,
        'y': 0,
        'y2': 10,
      }).draw(context);

      expect(context.callsOf('fillText'), [
        ['5', 50.0, 10.0, null],
      ]);
      expect(context.callsOf('fillRect'), isNotEmpty);
    });

    test('draws and interacts with a vertical flow', () {
      final context = _createContext();
      final options = _createOptions(const ChartPaint.solid(_color123456));
      options['orientation'] = SankeyOrientation.vertical;
      final flow = Flow(<String, Object?>{
        'flow': 5,
        'height': 0,
        'options': options,
        'width': 8,
        'x': 10,
        'x2': 30,
        'y': 20,
        'y2': 120,
      })..draw(context);

      expect(context.callsOf('moveTo'), contains(equals([10.0, 20.0])));
      expect(context.callsOf('lineTo'), contains(equals([38.0, 120.0])));
      expect(flow.inRange(24, 70, false), isTrue);
      expect(flow.inRange(35, 70, false), isFalse);
      expect(flow.getCenterPoint(false), const ElementPoint(24, 70));
    });
  });
}
