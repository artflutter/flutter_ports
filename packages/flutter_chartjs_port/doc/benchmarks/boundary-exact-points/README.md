# Private boundary endpoint search: Android report

The implementation halves gap-fill draw CPU time at N=1000 on the connected
Pixel 8a. It avoids repeated interpolation scans for exact endpoints of private
`origin`, `start` and `end` boundaries. The chart produces the same drawing
commands. Shared interpolation, segment matching and canvas code are unchanged.

## Release results

Flutter 3.47.8 / Dart 3.13.7, Android 17, arm64 release, profiler off. Three datasets,
800 × 480 logical canvas, DPR 1. A/B/B/A, two fresh processes per variant, ten cells
per process, 500 ms warmup and nine batches targeting 150 ms. Guards run before
primary gap cells. No builds or tests ran alongside timing. No run was discarded.

The value is the median across the two process results. Each process result sums
its draw and recording-completion medians, plus update for a full update. These
are CPU measurements, not GPU raster time or FPS. Positive percentages mean less
time. Two pairs show direction only; they do not establish confidence intervals.

| Case | N | Operation | Baseline ms | Candidate ms | Time saved |
| --- | ---: | --- | ---: | ---: | ---: |
| Gap fill | 100 | Draw | 0.486 | 0.362 | 25.4% |
| Gap fill | 100 | Full update | 1.244 | 1.152 | 7.4% |
| Gap fill | 1000 | Draw | 10.704 | 5.339 | 50.1% |
| Gap fill | 1000 | Full update | 14.914 | 8.183 | 45.1% |
| Ordinary line | 1000 | Draw | 0.285 | 0.282 | 1.2% |
| Ordinary line | 1000 | Full update | 0.815 | 0.831 | -2.0% |
| Radar fill | 1000 | Draw | 0.913 | 0.903 | 1.1% |
| Radar fill | 1000 | Full update | 3.645 | 3.585 | 1.7% |
| Stack fill | 1000 | Draw | 1.805 | 1.768 | 2.1% |
| Stack fill | 1000 | Full update | 8.578 | 8.241 | 3.9% |

At N=1000, the paired draw reductions are 50.2% and 50.0%. Full-update reductions
are 40.4% and 49.3%; the baseline update processes vary (13.937 and 15.891 ms),
so the aggregate 45.1% should not be treated as a precise universal gain.
The only slower guard is ordinary-line update, +0.0165 ms (+2.0%), below both
predeclared limits of 0.1 ms and 5%. Small guard shifts are inconclusive.
Battery temperatures were 29.2–29.4 °C; all before/after thermal status readings
were 0. This is bounded Android validation; no iOS/macOS/web performance claim.

## Why it helps

The separate baseline profile collected 12,984 samples during a gap-fill draw
workload. Inclusive sample shares: `boundSegments` 66.9%, `boundSegment` 64.5%,
`interpolatedLineTo` 45.2%, `LineElement.interpolate` 44.7%, and segment matching
`segments` 27.5%. These shares overlap and must not be added. `boundSegment` self
time is 45.9%. The original filler scans the boundary again for each endpoint,
and repeats this for the above/below color passes.

The candidate validates a fresh, privately owned constant boundary once per draw,
then uses binary search for exact endpoints. Those hits return the same existing
point as the original `[i, i]` interpolation result. Unmatched queries, reversed,
duplicate, near-equal or non-finite coordinates and other targets retain the
original path. User dataset targets keep their custom interpolation callbacks.
Source-to-target segment matching still scans; this does not make the complete
fill algorithm linear.

## Verification

All checks pass on the final tree:

- Workspace tests: 10,572 pass, 87 skips across six packages.
- Full web suite on dart2js and dart2wasm: 7,894 chart-port and 110 test-utils
  tests pass, with four skips.
- Upstream specification coverage: 958 pass, 78 skips, no failed/missing cases.
- Fixtures: 628 pass, 39 expected skips, no failed/missing fixtures.
- Formatting, fatal-info analysis and all seven port checks pass.
- Reconstructed candidate source hashes equal the measured APK sources and the
  final working library. Python reproduction scripts parse successfully.

The new tests include four pure differential/guard cases and thirteen real-chart
cases, including custom dataset callbacks. `validation.json` records commands
and summaries. Generated parity was refreshed from the final specification run.
The implementation is retained with the bounded Android validation above.

## Evidence and reproduction

- `protocol.md`: protocol recorded before release timing.
- `metadata.json`: baseline commit, candidate source hashes and device versions.
- `candidate.patch`: the exact two-file library change used in the APK.
- `measurements.json.gz`: all four process records, individual cell results,
  APK hashes and before/after battery/thermal states.
- `summary.json`: unrounded aggregate and individual-process values.
- `profile-A.json.gz`, `profile-A.log`: original VM CPU samples and workload log.
- `main_gap.dart.txt`, `pubspec.lock`: measured harness and dependency lock.

Recompute the table without a device:

```sh
python3 packages/flutter_chartjs_port/doc/benchmarks/boundary-exact-points/report.py
```

Reconstruct and build in an empty scratch directory with the pinned Flutter SDK:

```sh
python3 packages/flutter_chartjs_port/doc/benchmarks/boundary-exact-points/setup.py \
  --repo "$PWD" --out /tmp/gap-fill-repro
cd /tmp/gap-fill-repro
python3 build.py A B
python3 run_android.py A B B A
```

The runner uses the recorded device serial and the separate app ID
`dev.artflutter.gap_fill_bench`. It preserves run metadata, enforces a 34 °C start
temperature ceiling and requires all ten rows plus the completion marker. The
reconstruction was checked against both measured candidate source hashes.

For profiling, build A with `flutter build apk --profile --target-platform
android-arm64 -t lib/main_gap.dart --dart-define=PROFILE=true` in `A/app`, set
`DART_PACKAGES` to the repository's absolute `.dart_tool/package_config.json`
(which includes `vm_service`), then run `python3 profile.py A`. The profiling
entry waits 15 seconds, then runs 30 batches of 500 ms with 1 s warmup. Keep
profile timings separate from the release comparison.
