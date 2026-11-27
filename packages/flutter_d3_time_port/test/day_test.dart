// Ported from d3-time v3.1.0 test/day-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('timeDays in an alias for timeDay.range', () {
    expect(timeDays, equals(timeDay.range));
  });

  test('timeDay() is equivalent to timeDay.floor(new Date)', () {
    final t = DateTime.now();
    expect(timeDay(), equals(timeDay.floor(t)));
  });

  test('timeDay(date) is equivalent to timeDay.floor(date)', () {
    final t = DateTime.now();
    expect(timeDay(t), equals(timeDay.floor(t)));
  });

  test('timeDay.floor(date) returns days', () {
    expect(timeDay.floor(local(2010, 11, 31, 23)), equals(local(2010, 11, 31)));
    expect(timeDay.floor(local(2011)), equals(local(2011)));
    expect(timeDay.floor(local(2011, 0, 1, 1)), equals(local(2011)));
  });

  // DIVERGES(d3-time): platform-time-tz-tests, checks exact LA assertions when
  // host TZ is America/Los_Angeles and equivalent host-TZ local-midnight
  // invariants on other timezones.
  test('timeDay.floor(date) observes daylight saving', () {
    if (isAmericaLosAngeles) {
      expect(timeDay.floor(utc(2011, 2, 13, 7)), equals(local(2011, 2, 12)));
      expect(timeDay.floor(utc(2011, 2, 13, 8)), equals(local(2011, 2, 13)));
      expect(timeDay.floor(utc(2011, 2, 13, 9)), equals(local(2011, 2, 13)));
      expect(timeDay.floor(utc(2011, 2, 13, 10)), equals(local(2011, 2, 13)));
      expect(timeDay.floor(utc(2011, 10, 6, 7)), equals(local(2011, 10, 6)));
      expect(timeDay.floor(utc(2011, 10, 6, 8)), equals(local(2011, 10, 6)));
      expect(timeDay.floor(utc(2011, 10, 6, 9)), equals(local(2011, 10, 6)));
      expect(timeDay.floor(utc(2011, 10, 6, 10)), equals(local(2011, 10, 6)));
    } else {
      for (final d in [
        utc(2011, 2, 13, 7),
        utc(2011, 2, 13, 8),
        utc(2011, 2, 13, 9),
        utc(2011, 2, 13, 10),
        utc(2011, 10, 6, 7),
        utc(2011, 10, 6, 8),
        utc(2011, 10, 6, 9),
        utc(2011, 10, 6, 10),
      ]) {
        final loc = d.toLocal();
        expect(
          timeDay.floor(d),
          equals(DateTime(loc.year, loc.month, loc.day)),
        );
      }
    }
  });

  test('timeDay.floor(date) handles years in the first century', () {
    expect(timeDay.floor(local(9, 10, 6, 7)), equals(local(9, 10, 6)));
  });

  test('timeDay.round(date) returns days', () {
    expect(timeDay.round(local(2010, 11, 30, 13)), equals(local(2010, 11, 31)));
    expect(timeDay.round(local(2010, 11, 30, 11)), equals(local(2010, 11, 30)));
  });

  test('timeDay.round(date) observes daylight saving', () {
    if (isAmericaLosAngeles) {
      expect(timeDay.round(utc(2011, 2, 13, 7)), equals(local(2011, 2, 13)));
      expect(timeDay.round(utc(2011, 2, 13, 8)), equals(local(2011, 2, 13)));
      expect(timeDay.round(utc(2011, 2, 13, 9)), equals(local(2011, 2, 13)));
      expect(timeDay.round(utc(2011, 2, 13, 20)), equals(local(2011, 2, 14)));
      expect(timeDay.round(utc(2011, 10, 6, 7)), equals(local(2011, 10, 6)));
      expect(timeDay.round(utc(2011, 10, 6, 8)), equals(local(2011, 10, 6)));
      expect(timeDay.round(utc(2011, 10, 6, 9)), equals(local(2011, 10, 6)));
      expect(timeDay.round(utc(2011, 10, 6, 20)), equals(local(2011, 10, 7)));
    } else {
      for (final d in [
        local(2011, 2, 12, 23),
        local(2011, 2, 13),
        local(2011, 2, 13, 1),
        local(2011, 2, 13, 13),
        local(2011, 10, 6),
        local(2011, 10, 6, 13),
      ]) {
        final d0 = timeDay.floor(d);
        final d1 = timeDay.ceil(d);
        final expected =
            d.millisecondsSinceEpoch - d0.millisecondsSinceEpoch <
                d1.millisecondsSinceEpoch - d.millisecondsSinceEpoch
            ? d0
            : d1;
        expect(timeDay.round(d), equals(expected));
      }
    }
  });

  test('timeDay.round(date) handles midnight in leap years', () {
    if (isAmericaLosAngeles) {
      expect(timeDay.round(utc(2012, 2)), equals(local(2012, 2)));
      expect(timeDay.round(utc(2012, 2)), equals(local(2012, 2)));
    } else {
      expect(timeDay.round(local(2012, 2)), equals(local(2012, 2)));
    }
  });

  test('timeDay.ceil(date) returns days', () {
    expect(timeDay.ceil(local(2010, 11, 30, 23)), equals(local(2010, 11, 31)));
    expect(timeDay.ceil(local(2010, 11, 31)), equals(local(2010, 11, 31)));
    expect(timeDay.ceil(local(2010, 11, 31, 1)), equals(local(2011)));
  });

  test('timeDay.ceil(date) observes start of daylight saving', () {
    if (isAmericaLosAngeles) {
      expect(timeDay.ceil(utc(2011, 2, 13, 7)), equals(local(2011, 2, 13)));
      expect(timeDay.ceil(utc(2011, 2, 13, 8)), equals(local(2011, 2, 13)));
      expect(timeDay.ceil(utc(2011, 2, 13, 9)), equals(local(2011, 2, 14)));
      expect(timeDay.ceil(utc(2011, 2, 13, 10)), equals(local(2011, 2, 14)));
    } else {
      expect(timeDay.ceil(local(2011, 2, 12, 23)), equals(local(2011, 2, 13)));
      expect(timeDay.ceil(local(2011, 2, 13)), equals(local(2011, 2, 13)));
      expect(timeDay.ceil(local(2011, 2, 13, 1)), equals(local(2011, 2, 14)));
    }
  });

  test('timeDay.ceil(date) observes end of daylight saving', () {
    if (isAmericaLosAngeles) {
      expect(timeDay.ceil(utc(2011, 10, 6, 7)), equals(local(2011, 10, 6)));
      expect(timeDay.ceil(utc(2011, 10, 6, 8)), equals(local(2011, 10, 7)));
      expect(timeDay.ceil(utc(2011, 10, 6, 9)), equals(local(2011, 10, 7)));
      expect(timeDay.ceil(utc(2011, 10, 6, 10)), equals(local(2011, 10, 7)));
    } else {
      expect(timeDay.ceil(local(2011, 10, 6)), equals(local(2011, 10, 6)));
      expect(timeDay.ceil(local(2011, 10, 6, 1)), equals(local(2011, 10, 7)));
    }
  });

  test('timeDay.ceil(date) handles midnight for leap years', () {
    if (isAmericaLosAngeles) {
      expect(timeDay.ceil(utc(2012, 2)), equals(local(2012, 2)));
      expect(timeDay.ceil(utc(2012, 2)), equals(local(2012, 2)));
    } else {
      expect(timeDay.ceil(local(2012, 2)), equals(local(2012, 2)));
    }
  });

  test('timeDay.offset(date) is an alias for timeDay.offset(date, 1)', () {
    expect(
      timeDay.offset(local(2010, 11, 31, 23, 59, 59, 999)),
      equals(local(2011, 0, 1, 23, 59, 59, 999)),
    );
  });

  test('timeDay.offset(date, step) does not modify the passed-in date', () {
    final d = local(2010, 11, 31, 23, 59, 59, 999);
    timeDay.offset(d);
    expect(d, equals(local(2010, 11, 31, 23, 59, 59, 999)));
  });

  test('timeDay.offset(date, step) does not round the passed-in date', () {
    expect(
      timeDay.offset(local(2010, 11, 31, 23, 59, 59, 999)),
      equals(local(2011, 0, 1, 23, 59, 59, 999)),
    );
    expect(
      timeDay.offset(local(2010, 11, 31, 23, 59, 59, 456), -2),
      equals(local(2010, 11, 29, 23, 59, 59, 456)),
    );
  });

  test('timeDay.offset(date, step) allows step to be negative', () {
    expect(
      timeDay.offset(local(2010, 11, 31), -1),
      equals(local(2010, 11, 30)),
    );
    expect(timeDay.offset(local(2011), -2), equals(local(2010, 11, 30)));
    expect(timeDay.offset(local(2011), -1), equals(local(2010, 11, 31)));
  });

  test('timeDay.offset(date, step) allows step to be positive', () {
    expect(timeDay.offset(local(2010, 11, 31)), equals(local(2011)));
    expect(timeDay.offset(local(2010, 11, 30), 2), equals(local(2011)));
    expect(timeDay.offset(local(2010, 11, 30)), equals(local(2010, 11, 31)));
  });

  test('timeDay.offset(date, step) allows step to be zero', () {
    expect(
      timeDay.offset(local(2010, 11, 31, 23, 59, 59, 999), 0),
      equals(local(2010, 11, 31, 23, 59, 59, 999)),
    );
    expect(
      timeDay.offset(local(2010, 11, 31, 23, 59, 58), 0),
      equals(local(2010, 11, 31, 23, 59, 58)),
    );
  });

  test('timeDay.range(start, stop) returns days between start (inclusive) and '
      'stop (exclusive)', () {
    expect(
      timeDay.range(local(2011, 10, 4), local(2011, 10, 10)),
      equals([
        local(2011, 10, 4),
        local(2011, 10, 5),
        local(2011, 10, 6),
        local(2011, 10, 7),
        local(2011, 10, 8),
        local(2011, 10, 9),
      ]),
    );
  });

  test('timeDay.range(start, stop) returns days', () {
    expect(
      timeDay.range(local(2011, 10, 4, 2), local(2011, 10, 10, 13)),
      equals([
        local(2011, 10, 5),
        local(2011, 10, 6),
        local(2011, 10, 7),
        local(2011, 10, 8),
        local(2011, 10, 9),
        local(2011, 10, 10),
      ]),
    );
  });

  test(
    'timeDay.range(start, stop) coerces start and stop to dates',
    () {},
    skip: 'diverges: adapt-time-typed-api (range takes typed DateTime)',
  );

  test(
    'timeDay.range(start, stop) returns the empty array for invalid dates',
    () {},
    skip: 'diverges: adapt-time-typed-api (Dart DateTime cannot hold NaN)',
  );

  test(
    'timeDay.range(start, stop) returns the empty array if start >= stop',
    () {
      expect(timeDay.range(local(2011, 10, 10), local(2011, 10, 4)), isEmpty);
      expect(timeDay.range(local(2011, 10, 10), local(2011, 10, 10)), isEmpty);
    },
  );

  test('timeDay.range(start, stop, step) returns every step day', () {
    expect(
      timeDay.range(local(2011, 10, 4, 2), local(2011, 10, 14, 13), 3),
      equals([
        local(2011, 10, 5),
        local(2011, 10, 8),
        local(2011, 10, 11),
        local(2011, 10, 14),
      ]),
    );
  });

  test('timeDay.range(start, stop, step) returns the empty array if step is '
      'zero, negative or NaN', () {
    expect(timeDay.range(local(2011), local(2011, 4, 9), 0), isEmpty);
    expect(timeDay.range(local(2011), local(2011, 4, 9), -1), isEmpty);
  });

  test('timeDay.count(start, end) counts days after start (exclusive) and '
      'before end (inclusive)', () {
    expect(timeDay.count(local(2011), local(2011, 4, 9)), 128);
    expect(timeDay.count(local(2011, 0, 1, 1), local(2011, 4, 9)), 128);
    expect(timeDay.count(local(2010, 11, 31, 23), local(2011, 4, 9)), 129);
    expect(timeDay.count(local(2011), local(2011, 4, 8, 23)), 127);
    expect(timeDay.count(local(2011), local(2011, 4, 9, 1)), 128);
  });

  test('timeDay.count(start, end) observes daylight saving', () {
    expect(timeDay.count(local(2011), local(2011, 2, 13, 1)), 71);
    expect(timeDay.count(local(2011), local(2011, 2, 13, 3)), 71);
    expect(timeDay.count(local(2011), local(2011, 2, 13, 4)), 71);
    expect(timeDay.count(local(2011), local(2011, 10, 6)), 309);
    expect(timeDay.count(local(2011), local(2011, 10, 6, 1)), 309);
    expect(timeDay.count(local(2011), local(2011, 10, 6, 2)), 309);
  });

  test(
    'timeDay.count(start, stop) does not exhibit floating-point rounding error',
    () {
      final date = DateTime(2011, 5, 9);
      expect(timeDay.count(timeYear(date), date), 128);
    },
  );

  test('timeDay.count(start, end) returns 364 or 365 for a full year', () {
    expect(timeDay.count(local(1999), local(1999, 11, 31)), 364);
    expect(timeDay.count(local(2000), local(2000, 11, 31)), 365);
    expect(timeDay.count(local(2001), local(2001, 11, 31)), 364);
    expect(timeDay.count(local(2002), local(2002, 11, 31)), 364);
    expect(timeDay.count(local(2003), local(2003, 11, 31)), 364);
    expect(timeDay.count(local(2004), local(2004, 11, 31)), 365);
    expect(timeDay.count(local(2005), local(2005, 11, 31)), 364);
    expect(timeDay.count(local(2006), local(2006, 11, 31)), 364);
    expect(timeDay.count(local(2007), local(2007, 11, 31)), 364);
    expect(timeDay.count(local(2008), local(2008, 11, 31)), 365);
    expect(timeDay.count(local(2009), local(2009, 11, 31)), 364);
    expect(timeDay.count(local(2010), local(2010, 11, 31)), 364);
    expect(timeDay.count(local(2011), local(2011, 11, 31)), 364);
  });

  test('timeDay.every(step) returns every stepth day, starting with the first '
      'day of the month', () {
    expect(
      timeDay
          .every(3)!
          .range(local(2008, 11, 30, 0, 12), local(2009, 0, 5, 23, 48)),
      equals([local(2008, 11, 31), local(2009), local(2009, 0, 4)]),
    );
    expect(
      timeDay
          .every(5)!
          .range(local(2008, 11, 30, 0, 12), local(2009, 0, 6, 23, 48)),
      equals([local(2008, 11, 31), local(2009), local(2009, 0, 6)]),
    );
    expect(
      timeDay
          .every(7)!
          .range(local(2008, 11, 30, 0, 12), local(2009, 0, 8, 23, 48)),
      equals([local(2009), local(2009, 0, 8)]),
    );
  });
}
