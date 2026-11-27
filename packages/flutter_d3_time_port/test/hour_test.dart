// Ported from d3-time v3.1.0 test/hour-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('timeHour.floor(date) returns hours', () {
    expect(
      timeHour.floor(local(2010, 11, 31, 23, 59)),
      equals(local(2010, 11, 31, 23)),
    );
    expect(timeHour.floor(local(2011)), equals(local(2011)));
    expect(timeHour.floor(local(2011, 0, 1, 0, 1)), equals(local(2011)));
  });

  // DIVERGES(d3-time): platform-time-tz-tests, checks exact LA assertions when
  // host TZ is America/Los_Angeles and equivalent host-TZ hour-floor invariants
  // on other timezones.
  test('timeHour.floor(date) observes start of daylight savings time', () {
    if (isWholeHourTimeZone) {
      expect(
        timeHour.floor(utc(2011, 2, 13, 8, 59)),
        sameInstant(utc(2011, 2, 13, 8)),
      );
      expect(
        timeHour.floor(utc(2011, 2, 13, 9)),
        sameInstant(utc(2011, 2, 13, 9)),
      );
      expect(
        timeHour.floor(utc(2011, 2, 13, 9, 1)),
        sameInstant(utc(2011, 2, 13, 9)),
      );
      expect(
        timeHour.floor(utc(2011, 2, 13, 9, 59)),
        sameInstant(utc(2011, 2, 13, 9)),
      );
      expect(
        timeHour.floor(utc(2011, 2, 13, 10)),
        sameInstant(utc(2011, 2, 13, 10)),
      );
      expect(
        timeHour.floor(utc(2011, 2, 13, 10, 1)),
        sameInstant(utc(2011, 2, 13, 10)),
      );
    } else {
      for (final m in [0, 1, 30, 59]) {
        final d = utc(2011, 2, 13, 9, m).toLocal();
        final f = timeHour.floor(d);
        expect(f.minute, 0);
        expect(f.second, 0);
        expect(f.millisecond, 0);
      }
    }
  });

  test('timeHour.floor(date) observes end of daylight savings time', () {
    if (isWholeHourTimeZone) {
      expect(
        timeHour.floor(utc(2011, 10, 6, 7, 59)),
        sameInstant(utc(2011, 10, 6, 7)),
      );
      expect(
        timeHour.floor(utc(2011, 10, 6, 8)),
        sameInstant(utc(2011, 10, 6, 8)),
      );
      expect(
        timeHour.floor(utc(2011, 10, 6, 8, 1)),
        sameInstant(utc(2011, 10, 6, 8)),
      );
      expect(
        timeHour.floor(utc(2011, 10, 6, 8, 59)),
        sameInstant(utc(2011, 10, 6, 8)),
      );
      expect(
        timeHour.floor(utc(2011, 10, 6, 9)),
        sameInstant(utc(2011, 10, 6, 9)),
      );
      expect(
        timeHour.floor(utc(2011, 10, 6, 9, 1)),
        sameInstant(utc(2011, 10, 6, 9)),
      );
    } else {
      for (final m in [0, 1, 30, 59]) {
        final d = utc(2011, 10, 6, 8, m).toLocal();
        final f = timeHour.floor(d);
        expect(f.minute, 0);
        expect(f.second, 0);
        expect(f.millisecond, 0);
      }
    }
  });

  test('timeHour.ceil(date) returns hours', () {
    expect(timeHour.ceil(local(2010, 11, 31, 23, 59)), equals(local(2011)));
    expect(timeHour.ceil(local(2011)), equals(local(2011)));
    expect(
      timeHour.ceil(local(2011, 0, 1, 0, 1)),
      equals(local(2011, 0, 1, 1)),
    );
  });

  test('timeHour.ceil(date) observes start of daylight savings time', () {
    if (isWholeHourTimeZone) {
      expect(
        timeHour.ceil(utc(2011, 2, 13, 8, 59)),
        sameInstant(utc(2011, 2, 13, 9)),
      );
      expect(
        timeHour.ceil(utc(2011, 2, 13, 9)),
        sameInstant(utc(2011, 2, 13, 9)),
      );
      expect(
        timeHour.ceil(utc(2011, 2, 13, 9, 1)),
        sameInstant(utc(2011, 2, 13, 10)),
      );
      expect(
        timeHour.ceil(utc(2011, 2, 13, 9, 59)),
        sameInstant(utc(2011, 2, 13, 10)),
      );
      expect(
        timeHour.ceil(utc(2011, 2, 13, 10)),
        sameInstant(utc(2011, 2, 13, 10)),
      );
      expect(
        timeHour.ceil(utc(2011, 2, 13, 10, 1)),
        sameInstant(utc(2011, 2, 13, 11)),
      );
    } else {
      for (final m in [0, 1, 30, 59]) {
        final d = utc(2011, 2, 13, 9, m).toLocal();
        final c = timeHour.ceil(d);
        expect(c.minute, 0);
        expect(c.millisecondsSinceEpoch >= d.millisecondsSinceEpoch, isTrue);
      }
    }
  });

  test('timeHour.ceil(date) observes end of daylight savings time', () {
    if (isWholeHourTimeZone) {
      expect(
        timeHour.ceil(utc(2011, 10, 6, 7, 59)),
        sameInstant(utc(2011, 10, 6, 8)),
      );
      expect(
        timeHour.ceil(utc(2011, 10, 6, 8)),
        sameInstant(utc(2011, 10, 6, 8)),
      );
      expect(
        timeHour.ceil(utc(2011, 10, 6, 8, 1)),
        sameInstant(utc(2011, 10, 6, 9)),
      );
      expect(
        timeHour.ceil(utc(2011, 10, 6, 8, 59)),
        sameInstant(utc(2011, 10, 6, 9)),
      );
      expect(
        timeHour.ceil(utc(2011, 10, 6, 9)),
        sameInstant(utc(2011, 10, 6, 9)),
      );
      expect(
        timeHour.ceil(utc(2011, 10, 6, 9, 1)),
        sameInstant(utc(2011, 10, 6, 10)),
      );
    } else {
      for (final m in [0, 1, 30, 59]) {
        final d = utc(2011, 10, 6, 8, m).toLocal();
        final c = timeHour.ceil(d);
        expect(c.minute, 0);
        expect(c.millisecondsSinceEpoch >= d.millisecondsSinceEpoch, isTrue);
      }
    }
  });

  test('timeHour.offset(date) does not modify the passed-in date', () {
    final d = local(2010, 11, 31, 23, 59, 59, 999);
    timeHour.offset(d);
    expect(d, equals(local(2010, 11, 31, 23, 59, 59, 999)));
  });

  test('timeHour.offset(date) does not round the passed-in-date', () {
    expect(
      timeHour.offset(local(2010, 11, 31, 23, 59, 59, 999)),
      equals(local(2011, 0, 1, 0, 59, 59, 999)),
    );
    expect(
      timeHour.offset(local(2010, 11, 31, 23, 59, 59, 456), -2),
      equals(local(2010, 11, 31, 21, 59, 59, 456)),
    );
  });

  test('timeHour.offset(date) allows negative offsets', () {
    expect(
      timeHour.offset(local(2010, 11, 31, 12), -1),
      equals(local(2010, 11, 31, 11)),
    );
    expect(
      timeHour.offset(local(2011, 0, 1, 1), -2),
      equals(local(2010, 11, 31, 23)),
    );
    expect(timeHour.offset(local(2011), -1), equals(local(2010, 11, 31, 23)));
  });

  test('timeHour.offset(date) allows positive offsets', () {
    expect(
      timeHour.offset(local(2010, 11, 31, 11)),
      equals(local(2010, 11, 31, 12)),
    );
    expect(
      timeHour.offset(local(2010, 11, 31, 23), 2),
      equals(local(2011, 0, 1, 1)),
    );
    expect(timeHour.offset(local(2010, 11, 31, 23)), equals(local(2011)));
  });

  test('timeHour.offset(date) allows zero offset', () {
    expect(
      timeHour.offset(local(2010, 11, 31, 23, 59, 59, 999), 0),
      equals(local(2010, 11, 31, 23, 59, 59, 999)),
    );
    expect(
      timeHour.offset(local(2010, 11, 31, 23, 59, 58), 0),
      equals(local(2010, 11, 31, 23, 59, 58)),
    );
  });

  test('timeHour.range(start, stop) returns hours', () {
    expect(
      timeHour.range(local(2010, 11, 31, 12, 30), local(2010, 11, 31, 15, 30)),
      equals([
        local(2010, 11, 31, 13),
        local(2010, 11, 31, 14),
        local(2010, 11, 31, 15),
      ]),
    );
  });

  test('timeHour.range(start, stop) has an inclusive lower bound', () {
    expect(
      timeHour.range(local(2010, 11, 31, 23), local(2011, 0, 1, 2))[0],
      equals(local(2010, 11, 31, 23)),
    );
  });

  test('timeHour.range(start, stop) has an exclusive upper bound', () {
    expect(
      timeHour.range(local(2010, 11, 31, 23), local(2011, 0, 1, 2))[2],
      equals(local(2011, 0, 1, 1)),
    );
  });

  test('timeHour.range(start, stop) can skip hours', () {
    expect(
      timeHour.range(local(2011, 1, 1, 1), local(2011, 1, 1, 13), 3),
      equals([
        local(2011, 1, 1, 1),
        local(2011, 1, 1, 4),
        local(2011, 1, 1, 7),
        local(2011, 1, 1, 10),
      ]),
    );
  });

  test(
    'timeHour.range(start, stop) observes start of daylight savings time',
    () {
      if (isAmericaLosAngeles) {
        expect(
          timeHour.range(local(2011, 2, 13, 1), local(2011, 2, 13, 5)),
          sameInstants([
            utc(2011, 2, 13, 9),
            utc(2011, 2, 13, 10),
            utc(2011, 2, 13, 11),
          ]),
        );
      } else {
        final start = local(2011, 2, 13, 1);
        final stop = local(2011, 2, 13, 5);
        final range = timeHour.range(start, stop);
        final expectedCount =
            (stop.millisecondsSinceEpoch - start.millisecondsSinceEpoch) ~/
            durationHour;
        expect(range, hasLength(expectedCount));
        for (var i = 0; i < range.length; ++i) {
          expect(
            range[i].millisecondsSinceEpoch,
            start.millisecondsSinceEpoch + i * durationHour,
          );
        }
      }
    },
  );

  test('timeHour.range(start, stop) observes end of daylight savings time', () {
    if (isAmericaLosAngeles) {
      expect(
        timeHour.range(local(2011, 10, 6), local(2011, 10, 6, 2)),
        sameInstants([
          utc(2011, 10, 6, 7),
          utc(2011, 10, 6, 8),
          utc(2011, 10, 6, 9),
        ]),
      );
    } else {
      final start = local(2011, 10, 6);
      final stop = local(2011, 10, 6, 2);
      final range = timeHour.range(start, stop);
      final expectedCount =
          (stop.millisecondsSinceEpoch - start.millisecondsSinceEpoch) ~/
          durationHour;
      expect(range, hasLength(expectedCount));
      for (var i = 0; i < range.length; ++i) {
        expect(
          range[i].millisecondsSinceEpoch,
          start.millisecondsSinceEpoch + i * durationHour,
        );
      }
    }
  });

  test(
    'timeHour.every(step) returns every stepth hour, starting with the first '
    'hour of the day',
    () {
      expect(
        timeHour
            .every(4)!
            .range(local(2008, 11, 30, 12, 47), local(2008, 11, 31, 13, 57)),
        equals([
          local(2008, 11, 30, 16),
          local(2008, 11, 30, 20),
          local(2008, 11, 31),
          local(2008, 11, 31, 4),
          local(2008, 11, 31, 8),
          local(2008, 11, 31, 12),
        ]),
      );
      expect(
        timeHour
            .every(12)!
            .range(local(2008, 11, 30, 12, 47), local(2008, 11, 31, 13, 57)),
        equals([local(2008, 11, 31), local(2008, 11, 31, 12)]),
      );
    },
  );

  test('timeHour.range(start, stop) returns every hour crossing the daylight '
      'savings boundary', () {
    if (isWholeHourTimeZone) {
      expect(
        timeHour.range(
          DateTime.fromMillisecondsSinceEpoch(1478422800000 - 2 * 3600000),
          DateTime.fromMillisecondsSinceEpoch(1478422800000 + 2 * 3600000),
        ),
        equals([
          DateTime.fromMillisecondsSinceEpoch(1478415600000),
          DateTime.fromMillisecondsSinceEpoch(1478419200000),
          DateTime.fromMillisecondsSinceEpoch(1478422800000),
          DateTime.fromMillisecondsSinceEpoch(1478426400000),
        ]),
      );
    } else {
      final range = timeHour.range(
        DateTime.fromMillisecondsSinceEpoch(1478422800000 - 2 * 3600000),
        DateTime.fromMillisecondsSinceEpoch(1478422800000 + 2 * 3600000),
      );
      expect(range, hasLength(4));
    }
  });
}
