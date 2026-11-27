// Ported from d3-time v3.1.0 test/utcThursday-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('utcThursdays in an alias for utcThursday.range', () {
    expect(utcThursdays, equals(utcThursday.range));
  });

  test('utcThursday.floor(date) returns Thursdays', () {
    expect(
      utcThursday.floor(utc(2011, 0, 4, 23, 59, 59)),
      equals(utc(2010, 11, 30)),
    );
    expect(utcThursday.floor(utc(2011, 0, 5)), equals(utc(2010, 11, 30)));
    expect(
      utcThursday.floor(utc(2011, 0, 5, 0, 0, 1)),
      equals(utc(2010, 11, 30)),
    );
    expect(
      utcThursday.floor(utc(2011, 0, 5, 23, 59, 59)),
      equals(utc(2010, 11, 30)),
    );
    expect(utcThursday.floor(utc(2011, 0, 6)), equals(utc(2011, 0, 6)));
    expect(
      utcThursday.floor(utc(2011, 0, 6, 0, 0, 1)),
      equals(utc(2011, 0, 6)),
    );
  });

  test('utcThursday.count(start, end) counts Thursdays after start (exclusive) '
      'and before end (inclusive)', () {
    expect(utcThursday.count(utc(2012), utc(2012, 0, 4)), 0);
    expect(utcThursday.count(utc(2012), utc(2012, 0, 5)), 1);
    expect(utcThursday.count(utc(2012), utc(2012, 0, 6)), 1);
    expect(utcThursday.count(utc(2012), utc(2012, 0, 12)), 2);

    expect(utcThursday.count(utc(2015), utc(2015, 0, 7)), 0);
    expect(utcThursday.count(utc(2015), utc(2015, 0, 8)), 1);
    expect(utcThursday.count(utc(2015), utc(2015, 0, 9)), 1);
  });

  test('utcThursday.count(start, end) does not observe daylight saving', () {
    expect(utcThursday.count(utc(2011), utc(2011, 2, 13, 1)), 10);
    expect(utcThursday.count(utc(2011), utc(2011, 2, 13, 3)), 10);
    expect(utcThursday.count(utc(2011), utc(2011, 2, 13, 4)), 10);
    expect(utcThursday.count(utc(2011), utc(2011, 10, 6)), 44);
    expect(utcThursday.count(utc(2011), utc(2011, 10, 6, 1)), 44);
    expect(utcThursday.count(utc(2011), utc(2011, 10, 6, 2)), 44);
  });
}
