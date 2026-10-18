// Original code, not ported from Chart.js: tests of lib/src/js/js_array.dart.
import 'package:flutter_chartjs/src/js/js_array.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:test/test.dart';

// The expected values come from Node.js v24.12.0 (V8 13.6): array.sort(compare)
// and Object.keys(object) for each input.

/// An element with a sort key and its position before the sort.
typedef _Item = ({int key, int position});

void main() {
  group('jsSort', () {
    test('sorts numbers with a numeric comparator', () {
      final list = <double>[10, 9, 1, 2, 100, -1, 0.5];
      expect(jsSort(list, (a, b) => a - b), [-1, 0.5, 1, 2, 9, 10, 100]);
    });

    test('sorts in place and returns the list', () {
      final list = <double>[3, 1, 2];
      final sorted = jsSort(list, (a, b) => a - b);
      expect(identical(sorted, list), isTrue);
      expect(list, [1, 2, 3]);
    });

    test('is stable above 32 elements', () {
      // 200 elements with 5 keys: List.sort reorders equal keys on the VM.
      final list = <_Item>[
        for (var i = 0; i < 200; i++) (key: (i * 7) % 5, position: i),
      ];
      jsSort<_Item>(list, (a, b) => a.key - b.key);
      for (var i = 1; i < list.length; i++) {
        final (previous, current) = (list[i - 1], list[i]);
        expect(previous.key, lessThanOrEqualTo(current.key));
        if (previous.key == current.key) {
          expect(previous.position, lessThan(current.position));
        }
      }
    });

    test('reads a NaN result as equal', () {
      // [3, 1, 2].sort(() => NaN) is [3, 1, 2] in V8.
      final list = <double>[3, 1, 2];
      expect(jsSort(list, (a, b) => double.nan), [3, 1, 2]);

      // NaN keeps the order of the NaN keys; the numbers sort around them.
      // [{k: 2}, {k: NaN}, {k: 1}, {k: NaN}].sort((a, b) => a.k - b.k)
      // keeps every element in place in V8: each pair with a NaN is equal.
      final items = <(double, String)>[
        (2, 'a'),
        (double.nan, 'b'),
        (1, 'c'),
        (double.nan, 'd'),
      ];
      jsSort(items, (a, b) => a.$1 - b.$1);
      expect([for (final (_, name) in items) name], ['a', 'b', 'c', 'd']);
    });

    test('reads only the sign of the result', () {
      final list = <double>[0.3, 0.1, 0.2];
      // The differences are fractions: List.sort with toInt() sees 0.
      expect(jsSort(list, (a, b) => a - b), [0.1, 0.2, 0.3]);
      expect(jsSort(list, (a, b) => (b - a) * 1e300), [0.3, 0.2, 0.1]);
      expect(
        jsSort(list, (a, b) => a < b ? double.negativeInfinity : 1),
        [0.1, 0.2, 0.3],
      );
    });

    test('reads -0 as equal', () {
      final list = <String>['b', 'a', 'c'];
      expect(jsSort(list, (a, b) => -0.0), ['b', 'a', 'c']);
    });

    test('sorts an empty list and one element', () {
      expect(jsSort(<double>[], (a, b) => a - b), isEmpty);
      expect(jsSort(<double>[1], (a, b) => a - b), [1]);
    });
  });

  group('jsObjectKeys', () {
    test('puts array indices first, in numeric order', () {
      final object = <String, Object?>{
        'b': 1,
        '2': 1,
        'a': 1,
        '4294967294': 1,
        '4294967295': 1,
        '01': 1,
        '-0': 1,
        '1.0': 1,
        '0': 1,
        '-1': 1,
        '9007199254740991': 1,
        '10': 1,
        ' 1': 1,
        '1e3': 1,
        '4294967293': 1,
        '': 1,
        '1': 1,
      };
      expect(jsObjectKeys(object), [
        '0',
        '1',
        '2',
        '10',
        '4294967293',
        '4294967294',
        'b',
        'a',
        '4294967295',
        '01',
        '-0',
        '1.0',
        '-1',
        '9007199254740991',
        ' 1',
        '1e3',
        '',
      ]);
    });

    test('keeps the insertion order of other keys', () {
      final object = <String, Object?>{'x': 1, '3': 2, '1': 3, 'y': 4, '0': 5};
      expect(jsObjectKeys(object), ['0', '1', '3', 'x', 'y']);
      expect(jsObjectKeys({'z': 1, 'a': 2, 'm': 3}), ['z', 'a', 'm']);
    });

    test('lists keys with null values', () {
      expect(jsObjectKeys({'a': null, 'b': 1}), ['a', 'b']);
    });

    test('lists keys with undefined values', () {
      // Object.keys({a: undefined, b: null, 1: undefined}) is ['1', 'a', 'b'].
      expect(jsObjectKeys({'a': undefined, 'b': null, '1': undefined}), [
        '1',
        'a',
        'b',
      ]);
    });

    test('gives an empty list for an empty object', () {
      expect(jsObjectKeys(<String, Object?>{}), isEmpty);
    });

    test('rejects keys with more than ten digits', () {
      expect(jsObjectKeys({'a': 1, '42949672940': 2, '7': 3}), [
        '7',
        'a',
        '42949672940',
      ]);
    });
  });

  group('jsArrayIndex', () {
    test('reads the canonical strings of 0 to 2^32 - 2', () {
      expect(jsArrayIndex('0'), 0);
      expect(jsArrayIndex('7'), 7);
      expect(jsArrayIndex('4294967294'), 4294967294);
    });

    test('rejects other strings', () {
      for (final key in [
        '',
        '01',
        '-0',
        '-1',
        '+1',
        '1.0',
        ' 1',
        '1e3',
        '0x1',
        'length',
        '4294967295',
        '42949672940',
      ]) {
        expect(jsArrayIndex(key), isNull, reason: key);
      }
    });
  });
}
