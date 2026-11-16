// Ported from d3-interpolate v3.0.1 src/date.js (ISC, Mike Bostock).

/// Port of `src/date.js` of d3-interpolate 3.0.1: the interpolator of two
/// dates.
library;

/// date.js:1 the default export (`interpolateDate` of index.js:5): the
/// interpolator from the date [a] to the date [b].
///
/// Upstream interpolates the milliseconds since the epoch with
/// `a * (1 - t) + b * t`, truncates the result toward zero (`setTime`) and
/// writes it into one `Date` that each call returns. Here each call returns
/// a new [DateTime] (a [DateTime] is immutable), with the microseconds of
/// the dates: the milliseconds interpolate with the upstream line, the
/// microseconds within the millisecond (`microsecond`) with the same line,
/// and the sum in microseconds truncates toward zero. Thus `t = 0` gives
/// exactly [a] and `t = 1` exactly [b], over the whole range of [DateTime].
/// The result is in UTC when [b] is.
///
/// A NaN or infinite result throws an [UnsupportedError] and a result
/// outside the range of [DateTime] (±8.64e15 milliseconds) a [RangeError],
/// where upstream returns an invalid `Date`.
///
/// ```dart
/// final i = interpolateDate(DateTime.utc(2000), DateTime.utc(2000, 1, 2));
/// i(0.5); // 2000-01-01 12:00:00.000Z
/// ```
DateTime Function(double t) interpolateDate(DateTime a, DateTime b) {
  // DIVERGES(d3-interpolate): adapt-interpolate-date-value, microseconds.
  // millisecondsSinceEpoch is the floor of the microseconds / 1000, and
  // microsecond is in [0, 999]: their sum is the time of the date.
  final am = a.millisecondsSinceEpoch.toDouble();
  final bm = b.millisecondsSinceEpoch.toDouble();
  final au = a.microsecond.toDouble();
  final bu = b.microsecond.toDouble();
  final isUtc = b.isUtc;
  return (t) {
    // The milliseconds (date.js:4) and the microseconds of the millisecond.
    final m = am * (1 - t) + bm * t;
    final u = au * (1 - t) + bu * t;
    // The time is 1000 * f + r microseconds, with a whole f.
    final f = m.floorToDouble();
    final r = (m - f) * 1000 + u;
    if (!(f.abs() < 1e16 && r.abs() < 1e18)) {
      // NaN, an infinity, or a time far outside the range of DateTime: the
      // time in doubles. toInt() throws for NaN and the infinities, and the
      // constructor throws its RangeError outside the range.
      return DateTime.fromMicrosecondsSinceEpoch(
        (1000 * f + r).toInt(),
        isUtc: isUtc,
      );
    }
    // Truncate toward zero: down for a time at or above 0, else up.
    final k = 1000 * f + r >= 0 ? r.floor() : r.ceil();
    final ms = f.toInt() + k ~/ 1000;
    final us = k.remainder(1000);
    // A whole millisecond needs no microseconds: on the web, a time in
    // microseconds beyond 2^53 does not hold its last digits.
    return us == 0 || ms.abs() > _maxMilliseconds
        ? DateTime.fromMillisecondsSinceEpoch(ms, isUtc: isUtc)
        : DateTime.fromMicrosecondsSinceEpoch(ms * 1000 + us, isUtc: isUtc);
  };
}

/// The largest time of a [DateTime] in milliseconds from the epoch: 100
/// million days. Beyond it, `ms * 1000` can leave the 64-bit integers, so
/// [DateTime.fromMillisecondsSinceEpoch] throws its [RangeError] first.
const int _maxMilliseconds = 8640000000000000;
