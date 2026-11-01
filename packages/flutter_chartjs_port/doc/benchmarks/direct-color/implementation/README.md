# Direct-color implementation comparison

Archived CSS-compatible candidate. ADR 0057 was subsequently changed to Color-only;
see the sibling `strict/` evidence and performance.md §22 for the final change.

The measured production implementation is described in [ADR 0057](../../../adr/0057-direct-typed-colors.md).
The report is [performance.md §21](../../../performance.md#21-direct-color-implementation-macos-chrome-and-android).
This is separate from the earlier isolated prototype in the parent directory.

## Scope

Flutter 3.47.8 / Dart 3.13.7, release builds. Four fresh processes per platform,
A/B/B/A: macOS, headless Chrome 156 running Wasm, and Pixel 8a. The benchmark
uses actual typed dataset lowering, a line controller without a connecting line,
5000 numeric values, a hidden category x axis, a hidden linear y axis, an 800 × 480
bitmap at DPR 1, no animation, no legend or tooltip. Each of five cases measures
both draw + recording completion and update + draw + recording completion.
Each cell warms for 250 ms, then runs seven approximately 100 ms batches.

The five cases are a CSS-background callback control, a static typed color, a
16-color typed callback (alpha 0.45), a callback with 5000 distinct translucent
colors, and a list of those distinct colors. The control still has a typed border
color, so a small draw gain is possible there. Palette creation and initial config
lowering are outside the timed loop. Callback results are not memoized.

These timings measure CPU-side chart work, not FPS or GPU rasterization. This
workload includes category scale work and uses the final compatibility adapters;
it is not the same workload as the prototype in §20. Small two-pair differences
are provisional. The initial macOS screen found CSS-control overhead; the final
candidate inlines `publicColorValue`. Initial screen results are not pooled with
the final series. No iOS result is claimed.

## Reproduce

From the repository root, with the pinned SDK and connected Android device:

```sh
python3 packages/flutter_chartjs_port/doc/benchmarks/direct-color/implementation/setup.py \
  --repo . --out /private/tmp/direct-color-implementation-rerun
cd /private/tmp/direct-color-implementation-rerun/A/app
flutter pub get --offline
cd ../../B/app
flutter pub get --offline
cd ../..
python3 build.py A B
python3 run_native.py macos
python3 run_chrome.py
python3 run_native.py android
python3 report.py
adb uninstall dev.artflutter.direct_color_production
```

`setup.py` reconstructs baseline commit `175337ff09d37b6aa7a5de76cdf5f90e44be6bc8`
and applies the retained library patch to B. It does not modify the repository.
The patch includes the generated option classes and the new prepared-color module.
The app uses its own Android application identifier. The runner targets the
measured Pixel's serial; edit `adb()` in `run_native.py` for another device.
Chrome is launched by `flutter run --release --wasm`, not through the unavailable
browser connector. The application reports its build mode, Wasm backend and user
agent to a temporary localhost receiver; the runner requires ten release cells.

`measurements.json.gz` contains the individual process records and raw batch
summaries, including Android battery readings and native binary hashes.
`summary.json` retains medians and individual process values. To regenerate it from the retained evidence, run `python3 report.py --recorded`
in this directory. Build logs and APKs remain in `/private/tmp/direct-color-production/`.

The final benchmark library snapshot was compared byte-for-byte with the working
tree. Source headers, import constraints, JS semantics, the typed-read ratchet,
generated-code check, static analysis, affected compatibility tests and spec tests
were checked separately. The Chrome compatibility check runs only the six new
regressions, with the VM annotation removed in a temporary test file and components
registered explicitly. Neither the full web suite nor iOS was run for this change.
