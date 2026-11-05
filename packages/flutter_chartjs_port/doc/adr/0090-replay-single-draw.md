# Chart.js ADR 0090: One draw for an update that replays an event

- Status: accepted
- Date: 2026-11-05
- Related: performance.md §63; `differences.md` row `adapt-replay-single-draw`.

## Context

Chart.js keeps the last mouse event. Each update replays that event, so the hover state follows the
new data. On a replay, `plugin.tooltip.js:1155` always reports a change. Thus `core.controller.js:1182`
renders, and `core.controller.js:536` renders again. With no queued animation, each render draws.
The second draw starts with a clear, so the first draw never reaches the screen.

The port copied this behavior. A live 20k line chart with markers, tooltips and animation off lost
its 120 Hz cadence while the mouse stayed over the chart.

## Decision

`update` and `updateData` replay the last event through `_replayLastEvent`. During that call, the
event handler skips its render when no animation is queued. The render that follows the replay in
`update` or `updateData` draws the chart.

These calls keep the upstream form:

- A replay outside an update, for example a direct call of `eventHandler`.
- An event that is not a replay.
- A replay with a queued animation. Each render only starts the animator, so no draw is redundant.

## Consequences

The pixels do not change. The hover search, the hover styles, the tooltip update, `onHover` and the
`beforeEvent` and `afterEvent` hooks still run on each replay.

In an update that replays an event with no queued animation, these calls run once, not twice:

- The hooks `beforeRender`, `beforeDraw`, `afterDraw` and `afterRender`.
- The dataset and tooltip draw hooks.
- `animation.onComplete`.

A plugin or callback that counts these calls sees a lower count than on Chart.js.

## Alternatives

- **Keep the upstream double draw.** Rejected. The first draw has no visible result, and it costs
  about 2.1 ms for each frame on the measured chart with markers.
- **Make the tooltip report no change on a replay.** Rejected. `handleEvent` of the chart can also
  report a change, and then the replay still draws. It also changes the result of a replay outside
  an update.
- **Draw at most once for each frame.** Not chosen now. It can also remove the extra draws of a
  moving mouse, but it moves each draw to a later time, and code that reads the canvas after an
  update then sees old pixels. It needs its own decision.

## Evidence

Figures are in performance.md §63, and the driver and logs are in
`doc/benchmarks/replay-single-draw/`. With the mouse still and markers on, the chart holds 120 FPS,
as it does with no mouse. Before the change, it gave about 101 FPS.

`test/port/core/core.controller_replay_test.dart` pins the call counts of each case above. It also
compares the bytes of the bitmap after one draw with the bytes after a second draw on the same
state. The observation digests of `test/port/options/observation_test.dart` did not change.
