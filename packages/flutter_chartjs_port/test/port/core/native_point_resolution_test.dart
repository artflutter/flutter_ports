// Original code, not ported from Chart.js: prepared resolver source guards.
import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/point_options.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/resolved.g.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:test/test.dart';

const red = ChartPaint.solid(Color(0xffff0000));
const blue = ChartPaint.solid(Color(0xff0000ff));

class _Fixture() {
  this {
    final saved = defaults.saveState();
    addTearDown(() => defaults.restoreState(saved));
    defaults.elements = elements;
    root = {
      'type': 'line',
      'data': <String, Object?>{
        'datasets': <Object?>[dataset],
      },
    };
    config = Config(root);
    scopeKeys = config.datasetElementScopeKeys('line', 'point');
    scopes = config.getOptionScopes(dataset, scopeKeys);
    for (var i = 0; i < 3; i++) {
      config.resolveOwnedElementNamedOptions(
        scopes,
        point.nativeOwnKeySnapshot,
        () => ScriptableContext.data(null, 0, null),
        ['point', ''],
        point: true,
        immutableKeys: true,
      );
    }
  }
  final point = PointOptionsScope()
    ..radius = 3
    ..borderWidth = 1
    ..backgroundColor = red
    ..borderColor = blue;
  late final elements = ElementOptionsByTypeScope()..point = point;
  final dataset = <String, Object?>{
    '_scriptable': true,
    '_indexable': true,
    'data': <Object?>[
      <String, Object?>{'x': 1.0, 'y': 2.0},
    ],
    'backgroundColor': (Object? c) =>
        (c! as ScriptableContext).index == 1 ? blue : red,
  };
  late final Map<String, Object?> root;
  late final Config config;
  late final List<List<String>> scopeKeys;
  late final List<Object?> scopes;
  NativePointResolution get plan => config.prepareLineResolution(0)!;
}

void main() {
  test('warmed resolution is fresh and calls its context once', () {
    final f = _Fixture();
    final plan = f.plan;
    var contexts = 0;
    Object context() {
      contexts++;
      return ScriptableContext.data(null, 1, null);
    }

    final a = (plan.resolve(context, null)! as PointOptions)
      ..storeKey(OptionKey.radius, 99.0);
    final b = plan.resolve(context, null)! as PointOptions;
    expect(identical(a, b), isFalse);
    expect(b.radius, 3);
    expect(b.backgroundColor, blue);
    expect(contexts, 2);
  });
  for (final mutation in [
    'data',
    'datasets',
    'dataset',
    'raw',
    'options',
    'point',
    'elements',
    'keys',
    'clear',
    'scopes',
  ]) {
    test('source guard declines before context after $mutation changes', () {
      final f = _Fixture();
      final plan = f.plan;
      expect(plan.valid(), isTrue);
      final data = f.root['data']! as Map<String, Object?>;
      final datasets = data['datasets']! as List<Object?>;
      switch (mutation) {
        case 'data':
          f.root['data'] = <String, Object?>{'datasets': datasets};
        case 'datasets':
          data['datasets'] = List<Object?>.of(datasets);
        case 'dataset':
          datasets[0] = Map<String, Object?>.of(f.dataset);
        case 'raw':
          f.dataset['data'] = List<Object?>.of(
            f.dataset['data']! as List<Object?>,
          );
        case 'options':
          f.root['options'] = <String, Object?>{};
        case 'point':
          f.elements.point = PointOptionsScope()..radius = 9;
        case 'elements':
          defaults.elements = ElementOptionsByTypeScope()..point = f.point;
        case 'keys':
          f.point.jsWrite('extra', true);
        case 'clear':
          f.config.clearCache();
        case 'scopes':
          f.config.getOptionScopes(f.dataset, f.scopeKeys, true);
      }
      expect(plan.valid(), isFalse);
      expect(
        plan.resolve(() => throw StateError('context must not run'), null),
        isNull,
      );
    });
  }
  test('routes decline without invoking the route', () {
    final f = _Fixture();
    final plan = f.plan;
    var reads = 0;
    f.elements.addRoute(
      'point',
      ScopeRoute(
        (_) {
          reads++;
          return f.point;
        },
        targetScope: null,
        targetName: 'point',
      ),
    );
    expect(plan.valid(), isFalse);
    expect(reads, 0);
  });
  test(
    'context-time cache invalidation falls back without a second context',
    () {
      final f = _Fixture();
      final plan = f.plan;
      var calls = 0;
      final value = plan.resolve(() {
        calls++;
        f.config.clearCache();
        return ScriptableContext.data(null, 1, null);
      }, null)!;
      expect(calls, 1);
      expect(value.jsRead('backgroundColor'), blue);
      expect(plan.valid(), isFalse);
    },
  );
  test('current key snapshot survives a context-time key change', () {
    final f = _Fixture();
    final plan = f.plan;
    final result = plan.resolve(() {
      f.point.jsWrite('extra', 7);
      return ScriptableContext.data(null, 1, null);
    }, null)!;
    expect(result.jsHas('extra'), isFalse);
    expect(plan.valid(), isFalse);
  });
  test('static value changes keep upstream raw resolver caching', () {
    final f = _Fixture();
    final plan = f.plan;
    f.dataset['borderWidth'] = 9.0;
    final result = plan.resolve(
      () => ScriptableContext.data(null, 1, null),
      null,
    )!;
    expect(result.jsRead('borderWidth'), 1);
  });
}
