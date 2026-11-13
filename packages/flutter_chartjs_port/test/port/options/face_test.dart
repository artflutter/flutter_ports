// Original code, not ported from Chart.js: tests of the typed faces.

// The JS runtime over the faces of Chart.js ADR 0054 §5: `jsGet`,
// `jsGetKey`, `jsObjectKeys`, `jsOwnPropertyNames`, `isObject`, `merge`,
// `mergeIf` and `clone` over a typed scope (also through its `MapBase`
// scaffolding), and the raw scope over a user Map.

import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/core/core.interaction.dart'
    show InteractionAxis;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/raw_scope.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
import 'package:test/test.dart';

Object? _fn(Object? ctx) => ctx;

/// A point scope with a typed key, an extra, `undefined` and `null`.
PointOptionsScope _point() => PointOptionsScope()
  ..radius = 3.0
  ..jsWrite('extraKey', 5.0)
  ..jsWrite('pointStyle', undefined)
  ..jsWrite('backgroundColor', null);

void main() {
  group('the property read', () {
    test('jsGet and jsGetKey give the JS values', () {
      final scope = _point();
      for (final read in [jsGet, jsGetKey]) {
        expect(read(scope, 'radius'), 3.0);
        expect(read(scope, 'extraKey'), 5.0);
        expect(read(scope, 'pointStyle'), same(undefined));
        expect(read(scope, 'backgroundColor'), isNull);
        expect(read(scope, 'rotation'), same(undefined));
        expect(read(scope, 'noSuchKey'), same(undefined));
      }
    });

    test('a face is a JsObjectFace', () {
      final JsObjectFace face = _point();
      expect(face.jsRead('radius'), 3.0);
      expect(face.jsKeys(), [
        'radius',
        'extraKey',
        'pointStyle',
        'backgroundColor',
      ]);
      expect(face.jsHas('pointStyle'), isTrue);
      expect(face.jsDelete('pointStyle'), isTrue);
      expect(face.jsHas('pointStyle'), isFalse);
    });
  });

  group('the keys', () {
    test('jsObjectKeys and jsOwnPropertyNames give the own-key order', () {
      final scope = _point()
        ..jsDelete('radius')
        ..radius = 4.0;
      expect(jsObjectKeys(scope), [
        'extraKey',
        'pointStyle',
        'backgroundColor',
        'radius',
      ]);
      expect(jsOwnPropertyNames(scope), jsObjectKeys(scope));
    });

    test('the array-index names come first, as JS orders them', () {
      final scope = ScaleOptionsByIdScope()
        ..jsWrite('x', <String, Object?>{})
        ..jsWrite('10', <String, Object?>{})
        ..jsWrite('2', <String, Object?>{});
      expect(scope.jsKeys(), ['2', '10', 'x']);
      expect(jsObjectKeys(scope), ['2', '10', 'x']);
    });
  });

  group('the operators of the face', () {
    // The close step of Chart.js ADR 0054 removed the Map scaffolding:
    // `operator []` and `operator []=` are `jsRead` and `jsWrite`, with the
    // JS rules.
    test('the reads and writes by name of the scope', () {
      final scope = _point();
      expect(scope['radius'], 3.0);
      expect(scope['rotation'], same(undefined));
      expect(scope.jsHas('rotation'), isFalse);
      expect(scope.jsHas('pointStyle'), isTrue);
      expect(scope.ownKeyCount, 4);
      expect(scope.jsKeys(), [
        'radius',
        'extraKey',
        'pointStyle',
        'backgroundColor',
      ]);
      expect(scope.jsDelete('radius'), isTrue);
      expect(scope.jsKeys(), ['extraKey', 'pointStyle', 'backgroundColor']);
      scope['hitRadius'] = 2;
      expect(scope.hitRadiusCell!.raw, 2.0);
      scope.jsKeys().forEach(scope.jsDelete);
      expect(scope.ownKeyCount, 0);
    });
  });

  group('isObject and clone', () {
    test('a typed scope is an object', () {
      expect(isObject(_point()), isTrue);
      expect(isObject(const RawScope(<String, Object?>{}).map), isTrue);
    });

    test('clone gives a typed copy of a typed scope', () {
      final interaction = InteractionOptionsScope()..intersect = false;
      const font = ChartTextStyle(fontSize: 12);
      final scope = ChartOptionsScope()
        ..interaction = interaction
        ..font = font
        ..jsWrite('onClick', _fn);
      final copy = clone(scope)! as ChartOptionsScope;
      expect(copy, isNot(same(scope)));
      expect(copy.jsKeys(), ['interaction', 'font', 'onClick']);
      expect(copy.interactionCell!.raw, isA<InteractionOptionsScope>());
      expect(copy.interactionCell!.raw, isNot(same(interaction)));
      // A font is an immutable TextStyle (Chart.js ADR 0116): a leaf.
      expect(copy.fontCell!.raw, same(font));
      expect(copy.jsRead('onClick'), same(_fn));
    });
  });

  group('merge and mergeIf', () {
    test('merge into a typed scope makes typed children', () {
      final scope = ChartOptionsScope()
        ..color = const ChartPaint.solid(ui.Color.fromRGBO(255, 0, 0, 1));
      const font = ChartTextStyle(fontSize: 14, fontFamily: 'x');
      merge(scope, <String, Object?>{
        'interaction': <String, Object?>{
          'intersect': false,
          'axis': InteractionAxis.x,
        },
        'font': font,
        'color': const ChartPaint.solid(ui.Color.fromRGBO(0, 0, 255, 1)),
        'extra': <String, Object?>{'a': 1.0},
      });
      expect(scope.jsKeys(), ['color', 'interaction', 'font', 'extra']);
      expect(
        scope.jsRead('color'),
        const ChartPaint.solid(ui.Color.fromRGBO(0, 0, 255, 1)),
      );
      final interaction = scope.interactionCell!.raw;
      expect(interaction, isA<InteractionOptionsScope>());
      expect((interaction! as InteractionOptionsScope).jsKeys(), [
        'intersect',
        'axis',
      ]);
      expect(scope.fontCell!.raw, same(font));
      expect(scope.jsRead('extra'), isA<Map<String, Object?>>());
    });

    test('merge into a nested typed scope', () {
      final scope = ChartOptionsScope()
        ..interaction = (InteractionOptionsScope()..intersect = false)
        ..font = const ChartTextStyle(fontSize: 12);
      final interaction = scope.interactionCell!.raw;
      merge(scope, <String, Object?>{
        'interaction': <String, Object?>{'includeInvisible': true},
        'font': const ChartTextStyle(fontWeight: ui.FontWeight.bold),
      });
      expect(scope.interactionCell!.raw, same(interaction));
      expect((interaction! as InteractionOptionsScope).jsKeys(), [
        'intersect',
        'includeInvisible',
      ]);
      // A font merges with TextStyle.merge: a field of the source wins.
      expect(
        scope.fontCell!.raw,
        const ChartTextStyle(fontSize: 12, fontWeight: ui.FontWeight.bold),
      );
    });

    test('mergeIf keeps the own keys, also undefined', () {
      final scope = ChartOptionsScope()
        ..jsWrite('color', undefined)
        ..interaction = (InteractionOptionsScope()..intersect = false)
        ..font = const ChartTextStyle(fontSize: 12);
      mergeIf(scope, <String, Object?>{
        'color': const ChartPaint.solid(ui.Color.fromRGBO(255, 0, 0, 1)),
        'interaction': <String, Object?>{
          'intersect': true,
          'includeInvisible': true,
        },
        'font': const ChartTextStyle(
          fontSize: 20,
          fontStyle: ui.FontStyle.italic,
        ),
        'indexAxis': const YAxis(),
      });
      expect(scope.jsRead('color'), same(undefined));
      expect(scope.jsRead('indexAxis'), isA<YAxis>());
      final interaction =
          scope.interactionCell!.raw! as InteractionOptionsScope;
      expect(interaction.jsKeys(), ['intersect', 'includeInvisible']);
      expect(interaction.jsRead('intersect'), false);
      // A font merges with TextStyle.merge: a field of the target wins.
      expect(
        scope.fontCell!.raw,
        const ChartTextStyle(fontSize: 12, fontStyle: ui.FontStyle.italic),
      );
    });
  });

  group('RawScope', () {
    test('the cells of a user Map', () {
      final map = <String, Object?>{
        'radius': '5',
        'pointStyle': undefined,
        'backgroundColor': _fn,
      };
      final raw = RawScope(map);
      expect(raw.lookupName('rotation'), isNull);
      expect(raw.lookupName('pointStyle'), same(optUndefined));
      expect(
        raw.lookup(OptionKey.backgroundColor),
        isA<OptFunction<Object?>>(),
      );
      expect(
        raw.lookup(OptionKey.radius, ScopeKind.pointOptions),
        isA<OptForeign<double>>(),
      );
      expect(raw.lookup(OptionKey.radius)!.raw, '5');
      expect(raw.jsRead('rotation'), same(undefined));
      raw.jsWrite('rotation', 1.0);
      expect(map['rotation'], 1.0);
      expect(raw.jsKeys(), [
        'radius',
        'pointStyle',
        'backgroundColor',
        'rotation',
      ]);
    });
  });
}
