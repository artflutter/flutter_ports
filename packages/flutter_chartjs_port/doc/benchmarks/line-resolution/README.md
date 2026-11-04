# Native line resolver and context sources

2026-11-04. [ADR 0082](../../adr/0082-native-line-resolution.md).
Baseline: the working tree after ADR 0081, including earlier uncommitted changes.
Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7, profile AOT,
Impeller MetalSDF. Gains here are additional to the preceding passes.

## Refreshed profile

A fresh 12-second diagnostic capture contains 6,793 CPU samples. Element-option
resolution appears in 58.4% of sampled stacks, context refresh in 8.7%, and
Chart.draw in 20.2%. Inclusive shares overlap and must not be added. The raw
profile and a summary are retained.

Allocation-profile responses were also captured. For all 3,016 class entries,
the VM returned accumulated counters equal to current counters. We therefore
report these as heap snapshots, **not** per-frame allocation rates or total
allocations over the interval. PointOptions, lists and closures are visible
allocation targets; the implementation removes repeated lookup/factory work,
but no numerical allocation-reduction claim is inferred from those snapshots.

## Estimation

An isolated build measures baseline, scope-only, context-only and both variants.
A separate clean baseline exposes instrumentation overhead. Order: clean A1,
prototype B1, prototype B2 with variant order reversed, clean A2. Each CPU cell
uses 700 ms warmup and seven calibrated batches of about 160 ms.

20k scriptable line, full CPU milliseconds averaged over two process medians:

| Variant | Disconnected ms | Connected ms |
| --- | ---: | ---: |
| clean baseline | 26.65 | 28.44 |
| instrumented baseline | 26.41 | 28.21 |
| scope | 18.54 | 21.02 |
| context | 25.94 | 28.65 |
| both | 17.37 | 20.65 |

Scope reuse provides most of the gain. Context reuse alone does not materially
improve the scriptable workload, but helps indexed colors. The combined estimate
is evaluated directly rather than adding percentages. An isolated static-line
draw outlier is retained in the raw data; production controls are measured again.

Full CPU is update + draw + paint-end component medians, not a combined-call
percentile. Data movement is outside these CPU stopwatches. Profiling, builds
and tests are kept separate from timing runs.

## Implemented scope and guards

After two ordinary resolutions, an eligible mode-none line loop may retain its
warmed point-color resolver and native source references. It checks cache
priority, class/id/index, chart config/data identity, native root/data/dataset/
source/options references, default containers/routes, immutable key snapshot and
cache generation before each scriptable use. A failed check ends that loop's
reuse. Clear/reset operations invalidate the generation; callbacks still run and
returned options remain fresh.

The first implementation is limited to SDK Map configuration roots, native
source lists, native chart/controller behavior and the existing numeric line
loop constraints. Typed roots, custom containers and unsupported geometry retain
the ordinary path. Indexed/scriptable numeric options retain their prior paths.

An alternative context reader is admitted only after native resolver checks
establish an effect-free window, or within the existing guarded indexed loop.
It reads the current metadata element, checks captured native arrays and an
existing native context, then performs the original six setters in order. Live
list items, missing contexts, custom points, changed parsed arrays and reentrant
controller cache entries keep their original behavior. An ordinary resolver
fallback uses the ordinary context factory. No user-provided getter is bypassed
merely because it was pure in an earlier call.

The production build contains no experiment switches. No data sampling,
callback-result memoization, geometry changes or rendering substitutions were
introduced.

## Production CPU comparisons

A1/B1/B2/A2, 800×480/DPR1. Line uses 20,000 items; scatter/bar controls use 5,000.
Each process uses the same warmup/batch protocol. Negative reduction means slower.

| Type / items | Colors | Connected | Before ms | After ms | Reduction |
| --- | --- | --- | ---: | ---: | ---: |
| line / 20000 | static | off | 6.83 | 6.85 | -0.3% |
| line / 20000 | static | on | 8.90 | 9.18 | -3.2% |
| line / 20000 | indexed | off | 16.87 | 14.39 | 14.7% |
| line / 20000 | indexed | on | 20.22 | 18.12 | 10.4% |
| line / 20000 | scriptable | off | 32.48 | 20.60 | 36.6% |
| line / 20000 | scriptable | on | 34.21 | 25.47 | 25.5% |
| scatter / 5000 | static | off | 2.47 | 2.36 | 4.3% |
| scatter / 5000 | indexed | off | 5.34 | 5.24 | 1.9% |
| scatter / 5000 | scriptable | off | 14.77 | 15.11 | -2.3% |
| bar / 5000 | static | off | 4.96 | 4.73 | 4.6% |
| bar / 5000 | indexed | off | 6.17 | 6.02 | 2.5% |
| bar / 5000 | scriptable | off | 13.59 | 13.19 | 3.0% |

Individual runs, component costs and paired reductions are retained. Static,
indexed and non-line controls are shown in full; small fluctuations are not
presented as improvements attributable to this change.

## Matched frame comparisons

Each build runs 16 cases: full/data-only × indexed/scriptable × connections
off/on × 0/200 labels, at 20,000 items. The ordinary StressDemo uses a
1036×520/DPR2 chart in a temporary 1100×900 window. Each case runs eight seconds;
readouts from the first two seconds are excluded. Runs reject missing rows,
changed dimensions, fewer than four readouts or fewer than 25 captured timings.
Caffeinate holds the display awake only during measurement.

| Operation | Colors | Connected | Labels | FPS before → after | UI p90 before → after ms |
| --- | --- | --- | ---: | ---: | ---: |
| update | indexed | off | 0 | 55.6 → 60.0 | 18.29 → 16.15 |
| update | indexed | off | 200 | 59.1 → 59.4 | 17.42 → 17.38 |
| update | indexed | on | 0 | 52.0 → 45.3 | 20.90 → 24.22 |
| update | indexed | on | 200 | 50.5 → 50.4 | 21.16 → 21.43 |
| update | scriptable | off | 0 | 30.3 → 42.9 | 32.60 → 26.24 |
| update | scriptable | off | 200 | 29.1 → 40.2 | 34.99 → 27.77 |
| update | scriptable | on | 0 | 29.7 → 33.5 | 33.19 → 30.70 |
| update | scriptable | on | 200 | 29.3 → 34.0 | 34.41 → 30.59 |
| data | indexed | off | 0 | 57.4 → 59.4 | 18.08 → 17.55 |
| data | indexed | off | 200 | 56.8 → 57.9 | 18.35 → 18.48 |
| data | indexed | on | 0 | 48.7 → 51.5 | 22.06 → 21.55 |
| data | indexed | on | 200 | 45.2 → 48.2 | 23.21 → 22.68 |
| data | scriptable | off | 0 | 30.1 → 41.5 | 32.12 → 26.63 |
| data | scriptable | off | 200 | 28.7 → 44.3 | 35.88 → 25.90 |
| data | scriptable | on | 0 | 28.5 → 35.7 | 34.88 → 28.69 |
| data | scriptable | on | 200 | 28.4 → 35.5 | 36.12 → 29.27 |

FPS is the mean of readouts; UI p90 is calculated from captured post-warmup
FrameTimings, which may omit late timing batches. These short local runs are not
sustained or cross-device FPS guarantees. Data-only selects full-update fallback
in these scenes. This pass focuses on the changed update paths; it does not
repeat the earlier 96-cell redraw/animation matrix.

## Result and remaining budget

Production scriptable full CPU improves 36.6% without connections and 25.5% with
connections in these runs. Indexed full CPU improves 14.7% and 10.4%. Absolute
costs vary across processes, so the raw pairs and controls remain part of the
result. Static connected line averages 3.2% slower, with mixed paired changes;
no improvement is claimed for static/non-line controls.

Scriptable frame results rise from roughly 29–30 FPS to about 40–44 without
connections and 34–36 with connections, depending on operation/labels. The
original connected indexed full-update cell without labels measured 52 → 45 FPS.
A separate ten-second A/B/B/A repeat measured baseline 47.9/50.4 and production
50.5/54.2 FPS. Both the original and repeat are retained; this is not an
unconditional per-cell FPS improvement.

The final diagnostic profile has 5,198 samples. Ordinary
DatasetController._resolveElementOptions appears in 0.8% of stacks, versus 58.4%
in the baseline. Prepared Config resolution appears in 34.8%, Chart.draw in
26.8%, source validation in 5.3%, and the native context reader in 4.2%. These
inclusive percentages overlap and do not directly measure saved milliseconds.

**60 FPS in every mode remains unmet.** Worst scriptable full-update UI p90 in
this matrix is about 30.7 ms. The remaining prepared-option work, final objects,
geometry and drawing still exceed a 16.67 ms budget in those cases.

## Validation

- 10,988 workspace VM tests passed; 61 focused tests passed.
- 168 focused tests passed on each of JavaScript and WebAssembly.
- Workspace analysis, formatting, parity generation and all seven port checks
  passed. Runtime source hashes match the isolated measured production build.
- New native/ordinary twins cover source replacement and live values, options
  replacement, clear/reset, default keys and routes, custom parsed-list reads,
  replaced elements, nested cached-result precedence, exceptions and context-key
  reinsertion. Pure tests cover guard invalidation and context fallback without
  speculative custom indexing or partial writes.

No full browser, fixture, golden or mobile suite was run. The exact validation
scope and compressed logs are retained.

## Artifacts and reproduction

Use isolated workspace copies and the pinned lockfile/Flutter SDK. Avoid the
shared gallery build directory.

1. baseline-overlay.patch reverses only this pass's five runtime files from the
   delivered tree. Earlier ADRs remain in the baseline.
2. estimate.patch applies the prototype on that baseline. Restore the saved
   resolution_experiment.dart.txt under lib/src/core/ in the isolated package;
   this switch module is for the prototype only.
3. Restore estimate_probe.dart.txt or production_probe.dart.txt as
   .dart_tool/line_resolution/probe.dart. The clean baseline uses
   baseline_probe.dart.txt without optimization switches in its library code.
4. Use the saved temporary MainFlutterWindow.swift.txt in the isolated copies
   for a stable frame viewport. From apps/chartjs_gallery, build with:
   `flutter build macos --profile --no-pub --target ../../.dart_tool/line_resolution/probe.dart`.
5. Save the apps as /tmp/line-resolution-baseline.app,
   /tmp/line-resolution-estimate.app and /tmp/line-resolution-production.app.
   Sign only these temporary copies using the
   [category-layout recipe](../category-layout/README.md).
6. Restore the saved runners under .dart_tool/line_resolution without .txt.
   Run with `caffeinate -diu python3 <runner>` while builds/tests are idle.
   Canonical results go to OUTPUT files, independent of macOS log routing.

measurements.json.gz retains raw accepted rows. Separate summaries cover
estimates, production CPU comparisons and real frames. Metadata records source
and executable hashes. Profile files are diagnostic and are not used as timing
results.
