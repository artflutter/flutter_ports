# Chart.js ADR 0192: The tooltip options are one object

- Status: proposed
- Date: 2026-11-23
- Supersedes: of [Chart.js ADR 0182](0182-resolved-plugin-option-classes.md), item 1 for `TooltipOptions`, item 4,
  item 5 for `TooltipOptions.view`, and item 7 for the tooltip `cornerRadius` and `animations`; of
  [Chart.js ADR 0148](0148-plugin-typing.md), item 3 for the scope list of a plugin whose defaults are a
  `PluginOptions`; of [Chart.js ADR 0052](0052-typed-public-api.md), §1 and §8 for `ChartTooltip` and the
  parameter `tooltip` of `ChartConfig`; of [Chart.js ADR 0054](0054-typed-internal-model.md), §2 for the kind
  `TooltipOptions` of the schema, §3 for the typed defaults scope, the routes and the descriptors of the
  tooltip, and §12 for the tooltip facade; of [Chart.js ADR 0125](0125-native-tooltip-callbacks.md), the typed
  API `ChartTooltip(callbacks: ...)`; of [Chart.js ADR 0124](0124-native-text-direction.md), the field of
  `ChartTooltip`
- Related: [Zoom ADR 0005](../../../flutter_chartjs_plugin_zoom_port/doc/adr/0005-typed-zoom-options.md),
  [Chart.js ADR 0150](0150-typed-plugin-options.md)

## Context

The tooltip plugin had three types that each declared every option again: `ChartTooltip` (the typed API,
lowered by `lowerTooltip`), `TooltipOptionsScope` (generated from the schema) and `TooltipOptions` (the
resolved values, made by `TooltipOptions.of` from a resolver at each `setContext`). An option that one of
them missed needed `extra`, a Map. The zoom add-on gives its options as one immutable `PluginOptions`
object (Chart.js ADR 0148), with no resolver, and the plugin service merges the objects of its scopes.

## Decision

1. **One class.** `TooltipOptions` of `plugin_options.dart` is a `PluginOptions<TooltipOptions>` with one
   nullable field for each option of `plugin.tooltip.js:1275-1325` and of `index.d.ts` `TooltipOptions`
   (also `mode`, `intersect`, `axis`, `includeInvisible`, `reverse` and `events`), `merge`, `==`, `hashCode`.
   A null field is not set. The fonts, `animation` and `callbacks` merge by field; `animations` merge by item
   class. `TooltipCallbacks` gets a value `==`.

   ```dart
   ChartConfig(
     datasets: [LineDataset(data: .values([3, 5, 2]))],
     pluginOptions: const [TooltipOptions(mode: IndexInteractionMode(), intersect: false)],
   );
   ```

2. **The paths of the options.** `ChartTooltip`, `lowerTooltip` and `ChartConfig.tooltip` are removed: an app
   gives the object in `ChartConfig.pluginOptions`. A raw config holds the object in `options.plugins.tooltip`;
   a Map there stops a debug build, `false` turns the plugin off and `true` keeps the defaults. The schema has no
   kind `TooltipOptions`: the key `tooltip` of `PluginOptionsByType` is `bool | pluginOptions`. The theme writes
   one `TooltipOptions` with the keys that it themes. The sankey override writes a `TooltipOptions`.

3. **The defaults.** The plugin `defaults` are one `const TooltipOptions` with each default of upstream; the
   plugin has no `defaultRoutes` and no `descriptors`. It keeps the key `additionalOptionScopes`, and
   `Config.pluginScopeKeys` adds no additional scope for a plugin whose defaults are a `PluginOptions`: the
   scope list holds only `plugins.<id>` objects, which `_mergeOptions` merges from the defaults to the chart.

4. **The fallbacks in Dart.** The tooltip keeps the merged object and resolves it (`Tooltip._resolved`):
   `mode`, `intersect`, `axis` and `includeInvisible` that it does not set come from `options.interaction` of
   the chart (the additional scope of upstream); the three fonts merge over `Chart.defaults.font` with
   `toFont` (the routes); `boxWidth` and `boxHeight` take the size of the body font. `tooltip.options` holds the
   resolved object. The interaction modes read it through `InteractionOptionValues`.

5. **One scriptable function.** `scripted` (`TooltipScript`) replaces the scriptable form of each option: the
   tooltip calls it with its context and the resolved options where upstream calls `setContext`, merges the
   result and resolves again. Row `adapt-tooltip-scripted`.

   ```dart
   TooltipOptions(
     scripted: (context, options) => TooltipOptions(
       backgroundColor: context.tooltipItems!.length > 1 ? multi : single,
     ),
   );
   ```

6. **Animations.** `animation` is a `TooltipAnimation` (`TooltipAnimation.off` is `false`), and `animations` a
   `List<PropertyAnimation>` with the new item classes `CaretXAnimation`, `CaretYAnimation` and
   `OpacityAnimation`. The tooltip builds the config of `new Animations(chart, opts)` from them at each
   `_resolveAnimations`: each property takes its item, else `animation` (the `_fallback` of upstream).

7. **Tests.** A test that gives tooltip options gives a typed config with `pluginOptions`. The generated data and
   the hand fixtures keep raw configs with the object in `plugins.tooltip`. No helper turns a Map into options.

## Rejected

- Keep `ChartTooltip` over the object: two types with the same fields again.
- A typed function field for each scriptable option: 40 more fields for a rare form.
- A Map adapter for raw configs and tests: a raw config takes the object, as for zoom.

## Consequences

- A new closure in `TooltipOptions` is a new value: a typed config built in `build` updates the chart. A
  tear-off of a top-level function or a static method is equal at each build. `ChartTooltip` had trampolines.
- A scriptable option runs once for each `setContext` point, not once for each read.
- The key order of the tooltip options is the order of the fields, not of the scopes.
- The upstream `plugins.tooltip` defaults, routes and descriptors of the manifest compare with the fields of the
  object; the routes and the descriptors are a named exception list of the schema test.

## Tests

`test/port/plugins/plugin_options_test.dart`, `test/port/plugins/plugin.tooltip_test.dart`,
`test/specs/plugin.tooltip_test.dart`, `test/port/options/schema_test.dart`, `test/port/options/observation_test.dart`,
`test/port/typed/value_semantics_test.dart`, `test/port/typed/lowering_test.dart`, `test/port/theme/compile_test.dart`
