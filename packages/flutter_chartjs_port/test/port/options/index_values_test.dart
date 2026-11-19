// Original code, not ported from Chart.js: the dense IndexValues store.

import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:test/test.dart';

/// The store of `IndexValues` before Chart.js ADR 0152: a tree by index and
/// a Map of the named keys. Each operation gives the result of a plain JS
/// object with these keys.
class _Reference() {
  final SplayTreeMap<int, Object?> values = SplayTreeMap<int, Object?>();
  final Map<String, Object?> named = <String, Object?>{};

  List<String> keys() => [for (final i in values.keys) '$i', ...named.keys];
}

void _expectSame(IndexValues actual, _Reference expected, int span) {
  expect(actual.jsKeys(), expected.keys());
  expect(actual.ownKeyCount, expected.values.length + expected.named.length);
  expect(actual.indices.toList(), expected.values.keys.toList());
  for (var i = -2; i < span; i++) {
    expect(actual.hasIndex(i), expected.values.containsKey(i), reason: '$i');
    final value = actual.valueAt(i);
    if (expected.values.containsKey(i)) {
      expect(value, expected.values[i], reason: '$i');
    } else {
      expect(value, same(undefined), reason: '$i');
    }
  }
}

void main() {
  group('IndexValues (Chart.js ADR 0152)', () {
    test('random writes, deletes and reads match the tree store', () {
      for (final seed in [1, 2, 3, 4, 5, 6, 7, 8]) {
        final random = math.Random(seed);
        final actual = IndexValues();
        final expected = _Reference();
        // Seed 8 and up reach the tree form with large keys.
        final span = seed < 7 ? 24 : 3000;
        for (var step = 0; step < 400; step++) {
          final index = random.nextInt(span);
          final value = switch (random.nextInt(5)) {
            0 => null,
            1 => undefined,
            2 => 'v$step',
            _ => random.nextDouble() - .5,
          };
          switch (random.nextInt(8)) {
            case 0 || 1 || 2:
              actual.setAt(index, value);
              expected.values[index] = value;
            case 3:
              actual.jsWrite('$index', value);
              expected.values[index] = value;
            case 4:
              expect(
                actual.removeAt(index),
                expected.values.containsKey(index),
              );
              expected.values.remove(index);
            case 5:
              final had =
                  expected.values.containsKey(index) ||
                  expected.named.containsKey('$index');
              expect(actual.jsDelete('$index'), had);
              expected.values.remove(index);
            case 6:
              actual.jsWrite('n${index % 3}', value);
              expected.named['n${index % 3}'] = value;
            default:
              expect(
                actual.jsHas('$index'),
                expected.values.containsKey(index),
              );
              expect(
                actual.jsRead('$index'),
                expected.values.containsKey(index)
                    ? expected.values[index]
                    : same(undefined),
              );
          }
        }
        _expectSame(actual, expected, math.min(span, 64));
      }
    });

    test('a value of null or undefined is an own key', () {
      final values = IndexValues()
        ..setAt(2, null)
        ..setAt(0, undefined);
      expect(values.jsKeys(), ['0', '2']);
      expect(values.hasIndex(1), isFalse);
      expect(values.valueAt(1), same(undefined));
      expect(values.valueAt(2), isNull);
      expect(values.ownKeyCount, 2);
    });

    test('a negative or a large index keeps the ascending key order', () {
      final values = IndexValues()
        ..setAt(3, 'c')
        ..setAt(1, 'a')
        ..setAt(5000, 'x')
        ..setAt(2, 'b');
      expect(values.jsKeys(), ['1', '2', '3', '5000']);
      values.setAt(-1, 'm');
      expect(values.indices.toList(), [-1, 1, 2, 3, 5000]);
      expect(values.valueAt(-1), 'm');
      expect(values.removeAt(3), isTrue);
      expect(values.removeAt(3), isFalse);
      expect(values.jsKeys(), ['-1', '1', '2', '5000']);
    });

    test('a high index alone keeps the tree: no slot for each lower '
        'index', () {
      final alone = IndexValues()..setAt(500, 'x');
      expect(alone.denseSlots, 0);
      expect(alone.jsKeys(), ['500']);
      expect(alone.valueAt(500), 'x');
      expect(alone.valueAt(499), same(undefined));
      // Few datasets with high indexes in one stack: the tree too.
      final few = IndexValues()
        ..setAt(3, 'a')
        ..setAt(40, 'b')
        ..setAt(900, 'c');
      expect(few.denseSlots, 0);
      expect(few.jsKeys(), ['3', '40', '900']);
      // Dense indexes stay dense, with at most about two slots for each key.
      final dense = IndexValues();
      for (var i = 0; i < 200; i += 2) {
        dense.setAt(i, i);
      }
      expect(dense.denseSlots, 199);
      expect(dense.indices.length, 100);
      expect(IndexValues().denseSlots, 0);
    });

    test('a key that is not an index follows the indices', () {
      final values = IndexValues()
        ..jsWrite('foo', 1)
        ..setAt(4, 2)
        ..jsWrite('0', 3);
      expect(values.jsKeys(), ['0', '4', 'foo']);
      expect(values.jsRead('foo'), 1);
      expect(values.jsDelete('foo'), isTrue);
      expect(values.jsKeys(), ['0', '4']);
    });
  });
}
