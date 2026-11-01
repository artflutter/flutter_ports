# Chart.js ADR 0058: Exact-point search for stacked fills

- Status: implemented; bounded macOS/Chrome validation.
- Date: 2026-11-01
- Related: ADR 0046 (the rejected broader search), ADR 0040 Open 3.

## Candidate

Only stack target construction changes. For an ordinary line with one contiguous,
non-looping segment and strictly increasing, finite, well-separated x coordinates,
an exact x match can return the existing target point. The original interpolation
scan would produce the single bound segment `[i, i]` and return that same object.
The first/last flags come from the same segment endpoints.

A cursor advances for ordered source queries and uses binary search when a query
moves backward. Nonmatching and non-finite source x values use original interpolation.
Gaps, duplicate/near-equal x values, loops, nonordinary options, custom lines, points,
lists and segments use the original path. Target validation is lazy: a lower line
that the stack never reaches remains unread. Before a fallback that could run user
code, all indexed reuse is disabled for the remainder of that build.

The margin between target x values must exceed
`1e-5 + (abs(x) + abs(previousX)) * 1e-12`, conservatively beyond the original
`isBetween` epsilon of 1e-6 and rounding. This prevents an exact match from yielding
additional neighboring bound segments. The shortcut does not approximate positions.

Search state lives for one synchronous `buildStackLine` call. It is rebuilt after
point changes and is never retained on a chart. The boundary line still uses its
original interpolation. Shared `LineElement.interpolate`, segment helpers, radar
and canvas code are unchanged. Unlike ADR 0044, no shared hot loop or new segment
implementer is introduced.

## Bounded experiment protocol

Baseline: commit `3ea45085a961adc2fc50770294d6cce04417ac2d`.
Candidate: that source plus the two stack-search files in this experiment.
Use the existing frameless gallery benchmark in release builds on macOS and Chrome
Wasm. A/B/B/A, two processes per variant. Ten cells per process: stacked fill draw
and update at N=100 and N=1000; gaps and radar draw/update at N=1000; ordinary line
draw/update at N=1000. Warmup 250 ms, seven batches of approximately 100 ms.

Compare CPU draw/recording completion and update/draw/recording completion. This
is not an FPS or GPU-raster measurement. Keep both process results, including
regressions; do not tune and repeat until the numbers look good. The primary
question is whether aligned stacked fills improve materially on both targets
without a repeatable regression in the gaps, radar or ordinary-line controls.
Small changes in this short run are inconclusive. No device benchmark is required
for this initial experiment.

Correctness uses the original algorithm with the shortcut disabled as an oracle:
exact point identity, geometry, endpoints, gaps, duplicates, epsilon-near points,
reversed queries, stepped/curved lines, mutations between builds and custom
interpolation. Existing filler reference and fixture tests remain applicable.
Results will be recorded in performance.md; this document does not accept a change
before measurements are available.

## Initial outcome (candidate B)

The primary aligned-stack cells improved on macOS and Chrome Wasm: about 97%
less draw CPU time and 88% less full-update time at N=1000. The guard criterion
was not satisfied. Chrome gap-fill drawing increased by 10.3% (+0.844 ms), and
full updates by 5.2% (+0.572 ms); both candidate processes were slower. macOS radar
drawing increased by 4.1% (+0.018 ms) in both processes. The cause of these shifts
is not established. No shared interpolation/segment/radar source was changed.

Keep this as a reviewable experiment, not a release acceptance. No tuning reruns
or mobile benchmarks were added. Diagnose the guard shifts before considering a
revised candidate. See performance.md §23 and its retained reproduction package.

## Follow-up and revised decision (candidate C)

The user requested diagnosis and a fix after the initial result. A fresh-process
Chrome A/B/B/A run executing only gap fills found +0.54% draw time and +0.51%
full-update time. The large initial difference did not reproduce. This points to
workload-order sensitivity in the short mixed sequence, where gap fills followed
very different amounts of stack work. No specific GC/JIT cause was established.

Replace the synthetic LineElement used to discover the private segment type with
an internal `nativeSegmentType` constant in helpers.segment.dart. This avoids an
artificial line/list construction and its compiler type-flow exposure. It changes
no interpolation, segment-scanning or radar algorithm and adds no public export.
This cleanup is not claimed as the sole cause of the Chrome diagnostic result.

The final A/C/C/A comparison runs guards before stacks, with the same sizes,
warmup and batch settings. At N=1000, stack draw time falls by 97.0% on macOS and
97.5% in Chrome; full updates improve by 88.0% and 89.7%. Chrome gap drawing is
+0.6% (+0.053 ms), with overlapping process ranges, and its full update improves
by 0.9%. Other guard changes are small in absolute time: macOS radar draw +0.006 ms,
Chrome radar draw +0.017 ms. Such small shifts are inconclusive with two pairs.

Retain the revised implementation for review. The large guard concern has been
addressed by isolated and corrected-order validation; this is not a statistical
zero-regression assertion or mobile/raster qualification. Keep initial, diagnostic
and final evidence separate in performance.md §23 and its reproduction packages.
