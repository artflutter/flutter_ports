// Original code, not ported from Chart.js: scatter overflow and context twins.
@TestOn('vm')
library;

import 'dart:collection' show ListBase;
import 'dart:typed_data' show Uint8List;
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/pure.dart';

import 'package:clock/clock.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/context_keys.dart';
import '../../support/parsed_items.dart';

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

ChartConfigurationScope _config({
  String type = 'scatter',
  Object? backgroundColor = blue,
  Map<String, Object?> dataset = const {},
}) => (ChartConfigurationScope()
  ..type = type
  ..data = (ChartDataScope()
    ..datasets = <Object?>[
      scopeFromMap(LineControllerDatasetOptionsScope(), {
        'data': <Object?>[
          for (var i = 0; i < _length; i++)
            <String, Object?>{'x': i.toDouble(), 'y': (i - 3).toDouble()},
        ],
        'backgroundColor': backgroundColor,
        'borderColor': blue,
        'radius': 3.0,
        'borderWidth': 1.0,
        ...dataset,
      }),
    ])
  ..options = scopeFromMap(
    ChartOptionsScope()
      ..responsive = false
      ..animation = false,
    {
      'parsing': false,
      'events': <String>[],
      'plugins': <String, Object?>{'legend': false, 'tooltip': false},
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'type': 'linear',
          'display': ScaleDisplay.off,
          'min': 0.0,
          'max': 8.0,
        },
        'y': <String, Object?>{
          'type': 'linear',
          'display': ScaleDisplay.off,
          'min': -5.0,
          'max': 10.0,
        },
      },
    },
  ));

JsObjectFace _dataset(ChartConfigurationScope cfg) =>
    (jsGet(cfg['data'], 'datasets')! as List<Object?>)[0]! as JsObjectFace;

Chart _chart(Object cfg, {bool reference = false}) {
  final canvas = UiCanvasElement(width: 640, height: 400);
  final chart = reference
      ? _ReferenceChart(canvas, withParsedDataItems(cfg))
      : Chart(canvas, withParsedDataItems(cfg));
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
}

ChartConfig _typed(List<DataPoint> points, {ChartValue<ChartPaint>? color}) =>
    ChartConfig(
      datasets: [
        ScatterDataset(
          data: .points(points),
          backgroundColor: color ?? const ChartValue.constant(blue),
          pointRadius: const .constant(3),
          pointBorderWidth: 0,
        ),
      ],
      scales: const [
        LinearAxis(.x, min: 0, max: 8, display: ScaleDisplay.off),
        LinearAxis(.y, min: -5, max: 10, display: ScaleDisplay.off),
      ],
      animation: ChartAnimation.none,
      parsing: false,
    );

List<DataPoint> _points({double step = 0}) => [
  for (var i = 0; i < _length; i++)
    DataPoint(i.toDouble(), (i - 3).toDouble() + step),
];

/// A List of the app whose reads run code of the app: its `operator []`
/// counts each read.
final class _ReadingList(final List<Object?> _inner) extends ListBase<Object?> {
  int reads = 0;

  @override
  int get length => _inner.length;

  @override
  set length(int value) => _inner.length = value;

  @override
  Object? operator [](int index) {
    reads++;
    return _inner[index];
  }

  @override
  void operator []=(int index, Object? value) => _inner[index] = value;
}

/// [_observe] with the clip of the meta and the chart area, which the
/// overflow of an update decides.
Object _observeAll(Chart chart) {
  final meta = chart.getDatasetMeta(0);
  final area = chart.chartArea!;
  final clip = meta.clip;
  return [
    _observe(chart),
    [clip.left, clip.top, clip.right, clip.bottom],
    [area.left, area.top, area.right, area.bottom],
  ];
}

/// The draw calls of one draw of [chart].
List<Object?> _drawCalls(Chart chart) {
  final target = chart.ctx!;
  final recording = RecordingContext(target);
  chart.ctx = recording;
  try {
    chart.draw();
  } finally {
    chart.ctx = target;
  }
  return recording.getCalls();
}

Future<Uint8List> _pixels(Chart chart) async {
  chart.draw();
  final canvas = chart.canvas! as UiCanvasElement;
  final recorder = ui.PictureRecorder();
  canvas.getContext2d().paint(ui.Canvas(recorder), ui.Offset.zero, 1, 1);
  final picture = recorder.endRecording();
  final image = await picture.toImage(canvas.width, canvas.height);
  final data = await image.toByteData();
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

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
        expect(contextField(probes[i].$context, 'index'), i);
        expect(contextField(probes[i].$context, 'mode'), 'default');
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
            _dataset(cfg)['data'] = parsedItemsOf([
              for (var i = 0; i < _length; i++)
                <String, Object?>{'x': i.toDouble(), 'y': step + i - 3.0},
            ]);
          }
          first.update(UpdateMode.none);
          second.update(UpdateMode.none);
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
            _dataset(cfg)['data'] = parsedItemsOf([
              for (var i = 0; i < length; i++)
                <String, Object?>{'x': i.toDouble(), 'y': 1.0 + length},
            ]);
          }
          first.update(UpdateMode.none);
          second.update(UpdateMode.none);
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
            (cfg['options']! as JsObjectFace)['animation'] = true;
            cfg['platform'] = _AnimatedPlatform.value;
          }
          final first = _chart(a);
          final second = _chart(b, reference: true);
          for (final cfg in [a, b]) {
            _dataset(cfg)['data'] = parsedItemsOf([
              for (var i = 0; i < _length; i++)
                <String, Object?>{'x': i.toDouble(), 'y': i - 2.0},
            ]);
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
        double radius(ScriptableContext context) {
          calls.add([context.dataIndex, context.mode]);
          return 2 + context.dataIndex!.toDouble();
        }

        final chart = _chart(
          _config(type: type, dataset: {'radius': radius}),
          reference: type != 'scatter',
        )..update(UpdateMode.none);
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
        a.update(UpdateMode.none);
        b.update(UpdateMode.none);
        expect(probes.any((p) => p.$context != null), isTrue);
        expect(others.any((p) => p.$context != null), isTrue);
        for (var i = 0; i < _length; i++) {
          final context = probes[i].$context!;
          final reference = others[i].$context!;
          expect(contextKeys(context), contextKeys(reference));
          for (final key in ['index', 'dataIndex', 'mode', 'active']) {
            expect(contextField(context, key), contextField(reference, key));
          }
          expect(contextField(context, 'mode'), 'default');
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
        expect(contextField(probes[3].$context, 'mode'), 'none');
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
      expect(contextField(probes[1].$context, 'index'), 1);
    });

    test('a store into a result stays with that result', () {
      final chart = _chart(_config(backgroundColor: <ChartPaint>[red, blue]));
      final points = chart.getDatasetMeta(0).data;
      (points[3].options! as ElementOptions).storeKey(OptionKey.radius, 77.0);
      expect((points[4].options! as ElementOptions).jsRead('radius'), 3);
      chart.update(UpdateMode.none);
      expect((points[3].options! as ElementOptions).jsRead('radius'), 3);
    });
  });

  // Chart.js ADR 0163: the size fields of the point plan.
  group('indexed sizes', () {
    final cases = <String, Map<String, Object?> Function()>{
      'radius': () => {
        'radius': <double>[2, 3, 4, 5, 6, 7, 8, 9],
      },
      'radius, shorter than the data': () => {
        'radius': <double>[2, 5, 3],
      },
      'radius of int values': () => {
        'radius': <int>[2, 6, 4],
      },
      'radius with NaN, 0 and a negative item': () => {
        'radius': <double>[2, double.nan, 0, -3, 4],
      },
      'border width': () => {
        'borderWidth': <double>[0, 1, 2.5],
      },
      'hover radius': () => {
        'radius': 2.0,
        'hoverRadius': <double>[1, 9, 4],
      },
      'all three with indexed colors': () => {
        'radius': <double>[2, 3, 4],
        'hoverRadius': <num>[5, 1.5],
        'borderWidth': <double>[1, 0, 3, 2],
        'backgroundColor': <ChartPaint>[red, blue],
      },
      'one item': () => {
        'radius': <double>[6],
      },
    };

    for (final MapEntry(key: name, value: options) in cases.entries) {
      test('twin over updates: $name', () async {
        final a = _config(dataset: options());
        final b = _config(type: 'referenceScatter', dataset: options());
        final first = _chart(a);
        final second = _chart(b, reference: true);
        expect(_observeAll(first), _observeAll(second));
        for (var step = 0; step < 3; step++) {
          for (final cfg in [a, b]) {
            _dataset(cfg)['data'] = parsedItemsOf([
              for (var i = 0; i < _length; i++)
                <String, Object?>{'x': i.toDouble(), 'y': step + i - 3.0},
            ]);
            // The lists stay live: an item changes in place.
            final radius = _dataset(cfg)['radius'];
            if (radius is List<double>) radius[0] = 2.0 + step;
          }
          first.update(UpdateMode.none);
          second.update(UpdateMode.none);
          expect(_observeAll(first), _observeAll(second), reason: '$step');
          expect(_drawCalls(first), _drawCalls(second), reason: '$step');
          expect(await _pixels(first), await _pixels(second));
        }
      });
    }

    test('the plan takes each size with no options object and no size', () {
      final chart = _chart(
        _config(
          dataset: {
            'radius': <double>[2, 3, 4],
          },
        ),
      );
      final probes = _probes(chart);
      final overflow = chart.getDatasetMeta(0).controller!.getMaxOverflow();
      // Two ordinary resolutions warm the plan, then each index takes it.
      expect(probes[_length - 1].sizeCalls, 1);
      expect(probes[_length - 2].sizeCalls, 1);
      expect(probes.take(_length - 2).every((p) => p.sizeCalls == 0), isTrue);
      // The radius 4 at the indexes 2 and 5, with the border 1: (4 + 1) / 1.
      expect(overflow, 5);
      for (var i = 0; i < _length; i++) {
        expect(contextField(probes[i].$context, 'index'), i);
        expect(contextField(probes[i].$context, 'mode'), 'default');
      }
      for (final probe in probes) {
        probe.sizeCalls = 0;
      }
      chart.update(UpdateMode.none);
      // The overflow before the layout resolves the last two points, then
      // takes the plan. The loop takes it from its third point, and the
      // overflow pass of the update takes each size from it. The draw of each
      // point calls `size` once (element.point.ts:91).
      expect(probes.map((p) => p.sizeCalls), [
        ...List.filled(_length - 2, 1),
        2,
        2,
      ]);
      final points = chart.getDatasetMeta(0).data;
      for (var i = 0; i < _length; i++) {
        expect(jsGet(points[i].options, 'radius'), [2, 3, 4][i % 3]);
        expect(jsGet(points[i].options, r'$shared'), isFalse);
      }
      expect(identical(points[3].options, points[6].options), isFalse);
    });

    test('a List of the app keeps its reads and each size call', () {
      final reads = <int>[];
      final states = <Object>[];
      for (final type in ['scatter', 'referenceScatter']) {
        final radius = _ReadingList(<Object?>[2.0, 3.0, 4.0]);
        final chart = _chart(
          _config(type: type, dataset: {'radius': radius}),
          reference: type != 'scatter',
        );
        final probes = _probes(chart);
        radius.reads = 0;
        chart.getDatasetMeta(0).controller!.getMaxOverflow();
        chart.update(UpdateMode.none);
        reads.add(radius.reads);
        states.add(_observeAll(chart));
        expect(probes.every((p) => p.sizeCalls >= 1), isTrue);
      }
      expect(reads[0], greaterThan(0));
      expect(reads[0], reads[1]);
      expect(states[0], states[1]);
    });

    test('an item that is not a number keeps the options object', () {
      final saved = foreignAudit;
      addTearDown(() => foreignAudit = saved);
      foreignAudit = (_, _, _) {};
      for (final items in <List<Object?>>[
        <Object?>[2.0, '5', 4.0],
        <Object?>[2.0, null, 4.0],
        <Object?>[2.0, true, 4.0],
        <Object?>[2.0, 3.0, undefined],
      ]) {
        final a = _chart(_config(dataset: {'radius': List.of(items)}));
        final probes = _probes(a);
        final b = _chart(
          _config(type: 'referenceScatter', dataset: {'radius': items}),
          reference: true,
        );
        _probes(b);
        expect(_observeAll(a), _observeAll(b), reason: '$items');
        expect(probes.every((p) => p.sizeCalls == 1), isTrue, reason: '$items');
      }
      foreignAudit = saved;
    });

    test('a scriptable radius beside an indexed width keeps its calls', () {
      final logs = <List<Object?>>[];
      final states = <Object>[];
      for (final type in ['scatter', 'referenceScatter']) {
        final calls = <Object?>[];
        double radius(ScriptableContext context) {
          calls.add([context.dataIndex, context.mode]);
          return 2 + context.dataIndex!.toDouble();
        }

        final chart = _chart(
          _config(
            type: type,
            dataset: {
              'radius': radius,
              'borderWidth': <double>[1, 2],
            },
          ),
          reference: type != 'scatter',
        )..update(UpdateMode.none);
        logs.add(calls);
        states.add(_observeAll(chart));
      }
      expect(logs[0], isNotEmpty);
      expect(logs[0], logs[1]);
      expect(states[0], states[1]);
    });

    test('a list that the app empties falls back as upstream does', () {
      final a = _config(
        dataset: {
          'radius': <double>[2, 3],
        },
      );
      final b = _config(
        type: 'referenceScatter',
        dataset: {
          'radius': <double>[2, 3],
        },
      );
      final first = _chart(a);
      final second = _chart(b, reference: true);
      for (final cfg in [a, b]) {
        (_dataset(cfg)['radius']! as List<double>).clear();
      }
      first.update(UpdateMode.none);
      second.update(UpdateMode.none);
      expect(_observeAll(first), _observeAll(second));
    });
  });

  // Chart.js ADR 0163: the overflow pass of `update_` decides `meta.clip`
  // only on a scale with no `min` or `max` (scaleClip of
  // core.datasetController.js). The twins above set both, so these twins
  // free the scales.
  group('indexed sizes in the clip of the overflow pass', () {
    ChartConfigurationScope free(ChartConfigurationScope cfg) {
      final options = cfg['options']! as JsObjectFace;
      for (final axis in (options['scales']! as OptionScope).jsKeys().map(
        (key) => jsGet(options['scales'], key),
      )) {
        (axis! as JsObjectFace)
          ..jsDelete('min')
          ..jsDelete('max');
      }
      return cfg;
    }

    List<double?> clipOf(Chart chart) {
      final clip = chart.getDatasetMeta(0).clip;
      return [clip.left, clip.top, clip.right, clip.bottom];
    }

    final cases = <String, Map<String, Object?> Function()>{
      'the largest radius at index 0': () => {
        'radius': <double>[20, 3, 4, 5, 6, 7],
      },
      'the largest radius at index 1': () => {
        'radius': <double>[2, 30, 4],
      },
      'the largest radius in the middle': () => {
        'radius': <double>[2, 3, 4, 50, 6, 7, 8, 4],
      },
      'the largest border width in the middle': () => {
        'borderWidth': <double>[1, 1, 1, 25, 1, 1, 1, 1],
      },
      'the largest hover radius in the middle': () => {
        'hoverRadius': <double>[1, 1, 1, 1, 33, 1, 1, 1],
      },
      'an infinite radius and border width': () => {
        'radius': <double>[2, 3, double.infinity, 4],
        'borderWidth': <double>[1, 2, double.negativeInfinity],
      },
      'zero radii': () => {
        'radius': <double>[0, 0, 0],
      },
      'negative radii': () => {
        'radius': <double>[-5, -2, -9],
        'hoverRadius': <double>[3, 8],
      },
      'NaN in the middle': () => {
        'radius': <double>[2, 3, 4, double.nan, 6, 7, 8, 4],
      },
    };

    for (final MapEntry(key: name, value: options) in cases.entries) {
      test('twin over updates: $name', () {
        final a = free(_config(dataset: options()));
        final b = free(_config(type: 'referenceScatter', dataset: options()));
        final first = _chart(a);
        final second = _chart(b, reference: true);
        for (var step = 0; step < 3; step++) {
          for (final cfg in [a, b]) {
            _dataset(cfg)['data'] = parsedItemsOf([
              for (var i = 0; i < _length; i++)
                <String, Object?>{'x': i.toDouble(), 'y': step * i - 3.0},
            ]);
            // The last item changes in place: the pass reads the live list.
            final radius = _dataset(cfg)['radius'];
            if (radius is List<double>) {
              radius[radius.length - 1] = 2.0 + 9 * step;
            }
          }
          first.update(UpdateMode.none);
          second.update(UpdateMode.none);
          expect(clipOf(first), clipOf(second), reason: '$step');
          expect(_observeAll(first), _observeAll(second), reason: '$step');
          expect(_drawCalls(first), _drawCalls(second), reason: '$step');
        }
      });
    }

    test('lists of the elements, a hidden dataset and an active point', () {
      for (final variant in ['elements', 'hidden', 'active']) {
        ChartConfigurationScope make(String type) {
          final cfg = free(_config(type: type));
          final dataset = _dataset(cfg);
          switch (variant) {
            case 'elements':
              dataset.jsDelete('radius');
              (cfg['options']! as JsObjectFace)['elements'] = <String, Object?>{
                'point': <String, Object?>{
                  'radius': <double>[2, 9, 4],
                  'hoverRadius': <double>[2, 4],
                },
              };
            case 'hidden':
              dataset
                ..['radius'] = <double>[2, 9, 4]
                ..['hidden'] = true;
            default:
              dataset
                ..['radius'] = <double>[2, 9, 4]
                ..['pointHoverRadius'] = <double>[12, 1];
          }
          return cfg;
        }

        final first = _chart(make('scatter'));
        final second = _chart(make('referenceScatter'), reference: true);
        if (variant == 'active') {
          for (final chart in [first, second]) {
            chart.setActiveElements([
              const ActiveElement(datasetIndex: 0, index: 4),
            ]);
          }
        }
        first.update(UpdateMode.none);
        second.update(UpdateMode.none);
        expect(clipOf(first), clipOf(second), reason: variant);
        expect(_observeAll(first), _observeAll(second), reason: variant);
        expect(_drawCalls(first), _drawCalls(second), reason: variant);
      }
    });
  });
}
