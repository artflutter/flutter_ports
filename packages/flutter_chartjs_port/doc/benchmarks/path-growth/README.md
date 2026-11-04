# Path-buffer growth triage

2026-11-04. Baseline: ADR 0084, repository HEAD recorded in metadata.json.
Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7, native profile AOT.
All experiments are isolated; production runtime source hashes remain unchanged.

## Decision

**Take adaptive chunked storage into a production-hardening pass.** It is the
strongest candidate for reducing slow frames and does not require a point-count
hint or changes to the ported line algorithm. The reservation experiment is
useful evidence, but is less general and can over-allocate for sparse paths.
Neither prototype is shipped, committed as runtime code, or a universal 60 FPS
result. A broader production validation matrix and browser checks remain gates.

The construction benchmark and GC traces support chunks. Ordinary full-update
mean improvements are small and within control variation, so they are not
presented as a reliable percentage speedup. Lower p90 is the more promising
whole-frame result. Animation comparisons are affected by a baseline refresh-
cadence change, which remains visible in the raw rows.

## Candidates and ownership

- **Baseline:** contiguous buffers, initially 16 commands, doubling when full.
- **Reserve:** use the already-supplied finite line count, bounded to one million
  and rounded to 1,024, as a capacity hint. The hint takes effect only when the
  first 16 simple commands overflow. Normal growth remains available afterward.
  No point-list scan, extra option getter or callback is introduced. The optional
  constructor argument is an isolated experiment, not a public API proposal.
- **Chunks:** grow the first buffer from 16 to 1,024 commands; then retain full
  chunks and allocate another 1,024-command chunk without copying earlier data.
  Native replay walks the chunks. The public command list still materializes
  once, and complex/exposed paths keep ordinary command objects and replay.

Each path owns its storage. No arrays from a previous path are recycled: callers
can retain an old Path2D and inspect it later. Both candidates preserve this.
Chunks also change the shape of the native replay loop; the measurements are for
the complete candidate, not a separation of allocation savings from loop/codegen
changes. Chunk size 1,024 is a tested starting point, not an exhaustive tuning result.

For 20,000 simple commands, source arithmetic gives the following buffer payloads:

| Variant | Payload allocated across growth | Payload copied during growth | Final retained payload |
| --- | ---: | ---: | ---: |
| Baseline | 1,113,840 bytes | 556,784 bytes | 557,056 bytes |
| Reservation | 348,432 bytes | 272 bytes | 348,160 bytes |
| Chunks | 365,296 bytes | 17,136 bytes | 348,160 bytes |

This excludes object headers, chunk-list storage and unrelated chart work. It is
not a VM allocation-rate measurement. Post-capture inspection found an unobserved
baseline path with 20,047 commands/capacity 32,768 and a reserved path with 20,033
commands/capacity 20,480. Counts differ because the moving scene was sampled at
different times. Some captures found no path instance; an update can temporarily
clear the path, so an empty inspection does not establish zero allocations.

A large dataset count is not always a good capacity estimate. If a 20k-point
scene emits only 17 simple commands, the reservation requests 348,432 payload
bytes across growth versus 816 for baseline/chunks. This is another source-level
example, not a measured sparse-chart timing. Delaying the hint avoids waste for
0–16 commands, but does not solve all sparse or mixed-path cases. Chunks avoid
that point-count assumption.

## Construction and conversion benchmark

Separate compiled binaries, order A1/B1/C1/C2/B2/A2: baseline/reserve/chunks.
Six cells per process: 8/100/20,000 commands with compact or already-exposed
storage. Each includes construction, native conversion and a bounds query;
400 ms warmup, an approximately 80 ms calibration and seven measured batches.
Figures average the two process medians. They are CPU microbenchmarks, not FPS.

| Commands | Observed list | Baseline ms | Reserved ms | Chunked ms |
| ---: | --- | ---: | ---: | ---: |
| 8 | False | 0.000705 | 0.000703 | 0.000719 |
| 8 | True | 0.000783 | 0.000783 | 0.000784 |
| 100 | False | 0.003463 | 0.003474 | 0.003505 |
| 100 | True | 0.003954 | 0.004022 | 0.003958 |
| 20000 | False | 0.750379 | 0.600037 | 0.498032 |
| 20000 | True | 1.091447 | 1.066097 | 1.081483 |

At 20k unobserved commands, reservation improves about 20.0% and chunks about
33.6%, saving about 0.15 and 0.25 ms respectively in this microbenchmark.
Small and already-exposed paths are broadly similar; no gain is claimed there.

## Ordinary frames

All cases use 20k scriptable points, 200 rotating labels and a 1036×520/DPR2
chart in a 1100×900 visible window. Twelve seconds per case, excluding the first
two seconds, with the same A/B/C/C/B/A order. Two cases per process: connected
full update and ongoing animation. No builds/tests/profiling run alongside these
measurements. All rows meet sample/viewport checks and visibility logs are clean.

Mean UI averages readouts; the p90 entries are individual process results, not
combined percentiles. FPS is measured, not derived from p90.

| Operation | Variant | Mean UI ms | Individual UI p90 ms | Individual FPS |
| --- | --- | ---: | --- | --- |
| update | baseline | 15.610 | 17.55 / 17.40 | 60.0 / 59.2 |
| update | reserve | 15.259 | 16.66 / 16.15 | 60.0 / 60.0 |
| update | chunks | 15.406 | 16.23 / 16.20 | 60.0 / 60.0 |
| animate | baseline | 8.707 | 12.85 / 9.16 | 60.0 / 117.1 |
| animate | reserve | 8.478 | 10.54 / 10.90 | 60.0 / 60.0 |
| animate | chunks | 7.878 | 8.51 / 8.45 | 60.0 / 60.0 |

Connected full-update mean UI moves only 15.61→15.26 ms with reservation and
15.61→15.41 ms with chunks. The unconnected control, where no line path is built,
varies from 13.61 ms baseline to 13.12/13.03 ms. That control variation is larger
than the connected mean differences. **Do not claim a robust 1–2% whole-update
average gain from these runs.**

The p90 result is more consistent: baseline 17.40–17.55 ms, reserve 16.15–16.66,
chunks 16.20–16.23. Those candidate runs approach or fit the 16.67 ms budget, but
leave little headroom and do not cover every chart mode/configuration.

Animation's baseline changes from about 60 to 117 FPS between processes. The
measurement does not pin a physical display cadence. Consequently the apparent
animation average improvement is provisional, and FPS comparisons cannot be
interpreted as a fixed-refresh throughput gain. Original rows are retained.

## GC and slow frames

Five GC-only captures disable CPU sampling: heavy full update for all three
variants, plus animation for baseline/chunks. Timelines collect Dart/GC streams
after four seconds of warmup for about 16 seconds. We pair complete Flutter
UI Frame events and union nested/overlapping GC spans on the same UI thread;
background-worker GC is excluded. Full retained timelines and per-frame data
are saved; the table compares complete frames from the same final five seconds.

| GC-only capture, final 5 seconds | Frames | Mean GC ms/frame | Slow-decile mean GC ms | UI Frame p90 ms |
| --- | ---: | ---: | ---: | ---: |
| gc-baseline | 284 | 3.35 | 6.19 | 18.79 |
| gc-reserve | 297 | 2.58 | 4.24 | 17.24 |
| gc-chunks | 298 | 2.20 | 2.85 | 15.81 |
| gc-animate-baseline | 561 | 0.49 | 3.94 | 9.70 |
| gc-animate-chunks | 595 | 0.11 | 0.45 | 8.38 |

In those equal-duration update windows, mean GC-labelled UI time moves
3.35→2.58 ms with reservation and **3.35→2.20 ms with chunks**, about 23% and 34%
lower. The slowest-decile mean moves 6.19→4.24/2.85 ms. Over the full retained
traces, the corresponding means are 3.12→2.53/2.16 ms, supporting the direction.
Animation also has lower GC-labelled time in the chunk capture, though these are
short diagnostic traces with differing delivered frame rates.

These are instrumented timeline durations, not the ordinary readouts above.
They cannot be subtracted from the frame table to predict FPS. Heap accumulated
counters still equal current counters: heap responses are snapshots, not
objects/frame or bytes/frame rates. Private path inspection runs after the
timed capture and never reads the public commands getter.

A fresh, separate baseline CPU profile has 10,226 samples. Inclusive stacks
contain LineController.updateElements in 43.8%, Chart.draw in 39.1%, point drawing
in 19.1%, labels in 11.0%, and line drawing in 6.3%. These shares overlap. They
show that option/context/element-update work remains substantial after ADR 0084;
path-buffer work is a focused opportunity, not the entire remaining budget.

## Validation and next implementation gate

Each variant passes 170 existing focused canvas/path/line tests and 12 additional
boundary/retention cases. The extra cases cover 15/16/17, 1,023/1,024/1,025,
20,479/20,480/20,481 and 50,000 commands; reservation overflow with a smaller hint;
late exposure/clearing, mixed commands and old paths retained while new paths are
created. All 300 native pixel scenes match baseline for each candidate: 600
candidate comparisons, zero differences. Pixel probes warm up for two seconds.

Before promotion, integrate chunks with production documentation/guard contracts,
run browser and full regression/fixture checks, repeat the full native mode matrix
and control cadence explicitly where possible. Check small, sparse, curved,
stepped and command-inspecting paths for regressions. Data-only eligibility is
unchanged. This triage does not weaken any callback or range guard.

## Reproduction and artifacts

metadata.json records baseline source hashes, compiled variant hashes, protocol
and validation scope. summary.json includes individual micro/frame rows, controls,
GC intersections and the source-level payload model. Compressed raw timelines,
heap snapshots, window logs, tests and pixel hashes retain the evidence.

Use an isolated workspace at /tmp/path-growth-work with the pinned SDK/lockfile
and the temporary native window host from ../circle-path. Copy the two baseline
runtime files to .dart_tool/path_growth/canvas.dart.baseline and
element.line.dart.baseline. Restore the saved .txt tools under .dart_tool/path_growth
with their original suffixes. variants.py constructs each candidate; reserve.patch
and chunks.patch also show the exact runtime differences. The original micro and
pixel templates feed the probes. build.py builds/tests each separately and saves
/tmp/path-growth-{baseline,reserve,chunks}.app with temporary probe entitlements.

Run run.py under caffeinate with builds/tests idle. capture.py/profile.dart collect
the GC and fresh CPU evidence afterward. Extra boundary tests run separately via
extra_tests.py. analyze.py and report.py regenerate the summaries. Production
sources are checked against the initial hashes at the end; none were modified.
