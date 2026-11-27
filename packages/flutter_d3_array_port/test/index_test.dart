// Ported from d3-array v3.2.4 test/index-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart' hide group;

typedef _Row = ({String name, double amount, String date});

const List<_Row> _data = <_Row>[
  (name: 'jim', amount: 34.0, date: '11/12/2015'),
  (name: 'carl', amount: 120.11, date: '11/12/2015'),
  (name: 'stacy', amount: 12.01, date: '01/04/2016'),
  (name: 'stacy', amount: 34.05, date: '01/04/2016'),
];

void _expectNested(
  List<(String, List<(double, _Row)>)> actual,
  List<(String, List<(double, _Row)>)> expected,
) {
  expect(actual.length, expected.length);
  for (var i = 0; i < expected.length; ++i) {
    expect(actual[i].$1, expected[i].$1);
    expect(actual[i].$2, expected[i].$2);
  }
}

void main() {
  test('indexes(data, ...keys) returns the expected nested arrays', () {
    expect(indexes(_data, (d) => d.amount), <(double, _Row)>[
      (34.0, (name: 'jim', amount: 34.0, date: '11/12/2015')),
      (120.11, (name: 'carl', amount: 120.11, date: '11/12/2015')),
      (12.01, (name: 'stacy', amount: 12.01, date: '01/04/2016')),
      (34.05, (name: 'stacy', amount: 34.05, date: '01/04/2016')),
    ]);
    _expectNested(
      indexes2(_data, (d) => d.name, (d) => d.amount),
      <(String, List<(double, _Row)>)>[
        (
          'jim',
          <(double, _Row)>[
            (34.0, (name: 'jim', amount: 34.0, date: '11/12/2015')),
          ],
        ),
        (
          'carl',
          <(double, _Row)>[
            (120.11, (name: 'carl', amount: 120.11, date: '11/12/2015')),
          ],
        ),
        (
          'stacy',
          <(double, _Row)>[
            (12.01, (name: 'stacy', amount: 12.01, date: '01/04/2016')),
            (34.05, (name: 'stacy', amount: 34.05, date: '01/04/2016')),
          ],
        ),
      ],
    );
  });

  test('index(data, ...keys) returns the expected map', () {
    expect(
      index(
        _data,
        (d) => d.amount,
      ).entries.map((e) => (e.key, e.value)).toList(),
      indexes(_data, (d) => d.amount),
    );
    _expectNested(
      index2(_data, (d) => d.name, (d) => d.amount).entries
          .map(
            (e1) => (
              e1.key,
              e1.value.entries.map((e2) => (e2.key, e2.value)).toList(),
            ),
          )
          .toList(),
      indexes2(_data, (d) => d.name, (d) => d.amount),
    );
  });

  test('index(data, ...keys) throws on a non-unique key', () {
    expect(() => index(_data, (d) => d.name), throwsStateError);
    expect(() => index(_data, (d) => d.date), throwsStateError);
  });
}
