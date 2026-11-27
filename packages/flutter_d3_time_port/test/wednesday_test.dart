// Ported from d3-time v3.1.0 test/wednesday-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('timeWednesdays in an alias for timeWednesday.range', () {
    expect(timeWednesdays, equals(timeWednesday.range));
  });

  test('timeWednesday.floor(date) returns Wednesdays', () {
    expect(
      timeWednesday.floor(local(2011, 0, 3, 23, 59, 59)),
      equals(local(2010, 11, 29)),
    );
    expect(timeWednesday.floor(local(2011, 0, 4)), equals(local(2010, 11, 29)));
    expect(
      timeWednesday.floor(local(2011, 0, 4, 0, 0, 1)),
      equals(local(2010, 11, 29)),
    );
    expect(
      timeWednesday.floor(local(2011, 0, 4, 23, 59, 59)),
      equals(local(2010, 11, 29)),
    );
    expect(timeWednesday.floor(local(2011, 0, 5)), equals(local(2011, 0, 5)));
    expect(
      timeWednesday.floor(local(2011, 0, 5, 0, 0, 1)),
      equals(local(2011, 0, 5)),
    );
  });

  test('timeWednesday.count(start, end) counts Wednesdays after start '
      '(exclusive) and before end (inclusive)', () {
    expect(timeWednesday.count(local(2012), local(2012, 0, 3)), 0);
    expect(timeWednesday.count(local(2012), local(2012, 0, 4)), 1);
    expect(timeWednesday.count(local(2012), local(2012, 0, 5)), 1);
    expect(timeWednesday.count(local(2012), local(2012, 0, 11)), 2);

    expect(timeWednesday.count(local(2014), local(2014, 0, 7)), 0);
    expect(timeWednesday.count(local(2014), local(2014, 0, 8)), 1);
    expect(timeWednesday.count(local(2014), local(2014, 0, 9)), 1);
  });

  test('timeWednesday.count(start, end) observes daylight saving', () {
    expect(timeWednesday.count(local(2011), local(2011, 2, 13, 1)), 10);
    expect(timeWednesday.count(local(2011), local(2011, 2, 13, 3)), 10);
    expect(timeWednesday.count(local(2011), local(2011, 2, 13, 4)), 10);
    expect(timeWednesday.count(local(2011), local(2011, 10, 6)), 44);
    expect(timeWednesday.count(local(2011), local(2011, 10, 6, 1)), 44);
    expect(timeWednesday.count(local(2011), local(2011, 10, 6, 2)), 44);
  });
}
