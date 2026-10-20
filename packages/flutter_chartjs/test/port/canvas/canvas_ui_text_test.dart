// Original code, not ported from Chart.js: tests of the canvas text.
@TestOn('vm')
library;

// flutter_test and dart:ui: the web legs cannot compile this file.
import 'dart:ui' as ui;

import 'package:flutter_chartjs/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs/src/canvas/canvas_ui_text.dart';
import 'package:flutter_test/flutter_test.dart';

// The font weights of the canvas layer (Chart.js ADR 0015, section 1).
// flutter_test_config.dart installs Liberation Sans 2.1.5, a family with two
// upright faces: regular (400) and bold (700).
//
// The reference is Chromium 155.0.8059.79 on Debian 12 (headless, arm64, in
// Docker) with the system fonts of fonts-liberation2 2.1.5 and fontconfig
// 2.14.1. This is the platform of the upstream specs: Chrome on Linux with
// system fonts. There, fontconfig selects the face with the nearest weight.
// Chromium gave the regular face for the weights 1 to 549.99 and the bold
// face for 550 to 1000.
//
// The CSS font matching rule of `@font-face` fonts is different: for a
// weight above 500, it looks at the heavier faces first. With the same files
// as `@font-face` fonts, the same Chromium gave the bold face for 501 to 549.
// The upstream specs load no `@font-face` fonts. Thus the canvas layer does
// not follow that rule.

/// The probe text.
const String _text = 'January February WWW iii 0123456789';

/// The width of [_text] at 100px in the regular face, in Chromium.
const double _regular = 1772.998046875;

/// The width of [_text] at 100px in the bold face, in Chromium.
const double _bold = 1845.263671875;

/// The Chart.js default family list (`core.defaults.js:55`).
const String _family = "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif";

/// The width of [_text] in [font] on the canvas layer.
double _width(String font) {
  final ctx = UiCanvasElement().getContext2d()..font = font;
  return ctx.measureText(_text).width;
}

void main() {
  group('font weight', () {
    test('the faces of the test font have different widths', () {
      // The other tests identify the face by the width.
      expect(_bold - _regular, greaterThan(70));
      expect(_width('100px $_family'), closeTo(_regular, 0.5));
      expect(_width('bold 100px $_family'), closeTo(_bold, 0.5));
    });

    test('a weight gives the face of Chrome on Linux with system fonts', () {
      const expected = <String, double>{
        '1': _regular,
        '100': _regular,
        '400': _regular,
        '500': _regular,
        '501': _regular,
        '549': _regular,
        '549.99': _regular,
        '550': _bold,
        '550.5': _bold,
        '600': _bold,
        '700': _bold,
        '900': _bold,
        '1000': _bold,
        'normal': _regular,
        'lighter': _regular,
        'bold': _bold,
        'bolder': _bold,
      };
      for (final MapEntry(key: weight, value: width) in expected.entries) {
        expect(
          _width('$weight 100px $_family'),
          closeTo(width, 0.5),
          reason: 'weight $weight',
        );
      }
    });

    test('a number gives the nearest ui.FontWeight', () {
      const expected = <String, ui.FontWeight>{
        '1': ui.FontWeight.w100,
        '149.99': ui.FontWeight.w100,
        '150': ui.FontWeight.w200,
        '449.99': ui.FontWeight.w400,
        '450': ui.FontWeight.w500,
        '549.99': ui.FontWeight.w500,
        '550': ui.FontWeight.w600,
        '949.99': ui.FontWeight.w900,
        '1000': ui.FontWeight.w900,
      };
      for (final MapEntry(key: weight, value: fontWeight) in expected.entries) {
        expect(
          parseCanvasFont('$weight 10px a')!.weight,
          fontWeight,
          reason: 'weight $weight',
        );
      }
    });

    test('the engine gives the regular face up to w500 and the bold face '
        'from w600', () {
      for (final weight in ui.FontWeight.values) {
        final font = CanvasFont(
          size: 100,
          families: const ['Liberation Sans'],
          weight: weight,
        );
        expect(
          measureCanvasText(font, _text).width,
          closeTo(weight.value <= 500 ? _regular : _bold, 0.5),
          reason: 'w${weight.value}',
        );
      }
    });
  });

  // The keywords before the size. The reference is Chromium 155.0.8059.79
  // on Debian 12 and on Debian 13 (headless, arm64, in Docker), with the same
  // results: `ctx.font = '<keywords> 12px Arial'` after
  // `ctx.font = '10px monospace'`. A font that Chromium does not accept
  // keeps `10px monospace`. A font that the canvas layer does not
  // accept keeps the earlier font too, so a difference changes the text
  // widths and thus the layout.
  group('font keywords', () {
    /// The weight and the style of `<keywords> 12px Arial`, or `null` when
    /// the font does not parse.
    (ui.FontWeight, ui.FontStyle)? parse(String keywords) {
      final font = parseCanvasFont('$keywords 12px Arial');
      return font == null ? null : (font.weight, font.style);
    }

    const normal = ui.FontStyle.normal;
    const italic = ui.FontStyle.italic;

    test('a weight is a CSS number', () {
      // Chromium accepts these numbers.
      const valid = <String, ui.FontWeight>{
        '+500': ui.FontWeight.w500,
        '5e2': ui.FontWeight.w500,
        '5E2': ui.FontWeight.w500,
        '5e+2': ui.FontWeight.w500,
        '.5e3': ui.FontWeight.w500,
        '+.5e3': ui.FontWeight.w500,
        '1e3': ui.FontWeight.w900,
        '+1e3': ui.FontWeight.w900,
        '1.0e3': ui.FontWeight.w900,
        '100e-2': ui.FontWeight.w100,
        '00500': ui.FontWeight.w500,
        '0500.000': ui.FontWeight.w500,
        '1': ui.FontWeight.w100,
        '1000': ui.FontWeight.w900,
      };
      for (final MapEntry(key: keywords, value: weight) in valid.entries) {
        expect(parse(keywords), (weight, normal), reason: keywords);
      }
      // Chromium does not accept these: no digit after the point, a value
      // out of [1, 1000], or no number.
      for (final keywords in [
        '500.',
        '1.',
        '1.e3',
        '-500',
        '-1',
        '+0',
        '-0',
        '0.5',
        '1e-3',
        '1e309',
        '1000.0001',
        '5e',
        '5e+',
      ]) {
        expect(parse(keywords), isNull, reason: keywords);
      }
    });

    test('each keyword occurs one time, with at most 4 keywords', () {
      const valid = <String, (ui.FontWeight, ui.FontStyle)>{
        'normal normal normal normal': (ui.FontWeight.normal, normal),
        'normal 600 normal normal': (ui.FontWeight.w600, normal),
        'italic small-caps 600 condensed': (ui.FontWeight.w600, italic),
        '550 small-caps italic condensed': (ui.FontWeight.w600, italic),
        'italic bold': (ui.FontWeight.bold, italic),
        'bold italic': (ui.FontWeight.bold, italic),
        'condensed 600': (ui.FontWeight.w600, normal),
        '600 condensed': (ui.FontWeight.w600, normal),
      };
      for (final MapEntry(key: keywords, value: result) in valid.entries) {
        expect(parse(keywords), result, reason: keywords);
      }
      for (final keywords in [
        'bold 600',
        '600 bold',
        'bold bold',
        'bolder bold',
        'lighter 100',
        'bold normal 600',
        'italic italic',
        'italic oblique',
        'oblique italic',
        'small-caps small-caps',
        'condensed condensed',
        'condensed expanded',
        'normal normal normal normal normal',
        'normal 600 normal normal normal',
        'italic small-caps 600 condensed normal',
        'initial',
        'inherit',
        'unset',
      ]) {
        expect(parse(keywords), isNull, reason: keywords);
      }
    });

    test('oblique takes an angle with a number in [-90, 90]', () {
      const valid = <String, (ui.FontWeight, ui.FontStyle)>{
        'oblique': (ui.FontWeight.normal, italic),
        'oblique 20deg': (ui.FontWeight.normal, italic),
        'oblique -20deg': (ui.FontWeight.normal, italic),
        'oblique 90deg': (ui.FontWeight.normal, italic),
        'oblique -90deg': (ui.FontWeight.normal, italic),
        'oblique 89.9999deg': (ui.FontWeight.normal, italic),
        'oblique 9e1deg': (ui.FontWeight.normal, italic),
        'oblique +20deg': (ui.FontWeight.normal, italic),
        'oblique .5deg': (ui.FontWeight.normal, italic),
        'OBLIQUE 20DEG': (ui.FontWeight.normal, italic),
        // Chromium compares the number, not the angle, with [-90, 90].
        'oblique 89grad': (ui.FontWeight.normal, italic),
        'oblique 2rad': (ui.FontWeight.normal, italic),
        'oblique 90rad': (ui.FontWeight.normal, italic),
        'oblique 90turn': (ui.FontWeight.normal, italic),
        // A slope of 0 is the normal style.
        'oblique 0deg': (ui.FontWeight.normal, normal),
        'oblique -0deg': (ui.FontWeight.normal, normal),
        'oblique 0turn': (ui.FontWeight.normal, normal),
        // The angle is not one of the 4 keywords.
        'oblique 20deg 600': (ui.FontWeight.w600, italic),
        '600 oblique 20deg': (ui.FontWeight.w600, italic),
        'oblique 20deg bold': (ui.FontWeight.bold, italic),
        'normal normal normal oblique 20deg': (ui.FontWeight.normal, italic),
        // A number without a unit after oblique is the weight.
        'oblique 20': (ui.FontWeight.w100, italic),
        'oblique normal': (ui.FontWeight.normal, italic),
      };
      for (final MapEntry(key: keywords, value: result) in valid.entries) {
        expect(parse(keywords), result, reason: keywords);
      }
      for (final keywords in [
        'oblique 91deg',
        'oblique -91deg',
        'oblique 99deg',
        'oblique 90.0001deg',
        'oblique 9.1e1deg',
        'oblique 95grad',
        'oblique 90.0001grad',
        'oblique 91rad',
        'oblique -90.5rad',
        'oblique 91turn',
        'oblique 0',
        'oblique 5.deg',
        'oblique 5degs',
        'oblique 1x',
        'oblique deg',
        'oblique 20 deg',
        'oblique 20deg 20deg',
        'oblique 20deg oblique',
        'oblique 20deg italic',
        'italic 20deg',
        'oblique 20deg normal normal normal normal',
      ]) {
        expect(parse(keywords), isNull, reason: keywords);
      }
    });

    test('a toFontString output with an oblique angle sets the font', () {
      // helpers.options.ts:8 FONT_STYLE accepts `oblique -99deg` to
      // `oblique 99deg`. The spec helpers.options.tests.js makes
      // 'oblique 9deg 42px foobar' and 'oblique -90deg 21px bla'.
      expect(parseCanvasFont('oblique 9deg 42px foobar')?.size, 42);
      expect(parseCanvasFont('oblique -90deg 21px bla')?.family, 'bla');
      // Chromium measures 1772.998046875 for 'oblique 20deg', the width of
      // the regular face: the font applies. Before the fix, the canvas
      // layer kept the earlier font.
      expect(_width('oblique 20deg 100px $_family'), closeTo(_regular, 0.5));
      expect(
        _width('oblique -5deg bold 100px $_family'),
        closeTo(_bold, 0.5),
      );
      // Chromium does not accept 'oblique 95deg 100px ...'.
      final ctx = UiCanvasElement().getContext2d()
        ..font = '10px monospace'
        ..font = 'oblique 95deg 100px $_family';
      expect(ctx.font, '10px monospace');
    });
  });

  // The caches of the text layer. A category axis measures half of its
  // labels in each update, and the halves alternate (core.scale.js:71
  // `garbageCollect`). Thus the metrics cache sees a cycle of all the
  // labels. A cache smaller than the cycle missed on each text and built a
  // paragraph for it.
  group('caches', () {
    final font = parseCanvasFont('12px $_family')!;

    // It runs before the cycle below: the metrics cache has only the texts
    // of the groups above.
    test('a full metrics cache removes its oldest quarter', () {
      final before = canvasMetricsCacheLength;
      const removed = (metricsCacheSize + 1) ~/ 4;
      expect(before, lessThan(removed - 1));
      final texts = [
        for (var i = before; i < metricsCacheSize; i++) 'fill $i',
      ];
      final metrics = [for (final text in texts) measureCanvasText(font, text)];
      expect(canvasMetricsCacheLength, metricsCacheSize);
      // A hit moves the first fill text to the end of the order.
      expect(
        identical(measureCanvasText(font, texts.first), metrics.first),
        isTrue,
      );
      // One more text removes the oldest quarter: the texts of the groups
      // above and the fill texts 1 to `gone`.
      measureCanvasText(font, 'one more');
      expect(canvasMetricsCacheLength, metricsCacheSize + 1 - removed);
      final gone = removed - before;
      for (final i in [0, gone + 1, texts.length - 1]) {
        expect(
          identical(measureCanvasText(font, texts[i]), metrics[i]),
          isTrue,
          reason: texts[i],
        );
      }
      expect(
        identical(measureCanvasText(font, texts[gone]), metrics[gone]),
        isFalse,
      );
    });

    test('a cycle of 10000 texts measured twice gives the same widths, and '
        'the second pass builds no paragraph', () {
      final texts = [for (var i = 0; i < 10000; i++) 'cycle label $i'];
      final first = [for (final text in texts) measureCanvasText(font, text)];
      final length = canvasMetricsCacheLength;
      expect(length, lessThanOrEqualTo(metricsCacheSize));
      for (var i = 0; i < texts.length; i++) {
        final second = measureCanvasText(font, texts[i]);
        // A miss builds a paragraph and new metrics. A hit gives the
        // metrics of the first pass.
        expect(identical(second, first[i]), isTrue, reason: texts[i]);
        expect(second.width, first[i].width, reason: texts[i]);
      }
      // A miss adds an entry.
      expect(canvasMetricsCacheLength, length);
      // The cached widths are the widths of a new paragraph.
      for (var i = 0; i < texts.length; i += 97) {
        final layout = layoutCanvasText(font, texts[i], ui.TextDirection.ltr);
        expect(first[i].width, layout.width, reason: texts[i]);
        layout.paragraph.dispose();
      }
    });

    test('a full paragraph cache removes and disposes its oldest quarter', () {
      const black = ui.Color(0xFF000000);
      CanvasTextLayout layout(String text) => layoutCanvasText(
        font,
        text,
        ui.TextDirection.ltr,
        color: black,
        cacheKey: black,
      );
      final before = canvasParagraphCacheLength;
      const removed = (paragraphCacheSize + 1) ~/ 4;
      expect(before, lessThan(removed));
      final layouts = [
        for (var i = before; i < paragraphCacheSize; i++)
          layout('paragraph $i'),
      ];
      expect(canvasParagraphCacheLength, paragraphCacheSize);
      layout('one more paragraph');
      expect(canvasParagraphCacheLength, paragraphCacheSize + 1 - removed);
      final gone = removed - before;
      for (var i = 0; i < layouts.length; i++) {
        expect(
          layouts[i].paragraph.debugDisposed,
          i < gone,
          reason: 'paragraph ${before + i}',
        );
      }
      // A kept layout comes from the cache.
      expect(
        identical(layout('paragraph ${paragraphCacheSize - 1}'), layouts.last),
        isTrue,
      );
    });
  });
}
