// Original code, not ported from Chart.js: tests of the typed parsed items.

import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/parsed.dart';
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:test/test.dart';

void main() {
  // The typed parsed data of Chart.js ADR 0054 §8 and the base TypedRecord.
  group('ParsedItem', () {
    test('keeps the key order of the writes', () {
      final item = ParsedItem.of(const YAxis(), 1.0, const XAxis(), 'a');
      expect(jsObjectKeys(item), ['y', 'x']);
      expect([item.x, item.y, item.r], ['a', 1.0, same(undefined)]);
      item
        ..custom = 3.0
        ..['foo'] = 'bar'
        ..stacks = ItemStacks();
      expect(jsObjectKeys(item), ['y', 'x', '_custom', 'foo', '_stacks']);
      expect(item.jsKeys(), ['y', 'x', '_custom', 'foo', '_stacks']);
      expect(item.ownKeyCount, 5);
    });

    test('of gives the record of the two writes for each pair of axes', () {
      // Each axis class with the key of its field. An axis of another class
      // has no field: its value goes (row adapt-axis-objects).
      final axes = <String, ScaleAxis>{
        'x': const XAxis(),
        'y': const YAxis(),
        'r': const RAxis(),
        'u': _OtherAxis(),
      };
      List<Object?> state(ParsedItem item) => [
        item.jsKeys(),
        item.ownKeyCount,
        for (var slot = 0; slot < 5; slot++) ...[
          item.hasSlot(slot),
          item.isForeignSlot(slot),
          item.foreignSlot(slot),
        ],
        for (var p = 0; p < item.ownKeyCount; p++) ...[
          item.keyAt(p),
          item.slotAt(p),
        ],
        for (final name in axes.keys) [item[name], item.jsHas(name)],
        item.x,
        item.y,
        item.r,
        item.custom,
        item.stacks,
      ];
      axes.forEach((aName, a) {
        axes.forEach((bName, b) {
          final reason = '$aName $bName';
          final fast = ParsedItem.of(a, 1.0, b, null);
          final writes = ParsedItem()
            ..setValue(a, 1.0)
            ..setValue(b, null);
          expect(state(fast), state(writes), reason: reason);
          // A later key goes to the end, and a key of the two stays in place.
          for (final item in [fast, writes]) {
            item
              ..custom = 3.0
              ..['extra'] = 'e'
              ..x = 7.0;
          }
          expect(state(fast), state(writes), reason: reason);
          for (final item in [fast, writes]) {
            item.jsDelete(aName);
          }
          expect(state(fast), state(writes), reason: reason);
        });
      });
    });

    test('of keeps the second value of two equal keys', () {
      final item = ParsedItem.of(const RAxis(), true, const RAxis(), 4.0);
      expect(item.jsKeys(), ['r']);
      expect(item.r, 4.0);
      expect(item.x, same(undefined));
      expect(item.ownKeyCount, 1);
    });

    test('reads by axis class and by name', () {
      final item = ParsedItem()
        ..setValue(const XAxis(), 1.0)
        ..setValue(_OtherAxis(), 2.0)
        ..['u'] = 2.0;
      expect(item.valueOf(const XAxis()), 1.0);
      expect(item.valueOf(_OtherAxis()), same(undefined));
      expect(item.valueOf(const YAxis()), same(undefined));
      expect(item.jsKeys(), ['x', 'u']);
      expect(jsGet(item, 'u'), 2.0);
      expect(jsGet(item, 'y'), same(undefined));
      expect(item['y'], same(undefined));
      expect(item.jsHas('y'), isFalse);
    });

    test('stores undefined and null as values', () {
      final item = ParsedItem()
        ..x = undefined
        ..y = null;
      expect(item.jsHas('x'), isTrue);
      expect(item['x'], same(undefined));
      expect(item.x, same(undefined));
      expect(item['y'], isNull);
      expect(jsGet(item, 'y'), isNull);
      expect(jsObjectKeys(item), ['x', 'y']);
    });

    test('a _stacks of another class is foreign', () {
      final map = <String, Object?>{};
      final item = ParsedItem()..['_stacks'] = map;
      expect(item.stacks, isNull);
      expect(item.isForeignSlot(4), isTrue);
      expect(item['_stacks'], same(map));
      final stacks = ItemStacks();
      item.stacks = stacks;
      expect(item.isForeignSlot(4), isFalse);
      expect(item.stacks, same(stacks));
    });

    test('a delete keeps the order of the other keys', () {
      final item = ParsedItem()
        ..x = 1.0
        ..['a'] = 'a'
        ..y = 2.0
        ..['b'] = 'b';
      expect(item['a'], 'a');
      expect(item.jsDelete('a'), isTrue);
      expect(jsObjectKeys(item), ['x', 'y', 'b']);
      expect(item['x'], 1.0);
      expect(item.jsDelete('x'), isTrue);
      expect(jsObjectKeys(item), ['y', 'b']);
      item.x = 3.0;
      expect(jsObjectKeys(item), ['y', 'b', 'x']);
      expect(item.jsDelete('nothing'), isFalse);
      item.jsKeys().forEach(item.jsDelete);
      expect(item.ownKeyCount, 0);
      expect(item.x, same(undefined));
    });

    test('more than 7 keys keep their order, and indices come first', () {
      final item = ParsedItem();
      for (final name in ['x', 'k1', 'k2', 'y', 'k3', 'k4', 'r', 'k5', '7']) {
        item[name] = name;
      }
      expect(item.ownKeyCount, 9);
      expect(jsObjectKeys(item), [
        '7',
        'x',
        'k1',
        'k2',
        'y',
        'k3',
        'k4',
        'r',
        'k5',
      ]);
      expect(item.jsDelete('k2'), isTrue);
      expect(item.jsKeys(), ['7', 'x', 'k1', 'y', 'k3', 'k4', 'r', 'k5']);
      expect(item.r, 'r');
    });
  });

  group('ItemStacks and StackEntry', () {
    test('an entry by axis', () {
      final entry = StackEntry();
      final stacks = ItemStacks()
        ..setEntry(const YAxis(), entry)
        ..setEntry(_OtherAxis(), StackEntry());
      expect(stacks.entryOf(const YAxis()), same(entry));
      expect(stacks.entryOf(const XAxis()), isNull);
      expect(stacks.entryOf(_OtherAxis()), isNull);
      expect(jsObjectKeys(stacks), ['y']);
    });

    test('the dataset indices come first, in ascending order', () {
      // core.datasetController.js:160-174: stack[datasetIndex] = value,
      // then _top, _bottom and _visualValues.
      final entry = StackEntry()
        ..['2'] = 5.0
        ..top = 2
        ..bottom = null
        ..['0'] = -1.0
        ..visualValues = (IndexValues()..setAt(2, 5.0));
      expect(jsObjectKeys(entry), [
        '0',
        '2',
        '_top',
        '_bottom',
        '_visualValues',
      ]);
      expect(entry.datasetValues.valueAt(0), -1.0);
      expect(entry.datasetValues.valueAt(1), same(undefined));
      expect(jsGet(entry, '2'), 5.0);
      expect(jsGet(entry, '1'), same(undefined));
      expect([entry.top, entry.bottom], [2.0, isNull]);
      expect(entry['_bottom'], isNull);
      expect(entry.jsHas('_bottom'), isTrue);
      expect(entry['2'], 5.0);
      expect(entry.jsDelete('2'), isTrue);
      expect(entry.datasetValues.indices, [0]);
      expect(entry.jsKeys(), hasLength(4));
    });

    test('a _top that is not a number is foreign', () {
      final entry = StackEntry()..['_top'] = '1';
      expect(entry.top, isNull);
      expect(entry['_top'], '1');
      expect(entry.isForeignSlot(0), isTrue);
    });

    test('IndexValues keeps the names after the indices', () {
      final values = IndexValues()
        ..['b'] = 1
        ..['10'] = 2
        ..['1'] = 3;
      expect(jsObjectKeys(values), ['1', '10', 'b']);
      expect(values.removeAt(10), isTrue);
      expect(values.removeAt(10), isFalse);
      expect(values.jsRead('10'), same(undefined));
      expect(values.ownKeyCount, 2);
    });
  });

  group('FloatingBar', () {
    test('has the keys of parseFloatBar in their order', () {
      final bar = FloatingBar(
        barStart: 1,
        barEnd: -3,
        start: 1.0,
        end: -3.0,
        min: -3,
        max: 1,
      );
      expect(jsObjectKeys(bar), [
        'barStart',
        'barEnd',
        'start',
        'end',
        'min',
        'max',
      ]);
      expect([bar.barStart, bar.barEnd, bar.min, bar.max], [1, -3, -3, 1]);
      bar['min'] = 'x';
      expect(bar.min, isNaN);
      expect(bar['min'], 'x');
      expect(bar['end'], -3.0);
      expect(bar.jsDelete('end'), isTrue);
      expect(bar.end, same(undefined));
      expect(bar['end'], same(undefined));
    });
  });
}

/// An axis of a class that the core does not know: no field of a parsed
/// item and no stack entry.
final class _OtherAxis() implements ScaleAxis;
