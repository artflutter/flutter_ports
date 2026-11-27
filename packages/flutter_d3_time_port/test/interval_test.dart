// Ported from d3-time v3.1.0 test/interval-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('timeInterval() is equivalent to timeInterval.floor(new Date)', () {
    final t = DateTime.now();
    expect(timeYear(), equals(timeYear.floor(t)));
  });

  test('timeInterval(date) is equivalent to timeInterval.floor(date)', () {
    final t = DateTime.now();
    expect(timeYear(t), equals(timeYear.floor(t)));
  });

  test('timeInterval(floor, offset) returns a custom time interval', () {
    final i = timeInterval(
      (date) {
        final d = date.toUtc();
        return DateTime.utc(d.year, d.month, d.day, d.hour);
      },
      (date, step) {
        final d = date.toUtc();
        return DateTime.utc(
          d.year,
          d.month,
          d.day,
          d.hour + step,
          d.minute,
          d.second,
          d.millisecond,
        );
      },
    );
    expect(i(utc(2015, 0, 1, 12, 34, 56, 789)), equals(utc(2015, 0, 1, 12)));
  });

  test('timeInterval(floor, offset) does not define a count method', () {
    final i = timeInterval(
      (date) {
        final d = date.toUtc();
        return DateTime.utc(d.year, d.month, d.day, d.hour);
      },
      (date, step) {
        final d = date.toUtc();
        return DateTime.utc(
          d.year,
          d.month,
          d.day,
          d.hour + step,
          d.minute,
          d.second,
          d.millisecond,
        );
      },
    );
    expect(i, isNot(isA<CountableTimeInterval>()));
  });

  test(
    'timeInterval(floor, offset) floors the step before passing it to offset',
    () {
      final steps = <int>[];
      final i = timeInterval(
        (date) {
          final d = date.toUtc();
          return DateTime.utc(d.year, d.month, d.day, d.hour);
        },
        (date, step) {
          steps.add(step);
          final d = date.toUtc();
          return DateTime.utc(
            d.year,
            d.month,
            d.day,
            d.hour + step,
            d.minute,
            d.second,
            d.millisecond,
          );
        },
      );
      expect(
        i.offset(utc(2015, 0, 1, 12, 34, 56, 789)),
        equals(utc(2015, 0, 1, 13, 34, 56, 789)),
      );
      expect(
        i.range(utc(2015, 0, 1, 12), utc(2015, 0, 1, 15)),
        equals([utc(2015, 0, 1, 12), utc(2015, 0, 1, 13), utc(2015, 0, 1, 14)]),
      );
      expect(steps.every((step) => step == 1), isTrue);
    },
  );

  test('timeInterval(floor, offset, count) defines a count method', () {
    final i = countableTimeInterval(
      (date) {
        final d = date.toUtc();
        return DateTime.utc(d.year, d.month, d.day, d.hour);
      },
      (date, step) {
        final d = date.toUtc();
        return DateTime.utc(
          d.year,
          d.month,
          d.day,
          d.hour + step,
          d.minute,
          d.second,
          d.millisecond,
        );
      },
      (start, end) =>
          (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) / 36e5,
    );
    expect(i.count(utc(2015, 0, 1, 12, 34), utc(2015, 0, 1, 15, 56)), 3);
  });

  test('timeInterval(floor, offset, count) floors dates before passing them '
      'to count', () {
    final dates = <DateTime>[];
    countableTimeInterval(
      (date) {
        final d = date.toUtc();
        return DateTime.utc(d.year, d.month, d.day, d.hour);
      },
      (date, step) {
        final d = date.toUtc();
        return DateTime.utc(
          d.year,
          d.month,
          d.day,
          d.hour + step,
          d.minute,
          d.second,
          d.millisecond,
        );
      },
      (start, end) {
        dates.addAll([start, end]);
        return (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) /
            36e5;
      },
    ).count(utc(2015, 0, 1, 12, 34), utc(2015, 0, 1, 15, 56));
    expect(dates, equals([utc(2015, 0, 1, 12), utc(2015, 0, 1, 15)]));
  });

  test('timeInterval.every(step) returns null if step is invalid', () {
    expect(timeMinute.every(0), isNull);
    expect(timeHour.every(-1), isNull);
    expect(timeDay.every(-10), isNull);
  });

  test('timeInterval.every(step) returns interval if step is one', () {
    expect(identical(timeDay.every(1), timeDay), isTrue);
    expect(identical(timeMinute.every(1), timeMinute), isTrue);
    expect(identical(timeSecond.every(1), timeSecond), isTrue);
  });

  test(
    'timeInterval.every(step).range(invalid, invalid) returns the empty array',
    () {
      expect(timeMinute.every(15)!.range(local(2015), local(2015)), isEmpty);
    },
    skip: 'diverges: adapt-time-typed-api (Dart DateTime cannot hold NaN)',
  );

  test('timeInterval.every(…).offset(date, step) returns the expected value '
      'when step is positive', () {
    final i = timeMinute.every(15)!;
    expect(
      i.offset(local(2015, 0, 1, 12, 34), 0),
      equals(local(2015, 0, 1, 12, 34)),
    );
    expect(
      i.offset(local(2015, 0, 1, 12, 34)),
      equals(local(2015, 0, 1, 12, 45)),
    );
    expect(
      i.offset(local(2015, 0, 1, 12, 34), 2),
      equals(local(2015, 0, 1, 13)),
    );
    expect(
      i.offset(local(2015, 0, 1, 12, 34), 3),
      equals(local(2015, 0, 1, 13, 15)),
    );
    expect(
      i.offset(local(2015, 0, 1, 12, 34), 4),
      equals(local(2015, 0, 1, 13, 30)),
    );
    expect(
      i.offset(local(2015, 0, 1, 12, 34), 5),
      equals(local(2015, 0, 1, 13, 45)),
    );
  });

  test('timeInterval.every(…).offset(date, step) returns the expected value '
      'when step is negative', () {
    final i = timeMinute.every(15)!;
    expect(
      i.offset(local(2015, 0, 1, 12, 34), -1),
      equals(local(2015, 0, 1, 12, 30)),
    );
    expect(
      i.offset(local(2015, 0, 1, 12, 34), -2),
      equals(local(2015, 0, 1, 12, 15)),
    );
    expect(
      i.offset(local(2015, 0, 1, 12, 34), -3),
      equals(local(2015, 0, 1, 12)),
    );
  });

  test(
    'timeInterval.every(…).offset(date, step) returns the expected value '
    'when step is not an integer',
    () {},
    skip:
        'diverges: adapt-time-typed-api (offset step is statically typed int)',
  );
}
