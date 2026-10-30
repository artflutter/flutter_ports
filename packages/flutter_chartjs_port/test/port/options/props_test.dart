// Original code, not ported from Chart.js: tests of the typed properties.

import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/animated_prop.dart';
import 'package:flutter_chartjs_port/src/options/props.dart';
import 'package:test/test.dart';

void main() {
  // The property objects of the controllers (Chart.js ADR 0054 §9).
  group('properties', () {
    test('PointProperties keeps the order of the writes', () {
      // controller.line.js:91-111 with the index axis y.
      final options = <String, Object?>{};
      final p = PointProperties()
        ..y = 10
        ..x = 20
        ..skip = false
        ..stop = true
        ..parsed = {'x': 1}
        ..raw = 1
        ..options = options;
      expect(jsObjectKeys(p), [
        'y',
        'x',
        'skip',
        'stop',
        'parsed',
        'raw',
        'options',
      ]);
      expect([p.x, p.y, p.skip, p.stop], [20, 10, false, true]);
      expect(p.options, same(options));
      expect(p.angle, isNaN);
      expect(jsGet(p, 'angle'), same(undefined));
      expect(p['angle'], isNull);
    });

    test('BarProperties has the literal of controller.bar.js', () {
      final p = BarProperties()
        ..horizontal = false
        ..base = 100
        ..enableBorderRadius = true
        ..x = 1
        ..y = 2
        ..height = 3
        ..width = 4
        ..['borderSkipped'] = {'top': true}
        ..inflateAmount = 0.33;
      expect(jsObjectKeys(p), [
        'horizontal',
        'base',
        'enableBorderRadius',
        'x',
        'y',
        'height',
        'width',
        'borderSkipped',
        'inflateAmount',
      ]);
      expect(p.borderSkipped, {'top': true});
    });

    test('ArcProperties and LineProperties', () {
      final arc = ArcProperties()
        ..x = 0
        ..y = 0
        ..innerRadius = 0
        ..outerRadius = 10
        ..startAngle = 1
        ..endAngle = 2;
      expect(jsObjectKeys(arc), [
        'x',
        'y',
        'innerRadius',
        'outerRadius',
        'startAngle',
        'endAngle',
      ]);
      final line = LineProperties()
        ..loop = true
        ..fullLoop = false;
      expect(jsObjectKeys(line), ['_loop', '_fullLoop']);
      expect(line['_loop'], true);
    });

    test('a write by name outside the type is foreign', () {
      final p = PointProperties()
        ..['x'] = '5'
        ..['skip'] = 1
        ..['options'] = 'no';
      expect(p.x, 5);
      expect(p['x'], '5');
      expect(p.skip, isTrue);
      expect(p['skip'], 1);
      expect(p.options, isNull);
      expect(p['options'], 'no');
      p.x = 6;
      expect(p['x'], 6);
      expect(p.isForeignSlot(0), isFalse);
    });
  });

  group('AnimatedProp', () {
    test('the built-in names map to their instances', () {
      for (final (id, prop) in AnimatedProp.builtIns.indexed) {
        expect(prop.id, id);
        expect(identical(AnimatedProp.of(prop.name), prop), isTrue);
        expect(prop.isCustom, isFalse);
      }
      expect(AnimatedProp.builtIns.map((p) => p.name).toSet(), hasLength(22));
    });

    test('another name is a custom prop', () {
      final prop = AnimatedProp.of('foo');
      expect(prop.id, -1);
      expect(prop.isCustom, isTrue);
      expect(prop, const AnimatedProp.custom('foo'));
      expect(prop.hashCode, 'foo'.hashCode);
    });
  });
}
