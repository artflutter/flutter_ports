// Ported from d3-time v3.1.0 test/utcFriday-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('utcFridays in an alias for utcFriday.range', () {
    expect(utcFridays, equals(utcFriday.range));
  });

  test('utcFriday.floor(date) returns Fridays', () {
    expect(
      utcFriday.floor(utc(2011, 0, 5, 23, 59, 59)),
      equals(utc(2010, 11, 31)),
    );
    expect(utcFriday.floor(utc(2011, 0, 6)), equals(utc(2010, 11, 31)));
    expect(
      utcFriday.floor(utc(2011, 0, 6, 0, 0, 1)),
      equals(utc(2010, 11, 31)),
    );
    expect(
      utcFriday.floor(utc(2011, 0, 6, 23, 59, 59)),
      equals(utc(2010, 11, 31)),
    );
    expect(utcFriday.floor(utc(2011, 0, 7)), equals(utc(2011, 0, 7)));
    expect(utcFriday.floor(utc(2011, 0, 7, 0, 0, 1)), equals(utc(2011, 0, 7)));
  });

  test('utcFriday.count(start, end) counts Fridays after start (exclusive) and '
      'before end (inclusive)', () {
    expect(utcFriday.count(utc(2012), utc(2012, 0, 5)), 0);
    expect(utcFriday.count(utc(2012), utc(2012, 0, 6)), 1);
    expect(utcFriday.count(utc(2012), utc(2012, 0, 7)), 1);
    expect(utcFriday.count(utc(2012), utc(2012, 0, 13)), 2);

    expect(utcFriday.count(utc(2010), utc(2010, 0, 7)), 0);
    expect(utcFriday.count(utc(2010), utc(2010, 0, 8)), 1);
    expect(utcFriday.count(utc(2010), utc(2010, 0, 9)), 1);
  });

  test('utcFriday.count(start, end) does not observe daylight saving', () {
    expect(utcFriday.count(utc(2011), utc(2011, 2, 13, 1)), 10);
    expect(utcFriday.count(utc(2011), utc(2011, 2, 13, 3)), 10);
    expect(utcFriday.count(utc(2011), utc(2011, 2, 13, 4)), 10);
    expect(utcFriday.count(utc(2011), utc(2011, 10, 6)), 44);
    expect(utcFriday.count(utc(2011), utc(2011, 10, 6, 1)), 44);
    expect(utcFriday.count(utc(2011), utc(2011, 10, 6, 2)), 44);
  });
}
