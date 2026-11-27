// Ported from d3-array v3.2.4 test/bin-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

import 'port/test_data.dart';

typedef _ExpectedBin<T> = (List<T>, double, double);

void _expectBins<T>(List<Bin<T>> actual, List<_ExpectedBin<T>> expected) {
  expect(actual.length, expected.length);
  for (var i = 0; i < expected.length; ++i) {
    final (items, x0, x1) = expected[i];
    expect(actual[i].toList(), items, reason: 'bin[$i] elements');
    expect(actual[i].x0, x0, reason: 'bin[$i].x0');
    expect(actual[i].x1, x1, reason: 'bin[$i].x1');
  }
}

Iterable<T> _iterable<T>(List<T> array) sync* {
  yield* array;
}

void main() {
  test('histogram is a deprecated alias for bin', () {
    // Upstream bin-test.js verifies the deprecated histogram alias.
    // ignore: deprecated_member_use_from_same_package
    final h = histogram<int>();
    final b = bin<int>();
    final data = <int>[0, 0, 0, 10, 20, 20];
    final hb = h(data);
    final bb = b(data);
    expect(hb.length, bb.length);
    for (var i = 0; i < bb.length; ++i) {
      expect(hb[i].toList(), bb[i].toList());
      expect(hb[i].x0, bb[i].x0);
      expect(hb[i].x1, bb[i].x1);
    }
  });

  test('bin() returns a default bin generator', () {
    final h = bin<int>();
    expect(h.value(42, 0, <int>[42]), 42);
    expect(h.domain(<double?>[1, 5, 3]), (1.0, 5.0));
    expect(h.thresholdsCount, thresholdSturges);
  });

  test('bin(data) computes bins of the specified array of data', () {
    final h = bin<int>();
    _expectBins(h(<int>[0, 0, 0, 10, 20, 20]), <_ExpectedBin<int>>[
      (<int>[0, 0, 0], 0, 5),
      (<int>[], 5, 10),
      (<int>[10], 10, 15),
      (<int>[], 15, 20),
      (<int>[20, 20], 20, 25),
    ]);
  });

  test('bin(iterable) is equivalent to bin(array)', () {
    final h = bin<int>();
    _expectBins(h(_iterable(<int>[0, 0, 0, 10, 20, 20])), <_ExpectedBin<int>>[
      (<int>[0, 0, 0], 0, 5),
      (<int>[], 5, 10),
      (<int>[10], 10, 15),
      (<int>[], 15, 20),
      (<int>[20, 20], 20, 25),
    ]);
  });

  test('bin.value(number) sets the constant value', () {
    final h = bin<int>()..valueConst(12); // Pointless, but for consistency.
    _expectBins(h(<int>[0, 0, 0, 1, 2, 2]), <_ExpectedBin<int>>[
      (<int>[0, 0, 0, 1, 2, 2], 12, 12),
    ]);
  });

  test('bin(data) does not bin null, undefined, or NaN', () {
    final h = bin<num?>();
    _expectBins(
      h(<num?>[0, null, double.nan, 10, 20, 20]),
      <_ExpectedBin<num?>>[
        (<num?>[0], 0, 5),
        (<num?>[], 5, 10),
        (<num?>[10], 10, 15),
        (<num?>[], 15, 20),
        (<num?>[20, 20], 20, 25),
      ],
    );
  });

  test('bin.value(function) sets the value accessor', () {
    final h = binBy<({int value})>((d) => d.value);
    const a = (value: 0);
    const b = (value: 10);
    const c = (value: 20);
    _expectBins(
      h(<({int value})>[a, a, a, b, c, c]),
      <_ExpectedBin<({int value})>>[
        (<({int value})>[a, a, a], 0, 5),
        (<({int value})>[], 5, 10),
        (<({int value})>[b], 10, 15),
        (<({int value})>[], 15, 20),
        (<({int value})>[c, c], 20, 25),
      ],
    );
  });

  test('bin.domain(array) sets the domain', () {
    final h = bin<int>()..domainConst(0, 20);
    expect(h.domain(<double?>[]), (0.0, 20.0));
    _expectBins(h(<int>[1, 2, 2, 10, 18, 18]), <_ExpectedBin<int>>[
      (<int>[1, 2, 2], 0, 5),
      (<int>[], 5, 10),
      (<int>[10], 10, 15),
      (<int>[18, 18], 15, 20),
    ]);
  });

  test('bin.domain(function) sets the domain accessor', () {
    List<double?>? actual;
    const values = <int>[1, 2, 2, 10, 18, 18];
    (double, double)? domain(List<double?> v) {
      actual = v;
      return (0.0, 20.0);
    }

    final h = bin<int>()..domain = domain;
    expect(identical(h.domain, domain), isTrue);
    _expectBins(h(values), <_ExpectedBin<int>>[
      (<int>[1, 2, 2], 0, 5),
      (<int>[], 5, 10),
      (<int>[10], 10, 15),
      (<int>[18, 18], 15, 20),
    ]);
    expect(actual, <double>[1, 2, 2, 10, 18, 18]);
  });

  test(
    'bin.thresholds(number) sets the approximate number of bin thresholds',
    () {
      final h = bin<int>()..thresholdsCountConst(3);
      _expectBins(h(<int>[0, 0, 0, 10, 30, 30]), <_ExpectedBin<int>>[
        (<int>[0, 0, 0], 0, 10),
        (<int>[10], 10, 20),
        (<int>[], 20, 30),
        (<int>[30, 30], 30, 40),
      ]);
    },
  );

  test('bin.thresholds(array) sets the bin thresholds', () {
    final h = bin<int>()..thresholdsValuesConst(<num>[10, 20]);
    _expectBins(h(<int>[0, 0, 0, 10, 30, 30]), <_ExpectedBin<int>>[
      (<int>[0, 0, 0], 0, 10),
      (<int>[10], 10, 20),
      (<int>[30, 30], 20, 30),
    ]);
  });

  test('bin.thresholds(array) ignores thresholds outside the domain', () {
    final h = bin<int>()..thresholdsValuesConst(<num>[0, 1, 2, 3, 4]);
    _expectBins(h(<int>[0, 1, 2, 3]), <_ExpectedBin<int>>[
      (<int>[0], 0, 1),
      (<int>[1], 1, 2),
      (<int>[2], 2, 3),
      (<int>[3], 3, 3),
    ]);
  });

  test('bin.thresholds(function) sets the bin thresholds accessor', () {
    (List<double?>, double, double)? actual;
    const values = <int>[0, 0, 0, 10, 30, 30];
    final h = bin<int>()
      ..thresholdsValues = (v, x0, x1) {
        actual = (v, x0, x1);
        return <double>[10, 20];
      };
    _expectBins(h(values), <_ExpectedBin<int>>[
      (<int>[0, 0, 0], 0, 10),
      (<int>[10], 10, 20),
      (<int>[30, 30], 20, 30),
    ]);
    expect(actual?.$1, <double>[0, 0, 0, 10, 30, 30]);
    expect(actual?.$2, 0.0);
    expect(actual?.$3, 30.0);
    h.thresholdsCount = (_, _, _) => 5;
    _expectBins(h(values), <_ExpectedBin<int>>[
      (<int>[0, 0, 0], 0, 5),
      (<int>[], 5, 10),
      (<int>[10], 10, 15),
      (<int>[], 15, 20),
      (<int>[], 20, 25),
      (<int>[], 25, 30),
      (<int>[30, 30], 30, 35),
    ]);
  });

  test('bin(data) uses nice thresholds', () {
    final h = bin<double>()
      ..domainConst(0, 1)
      ..thresholdsCountConst(5);
    expect(h(<double>[]).map((b) => (b.x0, b.x1)).toList(), <(double, double)>[
      (0.0, 0.2),
      (0.2, 0.4),
      (0.4, 0.6),
      (0.6, 0.8),
      (0.8, 1.0),
    ]);
  });

  test('bin()() returns bins whose rightmost bin is not too wide', () {
    final h = bin<double>();
    _expectBins(h(<double>[9.8, 10, 11, 12, 13, 13.2]), <_ExpectedBin<double>>[
      (<double>[9.8], 9, 10),
      (<double>[10], 10, 11),
      (<double>[11], 11, 12),
      (<double>[12], 12, 13),
      (<double>[13, 13.2], 13, 14),
    ]);
  });

  test('bin(data) handles fractional step correctly', () {
    final h = bin<double>()..thresholdsCountConst(10);
    _expectBins(h(<double>[9.8, 10, 11, 12, 13, 13.2]), <_ExpectedBin<double>>[
      (<double>[9.8], 9.5, 10),
      (<double>[10], 10, 10.5),
      (<double>[], 10.5, 11),
      (<double>[11], 11, 11.5),
      (<double>[], 11.5, 12),
      (<double>[12], 12, 12.5),
      (<double>[], 12.5, 13),
      (<double>[13, 13.2], 13, 13.5),
    ]);
  });

  test('bin(data) handles fractional step correctly with a custom, '
      'non-aligned domain', () {
    final h = bin<double>()
      ..thresholdsCountConst(10)
      ..domainConst(9.7, 13.3);
    _expectBins(h(<double>[9.8, 10, 11, 12, 13, 13.2]), <_ExpectedBin<double>>[
      (<double>[9.8], 9.7, 10),
      (<double>[10], 10, 10.5),
      (<double>[], 10.5, 11),
      (<double>[11], 11, 11.5),
      (<double>[], 11.5, 12),
      (<double>[12], 12, 12.5),
      (<double>[], 12.5, 13),
      (<double>[13, 13.2], 13, 13.3),
    ]);
  });

  test(
    'bin(data) handles fractional step correctly with a custom, aligned domain',
    () {
      final h = bin<double>()
        ..thresholdsCountConst(10)
        ..domainConst(9.5, 13.5);
      _expectBins(
        h(<double>[9.8, 10, 11, 12, 13, 13.2]),
        <_ExpectedBin<double>>[
          (<double>[9.8], 9.5, 10),
          (<double>[10], 10, 10.5),
          (<double>[], 10.5, 11),
          (<double>[11], 11, 11.5),
          (<double>[], 11.5, 12),
          (<double>[12], 12, 12.5),
          (<double>[], 12.5, 13),
          (<double>[13, 13.2], 13, 13.5),
        ],
      );
    },
  );

  test(
    'bin(data) coerces values to numbers as expected',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('bin(athletes) produces the expected result', () {
    final bins = (bin<double>()..thresholdsCountConst(57))(athleteHeights);
    expect(bins.map((b) => b.length).toList(), <int>[
      1,
      0,
      0,
      0,
      0,
      0,
      2,
      1,
      2,
      1,
      1,
      4,
      11,
      7,
      13,
      39,
      78,
      93,
      119,
      193,
      354,
      393,
      573,
      483,
      651,
      834,
      808,
      763,
      627,
      648,
      833,
      672,
      578,
      498,
      395,
      425,
      278,
      235,
      182,
      128,
      91,
      69,
      43,
      29,
      21,
      23,
      3,
      3,
      1,
      1,
      1,
    ]);
  });

  test('bin(data) assigns floating point values to the correct bins', () {
    for (final n in <int>[
      1,
      2,
      5,
      10,
      20,
      50,
      100,
      200,
      500,
      1000,
      2000,
      5000,
      10000,
      20000,
      50000,
    ]) {
      final result = (bin<double>()..thresholdsCountConst(n))(ticks(1, 2, n));
      expect(result.every((d) => d.length == 1), isTrue, reason: 'n=$n');
    }
  });

  test('bin(data) assigns integer values to the correct bins', () {
    _expectBins((bin<int>()..domainConst(4, 5))(<int>[5]), <_ExpectedBin<int>>[
      (<int>[5], 4, 5),
    ]);
    const eights = <int>[8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8];
    _expectBins((bin<int>()..domainConst(3, 8))(eights), <_ExpectedBin<int>>[
      (<int>[], 3, 4),
      (<int>[], 4, 5),
      (<int>[], 5, 6),
      (<int>[], 6, 7),
      (eights, 7, 8),
    ]);
  });

  test('bin(data) does not mutate user-supplied thresholds as an array', () {
    final thresholds = <double>[3, 4, 5, 6];
    final b = bin<int>()
      ..domainConst(4, 5)
      ..thresholdsValuesConst(thresholds);
    _expectBins(b(<int>[5]), <_ExpectedBin<int>>[
      (<int>[], 4, 5),
      (<int>[5], 5, 5),
    ]);
    expect(thresholds, <double>[3, 4, 5, 6]);
    expect(b.thresholdsValues!(<double?>[], 0, 0), <double>[3, 4, 5, 6]);
  });

  test('bin(data) does not mutate user-supplied thresholds as a function', () {
    final thresholds = <double>[3, 4, 5, 6];
    final b = bin<int>()
      ..domainConst(4, 5)
      ..thresholdsValues = (_, _, _) => thresholds;
    _expectBins(b(<int>[5]), <_ExpectedBin<int>>[
      (<int>[], 4, 5),
      (<int>[5], 5, 5),
    ]);
    expect(thresholds, <double>[3, 4, 5, 6]);
    expect(b.thresholdsValues!(<double?>[], 0, 0), <double>[3, 4, 5, 6]);
  });
}
