# Zoom ADR 0008: Typed mode option

- Status: accepted (2026-11-23): the zoom tests, the fixtures, the range-only suite, analysis and port checks pass.
- Date: 2026-11-23
- Supersedes: [Zoom ADR 0005](0005-typed-zoom-options.md) item 1, the sentence "A `mode`, `scaleMode` or
  `overScaleMode` field holds a `Mode` or a `ModeFn`, and its constructor asserts it."
- Related: [Zoom ADR 0004](0004-native-zoom-pan-callbacks.md)
- Difference: `adapt-native-zoom-options`, `adapt-native-callbacks`.

## Context

Upstream types the options `mode`, `scaleMode` and `overScaleMode` as `ModeOption = Mode | ModeFn`
(`src/options.ts:5-7`). Dart has no union of an enum and a function type, so the three fields of `ZoomOptions` and
`PanOptions` were `Object?`, and only a debug assert of the constructor checked the value. A wrong value compiled,
and each reader switched over `Object?` with a fallback case that no valid value reached.

## Decision

1. `ModeOption` is a sealed class of `lib/src/options.dart`. Its two members are the enum `Mode` and the final
   class `ModeFromChart`, which holds a `ModeFn` in its field `fn`.

   ```dart
   const ZoomOptions(mode: Mode.x);
   ZoomOptions(
     mode: ModeFromChart((context) => context.chart.width > 600 ? .xy : .x),
   );
   ```

2. The fields `mode`, `scaleMode` and `overScaleMode` of `ZoomOptions`, `PanOptions` and `ScaleModeOptions` are
   `ModeOption?`. Null is not set. The constructors have no assert of these fields.
3. Each reader (`directionEnabled`, `_directionsEnabled`, `computeDragRect` and their callers) takes a
   `ModeOption?` and switches over `null`, `Mode` and `ModeFromChart`, with no default case. A `ModeFromChart`
   calls `fn` with `{ chart }` each time the plugin reads the mode, as upstream calls the function.
4. Two `ModeFromChart` values are equal when their functions are equal (the `==` of a function). `merge`, `==` and
   `hashCode` of the option classes compare the fields with `==`.

## Rejected

- A `ModeFn` field next to a `Mode` field: two fields for one option, and a rule for the case with both set.
- An extension type over `Object?`: a wrong value still compiles, and a switch over it is not exhaustive.

## Consequences

- A function in a mode field is `ModeFromChart(fn)`: a bare function does not compile.
- The test that a mode function of another type stops a debug build skips with `diverges: adapt-native-zoom-options`.

## Tests

- `packages/flutter_chartjs_plugin_zoom_port/test/port/callbacks_test.dart`
- `packages/flutter_chartjs_plugin_zoom_port/test/specs/utils_test.dart`
- `packages/flutter_chartjs_plugin_zoom_port/test/specs/zoom.drag_test.dart`
