// Ported from d3-array v3.2.4 test/disjoint-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

Iterable<int> _odds() sync* {
  for (var i = 1; ; i += 2) {
    yield i;
  }
}

Iterable<int> _repeat(List<int> values) sync* {
  while (true) {
    yield* values;
  }
}

void main() {
  test('disjoint(values, other) returns true if sets are disjoint', () {
    expect(disjoint([1], [2]), isTrue);
    expect(disjoint([2, 3], [3, 4]), isFalse);
    expect(disjoint([1], <int>[]), isTrue);
  });

  test('disjoint(values, other) allows values to be infinite', () {
    expect(disjoint(_odds(), [0, 2, 4, 5]), isFalse);
  });

  test('disjoint(values, other) allows other to be infinite', () {
    expect(disjoint([2], _repeat([1, 3, 2])), isFalse);
  });

  test('disjoint(values, other) performs interning', () {
    expect(
      disjoint(
        [DateTime.parse('2021-01-01T00:00:00Z')],
        [DateTime.parse('2021-01-02T00:00:00Z')],
      ),
      isTrue,
    );
    expect(
      disjoint(
        [
          DateTime.parse('2021-01-02T00:00:00Z'),
          DateTime.parse('2021-01-03T00:00:00Z'),
        ],
        [
          DateTime.parse('2021-01-03T00:00:00Z'),
          DateTime.parse('2021-01-04T00:00:00Z'),
        ],
      ),
      isFalse,
    );
    expect(
      disjoint([DateTime.parse('2021-01-01T00:00:00Z')], <DateTime>[]),
      isTrue,
    );
  });
}
