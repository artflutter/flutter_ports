# One draw for an update that replays an event

These files are the evidence of [Chart.js ADR 0090](../../adr/0090-replay-single-draw.md) and of
[performance.md](../../performance.md) §63.

The runs used an Apple M3 Max, the built-in 120 Hz display, DPR 2, Flutter 3.50.0-0.4.pre and a
native macOS profile build. The chart was the Chart.js line of `apps/chart_benchmark_lab`: 20k live
points, tooltips on, animation off, no axes and no grid, in a 964 x 420 logical plot.

- `probe.dart.txt` is the driver. It starts a capture, sends a synthetic mouse hover to the center
  of the chart and times the phases of each frame through a global plugin. With `MOVE=1`, it moves
  the mouse every 8 ms.
- `before-mouse-and-markers.txt` has the runs before the change.
- `before-simulated-one-draw.txt` has the runs before the change with and without `DRAW_ONCE=1`.
  This flag cancelled the first draw from the plugin, with no library change.
- `after.txt` has the runs after the change.

To run the driver, build it and start the binary directly. The app runs in the macOS sandbox, so
the driver logs to stdout.

```sh
cd apps/chart_benchmark_lab
cp ../../packages/flutter_chartjs_port/doc/benchmarks/replay-single-draw/probe.dart.txt /tmp/probe.dart
flutter build macos --profile -t /tmp/probe.dart
MODE=hover MARKERS=1 HOVER=1 MOVE=0 \
  build/macos/Build/Products/Profile/chart_benchmark_lab.app/Contents/MacOS/chart_benchmark_lab
```

Do not set `DRAW_ONCE=1` after the change: the replay then has no draw to cancel except the only
draw of the update.
