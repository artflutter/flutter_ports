// Ported from d3-time-format v4.1.0 test/utcFormat-test.js (ISC, Mike Bostock).
// ignore_for_file: avoid_redundant_argument_values, file_names

import 'package:flutter_d3_time_format_port/d3_time_format.dart';
import 'package:flutter_d3_time_port/d3_time.dart';
import 'package:test/test.dart';

import 'date.dart';

final TimeFormat _formatMillisecond = utcFormat('.%L');
final TimeFormat _formatSecond = utcFormat(':%S');
final TimeFormat _formatMinute = utcFormat('%I:%M');
final TimeFormat _formatHour = utcFormat('%I %p');
final TimeFormat _formatDay = utcFormat('%a %d');
final TimeFormat _formatWeek = utcFormat('%b %d');
final TimeFormat _formatMonth = utcFormat('%B');
final TimeFormat _formatYear = utcFormat('%Y');

String _multi(DateTime d) => (utcSecond(d).isBefore(d)
    ? _formatMillisecond
    : utcMinute(d).isBefore(d)
    ? _formatSecond
    : utcHour(d).isBefore(d)
    ? _formatMinute
    : utcDay(d).isBefore(d)
    ? _formatHour
    : utcMonth(d).isBefore(d)
    ? (utcWeek(d).isBefore(d) ? _formatDay : _formatWeek)
    : utcYear(d).isBefore(d)
    ? _formatMonth
    : _formatYear)(d);

void main() {
  test('utcFormat("%a")(date) formats abbreviated weekdays', () {
    final f = utcFormat('%a');
    expect(f(utc(1990, 0, 1)), 'Mon');
    expect(f(utc(1990, 0, 2)), 'Tue');
    expect(f(utc(1990, 0, 3)), 'Wed');
    expect(f(utc(1990, 0, 4)), 'Thu');
    expect(f(utc(1990, 0, 5)), 'Fri');
    expect(f(utc(1990, 0, 6)), 'Sat');
    expect(f(utc(1990, 0, 7)), 'Sun');
  });

  test('utcFormat("%A")(date) formats weekdays', () {
    final f = utcFormat('%A');
    expect(f(utc(1990, 0, 1)), 'Monday');
    expect(f(utc(1990, 0, 2)), 'Tuesday');
    expect(f(utc(1990, 0, 3)), 'Wednesday');
    expect(f(utc(1990, 0, 4)), 'Thursday');
    expect(f(utc(1990, 0, 5)), 'Friday');
    expect(f(utc(1990, 0, 6)), 'Saturday');
    expect(f(utc(1990, 0, 7)), 'Sunday');
  });

  test('utcFormat("%b")(date) formats abbreviated months', () {
    final f = utcFormat('%b');
    expect(f(utc(1990, 0, 1)), 'Jan');
    expect(f(utc(1990, 1, 1)), 'Feb');
    expect(f(utc(1990, 2, 1)), 'Mar');
    expect(f(utc(1990, 3, 1)), 'Apr');
    expect(f(utc(1990, 4, 1)), 'May');
    expect(f(utc(1990, 5, 1)), 'Jun');
    expect(f(utc(1990, 6, 1)), 'Jul');
    expect(f(utc(1990, 7, 1)), 'Aug');
    expect(f(utc(1990, 8, 1)), 'Sep');
    expect(f(utc(1990, 9, 1)), 'Oct');
    expect(f(utc(1990, 10, 1)), 'Nov');
    expect(f(utc(1990, 11, 1)), 'Dec');
  });

  test('utcFormat("%B")(date) formats months', () {
    final f = utcFormat('%B');
    expect(f(utc(1990, 0, 1)), 'January');
    expect(f(utc(1990, 1, 1)), 'February');
    expect(f(utc(1990, 2, 1)), 'March');
    expect(f(utc(1990, 3, 1)), 'April');
    expect(f(utc(1990, 4, 1)), 'May');
    expect(f(utc(1990, 5, 1)), 'June');
    expect(f(utc(1990, 6, 1)), 'July');
    expect(f(utc(1990, 7, 1)), 'August');
    expect(f(utc(1990, 8, 1)), 'September');
    expect(f(utc(1990, 9, 1)), 'October');
    expect(f(utc(1990, 10, 1)), 'November');
    expect(f(utc(1990, 11, 1)), 'December');
  });

  test('utcFormat("%c")(date) formats localized dates and times', () {
    final f = utcFormat('%c');
    expect(f(utc(1990, 0, 1)), '1/1/1990, 12:00:00 AM');
  });

  test('utcFormat("%d")(date) formats zero-padded dates', () {
    final f = utcFormat('%d');
    expect(f(utc(1990, 0, 1)), '01');
  });

  test('utcFormat("%e")(date) formats space-padded dates', () {
    final f = utcFormat('%e');
    expect(f(utc(1990, 0, 1)), ' 1');
  });

  test(
    'timeFormat("%g")(date) formats zero-padded two-digit ISO 8601 years',
    () {
      final f = utcFormat('%g');
      expect(f(utc(2018, 11, 30, 0)), '18'); // Sunday
      expect(f(utc(2018, 11, 31, 0)), '19'); // Monday
      expect(f(utc(2019, 0, 1, 0)), '19');
    },
  );

  test(
    'utcFormat("%G")(date) formats zero-padded four-digit ISO 8601 years',
    () {
      final f = utcFormat('%G');
      expect(f(utc(2018, 11, 30, 0)), '2018'); // Sunday
      expect(f(utc(2018, 11, 31, 0)), '2019'); // Monday
      expect(f(utc(2019, 0, 1, 0)), '2019');
    },
  );

  test('utcFormat("%H")(date) formats zero-padded hours (24)', () {
    final f = utcFormat('%H');
    expect(f(utc(1990, 0, 1, 0)), '00');
    expect(f(utc(1990, 0, 1, 13)), '13');
  });

  test('utcFormat("%I")(date) formats zero-padded hours (12)', () {
    final f = utcFormat('%I');
    expect(f(utc(1990, 0, 1, 0)), '12');
    expect(f(utc(1990, 0, 1, 13)), '01');
  });

  test('utcFormat("%j")(date) formats zero-padded day of year numbers', () {
    final f = utcFormat('%j');
    expect(f(utc(1990, 0, 1)), '001');
    expect(f(utc(1990, 5, 1)), '152');
    expect(f(utc(2010, 2, 13)), '072');
    expect(f(utc(2010, 2, 14)), '073'); // DST begins
    expect(f(utc(2010, 2, 15)), '074');
    expect(f(utc(2010, 10, 6)), '310');
    expect(f(utc(2010, 10, 7)), '311'); // DST ends
    expect(f(utc(2010, 10, 8)), '312');
  });

  test('utcFormat("%m")(date) formats zero-padded months', () {
    final f = utcFormat('%m');
    expect(f(utc(1990, 0, 1)), '01');
    expect(f(utc(1990, 9, 1)), '10');
  });

  test('utcFormat("%M")(date) formats zero-padded minutes', () {
    final f = utcFormat('%M');
    expect(f(utc(1990, 0, 1, 0, 0)), '00');
    expect(f(utc(1990, 0, 1, 0, 32)), '32');
  });

  test('utcFormat("%p")(date) formats AM or PM', () {
    final f = utcFormat('%p');
    expect(f(utc(1990, 0, 1, 0)), 'AM');
    expect(f(utc(1990, 0, 1, 13)), 'PM');
  });

  test('utcFormat("%q")(date) formats quarters', () {
    final f = utcFormat('%q');
    expect(f(utc(1990, 0, 1)), '1');
    expect(f(utc(1990, 3, 1)), '2');
    expect(f(utc(1990, 6, 1)), '3');
    expect(f(utc(1990, 9, 1)), '4');
  });

  test('utcFormat("%Q")(date) formats UNIX timestamps', () {
    final f = utcFormat('%Q');
    expect(f(utc(1970, 0, 1, 0, 0, 0)), '0');
    expect(f(utc(1990, 0, 1, 0, 0, 0)), '631152000000');
    expect(f(utc(1990, 0, 1, 12, 34, 56)), '631197296000');
  });

  test('utcFormat("%s")(date) formats UNIX timetamps in seconds', () {
    final f = utcFormat('%s');
    expect(f(utc(1970, 0, 1, 0, 0, 0)), '0');
    expect(f(utc(1990, 0, 1, 0, 0, 0)), '631152000');
    expect(f(utc(1990, 0, 1, 12, 34, 56)), '631197296');
  });

  test('utcFormat("%s.%L")(date) formats UNIX timetamps in seconds and '
      'milliseconds', () {
    final f = utcFormat('%s.%L');
    expect(f(utc(1990, 0, 1, 0, 0, 0, 123)), '631152000.123');
    expect(f(utc(1990, 0, 1, 12, 34, 56, 789)), '631197296.789');
  });

  test('utcFormat("%s.%f")(date) formats UNIX timetamps in seconds and '
      'microseconds', () {
    final f = utcFormat('%s.%f');
    expect(f(utc(1990, 0, 1, 0, 0, 0, 123)), '631152000.123000');
    expect(f(utc(1990, 0, 1, 12, 34, 56, 789)), '631197296.789000');
  });

  test('utcFormat("%S")(date) formats zero-padded seconds', () {
    final f = utcFormat('%S');
    expect(f(utc(1990, 0, 1, 0, 0, 0)), '00');
    expect(f(utc(1990, 0, 1, 0, 0, 32)), '32');
    final f2 = utcFormat('%0S');
    expect(f2(utc(1990, 0, 1, 0, 0, 0)), '00');
    expect(f2(utc(1990, 0, 1, 0, 0, 32)), '32');
  });

  test('utcFormat("%_S")(date) formats space-padded seconds', () {
    final f = utcFormat('%_S');
    expect(f(utc(1990, 0, 1, 0, 0, 0)), ' 0');
    expect(f(utc(1990, 0, 1, 0, 0, 3)), ' 3');
    expect(f(utc(1990, 0, 1, 0, 0, 32)), '32');
  });

  test('utcFormat("-S")(date) formats no-padded seconds', () {
    final f = utcFormat('%-S');
    expect(f(utc(1990, 0, 1, 0, 0, 0)), '0');
    expect(f(utc(1990, 0, 1, 0, 0, 3)), '3');
    expect(f(utc(1990, 0, 1, 0, 0, 32)), '32');
  });

  test('utcFormat("%L")(date) formats zero-padded milliseconds', () {
    final f = utcFormat('%L');
    expect(f(utc(1990, 0, 1, 0, 0, 0, 0)), '000');
    expect(f(utc(1990, 0, 1, 0, 0, 0, 432)), '432');
  });

  test('utcFormat("%u")(date) formats week day numbers', () {
    final f = utcFormat('%u');
    expect(f(utc(1990, 0, 1, 0)), '1');
    expect(f(utc(1990, 0, 7, 0)), '7');
    expect(f(utc(2010, 2, 13, 23)), '6');
  });

  test('utcFormat("%f")(date) formats zero-padded microseconds', () {
    final f = utcFormat('%f');
    expect(f(utc(1990, 0, 1, 0, 0, 0, 0)), '000000');
    expect(f(utc(1990, 0, 1, 0, 0, 0, 432)), '432000');
  });

  test('utcFormat("%U")(date) formats zero-padded week numbers', () {
    final f = utcFormat('%U');
    expect(f(utc(1990, 0, 1, 0)), '00');
    expect(f(utc(1990, 5, 1, 0)), '21');
    expect(f(utc(2010, 2, 13, 23)), '10');
    expect(f(utc(2010, 2, 14, 0)), '11'); // DST begins
    expect(f(utc(2010, 2, 15, 0)), '11');
    expect(f(utc(2010, 10, 6, 23)), '44');
    expect(f(utc(2010, 10, 7, 0)), '45'); // DST ends
    expect(f(utc(2010, 10, 8, 0)), '45');
    expect(f(utc(2012, 0, 1, 0)), '01'); // Sunday!
  });

  test('utcFormat("%W")(date) formats zero-padded week numbers', () {
    final f = utcFormat('%W');
    expect(f(utc(1990, 0, 1, 0)), '01'); // Monday!
    expect(f(utc(1990, 5, 1, 0)), '22');
    expect(f(utc(2010, 2, 15, 0)), '11');
    expect(f(utc(2010, 10, 8, 0)), '45');
  });

  test('utcFormat("%V")(date) formats zero-padded ISO 8601 week numbers', () {
    final f = utcFormat('%V');
    expect(f(utc(1990, 0, 1, 0)), '01');
    expect(f(utc(1990, 5, 1, 0)), '22');
    expect(f(utc(2010, 2, 13, 23)), '10');
    expect(f(utc(2010, 2, 14, 0)), '10'); // DST begins
    expect(f(utc(2010, 2, 15, 0)), '11');
    expect(f(utc(2010, 10, 6, 23)), '44');
    expect(f(utc(2010, 10, 7, 0)), '44'); // DST ends
    expect(f(utc(2010, 10, 8, 0)), '45');
    expect(f(utc(2015, 11, 31, 0)), '53');
    expect(f(utc(2016, 0, 1, 0)), '53');
  });

  test('utcFormat("%x")(date) formats localized dates', () {
    final f = utcFormat('%x');
    expect(f(utc(1990, 0, 1)), '1/1/1990');
    expect(f(utc(2010, 5, 1)), '6/1/2010');
  });

  test('utcFormat("%X")(date) formats localized times', () {
    final f = utcFormat('%X');
    expect(f(utc(1990, 0, 1, 0, 0, 0)), '12:00:00 AM');
    expect(f(utc(1990, 0, 1, 13, 34, 59)), '1:34:59 PM');
  });

  test('utcFormat("%y")(date) formats zero-padded two-digit years', () {
    final f = utcFormat('%y');
    expect(f(utc(1990, 0, 1)), '90');
    expect(f(utc(2002, 0, 1)), '02');
    expect(f(utc(-2, 0, 1)), '-02');
  });

  test('utcFormat("%Y")(date) formats zero-padded four-digit years', () {
    final f = utcFormat('%Y');
    expect(f(utc(123, 0, 1)), '0123');
    expect(f(utc(1990, 0, 1)), '1990');
    expect(f(utc(2002, 0, 1)), '2002');
    expect(f(utc(10002, 0, 1)), '0002');
    expect(f(utc(-2, 0, 1)), '-0002');
  });

  test('utcFormat("%Z")(date) formats time zones', () {
    final f = utcFormat('%Z');
    expect(f(utc(1990, 0, 1)), '+0000');
  });

  test('utcFormat("%%")(date) formats literal percent signs', () {
    final f = utcFormat('%%');
    expect(f(utc(1990, 0, 1)), '%');
  });

  test('utcFormat(…) can be used to create a conditional multi-format', () {
    expect(_multi(utc(1990, 0, 1, 0, 0, 0, 12)), '.012');
    expect(_multi(utc(1990, 0, 1, 0, 0, 1, 0)), ':01');
    expect(_multi(utc(1990, 0, 1, 0, 1, 0, 0)), '12:01');
    expect(_multi(utc(1990, 0, 1, 1, 0, 0, 0)), '01 AM');
    expect(_multi(utc(1990, 0, 2, 0, 0, 0, 0)), 'Tue 02');
    expect(_multi(utc(1990, 1, 1, 0, 0, 0, 0)), 'February');
    expect(_multi(utc(1990, 0, 1, 0, 0, 0, 0)), '1990');
  });
}
