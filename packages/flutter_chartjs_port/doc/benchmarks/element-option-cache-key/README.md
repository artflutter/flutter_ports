# Element option cache-key reuse: Android report

Reusing the last `elementType-mode` string per controller improves unshared
scatter updates most. At N=5000 on the Pixel 8a, update CPU falls 37.7% and the
full call falls 25.8%. Bubble update CPU falls 16.1%, but its drawing portion
rises, leaving a 3.0% full-call gain. The implementation adds three private
fields and changes no option-result caching or public API.

## Method and decision

Baseline: `6197449`, the direct Flutter Color core. Flutter 3.47.8 / Dart 3.13.7,
Android 17, arm64 release, profiler off. A/B/B/A, two fresh processes per variant,
15 cells with controls first, 500 ms warmup and nine 150 ms batches per cell.
No builds or tests ran alongside timing. No run was discarded. Temperatures
were 28.2–29.5 °C; before/after thermal status was 0 for every run.

Each process value is a median across batches. A full call sums that process's
update + draw + recording-completion medians; the table then takes the median
across the two processes per variant. These are CPU times, not GPU time or FPS.
Two pairs give direction only and no confidence interval.

The prewritten protocol requires at least 5% less update CPU in both pairs for
bubble and unshared scatter at N=5000, and no repeatable full-call increase over
both 0.1 ms and 5%. **The protocol passes.** Bubble update reductions are 16.9%
and 15.3%; scatter update reductions are 39.1% and 36.2%. Full scatter calls are
26.7% and 24.8% faster; full bubble calls are 3.7% and 2.3% faster.

## Primary results

Positive percentages mean less time. N is the number of points.

| Workload | N | Update CPU, A → B ms | Saved | Full call, A → B ms | Saved |
| --- | ---: | ---: | ---: | ---: | ---: |
| Bubble update | 1000 | 1.8775 → 1.6365 | 12.8% | 4.4990 → 4.3225 | 3.9% |
| Unshared scatter update | 1000 | 1.0545 → 0.7900 | 25.1% | 1.4030 → 1.1580 | 17.5% |
| Bubble update | 5000 | 8.5060 → 7.1360 | 16.1% | 20.1270 → 19.5200 | 3.0% |
| Unshared scatter update | 5000 | 3.6850 → 2.2965 | 37.7% | 5.3965 → 4.0060 | 25.8% |

**Bubble has an offsetting draw cost.** Within its N=5000 update call, drawing
rises from 7.1655 to 7.9185 ms (+10.5%), with increases in both pairs (+9.3% and
+11.7%). Recording completion is nearly unchanged. The full call is still faster
in both pairs. The separate bubble draw control changes by only +0.3%. No profile
establishes why the timing split changes, and no geometry change is inferred.
This is why the report distinguishes update CPU from the full call.

## All remaining cells

The values below are full-call CPU totals, including recording completion.

| Workload | N | A → B ms | Time saved |
| --- | ---: | ---: | ---: |
| Ordinary line draw | 5000 | 1.3690 → 1.4125 | -3.2% |
| Bar draw | 1000 | 6.3815 → 6.3660 | 0.2% |
| Radar draw | 1000 | 0.7160 → 0.7240 | -1.1% |
| Bubble draw | 5000 | 10.2865 → 10.3180 | -0.3% |
| Gap fill draw | 1000 | 2.8075 → 2.8615 | -1.9% |
| Shared line update | 5000 | 2.5630 → 2.5700 | -0.3% |
| Scriptable line update | 1000 | 5.2870 → 5.1370 | 2.8% |
| Tooltip hover frame | 1000 | 1.3520 → 1.3580 | -0.4% |
| Polar-area update | 1000 | 5.8435 → 5.6120 | 4.0% |
| Radar update | 1000 | 1.8595 → 1.7530 | 5.7% |
| Bar update | 5000 | 40.6030 → 41.4315 | -2.0% |

Bar update is the largest slower full-call result: +0.8285 ms (+2.0%). Its pairs
are +4.05% (+1.655 ms) and effectively unchanged (+0.002 ms), below the combined
rejection threshold. Its update component alone increases 13.4% in one pair and
0.5% in the other. Small control differences and secondary-case variation remain
uncertain with two pairs. No cross-device or zero-regression claim is made.

## Why this candidate

The baseline profile contains 11,548 samples from bubble updates at N=5000.
`_resolveElementOptions` has 12.4% inclusive frame samples. Within that function,
String `hashCode` has 2.59% self, `_concatAll` 2.28%, and `_interpolate` 2.12%
of the whole capture. Repeated equal strings pay allocation, construction and
hashing costs. Canvas circle drawing and picture recording remain large costs.

The candidate reuses only the string. The element id is still read and converted
on every call. The original dictionary keeps joined-key collisions, configure
invalidation, sharing, cloning and scriptable callback behavior. No global flag
or result cache is introduced. ADR 0062 describes the bounded memo.

Five semantic tests passed on the unchanged baseline before implementation and
then on the candidate. They cover alternating modes/types, effectful id conversion,
joined-key collisions, changed configuration and uncached callback results. The
focused controller/reference/specification run passes 133 tests.

## Final verification

All checks pass: workspace tests (10,583 passed, 87 skipped), full Flutter
browser suites (3,950 chart-port + 55 harness tests in each compiler mode, two
existing skips per mode), upstream case coverage (958 passed, 78 skipped),
fixtures (628 passed, 39 skipped), formatting, fatal-info analysis and all seven
port checks. Parity is regenerated. `validation.json` records the commands.
The measured library hash equals the final working source; the implementation
is retained with the bounded Android validation above. The preceding native-Color
refactor was pushed as 6197449 and
GitHub CI run 41370124105 passed.

## Evidence and reproduction

- `protocol.md`: protocol written before release measurements.
- `metadata.json`: baseline, SDK/device versions and measured library hash.
- `candidate.patch`: the exact one-file library patch used in the APK.
- `measurements.json.gz`: all four process records, every component time, APK
  hashes and before/after battery and thermal state.
- `summary.json`: unrounded process values, paired differences and protocol result.
- `profile-A.json.gz`, `profile-A.log`, `profile_entry.dart.txt`: baseline profile.
- `main_cache.dart.txt`, `pubspec.lock`: measured release harness and dependencies.

Recompute the report without a device:

```sh
python3 packages/flutter_chartjs_port/doc/benchmarks/element-option-cache-key/report.py
```

Reconstruct and run using the pinned Flutter SDK:

```sh
python3 packages/flutter_chartjs_port/doc/benchmarks/element-option-cache-key/setup.py \
  --repo "$PWD" --out /tmp/element-cache-repro
cd /tmp/element-cache-repro
python3 build.py A B
python3 run_android.py A B B A
```

The runner uses the recorded phone serial and a separate app ID,
`dev.artflutter.element_cache_bench`. It requires all 15 cells and the completion
marker and enforces a 34 °C start-temperature ceiling. Reconstruction was checked
against the measured library hash. For the profile, build A with `--profile`,
`-t lib/main_profile.dart --dart-define=PROFILE=true`, set `DART_PACKAGES` to the
repository's absolute `.dart_tool/package_config.json`, and run `python3 profile.py A`.
The profile entry retains its original log markers and is separate from release
measurements. No performance tuning reruns are pooled into these figures.
