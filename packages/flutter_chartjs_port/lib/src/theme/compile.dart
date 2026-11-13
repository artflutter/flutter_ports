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
/// The compiler writes each key with the typed setter of its scope
/// (Chart.js ADR 0118): no key is a dotted path, and no key passes through a
/// Map. The keys are the token table of theming.md §4 and nothing else, so
/// the compiler needs no guard.
///
/// Ported files never import this file (Chart.js ADR 0050, invariant 4).
library;

import 'dart:collection' show ListBase;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show JsFreezable, jsObjectFreeze;
import 'package:flutter_chartjs_port/src/options/opt.dart' show OptScope;
import 'package:flutter_chartjs_port/src/options/option_scope.dart'
    show OptionScope;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';

/// The background alpha of the palette when the theme gives none: the 0.5
/// of `BACKGROUND_COLORS` (`plugin.colors.ts:25`).
const double _paletteBackgroundAlpha = 0.5;

/// The alpha of the tick backdrop of the `surface` token: the scale tick
/// backdrop `'rgba(255, 255, 255, 0.75)'` (`core.scale.defaults.js:81`).
/// "At alpha" replaces the alpha, as the palette replaces it
/// (`plugin.colors.ts:25`).
const double _backdropAlpha = 0.75;

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
/// - The result is frozen deeply: each scope and List is a [JsFreezable]
///   after [jsObjectFreeze]. A write throws a [TypeError]. Thus a write of
///   the set trap of a resolver into a theme scope throws, instead of a leak
///   into other charts (`helpers.config.ts:101-106`).
///
/// The keys go in the order of the token table of theming.md §4. Each scope
/// gets its keys in the order of their first write, so the `plugins` scope
/// has the order `title`, `subtitle`, `legend`, `tooltip`, `colors`, and the
/// root key `plugins` comes after `scales`, in each compiled theme.
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
  final t = _ThemeTree();

  // `color` replaces `Defaults.color` (`core.defaults.js:43`). The scale
  // routes (`core.scale.defaults.js:86, 89`), the route of the point labels
  // (`scale.radialLinear.js:400-404`) and the routes of the title color
  // (`plugin.title.js:158-160`) and of the subtitle color
  // (`plugin.subtitle.js:45-47`) read it. The legend reads the root `color`
  // (`plugin.legend.js:661, 707`) and gets no key.
  //
  // The radial keys are necessary. Hunk H1 merges the theme into the scale
  // copy-in before `defaults.scales.radialLinear` (theming.md §3.1). Thus the
  // routes of `pointLabels.color` and `angleLines.color` fill these keys from
  // the global `Defaults` when the theme has no value for them. The theme key
  // `scale.grid.color` does not reach `angleLines.color`: the
  // `_fallback: 'grid'` of `scale.radialLinear.js:406-410` adds the grid
  // scopes after the angle-line scopes, and the copy-in always has
  // `angleLines.color`. `scales.radialLinear.ticks.color` needs no key: H1
  // fills it from `scale.ticks.color` first.
  if (color != null) {
    t.root.color = ChartPaint.solid(color);
    t.ticks.color = ChartPaint.solid(color);
    t.scaleTitle.color = ChartPaint.solid(color);
    t.pointLabels.color = ChartPaint.solid(color);
    t.title.color = ChartPaint.solid(color);
    t.subtitle.color = ChartPaint.solid(color);
  }
  // `borderColor` replaces `Defaults.borderColor` (`core.defaults.js:42`).
  // The scale routes (`core.scale.defaults.js:87-88`), the route of the
  // angle lines (`scale.radialLinear.js:400-404`) and the element routes
  // (`element.point.ts:44-47`, `element.line.js:267-270`,
  // `element.bar.js:159-162`) read it.
  if (borderColor != null) {
    t.grid.color = ChartPaint.solid(borderColor);
    t.border.color = ChartPaint.solid(borderColor);
    t.angleLines.color = ChartPaint.solid(borderColor);
    t.point.borderColor = ChartPaint.solid(borderColor);
    t.line.borderColor = ChartPaint.solid(borderColor);
    t.bar.borderColor = ChartPaint.solid(borderColor);
  }
  // `backgroundColor` replaces `Defaults.backgroundColor`
  // (`core.defaults.js:41`) for the routes of the four elements
  // (`element.arc.ts:393-395`).
  if (backgroundColor != null) {
    t.point.backgroundColor = ChartPaint.solid(backgroundColor);
    t.line.backgroundColor = ChartPaint.solid(backgroundColor);
    t.bar.backgroundColor = ChartPaint.solid(backgroundColor);
    t.arc.backgroundColor = ChartPaint.solid(backgroundColor);
  }
  // `surface` replaces the arc `borderColor` `'#fff'` (`element.arc.ts:379`)
  // and, at alpha 0.75, the tick backdrop.
  if (surface != null) {
    t.arc.borderColor = ChartPaint.solid(surface);
    t.ticks.backdropColor = ChartPaint.solid(
      surface.withValues(alpha: _backdropAlpha),
    );
  }

  // The scale slots of the font token. `toFont` fills an absent field from
  // the global `defaults.font` (`helpers.options.ts:115-117`). Thus the
  // compiler writes a font into every slot and no root `font` (theming.md
  // §3.4).
  final baseFont = _font(font);
  if (baseFont != null) {
    t.ticks.font = baseFont;
    t.scaleTitle.font = baseFont;
  }
  // The point-label font is the font token without its size, then the
  // `pointLabelsFont` token over it. Upstream sets the point-label size 10
  // locally (`scale.radialLinear.js:383-385`). Thus the base font gives no
  // size (theming.md §3.4). Without a `pointLabelsFont` size, the size 10 of
  // `defaults.scales.radialLinear` stays. Hunk H1 merges the theme font into
  // the scale copy-in first. Then `mergeIf` adds the absent size of the
  // defaults font to that font (`core.config.js:109`,
  // `helpers.core.ts:310-323`).
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
    t.pointLabels.font = pointLabels;
  }
  // The font token without its weight where upstream sets the weight
  // locally: `plugins.title.font` has the weight `'bold'`
  // (`plugin.title.js:148-150`), and `plugins.subtitle.font` has the weight
  // `'normal'` (`plugin.subtitle.js:35-37`). A font without other fields is
  // not emitted.
  final fontWithoutWeight = baseFont == null
      ? null
      : _fontWithout(baseFont, weight: true);
  final emitWithoutWeight =
      fontWithoutWeight != null && _hasFontField(fontWithoutWeight);
  if (emitWithoutWeight) {
    t.title.font = fontWithoutWeight;
    t.subtitle.font = fontWithoutWeight;
  }
  // The whole font token for the legend label font
  // (`plugin.legend.js:136, 288`) and the legend title font (`:446, 495`).
  // The legend has no font defaults (`plugin.legend.js:636-712`), so `toFont`
  // fills an absent field from the global `defaults.font`.
  if (baseFont != null) {
    t.legendLabels.font = baseFont;
    t.legendTitle.font = baseFont;
  }

  // The tooltip keys come after the legend keys (theming.md §4).
  // `inverseSurface` replaces the tooltip `backgroundColor`
  // `'rgba(0,0,0,0.8)'` (`plugin.tooltip.js:1279`). `onInverseSurface`
  // replaces the `'#fff'` of the tooltip `titleColor`, `bodyColor`,
  // `footerColor` and `multiKeyBackground`
  // (`plugin.tooltip.js:1280, 1287, 1292, 1305`).
  if (inverseSurface != null) {
    t.tooltip.backgroundColor = ChartPaint.solid(inverseSurface);
  }
  if (onInverseSurface != null) {
    t.tooltip
      ..titleColor = ChartPaint.solid(onInverseSurface)
      ..bodyColor = ChartPaint.solid(onInverseSurface)
      ..footerColor = ChartPaint.solid(onInverseSurface)
      ..multiKeyBackground = ChartPaint.solid(onInverseSurface);
  }
  // The three tooltip fonts in the order of the tooltip defaults
  // (`plugin.tooltip.js:1281-1297`). They route to the global `font`
  // (`plugin.tooltip.js:1327-1331`). `titleFont` and `footerFont` set the
  // weight `'bold'` locally (`plugin.tooltip.js:1281-1283, 1295-1297`), so
  // they get the font token without its weight. `bodyFont` sets nothing
  // locally (`plugin.tooltip.js:1289-1290`) and gets the whole font token.
  if (emitWithoutWeight) t.tooltip.titleFont = fontWithoutWeight;
  if (baseFont != null) t.tooltip.bodyFont = baseFont;
  if (emitWithoutWeight) t.tooltip.footerFont = fontWithoutWeight;

  // `plugins.colors.$borderColors` gets the colors at their alpha.
  // `plugins.colors.$backgroundColors` gets the same colors with the alpha
  // replaced by [paletteBackgroundAlpha], as `plugin.colors.ts:25` derives
  // `BACKGROUND_COLORS` from `BORDER_COLORS`. A null or empty [palette]
  // emits nothing.
  if (palette != null && palette.isNotEmpty) {
    t.colors
      ..dollarBorderColors = _FrozenList.of(palette)
      ..dollarBackgroundColors = _FrozenList.of([
        for (final color in palette)
          color.withValues(alpha: paletteBackgroundAlpha),
      ]);
  }

  // The transitions come only beside other keys (theming.md §3.3).
  if (t.isEmpty) return null;
  t.addTransitions();
  return t.freeze();
}

/// The scopes of one compiled theme. Each scope comes into its parent at its
/// first use, so each scope gets its keys in the order of their first write.
final class _ThemeTree {
  /// The root scope.
  late final ChartOptionsScope root = add(ChartOptionsScope());

  /// The scopes of the tree, for [freeze].
  final List<OptionScope> _scopes = [];

  late final ScaleOptionsScope _scale = root.scale = add(ScaleOptionsScope());

  /// `scale.ticks`.
  late final TickOptionsScope ticks = _scale.ticks = add(TickOptionsScope());

  /// `scale.title`.
  late final ScaleTitleOptionsScope scaleTitle = _scale.title = add(
    ScaleTitleOptionsScope(),
  );

  /// `scale.grid`.
  late final GridLineOptionsScope grid = _scale.grid = add(
    GridLineOptionsScope(),
  );

  /// `scale.border`.
  late final BorderOptionsScope border = _scale.border = add(
    BorderOptionsScope(),
  );

  /// `scales.radialLinear`: hunk H1 reads only `theme.scales[<scale type>]`
  /// (theming.md §3.3), and the scale ids are keys by name.
  late final ScaleOptionsScope _radialLinear = () {
    final scales = root.scales = add(ScaleOptionsByIdScope());
    final radialLinear = add(ScaleOptionsScope());
    scales.store('radialLinear', OptScope<ScaleOptionsScope>(radialLinear));
    return radialLinear;
  }();

  /// `scales.radialLinear.pointLabels`.
  late final PointLabelOptionsScope pointLabels = _radialLinear.pointLabels =
      add(PointLabelOptionsScope());

  /// `scales.radialLinear.angleLines`.
  late final AngleLineOptionsScope angleLines = _radialLinear.angleLines = add(
    AngleLineOptionsScope(),
  );

  late final PluginOptionsByTypeScope _plugins = root.plugins = add(
    PluginOptionsByTypeScope(),
  );

  /// `plugins.title`.
  late final TitleOptionsScope title = _plugins.title = add<TitleOptionsScope>(
    TitleOptionsScope(),
  );

  /// `plugins.subtitle`.
  late final TitleOptionsScope subtitle = _plugins.subtitle =
      add<TitleOptionsScope>(TitleOptionsScope());

  late final LegendOptionsScope _legend = _plugins.legend =
      add<LegendOptionsScope>(LegendOptionsScope());

  /// `plugins.legend.labels`.
  late final LegendLabelOptionsScope legendLabels = _legend.labels = add(
    LegendLabelOptionsScope(),
  );

  /// `plugins.legend.title`.
  late final LegendTitleOptionsScope legendTitle = _legend.title = add(
    LegendTitleOptionsScope(),
  );

  /// `plugins.tooltip`.
  late final TooltipOptionsScope tooltip = _plugins.tooltip =
      add<TooltipOptionsScope>(TooltipOptionsScope());

  /// `plugins.colors`.
  late final ColorsOptionsScope colors = _plugins.colors =
      add<ColorsOptionsScope>(ColorsOptionsScope());

  late final ElementOptionsByTypeScope _elements = root.elements = add(
    ElementOptionsByTypeScope(),
  );

  /// `elements.point`.
  late final PointOptionsScope point = _elements.point = add(
    PointOptionsScope(),
  );

  /// `elements.line`.
  late final LineOptionsScope line = _elements.line = add(LineOptionsScope());

  /// `elements.bar`.
  late final BarOptionsScope bar = _elements.bar = add(BarOptionsScope());

  /// `elements.arc`.
  late final ArcOptionsScope arc = _elements.arc = add(ArcOptionsScope());

  /// Writes the theme transitions of theming.md §3.8: `'theme'` animates
  /// for 200 ms with `Curves.linear`, the values of the `FThemeMotion` of
  /// forui. `'themeFrame'` has the duration 0 (reduced motion). The two
  /// modes are port-only, so they are keys by name of the scope of the
  /// modes.
  void addTransitions() {
    final transitions = root.transitions = add(TransitionsSpecScope());
    for (final (mode, animation) in [
      (
        'theme',
        add(AnimationOptionsScope())
          ..duration = 200.0
          ..easing = Curves.linear,
      ),
      ('themeFrame', add(AnimationOptionsScope())..duration = 0.0),
    ]) {
      transitions.store(
        mode,
        OptScope<TransitionOptionsScope>(
          add<TransitionOptionsScope>(TransitionOptionsScope())
            ..animation = animation,
        ),
      );
    }
  }

  /// Whether no token wrote a key. A scope comes into the tree only for a
  /// write, so the tree is empty when it has no scope.
  bool get isEmpty => _scopes.isEmpty;

  /// Adds [scope] to the scopes of the tree and gives it.
  T add<T extends OptionScope>(T scope) {
    _scopes.add(scope);
    return scope;
  }

  /// Freezes each scope of the tree and gives the root.
  ChartOptionsScope freeze() {
    _scopes.forEach(jsObjectFreeze);
    return root;
  }
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

/// A palette List of the compiled theme in the frozen state of
/// `Object.freeze` (Chart.js ADR 0021, section 5).
///
/// A write and a change of the length throw a [TypeError], as they do on a
/// frozen array in strict mode.
final class _FrozenList extends ListBase<Object?> implements JsFreezable {
  /// A frozen copy of [colors].
  _FrozenList.of(List<ui.Color> colors) : _list = [...colors];

  /// The items.
  final List<Object?> _list;

  @override
  bool get isFrozen => true;

  @override
  void freeze() {}

  @override
  int get length => _list.length;

  @override
  set length(int newLength) {
    // A JavaScript TypeError: a write into a frozen array.
    throw TypeError();
  }

  @override
  Object? operator [](int index) => _list[index];

  @override
  void operator []=(int index, Object? value) {
    // A JavaScript TypeError: a write into a frozen array.
    throw TypeError();
  }
}
