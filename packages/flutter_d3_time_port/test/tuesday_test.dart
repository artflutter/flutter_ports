// Ported from d3-time v3.1.0 test/tuesday-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('timeTuesdays in an alias for timeTuesday.range', () {
    expect(timeTuesdays, equals(timeTuesday.range));
  });

  test('timeTuesday.floor(date) returns Tuesdays', () {
    expect(
      timeTuesday.floor(local(2011, 0, 2, 23, 59, 59)),
      equals(local(2010, 11, 28)),
    );
    expect(timeTuesday.floor(local(2011, 0, 3)), equals(local(2010, 11, 28)));
    expect(
      timeTuesday.floor(local(2011, 0, 3, 0, 0, 1)),
      equals(local(2010, 11, 28)),
    );
    expect(
      timeTuesday.floor(local(2011, 0, 3, 23, 59, 59)),
      equals(local(2010, 11, 28)),
    );
    expect(timeTuesday.floor(local(2011, 0, 4)), equals(local(2011, 0, 4)));
    expect(
      timeTuesday.floor(local(2011, 0, 4, 0, 0, 1)),
      equals(local(2011, 0, 4)),
    );
  });

  test('timeTuesday.count(start, end) counts Tuesdays after start (exclusive) '
      'and before end (inclusive)', () {
    expect(timeTuesday.count(local(2014), local(2014, 0, 6)), 0);
    expect(timeTuesday.count(local(2014), local(2014, 0, 7)), 1);
    expect(timeTuesday.count(local(2014), local(2014, 0, 8)), 1);
    expect(timeTuesday.count(local(2014), local(2014, 0, 14)), 2);

    expect(timeTuesday.count(local(2013), local(2013, 0, 7)), 0);
    expect(timeTuesday.count(local(2013), local(2013, 0, 8)), 1);
    expect(timeTuesday.count(local(2013), local(2013, 0, 9)), 1);
  });

  test('timeTuesday.count(start, end) observes daylight saving', () {
    expect(timeTuesday.count(local(2011), local(2011, 2, 13, 1)), 10);
    expect(timeTuesday.count(local(2011), local(2011, 2, 13, 3)), 10);
    expect(timeTuesday.count(local(2011), local(2011, 2, 13, 4)), 10);
    expect(timeTuesday.count(local(2011), local(2011, 10, 6)), 44);
    expect(timeTuesday.count(local(2011), local(2011, 10, 6, 1)), 44);
    expect(timeTuesday.count(local(2011), local(2011, 10, 6, 2)), 44);
  });
}
