// Ported from d3-time v3.1.0 test/utcSaturday-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('utcSaturdays in an alias for utcSaturday.range', () {
    expect(utcSaturdays, equals(utcSaturday.range));
  });

  test('utcSaturday.floor(date) returns Saturdays', () {
    expect(utcSaturday.floor(utc(2011, 0, 6, 23, 59, 59)), equals(utc(2011)));
    expect(utcSaturday.floor(utc(2011, 0, 7)), equals(utc(2011)));
    expect(utcSaturday.floor(utc(2011, 0, 7, 0, 0, 1)), equals(utc(2011)));
    expect(utcSaturday.floor(utc(2011, 0, 7, 23, 59, 59)), equals(utc(2011)));
    expect(utcSaturday.floor(utc(2011, 0, 8)), equals(utc(2011, 0, 8)));
    expect(
      utcSaturday.floor(utc(2011, 0, 8, 0, 0, 1)),
      equals(utc(2011, 0, 8)),
    );
  });

  test('utcSaturday.count(start, end) counts Saturdays after start (exclusive) '
      'and before end (inclusive)', () {
    expect(utcSaturday.count(utc(2012), utc(2012, 0, 6)), 0);
    expect(utcSaturday.count(utc(2012), utc(2012, 0, 7)), 1);
    expect(utcSaturday.count(utc(2012), utc(2012, 0, 8)), 1);
    expect(utcSaturday.count(utc(2012), utc(2012, 0, 14)), 2);

    expect(utcSaturday.count(utc(2011), utc(2011, 0, 7)), 0);
    expect(utcSaturday.count(utc(2011), utc(2011, 0, 8)), 1);
    expect(utcSaturday.count(utc(2011), utc(2011, 0, 9)), 1);
  });

  test('utcSaturday.count(start, end) does not observe daylight saving', () {
    expect(utcSaturday.count(utc(2011), utc(2011, 2, 13, 1)), 10);
    expect(utcSaturday.count(utc(2011), utc(2011, 2, 13, 3)), 10);
    expect(utcSaturday.count(utc(2011), utc(2011, 2, 13, 4)), 10);
    expect(utcSaturday.count(utc(2011), utc(2011, 10, 6)), 44);
    expect(utcSaturday.count(utc(2011), utc(2011, 10, 6, 1)), 44);
    expect(utcSaturday.count(utc(2011), utc(2011, 10, 6, 2)), 44);
  });
}
