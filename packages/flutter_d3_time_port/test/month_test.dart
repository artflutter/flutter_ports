// Ported from d3-time v3.1.0 test/month-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('timeMonths in an alias for timeMonth.range', () {
    expect(timeMonths, equals(timeMonth.range));
  });

  test('timeMonth.floor(date) returns months', () {
    expect(
      timeMonth.floor(local(2010, 11, 31, 23, 59, 59)),
      equals(local(2010, 11)),
    );
    expect(timeMonth.floor(local(2011)), equals(local(2011)));
    expect(timeMonth.floor(local(2011, 0, 1, 0, 0, 1)), equals(local(2011)));
  });

  test('timeMonth.floor(date) observes the start of daylight savings time', () {
    expect(timeMonth.floor(local(2011, 2, 13, 1)), equals(local(2011, 2)));
  });

  test(
    'timeMonth.floor(date) observes the end of the daylight savings time',
    () {
      expect(timeMonth.floor(local(2011, 10, 6, 1)), equals(local(2011, 10)));
    },
  );

  test(
    'timeMonth.floor(date) correctly handles years in the first century',
    () {
      expect(timeMonth.floor(local(9, 10, 6, 7)), equals(local(9, 10)));
    },
  );

  test('timeMonth.ceil(date) returns months', () {
    expect(
      timeMonth.ceil(local(2010, 11, 31, 23, 59, 59)),
      equals(local(2011)),
    );
    expect(timeMonth.ceil(local(2011)), equals(local(2011)));
    expect(timeMonth.ceil(local(2011, 0, 1, 0, 0, 1)), equals(local(2011, 1)));
  });

  test('timeMonth.ceil(date) observes the start of daylight savings time', () {
    expect(timeMonth.ceil(local(2011, 2, 13, 1)), equals(local(2011, 3)));
  });

  test(
    'timeMonth.ceil(date) observes the end of the daylight savings time',
    () {
      expect(timeMonth.ceil(local(2011, 10, 6, 1)), equals(local(2011, 11)));
    },
  );

  test('timeMonth.offset(date) does not modify the passed-in date', () {
    final d = local(2010, 11, 31, 23, 59, 59, 999);
    timeMonth.offset(d);
    expect(d, equals(local(2010, 11, 31, 23, 59, 59, 999)));
  });

  test('timeMonth.offset(date) does not round the passed-in-date', () {
    expect(
      timeMonth.offset(local(2010, 11, 31, 23, 59, 59, 999)),
      equals(local(2011, 0, 31, 23, 59, 59, 999)),
    );
    expect(
      timeMonth.offset(local(2010, 11, 31, 23, 59, 59, 456), -2),
      equals(local(2010, 9, 31, 23, 59, 59, 456)),
    );
  });

  test('timeMonth.offset(date) allows negative offsets', () {
    expect(timeMonth.offset(local(2010, 11), -1), equals(local(2010, 10)));
    expect(timeMonth.offset(local(2011), -2), equals(local(2010, 10)));
    expect(timeMonth.offset(local(2011), -1), equals(local(2010, 11)));
  });

  test('timeMonth.offset(date) allows positive offsets', () {
    expect(timeMonth.offset(local(2010, 10)), equals(local(2010, 11)));
    expect(timeMonth.offset(local(2010, 10), 2), equals(local(2011)));
    expect(timeMonth.offset(local(2010, 11)), equals(local(2011)));
  });

  test('timeMonth.offset(date) allows zero offset', () {
    expect(
      timeMonth.offset(local(2010, 11, 31, 23, 59, 59, 999), 0),
      equals(local(2010, 11, 31, 23, 59, 59, 999)),
    );
    expect(
      timeMonth.offset(local(2010, 11, 31, 23, 59, 58), 0),
      equals(local(2010, 11, 31, 23, 59, 58)),
    );
  });

  test('timeMonths in an alias for timeMonth.range (2)', () {
    expect(timeMonths, equals(timeMonth.range));
  });

  test('timeMonth.floor(date) returns months (2)', () {
    expect(timeMonth.floor(local(2010, 11, 31, 23)), equals(local(2010, 11)));
    expect(timeMonth.floor(local(2011)), equals(local(2011)));
    expect(timeMonth.floor(local(2011, 0, 1, 1)), equals(local(2011)));
  });

  test('timeMonth.floor(date) observes daylight saving', () {
    expect(timeMonth.floor(utc(2011, 2, 13, 7)), equals(local(2011, 2)));
    expect(timeMonth.floor(utc(2011, 2, 13, 8)), equals(local(2011, 2)));
    expect(timeMonth.floor(utc(2011, 2, 13, 9)), equals(local(2011, 2)));
    expect(timeMonth.floor(utc(2011, 2, 13, 10)), equals(local(2011, 2)));
    expect(timeMonth.floor(utc(2011, 10, 6, 7)), equals(local(2011, 10)));
    expect(timeMonth.floor(utc(2011, 10, 6, 8)), equals(local(2011, 10)));
    expect(timeMonth.floor(utc(2011, 10, 6, 9)), equals(local(2011, 10)));
    expect(timeMonth.floor(utc(2011, 10, 6, 10)), equals(local(2011, 10)));
  });

  test('timeMonth.floor(date) handles years in the first century', () {
    expect(timeMonth.floor(local(9, 10, 6, 7)), equals(local(9, 10)));
  });

  test('timeMonth.round(date) returns months', () {
    expect(timeMonth.round(local(2010, 11, 16, 12)), equals(local(2011)));
    expect(timeMonth.round(local(2010, 11, 16, 11)), equals(local(2010, 11)));
  });

  test('timeMonth.round(date) observes daylight saving', () {
    expect(timeMonth.round(utc(2011, 2, 13, 7)), equals(local(2011, 2)));
    expect(timeMonth.round(utc(2011, 2, 13, 8)), equals(local(2011, 2)));
    expect(timeMonth.round(utc(2011, 2, 13, 9)), equals(local(2011, 2)));
    expect(timeMonth.round(utc(2011, 2, 13, 20)), equals(local(2011, 2)));
    expect(timeMonth.round(utc(2011, 10, 6, 7)), equals(local(2011, 10)));
    expect(timeMonth.round(utc(2011, 10, 6, 8)), equals(local(2011, 10)));
    expect(timeMonth.round(utc(2011, 10, 6, 9)), equals(local(2011, 10)));
    expect(timeMonth.round(utc(2011, 10, 6, 20)), equals(local(2011, 10)));
  });

  test('timeMonth.round(date) handles midnight for leap years', () {
    expect(timeMonth.round(utc(2012, 2)), equals(local(2012, 2)));
    expect(timeMonth.round(utc(2012, 2)), equals(local(2012, 2)));
  });

  test('timeMonth.ceil(date) returns months (2)', () {
    expect(timeMonth.ceil(local(2010, 10, 30, 23)), equals(local(2010, 11)));
    expect(timeMonth.ceil(local(2010, 11, 1, 1)), equals(local(2011)));
    expect(timeMonth.ceil(local(2011, 1)), equals(local(2011, 1)));
    expect(timeMonth.ceil(local(2011, 2)), equals(local(2011, 2)));
    expect(timeMonth.ceil(local(2011, 3)), equals(local(2011, 3)));
  });

  test('timeMonth.ceil(date) observes daylight saving', () {
    expect(timeMonth.ceil(utc(2011, 2, 13, 7)), equals(local(2011, 3)));
    expect(timeMonth.ceil(utc(2011, 2, 13, 8)), equals(local(2011, 3)));
    expect(timeMonth.ceil(utc(2011, 2, 13, 9)), equals(local(2011, 3)));
    expect(timeMonth.ceil(utc(2011, 2, 13, 10)), equals(local(2011, 3)));
    expect(timeMonth.ceil(utc(2011, 10, 6, 7)), equals(local(2011, 11)));
    expect(timeMonth.ceil(utc(2011, 10, 6, 8)), equals(local(2011, 11)));
    expect(timeMonth.ceil(utc(2011, 10, 6, 9)), equals(local(2011, 11)));
    expect(timeMonth.ceil(utc(2011, 10, 6, 10)), equals(local(2011, 11)));
  });

  // DIVERGES(d3-time): platform-time-tz-tests, utc(2012, 2, 1, 0) is after
  // local midnight in positive UTC offsets (east of Greenwich).
  test('timeMonth.ceil(date) handles midnight for leap years', () {
    if (isAmericaLosAngeles) {
      expect(timeMonth.ceil(utc(2012, 2)), equals(local(2012, 2)));
      expect(timeMonth.ceil(utc(2012, 2)), equals(local(2012, 2)));
    } else {
      expect(timeMonth.ceil(local(2012, 2)), equals(local(2012, 2)));
      expect(timeMonth.ceil(local(2012, 1, 29, 23)), equals(local(2012, 2)));
    }
  });

  test('timeMonth.offset(date) is an alias for timeMonth.offset(date, 1)', () {
    expect(
      timeMonth.offset(local(2010, 11, 31, 23, 59, 59, 999)),
      equals(local(2011, 0, 31, 23, 59, 59, 999)),
    );
  });

  test('timeMonth.offset(date, step) does not modify the passed-in date', () {
    final d = local(2010, 11, 31, 23, 59, 59, 999);
    timeMonth.offset(d);
    expect(d, equals(local(2010, 11, 31, 23, 59, 59, 999)));
  });

  test('timeMonth.offset(date, step) does not round the passed-in date', () {
    expect(
      timeMonth.offset(local(2010, 11, 31, 23, 59, 59, 999)),
      equals(local(2011, 0, 31, 23, 59, 59, 999)),
    );
    expect(
      timeMonth.offset(local(2010, 11, 31, 23, 59, 59, 456), -2),
      equals(local(2010, 9, 31, 23, 59, 59, 456)),
    );
  });

  test('timeMonth.offset(date, step) allows step to be negative', () {
    expect(
      timeMonth.offset(local(2010, 11, 31), -1),
      equals(local(2010, 10, 31)),
    );
    expect(timeMonth.offset(local(2011), -2), equals(local(2010, 10)));
    expect(timeMonth.offset(local(2011), -1), equals(local(2010, 11)));
  });

  test('timeMonth.offset(date, step) allows step to be positive', () {
    expect(timeMonth.offset(local(2010, 11, 31)), equals(local(2011, 0, 31)));
    expect(
      timeMonth.offset(local(2010, 11, 30), 2),
      equals(local(2011, 1, 30)),
    );
    expect(timeMonth.offset(local(2010, 11, 30)), equals(local(2011, 0, 30)));
  });

  test('timeMonth.offset(date, step) allows step to be zero', () {
    expect(
      timeMonth.offset(local(2010, 11, 31, 23, 59, 59, 999), 0),
      equals(local(2010, 11, 31, 23, 59, 59, 999)),
    );
    expect(
      timeMonth.offset(local(2010, 11, 31, 23, 59, 58), 0),
      equals(local(2010, 11, 31, 23, 59, 58)),
    );
  });

  test('timeMonth.range(start, stop) returns months between start (inclusive) '
      'and stop (exclusive)', () {
    expect(
      timeMonth.range(local(2011, 11), local(2012, 5)),
      equals([
        local(2011, 11),
        local(2012),
        local(2012, 1),
        local(2012, 2),
        local(2012, 3),
        local(2012, 4),
      ]),
    );
  });

  test('timeMonth.range(start, stop) returns months', () {
    expect(
      timeMonth.range(local(2011, 10, 4, 2), local(2012, 4, 10, 13)),
      equals([
        local(2011, 11),
        local(2012),
        local(2012, 1),
        local(2012, 2),
        local(2012, 3),
        local(2012, 4),
      ]),
    );
  });

  test(
    'timeMonth.range(start, stop) coerces start and stop to dates',
    () {},
    skip: 'diverges: adapt-time-typed-api (range takes typed DateTime)',
  );

  test(
    'timeMonth.range(start, stop) returns the empty array for invalid dates',
    () {},
    skip: 'diverges: adapt-time-typed-api (Dart DateTime cannot hold NaN)',
  );

  test(
    'timeMonth.range(start, stop) returns the empty array if start >= stop',
    () {
      expect(timeMonth.range(local(2011, 11, 10), local(2011, 10, 4)), isEmpty);
      expect(timeMonth.range(local(2011, 10), local(2011, 10)), isEmpty);
    },
  );

  test('timeMonth.range(start, stop) returns months (2)', () {
    expect(
      timeMonth.range(local(2010, 10, 31), local(2011, 2)),
      equals([local(2010, 11), local(2011), local(2011, 1)]),
    );
  });

  test('timeMonth.range(start, stop) has an inclusive lower bound', () {
    expect(
      timeMonth.range(local(2010, 10, 31), local(2011, 2))[0],
      equals(local(2010, 11)),
    );
  });

  test('timeMonth.range(start, stop) has an exclusive upper bound', () {
    expect(
      timeMonth.range(local(2010, 10, 31), local(2011, 2))[2],
      equals(local(2011, 1)),
    );
  });

  test('timeMonth.range(start, stop) can skip months', () {
    expect(
      timeMonth.range(local(2011, 1), local(2012, 1), 3),
      equals([local(2011, 1), local(2011, 4), local(2011, 7), local(2011, 10)]),
    );
  });

  test(
    'timeMonth.range(start, stop) observes start of daylight savings time',
    () {
      expect(
        timeMonth.range(local(2011), local(2011, 4)),
        equals([local(2011), local(2011, 1), local(2011, 2), local(2011, 3)]),
      );
    },
  );

  test(
    'timeMonth.range(start, stop) observes end of daylight savings time',
    () {
      expect(
        timeMonth.range(local(2011, 9), local(2012, 1)),
        equals([local(2011, 9), local(2011, 10), local(2011, 11), local(2012)]),
      );
    },
  );

  test('timeMonth.count(start, end) counts months after start (exclusive) and '
      'before end (inclusive)', () {
    expect(timeMonth.count(local(2011), local(2011, 4)), 4);
    expect(timeMonth.count(local(2011), local(2011, 3, 30)), 3);
    expect(timeMonth.count(local(2010, 11, 31), local(2011, 3, 30)), 4);
    expect(timeMonth.count(local(2010, 11, 31), local(2011, 4)), 5);
    expect(timeMonth.count(local(2009, 11, 31), local(2012, 4)), 29);
    expect(timeMonth.count(local(2012, 4), local(2009, 11, 31)), -29);
  });

  test('timeMonth.every(step) returns every stepth month, starting with the '
      'first month of the year', () {
    expect(
      timeMonth.every(3)!.range(local(2008, 11, 3), local(2010, 6, 5)),
      equals([
        local(2009),
        local(2009, 3),
        local(2009, 6),
        local(2009, 9),
        local(2010),
        local(2010, 3),
        local(2010, 6),
      ]),
    );
  });
}
