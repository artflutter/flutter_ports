# Chart.js ADR 0148: Typed plugin chart, options and update mode

- Status: accepted (2026-11-15): its code and the tests of section Tests pass.
- Superseded in part by: [Chart.js ADR 0150](0150-typed-plugin-options.md) (2026-11-16), for item 3 (the members of `PluginOptions`) and the consequence on `Plugin.events`
- Date: 2026-11-15
- Supersedes: the parts of [Chart.js ADR 0144](0144-native-plugins.md) that stay dynamic: item 4 (the `Object?`
  update mode of the hook arguments), item 6 (`defaults` and `descriptors` as `Object?`), item 10 (the chart of a
  hook as the core interface only) and Open 1 and 2.
- Related: the draft [native-plugin-typing-design-draft.md](../native-plugin-typing-design-draft.md), zoom seam H18.

## Context

After Chart.js ADR 0144, five parts of the plugin API stayed dynamic: the chart of a hook (an add-on cast it to
`Chart`), the update mode (`Object?`: a string, a function or `undefined`), the options of an add-on (a resolver
read by name), `defaults` and `descriptors` (`Object?`), and the inline plugin List of a raw config (read by name).

## Decision

1. **The chart type.** The plugin class is `PluginOf<O, C extends types.Chart>`. `Plugin<O>` is the alias with the
   core chart interface (the built-in plugins, the tests). `ChartPlugin<O>` is the alias with the public `Chart`:
   its hooks get the public chart. `Plugin.notify` casts the chart once, a checked cast, only for a hook that is
   set.

   ```dart
   final crosshair = ChartPlugin<Object?>(
     id: 'crosshair',
     afterDraw: (chart, args, options) => chart.getActiveElements(), // chart: Chart, no cast
   );
   ```

2. **The update mode.** `UpdateMode` is an extension type over its name that implements `String`, with the
   constants of `UpdateModeEnum` (`defaultMode` for `default`). An add-on adds a mode as a constant, as
   chartjs-plugin-zoom adds `zoom` (`src/index.ts:16`). `chart.update([UpdateMode? mode])` and
   `chart.updateRanges([UpdateMode? mode])` take one mode. The function form `update((ctx) => mode)` is
   `chart.updateDatasets(UpdateModeOf modeOf)`, with `UpdateModeOf = UpdateMode? Function(int datasetIndex)`.
   `UpdateHookArgs` has `UpdateMode? mode` and `UpdateModeOf? modeOf`, and `DatasetUpdateHookArgs.mode` is an
   `UpdateMode?`. `ChartView.updateMode` is an `UpdateMode?`. A transition keeps its key by the name.

3. **The options of an add-on.** An add-on gives its options as one immutable `PluginOptions<T>` object:
   `pluginId` (its key in `options.plugins`) and `merge(over)`. Upstream resolves plugin options with
   `scriptable: false` and `indexable: false` (`core.plugins.js:182-187`), so a merge of the scopes gives the
   values of the resolver. A plugin whose `defaults` is a `PluginOptions` gets the options objects of its scopes
   merged from the defaults to the options of the chart; no resolver runs. The registry writes the defaults object
   into `defaults.plugins.<id>` and merges it over an earlier one. A Map in place of the object stops a debug
   build, `true` adds nothing and `false` turns the plugin off, as upstream. The schema gives the scope
   `PluginOptionsByType` the typed atom `pluginOptions`. `ChartConfig.pluginOptions` writes each object to
   `options.plugins.<pluginId>`: a plugin and its options come apart, so a plugin that `Chart.register` adds for
   all charts takes the options of each chart. The data-only and range updates keep the object.

4. **Defaults and descriptors.** `defaults` is a `PluginDefaults?`, which `OptionScope` and `PluginOptions`
   implement. `descriptors` is a `DescriptorsScope?`: only a built-in plugin with resolver options has rules. A
   test plugin with a plain object of upstream gives a `GenericPluginOptionsScope`.

5. **The inline plugin List.** `Config.plugins` is a `List<Plugin<Object?>>?`. A value that is not a List and an
   empty List are none, as upstream reads `length` of them. A List of another type argument stops a debug build. `ChartView` makes its root List as
   a `List<Plugin<Object?>>`. The service iterates the List with no reads by name.

## Tests

- `test/port/core/core.plugins_typed_public_test.dart`: a `ChartPlugin` with `Chart` hooks and a `PluginOptions`
  class from the public library, merged with the options of the chart.
- `test/port/core/core.plugins_test.dart` and `test/port/types/plugin_test.dart`.
- The zoom port: its options are `ZoomPluginOptions` objects, its hooks take `Chart`, its transitions are
  `UpdateMode` values.
- The full test list of AGENTS.md before a push.

## Consequences

- An add-on has typed options and typed hooks, with no read by name and no cast.
- Each `update('none')` of a test or an app is `update(UpdateMode.none)`.
- A third-party plugin with resolver options and rules (a Map with `descriptors`) has no form; upstream plugins
  resolve with `scriptable: false` unless they give rules, and only built-in plugins give them here.
- `Plugin.events` stays `List<String>?`: an event type is a `String` in the whole port.
