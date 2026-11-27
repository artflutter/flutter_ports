// Ported from d3-time v3.1.0 test/saturday-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('timeSaturdays in an alias for timeSaturday.range', () {
    expect(timeSaturdays, equals(timeSaturday.range));
  });

  test('timeSaturday.floor(date) returns Saturdays', () {
    expect(
      timeSaturday.floor(local(2011, 0, 6, 23, 59, 59)),
      equals(local(2011)),
    );
    expect(timeSaturday.floor(local(2011, 0, 7)), equals(local(2011)));
    expect(timeSaturday.floor(local(2011, 0, 7, 0, 0, 1)), equals(local(2011)));
    expect(
      timeSaturday.floor(local(2011, 0, 7, 23, 59, 59)),
      equals(local(2011)),
    );
    expect(timeSaturday.floor(local(2011, 0, 8)), equals(local(2011, 0, 8)));
    expect(
      timeSaturday.floor(local(2011, 0, 8, 0, 0, 1)),
      equals(local(2011, 0, 8)),
    );
  });

  test(
    'timeSaturday.count(start, end) counts Saturdays after start (exclusive) '
    'and before end (inclusive)',
    () {
      expect(timeSaturday.count(local(2012), local(2012, 0, 6)), 0);
      expect(timeSaturday.count(local(2012), local(2012, 0, 7)), 1);
      expect(timeSaturday.count(local(2012), local(2012, 0, 8)), 1);
      expect(timeSaturday.count(local(2012), local(2012, 0, 14)), 2);

      expect(timeSaturday.count(local(2011), local(2011, 0, 7)), 0);
      expect(timeSaturday.count(local(2011), local(2011, 0, 8)), 1);
      expect(timeSaturday.count(local(2011), local(2011, 0, 9)), 1);
    },
  );

  test('timeSaturday.count(start, end) observes daylight saving', () {
    expect(timeSaturday.count(local(2011), local(2011, 2, 13, 1)), 10);
    expect(timeSaturday.count(local(2011), local(2011, 2, 13, 3)), 10);
    expect(timeSaturday.count(local(2011), local(2011, 2, 13, 4)), 10);
    expect(timeSaturday.count(local(2011), local(2011, 10, 6)), 44);
    expect(timeSaturday.count(local(2011), local(2011, 10, 6, 1)), 44);
    expect(timeSaturday.count(local(2011), local(2011, 10, 6, 2)), 44);
  });
}
