// Ported from d3-time v3.1.0 test/multiYear-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test(
    'timeYear.every(n).floor(date) returns integer multiples of n years',
    () {
      expect(
        timeYear.every(10)!.floor(local(2009, 11, 31, 23, 59, 59)),
        equals(local(2000)),
      );
      expect(timeYear.every(10)!.floor(local(2010)), equals(local(2010)));
      expect(
        timeYear.every(10)!.floor(local(2010, 0, 1, 0, 0, 1)),
        equals(local(2010)),
      );
    },
  );

  test('timeYear.every(n).ceil(date) returns integer multiples of n years', () {
    expect(
      timeYear.every(100)!.ceil(local(1999, 11, 31, 23, 59, 59)),
      equals(local(2000)),
    );
    expect(timeYear.every(100)!.ceil(local(2000)), equals(local(2000)));
    expect(
      timeYear.every(100)!.ceil(local(2000, 0, 1, 0, 0, 1)),
      equals(local(2100)),
    );
  });

  test(
    'timeYear.every(n).offset(date, count) does not modify the passed-in date',
    () {
      final d = local(2010, 11, 31, 23, 59, 59, 999);
      timeYear.every(5)!.offset(d);
      expect(d, equals(local(2010, 11, 31, 23, 59, 59, 999)));
    },
  );

  test(
    'timeYear.every(n).offset(date, count) does not round the passed-in-date',
    () {
      expect(
        timeYear.every(5)!.offset(local(2010, 11, 31, 23, 59, 59, 999)),
        equals(local(2015, 11, 31, 23, 59, 59, 999)),
      );
      expect(
        timeYear.every(5)!.offset(local(2010, 11, 31, 23, 59, 59, 456), -2),
        equals(local(2000, 11, 31, 23, 59, 59, 456)),
      );
    },
  );

  test(
    'timeYear.every(n) does not define interval.count or interval.every',
    () {
      final decade = timeYear.every(10)!;
      expect(decade, isNot(isA<CountableTimeInterval>()));
    },
  );

  test('timeYear.every(n).range(start, stop) returns multiples of n years', () {
    expect(
      timeYear.every(10)!.range(local(2010), local(2031)),
      equals([local(2010), local(2020), local(2030)]),
    );
  });
}
