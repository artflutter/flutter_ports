# Zoom ADR 0005: Typed zoom options

- Status: accepted (2026-11-15): the zoom tests, the fixtures, the range-only suite, analysis and port checks pass.
- Date: 2026-11-15
- Superseded in part by: [Zoom ADR 0007](0007-typed-zoom-limits.md): the limits are a class with direction and axis keys (2026-11-20)
- Supersedes: of [Zoom ADR 0003](0003-host-connection.md) item 9, the bullets of the update mode (seam H15), of the
  plugin object (seam H16), of the option facades (seam H17) and of the defaults Map; of
  [Zoom ADR 0004](0004-native-zoom-pan-callbacks.md), item 1 (the callback getters and the foreign value) and the
  foreign value of item 3.
- Related: [Chart.js ADR 0148](../../../flutter_chartjs_port/doc/adr/0148-plugin-typing.md) (the host change),
  seam H18 of [host-seams.md](../host-seams.md).
- Difference: `adapt-native-zoom-options`.

## Context

The hooks of the plugin read their options through extension-type facades over the resolver of the host: each getter
reads one key by name and gives the raw JavaScript value, and each call site keeps the JavaScript operators. The
defaults are a mutable Map, a hook casts its chart from `Object` to `Chart`, and the update mode is a `String`.
Chart.js ADR 0148 gives the host the types for all four: `ChartPlugin<O>`, `PluginOptions<T>`,
`ChartConfig.pluginOptions` and `UpdateMode`.

## Decision

1. The options are immutable final classes with one nullable field for each option of `src/options.ts`, `merge`,
   `==` and `hashCode`: `ZoomPluginOptions` (a `PluginOptions` with `pluginId` `'zoom'`), `ZoomOptions`,
   `PanOptions`, `WheelOptions`, `DragOptions`, `PinchOptions` and `ScaleLimits`. `LimitOptions` is
   `Map<String, ScaleLimits>`, and a limit is a `ScaleLimit`: `ScaleLimit(0)` or `ScaleLimit.original`. A field
   that is null is not set. `merge` takes each field that the other object sets; a nested object merges its own
   fields, and `limits` merges by scale id. A callback field has its typedef type (Zoom ADR 0004). A `mode`,
   `scaleMode` or `overScaleMode` field holds a `Mode` or a `ModeFn`, and its constructor asserts it.

   ```dart
   ChartConfig(
     type: .line,
     pluginOptions: const [
       ZoomPluginOptions(
         pan: PanOptions(enabled: true, mode: Mode.x),
         zoom: ZoomOptions(wheel: WheelOptions(enabled: true)),
         limits: {'x': ScaleLimits(min: ScaleLimit.original, max: ScaleLimit(100))},
       ),
     ],
   );
   ```

2. `defaults` is a `const ZoomPluginOptions` with the values of `src/defaults.ts`. The plugin service merges the
   options of the defaults and of the chart, and the hooks get the merged object.
3. `zoomPlugin` is a `ChartPlugin<ZoomPluginOptions>`: each hook takes `Chart chart` with no cast.
4. The update mode is an `UpdateMode` of the host. The library constant `zoomUpdateMode` is the mode `zoom` of
   `UpdateModeEnum` (`src/index.ts:15-17`). The transition parameters of `zoom`, `zoomRect`, `zoomScale`,
   `resetZoom`, `pan` and the `ZoomChart` methods are `UpdateMode`, with the upstream defaults.
5. The port-only option `rangeOnlyUpdates` is a field of `ZoomPluginOptions`.
6. A key that no interface declares has no field: the removed option `zoom.enabled` cannot be given, and its
   warning never prints. Its two port-only cases skip with `diverges: adapt-native-zoom-options`.

## Tests

- `test/specs/defaults_test.dart`: the defaults object and the options of the hook equal the upstream object.
- The specs, the 12 fixtures, the range-only suite and the tests of real input, with the options as objects.
- `test/port/plugin_test.dart`: a callback in the options keeps the data-only update of a `ChartView`.
- `test/port/callbacks_test.dart`: a mode function of another type stops a debug build.
