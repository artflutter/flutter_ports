// Ported from d3-time v3.1.0 test/date.js (ISC, Mike Bostock).

import 'package:test/test.dart';

/// Constructs a local [DateTime] using upstream 0-indexed [month] (`0..11`).
DateTime local([
  int year = 0,
  int month = 0,
  int day = 1,
  int hours = 0,
  int minutes = 0,
  int seconds = 0,
  int milliseconds = 0,
]) => DateTime(year, month + 1, day, hours, minutes, seconds, milliseconds);

/// Constructs a UTC [DateTime] using upstream 0-indexed [month] (`0..11`).
DateTime utc([
  int year = 0,
  int month = 0,
  int day = 1,
  int hours = 0,
  int minutes = 0,
  int seconds = 0,
  int milliseconds = 0,
]) => DateTime.utc(year, month + 1, day, hours, minutes, seconds, milliseconds);

/// Whether the host timezone matches `America/Los_Angeles` on the 2011 DST
/// transition dates used by upstream d3-time tests.
final bool isAmericaLosAngeles =
    DateTime(2011, 3, 13).timeZoneOffset == const Duration(hours: -8) &&
    DateTime(2011, 3, 13, 4).timeZoneOffset == const Duration(hours: -7) &&
    DateTime(2011, 11, 6).timeZoneOffset == const Duration(hours: -7) &&
    DateTime(2011, 11, 6, 3).timeZoneOffset == const Duration(hours: -8);

/// Whether the host timezone offset is a whole number of hours on 2011-03-13
/// and 2011-11-06.
final bool isWholeHourTimeZone =
    DateTime(2011, 3, 13).timeZoneOffset.inMinutes % 60 == 0 &&
    DateTime(2011, 11, 6).timeZoneOffset.inMinutes % 60 == 0;

/// Matches a [DateTime] representing the exact same epoch millisecond as
/// [expected], regardless of `isUtc`.
Matcher sameInstant(DateTime expected) => predicate<DateTime>(
  (actual) => actual.millisecondsSinceEpoch == expected.millisecondsSinceEpoch,
  'same instant as ${expected.toUtc().toIso8601String()} '
  '(${expected.millisecondsSinceEpoch})',
);

/// Matches a [List<DateTime>] with the exact same epoch milliseconds as
/// [expected], regardless of `isUtc`.
Matcher sameInstants(List<DateTime> expected) => predicate<List<DateTime>>(
  (actual) {
    if (actual.length != expected.length) return false;
    for (var i = 0; i < actual.length; ++i) {
      if (actual[i].millisecondsSinceEpoch !=
          expected[i].millisecondsSinceEpoch) {
        return false;
      }
    }
    return true;
  },
  'same instants as '
  '${expected.map((d) => d.toUtc().toIso8601String()).toList()}',
);
