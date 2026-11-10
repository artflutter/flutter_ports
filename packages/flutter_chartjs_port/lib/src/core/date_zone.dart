// Original code, not ported from Chart.js: the zones of the date adapter.

/// The time zones of the default date adapter (Chart.js ADR 0024, decision
/// 3).
///
/// The calendar functions of `date_calendar.dart` work on wall time: the
/// wall fields of a zone, coded as UTC milliseconds. A [DateZone] converts
/// between an instant and its wall time. UTC has no zone object: the
/// calendar functions get `null` for it.
///
/// [LocalZone] gives the offsets of the platform. It keeps up to 64 intervals
/// of instants with one offset each, because a local `DateTime` costs about
/// 1 µs on AOT and on dart2wasm (Chart.js ADR 0024, fact 3, and Chart.js ADR
/// 0110).
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

/// Whether the code runs on the web (dart2js, DDC or dart2wasm).
const bool _onWeb = bool.fromEnvironment('dart.library.js_interop');

/// The number of cached intervals of [LocalZone] (Chart.js ADR 0110): more
/// than the ticks that a time scale generates in one update before its auto
/// skip, about 33-58 in the zoom benchmark.
const int _intervalSlots = 64;

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

/// The local zone of the platform, with up to 64 cached intervals of instants
/// with one offset each.
///
/// The cache rule: when the offsets at `t - 1 day`, `t` and `t + 1 day` are
/// equal, the offset is constant from `t - 1 day` to `t + 1 day`. The rule
/// is exact when no two offset changes of the zone are less than 48 hours
/// apart. In 1902-2037, the smallest gap between two offset changes of a
/// zone of the tz data is 167 hours (Chart.js ADR 0024, fact 3).
///
/// Each cached interval comes from this rule, or from two such intervals of
/// one offset that overlap or touch. The cache keeps up to 64 of them
/// (Chart.js ADR 0110). A new interval takes the slot of the oldest one
/// when all slots are in use. Thus the label pass of a time scale finds the
/// offsets that the tick generation of the same update asked for.
///
/// The default `formats` member clears the cache once in each chart update
/// (Chart.js ADR 0024, decision 3). Thus a change of the platform zone
/// reaches the next update.
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

  /// The first instant of the interval of each slot. A slot is empty when
  /// its first instant is larger than its last instant.
  final List<int> _firsts = List<int>.filled(_intervalSlots, 1);

  /// The last instant of the interval of each slot.
  final List<int> _lasts = List<int>.filled(_intervalSlots, 0);

  /// The offset of each instant of the interval of each slot.
  final List<int> _offsets = List<int>.filled(_intervalSlots, 0);

  /// The number of slots in use: the slots `0` to `_count - 1`.
  int _count = 0;

  /// The slot of the next new interval when all slots are in use: the
  /// oldest new interval.
  int _next = 0;

  /// The slot of the last hit or of the last new interval. The calendar
  /// functions ask for close instants in a row.
  int _last = 0;

  /// The cached intervals in the order of their slots: their first and last
  /// instant and their offset. Empty after [clear].
  @visibleForTesting
  List<({int first, int last, int offset})> get cachedIntervals => [
    for (var i = 0; i < _count; i++)
      (first: _firsts[i], last: _lasts[i], offset: _offsets[i]),
  ];

  /// Clears the cached intervals.
  void clear() {
    for (var i = 0; i < _count; i++) {
      _firsts[i] = 1;
      _lasts[i] = 0;
    }
    _count = 0;
    _next = 0;
    _last = 0;
  }

  @override
  int offsetAt(int t) {
    final firsts = _firsts;
    final lasts = _lasts;
    // The slot of the last hit, then the slots after it, then the slots
    // before it.
    final last = _last;
    if (t >= firsts[last] && t <= lasts[last]) return _offsets[last];
    final count = _count;
    for (var i = last + 1; i < count; i++) {
      if (t >= firsts[i] && t <= lasts[i]) {
        _last = i;
        return _offsets[i];
      }
    }
    for (var i = 0; i < last && i < count; i++) {
      if (t >= firsts[i] && t <= lasts[i]) {
        _last = i;
        return _offsets[i];
      }
    }
    final offsetOf = _offsetOf;
    final offset = offsetOf(t);
    if (offsetOf(t - _day) == offset && offsetOf(t + _day) == offset) {
      _add(t - _day, t + _day, offset);
    }
    return offset;
  }

  /// Caches the interval from [first] to [last] with the offset [offset].
  ///
  /// An interval of the same offset that overlaps or touches it grows to
  /// the union of the two, which has the offset at each instant. Else the
  /// interval takes a free slot, or the slot of the oldest new interval.
  void _add(int first, int last, int offset) {
    final firsts = _firsts;
    final lasts = _lasts;
    final offsets = _offsets;
    for (var i = 0; i < _count; i++) {
      if (offsets[i] == offset &&
          first <= lasts[i] + 1 &&
          last >= firsts[i] - 1) {
        // The two intervals touch, and both have the same offset.
        if (first < firsts[i]) firsts[i] = first;
        if (last > lasts[i]) lasts[i] = last;
        _last = i;
        return;
      }
    }
    final int slot;
    if (_count < _intervalSlots) {
      slot = _count++;
    } else {
      slot = _next;
      _next = slot + 1 == _intervalSlots ? 0 : slot + 1;
    }
    firsts[slot] = first;
    lasts[slot] = last;
    offsets[slot] = offset;
    _last = slot;
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

/// The offset of the platform at the instant [t] in ms. An instant outside
/// the range of a JS `Date` reads the offset at the nearest end of the
/// range.
///
/// On the web, it is the UTC milliseconds of the local fields of [t], minus
/// [t]. It does not read `timeZoneOffset` there: dart2js gives it in whole
/// minutes, and the local fields keep the seconds of a local mean time
/// offset (Chart.js ADR 0024, fact 3).
///
/// On the VM, it is `timeZoneOffset` in ms: one call of the platform. The
/// VM computes the local fields from the instant plus the same offset in
/// whole seconds, so the two forms give the same value (Chart.js ADR 0110).
// DIVERGES(chartjs): platform-date-local-offset, the offsets of the platform.
int _platformOffset(int t) {
  final instant = t > _maxTime ? _maxTime : (t < -_maxTime ? -_maxTime : t);
  final local = DateTime.fromMillisecondsSinceEpoch(instant);
  if (!_onWeb) return local.timeZoneOffset.inMilliseconds;
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
