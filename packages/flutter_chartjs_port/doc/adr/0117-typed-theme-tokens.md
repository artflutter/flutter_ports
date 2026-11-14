# Chart.js ADR 0117: The theme compiles from typed tokens

- Status: accepted (2026-11-12): its code and the tests of section Tests pass.
- Superseded in part by: [Chart.js ADR 0118](0118-theme-compile-typed-setters.md) (2026-11-12)
- Date: 2026-11-12
- Supersedes: parts of [Chart.js ADR 0050](0050-public-theme-api.md): the raw Map theme as the input of
  `compileChartTheme` (the fields `colors`, `typography`, `palette` and `raw`), the conversion to the raw Map theme in
  "The public classes" (a color through `ColorSpace.extendedSRGB` and the clamp of `themeColorToRgba`), the raw Map
  presets `ChartThemes.light` and `ChartThemes.none` in "The presets", the form
  `palette: {colors: [...], backgroundAlpha: 0.5}` in "The palette token", and the sentence "The guard
  `themeNeverEmittedReason` keeps this list for the raw Map themes of the tests".
- Related: Chart.js ADR [0054](0054-typed-internal-model.md) (the compiled theme is a frozen typed scope),
  [0061](0061-native-flutter-colors.md) (a color keeps its identity and its color space),
  [0116](0116-text-style-fonts.md) (the font is a Flutter `TextStyle`) and [0052](0052-typed-public-api.md) (the
  typed public API).

## Context

Before this decision, `compileChartTheme` took a raw Map theme with the fields `colors`, `typography`, `palette` and
`raw`. Each token name was a string key of that Map. A color token was a `RawThemeColor` record of sRGB components.
`themeDataToRaw` of `theme_data.dart` converted a `ChartThemeData` to the Map. It converted each color with
`Color.withValues(colorSpace: ColorSpace.extendedSRGB)`, and `themeColorToRgba` clamped it. The compile then made a
`Color` again with 8-bit channels. Thus a Display P3 color of an app became an sRGB color.

The field `raw` gave keys outside the token table. No public input had it: only the tests gave it. The internal
presets `ChartThemes.light` and `ChartThemes.none` were raw Map themes for the pure tests. The internal file
`lib/src/theme/css.dart` had the conversions `rawColorOf` and `colorToRgba`. The maintainer rejects each such
conversion: the core takes the native type and uses it.

## Decision

1. `compileChartTheme` takes the tokens as named parameters: `color`, `borderColor`, `backgroundColor`, `surface`,
   `inverseSurface` and `onInverseSurface` (each a `Color?`), `font` and `pointLabelsFont` (each a `TextStyle?`),
   `palette` (a `List<Color>?`) and `paletteBackgroundAlpha` (a `double`, 0.5 by default). It emits the keys of
   theming.md §4 in the same order as before.
2. The compiled theme holds each color token as the app gives it. The compile does not round a channel, clamp a
   color or change its color space. The palette background colors are `color.withValues(alpha:
   paletteBackgroundAlpha)`, as `plugin.colors.ts:25` derives `BACKGROUND_COLORS`. The tick backdrop is
   `surface.withValues(alpha: 0.75)`.
3. `compileThemeData(ChartThemeData)` gives the fields of the class to `compileChartTheme`. `compile.dart` stays a
   pure layer, so it does not import `ChartThemeData`, which uses `Diagnosticable` of the foundation library.
4. The pure `presets.dart` holds `LightThemeTokens`: the static constants of the light tokens at their Chart.js
   v4.6.1 values. `ChartThemeData.light()` takes all its tokens from it, and `.dark()` takes its fonts and its
   palette from it. The pure tests compile the same constants (`compileLightTheme()` of
   `test/support/light_theme.dart`). The library exports no `LightThemeTokens`.
5. Gone: the raw Map theme, the field `raw`, `RawThemeColor`, `themeColorValue`, `themeColorToRgba`, `themeDataToRaw`,
   `ChartThemes.light`, `ChartThemes.none` and `lib/src/theme/css.dart` with `rawColorOf` and `colorToRgba`.
6. The emission guard `themeNeverEmittedReason` stays as the debug assert of each emitted key. No input reaches a key
   outside the token table.
7. A `$theme` value of a raw chart config can still be a Map: it is a part of the raw config, not an input of the
   compile.

## Consequences

- A Display P3 color token stays a P3 color, and the chart draws it as the app gives it.
- The light and dark presets give the same pixels as before: their channels are exact 8-bit values. The dark
  `1 - 0.4` is `0.6`, that is `153 / 255`. The theme goldens update only on the Ubuntu CI job. That job confirms this.
- A later public `raw` field needs a new ADR, as Chart.js ADR 0050 states. It also needs a new typed input of the
  compile.
- The tests of the guard call `themeNeverEmittedReason` directly, because no input gives a key outside the token
  table.

## Tests

- `test/port/theme/compile_test.dart`: the keys of each token, the palette, the point-label font, the guard, the deep
  freeze and no memo.
- `test/port/theme/theme_data_test.dart`: the presets, the token allowlist and the compile of `ChartThemeData`.
- `test/port/theme/precedence_test.dart`, `presets_test.dart`, `presets_plugins_test.dart`,
  `presets_radial_test.dart`, `coverage_test.dart` and `target_platform_test.dart`, and the light-preset groups of the
  controller and plugin reference tests: the light tokens through `compileLightTheme()` give an unthemed chart.
- `test/port/theme/light_pixels_test.dart` and `blue_screen_test.dart`: the pixels of `ChartThemeData.light()` and of
  a blue theme through `compileThemeData`.
- The theme goldens of the CI job `fixtures`: the pixels of the light and dark presets.
