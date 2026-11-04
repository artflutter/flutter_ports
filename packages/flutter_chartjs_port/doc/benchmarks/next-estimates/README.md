# Estimates after prepared indexed styles

2026-11-03. The baseline is the current ADR 0078 implementation, including the
indexed-color bulk-bar improvement. These are **additional** wins over that
implementation. All prototypes lived in an isolated worktree; production library
source was byte-identical before and after this investigation.

## Useful planning targets

The point experiment prepares a private options template per mode/update, fills
the live indexed background color, retains fresh options and refreshes contexts.
The context experiment writes the already-present typed fields directly, avoiding
the repeated linear searches for their key names. The combined path was measured
both without input scans and with extra native-input validation work.

With **one full input/element scan per steady-state update**:

| Indexed case | N | Current full CPU | Prototype full CPU | Reduction | Paired reductions |
| --- | ---: | ---: | ---: | ---: | ---: |
| Line | 5000 | 7.021ms | 4.160ms | 40.7% | 39.1% / 42.3% |
| Scatter | 5000 | 17.221ms | 5.400ms | 68.6% | 68.5% / 68.8% |

This is a **validation-cost target**, not a proof that one scan per update is
sufficient for arbitrary inputs. Reusing that qualification across option modes,
layout and plugin observation points needs a production correctness argument.
A native loop or a trusted source contract must make that reuse safe. These
figures should not be promised for configurations that require repeated scans.

The scan invokes the existing `dataUpdateValues(prepared: true)` validator, then
checks every element's exact native point class, active flag and context index
presence. It reads current values rather than assuming stable list contents.
The one-scan variant remembers this qualification across modes until configure;
two scans occur during initial construction, then exactly one per timed update.
This is only a model of validation cost: it does not establish every resolver,
callback, scale, route or context-mutation guard needed in production.

## Why validation cost matters

The first matrix, without these scans, gives these optimistic controlled-case
results. All use 5000 items and full-call CPU:

| Indexed case / experiment | Current → prototype | Reduction |
| --- | ---: | ---: |
| Line / prepared points | 7.111 → 2.923ms | 58.9% |
| Line / prepared points + context writes | 7.111 → 2.546ms | 64.2% |
| Scatter / prepared points | 17.474 → 4.923ms | 71.8% |
| Scatter / prepared points + context writes | 17.474 → 3.691ms | 78.9% |

Scatter also resolves every point's options in its overflow calculation. The
simple color callback runs 15001 times per update for this 5000-point scatter
scene, versus 5006 for line. The prototypes retain those callback counts.

A separate repeat measured **four full scans per update**, two for each prepared
default/none mode. That added approximately 7.1ms to both combined prototypes:

| Indexed case | Current → four-scan prototype | Reduction |
| --- | ---: | ---: |
| Line | 7.196 → 9.563ms | **-32.9%** (slower) |
| Scatter | 17.388 → 10.665ms | 38.7% |

The no-scan controls in that same repeat were 2.423ms and 3.559ms. The scan costs
are measured, not inferred by subtracting percentages from unrelated runs.
Avoid designing a fast path that repeatedly validates the whole dataset merely
to qualify each option-resolution pass.

## Contexts and drawing

Context refresh alone reduced full CPU by 4.3% for indexed line, 5.5% for indexed
scatter and 3.9% for indexed bars at N=5000. This is a smaller opportunity than
prepared point loops. Production code must still preserve creation/deletion of
context keys, key order and the observation order of effectful raw-data reads.

The drawing experiment defers intermediate native bar current-path bookkeeping
until a state/path boundary. It keeps actual canvas draw calls and paint inputs.
All tested pixels and final paths match, but this is not a complete generic
canvas implementation: other path consumers, callbacks and transformations need
proper flushing rules before it could ship.

| Indexed bar experiment | N | Current → prototype full CPU | Reduction | Paired reductions |
| --- | ---: | ---: | ---: | ---: |
| Path bookkeeping only | 5000 | 5.364 → 5.377ms | -0.2% | -5.9% / 5.2% |
| Context + path bookkeeping | 5000 | 5.364 → 4.810ms | 10.3% | 3.7% / 16.6% |
| Context only | 20000 | 27.074 → 27.342ms | -1.0% | -6.3% / 4.1% |
| Path bookkeeping only | 20000 | 27.074 → 26.794ms | 1.0% | -0.6% / 2.5% |
| Context + path bookkeeping | 20000 | 27.074 → 25.782ms | 4.8% | -0.9% / 10.2% |

Drawing-only gains are not dependable. Dense-bar pairs disagree, and the
instrumented mode-0 dense-bar control itself is 4.7% slower than production.
Do not budget a reliable additional 20000-bar gain from these results. The
5000-bar combination is positive in both pairs but variable; do not treat its
10.3% mean as a stable production estimate.

Static and scriptable controls are in summary.json. Mode-0 means at N=5000 are
within 2% of production. The static scatter combined control regresses 2.7%;
callback line/scatter improvements disagree between pairs. None are discarded.

## Fresh profiles

Ten-second captures from the current production binary show these inclusive
sample shares:

- Line N=5000: option resolution 64.9%, context refresh 13.7%, key claims 7.0%.
- Scatter N=5000: option resolution 81.2%, context refresh 17.0%, key claims 8.2%.
- Bar N=20000: context refresh 18.1%, key claims 9.7%, native drawRect 21.1%,
  native drawPicture 10.9%, and current-path rectangle construction 3.2%.

Inclusive shares overlap and include data simulation outside the timed phases.
They are not allocation percentages or exact full-call time fractions. Much of
the remaining bar drawing cost is already in native canvas calls, which the
path-bookkeeping experiment does not eliminate.

## Protocol, checks and limits

Native macOS profile AOT, Flutter 3.47.8/Dart 3.13.7, 800×480 DPR1, changing data.
Each matrix runs A1/B1/B2/A2 with reversed case order in B2/A2, 800ms warmup and
seven 200ms batches. No builds or tests run concurrently with timing. Full CPU
sums update/draw/paint-end medians per process, then averages two processes; it
is not a full-call percentile. Simulation and validation are outside the timers.

There are **104 timing cells and 76 candidate differential checks**. After each
candidate case, mode 0 updates the same current data and chart. The comparisons
cover parsed data, selected geometry, complete element options, selected context
fields and key order, final current-path bounds/metrics, and exact RGBA pixels.
Every comparison passed. Callback counts and prototype activation counters are
checked. The scan counters establish one or four scans per steady-state update.

The point prototype assumes only backgroundColor varies and all other style
fields are static. It does not preserve arbitrary callbacks, mutation between
resolution sites or custom component behavior. The context prototype assumes
its refreshed fields already exist. The preflight experiments do not close
those semantic gaps. No general compatibility, mobile/web speed, allocation,
raster-time or FPS claim follows. No full regression suite was needed or run
because production library code was unchanged.

## Evidence and reproduction

- `a*/b*.json` and `dense-*`: main matrix; `summary.json`: paired/mean results.
- `guard-*`: four-scan matrix; `one-*`: one-scan matrix; `guard-summary.json`.
- `profile-*.json.gz`: raw samples; summary companions retain function counts.
- `validation.json`: check counts and outcomes; compressed logs retain output.
- `metadata.json`: baseline patch, binary hashes, toolchain, flags and protocol.
- `baseline.patch`: current production changes over ba58aa8. The prototype
  patches include that baseline and show each experimental stage against HEAD.

Create a detached checkout at ba58aa8 and apply baseline.patch. Restore the
saved baseline probe as `.dart_tool/next_estimates/probe.dart`, build from
`apps/chartjs_gallery`, and save the app as `/tmp/prepared-options-b.app`:

```
flutter build macos --profile --no-pub -t ../../.dart_tool/next_estimates/probe.dart
```

Restore patch.py.txt as `.dart_tool/next_estimates/patch.py` and run it from the
checkout root. It creates next_estimate.dart and patches the library. Restore
main-probe.dart.txt as the probe, build, and save `/tmp/next-estimates-b.app`.
Apply preflight.py.txt next; it patches the probe too. Build and save
`/tmp/next-estimates-preflight.app`. Then apply one_scan.py.txt, build and save
`/tmp/next-estimates-one-scan.app`. The saved stage probes/patches permit inspection
without executing the patch scripts. Sign only the temporary copies using the
[category-layout recipe](../category-layout/README.md).

Restore the runner/reporter/capture files into `.dart_tool/next_estimates/` without
their `.txt` suffixes. With tests and builds idle, from the main checkout:

```
python3 .dart_tool/next_estimates/profile.py
python3 .dart_tool/next_estimates/run.py
python3 .dart_tool/next_estimates/report.py
python3 .dart_tool/next_estimates/guard_run.py
python3 .dart_tool/next_estimates/one_run.py
python3 .dart_tool/next_estimates/guard_report.py
```

The runners write to `.dart_tool/next_estimates`. Profile collection waits five
seconds after VM attach, clears samples and records ten seconds. `notifies`
includes the untimed reference update; activation/callback counters precede it.
