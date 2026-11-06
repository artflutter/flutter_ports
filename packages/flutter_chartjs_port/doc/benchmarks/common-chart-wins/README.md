# Common performance work on all chart types

These files are the evidence of [performance.md](../../performance.md) §65 and of Chart.js ADRs 0092 to
0103.

The runs used an Apple M3 Max, the built-in 120 Hz display, DPR 2, Flutter 3.50.0-0.4.pre with Impeller
and a native macOS profile build. The plot of `apps/chart_benchmark_lab` was 964 x 420 logical pixels.
The driver is `apps/chart_benchmark_lab/tool/perf_matrix.dart`. It has 48 cells: 8 chart types, 3 item
counts and 2 presets. Each cell has 2 seconds of warmup and 4 seconds of capture.

- `baseline-visible.txt` is one pass at commit `bbd9779`, the start of the work, with the window in view.
- `old-1.txt` and `old-2.txt` are two passes of the library of commit `25d9637`. That library equals the
  library of `bbd9779`. Only the lab differs: it keeps its config objects stable between ticks.
- `new-1.txt` and `new-2.txt` are two passes of the merged work at commit `310806d`.
- `new-no-data-only.txt` is one pass of the same code with
  `--dart-define=CHARTJS_DATA_ONLY_UPDATES=false`: a full update on each tick.
- `new-no-scene-layers.txt` is one pass of the same code with the condition of the scene layers in
  `RenderChartHost.paint` set to false, in a temporary edit.
- `final-pass.txt` is one pass of the delivered code at commit `fc4e1de`. After `310806d`, that code runs a
  full update after a cancelled layout and writes the dataset context once on each data-only tick. Each cell
  differs from the mean of `new-1.txt` and `new-2.txt` by less than 4%.
- `profiles/` has the top of the CPU profile of the UI thread for 8 of the slowest cells of the merged work.
  Each one samples 7 seconds, 3 seconds after the cell starts.

Each line `MATRIX {json}` has the frame timings of the capture (`fps`, `intervalP90`, `uiP90`,
`rasterP90`), the mean time of the update and of the draw from a plugin (`updateMs`, `drawMs`), the time
from the start of the frame callbacks to the end of the post-frame work (`busyP50`, `busyP90`) and
`refreshHz`, which is 120 in each line.

The screen of the Mac was locked in all passes but `baseline-visible.txt`. The driver flag
`MATRIX_IGNORE_COVER=1` keeps the frames on and the capture gate open. The process argument
`-NSAppSleepDisabled YES` removes the throttle of the system. With both, the frame clock stays at 120 Hz
in each cell. `old-1.txt` differs from `baseline-visible.txt` by 11% or less in each cell. Part of that
difference is the lab change. A Docker VM ran during the passes. It used about 240% of one CPU core when it
was examined.
