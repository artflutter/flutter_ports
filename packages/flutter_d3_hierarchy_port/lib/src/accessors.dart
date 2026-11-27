// Ported from d3-hierarchy v3.1.2 src/accessors.js (ISC, Mike Bostock).

/// Port of `src/accessors.js` of d3-hierarchy 3.1.2.
library;

// DIVERGES(d3-hierarchy): adapt-hierarchy-typed-api, static Dart function
// types enforce callback validity at compile time.

/// Returns [f] when non-null, or `null` otherwise.
@pragma('vm:prefer-inline')
F? hierarchyOptional<F extends Function>(F? f) => f;

/// Returns [f] unchanged (non-null function enforced statically).
@pragma('vm:prefer-inline')
F hierarchyRequired<F extends Function>(F f) => f;
