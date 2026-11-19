// Original code, not ported from Chart.js: the typed plugin option getters.
import 'dart:ui' show TextAlign;

import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:test/test.dart';

/// Options of an add-on with no field `events`.
final class const _NoEvents() extends PluginOptions<_NoEvents> {
  @override
  String get pluginId => 'noEvents';

  @override
  _NoEvents merge(_NoEvents over) => over;
}

// Each getter gives the type of its schema key, with the conversion that its
// readers applied before (Chart.js ADR 0150). A plain Map stands for the
// resolved options: a getter reads it by name, as the facade reads a Map of
// a spec.
void main() {
  group('the typed getters of the plugin option facades', () {
    test('a number of a truthy value, else null', () {
      expect(
        LegendOptions.of(<String, Object?>{'maxWidth': 120.0}).maxWidth,
        120,
      );
      expect(
        LegendOptions.of(<String, Object?>{'maxHeight': '80'}).maxHeight,
        80,
      );
      expect(
        LegendOptions.of(<String, Object?>{'maxWidth': 0.0}).maxWidth,
        isNull,
      );
      expect(LegendOptions.of(<String, Object?>{}).maxHeight, isNull);
      expect(
        LegendLabelOptions.of(<String, Object?>{'pointStyleWidth': 12.0})
            .pointStyleWidth,
        12,
      );
      expect(
        DecimationOptions.of(<String, Object?>{'samples': 50.0}).samples,
        50,
      );
      expect(
        DecimationOptions.of(<String, Object?>{'threshold': 0.0}).threshold,
        isNull,
      );
    });

    test('a number of a defined value, else null', () {
      final labels = LegendLabelOptions.of(<String, Object?>{
        'boxWidth': 30.0,
        'boxHeight': null,
      });
      expect(labels.boxWidth, 30);
      // `ToNumber(null)` is 0: only `undefined` takes the default.
      expect(labels.boxHeight, 0);
      expect(LegendLabelOptions.of(<String, Object?>{}).boxWidth, isNull);
    });

    test('a number', () {
      final options = TooltipOptions.of(<String, Object?>{
        'caretSize': '5',
        'bodySpacing': 2.0,
      });
      expect(options.caretSize, 5);
      expect(options.bodySpacing, 2);
      expect(LegendLabelOptions.of(<String, Object?>{}).padding, isNaN);
    });

    test('the border width of the canvas setter', () {
      expect(TooltipOptions.of(<String, Object?>{}).borderWidth, isNull);
      expect(
        TooltipOptions.of(<String, Object?>{'borderWidth': 2.0}).borderWidth,
        2,
      );
      // JS null is no number: no ToNumber (Chart.js ADR 0174).
      expect(
        TooltipOptions.of(<String, Object?>{'borderWidth': null}).borderWidth,
        isNull,
      );
    });

    test('the lines of a text', () {
      expect(
        TitleOptions.of(<String, Object?>{
          'text': ['a'],
        }).text,
        ['a'],
      );
      expect(
        TitleOptions.of(<String, Object?>{
          'text': ['a', 'b'],
        }).text,
        ['a', 'b'],
      );
      expect(
        LegendTitleOptions.of(<String, Object?>{
          'text': ['a'],
        }).text,
        ['a'],
      );
      expect(
        TitleOptions.of(<String, Object?>{'text': <String>[]}).text,
        isEmpty,
      );
      // A text takes its lines (row adapt-title-text-lines): a String stops
      // a debug build.
      expect(
        () => TitleOptions.of(<String, Object?>{'text': 'a'}).text,
        throwsA(isA<AssertionError>()),
      );
    });

    test('a font, a text align and an enum', () {
      final font = TitleOptions.of(<String, Object?>{
        'font': const ChartTextStyle(fontSize: 20),
      }).font;
      expect(font.fontSize, 20);
      expect(
        TooltipOptions.of(<String, Object?>{'bodyAlign': TextAlign.right})
            .bodyAlign,
        TextAlign.right,
      );
      expect(LegendLabelOptions.of(<String, Object?>{}).textAlign, isNull);
      expect(
        FillerOptions.of(<String, Object?>{
          'drawTime': FillerDrawTime.beforeDraw,
        }).drawTime,
        FillerDrawTime.beforeDraw,
      );
    });

    test('a position', () {
      expect(
        TitleOptions.of(<String, Object?>{'position': ChartPosition.left})
            .position,
        ChartPosition.left,
      );
      expect(
        LegendOptions.of(<String, Object?>{
          'position': const ScaleValuePosition('x', 0.0),
        }).position,
        const ScaleValuePosition('x', 0.0),
      );
      expect(TitleOptions.of(<String, Object?>{}).position, isNull);
    });
  });

  test('the options of an add-on give no events by default', () {
    expect(const _NoEvents().events, isNull);
  });
}
