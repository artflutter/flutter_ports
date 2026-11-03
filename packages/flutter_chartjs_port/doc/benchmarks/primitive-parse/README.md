# Numeric/category parsing evidence

Baseline 65fc68f includes native rectangular drawing. Apply `candidate.patch`
and put `primitive_parse.dart.txt` at `lib/src/core/primitive_parse.dart`.
`metadata.json` records the complete candidate library source hashes.

Use the unchanged harness in ../bar-native/ (`probe.dart.txt`, `native.dart.txt`,
`controller.dart.txt`) in `.dart_tool/bar_update/`, then build from the gallery:

```
flutter build macos --profile -t ../../.dart_tool/bar_update/probe.dart --dart-define=SECONDS=25
```

Retain `/tmp/bar-native-final.app` as baseline and
`/tmp/primitive-parse-final.app` as candidate. Ad-hoc sign only the temporary
copies as described in ../category-layout/README.md. `measure.py.txt` runs the
A/B/B/A cases; `stress.py.txt` runs and monitors foreground update scenarios.
The protocol was recorded before measurements. No builds or tests run during
timing. Full calls sum per-process update/draw/completion medians, then aggregate
the two process results. Foreground FPS comes from a separate real frame loop.

Browser twins use a temporary copy of `test/port/core/primitive_parse_test.dart`
without its VM annotation; run `flutter test --platform chrome` on the copy,
then again with `--wasm`, and remove it before the repository import checks.

## Results

The full 20k update improves 9.7%, 21.697 → 19.582ms; both pairs pass the 8%
gate (11.3%, 8.2%). Element preparation, including parsing, falls
4.220 → 1.231ms. Update CPU falls 10.625 → 8.443ms. The layout component rises
1.171 → 1.827ms; totals include this increase. All components and controls are
in `summary.json` and every raw row in `measurements.json.gz`.

Foreground updates rise 34.92 → 39.73 FPS, average build 24.46 → 22.04ms and
raster 14.29 → 14.17ms. Both activity monitors remain true for 24 complete
windows. There is no mobile/web performance claim or claim of reaching 60 FPS.

`validation.json` and compressed logs retain the passing checks. The workspace
run also picked up the temporary browser twin: its 10,778 passing executions
include 15 duplicates (10,763 distinct tests). The final 15-test browser probe
is retained as `browser_probe.dart.txt` and was removed before final static and
port checks. No golden file changed.

## Next measured target

A fresh profile of the candidate, after nine seconds of warmup, captures 6,528
CPU samples over 10.002 seconds without concurrent builds or tests. Of the
5,510 samples inside `Chart.update`, 1,097 (19.9%) include bar ruler creation,
984 (17.9%) include minimum-spacing calculation and 424 (7.7%) include
`arrayUnique`. Parsing now appears in 483 samples (8.8%). These inclusive counts
overlap and are neither additive costs nor wall-clock measurements.

The next recommendation is to streamline bar spacing calculations. The existing
ruler projects every parsed index; minimum-spacing calculation then gathers and
deduplicates indexes, projects them again, and walks ticks. For a guarded native
single-dataset, sorted-value case, reuse the already projected pixels and replace
hash-set deduplication with a linear adjacent-value scan. Retain tick spacing,
truncated-pixel handling, signed-zero semantics and ordinary custom-scale reads.
Avoid a cross-update geometry cache unless its invalidation is separately proven.

This is an unimplemented recommendation, mainly for bar updates. No FPS gain is
claimed. Raw samples and counts are in `next-update-profile.json.gz` and
`next-profile-summary.json`; `profile_capture.py.txt` and `profile.dart.txt`
retain the capture scripts (the latter goes at `.dart_tool/bar_scan/profile.dart`).
