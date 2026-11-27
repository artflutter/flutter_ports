// Ported from d3-time v3.1.0 test/utcMonday-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('utcMondays in an alias for utcMonday.range', () {
    expect(utcMondays, equals(utcMonday.range));
  });

  test('utcMonday.floor(date) returns Mondays', () {
    expect(
      utcMonday.floor(utc(2011, 0, 1, 23, 59, 59)),
      equals(utc(2010, 11, 27)),
    );
    expect(utcMonday.floor(utc(2011, 0, 2)), equals(utc(2010, 11, 27)));
    expect(
      utcMonday.floor(utc(2011, 0, 2, 0, 0, 1)),
      equals(utc(2010, 11, 27)),
    );
    expect(
      utcMonday.floor(utc(2011, 0, 2, 23, 59, 59)),
      equals(utc(2010, 11, 27)),
    );
    expect(utcMonday.floor(utc(2011, 0, 3)), equals(utc(2011, 0, 3)));
    expect(utcMonday.floor(utc(2011, 0, 3, 0, 0, 1)), equals(utc(2011, 0, 3)));
  });

  test('utcMonday.range(start, stop, step) returns every step Monday', () {
    expect(
      utcMonday.range(utc(2011, 11), utc(2012, 0, 15), 2),
      equals([utc(2011, 11, 5), utc(2011, 11, 19), utc(2012, 0, 2)]),
    );
  });

  test('utcMonday.count(start, end) counts Mondays after start (exclusive) and '
      'before end (inclusive)', () {
    expect(utcMonday.count(utc(2014), utc(2014, 0, 5)), 0);
    expect(utcMonday.count(utc(2014), utc(2014, 0, 6)), 1);
    expect(utcMonday.count(utc(2014), utc(2014, 0, 7)), 1);
    expect(utcMonday.count(utc(2014), utc(2014, 0, 13)), 2);

    expect(utcMonday.count(utc(2018), utc(2018, 0, 7)), 0);
    expect(utcMonday.count(utc(2018), utc(2018, 0, 8)), 1);
    expect(utcMonday.count(utc(2018), utc(2018, 0, 9)), 1);
  });

  test('utcMonday.count(start, end) does not observe daylight saving', () {
    expect(utcMonday.count(utc(2011), utc(2011, 2, 13, 1)), 10);
    expect(utcMonday.count(utc(2011), utc(2011, 2, 13, 3)), 10);
    expect(utcMonday.count(utc(2011), utc(2011, 2, 13, 4)), 10);
    expect(utcMonday.count(utc(2011), utc(2011, 10, 6)), 44);
    expect(utcMonday.count(utc(2011), utc(2011, 10, 6, 1)), 44);
    expect(utcMonday.count(utc(2011), utc(2011, 10, 6, 2)), 44);
  });
}
