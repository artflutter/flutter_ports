// Original code, not ported from Chart.js: the bulk refresh of a data context.
import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:test/test.dart';

void main() {
  test('a refresh writes the six fields of getContext', () {
    final context = ScriptableContext.data(null, 7, null)
      ..refresh('parsed', 'raw', 3, true, UpdateMode.none);
    expect(context.parsed, 'parsed');
    expect(context.raw, 'raw');
    expect(context.dataIndex, 3);
    expect(context.index, 3);
    expect(context.active, isTrue);
    expect(context.mode, UpdateMode.none);
  });

  test('a refresh gives Dart null for undefined and for no mode', () {
    final context = ScriptableContext.data(null, 0, null)
      ..refresh(undefined, undefined, 1, false, null);
    expect(context.parsed, isNull);
    expect(context.raw, isNull);
    expect(context.mode, isNull);
  });

  test('the index fields take each index', () {
    final context = ScriptableContext.data(null, 0, null)
      ..index = 5
      ..dataIndex = 9
      ..refresh(1, 2, 5, false, UpdateMode.none);
    expect(context.dataIndex, 5);
    expect(context.index, 5);
  });

  test('a refresh changes no other field and not the parent', () {
    final parent = ScriptableContext.dataset(null, 2)..dataset = 'dataset';
    final element = PointElement();
    final context = ScriptableContext.data(parent, 0, element)
      ..refresh('p', 'r', 4, false, UpdateMode.defaultMode);
    expect(context.element, same(element));
    expect(context.type, 'data');
    expect(context.datasetIndex, 2);
    expect(context.dataset, 'dataset');
    expect(parent.index, 2);
    expect(parent.dataIndex, isNull);
    expect(parent.mode, UpdateMode.defaultMode);
  });
}
