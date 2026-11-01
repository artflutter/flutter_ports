# Direct typed color to canvas: Android experiment

Measured on 2026-11-01. Results and limitations are in
[performance.md §20](../../performance.md#20-direct-typed-color-to-canvas-android-experiment).
This package retains the experiment, not a production implementation.

The baseline source is commit `175337ff09d37b6aa7a5de76cdf5f90e44be6bc8`, after the
color-parser optimization. `candidate.patch` adds a compile-time experiment to an
isolated copy of that source. A compiles with `DIRECT_COLOR=false`: existing CSS
conversion and parsing. B compiles with `DIRECT_COLOR=true`: typed colors become
normalized `dart:ui` colors, which the canvas setters accept directly. The string
path and its 512-entry cache remain available in B for raw callers.

`main_direct_color.dart.txt` is copied to the isolated app as Dart source. It uses
the real `colorOption`/`colorScript` lowering functions and the existing gallery
`runChartBenchCase` harness. The rest of each config is a raw config, deliberately
identical across variants. It measures a line controller with visible points,
no connecting line, hidden axes, no animation, no events, no legend, no tooltip,
no automatic color plugin, an 800 × 480 bitmap and DPR 1.

## Reproduce

Use Flutter 3.47.8 / Dart 3.13.7 and the connected Pixel 8a. The build uses release
AOT, arm64, with the profiler off. The runner defaults to the measured device's
ADB serial and installs its own `dev.artflutter.direct_color_bench` app. Change
`dev` in `run_android.py` for another device; do not pool those results.

From the repository root:

```sh
python3 packages/flutter_chartjs_port/doc/benchmarks/direct-color/setup.py \
  --repo . --out /private/tmp/chart-direct-color-rerun
cd /private/tmp/chart-direct-color-rerun/app
flutter pub get --offline
cd ..
python3 build.py A B
python3 run_android.py A B B A B A A B
python3 report.py
adb uninstall dev.artflutter.direct_color_bench
```

The separate common-color guard uses opaque colors and colors with alpha 0.45,
both as 16-color callbacks. It measures update + draw + end at N 1000 and 5000,
with raw-string controls, in four fresh processes A/B/B/A:

```sh
TARGET=lib/main_common_color.dart SUFFIX=-common python3 build.py A B
RUN_DIR=common-runs SUFFIX=-common EXPECTED_ROWS=10 MAX_BATTERY_TEMP=350 \
  python3 run_android.py A B B A
RUN_DIR=common-runs python3 report.py
adb uninstall dev.artflutter.direct_color_bench
```

The main series uses a 34 °C starting gate. For the common-color guard, the
phone had settled around 34 °C after the main series, and the gate was set to
35 °C before collecting any guard results. The guard has its own results and
controls; do not pool it with the main series. `MAX_BATTERY_TEMP` is in tenths
of a degree; `WAIT_COOL=1` optionally waits for that gate instead of exiting.

To inspect the retained results without rebuilding, run in this evidence directory:

```sh
python3 report.py --recorded
RUN_DIR=common-runs python3 report.py --recorded
```

The compressed `*-measurements.json.gz` files retain each process's raw batch
summaries, checks, APK SHA-256, battery and thermal-service snapshots. The
`*-summary.json` and `.csv` files retain the medians, individual process values
and adjacent paired reductions. The scripts regenerate these summary files.

The output directory must be empty. `setup.py` reconstructs the two package trees
with `git archive`, applies the patch, copies the entry and scripts, and retains
the dependency lockfile. The Flutter build creates missing Gradle wrappers. If
cached dependencies are unavailable, run `flutter pub get` without `--offline`.
The reconstruction was checked against the source files used for measurement and successfully rebuilt a release APK.

## Workloads and interpretation

- Static: one typed color shared by all points.
- Script16: a typed callback returns one of 16 preconstructed colors.
- Script-unique: a typed callback returns a distinct preconstructed color per point.
- Indexable-unique: a list of distinct typed colors, lowered before the timed loop.
- Raw-static and raw-script16: CSS-string controls. Their output stays a string in B.
- Each chart workload runs at N 1000 and 5000, for draw-only and update-plus-draw.
- Each process uses 300 ms warm-up, then nine approximately 100 ms batches per cell.
  All variants visit cells in the same order. Eight fresh processes run in
  A/B/B/A/B/A/A/B order, with ten seconds between processes. The runner refuses
  to start above a battery temperature of 34 °C and records thermal state.
- Microbenchmarks use 100 ms warm-up and seven approximately 40 ms batches.
  They consume the result. `lower` measures the typed color conversion;
  `lower-and-paint` adds `parseCssColor` for strings. The latter returns the paint
  color; it does not issue a draw or measure the canvas setter itself.
- The report takes the median of each variant's four process values. A chart
  process value is the sum of its update/draw/end medians, as in the existing
  harness. Draw-only excludes update. The per-process values and four adjacent
  paired percentage reductions are retained; this is not a confidence-interval study.
- Initialization, initial list lowering, GPU rasterization, host/widget overhead,
  frame rate, animation and hover are outside the timed chart workload.

Every process in the main series compares 17,002 direct conversions with the existing CSS/parsing
path (alpha sweep, palette, Display P3 and extended sRGB). Six 600-point charts
also emit full-image byte hashes and nontransparent pixel counts; the report
requires matching hashes across variants. Hashes are a rendering check, not a
full behavior-equivalence proof.

## Integration limits

The prototype changes resolved option values from CSS strings to `ui.Color`
objects. The public option face and typed/raw twin tests currently expect strings.
The pure color helpers and animation parser do not support `ui.Color`; their
non-string object path does not read Flutter color channels. A production design
must handle these consumers and preserve their observable values and behavior.
A focused VM probe confirms this boundary: `getHoverColor` of the CSS form of
`Color(0xFF2050C0)` returns `#003CCA`, while passing the Flutter color directly
returns `#000`. The probe is retained in `behavior_probe_test.dart.txt`; copy it
to a temporary `.dart` file and run `flutter test <file>` from the repository root.
Theme compilation is also outside this experiment.

The candidate preserves the existing canvas alpha path: clamp the alpha, multiply
by 255, apply the `Color.rgb` percentage rounding, then round to a canvas byte.
Passing the original Flutter color straight to the paint would not preserve this
behavior. Hover and interpolation need their own original color semantics, not
just the final quantized paint color.

The experiment justifies further implementation work; it does not close ADR 0054
Open 2 or establish a release-ready fix. No production library file was modified.
