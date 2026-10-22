// Original code, not ported from Chart.js: the zones of the date adapter.

/// The time zones of the default date adapter (Chart.js ADR 0024, decision
/// 3).
///
/// The calendar functions of `date_calendar.dart` work on wall time: the
/// wall fields of a zone, coded as UTC milliseconds. A [DateZone] converts
/// between an instant and its wall time. UTC has no zone object: the
/// calendar functions get `null` for it.
///
/// [LocalZone] gives the offsets of the platform. It keeps one interval of
/// instants with one offset, because a local `DateTime` costs about 1 µs on
/// AOT and on dart2wasm (Chart.js ADR 0024, fact 3).
///
/// This library is a pure layer. It imports neither `dart:ui` nor
/// `package:flutter`.
library;

import 'package:flutter_chartjs_port/src/core/date_calendar.dart'
    show daysFromCivil;
import 'package:meta/meta.dart';

/// One day in milliseconds.
const int _day = 86400000;

/// The largest time value of a JS `Date` in milliseconds.
const int _maxTime = 8640000000000000;

/// A time zone of the default date adapter. The calendar functions get
/// `null` for UTC.
abstract interface class DateZone {
  /// The offset of the instant [t] in ms. The wall time is `t + offsetAt(t)`.
  int offsetAt(int t);

  /// The instant of the wall time [wall] (the wall fields coded as UTC ms).
  /// A repeated wall time gives the earlier instant. A skipped wall time uses
  /// the offset before the change. This is the rule of JS `Date`.
  int fromWall(int wall);
}

/// The local zone of the platform, with one cached interval of instants
/// with one offset.
///
/// The cache rule: when the offsets at `t - 1 day`, `t` and `t + 1 day` are
/// equal, the offset is constant from `t - 1 day` to `t + 1 day`. The rule
/// is exact when no two offset changes of the zone are less than 48 hours
/// apart. In 1902-2037, the smallest gap between two offset changes of a
/// zone of the tz data is 167 hours (Chart.js ADR 0024, fact 3).
///
/// The default `formats` member clears the cache once in each chart update
/// (decision 3). Thus a change of the platform zone reaches the next update.
final class LocalZone implements DateZone {
  LocalZone._(this._offsetOf);

  /// A zone with the cache rule and the rule of [fromWall] of the local
  /// zone, on the offsets [offsetOf] in place of the offsets of the
  /// platform. The tests run the code of the local zone with the offset
  /// changes of a table, also on a machine in UTC.
  @visibleForTesting
  LocalZone.withOffsets(int Function(int t) offsetOf) : this._(offsetOf);

  /// The one local zone.
  static final LocalZone instance = LocalZone._(_platformOffset);

  /// The offset at an instant: [_platformOffset] for [instance].
  final int Function(int t) _offsetOf;

  /// The first instant of the cached interval. The interval is empty when
  /// [_lo] is larger than [_hi].
  int _lo = 1;

  /// The last instant of the cached interval.
  int _hi = 0;

  /// The offset of each instant of the cached interval.
  int _offset = 0;

  /// The cached interval: its first and last instant and its offset, or
  /// `null` when it is empty.
  @visibleForTesting
  ({int first, int last, int offset})? get cachedInterval =>
      _lo <= _hi ? (first: _lo, last: _hi, offset: _offset) : null;

  /// Clears the cached interval.
  void clear() {
    _lo = 1;
    _hi = 0;
  }

  @override
  int offsetAt(int t) {
    if (t >= _lo && t <= _hi) return _offset;
    final offsetOf = _offsetOf;
    final offset = offsetOf(t);
    if (offsetOf(t - _day) == offset && offsetOf(t + _day) == offset) {
      final lo = t - _day;
      final hi = t + _day;
      if (offset == _offset && _lo <= _hi && lo <= _hi + 1 && hi >= _lo - 1) {
        // The two intervals touch, and both have the same offset.
        if (lo < _lo) _lo = lo;
        if (hi > _hi) _hi = hi;
      } else {
        _lo = lo;
        _hi = hi;
        _offset = offset;
      }
    }
    return offset;
  }

  @override
  int fromWall(int wall) {
    final before = offsetAt(wall - _day);
    final after = offsetAt(wall + _day);
    final early = wall - before;
    // No offset change from `wall - 1 day` to `wall + 1 day`: one instant.
    if (before == after) return early;
    final late = wall - after;
    final earlyFits = offsetAt(early) == before;
    final lateFits = offsetAt(late) == after;
    // A repeated wall time: the earlier instant.
    if (earlyFits && lateFits) return early < late ? early : late;
    if (earlyFits) return early;
    if (lateFits) return late;
    // A skipped wall time: the offset before the change.
    return early;
  }
}

/// The offset of the platform at the instant [t] in ms: the UTC milliseconds
/// of the local fields of [t], minus [t].
///
/// It does not read `timeZoneOffset`: dart2js gives it in whole minutes,
/// and the local fields keep the seconds of a local mean time offset
/// (Chart.js ADR 0024, fact 3). An instant outside the range of a JS `Date`
/// reads the offset at the nearest end of the range.
// DIVERGES(chartjs): platform-date-local-offset, the offsets of the platform.
int _platformOffset(int t) {
  final instant = t > _maxTime ? _maxTime : (t < -_maxTime ? -_maxTime : t);
  final local = DateTime.fromMillisecondsSinceEpoch(instant);
  // The day number, not `DateTime.utc`: the local fields of the last
  // instants are outside the range of `DateTime`.
  final wall =
      daysFromCivil(local.year, local.month, local.day) * _day +
      local.hour * 3600000 +
      local.minute * 60000 +
      local.second * 1000 +
      local.millisecond;
  return wall - instant;
}

/// The offset of [t] in whole minutes, truncated toward zero, in ms: the
/// offset of V8 `getTimezoneOffset()` (moment.js:3294-3298). [zone] `null`
/// is UTC and gives 0.
///
/// moment reads this offset for the hour floor of `startOf` and `endOf`
/// (moment.js:4135-4141) and for the zone delta of `diff` (:3860).
int wholeMinuteOffset(DateZone? zone, int t) =>
    zone == null ? 0 : (zone.offsetAt(t) ~/ 60000) * 60000;
