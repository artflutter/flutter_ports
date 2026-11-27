// Original code, not ported from d3-time-format: TZ subprocess test worker.

import 'dart:io';

import 'package:flutter_d3_time_format_port/d3_time_format.dart';

void _check(Object? actual, Object? expected, String label) {
  if (actual != expected) {
    stderr.writeln('FAIL [$label]: expected <$expected>, got <$actual>');
    exit(1);
  }
}

void main(List<String> args) {
  final tz = args.single;
  final fz = timeFormat('%Z');
  final pz = timeParse('%m/%d/%Y %Z');

  switch (tz) {
    case 'America/Los_Angeles':
      _check(fz(DateTime(1990)), '-0800', 'LA winter %Z');
      _check(fz(DateTime(2010, 3, 14, 12)), '-0700', 'LA summer %Z');
      _check(pz('01/02/1990 +0000'), DateTime(1990, 1, 1, 16), 'LA +0000');
      _check(pz('01/02/1990 +0100'), DateTime(1990, 1, 1, 15), 'LA +0100');
      _check(pz('01/02/1990 +0130'), DateTime(1990, 1, 1, 14, 30), 'LA +0130');
      _check(pz('01/02/1990 -0100'), DateTime(1990, 1, 1, 17), 'LA -0100');
      _check(pz('01/02/1990 -0130'), DateTime(1990, 1, 1, 17, 30), 'LA -0130');
      _check(pz('01/02/1990 -0800'), DateTime(1990, 1, 2), 'LA -0800');
      _check(pz('01/02/1990 Z'), DateTime(1990, 1, 1, 16), 'LA Z');
    case 'UTC':
      _check(fz(DateTime(1990)), '+0000', 'UTC %Z');
      _check(pz('01/02/1990 +0000'), DateTime(1990, 1, 2), 'UTC +0000');
      _check(pz('01/02/1990 -0800'), DateTime(1990, 1, 2, 8), 'UTC -0800');
    case 'Asia/Kolkata':
      _check(fz(DateTime(1990)), '+0530', 'Kolkata %Z');
      _check(
        pz('01/02/1990 +0000'),
        DateTime(1990, 1, 2, 5, 30),
        'Kolkata +0000',
      );
      _check(pz('01/02/1990 +05:30'), DateTime(1990, 1, 2), 'Kolkata +05:30');
    case 'Asia/Kathmandu':
      _check(fz(DateTime(1990)), '+0545', 'Kathmandu %Z');
      _check(
        pz('01/02/1990 +0000'),
        DateTime(1990, 1, 2, 5, 45),
        'Kathmandu +0000',
      );
      _check(pz('01/02/1990 +05:45'), DateTime(1990, 1, 2), 'Kathmandu +05:45');
    default:
      stderr.writeln('Unknown tz: $tz');
      exit(2);
  }
}
