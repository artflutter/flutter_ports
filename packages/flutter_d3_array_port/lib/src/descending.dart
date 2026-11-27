// Ported from d3-array v3.2.4 src/descending.js (ISC, Mike Bostock).

/// Port of `src/descending.js` of d3-array 3.2.4.
library;

/// Returns `-1` if [b] is less than [a], `1` if [b] is greater than [a],
/// `0` if equal, or `double.nan` if either value is `null` or `NaN`.
// DIVERGES(d3-array): adapt-array-typed-api, typed Comparable<Object> with
// IEEE NaN handling.
@pragma('vm:prefer-inline')
double descending<T extends Comparable<Object>>(T? a, T? b) {
  if (a == null || b == null) return double.nan;
  if (a is num && b is num) {
    return b < a ? -1.0 : (b > a ? 1.0 : (b >= a ? 0.0 : double.nan));
  }
  final c = b.compareTo(a);
  return c < 0 ? -1.0 : (c > 0 ? 1.0 : 0.0);
}
