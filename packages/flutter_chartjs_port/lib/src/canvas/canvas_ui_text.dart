// Original code, not ported from Chart.js: the dart:ui canvas text.

/// The text of the `dart:ui` canvas context (Chart.js ADR 0015,
/// porting-flow.md 2.8).
///
/// - The font of the canvas is a Flutter `TextStyle` (Chart.js ADR 0116, row
///   `adapt-text-style-fonts`): the context lays out each text with its
///   family, fallback families, size, weight, style, letter and word
///   spacing, locale, font features and font variations. As in a DOM canvas,
///   the line height of the font has no effect, and the paint is the fill or
///   the stroke of the context.
/// - [layoutCanvasText] lays out one `ui.Paragraph` for each font, text and
///   paint, in a bounded LRU cache. [measureCanvasText] caches the metrics
///   only.
///
/// The metrics come from the paragraph: the advance width, the ascent and
/// the descent of the font. `dart:ui` gives no glyph ink boxes, thus the
/// `actualBoundingBox*` values of `measureText` use the font ascent and
/// descent (Chart.js ADR 0034: no display-only exactness).
library;

import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show TextStyle, kDefaultFontSize;
import 'package:flutter_chartjs_port/src/canvas/canvas.dart'
    show CanvasTextBaseline;

/// The size of [font] in pixels: its `fontSize`, or the default size of
/// Flutter text, [kDefaultFontSize], with which the engine lays it out.
double canvasFontSize(TextStyle font) => font.fontSize ?? kDefaultFontSize;

ui.ParagraphStyle _paragraphStyle(TextStyle font, ui.TextDirection direction) =>
    ui.ParagraphStyle(
      textAlign: ui.TextAlign.left,
      textDirection: direction,
      maxLines: 1,
      fontFamily: font.fontFamily,
      fontSize: font.fontSize,
      fontWeight: font.fontWeight,
      fontStyle: font.fontStyle,
    );

ui.TextStyle _textStyle(
  TextStyle font,
  ui.Color? color,
  ui.Paint? foreground,
) => ui.TextStyle(
  color: foreground == null ? color : null,
  foreground: foreground,
  fontFamily: font.fontFamily,
  fontFamilyFallback: font.fontFamilyFallback,
  fontSize: font.fontSize,
  fontWeight: font.fontWeight,
  fontStyle: font.fontStyle,
  letterSpacing: font.letterSpacing,
  wordSpacing: font.wordSpacing,
  locale: font.locale,
  fontFeatures: font.fontFeatures,
  fontVariations: font.fontVariations,
);

/// A laid out text: the paragraph and its metrics.
final class CanvasTextLayout {
  CanvasTextLayout._(this.paragraph)
    : width = paragraph.maxIntrinsicWidth,
      ascent = paragraph.alphabeticBaseline,
      descent = paragraph.height - paragraph.alphabeticBaseline,
      ideographic = paragraph.ideographicBaseline;

  /// The paragraph, laid out on one line, aligned left.
  final ui.Paragraph paragraph;

  /// The advance width.
  final double width;

  /// The font ascent: the distance from the top of the paragraph to the
  /// alphabetic baseline.
  final double ascent;

  /// The font descent: the distance from the alphabetic baseline to the
  /// bottom of the paragraph.
  final double descent;

  /// The distance from the top of the paragraph to the ideographic
  /// baseline.
  final double ideographic;
}

/// The metrics of a text, without the paragraph.
final class CanvasTextMetricsData {
  CanvasTextMetricsData._(CanvasTextLayout layout)
    : width = layout.width,
      ascent = layout.ascent,
      descent = layout.descent,
      ideographic = layout.ideographic;

  /// See [CanvasTextLayout.width].
  final double width;

  /// See [CanvasTextLayout.ascent].
  final double ascent;

  /// See [CanvasTextLayout.descent].
  final double descent;

  /// See [CanvasTextLayout.ideographic].
  final double ideographic;
}

/// The bound of the paragraph cache.
const int paragraphCacheSize = 512;

/// The bound of the metrics cache.
///
/// A category axis measures half of its labels again in each update: the
/// upstream `garbageCollect` (core.scale.js:71) deletes the older half of
/// the label widths of the scale after the fit, and the two halves
/// alternate. The cache thus sees a cycle of all the labels, and an LRU
/// cache smaller than the cycle never hits. The bound keeps the cycle of
/// 20000 labels (the stress cases) with room for the other texts.
///
/// An entry takes 104 to 128 bytes on the 64-bit Dart VM 3.12 with 8-byte
/// pointers: the key record (32), the metrics (48) and the slots of the
/// hash table (24 to 48). The text is the string of the caller. A full
/// cache takes 3.3 to 4.0 MiB.
const int metricsCacheSize = 32768;

final LinkedHashMap<Object, CanvasTextLayout> _layouts = LinkedHashMap();

final LinkedHashMap<(TextStyle, String), CanvasTextMetricsData> _metrics =
    LinkedHashMap();

Object _textMetricsGeneration = Object();

/// Identity of the current native font environment.
Object get canvasTextMetricsGeneration => _textMetricsGeneration;

/// Flutter's fontsChange notification invalidates both native paragraphs and
/// numeric metrics. Axis plans observe the new generation on update.
void invalidateCanvasTextMetrics() {
  for (final layout in _layouts.values) {
    layout.paragraph.dispose();
  }
  _layouts.clear();
  _metrics.clear();
  _textMetricsGeneration = Object();
}

/// The count of entries in the paragraph cache, for tests.
int get canvasParagraphCacheLength => _layouts.length;

/// The count of entries in the metrics cache, for tests.
int get canvasMetricsCacheLength => _metrics.length;

/// Removes the oldest quarter of the entries of the LRU cache [cache], the
/// first ones in its order, and gives each removed value to [evicted].
///
/// One pass over the keys finds them. A `LinkedHashMap` keeps the slot of
/// a removed entry until its table compacts, and `keys.first` walks over
/// these slots. Removing one entry at a time with `keys.first` walked them
/// again for each entry. A quarter keeps the entries in use, for example
/// the labels of an axis, where clearing the cache would measure them all
/// again.
void _evictOldest<K, V>(
  LinkedHashMap<K, V> cache, [
  void Function(V value)? evicted,
]) {
  final oldest = cache.keys.take(cache.length ~/ 4).toList(growable: false);
  for (final key in oldest) {
    final value = cache.remove(key) as V;
    evicted?.call(value);
  }
}

/// [text] with each ASCII whitespace character as a space: canvas text
/// is one line (the DOM text preparation algorithm).
String prepareCanvasText(String text) {
  for (var i = 0; i < text.length; i++) {
    final unit = text.codeUnitAt(i);
    if (unit == 0x09 || unit == 0x0A || unit == 0x0C || unit == 0x0D) {
      return text.replaceAll(RegExp('[\t\n\f\r]'), ' ');
    }
  }
  return text;
}

ui.Paragraph _build(
  TextStyle font,
  String text,
  ui.TextDirection direction,
  ui.Color? color,
  ui.Paint? foreground,
) {
  final builder = ui.ParagraphBuilder(_paragraphStyle(font, direction))
    ..pushStyle(_textStyle(font, color, foreground))
    ..addText(text);
  return builder.build()
    ..layout(const ui.ParagraphConstraints(width: double.infinity));
}

/// The layout of [text] in [font], painted with [color] or [foreground].
/// [buildForeground] builds the foreground when the layout is not in the
/// cache, in place of [foreground].
///
/// With a [cacheKey], the layout comes from the LRU cache of
/// [paragraphCacheSize] entries for (font, text, direction, key). The key
/// stands for the paint: the color for a fill, the color and the stroke
/// values for a stroke. Without one (a gradient or a pattern), the layout
/// is new.
CanvasTextLayout layoutCanvasText(
  TextStyle font,
  String text,
  ui.TextDirection direction, {
  ui.Color? color,
  ui.Paint? foreground,
  ui.Paint Function()? buildForeground,
  Object? cacheKey,
}) {
  if (cacheKey == null) {
    return CanvasTextLayout._(
      _build(
        font,
        text,
        direction,
        color,
        foreground ?? buildForeground?.call(),
      ),
    );
  }
  final key = (font, text, direction, cacheKey);
  final hit = _layouts.remove(key);
  if (hit != null) {
    _layouts[key] = hit;
    return hit;
  }
  final layout = CanvasTextLayout._(
    _build(font, text, direction, color, foreground ?? buildForeground?.call()),
  );
  _layouts[key] = layout;
  if (_layouts.length > paragraphCacheSize) {
    // A recorded picture keeps its own reference to the text that a
    // paragraph painted, so the evicted paragraph can go now, as
    // `TextPainter` disposes its old paragraph. Left to the garbage
    // collector, a paragraph for each frame (a text that changes in each
    // frame) piles up native memory.
    _evictOldest(_layouts, (layout) => layout.paragraph.dispose());
  }
  _rememberMetrics(font, text, layout);
  return layout;
}

void _rememberMetrics(TextStyle font, String text, CanvasTextLayout layout) {
  final key = (font, text);
  if (_metrics.containsKey(key)) return;
  _metrics[key] = CanvasTextMetricsData._(layout);
  if (_metrics.length > metricsCacheSize) _evictOldest(_metrics);
}

/// The metrics of [text] in [font], from the LRU metrics cache.
CanvasTextMetricsData measureCanvasText(TextStyle font, String text) {
  final key = (font, text);
  final hit = _metrics.remove(key);
  if (hit != null) {
    _metrics[key] = hit;
    return hit;
  }
  final paragraph = _build(
    font,
    text,
    ui.TextDirection.ltr,
    const ui.Color(0xFF000000),
    null,
  );
  final data = CanvasTextMetricsData._(CanvasTextLayout._(paragraph));
  // Never painted: it can go now.
  paragraph.dispose();
  _metrics[key] = data;
  if (_metrics.length > metricsCacheSize) _evictOldest(_metrics);
  return data;
}

/// The position of the alphabetic baseline below the anchor of
/// `textBaseline` [baseline], for a font of [size] with the metrics
/// [ascent], [descent] and [ideographic] (see [CanvasTextLayout]).
///
/// Chromium places `top`, `middle` and `bottom` on the em box of the font
/// (its ascent and descent scaled to sum to the font size), `hanging` at
/// 80% of the ascent and `ideographic` at the descent. `dart:ui` gives the
/// ascent and descent of the font. The em box here scales them.
double canvasBaselineShift(
  CanvasTextBaseline baseline,
  double size,
  double ascent,
  double descent,
  double ideographic,
) {
  final sum = ascent + descent;
  final emAscent = sum > 0 ? ascent * size / sum : size * 0.8;
  final emDescent = sum > 0 ? descent * size / sum : size * 0.2;
  return switch (baseline) {
    CanvasTextBaseline.top => emAscent,
    CanvasTextBaseline.hanging => ascent * 0.8,
    CanvasTextBaseline.middle => (emAscent - emDescent) / 2,
    CanvasTextBaseline.ideographic => ascent - ideographic,
    CanvasTextBaseline.bottom => -emDescent,
    CanvasTextBaseline.alphabetic => 0,
  };
}
