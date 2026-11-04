# Line charts at 20,000 items: native macOS

2026-11-03–04. [ADR 0080](../../adr/0080-line-20k-options.md).
Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7, profile AOT,
Impeller MetalSDF. The baseline includes the existing ADR 0078/0079 working-tree
changes. It is not a clean checkout of ba58aa8.

**The every-mode 60 FPS target is not achieved.** All 20,000 items remain;
callbacks still execute, and redraw, full update, data-only fallback and looping
animation retain their distinct behavior. The improvements reduce option and
context work. They do not change sampling, geometry, drawing or animations.

## CPU comparisons

800×480, DPR1, moving data for full update. Each cell has 700 ms warmup and
seven calibrated batches of approximately 160 ms. Two baseline and two final
processes use the same case order. The final frame matrix runs between the two
final CPU processes. No assistant build or test runs during measurements.

The following costs average two process medians. Full CPU is the sum of the
update, draw and paint-end medians, **not** a percentile of the combined call.
Data generation is outside these CPU stopwatches; the real frame run includes it.

| Full update | Connected | Before CPU ms | After CPU ms | Reduction |
| --- | --- | ---: | ---: | ---: |
| static | off | 5.15 | 5.37 | -4.3% |
| static | on | 7.03 | 7.21 | -2.5% |
| indexed | off | 30.21 | 13.90 | 54.0% |
| indexed | on | 31.97 | 16.50 | 48.4% |
| scriptable | off | 59.86 | 28.25 | 52.8% |
| scriptable | on | 60.48 | 29.66 | 51.0% |

Static and redraw rows are controls; no improvement is claimed for them.
`cpu-summary.json` retains all twelve cells, component costs and individual runs.

## Real frame matrix

The ordinary StressDemo runs in a fixed 1100×900 content window, producing a
1036×520 chart at DPR2. The temporary native runner sets the window before the
warmup ends; source code for the application's native runner is unchanged.
Saved macOS window state is ignored. Every accepted row checks the chart size.

The final run has **72 cases**: four operations × three color modes × connected
points off/on × 0/50/200 overlay labels. 19 cells with absent or insufficient frame samples were repeated with the display kept awake; the accepted matrix contains 72 valid cells. Another **24 cases** repeat every
operation/style/connection combination with 200 rotating labels. Each case runs
five seconds; readouts from the first two seconds are excluded. The FPS columns
below span the six connection/label combinations of each operation/style.

| Operation | Colors | FPS range | Worst UI p90 ms | Worst raster p90 ms |
| --- | --- | ---: | ---: | ---: |
| draw | static | 60.0–60.0 | 5.49 | 1.99 |
| draw | indexed | 60.0–60.0 | 6.49 | 2.41 |
| draw | scriptable | 60.0–60.0 | 6.29 | 2.32 |
| update | static | 60.0–60.0 | 8.79 | 1.99 |
| update | indexed | 49.7–60.0 | 21.98 | 2.52 |
| update | scriptable | 27.4–30.0 | 35.82 | 2.48 |
| data | static | 60.0–60.0 | 9.04 | 2.02 |
| data | indexed | 50.2–60.0 | 21.43 | 2.57 |
| data | scriptable | 29.6–30.0 | 34.02 | 2.40 |
| animate | static | 60.0–60.0 | 7.59 | 1.90 |
| animate | indexed | 60.0–60.0 | 14.16 | 2.44 |
| animate | scriptable | 45.7–60.0 | 14.27 | 2.40 |

With 200 rotating labels, observed FPS ranges were draw 60.0–60.0, update 28.1–60.0, data 28.9–60.0, animate 57.3–60.0. The full rotating-label rows are retained in the measurements.

FPS is the mean of the StressDemo readouts, not a guaranteed minimum. UI/raster
p90 figures are calculated from captured FrameTimings after warmup; the JSON
retains the frame count, and late timing batches can arrive after a case ends.
These short local measurements do not establish sustained or cross-device FPS.
Two rotating-label cells used eight-second replacement runs after insufficient samples.
The original animation matrix includes a 45.7 FPS outlier (scriptable, no line,
200 labels; four readouts, 89 captured frames, UI p90 8.56 ms). A separate
ten-second repeat measured 60.0 FPS, with 16 readouts and UI p90 8.69 ms. The
repeat is supplemental: the lower original result remains in the matrix.
The baseline's 24 zero-label frame cases retained readout means, without the
additional raw frame-timing collection of the final probe.

Data-only returns false in this matrix: the documented eligibility checks select
full-update fallback. The report does not count fallback as an incremental update.
The looping-animation cells measure animation ticks after initialization, not
restarting a complete animated chart update every frame. The scriptable workload
is the gallery's simple color callback; arbitrary user callbacks have no fixed
execution-time bound.

## What still needs to fit inside 16.67 ms

The raster thread remains below budget in these scenes. The remaining bottleneck
is UI-thread work for changing indexed/scriptable styles, especially with a
connected line. Passing a frameless CPU threshold alone is insufficient: data
motion, Flutter work, allocations and timing tails also need room.

The final diagnostic profile contains 7,102 samples: 63.1% include
DatasetController._resolveElementOptions, 27.5% include the prepared scriptable
resolver, and 17.5% include Chart.draw. These inclusive shares overlap and must
not be added. It confirms that per-point option work remains the main target;
skipping layout alone cannot close the gap. The worst measured UI p90 needs
about 5.3 ms less work for indexed full updates and 19.1 ms less for scriptable
full updates to reach 16.67 ms.

1. Reduce repeated per-point resolver setup and allocations further. A likely
   next implementation is a guarded per-update plan for native key/prefix/scope
   metadata, with explicit invalidation on observable mutations. It must retain
   original exceptions, callback order, fresh option identities and custom
   getters; blindly retaining a template across callbacks is unsafe.
2. Bring connected indexed UI-frame p90 below 16.67 ms with headroom. For
   scriptable full updates, the remaining reduction is substantially larger;
   the measured UI p90 values above quantify the gap. Native context-source
   reuse and avoiding temporary option objects are candidates to measure, not
   established gains.
3. Extend data-only eligibility separately if stable indexed styles are to use
   the incremental lifecycle. General data-dependent callbacks still need to
   run. Skipping them or silently replacing full update with a different
   lifecycle would change the task's semantics.

A universal promise for every custom callback/component/plugin is impossible:
user code can itself exceed a frame budget. A useful 60 FPS acceptance target
must name hardware, viewport, supported configurations and callback workload,
then pass actual frame measurements in every named cell.

## Correctness

- 10,929 workspace VM tests passed.
- 179 focused resolver/context tests passed on each of JavaScript and WebAssembly.
- Workspace analysis, formatting, parity generation and all seven port checks passed.
- New tests compare ordinary Config/chart twins, callback counts, fresh and
  retained views/options, context/key order, mutation/deletion and invalidation,
  optional callback arguments, non-scalar returns, partial ranges and custom
  points/scales. Existing line reference and resolver trace tests also pass.

No full browser, fixture, golden or mobile suite was run for this change.
`validation.json` and compressed logs retain the scope and results.

## Reproduction and artifacts

Use isolated workspace copies; the shared gallery build directory can be replaced
by another build. Resolve the existing lockfile with `flutter pub get --offline`.
Restore `probe.dart.txt`, `build_fixed.py.txt`, `run_final.py.txt` and
`report.py.txt` under `.dart_tool/line_20k/`, removing `.txt`.

Run `build_fixed.py` inside each isolated copy. It temporarily establishes the
benchmark window in the native runner, builds the probe with `--profile --no-pub`,
and restores that source file in `finally`. Save the candidate app as
`/tmp/line-20k-final.app`. For the baseline, apply `baseline-overlay.patch` to a
second copy of the delivered tree before building, and save `/tmp/line-20k-a.app`.
The patch reverts only this pass's four runtime files, preserving the preceding
working-tree optimizations.

Sign only these temporary app copies using the entitlements in
[the category-layout recipe](../category-layout/README.md). The runner passes
`-ApplePersistenceIgnoreState YES` and receives canonical results through an
`OUTPUT` file, independent of macOS console routing. `caffeinate -diu python3 .dart_tool/line_20k/run_final.py` runs the
matrix sequentially with temporary display-sleep prevention and rejects missing rows, undersampled cases or mismatched chart dimensions.
`run_remaining.py` and `finish.py` rerun undersampled cells; the original and
accepted rows remain separately available.
The original first baseline logs are retained; `report.py` combines them with
the final runs. `metadata.json` records measured/delivered source and executable hashes. The only
post-measurement runtime edit is a lint-only helper return cleanup; 28 focused
VM regressions and analysis passed after it.

`measurements.json.gz` contains every accepted CPU/frame row. The intermediate
CPU profile explains the second optimization step; it is diagnostic and is not
used for timing claims. The separate final profile and its summary identify
the remaining costs; no profiler was attached during timing runs. Temporary wrong-entry-point and wrong-viewport runs were
rejected and are excluded from the measurements.
