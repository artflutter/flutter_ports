// Ported from d3-format v3.1.2 test/format-type-o-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_format_port/d3_format.dart';
import 'package:test/test.dart';

void main() {
  test('format("o") octal', () {
    expect(format('o')(10), '12');
  });

  test('format("#o") octal with prefix', () {
    expect(format('#o')(10), '0o12');
  });
}
