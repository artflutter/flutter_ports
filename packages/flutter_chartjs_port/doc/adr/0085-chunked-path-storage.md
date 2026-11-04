# Chart.js ADR 0085: Bounded chunks for unobserved paths

- Date: 2026-11-04
- Status: implemented; validation and native measurements accompany the change.
- Related: ADR 0084; performance.md §§56–57.

## Decision

Keep ADR 0084's private compact move/line/close representation, but bound buffer
growth. The first chunk starts at 16 commands and doubles to 1,024. Once full,
it is retained and a fresh 1,024-command chunk is allocated. Appending later
commands never recopies a completed chunk. Short paths keep the small start;
there is no reservation based on a dataset's possibly misleading point count.

Each Path2D owns its buffers and completed-chunk lists. Nothing is pooled across
paths: an old path may be retained and inspected later. Native replay visits
completed chunks followed by the used portion of the current chunk, retaining
exact command order and coordinates. Chunk size is a private implementation
choice, not a public option.

The first commands read or complex command materializes the same ordinary
mutable, growable List<PathCommand> as ADR 0084. Materialization releases private
chunk references. Later appends and public/custom replay use that list. Its
identity, live replacement and platform-specific count-mutation behavior remain.
The existing version/cache contract is unchanged, including same-length list
mutations. Native scalar replay retains its synchronous, non-observing builder
precondition. No callback-visible object or buffer is recycled.

## Scope

Only canvas.dart changes in the production runtime. There is no line-controller
or line-element change, capacity hint, new public API, data-only eligibility
change, command omission, native drawing cut or altered raster operation.

## Evidence

The [triage](../benchmarks/path-growth/README.md) compared contiguous, reserved
and chunked storage. [Production evidence](../benchmarks/path-chunks/README.md)
records broader compatibility and native checks. Boundary tests include empty,
small, exact-chunk, multi-chunk and 50k-command paths, mixed commands, retained
old paths, later exposure/clearing and native cache behavior. Existing mutation,
non-finite/signed-zero and pixel regressions remain in force.
