# Color-only comparison

Final implementation: [ADR 0057](../../../adr/0057-direct-typed-colors.md).
Results and limitations: [performance.md §22](../../../performance.md#22-color-only-implementation).
The sibling `implementation/` is the earlier CSS-compatible candidate.

Each measured platform ran A/B/B/A, two fresh release processes per variant.
Each process measures five 5000-point cases, both draw and full update, with a
250 ms warmup and seven 100 ms batches per cell. The line has no connecting line,
hidden category/linear axes, no animation, no legend and no tooltip. Timings sum
CPU update, draw and recording-completion medians; they do not measure GPU/FPS.

A is commit `175337ff09d37b6aa7a5de76cdf5f90e44be6bc8`. B passes native Colors
through typed lowering, raw callbacks and the canvas. The raw callback case
changes from returning CSS in A to returning Color in B, as the new API requires.
It is not an unchanged control. Static/16-color cases hit A's parser cache;
distinct-color cases exceed it. Palette creation and initial lowering are outside
the timed region. Callback answers are never memoized.

`measurements.json.gz` contains every process record and batch summary;
`summary.json` contains medians and per-process values. Recompute them with:

```sh
python3 report.py --recorded
```

`candidate.patch` preserves the measured library snapshot. Subsequent source
cleanup removes an unused compatibility helper and changes comments; neither
changes the measured path. `metadata.json` records versions and limitations.
The macOS host also compiled iOS builds during part of its series; small macOS
changes are inconclusive. This bounded run intentionally avoids repeated tuning.

iOS completed the same A/B/B/A series on the connected iPhone 17 Pro after
resolving its development-profile launch rejection. Release console output was
unavailable. The completion helper writes results to the app's temporary directory
after all timed cells; `run_ios.py` retrieves the file and checks variant/build.
Before each subsequent launch it overwrites only that result file with a sentinel,
so stale results cannot pass. One console-only launch preceded the retained series;
its output is not pooled with measurements. The earlier launch error is retained
as troubleshooting evidence. No production library change was needed.

To reconstruct the measured apps without touching the repository:

```sh
python3 setup.py --repo /path/to/flutter_ports --out /private/tmp/color-rerun
cd /private/tmp/color-rerun/A/app
flutter pub get --offline
cd ../../B/app
flutter pub get --offline
cd ../..
python3 build.py A B
python3 run_native.py macos
python3 run_native.py android
python3 run_chrome.py
python3 report.py
```

Use the pinned Flutter SDK. Device runners identify the connected devices used
for this run; adjust their IDs for another device. For iOS, use your signing team
and bundle identifier in the temporary projects, build each app with
`flutter build ios --release -t lib/main_color_bench.dart --dart-define=VARIANT=A`
(or B), trust the profile on the phone, then run `python3 run_ios.py`.
The Android runner uses a separate benchmark application identifier.
