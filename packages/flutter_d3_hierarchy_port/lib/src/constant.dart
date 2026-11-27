// Ported from d3-hierarchy v3.1.2 src/constant.js (ISC, Mike Bostock).

/// Port of `src/constant.js` of d3-hierarchy 3.1.2.
library;

// DIVERGES(d3-hierarchy): adapt-hierarchy-typed-api, typed numeric constant
// accessors prefixed with `hierarchy*` to avoid collisions in flutter_d3_port.

/// Returns `0.0` for any node.
double hierarchyConstantZero<T>(T _) => 0;

/// Returns a constant accessor that always returns [x].
double Function(T) hierarchyConstant<T>(double x) =>
    (_) => x;
