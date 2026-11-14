# Chart.js ADR 0117: The theme compiles from typed tokens

- Status: accepted (2026-11-12): its code and the tests of section Tests pass.
- Superseded in part by: [Chart.js ADR 0118](0118-theme-compile-typed-setters.md) (2026-11-12)
- Superseded by: [Chart.js ADR 0147](0147-public-theme-api.md) (2026-11-14)
- Date: 2026-11-12
- Supersedes: parts of [Chart.js ADR 0050](0050-public-theme-api.md): the raw Map theme as the input of
  `compileChartTheme` (the fields `colors`, `typography`, `palette` and `raw`), the conversion to the raw Map theme in
  "The public classes" (a color through `ColorSpace.extendedSRGB` and the clamp of `themeColorToRgba`), the raw Map
  presets `ChartThemes.light` and `ChartThemes.none` in "The presets", the form
  `palette: {colors: [...], backgroundAlpha: 0.5}` in "The palette token", and the sentence "The guard
  `themeNeverEmittedReason` keeps this list for the raw Map themes of the tests".
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:packages/flutter_chartjs_port/doc/adr/0117-typed-theme-tokens.md`

## Summary

This ADR made `compileChartTheme` take ten typed tokens as named parameters, in place of a raw Map theme. The
compiled theme held each color as the app gave it, with no rounding, no clamp and no change of the color space.
`LightThemeTokens` of `presets.dart` held the light tokens. The raw Map theme, the field `raw` and the color
conversions went away. [Chart.js ADR 0147](0147-public-theme-api.md) now states the complete theme decision.

## Where each part went

- Item 1 (the ten tokens as named parameters of `compileChartTheme`):
  [Chart.js ADR 0147](0147-public-theme-api.md) §7 and §10.
- Item 2 (each color as the app gives it, the palette and backdrop alphas):
  [Chart.js ADR 0147](0147-public-theme-api.md) §8 and §10.
- Item 3 (`compileThemeData` and a pure `compile.dart`): [Chart.js ADR 0147](0147-public-theme-api.md) §10.
- Item 4 (`LightThemeTokens` of `presets.dart`): [Chart.js ADR 0147](0147-public-theme-api.md) §11. The export rule
  changed: [Chart.js ADR 0147](0147-public-theme-api.md) §10.
- Item 5 (the removed raw Map theme, `raw` and color conversions): [Chart.js ADR 0147](0147-public-theme-api.md)
  Rejected.
- Item 6 (the emission guard as a debug assert): [Chart.js ADR 0147](0147-public-theme-api.md) §7.
- Item 7 (a Map under `$theme` of a raw chart config): [Chart.js ADR 0147](0147-public-theme-api.md) §1.
- Consequences (the Display P3 colors, the pixels of the presets and a later `raw`):
  [Chart.js ADR 0147](0147-public-theme-api.md) §10 and §12.
