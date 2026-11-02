// Original code, not ported from Chart.js: guarded reuse of scalar tick fonts.

import 'package:flutter_chartjs_port/src/core/core.defaults.dart' show defaults;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show OptionView;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ParsedFont, toFont;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart' show undefined;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show FontSpecScope;
import 'package:flutter_chartjs_port/src/options/static_font.dart';

/// One previously parsed font per scale. Inputs are checked on every read;
/// there is no cache of a scriptable result or a view tied to an old tick.
final class TickFontCache {
  StaticFontInputs? _inputs;
  ParsedFont? _font;

  /// A fresh font with the previously parsed values, or null for the upstream
  /// resolution path. Fresh objects preserve the mutable `font.string` field.
  ParsedFont? read(Object? ticks) {
    final font = _font;
    if (font == null) return null;
    final inputs = staticInputs(ticks);
    return inputs != null && inputs == _inputs ? _copy(font) : null;
  }

  /// Learn only after a complete upstream resolution has populated the raw
  /// resolver caches. Never keep the object returned to the caller.
  void remember(Object? ticks, ParsedFont font) {
    final inputs = staticInputs(ticks);
    final valid = inputs != null && matchesResolved(inputs, font);
    _inputs = valid ? inputs : null;
    _font = valid ? _copy(font) : null;
  }

  /// A getter may write an earlier font field while toFont is still reading
  /// later fields. Such a mixed result must not be remembered for the new
  /// scalar tuple. The comparison itself reads only owned primitive values.
  static bool matchesResolved(StaticFontInputs inputs, ParsedFont font) {
    if (font.weight != null && font.weight is! String) return false;
    final expected = toFont({
      'size': inputs.size,
      'family': inputs.family,
      'style': inputs.style,
      'lineHeight': inputs.lineHeight,
      'weight': inputs.weight,
    }, const <String, Object?>{});
    return font.size == expected.size &&
        font.family == expected.family &&
        font.style == expected.style &&
        font.lineHeight == expected.lineHeight &&
        font.weight == expected.weight &&
        font.string == expected.string;
  }

  /// Current scalar inputs, inspected without executing any font callbacks.
  static StaticFontInputs? staticInputs(Object? ticks) {
    if (ticks is! OptionView) return null;
    final fallback = _plainFallback();
    if (fallback == null) return null;
    return ticks.cachedStaticFont(
      staticFontInputs(
        fallback.sizeCell?.raw,
        fallback.familyCell?.raw,
        fallback.styleCell?.raw,
        fallback.lineHeightCell?.raw,
        fallback.weightCell == null ? undefined : fallback.weightCell!.raw,
      ),
    );
  }

  /// toFont eagerly reads defaults.font even when all five inputs are present.
  /// Omit those unused reads only for the exact plain built-in scope, with no
  /// routed getters. Invalid/replaced defaults retain their reads and throws.
  static FontSpecScope? _plainFallback() {
    if (defaults.routeOf('font') != null) return null;
    final font = defaults.fontCell?.raw;
    if (font.runtimeType != FontSpecScope) return null;
    final scope = font! as FontSpecScope;
    return scope.routeOf('size') == null &&
            scope.routeOf('style') == null &&
            scope.routeOf('family') == null &&
            scope.routeOf('lineHeight') == null &&
            scope.routeOf('weight') == null
        ? scope
        : null;
  }

  static ParsedFont _copy(ParsedFont font) => ParsedFont(
    family: font.family,
    lineHeight: font.lineHeight,
    size: font.size,
    style: font.style,
    weight: font.weight,
    string: font.string,
  );
}
