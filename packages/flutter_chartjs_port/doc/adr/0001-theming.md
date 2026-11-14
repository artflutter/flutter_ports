# Chart.js ADR 0001: Theming

- Status: accepted (2026-10-18) for the four invariants of the Consequences section only. The rest
  stays proposed until phase 5.
- Superseded by: [Chart.js ADR 0042](0042-theming.md) (2026-10-23)
- Date: 2026-10-16
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:packages/flutter_chartjs_port/doc/adr/0001-theming.md`

## Summary

This ADR made the theme one more option scope: a frozen map under `$theme`. The resolver read it between
`overrides[type]` and `defaults`. Eight marked hunks in `core.config` and `plugin.colors` connected it, with
no write to `Chart.defaults`. The specs ran unthemed, and a widget switched the theme with `update('theme')`.
The team accepted only the four invariants: unthemed specs, no forui or Material in `lib/`, no theme writes,
no theme imports.

## Where each part went

- One scope (the theme between the chart-type overrides and the defaults):
  [Chart.js ADR 0050](0050-public-theme-api.md), "One scope".
  [Chart.js ADR 0054](0054-typed-internal-model.md) §18 gives the form of the compiled scope.
- Eight marked hunks (H0-H3 and H4a-H5): [Chart.js ADR 0050](0050-public-theme-api.md), "Eight marked hunks"
  and "The hunks change no upstream line".
- No writes to `Chart.defaults`: [Chart.js ADR 0050](0050-public-theme-api.md), "No writes to
  `Chart.defaults`".
- The unthemed run is the oracle: [Chart.js ADR 0050](0050-public-theme-api.md), "The unthemed run is the
  oracle".
- Static values only (the keys that the compiler never emits): [Chart.js ADR 0050](0050-public-theme-api.md),
  "Static values only". [Chart.js ADR 0118](0118-theme-compile-typed-setters.md) removes its debug assert.
- Two states (default and active): [Chart.js ADR 0050](0050-public-theme-api.md), "Two states".
- Runtime switch: [Chart.js ADR 0050](0050-public-theme-api.md), "Runtime switch".
  [Chart.js ADR 0054](0054-typed-internal-model.md) §18 states its steps 1 and 2 again.
- A small public surface in 0.1.0: [Chart.js ADR 0050](0050-public-theme-api.md), "The public classes" and
  "The presets". [Chart.js ADR 0117](0117-typed-theme-tokens.md) replaces the raw Map theme with typed tokens.
- No design-system dependency: [Chart.js ADR 0050](0050-public-theme-api.md), "No design-system dependency".
- Acceptance: [Chart.js ADR 0050](0050-public-theme-api.md), "Acceptance".
- The four invariants (Consequences): [Chart.js ADR 0050](0050-public-theme-api.md), Consequences.
- Touch sizes (an open item of Consequences): [Chart.js ADR 0050](0050-public-theme-api.md), "No touch sizes".
