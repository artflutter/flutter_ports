# Chart.js ADR 0087: Shared native point contracts and preparation

- Date: 2026-11-05
- Status: implemented; VM, JavaScript, WebAssembly and port checks pass.
- Related: ADRs 0079, 0080, 0082, 0086.

## Decision

Consolidate the line/scatter native point-option family around one set of
predicates and preparation functions. Keep general capability/value contracts
in the framework-free point_options.dart. Keep controller/config orchestration
in point_option_preparation.dart, which imports DatasetController and is not
framework-free. Controllers retain their exact-class gates and the observation
points of their ordinary loops.

This is an architectural refactor, with no new eligible inputs or cache. It does
not promise a speedup. Existing native wrappers and component opt-ins keep the
same capability interfaces and getters; no public library API changes.

## Guarantees and lifetimes

| Fact | Authority | Lifetime / use rule |
| --- | --- | --- |
| SDK map implementation | nativeDataUpdateObject and ADR 0086 weak identities | Same native object; coordinate values are not part of the proof. |
| Chart/point capability | nativePointChart / nativePointElement | Read at the current observation point; explicit wrapper opt-ins are not cached. |
| Numeric projection | nativePointProjection, using the existing BulkBarScale capability | Capability only; scale/chart ownership is checked afterward. No grid-purity promise. |
| Point class and dataset index | nativePointClass / nativePointDatasetIndex | Current class metadata and an index already read from an exact controller. |
| Permission to attempt update preparation | canPrepareNativePointUpdate | Already-read mode/options/axes/range values only; it does not qualify points or sources. |
| Indexed color plan | prepareNativePointColors and Config/resolver preparation | One synchronous loop; stop before active/custom points or foreign conversion. |
| Resolver source snapshot | NativePointResolution.resolve | Validate on every call before the executor or either context factory. |
| Changes during callbacks | Existing Config/resolver generation and continuation checks | Retain their original per-use/per-key observation points inside execution. |
| Coordinate values/routes | NativePointCoordinates | Re-read at the original iteration, even on an identity-cache hit. |

There is deliberately no global native/safe flag. Container allowlists remain
with their existing authorities. Bar-specific grid, topology and direct-write
contracts retain their narrower requirements; a point projection guarantee
cannot authorize any of those operations. Data-only eligibility is unchanged.

## Shared preparation and ordering

Line update, scatter update and scatter overflow use the same indexed point
preparation function after their exact-controller gate. That function preserves
the short-circuit order: chart capability; owned point list; parsed list; point
class and dataset index; exact Config; existing warmed resolver preparation.
The controller type is passed explicitly, preserving distinct line/scatter
scope keys. The line resolver preparation shares chart/class/index predicates
but retains its own cache/source requirements.

Only native field reads are combined by the extraction: the exact-controller
gate excludes overriding getters on controller subclasses. Capability getters,
custom-container rejection, config lookup and context factories remain at their
original stages. Projection ownership stays at the caller so an owner read is
not eagerly evaluated before a declined projection capability.

Activity is intentionally separate from the point capability: scatter overflow
may measure active points, while prepared update loops must stop before an
active callback. The line loop still checks activity before its parsed-item
read; scatter retains its original parsed read before that activity check.
Preparation is still attempted once, after two ordinary resolutions. Neither
loop resumes its indexed plan after a fallback.

## Resolution plans validate themselves

NativePointResolution keeps its executor private. Its resolve method always
calls the source validator first and returns null on rejection, before invoking
the executor or either context factory. Config no longer has to remember to
wrap each executor with this entry check. valid remains available for diagnostic
tests; calling it is not a caller precondition for resolve.

This entry check does not replace the existing generation checks during
callbacks. Invalidation, key ordering, non-scalar returns and continuation still
belong to the resolver, where mutation can actually occur. Validator/executor
exceptions propagate unchanged.

## Adding another shortcut

Use an existing predicate when its guarantee and lifetime match the new read.
A narrower operation requirement stays explicit at its observation point. Do
not widen an allowlist or capability just to make two callers share a helper.
Pass already-read scalar inputs to common prerequisites; keep effectful reads
behind their original short circuits. A new executable plan should own its
entry validator, while checks needed during callbacks stay inside execution.
Regression tests should pin the decline path and observable read/callback order,
not just the successful shortcut.

## Validation

Shared contract tests cover changing capabilities/class metadata, projection
versus grid/ownership scope, self-validation before contexts/execution, and
validator exceptions. Existing chart twins and resolver tests cover active and
custom points, effectful coordinates, routes, source/config mutation, partial
ranges, fresh options, context ordering and warm cache lifecycle.

VM/browser/port results and matched native performance checks are recorded in
[the verification report](../benchmarks/native-contracts/README.md). The native
comparison checks for regressions; it is not a new speedup claim.
