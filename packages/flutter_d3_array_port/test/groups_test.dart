// Ported from d3-array v3.2.4 test/groups-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart' hide group;

typedef _Row = ({String name, String amount, String date});

const List<_Row> _data = <_Row>[
  (name: 'jim', amount: '34.0', date: '11/12/2015'),
  (name: 'carl', amount: '120.11', date: '11/12/2015'),
  (name: 'stacy', amount: '12.01', date: '01/04/2016'),
  (name: 'stacy', amount: '34.05', date: '01/04/2016'),
];

void _expectEntries<K, V>(List<(K, V)> actual, List<(K, V)> expected) {
  expect(actual.length, expected.length);
  for (var i = 0; i < expected.length; ++i) {
    expect(actual[i].$1, expected[i].$1);
    expect(actual[i].$2, expected[i].$2);
  }
}

void _expectEntries2<K1, K2, V>(
  List<(K1, List<(K2, V)>)> actual,
  List<(K1, List<(K2, V)>)> expected,
) {
  expect(actual.length, expected.length);
  for (var i = 0; i < expected.length; ++i) {
    expect(actual[i].$1, expected[i].$1);
    _expectEntries(actual[i].$2, expected[i].$2);
  }
}

void main() {
  test('groups(data, accessor) returns the expected array', () {
    _expectEntries(groups(_data, (d) => d.name), <(String, List<_Row>)>[
      ('jim', <_Row>[(name: 'jim', amount: '34.0', date: '11/12/2015')]),
      ('carl', <_Row>[(name: 'carl', amount: '120.11', date: '11/12/2015')]),
      (
        'stacy',
        <_Row>[
          (name: 'stacy', amount: '12.01', date: '01/04/2016'),
          (name: 'stacy', amount: '34.05', date: '01/04/2016'),
        ],
      ),
    ]);
  });

  test('groups(data, accessor, accessor) returns the expected array', () {
    _expectEntries2(
      groups2(_data, (d) => d.name, (d) => d.amount),
      <(String, List<(String, List<_Row>)>)>[
        (
          'jim',
          <(String, List<_Row>)>[
            ('34.0', <_Row>[(name: 'jim', amount: '34.0', date: '11/12/2015')]),
          ],
        ),
        (
          'carl',
          <(String, List<_Row>)>[
            (
              '120.11',
              <_Row>[(name: 'carl', amount: '120.11', date: '11/12/2015')],
            ),
          ],
        ),
        (
          'stacy',
          <(String, List<_Row>)>[
            (
              '12.01',
              <_Row>[(name: 'stacy', amount: '12.01', date: '01/04/2016')],
            ),
            (
              '34.05',
              <_Row>[(name: 'stacy', amount: '34.05', date: '01/04/2016')],
            ),
          ],
        ),
      ],
    );
  });
}
