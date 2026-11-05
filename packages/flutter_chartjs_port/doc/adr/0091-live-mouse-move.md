# Chart.js ADR 0091: One hover pass and one draw for each frame of a live chart

- Status: accepted
- Date: 2026-11-05
- Related: Chart.js ADR 0090; performance.md §64; `differences.md` row `adapt-live-mouse-move`.

## Context

A mouse move runs in the frame callbacks: the hover search, the tooltip update and, when the active
point changed, a draw. A live `ChartView` then gets a new config, and its update runs after the same
frame: the data update, the replay of the mouse event and a draw. So a frame with a moving mouse does
the hover work two times and the draw two times.

On a live 20k line chart with markers and a mouse on the curve, this takes 10.1 ms for each frame.
The limit at 120 Hz is 8.33 ms, so the chart gave about 90 FPS. Chart.js ADR 0090 removes a different
draw, inside the update, and does not change this case.

## Decision

A `ChartView` guesses that its chart is live when a config update ran in the last 34 ms of frame time.

- A `mousemove` of a live chart with no queued animation waits for the update of its frame. The chart
  holds the move.
- `update` and `updateData` take the held move in place of the last event, and replay it. The frame
  then has one pass of hover work and one draw.
- If no update takes the move, the microtask after the last post-frame callback releases it as a real
  event.
- Any other event type releases the held move first, so the events keep their order.

These cases keep the upstream path: a `Chart` with no `ChartView`, a `ChartView` with no recent config
update, updates that an app starts with a direct call of `chart.update`, and a chart with a queued
animation.

## Consequences

In a live chart, the hover appears one frame later: about 8 ms at 120 Hz. The hit test then uses the
new data and not the data of the last frame.

In such a frame, `onHover` and the `beforeEvent` and `afterEvent` hooks run once, not twice. The hooks
get `replay: true` for the new move. A plugin that ignores replays does not see these moves. The
tooltip does not have this problem: the update ends its state that ignores replays after
`setActiveElements`, as a real event does.

A wrong guess costs one frame of latency for one move. It changes no result.

## Alternatives

- **Cancel only the draw of the mouse event.** Rejected. It gave 108.0 and 110.4 FPS, because the hover
  work still runs two times, and a chart with no data update needs that draw.
- **Handle the mouse after the frame in every chart.** Rejected. A chart with no data updates would
  show each hover one frame later, with no gain.
- **Draw in the paint phase, once for each frame.** Rejected. The draw runs plugin hooks and user
  callbacks, and these must not run in the paint phase.
- **Make marker drawing cheaper.** This is a separate change. It can add a margin for all charts with
  markers, and this decision does not exclude it.

## Evidence

Figures are in performance.md §64, and the driver and logs are in `doc/benchmarks/live-mouse/`. With a
mouse on the curve and markers on, the chart gives 120 FPS. Before the change, it gave about 90 FPS.

`test/port/widgets/chart_view_live_mouse_test.dart` pins one hover pass and one draw for each frame of
a live `ChartView`, and the old path of a chart with no recent update. It also pins the release of a
move that no update takes. `test/port/core/core.controller_replay_test.dart` pins the chart side:
both update paths, the order of other event types, a queued animation, the tooltip state and destroy.
Each test group fails when the matching part of the code is turned off.
