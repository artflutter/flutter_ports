// Original code, not ported from Chart.js: prepared line lookup/context twins.
@TestOn('vm')
library;

import 'dart:collection';
import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    as helpers;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

const red = Color(0xffff0000);
const blue = Color(0xff0000ff);

class _Reference extends Chart {
  _Reference(super.item, super.userConfig);
  @override
  bool get supportsNativePointOptions => false;
}

// Explicit native opt-in; counters only, with ordinary property/context behavior.
class _Probe extends PointElement {
  int reads = 0;
  @override
  bool get supportsNativePointOptions {
    reads++;
    return true;
  }

  @override
  bool get typedWrites => true;
}

class _ObservedList<T> extends ListBase<T> {
  _ObservedList(this.values, this.trace);
  final List<T> values;
  final List<Object?> trace;
  @override
  int get length {
    trace.add('length');
    return values.length;
  }

  @override
  set length(int value) => values.length = value;
  @override
  T operator [](int index) {
    trace.add(['get', index]);
    return values[index];
  }

  @override
  void operator []=(int index, T value) => values[index] = value;
}

Object? plain(Object? value) {
  if (value is double && !value.isFinite) return value.toString();
  if (value is JsObjectFace) {
    return {for (final key in value.jsKeys()) key: plain(value.jsRead(key))};
  }
  if (value is Map) {
    return {for (final entry in value.entries) entry.key: plain(entry.value)};
  }
  return value;
}

Object observe(List<types.Element> points) => [
  for (final p in points.cast<PointElement>())
    [
      plain(p.x),
      plain(p.y),
      p.skip,
      p.stop,
      plain(p.options),
      p.$context?.jsKeys(),
      if (p.$context case final c?)
        [plain(c.raw), plain(c.parsed), c.dataIndex, c.index, c.active, c.mode],
    ],
];
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final change in [
    'none',
    'raw',
    'raw-values',
    'datasets',
    'data',
    'options',
    'clear',
    'scopes',
    'keys',
    'route',
    'parsed',
    'points',
    'cache',
    'invalid-options',
    'context-keys',
  ]) {
    test('prepared line matches ordinary path after $change', () {
      final elements =
          Chart.defaults.elementsCell!.raw! as ElementOptionsByTypeScope;
      final pointDefaults = elements.pointCell!.raw! as PointOptionsScope;
      final pointState = pointDefaults.saveState();
      final elementsState = elements.saveState();
      final states = <Object>[];
      final traces = <List<Object?>>[];
      final errors = <Type?>[];
      for (final reference in [false, true]) {
        pointDefaults.restoreState(pointState);
        elements.restoreState(elementsState);
        final raw = <Object?>[
          for (var i = 0; i < 8; i++)
            <String, Object?>{
              'x': i.toDouble(),
              'y': i.toDouble(),
              'tag': 'old',
            },
        ];
        final dataset = <String, Object?>{
          'data': raw,
          'radius': 3.0,
          'borderColor': const ChartPaint.solid(blue),
          'showLine': true,
        };
        final data = <String, Object?>{
          'datasets': <Object?>[dataset],
        };
        final options = <String, Object?>{
          'responsive': false,
          'animation': false,
          'parsing': false,
          'events': <String>[],
          'plugins': <String, Object?>{'legend': false},
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'type': 'linear',
              'display': false,
              'min': 0.0,
              'max': 8.0,
            },
            'y': <String, Object?>{
              'type': 'linear',
              'display': false,
              'min': 0.0,
              'max': 10.0,
            },
          },
        };
        final cfg = <String, Object?>{
          'type': 'line',
          'data': data,
          'options': options,
        };
        final trace = <Object?>[];
        var armed = false;
        var done = false;
        late Chart chart;
        late ChartMeta meta;
        late List<_Probe> points;
        ChartPaint color(Object? input) {
          if (!armed) return const ChartPaint.solid(red);
          final context = input! as ScriptableContext;
          trace.add([
            'color',
            context.dataIndex,
            plain(context.raw),
            plain(context.parsed),
          ]);
          if (context.dataIndex == 3.0 && !done) {
            done = true;
            switch (change) {
              case 'raw':
                dataset['data'] = <Object?>[
                  for (var i = 0; i < 8; i++)
                    <String, Object?>{
                      'x': i.toDouble(),
                      'y': i.toDouble(),
                      'tag': 'new',
                    },
                ];
              case 'raw-values':
                raw[4] = <String, Object?>{
                  'x': 4.0,
                  'y': 9.0,
                  'tag': 'changed',
                };
              case 'datasets':
                data['datasets'] = <Object?>[dataset];
              case 'data':
                cfg['data'] = <String, Object?>{
                  'datasets': <Object?>[dataset],
                };
              case 'options':
                cfg['options'] = Map<String, Object?>.of(options);
              case 'clear':
                chart.config.clearCache();
              case 'scopes':
                chart.config.getOptionScopes(
                  dataset,
                  chart.config.datasetElementScopeKeys('line', 'point'),
                  true,
                );
              case 'keys':
                pointDefaults
                  ..jsDelete('radius')
                  ..jsWrite('late', 7.0);
              case 'route':
                elements.addRoute(
                  'point',
                  ScopeRoute(
                    (_) {
                      trace.add('route');
                      return pointDefaults;
                    },
                    targetScope: null,
                    targetName: 'point',
                  ),
                );
              case 'parsed':
                meta.parsed = _ObservedList<Object?>(
                  List<Object?>.of(meta.parsed),
                  trace,
                );
              case 'points':
                meta.data[4] = _Probe()
                  ..$context = ScriptableContext.data(null, 4, 'replacement');
              case 'cache':
                final config = chart.config;
                final scopes = config.getOptionScopes(
                  dataset,
                  config.datasetElementScopeKeys('line', 'point'),
                );
                final resolver =
                    (config.createResolver(scopes, null, [
                      'point',
                      '',
                    ]) as helpers.OptionResolver)..jsWrite(
                      'backgroundColor',
                      const ChartPaint.solid(blue),
                    );
                meta.controller!.resolveDataElementOptions(3, 'none');
                resolver.jsWrite('backgroundColor', color);
                config.resolveOwnedElementNamedOptions(
                  scopes,
                  pointDefaults.nativeOwnKeySnapshot,
                  () => context,
                  ['point', ''],
                  point: true,
                  immutableKeys: true,
                );
              case 'invalid-options':
                cfg['options'] = 42;
              case 'context-keys':
                points[4].$context!
                  ..jsDelete('raw')
                  ..jsDelete('parsed')
                  ..jsWrite('note', true);
              case 'none':
                break;
            }
          }
          return const ChartPaint.solid(red);
        }

        dataset['backgroundColor'] = color;
        final canvas = UiCanvasElement(width: 640, height: 400);
        chart = reference ? _Reference(canvas, cfg) : Chart(canvas, cfg);
        meta = chart.getDatasetMeta(0);
        points = [for (var i = 0; i < 8; i++) meta.data[i] = _Probe()];
        try {
          chart.update('none');
          for (final point in points) {
            point.reads = 0;
          }
          armed = true;
          Type? error;
          try {
            meta.controller!.updateElements(meta.data, 0, 8, 'none');
          } on Object catch (e) {
            error = e.runtimeType;
          }
          armed = false;
          errors.add(error);
          states.add([observe(points), observe(meta.data)]);
          traces.add(List<Object?>.of(trace));
          if (!reference && change == 'none') {
            expect(points[2].reads, greaterThan(0));
          }
          if (change == 'cache') {
            expect(identical(points[4].options, points[5].options), isTrue);
          }
        } finally {
          armed = false;
          cfg['options'] = options;
          chart.destroy();
          pointDefaults.restoreState(pointState);
          elements.restoreState(elementsState);
        }
      }
      expect(errors[0], errors[1]);
      expect(states[0], states[1]);
      expect(traces[0], traces[1]);
    });
  }
}
