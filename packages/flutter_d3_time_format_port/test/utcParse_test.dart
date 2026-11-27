// Ported from d3-time-format v4.1.0 test/utcParse-test.js (ISC, Mike Bostock).
// ignore_for_file: avoid_redundant_argument_values, file_names

import 'package:flutter_d3_time_format_port/d3_time_format.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  // DIVERGES(d3-time-format): adapt-time-format-typed-api, utcParse accepts
  // typed String without JS toString() coercion.
  test(
    'utcParse(specifier) coerces the specified specifier to a string',
    () {},
    skip: 'diverges: adapt-time-format-typed-api',
  );

  test('utcParse("")(date) parses abbreviated weekday and numeric date', () {
    final p = utcParse('%a %m/%d/%Y');
    expect(p('Sun 01/01/1990'), utc(1990, 0, 1));
    expect(p('Wed 02/03/1991'), utc(1991, 1, 3));
    expect(p('XXX 03/10/2010'), isNull);
  });

  test('utcParse("")(date) parses weekday and numeric date', () {
    final p = utcParse('%A %m/%d/%Y');
    expect(p('Sunday 01/01/1990'), utc(1990, 0, 1));
    expect(p('Wednesday 02/03/1991'), utc(1991, 1, 3));
    expect(p('Caturday 03/10/2010'), isNull);
  });

  test('utcParse("")(date) parses numeric date', () {
    final p = utcParse('%m/%d/%y');
    expect(p('01/01/90'), utc(1990, 0, 1));
    expect(p('02/03/91'), utc(1991, 1, 3));
    expect(p('03/10/2010'), isNull);
  });

  test('utcParse("")(date) parses locale date', () {
    final p = utcParse('%x');
    expect(p('01/01/1990'), utc(1990, 0, 1));
    expect(p('02/03/1991'), utc(1991, 1, 3));
    expect(p('03/10/2010'), utc(2010, 2, 10));
  });

  test('utcParse("")(date) parses abbreviated month, date and year', () {
    final p = utcParse('%b %d, %Y');
    expect(p('jan 01, 1990'), utc(1990, 0, 1));
    expect(p('feb  2, 2010'), utc(2010, 1, 2));
    expect(p('jan. 1, 1990'), isNull);
  });

  test('utcParse("")(date) parses month, date and year', () {
    final p = utcParse('%B %d, %Y');
    expect(p('january 01, 1990'), utc(1990, 0, 1));
    expect(p('February  2, 2010'), utc(2010, 1, 2));
    expect(p('jan 1, 1990'), isNull);
  });

  test('utcParse("")(date) parses locale date and time', () {
    final p = utcParse('%c');
    expect(p('1/1/1990, 12:00:00 AM'), utc(1990, 0, 1));
  });

  test('utcParse("")(date) parses twenty-four hour, minute and second', () {
    final p = utcParse('%H:%M:%S');
    expect(p('00:00:00'), utc(1900, 0, 1, 0, 0, 0));
    expect(p('11:59:59'), utc(1900, 0, 1, 11, 59, 59));
    expect(p('12:00:00'), utc(1900, 0, 1, 12, 0, 0));
    expect(p('12:00:01'), utc(1900, 0, 1, 12, 0, 1));
    expect(p('23:59:59'), utc(1900, 0, 1, 23, 59, 59));
  });

  test('utcParse("")(date) parses locale time', () {
    final p = utcParse('%X');
    expect(p('12:00:00 AM'), utc(1900, 0, 1, 0, 0, 0));
    expect(p('11:59:59 AM'), utc(1900, 0, 1, 11, 59, 59));
    expect(p('12:00:00 PM'), utc(1900, 0, 1, 12, 0, 0));
    expect(p('12:00:01 PM'), utc(1900, 0, 1, 12, 0, 1));
    expect(p('11:59:59 PM'), utc(1900, 0, 1, 23, 59, 59));
  });

  test('utcParse("%L")(date) parses milliseconds', () {
    final p = utcParse('%L');
    expect(p('432'), utc(1900, 0, 1, 0, 0, 0, 432));
  });

  test('utcParse("%f")(date) parses microseconds', () {
    final p = utcParse('%f');
    expect(p('432000'), utc(1900, 0, 1, 0, 0, 0, 432));
  });

  test('utcParse("")(date) parses twelve hour, minute and second', () {
    final p = utcParse('%I:%M:%S %p');
    expect(p('12:00:00 am'), utc(1900, 0, 1, 0, 0, 0));
    expect(p('11:59:59 AM'), utc(1900, 0, 1, 11, 59, 59));
    expect(p('12:00:00 pm'), utc(1900, 0, 1, 12, 0, 0));
    expect(p('12:00:01 pm'), utc(1900, 0, 1, 12, 0, 1));
    expect(p('11:59:59 PM'), utc(1900, 0, 1, 23, 59, 59));
  });

  // DIVERGES(d3-time-format): platform-time-format-tz-tests, checks -0800
  // against utc(1990, 0, 2, 8) (and sameInstant(local(1990, 0, 2)) in LA).
  test('utcParse("")(date) parses timezone offset', () {
    final p = utcParse('%m/%d/%Y %Z');
    expect(p('01/02/1990 +0000'), utc(1990, 0, 2));
    expect(p('01/02/1990 +0100'), utc(1990, 0, 1, 23));
    expect(p('01/02/1990 -0100'), utc(1990, 0, 2, 1));
    expect(p('01/02/1990 -0800'), utc(1990, 0, 2, 8));
    if (isAmericaLosAngeles) {
      expect(p('01/02/1990 -0800'), sameInstant(local(1990, 0, 2)));
    }
  });

  test(
    "utcParse(\"\")(date) parses timezone offset (in the form '+-hh:mm')",
    () {
      final p = utcParse('%m/%d/%Y %Z');
      expect(p('01/02/1990 +01:30'), utc(1990, 0, 1, 22, 30));
      expect(p('01/02/1990 -01:30'), utc(1990, 0, 2, 1, 30));
    },
  );

  test("utcParse(\"\")(date) parses timezone offset (in the form '+-hh')", () {
    final p = utcParse('%m/%d/%Y %Z');
    expect(p('01/02/1990 +01'), utc(1990, 0, 1, 23));
    expect(p('01/02/1990 -01'), utc(1990, 0, 2, 1));
  });

  test("utcParse(\"\")(date) parses timezone offset (in the form 'Z')", () {
    final p = utcParse('%m/%d/%Y %Z');
    expect(p('01/02/1990 Z'), utc(1990, 0, 2));
  });

  test('utcParse("%Y %U %w")(date) handles a year that starts on Sunday', () {
    final p = utcParse('%Y %U %w');
    expect(p('2012 01 0'), utc(2012, 0, 1));
  });

  test('utcParse("%w %V %Y")(date) parses numeric weekday, week number (ISO) '
      'and year', () {
    final p = utcParse('%w %V %Y');
    expect(p('1 01 1990'), utc(1990, 0, 1));
    expect(p('0 05 1991'), utc(1991, 1, 3));
    expect(p('4 53 1992'), utc(1992, 11, 31));
    expect(p('0 52 1994'), utc(1995, 0, 1));
    expect(p('0 01 1995'), utc(1995, 0, 8));
    expect(p('X 03 2010'), isNull);
  });

  test('utcParse("%w %V %G")(date) parses numeric weekday, week number (ISO) '
      'and corresponding year', () {
    final p = utcParse('%w %V %G');
    expect(p('1 01 1990'), utc(1990, 0, 1));
    expect(p('0 05 1991'), utc(1991, 1, 3));
    expect(p('4 53 1992'), utc(1992, 11, 31));
    expect(p('0 52 1994'), utc(1995, 0, 1));
    expect(p('0 01 1995'), utc(1995, 0, 8));
    expect(p('1 01 2018'), utc(2018, 0, 1));
    expect(p('1 01 2019'), utc(2018, 11, 31));
    expect(p('X 03 2010'), isNull);
  });

  test('utcParse("%V %Y")(date) week number (ISO) and year', () {
    final p = utcParse('%V %Y');
    expect(p('01 1990'), utc(1990, 0, 1));
    expect(p('05 1991'), utc(1991, 0, 28));
    expect(p('53 1992'), utc(1992, 11, 28));
    expect(p('01 1993'), utc(1993, 0, 4));
    expect(p('01 1995'), utc(1995, 0, 2));
    expect(p('00 1995'), isNull);
    expect(p('54 1995'), isNull);
    expect(p('X 1995'), isNull);
  });

  test('utcParse("%V %g")(date) week number (ISO) and corresponding two-digits '
      'year', () {
    final p = utcParse('%V %g');
    expect(p('01 90'), utc(1990, 0, 1));
    expect(p('05 91'), utc(1991, 0, 28));
    expect(p('53 92'), utc(1992, 11, 28));
    expect(p('01 93'), utc(1993, 0, 4));
    expect(p('01 95'), utc(1995, 0, 2));
    expect(p('01 18'), utc(2018, 0, 1));
    expect(p('01 19'), utc(2018, 11, 31));
    expect(p('00 95'), isNull);
    expect(p('54 95'), isNull);
    expect(p('X 95'), isNull);
  });

  test('utcParse("%V %G")(date) week number (ISO) and corresponding year', () {
    final p = utcParse('%V %G');
    expect(p('01 1990'), utc(1990, 0, 1));
    expect(p('05 1991'), utc(1991, 0, 28));
    expect(p('53 1992'), utc(1992, 11, 28));
    expect(p('01 1993'), utc(1993, 0, 4));
    expect(p('01 1995'), utc(1995, 0, 2));
    expect(p('01 2018'), utc(2018, 0, 1));
    expect(p('01 2019'), utc(2018, 11, 31));
    expect(p('00 1995'), isNull);
    expect(p('54 1995'), isNull);
    expect(p('X 1995'), isNull);
  });

  test('utcParse("%Q")(date) parses UNIX timestamps', () {
    final p = utcParse('%Q');
    expect(p('0'), utc(1970, 0, 1));
    expect(p('631152000000'), utc(1990, 0, 1));
  });

  test('utcParse("%s")(date) parses UNIX timestamps in seconds', () {
    final p = utcParse('%s');
    expect(p('0'), utc(1970, 0, 1));
    expect(p('631152000'), utc(1990, 0, 1));
  });

  test(
    'utcParse("%s.%L")(date) parses UNIX timetamps in seconds and milliseconds',
    () {
      final p = utcParse('%s.%L');
      expect(p('631152000.123'), utc(1990, 0, 1, 0, 0, 0, 123));
      expect(p('631197296.789'), utc(1990, 0, 1, 12, 34, 56, 789));
    },
  );

  test(
    'utcParse("%s.%f")(date) parses UNIX timetamps in seconds and microseconds',
    () {
      final p = utcParse('%s.%f');
      expect(p('631152000.123000'), utc(1990, 0, 1, 0, 0, 0, 123));
      expect(p('631197296.789000'), utc(1990, 0, 1, 12, 34, 56, 789));
    },
  );
}
