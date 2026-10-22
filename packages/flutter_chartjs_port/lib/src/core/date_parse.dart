// Original code, not ported from Chart.js: the input and parse of the adapter.

/// The input rule and the parse of the default date adapter (Chart.js ADR
/// 0024, decision 5).
///
/// [dateInput] gives the time of `moment(value)` of chartjs-adapter-moment
/// 1.0.1 on moment 2.29.4. [parseDateString] reads the ASP.NET, ISO 8601 and
/// RFC 2822 forms of moment `configFromString` (moment.js:2525-2552) with
/// scanners on code units. [parseWithFormat] reads a string with an ICU
/// pattern through `DateFormat.tryParse` of intl.
///
/// The scanners state the moment grammars in code of the port. They copy no
/// moment code. The ISO 8601 scanner costs 35-54 ns on AOT, where a
/// `RegExp` form of the moment grammar costs 2.3 µs (Chart.js ADR 0024,
/// fact 5).
///
/// This library is a pure layer. It imports neither `dart:ui` nor
/// `package:flutter`.
library;

import 'package:flutter_chartjs_port/src/core/date_calendar.dart';
import 'package:flutter_chartjs_port/src/core/date_format.dart';
import 'package:flutter_chartjs_port/src/core/date_zone.dart';
import 'package:flutter_chartjs_port/src/js/js_date.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

/// One minute in ms.
const int _minuteMs = 60000;

/// One hour in ms.
const int _hourMs = 3600000;

/// One day in ms.
const int _dayMs = 86400000;

/// The largest day number of a wall time that the parse builds. The day
/// numbers of the valid times are in ±100,000,000.
const int _maxDays = 100000002;

/// The largest time value of a JS `Date` in ms.
const int _maxTime = 8640000000000000;

/// `moment(value).valueOf()` of the default adapter (moment.js:2953-3007):
/// the time of [value], or NaN for an invalid value.
///
/// - A `double` or an `int`: TimeClip. NaN and ±Infinity are invalid.
/// - A `DateTime`: its `millisecondsSinceEpoch`, as a JS `Date`.
/// - [undefined]: `jsDateNow()`, as `moment(undefined)` reads the current
///   time.
/// - `null` and `''`: invalid.
/// - Another `String`: [parseDateString].
/// - A `bool`: invalid. moment gives it to `new Date('true')`, which is
///   invalid.
/// - A `List`, a `Map` and any other value: invalid. moment reads an array
///   and an object as date fields, and an empty one as the current time.
double dateInput(Object? value, DateZone? zone) {
  switch (value) {
    case final double number:
      return timeClip(number);
    case final String text:
      return text.isEmpty ? double.nan : parseDateString(text, zone);
    case final int number:
      return timeClip(number.toDouble());
    case final DateTime date:
      return date.millisecondsSinceEpoch.toDouble();
    case Undefined():
      return jsDateNow();
    case null || bool():
      return double.nan;
  }
  // DIVERGES(chartjs): adapt-date-parse-fallback, no moment array or object.
  return double.nan;
}

/// The ISO 8601, ASP.NET and RFC 2822 grammars of moment `configFromString`
/// (moment.js:2525-2552): the time of [s], or NaN.
///
/// The order is the order of moment:
/// 1. ASP.NET: `/Date(n)` (moment.js:2346, :2526-2530).
/// 2. ISO 8601 (moment.js:2314-2345, :2364-2409), with the token parse of
///    moment `configFromStringAndFormat` and the checks of `checkOverflow`
///    (:2268). A wall time without an offset goes through
///    [DateZone.fromWall].
/// 3. RFC 2822 (moment.js:2348-2361, :2421-2522).
/// 4. Any other string is invalid. moment calls `new Date(string)` there
///    (moment.js:2550-2560). That result depends on the engine and on the
///    zone of the process.
double parseDateString(String s, DateZone? zone) {
  final aspNet = _aspNet(s);
  if (aspNet != null) return aspNet;
  final iso = _parseIso(s, zone);
  if (iso != null) return iso;
  final rfc = _rfc2822(s);
  if (rfc != null) return rfc;
  // DIVERGES(chartjs): adapt-date-parse-fallback, no new Date(string) fallback.
  return double.nan;
}

/// Whether [unit] is JS white space, the class `\s` of a JS `RegExp`.
bool _isSpace(int unit) =>
    // The printable ASCII characters and the controls up to U+009F, except
    // the space, are no white space.
    !(unit > 0x20 && unit < 0xA0) &&
    (unit == 0x20 ||
        (unit >= 0x09 && unit <= 0x0D) ||
        unit == 0xA0 ||
        unit == 0x1680 ||
        (unit >= 0x2000 && unit <= 0x200A) ||
        unit == 0x2028 ||
        unit == 0x2029 ||
        unit == 0x202F ||
        unit == 0x205F ||
        unit == 0x3000 ||
        unit == 0xFEFF);

/// Whether [s] has an ASCII digit at [i].
bool _isDigit(String s, int i) {
  if (i >= s.length) return false;
  final unit = s.codeUnitAt(i);
  return unit >= 0x30 && unit <= 0x39;
}

/// Whether [s] has [count] ASCII digits from [i].
bool _hasDigits(String s, int i, int count) {
  for (var k = 0; k < count; k++) {
    if (!_isDigit(s, i + k)) return false;
  }
  return true;
}

/// The number of ASCII digits of [s] from [i].
int _digitRun(String s, int i) {
  var k = i;
  while (_isDigit(s, k)) {
    k++;
  }
  return k - i;
}

/// The value of the [count] ASCII digits of [s] from [i], or -1 when one of
/// them is not a digit.
int _digitsAt(String s, int i, int count) {
  if (i < 0 || i + count > s.length) return -1;
  var value = 0;
  for (var k = i; k < i + count; k++) {
    final digit = s.codeUnitAt(k) - 0x30;
    if (digit < 0 || digit > 9) return -1;
    value = value * 10 + digit;
  }
  return value;
}

/// The value of the [count] digits of [s] from [i].
int _digitValue(String s, int i, int count) {
  var value = 0;
  for (var k = i; k < i + count; k++) {
    value = value * 10 + s.codeUnitAt(k) - 0x30;
  }
  return value;
}

/// Whether [s] has the code unit [unit] at [i].
bool _at(String s, int i, int unit) => i < s.length && s.codeUnitAt(i) == unit;

/// The ASP.NET form `/^\/?Date\((-?\d+)/i` (moment.js:2346): the TimeClip of
/// the number, or null when [s] does not start with the form.
double? _aspNet(String s) {
  var i = _at(s, 0, 0x2F) ? 1 : 0; // '/'
  if (i + 5 > s.length) return null;
  // `Date` in any case: the bit 0x20 makes an ASCII letter lower case.
  if ((s.codeUnitAt(i) | 0x20) != 0x64 ||
      (s.codeUnitAt(i + 1) | 0x20) != 0x61 ||
      (s.codeUnitAt(i + 2) | 0x20) != 0x74 ||
      (s.codeUnitAt(i + 3) | 0x20) != 0x65 ||
      s.codeUnitAt(i + 4) != 0x28) {
    return null;
  }
  i += 5;
  final negative = _at(s, i, 0x2D);
  if (negative) i++;
  final count = _digitRun(s, i);
  if (count == 0) return null;
  var first = i;
  while (first < i + count - 1 && s.codeUnitAt(first) == 0x30) {
    first++;
  }
  final significant = i + count - first;
  // 17 digits or more give at least 1e16, outside the range of a Date.
  if (significant > 16) return double.nan;
  final value = _digitValue(s, first, significant).toDouble();
  return timeClip(negative ? -value : value);
}

/// moment `parseMs` (moment.js:4868-4870) of the digits of [s] from [start]
/// to [end]: `toInt(('0.' + digits) * 1000)`.
int _milliseconds(String s, int start, int end) {
  final count = end - start;
  final double value;
  if (count < _powersOfTen.length) {
    // An integer below 2^53 divided by an exact power of ten: the double of
    // the decimal fraction, as the JS parse of the string gives it.
    value = _digitValue(s, start, count) / _powersOfTen[count];
  } else {
    value = double.parse('0.${s.substring(start, end)}');
  }
  return (value * 1000).truncate();
}

/// The date forms of moment `isoDates` (moment.js:2319-2333), by index.
const int _formYearMonthDay6 = 0; // YYYYYY-MM-DD
const int _formYearMonthDay = 1; // YYYY-MM-DD
const int _formWeekDay = 2; // GGGG-[W]WW-E
const int _formWeek = 3; // GGGG-[W]WW
const int _formOrdinal = 4; // YYYY-DDD
const int _formYearMonth = 5; // YYYY-MM
const int _formBasicYearMonthDay6 = 6; // YYYYYYMMDD
const int _formBasicYearMonthDay = 7; // YYYYMMDD
const int _formBasicWeekDay = 8; // GGGG[W]WWE
const int _formBasicWeek = 9; // GGGG[W]WW
const int _formBasicOrdinal = 10; // YYYYDDD
const int _formBasicYearMonth = 11; // YYYYMM
const int _formYear = 12; // YYYY

/// The tokens of the moment formats of the ISO parse.
///
/// The token parse reads only a signed year in a form of four digits (see
/// [_parseIso]). Thus it has no token `YYYYYY`, and `YYYY` always reads
/// four digits.
const int _tokenYear = 0; // YYYY: \d{1,4}
const int _tokenWeekYear = 1; // GGGG: \d{1,4}
const int _tokenMonth = 2; // MM: \d\d?
const int _tokenDate = 3; // DD: \d\d?
const int _tokenDayOfYear = 4; // DDD: \d{1,3}
const int _tokenWeek = 5; // WW: \d\d?
const int _tokenWeekday = 6; // E: \d\d?
const int _tokenHour = 7; // HH: \d\d?
const int _tokenMinute = 8; // mm: \d\d?
const int _tokenSecond = 9; // ss: \d\d?
const int _tokenFraction = 10; // SSSS: \d+
const int _tokenZone = 11; // Z: Z|[+-]\d\d(?::?\d\d)?

/// A literal of a moment format: the code unit plus [_literal].
const int _literal = 0x10000;

/// The `-` literal.
const int _dash = _literal + 0x2D;

/// The `W` literal.
const int _w = _literal + 0x57;

/// The `:` literal.
const int _colon = _literal + 0x3A;

/// The tokens of each date form, in the order of [_formYearMonthDay6] to
/// [_formYear].
///
/// The two forms of six digits have no tokens: [_parseIso] reads them
/// without the token parse.
const List<List<int>> _dateTokens = [
  [],
  [_tokenYear, _dash, _tokenMonth, _dash, _tokenDate],
  [_tokenWeekYear, _dash, _w, _tokenWeek, _dash, _tokenWeekday],
  [_tokenWeekYear, _dash, _w, _tokenWeek],
  [_tokenYear, _dash, _tokenDayOfYear],
  [_tokenYear, _dash, _tokenMonth],
  [],
  [_tokenYear, _tokenMonth, _tokenDate],
  [_tokenWeekYear, _w, _tokenWeek, _tokenWeekday],
  [_tokenWeekYear, _w, _tokenWeek],
  [_tokenYear, _tokenDayOfYear],
  [_tokenYear, _tokenMonth],
  [_tokenYear],
];

/// The tokens of the time forms of moment `isoTimes` (moment.js:2334-2344),
/// after the separator.
const List<List<int>> _timeTokens = [
  // HH:mm:ss.SSSS
  [
    _tokenHour,
    _colon,
    _tokenMinute,
    _colon,
    _tokenSecond,
    _literal + 0x2E,
    _tokenFraction,
  ],
  // HH:mm:ss,SSSS
  [
    _tokenHour,
    _colon,
    _tokenMinute,
    _colon,
    _tokenSecond,
    _literal + 0x2C,
    _tokenFraction,
  ],
  // HH:mm:ss
  [_tokenHour, _colon, _tokenMinute, _colon, _tokenSecond],
  // HH:mm
  [_tokenHour, _colon, _tokenMinute],
  // HHmmss.SSSS
  [_tokenHour, _tokenMinute, _tokenSecond, _literal + 0x2E, _tokenFraction],
  // HHmmss,SSSS
  [_tokenHour, _tokenMinute, _tokenSecond, _literal + 0x2C, _tokenFraction],
  // HHmmss
  [_tokenHour, _tokenMinute, _tokenSecond],
  // HHmm
  [_tokenHour, _tokenMinute],
  // HH
  [_tokenHour],
];

/// The powers of ten that a `double` holds exactly.
const List<double> _powersOfTen = [
  1e0,
  1e1,
  1e2,
  1e3,
  1e4,
  1e5,
  1e6,
  1e7,
  1e8,
  1e9,
  1e10,
  1e11,
  1e12,
  1e13,
  1e14,
  1e15,
];

/// The ISO 8601 parse of moment `configFromISO` (moment.js:2364-2409): the
/// time of [s] in [zone], NaN for an invalid ISO date, or null when [s] is
/// not an ISO string of moment.
///
/// Step 1 scans [s] with the grammar of `extendedIsoRegex` and
/// `basicIsoRegex` (moment.js:2314-2317). It finds the date form of
/// `isoDates` and the time form of `isoTimes` that moment finds, and it
/// keeps the value of each field. Step 2 is the token parse of [_IsoParse].
/// For a year of four digits, and for a signed year in the forms of six
/// digits, each token of step 2 matches at the position of its field in
/// step 1. Thus the values of step 1 are the fields there, and the parse
/// needs no token search.
double? _parseIso(String s, DateZone? zone) {
  final length = s.length;
  var i = 0;
  while (i < length && _isSpace(s.codeUnitAt(i))) {
    i++;
  }
  // Step 1 keeps the value of each field that it reads.
  // The year: [+-]\d{6} or \d{4}.
  final signed = _at(s, i, 0x2B) || _at(s, i, 0x2D);
  final int year;
  if (signed) {
    final digits = _digitsAt(s, i + 1, 6);
    if (digits < 0) return null;
    year = _at(s, i, 0x2D) ? -digits : digits;
    i += 7;
  } else {
    year = _digitsAt(s, i, 4);
    if (year < 0) return null;
    i += 4;
  }
  var field1 = -1; // The month, the week or the day of the year.
  var field2 = -1; // The day of the month or the weekday.
  final int form;
  if (_at(s, i, 0x2D)) {
    // The extended form: -(\d\d-\d\d|W\d\d-\d|W\d\d|\d\d\d|\d\d).
    i++;
    final two = _digitsAt(s, i, 2);
    if (two >= 0 && _at(s, i + 2, 0x2D) && _digitsAt(s, i + 3, 2) >= 0) {
      form = signed ? _formYearMonthDay6 : _formYearMonthDay;
      field1 = two;
      field2 = _digitsAt(s, i + 3, 2);
      i += 5;
    } else if (_at(s, i, 0x57) && _digitsAt(s, i + 1, 2) >= 0) {
      field1 = _digitsAt(s, i + 1, 2);
      if (_at(s, i + 3, 0x2D) && _isDigit(s, i + 4)) {
        form = _formWeekDay;
        field2 = s.codeUnitAt(i + 4) - 0x30;
        i += 5;
      } else {
        form = _formWeek;
        i += 3;
      }
    } else if (_digitsAt(s, i, 3) >= 0) {
      form = _formOrdinal;
      field1 = _digitsAt(s, i, 3);
      i += 3;
    } else if (two >= 0) {
      form = _formYearMonth;
      field1 = two;
      i += 2;
    } else {
      return null;
    }
  } else if (_at(s, i, 0x57)) {
    // The basic week forms: W\d\d\d or W\d\d.
    final count = _digitRun(s, i + 1);
    if (count == 3) {
      form = _formBasicWeekDay;
      field2 = s.codeUnitAt(i + 3) - 0x30;
    } else if (count == 2) {
      form = _formBasicWeek;
    } else {
      return null;
    }
    field1 = _digitsAt(s, i + 1, 2);
    i += 1 + count;
  } else {
    // The basic forms: \d\d\d\d, \d\d\d, \d\d or nothing. The search of
    // `isoDates` finds `\d{8}` in a signed year with three or two more
    // digits, and `\d{6}` in a signed year alone.
    final count = _digitRun(s, i);
    switch (count) {
      case 4:
        form = signed ? _formBasicYearMonthDay6 : _formBasicYearMonthDay;
        field1 = _digitsAt(s, i, 2);
        field2 = _digitsAt(s, i + 2, 2);
      case 3:
        form = signed ? _formBasicYearMonthDay : _formBasicOrdinal;
        field1 = _digitsAt(s, i, 3);
      case 2:
        form = signed ? _formBasicYearMonthDay : _formBasicYearMonth;
        field1 = _digitsAt(s, i, 2);
      case 0:
        form = signed ? _formBasicYearMonth : _formYear;
      default:
        return null;
    }
    i += count;
  }
  // The time: (T| ) and the forms of `isoTimes`.
  var time = -1;
  var separator = 0;
  var hour = -1;
  var minute = -1;
  var seconds = -1;
  var fractionAt = 0;
  var fractionEnd = 0;
  int? zoneMinutes;
  if (i < length &&
      (s.codeUnitAt(i) == 0x54 || s.codeUnitAt(i) == 0x20) &&
      (hour = _digitsAt(s, i + 1, 2)) >= 0) {
    separator = s.codeUnitAt(i);
    i += 3;
    final extended = form <= _formYearMonth;
    // The digits of the next unit: after a colon in the extended form.
    int unit() => extended
        ? (_at(s, i, 0x3A) ? _digitsAt(s, i + 1, 2) : -1)
        : _digitsAt(s, i, 2);
    final step = extended ? 3 : 2;
    if ((minute = unit()) >= 0) {
      i += step;
      if ((seconds = unit()) >= 0) {
        i += step;
        if ((_at(s, i, 0x2E) || _at(s, i, 0x2C)) && _isDigit(s, i + 1)) {
          time = (extended ? 0 : 4) + (_at(s, i, 0x2E) ? 0 : 1);
          fractionAt = i + 1;
          i += 1 + _digitRun(s, i + 1);
          fractionEnd = i;
        } else {
          time = extended ? 2 : 6;
        }
      } else {
        time = extended ? 3 : 7;
      }
    } else {
      time = 8;
    }
    // The zone: [+-]\d\d(?::?\d\d)? or \s*Z.
    final zoneHours = _digitsAt(s, i + 1, 2);
    if ((_at(s, i, 0x2B) || _at(s, i, 0x2D)) && zoneHours >= 0) {
      final negative = _at(s, i, 0x2D);
      var minutes = 0;
      if (_at(s, i + 3, 0x3A) && _digitsAt(s, i + 4, 2) >= 0) {
        minutes = _digitsAt(s, i + 4, 2);
        i += 6;
      } else if (_digitsAt(s, i + 3, 2) >= 0) {
        minutes = _digitsAt(s, i + 3, 2);
        i += 5;
      } else {
        i += 3;
      }
      // moment `offsetFromString`: 0 has no sign.
      final total = zoneHours * 60 + minutes;
      zoneMinutes = negative ? -total : total;
    } else {
      var k = i;
      while (k < length && _isSpace(s.codeUnitAt(k))) {
        k++;
      }
      if (_at(s, k, 0x5A)) {
        i = k + 1;
        zoneMinutes = 0;
      }
    }
  }
  if (i != length) return null;
  // `isoDates` entries with `false` allow no time (moment.js:2385-2388).
  final allowsTime =
      form != _formWeek &&
      form != _formYearMonth &&
      form != _formBasicWeek &&
      form != _formBasicYearMonth &&
      form != _formYear;
  if (time >= 0 && !allowsTime) return null;

  if (!signed ||
      form == _formYearMonthDay6 ||
      form == _formBasicYearMonthDay6) {
    // Each token of step 2 matches at the position of its field in step
    // 1, so the values of step 1 are the fields.
    final millisecond = fractionEnd > fractionAt
        ? _milliseconds(s, fractionAt, fractionEnd)
        : 0;
    final week =
        form == _formWeekDay ||
        form == _formWeek ||
        form == _formBasicWeekDay ||
        form == _formBasicWeek;
    final ordinal = form == _formOrdinal || form == _formBasicOrdinal;
    if (!week && !ordinal) {
      return _isoTime(
        year,
        field1 >= 0 ? field1 - 1 : 0,
        field2 >= 0 ? field2 : 1,
        hour < 0 ? 0 : hour,
        minute < 0 ? 0 : minute,
        seconds < 0 ? 0 : seconds,
        millisecond,
        zoneMinutes,
        zone,
      );
    }
    final parse = _IsoParse(s);
    if (week) {
      parse
        .._weekYear = year
        .._week = field1;
      if (field2 >= 0) parse._weekday = field2;
    } else {
      parse
        .._year = year
        .._dayOfYear = field1;
    }
    if (time >= 0) {
      parse
        .._hour = hour
        .._millisecond = millisecond;
      if (minute >= 0) parse._minute = minute;
      if (seconds >= 0) parse._second = seconds;
    }
    parse._zoneMinutes = zoneMinutes;
    return parse._time(zone);
  }
  final parse = _IsoParse(s);
  final dateTokens = _dateTokens[form];
  for (var k = 0; k < dateTokens.length; k++) {
    parse._read(dateTokens[k]);
  }
  if (time >= 0) {
    parse._read(_literal + separator);
    final timeTokens = _timeTokens[time];
    for (var k = 0; k < timeTokens.length; k++) {
      parse._read(timeTokens[k]);
    }
  }
  if (zoneMinutes != null) parse._read(_tokenZone);
  return parse._time(zone);
}

/// The token parse of moment `configFromStringAndFormat`
/// (moment.js:2748-2836) in the mode that is not strict, for the ISO forms
/// of [_parseIso]: each token takes the first match of its pattern from the
/// current position, and it skips the text before the match. Thus a year of
/// six digits in a form of four digits gives the first four digits, as in
/// moment. [_time] then applies `configFromArray` and `checkOverflow`
/// (moment.js:2268, :2591-2680).
///
/// [_parseIso] calls [_read] only for a signed year in a form of four
/// digits. Step 1 of [_parseIso] found each field of the form. Thus each
/// token finds its match.
final class _IsoParse {
  _IsoParse(this.s);

  /// The string.
  final String s;

  /// The position of the token parse.
  int _position = 0;

  // The fields that the tokens read. `null` is a field that the format has
  // not, or that its token did not find.
  int? _year;
  int? _month;
  int? _date;
  int? _hour;
  int? _minute;
  int? _second;
  int? _millisecond;
  int? _weekYear;
  int? _week;
  int? _weekday;
  int? _dayOfYear;

  /// The offset of the zone token in minutes.
  int? _zoneMinutes;

  /// The position of the first ASCII digit of [s] from [_position].
  ///
  /// Step 1 of [_parseIso] found a digit for each token. Without one, the
  /// read past the end of [s] throws a [RangeError].
  int _nextDigit() {
    for (var k = _position; ; k++) {
      final unit = s.codeUnitAt(k);
      if (unit >= 0x30 && unit <= 0x39) return k;
    }
  }

  /// The value of the first match of `\d{1,max}` from [_position]. The
  /// position moves past the match.
  int _digits(int max) {
    final start = _nextDigit();
    var end = start + 1;
    while (end < start + max && _isDigit(s, end)) {
      end++;
    }
    _position = end;
    return _digitValue(s, start, end - start);
  }

  /// Reads one token of the moment format: moment
  /// `configFromStringAndFormat` (moment.js:2748-2836) and the parse
  /// functions of the tokens.
  void _read(int token) {
    switch (token) {
      case _tokenYear:
        // The signed year has six digits. Thus the year has four digits,
        // and moment `parseTwoDigitYear` does not apply.
        _year = _digits(4);
      case _tokenWeekYear:
        _weekYear = _digits(4);
      case _tokenMonth:
        _month = _digits(2) - 1;
      case _tokenDate:
        _date = _digits(2);
      case _tokenDayOfYear:
        _dayOfYear = _digits(3);
      case _tokenWeek:
        _week = _digits(2);
      case _tokenWeekday:
        _weekday = _digits(2);
      case _tokenHour:
        _hour = _digits(2);
      case _tokenMinute:
        _minute = _digits(2);
      case _tokenSecond:
        _second = _digits(2);
      case _tokenFraction:
        _millisecond = _fraction();
      case _tokenZone:
        _zoneMinutes = _zone() ?? _zoneMinutes;
      default:
        final unit = token - _literal;
        for (var k = _position; k < s.length; k++) {
          if (s.codeUnitAt(k) == unit) {
            _position = k + 1;
            break;
          }
        }
    }
  }

  /// moment `parseMs` of the first digits from [_position].
  int _fraction() {
    final start = _nextDigit();
    _position = start + _digitRun(s, start);
    return _milliseconds(s, start, _position);
  }

  /// The offset in minutes of the first match of `Z|[+-]\d\d(?::?\d\d)?`
  /// (case-insensitive) from [_position], or null: moment
  /// `offsetFromString` (moment.js:3259-3275).
  int? _zone() {
    for (var k = _position; k < s.length; k++) {
      final unit = s.codeUnitAt(k);
      if (unit == 0x5A || unit == 0x7A) {
        _position = k + 1;
        return 0;
      }
      if ((unit == 0x2B || unit == 0x2D) && _hasDigits(s, k + 1, 2)) {
        final hours = _digitValue(s, k + 1, 2);
        var end = k + 3;
        var minutes = 0;
        if (_at(s, end, 0x3A) && _hasDigits(s, end + 1, 2)) {
          minutes = _digitValue(s, end + 1, 2);
          end += 3;
        } else if (_hasDigits(s, end, 2)) {
          minutes = _digitValue(s, end, 2);
          end += 2;
        }
        _position = end;
        final total = hours * 60 + minutes;
        return unit == 0x2B ? total : -total;
      }
    }
    return null;
  }

  /// moment `configFromArray` (moment.js:2591-2680) and `checkOverflow`
  /// (:2268): the time in [zone], or NaN.
  double _time(DateZone? zone) {
    var year = _year;
    var month = _month;
    var date = _date;
    if ((_weekYear != null || _week != null || _weekday != null) &&
        date == null &&
        month == null) {
      // moment `dayOfYearFromWeekInfo` with the ISO week (dow 1, doy 4).
      final weekYear = _weekYear ?? year;
      if (weekYear == null) return double.nan;
      final week = _week ?? 1;
      final weekday = _weekday ?? 1;
      if (week < 1 || week > _isoWeeksIn(weekYear)) return double.nan;
      if (weekday < 1 || weekday > 7) return double.nan;
      final days = _isoWeekOne(weekYear) + 7 * (week - 1) + weekday - 1;
      if (days > _maxDays || days < -_maxDays) return double.nan;
      final civil = civilFromDays(days);
      year = civil.year;
      month = civil.month - 1;
      date = civil.day;
    } else if (_dayOfYear != null) {
      final dayOfYear = _dayOfYear!;
      if (year == null) return double.nan;
      final yearLength = daysInMonth(year, 2) == 29 ? 366 : 365;
      if (dayOfYear > yearLength || dayOfYear == 0) return double.nan;
      final civil = civilFromDays(
        daysFromCivil(year, 1, 1) + dayOfYear - 1,
      );
      month = civil.month - 1;
      date = civil.day;
    }
    // Each ISO form has a year: moment fills no field from the current
    // date.
    if (year == null) return double.nan;
    return _isoTime(
      year,
      month ?? 0,
      date ?? 1,
      _hour ?? 0,
      _minute ?? 0,
      _second ?? 0,
      _millisecond ?? 0,
      _zoneMinutes,
      zone,
    );
  }
}

/// The end of moment `configFromArray` (moment.js:2591-2680) and
/// `checkOverflow` (:2268) for the fields of an ISO string: the time in
/// [zone], or NaN. [month] is 0-11. [zoneMinutes] is the offset of the zone
/// token, or null for a wall time.
double _isoTime(
  int year,
  int month,
  int date,
  int hour,
  int minute,
  int second,
  int millisecond,
  int? zoneMinutes,
  DateZone? zone,
) {
  // moment `checkOverflow`. 24:00:00.000 is valid.
  if (month < 0 || month > 11) return double.nan;
  if (date < 1 || date > daysInMonth(year, month + 1)) return double.nan;
  final nextDay = hour == 24;
  if (hour > 24 || (nextDay && (minute | second | millisecond) != 0)) {
    return double.nan;
  }
  if (minute > 59 || second > 59 || millisecond > 999) return double.nan;
  var days = daysFromCivil(year, month + 1, date);
  if (days > _maxDays || days < -_maxDays) return double.nan;
  // moment `configFromArray` gives the hour 24 to `createDate` or
  // `createUTCDate` (moment.js:2640-2655). Thus the wall time is 00:00 of
  // the next day, as `new Date(y, m, d, 24)` and `Date.UTC(y, m, d, 24)`
  // give it. moment adds no day after that: `copyConfig` does not copy
  // `_nextDay` (moment.js:209-254), so `createFromConfig` skips its
  // `add(1, 'd')` (:2942-2951).
  if (nextDay && month == 11 && date == 31 && year >= 0 && year < 100) {
    // `createDate` and `createUTCDate` build a year 0-99 in the year + 400,
    // then set the year (moment.js:1282-1316). The hour 24 of December 31
    // gives January 1 of the year + 401, and the set year gives January 1
    // of [year].
    days = daysFromCivil(year, 1, 1) - 1;
  }
  final timeOfDay =
      hour * _hourMs + minute * _minuteMs + second * 1000 + millisecond;
  final wall = days * _dayMs + timeOfDay;
  if (zoneMinutes != null) {
    // `createUTCDate`, then `setUTCMinutes(getUTCMinutes() - tzm)`.
    return wall > _maxTime || wall < -_maxTime
        ? double.nan
        : timeClip((wall - zoneMinutes * _minuteMs).toDouble());
  }
  return timeClip((zone == null ? wall : zone.fromWall(wall)).toDouble());
}

/// The day number of the Monday of ISO week 1 of [year] (moment
/// `firstWeekOffset` with dow 1 and doy 4, moment.js:1319-1326).
int _isoWeekOne(int year) {
  final january4 = daysFromCivil(year, 1, 4);
  return january4 - (weekdayOfDays(january4) + 6) % 7;
}

/// The number of ISO weeks of [year]: 52 or 53 (moment `weeksInYear`).
int _isoWeeksIn(int year) => (_isoWeekOne(year + 1) - _isoWeekOne(year)) ~/ 7;

/// The short weekday names of the moment locale `en`, Sunday first.
const List<String> _weekdayNames = [
  'Sun',
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
];

/// The short month names of the moment locale `en`.
const List<String> _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// The zone names of RFC 2822 and their offsets in minutes
/// (moment.js:2350-2361).
const Map<String, int> _zoneNames = {
  'UT': 0,
  'GMT': 0,
  'EDT': -4 * 60,
  'EST': -5 * 60,
  'CDT': -5 * 60,
  'CST': -6 * 60,
  'MDT': -6 * 60,
  'MST': -7 * 60,
  'PDT': -7 * 60,
  'PST': -8 * 60,
};

/// [s] after moment `preprocessRFC2822` (moment.js:2454-2461): each
/// comment `([^()]*)` and each tab and line feed is a space, each run of two
/// or more white space characters is one space, and the white space at the
/// start and at the end goes.
String _preprocessRfc2822(String s) {
  final units = <int>[];
  for (var i = 0; i < s.length; i++) {
    final unit = s.codeUnitAt(i);
    if (unit == 0x28) {
      var k = i + 1;
      while (k < s.length &&
          s.codeUnitAt(k) != 0x28 &&
          s.codeUnitAt(k) != 0x29) {
        k++;
      }
      if (_at(s, k, 0x29)) {
        units.add(0x20);
        i = k;
        continue;
      }
    }
    units.add(unit == 0x0A || unit == 0x09 ? 0x20 : unit);
  }
  final folded = <int>[];
  for (var i = 0; i < units.length; i++) {
    if (_isSpace(units[i]) && i + 1 < units.length && _isSpace(units[i + 1])) {
      while (i + 1 < units.length && _isSpace(units[i + 1])) {
        i++;
      }
      folded.add(0x20);
    } else {
      folded.add(units[i]);
    }
  }
  var start = 0;
  var end = folded.length;
  while (start < end && _isSpace(folded[start])) {
    start++;
  }
  while (end > start && _isSpace(folded[end - 1])) {
    end--;
  }
  return String.fromCharCodes(folded, start, end);
}

/// The index of the name of [names] at [i] of [s], or -1.
int _nameAt(String s, int i, List<String> names) {
  if (i + 3 > s.length) return -1;
  for (var k = 0; k < names.length; k++) {
    if (s.startsWith(names[k], i)) return k;
  }
  return -1;
}

/// The RFC 2822 form of moment `configFromRFC2822` (moment.js:2496-2522):
/// the time, NaN for a date outside the ranges of `checkOverflow`, or null
/// when [original] does not match or the weekday is not the weekday of the
/// date.
///
/// The grammar is `rfc2822` (moment.js:2348-2349). The year of two or three
/// digits is `untruncateYear` (`<= 49` gives 2000+, `<= 999` gives 1900+).
/// The weekday, when present, must be the weekday of the date after the day
/// roll of `Date`. moment then calls `new Date(string)`. The result is a
/// UTC instant.
double? _rfc2822(String original) {
  final s = _preprocessRfc2822(original);
  var i = 0;
  var weekday = -1;
  final name = _nameAt(s, 0, _weekdayNames);
  if (name >= 0) {
    var k = 3;
    if (_at(s, k, 0x2C)) k++;
    if (k < s.length && _isSpace(s.codeUnitAt(k))) {
      weekday = name;
      i = k + 1;
    }
  }
  final dayDigits = _digitRun(s, i);
  if (dayDigits < 1 || dayDigits > 2) return null;
  final day = _digitValue(s, i, dayDigits);
  i += dayDigits;
  if (i >= s.length || !_isSpace(s.codeUnitAt(i))) return null;
  final month = _nameAt(s, i + 1, _monthNames);
  if (month < 0) return null;
  i += 4;
  if (i >= s.length || !_isSpace(s.codeUnitAt(i))) return null;
  i++;
  final yearDigits = _digitRun(s, i);
  if (yearDigits < 2 || yearDigits > 4) return null;
  var year = _digitValue(s, i, yearDigits);
  i += yearDigits;
  if (i >= s.length || !_isSpace(s.codeUnitAt(i))) return null;
  i++;
  if (!_hasDigits(s, i, 2) ||
      !_at(s, i + 2, 0x3A) ||
      !_hasDigits(s, i + 3, 2)) {
    return null;
  }
  final hour = _digitValue(s, i, 2);
  final minute = _digitValue(s, i + 3, 2);
  i += 5;
  int? second;
  if (_at(s, i, 0x3A) && _hasDigits(s, i + 1, 2)) {
    second = _digitValue(s, i + 1, 2);
    i += 3;
  }
  if (i >= s.length || !_isSpace(s.codeUnitAt(i))) return null;
  i++;
  final int zoneMinutes;
  final rest = s.length - i;
  final first = i < s.length ? s.codeUnitAt(i) : 0;
  if (rest == 1 && (first == 0x5A || first == 0x7A)) {
    zoneMinutes = 0;
  } else if (rest == 5 && (first == 0x2B || first == 0x2D)) {
    if (!_hasDigits(s, i + 1, 4)) return null;
    // moment `calculateOffset`: the sign applies to the hours and the
    // minutes.
    final hoursMinutes = _digitValue(s, i + 1, 4);
    final total = hoursMinutes ~/ 100 * 60 + hoursMinutes % 100;
    zoneMinutes = first == 0x2D ? -total : total;
  } else {
    // UT, GMT and [ECMP][SD]T: the keys of the table.
    final named = _zoneNames[s.substring(i)];
    if (named == null) return null;
    zoneMinutes = named;
  }
  // moment `untruncateYear`.
  if (year <= 49) {
    year += 2000;
  } else if (year <= 999) {
    year += 1900;
  }
  final days = daysFromCivil(year, month + 1, 1) + day - 1;
  if (weekday >= 0 && weekdayOfDays(days) != weekday) return null;
  // moment `checkOverflow` of the fields. The hour 24 always overflows: the
  // field of the milliseconds is undefined.
  if (day < 1 || day > daysInMonth(year, month + 1)) return double.nan;
  if (hour > 23 || minute > 59 || (second ?? 0) > 59) return double.nan;
  final wall =
      days * _dayMs +
      hour * _hourMs +
      minute * _minuteMs +
      (second ?? 0) * 1000;
  return timeClip((wall - zoneMinutes * _minuteMs).toDouble());
}

/// `moment(value, format)` with an ICU pattern [format] (row
/// `adapt-date-moment-format`): the time, or NaN.
///
/// The parse is [parseDateWall] of [value], [format] and [locale]. It does
/// not check the field ranges, and it does not skip text before the date.
/// When the pattern has no year field, the year is the current year. When
/// it has no year and no month field, the month is the current month. When
/// it has no year, month and day field, the day is the current day. This is
/// the moment rule `create/from-array.js:79-81`. The date of the filled
/// fields is the date of moment: in a leap current year, `'02/29'` with
/// `'MM/dd'` gives February 29, and `'24:00'` with `'HH:mm'` gives 00:00 of
/// the next day. The current date is the wall date of `jsDateNow()` in
/// [LocalZone], also when [zone] is UTC: moment `currentDateArray` reads the
/// local date of the process, also under the default zone of
/// `moment.tz.setDefault`. The day periods and the names of the months and
/// the weekdays match in any case, as in moment. The wall time of the fields
/// goes through [DateZone.fromWall] of [zone].
///
/// A failed parse costs 2.5 µs on AOT and 16.6 µs on dart2wasm, because
/// intl throws a `FormatException` inside (Chart.js ADR 0024, fact 6). A
/// value with a name in another case costs one more failed parse.
double parseWithFormat(
  String value,
  String format,
  DateZone? zone,
  String locale,
) {
  // DIVERGES(chartjs): adapt-date-moment-format, the intl parse.
  int? wall;
  try {
    wall = parseDateWall(value, format, locale, _today);
    // intl builds the date with the DateTime constructor, which throws an
    // ArgumentError for a year outside its range.
    // ignore: avoid_catching_errors
  } on ArgumentError {
    // A year outside the range of `DateTime`.
    return double.nan;
  }
  if (wall == null) return double.nan;
  return timeClip((zone == null ? wall : zone.fromWall(wall)).toDouble());
}

/// The day number of the current date of moment `currentDateArray`
/// (moment.js:2574-2585): the wall date of `jsDateNow()` in [LocalZone].
///
/// moment reads the local date of the process, also under a default zone
/// of moment-timezone. Thus the current date is the date of the local zone,
/// also when the default zone is UTC.
int _today() {
  final now = jsDateNow().toInt();
  final wall = now + LocalZone.instance.offsetAt(now);
  return (wall - wall % _dayMs) ~/ _dayMs;
}
