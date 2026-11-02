# Chart.js ADR 0060: Exact segment bounds on private fill boundaries

- Status: implemented; bounded Android validation.
- Date: 2026-11-02
- Related: ADR 0059 (private boundary endpoint search), ADR 0040 (filler).

## Decision

Extend the per-draw BoundaryPointSearch of ADR 0059 to match target segment
bounds. Only the same fresh origin/start/end linear targets qualify: native
points, constant finite secondary coordinate, finite strictly increasing primary
coordinates beyond the tolerance margin, no skipped/stopped points and no loop.
These targets have fixed options and no segment style. They cannot be reached by
user code during the draw. No dataset target or arbitrary user line is indexed.

For finite ascending bounds whose two values exactly match target points, return
the single native segment with those indices, loop false and absent style. The
unchanged boundSegments algorithm returns the same fields. A forward cursor
advances across ordered ranges; backward or overlapping ranges use binary search.
The second color pass can safely reuse the index. Missing, reversed, non-finite,
wrong-axis and loop bounds retain the original scan. An unmatched query may move
the cursor but cannot invalidate a later query.

Only the target search changes. Source boundSegment calls and all source reads,
styles, clipping, interpolation and drawing order stay in place. Rebuild the
private index on every draw; never keep it on a chart. The internal
createBoundarySegment factory uses the existing private _Segment class, avoiding
a new implementer. lib/helpers.dart hides the factory; the public API is unchanged.
Shared boundSegment/boundSegments loops are unchanged.

## Evidence and protocol

Baseline e942d50 includes ADR 0059. On the connected Pixel 8a, its CPU profile
collects 13,025 samples. Inclusive shares: segments 50.3%, boundSegments 43.7%,
and boundSegment 44.6%; shares overlap. boundSegment self time is 26.0%.
The workload is fill.gaps drawing, three datasets of 1000 points.

The prewritten protocol in benchmarks/boundary-segment-search/protocol.md uses
release A/B/B/A, ten cells with controls first, nine 150 ms batches and 500 ms
warmup. Compare total drawing/update CPU time, including recording completion.
Require material primary gains in both pairs and no repeatable guard slowdown
over both 0.1 ms and 5%. Two pairs give direction only, with no GPU/FPS claim.

## Correctness

Two hundred generated boundaries on both axes compare ordered, overlapping,
backward, repeated and single-point exact bounds against the original scanner,
including the native segment type and all fields. Two hundred generated source
cases compare complete fill parts for both color passes, including source
coordinate mutations after target creation. Misses, tolerance-near endpoints,
non-finite/reversed/unsupported bounds and cursor recovery use the original path.
Existing real charts compare every draw command with both optimizations disabled,
with only the previous endpoint optimization, and with both enabled. Custom dataset
callbacks and the public export list remain covered.

## Android outcome

The planned release comparison passes. At N=1000, draw CPU time is 5.298 to
2.882 ms (-45.6%) and full-update time is 8.5565 to 5.992 ms (-30.0%). Both
pairs improve; full-update reductions vary from 21.5% to 37.8%. The largest
slower aggregate control is stack update, +0.185 ms (+2.3%), below the combined
threshold. Its pairs are inconsistent: -3.5% time in one, +8.4% (+0.663 ms) in
the other. The slowdown is not repeatable by the protocol, and its cause is
unestablished; the comparison does not prove zero regression.
No run was discarded; battery readings were 29.0–29.4 °C and thermal status was
0 before/after all runs. Retain the implementation with these bounded CPU
measurements. Performance.md chapter 25 and the reproduction package retain
individual process results, including control shifts. No GPU/FPS or other-device
performance claim is made.
