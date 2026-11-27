// Ported from d3-array v3.2.4 test/rollups-test.js (ISC, Mike Bostock).

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
  test('rollups(data, reduce, accessor) returns the expected array', () {
    expect(rollups(_data, (v) => v.length, (d) => d.name), <(String, int)>[
      ('jim', 1),
      ('carl', 1),
      ('stacy', 2),
    ]);
    expect(
      rollups(
        _data,
        (v) => sumBy(v, (d) => int.parse(d.amount)),
        (d) => d.name,
      ),
      <(String, double)>[('jim', 3400), ('carl', 12011), ('stacy', 4606)],
    );
  });

  test(
    'rollups(data, reduce, accessor, accessor) returns the expected array',
    () {
      final actual = rollups2(
        _data,
        (v) => v.length,
        (d) => d.name,
        (d) => d.amount,
      );
      const expected = <(String, List<(String, int)>)>[
        ('jim', <(String, int)>[('3400', 1)]),
        ('carl', <(String, int)>[('12011', 1)]),
        ('stacy', <(String, int)>[('1201', 1), ('3405', 1)]),
      ];
      expect(actual.length, expected.length);
      for (var i = 0; i < expected.length; ++i) {
        expect(actual[i].$1, expected[i].$1);
        expect(actual[i].$2, expected[i].$2);
      }
    },
  );
}
