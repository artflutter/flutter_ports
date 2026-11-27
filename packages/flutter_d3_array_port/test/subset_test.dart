// Ported from d3-array v3.2.4 test/subset-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test(
    'subset(values, other) returns true if values is a subset of others',
    () {
      expect(subset([2], [1, 2]), isTrue);
      expect(subset([3, 4], [2, 3]), isFalse);
      expect(subset(<int>[], [1]), isTrue);
    },
  );

  test('subset(values, other) performs interning', () {
    expect(
      subset(
        [DateTime.parse('2021-01-02T00:00:00Z')],
        [
          DateTime.parse('2021-01-01T00:00:00Z'),
          DateTime.parse('2021-01-02T00:00:00Z'),
        ],
      ),
      isTrue,
    );
    expect(
      subset(
        [
          DateTime.parse('2021-01-03T00:00:00Z'),
          DateTime.parse('2021-01-04T00:00:00Z'),
        ],
        [
          DateTime.parse('2021-01-02T00:00:00Z'),
          DateTime.parse('2021-01-03T00:00:00Z'),
        ],
      ),
      isFalse,
    );
    expect(
      subset(<DateTime>[], [DateTime.parse('2021-01-01T00:00:00Z')]),
      isTrue,
    );
  });
}
