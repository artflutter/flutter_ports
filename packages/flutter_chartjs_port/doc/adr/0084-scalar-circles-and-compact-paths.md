# Chart.js ADR 0084: Scalar circles and compact unobserved paths

- Date: 2026-11-04
- Status: implemented; native measurements and validation accompany the change.
- Related: ADR 0083; performance.md §§54–55; canvas-cuts-plan.md N1–N5.

## Decision

The native context reads a recognized full circle through scalar getters on
UiPathBuilder and passes x/y/radius directly to its private batch entry. The
existing singleCircle record getter remains available. Recognition, transforms,
paint setup, batching eligibility, fill/stroke order, native drawing calls and
fallbacks are unchanged. This removes temporary geometry records and their
numeric boxing on the ordinary native circle path.

Path2D privately packs moveTo/lineTo/closePath commands into growable numeric
buffers until an observer needs command objects. Float64 storage retains the
coordinate values, including signed zero and non-finite values. The first read
of commands materializes one ordinary growable List<PathCommand>; all later
reads return that list and subsequent writes append directly to it. A complex
command also materializes the list, after its existing argument validation.
The public version remains the command count, including after list mutation.

Public replay always uses the ordinary list iterator, preserving live command
replacement, exceptions and platform-specific list-length mutation behavior. Only
uiPathOf, which constructs the exact synchronous native UiPathBuilder, uses the
internal scalar replay. It cannot execute user callbacks or inspect the source
path. If commands are already exposed or mixed, native replay uses the ordinary
path too. Native conversion still caches by the existing path/version contract.
No command object that a user can retain is pooled or reused.

## Scope

No chart/controller algorithm, option callback, data-only guard, path observation
point, circle quantization or atlas command order changes. Connected lines keep
their existing path invalidation and lifetime. This changes storage and argument
transport, not the Canvas 2D operations or the N1–N5 drawing cuts.

The raw Path2D command list remains mutable with stable identity; changing a
command without changing list length retains the prior version/cache behavior.
This pass deliberately does not redesign that pre-existing public contract.

## Evidence

[Native timing, GC and pixel evidence](../benchmarks/circle-path/README.md).
Regressions cover large compact paths, mixed commands, signed zero/non-finite
coordinates, list exposure/identity, retained command objects, custom replay
mutation and self replay, native caching, and exact native-path pixels/contours.
Existing circle rendering tests cover transforms, compositing, batching,
clipping, invalid geometry and fallback cases. No experiment switches are in
the production library.
