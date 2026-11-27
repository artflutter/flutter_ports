// Ported from d3-time v3.1.0 test/utcTuesday-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('utcTuesdays in an alias for utcTuesday.range', () {
    expect(utcTuesdays, equals(utcTuesday.range));
  });

  test('utcTuesday.floor(date) returns Tuesdays', () {
    expect(
      utcTuesday.floor(utc(2011, 0, 2, 23, 59, 59)),
      equals(utc(2010, 11, 28)),
    );
    expect(utcTuesday.floor(utc(2011, 0, 3)), equals(utc(2010, 11, 28)));
    expect(
      utcTuesday.floor(utc(2011, 0, 3, 0, 0, 1)),
      equals(utc(2010, 11, 28)),
    );
    expect(
      utcTuesday.floor(utc(2011, 0, 3, 23, 59, 59)),
      equals(utc(2010, 11, 28)),
    );
    expect(utcTuesday.floor(utc(2011, 0, 4)), equals(utc(2011, 0, 4)));
    expect(utcTuesday.floor(utc(2011, 0, 4, 0, 0, 1)), equals(utc(2011, 0, 4)));
  });

  test('utcTuesday.count(start, end) counts Tuesdays after start (exclusive) '
      'and before end (inclusive)', () {
    expect(utcTuesday.count(utc(2014), utc(2014, 0, 6)), 0);
    expect(utcTuesday.count(utc(2014), utc(2014, 0, 7)), 1);
    expect(utcTuesday.count(utc(2014), utc(2014, 0, 8)), 1);
    expect(utcTuesday.count(utc(2014), utc(2014, 0, 14)), 2);

    expect(utcTuesday.count(utc(2013), utc(2013, 0, 7)), 0);
    expect(utcTuesday.count(utc(2013), utc(2013, 0, 8)), 1);
    expect(utcTuesday.count(utc(2013), utc(2013, 0, 9)), 1);
  });

  test('utcTuesday.count(start, end) does not observe daylight saving', () {
    expect(utcTuesday.count(utc(2011), utc(2011, 2, 13, 1)), 10);
    expect(utcTuesday.count(utc(2011), utc(2011, 2, 13, 3)), 10);
    expect(utcTuesday.count(utc(2011), utc(2011, 2, 13, 4)), 10);
    expect(utcTuesday.count(utc(2011), utc(2011, 10, 6)), 44);
    expect(utcTuesday.count(utc(2011), utc(2011, 10, 6, 1)), 44);
    expect(utcTuesday.count(utc(2011), utc(2011, 10, 6, 2)), 44);
  });
}
