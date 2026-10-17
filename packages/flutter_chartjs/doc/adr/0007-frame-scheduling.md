# Chart.js ADR 0007: Frame scheduling

- Status: proposed
- Date: 2026-10-17

## Context

`helpers.extras.ts` defines three scheduling helpers:
- `requestAnimFrame` (`:14-21`) is `window.requestAnimationFrame` in a browser. Without a
  `window`, it calls the callback at once.
- `throttled` (`:27-45`) calls `fn` at most once in each animation frame, with the latest
  arguments.
- `debounce` (`:50-61`) calls `fn` after `delay` ms through `setTimeout`. With a `delay` of 0, it
  calls `fn` at once. It returns `delay`.

Three upstream modules call them:
- `core.animator.js:44` runs the animation loop on `requestAnimFrame`.
- `core.controller.js:173` wraps `update` in `debounce` with `options.resizeDelay`. `_resize`
  tests the return value at `:297`.
- `platform.dom.js:197` and `:242` throttle resize events and input events.

Phase 2 ports `helpers.extras`. The animation ADR has gate 5. Thus
[porting-flow.md](../porting-flow.md) §2.9 takes the scheduling part of the animation decision
first, with gate 2. This ADR is that part. `test/specs` has no spec for `helpers.extras`.

`debounce` gives `fn` its arguments in two forms. With a delay, `setTimeout(fn, delay, args)`
passes the argument array as one argument (`:55`). Without a delay, `fn.apply(this, args)`
spreads the array (`:57`). Thus `chart.update` gets `['resize']` after a delayed resize. It gets
`'resize'` after an immediate resize. A Node.js run of the upstream function confirmed both forms.
Two consumers see the difference:
- `controller.radar.js:62` tests `mode !== 'resize'`. After a delayed resize, the radar controller
  resolves its line options again.
- Plugin hooks get `mode: ['resize']`.

The transition keys do not change, because `` `transitions.${['resize']}` `` is
`transitions.resize`. No upstream spec or fixture sets `resizeDelay`.

Flutter 3.44.9 schedules frames through `SchedulerBinding`
(`packages/flutter/lib/src/scheduler/binding.dart`):
- `scheduleFrameCallback` (`:608-622`) registers a transient callback. It also schedules a frame.
  It returns the callback id. The ids start at 1.
- `handleBeginFrame` (`:1256-1272`) runs the callbacks of one frame in registration order. It
  takes a fresh map before it runs them. Thus a callback that a callback registers runs in the
  next frame.
- `scheduleFrame` (`:946-959`) does nothing while `framesEnabled` is false. That is the case while
  the app is hidden, paused or detached (`:419-427`). The callbacks then wait for the next frame.

A `flutter_test` probe of this decision (Flutter 3.44.9, 2026-10-17) gave these results:
- A callback runs on the next `tester.pump()`, not at once.
- Callbacks run in registration order. A callback that a callback schedules runs one frame later.
- Three `throttled` calls in one frame give one call with the last arguments.
- `debounce` with a delay of 0 calls at once. With a delay of 50.7 ms, it calls once, after 50 ms
  of fake time, with the last arguments.
- A pending `Timer` at the end of a test fails the test with "A Timer is still pending even after
  the widget tree was disposed." A pending frame callback does not fail it.

## Decision

1. **`requestAnimFrame`.** `requestAnimFrame(callback)` calls
   `SchedulerBinding.instance.scheduleFrameCallback`. It returns the callback id. The callback
   ignores the frame time stamp, because the upstream callbacks take no argument
   (`core.animator.js:44`, `helpers.extras.ts:39`).
   - The `window` test of `:15-19` has no Flutter counterpart. Every Flutter app has a binding. A
     `flutter_test` test gets one from `testWidgets` or from
     `TestWidgetsFlutterBinding.ensureInitialized()`.
   - One `DIVERGES(chartjs)` hunk replaces `:14-21`. Its `differences.md` row is
     `platform-request-anim-frame`.
   - At the call sites, `requestAnimFrame.call(window, …)` becomes a plain call. A Dart function
     has no receiver to bind.
2. **`throttled`.** `throttled` is a line-by-line port on `requestAnimFrame`.
   - The variadic `TArgs` becomes one type parameter `T`. A caller with more than one argument
     passes a record, the Dart form of a TypeScript tuple.
   - The port drops the `thisArg` parameter. A Dart closure takes `this` from the code around
     it.
3. **`debounce`.** `debounce` uses a `dart:async` `Timer` for `setTimeout`. `Timer.cancel`
   replaces `clearTimeout`.
   - The delay converts as the HTML `setTimeout` converts it: ToInt32 (`jsToInt32`), then 0 for a
     negative value.
   - The function returns `delay`, as upstream does.
   - Both branches give `fn` the latest argument value. The delayed branch does not wrap it in a
     list. This change is one `DIVERGES(chartjs)` hunk with the row
     `js-semantics-debounce-args`. Its pinning test makes sure that a delayed resize updates the
     chart with the mode `'resize'`.
4. **Layer.** `helpers.extras.dart` imports `package:flutter/scheduler.dart` and `dart:async`.
   Thus it is not a pure layer ([porting-flow.md](../porting-flow.md) §3). Its tests use
   `flutter_test`. Each test file has `@TestOn('vm')` directly below its header lines. The files go
   in `test/port/helpers/`.
5. **No cancel.** Upstream never calls `cancelAnimationFrame`. The port adds no cancel function.
6. **Scope.** This ADR does not decide the animation design. `core.animator.js:44` calls
   `requestAnimFrame`. The animation ADR (gate 5) decides whether a `Ticker` replaces that call.
   It also decides these items:
   - the clock behind `Date.now()` (`core.animator.js:57`, `:169`, `:201`,
     `core.animation.js:37`, `:70`, `core.animations.js:73`)
   - the chart host of phase 3, `TickerMode` and reduced motion
   - the tests of `core.animator.tests.js` and the 400 ms hover transitions

## Alternatives considered

- **Keep the array argument of the delayed `debounce` branch.** Rejected. `update` then gets a
  `List` where it expects a mode. The Dart string of `['resize']` is `[resize]`, not `resize`.
  Thus the transition keys also change. No upstream spec pins the upstream form.
- **A `Ticker` for `requestAnimFrame`.** Not chosen for `helpers.extras`. A `Ticker` calls its
  callback on every frame until something stops it. `requestAnimFrame` asks for one frame only.
  `scheduleFrameCallback` has the same one-frame semantics.
- **A synchronous call without a binding**, as upstream does without a `window`. Rejected. Every
  Flutter app has a binding. A `flutter_test` test can get one. The fallback has no caller in the
  port.

## Consequences

- Throttled events and resizes coalesce to one call in each frame, as in a browser.
- Frame callbacks run before the build, layout and paint of their frame. Thus a callback that
  marks the chart host for paint gets its pixels in the same frame.
- While the app is hidden, no frame runs. The callbacks wait. A browser also pauses
  `requestAnimationFrame` callbacks in a hidden tab.
- A test must end with no pending `debounce` timer. A test with `resizeDelay` must pump past the
  delay.
- The two `DIVERGES` rows come with the `helpers.extras` port in phase 2. If no earlier hunk exists,
  they create `differences.md` ([porting-flow.md](../porting-flow.md) §4).
- `platform.flutter.dart` (phase 3) calls `throttled` with records for resize events.
