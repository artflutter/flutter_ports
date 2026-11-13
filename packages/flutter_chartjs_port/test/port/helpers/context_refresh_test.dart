// Original code, not ported from Chart.js: the bulk refresh of a data context.
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:test/test.dart';

const _names = ['parsed', 'raw', 'dataIndex', 'index', 'active', 'mode'];

/// The six writes of `getContext`, each through its setter.
void _ordinary(ScriptableContext context, double index) => context
  ..parsed = 'parsed $index'
  ..raw = 'raw $index'
  ..dataIndex = index
  ..index = index
  ..active = false
  ..mode = 'none';

Object? _state(ScriptableContext context) => [
  context.jsKeys(),
  for (final name in context.jsKeys())
    if (name != 'element') context.jsRead(name),
];

void main() {
  test('all subsets of deleted keys reinsert in the order of getContext', () {
    for (var deleted = 0; deleted < 1 << _names.length; deleted++) {
      for (final extra in [false, true]) {
        ScriptableContext start() {
          final context = ScriptableContext.data(null, 7, 'point');
          if (extra) context.jsWrite('note', 1);
          for (var bit = 0; bit < _names.length; bit++) {
            if (deleted & (1 << bit) != 0) context.jsDelete(_names[bit]);
          }
          if (extra) context.jsWrite('after', 2);
          return context;
        }

        final expected = start();
        _ordinary(expected, 3);
        // The interpolation gives the text of `_ordinary` on each target: the
        // text of a whole double has no `.0` on JavaScript.
        final bulk = start()
          ..refresh('parsed ${3.0}', 'raw ${3.0}', 3, false, 'none');
        expect(_state(bulk), _state(expected), reason: 'deleted $deleted');
        expect(bulk.dataIndex, 3);
        expect(bulk.index, 3);
      }
    }
  });

  test(
    'the writes after parsed keep a delete of parsed in the read of raw',
    () {
      for (final name in _names) {
        ScriptableContext start() {
          final context = ScriptableContext.data(null, 7, 'point');
          if (name != 'parsed') context.parsed = 'old';
          context.jsDelete(name);
          return context;
        }

        final expected = start()
          ..raw = 'raw'
          ..dataIndex = 1
          ..index = 1
          ..active = true
          ..mode = undefined;
        final bulk = start()..refreshAfterParsed('raw', 1, true, undefined);
        expect(_state(bulk), _state(expected), reason: name);
        expect(bulk.jsHas('parsed'), name != 'parsed');
      }
    },
  );

  test('the index fields take each index, also over a string', () {
    final context = ScriptableContext.data(null, 0, 'point')
      ..jsWrite('index', 'three')
      ..jsWrite('dataIndex', 'four')
      ..refresh(1, 2, 3, false, 'none');
    expect(context.index, 3);
    expect(context.dataIndex, 3);

    // A dataIndex that a user changed takes the index of the refresh.
    context
      ..index = 5
      ..dataIndex = 9
      ..refresh(1, 2, 5, false, 'none');
    expect(context.dataIndex, 5);
    expect(context.index, 5);
  });

  test('a refresh changes no other key and no prototype', () {
    final parent = ScriptableContext.dataset(null, 2);
    final context = ScriptableContext.data(parent, 0, 'point')
      ..refresh('p', 'r', 4, false, 'default');
    expect(context.jsRead('element'), 'point');
    expect(context.jsRead('type'), 'data');
    expect(context.jsRead('datasetIndex'), 2);
    expect(parent.index, 2);
    expect(parent.mode, 'default');
    expect(context.jsKeys(), [
      'active',
      'dataIndex',
      'parsed',
      'raw',
      'element',
      'index',
      'mode',
      'type',
    ]);
  });

  test('the index key test follows the own keys', () {
    final context = ScriptableContext.data(null, 0, 'point');
    expect(context.hasIndexKey, isTrue);
    context.jsDelete('index');
    expect(context.hasIndexKey, isFalse);
    expect(context.hasIndexKey, context.jsHas('index'));
    context.jsWrite('index', 1.0);
    expect(context.hasIndexKey, isTrue);
    expect(ScriptableContext(null).hasIndexKey, isFalse);
  });
}
