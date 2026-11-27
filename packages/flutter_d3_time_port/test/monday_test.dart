// Ported from d3-time v3.1.0 test/monday-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('timeMondays in an alias for timeMonday.range', () {
    expect(timeMondays, equals(timeMonday.range));
  });

  test('timeMonday.floor(date) returns Mondays', () {
    expect(
      timeMonday.floor(local(2011, 0, 1, 23, 59, 59)),
      equals(local(2010, 11, 27)),
    );
    expect(timeMonday.floor(local(2011, 0, 2)), equals(local(2010, 11, 27)));
    expect(
      timeMonday.floor(local(2011, 0, 2, 0, 0, 1)),
      equals(local(2010, 11, 27)),
    );
    expect(
      timeMonday.floor(local(2011, 0, 2, 23, 59, 59)),
      equals(local(2010, 11, 27)),
    );
    expect(timeMonday.floor(local(2011, 0, 3)), equals(local(2011, 0, 3)));
    expect(
      timeMonday.floor(local(2011, 0, 3, 0, 0, 1)),
      equals(local(2011, 0, 3)),
    );
  });

  test('timeMonday.range(start, stop, step) returns every step Monday', () {
    expect(
      timeMonday.range(local(2011, 11), local(2012, 0, 15), 2),
      equals([local(2011, 11, 5), local(2011, 11, 19), local(2012, 0, 2)]),
    );
  });

  test(
    'timeMonday.count(start, end) counts Mondays after start (exclusive) and '
    'before end (inclusive)',
    () {
      expect(timeMonday.count(local(2014), local(2014, 0, 5)), 0);
      expect(timeMonday.count(local(2014), local(2014, 0, 6)), 1);
      expect(timeMonday.count(local(2014), local(2014, 0, 7)), 1);
      expect(timeMonday.count(local(2014), local(2014, 0, 13)), 2);

      expect(timeMonday.count(local(2018), local(2018, 0, 7)), 0);
      expect(timeMonday.count(local(2018), local(2018, 0, 8)), 1);
      expect(timeMonday.count(local(2018), local(2018, 0, 9)), 1);
    },
  );

  test('timeMonday.count(start, end) observes daylight saving', () {
    expect(timeMonday.count(local(2011), local(2011, 2, 13, 1)), 10);
    expect(timeMonday.count(local(2011), local(2011, 2, 13, 3)), 10);
    expect(timeMonday.count(local(2011), local(2011, 2, 13, 4)), 10);
    expect(timeMonday.count(local(2011), local(2011, 10, 6)), 44);
    expect(timeMonday.count(local(2011), local(2011, 10, 6, 1)), 44);
    expect(timeMonday.count(local(2011), local(2011, 10, 6, 2)), 44);
  });
}
