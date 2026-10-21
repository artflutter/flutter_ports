# Phase 7: the "before" figures

These are the figures of the chart path before the change of phase 7. Phase 7 replaces the gallery
controller `StressPointController` with the ported `LineController` and `ScatterController`. Use
these figures as the base for the "after" figures of phase 7.

## 1. Code and method

- **Code.** Commit `0e0ab93` (2026-10-20 23:18 +0200, "chore(flutter_chartjs): restamp headers to
  v4.5.1+7169e651"). The runs used a detached git worktree of this commit. The worktree had no
  changes, except the iPhone signing team (see below).
- **Date.** From 2026-10-20 22:59 UTC to 2026-10-21 00:49 UTC (00:59 to 02:49 CEST).
- **Method.** The method is that of `performance.md` §6 and §11.6. Each run is a fresh process of a
  profile build. Each Android APK was built with
  `flutter build apk --profile --target-platform android-arm64`, installed with `adb install -r`
  and started with `adb shell am start` after `am force-stop`. The figures come from the lines
  `BENCH {json}` and `STRESS {json}` of `adb logcat -d -s flutter:I`. The stress entry ran from a
  profile APK with the same defines as `flutter run --profile -t lib/main_stress.dart`, as in
  §11.6. The app stayed in front. Nobody touched the screen.
- **Gate (Pixel 8a).** Before each run, a script read the battery temperature
  (`adb shell dumpsys battery`) and the frequency of the big core (`cpu8`) during a busy loop of 3 s
  on that core. The run started when the battery was at 33.0 °C or less and the big core was at
  2.8 GHz or more, or after 10 minutes of wait. During each run, a loop on the phone recorded every
  0.25 s the frequency of `cpu8`, the core of the UI thread and the frequency of that core
  (the `.freq.txt` file of each run).
- **Cells.** A benchmark cell gives the median of the run medians, in ms, and the minimum and the
  maximum of the run medians in brackets. The "case window" is the time of the case in its run.

## 2. Device state

| Device | State |
|---|---|
| Pixel 8a (`4B071JEKB17363`) | Android 17, build `google/akita/akita:17/CP3A.260905.009/16091614:user/release-keys`. On AC power, battery at 100 %. Not locked during all runs (`isKeyguardShowing=false` before and after each run). |
| iPhone 17 Pro (Home_26+, `EB0E7518-04E9-5ECB-80B0-02D8FB10E2A4`) | iOS 26.6.2. On the cable (`transportType: wired`). Not locked before and after each run (`passcodeRequired: false`). |

Battery temperature and big-core frequency at the gate, for each Pixel run:

| Run | Start (UTC) | Battery before / after (°C) | Big core in the gate (GHz) | Gate |
|---|---|---|---|---|
| benchmark, all cases, run 1 | 2026-10-20 23:33 | 34.6 / 35.2 | 2.91 | not met after 613 s (battery too hot) |
| benchmark, all cases, run 2 | 2026-10-20 23:46 | 33.8 / 34.3 | 2.91 | not met after 613 s (battery too hot) |
| benchmark, all cases, run 3 | 2026-10-20 23:59 | 33.3 / 33.9 | 2.91 | not met after 613 s (battery too hot) |
| benchmark, `CASES=axes`, run 1 | 2026-10-21 00:26 | 33.0 / 33.3 | 2.91 | met after 3 s |
| benchmark, `CASES=axes`, run 2 | 2026-10-21 00:35 | 33.0 / 33.4 | 2.91 | met after 426 s |
| benchmark, `CASES=axes`, run 3 | 2026-10-21 00:44 | 32.9 / 33.3 | 2.91 | met after 473 s |
| stress, 14 scenarios | 2026-10-21 00:11-00:26 | 32.8-33.0 / 32.8-33.1 | 2.91 | met for each scenario (see §5) |

Before the first Pixel run, the phone had a busy loop that did not stop. A stopped earlier attempt
of this measurement left it on `cpu8` (the gate loop, 49 minutes of CPU time). The loop heated the
phone to 37 °C. It was stopped, and the gate loop now stops by itself after 3 s. The figures of
the runs with that loop were deleted. All the figures below come from runs without it.

## 3. Pixel 8a: frameless benchmark, all cases

Command: `flutter build apk --profile --target-platform android-arm64 -t lib/main_bench.dart`
(all cases, `N=1000,5000,20000`, the default `BATCHES=15`, `BATCH_MS=200` and `WARMUP_MS=1000`).
3 fresh processes. Each process runs 36 cases for about 150 s.

`chart.b sharing` is case (b) with `SHARING=1`. `chart.b no-sharing` is case (b) with `SHARING=0`.
`axes.<scale> draw` is the draw case of that scale, and `axes.<scale> update` is its update case.

| Case | N | Runs | update | draw | end | layout | datasetsUpdate | datasetsDraw | ticks / rotation | Big core in the case window (GHz) | UI core in the case window (GHz) |
|---|---:|---:|---|---|---|---|---|---|---|---|---|
| chart.a | 1000 | 3 | - | 0.329 (0.327-0.337) | 0.067 (0.065-0.068) | - | - | - | - | 2.91-2.91 | 2.91-2.91 |
| chart.a | 5000 | 3 | - | 1.679 (1.664-1.689) | 0.316 (0.312-0.319) | - | - | - | - | 2.91-2.91 | 2.91-2.91 |
| chart.a | 20000 | 3 | - | 6.812 (6.795-6.842) | 2.017 (2.009-2.022) | - | - | - | - | 2.91-2.91 | 2.91-2.91 |
| chart.b sharing | 1000 | 3 | 0.162 (0.162-0.164) | 0.353 (0.351-0.359) | 0.072 (0.072-0.073) | - | - | - | - | 2.91-2.91 | 2.91-2.91 |
| chart.b sharing | 5000 | 3 | 0.533 (0.527-0.533) | 1.769 (1.763-1.783) | 0.329 (0.327-0.336) | - | - | - | - | 2.91-2.91 | 2.91-2.91 |
| chart.b sharing | 20000 | 3 | 2.059 (2.043-2.089) | 8.152 (8.128-8.241) | 2.052 (1.988-2.100) | - | - | - | - | 2.91-2.91 | 2.91-2.91 |
| chart.b no-sharing | 1000 | 3 | 0.336 (0.331-0.357) | 0.367 (0.365-0.379) | 0.072 (0.072-0.077) | - | - | - | - | 2.91-2.91 | 2.91-2.91 |
| chart.b no-sharing | 5000 | 3 | 1.395 (1.374-1.397) | 1.820 (1.802-1.833) | 0.341 (0.337-0.347) | - | - | - | - | 2.91-2.91 | 2.91-2.91 |
| chart.b no-sharing | 20000 | 3 | 5.181 (5.173-5.949) | 9.246 (8.930-9.764) | 2.080 (2.035-2.110) | - | - | - | - | 2.91-2.91 | 2.91-2.91 |
| chart.c | 1000 | 3 | 6.333 (6.292-6.337) | 1.503 (1.502-1.513) | 1.378 (1.378-1.420) | - | - | - | - | 2.91-2.91 | 2.91-2.91 |
| chart.c | 5000 | 3 | 32.658 (32.559-32.866) | 8.272 (8.245-8.373) | 5.249 (5.235-5.255) | - | - | - | - | 2.91-2.91 | 2.91-2.91 |
| chart.c | 20000 | 3 | 144.485 (142.543-145.028) | 33.094 (32.991-33.711) | 12.619 (12.440-12.653) | - | - | - | - | 2.91-2.91 | 2.91-2.91 |
| axes.linear draw | 1000 | 3 | - | 0.486 (0.485-0.509) | 0.101 (0.100-0.105) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 0.342 (0.341-0.356) | 11/0.00 | 2.91-2.91 | 2.91-2.91 |
| axes.linear draw | 5000 | 3 | - | 1.877 (1.858-2.029) | 0.387 (0.387-0.418) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 1.714 (1.691-1.844) | 11/0.00 | 2.69-2.91 | 2.69-2.91 |
| axes.linear draw | 20000 | 3 | - | 7.283 (7.220-7.777) | 2.136 (2.114-2.281) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 6.833 (6.798-7.302) | 11/0.00 | 2.69-2.91 | 2.69-2.91 |
| axes.linear update | 1000 | 3 | 0.723 (0.714-0.803) | 0.721 (0.712-0.804) | 0.113 (0.111-0.129) | 0.469 (0.461-0.515) | 0.141 (0.135-0.151) | 0.364 (0.351-0.390) | 11/0.00 | 2.36-2.91 | 2.36-2.91 |
| axes.linear update | 5000 | 3 | 1.595 (1.524-1.830) | 2.306 (2.199-2.628) | 0.426 (0.410-0.495) | 0.822 (0.787-0.954) | 0.599 (0.580-0.681) | 1.904 (1.817-2.121) | 11/0.00 | 2.25-2.91 | 2.25-2.91 |
| axes.linear update | 20000 | 3 | 4.972 (4.657-5.577) | 9.202 (8.759-10.673) | 2.338 (2.259-2.705) | 2.170 (2.037-2.534) | 2.501 (2.339-2.681) | 8.336 (7.996-9.738) | 11/0.00 | 2.15-2.91 | 2.15-2.91 |
| axes.logarithmic draw | 1000 | 3 | - | 0.604 (0.547-0.969) | 0.129 (0.118-0.225) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 0.371 (0.336-0.565) | 25/50.00 | 1.89-2.91 | 2.37-2.91 |
| axes.logarithmic draw | 5000 | 3 | - | 2.145 (1.967-3.327) | 0.443 (0.409-0.681) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 1.889 (1.721-2.847) | 25/50.00 | 1.19-2.91 | 2.36-2.91 |
| axes.logarithmic draw | 20000 | 3 | - | 8.831 (7.377-12.187) | 2.531 (2.129-3.827) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 8.227 (6.902-11.264) | 25/50.00 | 1.89-2.91 | 1.89-2.91 |
| axes.logarithmic update | 1000 | 3 | 1.212 (1.038-1.390) | 1.093 (0.935-1.254) | 0.162 (0.139-0.187) | 0.816 (0.698-0.938) | 0.241 (0.208-0.280) | 0.436 (0.367-0.500) | 25/50.00 | 1.19-2.91 | 2.15-2.91 |
| axes.logarithmic update | 5000 | 3 | 2.705 (2.219-3.249) | 3.171 (2.512-3.918) | 0.583 (0.463-0.696) | 1.356 (1.096-1.621) | 1.149 (0.939-1.342) | 2.349 (1.911-2.876) | 25/50.00 | 0.50-2.69 | 2.05-2.69 |
| axes.logarithmic update | 20000 | 3 | 8.827 (6.735-9.382) | 12.541 (9.741-15.143) | 3.282 (2.441-3.658) | 3.248 (2.489-3.402) | 5.106 (3.928-5.317) | 11.164 (8.705-13.553) | 25/50.00 | 0.50-2.69 | 1.89-2.69 |
| axes.category draw | 1000 | 3 | - | 0.911 (0.714-1.133) | 0.161 (0.125-0.210) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 0.479 (0.377-0.561) | 34/50.00 | 0.50-2.36 | 1.89-2.37 |
| axes.category draw | 5000 | 3 | - | 2.669 (2.464-3.526) | 0.527 (0.481-0.727) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 2.225 (2.065-2.800) | 34/50.00 | 0.50-2.15 | 2.15-2.37 |
| axes.category draw | 20000 | 3 | - | 9.691 (9.123-10.661) | 2.797 (2.544-3.030) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 8.862 (8.397-9.734) | 34/50.00 | 1.89-2.15 | 1.89-2.15 |
| axes.category update | 1000 | 3 | 5.791 (4.961-6.499) | 1.618 (1.340-1.815) | 0.197 (0.162-0.240) | 5.400 (4.624-5.987) | 0.209 (0.176-0.236) | 0.531 (0.443-0.546) | 34/50.00 | 0.50-2.15 | 1.89-2.37 |
| axes.category update | 5000 | 3 | 32.018 (26.746-32.541) | 4.155 (3.597-4.544) | 0.739 (0.620-0.765) | 30.652 (25.610-31.267) | 0.990 (0.901-1.005) | 2.290 (2.257-2.332) | 34/50.00 | 1.89-2.15 | 1.89-2.37 |
| axes.category update | 20000 | 3 | 144.186 (142.061-148.187) | 17.487 (15.983-17.565) | 3.207 (3.175-3.239) | 140.000 (138.062-144.539) | 3.566 (3.510-3.656) | 14.005 (13.938-15.533) | 34/50.00 | 0.88-1.89 | 1.89-2.37 |
| axes.time draw | 1000 | 3 | - | 0.841 (0.831-1.103) | 0.160 (0.157-0.217) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 0.451 (0.441-0.556) | 33/50.00 | 0.50-2.05 | 2.05-2.37 |
| axes.time draw | 5000 | 3 | - | 2.518 (2.432-3.324) | 0.514 (0.507-0.674) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 2.265 (2.186-2.884) | 14/0.00 | 1.89-2.05 | 2.05-2.37 |
| axes.time draw | 20000 | 3 | - | 9.118 (9.006-9.600) | 2.612 (2.597-2.821) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 8.422 (8.322-8.808) | 28/50.00 | 2.05-2.15 | 2.05-2.15 |
| axes.time update | 1000 | 3 | 1.378 (1.257-1.378) | 1.389 (1.272-1.411) | 0.179 (0.165-0.185) | 0.980 (0.904-0.989) | 0.180 (0.169-0.182) | 0.453 (0.433-0.479) | 33/50.00 | 2.05-2.15 | 2.05-2.15 |
| axes.time update | 5000 | 3 | 2.211 (2.018-2.782) | 2.989 (2.702-3.546) | 0.552 (0.501-0.669) | 1.188 (1.102-1.540) | 0.767 (0.716-0.908) | 2.375 (2.190-2.731) | 14/0.00 | 0.50-2.15 | 2.05-2.37 |
| axes.time update | 20000 | 3 | 6.484 (6.466-8.023) | 11.239 (11.217-14.973) | 2.748 (2.672-4.088) | 3.128 (3.090-3.789) | 2.994 (2.988-3.169) | 9.893 (9.878-13.119) | 28/50.00 | 0.50-2.15 | 2.15-2.37 |

- The `chart.*` cases ran at 2.91 GHz in all runs. From the `axes.linear` cases on, the governor
  lowered the core of the UI thread in some runs (to 2.25 GHz for the linear update). From the
  logarithmic axis on, it lowered that core to 1.9-2.4 GHz in each process: the process runs for
  more than 1 minute at full load before these cases. Thus the `axes.*` figures of this table
  include this throttle. For example, the category update at 5000 is
  32.018 ms here, and 20.378 ms in §4.
- For a comparison of the `axes.*` cases, use §4. For the `chart.*` cases, use this table.

## 4. Pixel 8a: frameless benchmark, the `axes` cases alone

Command: `flutter build apk --profile --target-platform android-arm64 -t lib/main_bench.dart
--dart-define=CASES=axes` (`N=1000,5000,20000`, the default timing). 3 fresh processes. This is
the same protocol as `performance.md` §11.6 and §11.7. These runs are not in the requested set.
They were added because of the throttle in §3.

| Case | N | Runs | update | draw | end | layout | datasetsUpdate | datasetsDraw | ticks / rotation | Big core in the case window (GHz) | UI core in the case window (GHz) |
|---|---:|---:|---|---|---|---|---|---|---|---|---|
| axes.linear draw | 1000 | 3 | - | 0.464 (0.458-0.465) | 0.096 (0.095-0.096) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 0.325 (0.320-0.326) | 11/0.00 | 2.91-2.91 | 2.91-2.91 |
| axes.linear draw | 5000 | 3 | - | 1.833 (1.811-1.841) | 0.372 (0.370-0.378) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 1.672 (1.652-1.678) | 11/0.00 | 2.91-2.91 | 2.91-2.91 |
| axes.linear draw | 20000 | 3 | - | 6.997 (6.988-7.006) | 2.012 (1.996-2.033) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 6.588 (6.575-6.603) | 11/0.00 | 2.91-2.91 | 2.91-2.91 |
| axes.linear update | 1000 | 3 | 0.705 (0.701-0.713) | 0.697 (0.695-0.706) | 0.109 (0.109-0.109) | 0.456 (0.454-0.460) | 0.132 (0.131-0.132) | 0.352 (0.346-0.354) | 11/0.00 | 2.91-2.91 | 2.91-2.91 |
| axes.linear update | 5000 | 3 | 1.501 (1.486-1.505) | 2.148 (2.139-2.160) | 0.392 (0.392-0.395) | 0.770 (0.766-0.781) | 0.570 (0.547-0.581) | 1.772 (1.754-1.779) | 11/0.00 | 2.91-2.91 | 2.91-2.91 |
| axes.linear update | 20000 | 3 | 4.598 (4.582-4.616) | 8.708 (8.555-8.717) | 2.151 (2.150-2.159) | 2.005 (1.997-2.012) | 2.318 (2.311-2.333) | 7.822 (7.791-7.983) | 11/0.00 | 2.91-2.91 | 2.91-2.91 |
| axes.logarithmic draw | 1000 | 3 | - | 0.540 (0.540-0.541) | 0.116 (0.115-0.116) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 0.331 (0.330-0.332) | 25/50.00 | 2.91-2.91 | 2.91-2.91 |
| axes.logarithmic draw | 5000 | 3 | - | 1.937 (1.927-1.943) | 0.399 (0.398-0.404) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 1.708 (1.694-1.709) | 25/50.00 | 2.91-2.91 | 2.91-2.91 |
| axes.logarithmic draw | 20000 | 3 | - | 7.177 (7.108-7.287) | 2.082 (2.066-2.086) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 6.719 (6.649-6.812) | 25/50.00 | 2.91-2.91 | 2.91-2.91 |
| axes.logarithmic update | 1000 | 3 | 0.987 (0.984-0.991) | 0.891 (0.883-0.898) | 0.130 (0.129-0.131) | 0.666 (0.662-0.666) | 0.198 (0.193-0.210) | 0.360 (0.358-0.361) | 25/50.00 | 2.91-2.91 | 2.91-2.91 |
| axes.logarithmic update | 5000 | 3 | 2.044 (2.022-2.052) | 2.373 (2.337-2.373) | 0.424 (0.424-0.428) | 1.011 (1.006-1.017) | 0.873 (0.872-0.879) | 1.788 (1.764-1.802) | 25/50.00 | 2.91-2.91 | 2.91-2.91 |
| axes.logarithmic update | 20000 | 3 | 6.108 (6.029-6.208) | 9.045 (8.925-9.045) | 2.217 (2.185-2.227) | 2.238 (2.231-2.251) | 3.529 (3.522-3.598) | 7.999 (7.971-8.069) | 25/50.00 | 2.91-2.91 | 2.91-2.91 |
| axes.category draw | 1000 | 3 | - | 0.634 (0.630-0.635) | 0.111 (0.110-0.111) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 0.332 (0.332-0.333) | 34/50.00 | 2.91-2.91 | 2.91-2.91 |
| axes.category draw | 5000 | 3 | - | 2.043 (2.031-2.049) | 0.395 (0.393-0.397) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 1.717 (1.700-1.723) | 34/50.00 | 2.91-2.91 | 2.91-2.91 |
| axes.category draw | 20000 | 3 | - | 7.520 (7.507-7.585) | 2.100 (2.081-2.116) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 6.952 (6.944-6.955) | 34/50.00 | 2.91-2.91 | 2.91-2.91 |
| axes.category update | 1000 | 3 | 4.084 (4.052-4.160) | 1.106 (1.087-1.119) | 0.130 (0.129-0.130) | 3.822 (3.786-3.862) | 0.143 (0.143-0.145) | 0.357 (0.335-0.385) | 34/50.00 | 2.91-2.91 | 2.91-2.91 |
| axes.category update | 5000 | 3 | 20.378 (20.350-20.436) | 2.722 (2.717-2.919) | 0.480 (0.477-0.489) | 19.489 (19.466-19.527) | 0.657 (0.624-0.680) | 1.739 (1.735-1.965) | 34/50.00 | 2.91-2.91 | 2.91-2.91 |
| axes.category update | 20000 | 3 | 97.440 (96.829-99.262) | 10.696 (10.615-12.253) | 2.182 (2.180-2.234) | 93.939 (92.612-96.425) | 2.444 (2.430-2.499) | 9.382 (9.124-11.019) | 34/50.00 | 2.91-2.91 | 2.91-2.91 |
| axes.time draw | 1000 | 3 | - | 0.632 (0.632-0.637) | 0.118 (0.118-0.119) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 0.339 (0.336-0.341) | 33/50.00 | 2.91-2.91 | 2.91-2.91 |
| axes.time draw | 5000 | 3 | - | 1.934 (1.933-1.945) | 0.390 (0.389-0.390) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 1.745 (1.745-1.754) | 14/0.00 | 2.91-2.91 | 2.91-2.91 |
| axes.time draw | 20000 | 3 | - | 7.437 (7.405-7.815) | 2.106 (2.092-2.206) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 6.912 (6.868-7.242) | 28/50.00 | 2.91-2.91 | 2.91-2.91 |
| axes.time update | 1000 | 3 | 1.076 (1.048-1.114) | 1.074 (1.027-1.106) | 0.134 (0.132-0.140) | 0.769 (0.749-0.801) | 0.144 (0.139-0.145) | 0.367 (0.349-0.379) | 33/50.00 | 2.69-2.91 | 2.69-2.91 |
| axes.time update | 5000 | 3 | 1.743 (1.729-1.799) | 2.366 (2.318-2.402) | 0.425 (0.424-0.441) | 0.957 (0.933-0.979) | 0.619 (0.615-0.629) | 1.891 (1.876-1.938) | 14/0.00 | 2.69-2.91 | 2.69-2.91 |
| axes.time update | 20000 | 3 | 5.597 (5.532-5.740) | 9.614 (9.548-9.881) | 2.354 (2.310-2.369) | 2.690 (2.654-2.780) | 2.574 (2.534-2.617) | 8.463 (8.354-8.716) | 28/50.00 | 2.36-2.69 | 2.36-2.69 |

- All the case windows ran at 2.91 GHz, except the update case of `axes.time` (the last case of
  each process): 2.69-2.91 GHz at 1000 and 5000, 2.36-2.69 GHz at 20000.
- The figures agree with `performance.md` §11.7, side B: the category update at 5000 is 20.378 ms
  (§11.7: 20.864 ms), and the linear update at 5000 is 1.501 ms (§11.7: 1.518 ms).

## 5. Pixel 8a: stress entry

Commands: `flutter build apk --profile --target-platform android-arm64 -t lib/main_stress.dart`
with `--dart-define=MODE=chart --dart-define=CALL=<draw|update> --dart-define=SCENARIO=<N>x0`, or
with `--dart-define=MODE=axes --dart-define=SCALE=<scale> --dart-define=CALL=<draw|update>
--dart-define=SCENARIO=5000x0`. The default `SECONDS=7`. One fresh process for each scenario. No
scenario was below 4 FPS, thus no scenario needed `SECONDS=60`.

The figures are the means of the stress line: FPS, `updateMs` (the update without its draw),
`drawMs`, `rasterMs` and `layoutMs` (mode `axes` only). The UI-core column is the median frequency
of the core of the UI thread during the run. With a light load, the governor keeps that core low
(see `performance.md` §11.6). Thus use the benchmark for the times, and the stress entry for FPS
and raster.

| Mode | Call | Scale | N | FPS | updateMs | drawMs | rasterMs | layoutMs | ticks / rotation | Battery before / after (°C) | Big core in gate (GHz) | UI core in run, median (GHz) |
|---|---|---|---:|---:|---:|---:|---:|---:|---|---|---|--- |
| chart | draw | - | 1000 | 58.02 | 0.00 | 5.53 | 5.23 | - | - | 32.9 / 32.9 | 2.91 | 0.58 |
| chart | update | - | 1000 | 59.01 | 1.33 | 3.85 | 4.66 | - | - | 32.8 / 32.8 | 2.91 | 0.58 |
| chart | draw | - | 5000 | 59.00 | 0.00 | 7.38 | 4.83 | - | - | 32.8 / 32.8 | 2.91 | 1.22 |
| chart | update | - | 5000 | 57.67 | 1.62 | 6.27 | 5.04 | - | - | 32.8 / 32.8 | 2.91 | 1.37 |
| chart | draw | - | 20000 | 56.86 | 0.00 | 12.03 | 7.72 | - | - | 32.8 / 32.9 | 2.91 | 2.91 |
| chart | update | - | 20000 | 39.52 | 2.44 | 12.14 | 9.15 | - | - | 32.8 / 33.1 | 2.91 | 2.85 |
| axes | draw | linear | 5000 | 57.69 | 0.00 | 7.80 | 4.73 | 0.00 | 6 / 0.00 | 33.0 / 33.0 | 2.91 | 1.22 |
| axes | update | linear | 5000 | 56.52 | 3.30 | 5.82 | 5.28 | 1.65 | 6 / 0.00 | 33.0 / 32.9 | 2.91 | 1.79 |
| axes | draw | logarithmic | 5000 | 57.82 | 0.00 | 7.90 | 4.45 | 0.00 | 11 / 50.00 | 32.9 / 32.9 | 2.91 | 1.11 |
| axes | update | logarithmic | 5000 | 54.23 | 3.90 | 5.75 | 5.39 | 1.91 | 11 / 50.00 | 33.0 / 33.0 | 2.91 | 1.66 |
| axes | draw | category | 5000 | 58.35 | 0.00 | 7.69 | 4.76 | 0.00 | 14 / 50.00 | 33.0 / 33.0 | 2.91 | 1.06 |
| axes | update | category | 5000 | 28.43 | 21.66 | 3.28 | 6.51 | 20.61 | 14 / 50.00 | 33.0 / 33.0 | 2.91 | 2.91 |
| axes | draw | time | 5000 | 58.03 | 0.00 | 7.92 | 4.56 | 0.00 | 14 / 50.00 | 33.0 / 33.1 | 2.91 | 1.22 |
| axes | update | time | 5000 | 54.23 | 3.48 | 6.03 | 5.26 | 1.84 | 14 / 50.00 | 33.0 / 33.0 | 2.91 | 1.75 |

- The stress host is phone-sized. Thus the x axis has 6 (linear), 11 (logarithmic) and 14
  (category, time) ticks. The benchmark chart is 800 x 480 and has more ticks.
- The mode `chart` agrees with `performance.md` §10.9 (typed, sharing on): at 5000, case (a)
  gave 58.2 FPS and a draw of 7.50 ms there, and 59.0 FPS and 7.38 ms here.

## 6. iPhone 17 Pro: frameless benchmark

Command: `flutter run --profile --device-timeout 30 -d 00008150-001870922140401C
-t lib/main_bench.dart --dart-define=N=5000` in the worktree. All cases (`chart.*` and `axes.*`)
at N=5000, the default timing. For the signing, the worktree had `DEVELOPMENT_TEAM = T5447D382T`
in `apps/chartjs_gallery/ios/Runner.xcodeproj/project.pbxproj`. After the runs, that file was
restored to the content of the commit. A watchdog of 1200 s stopped only the `flutter run` process
of the script (by its process ID). Each run gave `BENCH done` in 116 s, the build included.

There are 2 runs. Run 1 started at 2026-10-20 22:59 UTC, before the Pixel runs. Run 2 started at
2026-10-21 00:46 UTC, after the Pixel runs. The cells give the median of the 2 run medians, with
the minimum and the maximum. The iPhone has no frequency samples.

| Case | N | Runs | update | draw | end | layout | datasetsUpdate | datasetsDraw | ticks / rotation |
|---|---:|---:|---|---|---|---|---|---|---|
| chart.a | 5000 | 2 | - | 0.770 (0.756-0.785) | 0.172 (0.169-0.176) | - | - | - | - |
| chart.b sharing | 5000 | 2 | 0.238 (0.232-0.244) | 0.819 (0.807-0.831) | 0.182 (0.179-0.185) | - | - | - | - |
| chart.b no-sharing | 5000 | 2 | 0.653 (0.638-0.668) | 0.850 (0.835-0.865) | 0.187 (0.183-0.191) | - | - | - | - |
| chart.c | 5000 | 2 | 16.364 (16.089-16.639) | 2.585 (2.541-2.629) | 1.831 (1.784-1.878) | - | - | - | - |
| axes.linear draw | 5000 | 2 | - | 0.873 (0.866-0.880) | 0.215 (0.211-0.219) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 0.831 (0.825-0.838) | 11/0.00 |
| axes.linear update | 5000 | 2 | 0.719 (0.708-0.730) | 0.993 (0.978-1.009) | 0.223 (0.219-0.227) | 0.381 (0.375-0.387) | 0.283 (0.279-0.287) | 0.853 (0.839-0.867) | 11/0.00 |
| axes.logarithmic draw | 5000 | 2 | - | 0.906 (0.897-0.915) | 0.223 (0.219-0.226) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 0.845 (0.836-0.853) | 25/50.00 |
| axes.logarithmic update | 5000 | 2 | 0.996 (0.982-1.010) | 1.080 (1.066-1.094) | 0.228 (0.224-0.231) | 0.492 (0.486-0.498) | 0.447 (0.441-0.453) | 0.863 (0.851-0.874) | 25/50.00 |
| axes.category draw | 5000 | 2 | - | 0.937 (0.930-0.944) | 0.224 (0.220-0.227) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 0.849 (0.843-0.856) | 34/50.00 |
| axes.category update | 5000 | 2 | 10.228 (10.149-10.307) | 1.190 (1.177-1.203) | 0.234 (0.233-0.236) | 9.886 (9.812-9.959) | 0.287 (0.283-0.292) | 0.903 (0.893-0.912) | 34/50.00 |
| axes.time draw | 5000 | 2 | - | 0.906 (0.896-0.916) | 0.225 (0.222-0.227) | 0.000 (0.000-0.000) | 0.000 (0.000-0.000) | 0.857 (0.848-0.867) | 14/0.00 |
| axes.time update | 5000 | 2 | 0.784 (0.778-0.789) | 1.032 (1.027-1.038) | 0.231 (0.229-0.232) | 0.424 (0.422-0.426) | 0.289 (0.288-0.291) | 0.874 (0.871-0.877) | 14/0.00 |

## 7. Raw files

All raw files are in `packages/flutter_chartjs/doc/phase7/perf/before/`. Each text file has a
header with the command, the commit, the device, the start time, the gate result, the battery
after the run and the end state, then the log lines.

| File | Contents |
|---|---|
| `pixel-bench-run1.txt` to `pixel-bench-run3.txt` | §3, the benchmark with all cases. 36 `BENCH` lines each. |
| `pixel-bench-axes-run1.txt` to `pixel-bench-axes-run3.txt` | §4, the benchmark with `CASES=axes`. 24 `BENCH` lines each. |
| `pixel-stress-chart-<draw\|update>-<1000\|5000\|20000>.txt` | §5, the mode `chart`. 6 files. |
| `pixel-stress-axes-<linear\|logarithmic\|category\|time>-<draw\|update>-5000.txt` | §5, the mode `axes`. 8 files. |
| `<run file>.freq.txt` | The frequency samples of each Pixel run: epoch seconds, `cpu8` in kHz, the core of the UI thread, its frequency in kHz. |
| `iphone-bench-run1.txt`, `iphone-bench-run2.txt` | §6, the `BENCH` lines of each iPhone run. |
| `iphone-bench-run<n>.txt.flutter.log` | The full output of `flutter run` of each iPhone run. |
