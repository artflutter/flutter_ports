// Original code, not ported from Chart.js: tests of the typed parsed items.

import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/parsed.dart';
import 'package:test/test.dart';

void main() {
  // The typed parsed data of Chart.js ADR 0054 §8 and the base TypedRecord.
  group('ParsedItem', () {
    test('keeps the key order of the writes', () {
      final item = ParsedItem.of(AxisKey.y, 'y', 1.0, AxisKey.x, 'x', 'a');
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

    test('reads by axis key and by name', () {
      final item = ParsedItem()
        ..setValue(AxisKey.x, 'x', 1.0)
        ..setValue(AxisKey.other, 'u', 2.0);
      expect(AxisKey.of('u'), AxisKey.other);
      expect(AxisKey.of('r'), AxisKey.r);
      expect(item.valueOf(AxisKey.x), 1.0);
      expect(item.valueOf(AxisKey.other, 'u'), 2.0);
      expect(item.valueOf(AxisKey.y), same(undefined));
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
        ..setEntry(AxisKey.y, 'y', entry)
        ..setEntry(AxisKey.other, 'v', StackEntry());
      expect(stacks.entryOf(AxisKey.y), same(entry));
      expect(stacks.entryOf(AxisKey.x), isNull);
      expect(stacks.entryOf(AxisKey.other, 'v'), isA<StackEntry>());
      expect(jsObjectKeys(stacks), ['y', 'v']);
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
