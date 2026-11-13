# Zoom ADR 0004: Native zoom and pan callbacks

- Status: accepted (2026-11-13): the zoom tests, the fixtures, the range-only suite, analysis and port checks pass.
- Date: 2026-11-13
- Related: [Zoom ADR 0003](0003-host-connection.md) item 9 (the call of a user function),
  [Chart.js ADR 0125](../../../flutter_chartjs_port/doc/adr/0125-native-tooltip-callbacks.md) (native tooltip
  callbacks), the candidate list
  [callback-migration-candidates.md](../../../flutter_chartjs_port/doc/callback-migration-candidates.md) (item 3).
- Difference: `adapt-native-callbacks`.

## Context

The zoom and pan options have eight callbacks: `onZoomStart`, `onZoom`, `onZoomComplete`, `onZoomRejected`,
`onPanStart`, `onPan`, `onPanComplete` and `onPanRejected`. The options `mode`, `scaleMode` and `overScaleMode` also
take a function (`ModeFn`). The callback contexts are records, and each callback type has a typedef. But each option
getter gives the raw value as `Object?`. Each call site tests the typedef first and then calls `callUser`, which calls
any other function through `jsCall` with JS arity. A start callback gives `bool?`, and the port tests the result for
`false`, as upstream tests `=== false`.

The candidate list asks for typed callback fields, explicit start acceptance and direct calls.

## Decision

1. Each callback getter of `ZoomOptions` and `PanOptions` gives its typedef type or null:

   ```dart
   ZoomCallback? get onZoom;
   GenericEvent? get onZoomComplete;
   RejectEvent<NativeEvent>? get onZoomRejected;
   RejectableStartEvent<NativeEvent>? get onZoomStart;
   GenericEvent? get onPan;
   GenericEvent? get onPanComplete;
   RejectEvent<GestureEvent>? get onPanRejected;
   RejectableStartEvent<GestureEvent>? get onPanStart;
   ```

   A raw config and `ChartConfig.extra` hold the same Dart function. Null and `undefined` mean no callback. A value of
   another type is a foreign value: a debug build stops on it, and a release build makes no call.
2. A start callback returns `bool`. `true` starts the zoom or the pan, and `false` rejects it and calls the reject
   callback. Upstream accepts `undefined`. A Dart callback states its result.

   ```dart
   final zoom = <String, Object?>{
     'mode': Mode.xy,
     'onZoomStart': (ZoomStartContext<NativeEvent> context) => context.point.x > 40,
     'onZoomComplete': (ZoomChartContext context) => print(context.chart.getZoomLevel()),
   };
   ```

3. `mode`, `scaleMode` and `overScaleMode` hold a `Mode` or a `ModeFn`. The plugin calls a `ModeFn` directly. Another
   function is a foreign value, as in item 1.

   ```dart
   final pan = <String, Object?>{
     'enabled': true,
     'mode': (ZoomChartContext context) => context.chart.width > 400 ? Mode.xy : Mode.x,
   };
   ```

4. `callUser` and the `jsCall` import of `utils.dart` go. The call sites call the typed value with `?.call`. The
   invocation order, the contexts, the debounce of `onZoomComplete` and the live reads of the options do not change.
5. The specs keep their cases. A Jasmine spy goes into a typed closure that records the context
   (`(ZoomChartContext context) => spy.call(context)`). A start spy that returns nothing returns `true` in its
   closure, because `undefined` accepts upstream.
6. This decision supersedes the bullet "A user function (`mode`, `onZoom`, `onPanStart`, ...) gets a typed call when
   the value has the type of its typedef, else `jsCall` with JS arity" of Zoom ADR 0003 item 9. The typed options slot
   of seam H18 stays in zoom phase 5.

## Tests

- The specs `api`, `pan`, `zoom.wheel`, `zoom.pinch` and `zoom.drag` with typed closures.
- `test/port/plugin_test.dart`: a foreign callback value and a foreign mode function stop a debug build, a start
  callback that returns `true` starts the zoom, and a `ModeFn` selects the directions.
- The fixtures, the range-only suite and the tests of real input.
