// Ported from d3-time v3.1.0 test/utcHour-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('utcHour.floor(date) returns hours', () {
    expect(
      utcHour.floor(utc(2010, 11, 31, 23, 59)),
      equals(utc(2010, 11, 31, 23)),
    );
    expect(utcHour.floor(utc(2011)), equals(utc(2011)));
    expect(utcHour.floor(utc(2011, 0, 1, 0, 1)), equals(utc(2011)));
  });

  test('utcHour.floor(date) observes start of daylight savings time', () {
    expect(utcHour.floor(utc(2011, 2, 13, 8, 59)), equals(utc(2011, 2, 13, 8)));
    expect(utcHour.floor(utc(2011, 2, 13, 9)), equals(utc(2011, 2, 13, 9)));
    expect(utcHour.floor(utc(2011, 2, 13, 9, 1)), equals(utc(2011, 2, 13, 9)));
    expect(utcHour.floor(utc(2011, 2, 13, 9, 59)), equals(utc(2011, 2, 13, 9)));
    expect(utcHour.floor(utc(2011, 2, 13, 10)), equals(utc(2011, 2, 13, 10)));
    expect(
      utcHour.floor(utc(2011, 2, 13, 10, 1)),
      equals(utc(2011, 2, 13, 10)),
    );
  });

  test('utcHour.floor(date) observes end of daylight savings time', () {
    expect(utcHour.floor(utc(2011, 10, 6, 7, 59)), equals(utc(2011, 10, 6, 7)));
    expect(utcHour.floor(utc(2011, 10, 6, 8)), equals(utc(2011, 10, 6, 8)));
    expect(utcHour.floor(utc(2011, 10, 6, 8, 1)), equals(utc(2011, 10, 6, 8)));
    expect(utcHour.floor(utc(2011, 10, 6, 8, 59)), equals(utc(2011, 10, 6, 8)));
    expect(utcHour.floor(utc(2011, 10, 6, 9)), equals(utc(2011, 10, 6, 9)));
    expect(utcHour.floor(utc(2011, 10, 6, 9, 1)), equals(utc(2011, 10, 6, 9)));
  });

  test('utcHour.ceil(date) returns hours', () {
    expect(utcHour.ceil(utc(2010, 11, 31, 23, 59)), equals(utc(2011)));
    expect(utcHour.ceil(utc(2011)), equals(utc(2011)));
    expect(utcHour.ceil(utc(2011, 0, 1, 0, 1)), equals(utc(2011, 0, 1, 1)));
  });

  test('utcHour.ceil(date) observes start of daylight savings time', () {
    expect(utcHour.ceil(utc(2011, 2, 13, 8, 59)), equals(utc(2011, 2, 13, 9)));
    expect(utcHour.ceil(utc(2011, 2, 13, 9)), equals(utc(2011, 2, 13, 9)));
    expect(utcHour.ceil(utc(2011, 2, 13, 9, 1)), equals(utc(2011, 2, 13, 10)));
    expect(utcHour.ceil(utc(2011, 2, 13, 9, 59)), equals(utc(2011, 2, 13, 10)));
    expect(utcHour.ceil(utc(2011, 2, 13, 10)), equals(utc(2011, 2, 13, 10)));
    expect(utcHour.ceil(utc(2011, 2, 13, 10, 1)), equals(utc(2011, 2, 13, 11)));
  });

  test('utcHour.ceil(date) observes end of daylight savings time', () {
    expect(utcHour.ceil(utc(2011, 10, 6, 7, 59)), equals(utc(2011, 10, 6, 8)));
    expect(utcHour.ceil(utc(2011, 10, 6, 8)), equals(utc(2011, 10, 6, 8)));
    expect(utcHour.ceil(utc(2011, 10, 6, 8, 1)), equals(utc(2011, 10, 6, 9)));
    expect(utcHour.ceil(utc(2011, 10, 6, 8, 59)), equals(utc(2011, 10, 6, 9)));
    expect(utcHour.ceil(utc(2011, 10, 6, 9)), equals(utc(2011, 10, 6, 9)));
    expect(utcHour.ceil(utc(2011, 10, 6, 9, 1)), equals(utc(2011, 10, 6, 10)));
  });

  test('utcHour.offset(date) does not modify the passed-in date', () {
    final d = utc(2010, 11, 31, 23, 59, 59, 999);
    utcHour.offset(d);
    expect(d, equals(utc(2010, 11, 31, 23, 59, 59, 999)));
  });

  test('utcHour.offset(date) does not round the passed-in-date', () {
    expect(
      utcHour.offset(utc(2010, 11, 31, 23, 59, 59, 999)),
      equals(utc(2011, 0, 1, 0, 59, 59, 999)),
    );
    expect(
      utcHour.offset(utc(2010, 11, 31, 23, 59, 59, 456), -2),
      equals(utc(2010, 11, 31, 21, 59, 59, 456)),
    );
  });

  test('utcHour.offset(date) allows negative offsets', () {
    expect(
      utcHour.offset(utc(2010, 11, 31, 12), -1),
      equals(utc(2010, 11, 31, 11)),
    );
    expect(
      utcHour.offset(utc(2011, 0, 1, 1), -2),
      equals(utc(2010, 11, 31, 23)),
    );
    expect(utcHour.offset(utc(2011), -1), equals(utc(2010, 11, 31, 23)));
  });

  test('utcHour.offset(date) allows positive offsets', () {
    expect(
      utcHour.offset(utc(2010, 11, 31, 11)),
      equals(utc(2010, 11, 31, 12)),
    );
    expect(
      utcHour.offset(utc(2010, 11, 31, 23), 2),
      equals(utc(2011, 0, 1, 1)),
    );
    expect(utcHour.offset(utc(2010, 11, 31, 23)), equals(utc(2011)));
  });

  test('utcHour.offset(date) allows zero offset', () {
    expect(
      utcHour.offset(utc(2010, 11, 31, 23, 59, 59, 999), 0),
      equals(utc(2010, 11, 31, 23, 59, 59, 999)),
    );
    expect(
      utcHour.offset(utc(2010, 11, 31, 23, 59, 58), 0),
      equals(utc(2010, 11, 31, 23, 59, 58)),
    );
  });

  test('utcHour.range(start, stop) returns hours', () {
    expect(
      utcHour.range(utc(2010, 11, 31, 12, 30), utc(2010, 11, 31, 15, 30)),
      equals([
        utc(2010, 11, 31, 13),
        utc(2010, 11, 31, 14),
        utc(2010, 11, 31, 15),
      ]),
    );
  });

  test('utcHour.range(start, stop) has an inclusive lower bound', () {
    expect(
      utcHour.range(utc(2010, 11, 31, 23), utc(2011, 0, 1, 2))[0],
      equals(utc(2010, 11, 31, 23)),
    );
  });

  test('utcHour.range(start, stop) has an exclusive upper bound', () {
    expect(
      utcHour.range(utc(2010, 11, 31, 23), utc(2011, 0, 1, 2))[2],
      equals(utc(2011, 0, 1, 1)),
    );
  });

  test('utcHour.range(start, stop) can skip hours', () {
    expect(
      utcHour.range(utc(2011, 1, 1, 1), utc(2011, 1, 1, 13), 3),
      equals([
        utc(2011, 1, 1, 1),
        utc(2011, 1, 1, 4),
        utc(2011, 1, 1, 7),
        utc(2011, 1, 1, 10),
      ]),
    );
  });

  test('utcHour.range(start, stop) does not observe the start of daylight '
      'savings time', () {
    expect(
      utcHour.range(utc(2011, 2, 13, 1), utc(2011, 2, 13, 5)),
      equals([
        utc(2011, 2, 13, 1),
        utc(2011, 2, 13, 2),
        utc(2011, 2, 13, 3),
        utc(2011, 2, 13, 4),
      ]),
    );
  });

  test('utcHour.range(start, stop) does not observe the end of daylight '
      'savings time', () {
    expect(
      utcHour.range(utc(2011, 10, 6), utc(2011, 10, 6, 2)),
      equals([utc(2011, 10, 6), utc(2011, 10, 6, 1)]),
    );
  });

  test('utcHour.every(step) returns every stepth hour, starting with the first '
      'hour of the day', () {
    expect(
      utcHour
          .every(4)!
          .range(utc(2008, 11, 30, 12, 47), utc(2008, 11, 31, 13, 57)),
      equals([
        utc(2008, 11, 30, 16),
        utc(2008, 11, 30, 20),
        utc(2008, 11, 31),
        utc(2008, 11, 31, 4),
        utc(2008, 11, 31, 8),
        utc(2008, 11, 31, 12),
      ]),
    );
    expect(
      utcHour
          .every(12)!
          .range(utc(2008, 11, 30, 12, 47), utc(2008, 11, 31, 13, 57)),
      equals([utc(2008, 11, 31), utc(2008, 11, 31, 12)]),
    );
  });
}
