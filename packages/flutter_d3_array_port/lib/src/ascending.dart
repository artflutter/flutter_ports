// Ported from d3-array v3.2.4 src/ascending.js (ISC, Mike Bostock).

/// Port of `src/ascending.js` of d3-array 3.2.4.
library;

/// Returns `-1` if [a] is less than [b], `1` if [a] is greater than [b],
/// `0` if equal, or `double.nan` if either value is `null` or `NaN`.
// DIVERGES(d3-array): adapt-array-typed-api, typed Comparable<Object> with
// IEEE NaN handling (unlike Dart's double.compareTo where NaN > Infinity).
@pragma('vm:prefer-inline')
double ascending<T extends Comparable<Object>>(T? a, T? b) {
  if (a == null || b == null) return double.nan;
  if (a is num && b is num) {
    return a < b ? -1.0 : (a > b ? 1.0 : (a >= b ? 0.0 : double.nan));
  }
  final c = a.compareTo(b);
  return c < 0 ? -1.0 : (c > 0 ? 1.0 : 0.0);
}
