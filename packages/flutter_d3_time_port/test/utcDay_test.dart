// Ported from d3-time v3.1.0 test/utcDay-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('utcDays in an alias for utcDay.range', () {
    expect(utcDays, equals(utcDay.range));
  });

  test('utcDay.floor(date) returns days', () {
    expect(utcDay.floor(utc(2010, 11, 31, 23)), equals(utc(2010, 11, 31)));
    expect(utcDay.floor(utc(2011)), equals(utc(2011)));
    expect(utcDay.floor(utc(2011, 0, 1, 1)), equals(utc(2011)));
  });

  test('utcDay.floor(date) does not observe daylight saving', () {
    expect(utcDay.floor(utc(2011, 2, 13, 7)), equals(utc(2011, 2, 13)));
    expect(utcDay.floor(utc(2011, 2, 13, 8)), equals(utc(2011, 2, 13)));
    expect(utcDay.floor(utc(2011, 2, 13, 9)), equals(utc(2011, 2, 13)));
    expect(utcDay.floor(utc(2011, 2, 13, 10)), equals(utc(2011, 2, 13)));
    expect(utcDay.floor(utc(2011, 10, 6, 5)), equals(utc(2011, 10, 6)));
    expect(utcDay.floor(utc(2011, 10, 6, 6)), equals(utc(2011, 10, 6)));
    expect(utcDay.floor(utc(2011, 10, 6, 7)), equals(utc(2011, 10, 6)));
    expect(utcDay.floor(utc(2011, 10, 6, 8)), equals(utc(2011, 10, 6)));
  });

  test('utcDay.round(date) returns days', () {
    expect(utcDay.round(utc(2010, 11, 30, 13)), equals(utc(2010, 11, 31)));
    expect(utcDay.round(utc(2010, 11, 30, 11)), equals(utc(2010, 11, 30)));
  });

  test('utcDay.ceil(date) returns days', () {
    expect(utcDay.ceil(utc(2010, 11, 30, 23)), equals(utc(2010, 11, 31)));
    expect(utcDay.ceil(utc(2010, 11, 31)), equals(utc(2010, 11, 31)));
    expect(utcDay.ceil(utc(2010, 11, 31, 1)), equals(utc(2011)));
  });

  test('utcDay.ceil(date) does not observe daylight saving', () {
    expect(utcDay.ceil(utc(2011, 2, 13, 7)), equals(utc(2011, 2, 14)));
    expect(utcDay.ceil(utc(2011, 2, 13, 8)), equals(utc(2011, 2, 14)));
    expect(utcDay.ceil(utc(2011, 2, 13, 9)), equals(utc(2011, 2, 14)));
    expect(utcDay.ceil(utc(2011, 2, 13, 10)), equals(utc(2011, 2, 14)));
    expect(utcDay.ceil(utc(2011, 10, 6, 5)), equals(utc(2011, 10, 7)));
    expect(utcDay.ceil(utc(2011, 10, 6, 6)), equals(utc(2011, 10, 7)));
    expect(utcDay.ceil(utc(2011, 10, 6, 7)), equals(utc(2011, 10, 7)));
    expect(utcDay.ceil(utc(2011, 10, 6, 8)), equals(utc(2011, 10, 7)));
  });

  test('utcDay.offset(date) is an alias for utcDay.offset(date, 1)', () {
    expect(
      utcDay.offset(utc(2010, 11, 31, 23, 59, 59, 999)),
      equals(utc(2011, 0, 1, 23, 59, 59, 999)),
    );
  });

  test('utcDay.offset(date, step) does not modify the passed-in date', () {
    final d = utc(2010, 11, 31, 23, 59, 59, 999);
    utcDay.offset(d);
    expect(d, equals(utc(2010, 11, 31, 23, 59, 59, 999)));
  });

  test('utcDay.offset(date, step) does not round the passed-in date', () {
    expect(
      utcDay.offset(utc(2010, 11, 31, 23, 59, 59, 999)),
      equals(utc(2011, 0, 1, 23, 59, 59, 999)),
    );
    expect(
      utcDay.offset(utc(2010, 11, 31, 23, 59, 59, 456), -2),
      equals(utc(2010, 11, 29, 23, 59, 59, 456)),
    );
  });

  test('utcDay.offset(date, step) allows step to be negative', () {
    expect(utcDay.offset(utc(2010, 11, 31), -1), equals(utc(2010, 11, 30)));
    expect(utcDay.offset(utc(2011), -2), equals(utc(2010, 11, 30)));
    expect(utcDay.offset(utc(2011), -1), equals(utc(2010, 11, 31)));
  });

  test('utcDay.offset(date, step) allows step to be positive', () {
    expect(utcDay.offset(utc(2010, 11, 31)), equals(utc(2011)));
    expect(utcDay.offset(utc(2010, 11, 30), 2), equals(utc(2011)));
    expect(utcDay.offset(utc(2010, 11, 30)), equals(utc(2010, 11, 31)));
  });

  test('utcDay.offset(date, step) allows step to be zero', () {
    expect(
      utcDay.offset(utc(2010, 11, 31, 23, 59, 59, 999), 0),
      equals(utc(2010, 11, 31, 23, 59, 59, 999)),
    );
    expect(
      utcDay.offset(utc(2010, 11, 31, 23, 59, 58), 0),
      equals(utc(2010, 11, 31, 23, 59, 58)),
    );
  });

  test(
    'utcDay.count(start, end) counts days after start (exclusive) and before '
    'end (inclusive)',
    () {
      expect(utcDay.count(utc(2011), utc(2011, 4, 9)), 128);
      expect(utcDay.count(utc(2011, 0, 1, 1), utc(2011, 4, 9)), 128);
      expect(utcDay.count(utc(2010, 11, 31, 23), utc(2011, 4, 9)), 129);
      expect(utcDay.count(utc(2011), utc(2011, 4, 8, 23)), 127);
      expect(utcDay.count(utc(2011), utc(2011, 4, 9, 1)), 128);
    },
  );

  test('utcDay.count(start, end) does not observe daylight saving', () {
    expect(utcDay.count(utc(2011), utc(2011, 2, 13, 1)), 71);
    expect(utcDay.count(utc(2011), utc(2011, 2, 13, 3)), 71);
    expect(utcDay.count(utc(2011), utc(2011, 2, 13, 4)), 71);
    expect(utcDay.count(utc(2011), utc(2011, 10, 6)), 309);
    expect(utcDay.count(utc(2011), utc(2011, 10, 6, 1)), 309);
    expect(utcDay.count(utc(2011), utc(2011, 10, 6, 2)), 309);
  });

  test('utcDay.count(start, end) returns 364 or 365 for a full year', () {
    expect(utcDay.count(utc(1999), utc(1999, 11, 31)), 364);
    expect(utcDay.count(utc(2000), utc(2000, 11, 31)), 365);
    expect(utcDay.count(utc(2001), utc(2001, 11, 31)), 364);
    expect(utcDay.count(utc(2002), utc(2002, 11, 31)), 364);
    expect(utcDay.count(utc(2003), utc(2003, 11, 31)), 364);
    expect(utcDay.count(utc(2004), utc(2004, 11, 31)), 365);
    expect(utcDay.count(utc(2005), utc(2005, 11, 31)), 364);
    expect(utcDay.count(utc(2006), utc(2006, 11, 31)), 364);
    expect(utcDay.count(utc(2007), utc(2007, 11, 31)), 364);
    expect(utcDay.count(utc(2008), utc(2008, 11, 31)), 365);
    expect(utcDay.count(utc(2009), utc(2009, 11, 31)), 364);
    expect(utcDay.count(utc(2010), utc(2010, 11, 31)), 364);
    expect(utcDay.count(utc(2011), utc(2011, 11, 31)), 364);
  });

  test('utcDay.every(step) returns every stepth day, starting with the first '
      'day of the month', () {
    expect(
      utcDay.every(3)!.range(utc(2008, 11, 30, 0, 12), utc(2009, 0, 5, 23, 48)),
      equals([utc(2008, 11, 31), utc(2009), utc(2009, 0, 4)]),
    );
    expect(
      utcDay.every(5)!.range(utc(2008, 11, 30, 0, 12), utc(2009, 0, 6, 23, 48)),
      equals([utc(2008, 11, 31), utc(2009), utc(2009, 0, 6)]),
    );
    expect(
      utcDay.every(7)!.range(utc(2008, 11, 30, 0, 12), utc(2009, 0, 8, 23, 48)),
      equals([utc(2009), utc(2009, 0, 8)]),
    );
  });
}
