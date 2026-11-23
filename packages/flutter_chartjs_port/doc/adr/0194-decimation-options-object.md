# Chart.js ADR 0194: The decimation options are one object

- Status: accepted (2026-11-23): its code is on main, and all the gates of AGENTS.md pass.
- Date: 2026-11-23
- Supersedes: of [Chart.js ADR 0182](0182-resolved-plugin-option-classes.md), item 1 for `DecimationOptions`
  and item 6; of [Chart.js ADR 0054](0054-typed-internal-model.md), §2 for the kind `DecimationOptions` of the
  schema, §3 for the typed defaults scope of the decimation, and §12 for the decimation facade; of
  [Chart.js ADR 0052](0052-typed-public-api.md), §4 and Open item 4 for `parsing` and the decimation plugin
- Related: [Chart.js ADR 0192](0192-tooltip-options-object.md),
  [Zoom ADR 0005](../../../flutter_chartjs_plugin_zoom_port/doc/adr/0005-typed-zoom-options.md),
  [Chart.js ADR 0148](0148-plugin-typing.md)

## Context

The decimation plugin had two types that each declared its options: `DecimationOptionsScope` (generated
from the schema) and `DecimationOptions` (the resolved values, made by `DecimationOptions.of` from a resolver
at each update). The typed API had no parameter for them: an app and each decimation test gave the options
and `parsing: false` through `extra`, a Map. A value that was not an algorithm gave a private algorithm that
threw the error of upstream at its use. Chart.js ADR 0192 made the tooltip options one immutable
`PluginOptions` object, as the zoom add-on does (Chart.js ADR 0148).

## Decision

1. **One class.** `DecimationOptions` of `plugin_options.dart` is a `PluginOptions<DecimationOptions>` with
   one nullable field for each option of `plugin.decimation.js` and of `index.d.ts` `DecimationOptions`:
   `enabled`, `algorithm` (a `DecimationAlgorithm`), `samples`, `threshold` and `events`; `merge`, `==` and
   `hashCode`. A null field is not set. Upstream plugin options are not scriptable (`core.plugins.js:184`):
   the object has no scriptable form.

   ```dart
   ChartConfig(
     datasets: [LineDataset(data: .points(points))],
     parsing: false,
     pluginOptions: const [
       DecimationOptions(enabled: true, algorithm: LttbDecimationAlgorithm(), samples: 100),
     ],
   );
   ```

2. **The paths of the options.** An app gives the object in `ChartConfig.pluginOptions`. A raw config holds the
   object in `options.plugins.decimation`; a Map there stops a debug build, `false` turns the plugin off and
   `true` keeps the defaults. The schema has no kind `DecimationOptions`: the key `decimation` of
   `PluginOptionsByType` is `bool | pluginOptions`. `DecimationOptions.of`, `DecimationOptionsScope` and
   `DecimationAlgorithm.of` are removed.

3. **The defaults.** The plugin `defaults` are one `const DecimationOptions(algorithm:
   MinMaxDecimationAlgorithm(), enabled: false)` (`plugin.decimation.js:200-203`). The plugin service merges
   the objects of the defaults, the theme and the chart, and the hooks get the merged object.

4. **The algorithm.** The field type takes no value that is not an algorithm, so the `default` case of
   `plugin.decimation.js:276-277` has no port: the private algorithm that threw is removed. An object with no
   algorithm takes `MinMaxDecimationAlgorithm()`, the default.

5. **The truthiness of the numbers.** `samples` and `threshold` keep the tests `options.samples ||
   availableWidth` (`:12`) and `options.threshold || 4 * availableWidth` (`:242`): null, 0 and NaN are not
   set.

6. **The typed fields of the decimation tests.** `ChartConfig` gets `parsing` (`options.parsing`, a `bool`),
   `devicePixelRatio` (`options.devicePixelRatio`) and `colors` (`ChartColors`, the options `enabled` and
   `forceOverride` of the colors plugin), the options that the decimation tests set.

7. **Tests.** Each decimation test gives a typed `ChartConfig` with no `extra` and no Map patch after the
   lowering. A change of an option pumps a `ChartView` with the next `ChartConfig`, as an app does. The writes
   of `data`, `_data`, `_decimated` and `type` into the live dataset object stay where they are the subject of
   the row `adapt-decimation-data-accessor`, and the group `js-semantics-narrow-datasets` keeps a dataset Map
   of the user, its subject. The generators write `DecimationOptions` literals; the reference data are
   generated again with the same expectations. No helper turns a Map into options.

## Rejected

- Keep the resolved class next to a typed group: two types with the same fields again.
- A `String` or `Object` field for `algorithm` to keep the error of `:277`: an app cannot hold such a value in
  a typed field, and the error was a port of a name check.
- A `ChartDecimation` group in `ChartConfig`: the object goes in `pluginOptions`, as the tooltip.

## Consequences

- An algorithm name or a number in `algorithm` does not compile, and a raw config with a Map stops a debug
  build where it threw at the first update.
- The two cases of `plugin.decimation_algorithms_test.dart` with a string `samples` and with a value that is
  not an algorithm, and the case of `plugin.decimation_test.dart` with the algorithm `5`, are removed: no
  upstream spec has them.
- The step of the reference case `setOption enabled: false cleans the dataset` writes the whole object
  `plugins.decimation`, with the same observations.

## Tests

`test/port/plugins/plugin_options_test.dart`, `test/port/plugins/plugin.decimation_test.dart`,
`test/port/plugins/plugin.decimation_algorithms_test.dart`, `test/specs/plugin.decimation_test.dart`,
`test/port/theme/decimation_theme_test.dart`, `test/port/typed/lowering_test.dart`,
`test/port/typed/value_semantics_test.dart`, `test/port/typed/reconcile_test.dart`,
`test/port/core/range_update_test.dart`, `test/port/core/data_update_test.dart`,
`test/port/widgets/chart_theme_switch_test.dart`
