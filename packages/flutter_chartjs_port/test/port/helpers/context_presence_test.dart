// Original code, not ported from Chart.js: context membership and key order.
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:test/test.dart';

void main() {
  test('typed context refresh preserves deletion and reinsertion order', () {
    final context = ScriptableContext.data(null, 0, 'point');
    final keys = context.jsKeys();
    for (final name in keys) {
      expect(context.jsDelete(name), isTrue);
      expect(context.jsHas(name), isFalse);
      expect(context.hasOwnProperty(name), isFalse);
      expect(context.jsRead(name), same(undefined));
      context.jsWrite(name, null);
      expect(context.jsKeys().last, name);
      expect(context.jsRead(name), isNull);
      expect(context.jsHas(name), isTrue);
    }
    expect(context.jsKeys(), keys);
    context
      ..jsDelete('parsed')
      ..jsWrite('extra', 1)
      ..parsed = 'new parsed'
      ..raw = 'new raw'
      ..index = 2.0;
    expect(context.jsKeys(), [
      ...keys.where((k) => k != 'parsed'),
      'extra',
      'parsed',
    ]);
    expect(context.parsed, 'new parsed');
    expect(context.index, 2);
  });

  test('generic contexts and initial tick names keep membership in sync', () {
    final generic = ContextObject(null);
    final tick = ScriptableScaleContext.tick(generic, 'tick', 0);
    for (final context in [generic, tick]) {
      for (final name in [
        'active',
        'dataset',
        'datasetIndex',
        'dataIndex',
        'parsed',
        'raw',
        'element',
        'index',
        'mode',
        'type',
        'extra',
        '0',
      ]) {
        context.jsWrite(name, name);
        expect(context.hasProperty(name), isTrue);
        expect(context.jsRead(name), name);
        expect(context.jsDelete(name), isTrue);
        expect(context.jsDelete(name), isFalse);
        expect(context.jsHas(name), isFalse);
        context.jsWrite(name, null);
        expect(context.jsRead(name), isNull);
      }
      expect(context.jsKeys().first, '0');
    }
  });
}
