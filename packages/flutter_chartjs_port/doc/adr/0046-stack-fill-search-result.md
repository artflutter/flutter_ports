# Chart.js ADR 0046: Stack fill search, the result of the code A/B

- Status: accepted (2026-10-29)
- Date: 2026-10-29
- Related: [Chart.js ADR 0044](0044-stack-fill-search.md) (the stack fill search, rejected),
  [Chart.js ADR 0040](0040-filler-targets-and-plain-points.md) Open 3 (`interpolate` and the
  quadratic stack), [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) (the protected
  behavior), [porting-flow.md](../porting-flow.md) §1.1 (the performance rule),
  [performance.md](../performance.md) §14.9 (the figures)

## Context

Chart.js ADR 0044 changes two things in the port. The loop of `_boundSegment` gets direct calls,
an `int` index and inline helpers (row `adapt-bound-segment-loop`). The stack line gets a window
search of the lines below (row `adapt-stack-line-window`). The bound segments, the results of
`interpolate` and the stack points stay the upstream ones. Section 6 of Chart.js ADR 0044 gives
the gates of the acceptance: the full gate, a code A/B on macOS and in the VS Code browser with
the rule ACCEPT on both platforms, and R below 1.5 in the VS Code browser. It also says: "If the
A/B rejects the change or stays inconclusive on a platform, the change goes out of the tree, and
a new ADR records the result." This ADR is that record.

The full gate passed with the change on 2026-10-28. The code A/B ran in the night of 2026-10-28
to 2026-10-29. A protocol that was written before the first run decided it.

## Decision

1. The change of Chart.js ADR 0044 does not land. The port keeps the upstream form of
   `_boundSegment`, `_boundSegments`, `interpolate` and `_buildStackLine`. The stack fill stays
   quadratic, as upstream.
2. The rows `adapt-bound-segment-loop` and `adapt-stack-line-window` do not go into
   `differences.md`.
3. Chart.js ADR 0040 Open 3 stays open. A new candidate needs a new design and a new code A/B.
   The design must keep the speed of the `'angle'` path of the radar fill (the guard G2 below).
   The window search of the stack line alone is one possible candidate, because the stack cells
   P1 and P2 got most of their gain from it.

## The result

Sides: A is `1d271cd`. B is `1d271cd` with the patch of Chart.js ADR 0044 (507 lines). The
protocol used ABBA order, fresh processes, 6 pairs and 6 more pairs where a stage 2 condition was
true, the mean of the pair differences B − A with a 95 % bootstrap interval, and a gate on the
load of the Mac. The figures are the mean of B − A in ms for one frame, with the interval.

| Cell | macOS (Apple M3 Max, AOT; 9 valid pairs of 12) | VS Code browser (Chromium, dart2wasm; 6 pairs) |
|---|---|---|
| P1, `fill.stack` N 1000 `draw` | -29.9979 (-30.1282 .. -29.8468) | -34.5790 |
| P2, `fill.stack` N 1000 `update` | -31.9189 | -35.4873 |
| G1, `fill.gaps` N 1000 `draw` | -2.1839 | -2.9032 (5 pairs) |
| G2, `fill.radar` N 1000 `draw` | +0.0023 (0 .. +0.0049) | +0.0266 (+0.0230 .. +0.0302), +5.5 % (5 pairs) |
| G3, `fill.stack` N 100 `draw` | -0.3051 | -0.3605 |
| Control cells slower (h, limit 4) | 0 | 9 |
| Rule | ACCEPT | REJECT |

- In the VS Code browser, G2 is wholly above 0, and h = 9. The 9 slower control cells are the
  `update` cells of `fill.gaps` and `fill.radar` and the `draw` cell of `fill.radar` at N 1000.
  The slower `'angle'` scans of the new loop are the probable cause in the `fill.radar` cells
  (+2 % to +6 %). The `fill.gaps` cells have no `'angle'` path. The A/B does not give their cause.
- Chart.js ADR 0044 E3 measured 200 `'angle'` scans alone, 11 % faster with the change. The
  whole frame of the radar fill in the VS Code browser is slower. The A/B does not explain the
  difference.
- On macOS, the lower end of the G2 interval is exactly 0, so G2 is not wholly above 0. An
  independent recompute found that this result depends on one pair. A fault of the front-app
  sampler excluded that pair. With that pair, G2 on macOS is +0.0025 (+0.0004 .. +0.0048), and
  macOS gives REJECT too. The decision does not change.
- R with the B side in the VS Code browser is 1.116 / 19.862 = 0.056 (R_B). Without the change,
  R is 35.687 / 19.862 = 1.80 (R_A). R_B alone does not decide: section 6 of Chart.js ADR 0044
  needs ACCEPT on both platforms.
- The independent recompute agrees with each figure, each exclusion and each decision.

## Consequences

- `lib/` and `test/` do not change. Chart.js ADR 0044 stays in `doc/adr/` with the status
  rejected, as the record of the design.
- One frame of `fill.stack` at N 1000 stays 1.8 to 1.9 times the upstream time in the VS Code
  browser (performance.md §14.9).
- Chart.js ADR 0040 is accepted and does not change. Its Open 3 gave the owner step 8 and no
  trigger. From this ADR, Open 3 has the owner the porting lead. Its trigger is a new design of the
  stack fill search, or a user report of a slow stack fill.

## Evidence

- **E1, the protocol.** The code A/B protocol of the fill step of phase 8 (cells P1, P2, G1-G3,
  37 control cells, h* = 4, the rule of section 6 of Chart.js ADR 0044), written before the first
  run. A working file of phase 8, not committed.
- **E2, the runs.** macOS: 12 pairs, with 9 valid pairs in each group. The excluded runs have a
  sampler fault (pair 1), an app that was not in front (pair 3), a stopped driver or a duplicate
  run (pair 4 of `f1`) and a second bench app during the run (pair 5 of `f2`). VS Code browser:
  6 pairs in one tab of the integrated browser. Pair 1 of `f1` is excluded, because the load
  after the run was above 8. Working files of phase 8, not committed.
- **E3, the recompute.** An independent agent recomputed every figure from the raw run files with
  its own scripts. All figures agree within 1e-12 ms, and all decisions agree. A working file of
  phase 8, not committed.
