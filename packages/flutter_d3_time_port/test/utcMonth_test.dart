// Ported from d3-time v3.1.0 test/utcMonth-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('utcMonths in an alias for utcMonth.range', () {
    expect(utcMonths, equals(utcMonth.range));
  });

  test('utcMonth.floor(date) returns months', () {
    expect(utcMonth.floor(utc(2010, 11, 31, 23)), equals(utc(2010, 11)));
    expect(utcMonth.floor(utc(2011)), equals(utc(2011)));
    expect(utcMonth.floor(utc(2011, 0, 1, 1)), equals(utc(2011)));
  });

  test('utcMonth.floor(date) observes daylight saving', () {
    expect(utcMonth.floor(utc(2011, 2, 13, 7)), equals(utc(2011, 2)));
    expect(utcMonth.floor(utc(2011, 2, 13, 8)), equals(utc(2011, 2)));
    expect(utcMonth.floor(utc(2011, 2, 13, 9)), equals(utc(2011, 2)));
    expect(utcMonth.floor(utc(2011, 2, 13, 10)), equals(utc(2011, 2)));
    expect(utcMonth.floor(utc(2011, 10, 6, 7)), equals(utc(2011, 10)));
    expect(utcMonth.floor(utc(2011, 10, 6, 8)), equals(utc(2011, 10)));
    expect(utcMonth.floor(utc(2011, 10, 6, 9)), equals(utc(2011, 10)));
    expect(utcMonth.floor(utc(2011, 10, 6, 10)), equals(utc(2011, 10)));
  });

  test('utcMonth.floor(date) handles years in the first century', () {
    expect(utcMonth.floor(utc(9, 10, 6, 7)), equals(utc(9, 10)));
  });

  test('utcMonth.round(date) returns months', () {
    expect(utcMonth.round(utc(2010, 11, 16, 12)), equals(utc(2011)));
    expect(utcMonth.round(utc(2010, 11, 16, 11)), equals(utc(2010, 11)));
  });

  test('utcMonth.round(date) observes daylight saving', () {
    expect(utcMonth.round(utc(2011, 2, 13, 7)), equals(utc(2011, 2)));
    expect(utcMonth.round(utc(2011, 2, 13, 8)), equals(utc(2011, 2)));
    expect(utcMonth.round(utc(2011, 2, 13, 9)), equals(utc(2011, 2)));
    expect(utcMonth.round(utc(2011, 2, 13, 20)), equals(utc(2011, 2)));
    expect(utcMonth.round(utc(2011, 10, 6, 7)), equals(utc(2011, 10)));
    expect(utcMonth.round(utc(2011, 10, 6, 8)), equals(utc(2011, 10)));
    expect(utcMonth.round(utc(2011, 10, 6, 9)), equals(utc(2011, 10)));
    expect(utcMonth.round(utc(2011, 10, 6, 20)), equals(utc(2011, 10)));
  });

  test('utcMonth.round(date) handles midnight for leap years', () {
    expect(utcMonth.round(utc(2012, 2)), equals(utc(2012, 2)));
    expect(utcMonth.round(utc(2012, 2)), equals(utc(2012, 2)));
  });

  test('utcMonth.ceil(date) returns months', () {
    expect(utcMonth.ceil(utc(2010, 10, 30, 23)), equals(utc(2010, 11)));
    expect(utcMonth.ceil(utc(2010, 11, 1, 1)), equals(utc(2011)));
  });

  test('utcMonth.ceil(date) observes daylight saving', () {
    expect(utcMonth.ceil(utc(2011, 2, 13, 7)), equals(utc(2011, 3)));
    expect(utcMonth.ceil(utc(2011, 2, 13, 8)), equals(utc(2011, 3)));
    expect(utcMonth.ceil(utc(2011, 2, 13, 9)), equals(utc(2011, 3)));
    expect(utcMonth.ceil(utc(2011, 2, 13, 10)), equals(utc(2011, 3)));
    expect(utcMonth.ceil(utc(2011, 10, 6, 7)), equals(utc(2011, 11)));
    expect(utcMonth.ceil(utc(2011, 10, 6, 8)), equals(utc(2011, 11)));
    expect(utcMonth.ceil(utc(2011, 10, 6, 9)), equals(utc(2011, 11)));
    expect(utcMonth.ceil(utc(2011, 10, 6, 10)), equals(utc(2011, 11)));
  });

  test('utcMonth.ceil(date) handles midnight for leap years', () {
    expect(utcMonth.ceil(utc(2012, 2)), equals(utc(2012, 2)));
    expect(utcMonth.ceil(utc(2012, 2)), equals(utc(2012, 2)));
  });

  test('utcMonth.offset(date) is an alias for utcMonth.offset(date, 1)', () {
    expect(
      utcMonth.offset(utc(2010, 11, 31, 23, 59, 59, 999)),
      equals(utc(2011, 0, 31, 23, 59, 59, 999)),
    );
  });

  test('utcMonth.offset(date, step) does not modify the passed-in date', () {
    final d = utc(2010, 11, 31, 23, 59, 59, 999);
    utcMonth.offset(d);
    expect(d, equals(utc(2010, 11, 31, 23, 59, 59, 999)));
  });

  test('utcMonth.offset(date, step) does not round the passed-in date', () {
    expect(
      utcMonth.offset(utc(2010, 11, 31, 23, 59, 59, 999)),
      equals(utc(2011, 0, 31, 23, 59, 59, 999)),
    );
    expect(
      utcMonth.offset(utc(2010, 11, 31, 23, 59, 59, 456), -2),
      equals(utc(2010, 9, 31, 23, 59, 59, 456)),
    );
  });

  test('utcMonth.offset(date, step) allows step to be negative', () {
    expect(utcMonth.offset(utc(2010, 11, 31), -1), equals(utc(2010, 10, 31)));
    expect(utcMonth.offset(utc(2011), -2), equals(utc(2010, 10)));
    expect(utcMonth.offset(utc(2011), -1), equals(utc(2010, 11)));
  });

  test('utcMonth.offset(date, step) allows step to be positive', () {
    expect(utcMonth.offset(utc(2010, 11, 31)), equals(utc(2011, 0, 31)));
    expect(utcMonth.offset(utc(2010, 11, 30), 2), equals(utc(2011, 1, 30)));
    expect(utcMonth.offset(utc(2010, 11, 30)), equals(utc(2011, 0, 30)));
  });

  test('utcMonth.offset(date, step) allows step to be zero', () {
    expect(
      utcMonth.offset(utc(2010, 11, 31, 23, 59, 59, 999), 0),
      equals(utc(2010, 11, 31, 23, 59, 59, 999)),
    );
    expect(
      utcMonth.offset(utc(2010, 11, 31, 23, 59, 58), 0),
      equals(utc(2010, 11, 31, 23, 59, 58)),
    );
  });

  test(
    'utcMonth.range(start, stop) returns months between start (inclusive) and '
    'stop (exclusive)',
    () {
      expect(
        utcMonth.range(utc(2011, 11), utc(2012, 5)),
        equals([
          utc(2011, 11),
          utc(2012),
          utc(2012, 1),
          utc(2012, 2),
          utc(2012, 3),
          utc(2012, 4),
        ]),
      );
    },
  );

  test('utcMonth.range(start, stop) returns months', () {
    expect(
      utcMonth.range(utc(2011, 10, 4, 2), utc(2012, 4, 10, 13)),
      equals([
        utc(2011, 11),
        utc(2012),
        utc(2012, 1),
        utc(2012, 2),
        utc(2012, 3),
        utc(2012, 4),
      ]),
    );
  });

  test(
    'utcMonth.range(start, stop) coerces start and stop to dates',
    () {},
    skip: 'diverges: adapt-time-typed-api (range takes typed DateTime)',
  );

  test(
    'utcMonth.range(start, stop) returns the empty array for invalid dates',
    () {},
    skip: 'diverges: adapt-time-typed-api (Dart DateTime cannot hold NaN)',
  );

  test(
    'utcMonth.range(start, stop) returns the empty array if start >= stop',
    () {
      expect(utcMonth.range(utc(2011, 11, 10), utc(2011, 10, 4)), isEmpty);
      expect(utcMonth.range(utc(2011, 10), utc(2011, 10)), isEmpty);
    },
  );

  test('utcMonth.range(start, stop) returns months (2)', () {
    expect(
      utcMonth.range(utc(2010, 10, 31), utc(2011, 2)),
      equals([utc(2010, 11), utc(2011), utc(2011, 1)]),
    );
  });

  test('utcMonth.range(start, stop) has an inclusive lower bound', () {
    expect(
      utcMonth.range(utc(2010, 10, 31), utc(2011, 2))[0],
      equals(utc(2010, 11)),
    );
  });

  test('utcMonth.range(start, stop) has an exclusive upper bound', () {
    expect(
      utcMonth.range(utc(2010, 10, 31), utc(2011, 2))[2],
      equals(utc(2011, 1)),
    );
  });

  test('utcMonth.range(start, stop) can skip months', () {
    expect(
      utcMonth.range(utc(2011, 1), utc(2012, 1), 3),
      equals([utc(2011, 1), utc(2011, 4), utc(2011, 7), utc(2011, 10)]),
    );
  });

  test(
    'utcMonth.range(start, stop) observes start of daylight savings time',
    () {
      expect(
        utcMonth.range(utc(2011), utc(2011, 4)),
        equals([utc(2011), utc(2011, 1), utc(2011, 2), utc(2011, 3)]),
      );
    },
  );

  test('utcMonth.range(start, stop) observes end of daylight savings time', () {
    expect(
      utcMonth.range(utc(2011, 9), utc(2012, 1)),
      equals([utc(2011, 9), utc(2011, 10), utc(2011, 11), utc(2012)]),
    );
  });

  test('utcMonth.count(start, end) counts months after start (exclusive) and '
      'before end (inclusive)', () {
    expect(utcMonth.count(utc(2011), utc(2011, 4)), 4);
    expect(utcMonth.count(utc(2011), utc(2011, 3, 30)), 3);
    expect(utcMonth.count(utc(2010, 11, 31), utc(2011, 3, 30)), 4);
    expect(utcMonth.count(utc(2010, 11, 31), utc(2011, 4)), 5);
    expect(utcMonth.count(utc(2009, 11, 31), utc(2012, 4)), 29);
    expect(utcMonth.count(utc(2012, 4), utc(2009, 11, 31)), -29);
  });

  test(
    'utcMonth.every(step) returns every stepth month, starting with the first '
    'month of the year',
    () {
      expect(
        utcMonth.every(3)!.range(utc(2008, 11, 3), utc(2010, 6, 5)),
        equals([
          utc(2009),
          utc(2009, 3),
          utc(2009, 6),
          utc(2009, 9),
          utc(2010),
          utc(2010, 3),
          utc(2010, 6),
        ]),
      );
    },
  );
}
