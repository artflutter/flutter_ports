// Ported from d3-time v3.1.0 test/utcMillisecond-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

void main() {
  test('utcMillisecond is an alias for timeMillisecond', () {
    expect(identical(utcMillisecond, timeMillisecond), isTrue);
  });
}
