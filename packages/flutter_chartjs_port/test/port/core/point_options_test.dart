// Original code, not ported from Chart.js: point-loop regressions.
import 'dart:collection';
import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/data_update.dart';
import 'package:flutter_chartjs_port/src/core/point_options.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/foreign_audit.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/parsed.dart';
import 'package:flutter_chartjs_port/src/options/resolved.g.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:flutter_chartjs_port/src/types/data_item.dart';
import 'package:test/test.dart';

class _ObservedMap() extends MapBase<String, Object?> {
  int reads = 0;
  @override
  Object? operator [](Object? key) {
    reads++;
    return 1.0;
  }

  @override
  void operator []=(String key, Object? value) {}
  @override
  Iterable<String> get keys => ['x', 'y'];
  @override
  void clear() {}
  @override
  Object? remove(Object? key) => null;
}

class _RegisteredItem() implements TypedDataItem {
  @override
  Object get x => 1.0;
  @override
  double? get y => 2;
  @override
  double? get r => 3;
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _OtherItem() extends _RegisteredItem;

void main() {
  test('typed items classify by their class, one class after another', () {
    registerDataUpdateTypes(const [], [_RegisteredItem]);
    final items = NativeTypedItems();
    expect(items.accepts(_RegisteredItem()), isTrue);
    expect(items.accepts(_RegisteredItem()), isTrue);
    expect(items.accepts(_OtherItem()), isFalse);
    expect(items.accepts(_OtherItem()), isFalse);
    expect(items.accepts(_RegisteredItem()), isTrue);
  });

  group('the size arithmetic of a native point', () {
    const values = <double>[
      0,
      // The double literal keeps the sign.
      // ignore: prefer_int_literals
      -0.0,
      1,
      3.5,
      -2,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ];

    test('equals `size` on typed options and on the object by name', () {
      final point = PointElement();
      for (final radius in values) {
        for (final hoverRadius in values) {
          for (final borderWidth in values) {
            final typed = PointOptions()
              ..storeKey(OptionKey.radius, radius)
              ..storeKey(OptionKey.hoverRadius, hoverRadius)
              ..storeKey(OptionKey.borderWidth, borderWidth);
            final size = nativePointSize(radius, hoverRadius, borderWidth);
            final reason = '$radius, $hoverRadius, $borderWidth';
            // The two forms of NaN compare through their text.
            expect('${point.size(typed)}', '$size', reason: reason);
            final byName = <String, Object?>{
              'radius': radius,
              'hoverRadius': hoverRadius,
              'borderWidth': borderWidth,
            };
            expect('${point.size(byName)}', '$size', reason: reason);
          }
        }
      }
    });

    test('the fields of plain options read once, and others decline', () {
      final options = PointOptions()
        ..storeKey(OptionKey.radius, 3.0)
        ..storeKey(OptionKey.hoverRadius, 4.0)
        ..storeKey(OptionKey.borderWidth, 1.0);
      final fields = NativePointSizeFields.of(options)!;
      expect(fields.radius, 3);
      expect(fields.hoverRadius, 4);
      expect(fields.borderWidth, 1);

      expect(NativePointSizeFields.of(null), isNull);
      expect(
        NativePointSizeFields.of(<String, Object?>{'radius': 3.0}),
        isNull,
      );
      for (final key in [
        OptionKey.radius,
        OptionKey.hoverRadius,
        OptionKey.borderWidth,
      ]) {
        final saved = foreignAudit;
        foreignAudit = (_, _, _) {};
        addTearDown(() => foreignAudit = saved);
        final foreign = options.clone()..storeKey(key, '5');
        foreignAudit = saved;
        expect(NativePointSizeFields.of(foreign), isNull, reason: '$key');
        final absent = PointOptions()
          ..storeKey(OptionKey.radius, 3.0)
          ..storeKey(OptionKey.hoverRadius, 4.0)
          ..storeKey(OptionKey.borderWidth, 1.0)
          ..jsDelete(key.jsName);
        expect(NativePointSizeFields.of(absent), isNull, reason: '$key');
      }
    });
  });

  test(
    'coordinate checks retain live values without touching custom getters',
    () {
      final guard = NativePointCoordinates();
      final raw = <String, Object?>{'x': 1.0, 'y': 2.0};
      expect(guard.accepts(raw), isTrue);
      raw['y'] = Object();
      expect(guard.accepts(raw), isFalse);
      raw['y'] = null;
      expect(guard.accepts(raw), isTrue);
      final custom = _ObservedMap();
      expect(guard.accepts(custom), isFalse);
      expect(custom.reads, 0);
      final parsed = ParsedItem()
        ..x = 1.0
        ..y = double.nan;
      expect(guard.accepts(parsed), isTrue);
      parsed.y = undefined;
      expect(guard.accepts(parsed), isTrue);
      expect(guard.accepts(Object()), isFalse);
    },
  );

  test('coordinate routes are rejected without running them', () {
    var calls = 0;
    final scope = PointOptionsScope()
      ..store('x', const OptValue<double>(1))
      ..store('y', const OptValue<double>(2));
    expect(NativePointCoordinates().accepts(scope), isTrue);
    scope.addRoute(
      'x',
      ScopeRoute(
        (local) {
          calls++;
          return local;
        },
        targetScope: null,
        targetName: 'x',
      ),
    );
    expect(NativePointCoordinates().accepts(scope), isFalse);
    expect(calls, 0);
  });

  test(
    'point plans preserve dataset selection, ownership and invalidation',
    () {
      const red = ChartPaint.solid(Color(0xffff0000));
      const blue = ChartPaint.solid(Color(0xff0000ff));
      final saved = defaults.saveState();
      addTearDown(() => defaults.restoreState(saved));
      final point = PointOptionsScope()
        ..radius = 3
        ..hoverRadius = 4
        ..borderWidth = 1
        ..backgroundColor = red
        ..borderColor = blue;
      defaults.elements = ElementOptionsByTypeScope()..point = point;
      final datasets = <Object?>[
        for (final colors in [
          <ChartPaint>[red, blue],
          <ChartPaint>[blue, red],
        ])
          <String, Object?>{
            '_scriptable': true,
            '_indexable': true,
            'backgroundColor': colors,
            'data': <Object?>[
              <String, double>{'x': 1, 'y': 2},
            ],
          },
      ];
      final config = Config({
        'type': 'scatter',
        'data': <String, Object?>{'datasets': datasets},
      });
      void warm(int index) {
        final scopes = config.getOptionScopes(
          datasets[index],
          config.datasetElementScopeKeys('scatter', 'point'),
        );
        for (var i = 0; i < 2; i++) {
          config.resolveNativeElementNamedOptions(
            scopes,
            point.jsOwnKeys(),
            () => ScriptableContext.data(null, 0, null),
            const ['point', ''],
            PointOptions(),
            allowReplacement: true,
          );
        }
      }

      warm(0);
      warm(1);
      final a = config.prepareIndexedPointColors(0);
      final b = config.prepareIndexedPointColors(1);
      expect(a, isNotNull);
      expect(b, isNotNull);
      expect(a!(0).backgroundColor, red);
      expect(b!(0).backgroundColor, blue);
      final first = a(0)..storeKey(OptionKey.radius, 99.0);
      expect(a(0).radius, 3);
      expect(first.$sharedValue, isFalse);
      expect(identical(a(0), a(0)), isFalse);
      expect(config.prepareIndexedPointColors(-1), isNull);
      expect(config.prepareIndexedPointColors(2), isNull);
      final ds = datasets[0]! as Map<String, Object?>;
      (ds['backgroundColor']! as List<ChartPaint>).clear();
      expect(config.prepareIndexedPointColors(0), isNull);
      config.clearCache();
      expect(config.prepareIndexedPointColors(1), isNull);
    },
  );
}
