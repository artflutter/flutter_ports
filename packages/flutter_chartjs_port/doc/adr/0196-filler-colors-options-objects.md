# Chart.js ADR 0196: The filler and colors options are one object each

- Status: proposed
- Date: 2026-11-23
- Supersedes: of [Chart.js ADR 0182](0182-resolved-plugin-option-classes.md), item 1 for `FillerOptions` and
  `ColorsPluginOptions`; of [Chart.js ADR 0052](0052-typed-public-api.md), §1, §6 and §8 for `ChartFiller` and the
  parameter `filler` of `ChartConfig`; of [Chart.js ADR 0054](0054-typed-internal-model.md), §2 for the kinds
  `FillerOptions` and `ColorsOptions` of the schema and §3 for the typed defaults scopes of the filler and the colors
  plugin; of [Chart.js ADR 0147](0147-public-theme-api.md), item 4 (the palette keys and their reader), item 8 (the
  palette token emits two frozen Lists under `$` keys) and the two palette keys of item 10; of
  [Chart.js ADR 0194](0194-decimation-options-object.md), item 6 for `ChartColors` and the parameter `colors` of
  `ChartConfig`
- Related: [Chart.js ADR 0192](0192-tooltip-options-object.md), [Chart.js ADR 0193](0193-legend-options-object.md),
  [Chart.js ADR 0148](0148-plugin-typing.md)

## Context

The filler and the colors plugin each had three types for their options: a typed group of the typed API
(`ChartFiller`, and `ChartColors` of Chart.js ADR 0194) with its lowering, a scope generated from the schema
(`FillerOptionsScope`, `ColorsOptionsScope`) and a class of resolved values made by `of` from a resolver at each
update (`FillerOptions`, `ColorsPluginOptions`). The theme wrote its palette into two port-only keys of the colors
scope, `$borderColors` and `$backgroundColors`, and the colors plugin read them by name from the theme map.
Chart.js ADRs 0192 to 0194 made the tooltip, legend and decimation options one immutable `PluginOptions` object
each. Upstream resolves plugin options with `scriptable: false` (`core.plugins.js:182-187`): no filler or colors
option is a function.

## Decision

1. **One class each.** `FillerOptions` and `ColorsPluginOptions` of `plugin_options.dart` are
   `PluginOptions<FillerOptions>` and `PluginOptions<ColorsPluginOptions>` (plugin ids `filler` and `colors`) with
   one nullable field for each option (`propagate`, `drawTime`; `enabled`, `forceOverride`), `events` (Chart.js
   ADR 0150), `merge`, `==` and `hashCode`. A null field is not set. Neither class has a scriptable form.

   ```dart
   ChartConfig(
     datasets: [LineDataset(data: .values([3, 5, 2]), fill: .toOrigin)],
     pluginOptions: const [
       FillerOptions(propagate: false),
       ColorsPluginOptions(forceOverride: true),
     ],
   );
   ```

2. **The paths of the options.** `ChartFiller`, `lowerFiller`, `ChartColors`, `lowerColors` and the parameters
   `filler` and `colors` of `ChartConfig` are removed: an app gives the objects in `ChartConfig.pluginOptions`. A raw
   config holds the object in `options.plugins.filler` or `options.plugins.colors`; a Map there stops a debug build,
   `false` turns the plugin off and `true` keeps the defaults. The schema has no kinds `FillerOptions` and
   `ColorsOptions`: the keys `filler` and `colors` of `PluginOptionsByType` are `bool | pluginOptions`.

3. **The defaults.** The plugin `defaults` are one `const FillerOptions(propagate: true, drawTime:
   FillerDrawTime.beforeDatasetDraw)` (`plugin.filler/index.js:93-96`) and one `const ColorsPluginOptions(enabled:
   true, forceOverride: false)` (`plugin.colors.ts:97-100`). The plugin service merges the objects of the defaults,
   the theme and the chart. A field that no scope sets reads as the falsy `undefined` of upstream in the hooks. The
   test harness turns the colors plugin off with `defaults.plugins.colors =
   current.merge(const ColorsPluginOptions(enabled: false))` (`test/index.js:25-28`).

4. **The palette of the theme.** `ColorsPluginOptions` has the port-only fields `borderColors` and
   `backgroundColors` (`List<Color>?`, row `theme-H4a`). The theme compiler writes one `ColorsPluginOptions` with
   both palettes in `plugins.colors` of the compiled theme, with unmodifiable Lists. Hunk H5 takes the palettes of
   the merged options: the options of the chart come over the theme, as for any option. A null or empty List gives
   the upstream palette. `themeBorderColorsKey`, `themeBackgroundColorsKey` and the reader of the theme map are
   removed.

5. **Tests.** A test that gives filler or colors options gives a typed config with `pluginOptions`, or the object in
   a raw config. The hand fixtures hold the objects, and the 10 data fixtures of `plugin.colors` with
   `colors: {enabled: true}` get a hand port (Chart.js ADR 0115). The generators write `FillerOptions` and
   `ColorsPluginOptions` literals; the step of the colors case "dataset colors given, then forceOverride" writes the
   whole options object. The reference data are generated again with the same expectations. No helper turns a Map
   into options, and the fixture adapter no longer converts the keyword of `drawTime`.

## Rejected

- Keep `ChartFiller` and `ChartColors` over the objects: two types with the same fields again.
- Keep the palette in two `$` keys of a theme Map: the theme scope of `plugins.colors` is one of the scopes that the
  plugin service merges, and it holds one options object.
- Read the palette only from the theme: a public field with no effect in the options of a chart.

## Consequences

- A palette in the `ColorsPluginOptions` of a chart now colors its datasets; before, H5 read only the theme map.
- The key order of the filler and colors options is the order of the fields.
- The upstream `plugins.filler` and `plugins.colors` defaults of the manifest compare with the fields of the
  objects.

## Tests

`test/port/plugins/plugin_options_test.dart`, `test/port/plugins/plugin.colors_test.dart`,
`test/port/plugins/plugin.filler/index_test.dart`, `test/specs/plugin.filler_test.dart`,
`test/specs/plugin.colors_test.dart`, `test/port/options/schema_test.dart`, `test/port/theme/compile_test.dart`,
`test/port/theme/coverage_test.dart`, `test/port/fixtures/index_test.dart`
