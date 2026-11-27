// Ported from d3-time v3.1.0 test/minute-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('timeMinute.floor(date) returns minutes', () {
    expect(
      timeMinute.floor(local(2010, 11, 31, 23, 59, 59)),
      equals(local(2010, 11, 31, 23, 59)),
    );
    expect(timeMinute.floor(local(2011)), equals(local(2011)));
    expect(timeMinute.floor(local(2011, 0, 1, 0, 0, 59)), equals(local(2011)));
    expect(
      timeMinute.floor(local(2011, 0, 1, 0, 1)),
      equals(local(2011, 0, 1, 0, 1)),
    );
  });

  test('timeMinute.ceil(date) returns minutes', () {
    expect(
      timeMinute.ceil(local(2010, 11, 31, 23, 59, 59)),
      equals(local(2011)),
    );
    expect(timeMinute.ceil(local(2011)), equals(local(2011)));
    expect(
      timeMinute.ceil(local(2011, 0, 1, 0, 0, 59)),
      equals(local(2011, 0, 1, 0, 1)),
    );
    expect(
      timeMinute.ceil(local(2011, 0, 1, 0, 1)),
      equals(local(2011, 0, 1, 0, 1)),
    );
  });

  test('timeMinute.offset(date) does not modify the passed-in date', () {
    final d = local(2010, 11, 31, 23, 59, 59, 999);
    timeMinute.offset(d);
    expect(d, equals(local(2010, 11, 31, 23, 59, 59, 999)));
  });

  test('timeMinute.offset(date) does not round the passed-in-date', () {
    expect(
      timeMinute.offset(local(2010, 11, 31, 23, 59, 59, 999)),
      equals(local(2011, 0, 1, 0, 0, 59, 999)),
    );
    expect(
      timeMinute.offset(local(2010, 11, 31, 23, 59, 59, 456), -2),
      equals(local(2010, 11, 31, 23, 57, 59, 456)),
    );
  });

  test('timeMinute.offset(date) allows negative offsets', () {
    expect(
      timeMinute.offset(local(2010, 11, 31, 23, 12), -1),
      equals(local(2010, 11, 31, 23, 11)),
    );
    expect(
      timeMinute.offset(local(2011, 0, 1, 0, 1), -2),
      equals(local(2010, 11, 31, 23, 59)),
    );
    expect(
      timeMinute.offset(local(2011), -1),
      equals(local(2010, 11, 31, 23, 59)),
    );
  });

  test('timeMinute.offset(date) allows positive offsets', () {
    expect(
      timeMinute.offset(local(2010, 11, 31, 23, 11)),
      equals(local(2010, 11, 31, 23, 12)),
    );
    expect(
      timeMinute.offset(local(2010, 11, 31, 23, 59), 2),
      equals(local(2011, 0, 1, 0, 1)),
    );
    expect(timeMinute.offset(local(2010, 11, 31, 23, 59)), equals(local(2011)));
  });

  test('timeMinute.offset(date) allows zero offset', () {
    expect(
      timeMinute.offset(local(2010, 11, 31, 23, 59, 59, 999), 0),
      equals(local(2010, 11, 31, 23, 59, 59, 999)),
    );
    expect(
      timeMinute.offset(local(2010, 11, 31, 23, 59, 58), 0),
      equals(local(2010, 11, 31, 23, 59, 58)),
    );
  });

  test('timeMinute.range(start, stop), returns minutes', () {
    expect(
      timeMinute.range(local(2010, 11, 31, 23, 59), local(2011, 0, 1, 0, 2)),
      equals([
        local(2010, 11, 31, 23, 59),
        local(2011),
        local(2011, 0, 1, 0, 1),
      ]),
    );
  });

  test('timeMinute.range(start, stop), has an inclusive lower bound', () {
    expect(
      timeMinute.range(local(2010, 11, 31, 23, 59), local(2011, 0, 1, 0, 2))[0],
      equals(local(2010, 11, 31, 23, 59)),
    );
  });

  test('timeMinute.range(start, stop), has an exclusive upper bound', () {
    expect(
      timeMinute.range(local(2010, 11, 31, 23, 59), local(2011, 0, 1, 0, 2))[2],
      equals(local(2011, 0, 1, 0, 1)),
    );
  });

  test('timeMinute.range(start, stop), can skip minutes', () {
    expect(
      timeMinute.range(local(2011, 1, 1, 12, 7), local(2011, 1, 1, 13, 7), 15),
      equals([
        local(2011, 1, 1, 12, 7),
        local(2011, 1, 1, 12, 22),
        local(2011, 1, 1, 12, 37),
        local(2011, 1, 1, 12, 52),
      ]),
    );
  });

  test(
    'timeMinute.range(start, stop), observes start of daylight savings time',
    () {
      expect(
        timeMinute.range(utc(2011, 2, 13, 9, 59), utc(2011, 2, 13, 10, 2)),
        sameInstants([
          utc(2011, 2, 13, 9, 59),
          utc(2011, 2, 13, 10),
          utc(2011, 2, 13, 10, 1),
        ]),
      );
    },
  );

  test(
    'timeMinute.range(start, stop), observes end of daylight savings time',
    () {
      expect(
        timeMinute.range(utc(2011, 10, 6, 8, 59), utc(2011, 10, 6, 9, 2)),
        sameInstants([
          utc(2011, 10, 6, 8, 59),
          utc(2011, 10, 6, 9),
          utc(2011, 10, 6, 9, 1),
        ]),
      );
    },
  );

  test('timeMinute.every(step) returns every stepth minute, starting with the '
      'first minute of the hour', () {
    expect(
      timeMinute
          .every(15)!
          .range(local(2008, 11, 30, 12, 47), local(2008, 11, 30, 13, 57)),
      equals([
        local(2008, 11, 30, 13),
        local(2008, 11, 30, 13, 15),
        local(2008, 11, 30, 13, 30),
        local(2008, 11, 30, 13, 45),
      ]),
    );
    expect(
      timeMinute
          .every(30)!
          .range(local(2008, 11, 30, 12, 47), local(2008, 11, 30, 13, 57)),
      equals([local(2008, 11, 30, 13), local(2008, 11, 30, 13, 30)]),
    );
  });

  test('timeMinute.range(start, stop) returns every minute crossing the '
      'daylight savings boundary', () {
    expect(
      timeMinute.range(
        DateTime.fromMillisecondsSinceEpoch(1478422800000 - 2 * 60000),
        DateTime.fromMillisecondsSinceEpoch(1478422800000 + 2 * 60000),
      ),
      equals([
        DateTime.fromMillisecondsSinceEpoch(1478422680000),
        DateTime.fromMillisecondsSinceEpoch(1478422740000),
        DateTime.fromMillisecondsSinceEpoch(1478422800000),
        DateTime.fromMillisecondsSinceEpoch(1478422860000),
      ]),
    );
  });
}
