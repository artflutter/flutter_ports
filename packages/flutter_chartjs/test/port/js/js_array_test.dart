// Original code, not ported from Chart.js: tests of lib/src/js/js_array.dart.
import 'package:flutter_chartjs/src/helpers/helpers.config.dart'
    show createResolver;
import 'package:flutter_chartjs/src/js/js_array.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:test/test.dart';

// The expected values come from Node.js v24.12.0 (V8 13.6): array.sort(compare)
// and Object.keys(object) for each input, Object.getOwnPropertyNames of an
// object and of a resolver of the pinned helpers.config.ts, and the write
// array[index] = value.

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

  group('jsOwnPropertyNames', () {
    test('gives the keys of a Map in the order of Object.keys', () {
      // Object.getOwnPropertyNames({b: 1, 10: 2, a: 3, 2: 4}).
      expect(
        jsOwnPropertyNames(<String, Object?>{'b': 1, '10': 2, 'a': 3, '2': 4}),
        ['2', '10', 'b', 'a'],
      );
      expect(jsOwnPropertyNames(<String, Object?>{}), isEmpty);
    });

    test('gives the ownKeys trap of a resolver, with the later scopes', () {
      // _createResolver([{a: 1, 10: 'x'}, {b: 2, a: 3, 2: 'y'}]): the own
      // names are ['10', 'a', '2', 'b'], and Object.keys gives ['10', 'a'].
      final resolver = createResolver([
        <String, Object?>{'a': 1, '10': 'x'},
        <String, Object?>{'b': 2, 'a': 3, '2': 'y'},
      ]);
      expect(jsOwnPropertyNames(resolver), ['10', 'a', '2', 'b']);
      expect(jsObjectKeys(resolver), ['10', 'a']);
    });
  });

  group('jsSplice', () {
    // [0, 1, 2, 3, 4].splice(...args) in Node.js v24.12.0 on x64: the
    // arguments, the removed elements and the array after the call. Dart
    // null stands for an absent deleteCount.
    final cases = <(double, double?, List<Object?>, List<int>, List<Object?>)>[
      (1, 2, [], [1, 2], [0, 3, 4]),
      (1, null, [], [1, 2, 3, 4], [0]),
      (-1, 1, [], [4], [0, 1, 2, 3]),
      (-10, 2, [], [0, 1], [2, 3, 4]),
      (7, 2, [], [], [0, 1, 2, 3, 4]),
      (2, 10, [], [2, 3, 4], [0, 1]),
      (2, -3, [], [], [0, 1, 2, 3, 4]),
      (1.7, 1.9, [], [1], [0, 2, 3, 4]),
      (double.nan, 2, [], [0, 1], [2, 3, 4]),
      (1, double.nan, [], [], [0, 1, 2, 3, 4]),
      (double.infinity, 1, [], [], [0, 1, 2, 3, 4]),
      (double.negativeInfinity, 1, [], [0], [1, 2, 3, 4]),
      (1, double.infinity, [], [1, 2, 3, 4], [0]),
      (1, 0, ['a', 'b'], [], [0, 'a', 'b', 1, 2, 3, 4]),
      (1, 2, ['a'], [1, 2], [0, 'a', 3, 4]),
      (-2, -0.5, ['a'], [], [0, 1, 2, 'a', 3, 4]),
    ];
    for (final (start, deleteCount, items, removed, after) in cases) {
      test('splice($start, $deleteCount, ...$items)', () {
        final list = <Object?>[0, 1, 2, 3, 4];
        expect(jsSplice(list, start, deleteCount, items), removed);
        expect(list, after);
      });
    }

    test('an empty array', () {
      // [].splice(-1, 1) and [].splice(0, 0, 'a').
      final empty = <Object?>[];
      expect(jsSplice(empty, -1, 1), isEmpty);
      expect(empty, isEmpty);
      expect(jsSplice(empty, 0, 0, ['a']), isEmpty);
      expect(empty, ['a']);
    });
  });

  group('jsSetIndex', () {
    test('appends at the length', () {
      // const a = [1, 2]; a[2] = 3 gives [1, 2, 3].
      final list = <Object?>[1.0, 2.0];
      jsSetIndex(list, 2, 3.0);
      expect(list, [1.0, 2.0, 3.0]);
      final empty = <Object?>[];
      jsSetIndex(empty, 0, 'a');
      expect(empty, ['a']);
    });

    test('replaces an item below the length', () {
      // const a = [1, 2]; a[0] = 9 gives [9, 2].
      final list = <Object?>[1.0, 2.0];
      jsSetIndex(list, 0, 9.0);
      expect(list, [9.0, 2.0]);
    });

    test('throws a RangeError past the length', () {
      // const a = [1, 2]; a[3] = 9 gives the length 4 and a hole at 2 in
      // JavaScript (differences.md row platform-array-events).
      final list = <Object?>[1.0, 2.0];
      expect(() => jsSetIndex(list, 3, 9.0), throwsA(isA<RangeError>()));
      expect(list, [1.0, 2.0]);
    });

    test('throws a RangeError for a negative index', () {
      // const a = [1, 2]; a[-1] = 9 writes the property '-1' in JavaScript:
      // no throw, and the length stays 2 (differences.md row
      // platform-array-events).
      final list = <Object?>[1.0, 2.0];
      expect(() => jsSetIndex(list, -1, 9.0), throwsA(isA<RangeError>()));
      expect(list, [1.0, 2.0]);
    });

    test('throws a TypeError for a value of another type', () {
      // A List<int> takes no double: the run-time check of the covariant
      // type argument fails, at the length and below it. The value is not
      // whole, because a whole double is an int on dart2js.
      final List<Object?> ints = <int>[1, 2];
      expect(() => jsSetIndex(ints, 2, 3.5), throwsA(isA<TypeError>()));
      expect(() => jsSetIndex(ints, 0, 3.5), throwsA(isA<TypeError>()));
      expect(ints, [1, 2]);
    });
  });

  group('JsStringList', () {
    test('reads the UTF-16 code units of the string', () {
      // const s = 'a\u{1F600}'; s.length is 3, s[0] is 'a', and s[1] and
      // s[2] are the two surrogates.
      final list = JsStringList('a\u{1F600}');
      expect(list.string, 'a\u{1F600}');
      expect(list, hasLength(3));
      expect(list, ['a', '\uD83D', '\uDE00']);
      expect(JsStringList(''), isEmpty);
    });

    test('throws a TypeError for each write', () {
      // 'use strict'; const s = 'abc'; s[0] = 'x', s[5] = 'x' and
      // s.length = 1 throw a TypeError.
      final list = JsStringList('abc');
      expect(() => list[0] = 'x', throwsA(isA<TypeError>()));
      expect(() => jsSetIndex(list, 3, 'x'), throwsA(isA<TypeError>()));
      expect(() => list.length = 1, throwsA(isA<TypeError>()));
      expect(() => list.add('x'), throwsA(isA<TypeError>()));
      expect(list, ['a', 'b', 'c']);
    });
  });
}
