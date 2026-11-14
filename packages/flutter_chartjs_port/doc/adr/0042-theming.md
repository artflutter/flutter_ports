# Chart.js ADR 0042: Theming

- Status: accepted (2026-10-23)
- Superseded by: [Chart.js ADR 0050](0050-public-theme-api.md) (2026-10-30)
- Date: 2026-10-22
- Supersedes: [Chart.js ADR 0001](0001-theming.md)
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:packages/flutter_chartjs_port/doc/adr/0042-theming.md`

## Summary

The theme was one more option scope of the ported resolver, between `overrides[type]` and `defaults`.
Eight marked hunks (H0-H3 in `core.config`, H4a-H4c and H5 in `plugin.colors`) added lines to upstream code.
H5 read the palette from the theme map of the chart. The compiler emitted static values only.
[Chart.js ADR 0050](0050-public-theme-api.md) added the public API, the presets and the touch-size rule.
[Chart.js ADR 0147](0147-public-theme-api.md) now states the complete theme decision.

## Where each part went

- Decision, "One scope" (the theme as an option scope): [Chart.js ADR 0147](0147-public-theme-api.md) item 1.
- Decision, "Eight marked hunks": [Chart.js ADR 0147](0147-public-theme-api.md) item 2.
- Decision, "The hunks change no upstream line": [Chart.js ADR 0147](0147-public-theme-api.md) item 3.
- Decision, "The palette comes from the theme of the chart" (`chartThemeOf` and H5):
  [Chart.js ADR 0147](0147-public-theme-api.md) item 4.
- Decision, "No writes to `Chart.defaults`": [Chart.js ADR 0147](0147-public-theme-api.md) item 5.
- Decision, "The unthemed run is the oracle": [Chart.js ADR 0147](0147-public-theme-api.md) item 6.
- Decision, "Static values only" (the behavior keys, `fill` among them, which theming.md §3.3 cites):
  [Chart.js ADR 0147](0147-public-theme-api.md) item 7.
- Decision, "The palette token": [Chart.js ADR 0147](0147-public-theme-api.md) item 8.
- Decision, "Two states" (default and active): [Chart.js ADR 0147](0147-public-theme-api.md) item 9.
- Decision, "Runtime switch": [Chart.js ADR 0147](0147-public-theme-api.md) item 13.
- Decision, "A small public surface in 0.1.0": [Chart.js ADR 0147](0147-public-theme-api.md) items 10, 11
  and 12.
- Decision, "No design-system dependency": [Chart.js ADR 0147](0147-public-theme-api.md) item 16.
- Decision, "The blue screen": [Chart.js ADR 0147](0147-public-theme-api.md) item 17.
- Decision, "Acceptance" (the gates of the hunks H4a-H4c and H5): done in phase 8.
- Changes 1 and 2 (H5 reads the theme map, no hunk changes an upstream line):
  [Chart.js ADR 0147](0147-public-theme-api.md) items 4 and 3.
- Change 3 (the two parts of the known-leaks list): [Chart.js ADR 0147](0147-public-theme-api.md) item 17.
- Change 4 (the library floor and the adapter name): [Chart.js ADR 0147](0147-public-theme-api.md) item 16
  and [ADR 0007](../../../../docs/adr/0007-package-names.md) item 5.
- Consequences (the replay of the hunks, the overrides, the review of the defaults):
  [Chart.js ADR 0147](0147-public-theme-api.md) Consequences.
- Consequences (the four invariants): [Chart.js ADR 0147](0147-public-theme-api.md) item 19.
- Consequences (the touch sizes stay open): [Chart.js ADR 0147](0147-public-theme-api.md) item 15.
- Open 1 (the box layout keys and the fonts pass the guard, theming.md cites it): closed by
  [Chart.js ADR 0050](0050-public-theme-api.md) Change 3, now [Chart.js ADR 0147](0147-public-theme-api.md)
  item 12.
- Open 2 (`plugins.filler.drawTime` passes the guard): closed by [Chart.js ADR 0050](0050-public-theme-api.md)
  Change 3, now [Chart.js ADR 0147](0147-public-theme-api.md) item 12.
- Open 3 (the public palette type and the `raw` allowlist, theming.md cites it): closed by
  [Chart.js ADR 0050](0050-public-theme-api.md) Changes 2 and 3, now
  [Chart.js ADR 0147](0147-public-theme-api.md) items 10 and 12.
- Open 4 (the blue screen with an active element, porting-flow.md cites it): closed by
  [Chart.js ADR 0050](0050-public-theme-api.md) Change 8, now [Chart.js ADR 0147](0147-public-theme-api.md)
  item 17.
