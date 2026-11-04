# Production chunked path storage

2026-11-04. [ADR 0085](../../adr/0085-chunked-path-storage.md), following
[the buffer-growth triage](../path-growth/README.md). Native macOS profile AOT,
Apple M3 Max, Flutter 3.47.8 / Dart 3.13.7. Baseline is ADR 0084.

## Implementation

Path2D's first private compact buffer starts at 16 commands and grows to 1,024.
Later commands allocate a new chunk, retaining completed chunks without copying
them. Native replay visits complete chunks followed by the used active portion.
Short paths keep the small start. There is no count-based reservation.

Each path owns its buffers. No storage is recycled across paths. Public command
inspection and complex commands materialize one stable mutable growable list in
original order, releasing private chunks. Later appends and public/custom replay
use that list. Version/cache semantics, coordinate values, exceptions and the
original platform-specific replay behavior remain. No new public API, line
algorithm, option callback, data-only guard or native drawing operation changes.
The only production runtime change is canvas.dart.

## Correctness validation

- 11,060 workspace VM tests passed. The focused canvas/path run passed 84 tests.
- Full browser suites passed: 4,151 port tests plus 55 test-utils tests on each
  of JavaScript and WebAssembly (4,206 per backend).
- Formatting, analysis, spec-case coverage, fixture validation, regenerated
  parity and all seven port checks passed.
- All 300 final native baseline/candidate RGBA comparisons are identical.
  They cover DPR1/2, transformed/indexed/translucent circles, clipping, dashes,
  open/closed/mixed/exposed paths, mutation and 20k-segment lines.
- New tests cover empty/small paths, growth and exact chunk boundaries through
  50k commands, retained old paths, later exposure/clearing, mixed commands and
  native conversion/cache behavior. Existing signed-zero, non-finite and custom
  replay regressions remain in place.

No golden files were updated on macOS; the platform-pinned golden suite and
mobile suites were not run.

## Native timing protocol and displays

The completed matrix and fresh matched comparisons run on the built-in Retina
display (ID 1, maximum refresh 120 Hz, DPR2), selected by the user to keep the
Studio Display free. The temporary window is anchored at 1100×900 with an exact
1036×520 chart viewport. Screen, resize and visibility logs are checked for every
accepted process. Actual presentation cadence may vary up to 120 Hz; 60-FPS
assessment uses measured rates and the 16.67 ms UI/raster budget, not the display's
maximum rate alone. No system refresh settings are changed.

Earlier Studio Display measurements (ID 5, fixed 60 Hz) remain separately in
studio-summary.json. Those eight repeats and eighteen controls are not combined
with built-in-display means. An off-display attempt and a minimized matrix group
remain rejected and archived. Both displays use identical baseline/production
Dart binaries; moving the benchmark changed only its host environment.

The completed production matrix covers 20k line items in 96 cells: four
operations × three color modes × connections off/on × 0/50/200 static labels
(72), plus 200 rotating labels (24). Cases run six seconds with two seconds
excluded as warmup. Fresh heavy-case repeats run twelve seconds in A/B/B/A order.
All 104 built-in-display ordinary rows have at least eight readouts and 195
captured timings, totaling 43,545 timings. Builds, tests and profiling are idle
during these ordinary measurements.

Mean UI averages post-warmup readouts. P90 uses delivered FrameTimings; late
batches can be absent at boundaries. Process means and p90s are not pooled into
one percentile. These are short local profile results, not sustained or cross-
device guarantees.

## Result

**The implementation improves the measured workload, but every-mode 60 FPS is
not achieved.** On the built-in display, heavy scriptable full-update mean UI
falls **15.94→14.64 ms (8.1%)**; UI p90 falls from **17.69–18.06 to 15.43–15.71 ms**.
Animation mean UI changes **8.00→7.83 ms (2.1%)**, a modest improvement.

The complete matrix has redraw around 120 FPS and animation around 115–120 FPS.
Full updates range about 57–120 FPS; data-only requests about 52–120 FPS. All
data-only cells still use full-update fallback. Seven cells exceed a 16.67 ms
UI p90, and one additional cell has mean FPS below 59 despite UI p90 fitting.
Thus 88/96 meet the report's near-60 screen (mean FPS ≥59 and both UI/raster p90
≤16.67 ms); that screen is not a sustained-60 guarantee.

The slowest observed cell is connected scriptable data-only fallback with 200
static labels: 51.9 FPS, UI p90 17.66 ms. The worst raster p90 across the matrix
is below 2.46 ms. The remaining measured constraint is UI work.

## Fresh heavy-case repeats: built-in display

A means baseline; B means production. Both cases use connected scriptable points
and 200 rotating labels.

| Operation | Run | Mean UI ms | UI p90 ms | FPS |
| --- | --- | ---: | ---: | ---: |
| update | a1 | 15.81 | 17.69 | 56.4 |
| update | b1 | 14.65 | 15.71 | 59.9 |
| update | b2 | 14.64 | 15.43 | 59.8 |
| update | a2 | 16.07 | 18.06 | 56.2 |
| animate | a1 | 8.14 | 9.22 | 113.8 |
| animate | b1 | 7.86 | 8.55 | 118.5 |
| animate | b2 | 7.80 | 8.35 | 119.1 |
| animate | a2 | 7.86 | 8.98 | 117.2 |

## Production mode matrix: built-in display

| Labels | Operation | Cases | FPS range | Worst UI p90 ms | Worst raster p90 ms |
| --- | --- | ---: | ---: | ---: | ---: |
| 0/50/200 static | draw | 18 | 120.0–120.0 | 5.38 | 2.41 |
| 0/50/200 static | update | 18 | 56.7–120.0 | 17.66 | 2.35 |
| 0/50/200 static | data | 18 | 51.9–120.0 | 17.66 | 2.39 |
| 0/50/200 static | animate | 18 | 115.5–120.0 | 8.96 | 2.40 |
| 200 rotating | draw | 6 | 120.0–120.0 | 5.10 | 2.27 |
| 200 rotating | update | 6 | 59.0–120.0 | 16.48 | 2.30 |
| 200 rotating | data | 6 | 56.7–120.0 | 17.07 | 2.46 |
| 200 rotating | animate | 6 | 117.5–120.0 | 8.55 | 2.45 |

The full per-cell rows and worst cases are in builtin/summary.json. Original
Studio Display rows remain separate; neither run is substituted for the other.

## Earlier shape/color controls: Studio Display

| Control | Operation | Baseline mean UI ms | Production mean UI ms | Baseline → production UI p90 ms |
| --- | --- | ---: | ---: | ---: |
| small | update | 1.30 | 1.37 | 1.76 → 2.21 |
| sparse | update | 9.46 | 9.55 | 10.91 → 11.01 |
| curved | update | 17.41 | 17.51 | 20.62 → 20.90 |
| stepped | update | 15.66 | 15.05 | 17.69 → 15.91 |
| observed | update | 15.60 | 15.44 | 18.64 → 17.97 |
| static | update | 7.52 | 7.52 | 7.93 → 7.86 |
| static | animate | 6.15 | 6.34 | 6.51 → 6.47 |
| indexed | update | 15.51 | 15.29 | 16.87 → 17.27 |
| indexed | animate | 9.77 | 8.37 | 12.73 → 9.17 |

These short controls show small mixed changes for small, sparse, curved and
observed paths; no broad improvement is claimed for those cases. Stepped and
indexed animation cases improve in this comparison. The indexed-update p90
increases slightly, so the result is not an unconditional per-cell improvement.


## Production GC comparison: built-in display

Four separate captures disable CPU sampling and collect Dart/GC timeline streams
after a four-second warmup for about sixteen seconds. Complete UI Frame spans
are paired. Nested/overlapping GC-labelled intervals on that UI thread are
unioned; background-worker GC is excluded. No forced GC is requested.

| GC capture | Retained seconds / frames | Mean GC ms/frame | Slow-decile mean GC ms | UI Frame p90 ms |
| --- | ---: | ---: | ---: | ---: |
| gc-a-update | 10.62 / 577 | 3.19 | 7.69 | 18.22 |
| gc-b-update | 11.29 / 674 | 2.15 | 2.72 | 15.92 |
| gc-a-animate | 5.99 / 661 | 0.66 | 4.83 | 11.99 |
| gc-b-animate | 7.77 / 928 | 0.10 | 0.38 | 8.43 |

Bounded timeline retention differs, so the same final five seconds are also
compared in all four captures:

| Matched GC window | Seconds / frames | Mean GC ms/frame | Slow-decile mean GC ms | UI Frame p90 ms |
| --- | ---: | ---: | ---: | ---: |
| gc-a-update | 5.00 / 267 | 3.46 | 8.78 | 18.85 |
| gc-b-update | 5.00 / 297 | 2.20 | 2.92 | 16.09 |
| gc-a-animate | 5.00 / 551 | 0.68 | 4.87 | 12.11 |
| gc-b-animate | 5.00 / 595 | 0.11 | 0.46 | 8.44 |

In the equal-duration update windows, mean GC-labelled UI time falls **3.46→2.20
ms/frame (36.5%)** and slowest-decile mean GC time falls **8.78→2.92 ms**. The
full retained update traces also improve, 3.19→2.15 ms/frame. Animation GC time
falls in these captures too, but ordinary animation averages improve only
modestly; these are different measurements and must not be added or subtracted
to predict FPS.

Timeline/GC collection can affect execution. Heap accumulated counters still
equal current counters, so heap responses are snapshots, not bytes/frame or
objects/frame rates. The data supports reduced collection-related slow-frame
cost in this workload, not elimination of GC or a universal timing guarantee.

## Evidence and reproduction

metadata.json records source/framework/native-host hashes and both display
cohorts. summary.json keeps Studio and built-in results separate. builtin/
contains the accepted matrix, repeats, GC intersections, raw captures and window
logs. Earlier rejected attempts are retained. Production source hashes match the
measured candidate; verification introduced no additional runtime changes.

Use isolated workspaces with the pinned SDK/lockfile. baseline-overlay.patch
reverses only this implementation. Restore probe.dart.txt and pixels.dart.txt
under .dart_tool/path_chunks, apply shape-harness.patch only to the isolated
gallery for additional controls, and use MainFlutterWindow.swift.txt. Build both
variants from apps/chartjs_gallery with:

`flutter build macos --profile --no-pub --target ../../.dart_tool/path_chunks/probe.dart`

Copy apps to /tmp/path-chunks-baseline.app and /tmp/path-chunks-production.app,
and sign temporary copies with ../category-layout/probe.entitlements. The final
frame/GC/report scripts are preserved under builtin/ as .txt; restore their
original suffixes in .dart_tool/path_chunks/builtin. They select display 1 and
verify a 120-Hz maximum at DPR2. Another machine must select and record its own
display. Use a fresh result directory when changing binaries or protocol; the
frame runner resumes past existing accepted JSON groups. Run frames.py, then
gc_capture.py under caffeinate with builds/tests idle; analyze_gc.py and report.py
regenerate the numerical summaries. The earlier root-level scripts and summaries
are retained for the Studio cohort and original investigation.
