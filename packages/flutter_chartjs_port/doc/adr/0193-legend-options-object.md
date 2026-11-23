# Chart.js ADR 0193: The legend options are one object

- Status: proposed
- Date: 2026-11-23
- Supersedes: of [Chart.js ADR 0182](0182-resolved-plugin-option-classes.md), item 1 for `LegendOptions`,
  `LegendLabelOptions` and `LegendTitleOptions`, item 3 for `Legend.options`, item 5 for `LegendOptions.view`, and
  item 7 for the legend colors, the label `borderRadius`, `pointStyle` and `generateLabels`; of
  [Chart.js ADR 0052](0052-typed-public-api.md), §1, §6 and §8 for `ChartLegend` and the parameter `legend` of
  `ChartConfig`; of [Chart.js ADR 0054](0054-typed-internal-model.md), §2 for the kinds `LegendOptions`,
  `LegendLabelOptions` and `LegendTitleOptions` of the schema, §3 for the typed defaults scope and the descriptors
  of the legend, and §12 for the legend facade; of [Chart.js ADR 0130](0130-native-callback-options.md), item 6 for `ChartLegend.onClick`, `onHover`
  and `onLeave`; of [Chart.js ADR 0124](0124-native-text-direction.md), the field of `ChartLegend`; of
  [Chart.js ADR 0092](0092-hidden-legend-items.md), the reads of the guards through the resolvers, the guard of the
  `_scriptable` descriptor and the first read of the label `color` at the mark; of
  [Chart.js ADR 0099](0099-hidden-legend-indexed-colors.md), the guard of the native scopes behind the legend and label
  resolvers
- Related: [Chart.js ADR 0192](0192-tooltip-options-object.md), [Chart.js ADR 0148](0148-plugin-typing.md),
  [Zoom ADR 0005](../../../flutter_chartjs_plugin_zoom_port/doc/adr/0005-typed-zoom-options.md)

## Context

The legend plugin had three types that each declared its options again: `ChartLegend` (the typed API, lowered by
`lowerLegend`, with the label options flat and `extra` for the rest), `LegendOptionsScope`, `LegendLabelOptionsScope`
and `LegendTitleOptionsScope` (generated from the schema), and `LegendOptions`, `LegendLabelOptions` and
`LegendTitleOptions` (the resolved values, made by `LegendOptions.of` from a resolver at the first hook of an update).
Chart.js ADR 0192 made the tooltip options one immutable `PluginOptions` object; the legend is the next plugin with the
same three types.

The options of `plugin.legend.js:636-719` are scriptable with the chart context, except `onClick`, `onHover`,
`onLeave`, `generateLabels`, `filter` and `sort`. The defaults use that form once: the label and title `color` is
`(ctx) => ctx.chart.options.color`. A test uses a scriptable label `font` and `color` (the oracle O1) and a scriptable
label `color` (the D2 resolver trace).

## Decision

1. **One class.** `LegendOptions` of `plugin_options.dart` is a `PluginOptions<LegendOptions>` with one nullable field
   for each option of `plugin.legend.js:636-712` and of `index.d.ts` `LegendOptions` (also `weight` and `events`),
   `merge`, `==`, `hashCode`, and `layoutOption` of `LayoutBoxOptions`. `labels` is a `LegendLabelOptions` and `title`
   a `LegendTitleOptions`: nested value classes with nullable fields and their own `merge`, which `LegendOptions.merge`
   calls by field. A null field is not set. A font merges by field (`TextStyle.merge`). A color is a `ChartPaint`, the
   label `borderRadius` a `BorderRadius`, `pointStyle` a `PointStyle` and `generateLabels` a `Function` (the
   `LegendLabelsGenerator` of the legend; its type names the `Chart` class, which this core layer does not import).

   ```dart
   ChartConfig(
     datasets: [LineDataset(data: .values([3, 5, 2]))],
     pluginOptions: const [
       LegendOptions(
         position: ChartPosition.bottom,
         labels: LegendLabelOptions(usePointStyle: true),
       ),
     ],
   );
   ```

2. **The paths of the options.** `ChartLegend`, `lowerLegend`, `legendTrampoline` and `ChartConfig.legend` are removed:
   an app gives the object in `ChartConfig.pluginOptions`. A raw config holds the object in `options.plugins.legend`; a
   Map there stops a debug build, `false` turns the plugin off and `true` keeps the defaults. The schema has no kinds
   `LegendOptions`, `LegendLabelOptions` and `LegendTitleOptions`: the key `legend` of `PluginOptionsByType` is
   `bool | pluginOptions`. The theme writes one `LegendOptions` with the two fonts that it themes. The doughnut and polar
   area overrides write a `LegendOptions` with their `generateLabels` and `onClick`.

3. **The defaults.** The plugin `defaults` are one `const LegendOptions` with each default of upstream except the two
   color functions; the plugin has no `descriptors`. The plugin service merges the objects of the defaults, the
   overrides of the chart type, the theme and the chart (Chart.js ADRs 0148 and 0192).

4. **The fallbacks in Dart.** The `beforeUpdate` hook gives the box the merged object with the fallbacks of upstream
   (`_resolvedOptions` of `plugin.legend.dart`): a label or title `color` that no options set is the `color` of the
   chart options, the default functions of `plugin.legend.js:661, 707`. `legend.options` holds that object. The fonts
   stay as the options give them, and each reader merges them over `Chart.defaults.font` with `toFont`, as upstream. The
   `start` hook gives the box the merged object; the layout reads only `display`, `fullSize`, `position` and `weight`
   before `beforeUpdate` of the same update.

5. **One scriptable function.** `scripted` (`LegendScript`) replaces the scriptable form of each option: the legend
   calls it with the chart context and the options with their fallbacks once for each update, in `beforeUpdate`, merges
   the result and adds the fallbacks again. Row `adapt-legend-scripted`.

   ```dart
   LegendOptions(
     scripted: (context, options) => LegendOptions(
       labels: LegendLabelOptions(color: paintFor(context.chart)),
     ),
   );
   ```

6. **The hidden legend.** The guards of Chart.js ADRs 0092 and 0099 read the object: its reads run no user code, and it
   holds the label color of its update. The guards of the `_scriptable` descriptor, of plain label values and of the
   native scopes behind the resolvers go, and so does `DatasetController.nativeLegendLabelKeys`. The other guards stay.

7. **Tests.** A test that gives legend options gives a typed config with `pluginOptions`. The generated data and the
   hand fixtures keep raw configs with the object in `plugins.legend`. No helper turns a Map into options.

## Rejected

- Keep `ChartLegend` over the object: two types with the same fields again.
- A typed function field for each scriptable option: about 25 more fields for a rare form.
- Resolve the fonts with `toFont` in the hook: upstream keeps the raw font in the options and calls `toFont` at each
  use, and a reader of `legend.options.labels.font` gets the font of the options.

## Consequences

- A new closure in `LegendOptions` is a new value: a typed config built in `build` updates the chart. A tear-off of a
  top-level function or a static method is equal at each build. `ChartLegend` had trampolines for its handlers.
- A scriptable option runs once for each update, in `beforeUpdate`, not once for each read. The D2 case of a scriptable
  label color calls the function once for each update, as upstream does.
- `legend.options` before the first `beforeUpdate` is the merged object with no fallbacks.
- `labels.pointStyle: false` has no form: null gives the point style of the dataset, as the falsy value does upstream.
- The upstream `plugins.legend` defaults and descriptors of the manifest compare with the fields of the object; the
  color functions and the descriptors are a named exception list of the schema test.

## Tests

`test/port/plugins/plugin_options_test.dart`, `test/port/plugins/plugin.legend_test.dart`,
`test/port/plugins/plugin.legend_hidden_test.dart`, `test/specs/plugin.legend_test.dart`,
`test/port/options/schema_test.dart`, `test/port/options/observation_test.dart`, `test/port/core/resolver_trace_test.dart`,
`test/port/typed/value_semantics_test.dart`, `test/port/typed/lowering_test.dart`, `test/port/theme/compile_test.dart`
