# The lab on the web and on phones

These files are the evidence of [performance.md](../../performance.md) §67.

All builds came from commit `d968024` with Flutter 3.50.0-0.4.pre. The drivers are
`apps/chart_benchmark_lab/tool/perf_matrix.dart`, with 48 cells (8 chart types, 3 item counts, 2 presets, 4 seconds of
capture), and `tool/perf_everyday.dart`, with 70 tests of first paint, animated updates, hover, resize, several series,
stacked bars and a time axis. Each pass ran once.

| Target | Details | Plot, logical pixels |
| --- | --- | --- |
| Web | Chrome 156, release build, a dedicated window on the built-in 120 Hz display of an M3 Max Mac, DPR 2. `web-wasm-*` is WebAssembly with skwasm. `web-js-*` is JavaScript with CanvasKit. | 964 x 420 |
| iPhone 17 Pro | iOS 26.6.2, profile build, DPR 3 | 318 x 300 in the matrix, 370 x 420 in the everyday tests |
| Pixel 8a | Android 17, profile build, Impeller on Vulkan, DPR 2.625, peak and minimum refresh rate set to 120 Hz for the run and restored after it | 327 x 300 in the matrix, 379 x 420 in the everyday tests |
| Mac | native profile build, the built-in display | 964 x 420 |

**The CPU test.** Each row has `calMs` and `calAfterMs`: the best of 6 runs of fixed work on the UI thread, before and
after the capture. On the Pixel, `MATRIX_COOL=1` waits for a test within 10% of the best time and measures again a cell
that ends more than 15% above it. No wait and no second measurement occurred. The test stayed between 53.4 and 58.1 ms.
The thermal files have one line for each 5 seconds: the clock cap of the big core, the battery temperature and the
thermal status. The battery rose from 27.1 to 35.0 °C. The status stayed 0. The cap fell from 2.914 to 2.687 GHz only at
the end of the matrix, in the radar cells.

On the iPhone, the wait stayed at a test twice as slow as the best time for minutes after the heaviest cell. The app
cannot read the heat or the core, so these passes ran with no wait. The test reached up to 57.7 ms against a best time
of 21.8 ms after some cells at 20,000 items. Thus the iPhone figures at 20,000 items are possibly low. The cells at
1,000 and 5,000 items all reached 120 FPS.

**Limits.** A browser reports a refresh rate of 60 in `refreshHz`, but its frames reach 120 Hz. The `fps` of the `mount`
tests counts only the frames around each new chart, so that it is no figure of smoothness. The phone plots are smaller
than the Mac plot, so that a phone has less raster work for each item. The hover tests use a mouse event on each target.

`scripts/` has the runners and the table scripts. The Pixel build needs `--android-skip-build-dependency-validation` on
this Flutter. The iPhone has a free signing profile with a limit of 3 apps, so that these runs used the existing app id
`dev.artflutter.colorBench` in place of `dev.artflutter.chartBenchmarkLab`.
