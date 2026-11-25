// Original code, not ported from Chart.js: native line option-loop twins.
@TestOn('vm')
library;

import 'dart:ui' as ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/context_keys.dart';
import '../../support/parsed_items.dart';

const red = ChartPaint.solid(ui.Color(0xffff0000));
const blue = ChartPaint.solid(ui.Color(0xff0000ff));
const green = ChartPaint.solid(ui.Color(0xff00ff00));

class _ReferenceChart(super.item, super.userConfig) extends Chart {
  @override
  bool get supportsNativePointOptions => false;
}

// Explicit test opt-in: counters only, with native size/context/property behavior.
class _ProbePoint() extends PointElement {
  int planReads = 0;
  @override
  bool get supportsNativePointOptions {
    planReads++;
    return true;
  }

  @override
  bool get typedWrites => true;
}

class _CustomScale(super.cfg) extends LinearScale {
  int calls = 0;
  static final value = ScaleType(
    id: 'scatter-custom-scale',
    defaults: LinearScale.component.defaults,
    defaultRoutes: LinearScale.component.defaultRoutes,
    descriptors: LinearScale.component.descriptors,
    parent: LinearScale.component,
    create: _CustomScale.new,
  );
  @override
  double getPixelForValue(double value, [int? index]) {
    calls++;
    return super.getPixelForValue(value, index);
  }
}

ChartConfigurationScope _config({
  bool line = false,
  int datasets = 1,
}) => lowerForTest(
  raw(
    ChartConfig(
      datasets: [
        for (var d = 0; d < datasets; d++)
          raw(
            LineDataset(
              borderColor: const ChartValue.constant(blue),
              borderWidth: 1,
              showLine: line,

              // Tests mutate these lists, raw points and the radius alias in
              // place.
            ),
            {
              'data': <Object?>[
                for (var i = 0; i < 8; i++)
                  <String, Object?>{'x': i.toDouble(), 'y': (i - 3).toDouble()},
              ],
              'backgroundColor': <ChartPaint>[if (d == 0) red else green, blue],
              'radius': 3.0,
            },
          ),
      ],
      responsive: false,
      animation: ChartAnimation.none,
      scales: const [
        LinearAxis(.x, display: ScaleDisplay.off, min: 0, max: 8),
        LinearAxis(.y, display: ScaleDisplay.off, min: -5, max: 10),
      ],
      events: const [],
      disabledPlugins: const [
        PluginOff<LegendPlugin>(),
        PluginOff<TooltipPlugin>(),
      ],
    ),
    const {'parsing': false},
  ),
);

JsObjectFace _dataset(ChartConfigurationScope cfg, [int index = 0]) =>
    (jsGet(cfg['data'], 'datasets')! as List<Object?>)[index]! as JsObjectFace;

Chart _chart(Object cfg, {bool reference = false}) {
  final canvas = UiCanvasElement(width: 640, height: 400);
  final chart = reference
      ? _ReferenceChart(canvas, withParsedDataItems(cfg))
      : Chart(canvas, withParsedDataItems(cfg));
  addTearDown(chart.destroy);
  return chart;
}

List<_ProbePoint> _probes(Chart chart, [int dataset = 0]) {
  final points = chart.getDatasetMeta(dataset).data;
  return [for (var i = 0; i < points.length; i++) points[i] = _ProbePoint()];
}

Object? _plain(Object? value) {
  if (value is double && !value.isFinite) return value.toString();
  if (value is JsObjectFace) {
    return {for (final k in value.jsKeys()) k: _plain(value.jsRead(k))};
  }
  if (value is Map) {
    return {for (final e in value.entries) e.key: _plain(e.value)};
  }
  return value;
}

Object _observe(Chart chart, [int dataset = 0]) => [
  for (final point in chart.getDatasetMeta(dataset).data.cast<PointElement>())
    [
      _plain(point.x),
      _plain(point.y),
      point.skip,
      point.stop,
      _plain(point.options),
      contextKeysOrNull(point.$context),
      for (final key in [
        'index',
        'dataIndex',
        'mode',
        'active',
        'parsed',
        'raw',
      ])
        _plain(contextField(point.$context, key)),
    ],
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Chart.register([
    LineController.component,
    PointElement.component,
    LineElement.component,
    LinearScale.component,
  ]);

  for (final line in [false, true]) {
    test(
      'fresh indexed options and contexts across updates, showLine=$line',
      () {
        final ca = _config(line: line, datasets: 2);
        final cb = _config(line: line, datasets: 2);
        final a = _chart(ca);
        final b = _chart(cb, reference: true);
        final probes = [_probes(a), _probes(a, 1)];
        for (var step = 0; step < 3; step++) {
          for (final cfg in [ca, cb]) {
            for (var d = 0; d < 2; d++) {
              final ds = _dataset(cfg, d);
              (ds['backgroundColor']! as List<ChartPaint>)[0] =
                  ChartPaint.solid(ui.Color(0xff001100 + step + d));
              jsSet((ds['data']! as List<Object?>)[3], 'y', step.toDouble());
            }
          }
          a.update(UpdateMode.none);
          b.update(UpdateMode.none);
          for (var d = 0; d < 2; d++) {
            expect(_observe(a, d), _observe(b, d));
            expect(
              identical(probes[d][3].options, probes[d][4].options),
              isFalse,
            );
            expect(jsGet(probes[d][3].options, r'$shared'), isFalse);
            probes[d][3].options!.storeKey(OptionKey.radius, 77.0);
          }
        }
        expect(probes.expand((x) => x).any((p) => p.planReads > 0), isTrue);
      },
    );
  }

  test('active point callback sees geometry and ends prepared resolution', () {
    final states = <Object>[];
    final logs = <List<Object?>>[];
    for (final reference in [false, true]) {
      final cfg = _config();
      final calls = <Object?>[];
      ChartPaint hover(ScriptableContext ctx) {
        final e = ctx.element! as PointElement;
        calls.add([ctx.dataIndex, e.x, e.y]);
        return green;
      }

      _dataset(cfg)['hoverBackgroundColor'] = hover;
      final chart = _chart(cfg, reference: reference);
      final probes = _probes(chart);
      probes[4].active = true;
      final meta = chart.getDatasetMeta(0);
      meta.controller!.updateElements(meta.data, 0, 8, 'none');
      logs.add(calls);
      states.add(_observe(chart));
      if (!reference) {
        expect(probes[3].planReads, greaterThan(0));
        expect(probes[6].planReads, 0);
      }
    }
    expect(logs[0], isNotEmpty);
    expect(logs[0], logs[1]);
    expect(states[0], states[1]);
  });

  test('scriptable and indexed numeric options preserve ordinary calls', () {
    for (final callback in [false, true]) {
      final states = <Object>[];
      final counts = <int>[];
      for (final reference in [false, true]) {
        final cfg = _config();
        var calls = 0;
        double radius(ScriptableContext ctx) {
          calls++;
          return 2 + (ctx.dataIndex! as num).toDouble();
        }

        _dataset(cfg)['radius'] = callback ? radius : <double>[2, 4];
        final chart = _chart(cfg, reference: reference);
        final probes = _probes(chart);
        calls = 0;
        chart.update(UpdateMode.none);
        states.add(_observe(chart));
        counts.add(calls);
        expect(probes.every((p) => p.planReads == 0), isTrue);
      }
      expect(states[0], states[1]);
      expect(counts[0], counts[1]);
    }
  });

  test('partial updates keep absolute indices and untouched points', () {
    final a = _chart(_config());
    final b = _chart(_config(), reference: true);
    final probes = _probes(a);
    _probes(b);
    for (final chart in [a, b]) {
      final meta = chart.getDatasetMeta(0);
      meta.controller!.updateElements(meta.data, 2, 5, 'none');
    }
    expect(_observe(a), _observe(b));
    expect(probes[4].planReads, greaterThan(0));
    expect(probes[0].$context, isNull);
    expect(probes[7].$context, isNull);
  });

  test('custom scale projections retain ordinary option resolution', () {
    Chart.register([_CustomScale.value]);
    addTearDown(() => Chart.unregister([_CustomScale.value]));
    final states = <Object>[];
    final calls = <int>[];
    for (final reference in [false, true]) {
      final cfg = _config();
      final scales =
          (cfg['options']! as JsObjectFace)['scales']! as JsObjectFace;
      (scales['y']! as JsObjectFace)['type'] = 'scatter-custom-scale';
      final chart = _chart(cfg, reference: reference);
      final probes = _probes(chart);
      final scale = (chart.scales['y']! as _CustomScale)..calls = 0;
      final meta = chart.getDatasetMeta(0);
      meta.controller!.updateElements(meta.data, 0, 8, 'none');
      expect(probes.every((p) => p.planReads == 0), isTrue);
      calls.add(scale.calls);
      states.add(_observe(chart));
    }
    expect(calls[0], greaterThan(0));
    expect(calls[0], calls[1]);
    expect(states[0], states[1]);
  });
  test(
    'warm identity slots survive replacement, resizing and mode changes',
    () {
      final ca = _config(line: true);
      final cb = _config(line: true);
      final a = _chart(ca);
      final b = _chart(cb, reference: true);
      for (var step = 0; step < 9; step++) {
        for (final cfg in [ca, cb]) {
          final ds = _dataset(cfg);
          final data = ds['data']! as List<Object?>;
          switch (step) {
            case 1:
              jsSet(data[4], 'y', null);
            case 2:
              jsSet(data[4], 'y', '2');
            case 3:
              ds['data'] = parsedItemsOf([
                for (var i = 0; i < 12; i++)
                  <String, double>{'x': i / 2, 'y': i / 3},
              ]);
            case 4:
              data.removeRange(5, data.length);
            case 5:
              ds['backgroundColor'] = green;
            case 6:
              ds['backgroundColor'] = <ChartPaint>[green, red];
              ds['data'] = <Object?>[
                ...data,
                for (var i = 5; i < 10; i++)
                  parsedItemOf(<String, Object?>{'x': i / 2, 'y': -0.0}),
              ];
            case 7:
              for (var i = 0; i < data.length; i += 2) {
                // A new item with the same keys and values.
                final item = data[i]! as ParsedItem;
                data[i] = parsedItemOf(<String, Object?>{
                  for (final key in item.jsKeys()) key: item.jsRead(key),
                });
              }
            case 8:
              data[3] = parsedItemOf(<String, Object?>{'x': 1.5, 'y': 2.0});
          }
        }
        final mode = step == 5 ? UpdateMode.reset : UpdateMode.none;
        a.update(mode);
        b.update(mode);
        expect(_observe(a), _observe(b), reason: 'step $step');
        for (final chart in [a, b]) {
          final meta = chart.getDatasetMeta(0);
          meta.controller!.updateElements(meta.data, 1, 4, 'none');
        }
        expect(_observe(a), _observe(b), reason: 'partial step $step');
      }
    },
  );

  test(
    'warm cache preserves active callback mutation, failure and recovery',
    () {
      final states = <Object>[];
      final logs = <List<Object?>>[];
      for (final reference in [false, true]) {
        final cfg = _config();
        final ds = _dataset(cfg);
        final calls = <Object?>[];
        var fail = false;
        ChartPaint hover(ScriptableContext context) {
          calls.add(context.dataIndex);
          if (fail) throw StateError('hover failure');
          jsSet((ds['data']! as List<Object?>)[6], 'y', '3');
          (ds['backgroundColor']! as List<ChartPaint>)[0] = green;
          return green;
        }

        ds['hoverBackgroundColor'] = hover;
        final chart = _chart(cfg, reference: reference)
          ..update(UpdateMode.none)
          ..update(UpdateMode.none);
        final meta = chart.getDatasetMeta(0);
        final point = (meta.data[4] as PointElement)..active = true;
        fail = true;
        expect(
          () => meta.controller!.updateElements(meta.data, 0, 8, 'none'),
          throwsStateError,
        );
        fail = false;
        meta.controller!.updateElements(meta.data, 0, 8, 'none');
        states.add(_observe(chart));
        point.active = false;
        chart.update(UpdateMode.none);
        states.add(_observe(chart));
        jsSet((ds['data']! as List<Object?>)[6], 'y', 3.0);
        chart.update(UpdateMode.none);
        states.add(_observe(chart));
        logs.add(calls);
      }
      expect(states.sublist(0, 3), states.sublist(3));
      expect(logs[0], logs[1]);
      expect(logs[0], [4.0, 4.0]);
    },
  );
}
