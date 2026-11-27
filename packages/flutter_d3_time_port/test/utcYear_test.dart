// Ported from d3-time v3.1.0 test/utcYear-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('utcYear.floor(date) returns years', () {
    expect(utcYear.floor(utc(2010, 11, 31, 23, 59, 59)), equals(utc(2010)));
    expect(utcYear.floor(utc(2011)), equals(utc(2011)));
    expect(utcYear.floor(utc(2011, 0, 1, 0, 0, 1)), equals(utc(2011)));
  });

  test('utcYear.floor(date) does not modify the specified date', () {
    final d = utc(2010, 11, 31, 23, 59, 59);
    expect(utcYear.floor(d), equals(utc(2010)));
    expect(d, equals(utc(2010, 11, 31, 23, 59, 59)));
  });

  test('utcYear.floor(date) correctly handles years in the first century', () {
    expect(utcYear.floor(utc(9, 10, 6, 7)), equals(utc(9)));
  });

  test('utcYear.ceil(date) returns years', () {
    expect(utcYear.ceil(utc(2010, 11, 31, 23, 59, 59)), equals(utc(2011)));
    expect(utcYear.ceil(utc(2011)), equals(utc(2011)));
    expect(utcYear.ceil(utc(2011, 0, 1, 0, 0, 1)), equals(utc(2012)));
  });

  test('utcYear.offset(date, count) does not modify the passed-in date', () {
    final d = utc(2010, 11, 31, 23, 59, 59, 999);
    utcYear.offset(d);
    expect(d, equals(utc(2010, 11, 31, 23, 59, 59, 999)));
  });

  test('utcYear.offset(date, count) does not round the passed-in-date', () {
    expect(
      utcYear.offset(utc(2010, 11, 31, 23, 59, 59, 999)),
      equals(utc(2011, 11, 31, 23, 59, 59, 999)),
    );
    expect(
      utcYear.offset(utc(2010, 11, 31, 23, 59, 59, 456), -2),
      equals(utc(2008, 11, 31, 23, 59, 59, 456)),
    );
  });

  test('utcYear.offset(date, count) allows negative offsets', () {
    expect(utcYear.offset(utc(2010, 11), -1), equals(utc(2009, 11)));
    expect(utcYear.offset(utc(2011), -2), equals(utc(2009)));
    expect(utcYear.offset(utc(2011), -1), equals(utc(2010)));
  });

  test('utcYear.offset(date, count) allows positive offsets', () {
    expect(utcYear.offset(utc(2009, 11)), equals(utc(2010, 11)));
    expect(utcYear.offset(utc(2009), 2), equals(utc(2011)));
    expect(utcYear.offset(utc(2010)), equals(utc(2011)));
  });

  test('utcYear.offset(date, count) allows zero offset', () {
    expect(
      utcYear.offset(utc(2010, 11, 31, 23, 59, 59, 999), 0),
      equals(utc(2010, 11, 31, 23, 59, 59, 999)),
    );
    expect(
      utcYear.offset(utc(2010, 11, 31, 23, 59, 58), 0),
      equals(utc(2010, 11, 31, 23, 59, 58)),
    );
  });

  test(
    'utcYear.every(step) returns every stepth year, starting with year zero',
    () {
      expect(
        utcYear.every(5)!.range(utc(2008), utc(2023)),
        equals([utc(2010), utc(2015), utc(2020)]),
      );
    },
  );

  test('utcYear.range(start, stop) returns years', () {
    expect(
      utcYear.range(utc(2010), utc(2013)),
      equals([utc(2010), utc(2011), utc(2012)]),
    );
  });

  test('utcYear.range(start, stop) has an inclusive lower bound', () {
    expect(utcYear.range(utc(2010), utc(2013))[0], equals(utc(2010)));
  });

  test('utcYear.range(start, stop) has an exclusive upper bound', () {
    expect(utcYear.range(utc(2010), utc(2013))[2], equals(utc(2012)));
  });

  test('utcYear.range(start, stop, step) can skip years', () {
    expect(
      utcYear.range(utc(2009), utc(2029), 5),
      equals([utc(2009), utc(2014), utc(2019), utc(2024)]),
    );
  });
}
