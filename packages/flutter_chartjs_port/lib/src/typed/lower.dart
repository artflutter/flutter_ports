// Original code, not ported from Chart.js: the lowering of the typed config.

/// The lowering of the typed config (Chart.js ADR 0052, section 2): the
/// conversions of the typed values to their option values and the merge
/// of the `extra` Maps.
///
/// The typed config lowers to the scope Maps of Chart.js ADR 0043. The
/// resolver does not change, and the chart reads only the Maps. Each class
/// of the typed config lowers to a new `<String, Object?>` Map in its
/// library (`lowerDataset` of `datasets.dart`), with these rules:
/// 1. The keys come in the order of the constructor parameters. A
///    parameter that is `null` writes no key.
/// 2. A List of the app goes by reference: `data`, `points`, `labels`,
///    `CategoryAxis.labels` and `plugins`. A small style List
///    (`backgroundColors`, `borderColors`, `borderDash`) lowers to a new
///    List.
/// 3. A `Color` lowers through [colorValue], a `TextStyle` through
///    `fontSpecOf` of `css.dart`, a `Duration` through [millisecondsOf] and
///    an `EdgeInsets` through [paddingValue]. A name type lowers to its
///    name or its `optionValue`, `IndexAxis` to its `name`.
/// 4. A plain value never lowers to a closure. Only a function parameter
///    does: [colorScript] for the scriptable colors.
/// 5. `extra` merges last ([mergeExtra]).
///
/// Internal: no public library exports it.
library;

import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/src/theme/css.dart' show colorToRgba;
import 'package:flutter_chartjs_port/src/typed/callbacks.dart'
    show ChartContext, ChartScript;

/// The option value of [color]: its `rgba()` string through `colorToRgba`
/// of `css.dart`, the conversion of the theme (Chart.js ADR 0050). Dart
/// `null` for `null`.
String? colorValue(Color? color) => color == null ? null : colorToRgba(color);

/// The option value of a color with three forms: [color] as its string,
/// [colors] as a new List of strings, or [colorFor] as a scriptable
/// closure ([colorScript]). Dart `null` when the three are `null`.
///
/// The constructors of the typed classes assert that at most one is set.
Object? colorOption(
  Color? color,
  List<Color>? colors,
  ChartScript<Color>? colorFor,
) {
  if (color != null) return colorToRgba(color);
  if (colors != null) {
    return <Object?>[for (final color in colors) colorToRgba(color)];
  }
  if (colorFor != null) return colorScript(colorFor);
  return null;
}

/// The scriptable option of [colorFor]: a closure that gives the `rgba()`
/// string of the color of each context.
///
/// The closure takes the 2 arguments of a Chart.js scriptable option, the
/// context and the options resolver, and `jsCall` calls it with JS arity
/// (`js_function.dart`). The context is the context object of the chart,
/// so the cast to the view [ChartContext] makes no copy. The resolver sees a
/// function, so it resolves the options of each data item, as for a raw
/// closure (`core.config.js:351-366`, `:405-418`).
Object? Function(Object?, Object?) colorScript(ChartScript<Color> colorFor) =>
    (context, options) => colorToRgba(colorFor(context! as ChartContext));

/// The option value of [padding]: a new Map `{top, right, bottom, left}`
/// (`index.d.ts`, `Padding`). Dart `null` for `null`.
Map<String, Object?>? paddingValue(EdgeInsets? padding) => padding == null
    ? null
    : <String, Object?>{
        'top': padding.top,
        'right': padding.right,
        'bottom': padding.bottom,
        'left': padding.left,
      };

/// The option value of [duration]: the milliseconds, with the fraction of
/// the microseconds. Dart `null` for `null`.
double? millisecondsOf(Duration? duration) =>
    duration == null ? null : duration.inMicroseconds / 1000;

/// A new List of the numbers of [list], or Dart `null` for `null`.
List<Object?>? numberList(List<double>? list) =>
    list == null ? null : <Object?>[...list];

/// Merges [extra] into [map] and gives [map] (Chart.js ADR 0052, section 2
/// rule 9).
///
/// Each entry of [extra] goes into [map] after the typed keys, so an entry
/// wins over a typed key of the same name. A Map value merges into the Map
/// of the key when [map] has one, else it replaces the value with a new
/// copy. A List or another value replaces the value by reference. Each Map
/// of the result is a new `<String, Object?>` Map: Chart.js writes into the
/// option Maps, and a `const` Map of the app would throw. The keys of a Map
/// of [extra] are Strings, as the keys of a JS object.
Map<String, Object?> mergeExtra(
  Map<String, Object?> map,
  Map<String, Object?>? extra,
) {
  if (extra != null) _merge(map, extra);
  return map;
}

/// Merges [source] into [target], a Map that the lowering made.
void _merge(Map<String, Object?> target, Map<Object?, Object?> source) {
  for (final MapEntry(:key, :value) in source.entries) {
    final name = key! as String;
    if (value is Map<Object?, Object?>) {
      final current = target[name];
      if (current is Map<String, Object?>) {
        _merge(current, value);
      } else {
        target[name] = _copy(value);
      }
    } else {
      target[name] = value;
    }
  }
}

/// A new `<String, Object?>` copy of [map], with a new copy of each Map
/// value and the other values by reference.
Map<String, Object?> _copy(Map<Object?, Object?> map) => <String, Object?>{
  for (final MapEntry(:key, :value) in map.entries)
    key! as String: value is Map<Object?, Object?> ? _copy(value) : value,
};
