// Original code, not ported from Chart.js: the date zone tests.
import 'dart:math' as math;

import 'package:flutter_chartjs/src/core/date_calendar.dart';
import 'package:flutter_chartjs/src/core/date_zone.dart';
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

    test('keeps one interval of instants with one offset', () {
      final t = DateTime.utc(2015, 1, 15).millisecondsSinceEpoch;
      expect(zone.cachedInterval, isNull);
      final offset = zone.offsetAt(t);
      final interval = zone.cachedInterval;
      if (changes.every((c) => (c - t).abs() > 2 * _day)) {
        expect(interval, (first: t - _day, last: t + _day, offset: offset));
        zone.offsetAt(t + _day + 1);
        expect(zone.cachedInterval!.last, t + 2 * _day + 1);
      }
      zone.clear();
      expect(zone.cachedInterval, isNull);
    });

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
