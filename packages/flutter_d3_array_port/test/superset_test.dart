// Ported from d3-array v3.2.4 test/superset-test.js (ISC, Mike Bostock).

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
  test(
    'superset(values, other) returns true if values is a superset of others',
    () {
      expect(superset([1, 2], [2]), isTrue);
      expect(superset([2, 3], [3, 4]), isFalse);
      expect(superset([1], <int>[]), isTrue);
    },
  );

  test('superset(values, other) allows values to be infinite', () {
    expect(superset(_odds(), [1, 3, 5]), isTrue);
  });

  test('superset(values, other) allows other to be infinite', () {
    expect(superset([1, 3, 5], _repeat([1, 3, 2])), isFalse);
  });

  test('superset(values, other) performs interning', () {
    expect(
      superset(
        [
          DateTime.parse('2021-01-01T00:00:00Z'),
          DateTime.parse('2021-01-02T00:00:00Z'),
        ],
        [DateTime.parse('2021-01-02T00:00:00Z')],
      ),
      isTrue,
    );
    expect(
      superset(
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
      superset([DateTime.parse('2021-01-01T00:00:00Z')], <DateTime>[]),
      isTrue,
    );
  });
}
