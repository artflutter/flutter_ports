// Ported from d3-array v3.2.4 test/flatRollup-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart' hide group;

typedef _Row = ({String name, String amount, String date});

const List<_Row> _data = <_Row>[
  (name: 'jim', amount: '34.0', date: '11/12/2015'),
  (name: 'carl', amount: '120.11', date: '11/12/2015'),
  (name: 'stacy', amount: '12.01', date: '01/04/2016'),
  (name: 'stacy', amount: '34.05', date: '01/04/2016'),
];

void main() {
  test('flatRollup(data, reduce, accessor) returns the expected array', () {
    expect(flatRollup(_data, (v) => v.length, (d) => d.name), <(String, int)>[
      ('jim', 1),
      ('carl', 1),
      ('stacy', 2),
    ]);
  });

  test(
    'flatRollup(data, reduce, accessor, accessor) returns the expected array',
    () {
      expect(
        flatRollup2(_data, (v) => v.length, (d) => d.name, (d) => d.amount),
        <(String, String, int)>[
          ('jim', '34.0', 1),
          ('carl', '120.11', 1),
          ('stacy', '12.01', 1),
          ('stacy', '34.05', 1),
        ],
      );
    },
  );
}
