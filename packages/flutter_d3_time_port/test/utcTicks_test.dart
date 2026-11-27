// Ported from d3-time v3.1.0 test/utcTicks-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('utcTicks(start, stop, interval) respects the specified interval', () {
    expect(
      utcTicksWith(
        utc(2011, 0, 1, 12, 1),
        utc(2011, 0, 1, 12, 4, 4),
        utcMinute,
      ),
      equals([
        utc(2011, 0, 1, 12, 1),
        utc(2011, 0, 1, 12, 2),
        utc(2011, 0, 1, 12, 3),
        utc(2011, 0, 1, 12, 4),
      ]),
    );
  });

  test(
    'utcTicks(start, stop, interval.every(step)) observes the specified tick '
    'interval and step',
    () {
      expect(
        utcTicksWith(
          utc(2011, 0, 1, 12),
          utc(2011, 0, 1, 12, 33, 4),
          utcMinute.every(10),
        ),
        equals([
          utc(2011, 0, 1, 12),
          utc(2011, 0, 1, 12, 10),
          utc(2011, 0, 1, 12, 20),
          utc(2011, 0, 1, 12, 30),
        ]),
      );
    },
  );

  test('utcTicks(start, stop, count) can generate sub-second ticks', () {
    expect(
      utcTicks(utc(2011, 0, 1, 12), utc(2011, 0, 1, 12, 0, 1), 4),
      equals([
        utc(2011, 0, 1, 12),
        utc(2011, 0, 1, 12, 0, 0, 200),
        utc(2011, 0, 1, 12, 0, 0, 400),
        utc(2011, 0, 1, 12, 0, 0, 600),
        utc(2011, 0, 1, 12, 0, 0, 800),
        utc(2011, 0, 1, 12, 0, 1),
      ]),
    );
  });

  test('utcTicks(start, stop, count) can generate 1-second ticks', () {
    expect(
      utcTicks(utc(2011, 0, 1, 12), utc(2011, 0, 1, 12, 0, 4), 4),
      equals([
        utc(2011, 0, 1, 12),
        utc(2011, 0, 1, 12, 0, 1),
        utc(2011, 0, 1, 12, 0, 2),
        utc(2011, 0, 1, 12, 0, 3),
        utc(2011, 0, 1, 12, 0, 4),
      ]),
    );
  });

  test('utcTicks(start, stop, count) can generate 5-second ticks', () {
    expect(
      utcTicks(utc(2011, 0, 1, 12), utc(2011, 0, 1, 12, 0, 20), 4),
      equals([
        utc(2011, 0, 1, 12),
        utc(2011, 0, 1, 12, 0, 5),
        utc(2011, 0, 1, 12, 0, 10),
        utc(2011, 0, 1, 12, 0, 15),
        utc(2011, 0, 1, 12, 0, 20),
      ]),
    );
  });

  test('utcTicks(start, stop, count) can generate 15-second ticks', () {
    expect(
      utcTicks(utc(2011, 0, 1, 12), utc(2011, 0, 1, 12, 0, 50), 4),
      equals([
        utc(2011, 0, 1, 12),
        utc(2011, 0, 1, 12, 0, 15),
        utc(2011, 0, 1, 12, 0, 30),
        utc(2011, 0, 1, 12, 0, 45),
      ]),
    );
  });

  test('utcTicks(start, stop, count) can generate 30-second ticks', () {
    expect(
      utcTicks(utc(2011, 0, 1, 12), utc(2011, 0, 1, 12, 1, 50), 4),
      equals([
        utc(2011, 0, 1, 12),
        utc(2011, 0, 1, 12, 0, 30),
        utc(2011, 0, 1, 12, 1),
        utc(2011, 0, 1, 12, 1, 30),
      ]),
    );
  });

  test('utcTicks(start, stop, count) can generate 1-minute ticks', () {
    expect(
      utcTicks(utc(2011, 0, 1, 12, 0, 27), utc(2011, 0, 1, 12, 4, 12), 4),
      equals([
        utc(2011, 0, 1, 12, 1),
        utc(2011, 0, 1, 12, 2),
        utc(2011, 0, 1, 12, 3),
        utc(2011, 0, 1, 12, 4),
      ]),
    );
  });

  test('utcTicks(start, stop, count) can generate 5-minute ticks', () {
    expect(
      utcTicks(utc(2011, 0, 1, 12, 3, 27), utc(2011, 0, 1, 12, 21, 12), 4),
      equals([
        utc(2011, 0, 1, 12, 5),
        utc(2011, 0, 1, 12, 10),
        utc(2011, 0, 1, 12, 15),
        utc(2011, 0, 1, 12, 20),
      ]),
    );
  });

  test('utcTicks(start, stop, count) can generate 15-minute ticks', () {
    expect(
      utcTicks(utc(2011, 0, 1, 12, 8, 27), utc(2011, 0, 1, 13, 4, 12), 4),
      equals([
        utc(2011, 0, 1, 12, 15),
        utc(2011, 0, 1, 12, 30),
        utc(2011, 0, 1, 12, 45),
        utc(2011, 0, 1, 13),
      ]),
    );
  });

  test('utcTicks(start, stop, count) can generate 30-minute ticks', () {
    expect(
      utcTicks(utc(2011, 0, 1, 12, 28, 27), utc(2011, 0, 1, 14, 4, 12), 4),
      equals([
        utc(2011, 0, 1, 12, 30),
        utc(2011, 0, 1, 13),
        utc(2011, 0, 1, 13, 30),
        utc(2011, 0, 1, 14),
      ]),
    );
  });

  test('utcTicks(start, stop, count) can generate 1-hour ticks', () {
    expect(
      utcTicks(utc(2011, 0, 1, 12, 28, 27), utc(2011, 0, 1, 16, 34, 12), 4),
      equals([
        utc(2011, 0, 1, 13),
        utc(2011, 0, 1, 14),
        utc(2011, 0, 1, 15),
        utc(2011, 0, 1, 16),
      ]),
    );
  });

  test('utcTicks(start, stop, count) can generate 3-hour ticks', () {
    expect(
      utcTicks(utc(2011, 0, 1, 14, 28, 27), utc(2011, 0, 2, 1, 34, 12), 4),
      equals([
        utc(2011, 0, 1, 15),
        utc(2011, 0, 1, 18),
        utc(2011, 0, 1, 21),
        utc(2011, 0, 2),
      ]),
    );
  });

  test('utcTicks(start, stop, count) can generate 6-hour ticks', () {
    expect(
      utcTicks(utc(2011, 0, 1, 16, 28, 27), utc(2011, 0, 2, 14, 34, 12), 4),
      equals([
        utc(2011, 0, 1, 18),
        utc(2011, 0, 2),
        utc(2011, 0, 2, 6),
        utc(2011, 0, 2, 12),
      ]),
    );
  });

  test('utcTicks(start, stop, count) can generate 12-hour ticks', () {
    expect(
      utcTicks(utc(2011, 0, 1, 16, 28, 27), utc(2011, 0, 3, 21, 34, 12), 4),
      equals([
        utc(2011, 0, 2),
        utc(2011, 0, 2, 12),
        utc(2011, 0, 3),
        utc(2011, 0, 3, 12),
      ]),
    );
  });

  test('utcTicks(start, stop, count) can generate 1-day ticks', () {
    expect(
      utcTicks(utc(2011, 0, 1, 16, 28, 27), utc(2011, 0, 5, 21, 34, 12), 4),
      equals([
        utc(2011, 0, 2),
        utc(2011, 0, 3),
        utc(2011, 0, 4),
        utc(2011, 0, 5),
      ]),
    );
  });

  test('utcTicks(start, stop, count) can generate 2-day ticks', () {
    expect(
      utcTicks(utc(2011, 0, 2, 16, 28, 27), utc(2011, 0, 9, 21, 34, 12), 4),
      equals([utc(2011, 0, 4), utc(2011, 0, 6), utc(2011, 0, 8)]),
    );
  });

  test('utcTicks(start, stop, count) can generate 1-week ticks', () {
    expect(
      utcTicks(utc(2011, 0, 1, 16, 28, 27), utc(2011, 0, 23, 21, 34, 12), 4),
      equals([
        utc(2011, 0, 2),
        utc(2011, 0, 9),
        utc(2011, 0, 16),
        utc(2011, 0, 23),
      ]),
    );
  });

  test('utcTicks(start, stop, count) can generate 1-month ticks', () {
    expect(
      utcTicks(utc(2011, 0, 18), utc(2011, 4, 2), 4),
      equals([utc(2011, 1), utc(2011, 2), utc(2011, 3), utc(2011, 4)]),
    );
  });

  test('utcTicks(start, stop, count) can generate 3-month ticks', () {
    expect(
      utcTicks(utc(2010, 11, 18), utc(2011, 10, 2), 4),
      equals([utc(2011), utc(2011, 3), utc(2011, 6), utc(2011, 9)]),
    );
  });

  test('utcTicks(start, stop, count) can generate 1-year ticks', () {
    expect(
      utcTicks(utc(2010, 11, 18), utc(2014, 2, 2), 4),
      equals([utc(2011), utc(2012), utc(2013), utc(2014)]),
    );
  });

  test('utcTicks(start, stop, count) can generate multi-year ticks', () {
    expect(
      utcTicks(utc(0, 11, 18), utc(2014, 2, 2), 6),
      equals([utc(500), utc(1000), utc(1500), utc(2000)]),
    );
  });

  test('utcTicks(start, stop, count) returns one tick for an empty domain', () {
    expect(
      utcTicks(utc(2014, 2, 2), utc(2014, 2, 2), 6),
      equals([utc(2014, 2, 2)]),
    );
  });

  test('utcTicks(start, stop, count) returns descending ticks for a descending '
      'domain', () {
    expect(
      utcTicks(utc(2014, 2, 2), utc(2010, 11, 18), 4),
      equals([utc(2014), utc(2013), utc(2012), utc(2011)]),
    );
    expect(
      utcTicks(utc(2011, 10, 2), utc(2010, 11, 18), 4),
      equals([utc(2011, 9), utc(2011, 6), utc(2011, 3), utc(2011)]),
    );
  });
}
