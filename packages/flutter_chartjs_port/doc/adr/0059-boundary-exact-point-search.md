# Chart.js ADR 0059: Exact endpoints of private fill boundaries

- Status: implemented; bounded Android validation.
- Date: 2026-11-02
- Related: ADR 0040 (filler), ADR 0058 (stack endpoint search).

## Decision

In `drawfill`, capture whether the requested target is a linear `origin`, `start`
or `end` boundary before `getTarget` can invoke a scale or user code. These modes
create a fresh `LineElement` with copied boundary points and fixed options. It is
local to that draw and is never given to user code. Dataset targets, stack targets,
radial boundaries and other fill forms do not enter this optimization.

For a boundary with at least four ordinary points, validate once that the varying
coordinate is finite and strictly increasing, the other coordinate is a finite
constant, and no point is skipped or stopped. Adjacent coordinates must differ by
more than `1e-5 + (abs(a) + abs(b)) * 1e-12`, conservatively beyond the original
segment tolerance. Duplicates, singleton-gap boundary pairs, reversed coordinates,
loops, non-finite values and near-equal coordinates retain the original path.

During the fill, binary search only for exact endpoint matches. A match returns
the same existing point as `LineElement.interpolate` would return for the sole
bound segment `[i, i]`. A miss uses the original interpolation, including its
arithmetic and epsilon behavior. The source matching, clip calls, path geometry,
fill order and public API do not change. Both color passes can share the index
because no callback can reach this fresh target. Rebuild it on every draw.

The new helper is port-only and pure Dart. The only ported file edited is
`filler.drawing.dart`, marked `adapt-boundary-exact-points`. Shared segment scanning,
`LineElement.interpolate`, stack search and canvas implementations are unchanged.
This removes repeated interpolation scans; matching source segments to the target
still scans the boundary, so the complete algorithm is not made linear.

## Evidence and protocol

The Android baseline profile puts 66.9% of samples under `boundSegments`, 64.5%
under `boundSegment` and 45.2% under `interpolatedLineTo` (inclusive shares overlap).
See performance.md chapter 24 and the retained experiment under
`benchmarks/boundary-exact-points/`.

The release protocol was written before timing: Pixel 8a, A/B/B/A, ten cells,
controls before gap fills, nine 150 ms batches after 500 ms warmup. The primary
question is material gain at N=1000 in both pairs, without a repeatable control
slowdown exceeding both 0.1 ms and 5%. Two pairs establish direction only; they do
not provide a confidence interval or a GPU/FPS claim.

Correctness compares endpoint identity against original interpolation for 200
seeded boundaries on both axes. Guards cover duplicates, epsilon-near and large
coordinates, reversed/non-finite/nonconstant boundaries, custom getters and misses.
Real charts compare every drawing command for the three boundary modes on both
axes, normal and reversed scales, curved/stepped sources and mutations between
updates. Existing filler references and fixtures remain the upstream oracle.

## Android outcome

The planned release comparison passes: at N=1000, draw CPU time is 10.704 to
5.339 ms (-50.1%), and full-update time is 14.914 to 8.183 ms (-45.1%). Both
pairs show a large gain. The only slower control is ordinary-line update,
+0.0165 ms (+2.0%), below the protocol threshold. No run was discarded. Battery
readings were 29.2–29.4 °C and thermal status was 0 before and after each run.
Keep the implementation, with no claim about GPU time, FPS or other platforms'
performance. Chapter 24 records validation and the bounded-run limitations.
