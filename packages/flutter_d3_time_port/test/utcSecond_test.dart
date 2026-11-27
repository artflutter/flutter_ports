// Ported from d3-time v3.1.0 test/utcSecond-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('utcSecond.floor(date) returns seconds', () {
    expect(
      utcSecond.floor(utc(2010, 11, 31, 23, 59, 59, 999)),
      equals(utc(2010, 11, 31, 23, 59, 59)),
    );
    expect(utcSecond.floor(utc(2011)), equals(utc(2011)));
    expect(utcSecond.floor(utc(2011, 0, 1, 0, 0, 0, 1)), equals(utc(2011)));
  });

  test('utcSecond.round(date) returns seconds', () {
    expect(
      utcSecond.round(utc(2010, 11, 31, 23, 59, 59, 999)),
      equals(utc(2011)),
    );
    expect(utcSecond.round(utc(2011, 0, 1, 0, 0, 0, 499)), equals(utc(2011)));
    expect(
      utcSecond.round(utc(2011, 0, 1, 0, 0, 0, 500)),
      equals(utc(2011, 0, 1, 0, 0, 1)),
    );
  });

  test('utcSecond.ceil(date) returns seconds', () {
    expect(
      utcSecond.ceil(utc(2010, 11, 31, 23, 59, 59, 999)),
      equals(utc(2011)),
    );
    expect(utcSecond.ceil(utc(2011)), equals(utc(2011)));
    expect(
      utcSecond.ceil(utc(2011, 0, 1, 0, 0, 0, 1)),
      equals(utc(2011, 0, 1, 0, 0, 1)),
    );
  });

  test('utcSecond.offset(date, step) does not modify the passed-in date', () {
    final d = utc(2010, 11, 31, 23, 59, 59, 999);
    utcSecond.offset(d);
    expect(d, equals(utc(2010, 11, 31, 23, 59, 59, 999)));
  });

  test('utcSecond.offset(date, step) does not round the passed-in-date', () {
    expect(
      utcSecond.offset(utc(2010, 11, 31, 23, 59, 59, 999)),
      equals(utc(2011, 0, 1, 0, 0, 0, 999)),
    );
    expect(
      utcSecond.offset(utc(2010, 11, 31, 23, 59, 59, 456), -2),
      equals(utc(2010, 11, 31, 23, 59, 57, 456)),
    );
  });

  test('utcSecond.offset(date, step) allows negative offsets', () {
    expect(
      utcSecond.offset(utc(2010, 11, 31, 23, 59, 59), -1),
      equals(utc(2010, 11, 31, 23, 59, 58)),
    );
    expect(
      utcSecond.offset(utc(2011), -2),
      equals(utc(2010, 11, 31, 23, 59, 58)),
    );
    expect(
      utcSecond.offset(utc(2011), -1),
      equals(utc(2010, 11, 31, 23, 59, 59)),
    );
  });

  test('utcSecond.offset(date, step) allows positive offsets', () {
    expect(
      utcSecond.offset(utc(2010, 11, 31, 23, 59, 58)),
      equals(utc(2010, 11, 31, 23, 59, 59)),
    );
    expect(
      utcSecond.offset(utc(2010, 11, 31, 23, 59, 58), 2),
      equals(utc(2011)),
    );
    expect(utcSecond.offset(utc(2010, 11, 31, 23, 59, 59)), equals(utc(2011)));
  });

  test('utcSecond.offset(date, step) allows zero offset', () {
    expect(
      utcSecond.offset(utc(2010, 11, 31, 23, 59, 59, 999), 0),
      equals(utc(2010, 11, 31, 23, 59, 59, 999)),
    );
    expect(
      utcSecond.offset(utc(2010, 11, 31, 23, 59, 58), 0),
      equals(utc(2010, 11, 31, 23, 59, 58)),
    );
  });

  test('utcSecond.range(start, stop) returns seconds', () {
    expect(
      utcSecond.range(utc(2010, 11, 31, 23, 59, 59), utc(2011, 0, 1, 0, 0, 2)),
      equals([
        utc(2010, 11, 31, 23, 59, 59),
        utc(2011),
        utc(2011, 0, 1, 0, 0, 1),
      ]),
    );
  });

  test('utcSecond.range(start, stop) has an inclusive lower bound', () {
    expect(
      utcSecond.range(
        utc(2010, 11, 31, 23, 59, 59),
        utc(2011, 0, 1, 0, 0, 2),
      )[0],
      equals(utc(2010, 11, 31, 23, 59, 59)),
    );
  });

  test('utcSecond.range(start, stop) has an exclusive upper bound', () {
    expect(
      utcSecond.range(
        utc(2010, 11, 31, 23, 59, 59),
        utc(2011, 0, 1, 0, 0, 2),
      )[2],
      equals(utc(2011, 0, 1, 0, 0, 1)),
    );
  });

  test('utcSecond.range(start, stop, step) can skip seconds', () {
    expect(
      utcSecond.range(utc(2011, 1, 1, 12, 0, 7), utc(2011, 1, 1, 12, 1, 7), 15),
      equals([
        utc(2011, 1, 1, 12, 0, 7),
        utc(2011, 1, 1, 12, 0, 22),
        utc(2011, 1, 1, 12, 0, 37),
        utc(2011, 1, 1, 12, 0, 52),
      ]),
    );
  });

  test(
    'utcSecond.range(start, stop) observes start of daylight savings time',
    () {
      expect(
        utcSecond.range(
          utc(2011, 2, 13, 9, 59, 59),
          utc(2011, 2, 13, 10, 0, 2),
        ),
        equals([
          utc(2011, 2, 13, 9, 59, 59),
          utc(2011, 2, 13, 10),
          utc(2011, 2, 13, 10, 0, 1),
        ]),
      );
    },
  );

  test(
    'utcSecond.range(start, stop) observes end of daylight savings time',
    () {
      expect(
        utcSecond.range(utc(2011, 10, 6, 8, 59, 59), utc(2011, 10, 6, 9, 0, 2)),
        equals([
          utc(2011, 10, 6, 8, 59, 59),
          utc(2011, 10, 6, 9),
          utc(2011, 10, 6, 9, 0, 1),
        ]),
      );
    },
  );

  test('utcSecond.every(step) returns every stepth second, starting with the '
      'first second of the minute', () {
    expect(
      utcSecond
          .every(15)!
          .range(utc(2008, 11, 30, 12, 36, 47), utc(2008, 11, 30, 12, 37, 57)),
      equals([
        utc(2008, 11, 30, 12, 37),
        utc(2008, 11, 30, 12, 37, 15),
        utc(2008, 11, 30, 12, 37, 30),
        utc(2008, 11, 30, 12, 37, 45),
      ]),
    );
    expect(
      utcSecond
          .every(30)!
          .range(utc(2008, 11, 30, 12, 36, 47), utc(2008, 11, 30, 12, 37, 57)),
      equals([utc(2008, 11, 30, 12, 37), utc(2008, 11, 30, 12, 37, 30)]),
    );
  });
}
