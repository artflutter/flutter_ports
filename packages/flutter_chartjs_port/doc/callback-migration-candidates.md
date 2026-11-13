# Callback migration candidates

- Status: candidate list, not an implementation plan.
- Date: 2026-11-13
- Scope: callback objects and callback groups in the Chart.js and zoom ports.

A native migration means real typed fields, typed arguments/results, and direct Dart invocation. A class backed by
`Object?` slots, runtime function checks and a JS-call fallback is only partially typed. Beta compatibility does not
require keeping callback Maps, `JsFunction`, arbitrary arity or by-name mutation.

## Candidates, by priority

| Priority | Candidate | Callback surface | Current gap | Native target | State |
| --- | --- | --- | --- | --- | --- |
| 1 | **Whole Plugin object** | Installation, start/stop, initialization, update/layout/render/draw, dataset, event, resize, destruction and tooltip hooks | `List<Object?>` storage; raw metadata; `Object` options; broad hook results; runtime signature checks; `jsCall` fallback and `MapPlugin` | A plugin contract with real metadata/hook fields, plugin-specific option types, concrete arguments and explicit cancellation results. | Proposed: [Chart.js ADR 0126](adr/0126-native-plugin-contract.md). |
| 2 | **TooltipCallbacks** | All 14 title/body/label/footer/style callbacks | Generic function cells, `Object?` callback object, JS `this`, dynamic dispatch and generic dataset overrides | One immutable callback object, direct typed calls, nullable native results and `merge`. [Proposal](adr/0125-native-tooltip-callbacks.md). | Done (Chart.js ADR 0125). |
| 3 | **Zoom callbacks** | `onZoomStart`, `onZoom`, `onZoomComplete`, `onZoomRejected` | Typed context records and typedefs exist, but option getters return raw values and invocation retains a JS fallback | Typed callback fields using the existing contexts; explicit start acceptance/rejection and direct calls. | Done ([Zoom ADR 0004](../../flutter_chartjs_plugin_zoom_port/doc/adr/0004-native-zoom-pan-callbacks.md)). |
| 3 | **Pan callbacks** | `onPanStart`, `onPan`, `onPanComplete`, `onPanRejected` | Same remaining dynamic boundary as zoom | Migrate alongside zoom using the same callback conventions. | Done ([Zoom ADR 0004](../../flutter_chartjs_plugin_zoom_port/doc/adr/0004-native-zoom-pan-callbacks.md)). |
| 4 | **Legend label generation** | `generateLabels`, `filter`, `sort` | Raw function reads and generic invocation; `LegendItem` has mostly `Object?` fields | Typed item production, boolean filtering and typed comparison. Include the returned legend-item contract. | Open. |
| 5 | **Legend events** | `onClick`, `onHover`, `onLeave` | The app API has typed callbacks/trampolines, but the underlying options and invocation remain dynamic | Direct typed event/item/legend callbacks in raw and typed configurations. | Open. |
| 6 | **Scale-local lifecycle hooks** | Before/after update, dimensions, data limits, tick building, label conversion, rotation and fitting | Fourteen facade getters still return `Object?` | Typed functions over the scale interface, preserving hook order and existing mutation effects. | Open. |
| 7 | **Chart events** | `onClick`, `onHover`, `onResize` | Typed app-facing wrappers exist; core reads raw functions and calls the generic callback helper | Typed event/active-item/chart and chart/size signatures through the core boundary. | Open. |
| 8 | **Animation events** | `onProgress`, `onComplete` | Typed event objects and app adapters exist; option lookup and invocation are still generic | Direct callbacks over the existing animation event type. This is separate from migrating animation interpolators/specifications. | Open. |
| 9 | **Other tooltip callbacks** | `filter`, `itemSort`, `external` | Generic calls with raw arguments and JS `this`; these are outside the 14-hook callbacks object | Typed filtering, ordering and external rendering callbacks using the shared tooltip/item views. | Open. |

Priority reflects architectural impact. TooltipCallbacks is the smaller, already-drafted migration; Plugin needs its
own full API proposal before implementation. The ranking does not claim that Plugin is ready to implement first.

## Plugin is not already finished

[Plugin](../lib/src/types/plugin.dart) currently provides typed accessors and some direct-call paths over a JS-compatible
object. The following remain migration work:

- Metadata such as `id`, `events`, defaults, routes and descriptors uses raw values.
- Hooks are stored in `List<Object?>` and can be written by name.
- `PluginHookFunction<A>` returns `Object?` and receives untyped `Object` options; some arguments are still Maps.
- `invokeHook` checks signatures at runtime and falls back to JS invocation.
- [PluginService](../lib/src/core/core.plugins.dart) also dispatches Map plugins and other objects by hook name.

The native proposal should separate non-cancelable `void` hooks from cancelable hooks and preserve each hook's exact
cancellation rules. Plugin-specific option typing must survive registration and dispatch. A heterogeneous registry
may need a typed adapter created at registration; it must not recreate arbitrary-arity dispatch at every invocation.
Keep plugin implementations extensible, including custom option types and existing update capabilities.

## Source map

| Candidate | Main code |
| --- | --- |
| Plugin | [types/plugin.dart](../lib/src/types/plugin.dart), [core.plugins.dart](../lib/src/core/core.plugins.dart) |
| Tooltip callbacks | [plugin.tooltip.dart](../lib/src/plugins/plugin.tooltip.dart), [plugin_options.dart](../lib/src/plugins/plugin_options.dart) |
| Zoom and pan | [options.dart](../../flutter_chartjs_plugin_zoom_port/lib/src/options.dart), [utils.dart](../../flutter_chartjs_plugin_zoom_port/lib/src/utils.dart) |
| Legend callbacks/items | [plugin.legend.dart](../lib/src/plugins/plugin.legend.dart), [plugin_options.dart](../lib/src/plugins/plugin_options.dart) |
| Scale-local hooks | [scale_options.dart](../lib/src/core/scale_options.dart), [core.scale.dart](../lib/src/core/core.scale.dart) |
| Chart and animation events | [core.controller.dart](../lib/src/core/core.controller.dart), [typed/lower.dart](../lib/src/typed/lower.dart) |

## Shared migration rules

- Preserve upstream option paths. Most entries above are callback fields inside an options object, not an upstream
  object named `callbacks`; introducing a native group must not silently invent new configuration nesting.
- Scale-local hooks and plugin hooks with similar names are separate contracts.
- Reuse existing context/event/item types, promoting shared views into the core when necessary. Do not add parallel
  representations solely to rename them.
- Use `merge` for configuration objects where absent fields inherit. Define return semantics independently for each
  group; tooltip null-to-default behavior must not be copied blindly into cancellation or notification hooks.
- Keep behavior extension points open. Closed data/result unions are appropriate only when their alternatives are
  defined by the consumer protocol.
- Preserve invocation order, identity, cancellation, reentrancy, live callback replacement and update behavior.
- Remove the old dynamic path when a group is migrated. A typed wrapper that lowers back to raw callback storage is
  not completion. Verify rendering/interaction behavior and measure performance separately.
