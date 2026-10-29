# Chart.js ADR 0044: Stack fill search

- Status: rejected (2026-10-29). The code A/B of section 6 gave ACCEPT on macOS and REJECT in
  the VS Code browser. Thus the change is not in the tree.
  [Chart.js ADR 0046](0046-stack-fill-search-result.md) records the result.
- Date: 2026-10-24
- Related: [Chart.js ADR 0020](0020-registry-and-component-classes.md) §13 (a gain that only a
  microbenchmark measures),
  [Chart.js ADR 0032](0032-js-numeric-semantics.md) (`remainder`, the index rules, the
  reference engine),
  [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) (the protected behavior),
  [Chart.js ADR 0040](0040-filler-targets-and-plain-points.md) §2, §11 and Open 1 and 3 (the
  results of `interpolate` in the stack line, one implementer of the point interfaces, the
  stacked fill above a line that goes back, `interpolate` and the quadratic stack),
  [porting-flow.md](../porting-flow.md) §1.1 (the performance rule),
  [performance.md](../performance.md) §14 (the fill figures of phase 8),
  [differences.md](../differences.md) rows `adapt-bound-segment-loop` and
  `adapt-stack-line-window` (new)

## Context

Chart.js ADR 0040 Open 3 says: "`interpolate` on dart2wasm costs about 2 times V8. The `stack`
fill is quadratic, as upstream. A cursor or binary-search form of `interpolate` changes a shared
element and needs its own design and a new ADR." Step 8 of phase 8 measured the fill cells of
the frameless benchmark (3 datasets, `pointRadius: 0`, `animation: false`, the call `draw`, N
points in each dataset). The rule of that series: when the ratio R of the port draw of
`fill.stack` at N 1000 to the upstream draw of the same cell is 1.5 or more, Open 3 goes to a
design panel and a new ADR.

The figures of `fill.stack`, call `draw`, N 1000 (the median of 6 runs, ms):

| Platform | Port draw | Upstream draw | R |
|---|---:|---:|---:|
| VS Code browser (Chromium, dart2wasm) | 36.755 (36.601-36.913) | 19.862 (3 runs: 20.163, 19.862, 19.678) | 1.85 |
| macOS (Apple M3 Max, AOT) | 31.151 (30.628-31.613) | not measured | — |
| iPhone 17 Pro (AOT) | 30.688 | not measured | — |

At N 100 the same draw is 0.411 ms on the iPhone: the factor 75 for 10 times the points is the
quadratic stack. At N 1000 one frame with the update takes 36.6 ms (macOS) to 41.5 ms (VS Code
browser): longer than two frames of 60 Hz. The Pixel 8a has no fill figures (the device series
stopped).

The line numbers of upstream files refer to Chart.js `v4.5.1+7169e651` (`third_party/Chart.js`
at `7169e65147a4`). "The port" is `packages/flutter_chartjs_port/lib/src/`.

### The upstream path

- `_buildStackLine` (`filler.target.stack.js:15-30`) calls `addPointsBelow` for each point of
  the source line. `addPointsBelow` (`:58-80`) calls `findPoint` (`:87-109`) for each line
  below until a hit in the middle of a segment. `findPoint` calls `line.interpolate(sourcePoint,
  'x')` (`:88`).
- `interpolate` (`element.line.js:351-378`) reads `options`, `point[property]` and `points`,
  calls `_boundSegments(this, {property, start: value, end: value})` (`:355`), and then makes one
  result for each bound segment.
- `_boundSegments` (`helpers.segment.js:141-152`) calls `_boundSegment` (`:77-129`) for each
  segment. `_boundSegment` gets `between`, `compare` and `normalize` from `propertyFn` (`:11-24`)
  as function values, defines four arrow functions (`:92-95`) and scans each point of the
  segment (`:97-122`), with `points[i % count]` (`:98`).
- Thus each source point scans all points of each line below that it reaches. In the cell
  `fill.stack`, datasets 1 and 2 each make 1000 scans of 1000 points in each draw: 2 million
  point visits. Upstream is quadratic in the point count.

### Where the port pays more

Three drafts and the judge of the panel measured the same thing in independent benchmarks. The
benchmarks build the scene of `fill.stack` with fakes of the chart, the metas and the scale, and
time the lib functions (AOT, and dart2wasm in Node.js v24.12.0 arm64 as a timer only) and the
pinned build in V8 in the same Node.js.

- The loop of `_boundSegment` has all of the excess: one point visit costs about 9.8 ns in V8,
  14.1 ns on AOT and 24.4 ns on dart2wasm in Node.js. `_boundSegments` alone is 98 % to 99 % of
  the stack build on both Dart targets. The other parts (`_buildStackLine`, `getLinesBelow`,
  `addPointsBelow`, `findPoint`, the rest of `interpolate`, the `PointElement` wraps of Chart.js
  ADR 0040 §2, the boundary line) add 0.2 ms or less at N 1000.
- Three Dart forms in that loop make the difference. AOT and dart2wasm do not inline them, and
  they box a `double` at each call or write. V8 inlines the same JS forms:
  1. the calls through the function values of the record of `propertyFn`: AOT -9 ms, dart2wasm
     -23 ms in the stack build of the 3 datasets when they become direct calls;
  2. the `double` index with `remainder` and `toInt()`: AOT -3.9 ms, dart2wasm -7.5 ms when it
     becomes an `int`. On dart2wasm, `double.remainder` is a software loop;
  3. the four local closures, which capture `value`, `prevValue` and `inside`: AOT -3.3 ms,
     dart2wasm -6 ms when their bodies go to the call sites.
- With these three changes, the port loop is faster than the V8 loop on AOT and on par with it on
  dart2wasm. The stack stays quadratic.

## Decision

The port changes two things, each with a `DIVERGES(chartjs)` marker and an `adapt` row. Both
keep the protected behavior of Chart.js ADR 0034: the bound segments, the results of
`interpolate`, the points of the stack line, the draw calls and the throws are the upstream ones.

### 1. The loop of `_boundSegment` (row `adapt-bound-segment-loop`)

In `helpers/helpers.segment.dart`:

1. `boundSegment` keeps the upstream lines up to `getSegment` (`:77-85`). Then it calls the loop
   `_boundRange` with a constant flag `angle` (`property === 'angle'`): one call for `'angle'` and
   one for the other names. `_boundRange` has `@pragma('vm:prefer-inline')`,
   `@pragma('wasm:prefer-inline')` and `@pragma('dart2js:prefer-inline')`, so each call site
   inlines its own loop, and the flag folds.
2. `_boundRange` is the loop of `:86-128` with the upstream variable names and statement order:
   - `between` and `compare` are the inline helpers `_between(angle, ...)` and
     `_compare(angle, ...)`: `angleBetween` and `angleDiff` for `'angle'`, `isBetween` and
     `a - b` for the other names, as `propertyFn` gives them. `normalize` is `normalizeAngle` for
     `'angle'` and the value itself for the other names.
   - The bodies of `shouldStart() && startIsBefore()` and `shouldStop() && endIsBefore()` are at
     their two call sites, with the same operands in the same order and the same short circuits.
     Each site cites `:92-95`.
   - The index `i` and `prev` are `int` values from `start.toInt()`. Each index of a segment is a
     whole number from 0 up in each caller (the segments of `_computeSegments` and the results of
     `getSegment`), so `points[i < count ? i : i.remainder(count)]` reads the point of
     `points[i % count]`. The `end` comparison stays `i <= end` with the `double` end. Each result
     gets `i.toDouble()` and `prev.toDouble()`, so `normalizeSegment` gets the upstream values.
   - Before the loop, two guards keep the upstream result for a start that is not such an
     index. A NaN start (`start % count` of a loop over no points, `:53`) or a start above the
     end gives no sub-segment, as `i <= end` (`:97`) is false at once. A start that is infinite,
     negative or not whole, or a list of no points, throws a `TypeError`, because the first read
     `points[i % count]` (`:98`) is `undefined` and upstream reads `point.skip` of it (`:100`).
     No caller of the port makes these starts, but `_boundSegment` is a helper of the upstream
     namespace (E8).
   - The `undefined` state of `value === prevValue` stays as before (`prevUndefined` and the read
     by name of a NaN `x` or `y`).
3. `_getSegment` keeps `propertyFn`: it runs once for each loop segment, outside the hot loop.
4. One result differs in a value that no reader tells apart: a segment start of -0 gives a
   sub-segment start of 0 where upstream can give -0. The value is an index. No caller makes a
   start of -0.

### 2. The window search of the stack line (row `adapt-stack-line-window`)

In `plugins/plugin.filler/filler.target.stack.dart`:

1. `buildStackLine` makes a list with one lookup slot for each line below. `_findPoint` makes the
   lookup of its line at the first call on that line, after the cast of the line and the
   `TypeError` of a missing source point. Upstream reads `points` and `segments` of a line below
   first in that call (`element.line.js:354-355`). A line below that the loop never reaches
   (after a hit in the middle of a segment, `filler.target.stack.js:71-74`) is never read.
2. The lookup has the window form when all of these are true. Else each call is the literal
   `line.interpolate(point, property)`:
   - the line is of the class `LineElement` itself (a subclass can change `interpolate`,
     `points` or `segments`);
   - the property is `'x'` (the only property of `addPointsBelow`, `:62`);
   - no segment is a loop, and each segment has whole indexes from 0 up, with `start <= end` and
     `end` below the point count;
   - in each segment, the points without `skip` have a finite `x` that strictly increases.
   The lookup keeps the indexes of the points without `skip` of each segment. A call with a
   source point whose `x` is not finite is also the literal call.
3. For the value `v` (the `x` of the source point), the window form finds in each segment, by
   binary search over those indexes:
   - `lo`: the last point with `x < v - delta`, else the start of the segment;
   - `hi`: the first point with `x > v + delta`, else the end of the segment;
   - `delta = 1e-5 + |v| * 1e-12`.
   A segment whose points are all below `v - delta` or all above `v + delta` gives no
   sub-segment, and the lookup skips it. For the other segments, the port-only function
   `boundSegmentWindow` of `helpers.segment.dart` runs `_boundRange` from `lo` to `hi` with the
   loop, the style and the point count of the segment. The lookup adds the non-empty results in
   segment order, as `_boundSegments` does, and calls `interpolateFrom` (section 3).
4. **The proof.** For the bounds `{x, v, v}` and a segment whose points without `skip` have a
   strictly increasing finite `x`, the scan of `_boundSegment` (`:97-122`) gives the same
   sub-segments over `lo..hi` as over the whole segment:
   - The skipped points change no state (`:100-102`), and a strictly increasing `x` never gives
     `value === prevValue` (`:106-108`).
   - Before `lo`, each point has `x < v - delta`. `inside` is false, because `x < v - 1e-6`.
     `startIsBefore` is false, because `max(prevValue, x) + 1e-6 < v`. Thus `subStart` stays
     `null`, and only `prev` and `prevValue` change.
   - At `lo`, the scan of the window starts with `prevValue` `undefined` (NaN in the
     comparisons), and the full scan has the `x` of an earlier point, also below `v - delta`. Both
     give `inside` false and `startIsBefore` false. After `lo`, both states are equal: `prev` is
     `lo`, `prevValue` is `x[lo]` and `subStart` is `null`. When no point is below `v - delta`,
     both scans start at the start of the segment with the same state.
   - From `lo` to `hi`, both scans see the same points with the same state, so they push the
     same sub-segments.
   - At `hi`, `inside` is false (`x > v + 1e-6`), so `shouldStop()` is true, and a sub-segment
     that is open or that starts at `hi` closes at `hi`. After `hi`, `min(prevValue, x) - 1e-6 >
     v`, so `inside` and `startIsBefore` stay false, and the last push of `:124-126` does not
     occur. When no point is above `v + delta`, `hi` is the end of the segment, and the last push
     is the same in both scans.
   - Rounding: `delta - 1e-6` is at least 9e-6 plus `|v| * 1e-12`, and the rounding error of
     `x + 1e-6`, of `x - 1e-6` and of `v ± delta` is a few units of the last place of `|v|`
     (about `|v| * 2.2e-16` each). Thus the strict inequalities above hold for each finite `v`. A
     `v ± delta` that overflows to an infinity gives a larger window, which the proof allows: any
     start point below `v - delta` and any end point above `v + delta` give the same result.
   - Segment order, the empty results and the `style` of each sub-segment are those of
     `_boundSegments` (`:141-152`) and `normalizeSegment` (`:26-33`) with `loop` false.
5. A flag `stackLineWindow` (`@visibleForTesting`, default `true`) turns the window form off.
   Only tests write it.
6. No user code runs between two calls of one stack line: the reads of `points`, `segments`,
   `x`, `skip` and `options` of a line and its points have no side effects after the first read
   of `segments`. Thus the points and segments do not change while the lookup lives. The lookup
   lives for one `buildStackLine` call only. It is not kept on the line, because the controller
   and the animations move the points in place without a write of `points`.

### 3. `interpolate` in two parts

In `elements/element.line.dart`, `LineElement.interpolate` computes the value and the bound
segments with `boundSegments` (`element.line.js:353-355`), and then calls the new `@internal`
method `interpolateFrom(point, property, segments)`: the rest of `interpolate`
(`element.line.js:352-377`), which reads `options`, the value and `points` and makes the result.
These reads have no side effects, so their place after `_boundSegments` changes no result. The
marker of the row `adapt-stack-line-window` is at `interpolateFrom`. `types.LineElement` does not
change.

### 4. No second implementer of `types.Segment`

The window passes its `lo` and `hi` as numbers to `boundSegmentWindow`. It makes no segment
object. Thus `_Segment` of `helpers.segment.dart` stays the only implementer of `types.Segment`
in `lib/`. Chart.js ADR 0040 §11 measured that a second implementer of an interface whose getters
are read in hot loops makes every line slower on AOT and dart2wasm.

### 5. Tests, rows and records

- `test/port/helpers/helpers.segment_loop_test.dart`, group `adapt-bound-segment-loop`:
  `boundSegment` against a copy of the closure form (the port before this ADR, line for line
  with `helpers.segment.js:11-129`) on 20000 random cases with a fixed seed: `x`, `y` and
  `angle`, loops, skipped points, NaN and `undefined` values, values inside the epsilon 1e-6, and
  bounds from the points. The start, the end, the loop and the style object must be equal. A
  fixed case pins the three sub-segments of the epsilon case, which the pinned build gives in
  Node.js v24.12.0 on x64. A second fixed case pins the guards of section 1 item 2 (E8). A pure
  layer test: `test:web` runs it on dart2js and dart2wasm.
- `test/port/plugins/plugin.filler/filler.target.stack_test.dart`, group
  `adapt-stack-line-window`: the stack lines of the window form and of the literal form are equal
  on 400 random charts with a fixed seed (the same point element of a line below, or a new point
  with the same `x` and `y` read by name); the window form runs: on a line below of 400 points
  with an increasing `x`, the stack line reads fewer than 40 points of that line for each source
  point, where the literal form reads more than 400 (a counting point list); and a subclass of
  `LineElement` gets each call.
- The existing reference tests of the filler (`filler.target_test.dart` and `index_test.dart`,
  the stack cases against the pinned build), the specs and the fixtures
  `plugin.filler/line/stack.json` and `plugin.filler/line/stack-multiple-scales.js` stay green.
- `differences.md` gets the rows `adapt-bound-segment-loop` and `adapt-stack-line-window`.
- `performance.md` gets the figures of the A/B of section 6 before this ADR is accepted.

### 6. The gates of the acceptance

The porting lead accepts this ADR when all of these are true:

1. The full gate of the kickstart is green with the change (also `test:web`, which runs the two
   pure test files on dart2js and dart2wasm).
2. A code A/B of the frameless benchmark on macOS and in the VS Code browser (Chromium, dart2wasm)
   with the fill groups `f1` (`fill.gaps`, `fill.radar`) and `f2` (`fill.stack`), written before
   its first run: ABBA, fresh processes, 6 pairs (6 more when a primary interval includes 0), the
   mean of the pair differences with a 95 % bootstrap interval. The primary cells are the whole
   frame of `fill.stack` at N 1000 with the calls `draw` and `update`. The guard cells are the
   whole frame of `fill.gaps` and `fill.radar` (call `draw`, N 1000) and of `fill.stack` (call
   `draw`, N 100). The rule gives ACCEPT on both platforms.
3. With the B side of that A/B, R in the VS Code browser (the port draw of `fill.stack`, N 1000,
   over the upstream 19.862 ms) is below 1.5.

If the A/B rejects the change or stays inconclusive on a platform, the change goes out of the
tree, and a new ADR records the result.

## Alternatives considered

A panel wrote three drafts: fidelity first (F), performance first (P) and simplicity first (S).
A judge scored them in the order of the decision protocol (the protected behavior, then the
performance, then the upstream structure, then less code) and ran its own probes (Evidence E3 to
E6). Priority 1 does not separate the drafts: each keeps the bound segments and the stack points,
with a proof or a differential test. Priority 2 decides: P is 20 to 40 times faster than F and S
in the stack build. P won. The judge took from F the specialized loop (one inlined loop for each
property kind, which removed a dart2wasm slowdown of the `'angle'` path that F found in a twin
for `'x'` and `'y'` only) and the pinning test against the closure form, and from S the in-place
change of the loop (no second copy of the loop) and the caution on the proof (section 2 item 4 is
in this ADR, and the bump check of the row repeats it).

- **Keep the upstream form.** R stays 1.85 in the VS Code browser, and one stack frame at N 1000
  stays above 33 ms on each platform. No gain in priorities 1 and 3 against the decision.
- **Only the loop change (S: the in-place loop; F: a twin).** Stack build of one dataset at N
  1000 about 5.3 to 8.3 ms (AOT) and 6.3 to 11 ms (dart2wasm in Node.js) in place of 0.25 and
  0.29 ms. Still quadratic. The decision keeps this change for the literal path and the other
  fills.
- **A twin of the loop with the upstream body kept for diffing (F).** The same speed as the
  in-place form. It keeps the upstream lines, but adds about 200 lines, a flag and a second loop
  that each bump must change. In the port the upstream body then runs only for inputs that no
  caller makes. The in-place form keeps the names, the order and the citations of each line.
  Priority 3 is about equal, and priority 4 decides.
- **A twin for `'x'` and `'y'` only.** It made the `'angle'` path of the radar fill about 10 %
  slower on dart2wasm (a whole-program effect). The specialized loop of section 1 makes the
  `'angle'` path 11 % faster on both targets.
- **One loop with `angle` branches and no inlining.** 3 ms slower than the specialized loop on
  AOT in the stack build of the 3 datasets.
- **Only the direct calls of `propertyFn`, the closures kept.** The closest text to upstream, but
  R stays about 1.26 on dart2wasm in Node.js, and it needs a second loop for `'angle'` too.
- **`propertyFn` as a class with two subclasses.** The fastest form on AOT, but 1.5 times slower
  than the direct calls on dart2wasm (14.39 ms against 9.43 ms for 1000 bound scans).
- **The window search for each caller of `interpolate`.** The check of the conditions costs one
  pass over the points, as much as the scan. Only the stack calls `interpolate` many times on one
  line.
- **A lookup kept on the `LineElement` and dropped at each write of `points`.** The controller and
  the animations move the points in place without a write of `points`. A kept lookup can be stale
  and change the result.
- **A merge cursor in place of the binary search.** It needs the source `x` in order too. It
  gains at most about 0.1 ms at N 1000 (10 search steps for each source point). Not built.
- **A segment object for the window.** A second implementer of `types.Segment` in `lib/`
  (section 4). The window passes numbers.
- **The `%` operator for the `int` index.** 8 % faster than `remainder` on dart2wasm in the
  literal path, but it needs a `js-ok` comment. With the window form the literal path is rare
  (a line that goes back, repeats an `x` or has a NaN `x`, where upstream drops the fill, Chart.js
  ADR 0040 Open 1). `remainder` keeps the rule of Chart.js ADR 0032.

## Consequences

- The stack fill is no longer quadratic for lines with an increasing `x` (the usual case): each
  source point costs O(log N) on each line below, plus one pass over each line below for its
  lookup. The results are the upstream results.
- A stack over a line whose `x` goes back, repeats or is NaN keeps the quadratic scan, about 3
  times faster than before (section 1).
- Every `interpolate`, the `_segments` of each fill and the `angle` path of the radar fill run the
  faster loop: 200 range scans of a line with gaps take 48 % to 50 % less time, and 200 `angle`
  scans of a radar loop of 1000 points 11 % less.
- New `DIVERGES` markers in `helpers.segment.dart` (2 rows), `element.line.dart` and
  `filler.target.stack.dart`. Two new rows. `LineElement` gets the `@internal` method
  `interpolateFrom`. `helpers.segment.dart` gets the `@internal` function `boundSegmentWindow`.
  `types.LineElement` and `types.Segment` do not change.
- A bump that changes `propertyFn`, `getSegment`, `_boundSegment`, `_boundSegments`,
  `interpolate`, `_isBetween` or `filler.target.stack.js` checks the proof of section 2 item 4
  and the closure form of the pinning test (the bump checks of the two rows).
- Chart.js ADR 0040 Open 3 closes when this ADR is accepted. Chart.js ADR 0040 is accepted and
  does not change.

## Open

1. **The device figures.** The A/B of section 6 runs on macOS and in the VS Code browser. The
   Pixel 8a and the iPhone 17 Pro have no figures of this change. Owner: the porting lead.
   Trigger: the next device block of the phones. The AOT figures of macOS are the best estimate
   for both phones.
2. **The literal path of the stack.** A stack over a line whose `x` goes back stays quadratic.
   Owner: the porting lead. Trigger: an upstream change of Chart.js ADR 0040 Open 1 (upstream
   drops that fill now), or a user report of a slow stack fill with such a line.

## Evidence

- **E0, upstream source** at `v4.5.1+7169e651`, `src/`:
  - `plugins/plugin.filler/filler.target.stack.js:15-109`
  - `elements/element.line.js:351-378`
  - `helpers/helpers.segment.js:11-60`, `:77-129`, `:141-152`
  - `helpers/helpers.math.ts:152-175`, `:205-207` (`_angleDiff`, `_normalizeAngle`,
    `_angleBetween`, `_isBetween`)
  - `plugins/plugin.filler/filler.drawing.js:200-205`, `filler.segment.js:3-47` (the other
    callers of `interpolate` and `_boundSegment`)
- **E1, the trigger figures** (Context): the fill series of step 8 of phase 8, 6 fresh processes
  of each group on each platform, and 3 runs of the upstream benchmark page with the pinned build
  in the VS Code browser.
- **E2, the drafts.** F: a stage breakdown (S1 `boundSegments` x 1000 13.83-13.99 ms AOT,
  24.44-24.80 ms dart2wasm in Node.js, 8.64-9.35 ms V8; S4 the stack build of dataset 1
  13.73-13.74, 24.00-24.13 and 9.03-9.39 ms) and the attribution of section "Where the port pays
  more"; an A/B of 6 ABBA pairs of its twin (the stack build of the 3 datasets, AOT 28.917 to
  10.633 ms, dart2wasm 48.524 to 12.389 ms; upstream V8 21.486 ms); 300000 random
  `boundSegment` cases and 2000 random stack charts with 0 differences. P: the loop forms (1000
  bound scans at N 1000, ms, AOT / dart2wasm in Node.js: lib 14.08 / 24.44, direct calls with an
  inlined `angle` flag 5.75 / 9.43, class form 4.91 / 14.39, upstream V8 9.82); a prototype of
  the window search (the stack build of dataset 2 at N 1000: 14.35 to 0.278 ms AOT, 22.95 to
  0.311 ms dart2wasm; upstream V8 9.93 ms); a differential test of 20000 random lines with
  9367440 queries (2696163 on the window path) and 15000 random stack builds, 0 mismatches, on
  AOT and dart2wasm; two mutations of the window (a throw; a window one point late) that 16 to 17
  reference tests detect. S: the filler frame of the scene at N 1000 with the in-place loop, 0.536
  times (AOT) and 0.398 times (dart2wasm in Node.js) the closure form; 300000 random cases with 0
  differences, and a one-operand mutant with 7886 differences.
- **E3, the judge benchmark** of the final code against the tree before it (the same harness as
  the P prototype, the `fill.stack` data at N 1000, 4 ABBA pairs of fresh processes on an Apple
  M3 Max with a load of 1.8 to 2.4; the median of the run medians in ms, AOT / dart2wasm in
  Node.js v24.12.0 arm64; equal digests of the stack points on both sides):

  | Cell | Before | After |
  |---|---:|---:|
  | stack build of dataset 2, increasing `x` (window form) | 13.886 / 22.351 | 0.248 / 0.286 |
  | the same with one repeated `x` in each line (literal form) | 13.790 / 22.290 | 4.601 / 6.772 |
  | 1000 calls of `interpolate` on line 0 | 13.624 / 22.095 | 4.513 / 6.760 |

  The guard cells (the same pairs; µs for one iteration): 200 `angle` bound scans of a radar
  loop of 1000 points, AOT 22867-23145 to 20352-20457, dart2wasm 21902-22037 to 19461-19639; 200
  range scans of a line of 1000 points with a gap every 12 points, AOT 3729-3749 to 1901-1948,
  dart2wasm 6094-6321 to 3066-3114.
- **E4, the judge differential runs:** the group `adapt-stack-line-window` with 6000 random
  charts for each of 3 more seeds, with more gaps around the epsilon and the delta (9e-7 to
  1.2e-5), the offsets 3.5 and 1e15 and source moves of up to 1.001e-5: 0 differences, 33644 stack
  lines with points.
- **E5, the judge mutation checks:** a window one point late (the window group, and the light
  preset stack case of `index_test.dart`, fail), a `delta` of 0 (the window group fails), the
  operand change `_compare(...) == 0` in the start test (the loop group fails), and the index
  `points[0]` for an index at or above the count (the loop group fails).
- **E6, the judge probe of the epsilon case** in the pinned build (`dist/helpers.js`, Node.js
  v24.12.0 on x64): `_boundSegment({start: 0, end: 3, loop: false}, [1, 2, 2.0000005, 3] as
  x, {property: 'x', start: 2, end: 2})` gives `[{start: 1, end: 1}, {start: 1, end: 2},
  {start: 2, end: 3}]`, as the port.
- **E7, the gates of the change:** `dart format`, `dart analyze --fatal-infos` of the package and
  of the gallery, the tests of `test/port/plugins/plugin.filler/`, `test/port/helpers/`,
  `test/port/elements/` and the specs of `plugin.filler`, `helpers.segment` and `element.line`
  (2136 tests), the fixtures of `plugin.filler`, `element.line`, `controller.line`,
  `controller.radar` and `plugin.decimation` with `FIXTURES_REQUIRED=1` (194 tests, both stack
  fixtures among them), and `check:port`.
- **E8, the review probes** (x64 Node.js v24.12.0, the pinned `dist/helpers.js` and
  `dist/chart.js`, and the upstream files `filler.target.stack.js`, `filler.helper.js` and
  `filler.segment.js` with their imports moved to the build):
  - `_boundSegment` gives `[]` for `{start: 0, end: 0, loop: true}` over no points (`x` and
    `angle`) and for a NaN start, and throws a `TypeError` for no points without a loop and for
    an infinite or a fractional start. The first version of the `int` index threw an
    `UnsupportedError` (`toInt` of NaN or of an infinity) for the NaN and the infinite starts,
    and an `IntegerDivisionByZeroException` for no points. The guards of section 1 item 2 give
    the upstream results.
  - 6000 random stack charts (3 seeds; offsets 0, 3.5, -7, 1e6, ±1e12, 1e15 and 2^52; gaps and
    source moves at the epsilon 1e-6 and at the `delta`; skipped points, `spanGaps`, stepped
    lines; lines that go back, repeat an `x` or have an `undefined` or NaN `x`): 12051 stack lines
    of the port, with the window form on and off, equal to the upstream stack lines (the same
    point elements of the lines below by index, else `x` and `y`; an Array result of
    `interpolate` counts as the bare point of Chart.js ADR 0040 §2). The window form ran in 15797
    of the 25620 lookups with the window on, with 145289 window calls.
  - A mutation that turns the window form off left all filler tests green before the group
    `adapt-stack-line-window` had its count of point reads (section 5). Now that group fails.
