// Original code, not ported from Chart.js: tests of the decimation algorithms.

import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.decimation.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:test/test.dart';

// The pure tests of `lttbDecimation` and `minMaxDecimation` of
// lib/src/plugins/plugin.decimation.dart (Chart.js ADR 0038, section 9).
// They run on the VM, with dart2js and with dart2wasm.
//
// The expected values come from a probe (p2_algorithms) that runs the two
// functions of the pinned source text
// (third_party/Chart.js/src/plugins/plugin.decimation.js:3-154) in the x64
// Node.js v24.12.0 (Chart.js ADR 0032), with the inputs of each case here.
// It logged one JSON line for each case, with the same case name, and each
// expected value here is the value of that line. `'<undefined>'` there is
// the `undefined` sentinel here.

/// [n] items `{x: i, y: f(i)}`.
List<Object?> _series(int n, Object? Function(int i) f) => <Object?>[
  for (var i = 0; i < n; i++) <String, Object?>{'x': i, 'y': f(i)},
];

/// The y values of the cases: a fixed pattern with peaks.
int _wave(int i) => (i * 37).remainder(23);

/// [n] items in clusters of 4: the x values of a cluster are 0.25 apart,
/// and the clusters are 10 apart.
List<Object?> _clustered(int n) => <Object?>[
  for (var i = 0; i < n; i++)
    <String, Object?>{
      'x': (i ~/ 4) * 10 + (i.remainder(4)) * 0.25,
      'y': (i * 37).remainder(23) - 5,
    },
];

/// The matcher of one expected value: NaN matches NaN.
Matcher _value(Object? expected) =>
    expected is double && expected.isNaN ? isNaN : equals(expected);

/// Expects [actual] to have the items of [expected] in order. Each Map item
/// has the keys of the expected Map in the same order, and the same values.
void _expectItems(List<Object?> actual, List<Object?> expected) {
  expect(actual, hasLength(expected.length), reason: 'the item count');
  for (var i = 0; i < expected.length; i++) {
    final want = expected[i];
    final got = actual[i];
    if (want is Map<String, Object?>) {
      expect(got, isA<AnyObject>(), reason: 'item $i');
      final map = got! as AnyObject;
      expect(jsObjectKeys(map), want.keys.toList(), reason: 'keys of item $i');
      for (final MapEntry(:key, :value) in want.entries) {
        expect(map[key], _value(value), reason: 'item $i.$key');
      }
    } else if (identical(want, undefined)) {
      expect(got, same(undefined), reason: 'item $i');
    } else {
      expect(got, _value(want), reason: 'item $i');
    }
  }
}

/// `{x, y}`.
AnyObject _p(Object? x, Object? y) => <String, Object?>{'x': x, 'y': y};

void main() {
  group('lttbDecimation', () {
    test('lttb samples 6', () {
      _expectItems(
        lttbDecimation(_series(20, _wave), 0, 20, 100, {'samples': 6}),
        [_p(0, 0), _p(3, 19), _p(5, 1), _p(13, 21), _p(15, 3), _p(19, 13)],
      );
    });

    test('lttb start 4 count 11 samples 5', () {
      _expectItems(
        lttbDecimation(_series(20, _wave), 4, 11, 100, {'samples': 5}),
        [_p(4, 10), _p(5, 1), _p(8, 20), _p(12, 7), _p(14, 12)],
      );
    });

    test('lttb samples >= count slices', () {
      final data = _series(20, _wave);
      final result = lttbDecimation(data, 3, 5, 100, {'samples': 9});
      expect(result, hasLength(5));
      expect(result[0], same(data[3]));
      expect(result, isNot(same(data)));
    });

    test('lttb samples string', () {
      _expectItems(
        lttbDecimation(_series(20, _wave), 0, 20, 100, {'samples': '6'}),
        [_p(0, 0), _p(3, 19), _p(5, 1), _p(13, 21), _p(15, 3), _p(19, 13)],
      );
    });

    test('lttb samples 6.5', () {
      _expectItems(
        lttbDecimation(_series(20, _wave), 0, 20, 100, {'samples': 6.5}),
        [
          _p(0, 0),
          _p(3, 19),
          _p(5, 1),
          _p(11, 16),
          _p(15, 3),
          _p(18, 22),
          _p(19, 13),
        ],
      );
    });

    test('lttb samples 0 uses the width 5', () {
      _expectItems(
        lttbDecimation(_series(20, _wave), 0, 20, 5, {'samples': 0}),
        [_p(0, 0), _p(3, 19), _p(10, 2), _p(13, 21), _p(19, 13)],
      );
    });

    test('lttb string values', () {
      final data = <Object?>[
        for (var i = 0; i < 20; i++) _p('$i', '${_wave(i)}'),
      ];
      _expectItems(lttbDecimation(data, 0, 20, 100, {'samples': 6}), [
        _p('0', '0'),
        _p('4', '10'),
        _p('8', '20'),
        _p('10', '2'),
        _p('18', '22'),
        _p('19', '13'),
      ]);
    });

    test('lttb no y in the first bucket, samples 3', () {
      final data = <Object?>[
        for (var i = 0; i < 9; i++)
          if (i < 5) <String, Object?>{'x': i} else _p(i, i),
      ];
      _expectItems(lttbDecimation(data, 0, 9, 100, {'samples': 3}), [
        <String, Object?>{'x': 0},
        undefined,
        _p(8, 8),
      ]);
    });

    test('lttb no y in the first bucket, samples 4', () {
      final data = <Object?>[
        for (var i = 0; i < 9; i++)
          if (i < 4) <String, Object?>{'x': i} else _p(i, i),
      ];
      // `a` is undefined in the second pass: the read of `data[a]` throws.
      expect(
        () => lttbDecimation(data, 0, 9, 100, {'samples': 4}),
        throwsA(isA<TypeError>()),
      );
    });

    test('lttb a null item', () {
      expect(
        () => lttbDecimation(
          [_p(0, 0), null, _p(2, 2), _p(3, 1), _p(4, 0)],
          0,
          5,
          100,
          {'samples': 3},
        ),
        throwsA(isA<TypeError>()),
      );
    });

    test('lttb number items', () {
      _expectItems(
        lttbDecimation([1, 2, 3, 4, 5, 6], 0, 6, 100, {'samples': 3}),
        [1, undefined, 6],
      );
    });
  });

  group('minMaxDecimation', () {
    test('min-max clustered 32 width 10', () {
      _expectItems(minMaxDecimation(_clustered(32), 0, 32, 10), [
        _p(0, -5),
        _p(0.75, 14),
        _p(10, 5),
        _p(10.5, -4),
        _p(10.5, 10),
        _p(10.75, 1),
        _p(20, 15),
        _p(20.5, -3),
        _p(20.75, 11),
        _p(30, 2),
        _p(30.5, 16),
        _p(30.75, -2),
        _p(40, 12),
        _p(40.5, 3),
        _p(40.5, 17),
        _p(40.75, 8),
        _p(50, -1),
        _p(50.5, 13),
        _p(50.75, -5),
        _p(60, 9),
        _p(60.5, 0),
        _p(60.5, 14),
        _p(60.75, 5),
        _p(70, -4),
        _p(70.375, 10),
        _p(70.5, 1),
        _p(70.75, 15),
      ]);
    });

    test('min-max start 6 count 20 width 5', () {
      // `i > 0` (plugin.decimation.js:139) is true at the first item: the
      // result starts with the item before the start.
      _expectItems(minMaxDecimation(_clustered(32), 6, 20, 5), [
        _p(10.25, -4),
        _p(10.5, 10),
        _p(17, 1),
        _p(17, 15),
        _p(20.25, 6),
        _p(20.5, -3),
        _p(30.25, 16),
        _p(30.5, 7),
        _p(37, -2),
        _p(37, 12),
        _p(40.25, 3),
        _p(40.5, 17),
        _p(47, -1),
        _p(50.25, 13),
        _p(50.5, 4),
        _p(55.375, -5),
        _p(60, 9),
        _p(60.25, 0),
      ]);
    });

    test('min-max string y', () {
      // Two strings compare by their code units: '10' < '5' and '30' > '9'.
      _expectItems(
        minMaxDecimation(
          [
            _p(0, '5'),
            _p(0.1, '10'),
            _p(0.2, '9'),
            _p(0.3, '2'),
            _p(0.4, '30'),
            _p(5, '1'),
            _p(10, '7'),
          ],
          0,
          7,
          2,
        ),
        [
          _p(0, '5'),
          _p(0.25, '10'),
          _p(0.25, '9'),
          _p(0.4, '30'),
          _p(5, '1'),
          _p(10, '7'),
        ],
      );
    });

    test('min-max string x', () {
      // `countX * avgX + point.x` joins a string x: '00.1', then '0.10.2'
      // (NaN).
      _expectItems(
        minMaxDecimation(
          [
            _p('0', 5),
            _p('0.1', 10),
            _p('0.2', 1),
            _p('0.3', 3),
            _p('5', 1),
            _p('10', 7),
          ],
          0,
          6,
          2,
        ),
        [
          _p('0', 5),
          _p(double.nan, 10),
          _p(double.nan, 1),
          _p('0.3', 3),
          _p('5', 1),
          _p('10', 7),
        ],
      );
    });

    test('min-max array items', () {
      _expectItems(
        minMaxDecimation(
          [
            _p(0, 5),
            [9, 9],
            _p(0.2, 1),
            <String, Object?>{'x': 0.3, 'y': 3, 'z': 'k'},
            _p(10, 7),
          ],
          0,
          5,
          2,
        ),
        [
          _p(0, 5),
          _p(double.nan, 1),
          <String, Object?>{'x': 0.3, 'y': 3, 'z': 'k'},
          _p(10, 7),
        ],
      );
    });

    test('min-max key order', () {
      // The spread keeps the order of Object.keys: an index key first, and
      // `x` at its own place.
      _expectItems(
        minMaxDecimation(
          [
            <String, Object?>{'y': 5, 'x': 0},
            <String, Object?>{'y': 9, '2': 'two', 'x': 0.1},
            <String, Object?>{'y': 1, 'x': 0.2},
            <String, Object?>{'y': 3, 'x': 0.3},
            <String, Object?>{'y': 7, 'x': 10},
          ],
          0,
          5,
          2,
        ),
        [
          <String, Object?>{'y': 5, 'x': 0},
          <String, Object?>{'2': 'two', 'y': 9, 'x': 0.20000000000000004},
          <String, Object?>{'y': 1, 'x': 0.20000000000000004},
          <String, Object?>{'y': 3, 'x': 0.3},
          <String, Object?>{'y': 7, 'x': 10},
        ],
      );
    });

    test('min-max Map<dynamic, dynamic> items', () {
      // An untyped literal gives a Map<dynamic, dynamic> item. The new item
      // of :124-133 has its String keys in the order of Object.keys and `x`
      // (probe fix-upstream.mjs, output fix-upstream.out, line F1a). The int
      // key 7 is not a property: jsGet never reads it, and the copy leaves
      // it out.
      final items = <Object?>[
        <dynamic, dynamic>{'x': 0, 'y': 5},
        <dynamic, dynamic>{'x': 0.1, 'y': 9, 'z': 'a', '2': 'two', 7: 'int'},
        <dynamic, dynamic>{'x': 0.2, 'y': 1},
        <dynamic, dynamic>{'x': 0.3, 'y': 3},
        <dynamic, dynamic>{'x': 10, 'y': 7},
      ];
      final decimated = minMaxDecimation(items, 0, 5, 2);
      expect(decimated, hasLength(5));
      for (final k in [0, 3, 4]) {
        expect(decimated[k], same(items[k]), reason: 'item $k');
      }
      final min = decimated[1]! as AnyObject;
      expect(jsObjectKeys(min), ['2', 'x', 'y', 'z']);
      expect(min['2'], 'two');
      expect(min['x'], 0.20000000000000004);
      expect(min['y'], 9);
      expect(min['z'], 'a');
      final max = decimated[2]! as AnyObject;
      expect(jsObjectKeys(max), ['x', 'y']);
      expect(max['x'], 0.20000000000000004);
      expect(max['y'], 1);
    });

    test('min-max dx 0', () {
      _expectItems(
        minMaxDecimation(
          [_p(1, 5), _p(1, 9), _p(1, 1), _p(1, 3)],
          0,
          4,
          10,
        ),
        [_p(1, 5)],
      );
    });

    test('min-max a null item', () {
      expect(
        () => minMaxDecimation([_p(0, 5), null, _p(1, 1)], 0, 3, 10),
        throwsA(isA<TypeError>()),
      );
    });

    test('min-max large x wraps in x | 0', () {
      _expectItems(
        minMaxDecimation(
          [_p(0, 1), _p(1, 2), _p(2, 0), _p(3, 4)],
          0,
          4,
          3000000000,
        ),
        [_p(0, 1), _p(1, 2), _p(2, 0), _p(3, 4)],
      );
    });
  });
}
