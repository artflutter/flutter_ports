// Ported from d3-format v3.1.2 test/format-type-b-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_format_port/d3_format.dart';
import 'package:test/test.dart';

void main() {
  test('format("b") binary', () {
    expect(format('b')(10), '1010');
  });

  test('format("#b") binary with prefix', () {
    expect(format('#b')(10), '0b1010');
  });
}
