// Ported from d3-time-format v4.1.0 test/isoParse-test.js (ISC, Mike Bostock).
// ignore_for_file: avoid_redundant_argument_values, file_names

import 'package:flutter_d3_time_format_port/d3_time_format.dart';
import 'package:test/test.dart';

import 'date.dart';

void main() {
  test('isoParse as ISO 8601', () {
    expect(isoParse('1990-01-01T00:00:00.000Z'), utc(1990, 0, 1, 0, 0, 0));
    expect(isoParse('2011-12-31T23:59:59.000Z'), utc(2011, 11, 31, 23, 59, 59));
    expect(isoParse('1990-01-01T00:00:00.000X'), isNull);
  });
}
