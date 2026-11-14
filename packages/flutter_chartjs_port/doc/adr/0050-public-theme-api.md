# Chart.js ADR 0050: The public theme API, the presets, the theme switch and the touch sizes

- Status: accepted (2026-10-30)
- Superseded in part by: [Chart.js ADR 0054](0054-typed-internal-model.md) (2026-10-31), for the form of the compiled theme in "One scope", the memo of `compileThemeData` and steps 1 and 2 of "Runtime switch"; [Chart.js ADR 0057](0057-direct-typed-colors.md), [Chart.js ADR 0116](0116-text-style-fonts.md) (2026-11-12), [Chart.js ADR 0117](0117-typed-theme-tokens.md) (2026-11-12), [Chart.js ADR 0118](0118-theme-compile-typed-setters.md) (2026-11-12), [Chart.js ADR 0141](0141-native-scale-border.md)
- Superseded by: [Chart.js ADR 0147](0147-public-theme-api.md) (2026-11-14)
- Date: 2026-10-29
- Supersedes: [Chart.js ADR 0042](0042-theming.md)
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:packages/flutter_chartjs_port/doc/adr/0050-public-theme-api.md`

## Summary

This ADR decided the public theme API: `ChartTheme` and one flat `ChartThemeData` with 6 colors, 2 fonts and a
palette. It kept the theme scope and the eight hunks of [Chart.js ADR 0042](0042-theming.md). It also decided the
presets, the runtime switch, the fixed transitions, the blue screen and the goldens. The theme got no public `raw`
and no touch sizes. [Chart.js ADR 0147](0147-public-theme-api.md) now states the complete theme decision.

## Where each part went

- Context (the token layer of Chart.js and the colors plugin at the pin):
  [Chart.js ADR 0147](0147-public-theme-api.md) Context.
- Context, "What phase 9 found" (the probe results, S-contrast among them): removed. They are probe figures of the
  design, not rules. The Figures bullet of the Consequences of [Chart.js ADR 0147](0147-public-theme-api.md) gives
  the command for the full text.
- Decision, "One scope" (the theme as one option scope under `$theme`):
  [Chart.js ADR 0147](0147-public-theme-api.md) §1.
- Decision, "Eight marked hunks" (H0-H3 and H4a-H5): [Chart.js ADR 0147](0147-public-theme-api.md) §2.
- Decision, "The hunks change no upstream line": [Chart.js ADR 0147](0147-public-theme-api.md) §3.
- Decision, "The palette comes from the theme of the chart" (`chartThemeOf` and H5):
  [Chart.js ADR 0147](0147-public-theme-api.md) §4.
- Decision, "No writes to `Chart.defaults`": [Chart.js ADR 0147](0147-public-theme-api.md) §5.
- Decision, "The unthemed run is the oracle": [Chart.js ADR 0147](0147-public-theme-api.md) §6.
- Decision, "Static values only" (the keys that the compiler never emits):
  [Chart.js ADR 0147](0147-public-theme-api.md) §7.
- Decision, "The palette token": [Chart.js ADR 0147](0147-public-theme-api.md) §8.
- Decision, "Two states" (default and active): [Chart.js ADR 0147](0147-public-theme-api.md) §9.
- Decision, "The public classes" (`ChartTheme`, `ChartThemeData`, `lerp` and the compile):
  [Chart.js ADR 0147](0147-public-theme-api.md) §10.
- Decision, "The presets" (`.light()`, `.dark()` and the opt-out): [Chart.js ADR 0147](0147-public-theme-api.md)
  §11.
- Decision, "No public `raw` in 0.1.0" (the token table as the allowlist):
  [Chart.js ADR 0147](0147-public-theme-api.md) §12.
- Decision, "Runtime switch": [Chart.js ADR 0147](0147-public-theme-api.md) §13.
- Decision, "Runtime switch", steps 1 to 5 (`chart_view.dart` cites them):
  [Chart.js ADR 0147](0147-public-theme-api.md) §13 steps 1 to 5.
- Decision, "Transitions" (rule F): [Chart.js ADR 0147](0147-public-theme-api.md) §14.
- Decision, "No touch sizes": [Chart.js ADR 0147](0147-public-theme-api.md) §15.
- Section 5.2 (theming.md cites it for the touch sizes, but this ADR has no such section):
  [Chart.js ADR 0147](0147-public-theme-api.md) §15.
- Decision, "No design-system dependency": [Chart.js ADR 0147](0147-public-theme-api.md) §16.
- Decision, "The blue screen": [Chart.js ADR 0147](0147-public-theme-api.md) §17.
- Decision, "Goldens": [Chart.js ADR 0147](0147-public-theme-api.md) §18.
- Decision, "Acceptance": removed. It held the acceptance history and a CI run, not a rule.
- Change 1 (the public classes): [Chart.js ADR 0147](0147-public-theme-api.md) §10.
- Change 2 (the public palette type): [Chart.js ADR 0147](0147-public-theme-api.md) §8.
- Change 3 (no public `raw`, theming.md and [Chart.js ADR 0042](0042-theming.md) cite it):
  [Chart.js ADR 0147](0147-public-theme-api.md) §12.
- Change 4 (the presets and the opt-out): [Chart.js ADR 0147](0147-public-theme-api.md) §11.
- Change 5 (the in-place restores of the switch): [Chart.js ADR 0147](0147-public-theme-api.md) §13.
- Change 6 (a removal under reduced motion, theming.md cites it): [Chart.js ADR 0147](0147-public-theme-api.md) §13
  step 5.
- Change 7 (the fixed transitions): [Chart.js ADR 0147](0147-public-theme-api.md) §14.
- Change 8 (the blue screen with an active element, [Chart.js ADR 0042](0042-theming.md) cites it):
  [Chart.js ADR 0147](0147-public-theme-api.md) §17.
- Change 9 (the goldens and the light identity): [Chart.js ADR 0147](0147-public-theme-api.md) §18.
- Change 10 (no touch sizes): [Chart.js ADR 0147](0147-public-theme-api.md) §15.
- Change 11 (the citations at `v4.6.1`): [Chart.js ADR 0147](0147-public-theme-api.md) Context.
- Consequences (the bump replay, the hunks, the chart-type overrides, `Chart.defaults` and the loss at a switch):
  [Chart.js ADR 0147](0147-public-theme-api.md) Consequences.
- Consequences (the one source of the palette and the dataset colors after a switch):
  [Chart.js ADR 0147](0147-public-theme-api.md) §4 and §13 step 4.
- Consequences (the coverage snapshot, the palette constant, the dark preset and the singleton reads,
  `coverage_test.dart` cites it): [Chart.js ADR 0147](0147-public-theme-api.md) Consequences, bullet 4.
- Consequences (the cost figures and the night record B-R1): [Chart.js ADR 0147](0147-public-theme-api.md)
  Consequences, Figures bullet.
- Consequences (the public names and a later addition): [Chart.js ADR 0147](0147-public-theme-api.md) §10.
- Consequences (the golden files and the toolchain): [Chart.js ADR 0147](0147-public-theme-api.md) §18.
- Consequences (the names of the adapter packages): removed.
  [ADR 0007](../../../../docs/adr/0007-package-names.md) holds the package names.
- Consequences, invariants 1 to 3: [Chart.js ADR 0147](0147-public-theme-api.md) §19.1 to §19.3.
- Consequences, invariant 4 (the files of `lib/src/theme/` cite it): [Chart.js ADR 0147](0147-public-theme-api.md)
  §19.4.
- Alternatives considered: [Chart.js ADR 0147](0147-public-theme-api.md) Rejected.
- Open 1 (the source of the Linux FreeType): [Chart.js ADR 0147](0147-public-theme-api.md) Open 1.
- Open 2 (the typed component styles, [Chart.js ADR 0052](0052-typed-public-api.md) cites it):
  [Chart.js ADR 0147](0147-public-theme-api.md) Open 2.
- Open 3 (the hover strategies and the theme extensions): [Chart.js ADR 0147](0147-public-theme-api.md) Open 3.
- Evidence (the probes of the design panel, F-P1b among them, `theme_data_test.dart` cites it):
  [Chart.js ADR 0147](0147-public-theme-api.md) Consequences, Figures bullet.
