# One hover pass and one draw for each frame of a live chart

These files are the evidence of [Chart.js ADR 0091](../../adr/0091-live-mouse-move.md) and of
[performance.md](../../performance.md) §64.

The runs used an Apple M3 Max, the built-in 120 Hz display, DPR 2, Flutter 3.50.0-0.4.pre and a
native macOS profile build. The chart was the Chart.js line of `apps/chart_benchmark_lab`: 20k live
points, tooltips on, animation off, no axes and no grid, in a 964 x 420 logical plot.

- `probe.dart.txt` is the driver. It starts a capture and sends a synthetic mouse that follows the
  curve. It splits each frame into mouse work and update work through a global plugin. `PERIOD_MS`
  sets the time between mouse moves. `NO_MARKERS=1` turns the markers off. `SKIP_MOUSE_DRAW=1`
  cancels the draw of a mouse event from the plugin, with no library change.
- `before.txt` has the runs before the change, with and without `SKIP_MOUSE_DRAW=1`.
- `after.txt` has the runs after the change.
- `after-still-and-wiggle.txt` has the runs after the change of the driver of
  [`../replay-single-draw/`](../replay-single-draw/README.md).

In `after.txt`, `mouseEvent` shows about 135 events. Nearly all of them come from the 1.1 seconds
after the capture, when the data updates have stopped and the moves correctly take the old path. The
mouse keeps moving there. A separate run counted only inside the capture window: 1,102 moves held,
0 declined and 4 real events.
