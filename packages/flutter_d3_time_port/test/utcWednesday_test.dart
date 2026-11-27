// Ported from d3-time v3.1.0 test/utcWednesday-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('utcWednesdays in an alias for utcWednesday.range', () {
    expect(utcWednesdays, equals(utcWednesday.range));
  });

  test('utcWednesday.floor(date) returns Wednesdays', () {
    expect(
      utcWednesday.floor(utc(2011, 0, 3, 23, 59, 59)),
      equals(utc(2010, 11, 29)),
    );
    expect(utcWednesday.floor(utc(2011, 0, 4)), equals(utc(2010, 11, 29)));
    expect(
      utcWednesday.floor(utc(2011, 0, 4, 0, 0, 1)),
      equals(utc(2010, 11, 29)),
    );
    expect(
      utcWednesday.floor(utc(2011, 0, 4, 23, 59, 59)),
      equals(utc(2010, 11, 29)),
    );
    expect(utcWednesday.floor(utc(2011, 0, 5)), equals(utc(2011, 0, 5)));
    expect(
      utcWednesday.floor(utc(2011, 0, 5, 0, 0, 1)),
      equals(utc(2011, 0, 5)),
    );
  });

  test(
    'utcWednesday.count(start, end) counts Wednesdays after start (exclusive) '
    'and before end (inclusive)',
    () {
      expect(utcWednesday.count(utc(2012), utc(2012, 0, 3)), 0);
      expect(utcWednesday.count(utc(2012), utc(2012, 0, 4)), 1);
      expect(utcWednesday.count(utc(2012), utc(2012, 0, 5)), 1);
      expect(utcWednesday.count(utc(2012), utc(2012, 0, 11)), 2);

      expect(utcWednesday.count(utc(2014), utc(2014, 0, 7)), 0);
      expect(utcWednesday.count(utc(2014), utc(2014, 0, 8)), 1);
      expect(utcWednesday.count(utc(2014), utc(2014, 0, 9)), 1);
    },
  );

  test('utcWednesday.count(start, end) does not observe daylight saving', () {
    expect(utcWednesday.count(utc(2011), utc(2011, 2, 13, 1)), 10);
    expect(utcWednesday.count(utc(2011), utc(2011, 2, 13, 3)), 10);
    expect(utcWednesday.count(utc(2011), utc(2011, 2, 13, 4)), 10);
    expect(utcWednesday.count(utc(2011), utc(2011, 10, 6)), 44);
    expect(utcWednesday.count(utc(2011), utc(2011, 10, 6, 1)), 44);
    expect(utcWednesday.count(utc(2011), utc(2011, 10, 6, 2)), 44);
  });
}
