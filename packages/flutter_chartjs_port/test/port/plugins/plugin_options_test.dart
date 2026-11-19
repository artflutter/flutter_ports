// Original code, not ported from Chart.js: the typed plugin option getters.
import 'dart:ui' show TextAlign;

import 'package:flutter_chartjs_port/src/plugins/filler_draw_time.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin_options.dart';
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
import 'package:flutter_chartjs_port/src/types/layout.dart';
import 'package:flutter_chartjs_port/src/types/plugin.dart';
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
        const LegendOptions(<String, Object?>{'maxWidth': 120.0}).maxWidth,
        120,
      );
      expect(
        const LegendOptions(<String, Object?>{'maxHeight': '80'}).maxHeight,
        80,
      );
      expect(
        const LegendOptions(<String, Object?>{'maxWidth': 0.0}).maxWidth,
        isNull,
      );
      expect(const LegendOptions(<String, Object?>{}).maxHeight, isNull);
      expect(
        const LegendLabelOptions(<String, Object?>{'pointStyleWidth': 12.0})
            .pointStyleWidth,
        12,
      );
      expect(
        const DecimationOptions(<String, Object?>{'samples': 50.0}).samples,
        50,
      );
      expect(
        const DecimationOptions(<String, Object?>{'threshold': 0.0}).threshold,
        isNull,
      );
    });

    test('a number of a defined value, else null', () {
      const labels = LegendLabelOptions(<String, Object?>{
        'boxWidth': 30.0,
        'boxHeight': null,
      });
      expect(labels.boxWidth, 30);
      // `ToNumber(null)` is 0: only `undefined` takes the default.
      expect(labels.boxHeight, 0);
      expect(const LegendLabelOptions(<String, Object?>{}).boxWidth, isNull);
    });

    test('a number', () {
      const options = TooltipOptions(<String, Object?>{
        'caretSize': '5',
        'bodySpacing': 2.0,
      });
      expect(options.caretSize, 5);
      expect(options.bodySpacing, 2);
      expect(const LegendLabelOptions(<String, Object?>{}).padding, isNaN);
    });

    test('the border width of the canvas setter', () {
      expect(const TooltipOptions(<String, Object?>{}).borderWidth, isNull);
      expect(
        const TooltipOptions(<String, Object?>{'borderWidth': 2.0}).borderWidth,
        2,
      );
      // JS null is no number: no ToNumber (Chart.js ADR 0174).
      expect(
        const TooltipOptions(<String, Object?>{'borderWidth': null})
            .borderWidth,
        isNull,
      );
    });

    test('the lines of a text', () {
      expect(
        const TitleOptions(<String, Object?>{
          'text': ['a'],
        }).text,
        ['a'],
      );
      expect(
        const TitleOptions(<String, Object?>{
          'text': ['a', 'b'],
        }).text,
        ['a', 'b'],
      );
      expect(
        const LegendTitleOptions(<String, Object?>{
          'text': ['a'],
        }).text,
        ['a'],
      );
      expect(
        const TitleOptions(<String, Object?>{'text': <String>[]}).text,
        isEmpty,
      );
      // A text takes its lines (row adapt-title-text-lines): a String stops
      // a debug build.
      expect(
        () => const TitleOptions(<String, Object?>{'text': 'a'}).text,
        throwsA(isA<AssertionError>()),
      );
    });

    test('a font, a text align and an enum', () {
      final font = const TitleOptions(<String, Object?>{
        'font': ChartTextStyle(fontSize: 20),
      }).font;
      expect(font.fontSize, 20);
      expect(
        const TooltipOptions(<String, Object?>{'bodyAlign': TextAlign.right})
            .bodyAlign,
        TextAlign.right,
      );
      expect(const LegendLabelOptions(<String, Object?>{}).textAlign, isNull);
      expect(
        const FillerOptions(<String, Object?>{
          'drawTime': FillerDrawTime.beforeDraw,
        }).drawTime,
        FillerDrawTime.beforeDraw,
      );
    });

    test('a position', () {
      expect(
        const TitleOptions(<String, Object?>{'position': ChartPosition.left})
            .position,
        ChartPosition.left,
      );
      expect(
        const LegendOptions(<String, Object?>{
          'position': ScaleValuePosition('x', 0.0),
        }).position,
        const ScaleValuePosition('x', 0.0),
      );
      expect(const TitleOptions(<String, Object?>{}).position, isNull);
    });
  });

  test('the options of an add-on give no events by default', () {
    expect(const _NoEvents().events, isNull);
  });
}
