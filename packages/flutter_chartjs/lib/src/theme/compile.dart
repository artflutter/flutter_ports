// Original code, not ported from Chart.js: the theme compiler.

/// The theme compiler of Chart.js ADR 0001 (theming.md §3.3), a pure layer.
///
/// [compileChartTheme] turns a raw Map theme into one frozen Map with the key
/// shape of `Chart.defaults`. The chart puts that Map into the raw
/// configuration under `themeConfigKey` of `core.config.dart`. The resolver
/// reads it as the option scope between `overrides[type]` and `defaults`
/// (hunks H0-H3, theming.md §3.1).
///
/// The public theme classes (`ChartThemeData`, `ChartColors`,
/// `ChartTypography`) come in phase 9 (theming.md §5). Until then, a theme is
/// a raw Map theme, a Map with the fields of `ChartThemeData`:
///
/// - `colors`: a Map of color tokens. Each value is a [RawThemeColor] or
///   Dart `null`, which themes nothing.
/// - `typography`: a Map with the font tokens `font` and `pointLabels`. Each
///   value is a Map of the `FontSpec` fields `family`, `size`, `style`,
///   `weight` and `lineHeight`, or Dart `null`.
/// - `raw`: a Map of Chart.js keys without a token. Its keys beat the token
///   keys.
///
/// The compiler knows the tokens of the parts that exist in phase 6:
/// `core.defaults`, the elements, `core.scale.defaults` and the
/// `scales.radialLinear` keys of `scale.radialLinear` (theming.md §10). The
/// tooltip, legend, title, subtitle and colors plugin keys come with the
/// plugins in phase 8. A debug assert rejects a field or a token that the
/// compiler does not know.
///
/// Ported files never import this file (Chart.js ADR 0001, invariant 4).
library;

import 'dart:collection';

import 'package:flutter_chartjs/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs/src/js/js_function.dart' show jsIsFunction;
import 'package:flutter_chartjs/src/js/js_number.dart' show jsNumberToString;
import 'package:flutter_chartjs/src/js/js_object.dart'
    show JsFreezable, jsObjectFreeze;
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/basic.dart';

/// A color token of a raw Map theme: the sRGB components of the `dart:ui`
/// constructor `Color.from(alpha:, red:, green:, blue:)`, each from 0 to 1.
///
/// The phase 9 theme classes convert a `dart:ui` `Color` of another color
/// space through `ColorSpace.extendedSRGB` to these components (theming.md
/// §3.3). [themeColorToRgba] clamps them.
typedef RawThemeColor = ({double alpha, double red, double green, double blue});

/// The `rgba()` string of [color] (theming.md §3.3): 8-bit sRGB channels and
/// the alpha from [jsNumberToString].
///
/// A channel is `(x * 255.0).round().clamp(0, 255)`, the 8-bit value of a
/// `dart:ui` `Color` (`Color._floatToInt8`, `painting.dart:221-223`, Flutter
/// 3.44.9). The alpha is clamped to the range from 0 to 1. Thus
/// `(alpha: 0.1, red: 0, green: 0, blue: 0)` gives `'rgba(0, 0, 0, 0.1)'`.
/// The alpha of `Color(0x1A000000)` gives
/// `'rgba(0, 0, 0, 0.10196078431372549)'` instead (theming.md §4).
String themeColorToRgba(RawThemeColor color) {
  final red = _channel(color.red);
  final green = _channel(color.green);
  final blue = _channel(color.blue);
  final alpha = jsNumberToString(color.alpha.clamp(0.0, 1.0));
  return 'rgba($red, $green, $blue, $alpha)';
}

/// The 8-bit value of the color component [x].
int _channel(double x) => (x * 255.0).round().clamp(0, 255);

/// The ids of the scale types of Chart.js v4.5.1: `scale.category.js:36`,
/// `scale.linear.js:8`, `scale.logarithmic.js:76`,
/// `scale.radialLinear.js:340`, `scale.time.js:201` and
/// `scale.timeseries.js:36`.
///
/// The emission guard accepts `scales.<id>` only for these ids. Hunk H1
/// reads only `theme.scales[<scale type>]` (theming.md §3.3).
const Set<String> themeScaleTypes = {
  'category',
  'linear',
  'logarithmic',
  'radialLinear',
  'time',
  'timeseries',
};

/// The behavior keys of theming.md §3.3. The compiler never emits a path
/// that contains one of them.
///
/// The tooltip also resolves `interaction` (`plugin.tooltip.js:1349`).
/// The `hover` scopes of every scope come before the `interaction` scopes
/// (`helpers.config.ts:346-351`, `core.defaults.js:168-170`). Thus a theme
/// `hover` would beat the `interaction` of the user options and of
/// `overrides[type]`, and change the hover elements
/// (`core.controller.js:1259-1260`).
const Set<String> themeBehaviorKeys = {
  'events',
  'interaction',
  'hover',
  'onHover',
  'onClick',
  'animation',
  'animations',
  'responsive',
  'maintainAspectRatio',
  'aspectRatio',
  'indexAxis',
  'type',
  'datasets',
  'parsing',
  'devicePixelRatio',
  'locale',
  'layout',
  'display',
  'enabled',
  'forceOverride',
};

/// The interaction keys that the compiler never emits under
/// `plugins.tooltip` (theming.md §3.3): the keys of `defaults.interaction`
/// (`core.defaults.js:66-70`) and `axis` (`core.interaction.js:272, 308`).
///
/// The tooltip resolves them from `plugins.tooltip`, then from `interaction`
/// (`core.config.js:267-275`, `plugin.tooltip.js:1349`). The theme scope of
/// `plugins.tooltip` comes before `defaults.interaction` (hunk H2). Thus a
/// theme key would change the tooltip elements (`plugin.tooltip.js:1200`).
const Set<String> themeTooltipInteractionKeys = {
  'mode',
  'intersect',
  'axis',
  'includeInvisible',
};

/// The root keys that the compiler never emits (theming.md §3.3). The `''`
/// scope key resolves to the theme root (`helpers.core.ts:338`), ahead of
/// `defaults.elements.<type>`. These keys then beat the `'#fff'` of the arc
/// (`element.arc.ts:306`).
const Set<String> _rootStyleKeys = {'backgroundColor', 'borderColor', 'font'};

/// The two palette keys of `plugins.colors` (theming.md §3.5), the only `$`
/// keys that the compiler emits.
const Set<String> _paletteKeys = {r'$borderColors', r'$backgroundColors'};

/// The emission guard of theming.md §3.3: the rule of the never-emitted list
/// that the theme key at [path] with [value] breaks, or Dart `null` when the
/// compiler can emit it.
///
/// [path] is the list of keys from the theme root to the key. A list item
/// has its index as its key. The rules, in this order:
///
/// 1. The root keys `backgroundColor`, `borderColor` and `font`.
/// 2. A behavior key of [themeBehaviorKeys] on the path, or an interaction
///    key of [themeTooltipInteractionKeys] under `plugins.tooltip`.
/// 3. A static hover color on the path: a key that contains `hover` in any
///    case and ends with `Color`.
/// 4. A `_` key on the path, which the resolver reads as a descriptor
///    (`helpers.config.ts:200-212`).
/// 5. A `$` key on the path, other than the palette keys
///    `plugins.colors.$borderColors` and `plugins.colors.$backgroundColors`.
/// 6. `plugins.<id>` with a `bool` value. Only user options can use it
///    (`core.plugins.js:101-107, 146-154`).
/// 7. `scales.<id>`, where the id is not a scale type of [themeScaleTypes].
///    These keys are dead.
/// 8. A function, Dart `null` (a JS `null` is a value) and [undefined].
///
/// The compiler adds its own `transitions` keys after the guard (theming.md
/// §3.8). Thus they pass, although `animation` is a behavior key.
String? themeNeverEmittedReason(List<String> path, Object? value) {
  if (path.length == 1 && _rootStyleKeys.contains(path[0])) {
    return 'a root ${path[0]} beats the element defaults';
  }
  for (var i = 0; i < path.length; i++) {
    final key = path[i];
    if (themeBehaviorKeys.contains(key)) {
      return '$key is a behavior key';
    }
    if (i == 2 &&
        path[0] == 'plugins' &&
        path[1] == 'tooltip' &&
        themeTooltipInteractionKeys.contains(key)) {
      return 'plugins.tooltip.$key is a behavior key';
    }
    if (key.toLowerCase().contains('hover') && key.endsWith('Color')) {
      return '$key is a static hover color';
    }
    if (key.startsWith('_')) {
      return '$key is read as a descriptor';
    }
    if (key.startsWith(r'$') && !_isPaletteKey(path, i)) {
      return '$key is a \$ key other than the palette';
    }
  }
  if (path.length == 2 && path[0] == 'plugins' && value is bool) {
    return 'plugins.${path[1]}: bool is for the user options only';
  }
  if (path.length >= 2 &&
      path[0] == 'scales' &&
      !themeScaleTypes.contains(path[1])) {
    return 'scales.${path[1]} is not a scale type';
  }
  if (value == null) {
    return 'null is a JS value';
  }
  if (identical(value, undefined)) {
    return 'undefined is no value';
  }
  if (jsIsFunction(value)) {
    return 'a function is no static value';
  }
  return null;
}

/// Whether the key at index [i] of [path] is a palette key of
/// `plugins.colors`.
bool _isPaletteKey(List<String> path, int i) =>
    i == 2 &&
    path[0] == 'plugins' &&
    path[1] == 'colors' &&
    _paletteKeys.contains(path[i]);

/// The color tokens of phase 6 and the keys that each token emits
/// (theming.md §4), in the order of that table.
///
/// - `color` replaces `Defaults.color` (`core.defaults.js:43`). The scale
///   routes (`core.scale.defaults.js:86, 89`) and the route of the point
///   labels (`scale.radialLinear.js:400-404`) read it.
/// - `borderColor` replaces `Defaults.borderColor` (`core.defaults.js:42`).
///   The scale routes (`core.scale.defaults.js:87-88`), the route of the
///   angle lines (`scale.radialLinear.js:400-404`) and the element routes
///   (`element.point.ts:44-47`, `element.line.js:267-270`,
///   `element.bar.js:159-162`) read it.
/// - `backgroundColor` replaces `Defaults.backgroundColor`
///   (`core.defaults.js:41`) for the routes of the four elements
///   (`element.arc.ts:319-321`).
/// - `surface` replaces the arc `borderColor` `'#fff'`
///   (`element.arc.ts:306`).
///
/// The radial keys are necessary. Hunk H1 merges the theme into the scale
/// copy-in before `defaults.scales.radialLinear` (theming.md §3.1). Thus
/// the routes of `pointLabels.color` and `angleLines.color` fill these keys
/// from the global `Defaults` when the theme has no value for them. The
/// theme key `scale.grid.color` does not reach `angleLines.color`: the
/// `_fallback: 'grid'` of `scale.radialLinear.js:406-410` adds the grid
/// scopes after the angle-line scopes, and the copy-in always has
/// `angleLines.color`.
/// `scales.radialLinear.ticks.color` needs no key: H1 fills it from
/// `scale.ticks.color` first.
///
/// The keys of the plugins come with their modules in phase 8.
const Map<String, List<String>> _colorTokenKeys = {
  'color': [
    'color',
    'scale.ticks.color',
    'scale.title.color',
    'scales.radialLinear.pointLabels.color',
  ],
  'borderColor': [
    'scale.grid.color',
    'scale.border.color',
    'scales.radialLinear.angleLines.color',
    'elements.point.borderColor',
    'elements.line.borderColor',
    'elements.bar.borderColor',
  ],
  'backgroundColor': [
    'elements.point.backgroundColor',
    'elements.line.backgroundColor',
    'elements.bar.backgroundColor',
    'elements.arc.backgroundColor',
  ],
  'surface': ['elements.arc.borderColor'],
};

/// The key of the `surface` token at alpha 0.75: the scale tick backdrop
/// `'rgba(255, 255, 255, 0.75)'` (`core.scale.defaults.js:81`). "At alpha"
/// replaces the alpha, as the palette replaces it (`plugin.colors.ts:25`).
const String _backdropKey = 'scale.ticks.backdropColor';

/// The alpha of [_backdropKey].
const double _backdropAlpha = 0.75;

/// The keys of the font token `typography.font` in phase 6 (theming.md §4):
/// the scale slots. `toFont` fills an absent field from the global
/// `defaults.font` (`helpers.options.ts:115-117`). Thus the compiler writes
/// a font into every slot and no root `font` (theming.md §3.4).
const List<String> _fontTokenKeys = ['scale.ticks.font', 'scale.title.font'];

/// The key of the font token `typography.pointLabels` (theming.md §4, the
/// last row): the font of the point labels of the radial linear scale.
///
/// Its value is the `typography.font` Map without `size`, then the fields
/// of `typography.pointLabels` over it. Upstream sets the point-label size
/// 10 locally (`scale.radialLinear.js:383-385`). Thus the base font gives
/// no size (theming.md §3.4). Without a `typography.pointLabels` size, the
/// size 10 of `defaults.scales.radialLinear` stays. Hunk H1 merges the
/// theme font into the scale copy-in first. Then `mergeIf` adds the absent
/// `size` of the defaults font to that font (`core.config.js:109`,
/// `helpers.core.ts:310-323`). The options of a scale do not have
/// `defaults.scales.<type>` as a scope.
const String _pointLabelsFontKey = 'scales.radialLinear.pointLabels.font';

/// The fields of a `FontSpec` (`index.d.ts:1787-1806`).
const Set<String> _fontFields = {
  'family',
  'size',
  'style',
  'weight',
  'lineHeight',
};

/// The fields of a raw Map theme in phase 6.
const Set<String> _themeFields = {'colors', 'typography', 'raw'};

/// The typography tokens of phase 6.
const Set<String> _typographyTokens = {'font', 'pointLabels'};

/// The theme transitions of theming.md §3.8: `'theme'` animates for 200 ms
/// with `'linear'`, the values of the `FThemeMotion` of forui.
/// `'themeFrame'` has the duration 0 (reduced motion).
const Map<String, Object?> _transitions = {
  'theme': <String, Object?>{
    'animation': <String, Object?>{'duration': 200.0, 'easing': 'linear'},
  },
  'themeFrame': <String, Object?>{
    'animation': <String, Object?>{'duration': 0.0},
  },
};

/// The compiled theme of each raw Map theme, by identity, or [_noTheme].
final Expando<Object> _compiled = Expando<Object>('compileChartTheme');

/// The memo value of a theme that compiles to Dart `null`.
const Object _noTheme = Object();

/// The compiled theme of [theme] (theming.md §3.3): one frozen Map with the
/// key shape of `Chart.defaults`, or Dart `null`.
///
/// - Dart `null` gives `null`. A theme that emits no key other than
///   `transitions` keys also gives `null`, for example `ChartThemes.none`.
/// - Each color token emits its keys of theming.md §4 as [themeColorToRgba]
///   strings. The font token `font` emits a Map of its fields that are not
///   `null` into each scale slot. The point-label font is the `font` Map
///   without `size`, then the fields of `pointLabels` over it (theming.md
///   §3.4).
/// - The `raw` keys beat the token keys, key by key. Maps merge, and a Map
///   that holds no key after the guard is left out.
/// - A key that [themeNeverEmittedReason] rejects is never emitted. In debug
///   mode, it fails an assert. A `raw` List with such an item is left out as
///   a whole.
/// - The `transitions` keys of theming.md §3.8 come only beside other keys.
/// - The result is frozen deeply: each Map and each List is a [JsFreezable]
///   after [jsObjectFreeze]. A write throws a [TypeError]. Thus a write of
///   the set trap of a resolver into a theme scope throws, instead of a leak
///   into other charts (`helpers.config.ts:101-106`).
///
/// The result is memoized per instance of [theme]: a second call with the
/// same Map gives the same result. Thus [theme] must not change after its
/// first compile, as the immutable `ChartThemeData` of phase 9.
AnyObject? compileChartTheme(AnyObject? theme) {
  if (theme == null) return null;
  final memo = _compiled[theme];
  if (memo != null) {
    return identical(memo, _noTheme) ? null : memo as AnyObject;
  }
  final result = _compile(theme);
  _compiled[theme] = result ?? _noTheme;
  return result;
}

/// The uncached [compileChartTheme] of [theme].
AnyObject? _compile(AnyObject theme) {
  assert(
    theme.keys.every(_themeFields.contains),
    'Unknown raw theme fields: '
    '${theme.keys.where((key) => !_themeFields.contains(key)).join(', ')}.',
  );
  final keys = <String, Object?>{};

  final colors = _field(theme, 'colors');
  assert(
    colors.keys.every(_colorTokenKeys.containsKey),
    'Unknown color tokens: '
    '${colors.keys.where((k) => !_colorTokenKeys.containsKey(k)).join(', ')}.',
  );
  for (final MapEntry(key: token, value: paths) in _colorTokenKeys.entries) {
    final color = _color(colors, token);
    if (color == null) continue;
    final rgba = themeColorToRgba(color);
    for (final path in paths) {
      _put(keys, path, rgba);
    }
    if (token == 'surface') {
      _put(
        keys,
        _backdropKey,
        themeColorToRgba((
          alpha: _backdropAlpha,
          red: color.red,
          green: color.green,
          blue: color.blue,
        )),
      );
    }
  }

  final typography = _field(theme, 'typography');
  assert(
    typography.keys.every(_typographyTokens.contains),
    'Unknown typography tokens: '
    '${typography.keys.where((k) => !_typographyTokens.contains(k))}.',
  );
  final font = _font(typography['font']);
  if (font.isNotEmpty) {
    for (final path in _fontTokenKeys) {
      _put(keys, path, Map<String, Object?>.of(font));
    }
  }
  // The base font without size, then the point-label font (theming.md §3.4).
  final pointLabelsFont = <String, Object?>{
    for (final MapEntry(:key, :value) in font.entries)
      if (key != 'size') key: value,
    ..._font(typography['pointLabels']),
  };
  if (pointLabelsFont.isNotEmpty) {
    _put(keys, _pointLabelsFontKey, pointLabelsFont);
  }

  _mergeRaw(keys, _field(theme, 'raw'), const []);

  // The transitions come only beside other keys (theming.md §3.3).
  if (keys.keys.every((key) => key == 'transitions')) return null;
  final transitions = keys['transitions'];
  if (transitions is AnyObject) {
    _mergeOver(transitions, _transitions);
  } else {
    keys['transitions'] = _transitions;
  }
  return _freeze(keys)! as AnyObject;
}

/// The Map of the field [name] of [theme]. An absent field and Dart `null`
/// give an empty Map. In debug mode, a value of another type fails an
/// assert.
AnyObject _field(AnyObject theme, String name) {
  final value = theme[name];
  assert(
    value == null || value is AnyObject,
    'The raw theme field $name is not a Map: $value.',
  );
  return value is AnyObject ? value : const <String, Object?>{};
}

/// The color token [token] of [colors], or Dart `null` for no color. In
/// debug mode, a value that is not a [RawThemeColor] fails an assert.
RawThemeColor? _color(AnyObject colors, String token) {
  final value = colors[token];
  assert(
    value == null || value is RawThemeColor,
    'The color token $token is not a RawThemeColor: $value.',
  );
  return value is RawThemeColor ? value : null;
}

/// The `FontSpec` Map of the font token [value]: its fields that are not
/// `null`, in their order (theming.md §3.3). Dart `null` gives an empty Map.
/// In debug mode, an unknown field fails an assert.
AnyObject _font(Object? value) {
  assert(
    value == null || value is AnyObject,
    'The font token is not a Map: $value.',
  );
  if (value is! AnyObject) return const <String, Object?>{};
  assert(
    value.keys.every(_fontFields.contains),
    'Unknown font fields: '
    '${value.keys.where((k) => !_fontFields.contains(k)).join(', ')}.',
  );
  return {
    for (final key in jsObjectKeys(value))
      if (value[key] != null && !identical(value[key], undefined))
        key: value[key],
  };
}

/// Writes [value] at the dot path [path] of [keys]. The Maps on the path are
/// new Maps where needed. In debug mode, a path that the guard rejects fails
/// an assert: the token keys never break the never-emitted list.
void _put(AnyObject keys, String path, Object? value) {
  final parts = path.split('.');
  assert(
    themeNeverEmittedReason(parts, value) == null,
    'The token key $path breaks the emission guard: '
    '${themeNeverEmittedReason(parts, value)}.',
  );
  var node = keys;
  for (final key in parts.take(parts.length - 1)) {
    final child = node[key];
    node = child is AnyObject ? child : (node[key] = <String, Object?>{});
  }
  node[parts.last] = value;
}

/// Merges the `raw` keys of [source] at [path] into [target]. A raw key
/// beats the key in [target]. A Map merges into a Map. A key that the guard
/// rejects is left out, and fails an assert in debug mode.
///
/// The keys come in the [jsObjectKeys] order, as `Object.keys` gives them
/// for an object literal.
void _mergeRaw(AnyObject target, AnyObject source, List<String> path) {
  for (final key in jsObjectKeys(source)) {
    final keyPath = [...path, key];
    final value = source[key];
    final reason =
        themeNeverEmittedReason(keyPath, value) ?? _listItem(keyPath, value);
    if (reason != null) {
      assert(false, 'The theme never emits ${keyPath.join('.')}: $reason.');
      continue;
    }
    if (value is AnyObject) {
      final current = target[key];
      final node = current is AnyObject ? current : <String, Object?>{};
      _mergeRaw(node, value, keyPath);
      if (node.isNotEmpty) target[key] = node;
    } else {
      target[key] = value;
    }
  }
}

/// The reason of the first item of the List [value] at [path], at any
/// depth, that the guard rejects, or Dart `null`. Another value gives Dart
/// `null`.
String? _listItem(List<String> path, Object? value) {
  String? walk(List<String> at, Object? node) {
    if (node is List) {
      for (var i = 0; i < node.length; i++) {
        final itemPath = [...at, '$i'];
        final reason =
            themeNeverEmittedReason(itemPath, node[i]) ??
            walk(itemPath, node[i]);
        if (reason != null) return '${itemPath.join('.')}: $reason';
      }
    } else if (node is AnyObject) {
      for (final key in jsObjectKeys(node)) {
        final keyPath = [...at, key];
        final reason =
            themeNeverEmittedReason(keyPath, node[key]) ??
            walk(keyPath, node[key]);
        if (reason != null) return '${keyPath.join('.')}: $reason';
      }
    }
    return null;
  }

  return value is List ? walk(path, value) : null;
}

/// Writes the keys of [source] over [target], Map into Map.
void _mergeOver(AnyObject target, AnyObject source) {
  for (final key in source.keys) {
    final value = source[key];
    final current = target[key];
    if (value is AnyObject && current is AnyObject) {
      _mergeOver(current, value);
    } else {
      target[key] = value;
    }
  }
}

/// The frozen copy of [value]: a frozen [_FrozenMap] for a Map, a frozen
/// [_FrozenList] for a List, the [themeColorToRgba] string for a
/// [RawThemeColor], else [value].
Object? _freeze(Object? value) => switch (value) {
  final AnyObject map => jsObjectFreeze(
    _FrozenMap({for (final key in jsObjectKeys(map)) key: _freeze(map[key])}),
  ),
  final List<Object?> list => jsObjectFreeze(
    _FrozenList([for (final item in list) _freeze(item)]),
  ),
  final RawThemeColor color => themeColorToRgba(color),
  _ => value,
};

/// A Map of the compiled theme with the frozen state of `Object.freeze`
/// (Chart.js ADR 0021, section 5).
///
/// In the frozen state, a write throws a [TypeError], as a write into a
/// frozen object in strict mode does. The reads do not change.
final class _FrozenMap extends MapBase<String, Object?> implements JsFreezable {
  _FrozenMap(this._map);

  /// The entries, in insertion order.
  final AnyObject _map;

  bool _frozen = false;

  @override
  bool get isFrozen => _frozen;

  @override
  void freeze() {
    _frozen = true;
  }

  @override
  Object? operator [](Object? key) => _map[key];

  @override
  void operator []=(String key, Object? value) {
    // A JavaScript TypeError: a write into a frozen object.
    if (_frozen) throw TypeError();
    _map[key] = value;
  }

  @override
  bool containsKey(Object? key) => _map.containsKey(key);

  @override
  Object? remove(Object? key) {
    // A JavaScript TypeError: a delete of a property of a frozen object.
    if (_frozen && _map.containsKey(key)) throw TypeError();
    return _map.remove(key);
  }

  @override
  Iterable<String> get keys => _map.keys;

  @override
  int get length => _map.length;

  @override
  void clear() {
    // A JavaScript TypeError: a delete of a property of a frozen object.
    if (_frozen && _map.isNotEmpty) throw TypeError();
    _map.clear();
  }
}

/// A List of the compiled theme with the frozen state of `Object.freeze`
/// (Chart.js ADR 0021, section 5).
///
/// In the frozen state, a write and a change of the length throw a
/// [TypeError], as they do on a frozen array in strict mode.
final class _FrozenList extends ListBase<Object?> implements JsFreezable {
  _FrozenList(this._list);

  /// The items.
  final List<Object?> _list;

  bool _frozen = false;

  @override
  bool get isFrozen => _frozen;

  @override
  void freeze() {
    _frozen = true;
  }

  @override
  int get length => _list.length;

  @override
  set length(int newLength) {
    // A JavaScript TypeError: a write into a frozen array.
    if (_frozen) throw TypeError();
    _list.length = newLength;
  }

  @override
  Object? operator [](int index) => _list[index];

  @override
  void operator []=(int index, Object? value) {
    // A JavaScript TypeError: a write into a frozen array.
    if (_frozen) throw TypeError();
    _list[index] = value;
  }
}
