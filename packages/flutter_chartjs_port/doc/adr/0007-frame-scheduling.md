# Chart.js ADR 0007: Frame scheduling

- Status: accepted (2026-10-18)
- Superseded by: [Chart.js ADR 0016](0016-frame-scheduling.md) (2026-10-21)
- Date: 2026-10-17

## Context

`helpers.extras.ts` has nine exports. Three of them are scheduling helpers:
- `requestAnimFrame` (`:14-21`) is `window.requestAnimationFrame` in a browser. Without a
  `window`, it calls the callback at once.
- `throttled` (`:27-45`) calls `fn` at most once in each animation frame, with the latest
  arguments.
- `debounce` (`:50-61`) calls `fn` after `delay` ms through `setTimeout`. With a `delay` of 0, it
  calls `fn` at once. The debounced function returns `delay`.

Upstream schedules work from these sites:
- `core.animator.js:44` runs the animation loop on `requestAnimFrame`. The loop is a one-shot
  callback that registers itself again while `_running` is true (`:38-52`). One module-level
  animator (`:214`) updates all charts with one `Date.now()` value in each frame (`:57-107`).
- `core.controller.js:173` wraps `update` in `debounce` with `options.resizeDelay`. `_resize`
  tests the return value at `:297`.
- `platform.dom.js:197` and `:242` throttle resize events and input events. `addEventListener`
  keeps one proxy for each event type (`:331-343`). For an input event type, that proxy is a
  throttled function (`:240-253`).
- `platform.dom.js:129-159` watches attach and detach with a `MutationObserver`. The DOM delivers
  the records of one task together, at the next microtask checkpoint. The callback acts only on a
  net change.

Phase 2 ports `helpers.extras`. The animation ADR has gate 5. Thus
[porting-flow.md](../porting-flow.md) §2.9 takes the scheduling part of the animation decision
first, with gate 2. This ADR is that part. It also decides the frame source of the animator,
because that source is a scheduling decision. `test/specs` has no spec for `helpers.extras`.

`debounce` gives `fn` its arguments in two forms. With a delay, `setTimeout(fn, delay, args)`
passes the argument array as one argument (`:55`). Without a delay, `fn.apply(this, args)`
spreads the array (`:57`). Thus `chart.update` gets `['resize']` after a delayed resize. It gets
`'resize'` after an immediate resize. The mode is `'attach'` when the chart had no width
(`core.controller.js:283`), for example after `detached()` ran `_resize(0, 0)` (`:1039`). A Node.js
run of the upstream function confirmed both forms. Three consumers see the difference:
- `controller.radar.js:62` tests `mode !== 'resize'`. After a delayed resize, the radar controller
  resolves its line options again.
- The plugin hooks `beforeUpdate`, `afterUpdate`, `beforeDatasetsUpdate`, `afterDatasetsUpdate`,
  `beforeDatasetUpdate` and `afterDatasetUpdate` get `mode: ['resize']`
  (`core.controller.js:490`, `:524`, `:649`, `:661`, `:671`).
- The scriptable and animation option contexts of datasets and data elements get
  `context.mode` (`core.datasetController.js:780`).

The transition keys do not change, because `` `transitions.${['resize']}` `` is
`transitions.resize`. No upstream spec or fixture sets `resizeDelay`. No other comparison with
`'resize'` occurs in `src`.

`destroy()` (`core.controller.js:937-955`) does not clear the debounce timeout. The `:173`
callback has no guard for a destroyed chart. The two throttled paths have a guard.
`core.controller.js:1016` tests `this.canvas`. `platform.dom.js:246` tests `chart.ctx !== null`.

Flutter 3.44.9 provides these parts. A line reference without a file name is in
`packages/flutter/lib/src/scheduler/binding.dart`.
- `scheduleFrameCallback` (`:608-622`) registers a one-shot transient callback. It also schedules
  a frame. It returns the callback id. The ids start at 1. `cancelFrameCallbackWithId` (`:631`)
  removes a callback.
- `handleBeginFrame` (`:1226-1274`) runs the callbacks of one frame in registration order
  (`:1256-1272`). It takes a fresh map before it runs them. Thus a callback that a callback
  registers runs in the next frame.
- Transient callbacks run before the build, layout and paint of their frame
  (`rendering/binding.dart:592-636`, `widgets/binding.dart:1571`). Post-frame callbacks run at the
  end of the same frame (`:1349-1351`).
- Flutter drains the microtasks once, after all transient callbacks of a frame
  (`rendering/binding.dart:601-604`). A browser runs a microtask checkpoint after each
  `requestAnimationFrame` callback.
- `scheduleFrame` (`:946-959`) does nothing while `framesEnabled` is false. That is the case while
  the app is hidden, paused or detached (`:419-427`). `scheduleForcedFrame` (`:981-994`) and
  `scheduleWarmUpFrame` (`:1037`) ignore that state. A metrics change calls `scheduleForcedFrame`
  (`rendering/binding.dart:404-412`).
- A `Ticker` is `scheduleFrameCallback` plus a new registration in each frame
  (`ticker.dart:271-303`). A `TickerProvider` in a `State` adds `TickerMode` muting, `forceFrames`
  and the assert "was disposed with an active Ticker" (`widgets/ticker_provider.dart:317-390`). A
  `RenderObjectWidget` can also read `TickerMode.valuesOf` in `createRenderObject` and
  `updateRenderObject` (`widgets/ticker_provider.dart:139-143`).
- `GestureBinding` sends each pointer event at once (`gestures/binding.dart:300-343`). It does not
  coalesce the events of a frame. Resampling is off by default (`gestures/binding.dart:600`).
- A parent can call `layout` on a child two times in one frame, with different constraints. A change of the
  device pixel ratio (DPR) reaches a render object through `MediaQuery` in the build, not through
  layout. A `setState` call during layout throws "Build scheduled during frame."
  (`widgets/binding.dart:1436`).
- `markNeedsPaint` asserts that no paint is in progress (`rendering/object.dart:3328`).
- `dart:async` `Timer` treats a negative duration as zero (`timer.dart:13`). Flutter, flutter_test
  and the Dart SDK have no public debounce or throttle. Flutter widgets cancel their timers in
  `dispose`, for example `widgets/raw_tooltip.dart:851` and `widgets/scrollbar.dart:2218`.

Probes of this decision (Flutter 3.44.9, 2026-10-17 and 2026-10-18) gave these results:
- A frame callback runs on the next `tester.pump()`, not at once.
- Callbacks run in registration order. A callback that a callback schedules runs one frame later.
- Three `throttled` calls in one frame give one call with the last arguments.
- A parent called `layout` on the chart two times in one frame. A port-shaped `throttled` gave one resize
  call with the last size. A size change and a DPR change in one frame also gave one call. A plain
  frame callback gave two calls in both cases.
- `debounce` with a delay of 0 calls at once. With a delay of 50.7 ms, it calls once, after 50 ms
  of fake time, with the last arguments.
- A pending `Timer` at the end of a test fails the test with "A Timer is still pending even after
  the widget tree was disposed."
- After the test body, flutter_test runs the warm-up frame of `runApp` and one `pump`
  (`flutter_test/lib/src/binding.dart:1959-1962`). These two frames run the pending one-shot
  callbacks. Then a callback that is still registered fails the test with "An animation is still
  running even after the widget tree was disposed." (`flutter_test/lib/src/binding.dart:1982-1986`). A chain of two callbacks
  passed. A chain of three callbacks failed.
- In a plain `test()`, `TestWidgetsFlutterBinding.ensureInitialized()` gives a binding but runs
  no frames. A callback from that test runs in the next `testWidgets`, before its body.
- `setUp` runs outside the `FakeAsync` zone of `testWidgets`. A `Timer` from `setUp` is a real
  timer. `tester.pump` does not fire it. The pending-timer check does not see it.
- `pumpAndSettle` pumps while a frame is scheduled. It does not wait for a `Timer`. A debounce
  `Timer` that a frame callback created was still pending when `pumpAndSettle` returned.

## Decision

1. **`requestAnimFrame`.** `requestAnimFrame(callback)` calls
   `SchedulerBinding.instance.scheduleFrameCallback`. It returns the callback id. The callback
   ignores the frame time stamp, because the upstream callbacks take no argument
   (`core.animator.js:44`, `helpers.extras.ts:39`).
   - Chart code runs on the root isolate after `runApp` or
     `WidgetsFlutterBinding.ensureInitialized()`. Without a binding, the call throws: a
     `FlutterError` in debug mode and a null-check error in release mode
     (`foundation/binding.dart:316`, `:403`).
   - One `DIVERGES(chartjs)` hunk replaces `:14-21`. Its `differences.md` row is
     `platform-request-anim-frame`. The row records two observable differences. A direct call of
     the exported helper without a binding throws, where upstream calls the callback at once. The
     microtasks of a frame run after all its frame callbacks, not after each callback.
   - At the call sites, `requestAnimFrame.call(window, …)` becomes a plain call. A Dart function
     has no receiver to bind.
2. **`throttled`.** `throttled` is a line-by-line port on `requestAnimFrame`.
   - The variadic `TArgs` becomes one type parameter `T`. A caller with more than one argument
     passes a record or a Flutter value type, for example `Size?`.
   - The port drops the `thisArg` parameter. A Dart closure takes `this` from the code around
     it.
   - Each throttled function coalesces its own calls to one call in each frame. Separate throttled
     functions run in their registration order.
3. **`debounce`.** `debounce` uses a `dart:async` `Timer` for `setTimeout`. `Timer.cancel`
   replaces `clearTimeout`.
   - The branch tests the raw `delay` with the JS ToBoolean: `delay != 0 && !delay.isNaN`
     ([Chart.js ADR 0002](0002-js-numeric-semantics.md)). Thus a delay of 0.5, -5 or Infinity
     takes the delayed branch, as upstream.
   - The `Timer` duration is `Duration(milliseconds: jsToInt32(delay).toInt())`, as the HTML
     `setTimeout` converts the delay. `Timer` treats a negative duration as zero.
   - The function returns the raw `delay`, as upstream does.
   - Both branches give `fn` the latest argument value. The delayed branch does not wrap it in a
     list. This change is one `DIVERGES(chartjs)` hunk with the row
     `js-semantics-debounce-args`. The mode is `'resize'` or `'attach'`. The row names the three
     consumers of the Context section.
4. **Debounce cancel.** `debounce` returns a `Debounced<T>` object. Its `call(T)` method is the
   upstream function. Its `cancel()` method cancels the pending `Timer`. `Chart.destroy()` calls
   `_doResize.cancel()`.
   - The return type and `cancel()` are one hunk with the row `platform-debounce-cancel`. The
     call in `destroy()` is one hunk with the row `platform-destroy-cancel-resize`. The
     `core.controller` port of phase 5 adds that row.
   - Only `destroy()` cancels. A detach does not cancel, because upstream `detached()` keeps the
     pending update. A `GlobalKey` move also detaches the render object.
   - The reasons: flutter_test fails a test with a pending `Timer` after the tree unmounts.
     Flutter widgets cancel their timers in `dispose`. Upstream leaves a timer that calls
     `update()` on a destroyed chart.
5. **Call sites in `core.controller`** (phase 5). `:173` reads `options.resizeDelay || 0` with the
   ToBoolean of the raw option value. `:297` tests the returned delay with `!= 0`. This test is
   exact, because `|| 0` already changed NaN, `-0` and `undefined` to 0. A string `resizeDelay` is
   outside the type contract (`src/types/index.d.ts:1660`).
6. **Animator frame source.** `core.animator.js` stays one module-level animator on
   `requestAnimFrame`, as upstream. `:44` is a plain call and needs no `DIVERGES` hunk. The clock
   behind `Date.now()` is `jsDateNow()` ([Chart.js ADR 0002](0002-js-numeric-semantics.md)).
   - A `Ticker` loop is the same mechanism as the `requestAnimFrame` loop. One shared `Ticker`
     cannot follow the `TickerMode` of each chart.
   - One animator keeps the upstream behavior: one `Date.now()` value in each frame for all
     charts. `core.animator.tests.js:41-47` drives the animator with a host-less `{}` chart.
   - flutter_test reports a loop that outlives the tree ("An animation is still running"), as it
     does for a `Ticker`. The port loses only the debug assert of a `TickerProvider`.
   - The chart host destroys its chart in `dispose`. Thus the loop ends when the tree unmounts.
     A test that keeps a chart after its body uses `animation: false`, the `acquireChart` default.
7. **`TickerMode` muting.** The chart host follows `TickerMode`. It reads `TickerMode.valuesOf` in
   `createRenderObject` and `updateRenderObject`. It keeps the last value. When `TickerMode` turns
   off, it calls `animator.mute(chart)`. When `TickerMode` turns on, it calls
   `animator.unmute(chart)`. A rebuild with the same value calls neither method.
   - `mute` marks the chart in an `Expando`. Thus a destroyed chart leaves no entry. `_update`
     skips a muted chart, as it skips a chart that does not run. A muted chart then does not count
     in `remaining`. When all charts with animations are muted, the loop ends. Then the animator
     schedules no more frames.
   - `unmute` removes the mark. If the chart has animations (`has(chart)`), it calls `_refresh()`.
     The animations continue at the current `Date.now()`, as a muted `Ticker` lets the time pass.
     Without these two conditions, each rebuild of the host schedules one frame for nothing.
   - While a chart is muted, its `onComplete` and `onProgress` callbacks wait. A `render()` call
     on it resets `anims.start` (`core.animator.js:169`). Thus `currentStep` of the next
     `onProgress` starts again from that time.
   - A `render()` call on a muted chart with animations starts the loop again
     (`core.controller.js:688-691`). `_update` then finds no running chart. Thus the loop ends
     after one frame.
   - Two `DIVERGES` hunks in `core.animator.js` carry the muting. The row `platform-animator-mute`
     covers the `Expando` and the two methods. The row `platform-animator-skip-muted` covers the
     test in `_update`. The `core.animator` port of phase 5 adds both rows.
   - The reason: a covered route with `maintainState` stays in the tree after its transition, with
     `TickerMode` off (`widgets/overlay.dart:900-908`, `:420-421`). The overlay does not paint it
     (`widgets/overlay.dart:1426-1440`). Without the mute, a chart there continues its animation. With
     `animation.loop: true`, the animation never ends (`core.animation.js:85`). Each animator frame
     is a full app frame (`scheduler/binding.dart:613-615`, `rendering/binding.dart:646-649`). Thus
     the app never goes idle.
   - A probe of 2026-10-18 (Flutter 3.44.9) ran a port of the upstream loop with this mute. A
     `LeafRenderObjectWidget` host read `TickerMode`, and a `Navigator` covered it. During the
     300 ms transition, the chart animated. After it, `updateRenderObject` ran one time, the
     chart drew no more frames, and no frame was scheduled. Without the mute, frames continued.
     After the pop, the animation continued at the current time. A visible chart animated while
     the covered chart stayed muted. A `render()` call on the muted chart ran one frame. A chart
     created under `TickerMode(enabled: false)` started muted.
8. **No frame-callback cancel.** Upstream never calls `cancelAnimationFrame`. The port adds no
   cancel function for frame callbacks. A callback that is pending at `destroy()` runs one time,
   in the next frame or in a teardown frame of flutter_test.
   - `core.controller.js:1016` stays as upstream.
   - `platform.flutter.dart` makes the guard of `platform.dom.js:246` again.
   - The animator loop ends after `_stop()` removes the chart (`core.animator.js:104-106`).
   - Port-only code can call `cancelFrameCallbackWithId` only for ids that it scheduled.
9. **Platform consumers.** `platform.flutter.dart` replaces `platform.dom.js` (phase 3). The gate 3
   ADR ([porting-flow.md](../porting-flow.md) §2.7) decides the other platform parts. This ADR
   decides the scheduling parts:
   - The chart host takes its size from layout. It calls a `throttled<Size?>` resize function,
     with null for a DPR change, as `platform.dom.js:172` calls `resize()` without arguments for a
     DPR change. Thus `resize`, `onResize` and the plugin hook `resize` never run inside layout or
     build.
   - The host makes one throttled function for each `options.events` entry, keyed by the DOM
     event type. Thus a click and a mousemove in one frame both reach the chart.
   - The host defers attach and detach to one post-frame callback. That callback compares the
     attached state with the state at its last call. Thus a detach and an attach in one frame
     cancel each other, as the records of one task do upstream. A `GlobalKey` move and a
     keep-alive move give such a pair.
   - A net detach reaches that callback only after `finalizeTree` unmounted the host and disposed
     its render object (`widgets/binding.dart:1578`, `widgets/framework.dart:6872`). The host then
     destroyed its chart. Thus the callback does nothing for a destroyed chart, and `detached()`
     never runs on a live chart. The specs that keep a detached chart across a task
     (`core.controller.tests.js:1065`, `:1147`, `:1179`) skip as `n/a`, unless the gate 3 ADR gives
     the harness a detach without an unmount.
10. **Layer.** `helpers.extras.dart` imports `package:flutter/scheduler.dart` and `dart:async`.
   Thus it is not a pure layer ([porting-flow.md](../porting-flow.md) §3). Its tests use
   `flutter_test`. Each test file has `@TestOn('vm')` directly below its header lines. The files go
   in `test/port/helpers/`.
   - A test that reaches `requestAnimFrame` or `throttled` is a `testWidgets` test.
   - The six other exports (`fontString`, `_toLeftRightCenter`, `_alignStartEnd`, `_textX`,
     `_getStartAndCountOfVisiblePoints`, `_scaleRangesChanged`) then run on the VM only. The port
     accepts this cost. It keeps the upstream file split (AGENTS.md rule 2,
     [Chart.js ADR 0004](0004-dart-file-naming.md)). Tool 3 still examines the file.
11. **Pinning tests.** Phase 2 pins the three `helpers.extras` rows at the function level, with
    `testWidgets` and `tester.pump`. The `debounce` test uses `T = Object?` and the delays 50, 0,
    0.5 and -5. It also pins `cancel()`. Phase 5 adds chart-level tests:
    - `js-semantics-debounce-args`: after a delayed resize, `beforeUpdate` and `afterUpdate` get
      the mode `'resize'`.
    - `platform-destroy-cancel-resize`: with `resizeDelay: 50`, a resize and then `destroy()` give
      no `update` after `tester.pump(const Duration(milliseconds: 60))`. The test ends with no
      pending `Timer`.
    - `platform-animator-mute` and `platform-animator-skip-muted`: a chart with
      `animation.loop: true` under `TickerMode(enabled: false)` schedules no frame. After
      `TickerMode` turns on, the animation continues.
12. **Scope.** The animation ADR (gate 5) decides these items:
    - chart animations under reduced motion, through `MediaQuery.maybeDisableAnimationsOf`
    - the `'themeFrame'` and `'default'` modes of a theme change ([theming.md](../theming.md)
      §3.7, §11)
    - the tests of `core.animator.tests.js` and the 400 ms hover transitions

## Alternatives considered

- **Keep the array argument of the delayed `debounce` branch.** Rejected. `update` then gets a
  `List` where it expects a mode. The Dart string of `['resize']` is `[resize]`, not `resize`.
  Thus the transition keys also change. No upstream spec pins the upstream form.
- **A `Ticker` for `requestAnimFrame`.** Rejected. A `Ticker` calls its callback on every frame
  until something stops it. `requestAnimFrame` asks for one frame only. `scheduleFrameCallback` has
  the same one-frame semantics.
- **A synchronous call without a binding**, as upstream does without a `window`. Rejected. The
  upstream callers pass `window` as the receiver (`core.animator.js:44`, `helpers.extras.ts:39`).
  Without a `window`, they throw a `ReferenceError`. Thus only a direct call of the exported helper
  reaches the fallback. The port has no such caller.
- **One `Ticker` for each chart host.** Rejected. The host can mute it through
  `TickerMode.valuesOf` in `createRenderObject` and `updateRenderObject`, as it reads the DPR. But
  it splits `_update` into one call for each chart, with structural `DIVERGES` hunks in `_refresh`
  and `_update`. The charts then also read `Date.now()` one time for each chart in a frame.
- **One `Ticker` for the module-level animator.** Rejected. One shared `Ticker` cannot follow the
  `TickerMode` of each chart.
- **No muting, as upstream.** Rejected. A looping chart under a covered route keeps the app in a
  new frame at each vsync. It adds a `DIVERGES` hunk and gives no behavior that the port needs.
- **`AnimationController` for `core.animation`.** Rejected. A Chart.js animation is one property,
  with a delay, a loop and a new target during the animation (`core.animation.js:36-99`). An
  `AnimationController` is one bounded value.
- **No port of the three helpers.** Rejected. The port then needs a `DIVERGES` hunk at
  `core.controller.js:173`, in a hot module ([porting-flow.md](../porting-flow.md) §7). The row
  `js-semantics-debounce-args` moves into `core.controller`. `helpers.extras` stays `partial`. The
  call sites then contain the same `Timer` code.
- **A `canvas` guard in the `:173` callback**, as `:1016` has. Rejected. It is one hunk. But the
  `Timer` stays pending. Thus flutter_test fails the test.
- **The upstream behavior with a note.** Rejected for the same reason.
- **`RestartableTimer` of `package:async`.** Rejected. It is `cancel` plus a new `Timer`. It also
  adds a dependency.
- **Process events in paint.** Rejected. During paint, `markNeedsPaint` fails its assert.
- **A post-frame callback for resize events.** Rejected. A post-frame callback from layout runs at
  the end of the same frame. The pixels then arrive in the next frame, as with `throttled`. But
  the callback runs before the animator callback of the next frame. Upstream runs the throttled
  resize after it. During an animation, upstream holds the resize in `_resizeBeforeDraw`
  (`core.controller.js:273`). The next `draw()` applies it (`:700-704`). A post-frame callback
  applies it one frame earlier than upstream. For input events, a post-frame callback is one frame
  late. It also needs an explicit `scheduleFrame`.
- **`SchedulerBinding.scheduleTask`.** Rejected. It runs one task by priority in each turn of the
  event loop, through a zero-duration `Timer` (`scheduler/binding.dart:466-510`). It has no delay, no frame alignment
  and no cancel handle.
- **`rescheduling: true` for the animator.** Rejected. The flag changes only a debug stack. In
  debug mode, with the flag, `scheduleFrameCallback` throws when no transient callback runs
  (`scheduler/binding.dart:111-130`). The animator also starts outside a frame.

## Consequences

- Each throttled function coalesces its calls to one call in each frame, as in a browser. Events
  of different types in one frame all run, in registration order.
- Frame callbacks run before the build, layout and paint of their frame. Thus a callback that
  marks the chart host for paint gets its pixels in the same frame. A callback that layout or
  paint of frame N registers runs in frame N+1.
- The microtasks of a frame run after all its transient callbacks. Thus the promise chain of
  `core.animations.js:55-59` finishes after a throttled callback of the same frame. In a browser,
  it finishes before that callback.
- While the app is hidden, `scheduleFrame` schedules no frame. The callbacks wait. On native
  platforms, forced frames and warm-up frames still run them. On the web, the frames wait for
  `window.requestAnimationFrame`. Browsers suspend it in a hidden tab.
- An exception in a frame callback goes to `FlutterError.reportError` (`scheduler/binding.dart:1429-1452`). The other
  callbacks of the frame still run. An exception in the debounce `Timer` goes to the
  uncaught-error handler of the zone that created the `Timer`. In the root zone on native
  platforms, that handler is `PlatformDispatcher.onError`. Upstream sends both to
  `window.onerror`.
- Tests:
  - A ported `beforeEach` that acquires a chart runs at the start of each `testWidgets` body, not
    in `setUp`.
  - The harness helpers pump ([porting-flow.md](../porting-flow.md) §3).
  - A test with `resizeDelay` pumps past the delay. `pumpAndSettle` stops when no frame is
    scheduled. Thus a debounce `Timer` that its last frame creates stays pending.
- The `helpers.extras` port of phase 2 adds the rows `platform-request-anim-frame`,
  `js-semantics-debounce-args` and `platform-debounce-cancel`. If no earlier hunk exists, these
  rows create `differences.md` ([porting-flow.md](../porting-flow.md) §4). The `core.controller`
  port of phase 5 adds the row `platform-destroy-cancel-resize`.
- `core.animator.js` needs no `DIVERGES` hunk for its frame source. It has two small hunks for the
  muting.
