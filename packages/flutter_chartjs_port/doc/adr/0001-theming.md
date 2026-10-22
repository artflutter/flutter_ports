# Chart.js ADR 0001: Theming

- Status: accepted (2026-10-18) for the four invariants of the Consequences section only. The rest
  stays proposed until phase 5.
- Date: 2026-10-16

## Context

Chart.js has one global token layer: `Defaults.color` (`'#666'`), `Defaults.borderColor` and
`Defaults.backgroundColor` (both `'rgba(0,0,0,0.1)'`) and `Defaults.font`
(`src/core/core.defaults.js:41-60`). The colors reach elements, scales and plugins through
`defaults.route` (`core.defaults.js:130-157`, called from `core.scale.defaults.js:86-89` and
`core.typedRegistry.js:94-95, 103-111`). The font reaches the tooltip through `defaultRoutes`
(`plugin.tooltip.js:1327-1331`). All other text reads it through the `toFont` fallback
(`helpers.options.ts:117`).

To get a dark chart, a Chart.js app changes `Chart.defaults`. That change is global. A change of
`Chart.defaults.borderColor` or `Chart.defaults.backgroundColor` also disables the colors plugin,
unless `forceOverride` is set. The plugin compares those two singleton defaults with
`'rgba(0,0,0,0.1)'` (`src/plugins/plugin.colors.ts:90-92, 119`). A Flutter app needs a theme per
subtree, a dark mode and a theme switch at runtime.

forui gives a good model ([survey](../prior-art/forui-theming.md)): an `InheritedTheme` root, a
one-way derivation from a few tokens, value equality, `copyWith`, `lerp` and a blue-screen test.
But forui 0.26 and later need Flutter 3.47, Dart 3.13 and `material_ui`. The library floor is
`sdk: ^3.12.0` and `flutter: ">=3.44.0"`. forui's generated deltas and variants also repeat what
Chart.js options do already. Options are partial values over defaults, with a fixed precedence.

The port has three constraints. Ported specs and fixtures must keep their upstream values
(AGENTS.md rule 3). Upstream releases must replay file by file
([ADR 0001](../../../../docs/adr/0001-native-ports-not-wrappers.md),
[ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md)). The ported files must thus stay
close to upstream.
Upstream draws two states only: default and active, through the hover option prefixes.

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
  Each hunk has one row in `packages/flutter_chartjs_port/doc/differences.md`. With no theme, the hunks have no
  effect.
- **No writes to `Chart.defaults`.** The theme stays per subtree. The colors plugin keeps its
  palette under a theme. The theme can supply that palette.
- **The unthemed run is the oracle.** Ported specs and fixtures run with no theme. The colors
  plugin is off, as in upstream `test/index.js:25-28`.
- **Static values only.** The compiler emits colors, fonts, the palette and the theme transitions.
  It never emits behavior keys, root `backgroundColor`, `borderColor` or `font`, static hover
  colors, scale ids, `_` keys, other `$` keys, functions or nulls. A debug assert and a test
  enforce this list.
- **Two states.** Default and active. Hover colors keep the upstream derivation from the themed
  base color. There are no variants, no deltas, no code generation and no CLI.
- **Runtime switch.** The widget gives the chart a fresh copy of the user options. It restores in
  place the two dataset keys that the colors plugin writes. It then calls `update('theme')`, with
  200 ms linear for element colors, or `update('themeFrame')`, with zero duration, under reduced
  motion. Theme removal calls `update('default')`. The widget never uses `'none'` or `'resize'`.
- **A small public surface in 0.1.0.** `ChartTheme`, `ChartThemeData(colors, typography, palette,
  raw)` and the presets `ChartThemes.light` (the v4.5.1 values), `dark` and `none`. Phase 9 decides
  the final API. Typed component styles come with the typed options API (ADR: Typed options API,
  after 0.1.0). Animated themes, extensions, hover strategies and touch sizes come later, each on
  its own condition.
- **No design-system dependency.** `lib/` imports neither forui nor Material. A forui adapter,
  `flutter_chartjs_port_forui`, comes after 0.1.0 with `forui: ^0.27.0`, `sdk: ^3.13.0` and
  `flutter: ">=3.47.0"`. forui 0.27 declares `sdk: ">=3.13.0-0 <4.0.0"` and
  `flutter: ">=3.47.0-0"`. The Material mapping is a snippet in the gallery, because
  `flutter/material.dart` and `material_ui` have distinct `ColorScheme` types.
- **Acceptance.** Phase numbers are those of [porting-flow.md](../porting-flow.md) §5.
  The team accepts the four invariants (Consequences) in phase 1, because tool 1 and AGENTS.md
  rule 5 enforce them from phase 1. The rest of this ADR stays proposed through phases 1-4. The
  team accepts it in phase 5, before the hunks H0-H3 land. First, a Dart prototype of H0-H3 on
  the ported `core.config` must confirm the scope position and the no-theme oracle.

## Consequences

- Upstream fixes replay without changes to theme code. A bump or an
  [ADR 0006](../../../../docs/adr/0006-follow-upstream-between-releases.md) backport into
  `core.config.js` or `plugin.colors.ts` re-applies the eight hunks and runs their pinning tests.
  These two files had 3 and 6 commits in `v4.0.0-release..v4.5.1`.
- The hunks change only two upstream lines: the bodies of `getBorderColor` and
  `getBackgroundColor`. All other hunks add lines.
- Chart-type overrides beat the theme. A theme cannot restyle a key that a chart type sets in
  `overrides[type]`.
- For the keys it emits, a theme beats app code that changes `Chart.defaults`.
- A theme switch discards imperative edits of `chart.options`. Element colors animate. Scales,
  legend, title and tooltip switch at once, as upstream does for any option change.
- Each bump reviews the defaults that the presets restate. A coverage snapshot test (phase 6)
  compares the compiled light preset with the defaults inventory of the upstream manifest. It
  reports added, removed and changed keys.
- Some singleton reads stay out of reach of the theme, for example `plugin.legend.js:286` and
  `helpers.options.ts:117`. [theming.md](../theming.md) §9 lists these reads for each
  bump. The blue-screen test
  keeps a committed known-leaks list of the reads that can change pixels (now
  `plugin.legend.js:286, 314, 319`).
- Four invariants apply from phase 1. [porting-flow.md](../porting-flow.md) adds them to
  AGENTS.md rule 5:
  1. Specs run unthemed.
  2. `lib/` imports no forui or Material.
  3. Ported code never writes `Chart.defaults` for theming.
  4. Ported files never import `lib/src/theme/`.
- The adapter change needs a new ADR that supersedes
  [ADR 0003](../../../../docs/adr/0003-package-names.md). In it, first-party design-system
  adapters take the name `flutter_chartjs_port_<system>` and stay `publish_to: none` until their first
  release.
- Touch sizes stay open. In phase 9, a new ADR that supersedes this ADR decides them, together
  with ADR: Input events and interaction state. ADR: Animation decides reduced motion for the
  other chart animations.
