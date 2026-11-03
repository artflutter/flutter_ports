# Production incremental data update evidence

This measures Chart.updateData, not the earlier geometry-only experiment. The
normal parser, metadata/stacks, controller geometry, approved hooks and event
replay remain live. The baseline source includes the local ADR 0073 sorted-value
scan; metadata.json identifies the library source hashes.

## Reproduction

Use the supporting probe from ../bar-native/ in `.dart_tool/bar_update/`. Copy
`probe.dart.txt` here to `.dart_tool/data_update/probe.dart`. Build from the gallery:

```
flutter build macos --profile -t ../../.dart_tool/data_update/probe.dart --dart-define=SECONDS=25
```

Copy the app to `/tmp/chart-data-update.app`; sign only the temporary copy with
the entitlement recipe in ../category-layout/README.md. `measure.py.txt` runs
forward/reverse cases. The fixed-range line/scatter scenes use a sorted fixed
x index and explicit x bounds, preserving valid prepared-data semantics. Their
original suggested-bound scenes are fallback controls, not incremental cases.
Both sides include identical simulation and data writes in their timed frames.

`candidate.patch` is relative to 3d10094 and includes the prior sorted scan.
Install `data_update.dart.txt` and `bar_sorted_values.dart.txt` at their core
paths too. The patch includes only relevant library/gallery source, not the
unrelated gallery design work. Full-call CPU sums update/draw/record-completion
medians per process, then averages the two runs. No tests/builds run alongside
measurement. Raw final data is measurements.json.gz; summary.json records parts,
paired gains and activation/reference checks.

## Decisions and results

At 20k, numeric bars improve 19.883 → 15.550ms (21.8%), passing the 15% gate in
both pairs (20.6%, 22.9%). Prepared-map bars improve 28.212 → 15.111ms (46.4%).
At 1k, line improves 43.8%, scatter 33.1%, radar 25.0%, bar 22.8%, bubble/polar
area about 10.9%, pie 4.3%, and doughnut 3.2%. No result is generalized to all
configurations: ranges/settings must meet the documented partial-lifecycle
contract. Every final incremental case reports zero fallback calls, and complete
parsed data, geometry and selected styles match a subsequent full update of the
same current data. These are CPU timings, not FPS or raster timings.

Full-update A/B/B/A controls against `/tmp/bar-spacing-two.app` show no repeatable
regression above both 5% and 0.1ms. All raw control rows are retained separately.

## Preliminary findings retained

The original suggested-bound line/scatter cases correctly fell back. The first
implementation rescanned each record on each call and missed narrow Map list
types in the old bulk-bar list guard. Those results include regressions and are
kept in preliminary-measurements.json.gz, with initial source snapshots. The
final explicit contract validates a source once per full generation/replacement;
only numeric values/nulls may change within existing records, with stable keys,
implementations and kinds. Native prepared arrays now reach the bulk updater.

## Foreground measurements

The initial subprocess launches and Launch Services retry ran with the desktop
locked. Their logs remain retained but excluded. After unlocking, the same app
and launcher produce active foreground runs: 43.17 → 56.29 FPS at 20k bars, on
matched 736.0×441.6/DPR2 canvases. Every activity check is true and the data path
is confirmed. The complete one-second window counts are 24 and 25; their mean
FPS values are 42.92 and 55.92.

UI/build improves 20.70 → 16.89ms, p50 20.85 → 15.95ms and p90 23.09 → 19.68ms.
Raster is 12.77 → 13.13ms. This is not steady 60 FPS. Raw windows, summaries and
monitor results are retained in `foreground-unlocked.json` and corresponding
logs. `stress_unlocked.py.txt` preserves the launcher without overwriting prior
invalid results. These are local single-process measurements, not cross-device
guarantees.

## Validation

The targeted VM/browser twins cover all chart types, metadata, stacks, hover,
hits, tooltips, typed/native buffers, prepared records, source replacement,
static bounds and fonts/size/visibility invalidation, cancellation/errors,
custom-component fallback and compatible hooks. The temporary browser probe
is removed before repository import checks. No golden files are rewritten.

Final validation passes 10,812 workspace tests, 39 targeted tests per browser
backend, full web suites (4,000 Chart.js + 55 utility tests per backend), 26
fixture files, public API, analysis, formatting, parity and port checks. See
validation.json and compressed logs. Final library hashes match the measured
source. No golden files changed.
