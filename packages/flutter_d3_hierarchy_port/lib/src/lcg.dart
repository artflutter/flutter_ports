// Ported from d3-hierarchy v3.1.2 src/lcg.js (ISC, Mike Bostock).

/// Port of `src/lcg.js` of d3-hierarchy 3.1.2: deterministic linear
/// congruential generator used by `pack`, `packSiblings`, and `packEnclose`.
library;

// https://en.wikipedia.org/wiki/Linear_congruential_generator#Parameters_in_common_use
const int _a = 1664525;
const int _c = 1013904223;
const int _m = 4294967296; // 2^32

/// Returns a seeded deterministic LCG producing values in `[0, 1)`.
double Function() hierarchyLcg() {
  var s = 1;
  return () {
    s = (_a * s + _c) % _m;
    return s / _m;
  };
}
