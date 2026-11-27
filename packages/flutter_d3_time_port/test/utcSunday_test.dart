// Ported from d3-time v3.1.0 test/utcSunday-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('utcSundays in an alias for utcSunday.range', () {
    expect(utcSundays, equals(utcSunday.range));
  });

  test('utcSunday.floor(date) returns Sundays', () {
    expect(
      utcSunday.floor(utc(2010, 11, 31, 23, 59, 59)),
      equals(utc(2010, 11, 26)),
    );
    expect(utcSunday.floor(utc(2011)), equals(utc(2010, 11, 26)));
    expect(
      utcSunday.floor(utc(2011, 0, 1, 0, 0, 1)),
      equals(utc(2010, 11, 26)),
    );
    expect(
      utcSunday.floor(utc(2011, 0, 1, 23, 59, 59)),
      equals(utc(2010, 11, 26)),
    );
    expect(utcSunday.floor(utc(2011, 0, 2)), equals(utc(2011, 0, 2)));
    expect(utcSunday.floor(utc(2011, 0, 2, 0, 0, 1)), equals(utc(2011, 0, 2)));
  });

  test('utcSunday.floor(date) observes daylight saving', () {
    expect(utcSunday.floor(utc(2011, 2, 13, 1)), equals(utc(2011, 2, 13)));
    expect(utcSunday.floor(utc(2011, 10, 6, 1)), equals(utc(2011, 10, 6)));
  });

  test('utcSunday.floor(date) handles years in the first century', () {
    expect(utcSunday.floor(utc(9, 10, 6, 7)), equals(utc(9, 10)));
  });

  test('utcSunday.ceil(date) returns Sundays', () {
    expect(
      utcSunday.ceil(utc(2010, 11, 31, 23, 59, 59)),
      equals(utc(2011, 0, 2)),
    );
    expect(utcSunday.ceil(utc(2011)), equals(utc(2011, 0, 2)));
    expect(utcSunday.ceil(utc(2011, 0, 1, 0, 0, 1)), equals(utc(2011, 0, 2)));
    expect(
      utcSunday.ceil(utc(2011, 0, 1, 23, 59, 59)),
      equals(utc(2011, 0, 2)),
    );
    expect(utcSunday.ceil(utc(2011, 0, 2)), equals(utc(2011, 0, 2)));
    expect(utcSunday.ceil(utc(2011, 0, 2, 0, 0, 1)), equals(utc(2011, 0, 9)));
  });

  test('utcSunday.ceil(date) observes daylight saving', () {
    expect(utcSunday.ceil(utc(2011, 2, 13, 1)), equals(utc(2011, 2, 20)));
    expect(utcSunday.ceil(utc(2011, 10, 6, 1)), equals(utc(2011, 10, 13)));
  });

  test('utcSunday.offset(date) is an alias for utcSunday.offset(date, 1)', () {
    expect(
      utcSunday.offset(utc(2010, 11, 31, 23, 59, 59, 999)),
      equals(utc(2011, 0, 7, 23, 59, 59, 999)),
    );
  });

  test('utcSunday.offset(date, step) does not modify the passed-in date', () {
    final d = utc(2010, 11, 31, 23, 59, 59, 999);
    utcSunday.offset(d);
    expect(d, equals(utc(2010, 11, 31, 23, 59, 59, 999)));
  });

  test('utcSunday.offset(date, step) does not round the passed-in date', () {
    expect(
      utcSunday.offset(utc(2010, 11, 31, 23, 59, 59, 999)),
      equals(utc(2011, 0, 7, 23, 59, 59, 999)),
    );
    expect(
      utcSunday.offset(utc(2010, 11, 31, 23, 59, 59, 456), -2),
      equals(utc(2010, 11, 17, 23, 59, 59, 456)),
    );
  });

  test('utcSunday.offset(date, step) allows step to be negative', () {
    expect(utcSunday.offset(utc(2010, 11), -1), equals(utc(2010, 10, 24)));
    expect(utcSunday.offset(utc(2011), -2), equals(utc(2010, 11, 18)));
    expect(utcSunday.offset(utc(2011), -1), equals(utc(2010, 11, 25)));
  });

  test('utcSunday.offset(date, step) allows step to be positive', () {
    expect(utcSunday.offset(utc(2010, 10, 24)), equals(utc(2010, 11)));
    expect(utcSunday.offset(utc(2010, 11, 18), 2), equals(utc(2011)));
    expect(utcSunday.offset(utc(2010, 11, 25)), equals(utc(2011)));
  });

  test('utcSunday.offset(date, step) allows step to be zero', () {
    expect(
      utcSunday.offset(utc(2010, 11, 31, 23, 59, 59, 999), 0),
      equals(utc(2010, 11, 31, 23, 59, 59, 999)),
    );
    expect(
      utcSunday.offset(utc(2010, 11, 31, 23, 59, 58), 0),
      equals(utc(2010, 11, 31, 23, 59, 58)),
    );
  });

  test('utcSunday.range(start, stop) returns Sundays between start (inclusive) '
      'and stop (exclusive)', () {
    expect(
      utcSunday.range(utc(2011, 11), utc(2012, 0, 15)),
      equals([
        utc(2011, 11, 4),
        utc(2011, 11, 11),
        utc(2011, 11, 18),
        utc(2011, 11, 25),
        utc(2012),
        utc(2012, 0, 8),
      ]),
    );
  });

  test('utcSunday.range(start, stop) returns Sundays', () {
    expect(
      utcSunday.range(utc(2011, 11, 1, 12, 23), utc(2012, 0, 14, 12, 23)),
      equals([
        utc(2011, 11, 4),
        utc(2011, 11, 11),
        utc(2011, 11, 18),
        utc(2011, 11, 25),
        utc(2012),
        utc(2012, 0, 8),
      ]),
    );
  });

  test(
    'utcSunday.range(start, stop) coerces start and stop to dates',
    () {},
    skip: 'diverges: adapt-time-typed-api (range takes typed DateTime)',
  );

  test(
    'utcSunday.range(start, stop) returns the empty array for invalid dates',
    () {},
    skip: 'diverges: adapt-time-typed-api (Dart DateTime cannot hold NaN)',
  );

  test(
    'utcSunday.range(start, stop) returns the empty array if start >= stop',
    () {
      expect(utcSunday.range(utc(2011, 11, 10), utc(2011, 10, 4)), isEmpty);
      expect(utcSunday.range(utc(2011, 10), utc(2011, 10)), isEmpty);
    },
  );

  test('utcSunday.range(start, stop, step) returns every step Sunday', () {
    expect(
      utcSunday.range(utc(2011, 11), utc(2012, 0, 15), 2),
      equals([utc(2011, 11, 4), utc(2011, 11, 18), utc(2012)]),
    );
  });

  test('utcSunday.count(start, end) counts Sundays after start (exclusive) and '
      'before end (inclusive)', () {
    expect(utcSunday.count(utc(2014), utc(2014, 0, 4)), 0);
    expect(utcSunday.count(utc(2014), utc(2014, 0, 5)), 1);
    expect(utcSunday.count(utc(2014), utc(2014, 0, 6)), 1);
    expect(utcSunday.count(utc(2014), utc(2014, 0, 12)), 2);

    expect(utcSunday.count(utc(2012), utc(2012, 0, 7)), 0);
    expect(utcSunday.count(utc(2012), utc(2012, 0, 8)), 1);
    expect(utcSunday.count(utc(2012), utc(2012, 0, 9)), 1);
  });

  test('utcSunday.count(start, end) does not observe daylight saving', () {
    expect(utcSunday.count(utc(2011), utc(2011, 2, 13, 1)), 11);
    expect(utcSunday.count(utc(2011), utc(2011, 2, 13, 3)), 11);
    expect(utcSunday.count(utc(2011), utc(2011, 2, 13, 4)), 11);
    expect(utcSunday.count(utc(2011), utc(2011, 10, 6)), 45);
    expect(utcSunday.count(utc(2011), utc(2011, 10, 6, 1)), 45);
    expect(utcSunday.count(utc(2011), utc(2011, 10, 6, 2)), 45);
  });
}
