# Chart.js ADR 0083: Ordered varying colors and scalar callbacks

- Date: 2026-11-04
- Status: implemented; validation and production measurements are recorded with evidence.
- Related: ADRs 0078, 0080–0082; performance.md §51 estimates.

## Decision

A native scriptable element plan retains an ordered list of color operations:
key, callback and original position. Its full key snapshot remains available for
ordinary continuation. Static fields still come from a private template and each
returned options object remains fresh. Only the varying colors are visited on
the unchanged-plan path; no callback result is memoized.

Exactly-one-argument callbacks use a separate scalar loop without closures that
capture per-point descriptor/view state. Its descriptor inputs are the immutable
references already held in the raw resolver cache when the plan is constructed.
Raw writes/deletes invalidate that plan; context-time validation remains before
its use. Mutable descriptor input objects, where applicable, retain their original
reference rather than being copied.

A non-scalar return enters the original post-call array/subresolver processing
without restarting the primary callback invocation. If a callback or an audited store changes
the raw resolver, continuation starts at the next original key, including static
keys between or after the colors. Already-resolved earlier fields are retained.
Views and descriptor objects are created fresh with the original snapshot.

Callbacks accepting options or a JsFunction receiver retain normal contextual
views and invocation. They also visit only varying keys until invalidation, then
walk the remaining original keys. Existing guard eligibility, shared flags,
context timing, exceptions, foreign values, key order and reentrant behavior are
unchanged. The full key list is not replaced by the varying list.

## Scope and evidence

This implements proposals 1 and 2 from the three-estimates investigation.
The native-circle/packing prototypes are not part of this implementation. Their
cold-start discrepancy was reproduced in the unchanged renderer as well;
matched baseline/prototype startup stages have identical pixels and commands.
The engine startup cause is not yet identified. Renderer production integration
and its validation remain separate work.

See [production evidence](../benchmarks/color-resolution/README.md). Tests compare
ordinary Config twins for one/two/this-aware callbacks, two varying colors,
intervening and trailing static changes, descriptor mutation, changed indexes,
arrays/objects, cache clear/deletion, audited stores, thrown errors and existing
context/root-source invalidation. Legacy virtual methods and public exports are
unchanged. Production contains no experiment switches.
