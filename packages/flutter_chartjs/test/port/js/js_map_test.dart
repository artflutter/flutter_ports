// Original code, not ported from Chart.js: tests of lib/src/js/js_map.dart.
import 'package:flutter_chartjs/src/js/js_map.dart';
import 'package:test/test.dart';

// The expected visits come from Map.prototype.forEach in Node.js v24.12.0
// (V8 13.6) on x64, with the same changes in the callback.

/// `[visits, keys]`: the keys that `jsMapForEach` visits on a Map of
/// [keys], with [change] in the callback, and the keys after the walk.
List<List<String>> _walk(
  List<String> keys,
  void Function(Map<String, String> map, String key) change,
) {
  final map = {for (final key in keys) key: key};
  final seen = <String>[];
  jsMapForEach<String, String>(map, (value, key) {
    seen.add(key);
    change(map, key);
  });
  return [seen, map.keys.toList()];
}

void main() {
  group('jsMapForEach', () {
    test('visits each entry in insertion order with its value and key', () {
      final calls = <(Object?, Object?)>[];
      jsMapForEach<String, int>({'b': 1, 'a': 2, '1': 3}, (value, key) {
        calls.add((key, value));
      });
      expect(calls, [('b', 1), ('a', 2), ('1', 3)]);
    });

    test('skips a key that the callback deletes before its visit', () {
      expect(
        _walk(['a', 'b', 'c'], (map, key) {
          if (key == 'a') map.remove('c');
        }),
        [
          ['a', 'b'],
          ['a', 'b'],
        ],
      );
    });

    test('visits a key that the callback adds', () {
      expect(
        _walk(['a', 'b', 'c'], (map, key) {
          if (key == 'a') map['d'] = 'd';
        }),
        [
          ['a', 'b', 'c', 'd'],
          ['a', 'b', 'c', 'd'],
        ],
      );
      // A key that the visit of an added key adds.
      expect(
        _walk(['a'], (map, key) {
          if (key == 'a') map['b'] = 'b';
          if (key == 'b') map['c'] = 'c';
        }),
        [
          ['a', 'b', 'c'],
          ['a', 'b', 'c'],
        ],
      );
    });

    test('allows the callback to delete its own key', () {
      expect(
        _walk(['a', 'b'], (map, key) {
          if (key == 'a') map.remove('a');
        }),
        [
          ['a', 'b'],
          ['b'],
        ],
      );
    });

    test('gives the current value of a key that the callback changes', () {
      final values = <String>[];
      final map = {'a': '1', 'b': '2'};
      jsMapForEach<String, String>(map, (value, key) {
        values.add(value);
        if (key == 'a') map['b'] = 'B';
      });
      expect(values, ['1', 'B']);
    });

    test('documents the two cases that differ from ECMAScript', () {
      // A delete and an add again after the visit: Node.js visits a, b, a.
      // The port visits each key one time.
      var once = false;
      expect(
        _walk(['a', 'b'], (map, key) {
          if (key == 'a' && !once) {
            once = true;
            map
              ..remove('a')
              ..['a'] = 'a2';
          }
        }),
        [
          ['a', 'b'],
          ['b', 'a'],
        ],
      );
      // A delete and an add again before the visit: Node.js visits a, c, b.
      // The port visits b at its old place.
      once = false;
      expect(
        _walk(['a', 'b', 'c'], (map, key) {
          if (key == 'a' && !once) {
            once = true;
            map
              ..remove('b')
              ..['b'] = 'b';
          }
        }),
        [
          ['a', 'b', 'c'],
          ['a', 'c', 'b'],
        ],
      );
    });

    test('a Dart Map.forEach throws for the same changes', () {
      // The reason of jsMapForEach (Chart.js ADR 0019, section 8).
      final map = {'a': 1, 'b': 2};
      expect(
        () => map.forEach((key, value) => map['c'] = 3),
        throwsConcurrentModificationError,
      );
    });
  });
}
