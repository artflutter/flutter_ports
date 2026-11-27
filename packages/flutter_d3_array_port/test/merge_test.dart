// Ported from d3-array v3.2.4 test/merge-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test('merge(arrays) merges an array of arrays', () {
    final a = Object();
    final b = Object();
    final c = Object();
    final d = Object();
    final e = Object();
    final f = Object();
    expect(
      merge(<List<Object>>[
        [a],
        [b, c],
        [d, e, f],
      ]),
      [a, b, c, d, e, f],
    );
  });

  test('merge(arrays) returns a new array when zero arrays are passed', () {
    final input = <List<num>>[];
    final output = merge(input);
    expect(output, <num>[]);
    input.add(<num>[0.1]);
    expect(input, <List<num>>[
      [0.1],
    ]);
    expect(output, <num>[]);
  });

  test('merge(arrays) returns a new array when one array is passed', () {
    final input = <List<num>>[
      [1, 2, 3],
    ];
    final output = merge(input);
    expect(output, [1, 2, 3]);
    input.add(<num>[4.1]);
    input[0].add(3.1);
    expect(input, [
      [1, 2, 3, 3.1],
      [4.1],
    ]);
    expect(output, [1, 2, 3]);
  });

  test(
    'merge(arrays) returns a new array when two or more arrays are passed',
    () {
      final input = <List<num>>[
        [1, 2, 3],
        [4, 5],
        [6],
      ];
      final output = merge(input);
      expect(output, [1, 2, 3, 4, 5, 6]);
      input.add(<num>[7.1]);
      input[0].add(3.1);
      input[1].add(5.1);
      input[2].add(6.1);
      expect(input, [
        [1, 2, 3, 3.1],
        [4, 5, 5.1],
        [6, 6.1],
        [7.1],
      ]);
      expect(output, [1, 2, 3, 4, 5, 6]);
    },
  );

  test('merge(arrays) does not modify the input arrays', () {
    final input = [
      [1, 2, 3],
      [4, 5],
      [6],
    ];
    merge(input);
    expect(input, [
      [1, 2, 3],
      [4, 5],
      [6],
    ]);
  });
}
