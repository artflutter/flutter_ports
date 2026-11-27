// Ported from d3-array v3.2.4 test/flatGroup-test.js (ISC, Mike Bostock).
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
  test('flatGroup(data, accessor, accessor) returns the expected array', () {
    final actual = flatGroup2(_data, (d) => d.name, (d) => d.amount);
    const expected = <(String, String, List<_Row>)>[
      (
        'jim',
        '34.0',
        <_Row>[(name: 'jim', amount: '34.0', date: '11/12/2015')],
      ),
      (
        'carl',
        '120.11',
        <_Row>[(name: 'carl', amount: '120.11', date: '11/12/2015')],
      ),
      (
        'stacy',
        '12.01',
        <_Row>[(name: 'stacy', amount: '12.01', date: '01/04/2016')],
      ),
      (
        'stacy',
        '34.05',
        <_Row>[(name: 'stacy', amount: '34.05', date: '01/04/2016')],
      ),
    ];
    expect(actual.length, expected.length);
    for (var i = 0; i < expected.length; ++i) {
      expect(actual[i].$1, expected[i].$1);
      expect(actual[i].$2, expected[i].$2);
      expect(actual[i].$3, expected[i].$3);
    }
  });
}
