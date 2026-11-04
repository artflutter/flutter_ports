# Native frame verification after ADR 0083

2026-11-04. Follow-up to [the resolver implementation](../color-resolution/README.md).
Native macOS profile AOT, Apple M3 Max, Flutter 3.47.8 / Dart 3.13.7.
This pass changes benchmark infrastructure and documentation only.

## Protocol and visibility

The production matrix covers 20,000 line-chart items in 96 cases:

- Four operations: redraw, full update, data-only request and animation.
- Static, indexed and scriptable colors; connections off/on.
- 0/50/200 static overlay labels (72 cases), plus 200 rotating labels (24).

Sixteen matched baseline cases cover full/data-only × indexed/scriptable ×
connections off/on × 0/200 static labels. Baseline is the working tree after
ADR 0082; production adds ADR 0083. Both App.framework hashes match the prior
implementation evidence. No renderer prototype is included.

Every case runs eight seconds. Readouts before two seconds are excluded.
Each accepted row requires at least four readouts, 25 captured frame timings and
the exact 1036×520/DPR2 chart viewport. The native window is 1100×900. FPS is the
mean of the post-warmup stress readouts; UI/raster p90 comes from delivered
FrameTimings. Late timing batches can be absent at the case boundary. These are
short local runs, not sustained or cross-device guarantees.

An initial ordinary-window attempt received valid timings in some cases but
lost them in another. The desktop session was unlocked at inspection. Rather
than treating missing callbacks as zero FPS, the full comparison uses a temporary
floating, all-Spaces benchmark window and logs its own visibility/occlusion.
Both apps use identical native executable code (verified after stripping their
resource-dependent signatures), with their original chart frameworks preserved.
The installed gallery and production sources are unchanged. Caffeinate keeps
the display awake; builds and tests are idle during timings.

## Verdict

**60 FPS in every mode is not achieved.** The accepted matrix contains 96
production cases and 16 matched baseline cases, with 39,228 captured timings,
at least 11 readouts and at least 174 timings per case. Window logs for all 32
accepted processes show the required startup dimensions and no subsequent
recorded visibility interruption. One static data-only group was briefly
occluded and changed height; all six of its cases were rejected and replaced
by a clean repeat. The original results remain archived.

The slowest production case is scriptable data-only fallback, connected points,
200 rotating labels: 34.87 FPS, UI p90 29.123 ms and raster p90 2.899 ms. Reaching
16.67 ms requires about 12.46 ms / 42.8% less UI p90 in that case, before adding
headroom. That is a budget gap, not a forecast of one optimization's gain.
Across the entire matrix, raster p90 stays at or below 3.129 ms; UI work is the
limiting measured stage. Redraw UI p90 stays below 10.3 ms. Animation ranges
53.2–60.0 FPS with UI p90 up to 25.36 ms.

Matched scriptable full updates improve from 35.8–37.6 to 49.9–54.2 FPS without
connections, and 31.9–32.0 to 40.3–40.7 with connections. Scriptable data-only
fallback improves too. Every data-only production case uses the full-update
fallback. This supports the implemented resolver gain, not a universal 60 FPS
claim or an unconditional improvement in every case.

Observed rates exceed 60 in some redraw/static-update cases; measurements are
not capped at 60. Display scheduling and process variation affect FPS, and label
counts are not strictly monotonic across separate runs. Original control results
are retained rather than selecting favorable rows.

The largest indexed-control drop in the first comparison was the unconnected
200-label data-only request: 57.2 → 47.9 FPS. A separate 12-second A/B/B/A repeat
measured baseline 57.9/54.7 and production 53.7/55.8 FPS. All four windows passed
visibility checks. The large original drop did not reproduce; the repeat averages
are 56.3 versus 54.8 FPS (about 2.7% lower for production), with opposite signs
in the two pairs. A small regression cannot be ruled out from this sample. No
indexed performance improvement is claimed.

## All-mode results

| Labels | Operation | Cases | FPS range | Worst UI p90 ms | Worst raster p90 ms |
| --- | --- | ---: | ---: | ---: | ---: |
| 0/50/200 static | draw | 18 | 58.2–120.0 | 10.29 | 2.96 |
| 0/50/200 static | update | 18 | 35.6–118.6 | 27.66 | 3.13 |
| 0/50/200 static | data | 18 | 38.1–60.0 | 27.69 | 2.92 |
| 0/50/200 static | animate | 18 | 55.5–60.0 | 24.99 | 2.93 |
| 200 rotating | draw | 6 | 60.0–60.0 | 6.83 | 2.88 |
| 200 rotating | update | 6 | 36.4–60.0 | 28.36 | 2.94 |
| 200 rotating | data | 6 | 34.9–60.0 | 29.12 | 2.94 |
| 200 rotating | animate | 6 | 53.2–60.0 | 25.36 | 2.99 |

## Matched update comparisons

| Operation | Colors | Connected | Labels | FPS before → after | UI p90 before → after ms |
| --- | --- | --- | ---: | ---: | ---: |
| update | indexed | off | 0 | 59.2 → 58.2 | 14.90 → 16.66 |
| update | indexed | off | 200 | 56.2 → 57.8 | 17.78 → 17.32 |
| update | indexed | on | 0 | 51.6 → 47.6 | 21.04 → 22.29 |
| update | indexed | on | 200 | 46.0 → 44.6 | 22.22 → 23.05 |
| update | scriptable | off | 0 | 37.6 → 54.2 | 31.32 → 19.00 |
| update | scriptable | off | 200 | 35.8 → 49.9 | 31.36 → 20.78 |
| update | scriptable | on | 0 | 32.0 → 40.3 | 35.01 → 26.57 |
| update | scriptable | on | 200 | 31.9 → 40.7 | 34.28 → 26.32 |
| data | indexed | off | 0 | 58.8 → 54.1 | 15.67 → 18.94 |
| data | indexed | off | 200 | 57.2 → 47.9 | 17.29 → 20.23 |
| data | indexed | on | 0 | 47.5 → 42.5 | 22.19 → 24.72 |
| data | indexed | on | 200 | 41.9 → 38.2 | 25.53 → 27.69 |
| data | scriptable | off | 0 | 41.6 → 51.3 | 25.11 → 20.97 |
| data | scriptable | off | 200 | 35.9 → 46.3 | 34.30 → 22.46 |
| data | scriptable | on | 0 | 30.8 → 38.1 | 36.28 → 26.84 |
| data | scriptable | on | 200 | 30.9 → 38.4 | 35.19 → 27.02 |

The data-only request may fall back to the full update lifecycle. The raw
`dataFast` flag records the path actually taken; the requested operation alone
does not establish that the retained-layout path was used. Animation measures
the ongoing loop after setup, not a full reconstruction of 20k animations every
frame. The scriptable callbacks in this stress scene are the built-in example;
arbitrary user callback costs are outside this result.

## Evidence and reproduction

metadata.json records the source/framework hashes, native host hashes and
protocol. summary.json contains all accepted production and baseline rows,
comparisons, ranges and worst cases. measurements.json.gz preserves individual
run rows. Compressed .results, .window and .log files retain raw timings and
window visibility, including the initial failed ordinary-window attempt in a
separate archive directory. Missing or undersampled rows are rejected.

Use the preserved production_probe.dart.txt from ../color-resolution with its
pinned isolated workspace and SDK. Build the temporary MainFlutterWindow.swift.txt
host from this directory, then use its native executable for both app copies,
retaining the original baseline/production App.framework files. Sign those
temporary apps with ../category-layout/probe.entitlements. Verify their framework
hashes against metadata.json. Restore run.py.txt under .dart_tool/color_verification/
and execute it under caffeinate with the apps named
/tmp/color-verification-baseline.app and /tmp/color-verification-production.app.
The runner writes through OUTPUT and validates every row. This archived session
also runs repeat.py.txt to replace the interrupted six-case static data group,
then control_repeat.py.txt for the separate A/B/B/A control check. Restore
report.py.txt beside those scripts to rebuild summaries; it also checks all
accepted window logs. Keep the initial attempts and replaced rows as evidence.

Prior correctness validation remains 11,021 workspace VM tests, 195 focused
tests each on JavaScript and WebAssembly, analysis, formatting, parity and the
seven port checks. This verification changes no library runtime code, so those
suites were not repeated. Source hashes are checked again after measurement.

## Full production matrix

| Operation | Colors | Connected | Labels | Rotating | FPS | UI p90 ms |
| --- | --- | --- | ---: | --- | ---: | ---: |
| animate | indexed | off | 0 | False | 60.0 | 10.09 |
| animate | indexed | off | 50 | False | 60.0 | 9.74 |
| animate | indexed | off | 200 | False | 59.2 | 11.24 |
| animate | indexed | on | 0 | False | 59.1 | 21.05 |
| animate | indexed | on | 50 | False | 56.6 | 23.50 |
| animate | indexed | on | 200 | False | 55.5 | 24.99 |
| animate | scriptable | off | 0 | False | 60.0 | 10.08 |
| animate | scriptable | off | 50 | False | 60.0 | 10.48 |
| animate | scriptable | off | 200 | False | 59.1 | 11.90 |
| animate | scriptable | on | 0 | False | 59.4 | 21.76 |
| animate | scriptable | on | 50 | False | 56.2 | 19.48 |
| animate | scriptable | on | 200 | False | 56.8 | 24.68 |
| animate | static | off | 0 | False | 60.0 | 6.78 |
| animate | static | off | 50 | False | 60.0 | 7.18 |
| animate | static | off | 200 | False | 60.0 | 7.24 |
| animate | static | on | 0 | False | 59.7 | 11.54 |
| animate | static | on | 50 | False | 60.0 | 11.46 |
| animate | static | on | 200 | False | 59.5 | 17.11 |
| data | indexed | off | 0 | False | 54.1 | 18.94 |
| data | indexed | off | 50 | False | 53.0 | 19.73 |
| data | indexed | off | 200 | False | 47.9 | 20.23 |
| data | indexed | on | 0 | False | 42.5 | 24.72 |
| data | indexed | on | 50 | False | 40.8 | 26.33 |
| data | indexed | on | 200 | False | 38.2 | 27.69 |
| data | scriptable | off | 0 | False | 51.3 | 20.97 |
| data | scriptable | off | 50 | False | 56.0 | 19.35 |
| data | scriptable | off | 200 | False | 46.3 | 22.46 |
| data | scriptable | on | 0 | False | 38.1 | 26.84 |
| data | scriptable | on | 50 | False | 42.4 | 25.05 |
| data | scriptable | on | 200 | False | 38.4 | 27.02 |
| data | static | off | 0 | False | 60.0 | 9.17 |
| data | static | off | 50 | False | 60.0 | 9.81 |
| data | static | off | 200 | False | 60.0 | 10.04 |
| data | static | on | 0 | False | 59.7 | 15.94 |
| data | static | on | 50 | False | 59.8 | 16.24 |
| data | static | on | 200 | False | 60.0 | 16.89 |
| draw | indexed | off | 0 | False | 83.8 | 5.72 |
| draw | indexed | off | 50 | False | 118.2 | 5.98 |
| draw | indexed | off | 200 | False | 119.7 | 6.45 |
| draw | indexed | on | 0 | False | 119.7 | 6.24 |
| draw | indexed | on | 50 | False | 119.7 | 6.21 |
| draw | indexed | on | 200 | False | 119.7 | 7.07 |
| draw | scriptable | off | 0 | False | 58.2 | 6.16 |
| draw | scriptable | off | 50 | False | 60.0 | 7.20 |
| draw | scriptable | off | 200 | False | 59.7 | 10.29 |
| draw | scriptable | on | 0 | False | 60.0 | 5.84 |
| draw | scriptable | on | 50 | False | 60.0 | 5.99 |
| draw | scriptable | on | 200 | False | 60.0 | 6.62 |
| draw | static | off | 0 | False | 114.6 | 5.16 |
| draw | static | off | 50 | False | 120.0 | 5.18 |
| draw | static | off | 200 | False | 119.7 | 5.70 |
| draw | static | on | 0 | False | 120.0 | 5.26 |
| draw | static | on | 50 | False | 120.0 | 5.58 |
| draw | static | on | 200 | False | 120.0 | 5.68 |
| update | indexed | off | 0 | False | 58.2 | 16.66 |
| update | indexed | off | 50 | False | 51.5 | 20.80 |
| update | indexed | off | 200 | False | 57.8 | 17.32 |
| update | indexed | on | 0 | False | 47.6 | 22.29 |
| update | indexed | on | 50 | False | 38.9 | 25.60 |
| update | indexed | on | 200 | False | 44.6 | 23.05 |
| update | scriptable | off | 0 | False | 54.2 | 19.00 |
| update | scriptable | off | 50 | False | 49.1 | 23.11 |
| update | scriptable | off | 200 | False | 49.9 | 20.78 |
| update | scriptable | on | 0 | False | 40.3 | 26.57 |
| update | scriptable | on | 50 | False | 35.6 | 27.66 |
| update | scriptable | on | 200 | False | 40.7 | 26.32 |
| update | static | off | 0 | False | 68.5 | 8.64 |
| update | static | off | 50 | False | 118.6 | 8.53 |
| update | static | off | 200 | False | 105.0 | 9.78 |
| update | static | on | 0 | False | 76.2 | 17.13 |
| update | static | on | 50 | False | 73.5 | 17.39 |
| update | static | on | 200 | False | 66.6 | 17.81 |
| animate | indexed | off | 200 | True | 60.0 | 10.98 |
| animate | indexed | on | 200 | True | 54.5 | 25.36 |
| animate | scriptable | off | 200 | True | 60.0 | 10.82 |
| animate | scriptable | on | 200 | True | 53.2 | 25.11 |
| animate | static | off | 200 | True | 60.0 | 7.50 |
| animate | static | on | 200 | True | 60.0 | 17.82 |
| data | indexed | off | 200 | True | 51.1 | 21.04 |
| data | indexed | on | 200 | True | 36.8 | 28.37 |
| data | scriptable | off | 200 | True | 47.7 | 24.19 |
| data | scriptable | on | 200 | True | 34.9 | 29.12 |
| data | static | off | 200 | True | 60.0 | 9.73 |
| data | static | on | 200 | True | 59.5 | 17.07 |
| draw | indexed | off | 200 | True | 60.0 | 6.56 |
| draw | indexed | on | 200 | True | 60.0 | 6.83 |
| draw | scriptable | off | 200 | True | 60.0 | 6.39 |
| draw | scriptable | on | 200 | True | 60.0 | 6.55 |
| draw | static | off | 200 | True | 60.0 | 5.61 |
| draw | static | on | 200 | True | 60.0 | 5.68 |
| update | indexed | off | 200 | True | 57.8 | 18.15 |
| update | indexed | on | 200 | True | 38.5 | 26.72 |
| update | scriptable | off | 200 | True | 46.9 | 24.79 |
| update | scriptable | on | 200 | True | 36.4 | 28.36 |
| update | static | off | 200 | True | 60.0 | 8.11 |
| update | static | on | 200 | True | 59.8 | 11.60 |
