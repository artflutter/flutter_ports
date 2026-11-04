# Ordered varying colors and scalar callbacks

2026-11-04. [ADR 0083](../../adr/0083-ordered-color-resolution.md).
Baseline is the working tree after ADR 0082, including earlier uncommitted work.
Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7, native profile AOT.

## Implemented changes

The native scriptable plan stores ordered varying color operations with their
original key positions. An unchanged plan visits these operations alone. Its
static template still produces a fresh result. Invalidation resumes ordinary
resolution at the next original key, including intervening static fields.

Exactly-one-argument callbacks use a separate scalar loop. The views and
per-point descriptor setup live in the continuation paths for non-scalar
results and invalidation. A non-scalar value enters the original post-call
processing without restarting its primary callback invocation. Descriptor inputs
retain the original cached references; contextual views remain fresh. Options-
aware and this-aware callbacks retain ordinary contextual invocation.

The production runtime change is confined to helpers.config.dart. No experiment
switches, callback-result caching, sampling or drawing changes are included.
The existing guards and context-time validation remain. Tests compare ordinary
Config twins across scalar/contextual callbacks and mutation behavior.

## Production CPU measurements

A1/B1/B2/A2, 800×480/DPR1, line 20k and scatter/bar controls 5k. Each cell uses
700 ms warmup and seven calibrated batches around 160 ms. Full CPU is the sum
of update, draw and paint-end component medians, averaged across two processes;
it is not a combined-call percentile or measured frame time. Data generation
is outside the stopwatches. Builds and tests were idle during measurements.

| Type / items | Colors | Connected | Before ms | After ms | Reduction |
| --- | --- | --- | ---: | ---: | ---: |
| line / 20000 | static | off | 5.01 | 5.06 | -0.9% |
| line / 20000 | static | on | 6.70 | 6.78 | -1.1% |
| line / 20000 | indexed | off | 12.23 | 12.08 | 1.2% |
| line / 20000 | indexed | on | 13.79 | 13.98 | -1.4% |
| line / 20000 | scriptable | off | 16.33 | 12.77 | 21.8% |
| line / 20000 | scriptable | on | 18.31 | 15.14 | 17.3% |
| scatter / 5000 | static | off | 2.02 | 1.99 | 1.4% |
| scatter / 5000 | indexed | off | 4.40 | 4.35 | 1.0% |
| scatter / 5000 | scriptable | off | 11.96 | 10.20 | 14.7% |
| bar / 5000 | static | off | 3.94 | 3.95 | -0.1% |
| bar / 5000 | indexed | off | 4.78 | 4.77 | 0.2% |
| bar / 5000 | scriptable | off | 10.47 | 9.80 | 6.4% |

Scriptable line CPU falls 21.8% without connections and 17.3% with connections.
Static/indexed line controls vary within about 1.5%; no gain is claimed there.
The shared helper also improves these scriptable scatter/bar scenes. Both paired
line reductions are positive; individual process costs and pair reductions are
in summary.json. Compare within this run: absolute costs differ from earlier
sessions and must not be used as additional cross-session speedups.

## Native frame measurements

The intended matrix was full/data-only × indexed/scriptable × connections on/off
× 0/200 labels, at 1036×520/DPR2. Each case ran eight seconds, excluding the first
two seconds. Valid rows require at least four readouts, 25 timings and the exact
canvas dimensions.

The baseline process initially delivered timings, then stopped receiving frames.
Its remaining rows were empty. A retry with four-case processes also received no
frame callbacks and failed validation. Both raw attempts are retained; neither
is used as a matched performance comparison. No production frame matrix was
completed, so this pass makes **no fresh FPS claim**. Missing callbacks are not
zero FPS, and sub-16.67 ms CPU sums do not establish 60 FPS. The follow-up [native verification](../color-verification/README.md)
now provides 96 valid production cases and 16 matched baseline cases; it confirms
scriptable improvements and that the every-mode 60 FPS target remains unmet.

## Renderer startup investigation

The separate native-circle prototype remains outside production. To investigate
the previous cold pixel discrepancy, four independent processes run baseline,
prototype, prototype, baseline. Each renders the original problematic scene six
times: DPR1, radius1, width0.5, alpha64, static colors. The first two renders have
one pixel hash and the four after a 250 ms pause have another. All four processes
have exactly the same sequence, and every atlas-command hash is identical.

Thus the cold transition occurs in the unchanged renderer too; matched baseline
and prototype startup stages have identical pixels. This clears the specific
differential concern, but does not identify the underlying engine startup cause.
It supplements the earlier 300 warmed pixel comparisons. It does not replace
production renderer integration, guard tests and native rendering validation.
Packing-center reuse remains deferred because its estimated benefit was tiny.

## Validation

- 11,021 workspace VM tests passed (including 33 new ordered-color cases).
- 195 focused tests passed on each of JavaScript and WebAssembly.
- Workspace analysis, formatting, parity generation and all seven port checks
  passed. Source hashes match the isolated production build. The baseline
  App.framework hash matches the prior ADR 0082 production evidence.
- Regressions compare callback/read order, arrays and objects, index changes,
  descriptor snapshots, middle/trailing mutations, cache clear/deletion,
  foreign-audit mutation, this receivers, thrown errors and fresh results.

No full browser, fixture, golden or mobile suite was run. The earlier redraw/
animation matrix was not repeated: this pass targets option resolution during
updates. This evidence does not establish 60 FPS in every mode.

## Reproduction and artifacts

Use isolated copies of the workspace and the pinned Flutter SDK/lockfile.
Apply baseline-overlay.patch to the delivered helper to recover this pass's
baseline. Earlier changes remain in place. Restore production_probe.dart.txt
as .dart_tool/color_resolution/probe.dart and MainFlutterWindow.swift.txt in the
isolated gallery. Build from apps/chartjs_gallery:

`flutter build macos --profile --no-pub --target ../../.dart_tool/color_resolution/probe.dart`

Copy builds to /tmp/color-resolution-baseline.app and
/tmp/color-resolution-production.app. Ad-hoc sign the temporary copies with
../category-layout/probe.entitlements for result-file output. Restore and run
production_run.py.txt under caffeinate with builds/tests idle. The runner uses
OUTPUT files rather than relying on native stdout. Restore report.py.txt in
.dart_tool/color_resolution to regenerate summaries.

metadata.json records source and framework hashes; measurements.json.gz retains
all valid rows, and per-run .results.gz files retain raw output. Compressed logs
record validation and rejected runs, if any. cold-start.json and the cold probe/
runner retain the startup diagnostic. Its renderer source is the runtime-switch
prototype preserved in ../three-estimates, with estimateCheckPixels enabled.
