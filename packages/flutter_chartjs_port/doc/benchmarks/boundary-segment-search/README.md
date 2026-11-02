# Private boundary segment matching: Android report

The implementation reduces gap-fill draw CPU time by a further 45.6% at N=1000
on the connected Pixel 8a, relative to the endpoint optimization in `e942d50`.
It matches exact target segment bounds with a per-draw cursor instead of scanning
the entire private boundary for each source segment.

## Release results

Flutter 3.47.8 / Dart 3.13.7, Android 17, arm64 release, profiler off. Three datasets,
800 × 480 logical canvas, DPR 1. A/B/B/A, two fresh processes per variant, ten cells
per process, 500 ms warmup and nine batches targeting 150 ms. Controls run before
gap fills. No builds or tests ran alongside timing. No run was discarded.

Each process result sums its draw and recording-completion medians, plus update
for a full update. The table takes the median across the two processes per variant.
Positive percentages mean less CPU time. Two pairs show direction only, with no
confidence interval, GPU raster measurement or FPS claim.

| Case | N | Operation | Baseline ms | Candidate ms | Time saved |
| --- | ---: | --- | ---: | ---: | ---: |
| Gap fill | 100 | Draw | 0.3655 | 0.3345 | 8.5% |
| Gap fill | 100 | Full update | 1.1535 | 1.0970 | 4.9% |
| Gap fill | 1000 | Draw | 5.2980 | 2.8820 | 45.6% |
| Gap fill | 1000 | Full update | 8.5565 | 5.9920 | 30.0% |
| Ordinary line | 1000 | Draw | 0.2785 | 0.2840 | -2.0% |
| Ordinary line | 1000 | Full update | 0.8115 | 0.8090 | 0.3% |
| Radar fill | 1000 | Draw | 0.8925 | 0.8955 | -0.3% |
| Radar fill | 1000 | Full update | 3.8060 | 3.5435 | 6.9% |
| Stack fill | 1000 | Draw | 1.7385 | 1.7565 | -1.0% |
| Stack fill | 1000 | Full update | 8.1355 | 8.3205 | -2.3% |

At N=1000, draw reductions are 45.3% and 45.9% in the two pairs. Full-update
reductions are 37.8% and 21.5%; process values vary (baseline 8.927/8.186 ms,
candidate 5.556/6.428 ms), so 30.0% is a directional aggregate.

The largest slower control is stack update: +0.185 ms (+2.3%). It does not exceed
both predeclared regression thresholds, 0.1 ms and 5%. Ordinary-line drawing is
+0.0055 ms (+2.0%); radar and stack draws change by +0.003 and +0.018 ms. These
aggregate control shifts are inconclusive. Stack update varies across pairs:
one improves by 3.5%, while the other is 0.663 ms slower (+8.4%). The latter
exceeds both limits in one pair, but does not meet the protocol's repeatability
criterion. Its cause is not established; this is not proof of zero regression.
No unrelated control improvement is attributed to the optimization. Battery temperatures were 29.0–29.4 °C and all
before/after thermal status readings were 0. No cross-device performance claim.

## Why it helps and scope

The baseline profile, after the earlier endpoint optimization, collected 13,025
samples. Inclusive shares: segment matching `segments` 50.3%, `boundSegments`
43.7%, `boundSegment` 44.6%; these overlap. `boundSegment` self time was 26.0%.
The remaining repeated work was scanning the target for each source interval.

The candidate extends the already validated private boundary index. Ordered exact
bounds advance a cursor; backward or overlapping queries use binary search. An
exact hit constructs the same native segment with identical start/end indices,
loop=false and absent style. The internal factory adds no segment implementer and
is hidden from the public helpers library. Source geometry calculations, the shared
scanners and canvas calls are unchanged. Misses, reversed/non-finite/unsupported
bounds and other target kinds retain the original path. State lasts one draw.

## Correctness

Two hundred generated boundaries on both axes compare native segment type and
fields against the original scanner for ordered, backward, overlapping, repeated
and single-point ranges. Another 200 generated source cases compare every fill
part across two passes, including source changes after boundary creation. Explicit
miss/tolerance/invalid-range cases verify fallback and cursor recovery.

Real charts compare complete drawing commands with neither shortcut, with only
the earlier endpoint shortcut and with both enabled. Existing tests cover mutation
between draws, both axes, reversed scales, curved/stepped sources and custom
dataset interpolation callbacks. Public export checks confirm no new API leaks.
The focused pure tests pass on VM, dart2js and dart2wasm.

## Final verification

All checks pass: workspace tests (10,575, 87 skipped), full web suite
(7,900 chart-port and 110 test-utils tests, four skips), upstream case coverage
(958 passed, 78 skipped), fixtures (628 passed, 39 skipped), formatting, fatal-info
analysis and all seven port checks. Parity is regenerated. `validation.json`
records the commands. The final working library matches all five measured source
hashes. The implementation is retained with the bounded Android validation above.

## Evidence and reproduction

- `protocol.md`: protocol written before release timing.
- `metadata.json`: pinned baseline, device versions and candidate source hashes.
- `candidate.patch`: exact five-file library patch used in the APK, without
  unrelated working-tree changes.
- `measurements.json.gz`: all four process records, APK hashes, per-cell results
  and before/after battery/thermal state.
- `summary.json`: unrounded aggregates and individual process values.
- `profile-A.json.gz`, `profile-A.log`: original baseline CPU samples and workload.
- `main_gap.dart.txt`, `pubspec.lock`: measured harness and dependency lock.

Recompute the table:

```sh
python3 packages/flutter_chartjs_port/doc/benchmarks/boundary-segment-search/report.py
```

Reconstruct both sources and run with the pinned Flutter SDK:

```sh
python3 packages/flutter_chartjs_port/doc/benchmarks/boundary-segment-search/setup.py \
  --repo "$PWD" --out /tmp/gap-segment-repro
cd /tmp/gap-segment-repro
python3 build.py A B
python3 run_android.py A B B A
```

The runner uses the recorded phone serial and the separate app ID
`dev.artflutter.gap_fill_bench`. It requires all ten rows and the completion
marker, retains run metadata and enforces a 34 °C start temperature ceiling.
All five reconstructed candidate files were verified against measured source hashes.

For profiling, build A with `flutter build apk --profile --target-platform
android-arm64 -t lib/main_gap.dart --dart-define=PROFILE=true` in `A/app`, set
`DART_PACKAGES` to the repository's absolute `.dart_tool/package_config.json`,
then run `python3 profile.py A`. The harness waits 15 seconds and uses 1 s warmup
plus 30 batches of 500 ms. Keep profile timings separate from release comparisons.
