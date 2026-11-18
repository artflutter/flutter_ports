# Chart.js ADR 0172: Animation frame jobs in place of promise jobs

- Status: accepted (2026-11-18): its code and the tests of section Tests pass.
- Date: 2026-11-18
- Supersedes: of [Chart.js ADR 0019](0019-animation.md), section 7, the item `lib/src/js/js_promise.dart` of
  section 1, and of section 12, the `jsPromiseAll` words of the group `platform-animation-promise-checkpoint` and
  the item "the job order of `js_promise.dart`".
- Related: [Chart.js ADR 0016](0016-frame-scheduling.md), [Chart.js ADR 0034](0034-no-display-only-js-exactness.md)

## Context

Upstream uses one promise chain in the animations. When the option animations of an element end, the element
gets the shared options object (`core.animations.js:51-55`). A browser runs that `.then` at the microtask
checkpoint after the animation frame callback. Flutter runs its microtasks after all the frame callbacks of a
frame. Without the checkpoint, a re-hover in the frame that ends an un-hover keeps the color with no hover.

Chart.js ADR 0019 §7 kept the promises: `Completer.sync`, `Future.wait`, the job queue of `js_promise.dart` and
`jsPromiseAll` for `Promise.all`. The order of the chain is necessary. The JS promise form is not.

## Decision

1. **A function, not a future.** `Animation.onSettle(listener)` takes the `_promises` place: `listener` gets
   `true` at the end and `false` at an update or a cancel, one time. `_notify` removes the functions that it
   calls, as a settled promise ignores a later `res()` or `rej()`.

   ```dart
   Animation.whenAllEnd(_awaitAll(animations, newOptions), () {
     writeProperty(target, 'options', newOptions);
   });
   ```

2. **`Promise.all` is a count.** `Animation.whenAllEnd(running, onEnd)` calls `onEnd` when each animation of
   `running` ends, and never after one fails. `_awaitAll` gives the list of the active animations.

3. **Frame jobs keep the order.** `_notify` queues one frame job for each function. `whenAllEnd` queues `onEnd`
   in the job after the job of the last end, and at once for an empty list. This is the job depth of
   `Promise.all(...).then`, so two chains on one target end on the object of upstream.

4. **The frame runs the jobs.** The animator frame callback runs inside `Animation.runFrame`. It runs the
   callback, then the queued jobs in their order, until no job is left. A nested call adds to the outer frame.
   A job error goes to the zone, and the next job runs. Outside a frame, a job is a Dart microtask.

5. **`wait()` stays.** The public `wait()` gives a plain `Future<void>`, which `onSettle` completes. It fails
   with `undefined`, as `rej()` passes no reason. The port does not call it.

6. **No JS promise runtime.** `lib/src/js/js_promise.dart` goes, with `jsEnqueuePromiseJob`,
   `jsRunWithMicrotaskCheckpoint` and `jsPromiseAll`. `js_semantics.dart` and the app library no longer export
   them. The row `platform-animation-promise-checkpoint` stays, with the new forms.

## Rejected

- Plain futures with no frame step: the re-hover keeps the color with no hover.
- The write in `_notify` with no job: an update in the last `progress` listener ends on the other options.

## Consequences

- No `Completer`, `Future` or job list for an animation that nobody waits for.
- An add-on that called the three `js*` names does not compile. The zoom and sankey ports do not call them.
- The jobs of a throttled event callback still run after all the frame callbacks, as before.

## Tests

- `test/port/core/core.animator_test.dart` (group `platform-animation-promise-checkpoint`)
- `test/port/core/core.animation_test.dart` and `test/port/core/core.animation_cancel_test.dart`
- `test/specs/core.animations_test.dart` and `test/specs/core.animation_test.dart`
- The full test list of AGENTS.md before a push.
