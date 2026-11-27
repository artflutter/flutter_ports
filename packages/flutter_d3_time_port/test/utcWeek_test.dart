// Ported from d3-time v3.1.0 test/utcWeek-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('utcWeek.floor(date) returns sundays', () {
    expect(
      utcWeek.floor(utc(2010, 11, 31, 23, 59, 59)),
      equals(utc(2010, 11, 26)),
    );
    expect(utcWeek.floor(utc(2011)), equals(utc(2010, 11, 26)));
    expect(utcWeek.floor(utc(2011, 0, 1, 0, 0, 1)), equals(utc(2010, 11, 26)));
    expect(
      utcWeek.floor(utc(2011, 0, 1, 23, 59, 59)),
      equals(utc(2010, 11, 26)),
    );
    expect(utcWeek.floor(utc(2011, 0, 2)), equals(utc(2011, 0, 2)));
    expect(utcWeek.floor(utc(2011, 0, 2, 0, 0, 1)), equals(utc(2011, 0, 2)));
  });

  test('utcWeek.floor(date) observes the start of daylight savings time', () {
    expect(utcWeek.floor(utc(2011, 2, 13, 1)), equals(utc(2011, 2, 13)));
  });

  test('utcWeek.floor(date) observes the end of the daylight savings time', () {
    expect(utcWeek.floor(utc(2011, 10, 6, 1)), equals(utc(2011, 10, 6)));
  });

  test('utcWeek.floor(date) correctly handles years in the first century', () {
    expect(utcWeek.floor(utc(9, 10, 6, 7)), equals(utc(9, 10)));
  });

  test('utcWeek.ceil(date) returns sundays', () {
    expect(
      utcWeek.ceil(utc(2010, 11, 31, 23, 59, 59)),
      equals(utc(2011, 0, 2)),
    );
    expect(utcWeek.ceil(utc(2011)), equals(utc(2011, 0, 2)));
    expect(utcWeek.ceil(utc(2011, 0, 1, 0, 0, 1)), equals(utc(2011, 0, 2)));
    expect(utcWeek.ceil(utc(2011, 0, 1, 23, 59, 59)), equals(utc(2011, 0, 2)));
    expect(utcWeek.ceil(utc(2011, 0, 2)), equals(utc(2011, 0, 2)));
    expect(utcWeek.ceil(utc(2011, 0, 2, 0, 0, 1)), equals(utc(2011, 0, 9)));
  });

  test(
    'utcWeek.ceil(date) does not observe the start of daylight savings time',
    () {
      expect(utcWeek.ceil(utc(2011, 2, 13, 1)), equals(utc(2011, 2, 20)));
    },
  );

  test(
    'utcWeek.ceil(date) does not observe the end of the daylight savings time',
    () {
      expect(utcWeek.ceil(utc(2011, 10, 6, 1)), equals(utc(2011, 10, 13)));
    },
  );

  test('utcWeek.offset(date, step) does not modify the passed-in date', () {
    final d = utc(2010, 11, 31, 23, 59, 59, 999);
    utcWeek.offset(d);
    expect(d, equals(utc(2010, 11, 31, 23, 59, 59, 999)));
  });

  test('utcWeek.offset(date, step) does not round the passed-in-date', () {
    expect(
      utcWeek.offset(utc(2010, 11, 31, 23, 59, 59, 999)),
      equals(utc(2011, 0, 7, 23, 59, 59, 999)),
    );
    expect(
      utcWeek.offset(utc(2010, 11, 31, 23, 59, 59, 456), -2),
      equals(utc(2010, 11, 17, 23, 59, 59, 456)),
    );
  });

  test('utcWeek.offset(date, step) allows negative offsets', () {
    expect(utcWeek.offset(utc(2010, 11), -1), equals(utc(2010, 10, 24)));
    expect(utcWeek.offset(utc(2011), -2), equals(utc(2010, 11, 18)));
    expect(utcWeek.offset(utc(2011), -1), equals(utc(2010, 11, 25)));
  });

  test('utcWeek.offset(date, step) allows positive offsets', () {
    expect(utcWeek.offset(utc(2010, 10, 24)), equals(utc(2010, 11)));
    expect(utcWeek.offset(utc(2010, 11, 18), 2), equals(utc(2011)));
    expect(utcWeek.offset(utc(2010, 11, 25)), equals(utc(2011)));
  });

  test('utcWeek.offset(date, step) allows zero offset', () {
    expect(
      utcWeek.offset(utc(2010, 11, 31, 23, 59, 59, 999), 0),
      equals(utc(2010, 11, 31, 23, 59, 59, 999)),
    );
    expect(
      utcWeek.offset(utc(2010, 11, 31, 23, 59, 58), 0),
      equals(utc(2010, 11, 31, 23, 59, 58)),
    );
  });

  test('utcWeek.range(start, stop) returns sundays', () {
    expect(
      utcWeek.range(utc(2010, 11, 21), utc(2011, 0, 12)),
      equals([utc(2010, 11, 26), utc(2011, 0, 2), utc(2011, 0, 9)]),
    );
  });

  test('utcWeek.range(start, stop) has an inclusive lower bound', () {
    expect(
      utcWeek.range(utc(2010, 11, 21), utc(2011, 0, 12))[0],
      equals(utc(2010, 11, 26)),
    );
  });

  test('utcWeek.range(start, stop) has an exclusive upper bound', () {
    expect(
      utcWeek.range(utc(2010, 11, 21), utc(2011, 0, 12))[2],
      equals(utc(2011, 0, 9)),
    );
  });

  test('utcWeek.range(start, stop) can skip weeks', () {
    expect(
      utcWeek.range(utc(2011), utc(2011, 3), 4),
      equals([
        utc(2011, 0, 2),
        utc(2011, 0, 30),
        utc(2011, 1, 27),
        utc(2011, 2, 27),
      ]),
    );
  });

  test('utcWeek.range(start, stop) does not observe start of daylight savings '
      'time', () {
    expect(
      utcWeek.range(utc(2011, 2), utc(2011, 2, 28)),
      equals([
        utc(2011, 2, 6),
        utc(2011, 2, 13),
        utc(2011, 2, 20),
        utc(2011, 2, 27),
      ]),
    );
  });

  test(
    'utcWeek.range(start, stop) does not observe end of daylight savings time',
    () {
      expect(
        utcWeek.range(utc(2011, 10), utc(2011, 10, 30)),
        equals([
          utc(2011, 10, 6),
          utc(2011, 10, 13),
          utc(2011, 10, 20),
          utc(2011, 10, 27),
        ]),
      );
    },
  );

  test('utcWeek is an alias for utcSunday', () {
    expect(identical(utcWeek, utcSunday), isTrue);
  });

  test(
    'utcWeek.every(step) returns every stepth Sunday, starting with the first '
    'Sunday of the month',
    () {
      expect(
        utcWeek.every(2)!.range(utc(2008, 11, 3), utc(2009, 1, 5)),
        equals([
          utc(2008, 11, 7),
          utc(2008, 11, 21),
          utc(2009, 0, 4),
          utc(2009, 0, 18),
          utc(2009, 1),
        ]),
      );
    },
  );
}
