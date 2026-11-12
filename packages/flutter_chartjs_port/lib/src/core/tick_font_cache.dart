// Original code, not ported from Chart.js: guarded reuse of static tick fonts.

import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/src/core/core.defaults.dart' show defaults;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show OptionView;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show toFont;
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';

/// One previously resolved font per scale. The static font option and the
/// global font are checked on every read; there is no cache of a scriptable
/// result or a view tied to an old tick. A font is a `TextStyle` (Chart.js
/// ADR 0116): immutable, so the cache can give the same object again.
final class TickFontCache {
  StaticFontInputs? _inputs;
  ChartTextStyle? _font;

  /// The previously resolved font, or null for the upstream resolution path.
  ChartTextStyle? read(Object? ticks) {
    final font = _font;
    if (font == null) return null;
    final inputs = staticInputs(ticks);
    return inputs != null && inputs == _inputs ? font : null;
  }

  /// Learn only after a complete upstream resolution has populated the raw
  /// resolver caches.
  void remember(Object? ticks, ChartTextStyle font) {
    final inputs = staticInputs(ticks);
    final valid = inputs != null && matchesResolved(inputs, font);
    _inputs = valid ? inputs : null;
    _font = valid ? font : null;
  }

  /// Whether [font] is the font that `toFont` gives for [inputs].
  static bool matchesResolved(StaticFontInputs inputs, ChartTextStyle font) =>
      font == toFont(inputs.font, inputs.fallback);

  /// The current static font option and the global font, inspected without
  /// executing any font callbacks.
  static StaticFontInputs? staticInputs(Object? ticks) {
    if (ticks is! OptionView) return null;
    final fallback = _plainFallback();
    if (fallback == null) return null;
    final font = ticks.cachedStaticFont(fallback);
    return font == null ? null : (font: font, fallback: fallback);
  }

  /// toFont eagerly reads defaults.font. Omit that read only for the plain
  /// built-in scope with no routed getter.
  static TextStyle? _plainFallback() {
    if (defaults.routeOf('font') != null) return null;
    final font = defaults.fontCell?.raw;
    return font is TextStyle ? font : null;
  }
}

/// The inputs of a static font: the font option of every context and the
/// global font `defaults.font` that `toFont` merges it over.
typedef StaticFontInputs = ({TextStyle font, TextStyle fallback});
