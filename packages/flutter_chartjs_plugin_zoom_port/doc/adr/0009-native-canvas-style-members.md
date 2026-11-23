# Zoom ADR 0009: Native canvas style members

- Status: proposed
- Date: 2026-11-24
- Supersedes: [Zoom ADR 0003](0003-host-connection.md) item 7, the sentence "The extension `CssStyleProperties`
  gives `style.touchAction`, `style.userSelect` and `style.removeProperty(...)`. Thus the upstream lines
  `src/gestures.ts:200-207` and `:220-222` stay as they are."
- Related: [Chart.js ADR 0200](../../../flutter_chartjs_port/doc/adr/0200-native-canvas-style-members.md)
- Difference: `adapt-canvas-style-members`.

## Context

The gesture manager sets `touch-action: none` and `user-select: none` on the canvas while pan or pinch is on,
and restores the old values at `destroy` (`src/gestures.ts:200-207`, `:220-222`). The host now has no canvas
style: Chart.js ADR 0200 gives the canvas `touchAction` (the enum `CanvasTouchAction`) and `userSelect` (a
`bool`).

## Decision

1. The manager writes the typed members and keeps their old values.

   ```dart
   // Before
   _previousTouchAction = _canvas.style.touchAction;
   _canvas.style.touchAction = 'none';
   _previousUserSelect = _canvas.style.userSelect;
   _canvas.style.userSelect = 'none';
   _canvas.style.setProperty('-webkit-user-select', 'none');
   // After
   _previousTouchAction = _canvas.touchAction;
   _canvas.touchAction = CanvasTouchAction.none;
   _previousUserSelect = _canvas.userSelect;
   _canvas.userSelect = false;
   ```

2. `destroy` writes the old values back. `-webkit-user-select` is `userSelect` too, so its
   `removeProperty` has no port.

   ```dart
   // Before
   _canvas.style.touchAction = _previousTouchAction;
   _canvas.style.userSelect = _previousUserSelect;
   _canvas.style.removeProperty('-webkit-user-select');
   // After
   _canvas
     ..touchAction = _previousTouchAction
     ..userSelect = _previousUserSelect;
   ```

3. The specs read the members: the upstream `toBe('none')` is `CanvasTouchAction.none` and `false`, and the
   upstream `toBe('')` is the defaults `CanvasTouchAction.auto` and `true`.

## Rejected

- A string `touchAction`: the host has two behaviors, so a string carries values that do nothing.

## Consequences

- The seam H8 keeps its state `connects`; its host side is the enum.
- An app that sets `touchAction` itself before the plugin starts gets its value back at `destroy`, as upstream.

## Tests

`test/specs/gestures_test.dart`, `test/port/gestures_test.dart`.
