# Chart.js ADR 0147: The public theme API

- Status: accepted (2026-11-14): it restates accepted decisions, and the code passes the tests.
- Date: 2026-11-14
- Supersedes: [Chart.js ADR 0050](0050-public-theme-api.md), [Chart.js ADR 0117](0117-typed-theme-tokens.md) and
  [Chart.js ADR 0118](0118-theme-compile-typed-setters.md) as a whole, and the theme parts of
  [Chart.js ADR 0054](0054-typed-internal-model.md) (the theme memos of §4 and §18 and the `JsFrozenMap` sentence of
  §19), [Chart.js ADR 0057](0057-direct-typed-colors.md) (the sentence on theme compilation),
  [Chart.js ADR 0116](0116-text-style-fonts.md) (the theme in items 1 and 2),
  [Chart.js ADR 0128](0128-chart-paint-options.md) (the sentence on theme tokens) and
  [Chart.js ADR 0141](0141-native-scale-border.md) item 6
- Related: [theming.md](../theming.md), [Chart.js ADR 0049](0049-chart-view-widget.md),
  [Chart.js ADR 0051](0051-input-events-and-interaction-state.md)

## Context

Chart.js themes through the global `Defaults.color`, `borderColor`, `backgroundColor` and `font`
(`core.defaults.js:41-60`). A change disables the colors plugin (`plugin.colors.ts:90-92, 119`). A Flutter app
needs a theme for each subtree and a switch at run time. The ported files stay close to upstream (`v4.6.1`).

## Decision

1. **One scope.** A theme compiles to one deep-frozen typed `ChartOptionsScope`, the kind of `Chart.defaults`. The
   root config holds it under `$theme`. The resolver reads it between `overrides[type]` and `defaults`
   (`core.config.js:312-313, 336-337`), and the scale merge reads it before the scale defaults (`:106-110`). Thus the
   user options and the chart-type overrides beat the theme key by key. `_themeOf` also reads a Map under `$theme`
   of a raw `Chart` config.
2. **Eight marked hunks.** H0-H3 in `core.config.dart` and H4a-H4c and H5 in `plugin.colors.dart` carry
   `// DIVERGES(chartjs): theme-H<n>, <reason>`, each with one row in `doc/differences.md`. H0 adds `themeConfigKey`,
   `_themeOf` and the public reader `chartThemeOf`. With no theme, the hunks have no effect.
3. **The hunks change no upstream line.** Each hunk adds lines before an unchanged upstream line. Thus a bump has no
   conflict in these lines.
4. **The palette comes from the theme of the chart.** H4a adds the keys `$borderColors` and `$backgroundColors` and
   two library variables after `BACKGROUND_COLORS` (`plugin.colors.ts:25`). Just before `getColorizer` (`:123`),
   H5 sets both variables from `plugins.colors` of `chartThemeOf(config)`. Only a List with at least one item counts,
   else the upstream palette stays. Thus each chart gets the palette of its own theme. H5 does not read the plugin
   options: a palette key in the options or the defaults has no effect.
5. **No writes to `Chart.defaults`.** The widget never writes `defaults` or `overrides` for theming.
6. **The unthemed run is the oracle.** The specs and fixtures run with no theme and with the colors plugin
   off (`test/index.js:25-28`).
7. **Static values only.** `t.ticks.color = ChartPaint.solid(color)`: the compiler writes each key of the token
   table of theming.md §4 with the typed setter of its scope. It writes the keys in the order of the token table.
   Each scope keeps the order of its first writes. The scale type `radialLinear` and the modes `theme` and
   `themeFrame` stay keys by name, as `OptScope` cells. The compiler has no guard. The token table has no key of the
   never-emitted list of theming.md §3.3.
8. **The palette token.** `palette` emits `plugins.colors.$borderColors`, the colors as the app gives them, and
   `$backgroundColors`, each color `withValues(alpha: paletteBackgroundAlpha)` (`plugin.colors.ts:25`). A null or
   empty `palette` emits nothing. Each palette List holds `Color`s and is frozen. The colorizers write
   `ChartPaint.solid` of a palette color.
9. **Two states.** Default and active. The hover colors keep the upstream derivation from the themed base color
   (`core.defaults.js:62-64`).
10. **The public classes.**

    ```dart
    const ChartTheme({required ChartThemeData data, required Widget child}); // an InheritedTheme
    const ChartThemeData({Color? color, Color? borderColor, Color? backgroundColor, Color? surface,
        Color? inverseSurface, Color? onInverseSurface, TextStyle? font, TextStyle? pointLabelsFont,
        List<Color>? palette, double paletteBackgroundAlpha = 0.5});
    ```

    - The app library exports `ChartTheme`, `ChartThemeData`, `compileChartTheme`, `LightThemeTokens`,
      `chartThemeOf` and `themeConfigKey`. It hides `compileThemeData`, `ChartThemeSwitch` and the two palette keys.
    - A chart reads `ChartTheme.maybeOf`: Dart `null` gives the Chart.js look. `ChartTheme.of` falls back to
      `.light()`. `ChartView.theme` replaces the inherited theme. `ChartTheme.updateShouldNotify` compares the data
      with `==`.
    - `ChartThemeData` stores the values of the app and nothing derived. It has `copyWith`, a deep `==` and
      diagnostics. A debug assert checks that `paletteBackgroundAlpha` is from 0 to 1.
    - `lerp` gives `a` for `identical(a, b)`. It switches at `t = 0.5` for a token that one end lacks, and for
      palettes of different lengths. Two fonts also switch when only one sets `fontSize`, `fontWeight` or
      `height`. Else the values interpolate, and `paletteBackgroundAlpha` clamps to [0, 1].
    - `compileChartTheme` takes the ten tokens as named parameters, and the internal `compileThemeData` gives it the
      fields of a `ChartThemeData`. Neither has a memo.
    - A color key holds `ChartPaint.solid(token)`: no 8-bit rounding, no clamp and no change of the color space. The
      tick backdrop is `surface.withValues(alpha: 0.75)`.
    - A font key holds the `TextStyle` token. The title, the subtitle and the tooltip title and footer get a
      `ChartTextStyle` copy without its weight, because upstream sets their weights. The point labels get a copy
      without its size, with `pointLabelsFont` over it. A font with no field that the chart reads emits nothing. The
      color of a `TextStyle` token has no effect: the color tokens color the text.
    - The `borderColor` token writes `scale.border` as `AxisBorder(color: ...)` and an empty `RadialAxisBorder`
      under `scales.radialLinear`.
    - Each scope is frozen. Thus a write of a resolver set trap throws a `TypeError` (`helpers.config.ts:101-106`).
      The `transitions` keys come only beside other keys.
    - `theme_data.dart` and `chart_theme.dart` import Flutter. `compile.dart` and `presets.dart` are core layers.
11. **The presets.** `const ChartThemeData.light()` takes the constants of `LightThemeTokens` of `presets.dart`: the
    Chart.js defaults and the 7 colors of `plugin.colors.ts:14-22` at alpha 1. A chart with it equals an unthemed
    chart. The pure tests and the light-preset groups of the reference tests compile the same constants through
    `compileLightTheme()` of `test/support/light_theme.dart`. `const ChartThemeData.dark()` mirrors each light color
    token to `(1 - r, 1 - g, 1 - b)` and keeps its alpha. It keeps the light fonts and palette. The opt-out
    `const ChartThemeData()` compiles to Dart `null`.
12. **No public `raw` in 0.1.0.** The token table is the allowlist. No public input reaches a behavior key, a box
    layout key (`position`, `align`, `fullSize`, `weight`, `padding`) or `plugins.filler.drawTime`. A later `raw`
    field needs a new ADR and a typed input of the compile. Its form is an allowlist of normalized paths, with the
    never-emitted list as a second gate. A `scale.` path also applies under each `scales.<type>`. A path joins only
    after a style-only test on the 8 chart types. With the key at a sentinel value, the chart area, the ticks, the
    element properties and the hit results equal the unthemed chart. The 38 candidate keys of the old guard are the
    regression list. The font is the one accepted layout exception.
13. **Runtime switch.** `ChartThemeSwitch` runs in the post-frame update callback of `ChartView`
    ([Chart.js ADR 0049](0049-chart-view-widget.md) §4). A theme change and a config change in one frame give one
    `chart.update`. The steps:
    1. The effective theme is `widget.theme ?? ChartTheme.maybeOf(context)`. A theme that is `==` to the applied
       theme gives no work, and so do two themes that compile to Dart `null`. Else the switch compiles the theme
       once and keeps the scope, so the palette List must not change.
    2. The widget writes the scope under `$theme` of its own typed root, or removes the key. `data` and `options`
       keep the identity of the app values. An app value under `$theme` fails a debug assert.
    3. `mergeScaleConfig` keeps the old theme in its merged copy (#11910). Thus the widget puts back the user
       `scales` object that it recorded before `new Chart` and at each new options object, or removes the key.
    4. The inline plugin `$chartView` records the palette keys of each dataset in `beforeUpdate` and after the colors
       plugin in `beforeLayout`. A switch restores a written key to its value before the first write, or deletes it
       when it was absent. It restores only when the dataset still holds the written value. Thus an app edit stays,
       and each dataset keeps its identity, meta and hidden state.
    5. One `chart.update(mode)`: `'theme'`, `'themeFrame'` under reduced motion, or `'default'` at a removal. The
       theme mode wins over `updateMode`. Under the reduced-motion flag of
       [Chart.js ADR 0049](0049-chart-view-widget.md) §7, the update ends at once. The widget never uses `'none'`,
       which keeps the old colors, or `'resize'`, which skips the radar line options.
14. **Transitions.** 0.1.0 has no public transition API. The compiler writes `transitions.theme` with 200 ms and
    `Curves.linear`, and `transitions.themeFrame` with the duration 0. A later public transition takes a Flutter
    `Curve`, as each `easing` option does
    ([Chart.js ADR 0145](0145-native-option-types.md) item 6, row `adapt-flutter-curves`).
    `ChartThemeTransition.frames` does not exist. A later ADR can add it on an app request. Its condition: the p90 of
    `update+draw+end` is at most 4.17 ms at N 100 and 8.33 ms at N 1000 on each deciding platform.
15. **No touch sizes.** The theme never carries touch sizes. Touch never changes `interaction`. `hitRadius` and
    `hoverRadius` are behavior keys (`element.point.ts:62-66`, `core.datasetController.js:815`). An app sets them
    in its options.
16. **No design-system dependency.** `lib/` imports no forui, Material (`flutter/material.dart`, `material_ui`) or
    Cupertino (`flutter/cupertino.dart`). The Material mapping is a gallery snippet.
17. **The blue screen.** A test theme sets each token and the palette to one blue, on a blue background. In the 8
    chart types, with the titles, a tooltip and the colors plugin on and off, each pixel is blue. The known-leaks
    list is empty. A pin case lists the `#666` of `plugin.legend.js:286`. In 16 cases with one active element, the
    only other setters take the `getHoverColor` of the blue. Each other pixel lies within 2 units of the line from
    the blue to that color.
18. **Goldens.** Two golden files show one bar chart with the titles, the legend and a tooltip, under `.light()` and
    `.dark()`. The chart lies over the `surface` of the preset, with `animation: false`, at 800 x 600 and DPR 1, in
    Liberation Sans 2.1.5. The test checks that each draw-call font names an installed family. The pinned runner is
    `ubuntu-24.04` in the CI job `fixtures`. Only a `workflow_dispatch` run of that job writes the files. A change
    of `.fvmrc` updates them. A test on three OS checks that the light preset paints the bytes of an unthemed chart.
19. **The four invariants.** `check:lib-imports` enforces invariants 2 and 4.
    1. The specs run unthemed.
    2. `lib/` imports no forui, Material or Cupertino.
    3. Ported code never writes `Chart.defaults` for theming.
    4. Ported files never import a file of `lib/src/theme/` directly: the check tests the direct imports.
       `plugin.colors.dart` imports the app library, which exports the theme files, and reads the theme only through
       `chartThemeOf`.

## Rejected

- The theme in the user options: theme scales add axes.
- A public `raw` with a deny list: it passed `hitRadius`, `arc.borderWidth` and `ticks.autoSkip`.
- A raw Map theme with a conversion of `Color` and `TextStyle`: the core takes the native type.
- A copy of the options or a new chart at a switch: the old ticks stay, or the hidden datasets show again.
- Goldens on `macos-latest` or with a tolerance: that image moves, and a tolerance hides leaks.

## Consequences

- A bump into `core.config.js` or `plugin.colors.ts` re-applies the eight hunks and runs their tests.
- For its keys, a theme beats a change of `Chart.defaults`.
- A switch loses only the imperative edits of `chart.options.scales`.
- Each bump reviews the defaults that `LightThemeTokens` restates, through the coverage snapshot test. The test
  reports added, removed and changed keys. It lists the palette as the module constant of `plugin.colors.ts:14-25`.
  The dark preset needs no review of its own. Each bump also checks the singleton reads of theming.md §9.
- Figures: performance.md §14.5 and §14.7. The design probes are in
  [Chart.js ADR 0050](0050-public-theme-api.md)
  (`git show ac269e6f:packages/flutter_chartjs_port/doc/adr/0050-public-theme-api.md`).

## Open

1. The source of the Linux FreeType is not known. The runner stays `ubuntu-24.04` until a test of a new image.
2. Typed theme component styles wait for the typed options API ([Chart.js ADR 0052](0052-typed-public-api.md)
   Open 5).
3. Hover strategies, `AnimatedChartTheme` and `ChartThemeExtension` wait for their conditions of theming.md §5.2.

## Tests

- `test/port/theme/compile_test.dart`, `theme_data_test.dart`, `chart_theme_test.dart`, `coverage_test.dart`
- `test/port/theme/presets_plugins_test.dart`, `target_platform_test.dart`, `decimation_theme_test.dart`
- `test/port/theme/light_pixels_test.dart`, `blue_screen_test.dart`, `goldens_test.dart`
- `test/port/widgets/chart_theme_switch_test.dart`
- `test/port/core/core.config_test.dart`, `test/port/plugins/plugin.colors_test.dart`
