# Chart.js ADR 0042: Theming

- Status: accepted (2026-10-23)
- Date: 2026-10-22
- Supersedes: [Chart.js ADR 0001](0001-theming.md)
- Related: [theming.md](../theming.md) (the design),
  [Chart.js ADR 0030](0030-controller-test-strategy.md) §8 and §11 (test 3 and the blue screen
  without plugins) and Open 5 (this ADR closes it, except the active element case),
  [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) (the protected
  behavior), [Chart.js ADR 0020](0020-registry-and-component-classes.md) §13 (micro gains),
  [ADR 0007](../../../../docs/adr/0007-package-names.md) (package names)

This ADR states the complete theming decision. It keeps every decision of Chart.js ADR 0001 and
changes four items (section "Changes from Chart.js ADR 0001"). The citations are at the pin
`v4.5.1+7169e651`. I checked each cited line at that commit.

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
The library floor is now `sdk: ^3.13.0` and `flutter: ">=3.47.0"`, the floor that forui 0.27
declares. But forui needs `material_ui`, and its generated deltas and variants repeat what
Chart.js options do already. Options are partial values over defaults, with a fixed precedence.

The port has three constraints. Ported specs and fixtures must keep their upstream values
(AGENTS.md rule 3). Upstream releases must replay file by file
([ADR 0001](../../../../docs/adr/0001-native-ports-not-wrappers.md),
[ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md)). The ported files must thus stay
close to upstream. Upstream draws two states only: default and active, through the hover option
prefixes.

### The colors plugin at the pin

- `plugin.colors.ts:14-22` is `BORDER_COLORS`, 7 `rgb()` strings. `:25` is `BACKGROUND_COLORS`:
  each border color with the alpha replaced by 0.5.
- `:27-29` `getBorderColor(i)` and `:31-33` `getBackgroundColor(i)` give `LIST[i % LIST.length]`.
- `:35-52` are the three colorizers. `:54-68` `getColorizer` keeps one counter for each call of
  `beforeLayout`.
- `ColorsPluginOptions` (`:4-7`) has `enabled` and `forceOverride` only. Upstream has no palette
  option.
- `beforeLayout` (`:102-126`) returns when `!options.enabled` (`:103`). It reads the raw user
  options `chart.config.options` (`:107-111`), so its checks do not see a theme. It returns when
  the datasets, the options or the elements hold a color, or when the singleton defaults changed,
  unless `forceOverride` (`:113-121`). Then it colorizes each dataset (`:123-125`).
- After the first colorize, the datasets hold colors. Thus the plugin colorizes one time for each
  chart, and at each update only with `forceOverride`. An event or a `render()` never colorizes.

### What Chart.js ADR 0001 and theming.md section 3.5 gave

Chart.js ADR 0001 decided the theme scope, eight marked hunks and a theme palette.
`theming.md` §3.5 (section 3 is the mechanism of that ADR, `theming.md:9-10`) said that hunk H5
reads the palette from the plugin options `$borderColors` and `$backgroundColors`. The plugin
options resolve the user options, `overrides[type]`, the theme scope of H2 and `defaults`
(`core.plugins.js:175-188`).

A JavaScript prototype of H0-H5 on the pinned sources showed a defect in that form (probe J1).
A bar chart with no theme and the colors plugin on:

| Case | Upstream | H5 from the plugin options | H5 from the theme map |
|---|---|---|---|
| user `plugins.colors.$borderColors: ['U0', 'U1']` | `rgb(54, 162, 235)` | `U0` | `rgb(54, 162, 235)` |
| `defaults.plugins.colors.$borderColors = ['D0', 'D1']` | `rgb(54, 162, 235)` | `D0` | `rgb(54, 162, 235)` |
| `overrides.bar.plugins.colors.$borderColors` | `rgb(54, 162, 235)` | `O0` | `rgb(54, 162, 235)` |

The value reaches the dataset and the resolved element option. Chart.js ADR 0034 protects both.
Thus the plugin-options form breaks the rule "With no theme, the hunks have no effect". The
theme-map form keeps it.

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
  Each hunk has one row in `packages/flutter_chartjs_port/doc/differences.md`. With no theme, the
  hunks have no effect.
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
- **No writes to `Chart.defaults`.** The theme stays per subtree. The colors plugin keeps its
  palette under a theme. The theme can supply that palette.
- **The unthemed run is the oracle.** Ported specs and fixtures run with no theme. The colors
  plugin is off, as in upstream `test/index.js:25-28`.
- **Static values only.** The compiler emits colors, fonts, the palette and the theme transitions.
  It never emits behavior keys, root `backgroundColor`, `borderColor` or `font`, static hover
  colors, scale ids, `_` keys, other `$` keys, functions or nulls. The behavior keys include
  the data and decision keys `fill`, `spanGaps`, `showLine`, `stacked`, `reverse`, `min`, `max`,
  `suggestedMin`, `suggestedMax`, `beginAtZero`, `grace`, `bounds`, `base`, `skipNull` and
  `grouped` at any depth ([theming.md](../theming.md) §3.3 gives the upstream lines). The `''`
  scope of the theme comes before `defaults.datasets[type]`. The behavior keys also include the
  key paths that change data, item order, a position or a discrete decision:
  `plugins.decimation.algorithm`, `.samples` and `.threshold` (`plugin.decimation.js:269, 12,
  242`), `plugins.filler.propagate` (`plugin.filler/index.js:47`), `plugins.legend.reverse`
  (`plugin.legend.js:116-117`), `plugins.legend.rtl` (`plugin.legend.js:235-259`),
  `plugins.tooltip.position` (`plugin.tooltip.js:651, 1012, 1218`), `plugins.tooltip.xAlign`
  and `.yAlign` (`plugin.tooltip.js:273, 270`), `scale.labels` (`core.scale.js:360`) and
  `scale.ticks.stepSize`, `.count`, `.precision` and `.maxTicksLimit`
  (`scale.linearbase.js:32-104, 216-260`), and the content keys `text` of the title, the
  subtitle, the legend title and the scale title (`plugin.title.js:43, 97`,
  `plugin.legend.js:487`, `core.scale.js:102, 613`). A `scale.` path also applies under each
  `scales.<type>`. A flat `labels` is not a behavior key, because `plugins.legend.labels` holds
  the legend colors and fonts.

  A palette value is a List with at least one item. A debug assert and a test enforce this list.
- **The palette token.** A raw Map theme gives the palette as
  `palette: {colors: [...], backgroundAlpha: 0.5}`. The compiler emits the colors at their
  alpha as `$borderColors`. It emits the same colors with the alpha replaced by
  `backgroundAlpha` as `$backgroundColors`, as `plugin.colors.ts:25` derives
  `BACKGROUND_COLORS`. An absent `backgroundAlpha` is 0.5.
- **Two states.** Default and active. Hover colors keep the upstream derivation from the themed
  base color. There are no variants, no deltas, no code generation and no CLI.
- **Runtime switch.** The widget gives the chart a fresh copy of the user options. It restores in
  place the two dataset keys that the colors plugin writes. It then calls `update('theme')`, with
  200 ms linear for element colors, or `update('themeFrame')`, with zero duration, under reduced
  motion. Theme removal calls `update('default')`. The widget never uses `'none'` or `'resize'`.
- **A small public surface in 0.1.0.** `ChartTheme`, `ChartThemeData(colors, typography, palette,
  raw)` and the presets `ChartThemes.light` (the values at the pin), `dark` and `none`. Phase 9
  decides the final API, also the public form of the palette. Typed component styles come with
  the typed options API (ADR: Typed options API, after 0.1.0). Animated themes, extensions, hover
  strategies and touch sizes come later, each on its own condition.
- **No design-system dependency.** `lib/` imports neither forui nor Material. A forui adapter,
  `flutter_chartjs_port_forui`, comes after 0.1.0 with `forui: ^0.27.0`, `sdk: ^3.13.0` and
  `flutter: ">=3.47.0"`. forui 0.27 declares `sdk: ">=3.13.0-0 <4.0.0"` and
  `flutter: ">=3.47.0-0"`. The Material mapping is a snippet in the gallery, because
  `flutter/material.dart` and `material_ui` have distinct `ColorScheme` types.
- **The blue screen.** A test-support theme sets every token and the palette (alpha 1) to one
  blue, on a blue background. In all 8 chart types, with the title, the subtitle, the legend
  title and a visible tooltip, with the colors plugin on and off, every pixel must be blue. The
  committed known-leaks list of the 8 chart types is empty. A pin case with a legend item without
  `fillStyle` and `strokeStyle` keeps its own committed list: `setFillStyle #666` and
  `setStrokeStyle #666`, the singleton read of `plugin.legend.js:286` at `:314` and `:319`.
- **Acceptance.** Phase numbers are those of [porting-flow.md](../porting-flow.md) §5. The four
  invariants (Consequences) are in force from phase 1. Chart.js ADR 0001 accepted them on
  2026-10-18. Phase 5 landed H0-H3 after a Dart prototype confirmed the scope position and the
  no-theme oracle. The porting lead accepts this ADR when H4a-H4c and H5 land and their gates
  are green. Chart.js ADR 0001 then gets only the line "Superseded by Chart.js ADR 0042".

## Changes from Chart.js ADR 0001

1. H5 reads the palette from the theme map of the chart (the H0 reader `chartThemeOf`), not from
   the plugin options. Thus H0 has two readers: the private `_themeOf` and the public
   `chartThemeOf`.
2. No hunk changes an upstream line. Chart.js ADR 0001 said: "The hunks change only two upstream
   lines: the bodies of `getBorderColor` and `getBackgroundColor`." H4b and H4c now add a branch
   before the unchanged `return` line.
3. The blue-screen known-leaks list has two parts: the empty list of the 8 default charts (the
   form of Chart.js ADR 0030 §11) and the list of the pin case (`plugin.legend.js:286, 314,
   319`). This joins the texts of Chart.js ADR 0001 and Chart.js ADR 0030 §11.
4. Current facts: the library floor is `sdk: ^3.13.0` and `flutter: ">=3.47.0"`.
   [ADR 0007](../../../../docs/adr/0007-package-names.md) superseded ADR 0003 and gave the adapter
   name `flutter_chartjs_port_<system>`. Thus the consequence "The adapter change needs a new ADR
   that supersedes ADR 0003" is done.

The guard list (Static values only) and the palette token restate the rule of Chart.js ADR 0001
for the keys of the plugins of phase 8. They do not change it.

## Consequences

- Upstream fixes replay without changes to theme code. A bump or an
  [ADR 0006](../../../../docs/adr/0006-follow-upstream-between-releases.md) backport into
  `core.config.js` or `plugin.colors.ts` re-applies the eight hunks and runs their pinning tests.
  These two files had 3 and 6 commits in `v4.0.0-release..v4.5.1`.
- All hunks add lines. Each upstream line stays verbatim. Thus a bump that changes an upstream
  line of a hunk host replays without a conflict in that line.
- Chart-type overrides beat the theme. A theme cannot restyle a key that a chart type sets in
  `overrides[type]`.
- For the keys it emits, a theme beats app code that changes `Chart.defaults`.
- The palette has one source: the theme. An app that wants another palette for one chart gives
  that chart its own theme, or sets the dataset colors.
- A theme switch discards imperative edits of `chart.options`. Element colors animate. Scales,
  legend, title and tooltip switch at once, as upstream does for any option change.
- Each bump reviews the defaults that the presets restate. A coverage snapshot test compares the
  compiled light preset with the defaults inventory of the upstream manifest. It reports added,
  removed and changed keys. The palette is a module constant, not a default. The test names it
  with its upstream lines (`plugin.colors.ts:14-25`), and test 3 compares its values.
- Some singleton reads stay out of reach of the theme, for example `plugin.legend.js:286` and
  `helpers.options.ts:117`. [theming.md](../theming.md) §9 lists these reads for each bump.
- The cost is small. H5 reads two Map keys one time for each colorize: 0.04-0.06 µs. The getter
  branch costs 0.3 ns (AOT) and 1.3 ns (dart2wasm) more than upstream for each call. No form
  changes a frame figure.
- Four invariants apply from phase 1. AGENTS.md rule 5 and tool 1 enforce them:
  1. Specs run unthemed.
  2. `lib/` imports no forui or Material.
  3. Ported code never writes `Chart.defaults` for theming.
  4. Ported files never import `lib/src/theme/`. A ported file can import `core.config.dart`.
     Thus `plugin.colors.dart` reads the theme through `chartThemeOf`.
- First-party design-system adapters take the name `flutter_chartjs_port_<system>` (ADR 0007) and
  stay `publish_to: none` until their first release.
- Touch sizes stay open. In phase 9, a new ADR that supersedes this ADR decides them, together
  with ADR: Input events and interaction state. ADR: Animation decides reduced motion for the
  other chart animations.

## Alternatives considered

| Option | Chosen | Reason |
|---|---|---|
| Theme in `Chart.defaults`, in the user options, or as a scope | a scope | Defaults are global. A changed default disables the palette. Tokens in the user's `options.scales` create axes on a doughnut |
| No palette hunks (the upstream form) | no | A theme then cannot give a palette, and the upstream palette leaks into a themed chart |
| H5 reads the plugin options (Chart.js ADR 0001, `theming.md` §3.5) | no | A user, `overrides[type]` or `defaults` key `$borderColors` changes an unthemed chart (probe J1). It costs 0.43-0.62 µs for each colorize |
| H5 reads the theme map of the chart | yes | No theme gives the upstream result for every input (J1). 0.04-0.06 µs for each colorize |
| An argument for the palette in place of the variables | no | It changes six upstream signatures: `getColorizer`, the three `colorize*` functions and both getters |
| Getter body `final c = theme ?? LIST; return c[i % c.length];` | no | It changes the upstream line. It costs 1.5 ns (AOT) and 5.6 ns (dart2wasm) more than upstream for each call |
| Getter body: a theme branch before the unchanged line | yes | Each upstream line stays. 0.3 ns (AOT) and 1.3 ns (dart2wasm) more than upstream |
| Palette token: two Lists, or one List at a fixed alpha 0.5, or one List with `backgroundAlpha` | one List with `backgroundAlpha` | It mirrors `plugin.colors.ts:25`. The blue screen needs alpha 1 without a `raw` override |
| Known leaks: an empty list, the three lines for each chart type, or an empty list and a pin case | an empty list and a pin case | The 8 default charts paint no `#666`, because `generateLabels` sets `fillStyle` and `strokeStyle` (`plugin.legend.js:685, 693`). A user `generateLabels` without them paints `#666` |
| Datasets on a switch: copies or an in-place restore | in-place restore | A new dataset object loses its meta and legend visibility. It also replays the entry animation |
| A rendering run of every fixture under the light preset | dropped | Equal resolved options and the blue screen show the same result |
| Material mapping: a package or a snippet | a snippet | The two Material libraries have distinct `ColorScheme` types |

## Open

1. The layout keys of the plugin boxes (`position`, `align`, `fullSize`, `weight`, `padding`) and
   the fonts pass the guard. They move the layout, as the font token does. The step 7 review of
   phase 8 moved the scale keys `reverse`, `min`, `max`, `beginAtZero`, `stacked` and
   `title.text` into the guard, with the other keys of "Static values only".
2. `plugins.filler.drawTime` passes the guard. It changes only the draw order. It stays allowed
   (Chart.js ADR 0034).
3. Phase 9 decides the public palette type and whether a `raw` allowlist replaces the guard. At
   step 7 the deny list needed 24 more keys. An allowlist of the emitted token keys and the style
   keys is the safer form.
4. The blue screen with an active element waits for `IdentityChartHover`
   ([theming.md](../theming.md) §8 item 6). Owner: phase 9. The blue screen and test 3 of this
   ADR close the rest of [Chart.js ADR 0030](0030-controller-test-strategy.md) Open 5.

## Evidence

The probes are scripts of the phase 8 design panel. The table names each script and its
result. Node.js is the x64 build of v24.12.0 under Rosetta. Dart is 3.13.5. The Mac was shared
(load average 6.3 to 10.2), so the absolute figures are high. The order of the forms is the same
in each run.

| Probe | Files | Result |
|---|---|---|
| J1 | `judge/judge-h5-source.mjs`, `.upstream`, `.A`, `.B`, `.Acoal` outputs | The table of the Context. The theme-map form equals upstream for each unthemed input. Both getter forms give equal colors |
| J2 | `judge/bench/judge_getter.dart` | Unthemed: upstream 1.39-1.42 ns AOT, 1.22-1.29 ns wasm. Branch form 1.70-1.75 ns AOT, 2.50-2.54 ns wasm. `??` form 2.85-2.90 ns AOT, 6.86-7.04 ns wasm |
| J3 | `judge/judge_guard.dart` | Before this ADR, the guard passes `plugins.decimation.algorithm`, `.samples`, `.threshold`, `plugins.filler.propagate`, `plugins.legend.reverse`, `plugins.tooltip.position`, `plugins.title.text` and an empty `$borderColors` |
| P1 | `fidelity/palette_prototype.mjs` | The palette rows of test 2, the edges (an empty List, a string) and the light palette (0 parsed differences for 5 chart types) |
| P2 | `fidelity/blue_screen_plugins.mjs` | 16 blue cases (8 types, colors on and off) with no leak. The pin case sets `#666` twice |
| P3 | `fidelity/light_plugins.mjs` | The 19 plugin keys of the light preset equal upstream |
| P4 | `fidelity/h5_read_bench.dart` | H5 from the plugin options: 464-506 ns AOT, 879 ns wasm. H5 from the theme map: 41-61 ns |
| P5 | `fidelity/guard_behavior.mjs` | A raw theme key changes the decimated data (50 points in place of 1204), the legend order and the fill target |
| S1 | `simplicity/s1_palette_forms.mjs` | Without the reset of H5, the last palette leaks into the next chart. Without the guard, an empty List gives `null` colors in JavaScript |
| S2 | `simplicity/s2_dart_palette.dart` | Without the guard, an empty List throws `IntegerDivisionByZeroException` in Dart |
| B1, B3 | `bench/bench_getter.dart`, `bench/bench_palette.dart` | The getter and H5 figures of the performance draft |
| R1 | the step 7 theming probes of phase 8 | Before the change of "Static values only", the guard passed the keys of its new groups. Each one changed a protected value under a theme: the fill target (`fill`), the line segments (`spanGaps`), the dataset element of a scatter chart (`showLine`), the tooltip position (`xAlign`, `yAlign`), the legend hit boxes and item order (`rtl`), the data labels (`labels`), the bar geometry (`base`, `skipNull`, `grouped`), the data range (`stacked`, `min`, `max`, `suggestedMin`, `suggestedMax`, `beginAtZero`, `grace`, `bounds`), the ticks (`reverse`, `ticks.stepSize`, `ticks.count`, `ticks.precision`, `ticks.maxTicksLimit`) or the content (`title.text`). The control `scale.ticks.font` changed only the layout: the same range and ticks |
