// Ported from d3-time-format v4.1.0 test/isoFormat-test.js (ISC, Mike Bostock).
// ignore_for_file: avoid_redundant_argument_values, file_names

import 'package:flutter_d3_time_format_port/d3_time_format.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('isoFormat(date) returns an ISO 8601 UTC string', () {
    expect(isoFormat(utc(1990, 0, 1, 0, 0, 0)), '1990-01-01T00:00:00.000Z');
    expect(
      isoFormat(utc(2011, 11, 31, 23, 59, 59)),
      '2011-12-31T23:59:59.000Z',
    );
  });
}
