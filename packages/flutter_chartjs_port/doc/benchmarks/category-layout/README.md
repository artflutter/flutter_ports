# Category layout profiling

2026-11-02; baseline `8bcbe47`; Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 /
Dart 3.13.7, arm64 profile AOT, Impeller. See performance.md §27.

The CPU capture uses the existing stress entry with `MODE=axes`,
`SCENARIO=20000x0`, `CALL=update`, `SCALE=category`, `YSCALE=logarithmic`.
`profile-before.json.gz` is the raw VM-service getCpuSamples response (the result
object). It includes startup and is diagnostic, not the timing comparison.

The timing comparison uses the existing frameless benchmark machinery, with the
exact same stress configuration, at its fixed 800 × 480 canvas. The probe runs
category/logarithmic and linear/logarithmic axes, each at N=1000/5000/20000,
with both update and draw. Each cell has 1000 ms warmup and nine 250 ms batches.
The comparison order is A1, B1, B2, A2. No builds or tests run during timing.
All process results are retained. There are two runs per variant; these are
local exploratory measurements, not a cross-platform performance guarantee.

`measurements.json.gz` contains the four unmodified process result lists, including
tick values/labels, rotation and chart bounds. `summary.json` compares their
medians. Layout outputs must agree exactly in every cell.

To reproduce the probe, copy `probe.dart.txt` to `.dart_tool/category_probe.dart`
at the repository root. From `apps/chartjs_gallery`, build with:

```
flutter build macos --profile -t ../../.dart_tool/category_probe.dart
```

Keep a separate copy of the `.app` for baseline and candidate. The probe writes
`/tmp/category-$CATEGORY_RUN.jsonl` outside the measured loops. For these
throwaway benchmark copies only, ad-hoc sign the outer app with the supplied
`probe.entitlements` (allow-jit and network.server, without the application
sandbox), so it can write that artifact:

```
codesign --force --sign - --entitlements probe.entitlements /tmp/category-a.app
CATEGORY_RUN=a1 /tmp/category-a.app/Contents/MacOS/chartjs_gallery
```

Use distinct `CATEGORY_RUN` names; the probe appends its results and exits after
12 cells. Keep the machine idle during each run. Repeat for the candidate and
then in reverse order. The app sandbox and signing of repository builds are
unchanged; only the temporary copies used for measurement are re-signed.

`validation.json` records the package, browser, fixture, analysis and port-check
results. The code adds no resolved-font cache: scriptable/indexed fonts continue
to evaluate per tick. Full layout remains O(N), including label-size work before
auto-skip; this optimization does not promise 60 FPS at N=20000.
