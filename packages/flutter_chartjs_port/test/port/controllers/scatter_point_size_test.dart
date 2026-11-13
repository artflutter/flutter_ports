// Original code, not ported from Chart.js: scatter overflow and context twins.
@TestOn('vm')
library;

import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    show
        ChartAnimation,
        ChartConfig,
        ChartValue,
        DataPoint,
        LinearAxis,
        ScatterDataset;
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/options/element_options_base.dart';
import 'package:flutter_chartjs_port/src/options/foreign_audit.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/typed/lower.dart'
    show ChartConfigLowering;
import 'package:flutter_test/flutter_test.dart';

const red = ChartPaint.solid(ui.Color(0xffff0000));
const blue = ChartPaint.solid(ui.Color(0xff0000ff));
const _length = 8;

/// A trivial user subclass: the exact-class guard fails, and each call stays on
/// the ordinary path. Its charts are the reference of each twin.
class _ReferenceScatter(super.chart, super.datasetIndex, [super.newTarget])
    extends ScatterController {
  static final JsClass value = JsClass(
    'ReferenceScatter',
    superclass: ScatterController.jsClass,
    statics: {'id': 'referenceScatter'},
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _ReferenceScatter(chart, datasetIndex, newTarget);
    },
  );
}

/// A user subclass that counts each option resolve.
class _CountingScatter(super.chart, super.datasetIndex, [super.newTarget])
    extends ScatterController {
  static int resolves = 0;

  static final JsClass value = JsClass(
    'CountingScatter',
    superclass: ScatterController.jsClass,
    statics: {'id': 'countingScatter'},
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _CountingScatter(chart, datasetIndex, newTarget);
    },
  );

  @override
  ElementOptions resolveDataElementOptions(int index, [String? mode]) {
    resolves++;
    return super.resolveDataElementOptions(index, mode);
  }
}

class _ReferenceChart(super.item, super.userConfig) extends Chart {
  @override
  bool get supportsNativePointOptions => false;
}

/// A platform that keeps the option `animation`: an unhosted canvas otherwise
/// gets a [BasicPlatform], whose `updateConfig` writes `false` into it.
class _AnimatedPlatform() extends BasicPlatform {
  static final JsClass value = JsClass(
    'AnimatedPlatform',
    superclass: BasicPlatform.jsClass,
    construct: (_, _) => _AnimatedPlatform(),
  );

  @override
  void updateConfig(ChartConfiguration config) {}
}

// Explicit test opt-in: counters only, with native size/context behavior.
class _ProbePoint() extends PointElement {
  int planReads = 0;
  int sizeCalls = 0;
  @override
  bool get supportsNativePointOptions {
    planReads++;
    return true;
  }

  @override
  bool get typedWrites => true;

  @override
  double size([Object? options]) {
    sizeCalls++;
    return super.size(options);
  }
}

class _CustomSize() extends PointElement {
  void Function()? afterSize;
  int calls = 0;
  @override
  double size([Object? options]) {
    final result = super.size(options);
    calls++;
    afterSize?.call();
    return result;
  }
}

Map<String, Object?> _config({
  String type = 'scatter',
  Object? backgroundColor = blue,
  Map<String, Object?> dataset = const {},
}) => {
  'type': type,
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[
          for (var i = 0; i < _length; i++)
            <String, Object?>{'x': i.toDouble(), 'y': (i - 3).toDouble()},
        ],
        'backgroundColor': backgroundColor,
        'borderColor': blue,
        'radius': 3.0,
        'borderWidth': 1.0,
        ...dataset,
      },
    ],
  },
  'options': <String, Object?>{
    'responsive': false,
    'animation': false,
    'parsing': false,
    'events': <String>[],
    'plugins': <String, Object?>{'legend': false, 'tooltip': false},
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
        'min': -5.0,
        'max': 10.0,
      },
    },
  },
};

Map<String, Object?> _dataset(Map<String, Object?> cfg) =>
    ((cfg['data']! as Map<String, Object?>)['datasets']! as List<Object?>)[0]!
        as Map<String, Object?>;

Chart _chart(Object cfg, {bool reference = false}) {
  final canvas = UiCanvasElement(width: 640, height: 400);
  final chart = reference ? _ReferenceChart(canvas, cfg) : Chart(canvas, cfg);
  addTearDown(chart.destroy);
  return chart;
}

List<_ProbePoint> _probes(Chart chart) {
  final points = chart.getDatasetMeta(0).data;
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

Object _observe(Chart chart) {
  final meta = chart.getDatasetMeta(0);
  return [
    _plain(meta.controller!.getMaxOverflow()),
    for (final point in meta.data.cast<PointElement>())
      [
        _plain(point.x),
        _plain(point.y),
        point.skip,
        point.stop,
        _plain(point.options),
        point.$context?.jsKeys(),
        for (final key in [
          'index',
          'dataIndex',
          'mode',
          'active',
          'parsed',
          'raw',
        ])
          _plain(point.$context?.jsRead(key)),
      ],
  ];
}

ChartConfig _typed(List<DataPoint> points, {ChartValue<ChartPaint>? color}) =>
    ChartConfig(
      type: .scatter,
      datasets: [
        ScatterDataset(
          points: points,
          backgroundColor: color ?? const ChartValue.constant(blue),
          pointRadius: 3,
          pointBorderWidth: 0,
        ),
      ],
      scales: const {
        'x': LinearAxis(min: 0, max: 8, display: false),
        'y': LinearAxis(min: -5, max: 10, display: false),
      },
      animation: ChartAnimation.none,
      extra: const {'parsing': false},
    );

List<DataPoint> _points({double step = 0}) => [
  for (var i = 0; i < _length; i++)
    DataPoint(i.toDouble(), (i - 3).toDouble() + step),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Chart.register([
    ScatterController.jsClass,
    _ReferenceScatter.value,
    _CountingScatter.value,
    PointElement.jsClass,
    LineElement.jsClass,
    LinearScale.jsClass,
  ]);

  group('one size in overflow', () {
    test('constant options take one size with no call on a native point', () {
      final chart = _chart(_config());
      final probes = _probes(chart);
      final overflow = chart.getDatasetMeta(0).controller!.getMaxOverflow();
      expect(probes.every((p) => p.sizeCalls == 0), isTrue);
      expect(probes.every((p) => p.planReads == 1), isTrue);

      final other = _chart(_config(type: 'referenceScatter'), reference: true);
      final others = _probes(other);
      expect(other.getDatasetMeta(0).controller!.getMaxOverflow(), overflow);
      expect(others.every((p) => p.sizeCalls == 1), isTrue);
      expect(others.every((p) => p.planReads == 0), isTrue);
    });

    test('a cold overflow resolves its first item, then takes the entry', () {
      final chart = _chart(_config());
      final controller = chart.getDatasetMeta(0).controller!..configure();
      final probes = _probes(chart);
      controller.getMaxOverflow();
      expect(probes.last.sizeCalls, 1);
      expect(probes.take(_length - 1).every((p) => p.sizeCalls == 0), isTrue);
    });

    test('indexed colors keep each context write with one size', () {
      final chart = _chart(_config(backgroundColor: <ChartPaint>[red, blue]));
      final probes = _probes(chart);
      chart.getDatasetMeta(0).controller!.getMaxOverflow();
      expect(probes[_length - 1].sizeCalls, 1);
      expect(probes[_length - 2].sizeCalls, 1);
      expect(probes.take(_length - 2).every((p) => p.sizeCalls == 0), isTrue);
      for (var i = 0; i < _length; i++) {
        expect(probes[i].$context?.jsRead('index'), i);
        expect(probes[i].$context?.jsRead('mode'), 'default');
      }
    });

    for (final color in [
      blue,
      <ChartPaint>[red, blue],
    ]) {
      test('twin over updates, color $color', () {
        final a = _config(backgroundColor: color);
        final b = _config(type: 'referenceScatter', backgroundColor: color);
        final first = _chart(a);
        final second = _chart(b, reference: true);
        expect(_observe(first), _observe(second));
        for (var step = 0; step < 3; step++) {
          for (final cfg in [a, b]) {
            _dataset(cfg)['data'] = <Object?>[
              for (var i = 0; i < _length; i++)
                <String, Object?>{'x': i.toDouble(), 'y': step + i - 3.0},
            ];
          }
          first.update('none');
          second.update('none');
          expect(_observe(first), _observe(second));
          final points = first.getDatasetMeta(0).data;
          expect(identical(points[3].options, points[4].options), isFalse);
        }
      });
    }

    test('twin with a data length change', () {
      for (final color in [
        blue,
        <ChartPaint>[red, blue],
      ]) {
        final a = _config(backgroundColor: color);
        final b = _config(type: 'referenceScatter', backgroundColor: color);
        final first = _chart(a);
        final second = _chart(b, reference: true);
        for (final length in [12, 3, 2, 1, 0, 6]) {
          for (final cfg in [a, b]) {
            _dataset(cfg)['data'] = <Object?>[
              for (var i = 0; i < length; i++)
                <String, Object?>{'x': i.toDouble(), 'y': 1.0 + length},
            ];
          }
          first.update('none');
          second.update('none');
          expect(_observe(first), _observe(second));
        }
      }
    });

    test('twin of a queued animation in the mode default', () {
      for (final color in [
        blue,
        <ChartPaint>[red, blue],
      ]) {
        // `stop` writes the value at its time: both charts stop at one time.
        var now = DateTime.utc(2026);
        withClock(Clock(() => now), () {
          final a = _config(backgroundColor: color);
          final b = _config(type: 'referenceScatter', backgroundColor: color);
          for (final cfg in [a, b]) {
            (cfg['options']! as Map)['animation'] = true;
            cfg['platform'] = _AnimatedPlatform.value;
          }
          final first = _chart(a);
          final second = _chart(b, reference: true);
          for (final cfg in [a, b]) {
            _dataset(cfg)['data'] = <Object?>[
              for (var i = 0; i < _length; i++)
                <String, Object?>{'x': i.toDouble(), 'y': i - 2.0},
            ];
          }
          first.update();
          second.update();
          for (final chart in [first, second]) {
            expect(chart.animationsDisabled, isFalse);
            expect(animator.has(chart), isTrue);
          }
          now = now.add(const Duration(milliseconds: 250));
          first.stop();
          second.stop();
          // The options hold the animations of their chart: read their values.
          Object values(Chart chart) {
            final meta = chart.getDatasetMeta(0);
            return [
              _plain(meta.controller!.getMaxOverflow()),
              for (final point in meta.data.cast<PointElement>())
                [
                  point.x,
                  point.y,
                  point.skip,
                  point.stop,
                  jsGet(point.options, 'radius'),
                  jsGet(point.options, 'borderWidth'),
                  jsGet(point.options, 'backgroundColor'),
                ],
            ];
          }

          expect(values(first), values(second));
        });
      }
    });

    test('option values of the size formula keep their result', () {
      for (final options in <Map<String, Object?>>[
        {'radius': 0.0},
        {'radius': double.nan},
        {'radius': -2.0, 'hoverRadius': -5.0},
        {'radius': 3.0, 'hoverRadius': 9.0},
        {'borderWidth': 0.0},
        {'borderWidth': double.nan},
        {'borderWidth': -4.0},
        {'radius': 5},
        {'hoverRadius': null},
      ]) {
        final a = _chart(_config(dataset: options));
        final b = _chart(
          _config(type: 'referenceScatter', dataset: options),
          reference: true,
        );
        expect(_observe(a), _observe(b), reason: '$options');
      }
    });

    test('foreign values keep the options object and `size`', () {
      final saved = foreignAudit;
      addTearDown(() => foreignAudit = saved);
      foreignAudit = (_, _, _) {};
      for (final options in <Map<String, Object?>>[
        {'radius': '5'},
        {'hoverRadius': '7'},
        {'borderWidth': '3'},
      ]) {
        final a = _chart(_config(dataset: options));
        final probes = _probes(a);
        final b = _chart(
          _config(type: 'referenceScatter', dataset: options),
          reference: true,
        );
        _probes(b);
        expect(_observe(a), _observe(b), reason: '$options');
        expect(probes.every((p) => p.sizeCalls == 1), isTrue);
      }
      foreignAudit = saved;
    });

    test('a user PointElement class keeps its size call at each point', () {
      for (final type in ['scatter', 'referenceScatter']) {
        final chart = _chart(_config(type: type), reference: type != 'scatter');
        final points = chart.getDatasetMeta(0).data;
        final customs = [
          for (var i = 0; i < points.length; i++) points[i] = _CustomSize(),
        ];
        chart.getDatasetMeta(0).controller!.getMaxOverflow();
        expect(customs.every((p) => p.calls == 1), isTrue);
      }
    });

    test('a custom point ends the one size before its mutation', () {
      final values = <Object?>[];
      for (final type in ['scatter', 'referenceScatter']) {
        final cfg = _config(type: type);
        final chart = _chart(cfg, reference: type != 'scatter');
        final probes = _probes(chart);
        final custom = _CustomSize()
          ..afterSize = () {
            _dataset(cfg)['radius'] = 40.0;
            chart.config.clearCache();
            chart.getDatasetMeta(0).controller!.configure();
          };
        chart.getDatasetMeta(0).data[4] = custom;
        values.add(chart.getDatasetMeta(0).controller!.getMaxOverflow());
        expect(custom.calls, 1);
        // The ordinary path after the custom point sees the new radius.
        expect(probes[3].sizeCalls, 1);
      }
      expect(values[0], values[1]);
      expect(values[0], 41);
    });

    test('a point of another class throws at its cast in descending order', () {
      for (final type in ['scatter', 'referenceScatter']) {
        final chart = _chart(_config(type: type), reference: type != 'scatter');
        final meta = chart.getDatasetMeta(0);
        final probes = _probes(chart);
        meta.data[2] = BarElement();
        expect(meta.controller!.getMaxOverflow, throwsA(isA<TypeError>()));
        expect(probes[1].planReads, 0);
        expect(probes[1].sizeCalls, 0);
      }
    });

    test('a user subclass keeps each resolve', () {
      final chart = _chart(_config(type: 'countingScatter'));
      _CountingScatter.resolves = 0;
      chart.getDatasetMeta(0).controller!.getMaxOverflow();
      expect(_CountingScatter.resolves, _length);
    });

    test('a scriptable radius keeps each call in the same order', () {
      final logs = <List<Object?>>[];
      final states = <Object>[];
      for (final type in ['scatter', 'referenceScatter']) {
        final calls = <Object?>[];
        double radius(Object? ctx) {
          final context = ctx! as JsObjectFace;
          calls.add([context.jsRead('dataIndex'), context.jsRead('mode')]);
          return 2 + (context.jsRead('dataIndex')! as num).toDouble();
        }

        final chart = _chart(
          _config(type: type, dataset: {'radius': radius}),
          reference: type != 'scatter',
        )..update('none');
        logs.add(calls);
        states.add(_observe(chart));
      }
      expect(logs[0], isNotEmpty);
      expect(logs[0], logs[1]);
      expect(states[0], states[1]);
    });

    test('options of the showLine path stay as they are', () {
      final a = _chart(_config(dataset: const {'showLine': true}));
      final b = _chart(
        _config(type: 'referenceScatter', dataset: const {'showLine': true}),
        reference: true,
      );
      expect(_observe(a), _observe(b));
    });
  });

  group('the context reader beside a plan', () {
    for (final typed in [false, true]) {
      test('fresh contexts through updates, typed root $typed', () {
        const colors = ChartValue<ChartPaint>.indexed([red, blue]);
        final lowering = ChartConfigLowering(_typed(_points(), color: colors));
        final rawConfig = _config(backgroundColor: <ChartPaint>[red, blue]);
        final a = _chart(typed ? lowering.lower() : rawConfig);
        // The twin of the typed root is a raw config with the same values.
        final other = _config(
          type: 'referenceScatter',
          backgroundColor: <ChartPaint>[red, blue],
          dataset: typed
              ? const {
                  'pointRadius': 3.0,
                  'pointBorderWidth': 0.0,
                  'borderColor': null,
                }
              : const {},
        );
        final b = _chart(other, reference: true);
        final probes = _probes(a);
        final others = _probes(b);
        a.update('none');
        b.update('none');
        expect(probes.any((p) => p.$context != null), isTrue);
        expect(others.any((p) => p.$context != null), isTrue);
        for (var i = 0; i < _length; i++) {
          final context = probes[i].$context!;
          final reference = others[i].$context!;
          expect(context.jsKeys(), reference.jsKeys());
          for (final key in ['index', 'dataIndex', 'mode', 'active']) {
            expect(context.jsRead(key), reference.jsRead(key));
          }
          expect(context.jsRead('mode'), 'default');
        }
        // A prepared point reads its capability once in each loop.
        final meta = a.getDatasetMeta(0);
        for (final point in probes) {
          point.planReads = 0;
        }
        meta.controller!.getMaxOverflow();
        expect(probes[_length - 1].planReads, 0);
        expect(probes[_length - 2].planReads, 0);
        expect(probes[0].planReads, 1);
        meta.controller!.updateElements(meta.data, 0, _length, 'none');
        expect(probes[3].$context?.jsRead('mode'), 'none');
        expect(probes[3].planReads, greaterThanOrEqualTo(2));
      });
    }

    test('a replaced context class takes the ordinary getContext', () {
      final chart = _chart(_config(backgroundColor: <ChartPaint>[red, blue]));
      final probes = _probes(chart);
      final meta = chart.getDatasetMeta(0);
      meta.controller!.getMaxOverflow();
      final context = probes[1].$context!;
      probes[1].$context = null;
      meta.controller!.getMaxOverflow();
      expect(probes[1].$context, isNotNull);
      expect(identical(probes[1].$context, context), isFalse);
      expect(probes[1].$context?.jsRead('index'), 1);
    });

    test('a store into a result stays with that result', () {
      final chart = _chart(_config(backgroundColor: <ChartPaint>[red, blue]));
      final points = chart.getDatasetMeta(0).data;
      (points[3].options! as ElementOptions).storeKey(OptionKey.radius, 77.0);
      expect((points[4].options! as ElementOptions).jsRead('radius'), 3);
      chart.update('none');
      expect((points[3].options! as ElementOptions).jsRead('radius'), 3);
    });
  });
}
