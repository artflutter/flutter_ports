// Original code, not ported from d3-time: subprocess timezone test worker.

import 'dart:io';

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';

void _assertEq(Object? actual, Object? expected, String label) {
  if (actual != expected) {
    stderr.writeln('FAIL [$label]: expected $expected, got $actual');
    exit(1);
  }
}

void _assertListEq(List<int> actual, List<int> expected, String label) {
  if (actual.length != expected.length) {
    stderr.writeln('FAIL [$label]: expected $expected, got $actual');
    exit(1);
  }
  for (var i = 0; i < actual.length; ++i) {
    if (actual[i] != expected[i]) {
      stderr.writeln('FAIL [$label]: expected $expected, got $actual');
      exit(1);
    }
  }
}

void main(List<String> args) {
  final tz = args.isNotEmpty ? args.first : (Platform.environment['TZ'] ?? '');
  switch (tz) {
    case 'Asia/Kolkata':
      _assertEq(
        timeHour
            .floor(DateTime.fromMillisecondsSinceEpoch(1456279843199))
            .millisecondsSinceEpoch,
        1456277400000,
        'Kolkata floor',
      );
      _assertEq(
        timeHour
            .ceil(DateTime.fromMillisecondsSinceEpoch(1456279843199))
            .millisecondsSinceEpoch,
        1456281000000,
        'Kolkata ceil',
      );
      _assertListEq(
        timeHour
            .range(DateTime(2011, 11, 7), DateTime(2011, 11, 7, 3))
            .map((d) => d.millisecondsSinceEpoch)
            .toList(),
        [1320604200000, 1320607800000, 1320611400000],
        'Kolkata range',
      );
    case 'Asia/Kathmandu':
      _assertEq(
        timeHour
            .floor(DateTime.fromMillisecondsSinceEpoch(1456279843199))
            .millisecondsSinceEpoch,
        1456276500000,
        'Kathmandu floor',
      );
      _assertEq(
        timeHour
            .ceil(DateTime.fromMillisecondsSinceEpoch(1456279843199))
            .millisecondsSinceEpoch,
        1456280100000,
        'Kathmandu ceil',
      );
      _assertListEq(
        timeHour
            .range(DateTime(2011, 11, 7), DateTime(2011, 11, 7, 3))
            .map((d) => d.millisecondsSinceEpoch)
            .toList(),
        [1320603300000, 1320606900000, 1320610500000],
        'Kathmandu range',
      );
    case 'America/Sao_Paulo':
      // Daylight saving ends at midnight (2016-02-21).
      _assertEq(
        timeDay.floor(DateTime.utc(2016, 2, 21, 1)).millisecondsSinceEpoch,
        1455933600000,
        'SP end floor 1',
      );
      _assertEq(
        timeDay.floor(DateTime.utc(2016, 2, 21, 2)).millisecondsSinceEpoch,
        1455933600000,
        'SP end floor 2',
      );
      _assertEq(
        timeDay.floor(DateTime.utc(2016, 2, 21, 3)).millisecondsSinceEpoch,
        1456023600000,
        'SP end floor 3',
      );
      _assertEq(
        timeDay.floor(DateTime.utc(2016, 2, 21, 4)).millisecondsSinceEpoch,
        1456023600000,
        'SP end floor 4',
      );
      _assertEq(
        timeDay.ceil(DateTime.utc(2016, 2, 21, 1)).millisecondsSinceEpoch,
        1456023600000,
        'SP end ceil 1',
      );
      _assertEq(
        timeDay.ceil(DateTime.utc(2016, 2, 21, 2)).millisecondsSinceEpoch,
        1456023600000,
        'SP end ceil 2',
      );
      _assertEq(
        timeDay.ceil(DateTime.utc(2016, 2, 21, 3)).millisecondsSinceEpoch,
        1456023600000,
        'SP end ceil 3',
      );
      _assertEq(
        timeDay.ceil(DateTime.utc(2016, 2, 21, 4)).millisecondsSinceEpoch,
        1456110000000,
        'SP end ceil 4',
      );
      _assertEq(
        timeDay.round(DateTime.utc(2016, 2, 20, 14)).millisecondsSinceEpoch,
        1455933600000,
        'SP end round 1',
      );
      _assertEq(
        timeDay.round(DateTime.utc(2016, 2, 20, 15)).millisecondsSinceEpoch,
        1456023600000,
        'SP end round 2',
      );
      _assertEq(
        timeDay.round(DateTime.utc(2016, 2, 21, 14)).millisecondsSinceEpoch,
        1456023600000,
        'SP end round 3',
      );
      _assertEq(
        timeDay.round(DateTime.utc(2016, 2, 21, 15)).millisecondsSinceEpoch,
        1456110000000,
        'SP end round 4',
      );
      _assertListEq(
        timeDay
            .range(DateTime(2016, 2, 19), DateTime(2016, 2, 23))
            .map((d) => d.millisecondsSinceEpoch)
            .toList(),
        [1455847200000, 1455933600000, 1456023600000, 1456110000000],
        'SP end range',
      );

      // Daylight saving begins at midnight (2016-10-16).
      _assertEq(
        timeDay.floor(DateTime.utc(2016, 10, 16, 1)).millisecondsSinceEpoch,
        1476500400000,
        'SP start floor 1',
      );
      _assertEq(
        timeDay.floor(DateTime.utc(2016, 10, 16, 2)).millisecondsSinceEpoch,
        1476500400000,
        'SP start floor 2',
      );
      _assertEq(
        timeDay.floor(DateTime.utc(2016, 10, 16, 3)).millisecondsSinceEpoch,
        1476586800000,
        'SP start floor 3',
      );
      _assertEq(
        timeDay.floor(DateTime.utc(2016, 10, 16, 4)).millisecondsSinceEpoch,
        1476586800000,
        'SP start floor 4',
      );
      _assertEq(
        timeDay.ceil(DateTime.utc(2016, 10, 16, 1)).millisecondsSinceEpoch,
        1476586800000,
        'SP start ceil 1',
      );
      _assertEq(
        timeDay.ceil(DateTime.utc(2016, 10, 16, 2)).millisecondsSinceEpoch,
        1476586800000,
        'SP start ceil 2',
      );
      _assertEq(
        timeDay.ceil(DateTime.utc(2016, 10, 16, 3)).millisecondsSinceEpoch,
        1476586800000,
        'SP start ceil 3',
      );
      _assertEq(
        timeDay.ceil(DateTime.utc(2016, 10, 16, 4)).millisecondsSinceEpoch,
        1476669600000,
        'SP start ceil 4',
      );
      _assertEq(
        timeDay.round(DateTime.utc(2016, 10, 15, 14)).millisecondsSinceEpoch,
        1476500400000,
        'SP start round 1',
      );
      _assertEq(
        timeDay.round(DateTime.utc(2016, 10, 15, 15)).millisecondsSinceEpoch,
        1476586800000,
        'SP start round 2',
      );
      _assertEq(
        timeDay.round(DateTime.utc(2016, 10, 16, 14)).millisecondsSinceEpoch,
        1476586800000,
        'SP start round 3',
      );
      _assertEq(
        timeDay.round(DateTime.utc(2016, 10, 16, 15)).millisecondsSinceEpoch,
        1476669600000,
        'SP start round 4',
      );
      _assertListEq(
        timeDay
            .range(DateTime(2016, 10, 14), DateTime(2016, 10, 18))
            .map((d) => d.millisecondsSinceEpoch)
            .toList(),
        [1476414000000, 1476500400000, 1476586800000, 1476669600000],
        'SP start range',
      );
    case 'America/Los_Angeles':
      _assertEq(
        timeDay.floor(DateTime.utc(2011, 3, 13, 7)),
        DateTime(2011, 3, 12),
        'LA day floor before midnight',
      );
      _assertEq(
        timeDay.floor(DateTime.utc(2011, 3, 13, 8)),
        DateTime(2011, 3, 13),
        'LA day floor at midnight',
      );
      _assertEq(
        timeDay.round(DateTime.utc(2011, 3, 13, 7)),
        DateTime(2011, 3, 13),
        'LA day round 7',
      );
      _assertEq(
        timeDay.round(DateTime.utc(2011, 3, 13, 20)),
        DateTime(2011, 3, 14),
        'LA day round 20',
      );
      _assertEq(
        timeDay.ceil(DateTime.utc(2011, 3, 13, 8)),
        DateTime(2011, 3, 13),
        'LA day ceil 8',
      );
      _assertEq(
        timeDay.ceil(DateTime.utc(2011, 3, 13, 9)),
        DateTime(2011, 3, 14),
        'LA day ceil 9',
      );
      _assertEq(
        timeDay.ceil(DateTime.utc(2011, 11, 6, 7)),
        DateTime(2011, 11, 6),
        'LA day ceil fall 7',
      );
      _assertEq(
        timeDay.ceil(DateTime.utc(2011, 11, 6, 8)),
        DateTime(2011, 11, 7),
        'LA day ceil fall 8',
      );
      _assertListEq(
        timeHour
            .range(DateTime(2011, 3, 13, 1), DateTime(2011, 3, 13, 5))
            .map((d) => d.millisecondsSinceEpoch)
            .toList(),
        [
          DateTime.utc(2011, 3, 13, 9).millisecondsSinceEpoch,
          DateTime.utc(2011, 3, 13, 10).millisecondsSinceEpoch,
          DateTime.utc(2011, 3, 13, 11).millisecondsSinceEpoch,
        ],
        'LA hour spring range',
      );
      _assertListEq(
        timeHour
            .range(DateTime(2011, 11, 6), DateTime(2011, 11, 6, 2))
            .map((d) => d.millisecondsSinceEpoch)
            .toList(),
        [
          DateTime.utc(2011, 11, 6, 7).millisecondsSinceEpoch,
          DateTime.utc(2011, 11, 6, 8).millisecondsSinceEpoch,
          DateTime.utc(2011, 11, 6, 9).millisecondsSinceEpoch,
        ],
        'LA hour fall range',
      );
      _assertEq(
        timeMonth.ceil(DateTime.utc(2012, 3)),
        DateTime(2012, 3),
        'LA month leap ceil',
      );
    default:
      stderr.writeln('Unknown timezone: $tz');
      exit(2);
  }
}
