# Chart.js ADR 0144: Native plugins

- Status: accepted (2026-11-14): its code and the tests of section Tests pass.
- Date: 2026-11-14
- Supersedes: [Chart.js ADR 0126](0126-native-plugin-contract.md) (proposed, no code) as a whole.
  The plugin parts of [Chart.js ADR 0054](0054-typed-internal-model.md) §12 (the face, the extras
  and the hook functions of another type), of [Chart.js ADR 0108](0108-input-surface-and-exports-for-add-on-plugins.md)
  (the one hook type `PluginHookFunction<A>` and the plugin Map of user code) and of
  [Chart.js ADR 0052](0052-typed-public-api.md) (`ChartConfig.plugins` as a List of plugin Maps).
- Related: Chart.js ADRs [0074](0074-incremental-data-updates.md) and [0111](0111-range-updates.md) (the data-only and
  range capabilities), [0130](0130-native-callback-options.md) (native callback options), the
  draft [native-plugin-design-draft.md](../native-plugin-design-draft.md).

## Context

Before this change, `Plugin` of `lib/src/types/plugin.dart` was a JS-compatible object. Its hooks
and its metadata were slots of a `List<Object?>`, with reads and writes by name. The plugin
service tested a hook function against nine typedefs at each call and called another function with
`jsCall`. A plugin Map (`MapPlugin`) was a second form of a plugin. Each hook returned `Object?`
and took the options as `Object`.

Chart.js ADR 0126 proposed one class with typed hook fields. Two of its statements do not match the
code. Its item 8 says that the later plugins still run after a cancel: upstream returns at once
(`core.plugins.js:66`). Its migration table says that the zoom hooks take `Chart` with no cast: the
hook type names the chart interface of the core, which the public library does not export.

## Decision

1. **One class with typed hook fields.** `Plugin<O>` has one field for each of the 35 hooks, with
   the function type of its hook. A field is mutable: a test replaces a hook, as upstream code
   replaces `plugin[hook]`. A plugin has no key by name, no extras and no face.

   ```dart
   final crosshair = Plugin<ContextResolver>(
     id: 'crosshair',
     afterDraw: (chart, args, options) => drawCrosshair(chart),
     beforeEvent: (chart, args, options) => args.event.type != 'mouseout',
   );
   ```

2. **Two hook kinds.** A hook that upstream calls with `cancelable: true` is a
   `CancelableHookFunction<A, O>` and returns `bool`: `false` cancels the step, and `true`
   continues. The ten cancelable hooks are `beforeUpdate`, `beforeDatasetsUpdate`,
   `beforeDatasetUpdate`, `beforeLayout`, `beforeRender`, `beforeDraw`, `beforeDatasetsDraw`,
   `beforeDatasetDraw`, `beforeEvent` and `beforeTooltipDraw`. Each other hook is a
   `PluginHookFunction<A, O>` and returns `void`. The kind replaces `args.cancelable`.

3. **The hook enum.** `PluginHook<A>` is a public generic enum. Each value has its JS name, its
   kind and the argument class `A` of its calls. `chart.notifyPlugins(PluginHook.afterDraw)` takes
   the enum and an `A?`. A hook name that is not one of the 35 hooks has no form.

4. **Typed arguments.** The argument classes are plain final classes, not typed records. No class
   has a `cancelable` field, and `CancelableHookArgs` goes: the four cancelable hooks without
   arguments take `PluginHookArgs`. `DatasetUpdateHookArgs.meta` and `DatasetDrawHookArgs.meta`
   are a `ChartMeta`, `EventHookArgs.event` is a `ChartEvent` and `EventHookArgs.replay` is a
   `bool` (an absent replay is `false`). `ResizeHookArgs.size` is the record
   `({double width, double height})` of the resize, and `TooltipDrawHookArgs.tooltip` is the
   `TooltipModel`. `EventHookArgs.inChartArea` and `changed` stay writable. The four scale hooks
   take the `ScriptableScaleContext` of the scale (`core.scale.js:535`).

5. **Plugin options.** The optional `options` makes the `O` of the hooks from the resolved options
   of the plugin, for example the constructor of a facade (`ZoomPluginOptions.new`). With no
   `options`, the hooks get the resolved options themselves: then `O` is `ContextResolver`,
   `Object` or `Object?`, and another `O` stops a debug build. `O` has no bound, because a facade
   is an extension type over `Object?`. The plugin service stores `Plugin<Object?>` and calls
   `Plugin.notify`, a generic method that reads the hook field inside the class: a read through
   `Plugin<Object?>` fails the covariance check of Dart. The filler, the decimation and the colors
   plugins take their facades. The legend, the title, the subtitle, the tooltip and the plugin of
   `ChartView` take the resolved options. `dataUpdateGuard` and `rangeUpdateGuard` take `O`.

6. **Typed metadata.** `id` is a required `String`. `events` is a `List<String>?`,
   `defaultRoutes` a `Map<String, String>?` and `additionalOptionScopes` a `List<String>?`.
   `defaults` and `descriptors` are a typed scope for a built-in plugin and a
   `Map<String, Object?>` for another plugin. The registry and the config read the typed fields.

7. **No Map plugins.** An inline plugin of `config.plugins` and a registered plugin are `Plugin`
   objects, also in a raw config. A value of another type stops a debug build, and a release build
   skips it. Dart `null` and `undefined` throw the `TypeError` of `plugin.id`, as upstream. A Map
   without an `id` in `Chart.register` stays a container of components. `MapPlugin`,
   `isHookFunction`, the dispatch of a class value and the `jsCall` of a hook go. A plugin has no
   `beforeRegister` or `afterRegister` callback: the registry calls them only on a class value.
   The typed `ChartConfig.plugins` is a `List<Plugin<Object?>>?`.

8. **Order and identity.** The service keeps the upstream order of the descriptors, the `start`
   and `stop` diff, the `install` and `uninstall` calls, the event filter and the args object by
   identity. The first `false` of a cancelable hook ends the notify at once: the later plugins do
   not run, as upstream.

9. **Removed keys.** The key `_element` of the legend, title and tooltip plugins is for the tests
   upstream: the tests read `Legend.jsClass`, `Title.jsClass` and `Tooltip.jsClass`. The hook
   `destroy` of the decimation plugin has no field, because no notify of Chart.js v4 calls it. The
   keys `version`, `panFunctions`, `zoomFunctions` and `zoomRectFunctions` of the zoom plugin are
   top-level names of the zoom library.

10. **The chart of a hook.** A hook takes `types.Chart`, the chart interface of the core layer,
    because the filler and the decimation plugins are core layers. The public library hides that
    interface. A closure literal needs no parameter type. A named hook function of an add-on takes
    `Object chart` and casts it to `Chart`.

## Tests

- `test/port/types/plugin_test.dart`: the hook kinds, the dispatch, the guards and the arguments.
- `test/port/core/core.plugins_test.dart`: the scenarios of `registry_reference.mjs` with native
  plugins, with the hook `reset` in place of the custom hook `hook`.
- `test/port/core/core.plugins_typed_public_test.dart`: a plugin of the public API.
- `test/specs/core.plugin_test.dart`: the 19 cases of `core.plugin.tests.js` with native plugins.
- The full test list of AGENTS.md before a push.

## Consequences

- A plugin of an app, of a test or of an add-on is one Dart object with typed hooks. The analyzer
  checks the argument class and the result of each hook.
- The public `notifyPlugins` takes no custom hook name. A plugin that needs its own events uses
  Dart code, for example a callback option.
- The test harness makes a native plugin of a plugin Map of the reference data
  (`test/support/native_plugin.dart`), as it makes the segment style.
- The O1 oracle records the hooks of a native plugin with the path of the field.

## Open

1. The update mode is a string, a function or `undefined`: `UpdateHookArgs.mode` stays `Object?`.
   A separate change can give it a type.
2. The public library can export the chart interface of the core under a public name. Then a named
   hook of an add-on needs no cast.
