# Chart.js ADR 0124: Native text direction and scoped restoration

- Status: accepted (2026-11-12): native and browser tests, fixtures, analysis and port checks pass.
- Date: 2026-11-12
- Related: ADR 0116 (native fonts), ADR 0123 (native padding).
- Difference: `adapt-text-direction`.
- Upstream: [PR #12371](https://github.com/chartjs/Chart.js/pull/12371), open and unmerged when checked on 2026-11-12;
  [issue #7035](https://github.com/chartjs/Chart.js/issues/7035), the earlier argument-mismatch report.

## Context

The legend and tooltip hold `textDirection` as `'ltr'` or `'rtl'`. `overrideTextDirection` saves the canvas element's
CSS direction and priority on the context, then writes an inline style. Both plugins pass the option string to
`restoreTextDirection`, which expects a tuple. Its `original[0]` and `original[1]` read individual characters, and
CSS ignores the invalid priority. The override leaks into subsequent drawing. The pinned source still has this
behavior. Upstream PR #12371 proposes restoring the saved CSS tuple.

## Decision

1. The legend and tooltip `textDirection` options hold `dart:ui.TextDirection`, including raw configs, scriptable
   results and typed scope setters. Missing or null means no override. Another type stops a debug build and gives
   no override in release. `ChartLegend` and `ChartTooltip` expose the native optional field, including copying,
   equality, diagnostics and lowering.
2. `CanvasRenderingContext2D.direction` is `TextDirection?`. Null explicitly means inheritance from the canvas
   element style and is the default state. Setting null restores inheritance. The canvas save/restore stack keeps
   this nullable value. CSS text remains only at the element style boundary; it is not an option representation.
3. `overrideTextDirection(ctx, direction)` returns the previous nullable native canvas direction. A null option
   leaves the canvas unchanged. `restoreTextDirection(ctx, original)` restores the returned value, including null.
   The restore argument is required. No CSS declaration or priority changes. The unused `prevTextDirectionOf`
   accessor and its Expando are removed; the public API inventory reflects this removal.
4. Legend and tooltip draw calls retain the returned value locally and restore it in `finally`. An explicit
   option overrides an explicit context direction during that draw. Nested overrides restore independently.
   This fixes the direction leak locally, without changing the upstream pin or importing the unmerged JS patch.
5. `rtl` continues to control layout mirroring independently. This migration does not infer it from text direction.
6. Reference inputs write the native enum. The upstream tooltip reference no longer compares the leaked CSS state
   of the `textDirection rtl` case; native tests verify direction during drawing, unchanged CSS, restoration after
   drawing and exceptional exits. Other drawing observations remain compared. The fixture adapter can convert the
   enum by its own names, as for TextAlign; it has no class-name lookup table.

## Tests

- `helpers.rtl_test.dart`: typed/raw storage, optional and scriptable options, invalid input rejection, saved native
  values, inheritance and nested restoration.
- `plugin.tooltip_test.dart`: both directions, repeated drawing with all prior states, no override, unchanged CSS,
  a legend followed by a tooltip, and restoration when either plugin's text draw throws.
- `canvas_ui_test.dart`: native setter, save/restore, reset to inheritance and start-aligned text with inherited RTL.
- Typed lowering and key coverage, mock context, plugin reference suites, public API inventory and import checks.
