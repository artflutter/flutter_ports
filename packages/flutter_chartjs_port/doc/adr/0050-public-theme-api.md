# Chart.js ADR 0050: The public theme API, the presets, the theme switch and the touch sizes

- Status: accepted (2026-10-30)
- Date: 2026-10-29
- Supersedes: [Chart.js ADR 0042](0042-theming.md)
- Related: [theming.md](../theming.md) (the design), [Chart.js ADR 0001](0001-theming.md),
  [Chart.js ADR 0030](0030-controller-test-strategy.md) §8, §11 and Open 5 (test 3, the blue
  screen), [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) (the protected behavior,
  Flutter goldens), [Chart.js ADR 0020](0020-registry-and-component-classes.md) §13,
  [Chart.js ADR 0019](0019-animation.md) §10 (theme modes), [Chart.js ADR 0015](0015-text.md),
  [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) §16 (touch sizes),
  [Chart.js ADR 0043](0043-options-representation-and-resolver.md) (raw Map configs),
  [Chart.js ADR 0048](0048-entry-points-and-public-library.md) (the public libraries),
  [Chart.js ADR 0049](0049-chart-view-widget.md) (the widget, its update callback, reduced motion)
  and [Chart.js ADR 0051](0051-input-events-and-interaction-state.md) (input events, the widget
  plugin, proposed), [ADR 0007](../../../../docs/adr/0007-package-names.md),
  [porting-flow.md](../porting-flow.md) §1.1 and §3 (goldens on one pinned runner)

## Context

Chart.js ADR 0042 (accepted 2026-10-23) decided the theme mechanism: one option scope, eight
marked hunks and the palette of the theme map. It left the public API to phase 9: the classes,
the public palette type, the `raw` rule, the presets, the touch sizes and its Open items 1 to 4.
The phase 9 design panel B (2026-10-29) decided these items. This ADR states the complete decision
of Chart.js ADR 0042 with these items, and supersedes Chart.js ADR 0042 on acceptance. The Decision
keeps the bullets and the order of Chart.js ADR 0042. These parts change:
- "A small public surface in 0.1.0" becomes three bullets: "The public classes", "The presets"
  and "No public `raw` in 0.1.0".
- "Runtime switch" gets the in-place restore of the user scales, the exact palette restore and
  the skip of equal themes.
- "The blue screen" gets the cases with an active element.
- New bullets: "Transitions", "No touch sizes" and "Goldens".
- "Acceptance", Consequences, Alternatives, Open and Evidence.
The other text is the text of Chart.js ADR 0042. The upstream citations are at the pin `v4.6.1`.
Its `src/` is identical to the old pin `v4.5.1+7169e651`. I checked each cited line at `v4.6.1`.

### The token layer of Chart.js

Chart.js has one global token layer: `Defaults.color` (`'#666'`), `Defaults.borderColor` and
`Defaults.backgroundColor` (both `'rgba(0,0,0,0.1)'`) and `Defaults.font`
(`src/core/core.defaults.js@v4.6.1:41-60`). The colors reach elements, scales and plugins through
`defaults.route` (`core.defaults.js:130-157`, called from `core.scale.defaults.js:86-89` and
`core.typedRegistry.js:94-95, 103-111`). The font reaches the tooltip through `defaultRoutes`
(`plugin.tooltip.js:1327-1331`). All other text reads it through the `toFont` fallback
(`helpers.options.ts:117`).

To get a dark chart, a Chart.js app changes `Chart.defaults`. That change is global. A change of
`Chart.defaults.borderColor` or `Chart.defaults.backgroundColor` also disables the colors plugin,
unless `forceOverride` is set (`src/plugins/plugin.colors.ts@v4.6.1:90-92, 119`). A Flutter app
needs a theme per subtree, a dark mode and a theme switch at runtime.

forui gives a good model ([survey](../prior-art/forui-theming.md)): an `InheritedTheme` root, a
one-way derivation from a few tokens, value equality, `copyWith`, `lerp` and a blue-screen test.
But forui needs `material_ui`, and its generated deltas and variants repeat what Chart.js options
do already. Options are partial values over defaults, with a fixed precedence.

The port has three constraints. Ported specs and fixtures keep their upstream values (AGENTS.md
rule 3). Upstream releases replay file by file
([ADR 0001](../../../../docs/adr/0001-native-ports-not-wrappers.md),
[ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md)). Thus the ported files stay close
to upstream. Upstream draws two states only: default and active, through the hover option
prefixes.

### The colors plugin at the pin

- `plugin.colors.ts:14-22` is `BORDER_COLORS`, 7 `rgb()` strings. `:25` is `BACKGROUND_COLORS`:
  each border color with the alpha replaced by 0.5.
- `:27-29` `getBorderColor(i)` and `:31-33` `getBackgroundColor(i)` give `LIST[i % LIST.length]`.
- `:35-52` are the three colorizers. `:54-68` `getColorizer` keeps one counter for each call of
  `beforeLayout`. `ColorsPluginOptions` (`:4-7`) has `enabled` and `forceOverride` only.
- `beforeLayout` (`:102-126`) returns when `!options.enabled` (`:103`). It reads the raw user
  options `chart.config.options` (`:107-111`), so its checks do not see a theme. It returns when
  the datasets, the options or the elements hold a color, or when the singleton defaults changed,
  unless `forceOverride` (`:113-121`). Then it colorizes each dataset (`:123-125`).
- After the first colorize, the datasets hold colors. Thus the plugin colorizes one time for each
  chart, and at each update only with `forceOverride`.
- Chart.js ADR 0001 read the theme palette from the plugin options. Then a user, `defaults` or
  `overrides.bar` key `plugins.colors.$borderColors` changes an unthemed bar chart (probe J1 of
  Chart.js ADR 0042). The palette of the theme map gives the upstream color for each unthemed
  input. Chart.js ADR 0042 chose it.

### What phase 9 found

The probes ran in detached worktrees of `e4fe262` (Flutter 3.47.7, Dart 3.13.5). Evidence names
the files.
- The internal guard `themeNeverEmittedReason` (`lib/src/theme/compile.dart:244`) passes 38 of 38
  candidate style keys, among them `elements.point.hitRadius`, `elements.arc.borderWidth` and
  `scale.ticks.autoSkip`. `hitRadius: 8` changes the hit element (`[]` to `[0:1]`), and
  `autoSkip: false` changes the x ticks (20 to 60) (F-P1). Thus a deny list is not complete for
  public input. The defaults inventory has 340 leaves: 89 paint, 48 layout and 6 hit (Pf-B3).
- `initOptions` writes `options.scales = mergeScaleConfig(config, options)` into the user options
  (`src/core/core.config.js@v4.6.1:115-120`). `mergeScaleConfig` builds each scale in a new
  object and merges the defaults and, with hunk H1, the theme into it (`:71-112`). Thus the user
  `scales` object never changes, and `options.scales` holds the old theme after a switch
  (#11910). A copy of the options Map that the chart changed keeps the old ticks (F-P4, form F1).
  The restore of the recorded user `scales` object gives the new theme, keeps an imperative
  `title.text` edit and the identity of `chart.config.options`, and loses an edit of
  `scales.x.min` (form F2). A full copy of the input options loses both edits and the identity
  (form F3). The scale-reset form gives the bitmap of a new chart with the new theme and the
  edited title (Pf-B5). A removal with `'default'` still animates after 16 ms (F-P5).
- The colors plugin skips all datasets when one dataset holds a color (`plugin.colors.ts:113-121`).
  Thus a dataset that the plugin colorized after the creation, and that the widget did not record,
  keeps its old color at a switch and blocks the new palette for all datasets.
- Registered plugins come before the inline plugins of the config
  (`src/core/core.plugins.js@v4.6.1:125-144`). Thus an inline plugin runs its `beforeLayout`
  after the `beforeLayout` of the registered colors plugin.
- The light preset paints the pixels of an unthemed chart: 0 of 262144 pixels differ, in 16 of
  16 cases (8 types, colors plugin on and off) (F-P6).
- With one active element, the only setter values that are not the blue of the blue screen are
  `setFillStyle` and `setStrokeStyle` `#003CCA`, the `getHoverColor` of `#2050c0`, in 16 of 16
  cases. Each other pixel lies on the segment from the blue to `#003CCA` within 1 unit (bubble: 1
  pixel at 2 units) (F-P2, Pf-B7). The hover colors are the root scriptables of `core.defaults.js:62-64`.
- `Color.lerp(a, a, 0.3) != a`, and `Color.lerp` asserts that no input is extended sRGB
  (`dart:ui` `painting.dart:424-426`). A Display P3 color (0.8, 0.3, 0.2) gives
  `rgba(221, 64, 37, 1)` through `ColorSpace.extendedSRGB` and the clamp of `themeColorToRgba`; a
  direct sRGB conversion only clamps (F-P3).
- `TextStyle` gives the `FontSpec` fields: `fontFamily` and `fontFamilyFallback`, quoted except
  the CSS generic families, give `'Helvetica Neue', 'Helvetica', 'Arial', sans-serif` (S-PR3).
  The canvas maps `oblique` to italic, `lighter` to w100 and `bolder` to bold
  (`lib/src/canvas/canvas_ui_text.dart:232-248`), and `FontWeight` holds each value from 1 to
  1000. Only a `px` line height has no factor form (`src/helpers/helpers.options.ts@v4.6.1:22-41`).
- A font that the app loads at run time goes through the font manager of the platform: FreeType
  on Linux, CoreText on macOS (Flutter 3.47.7 `engine/src/flutter/lib/ui/text/font_collection.cc:163-164`,
  `txt/src/txt/platform_linux.cc:27-31`, `platform_mac.mm:9`). The `macos-latest` image moves.
- Contrast of the mirror dark preset: text `#999` on `#000` 7.37:1, tooltip text 13.08:1, grid
  1.20:1 (light: 5.74:1, 12.63:1, 1.25:1) (S-contrast).

## Decision

The theme is one more option scope for the ported resolver. The design is in
[theming.md](../theming.md).

- **One scope.** A theme compiles to one frozen map with the key shape of `Chart.defaults`. The
  raw config carries it under `$theme`. The resolver reads it between `overrides[type]` and
  `defaults` (`core.config.js:312-313, 336-337`). The scale merge reads it before the scale
  defaults (`:106-110`). User options and chart-type overrides thus beat the theme key by key.
  This is the per-chart override mechanism.
- **Eight marked hunks.** The hunks H0-H3 in `core.config` and H4a-H4c and H5 in `plugin.colors`
  carry `// DIVERGES(chartjs): <row id>, <reason>`, with the row ids `theme-H0` to `theme-H5`.
  Each hunk has one row in `doc/differences.md`. With no theme, the hunks have no effect.
- **The hunks change no upstream line.** Each hunk adds lines. H1 adds a `mergeIf` call before the
  unchanged upstream line. H4b and H4c add a theme branch before the unchanged `return` line of
  `getBorderColor` and `getBackgroundColor`:

  ```dart
  // DIVERGES(chartjs): theme-H4b, the theme palette comes first.
  final themeColors = _themeBorderColors;
  if (themeColors != null) return themeColors[i % themeColors.length];
  return _borderColors[i % _borderColors.length];
  ```

- **The palette comes from the theme of the chart.** H4a adds the two palette keys and two
  library variables after `BACKGROUND_COLORS` (`plugin.colors.ts:25`). H0 adds a public reader of
  the theme map of a chart configuration (`chartThemeOf`). Directly before `getColorizer`
  (`plugin.colors.ts:123`), H5 sets both variables from `plugins.colors.$borderColors` and
  `plugins.colors.$backgroundColors` of that theme map, Dart `null` included. H5 takes a List
  with at least one item. Any other value gives Dart `null`, thus the upstream palette. The
  colorizer runs synchronously after H5. Thus each chart gets the palette of its own theme. H5
  does not read the plugin options. A palette key in the user options, in `overrides[type]` or in
  `defaults` thus has no effect, as upstream. The user keeps the upstream controls: dataset
  colors, root or `elements` colors, `enabled: false` and `forceOverride`.
- **No writes to `Chart.defaults`.** The theme stays per subtree. The widget never writes
  `defaults` or `overrides` for theming.
- **The unthemed run is the oracle.** Ported specs and fixtures run with no theme. The colors
  plugin is off, as in upstream `test/index.js:25-28`.
- **Static values only.** The compiler emits colors, fonts, the palette and the theme transitions.
  It never emits behavior keys, root `backgroundColor`, `borderColor` or `font`, static hover
  colors, scale ids, `_` keys, other `$` keys, functions or nulls. The behavior keys include the
  data and decision keys `fill`, `spanGaps`, `showLine`, `stacked`, `reverse`, `min`, `max`,
  `suggestedMin`, `suggestedMax`, `beginAtZero`, `grace`, `bounds`, `base`, `skipNull` and
  `grouped` at any depth ([theming.md](../theming.md) §3.3 gives the upstream lines). The `''`
  scope of the theme comes before `defaults.datasets[type]`. The behavior keys also include the
  key paths that change data, item order, a position or a discrete decision:
  `plugins.decimation.algorithm`, `.samples` and `.threshold` (`plugin.decimation.js:269, 12,
  242`), `plugins.filler.propagate` (`plugin.filler/index.js:47`), `plugins.legend.reverse`
  (`plugin.legend.js:116-117`), `plugins.legend.rtl` (`plugin.legend.js:235-259`),
  `plugins.tooltip.position` (`plugin.tooltip.js:651, 1012, 1218`), `plugins.tooltip.xAlign` and
  `.yAlign` (`plugin.tooltip.js:273, 270`), `scale.labels` (`core.scale.js:360`) and
  `scale.ticks.stepSize`, `.count`, `.precision` and `.maxTicksLimit`
  (`scale.linearbase.js:32-104, 216-260`), and the content keys `text` of the title, the
  subtitle, the legend title and the scale title (`plugin.title.js:43, 97`,
  `plugin.legend.js:487`, `core.scale.js:102, 613`). A `scale.` path also applies under each
  `scales.<type>`. A flat `labels` is not a behavior key, because `plugins.legend.labels` holds
  the legend colors and fonts. A palette value is a List with at least one item. A debug assert
  and a test enforce this list. The guard `themeNeverEmittedReason` keeps this list for the raw
  Map themes of the tests. In 0.1.0 no public input reaches it (No public `raw` in 0.1.0).
- **The palette token.** A raw Map theme gives the palette as
  `palette: {colors: [...], backgroundAlpha: 0.5}`. The compiler emits the colors at their alpha
  as `$borderColors`. It emits the same colors with the alpha replaced by `backgroundAlpha` as
  `$backgroundColors`, as `plugin.colors.ts:25` derives `BACKGROUND_COLORS`. An absent
  `backgroundAlpha` is 0.5. An absent or empty `colors` List emits nothing
  (`compile.dart:709-711`), thus the upstream palette.
- **Two states.** Default and active. Hover colors keep the upstream derivation from the themed
  base color (`core.defaults.js:62-64`). There are no variants, no deltas, no code generation and
  no CLI.
- **The public classes.** The app library `flutter_chartjs_port.dart` (Chart.js ADR 0048) exports
  two names: `ChartTheme` and `ChartThemeData`. `ChartThemeData` is one flat class, as
  `IconThemeData`. It holds the tokens of theming.md §4 and stores nothing derived:

  ```dart
  /// The chart theme of a subtree. A ChartView below reads [maybeOf].
  class ChartTheme extends InheritedTheme {
    /// Gives [data] to the charts of [child].
    const ChartTheme({required this.data, required super.child, super.key});
    /// The theme. `const ChartThemeData()` themes nothing.
    final ChartThemeData data;
    /// The nearest theme, or Dart null: a chart then has the Chart.js look.
    static ChartThemeData? maybeOf(BuildContext context);
    /// The nearest theme, or `const ChartThemeData.light()`, for widgets
    /// other than charts.
    static ChartThemeData of(BuildContext context);
    @override Widget wrap(BuildContext context, Widget child);
    @override bool updateShouldNotify(ChartTheme oldWidget); // data differs
  }

  /// The tokens of a chart theme. A null token themes nothing. The
  /// Chart.js options of a chart beat each key of the theme.
  @immutable
  class ChartThemeData with Diagnosticable {
    /// A theme of the given tokens. `const ChartThemeData()` themes nothing.
    const ChartThemeData({this.color, this.borderColor, this.backgroundColor,
        this.surface, this.inverseSurface, this.onInverseSurface, this.font,
        this.pointLabelsFont, this.palette, this.paletteBackgroundAlpha = 0.5});
    const ChartThemeData.light(); // The presets.
    const ChartThemeData.dark();
    /// `Defaults.color` '#666' (core.defaults.js:43).
    final Color? color;
    /// `Defaults.borderColor` (core.defaults.js:42).
    final Color? borderColor;
    /// `Defaults.backgroundColor` (core.defaults.js:41) of the elements.
    final Color? backgroundColor;
    /// The arc border '#fff' (element.arc.ts:379) and, at alpha 0.75, the
    /// tick backdrop (core.scale.defaults.js:81).
    final Color? surface;
    /// The tooltip background 'rgba(0,0,0,0.8)' (plugin.tooltip.js:1279).
    final Color? inverseSurface;
    /// The '#fff' of the tooltip texts (plugin.tooltip.js:1280, 1287, 1292,
    /// 1305).
    final Color? onInverseSurface;
    /// `Defaults.font` (core.defaults.js:54-60). The theme reads fontFamily,
    /// fontFamilyFallback, fontSize, fontStyle, fontWeight and height.
    final TextStyle? font;
    /// The point-label font over [font] without its size
    /// (scale.radialLinear.js:383-385).
    final TextStyle? pointLabelsFont;
    /// The palette of the colors plugin (plugin.colors.ts:14-22). Null and
    /// an empty list keep the Chart.js palette.
    final List<Color>? palette;
    /// The alpha of the background colors of [palette] (plugin.colors.ts:25).
    final double paletteBackgroundAlpha;
    ChartThemeData copyWith({/* one nullable parameter for each field */});
    static ChartThemeData lerp(ChartThemeData a, ChartThemeData b, double t);
    // == and hashCode over all fields (palette by listEquals and
    // Object.hashAll); debugFillProperties.
  }
  ```

  - `ChartTheme.data` is non-null, as `IconTheme.data`. A chart reads `maybeOf`; Dart `null` gives
    the upstream look. There is no `context.chartTheme`.
  - The conversion to the raw Map theme of `compile.dart` is internal. A color converts with
    `withValues(colorSpace: ColorSpace.extendedSRGB)` and then clamps in `themeColorToRgba`. The
    class stores the color of the app. A font reads six `TextStyle` fields: the family string
    (each name quoted, except the CSS generic families), `fontSize` as `size`, `fontStyle` as
    `'normal'` or `'italic'`, `fontWeight.value` as a number and `height` as `lineHeight`. A null
    field is left out. The compile ignores the other `TextStyle` fields, with no assert, so that
    an app can give `textTheme.bodySmall`. A `px` line height, `'oblique'` and `'lighter'` stay
    in the chart options.
  - `lerp` returns `a` for `identical(a, b)`, as `ThemeData.lerp`. A token lerps only when both
    ends are non-null; else it switches at `t = 0.5`. Two fonts also switch at `t = 0.5` when one
    of them sets `fontSize`, `fontWeight` or `height` and the other does not, because
    `TextStyle.lerp` fills the missing field. Two palettes of the same length lerp pairwise; else
    they switch at `t = 0.5`. `paletteBackgroundAlpha` lerps and stays in [0, 1].
  - The compiled map of an instance is memoized per instance (an `Expando`). Thus the palette list
    must not change after the construction. A debug assert checks `paletteBackgroundAlpha` in
    [0, 1]. `paletteBackgroundAlpha` has no effect without `palette`. The colors plugin colors only
    datasets without colors (`plugin.colors.ts:102-125`).
  - The files `lib/src/theme/theme_data.dart` and `lib/src/theme/chart_theme.dart` import
    `dart:ui` and `widgets`. They are not pure layers. `compile.dart` and `presets.dart` stay pure
    and internal.
- **The presets.** `const ChartThemeData.light()` holds the Chart.js v4.6.1 defaults and the 7
  colors of `plugin.colors.ts:14-22` at alpha 1 with `paletteBackgroundAlpha` 0.5. A chart with it
  equals an unthemed chart. `const ChartThemeData.dark()` follows the mirror rule: each color
  token is `(1 - r, 1 - g, 1 - b)` of the light token with its alpha kept. Its values: `color`
  `#999999`, `borderColor` and `backgroundColor` white at alpha 0.1, `surface` `#000000`,
  `inverseSurface` white at alpha 0.8 and `onInverseSurface` `#000000`, with the light fonts, the
  Chart.js palette at 0.5 and the upstream hover derivation. An app with another background sets
  `surface` with `copyWith`. The opt-out is `const ChartThemeData()`: it compiles to Dart `null`
  (`compile.dart:645`). The raw Map presets `ChartThemes.light` and `ChartThemes.none` of
  `presets.dart` stay internal for the pure tests. The library exports no `ChartThemes`.
- **No public `raw` in 0.1.0.** The token emission (`_put` with its assert,
  `compile.dart:753-759`) is the allowlist of 0.1.0. No public input reaches a key outside the
  token table of theming.md §4: no behavior key, no box layout key (`position`, `align`,
  `fullSize`, `weight`, `padding`) and not `plugins.filler.drawTime`. The font token keeps its
  accepted layout cost. A later `raw` field needs a new ADR, with these conditions:
  - Trigger: an app asks for a theme-wide key without a token, or ADR: Typed options API decides
    component styles.
  - The form: an allowlist of normalized paths (a `scale.` path also under each `scales.<type>`),
    with the deny rules as a second gate. A path joins the list only with a style-only test on the
    8 chart types: with the key at a sentinel value, the chart area, the ticks, the element
    properties and the hit results equal the unthemed chart. Fonts are the one accepted layout
    exception.
  - The 38 candidate keys of F-P1 are its regression list. Test 4 reports an unclassified leaf.
- **Runtime switch.** Port-only code of the widget switches the theme. The widget runs it in its
  update callback (Chart.js ADR 0049). A theme change and a config change in one frame give one
  `chart.update` call. The steps:
  1. The effective theme is `widget.theme ?? ChartTheme.maybeOf(context)`. When it `==` the last
     applied theme, the widget does no work. Else it compiles the theme (memo). When the old and
     the new theme both compile to Dart `null`, the widget does no work.
  2. The widget writes the compiled map under `$theme` of its own root config, or removes the key.
     The root config is the shallow copy of the app config of Chart.js ADR 0049; `data` and
     `options` keep the identity of the app Maps. In debug mode an app value under `$theme` fails
     an assert (row `theme-H0`).
  3. The widget puts the recorded user `scales` object back into `options['scales']`, or removes
     the key when the app had none. It records the object before `new Chart` and at each new
     `options` object.
  4. The palette keys: the internal inline plugin of the widget (Chart.js ADR 0051) records in
     `beforeUpdate` the two keys `borderColor` and `backgroundColor` of each dataset object (value
     or absent). In its `beforeLayout`, after the colors plugin, it records each key that changed
     in this update as written by the colors plugin, with the value before the first write. At a
     switch the widget restores a key in place only when the dataset still holds the written
     value. Thus an app edit of a dataset color stays. The dataset objects keep their identity:
     the metasets, a hidden dataset and the controllers stay.
  5. `chart.update(mode)`: `'theme'` for a new theme; `'themeFrame'` under reduced motion;
     `'default'` at a removal. With the reduced-motion flag of Chart.js ADR 0049, each of these
     updates ends at once. The widget never uses `'none'` (the elements keep their old colors) or
     `'resize'` (it skips the radar line options, `controller.radar.js:61-62`). When the same
     callback also applies a new config, the one `update` call takes the theme mode.
- **Transitions.** 0.1.0 has no public transition API. The compiler keeps `transitions.theme` at
  200 ms `'linear'` and `transitions.themeFrame` at the duration 0 (`compile.dart:494-501`).
  Scales, legend, title and tooltip switch at once, as upstream does for any option change. A later
  public transition takes `easing` as a `String` key of `effects`
  (`src/helpers/helpers.easing.ts@v4.6.1:12-124`), with a debug assert on these keys, because
  `core.animation.js:36` reads `effects[cfg.easing] || effects.linear`. `ChartThemeTransition.frames`
  does not exist. A later ADR can add it only on an app request, and only when its benchmark
  passes: the p90 of `update+draw+end` is at most 4.17 ms at N 100 and at most 8.33 ms at N 1000
  on each deciding platform (rule F of the design panel).
- **No touch sizes.** The theme never carries touch sizes, in 0.1.0 or later. `hitRadius` and
  `hoverRadius` are behavior keys: the point hit test reads `hitRadius + radius`
  (`element.point.ts:62-66`), and an active point resolves `radius` from `hoverRadius`
  (`core.datasetController.js:815`). Touch never changes `interaction`. The font size is a style
  key that `font` gives (`TextStyle(fontSize: 14)`). Padding keys are box layout keys. An app that
  wants larger targets sets `elements.point.hitRadius` and `hoverRadius` in its options. A
  design-system adapter (after 0.1.0) can give config helpers, not theme keys.
- **No design-system dependency.** `lib/` imports neither forui nor Material. A forui adapter,
  `flutter_chartjs_port_forui`, comes after 0.1.0 with `forui: ^0.27.0`, `sdk: ^3.13.0` and
  `flutter: ">=3.47.0"`. The Material mapping is a snippet in the gallery, because
  `flutter/material.dart` and `material_ui` have distinct `ColorScheme` types.
- **The blue screen.** A test-support theme sets every token and the palette (alpha 1) to one
  blue, on a blue background. In all 8 chart types, with the title, the subtitle, the legend
  title and a visible tooltip, with the colors plugin on and off, every pixel is blue. The
  committed known-leaks list of the 8 chart types is empty. A pin case with a legend item without
  `fillStyle` and `strokeStyle` keeps its own committed list: `setFillStyle #666` and
  `setStrokeStyle #666`, the singleton read of `plugin.legend.js:286` at `:314` and `:319`. 16
  more cases have one active element (`chart.setActiveElements` for one element, the tooltip
  active, `update()`). Their known active setters are `setFillStyle` and `setStrokeStyle` of the
  value of the ported `getHoverColor` of the blue (bar: `setFillStyle` only). Each pixel that is
  not the blue lies on the segment from the blue to that value, within 2 units for each channel.
  `IdentityChartHover` is not needed for this test. It stays a later item of theming.md §5.2 with
  its condition.
- **Goldens.** Test 9 has two golden files on one bar chart: `const ChartThemeData.light()` and
  `const ChartThemeData.dark()` over the `surface` of the preset. The chart has 2 datasets, the
  title, the subtitle, the legend with its title, the scale titles and a visible tooltip, with
  `animation: false`, at 800 x 600 and DPR 1. The harness font Liberation Sans 2.1.5 draws the
  text (Chart.js ADR 0015). The test checks that each draw-call `font` names an installed family.
  The pinned runner is `ubuntu-24.04` in the CI job `fixtures`. Only a `workflow_dispatch` run of
  that job writes the files. A change of `.fvmrc` updates the goldens in the same change. `none`
  needs no golden file: a test on the three OS of the `test` job checks that the light preset
  gives the bytes of an unthemed chart (16 cases).
- **Acceptance.** Phase numbers are those of [porting-flow.md](../porting-flow.md) §5. The four
  invariants (Consequences) are in force from phase 1. The hunks H0-H5 landed in phases 5 and 8.
  The porting lead accepts this ADR when the public classes, the presets, the switch and the tests
  land, and these gates are green: tests 7, 8 and 9 of theming.md §8, the 16 active cases of the
  blue screen, the light identity on the three OS, and the `fixtures` job with the goldens.
  Chart.js ADR 0042 then gets only the line "Superseded by Chart.js ADR 0050". The result
  (2026-10-30): tests 7 and 8, the 16 active cases of the blue screen and the light identity pass
  in `test --no-select`. CI run 41021651401 at `ec7d85c` passes the job `test` on the three OS
  and the job `fixtures`, with its step "Compare the theme goldens" (test 9).

## Changes from Chart.js ADR 0042

1. The public classes are `ChartTheme` (non-null `data`) and one flat `ChartThemeData` with 6
   `Color?` tokens, 2 `TextStyle?` fonts, `palette` and `paletteBackgroundAlpha`. Chart.js ADR 0042
   named `ChartThemeData(colors, typography, palette, raw)`.
2. The public palette type is `List<Color>? palette` with `paletteBackgroundAlpha` (Open 3).
3. 0.1.0 has no public `raw`. The token emission is the allowlist. The bullet gives the condition
   of a later `raw` (Open 3). No public input reaches the box layout keys (Open 1) or
   `plugins.filler.drawTime` (Open 2).
4. The presets are `const ChartThemeData.light()` and `.dark()`, with the mirror rule for dark.
   The opt-out is `const ChartThemeData()`. The library exports no `ChartThemes` and no `none`.
5. The switch restores the recorded user `scales` object in place, not "a fresh copy of the user
   options". It restores a palette key only when the dataset still holds the value that the colors
   plugin wrote, with records from the widget plugin in each update. It skips equal themes. The
   consequence narrows: a switch loses only the imperative edits of `chart.options.scales`.
6. A removal under reduced motion ends at once through the reduced-motion flag of Chart.js ADR
   0049. It needs no transitions-only scope.
7. Transitions stay fixed in 0.1.0. A later `easing` is a `String`. `frames` does not exist.
8. The blue screen gets 16 cases with an active element. Open 4 closes without
   `IdentityChartHover`.
9. Test 9 has two goldens on `ubuntu-24.04` in the `fixtures` job, and the light identity test.
10. The theme never carries touch sizes. This withdraws the theming.md §5.2 row "`touch` flag,
    `ChartSizes`" and closes theming.md §11 question 1 and the "Touch sizes" item of Chart.js ADR
    0037 §16.
11. The citations are at `v4.6.1`.

## Consequences

- Upstream fixes replay without changes to theme code. A bump or an
  [ADR 0006](../../../../docs/adr/0006-follow-upstream-between-releases.md) backport into
  `core.config.js` or `plugin.colors.ts` re-applies the eight hunks and runs their pinning tests.
- All hunks add lines. Each upstream line stays verbatim. Thus a bump that changes an upstream
  line of a hunk host replays without a conflict in that line.
- Chart-type overrides beat the theme. A theme cannot restyle a key that a chart type sets in
  `overrides[type]`.
- For the keys it emits, a theme beats app code that changes `Chart.defaults`.
- The palette has one source: the theme. An app that wants another palette for one chart gives
  that chart its own theme, or sets the dataset colors.
- A theme switch loses the imperative edits of `chart.options.scales`. Other imperative edits of
  `chart.options` stay, and `chart.config.options` keeps its identity. Element colors animate.
  Scales, legend, title and tooltip switch at once.
- After a switch, a dataset that the app colored keeps its color. Then the colors plugin colors no
  dataset, as for a new chart with that dataset color (`plugin.colors.ts:113-121`).
- Each bump reviews the defaults that the presets restate. The coverage snapshot test compares the
  compiled light preset with the defaults inventory of the upstream manifest. It reports added,
  removed and changed keys. The palette is a module constant, not a default. The test names it
  with its upstream lines (`plugin.colors.ts:14-25`), and test 3 compares its values. The dark
  preset follows the light preset by the mirror rule, with no review of its own.
- Some singleton reads stay out of reach of the theme, for example `plugin.legend.js:286` and
  `helpers.options.ts:117`. [theming.md](../theming.md) §9 lists these reads for each bump.
- The cost is small. H5 reads two Map keys one time for each colorize: 0.04-0.06 µs. The getter
  branch costs 0.3 ns (AOT) and 1.3 ns (dart2wasm) more than upstream for each call. An equal
  theme costs one `==`. The night record B-R1 (spec of phase 9) gives the switch figures to
  [performance.md](../performance.md). No decision depends on them.
- Four invariants apply from phase 1. AGENTS.md rule 5 and tool 1 enforce them:
  1. Specs run unthemed.
  2. `lib/` imports no forui or Material.
  3. Ported code never writes `Chart.defaults` for theming.
  4. Ported files never import `lib/src/theme/`. A ported file can import `core.config.dart`.
     Thus `plugin.colors.dart` reads the theme through `chartThemeOf`.
- The public names are `ChartTheme` and `ChartThemeData` with its fields and two named
  constructors. A field with a default value adds later with no break, and a removed field breaks
  apps. Thus a later `raw`, transition or hover strategy is an addition.
- The golden files depend on the Flutter engine and on the image `ubuntu-24.04`. A toolchain move
  writes them again in the same change. A local Mac never writes them.
- First-party design-system adapters take the name `flutter_chartjs_port_<system>` (ADR 0007) and
  stay `publish_to: none` until their first release. Chart.js ADR 0049 decides reduced motion.

## Alternatives considered

| Option | Chosen | Reason |
|---|---|---|
| Theme in `Chart.defaults`, in the user options, or as a scope | a scope | Defaults are global. A changed default disables the palette. Tokens in the user's `options.scales` create axes on a doughnut |
| H5 reads the plugin options (Chart.js ADR 0001) | no | A user, `overrides[type]` or `defaults` key `$borderColors` changes an unthemed chart |
| An argument for the palette in place of the variables | no | It changes six upstream signatures |
| Nested classes `ChartColors`, `ChartTypography`, `ChartFont` (Chart.js ADR 0042, theming.md §5.1) | no | Ties on behavior, performance and structure. The flat class writes `copyWith`, `lerp`, `==`, `hashCode` and diagnostics once, not 4 or 5 times. 2 public names, not 5 |
| `ChartFont` with `FontStyle` and `FontWeight` | no | `TextStyle` brings `lerp`, `==` and diagnostics. The canvas gives each keyword the same font as a `TextStyle` value |
| `ChartPalette({colors, backgroundAlpha})` | no | The flat pair needs no class and maps to the same palette token |
| A record palette | no | A record compares its List by identity: equal palettes give a switch |
| Public `raw` with a deny list (the guard) | no | F-P1: the guard passes `hitRadius`, `arc.borderWidth` and `ticks.autoSkip` |
| Public `raw` with a hand allowlist (about 50 paths) or a generated allowlist (about 140 paths) | not in 0.1.0 | No preset needs a `raw` key. A later `raw` is additive. The bullet keeps the form for that ADR |
| `ChartThemes.light`, `.dark`, `.none` as static fields | no | Const named constructors follow `ColorScheme.light` and `.dark`, with no extra public name |
| A dark preset of hand-picked colors (`#A3A3A3` on `#16181C`, or `#121212`) | no | The mirror rule needs no choice, passes 4.5:1, and gives a one-line test |
| The switch assigns a fresh copy of the user options (Chart.js ADR 0042) | no | F-P4 F1: a copy of the Map that the chart changed keeps the old ticks. F3 loses all edits and the identity |
| A shallow pristine copy of the options | no | It loses the top-level edits and the identity of the options |
| A new chart for each theme | no | A hidden dataset shows again, and the entry animation replays |
| Palette keys recorded only at the creation and at config updates | no | A dataset that the plugin colors later keeps its old color and blocks the new palette |
| A frozen transitions-only scope for a removal under reduced motion (F-P5) | no | The reduced-motion flag of Chart.js ADR 0049 ends the `'default'` update at once |
| `easing` as an enum or a Flutter `Curve` | no | A new upstream easing breaks an enum switch. `core.animation.js:36` gives linear for a function |
| `ChartThemeTransition.frames` in 0.1.0 | no | One full update for each frame: R2 costs 5.173 ms on the Pixel 8a (performance.md §14.7) |
| A test-only identity hover for the active blue screen | no | The setter check finds any other color. It tests a form that `lib/` does not have |
| Goldens on `macos-latest`, a new job, the three OS with a tolerance, or a JSON of draw calls | no | CoreText of a moving image; one more runner; a tolerance hides leaks; no raster check |
| Touch sizes in a later `touch` flag or `ChartSizes` | no | Both radii are behavior keys. Static values only forbids them |
| Datasets on a switch: copies or an in-place restore | in-place restore | A new dataset object loses its meta and legend visibility |
| Material mapping: a package or a snippet | a snippet | The two Material libraries have distinct `ColorScheme` types |

## Open

1. Whether the Linux FreeType comes from the engine build or from the runner image is not known.
   The runner stays pinned to `ubuntu-24.04` until a change of the image is tested.
2. Typed component styles (theming.md §11 question 4): ADR: Typed options API decides them after
   0.1.0.
3. Hover strategies (`IdentityChartHover`, `LightnessChartHover`), `AnimatedChartTheme` and
   `ChartThemeExtension` wait for their conditions of theming.md §5.2.

Chart.js ADR 0042 Open 1, 2, 3 and 4 close (Changes 2, 3 and 8).

## Evidence

The probes are working files of the phase 9 design panel B in `.handover/phase9/panel/probes/`,
not committed. Dart is 3.13.5 and Flutter 3.47.7, on the VM. No probe was a timed run.

| Probe | Files | Result |
|---|---|---|
| F-P1 | `b-fidelity/p1_guard_test.dart`, `p1_out.txt` | The guard passes 38 of 38 candidate keys. `hitRadius: 8` changes the hit element, `autoSkip: false` the x ticks (20 to 60) |
| F-P2, Pf-B7 | `b-fidelity/p2_blue_active_test.dart`, `p2_out.txt`; `b-performance/b7_active_blue_test.dart.txt`, `.out.txt` | 16 active cases: only `#003CCA` = `getHoverColor(#2050c0)`; the other pixels lie on the segment |
| F-P3 | `b-fidelity/p3_color_test.dart`, `p3_out.txt` | Display P3 to `rgba(221, 64, 37, 1)`; `Color.from(alpha: 0.1)` exact; `Color.lerp(a, a, 0.3) != a` |
| F-P4 | `b-fidelity/p4_switch_test.dart`, `p4_out.txt` | Forms F0 to F3 of the switch (Context) |
| F-P5 | `b-fidelity/p5_removal_test.dart`, `p5_out.txt` | A removal with `'default'` runs after 16 ms |
| F-P6 | `b-fidelity/p6_light_pixels_test.dart`, `p6_out.txt` | 16 cases: the light preset and no theme give equal pixels |
| S-contrast | `b-simplicity/contrast.py`, `contrast_output.txt` (also F-P7, Pf-B4) | Contrast of the presets |
| Pf-B3 | `b-performance/b3_allowlist_classes.py`, `.out.md` | 340 leaves: 89 paint, 48 layout, 6 hit |
| Pf-B5 | `b-performance/b5_switch_test.dart.txt`, `b5_switch.out.txt` | The scale reset gives the bitmap of a new chart (`bffa33e0`) |
| S-PR2, S-PR3 | `b-simplicity/probe_b_simplicity_test.dart.txt`, `probe_output.txt` | `update('theme')` in a widget callback; the family string |
| Flutter 3.47.7 | `widgets/icon_theme.dart:43`, `material/theme_data.dart:1938-1941`, `material/color_scheme.dart:488, 622`, `dart:ui` `painting.dart:153, 424-426`, `text.dart:62-74` | `IconTheme.data` non-null; `lerp` of identical themes; const named constructors; `Color.from` const; the lerp assert; the weight range |
