// Original code, not ported from d3-time: faster-form twin tests.

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

/// Literal upstream interval constructors (calendar field based, no fast-path
/// overrides) used as oracle twins for verifying `adapt-time-fast-forms`.
CountableTimeInterval _literalUtcMinute() => countableTimeInterval(
  (date) {
    final d = date.isUtc ? date : date.toUtc();
    return DateTime.utc(d.year, d.month, d.day, d.hour, d.minute);
  },
  (date, step) => DateTime.fromMillisecondsSinceEpoch(
    date.millisecondsSinceEpoch + step * durationMinute,
    isUtc: true,
  ),
  (start, end) =>
      (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) /
      durationMinute,
  (date) => (date.isUtc ? date : date.toUtc()).minute,
);

CountableTimeInterval _literalUtcHour() => countableTimeInterval(
  (date) {
    final d = date.isUtc ? date : date.toUtc();
    return DateTime.utc(d.year, d.month, d.day, d.hour);
  },
  (date, step) => DateTime.fromMillisecondsSinceEpoch(
    date.millisecondsSinceEpoch + step * durationHour,
    isUtc: true,
  ),
  (start, end) =>
      (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) /
      durationHour,
  (date) => (date.isUtc ? date : date.toUtc()).hour,
);

CountableTimeInterval _literalUtcDay() => countableTimeInterval(
  (date) {
    final d = date.isUtc ? date : date.toUtc();
    return DateTime.utc(d.year, d.month, d.day);
  },
  (date, step) {
    final d = date.isUtc ? date : date.toUtc();
    return DateTime.utc(
      d.year,
      d.month,
      d.day + step,
      d.hour,
      d.minute,
      d.second,
      d.millisecond,
    );
  },
  (start, end) =>
      (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) / durationDay,
  (date) => (date.isUtc ? date : date.toUtc()).day - 1,
);

CountableTimeInterval _literalUnixDay() => countableTimeInterval(
  (date) {
    final d = date.isUtc ? date : date.toUtc();
    return DateTime.utc(d.year, d.month, d.day);
  },
  (date, step) {
    final d = date.isUtc ? date : date.toUtc();
    return DateTime.utc(
      d.year,
      d.month,
      d.day + step,
      d.hour,
      d.minute,
      d.second,
      d.millisecond,
    );
  },
  (start, end) =>
      (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) / durationDay,
  (date) => (date.millisecondsSinceEpoch / durationDay).floor(),
);

CountableTimeInterval _literalUtcWeekday(int i) => countableTimeInterval(
  (date) {
    final d = date.isUtc ? date : date.toUtc();
    return DateTime.utc(d.year, d.month, d.day - ((d.weekday % 7) + 7 - i) % 7);
  },
  (date, step) {
    final d = date.isUtc ? date : date.toUtc();
    return DateTime.utc(
      d.year,
      d.month,
      d.day + step * 7,
      d.hour,
      d.minute,
      d.second,
      d.millisecond,
    );
  },
  (start, end) =>
      (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) /
      durationWeek,
);

CountableTimeInterval _literalTimeDay() => countableTimeInterval(
  (date) {
    final d = date.isUtc ? date.toLocal() : date;
    return DateTime(d.year, d.month, d.day);
  },
  (date, step) {
    final d = date.isUtc ? date.toLocal() : date;
    return DateTime(
      d.year,
      d.month,
      d.day + step,
      d.hour,
      d.minute,
      d.second,
      d.millisecond,
    );
  },
  (start, end) =>
      (end.millisecondsSinceEpoch -
          start.millisecondsSinceEpoch +
          (end.timeZoneOffset.inMinutes - start.timeZoneOffset.inMinutes) *
              durationMinute) /
      durationDay,
  (date) => (date.isUtc ? date.toLocal() : date).day - 1,
);

CountableTimeInterval _literalUtcMonth() => countableTimeInterval(
  (date) {
    final d = date.isUtc ? date : date.toUtc();
    return DateTime.utc(d.year, d.month);
  },
  (date, step) {
    final d = date.isUtc ? date : date.toUtc();
    return DateTime.utc(
      d.year,
      d.month + step,
      d.day,
      d.hour,
      d.minute,
      d.second,
      d.millisecond,
    );
  },
  (start, end) => end.month - start.month + (end.year - start.year) * 12,
  (date) => (date.isUtc ? date : date.toUtc()).month - 1,
);

void _expectIntervalParity(
  String label,
  CountableTimeInterval fast,
  CountableTimeInterval literal,
  List<DateTime> dates, {
  List<int> everySteps = const [2, 3, 5, 15],
}) {
  for (final d in dates) {
    expect(fast.floor(d), equals(literal.floor(d)), reason: '$label.floor($d)');
    expect(fast.ceil(d), equals(literal.ceil(d)), reason: '$label.ceil($d)');
    expect(fast.round(d), equals(literal.round(d)), reason: '$label.round($d)');
    for (final s in const [-5, -1, 0, 1, 4]) {
      expect(
        fast.offset(d, s),
        equals(literal.offset(d, s)),
        reason: '$label.offset($d, $s)',
      );
    }
  }
  for (var i = 0; i < dates.length - 1; ++i) {
    final a = dates[i];
    final b = dates[i + 1];
    expect(
      fast.count(a, b),
      literal.count(a, b),
      reason: '$label.count($a, $b)',
    );
  }
  for (final k in everySteps) {
    final fe = fast.every(k)!;
    final le = literal.every(k)!;
    for (final d in dates) {
      expect(
        fe.floor(d),
        equals(le.floor(d)),
        reason: '$label.every($k).floor($d)',
      );
      expect(
        fe.ceil(d),
        equals(le.ceil(d)),
        reason: '$label.every($k).ceil($d)',
      );
      expect(
        fe.round(d),
        equals(le.round(d)),
        reason: '$label.every($k).round($d)',
      );
      for (final s in const [-3, -1, 0, 1, 3]) {
        expect(
          fe.offset(d, s),
          equals(le.offset(d, s)),
          reason: '$label.every($k).offset($d, $s)',
        );
      }
    }
  }
}

void main() {
  final utcSamples = <DateTime>[
    DateTime.utc(9, 11, 6, 7, 12, 34, 567),
    DateTime.utc(1969, 12, 28),
    DateTime.utc(1969, 12, 31, 23, 59, 59, 999),
    DateTime.utc(1970),
    DateTime.utc(1970, 1, 1, 0, 0, 0, 1),
    DateTime.utc(2000, 2, 29, 12, 30, 45, 500),
    DateTime.utc(2011, 3, 13, 8, 30),
    DateTime.utc(2011, 11, 6, 7, 45, 59, 999),
    DateTime.utc(2024),
    DateTime.utc(2024, 12, 31, 23, 59, 59, 999),
  ];

  test('fast UTC fixed-period intervals match literal twins', () {
    _expectIntervalParity(
      'utcMinute',
      utcMinute,
      _literalUtcMinute(),
      utcSamples,
      everySteps: const [2, 5, 7, 15, 30],
    );
    _expectIntervalParity(
      'utcHour',
      utcHour,
      _literalUtcHour(),
      utcSamples,
      everySteps: const [2, 3, 5, 6, 12],
    );
    _expectIntervalParity(
      'utcDay',
      utcDay,
      _literalUtcDay(),
      utcSamples,
      everySteps: const [2, 3, 5, 7],
    );
    _expectIntervalParity(
      'unixDay',
      unixDay,
      _literalUnixDay(),
      utcSamples,
      everySteps: const [2, 3, 5, 7],
    );
    final weekdays = [
      utcSunday,
      utcMonday,
      utcTuesday,
      utcWednesday,
      utcThursday,
      utcFriday,
      utcSaturday,
    ];
    for (var i = 0; i < 7; ++i) {
      _expectIntervalParity(
        'utcWeekday($i)',
        weekdays[i],
        _literalUtcWeekday(i),
        utcSamples,
        everySteps: const [2, 3, 4],
      );
    }
  });

  test('fast utcMonth and local timeDay match literal twins', () {
    _expectIntervalParity(
      'utcMonth',
      utcMonth,
      _literalUtcMonth(),
      utcSamples,
      everySteps: const [2, 3, 6],
    );
    final localSamples = <DateTime>[
      DateTime(2010, 12, 31, 23, 59, 59, 999),
      DateTime(2011),
      DateTime(2011, 3, 13, 1, 30),
      DateTime(2011, 3, 13, 12),
      DateTime(2011, 11, 6, 0, 30),
      DateTime(2011, 11, 6, 12),
      DateTime(2024, 2, 29),
      DateTime(2025),
    ];
    _expectIntervalParity(
      'timeDay',
      timeDay,
      _literalTimeDay(),
      localSamples,
      everySteps: const [2, 3, 5],
    );
    expect(
      timeDay.range(DateTime(2024), DateTime(2025)),
      equals(_literalTimeDay().range(DateTime(2024), DateTime(2025))),
    );
    expect(
      timeDay.range(DateTime(2024, 1, 1, 1), DateTime(2025, 1, 1, 1), 3),
      equals(
        _literalTimeDay().range(
          DateTime(2024, 1, 1, 1),
          DateTime(2025, 1, 1, 1),
          3,
        ),
      ),
    );
  });

  test('fast ranges match literal twins across step values', () {
    expect(
      utcDay.range(DateTime.utc(2023, 12, 28, 12), DateTime.utc(2024, 3, 5), 3),
      equals(
        _literalUtcDay().range(
          DateTime.utc(2023, 12, 28, 12),
          DateTime.utc(2024, 3, 5),
          3,
        ),
      ),
    );
    expect(
      utcSunday.every(2)!.range(DateTime.utc(2019, 12), DateTime.utc(2020, 6)),
      equals(
        _literalUtcWeekday(0)
            .every(2)!
            .range(DateTime.utc(2019, 12), DateTime.utc(2020, 6)),
      ),
    );
    expect(
      utcMonth.range(DateTime.utc(1968, 6, 15), DateTime.utc(1975), 2),
      equals(
        _literalUtcMonth().range(
          DateTime.utc(1968, 6, 15),
          DateTime.utc(1975),
          2,
        ),
      ),
    );
  });
}
