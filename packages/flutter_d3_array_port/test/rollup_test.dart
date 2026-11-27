// Ported from d3-array v3.2.4 test/rollup-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart' hide group;

typedef _Row = ({String name, String amount, String date});

const List<_Row> _data = <_Row>[
  (name: 'jim', amount: '3400', date: '11/12/2015'),
  (name: 'carl', amount: '12011', date: '11/12/2015'),
  (name: 'stacy', amount: '1201', date: '01/04/2016'),
  (name: 'stacy', amount: '3405', date: '01/04/2016'),
];

void main() {
  test('rollup(data, reduce, accessor) returns the expected map', () {
    final counts = rollup(_data, (v) => v.length, (d) => d.name);
    expect(
      counts.entries.map((e) => (e.key, e.value)).toList(),
      <(String, int)>[('jim', 1), ('carl', 1), ('stacy', 2)],
    );

    final sums = rollup(
      _data,
      (v) => sumBy(v, (d) => int.parse(d.amount)),
      (d) => d.name,
    );
    expect(
      sums.entries.map((e) => (e.key, e.value)).toList(),
      <(String, double)>[('jim', 3400), ('carl', 12011), ('stacy', 4606)],
    );
  });

  test('rollup(data, reduce, accessor, accessor) returns the expected map', () {
    final nested = rollup2(
      _data,
      (v) => v.length,
      (d) => d.name,
      (d) => d.amount,
    );
    expect(nested.keys.toList(), <String>['jim', 'carl', 'stacy']);
    expect(nested['stacy']!.keys.toList(), <String>['1201', '3405']);
    expect(nested, <String, Map<String, int>>{
      'jim': <String, int>{'3400': 1},
      'carl': <String, int>{'12011': 1},
      'stacy': <String, int>{'1201': 1, '3405': 1},
    });
  });
}
