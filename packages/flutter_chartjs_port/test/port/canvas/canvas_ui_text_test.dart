// Original code, not ported from Chart.js: tests of the canvas text.
@TestOn('vm')
library;

// flutter_test and dart:ui: the web legs cannot compile this file.
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui_text.dart';
import 'package:flutter_test/flutter_test.dart';

// The font weights of the canvas layer (Chart.js ADR 0015, section 1). A
// font is a `TextStyle` (Chart.js ADR 0116): the weight is a `FontWeight`
// from 1 to 1000.
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
// The engine follows that rule: the canvas layer gives the `FontWeight` of
// the style to the engine with no change (Chart.js ADR 0116), and the bold
// face comes for 501 to 549. The upstream specs use no such weight.

/// The probe text.
const String _text = 'January February WWW iii 0123456789';

/// The width of [_text] at 100px in the regular face, in Chromium.
const double _regular = 1772.998046875;

/// The width of [_text] at 100px in the bold face, in Chromium.
const double _bold = 1845.263671875;

/// The Chart.js default family list (`core.defaults.js:55`): the first
/// family and the fallback families of a `TextStyle` (Chart.js ADR 0116).
TextStyle _font({double size = 100, ui.FontWeight? weight}) => TextStyle(
  fontFamily: 'Helvetica Neue',
  fontFamilyFallback: const ['Helvetica', 'Arial', 'sans-serif'],
  fontSize: size,
  fontWeight: weight,
);

/// The width of [_text] in [font] on the canvas layer.
double _width(TextStyle font) {
  final ctx = UiCanvasElement().getContext2d()..font = font;
  return ctx.measureText(_text).width;
}

void main() {
  group('font weight', () {
    test('the faces of the test font have different widths', () {
      // The other tests identify the face by the width.
      expect(_bold - _regular, greaterThan(70));
      expect(_width(_font()), closeTo(_regular, 0.5));
      expect(_width(_font(weight: ui.FontWeight.bold)), closeTo(_bold, 0.5));
    });

    test('a weight gives the face of Chrome with @font-face fonts', () {
      const expected = <int, double>{
        1: _regular,
        100: _regular,
        400: _regular,
        500: _regular,
        501: _bold,
        549: _bold,
        550: _bold,
        600: _bold,
        700: _bold,
        900: _bold,
        1000: _bold,
      };
      for (final MapEntry(key: weight, value: width) in expected.entries) {
        expect(
          _width(_font(weight: ui.FontWeight(weight))),
          closeTo(width, 0.5),
          reason: 'weight $weight',
        );
      }
    });

    test('the engine gives the regular face up to w500 and the bold face '
        'from w600', () {
      for (final weight in ui.FontWeight.values) {
        final font = TextStyle(
          fontFamily: 'Liberation Sans',
          fontSize: 100,
          fontWeight: weight,
        );
        expect(
          measureCanvasText(font, _text).width,
          closeTo(weight.value <= 500 ? _regular : _bold, 0.5),
          reason: 'w${weight.value}',
        );
      }
    });
  });

  // The canvas lays out the text with the whole style (Chart.js ADR 0116):
  // a field of the style that a CSS font has not, as a letter spacing, also
  // changes the width.
  group('style fields', () {
    test('a letter spacing makes the text wider', () {
      const spaced = TextStyle(
        fontFamily: 'Liberation Sans',
        fontSize: 100,
        letterSpacing: 2,
      );
      expect(_width(spaced), closeTo(_regular + 2 * _text.length, 0.5));
    });
  });

  // The caches of the text layer. A category axis measures half of its
  // labels in each update, and the halves alternate (core.scale.js:71
  // `garbageCollect`). Thus the metrics cache sees a cycle of all the
  // labels. A cache smaller than the cycle missed on each text and built a
  // paragraph for it.
  group('caches', () {
    final font = _font(size: 12);

    // It runs before the cycle below: the metrics cache has only the texts
    // of the groups above.
    test('a full metrics cache removes its oldest quarter', () {
      final before = canvasMetricsCacheLength;
      const removed = (metricsCacheSize + 1) ~/ 4;
      expect(before, lessThan(removed - 1));
      final texts = [for (var i = before; i < metricsCacheSize; i++) 'fill $i'];
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
