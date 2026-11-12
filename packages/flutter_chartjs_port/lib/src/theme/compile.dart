// Original code, not ported from Chart.js: the theme compiler.

/// The theme compiler of Chart.js ADR 0050 (theming.md §3.3), a pure layer.
///
/// [compileChartTheme] turns the tokens of a theme into one frozen typed
/// scope with the key shape of `Chart.defaults`: a `ChartOptionsScope`
/// (Chart.js ADR 0054 §3), the kind of `Chart.defaults`. The chart puts that
/// scope into its root configuration under `themeConfigKey` of
/// `core.config.dart`. The resolver reads it as the option scope between
/// `overrides[type]` and `defaults` (hunks H0-H3, theming.md §3.1), with the
/// typed reads of a typed scope.
///
/// The input is typed (Chart.js ADR 0117): the six colors are Flutter
/// `Color`s, the two fonts are Flutter `TextStyle`s (Chart.js ADR 0116), and
/// the palette is a List of `Color`s with its background alpha. The public
/// `ChartThemeData` of `theme_data.dart` gives its fields to
/// [compileChartTheme] (`compileThemeData`), and the pure tests give their
/// tokens in the same way. The compiler emits each value as it gets it: a
/// color keeps its color space and its components.
///
/// The compiler knows the tokens of these parts: `core.defaults`, the
/// elements, `core.scale.defaults`, the `scales.radialLinear` keys of
/// `scale.radialLinear`, the `color` and `font` of `plugins.title` and
/// `plugins.subtitle`, the two fonts of `plugins.legend`, the colors and the
/// three fonts of `plugins.tooltip` and the palette of `plugins.colors`
/// (theming.md §4).
///
/// Ported files never import this file (Chart.js ADR 0050, invariant 4).
library;

import 'dart:collection' show ListBase;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsIsFunction;
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show JsFreezable, JsFrozenMap, jsObjectFreeze;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart'
    show OptionScope;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show ChartOptionsScope;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';

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
///
/// The data and decision keys of the controllers, the elements and the
/// scales are behavior keys too: `fill` (`filler.options.js:12`),
/// `spanGaps` and `showLine` (`controller.line.js:63, 82`,
/// `controller.scatter.js:71, 102, 119`), `stacked`
/// (`core.datasetController.js:120-121`), `reverse` (`core.scale.js:481`),
/// `min`, `max`, `suggestedMin` and `suggestedMax` (`core.scale.js:262-265`),
/// `beginAtZero` and `grace` (`core.scale.js:394, 429`), `bounds`
/// (`scale.linearbase.js:257, 273`), `base` (`controller.bar.js:564`),
/// `grouped` (`controller.bar.js:437`) and `skipNull`
/// (`controller.bar.js:639-650`). A flat `labels` is not a behavior key,
/// because `plugins.legend.labels` holds the legend colors and fonts:
/// [themePluginBehaviorPaths] has `scale.labels`.
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
  'fill',
  'spanGaps',
  'showLine',
  'stacked',
  'reverse',
  'min',
  'max',
  'suggestedMin',
  'suggestedMax',
  'beginAtZero',
  'grace',
  'bounds',
  'base',
  'skipNull',
  'grouped',
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

/// The key paths that change data, item order, a position or a discrete
/// decision, and the content keys (Chart.js ADR 0050). The compiler never
/// emits them. The set holds paths, because a flat name is wrong at other
/// paths (`position` is also a layout key of a box, and `labels` of the
/// legend holds its colors and fonts).
///
/// A `scale.` path also stands for each `scales.<type>.` path of
/// [themeScaleTypes] ([themeNeverEmittedReason], rule 2b). The draw-only
/// keys `plugins.tooltip.rtl` and `plugins.tooltip.textDirection`, the
/// fonts and the layout keys of a box stay allowed.
const Set<String> themePluginBehaviorPaths = {
  'plugins.decimation.algorithm', // plugin.decimation.js:269
  'plugins.decimation.samples', // plugin.decimation.js:12
  'plugins.decimation.threshold', // plugin.decimation.js:242
  'plugins.filler.propagate', // plugin.filler/index.js:47
  'plugins.legend.reverse', // plugin.legend.js:116-117
  'plugins.tooltip.position', // plugin.tooltip.js:651, 1012, 1218
  'plugins.title.text', // plugin.title.js:43, 97
  'plugins.subtitle.text', // plugin.title.js:43, 97 (the Title of subtitle)
  'plugins.legend.title.text', // plugin.legend.js:487
  'plugins.legend.rtl', // plugin.legend.js:235-259
  'plugins.tooltip.xAlign', // plugin.tooltip.js:273
  'plugins.tooltip.yAlign', // plugin.tooltip.js:270
  'scale.title.text', // core.scale.js:102, 613
  'scale.labels', // core.scale.js:360
  'scale.ticks.stepSize', // scale.linearbase.js:216-220
  'scale.ticks.count', // scale.linearbase.js:32, 79-84
  'scale.ticks.precision', // scale.linearbase.js:55-57, 260
  'scale.ticks.maxTicksLimit', // scale.linearbase.js:216-231
};

/// The root keys that the compiler never emits (theming.md §3.3). The `''`
/// scope key resolves to the theme root (`helpers.core.ts:338`), ahead of
/// `defaults.elements.<type>`. These keys then beat the `'#fff'` of the arc
/// (`element.arc.ts:379`).
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
///
///    2b. A prefix of 2 or more keys of the normalized path in
///    [themePluginBehaviorPaths] (Chart.js ADR 0050). The normalized path
///    has `scale` in place of a leading `scales.<type>` of
///    [themeScaleTypes]. Thus `scales.linear.ticks.stepSize` matches
///    `scale.ticks.stepSize`. Rule 2b comes before rule 2 at each key, so
///    that the reason names the path.
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
/// 9. A palette key `plugins.colors.$borderColors` or
///    `plugins.colors.$backgroundColors` with a value that is not a List
///    with at least one item (Chart.js ADR 0050). Hunk H5 of
///    `plugin.colors` ignores such a value, and an empty List would give
///    `i % 0`.
///
/// The compiler adds its own `transitions` keys after the guard (theming.md
/// §3.8). Thus they pass, although `animation` is a behavior key.
///
/// No public input reaches the guard (Chart.js ADR 0050): the token emission
/// of [compileChartTheme] is the allowlist, and its debug assert checks each
/// token key against the guard. The guard keeps the never-emitted list of
/// theming.md §3.3 for a later `raw` field (Chart.js ADR 0050).
String? themeNeverEmittedReason(List<String> path, Object? value) {
  if (path.length == 1 && _rootStyleKeys.contains(path[0])) {
    return 'a root ${path[0]} beats the element defaults';
  }
  // Rule 2b: `scales.<type>.<rest>` compares as `scale.<rest>`. The index
  // `i` of `path` is the index `i - shift` of `normalized`.
  final shift =
      path.length >= 2 &&
          path[0] == 'scales' &&
          themeScaleTypes.contains(path[1])
      ? 1
      : 0;
  final normalized = shift == 0 ? path : ['scale', ...path.skip(2)];
  for (var i = 0; i < path.length; i++) {
    final key = path[i];
    final n = i - shift;
    if (n >= 1) {
      final prefix = normalized.take(n + 1).join('.');
      if (themePluginBehaviorPaths.contains(prefix)) {
        return '$prefix is a behavior key';
      }
    }
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
  if (path.length == 3 &&
      _isPaletteKey(path, 2) &&
      !(value is List && value.isNotEmpty)) {
    return 'a palette is a List with at least one item';
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

/// The keys that the color tokens emit (theming.md §4), in the order of that
/// table: [_colorKeys], [_borderColorKeys], [_backgroundColorKeys] and
/// [_surfaceKeys]. The tooltip tokens are [_inverseSurfaceKeys] and
/// [_onInverseSurfaceKeys].
///
/// - `color` replaces `Defaults.color` (`core.defaults.js:43`). The scale
///   routes (`core.scale.defaults.js:86, 89`), the route of the point
///   labels (`scale.radialLinear.js:400-404`) and the routes of the title
///   color (`plugin.title.js:158-160`) and of the subtitle color
///   (`plugin.subtitle.js:45-47`) read it. The legend reads the root
///   `color` (`plugin.legend.js:661, 707`) and gets no key.
/// - `borderColor` replaces `Defaults.borderColor` (`core.defaults.js:42`).
///   The scale routes (`core.scale.defaults.js:87-88`), the route of the
///   angle lines (`scale.radialLinear.js:400-404`) and the element routes
///   (`element.point.ts:44-47`, `element.line.js:267-270`,
///   `element.bar.js:159-162`) read it.
/// - `backgroundColor` replaces `Defaults.backgroundColor`
///   (`core.defaults.js:41`) for the routes of the four elements
///   (`element.arc.ts:393-395`).
/// - `surface` replaces the arc `borderColor` `'#fff'`
///   (`element.arc.ts:379`).
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
const List<String> _colorKeys = [
  'color',
  'scale.ticks.color',
  'scale.title.color',
  'scales.radialLinear.pointLabels.color',
  'plugins.title.color',
  'plugins.subtitle.color',
];

/// The keys of the `borderColor` token (see [_colorKeys]).
const List<String> _borderColorKeys = [
  'scale.grid.color',
  'scale.border.color',
  'scales.radialLinear.angleLines.color',
  'elements.point.borderColor',
  'elements.line.borderColor',
  'elements.bar.borderColor',
];

/// The keys of the `backgroundColor` token (see [_colorKeys]).
const List<String> _backgroundColorKeys = [
  'elements.point.backgroundColor',
  'elements.line.backgroundColor',
  'elements.bar.backgroundColor',
  'elements.arc.backgroundColor',
];

/// The keys of the `surface` token (see [_colorKeys]), with [_backdropKey]
/// at alpha 0.75.
const List<String> _surfaceKeys = ['elements.arc.borderColor'];

/// The keys of the tooltip color tokens (theming.md §4), in the order of
/// that table: [_inverseSurfaceKeys], then [_onInverseSurfaceKeys].
///
/// - `inverseSurface` replaces the tooltip `backgroundColor`
///   `'rgba(0,0,0,0.8)'` (`plugin.tooltip.js:1279`).
/// - `onInverseSurface` replaces the `'#fff'` of the tooltip `titleColor`,
///   `bodyColor`, `footerColor` and `multiKeyBackground`
///   (`plugin.tooltip.js:1280, 1287, 1292, 1305`).
///
/// The compiler emits them after the legend fonts, not with [_colorKeys].
/// Thus the `plugins` Map has the order `title`, `subtitle`, `legend`,
/// `tooltip`, `colors` in each compiled theme.
const List<String> _inverseSurfaceKeys = ['plugins.tooltip.backgroundColor'];

/// The keys of the `onInverseSurface` token (see [_inverseSurfaceKeys]).
const List<String> _onInverseSurfaceKeys = [
  'plugins.tooltip.titleColor',
  'plugins.tooltip.bodyColor',
  'plugins.tooltip.footerColor',
  'plugins.tooltip.multiKeyBackground',
];

/// The key of the `surface` token at alpha 0.75: the scale tick backdrop
/// `'rgba(255, 255, 255, 0.75)'` (`core.scale.defaults.js:81`). "At alpha"
/// replaces the alpha, as the palette replaces it (`plugin.colors.ts:25`).
const String _backdropKey = 'scale.ticks.backdropColor';

/// The alpha of [_backdropKey].
const double _backdropAlpha = 0.75;

/// The keys of the font token `typography.font` (theming.md §4): the scale
/// slots. `toFont` fills an absent field from the global `defaults.font`
/// (`helpers.options.ts:115-117`). Thus the compiler writes a font into
/// every slot and no root `font` (theming.md §3.4).
const List<String> _fontTokenKeys = ['scale.ticks.font', 'scale.title.font'];

/// The keys of the font token `typography.font` without its `weight`
/// (theming.md §3.4 and §4): the slots where upstream sets the weight
/// locally. `plugins.title.font` has the weight `'bold'`
/// (`plugin.title.js:148-150`), and `plugins.subtitle.font` has the weight
/// `'normal'` (`plugin.subtitle.js:35-37`). A font without other fields is
/// not emitted.
const List<String> _fontTokenKeysWithoutWeight = [
  'plugins.title.font',
  'plugins.subtitle.font',
];

/// The plugin keys of the whole font token `typography.font` (theming.md
/// §4): the legend label font (`plugin.legend.js:136, 288`) and the legend
/// title font (`:446, 495`). The legend has no font defaults
/// (`plugin.legend.js:636-712`). Thus `toFont` fills an absent field from
/// the global `defaults.font` (`helpers.options.ts:115-117`), as for the
/// scale slots of [_fontTokenKeys].
///
/// The compiler emits them after the plugin keys of
/// [_fontTokenKeysWithoutWeight], not with [_fontTokenKeys]. Thus the root
/// key `plugins` comes after `scales` in each compiled theme.
const List<String> _pluginFontTokenKeys = [
  'plugins.legend.labels.font',
  'plugins.legend.title.font',
];

/// The three tooltip fonts (theming.md §3.4 and §4), in the order of the
/// tooltip defaults (`plugin.tooltip.js:1281-1297`), each with a flag that
/// is `true` for the whole font token `typography.font`.
///
/// The three fonts route to the global `font` (`plugin.tooltip.js:1327-1331`).
/// `titleFont` and `footerFont` set the weight `'bold'` locally
/// (`plugin.tooltip.js:1281-1283, 1295-1297`). Thus they get the font token
/// without its `weight`, as `plugins.title.font`. `bodyFont` sets nothing
/// locally (`plugin.tooltip.js:1289-1290`) and gets the whole font token.
/// The compiler emits them after the tooltip colors of
/// [_onInverseSurfaceKeys].
const List<(String, bool)> _tooltipFontTokenKeys = [
  ('plugins.tooltip.titleFont', false),
  ('plugins.tooltip.bodyFont', true),
  ('plugins.tooltip.footerFont', false),
];

/// The key of the font token `typography.pointLabels` (theming.md §4, the
/// last row): the font of the point labels of the radial linear scale.
///
/// Its value is the `font` token without `size`, then the fields of the
/// `pointLabelsFont` token over it. Upstream sets the point-label size
/// 10 locally (`scale.radialLinear.js:383-385`). Thus the base font gives
/// no size (theming.md §3.4). Without a `pointLabelsFont` size, the
/// size 10 of `defaults.scales.radialLinear` stays. Hunk H1 merges the
/// theme font into the scale copy-in first. Then `mergeIf` adds the absent
/// `size` of the defaults font to that font (`core.config.js:109`,
/// `helpers.core.ts:310-323`). The options of a scale do not have
/// `defaults.scales.<type>` as a scope.
const String _pointLabelsFontKey = 'scales.radialLinear.pointLabels.font';

/// The background alpha of the palette when the theme gives none: the 0.5
/// of `BACKGROUND_COLORS` (`plugin.colors.ts:25`).
const double _paletteBackgroundAlpha = 0.5;

/// The theme transitions of theming.md §3.8: `'theme'` animates for 200 ms
/// with `Curves.linear`, the values of the `FThemeMotion` of forui.
/// `'themeFrame'` has the duration 0 (reduced motion).
const Map<String, Object?> _transitions = {
  'theme': <String, Object?>{
    'animation': <String, Object?>{
      'duration': 200.0,
      'easing': Curves.linear,
    },
  },
  'themeFrame': <String, Object?>{
    'animation': <String, Object?>{'duration': 0.0},
  },
};

/// The compiled theme of the tokens (theming.md §3.3): one frozen typed
/// scope with the key shape of `Chart.defaults` (a `ChartOptionsScope`,
/// Chart.js ADR 0054 §3), or Dart `null`.
///
/// - A null token themes nothing. Tokens that emit no key give Dart `null`,
///   for example no token at all: a per-chart opt-out (theming.md §5.1).
/// - Each color token emits its `Color` into its keys of theming.md §4.
///   [surface] also emits the tick backdrop at alpha 0.75.
/// - The font token [font] goes into each scale slot, into the two legend
///   fonts and into `plugins.tooltip.bodyFont`, and the same font without
///   its weight into `plugins.title.font`, `plugins.subtitle.font`,
///   `plugins.tooltip.titleFont` and `plugins.tooltip.footerFont`. The
///   point-label font is [font] without its size, then [pointLabelsFont]
///   over it (theming.md §3.4). A font with no field that the chart reads
///   themes nothing.
/// - A non-empty [palette] emits the two palette keys of `plugins.colors`:
///   the colors, and the colors at [paletteBackgroundAlpha] (Chart.js ADR
///   0050, theming.md §4).
/// - The `transitions` keys of theming.md §3.8 come only beside other keys.
/// - The result is a typed scope tree ([_typed]): each object under a key
///   of a nested kind is a typed scope of that kind. It is frozen deeply:
///   each scope and List is a [JsFreezable] after [jsObjectFreeze]. A write
///   throws a [TypeError]. Thus a write of the set trap of a resolver into
///   a theme scope throws, instead of a leak into other charts
///   (`helpers.config.ts:101-106`).
///
/// Each call compiles the tokens and gives a new result: no memo (judge-c
/// §3.9, Chart.js ADR 0054 §4). The theme switch of `ChartView` keeps the
/// compiled theme of its current theme.
ChartOptionsScope? compileChartTheme({
  ui.Color? color,
  ui.Color? borderColor,
  ui.Color? backgroundColor,
  ui.Color? surface,
  ui.Color? inverseSurface,
  ui.Color? onInverseSurface,
  TextStyle? font,
  TextStyle? pointLabelsFont,
  List<ui.Color>? palette,
  double paletteBackgroundAlpha = _paletteBackgroundAlpha,
}) {
  final keys = <String, Object?>{};
  void emit(ui.Color? value, List<String> paths) {
    if (value == null) return;
    for (final path in paths) {
      _put(keys, path, value);
    }
  }

  emit(color, _colorKeys);
  emit(borderColor, _borderColorKeys);
  emit(backgroundColor, _backgroundColorKeys);
  if (surface != null) {
    emit(surface, _surfaceKeys);
    _put(keys, _backdropKey, surface.withValues(alpha: _backdropAlpha));
  }

  final baseFont = _font(font);
  if (baseFont != null) {
    for (final path in _fontTokenKeys) {
      _put(keys, path, baseFont);
    }
  }
  // The base font without size, then the point-label font (theming.md §3.4).
  final pointLabelsToken = _font(pointLabelsFont);
  final baseWithoutSize = baseFont == null
      ? null
      : _fontWithout(baseFont, size: true);
  final pointLabels = baseWithoutSize == null
      ? pointLabelsToken
      : pointLabelsToken == null
      ? baseWithoutSize
      : baseWithoutSize.merge(pointLabelsToken);
  if (pointLabels != null && _hasFontField(pointLabels)) {
    _put(keys, _pointLabelsFontKey, pointLabels);
  }
  // The base font without weight (theming.md §3.4).
  final fontWithoutWeight = baseFont == null
      ? null
      : _fontWithout(baseFont, weight: true);
  final emitWithoutWeight =
      fontWithoutWeight != null && _hasFontField(fontWithoutWeight);
  if (emitWithoutWeight) {
    for (final path in _fontTokenKeysWithoutWeight) {
      _put(keys, path, fontWithoutWeight);
    }
  }
  if (baseFont != null) {
    for (final path in _pluginFontTokenKeys) {
      _put(keys, path, baseFont);
    }
  }

  // The tooltip keys come after the legend keys (theming.md §4).
  emit(inverseSurface, _inverseSurfaceKeys);
  emit(onInverseSurface, _onInverseSurfaceKeys);
  for (final (path, withWeight) in _tooltipFontTokenKeys) {
    final value = withWeight
        ? baseFont
        : (emitWithoutWeight ? fontWithoutWeight : null);
    if (value != null) _put(keys, path, value);
  }

  _palette(keys, palette, paletteBackgroundAlpha);

  // The transitions come only beside other keys (theming.md §3.3).
  if (keys.isEmpty) return null;
  keys['transitions'] = _transitions;
  return _typed(ChartOptionsScope(), keys);
}

/// The frozen typed copy of the emitted [map] in [scope] (Chart.js ADR 0054
/// §3): each key of [map] in its order. An object under a key of a nested
/// kind of [scope] becomes a frozen typed scope of that kind; any other
/// value is [_freeze] of it. A value outside the shape of its key is a
/// foreign cell, as in any typed scope. The keys go in the insertion order
/// of [map]; the scope gives them in the `Object.keys` order (array-index
/// names first), as `jsObjectKeys` of [map] does.
T _typed<T extends OptionScope>(T scope, AnyObject map) {
  for (final MapEntry(:key, :value) in map.entries) {
    final kind = scope.childKindFor(key);
    scope.jsWrite(
      key,
      kind != null && value is AnyObject && value is! OptionScope
          ? _typed(kind.create(), value)
          : _freeze(value),
    );
  }
  return jsObjectFreeze(scope);
}

/// Writes the palette keys of [palette] into [keys] (Chart.js ADR 0050,
/// theming.md §4).
///
/// `plugins.colors.$borderColors` gets the colors at their alpha.
/// `plugins.colors.$backgroundColors` gets the same colors with the alpha
/// replaced by [backgroundAlpha], as `plugin.colors.ts:25` derives
/// `BACKGROUND_COLORS` from `BORDER_COLORS`. A null or empty [palette] emits
/// nothing.
void _palette(
  AnyObject keys,
  List<ui.Color>? palette,
  double backgroundAlpha,
) {
  if (palette == null || palette.isEmpty) return;
  _put(keys, r'plugins.colors.$borderColors', [...palette]);
  _put(keys, r'plugins.colors.$backgroundColors', [
    for (final color in palette) color.withValues(alpha: backgroundAlpha),
  ]);
}

/// The font token [value] when it sets a field that the chart reads, else
/// Dart `null` (Chart.js ADR 0116).
TextStyle? _font(TextStyle? value) =>
    value != null && _hasFontField(value) ? value : null;

/// Whether [font] sets a field that the chart reads: the family, the
/// fallback families, the size, the style, the weight, the height, the
/// letter and word spacing, the locale, the font features or the font
/// variations.
bool _hasFontField(TextStyle font) =>
    font.fontFamily != null ||
    font.fontFamilyFallback != null ||
    font.fontSize != null ||
    font.fontStyle != null ||
    font.fontWeight != null ||
    font.height != null ||
    font.letterSpacing != null ||
    font.wordSpacing != null ||
    font.locale != null ||
    font.fontFeatures != null ||
    font.fontVariations != null;

/// [font] without its size ([size]) or without its weight ([weight]): a new
/// font with the other fields that the chart reads. A `TextStyle` cannot
/// clear a field, so the result is a new [ChartTextStyle].
ChartTextStyle _fontWithout(
  TextStyle font, {
  bool size = false,
  bool weight = false,
}) => ChartTextStyle(
  fontFamily: font.fontFamily,
  fontFamilyFallback: font.fontFamilyFallback,
  fontSize: size ? null : font.fontSize,
  fontStyle: font.fontStyle,
  fontWeight: weight ? null : font.fontWeight,
  height: font.height,
  letterSpacing: font.letterSpacing,
  wordSpacing: font.wordSpacing,
  locale: font.locale,
  fontFeatures: font.fontFeatures,
  fontVariations: font.fontVariations,
);

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

/// The frozen copy of [value]: a frozen [JsFrozenMap] for a Map, a frozen
/// [_FrozenList] for a List, else [value].
Object? _freeze(Object? value) => switch (value) {
  final AnyObject map => jsObjectFreeze(
    JsFrozenMap({for (final key in jsObjectKeys(map)) key: _freeze(map[key])}),
  ),
  final List<Object?> list => jsObjectFreeze(
    _FrozenList([for (final item in list) _freeze(item)]),
  ),
  _ => value,
};

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
