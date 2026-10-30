// Original code, not ported from Chart.js: tests of the typed option scopes.

// The typed scopes of Chart.js ADR 0054 §3 and their face (§5): the own-key
// order of JS, the extras, the three states of a key, the foreign values,
// the typed setters, the generated kinds and the deep clone.

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:test/test.dart';

Object? _fn(Object? ctx) => ctx;

void main() {
  group('the key order', () {
    test('a set of an absent key appends it, extras included', () {
      final scope = PointOptionsScope()
        ..radius = 3.0
        ..jsWrite('extraKey', 5.0)
        ..borderWidth = 1.0;
      expect(scope.jsKeys(), ['radius', 'extraKey', 'borderWidth']);
      scope.radius = 4.0;
      expect(scope.jsKeys(), ['radius', 'extraKey', 'borderWidth']);
    });

    test('a delete removes the key, and a new set appends it', () {
      final scope = PointOptionsScope()
        ..radius = 3.0
        ..rotation = 0.0
        ..hitRadius = 1.0;
      expect(scope.jsDelete('rotation'), isTrue);
      expect(scope.jsDelete('rotation'), isFalse);
      expect(scope.jsKeys(), ['radius', 'hitRadius']);
      scope.rotation = 15.0;
      expect(scope.jsKeys(), ['radius', 'hitRadius', 'rotation']);
      expect(scope.ownKeys, [
        OptionKey.radius,
        OptionKey.hitRadius,
        OptionKey.rotation,
      ]);
    });

    test('the cell setter with null deletes the key', () {
      final scope = PointOptionsScope()
        ..radius = 3.0
        ..radiusCell = null;
      expect(scope.jsKeys(), isEmpty);
      expect(scope.radiusCell, isNull);
    });
  });

  group('the three states', () {
    test('absent, undefined and null stay apart', () {
      final scope = PointOptionsScope()
        ..jsWrite('pointStyle', undefined)
        ..jsWrite('backgroundColor', null);
      expect(scope.jsHas('radius'), isFalse);
      expect(scope.jsRead('radius'), same(undefined));
      expect(scope.jsHas('pointStyle'), isTrue);
      expect(scope.pointStyleCell, same(optUndefined));
      expect(scope.jsRead('pointStyle'), same(undefined));
      expect(scope.jsHas('backgroundColor'), isTrue);
      expect(scope.jsRead('backgroundColor'), isNull);
      expect(scope.jsKeys(), ['pointStyle', 'backgroundColor']);
    });
  });

  group('the cells of a write by name', () {
    test('a number key keeps a string as a foreign cell', () {
      final scope = PointOptionsScope()..jsWrite('radius', '5');
      expect(scope.radiusCell, isA<OptForeign<double>>());
      expect(scope.jsRead('radius'), '5');
    });

    test('a function, an array and an object keep their objects', () {
      final list = <Object?>[1.0, 2.0];
      final map = <String, Object?>{'size': 12.0};
      final scope = ChartOptionsScope()
        ..jsWrite('backgroundColor', _fn)
        ..jsWrite('events', list)
        ..jsWrite('font', map);
      expect(scope.backgroundColorCell, isA<OptFunction<Object>>());
      expect(scope.jsRead('backgroundColor'), same(_fn));
      expect(scope.jsRead('events'), same(list));
      expect(scope.fontCell, isA<OptScope<FontSpecScope>>());
      expect(scope.jsRead('font'), same(map));
    });

    test('a number is a double', () {
      final scope = PointOptionsScope()..jsWrite('radius', 3);
      expect(scope.jsRead('radius'), isA<double>());
    });
  });

  group('the extras', () {
    test('a name that the kind does not declare is an extra', () {
      final scope = PointOptionsScope()..jsWrite('cutout', '50%');
      expect(scope.lookup(OptionKey.cutout)!.raw, '50%');
      expect(scope.lookup('cutout')!.raw, '50%');
      expect(scope.jsKeys(), ['cutout']);
      expect(scope.ownKeys, ['cutout']);
    });

    test('a dictionary classifies its extras by others', () {
      final elements = ElementOptionsByTypeScope()
        ..jsWrite('tbar', <String, Object?>{'a': 1.0})
        ..jsWrite('point', PointOptionsScope());
      expect(
        elements.lookup('tbar'),
        isA<OptScope<GenericElementOptionsScope>>(),
      );
      expect(elements.pointCell, isA<OptScope<PointOptionsScope>>());
      final scales = ScaleOptionsByIdScope()..jsWrite('x', 'oops');
      expect(scales.lookup('x'), isA<OptForeign<ScaleOptionsScope>>());
    });

    test('the descriptor keys', () {
      final descriptors = DescriptorsScope()
        ..jsWrite('_scriptable', _fn)
        ..jsWrite('elements', <String, Object?>{});
      expect(descriptors.descScriptableCell, isA<OptFunction<Object>>());
      expect(
        descriptors.lookup('elements'),
        isA<OptScope<DescriptorsScope>>(),
      );
    });
  });

  group('the kinds', () {
    test('each kind creates its class and declares its keys', () {
      for (final kind in ScopeKind.values) {
        final scope = kind.create();
        expect(scope.kind, kind);
        for (final key in kind.keys) {
          expect(scope.hasField(key), isTrue, reason: '$kind $key');
          expect(kind.shapeOf(key), isNot(0), reason: '$kind $key');
          expect(scope.cellOf(key), isNull);
        }
      }
    });

    test('a nested kind and the optionKeyOf switch', () {
      expect(
        ScopeKind.chartOptions.childKind(OptionKey.font),
        ScopeKind.fontSpec,
      );
      expect(ScopeKind.elementOptionsByType.othersKind, isNotNull);
      expect(optionKeyOf('pointRadius'), OptionKey.pointRadius);
      expect(optionKeyOf('noSuchOption'), isNull);
      expect(OptionKey.descScriptable.jsName, '_scriptable');
    });
  });

  group('the clone', () {
    test('a deep copy in the same order', () {
      final font = FontSpecScope()..size = 12.0;
      final raw = <String, Object?>{
        'a': <Object?>[1.0],
      };
      final list = <Object?>[
        <String, Object?>{'b': 2.0},
      ];
      final scope = ChartOptionsScope()
        ..font = font
        ..jsWrite('extra', raw)
        ..jsWrite('events', list)
        ..jsWrite('onClick', _fn);
      final copy = scope.cloneScope() as ChartOptionsScope;
      expect(copy.jsKeys(), scope.jsKeys());
      final copyFont = copy.fontCell!.raw! as FontSpecScope;
      expect(copyFont, isNot(same(font)));
      expect(copyFont.jsRead('size'), 12.0);
      final copyRaw = copy.jsRead('extra')! as Map<String, Object?>;
      expect(copyRaw, isNot(same(raw)));
      expect(copyRaw['a'], isNot(same(raw['a'])));
      expect(copyRaw['a'], [1.0]);
      expect(copy.jsRead('events'), isNot(same(list)));
      expect(copy.jsRead('onClick'), same(_fn));
    });
  });

  group('fitCell', () {
    test('a cell of the field type stays, another one is classified', () {
      const Opt<Object?> number = OptValue<double>(3);
      expect(
        fitCell<Object>(number, (raw) => classifyUnion(raw, 1)),
        same(number),
      );
      const Opt<Object?> text = OptValue<Object>('x');
      expect(fitCell(text, classifyNumber), isA<OptForeign<double>>());
      expect(fitCell(optUndefined, classifyNumber), same(optUndefined));
      expect(fitCell(null, classifyNumber), isNull);
    });
  });
}
