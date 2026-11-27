// Ported from d3-time v3.1.0 test/utcMultiYear-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('utcYear.every(n).floor(date) returns integer multiples of n years', () {
    expect(
      utcYear.every(10)!.floor(utc(2009, 11, 31, 23, 59, 59)),
      equals(utc(2000)),
    );
    expect(utcYear.every(10)!.floor(utc(2010)), equals(utc(2010)));
    expect(
      utcYear.every(10)!.floor(utc(2010, 0, 1, 0, 0, 1)),
      equals(utc(2010)),
    );
  });

  test('utcYear.every(n).ceil(date) returns integer multiples of n years', () {
    expect(
      utcYear.every(100)!.ceil(utc(1999, 11, 31, 23, 59, 59)),
      equals(utc(2000)),
    );
    expect(utcYear.every(100)!.ceil(utc(2000)), equals(utc(2000)));
    expect(
      utcYear.every(100)!.ceil(utc(2000, 0, 1, 0, 0, 1)),
      equals(utc(2100)),
    );
  });

  test(
    'utcYear.every(n).offset(date, count) does not modify the passed-in date',
    () {
      final d = utc(2010, 11, 31, 23, 59, 59, 999);
      utcYear.every(5)!.offset(d);
      expect(d, equals(utc(2010, 11, 31, 23, 59, 59, 999)));
    },
  );

  test(
    'utcYear.every(n).offset(date, count) does not round the passed-in-date',
    () {
      expect(
        utcYear.every(5)!.offset(utc(2010, 11, 31, 23, 59, 59, 999)),
        equals(utc(2015, 11, 31, 23, 59, 59, 999)),
      );
      expect(
        utcYear.every(5)!.offset(utc(2010, 11, 31, 23, 59, 59, 456), -2),
        equals(utc(2000, 11, 31, 23, 59, 59, 456)),
      );
    },
  );

  test('utcYear.every(n) does not define interval.count or interval.every', () {
    final decade = utcYear.every(10)!;
    expect(decade, isNot(isA<CountableTimeInterval>()));
  });

  test('utcYear.every(n).range(start, stop) returns multiples of n years', () {
    expect(
      utcYear.every(10)!.range(utc(2010), utc(2031)),
      equals([utc(2010), utc(2020), utc(2030)]),
    );
  });
}
