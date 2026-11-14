# Chart.js ADR 0126 proposal: A native plugin contract

- Status: superseded (2026-11-14) by [Chart.js ADR 0144](0144-native-plugins.md), which states the decision as built.
- Date: 2026-11-13
- Related: Chart.js ADR 0054 §12 (the typed plugin objects), Chart.js ADR 0108 (the typed plugin API for add-on
  ports), Chart.js ADR 0074 and 0111 (the data-only and range-only capabilities), Chart.js ADR 0125 (native tooltip
  callbacks).

## Context

`Plugin` of `lib/src/types/plugin.dart` is a JS-compatible object with typed getters. These parts are still dynamic:

- The metadata `id`, `events`, `defaults`, `defaultRoutes`, `descriptors` and `additionalOptionScopes` are `Object?`.
- The 39 hooks are slots of a `List<Object?>`. Code can write any value into a slot by name.
- `PluginHookFunction<A>` returns `Object?` and takes the options as `Object`. Some arguments are `Object?` fields
  (`mode`, `size`, `replay`, `tooltip`), and the scale hooks take `AnyObject`.
- `Plugin.invokeHook` tests the function against nine typedefs at each call. A function of another type takes
  `jsCall` with `this` the plugin.
- `PluginService._notify` also dispatches a Map plugin (`MapPlugin`) by the hook name, with `jsCall`.

Upstream calls a hook as `plugin[hook].call(plugin, chart, args, options)`. A hook can cancel only when `args`
has `cancelable: true` and the hook returns `false` (`core.plugins.js:59-71`). The call sites define the cancelable
hooks (`core.controller.js` and `plugin.tooltip.js:1254`), not the `index.d.ts` declarations. The two sources differ
for `beforeDatasetsUpdate`, `afterDatasetsUpdate` and `beforeDatasetDraw`.

## Decision

1. **One class with typed hook fields.** `Plugin<O>` keeps one field for each hook. Each field has the exact
   function type of its hook. A field is mutable, because upstream code and the specs replace hooks at run time
   (`plugin.beforeUpdate = spy`). A write goes through the typed setter only. The by-name face of the hooks, the
   slot List, the extras and `invokeHook` go.

   ```dart
   final crosshair = Plugin<CrosshairOptions>(
     id: 'crosshair',
     options: CrosshairOptions.new,
     afterDraw: (chart, args, options) => drawCrosshair(chart, options.color),
     beforeEvent: (chart, args, options) => args.event.type != 'mousemove' || options.enabled,
   );
   ```

2. **Two hook kinds.** A hook that upstream calls with `cancelable: true` returns `bool`. `false` cancels the step,
   and `true` continues. Each other hook returns `void`. The service needs no runtime test of `cancelable` for a
   typed hook: the field type states it.

   | Hook | Kind | Arguments |
   | --- | --- | --- |
   | `install`, `start`, `stop`, `uninstall`, `beforeInit`, `afterInit`, `reset`, `beforeElementsUpdate`, `afterLayout`, `afterRender`, `afterDraw`, `afterDatasetsDraw`, `beforeDestroy`, `afterDestroy` | void | `PluginHookArgs` (no fields) |
   | `beforeUpdate`, `beforeDatasetsUpdate` | cancelable | `UpdateHookArgs` |
   | `afterUpdate`, `afterDatasetsUpdate` | void | `UpdateHookArgs` |
   | `beforeDatasetUpdate` | cancelable | `DatasetUpdateHookArgs` |
   | `afterDatasetUpdate` | void | `DatasetUpdateHookArgs` |
   | `beforeLayout`, `beforeRender`, `beforeDraw`, `beforeDatasetsDraw` | cancelable | `CancelableHookArgs` |
   | `beforeDatasetDraw` | cancelable | `DatasetDrawHookArgs` |
   | `afterDatasetDraw` | void | `DatasetDrawHookArgs` |
   | `beforeDataLimits`, `afterDataLimits`, `beforeBuildTicks`, `afterBuildTicks` | void | `ScriptableScaleContext` |
   | `beforeEvent` | cancelable | `EventHookArgs` |
   | `afterEvent` | void | `EventHookArgs` |
   | `resize` | void | `ResizeHookArgs` |
   | `beforeTooltipDraw` | cancelable | `TooltipDrawHookArgs` |
   | `afterTooltipDraw` | void | `TooltipDrawHookArgs` |

3. **Typed arguments.** The argument classes keep their identity and their writable fields. Their open fields
   become exact types: `UpdateHookArgs.mode` is the update mode, `ResizeHookArgs.size` is
   `({double width, double height})`, `EventHookArgs.replay` is `bool`, and `TooltipDrawHookArgs.tooltip` is
   `TooltipModel`. The scale hooks take the scale context that upstream passes (`core.scale.js:535`), not a new
   record. A hook with no arguments takes one shared `PluginHookArgs`, as now.
4. **Plugin-specific options.** `Plugin<O>` takes `options`, a function that makes the `O` view of the resolved
   option view. A built-in plugin gives its existing facade (`LegendOptions.new`, `TooltipOptions.new`). A plugin
   without a facade uses `Plugin<OptionView>`. The service stores `Plugin<Object>`, and the plugin applies its own
   `options` function inside a generic method. Thus the option type survives the registration, and no dispatch
   tests the arity or the function type. The value `false` of `plugins.<id>` still disables the plugin, and no hook
   sees it.
5. **Typed metadata.** `id` is a `String` and is required. `events` is a `List<String>?` of event types.
   `defaults` is a `Map<String, Object?>?` for a third-party plugin, the form that the registry merges into the
   typed defaults. A built-in plugin keeps its typed default scope. `defaultRoutes` is a `Map<String, String>?`.
   `descriptors` is a typed record of the `_scriptable` and `_indexable` rules. `additionalOptionScopes` is a
   `List<String>?`. The Dart capabilities `supportsDataUpdates`, `dataUpdateGuard` and `rangeUpdateGuard` stay.
6. **No Map plugins.** An inline plugin of `config.plugins` and a registered plugin are `Plugin` objects, also in a
   raw config. `MapPlugin`, the Map branch of `_notify` and the `jsCall` of hooks go. A Map in the `plugins` List
   stops a debug build, and a release build skips it. The typed `ChartConfig.plugins` takes `List<Plugin>`. This
   closes the inline-plugin half of zoom seam H18.
7. **Extensibility.** `Plugin` stays a final class with function fields, as `TooltipCallbacks` is. A plugin
   author composes behavior through the fields and the `O` type. A plugin that needs state keeps it in its closures
   or in an `Expando` of the chart, as the built-in plugins do now.
8. **Order and identity.** The service keeps the upstream order of the descriptors, the `start` and `stop` diff,
   the `install` and `uninstall` calls, the event filter, the cancellation of the first `false` with the later
   plugins still called, and the args object by identity.

## Migration

| Step | Size | Done when |
| --- | --- | --- |
| Add the typed fields, the two hook kinds and the typed arguments | large | `plugin.dart` has no slot List and no `invokeHook` |
| Move the seven built-in plugins and the `$chartView` plugin | medium | each built-in plugin is a `Plugin<Facade>` |
| Remove `MapPlugin` and the Map branch of the service | medium | `core.plugins.dart` has no `jsCall` and no by-name hook read |
| Port the plugin specs and the reference tests to typed plugins | large | the specs `core.plugin` and `plugin.*` pass with typed hooks |
| Move the zoom plugin and the gallery, docs and lab plugins | medium | the zoom hooks take `Chart` without a cast |
| Update `public_api.txt`, the typed-read baselines and AGENTS.md | small | `check:port` and the public API test pass |

## Open questions

1. Some specs read a plugin by name, for example the keys of a registered plugin. The implementation must list
   these reads and port each one to a typed member, or mark the case `diverges:` with a row.
2. The update mode is a string in upstream. A separate change can make it an enum. This decision only removes the
   `Object?` type.
3. The plugin descriptor of the service holds the options as a resolver view. Step 4 needs a measure of the cost
   of the `O` view at each hook call. A cached view per descriptor and options generation is the fallback.
