// Original code, not ported from Chart.js: the dart:ui canvas text.

/// The text of the `dart:ui` canvas context (Chart.js ADR 0015,
/// porting-flow.md 2.8).
///
/// - [parseCanvasFont] parses the CSS font shorthand that `toFontString`
///   makes into a [CanvasFont]: the style, variant, weight and stretch
///   keywords, the size with an optional line height, and the family list.
///   A font that does not parse is `null`: the context ignores it, as the
///   DOM does.
/// - [layoutCanvasText] lays out one `ui.Paragraph` for each font, text and
///   paint, in a bounded LRU cache. [measureCanvasText] caches the metrics
///   only.
///
/// The metrics come from the paragraph: the advance width, the ascent and
/// the descent of the font. `dart:ui` gives no glyph ink boxes, thus the
/// `actualBoundingBox*` values of `measureText` use the font ascent and
/// descent (Chart.js ADR 0009: no display-only exactness).
library;

import 'dart:collection';
import 'dart:ui' as ui;

/// A parsed CSS font: what a `ui.TextStyle` needs.
final class CanvasFont {
  /// A font of [size] CSS pixels.
  CanvasFont({
    required this.size,
    required this.families,
    this.weight = ui.FontWeight.normal,
    this.style = ui.FontStyle.normal,
  });

  /// The font size in CSS pixels.
  final double size;

  /// The family list, without quotes, in order. The list ends at the first
  /// generic family (`sans-serif`, `serif`, `monospace`, ...): the platform
  /// always has a face for it. A generic family stays a name: the engine
  /// gives its default font for a name that it does not know, and the test
  /// harness registers its font under `sans-serif`.
  final List<String> families;

  /// The weight.
  final ui.FontWeight weight;

  /// The style: normal or italic (`oblique` is italic, `oblique 0deg` is
  /// normal).
  final ui.FontStyle style;

  /// The first family, the `fontFamily` of the text style.
  String? get family => families.isEmpty ? null : families.first;

  /// The other families, the `fontFamilyFallback` of the text style.
  List<String> get fallback =>
      families.length <= 1 ? const [] : families.sublist(1);

  late final List<String>? _fallback = families.length <= 1
      ? null
      : families.sublist(1);

  late final ui.ParagraphStyle _ltr = _paragraphStyle(ui.TextDirection.ltr);
  late final ui.ParagraphStyle _rtl = _paragraphStyle(ui.TextDirection.rtl);

  ui.ParagraphStyle _paragraphStyle(ui.TextDirection direction) =>
      ui.ParagraphStyle(
        textAlign: ui.TextAlign.left,
        textDirection: direction,
        maxLines: 1,
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        fontStyle: style,
      );

  /// The text style of this font with [color] or [foreground].
  ui.TextStyle textStyle({ui.Color? color, ui.Paint? foreground}) =>
      ui.TextStyle(
        color: foreground == null ? color : null,
        foreground: foreground,
        fontFamily: family,
        fontFamilyFallback: _fallback,
        fontSize: size,
        fontWeight: weight,
        fontStyle: style,
      );

  @override
  String toString() =>
      'CanvasFont($size, $families, ${weight.value}, ${style.name})';
}

const Set<String> _genericFamilies = {
  'serif',
  'sans-serif',
  'monospace',
  'cursive',
  'fantasy',
  'system-ui',
  'ui-serif',
  'ui-sans-serif',
  'ui-monospace',
  'ui-rounded',
  'emoji',
  'math',
  'fangsong',
};

const Set<String> _stretchKeywords = {
  'ultra-condensed',
  'extra-condensed',
  'condensed',
  'semi-condensed',
  'semi-expanded',
  'expanded',
  'extra-expanded',
  'ultra-expanded',
};

final RegExp _sizePattern = RegExp(
  r'^((?:\d+(?:\.\d*)?|\.\d+)(?:e[+-]?\d+)?)(px|pt)$',
  caseSensitive: false,
);

/// A CSS `<number>`: an optional sign, digits with an optional fraction
/// (`1.` is not a number), and an optional exponent.
const String _number = r'[+-]?(?:\d+|\d*\.\d+)(?:e[+-]?\d+)?';

final RegExp _numberPattern = RegExp('^$_number\$', caseSensitive: false);

/// The angle after `oblique`: a CSS `<number>` with an angle unit.
final RegExp _anglePattern = RegExp(
  '^($_number)(?:deg|grad|rad|turn)\$',
  caseSensitive: false,
);

/// The count of keywords that can come before the size (Blink
/// `ConsumeFont`): the style, the variant, the weight and the stretch.
const int _maxKeywords = 4;

final RegExp _token = RegExp(r'\S+');

final RegExp _spaces = RegExp(r'\s+');

/// The bound of the font cache. A full cache starts again empty.
const int _fontCacheSize = 256;

final Map<String, CanvasFont?> _fontCache = {};

/// The [CanvasFont] of the CSS font shorthand [font], or `null` when it does
/// not parse. Results are cached.
///
/// The size unit is `px` or `pt`. The line height after `/` is read and
/// dropped: canvas text ignores it. `normal`, `small-caps` and the stretch
/// keywords are accepted and have no effect. A weight is `normal`, `bold`,
/// `lighter`, `bolder` (relative to 400) or a CSS number in [1, 1000], which
/// gives the nearest `ui.FontWeight`. `oblique` can have an angle (`deg`,
/// `grad`, `rad` or `turn`) with a number in [-90, 90].
///
/// The keywords before the size follow Blink `ConsumeFont`: at most 4
/// keywords, and each of the style, the variant, the weight and the stretch
/// at most one time. `normal` is one of the 4 keywords. Thus
/// `bold 600 10px a` and `italic italic 10px a` do not parse, as in Chrome.
///
/// The engine then selects the face of the family for that `ui.FontWeight`.
/// For the test font (the faces 400 and 700), the result is the face of
/// Chrome on Linux with system fonts, the platform of the upstream specs:
/// fontconfig selects the nearest weight. Thus the weights 1 to 549.99 give
/// the regular face, and 550 to 1000 give the bold face. The CSS font
/// matching rule of `@font-face` fonts (bold from 501) does not apply. For a
/// family with more faces, the face can be different from Chrome, because
/// `dart:ui` does not give the faces of a family.
CanvasFont? parseCanvasFont(String font) {
  final cached = _fontCache[font];
  if (cached != null || _fontCache.containsKey(font)) return cached;
  if (_fontCache.length >= _fontCacheSize) _fontCache.clear();
  return _fontCache[font] = _parse(font);
}

CanvasFont? _parse(String font) {
  var weight = ui.FontWeight.normal;
  var style = ui.FontStyle.normal;
  // The keywords before the size, as Blink `ConsumeFont` reads them.
  var keywords = 0;
  var hasStyle = false;
  var hasVariant = false;
  var hasWeight = false;
  var hasStretch = false;
  var afterOblique = false;
  for (final match in _token.allMatches(font)) {
    final token = match[0]!;
    final slash = token.indexOf('/');
    final sizeToken = slash < 0 ? token : token.substring(0, slash);
    final size = _sizePattern.firstMatch(sizeToken);
    if (size != null) {
      var value = double.parse(size[1]!);
      if (size[2]!.toLowerCase() == 'pt') value = value * 4 / 3;
      var rest = font.substring(match.end);
      // The line height: `12px/1.2`, `12px/ 1.2`, `12px /1.2` or
      // `12px / 1.2`.
      if (slash >= 0) {
        if (slash == token.length - 1) rest = _dropToken(rest);
      } else {
        final trimmed = rest.trimLeft();
        if (trimmed.startsWith('/')) {
          rest = _dropToken(trimmed.substring(1));
        }
      }
      final families = _families(rest);
      if (families == null) return null;
      return CanvasFont(
        size: value,
        families: families,
        weight: weight,
        style: style,
      );
    }
    final keyword = token.toLowerCase();
    if (afterOblique) {
      afterOblique = false;
      final angle = _anglePattern.firstMatch(keyword);
      if (angle != null) {
        // Chromium compares the number with [-90, 90] in each unit.
        final value = double.parse(angle[1]!);
        if (value < -90 || value > 90) return null;
        if (value == 0) style = ui.FontStyle.normal;
        continue;
      }
    }
    if (++keywords > _maxKeywords) return null;
    if (keyword == 'normal') continue;
    if (!hasStyle && (keyword == 'italic' || keyword == 'oblique')) {
      hasStyle = true;
      style = ui.FontStyle.italic;
      afterOblique = keyword == 'oblique';
    } else if (!hasVariant && keyword == 'small-caps') {
      hasVariant = true;
    } else if (!hasWeight && (keyword == 'bold' || keyword == 'bolder')) {
      hasWeight = true;
      weight = ui.FontWeight.bold;
    } else if (!hasWeight && keyword == 'lighter') {
      hasWeight = true;
      weight = ui.FontWeight.w100;
    } else if (!hasWeight && _numberPattern.hasMatch(keyword)) {
      final number = double.parse(keyword);
      if (number < 1 || number > 1000) return null;
      hasWeight = true;
      weight = ui.FontWeight.values[((number / 100).round().clamp(1, 9)) - 1];
    } else if (!hasStretch && _stretchKeywords.contains(keyword)) {
      hasStretch = true;
    } else {
      return null;
    }
  }
  return null;
}

/// [text] without its first token.
String _dropToken(String text) {
  final match = _token.firstMatch(text);
  return match == null ? '' : text.substring(match.end);
}

/// The family list of [text]: comma-separated names, quoted or not.
/// `null` when the list is empty or malformed.
List<String>? _families(String text) {
  final families = <String>[];
  var i = 0;
  final n = text.length;
  while (true) {
    while (i < n && text[i].trim().isEmpty) {
      i++;
    }
    if (i >= n) return null;
    String name;
    final quote = text[i];
    if (quote == '"' || quote == "'") {
      final close = text.indexOf(quote, i + 1);
      if (close < 0) return null;
      name = text.substring(i + 1, close);
      i = close + 1;
      while (i < n && text[i].trim().isEmpty) {
        i++;
      }
    } else {
      var comma = text.indexOf(',', i);
      if (comma < 0) comma = n;
      name = text.substring(i, comma).trim().replaceAll(_spaces, ' ');
      if (name.isEmpty || name.contains('"') || name.contains("'")) {
        return null;
      }
      i = comma;
      if (_genericFamilies.contains(name.toLowerCase())) {
        families.add(name.toLowerCase());
        return families;
      }
    }
    families.add(name);
    if (i >= n) return families;
    if (text[i] != ',') return null;
    i++;
  }
}

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

final LinkedHashMap<(CanvasFont, String), CanvasTextMetricsData> _metrics =
    LinkedHashMap();

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
  CanvasFont font,
  String text,
  ui.TextDirection direction,
  ui.Color? color,
  ui.Paint? foreground,
) {
  final builder =
      ui.ParagraphBuilder(
          direction == ui.TextDirection.rtl ? font._rtl : font._ltr,
        )
        ..pushStyle(font.textStyle(color: color, foreground: foreground))
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
  CanvasFont font,
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

void _rememberMetrics(CanvasFont font, String text, CanvasTextLayout layout) {
  final key = (font, text);
  if (_metrics.containsKey(key)) return;
  _metrics[key] = CanvasTextMetricsData._(layout);
  if (_metrics.length > metricsCacheSize) _evictOldest(_metrics);
}

/// The metrics of [text] in [font], from the LRU metrics cache.
CanvasTextMetricsData measureCanvasText(CanvasFont font, String text) {
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
  String baseline,
  double size,
  double ascent,
  double descent,
  double ideographic,
) {
  final sum = ascent + descent;
  final emAscent = sum > 0 ? ascent * size / sum : size * 0.8;
  final emDescent = sum > 0 ? descent * size / sum : size * 0.2;
  return switch (baseline) {
    'top' => emAscent,
    'hanging' => ascent * 0.8,
    'middle' => (emAscent - emDescent) / 2,
    'ideographic' => ascent - ideographic,
    'bottom' => -emDescent,
    _ => 0,
  };
}
