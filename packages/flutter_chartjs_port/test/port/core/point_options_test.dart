// Original code, not ported from Chart.js: point-loop regressions.
import 'dart:collection';
import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/point_options.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/parsed.dart';
import 'package:flutter_chartjs_port/src/options/resolved.g.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:test/test.dart';

class _ObservedMap extends MapBase<String, Object?> {
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

void main() {
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
      const red = Color(0xffff0000);
      const blue = Color(0xff0000ff);
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
          <Color>[red, blue],
          <Color>[blue, red],
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
      (ds['backgroundColor']! as List<Color>).clear();
      expect(config.prepareIndexedPointColors(0), isNull);
      config.clearCache();
      expect(config.prepareIndexedPointColors(1), isNull);
    },
  );
}
