# Chart.js ADR 0007: Frame scheduling

- Status: accepted (2026-10-18)
- Superseded by: [Chart.js ADR 0016](0016-frame-scheduling.md) (2026-10-21)
- Date: 2026-10-17
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:packages/flutter_chartjs_port/doc/adr/0007-frame-scheduling.md`

## Summary

This ADR ran `requestAnimFrame` on `scheduleFrameCallback`. `throttled` gave one call in each frame.
`debounce` ran on a `Timer`, and `Chart.destroy()` cancelled it. One module-level animator kept the upstream
loop, and the chart host muted it under `TickerMode`. The host throttled resize and input events and deferred
attach and detach to one post-frame callback.

## Where each part went

- Decision 1 (`requestAnimFrame` on `scheduleFrameCallback`): [Chart.js ADR 0016](0016-frame-scheduling.md)
  item 1.
- Decision 2 (`throttled`): [Chart.js ADR 0016](0016-frame-scheduling.md) item 2.
- Decision 3 (`debounce` on a `Timer`): [Chart.js ADR 0016](0016-frame-scheduling.md) item 3.
- Decision 4 (the debounce cancel in `destroy()`): [Chart.js ADR 0016](0016-frame-scheduling.md) item 4.
- Decision 5 (the call sites in `core.controller`): [Chart.js ADR 0016](0016-frame-scheduling.md) item 5.
- Decision 6 (the animator frame source): [Chart.js ADR 0016](0016-frame-scheduling.md) item 6.
- Decision 7 (`TickerMode` muting): [Chart.js ADR 0016](0016-frame-scheduling.md) item 7.
- Decision 8 (no frame-callback cancel): [Chart.js ADR 0016](0016-frame-scheduling.md) item 8.
- Decision 9 (the platform consumers): [Chart.js ADR 0016](0016-frame-scheduling.md) item 9. There, the first
  layout reports the first attach at once, inside `performLayout`, not in a post-frame callback.
- Decision 10 (the layer of `helpers.extras`): [Chart.js ADR 0016](0016-frame-scheduling.md) item 10.
- Decision 11 (the pinning tests): [Chart.js ADR 0016](0016-frame-scheduling.md) item 11.
- Decision 12 (the scope of the animation ADR): [Chart.js ADR 0016](0016-frame-scheduling.md) item 12.
