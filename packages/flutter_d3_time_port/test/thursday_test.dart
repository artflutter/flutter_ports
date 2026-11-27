// Ported from d3-time v3.1.0 test/thursday-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('timeThursdays in an alias for timeThursday.range', () {
    expect(timeThursdays, equals(timeThursday.range));
  });

  test('timeThursday.floor(date) returns Thursdays', () {
    expect(
      timeThursday.floor(local(2011, 0, 4, 23, 59, 59)),
      equals(local(2010, 11, 30)),
    );
    expect(timeThursday.floor(local(2011, 0, 5)), equals(local(2010, 11, 30)));
    expect(
      timeThursday.floor(local(2011, 0, 5, 0, 0, 1)),
      equals(local(2010, 11, 30)),
    );
    expect(
      timeThursday.floor(local(2011, 0, 5, 23, 59, 59)),
      equals(local(2010, 11, 30)),
    );
    expect(timeThursday.floor(local(2011, 0, 6)), equals(local(2011, 0, 6)));
    expect(
      timeThursday.floor(local(2011, 0, 6, 0, 0, 1)),
      equals(local(2011, 0, 6)),
    );
  });

  test(
    'timeThursday.count(start, end) counts Thursdays after start (exclusive) '
    'and before end (inclusive)',
    () {
      expect(timeThursday.count(local(2012), local(2012, 0, 4)), 0);
      expect(timeThursday.count(local(2012), local(2012, 0, 5)), 1);
      expect(timeThursday.count(local(2012), local(2012, 0, 6)), 1);
      expect(timeThursday.count(local(2012), local(2012, 0, 12)), 2);

      expect(timeThursday.count(local(2015), local(2015, 0, 7)), 0);
      expect(timeThursday.count(local(2015), local(2015, 0, 8)), 1);
      expect(timeThursday.count(local(2015), local(2015, 0, 9)), 1);
    },
  );

  test('timeThursday.count(start, end) observes daylight saving', () {
    expect(timeThursday.count(local(2011), local(2011, 2, 13, 1)), 10);
    expect(timeThursday.count(local(2011), local(2011, 2, 13, 3)), 10);
    expect(timeThursday.count(local(2011), local(2011, 2, 13, 4)), 10);
    expect(timeThursday.count(local(2011), local(2011, 10, 6)), 44);
    expect(timeThursday.count(local(2011), local(2011, 10, 6, 1)), 44);
    expect(timeThursday.count(local(2011), local(2011, 10, 6, 2)), 44);
  });
}
