// Ported from d3-array v3.2.4 test/bisector-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

typedef _Box = ({num? value});

_Box _box(num? value) => (value: value);
num? _unbox(_Box box) => box.value;
double _ascendingBox(_Box a, _Box b) => ascending<num>(a.value, b.value);
double _ascendingBoxValue(_Box a, num value) => ascending<num>(a.value, value);

void main() {
  test('bisector(comparator).left(array, value) returns the index of an exact '
      'match', () {
    final boxes = [1, 2, 3].map(_box).toList();
    final bisectLeft = bisectorComparator(_ascendingBox).left;
    expect(bisectLeft(boxes, _box(1)), 0);
    expect(bisectLeft(boxes, _box(2)), 1);
    expect(bisectLeft(boxes, _box(3)), 2);
  });

  test('bisector(comparator).left(array, value) returns the index of the first '
      'match', () {
    final boxes = [1, 2, 2, 3].map(_box).toList();
    final bisectLeft = bisectorComparator(_ascendingBox).left;
    expect(bisectLeft(boxes, _box(1)), 0);
    expect(bisectLeft(boxes, _box(2)), 1);
    expect(bisectLeft(boxes, _box(3)), 3);
  });

  test('bisector(comparator).left(empty, value) returns zero', () {
    expect(
      bisectorComparator<int>((_, _) => throw StateError('unexpected'))
          .left(const [], 1),
      0,
    );
  });

  test(
    'bisector(comparator).left(array, value) returns the insertion point of a '
    'non-exact match',
    () {
      final boxes = [1, 2, 3].map(_box).toList();
      final bisectLeft = bisectorComparator(_ascendingBox).left;
      expect(bisectLeft(boxes, _box(0.5)), 0);
      expect(bisectLeft(boxes, _box(1.5)), 1);
      expect(bisectLeft(boxes, _box(2.5)), 2);
      expect(bisectLeft(boxes, _box(3.5)), 3);
    },
  );

  test('bisector(comparator).left(array, value) has undefined behavior if the '
      'search value is unorderable', () {
    final boxes = [1, 2, 3].map(_box).toList();
    final bisectLeft = bisectorComparator(_ascendingBox).left;
    expect(bisectLeft(boxes, _box(null)), isA<int>());
    expect(bisectLeft(boxes, _box(double.nan)), isA<int>());
  });

  test(
    'bisector(comparator).left(array, value, lo) observes the specified lower '
    'bound',
    () {
      final boxes = [1, 2, 3, 4, 5].map(_box).toList();
      final bisectLeft = bisectorComparator(_ascendingBox).left;
      expect(bisectLeft(boxes, _box(0), 2), 2);
      expect(bisectLeft(boxes, _box(1), 2), 2);
      expect(bisectLeft(boxes, _box(2), 2), 2);
      expect(bisectLeft(boxes, _box(3), 2), 2);
      expect(bisectLeft(boxes, _box(4), 2), 3);
      expect(bisectLeft(boxes, _box(5), 2), 4);
      expect(bisectLeft(boxes, _box(6), 2), 5);
    },
  );

  test('bisector(comparator).left(array, value, lo, hi) observes the specified '
      'bounds', () {
    final boxes = [1, 2, 3, 4, 5].map(_box).toList();
    final bisectLeft = bisectorComparator(_ascendingBox).left;
    expect(bisectLeft(boxes, _box(0), 2, 3), 2);
    expect(bisectLeft(boxes, _box(1), 2, 3), 2);
    expect(bisectLeft(boxes, _box(2), 2, 3), 2);
    expect(bisectLeft(boxes, _box(3), 2, 3), 2);
    expect(bisectLeft(boxes, _box(4), 2, 3), 3);
    expect(bisectLeft(boxes, _box(5), 2, 3), 3);
    expect(bisectLeft(boxes, _box(6), 2, 3), 3);
  });

  test(
    'bisector(comparator).left(array, value) handles large sparse d3',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'bisector(comparator).right(array, value) returns the index after an exact '
    'match',
    () {
      final boxes = [1, 2, 3].map(_box).toList();
      final bisectRight = bisectorComparator(_ascendingBox).right;
      expect(bisectRight(boxes, _box(1)), 1);
      expect(bisectRight(boxes, _box(2)), 2);
      expect(bisectRight(boxes, _box(3)), 3);
    },
  );

  test(
    'bisector(comparator).right(array, value) returns the index after the last '
    'match',
    () {
      final boxes = [1, 2, 2, 3].map(_box).toList();
      final bisectRight = bisectorComparator(_ascendingBox).right;
      expect(bisectRight(boxes, _box(1)), 1);
      expect(bisectRight(boxes, _box(2)), 3);
      expect(bisectRight(boxes, _box(3)), 4);
    },
  );

  test('bisector(comparator).right(empty, value) returns zero', () {
    expect(
      bisectorComparator<int>((_, _) => throw StateError('unexpected'))
          .right(const [], 1),
      0,
    );
  });

  test(
    'bisector(comparator).right(array, value) returns the insertion point of a '
    'non-exact match',
    () {
      final boxes = [1, 2, 3].map(_box).toList();
      final bisectRight = bisectorComparator(_ascendingBox).right;
      expect(bisectRight(boxes, _box(0.5)), 0);
      expect(bisectRight(boxes, _box(1.5)), 1);
      expect(bisectRight(boxes, _box(2.5)), 2);
      expect(bisectRight(boxes, _box(3.5)), 3);
    },
  );

  test(
    'bisector(comparator).right(array, value, lo) observes the specified lower '
    'bound',
    () {
      final boxes = [1, 2, 3, 4, 5].map(_box).toList();
      final bisectRight = bisectorComparator(_ascendingBox).right;
      expect(bisectRight(boxes, _box(0), 2), 2);
      expect(bisectRight(boxes, _box(1), 2), 2);
      expect(bisectRight(boxes, _box(2), 2), 2);
      expect(bisectRight(boxes, _box(3), 2), 3);
      expect(bisectRight(boxes, _box(4), 2), 4);
      expect(bisectRight(boxes, _box(5), 2), 5);
      expect(bisectRight(boxes, _box(6), 2), 5);
    },
  );

  test(
    'bisector(comparator).right(array, value, lo, hi) observes the specified '
    'bounds',
    () {
      final boxes = [1, 2, 3, 4, 5].map(_box).toList();
      final bisectRight = bisectorComparator(_ascendingBox).right;
      expect(bisectRight(boxes, _box(0), 2, 3), 2);
      expect(bisectRight(boxes, _box(1), 2, 3), 2);
      expect(bisectRight(boxes, _box(2), 2, 3), 2);
      expect(bisectRight(boxes, _box(3), 2, 3), 3);
      expect(bisectRight(boxes, _box(4), 2, 3), 3);
      expect(bisectRight(boxes, _box(5), 2, 3), 3);
      expect(bisectRight(boxes, _box(6), 2, 3), 3);
    },
  );

  test(
    'bisector(comparator).right(array, value) handles large sparse d3',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('bisector(comparator).left(array, value) supports an asymmetric '
      '(object, value) comparator', () {
    final boxes = [1, 2, 3].map(_box).toList();
    final bisectLeft = bisectorCompare<_Box, num>(_ascendingBoxValue).left;
    expect(bisectLeft(boxes, 1), 0);
    expect(bisectLeft(boxes, 2), 1);
    expect(bisectLeft(boxes, 3), 2);
  });

  test(
    'bisector(comparator).left(array, value) keeps non-comparable values to '
    'the right',
    () {},
    skip: 'upstream it.skip: comparator cannot test search value orderability',
  );

  test(
    'bisector(accessor).left(array, value) keeps non-comparable values to the '
    'right',
    () {
      final boxes = <num?>[1, 2, null, null, double.nan].map(_box).toList();
      final bisectLeft = bisectorNullable<_Box, num>(_unbox).left;
      expect(bisectLeft(boxes, 1), 0);
      expect(bisectLeft(boxes, 2), 1);
      expect(bisectLeft(boxes, null), 5);
      expect(bisectLeft(boxes, double.nan), 5);
    },
  );

  test(
    'bisector(accessor).left(array, value) returns the index of an exact match',
    () {
      final boxes = [1, 2, 3].map(_box).toList();
      final bisectLeft = bisector<_Box, num>(_unbox).left;
      expect(bisectLeft(boxes, 1), 0);
      expect(bisectLeft(boxes, 2), 1);
      expect(bisectLeft(boxes, 3), 2);
    },
  );

  test('bisector(accessor).left(array, value) returns the index of the first '
      'match', () {
    final boxes = [1, 2, 2, 3].map(_box).toList();
    final bisectLeft = bisector<_Box, num>(_unbox).left;
    expect(bisectLeft(boxes, 1), 0);
    expect(bisectLeft(boxes, 2), 1);
    expect(bisectLeft(boxes, 3), 3);
  });

  test('bisector(accessor).left(array, value) returns the insertion point of a '
      'non-exact match', () {
    final boxes = [1, 2, 3].map(_box).toList();
    final bisectLeft = bisector<_Box, num>(_unbox).left;
    expect(bisectLeft(boxes, 0.5), 0);
    expect(bisectLeft(boxes, 1.5), 1);
    expect(bisectLeft(boxes, 2.5), 2);
    expect(bisectLeft(boxes, 3.5), 3);
  });

  test('bisector(accessor).left(array, value) has undefined behavior if the '
      'search value is unorderable', () {
    final boxes = [1, 2, 3].map(_box).toList();
    final bisectLeft = bisectorNullable<_Box, num>(_unbox).left;
    expect(bisectLeft(boxes, null), isA<int>());
    expect(bisectLeft(boxes, double.nan), isA<int>());
  });

  test('bisector(accessor).left(array, value, lo) observes the specified lower '
      'bound', () {
    final boxes = [1, 2, 3, 4, 5].map(_box).toList();
    final bisectLeft = bisector<_Box, num>(_unbox).left;
    expect(bisectLeft(boxes, 0, 2), 2);
    expect(bisectLeft(boxes, 1, 2), 2);
    expect(bisectLeft(boxes, 2, 2), 2);
    expect(bisectLeft(boxes, 3, 2), 2);
    expect(bisectLeft(boxes, 4, 2), 3);
    expect(bisectLeft(boxes, 5, 2), 4);
    expect(bisectLeft(boxes, 6, 2), 5);
  });

  test('bisector(accessor).left(array, value, lo, hi) observes the specified '
      'bounds', () {
    final boxes = [1, 2, 3, 4, 5].map(_box).toList();
    final bisectLeft = bisector<_Box, num>(_unbox).left;
    expect(bisectLeft(boxes, 0, 2, 3), 2);
    expect(bisectLeft(boxes, 1, 2, 3), 2);
    expect(bisectLeft(boxes, 2, 2, 3), 2);
    expect(bisectLeft(boxes, 3, 2, 3), 2);
    expect(bisectLeft(boxes, 4, 2, 3), 3);
    expect(bisectLeft(boxes, 5, 2, 3), 3);
    expect(bisectLeft(boxes, 6, 2, 3), 3);
  });

  test(
    'bisector(accessor).left(array, value) handles large sparse d3',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'bisector(accessor).right(array, value) returns the index after an exact '
    'match',
    () {
      final boxes = [1, 2, 3].map(_box).toList();
      final bisectRight = bisector<_Box, num>(_unbox).right;
      expect(bisectRight(boxes, 1), 1);
      expect(bisectRight(boxes, 2), 2);
      expect(bisectRight(boxes, 3), 3);
    },
  );

  test(
    'bisector(accessor).right(array, value) returns the index after the last '
    'match',
    () {
      final boxes = [1, 2, 2, 3].map(_box).toList();
      final bisectRight = bisector<_Box, num>(_unbox).right;
      expect(bisectRight(boxes, 1), 1);
      expect(bisectRight(boxes, 2), 3);
      expect(bisectRight(boxes, 3), 4);
    },
  );

  test(
    'bisector(accessor).right(array, value) returns the insertion point of a '
    'non-exact match',
    () {
      final boxes = [1, 2, 3].map(_box).toList();
      final bisectRight = bisector<_Box, num>(_unbox).right;
      expect(bisectRight(boxes, 0.5), 0);
      expect(bisectRight(boxes, 1.5), 1);
      expect(bisectRight(boxes, 2.5), 2);
      expect(bisectRight(boxes, 3.5), 3);
    },
  );

  test(
    'bisector(accessor).right(array, value, lo) observes the specified lower '
    'bound',
    () {
      final boxes = [1, 2, 3, 4, 5].map(_box).toList();
      final bisectRight = bisector<_Box, num>(_unbox).right;
      expect(bisectRight(boxes, 0, 2), 2);
      expect(bisectRight(boxes, 1, 2), 2);
      expect(bisectRight(boxes, 2, 2), 2);
      expect(bisectRight(boxes, 3, 2), 3);
      expect(bisectRight(boxes, 4, 2), 4);
      expect(bisectRight(boxes, 5, 2), 5);
      expect(bisectRight(boxes, 6, 2), 5);
    },
  );

  test('bisector(accessor).right(array, value, lo, hi) observes the specified '
      'bounds', () {
    final boxes = [1, 2, 3, 4, 5].map(_box).toList();
    final bisectRight = bisector<_Box, num>(_unbox).right;
    expect(bisectRight(boxes, 0, 2, 3), 2);
    expect(bisectRight(boxes, 1, 2, 3), 2);
    expect(bisectRight(boxes, 2, 2, 3), 2);
    expect(bisectRight(boxes, 3, 2, 3), 3);
    expect(bisectRight(boxes, 4, 2, 3), 3);
    expect(bisectRight(boxes, 5, 2, 3), 3);
    expect(bisectRight(boxes, 6, 2, 3), 3);
  });

  test(
    'bisector(accessor).right(array, value) handles large sparse d3',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('bisector(accessor).center(array, value) returns the closest index', () {
    const data = <num>[0, 1, 2, 3, 4];
    final bisectCenter = bisector<num, num>((d) => d).center;
    expect(bisectCenter(data, 2), 2);
    expect(bisectCenter(data, 2.2), 2);
    expect(bisectCenter(data, 2.6), 3);
    expect(bisectCenter(data, 3), 3);
    expect(bisectCenter(data, 4), 4);
    expect(bisectCenter(data, 4.5), 4);
  });

  test(
    'bisector(comparator).center(array, value) returns the closest index',
    () {
      const data = <num>[0, 1, 2, 3, 4];
      final bisectCenter = bisectorCompare<num, num>((d, x) => d - x).center;
      expect(bisectCenter(data, 2), 2);
      expect(bisectCenter(data, 2.2), 2);
      expect(bisectCenter(data, 2.6), 3);
      expect(bisectCenter(data, 3), 3);
    },
  );

  test('bisector(comparator).center(empty, value) returns zero', () {
    expect(
      bisectorComparator<int>((_, _) => throw StateError('unexpected'))
          .center(const [], 1),
      0,
    );
  });

  test('bisector(ascending).center(array, value) returns the left value', () {
    const data = <num>[0, 1, 2, 3, 4];
    final bisectCenter = bisectorComparator<num>(ascending).center;
    expect(bisectCenter(data, 2.0), 2);
    expect(bisectCenter(data, 2.2), 3);
    expect(bisectCenter(data, 2.6), 3);
    expect(bisectCenter(data, 3.0), 3);
  });

  test(
    'bisector(ordinalAccessor).center(array, value) returns the left value',
    () {
      const data = ['aa', 'bb', 'cc', 'dd', 'ee'];
      final bisectCenter = bisector<String, String>((d) => d).center;
      expect(bisectCenter(data, 'cc'), 2);
      expect(bisectCenter(data, 'ce'), 3);
      expect(bisectCenter(data, 'cf'), 3);
      expect(bisectCenter(data, 'dd'), 3);
    },
  );
}
