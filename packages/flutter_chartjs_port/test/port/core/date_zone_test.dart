// Original code, not ported from Chart.js: the date zone tests.
import 'dart:math' as math;

import 'package:flutter_chartjs_port/src/core/date_calendar.dart';
import 'package:flutter_chartjs_port/src/core/date_zone.dart';
import 'package:test/test.dart';

import 'date_adapter_reference.dart';
import 'date_table_zone.dart';

// The zones of the default date adapter (Chart.js ADR 0024, decision 3).
//
// The group 'LocalZone on a table' runs the code of LocalZone on the offset
// changes of the reference zones (LocalZone.withOffsets). Thus the cache
// rule and the gap and overlap rules of fromWall run on each machine and
// each compiler.
//
// The group 'LocalZone' runs in the zone of the machine: on the VM the zone
// of the process, in Chrome the zone of the browser. The runners of CI run
// in UTC, which has no offset change. There, the test of the offset changes
// is skipped, and the other tests check the offset 0 only. Run the file with
// TZ=America/New_York (or another zone with offset changes) to check the
// offsets of the platform.

/// One day in ms.
const int _day = 86400000;

/// Whether the test runs on the web (dart2js, DDC or dart2wasm).
const bool _onWeb = bool.fromEnvironment('dart.library.js_interop');

/// The offset of the instant [t] from the local fields of `DateTime`, as
/// the platform gives them. `daysFromCivil` has its own test in
/// date_calendar_test.dart.
int _platformOffset(int t) {
  final local = DateTime.fromMillisecondsSinceEpoch(t);
  return daysFromCivil(local.year, local.month, local.day) * _day +
      local.hour * 3600000 +
      local.minute * 60000 +
      local.second * 1000 +
      local.millisecond -
      t;
}

/// The instant of the wall time [wall] from the local `DateTime`
/// constructor.
int _platformInstant(int wall) {
  final fields = DateTime.fromMillisecondsSinceEpoch(wall, isUtc: true);
  return DateTime(
    fields.year,
    fields.month,
    fields.day,
    fields.hour,
    fields.minute,
    fields.second,
    fields.millisecond,
  ).millisecondsSinceEpoch;
}

/// The instants of the offset changes of the platform from [from] to [to]:
/// a scan by day, then a search to the millisecond.
List<int> _platformChanges(int from, int to) {
  final changes = <int>[];
  var previous = _platformOffset(from);
  for (var t = from + _day; t <= to; t += _day) {
    final offset = _platformOffset(t);
    if (offset == previous) continue;
    var low = t - _day;
    var high = t;
    while (high - low > 1) {
      final middle = low + (high - low) ~/ 2;
      if (_platformOffset(middle) == previous) {
        low = middle;
      } else {
        high = middle;
      }
    }
    changes.add(high);
    previous = offset;
  }
  return changes;
}

void main() {
  group('table zone', () {
    for (final reference in dateReferenceZones) {
      test('${reference.name}: fromWall follows the rule of JS Date', () {
        final zone = TableZone.of(reference);
        final mismatches = <String>[];
        for (var i = 0; i < reference.walls.length; i++) {
          final got = zone.fromWall(reference.walls[i]);
          if (got != reference.wallInstants[i]) {
            mismatches.add(
              '${reference.walls[i]}: $got, expected '
              '${reference.wallInstants[i]}',
            );
          }
        }
        expect(mismatches, isEmpty);
      });

      test('${reference.name}: offsetAt around each change', () {
        final zone = TableZone.of(reference);
        expect(
          zone.offsetAt(reference.changes.first - 1),
          reference.initialOffset,
        );
        for (var i = 0; i < reference.changes.length; i++) {
          final change = reference.changes[i];
          expect(zone.offsetAt(change), reference.offsets[i]);
          expect(zone.offsetAt(change + _day ~/ 2), reference.offsets[i]);
          expect(
            zone.offsetAt(change - 1),
            i == 0 ? reference.initialOffset : reference.offsets[i - 1],
          );
        }
      });
    }

    test('Pacific/Apia skips 2011-12-30', () {
      final apia = TableZone.of(
        dateReferenceZones.firstWhere((z) => z.name == 'Pacific/Apia'),
      );
      final noon = DateTime.utc(2011, 12, 30, 12).millisecondsSinceEpoch;
      // The offset before the change (-10:00).
      expect(apia.fromWall(noon), noon + 10 * 3600000);
    });
  });

  group('LocalZone on a table', () {
    final from = DateTime.utc(1902).millisecondsSinceEpoch;
    final to = DateTime.utc(2037, 12, 31).millisecondsSinceEpoch;
    final tables = [
      for (final reference in dateReferenceZones)
        (reference.name, TableZone.of(reference)),
      for (final reference in dateReferenceHour24Zones)
        (
          '${reference.name} (hour 24)',
          TableZone(
            reference.initialOffset,
            reference.changes,
            reference.offsets,
          ),
        ),
    ];
    for (final (name, table) in tables) {
      test('$name: offsetAt and fromWall around each offset change', () {
        final zone = LocalZone.withOffsets(table.offsetAt);
        final mismatches = <String>[];
        for (var i = 0; i < table.changes.length; i++) {
          final change = table.changes[i];
          for (final step in [-_day, -3600000, -60000, -1, 0, 1, 60000]) {
            final t = change + step;
            final got = zone.offsetAt(t);
            final expected = table.offsetAt(t);
            if (got != expected) {
              mismatches.add('offsetAt($t): $got, expected $expected');
            }
          }
          final before = i == 0 ? table.initialOffset : table.offsets[i - 1];
          for (var k = -8; k <= 8; k++) {
            final wall = change + before + k * 15 * 60000;
            final got = zone.fromWall(wall);
            final expected = table.fromWall(wall);
            if (got != expected) {
              mismatches.add('fromWall($wall): $got, expected $expected');
            }
          }
        }
        expect(mismatches, isEmpty);
      });

      test('$name: offsetAt and fromWall at 20,000 random instants', () {
        final zone = LocalZone.withOffsets(table.offsetAt);
        final random = math.Random(24);
        final instants = [
          for (var i = 0; i < 20000; i++)
            from + (random.nextDouble() * (to - from)).floor(),
        ];
        final mismatches = <String>[];
        void check(List<int> list) {
          for (final t in list) {
            final got = zone.offsetAt(t);
            final expected = table.offsetAt(t);
            if (got != expected) {
              mismatches.add('offsetAt($t): $got, expected $expected');
            }
            final wall = t + expected;
            final instant = zone.fromWall(wall);
            if (instant != table.fromWall(wall)) {
              mismatches.add('fromWall($wall): $instant');
            }
          }
        }

        check(instants..sort());
        zone.clear();
        check(instants..shuffle(random));
        expect(mismatches, isEmpty);
      });
    }

    test('the reference zones have offset changes', () {
      for (final (name, table) in tables) {
        expect(table.changes, isNotEmpty, reason: name);
      }
    });

    // Chart.js ADR 0110: up to 64 cached intervals, each from the 1-day
    // rule or a union of two touching intervals of one offset.
    group('cached intervals', () {
      /// A zone with a summer offset of +1 h from [summer] to [winter]: the
      /// two changes of a year with daylight saving time.
      final summer = DateTime.utc(2021, 3, 28, 1).millisecondsSinceEpoch;
      final winter = DateTime.utc(2021, 10, 31, 1).millisecondsSinceEpoch;
      final table = TableZone(3600000, [summer, winter], [7200000, 3600000]);

      /// A zone over [table] that counts the reads of an offset.
      (LocalZone, int Function()) counted() {
        var reads = 0;
        final zone = LocalZone.withOffsets((t) {
          reads++;
          return table.offsetAt(t);
        });
        return (zone, () => reads);
      }

      test('a second pass over the same instants reads no offset', () {
        final (zone, reads) = counted();
        // The middle of each month of 2021: the ticks of a time scale, each
        // more than 2 days from an offset change.
        final ticks = [
          for (var m = 1; m <= 12; m++)
            DateTime.utc(2021, m, 15).millisecondsSinceEpoch,
        ];
        final offsets = [for (final t in ticks) zone.offsetAt(t)];
        expect(offsets, [for (final t in ticks) table.offsetAt(t)]);
        final first = reads();
        expect(first, 36);
        expect(zone.cachedIntervals, hasLength(12));
        // The label pass: the same instants, also in reverse order.
        expect([for (final t in ticks) zone.offsetAt(t)], offsets);
        expect([
          for (final t in ticks.reversed) zone.offsetAt(t),
        ], offsets.reversed);
        expect(reads(), first);
      });

      test('two touching intervals of one offset join', () {
        final (zone, _) = counted();
        final t = DateTime.utc(2021, 1, 15).millisecondsSinceEpoch;
        zone.offsetAt(t);
        expect(zone.cachedIntervals, [
          (first: t - _day, last: t + _day, offset: 3600000),
        ]);
        zone.offsetAt(t + 2 * _day + 1);
        expect(zone.cachedIntervals, [
          (first: t - _day, last: t + 3 * _day + 1, offset: 3600000),
        ]);
        // An interval that does not touch takes its own slot.
        zone.offsetAt(t + 5 * _day);
        expect(zone.cachedIntervals, hasLength(2));
      });

      test('no interval joins across an offset change', () {
        final (zone, _) = counted();
        final january = DateTime.utc(2021, 1, 15).millisecondsSinceEpoch;
        final december = DateTime.utc(2021, 12, 15).millisecondsSinceEpoch;
        expect(zone.offsetAt(january), 3600000);
        expect(zone.offsetAt(december), 3600000);
        expect(zone.cachedIntervals, hasLength(2));
        // The summer between two cached winter intervals.
        final july = DateTime.utc(2021, 7, 15).millisecondsSinceEpoch;
        expect(zone.offsetAt(july), 7200000);
        for (final t in [summer - 1, summer, winter - 1, winter, july]) {
          expect(zone.offsetAt(t), table.offsetAt(t), reason: '$t');
        }
        // No cached interval holds an instant of another offset.
        for (final interval in zone.cachedIntervals) {
          expect(table.offsetAt(interval.first), interval.offset);
          expect(table.offsetAt(interval.last), interval.offset);
          expect(
            table.changes.every(
              (c) => c <= interval.first || c > interval.last,
            ),
            isTrue,
            reason: '$interval',
          );
        }
      });

      test('more instants than slots replace the oldest interval', () {
        final (zone, reads) = counted();
        final days = [
          for (var i = 0; i < 80; i++)
            DateTime.utc(2021, 1, 1 + 4 * i).millisecondsSinceEpoch,
        ];
        for (final t in days) {
          expect(zone.offsetAt(t), table.offsetAt(t), reason: '$t');
        }
        final intervals = zone.cachedIntervals;
        expect(intervals, hasLength(64));
        // The newest intervals stay: the last day reads no offset.
        final before = reads();
        expect(zone.offsetAt(days.last), table.offsetAt(days.last));
        expect(reads(), before);
        // A second pass gives the table offsets again.
        for (final t in days) {
          expect(zone.offsetAt(t), table.offsetAt(t), reason: '$t');
        }
        zone.clear();
        expect(zone.cachedIntervals, isEmpty);
        expect(zone.offsetAt(days.first), table.offsetAt(days.first));
      });
    });
  });

  group('LocalZone', () {
    final zone = LocalZone.instance;
    setUp(zone.clear);

    final from = DateTime.utc(1902).millisecondsSinceEpoch;
    final to = DateTime.utc(2037, 12, 31).millisecondsSinceEpoch;
    final changes = _platformChanges(from, to);

    test(
      'offsetAt and fromWall around each offset change of 1902-2037',
      () {
        final mismatches = <String>[];
        for (final change in changes) {
          for (final step in [
            -_day,
            -3600000,
            -60000,
            -1,
            0,
            1,
            60000,
            3600000,
          ]) {
            final t = change + step;
            final got = zone.offsetAt(t);
            final expected = _platformOffset(t);
            if (got != expected) {
              mismatches.add('offsetAt($t): $got, $expected');
            }
          }
          final before = _platformOffset(change - 1);
          for (var k = -8; k <= 8; k++) {
            final wall = change + before + k * 15 * 60000;
            final got = zone.fromWall(wall);
            final expected = _platformInstant(wall);
            if (got != expected) {
              mismatches.add('fromWall($wall): $got, $expected');
            }
          }
        }
        expect(mismatches, isEmpty);
      },
      skip: changes.isEmpty
          ? 'the zone of the machine has no offset change in 1902-2037: '
                'run with TZ=America/New_York'
          : false,
    );

    test('offsetAt and fromWall at 20,000 random instants', () {
      final random = math.Random(24);
      final instants = [
        for (var i = 0; i < 20000; i++)
          from + (random.nextDouble() * (to - from)).floor(),
      ];
      final mismatches = <String>[];
      void check(List<int> list) {
        for (final t in list) {
          final got = zone.offsetAt(t);
          final expected = _platformOffset(t);
          if (got != expected) mismatches.add('offsetAt($t): $got, $expected');
          final wall = t + expected;
          final instant = zone.fromWall(wall);
          if (instant != _platformInstant(wall)) {
            mismatches.add('fromWall($wall): $instant');
          }
        }
      }

      check(instants..sort());
      zone.clear();
      check(instants..shuffle(random));
      expect(mismatches, isEmpty);
    });

    test('keeps the intervals of the 1-day rule', () {
      final t = DateTime.utc(2015, 1, 15).millisecondsSinceEpoch;
      expect(zone.cachedIntervals, isEmpty);
      final offset = zone.offsetAt(t);
      final intervals = zone.cachedIntervals;
      if (changes.every((c) => (c - t).abs() > 2 * _day)) {
        expect(intervals, [(first: t - _day, last: t + _day, offset: offset)]);
        zone.offsetAt(t + _day + 1);
        expect(zone.cachedIntervals.single.last, t + 2 * _day + 1);
      }
      zone.clear();
      expect(zone.cachedIntervals, isEmpty);
    });

    // Chart.js ADR 0110: the VM reads timeZoneOffset in place of the local
    // fields. Both come from the same offset in whole seconds. The web keeps
    // the local fields: dart2js gives timeZoneOffset in whole minutes.
    test('timeZoneOffset gives the offset of the local fields on the VM', () {
      const max = 8640000000000000;
      final random = math.Random(110);
      final instants = <int>[
        -max,
        max,
        -max + 1,
        max - 1,
        0,
        -1,
        for (final change in changes) ...[change - 1, change, change + 1],
        for (var i = 0; i < 20000; i++)
          from + (random.nextDouble() * (to - from)).floor(),
        // Outside ±2^31 s, where the VM takes a substitute year.
        for (var i = 0; i < 5000; i++)
          ((random.nextDouble() * 2 - 1) * max).truncate(),
      ];
      final mismatches = <String>[];
      for (final t in instants) {
        final offset = DateTime.fromMillisecondsSinceEpoch(t)
            .timeZoneOffset
            .inMilliseconds;
        if (offset != _platformOffset(t)) {
          mismatches.add('$t: $offset, ${_platformOffset(t)}');
        }
        zone.clear();
        if (zone.offsetAt(t) != _platformOffset(t)) {
          mismatches.add('offsetAt($t): ${zone.offsetAt(t)}');
        }
      }
      expect(mismatches, isEmpty);
    }, skip: _onWeb ? 'the web keeps the local fields' : false);

    test('reads the instants outside the range of a Date at the ends', () {
      const max = 8640000000000000;
      expect(zone.offsetAt(max + _day), _platformOffset(max));
      expect(zone.offsetAt(-max - _day), _platformOffset(-max));
    });
  });

  group('wholeMinuteOffset', () {
    test('is 0 in UTC', () {
      expect(wholeMinuteOffset(null, 1420142400000), 0);
    });

    test('truncates the seconds toward zero', () {
      // Tehran in 1910: +3:25:44 gives +3:25:00.
      final tehran = TableZone(12344000, const [], const []);
      expect(wholeMinuteOffset(tehran, 0), 12300000);
      // New York before 1883: -4:56:02 gives -4:56:00.
      final newYork = TableZone(-17762000, const [], const []);
      expect(wholeMinuteOffset(newYork, 0), -17760000);
    });
  });
}
