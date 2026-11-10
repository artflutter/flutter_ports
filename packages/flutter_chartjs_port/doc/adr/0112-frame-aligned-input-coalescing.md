# Chart.js ADR 0112: Frame-aligned coalescing of continuous input in the chart host

- Status: proposed (2026-11-10). The maintainer decides after the counts of the input probe on
  the Pixel 8a and the iPhone 17 Pro (section Measurement).
- Date: 2026-11-10
- Gate: the table of the section Measurement has the counts of both phones. The maintainer then
  accepts the decision, changes it or rejects it. An accepted form also needs the code and the
  tests of the section Tests.
- Related: [Chart.js ADR 0016](0016-frame-scheduling.md) (frame scheduling),
  [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) (§11, Open 10, Evidence E8),
  [Chart.js ADR 0091](0091-live-mouse-move.md) (the held mouse move),
  [Chart.js ADR 0108](0108-input-surface-and-exports-for-add-on-plugins.md) (§5, §6, §8, Open 4
  and Open 5), Chart.js ADR 0111 (the range-only update, proposed),
  [Zoom ADR 0003](../../../flutter_chartjs_plugin_zoom_port/doc/adr/0003-host-connection.md), the
  probe `apps/chartjs_gallery/lib/main_input_probe.dart`.
- Supersedes, in part, on acceptance: Chart.js ADR 0016 decision 1, Chart.js ADR 0037 §11 and
  Open 10, Chart.js ADR 0108 §5, §6, §8 and Open 4. The section "Superseded parts" gives each
  part.

## Context

### The stream of the host

`GestureBinding` sends each Flutter pointer event at once (Chart.js ADR 0016, Context). The host
(`RenderChartHost` of `lib/src/platform/chart_host.dart`) turns each event into DOM events at
once (Chart.js ADR 0108 §5 and §6):

- each `PointerMoveEvent` and `PointerHoverEvent` gives one `pointermove`, with `mousemove` for a
  mouse or `touchmove` for a touch;
- each `PointerScrollEvent` gives one `wheel`, with the `deltaX` and `deltaY` of that event.

The listeners of Chart.js are throttled: each event type of a chart runs at most once in each
frame, with the last event (`createProxyAndListen` of `platform.flutter.dart`, Chart.js ADR 0016
decision 9). A chart with no add-on thus does one hover pass for each event type in each frame,
whatever the count of events.

The listeners of an add-on are not throttled. chartjs-plugin-zoom runs one zoom or pan step for
each `pointermove` of a gesture and for each `wheel` (`src/gestures.ts:299-322`,
`src/handlers.ts:252-278` of the plugin). Each step is one full `chart.update`. With
`animation: false`, or the mode `'none'` of a pan, the update also draws at once.

### The cost of one step

The zoom profiles of 2026-11-10 (the zoom section of performance.md) timed one input step of a
line chart of 20,000 points at these p50 values:

| Device | Wheel step | Pan step | Pinch step |
|---|---|---|---|
| Pixel 8a | 8.04-8.08 ms | 8.33-8.36 ms | 7.31-7.56 ms |
| iPhone 17 Pro | 3.41-3.45 ms | 3.56-3.62 ms | 3.26-3.34 ms |
| Mac (M3 Max) | 3.75-3.79 ms | 3.81-3.93 ms | 3.57-3.76 ms |

The frame budget at 120 Hz is 8.33 ms. A frame with k steps costs k times one step. The host
update and draw are 92 to 99% of a step; the zoom side is at most 1.8% at 20,000 points.

### Chrome

- **rAF-aligned input.** Since Chrome 60, the continuous events `wheel`, `mousewheel`,
  `touchmove`, `pointermove` and `mousemove` wait for the next frame. Chrome dispatches them right
  before the `requestAnimationFrame` callbacks. The discrete events (`keydown`, `keyup`,
  `mousedown`, `mouseup`, `touchstart`, `touchend`) are not delayed: they "will be dispatched
  right away along with any pending events, preserving the relative ordering" (Dave Tapuska,
  "Aligning input events", Chrome for Developers blog, 2017).
- **Coalesced pointer moves.** The moves of one pointer in one frame become one `pointermove`.
  `PointerEvent.getCoalescedEvents()` (Chrome 58) gives the samples. Pointer Events Level 3 (W3C
  Recommendation, 2026-06-30): "User agents MAY delay dispatch of the pointermove event" (§4.2.4);
  "The final coordinates of such events should be used for finding the target of the event"
  (§4.2.4); the coalesced events list "MUST be chronologically sorted by timeStamp" (§10.1); "The
  order of all these dispatched events MUST match the actual order of the original events"
  (§10.1): a pending coalesced `pointermove` of a pointer goes before its `pointerdown` or
  `pointerup`.
- **Coalesced wheel events.** Blink coalesces two wheel events when they have the same modifiers,
  the same delta units and a consistent phase (`WebMouseWheelEvent::CanCoalesce`). The result has
  the sum of `delta_x`, `delta_y` and the wheel ticks, and the other fields of the newer event
  (`WebMouseWheelEvent::Coalesce`, `third_party/blink/common/input/web_mouse_wheel_event.cc`). The
  browser side also coalesces the wheel events that wait while an earlier one waits for its ack
  (`MouseWheelEventQueue::QueueEvent`, `components/input/mouse_wheel_event_queue.cc`), as the
  wheel events of a page with a blocking wheel listener do. The zoom plugin registers such a
  listener (`passive: false`, `src/handlers.ts:39-41`).
- **Two fingers.** Each finger of a pinch is its own pointer. Chrome dispatches one `pointermove`
  for each finger in each frame. Thus the zoom plugin runs two pinch steps, two updates, in each
  frame of a pinch in Chrome too. Coalescing helps only where a pointer gives more than one
  sample in one frame.

### The port against Chrome

The device check E8 of Chart.js ADR 0037 compared Chrome and the port on the Pixel 8a with the
same drag: Chrome sent 11 to 20 moves, the port 48 to 74 (Open 10). The Flutter stream on that
phone thus has 3 to 5 times the moves of the DOM stream. The zoom plugin turns each extra move
into an extra update.

A slow frame adds samples to the next frame: the samples of the touch screen keep their rate
while the frames slow down. A step of 8 ms on the Pixel then gives more than one step in the next
frame, and the frame rate falls further.

The zoom profiles did not count the events of each frame. This ADR waits for that count (section
Measurement).

### Flutter

- `GestureBinding.resamplingEnabled` (off by default) resamples the touch pointers at the frame
  time: one move for each pointer in each sample interval, at a position that it interpolates,
  with a default sampling offset of -38 ms. It applies to `PointerDeviceKind.touch` only
  (`_Resampler.addOrDispatch`, `gestures/binding.dart:98-100`), to every gesture of the app, and
  not to the wheel.
- The host claims a prevented `wheel` through `GestureBinding.instance.pointerSignalResolver`
  during the dispatch of the `PointerScrollEvent` (Chart.js ADR 0108 §8). `GestureBinding`
  resolves the signal in its own `handleEvent`, the last entry of the hit path
  (`gestures/binding.dart:538-544`). A dispatch that waits for the frame has no result at that
  time.
- `SchedulerBinding` runs the transient frame callbacks in the order of their registration. A
  callback that a transient callback registers runs one frame later (Chart.js ADR 0016, probes).

## Options

- **A. Keep the stream.** One dispatch for each Flutter event. No risk. The cost of a frame grows
  with the samples in the frame.
- **B. `GestureBinding.resamplingEnabled` in the app.** No port change. Touch only, about 38 ms
  more latency, interpolated positions for every gesture of the app, no wheel and no mouse. An
  app can already do it. The probe can measure it.
- **C. Coalescing in the host, as Chrome does (proposed).** One dispatch for each pointer in each
  frame, before the animation frame callbacks, with the discrete events in order.
- **D. A throttle in the zoom port.** Each listener of `gestures.ts` and `handlers.ts` throttled
  to the frame. A `DIVERGES(zoom)` row for upstream lines that are already right in Chrome, and
  each add-on would need its own. Rejected.
- **E. Option C as an opt-in of `ChartView`** (`coalesceInput: true`). The default stream of
  Chart.js ADR 0108 stays. An app that knows the option gets the gain. Weaker than C: the stream
  that Chart.js add-ons are written for is the coalesced stream of the browsers. The present
  stream is a Flutter artifact (Chart.js ADR 0037 Open 10).
- **F. Coalescing in `platform.flutter.dart` only.** The Chart.js listeners are throttled
  already. It does not reach add-ons. Rejected.
- **G. One step for both fingers of a pinch.** No browser does it. The plugin reads both pointers
  in each `pointermove`. It changes the stream beyond Chrome. Rejected.

## Decision (proposed)

Option C. The host aligns the continuous events to the frame and coalesces them, as Chrome does.

### 1. The continuous events

- `pointermove` of a pointer, with its compatibility `mousemove` (a mouse) or its `touchmove`
  (a touch): the events of a `PointerMoveEvent` or a `PointerHoverEvent`.
- `wheel` of a device: the event of a `PointerScrollEvent`.

All other events stay discrete and go out at once: `pointerdown`, `pointerup`, `pointercancel`,
the boundary events (`pointerover`, `pointerout`, `pointerenter`, `pointerleave` and the mouse
names), `click`, the compatibility events of a tap, `touchstart`, `touchend`, `touchcancel`, the
key events of the document bridge and of `ChartKeyboard`, and `resize`, `attach` and `detach`.

A dispatch by code is not input: `canvas.dispatchEvent` of user code, a spec or the harness
(`triggerMouseEvent`) stays synchronous and does not touch the queue, as a script
`dispatchEvent` in a browser.

### 2. The queue

- The isolate has one input queue, on the document (`CanvasDocument.instance`, Chart.js ADR 0108
  §6): one page, one input queue. Thus the order of the events of two charts stays the order of
  arrival.
- The queue holds at most one entry for each pointer and one wheel entry for each device. A new
  sample of a pointer with an entry joins that entry. The entry keeps its place in the queue, the
  place of its first sample.
- A wheel sample joins the wheel entry of its device only when its modifiers and `deltaMode` are
  those of the entry (`CanCoalesce` of Blink). Otherwise the host flushes the queue first, and the
  sample makes a new entry.
- The host still reads each Flutter event at its arrival for its own state: the touch sequence,
  the slop, the pan begin, the tap candidate, the claims of the gesture arena (Chart.js ADR 0108
  §8), the buttons of a mouse and the click rule. Only the dispatch to the listeners waits.

### 3. The coalesced event

- The fields are those of the last sample: the offsets, the client point, `buttons`, the
  modifiers, `touches`. `cancelable` follows the rules of Chart.js ADR 0108 §5 for the last
  sample.
- `wheel`: `deltaX` and `deltaY` are the sums of the samples.
- The target is the target of the last sample, as Pointer Events 3 §4.2.4 finds the target from
  the final coordinates: the canvas inside the box; the document for a pressed mouse outside the
  box (Chart.js ADR 0108 §6); no event for a hover that left the box. A mouse that crosses the
  edge of the canvas twice between two frames thus gives only the boundary events of its last
  position, as in Chrome (Chart.js ADR 0037 Open 10).
- For a touch sequence, the flush gives the `pointermove` of each touch pointer, in the order of
  the queue, then one `touchmove` with the `touches` of the last positions. Chrome dispatches the
  pointer events of a touch before its touch event (Chart.js ADR 0037 Evidence E8: `pointerup`,
  `pointerout`, `pointerleave`, then `touchend`). Whether Chrome sends one `touchmove` for both
  fingers of a frame is Open 4.
- `NativeEvent.getCoalescedEvents()` (new, the DOM name) gives the samples of a coalesced
  `pointermove` in time order, as `NativeEvent`s; a list of one for a single sample; an empty list
  for every other event (Pointer Events 3 §10.1). The host builds the list at the first read.

### 4. The flush

- **At the frame.** The first entry of a frame registers one transient frame callback
  (`SchedulerBinding.scheduleFrameCallback`), the animation frame slot of the port (Chart.js ADR
  0016 decision 1). The callback dispatches the entries in queue order.
- **Before a discrete event.** Each discrete event of the host, the document or `ChartKeyboard`
  flushes the queue first. The order of the events stays the order of the Flutter events, as
  Chrome dispatches the pending continuous events with a discrete event.
- **At a detach, a dispose and a canvas swap** of a host, the host flushes its entries before its
  own boundary events. No entry is dropped.
- **Without frames.** While `SchedulerBinding.instance.framesEnabled` is false (a hidden or
  paused app), the host does not queue: a continuous event goes out at once.
- **Animation frames requested in the flush.** A `requestAnimFrame` call during the flush (the
  throttle of a Chart.js listener, the animator) runs in the same frame, after the flush, in the
  order of the calls. In HTML, the animation frame callbacks of a frame run after the rAF-aligned
  input of that frame. Without this rule, each throttled Chart.js listener would run one frame
  later than today and than in Chrome. The row `platform-request-anim-frame` of `differences.md`
  gets this rule.
- **The order with earlier callbacks.** A transient callback that was registered before the
  first entry of the frame (an animator tick of the last frame) runs before the flush. In Chrome,
  the input of a frame runs before all its animation frame callbacks. The listeners of the flush
  then see the elements after the tick of that frame (Risks).

### 5. The wheel and the pointer signal

The claim of a prevented wheel must happen during the dispatch of the `PointerScrollEvent`. Thus:

- **The first wheel event of a sequence goes out at once.** Its dispatch decides the claim, as
  today. A sequence starts at a wheel event when the host saw no wheel event of that device since
  the start of the last frame.
- **Each later event of the sequence joins the wheel entry.** It registers with the pointer
  signal resolver at its arrival when the first event of the sequence was prevented. This is the
  latching of Chrome, where the later events of a scroll sequence follow the first (Chart.js ADR
  0108 Open 4).
- At the flush, the coalesced `wheel` goes out once, with the summed deltas. Its own result
  changes no claim: the claims of its samples are done.
- A wheel burst thus gives at most two dispatches in its first frame and one in each later frame.

### 6. What the zoom plugin sees

- A pan: one `pointermove`, one pan step and one update in each frame.
- A pinch: one `pointermove` for each finger in each frame: two steps and two updates, as in
  Chrome.
- A wheel burst: one zoom step for each frame of the burst, plus the first event. The step reads
  `sign(deltaY) * min(24, |deltaY|)` of the sum (`MAX_DELTA`, `src/handlers.ts:250`). Samples of
  24 px or more zoom by `speed` at most once in each frame: a burst of k such samples in one frame
  zooms by `1 + speed` (in) once, not k times. Samples below 24 px sum and zoom by about the same
  amount as before, to first order. Samples of both signs cancel out. Chrome gives the same steps.
- `onZoomComplete` runs once for each dispatched `wheel`, 250 ms later
  (`src/handlers.ts:277`, `:280-289`): fewer calls, as in Chrome.
- The specs and the fixtures of the zoom port dispatch by code: no change.

### 7. The switch for tests

An internal `@visibleForTesting` switch `debugCoalesceHostInput` (default true) gives back the
stream of one dispatch for each Flutter event. The data of `chart_host_input_test.dart` keeps the
model of separate DOM events (Chart.js ADR 0037 §11) and runs with the switch off. A test that
sends several events with no frame between them and reads the result at once also sets it off,
or pumps a frame.

## Risks

- **Latency.** A continuous event waits up to one frame (8.3 ms at 120 Hz, 16.7 ms at 60 Hz)
  before a listener sees it. Chrome has the same wait. The throttled Chart.js listeners keep
  their frame (section 4).
- **The order with the animator.** In a frame with a running animation, a listener in the flush
  runs after the animator tick of that frame when the tick was registered first. The hover search
  of Chart.js is throttled and runs after the tick today too. A zoom step reads the scale ranges,
  which do not animate.
- **The wheel latching.** When the first wheel of a sequence is prevented and a later one is not
  (the app changes the zoom options, or the modifier key changes inside one sequence), the later
  samples still block the scroll of an ancestor. A change of the modifiers makes a new entry, but
  the claim of the sequence stays. The reverse case lets an ancestor scroll for a wheel that a
  listener then prevents.
- **The held mouse move of Chart.js ADR 0091.** It holds the throttled chart `mousemove` and does
  not see the host queue. No change is expected; its tests run with the switch on.
- **Tests.** Many real-input tests send several events and then pump once. Their results can
  change where they read the state before a pump. The zoom tests of real input
  (`handlers_test.dart`, `gestures_test.dart`, `index_test.dart`), `chart_host_test.dart`,
  `chart_view_live_mouse_test.dart`, `chart_keyboard_test.dart`, the gallery tests
  `chart_types_test.dart` and `zoom_page_test.dart` need a review.
- **The touch-move fields of Open 12 of Chart.js ADR 0037** (a resting finger with a change of
  pressure) coalesce like any move.
- **Trackpads.** `PointerPanZoomUpdateEvent` still has no DOM mapping (Chart.js ADR 0108 Open 5).
  A later mapping to `wheel` would join the wheel entry.

## Tests

On acceptance:

| File | Cases |
|---|---|
| `test/port/platform/chart_host_test.dart`, new group `coalescing` | 3 mouse moves in one frame give one `pointermove` and one `mousemove` at the frame, with 3 coalesced events in time order; two touch pointers give one `pointermove` each in queue order, then one `touchmove`; a down, an up and a cancel between moves flush first; a hover that leaves the box in the frame gives only the boundary events; a pressed mouse that leaves the box gives one document `pointermove` at the last point; a detach and a dispose flush; no frames, no queue; the switch off gives the old stream |
| the same file, group `coalescing wheel` | the first wheel of a sequence goes out at once and claims as before; the later events of the frame give one `wheel` with the summed deltas; a prevented first event latches the claim of the later ones; a modifier change splits the entry; a frame with no wheel ends the sequence |
| `test/port/helpers/helpers.extras_test.dart` | `requestAnimFrame` in the flush runs in the same frame, after the flush, in call order; outside the flush, in the next frame as before |
| `test/port/platform/native_event_test.dart` | `getCoalescedEvents()` is empty for every event that the host did not coalesce |
| `test/port/platform/chart_host_input_test.dart` | the data stays byte-identical with the switch off; new cases with several moves in one step pin the coalesced stream |
| zoom port `test/port/handlers_test.dart` | three wheel events of -100 in one frame: the first event zooms at once, the two later ones zoom once together by `1 + speed`; two `onZoomComplete` calls |
| zoom port `test/port/gestures_test.dart` | a pinch with four moves of each finger in one frame gives two updates in that frame; a pan with four moves gives one |
| `apps/chartjs_gallery/test/input_probe_test.dart` | the probe still counts the Flutter events; the updates of a frame are at most the pointers that moved |
| unchanged, green | the specs, the fixtures, `test:fixtures:zoom` (synthetic dispatch), the observation digests |

## Measurement

### Method

The probe `apps/chartjs_gallery/lib/main_input_probe.dart` shows one `ChartView.raw` line chart
of 20,000 points on a linear x axis, with the zoom plugin: the wheel and the pinch zoom, and the
pan in the mode `'xy'`. The chart has `animation: false`, as the zoom cases of the benchmark: each
update draws at once.

- For each frame it counts the `PointerMoveEvent`s of each pointer (a global route of the pointer
  router), the `PointerScrollEvent`s, the `PointerPanZoomUpdateEvent`s, the chart updates
  (`afterUpdate` of an inline plugin) and the chart draws (`afterDraw`). A frame owns the work
  between the end of the frame before it and its own post-frame callbacks.
- Once per second with work it prints `PROBE {json}`: `frames`, `active` (the frames with input,
  a pointer down or chart work), `frameNumbers`, `pointers`, and `{mean, max, hist}` of the counts
  of the active frames for `movesPerPointer` (one value for each pointer that was down in a
  frame), `moves`, `scrolls`, `panZooms`, `updates` and `draws`. `hist` counts the values 0, 1, 2
  and 3 or more. `buildMs` and `rasterMs` are the p50 and p90 of `FrameTiming`.
- `buildMs` leaves out the input: the pointer events and their updates run in the platform task
  of the pointer packet, before the frame. The cost of the updates shows in the frame rate
  (`frames` per second), not in `buildMs`.

Steps on each phone, at its default refresh rate (both have a peak of 120 Hz):

1. Build: `flutter build apk --profile -t lib/main_input_probe.dart
   --android-skip-build-dependency-validation` for the Pixel; `flutter build ios --profile -t
   lib/main_input_probe.dart` for the iPhone, signed for the benchmark app id.
2. Start the app and wait for the first `PROBE` line (the first draw).
3. On the chart, by hand: a two-finger pinch out and in for about 3 s; lift, wait 2 s; a
   one-finger pan in circles for about 3 s; lift.
4. Read the lines: `adb logcat -v raw -s flutter:I` on the Pixel, the device console on the
   iPhone.
5. For each gesture, add the histograms of its lines and weight the means by the active frames.

The saving of option C for a gesture is about `(moves - pointer frames) / moves` of its updates,
where the pointer frames are the frame and pointer pairs with at least one move. For example, a
mean of 1.4 moves for each pointer and frame gives about 29% fewer zoom steps. At a mean of 1.0
to 1.1, option C saves under 10%, and options A or B suffice.

### Results

| Device | Gesture | Input events per frame (moves per pointer: mean / max / 0, 1, 2, 3+) | Updates per frame (mean / max / 0, 1, 2, 3+) |
|---|---|---|---|
| Pixel 8a | two-finger pinch | | |
| Pixel 8a | one-finger pan | | |
| iPhone 17 Pro | two-finger pinch | | |
| iPhone 17 Pro | one-finger pan | | |

Probe check, not a measurement (2026-11-10, Pixel 8a, vsync 120 Hz, a profile APK of the probe
of commit `4eff4b9`): `adb shell input swipe 300 800 600 800 500` injected one synthetic pointer
for 0.5 s. The two lines of the swipe gave 29 frames, each with a move, and 41 moves: 1.35 and
1.44 moves for each frame, at most 2 (2 moves in 11 frames, 1 move in 18), and the same counts of
updates and draws. 29 frames in 0.5 s is about 58 frames per second at a vsync of 120 Hz.
`buildMs` stayed at a p50 of 0.22 and 0.24 ms: the updates ran outside the frame build.

## Superseded parts

On acceptance, this ADR supersedes these parts. The rest of each ADR stays.

- Chart.js ADR 0016 decision 1: a `requestAnimFrame` call during the input flush runs in the same
  frame (section 4).
- Chart.js ADR 0037 §11: the sentences "This is the model of separate DOM events. Chrome
  coalesces the moves of one frame (Open 10). The port keeps this order. It does not sort the
  events of a frame." The host now coalesces as Chrome; the separate events stay behind the test
  switch. Open 10 is closed.
- Chart.js ADR 0108 §5: the row `deltaX`, `deltaY`, `deltaMode` (the sums of a coalesced wheel),
  and the list of fields that are not added (`getCoalescedEvents`). §6: the table "The host sends
  these events to the listeners", for the time of the dispatch of the continuous events (section
  4) and the target of a coalesced move (section 3). §8: the last paragraph, for the later events
  of a wheel sequence (section 5). Open 4: the item of scroll latching.

## Consequences

- Option C makes the stream of the port the stream of Chrome for continuous input. The cost of a
  frame of a pan is one step, and of a pinch two steps, whatever the sample rate of the screen.
- With Chart.js ADR 0111 (the range-only update), the two decisions multiply: fewer steps in each
  frame, and less work in each step.
- The host grows by the queue, the flush and the latching of the wheel. A chart with no add-on
  pays one queue entry for each move; its throttled listeners already ran once per frame.
- `NativeEvent` gets `getCoalescedEvents()`, one public member.

## Open

1. The counts of the section Measurement.
2. A Mac row with a physical mouse wheel and a mouse pan. The Mac pinch of a trackpad gives no
   `wheel` (Chart.js ADR 0108 Open 5).
3. `pointerrawupdate` (Pointer Events 3 §4.2.5) is not added: no ported code listens to it.
4. Blink's touch pipeline: whether Chrome on Android sends one `touchmove` for each frame of a
   two-finger pinch, after the two `pointermove`s. Verify on the Pixel with the device page of
   Chart.js ADR 0037 Evidence E8.
