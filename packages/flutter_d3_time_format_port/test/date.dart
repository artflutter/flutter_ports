// Ported from d3-time-format v4.1.0 test/date.js (ISC, Mike Bostock).

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

/// Whether the host timezone matches `America/Los_Angeles` on 1990-01-01 and
/// 2010 DST transitions used by upstream `d3-time-format` tests.
final bool isAmericaLosAngeles =
    DateTime(1990).timeZoneOffset == const Duration(hours: -8) &&
    DateTime(2010, 3, 14).timeZoneOffset == const Duration(hours: -8) &&
    DateTime(2010, 3, 14, 4).timeZoneOffset == const Duration(hours: -7);

/// Formats [offset] as `±HHMM`, matching `%Z`.
String formatOffset(Duration offset) {
  var minutes = offset.inMinutes;
  final sign = minutes < 0 ? '-' : '+';
  if (minutes < 0) minutes = -minutes;
  final hh = (minutes ~/ 60).toString().padLeft(2, '0');
  final mm = (minutes % 60).toString().padLeft(2, '0');
  return '$sign$hh$mm';
}

/// Matches a [DateTime] representing the exact same epoch millisecond as
/// [expected], regardless of `isUtc`.
Matcher sameInstant(DateTime expected) => predicate<DateTime>(
  (actual) => actual.millisecondsSinceEpoch == expected.millisecondsSinceEpoch,
  'same instant as ${expected.toUtc().toIso8601String()} '
  '(${expected.millisecondsSinceEpoch})',
);
