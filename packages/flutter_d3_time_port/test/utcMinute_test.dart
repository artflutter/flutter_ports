// Ported from d3-time v3.1.0 test/utcMinute-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('utcMinute.floor(date) returns minutes', () {
    expect(
      utcMinute.floor(utc(2010, 11, 31, 23, 59, 59)),
      equals(utc(2010, 11, 31, 23, 59)),
    );
    expect(utcMinute.floor(utc(2011)), equals(utc(2011)));
    expect(utcMinute.floor(utc(2011, 0, 1, 0, 0, 59)), equals(utc(2011)));
    expect(
      utcMinute.floor(utc(2011, 0, 1, 0, 1)),
      equals(utc(2011, 0, 1, 0, 1)),
    );
  });

  test('utcMinute.ceil(date) returns minutes', () {
    expect(utcMinute.ceil(utc(2010, 11, 31, 23, 59, 59)), equals(utc(2011)));
    expect(utcMinute.ceil(utc(2011)), equals(utc(2011)));
    expect(
      utcMinute.ceil(utc(2011, 0, 1, 0, 0, 59)),
      equals(utc(2011, 0, 1, 0, 1)),
    );
    expect(
      utcMinute.ceil(utc(2011, 0, 1, 0, 1)),
      equals(utc(2011, 0, 1, 0, 1)),
    );
  });

  test('utcMinute.offset(date) does not modify the passed-in date', () {
    final d = utc(2010, 11, 31, 23, 59, 59, 999);
    utcMinute.offset(d);
    expect(d, equals(utc(2010, 11, 31, 23, 59, 59, 999)));
  });

  test('utcMinute.offset(date) does not round the passed-in-date', () {
    expect(
      utcMinute.offset(utc(2010, 11, 31, 23, 59, 59, 999)),
      equals(utc(2011, 0, 1, 0, 0, 59, 999)),
    );
    expect(
      utcMinute.offset(utc(2010, 11, 31, 23, 59, 59, 456), -2),
      equals(utc(2010, 11, 31, 23, 57, 59, 456)),
    );
  });

  test('utcMinute.offset(date) allows negative offsets', () {
    expect(
      utcMinute.offset(utc(2010, 11, 31, 23, 12), -1),
      equals(utc(2010, 11, 31, 23, 11)),
    );
    expect(
      utcMinute.offset(utc(2011, 0, 1, 0, 1), -2),
      equals(utc(2010, 11, 31, 23, 59)),
    );
    expect(utcMinute.offset(utc(2011), -1), equals(utc(2010, 11, 31, 23, 59)));
  });

  test('utcMinute.offset(date) allows positive offsets', () {
    expect(
      utcMinute.offset(utc(2010, 11, 31, 23, 11)),
      equals(utc(2010, 11, 31, 23, 12)),
    );
    expect(
      utcMinute.offset(utc(2010, 11, 31, 23, 59), 2),
      equals(utc(2011, 0, 1, 0, 1)),
    );
    expect(utcMinute.offset(utc(2010, 11, 31, 23, 59)), equals(utc(2011)));
  });

  test('utcMinute.offset(date) allows zero offset', () {
    expect(
      utcMinute.offset(utc(2010, 11, 31, 23, 59, 59, 999), 0),
      equals(utc(2010, 11, 31, 23, 59, 59, 999)),
    );
    expect(
      utcMinute.offset(utc(2010, 11, 31, 23, 59, 58), 0),
      equals(utc(2010, 11, 31, 23, 59, 58)),
    );
  });

  test('utcMinute.range(start, stop), returns minutes', () {
    expect(
      utcMinute.range(utc(2010, 11, 31, 23, 59), utc(2011, 0, 1, 0, 2)),
      equals([utc(2010, 11, 31, 23, 59), utc(2011), utc(2011, 0, 1, 0, 1)]),
    );
  });

  test('utcMinute.range(start, stop), has an inclusive lower bound', () {
    expect(
      utcMinute.range(utc(2010, 11, 31, 23, 59), utc(2011, 0, 1, 0, 2))[0],
      equals(utc(2010, 11, 31, 23, 59)),
    );
  });

  test('utcMinute.range(start, stop), has an exclusive upper bound', () {
    expect(
      utcMinute.range(utc(2010, 11, 31, 23, 59), utc(2011, 0, 1, 0, 2))[2],
      equals(utc(2011, 0, 1, 0, 1)),
    );
  });

  test('utcMinute.range(start, stop), can skip minutes', () {
    expect(
      utcMinute.range(utc(2011, 1, 1, 12, 7), utc(2011, 1, 1, 13, 7), 15),
      equals([
        utc(2011, 1, 1, 12, 7),
        utc(2011, 1, 1, 12, 22),
        utc(2011, 1, 1, 12, 37),
        utc(2011, 1, 1, 12, 52),
      ]),
    );
  });

  test(
    'utcMinute.range(start, stop), observes start of daylight savings time',
    () {
      expect(
        utcMinute.range(utc(2011, 2, 13, 9, 59), utc(2011, 2, 13, 10, 2)),
        equals([
          utc(2011, 2, 13, 9, 59),
          utc(2011, 2, 13, 10),
          utc(2011, 2, 13, 10, 1),
        ]),
      );
    },
  );

  test(
    'utcMinute.range(start, stop), observes end of daylight savings time',
    () {
      expect(
        utcMinute.range(utc(2011, 10, 6, 8, 59), utc(2011, 10, 6, 9, 2)),
        equals([
          utc(2011, 10, 6, 8, 59),
          utc(2011, 10, 6, 9),
          utc(2011, 10, 6, 9, 1),
        ]),
      );
    },
  );

  test('utcMinute.every(step) returns every stepth minute, starting with the '
      'first minute of the hour', () {
    expect(
      utcMinute
          .every(15)!
          .range(utc(2008, 11, 30, 12, 47), utc(2008, 11, 30, 13, 57)),
      equals([
        utc(2008, 11, 30, 13),
        utc(2008, 11, 30, 13, 15),
        utc(2008, 11, 30, 13, 30),
        utc(2008, 11, 30, 13, 45),
      ]),
    );
    expect(
      utcMinute
          .every(30)!
          .range(utc(2008, 11, 30, 12, 47), utc(2008, 11, 30, 13, 57)),
      equals([utc(2008, 11, 30, 13), utc(2008, 11, 30, 13, 30)]),
    );
  });
}
