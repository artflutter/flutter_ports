# Chart.js ADR 0086: Bounded weak map classification for line updates

- Date: 2026-11-05
- Status: implemented; VM, JavaScript, WebAssembly and port checks pass.
- Related: ADRs 0079, 0080, 0082; performance.md §58.

## Decision

Remember accepted native coordinate-map identities in a controller-owned array
of weak references, indexed by the absolute point index. Only the existing
native indexed-color window in LineController uses it. Each loop retains a fresh
NativePointCoordinates classifier; its last-type state is not shared across
updates. Scatter and other callers retain their ordinary loop-local behavior.

The original nativeDataUpdateObject contract remains the classification
authority: SDK map implementation types qualify, custom containers do not.
Like the existing type guards, it relies on truthful runtimeType metadata; this
change does not introduce a general verifier for user objects impersonating SDK
implementation types. Custom type getters reporting their actual type preserve
the ordinary observations and exceptions. A cache hit clears the classifier's
previous last-type state so a preceding custom type cannot suppress the next
custom object's classification reads.

Identity reuse skips implementation classification only. Coordinate values are
read and checked at the original iteration on every visit. Null, undefined,
non-finite numbers and foreign values retain their existing behavior. Scopes
are not entered into the cache; their routes remain live. No coordinates,
options, context fields, callback results or projection results are memoized.

## Lifetime and allocation bound

A successful native color-plan preparation sizes the slot array to the current
point count and permits at most 1,024 new weak entries for that prepared loop.
Existing hits do not consume the budget. Growing/shrinking preserves only the
surviving prefix; replacement or collected targets miss by identity and take
ordinary qualification. Stable 20k input warms over roughly twenty updates.
Continually replaced input creates at most 1,024 weak entries per prepared loop.
There is no second data scan, hash/equality callback, or strong retention of old
user maps. The slot array is O(point count), independent of discarded datasets.

Unsupported modes/options clear storage before the loop. A loop that finishes
without a surviving native color plan clears storage afterward. An exception
may leave weak identities until the next update or controller collection; those
entries contain no coordinate values or reusable plan and cannot authorize an
unsupported path. Partial and nested updates use bounds-checked identity slots;
a fresh successful preparation is still required before any hit can be used.

## Behavior and scope

All existing point, coordinate, native projection, option, active-point and
callback guards remain. Two ordinary resolutions still precede preparation.
Fallback occurs at the same point, before a foreign conversion or callback can
make the prepared color plan stale. Fresh option identity, context setters,
geometry arithmetic and write ordering remain. Data-only eligibility is
unchanged. No public API is added.

## Evidence

The [triage](../benchmarks/indexed-update-triage/README.md) identified runtime
implementation-type retrieval as a larger cost than fresh options or numeric
projection. It also rejected uncapped weak-reference creation after measuring
replacement-data regressions. Production results are recorded separately in
[the verification report](../benchmarks/coordinate-cache/README.md).

Regressions exercise budget exhaustion/refill, mixed/replaced data, partial
ranges, growth/shrink, null/undefined/foreign/live coordinates, routed scopes,
custom getters and exceptions. Native-vs-ordinary chart twins warm the cache,
then change data topology, modes, styles, active callbacks and mutation order.
