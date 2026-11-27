// Ported from d3-time v3.1.0 test/year-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('timeYear.floor(date) returns years', () {
    expect(
      timeYear.floor(local(2010, 11, 31, 23, 59, 59)),
      equals(local(2010)),
    );
    expect(timeYear.floor(local(2011)), equals(local(2011)));
    expect(timeYear.floor(local(2011, 0, 1, 0, 0, 1)), equals(local(2011)));
  });

  test('timeYear.floor(date) does not modify the specified date', () {
    final d = local(2010, 11, 31, 23, 59, 59);
    expect(timeYear.floor(d), equals(local(2010)));
    expect(d, equals(local(2010, 11, 31, 23, 59, 59)));
  });

  test('timeYear.floor(date) correctly handles years in the first century', () {
    expect(timeYear.floor(local(9, 10, 6, 7)), equals(local(9)));
  });

  test('timeYear.ceil(date) returns years', () {
    expect(timeYear.ceil(local(2010, 11, 31, 23, 59, 59)), equals(local(2011)));
    expect(timeYear.ceil(local(2011)), equals(local(2011)));
    expect(timeYear.ceil(local(2011, 0, 1, 0, 0, 1)), equals(local(2012)));
  });

  test('timeYear.offset(date, count) does not modify the passed-in date', () {
    final d = local(2010, 11, 31, 23, 59, 59, 999);
    timeYear.offset(d);
    expect(d, equals(local(2010, 11, 31, 23, 59, 59, 999)));
  });

  test('timeYear.offset(date, count) does not round the passed-in-date', () {
    expect(
      timeYear.offset(local(2010, 11, 31, 23, 59, 59, 999)),
      equals(local(2011, 11, 31, 23, 59, 59, 999)),
    );
    expect(
      timeYear.offset(local(2010, 11, 31, 23, 59, 59, 456), -2),
      equals(local(2008, 11, 31, 23, 59, 59, 456)),
    );
  });

  test('timeYear.offset(date, count) allows negative offsets', () {
    expect(timeYear.offset(local(2010, 11), -1), equals(local(2009, 11)));
    expect(timeYear.offset(local(2011), -2), equals(local(2009)));
    expect(timeYear.offset(local(2011), -1), equals(local(2010)));
  });

  test('timeYear.offset(date, count) allows positive offsets', () {
    expect(timeYear.offset(local(2009, 11)), equals(local(2010, 11)));
    expect(timeYear.offset(local(2009), 2), equals(local(2011)));
    expect(timeYear.offset(local(2010)), equals(local(2011)));
  });

  test('timeYear.offset(date, count) allows zero offset', () {
    expect(
      timeYear.offset(local(2010, 11, 31, 23, 59, 59, 999), 0),
      equals(local(2010, 11, 31, 23, 59, 59, 999)),
    );
    expect(
      timeYear.offset(local(2010, 11, 31, 23, 59, 58), 0),
      equals(local(2010, 11, 31, 23, 59, 58)),
    );
  });

  test(
    'timeYear.every(step) returns every stepth year, starting with year zero',
    () {
      expect(
        timeYear.every(5)!.range(local(2008), local(2023)),
        equals([local(2010), local(2015), local(2020)]),
      );
    },
  );

  test('timeYear.range(start, stop) returns years', () {
    expect(
      timeYear.range(local(2010), local(2013)),
      equals([local(2010), local(2011), local(2012)]),
    );
  });

  test('timeYear.range(start, stop) has an inclusive lower bound', () {
    expect(timeYear.range(local(2010), local(2013))[0], equals(local(2010)));
  });

  test('timeYear.range(start, stop) has an exclusive upper bound', () {
    expect(timeYear.range(local(2010), local(2013))[2], equals(local(2012)));
  });

  test('timeYear.range(start, stop, step) can skip years', () {
    expect(
      timeYear.range(local(2009), local(2029), 5),
      equals([local(2009), local(2014), local(2019), local(2024)]),
    );
  });
}
