// Ported from d3-time v3.1.0 test/friday-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('timeFridays in an alias for timeFriday.range', () {
    expect(timeFridays, equals(timeFriday.range));
  });

  test('timeFriday.floor(date) returns Fridays', () {
    expect(
      timeFriday.floor(local(2011, 0, 5, 23, 59, 59)),
      equals(local(2010, 11, 31)),
    );
    expect(timeFriday.floor(local(2011, 0, 6)), equals(local(2010, 11, 31)));
    expect(
      timeFriday.floor(local(2011, 0, 6, 0, 0, 1)),
      equals(local(2010, 11, 31)),
    );
    expect(
      timeFriday.floor(local(2011, 0, 6, 23, 59, 59)),
      equals(local(2010, 11, 31)),
    );
    expect(timeFriday.floor(local(2011, 0, 7)), equals(local(2011, 0, 7)));
    expect(
      timeFriday.floor(local(2011, 0, 7, 0, 0, 1)),
      equals(local(2011, 0, 7)),
    );
  });

  test(
    'timeFriday.count(start, end) counts Fridays after start (exclusive) and '
    'before end (inclusive)',
    () {
      expect(timeFriday.count(local(2012), local(2012, 0, 5)), 0);
      expect(timeFriday.count(local(2012), local(2012, 0, 6)), 1);
      expect(timeFriday.count(local(2012), local(2012, 0, 7)), 1);
      expect(timeFriday.count(local(2012), local(2012, 0, 13)), 2);

      expect(timeFriday.count(local(2010), local(2010, 0, 7)), 0);
      expect(timeFriday.count(local(2010), local(2010, 0, 8)), 1);
      expect(timeFriday.count(local(2010), local(2010, 0, 9)), 1);
    },
  );

  test('timeFriday.count(start, end) observes daylight saving', () {
    expect(timeFriday.count(local(2011), local(2011, 2, 13, 1)), 10);
    expect(timeFriday.count(local(2011), local(2011, 2, 13, 3)), 10);
    expect(timeFriday.count(local(2011), local(2011, 2, 13, 4)), 10);
    expect(timeFriday.count(local(2011), local(2011, 10, 6)), 44);
    expect(timeFriday.count(local(2011), local(2011, 10, 6, 1)), 44);
    expect(timeFriday.count(local(2011), local(2011, 10, 6, 2)), 44);
  });
}
