// Original code, not ported from d3-time: runnable package example.

// Example prints formatted calendar ticks and interval boundaries.
// ignore_for_file: avoid_print

import 'package:flutter_d3_time_port/d3_time.dart';

void main() {
  final start = DateTime.utc(2024);
  final stop = DateTime.utc(2024, 7);

  // Automatic calendar-aligned ticks and chosen interval.
  final ticks = utcTicks(start, stop, 6);
  final interval = utcTickInterval(start, stop, 6);
  print('Chosen interval: ${interval != null ? 'present' : 'none'}');
  print('UTC ticks (${ticks.length}):');
  for (final tick in ticks) {
    print('  ${tick.toIso8601String()}');
  }

  // Floor, ceil, round, offset, count, and every(step).
  final sample = DateTime.utc(2024, 3, 15, 14, 37, 22);
  print('floor(utcHour): ${utcHour.floor(sample).toIso8601String()}');
  print('ceil(utcHour):  ${utcHour.ceil(sample).toIso8601String()}');
  print('round(utcDay):  ${utcDay.round(sample).toIso8601String()}');
  print('offset(+2 wk):  ${utcWeek.offset(sample, 2).toIso8601String()}');
  print('days in Q1:     ${utcDay.count(start, DateTime.utc(2024, 4))}');

  final quarterly = utcMonth.every(3)!;
  final quarters = quarterly
      .range(start, DateTime.utc(2025))
      .map((d) => d.toIso8601String())
      .toList();
  print('2024 quarters:  $quarters');
}
