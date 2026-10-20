// Original code, not ported from Chart.js: the calendar of the date adapter.

/// The calendar of the default date adapter (Chart.js ADR 0024, decision 4):
/// the unit aliases, TimeClip, the day numbers, `startOf`, `endOf`, `add`
/// and `diff`.
///
/// The functions give the results of chartjs-adapter-moment 1.0.1 on moment
/// 2.29.4. Each rule names its moment source. The code states the rules on
/// integer day numbers. It copies no moment code.
///
/// A time is a JS time value: an integral number of ms, or NaN for an
/// invalid date. A zone is a [DateZone], or `null` for UTC. The functions
/// work on wall time: the wall fields of the zone, coded as UTC ms. A wall
/// time goes back to an instant through [DateZone.fromWall]. A result
/// outside ±8.64e15 ms is NaN ([timeClip]).
///
/// This library is a pure layer. It imports neither `dart:ui` nor
/// `package:flutter`.
library;

import 'package:flutter_chartjs/src/core/date_zone.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';

/// One second in ms.
const int _second = 1000;

/// One minute in ms.
const int _minute = 60000;

/// One hour in ms.
const int _hour = 3600000;

/// One day in ms.
const int _day = 86400000;

/// The largest time value of a JS `Date` in ms.
const double _maxTime = 8640000000000000;

/// The largest day number that [_wallTime] accepts. The day numbers of the
/// valid times are in ±100,000,000. The margin keeps the wall times of the
/// last day.
const int _maxDays = 100000002;

/// The largest month count that a month step accepts. The valid times span
/// fewer than 6,600,000 months.
const double _maxMonths = 7000000;

/// The bias of the year in a packed civil date. It keeps each packed value
/// positive, so that the shifts and masks give the same results on the VM
/// and on the web.
const int _yearBias = 400000;

/// The unit that stands for the name of an `Object.prototype` member.
///
/// moment reads its alias table from a plain object (moment.js:633-644).
/// Thus `normalizeUnits('constructor')` gives the `Object` function, which
/// no unit case of moment knows.
const String _objectMember = 'Object.prototype member';

/// The aliases of moment `addUnitAlias` (moment.js:924, :1236, :1389,
/// :1390, :1465-1467, :1920, :4591-4592, :4692, :4719, :4750, :4781, :4803,
/// :4851). For each unit `U` with the short name `S`, the keys `lower(U)`,
/// `lower(U) + 's'` and `S` give `U`.
const Map<String, String> _aliases = {
  'millisecond': 'millisecond',
  'milliseconds': 'millisecond',
  'ms': 'millisecond',
  'second': 'second',
  'seconds': 'second',
  's': 'second',
  'minute': 'minute',
  'minutes': 'minute',
  'm': 'minute',
  'hour': 'hour',
  'hours': 'hour',
  'h': 'hour',
  'day': 'day',
  'days': 'day',
  'd': 'day',
  'date': 'date',
  'dates': 'date',
  'D': 'date',
  'week': 'week',
  'weeks': 'week',
  'w': 'week',
  'isoweek': 'isoWeek',
  'isoweeks': 'isoWeek',
  'W': 'isoWeek',
  'month': 'month',
  'months': 'month',
  'M': 'month',
  'quarter': 'quarter',
  'quarters': 'quarter',
  'Q': 'quarter',
  'year': 'year',
  'years': 'year',
  'y': 'year',
  'weekday': 'weekday',
  'weekdays': 'weekday',
  'e': 'weekday',
  'isoweekday': 'isoWeekday',
  'isoweekdays': 'isoWeekday',
  'E': 'isoWeekday',
  'dayofyear': 'dayOfYear',
  'dayofyears': 'dayOfYear',
  'DDD': 'dayOfYear',
  'weekyear': 'weekYear',
  'weekyears': 'weekYear',
  'gg': 'weekYear',
  'isoweekyear': 'isoWeekYear',
  'isoweekyears': 'isoWeekYear',
  'GG': 'isoWeekYear',
};

/// The names of the `Object.prototype` members that a plain object inherits
/// in V8.
const Set<String> _objectMembers = {
  'constructor',
  '__proto__',
  'toString',
  'valueOf',
  'hasOwnProperty',
  'isPrototypeOf',
  'propertyIsEnumerable',
  'toLocaleString',
  '__defineGetter__',
  '__defineSetter__',
  '__lookupGetter__',
  '__lookupSetter__',
};

/// moment `normalizeUnits` (moment.js:633-644): the unit of [unit], or null.
///
/// The lookup tries the string, then its JS lower case ([_lowerCase]). A
/// value that is not a `String` gives null (an unknown unit). The name of an
/// `Object.prototype` member gives a unit that no case knows: [startOfUnit]
/// and [endOfUnit] give NaN for it, [addUnit] returns the input, and
/// [diffUnit] gives the difference in ms.
String? normalizeDateUnit(Object? unit) {
  if (unit is! String) return null;
  return _alias(unit) ?? _alias(_lowerCase(unit));
}

/// The JS `toLowerCase` of [unit] for the alias lookup.
///
/// JS uses the full case mapping: `İ` (U+0130) gives `i` and U+0307. The
/// Dart VM gives `i` alone. A name with U+0307 is no alias. Thus a name with
/// `İ` stays as it is, and it is no alias, as in moment.
String _lowerCase(String unit) =>
    unit.contains('\u0130') ? unit : unit.toLowerCase();

/// The alias of [key], or null.
String? _alias(String key) =>
    _aliases[key] ?? (_objectMembers.contains(key) ? _objectMember : null);

/// ECMAScript TimeClip: NaN outside ±8.64e15, else the value truncated
/// toward zero. -0 gives 0.
double timeClip(double t) =>
    t.abs() <= _maxTime ? t.truncateToDouble() + 0.0 : double.nan;

/// TimeClip of an integral time.
double _clip(int t) =>
    t <= _maxTime && t >= -_maxTime ? t.toDouble() : double.nan;

/// The day number of a civil date (1970-01-01 is 0). [month] is 1-12. A
/// [day] outside the month counts on from day 1, as `Date.UTC` does.
///
/// The formula is the Gregorian rule of the proleptic calendar on integers.
int daysFromCivil(int year, int month, int day) {
  final y = month <= 2 ? year - 1 : year;
  final era = (y >= 0 ? y : y - 399) ~/ 400;
  final yearOfEra = y - era * 400;
  final monthFromMarch = month > 2 ? month - 3 : month + 9;
  final dayOfYear = (153 * monthFromMarch + 2) ~/ 5 + day - 1;
  final dayOfEra =
      yearOfEra * 365 + yearOfEra ~/ 4 - yearOfEra ~/ 100 + dayOfYear;
  return era * 146097 + dayOfEra - 719468;
}

/// The civil date of a day number (1970-01-01 is 0).
({int year, int month, int day}) civilFromDays(int days) {
  final packed = _civil(days);
  return (year: _yearOf(packed), month: _monthOf(packed), day: _dayOf(packed));
}

/// The civil date of [days], packed: `(year + _yearBias) * 512 + month * 32
/// + day`.
int _civil(int days) {
  final z = days + 719468;
  final era = (z >= 0 ? z : z - 146096) ~/ 146097;
  final dayOfEra = z - era * 146097;
  final yearOfEra =
      (dayOfEra - dayOfEra ~/ 1460 + dayOfEra ~/ 36524 - dayOfEra ~/ 146096) ~/
      365;
  final dayOfYear =
      dayOfEra - (365 * yearOfEra + yearOfEra ~/ 4 - yearOfEra ~/ 100);
  final monthFromMarch = (5 * dayOfYear + 2) ~/ 153;
  final day = dayOfYear - (153 * monthFromMarch + 2) ~/ 5 + 1;
  final month = monthFromMarch < 10 ? monthFromMarch + 3 : monthFromMarch - 9;
  final year = yearOfEra + era * 400 + (month <= 2 ? 1 : 0);
  return (year + _yearBias) * 512 + month * 32 + day;
}

/// The year of a packed civil date.
int _yearOf(int packed) => (packed >> 9) - _yearBias;

/// The month (1-12) of a packed civil date.
int _monthOf(int packed) => (packed >> 5) & 15;

/// The day of the month of a packed civil date.
int _dayOf(int packed) => packed & 31;

/// Whether [year] is a leap year of the Gregorian calendar.
bool _isLeap(int year) => (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

/// The number of days of [month] (1-12) of [year].
int daysInMonth(int year, int month) => switch (month) {
  2 => _isLeap(year) ? 29 : 28,
  4 || 6 || 9 || 11 => 30,
  _ => 31,
};

/// The JS weekday of a day number: 0 is Sunday, 6 is Saturday.
int weekdayOfDays(int days) => (days + 4) % 7;

/// The day number of the wall time [wall], rounded down.
int _dayNumber(int wall) => (wall - wall % _day) ~/ _day;

/// The wall time of the instant [t] in [zone].
int _wall(int t, DateZone? zone) => zone == null ? t : t + zone.offsetAt(t);

/// The time of the wall time at the day [days] and the time of day
/// [timeOfDay], in [zone]: TimeClip of `fromWall`.
///
/// It tests the day number first, so that no `int` exceeds 2^53 on the web.
double _wallTime(int days, int timeOfDay, DateZone? zone) {
  if (days > _maxDays || days < -_maxDays) return double.nan;
  final wall = days * _day + timeOfDay;
  return _clip(zone == null ? wall : zone.fromWall(wall));
}

/// The start of the day [days] in [zone], minus [minus] ms: moment
/// `startOfDate(y, m, d) - minus` (moment.js:4074-4092, :4166-4200).
double _midnight(int days, DateZone? zone, [int minus = 0]) {
  final start = _wallTime(days, 0, zone);
  return minus == 0 ? start : timeClip(start - minus);
}

/// The day number of the first day of [month] of [year]. A month above 12
/// counts on into the next year.
int _firstOfMonth(int year, int month) => month > 12
    ? daysFromCivil(year + 1, month - 12, 1)
    : daysFromCivil(year, month, 1);

/// moment `startOf(unit)` (moment.js:4094-4155) of the time [t] in [zone].
///
/// [unit] is a unit of [normalizeDateUnit]. [weekStart] is the first day of
/// the week of the locale: 0 is Sunday, 6 is Saturday (moment.js:1420-1426).
///
/// - `null` (an unknown unit) and `millisecond` give [t].
/// - `second` and `minute` round the instant down to 1,000 and 60,000 ms.
/// - `hour` rounds `t` plus the whole-minute offset ([wholeMinuteOffset])
///   down to 3,600,000 ms.
/// - `day`, `date`, `week`, `isoWeek`, `month`, `quarter` and `year` give the
///   start of the unit from the wall fields, through [DateZone.fromWall].
/// - Any other unit gives NaN, as `setTime(undefined)` does.
double startOfUnit(double t, String? unit, DateZone? zone, int weekStart) {
  if (t.isNaN || unit == null || unit == 'millisecond') return t;
  final instant = t.toInt();
  switch (unit) {
    case 'second':
      return _clip(instant - instant % _second);
    case 'minute':
      return _clip(instant - instant % _minute);
    case 'hour':
      final local = instant + wholeMinuteOffset(zone, instant);
      return _clip(instant - local % _hour);
  }
  final days = _dayNumber(_wall(instant, zone));
  switch (unit) {
    case 'day' || 'date':
      return _midnight(days, zone);
    case 'week':
      return _midnight(days - (weekdayOfDays(days) - weekStart) % 7, zone);
    case 'isoWeek':
      return _midnight(days - (weekdayOfDays(days) + 6) % 7, zone);
  }
  final packed = _civil(days);
  final year = _yearOf(packed);
  final month = _monthOf(packed);
  return switch (unit) {
    'month' => _midnight(daysFromCivil(year, month, 1), zone),
    'quarter' => _midnight(
      daysFromCivil(year, month - (month - 1) % 3, 1),
      zone,
    ),
    'year' => _midnight(daysFromCivil(year, 1, 1), zone),
    _ => double.nan,
  };
}

/// moment `endOf(unit)` (moment.js:4157-4224) of the time [t] in [zone].
///
/// `second`, `minute` and `hour` give the start of the unit plus the unit
/// minus 1 ms. The other units of [startOfUnit] give the start of the next
/// unit from the wall fields, minus 1 ms. The function does not add one
/// unit to the result of [startOfUnit]: after a skipped local midnight, that
/// form gives an end that is one hour late.
double endOfUnit(double t, String? unit, DateZone? zone, int weekStart) {
  if (t.isNaN || unit == null || unit == 'millisecond') return t;
  final instant = t.toInt();
  switch (unit) {
    case 'second':
      return _clip(instant + _second - instant % _second - 1);
    case 'minute':
      return _clip(instant + _minute - instant % _minute - 1);
    case 'hour':
      final local = instant + wholeMinuteOffset(zone, instant);
      return _clip(instant + _hour - local % _hour - 1);
  }
  final days = _dayNumber(_wall(instant, zone));
  switch (unit) {
    case 'day' || 'date':
      return _midnight(days + 1, zone, 1);
    case 'week':
      final start = days - (weekdayOfDays(days) - weekStart) % 7;
      return _midnight(start + 7, zone, 1);
    case 'isoWeek':
      return _midnight(days - (weekdayOfDays(days) + 6) % 7 + 7, zone, 1);
  }
  final packed = _civil(days);
  final year = _yearOf(packed);
  final month = _monthOf(packed);
  return switch (unit) {
    'month' => _midnight(_firstOfMonth(year, month + 1), zone, 1),
    'quarter' => _midnight(
      _firstOfMonth(year, month - (month - 1) % 3 + 3),
      zone,
      1,
    ),
    'year' => _midnight(daysFromCivil(year + 1, 1, 1), zone, 1),
    _ => double.nan,
  };
}

/// `isoWeekday(w).startOf('day')` of chartjs-adapter-moment
/// (`chartjs-adapter-moment.esm.js:53-56`, moment.js:1522-1527, :1715-1726,
/// :1736-1750). Throws a [TypeError] for a NaN weekday on Monday to
/// Saturday.
///
/// The weekday is `trunc(min(max(0, ToNumber(weekday)), 6))`. Thus `true`
/// gives 1, `7` gives 6 and `undefined` gives NaN. 0 is Sunday. The result
/// is the start of the day with that weekday in the ISO week (Monday to
/// Sunday) of [t]. Thus a weekday 2-6 can move the date forward, and 0 is
/// the Sunday before the week. A NaN weekday on a Sunday gives the Sunday
/// one week before. An invalid [t] gives NaN.
double startOfIsoWeekday(double t, Object? weekday, DateZone? zone) {
  final number = jsToNumber(weekday);
  if (t.isNaN) return double.nan;
  final instant = t.toInt();
  final day = weekdayOfDays(_dayNumber(_wall(instant, zone)));
  final int step;
  if (number.isNaN) {
    // moment calls `.startOf` on the weekday number of the getter.
    if (day != 0) throw TypeError();
    step = -7;
  } else {
    final iso = (number < 0 ? 0.0 : (number > 6 ? 6.0 : number)).toInt();
    step = day != 0 ? iso - day : iso - 7;
  }
  final moved = _addDays(t, step.toDouble(), zone);
  return startOfUnit(moved, 'day', zone, 0);
}

/// moment `absRound` (moment.js:3196-3202): half away from zero, as JS
/// `Math.round` of the absolute value.
double _absRound(double x) => x < 0 ? -(-x).roundToDouble() : x.roundToDouble();

/// moment `add(amount, unit)` of a time (moment.js:3157-3190, :3605-3629).
///
/// [amount] is not NaN: the member gives 0 for NaN, as the `|| 0` of the
/// moment `Duration`.
///
/// - `millisecond`, `second`, `minute` and `hour` add `amount`,
///   `amount * 1e3`, `amount * 6e4` and `amount * 1000 * 60 * 60` ms, in
///   this order of operations. TimeClip truncates the sum. An add of 0 ms
///   returns [t].
/// - `day` adds `absRound(amount)` days. `week` and `isoWeek` add
///   `absRound(amount * 7)` days. `month`, `quarter` and `year` add
///   `absRound(amount)`, `absRound(amount * 3)` and `absRound(amount * 12)`
///   months. A month step keeps the day of the month, clamped to the last
///   day of the target month (moment.js:1097-1120). The step keeps the wall
///   time of the day and goes through [DateZone.fromWall]. An amount of 0
///   days or months returns [t]: moment sets no field for it.
/// - Any other unit, also `null`, returns [t].
double addUnit(double t, double amount, String? unit, DateZone? zone) {
  if (t.isNaN) return t;
  return switch (unit) {
    'millisecond' => _addMs(t, amount),
    'second' => _addMs(t, amount * 1e3),
    'minute' => _addMs(t, amount * 6e4),
    'hour' => _addMs(t, amount * 1000 * 60 * 60),
    'day' => _addDays(t, _absRound(amount), zone),
    'week' || 'isoWeek' => _addDays(t, _absRound(amount * 7), zone),
    'month' => _addMonths(t, _absRound(amount), zone),
    'quarter' => _addMonths(t, _absRound(amount * 3), zone),
    'year' => _addMonths(t, _absRound(amount * 12), zone),
    _ => t,
  };
}

/// [t] plus [ms] ms, or [t] for 0 ms.
double _addMs(double t, double ms) => ms == 0 ? t : timeClip(t + ms);

/// [t] plus [days] wall days in [zone], or [t] for 0 days.
double _addDays(double t, double days, DateZone? zone) {
  if (days == 0) return t;
  if (!(days.abs() <= 2.0 * _maxDays)) return double.nan;
  final instant = t.toInt();
  final wall = _wall(instant, zone);
  final from = _dayNumber(wall);
  return _wallTime(from + days.toInt(), wall - from * _day, zone);
}

/// [t] plus [months] months in [zone], with the month-end clamp, or [t] for
/// 0 months.
double _addMonths(double t, double months, DateZone? zone) {
  if (months == 0) return t;
  if (!(months.abs() <= _maxMonths)) return double.nan;
  final instant = t.toInt();
  final wall = _wall(instant, zone);
  final from = _dayNumber(wall);
  final packed = _civil(from);
  final target = _monthOf(packed) - 1 + months.toInt();
  final targetYear = _yearOf(packed) + (target - target % 12) ~/ 12;
  final targetMonth = target % 12 + 1;
  final last = daysInMonth(targetYear, targetMonth);
  final day = _dayOf(packed) < last ? _dayOf(packed) : last;
  return _wallTime(
    daysFromCivil(targetYear, targetMonth, day),
    wall - from * _day,
    zone,
  );
}

/// The zone delta of moment `diff` (moment.js:3860): the whole-minute
/// offset of [b] minus that of [a], in ms. It is 0 in UTC.
double _zoneDelta(double a, double b, DateZone? zone) => zone == null
    ? 0
    : (wholeMinuteOffset(zone, b.toInt()) - wholeMinuteOffset(zone, a.toInt()))
          .toDouble();

/// moment `absFloor` (moment.js:687-694): truncation toward zero. -0 gives
/// 0, and NaN stays NaN.
double _absFloor(double x) {
  if (x < 0) {
    final up = x.ceilToDouble();
    return up == 0 ? 0 : up;
  }
  return x.floorToDouble();
}

/// moment `a.diff(b, unit)` of two times (moment.js:3847-3921): the number
/// of [unit] from [b] to [a], truncated toward zero.
///
/// - `month`, `quarter` and `year` use the moment `monthDiff`: whole months
///   from [b] to [a] with the month-end clamp of [addUnit], plus a linear
///   part of the next month. `quarter` and `year` divide by 3 and 12 before
///   the truncation.
/// - `day` and `week` subtract the zone delta: the whole-minute offset of
///   [b] minus that of [a]. Thus a 23-hour DST day counts as one day.
/// - `second`, `minute` and `hour` divide the difference of the instants.
/// - Any other unit gives the difference in ms.
///
/// An invalid [a] gives NaN. An invalid [b] gives NaN in local time. In UTC
/// it gives 0 for `month`, `quarter` and `year`, and NaN for the other
/// units: moment `cloneWithOffset` keeps the validity of [a] there
/// (moment.js:3277-3292), and `monthDiff` gives `NaN || 0` (:3920).
double diffUnit(double a, double b, String? unit, DateZone? zone) {
  if (a.isNaN) return double.nan;
  if (b.isNaN) {
    final months = unit == 'month' || unit == 'quarter' || unit == 'year';
    return zone == null && months ? 0 : double.nan;
  }
  final output = switch (unit) {
    'year' => _monthDiff(a, b, zone) / 12,
    'month' => _monthDiff(a, b, zone),
    'quarter' => _monthDiff(a, b, zone) / 3,
    'second' => (a - b) / 1e3,
    'minute' => (a - b) / 6e4,
    'hour' => (a - b) / 36e5,
    'day' => (a - b - _zoneDelta(a, b, zone)) / 864e5,
    'week' => (a - b - _zoneDelta(a, b, zone)) / 6048e5,
    _ => a - b,
  };
  return _absFloor(output);
}

/// moment `monthDiff(a, b)` (moment.js:3896-3921): the months from [a] to
/// [b], negated. -0 and NaN give 0.
double _monthDiff(double a, double b, DateZone? zone) {
  final civilA = _civil(_dayNumber(_wall(a.toInt(), zone)));
  final civilB = _civil(_dayNumber(_wall(b.toInt(), zone)));
  if (_dayOf(civilA) < _dayOf(civilB)) return -_monthDiff(b, a, zone);
  final whole =
      (_yearOf(civilB) - _yearOf(civilA)) * 12 +
      (_monthOf(civilB) - _monthOf(civilA));
  final anchor = _addMonths(a, whole.toDouble(), zone);
  final double adjust;
  if (b - anchor < 0) {
    final before = _addMonths(a, (whole - 1).toDouble(), zone);
    adjust = (b - anchor) / (anchor - before);
  } else {
    final after = _addMonths(a, (whole + 1).toDouble(), zone);
    adjust = (b - anchor) / (after - anchor);
  }
  final result = -(whole + adjust);
  return result == 0 || result.isNaN ? 0 : result;
}
