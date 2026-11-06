// Original code, not ported from Chart.js: twins of the radar update loop.
@TestOn('vm')
library;

// Keep each step of a twin as its own statement.
// ignore_for_file: cascade_invocations

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.radar.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/element_options_base.dart';
import 'package:flutter_chartjs_port/src/options/parsed.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

// The twins of Chart.js ADR 0095: the exact controller takes the typed writes
// and, in the mode `none`, the pure rest of the loop. A trivial user subclass
// of the controller keeps `Object.assign` of the property object and each
// ordinary call. Their points must have each bit in common.

/// A trivial user subclass, which keeps each ordinary call.
final class _OrdinaryRadar extends RadarController {
  _OrdinaryRadar(super.chart, super.datasetIndex, [super.newTarget]);

  static final value = JsClass(
    'OrdinaryRadar',
    superclass: RadarController.jsClass,
    statics: {'id': 'ordinaryRadar'},
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _OrdinaryRadar(chart, datasetIndex, newTarget);
    },
  );
}

/// A subclass that observes `updateElement` of a direct mode.
final class _ObservedRadar extends RadarController {
  _ObservedRadar(super.chart, super.datasetIndex, [super.newTarget]);

  static final List<String> updates = [];

  static final value = JsClass(
    'ObservedRadar',
    superclass: RadarController.jsClass,
    statics: {'id': 'observedRadar'},
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _ObservedRadar(chart, datasetIndex, newTarget);
    },
  );

  @override
  void updateElement(
    types.Element element,
    double? index,
    Object properties,
    String mode,
  ) {
    updates.add('$index $mode');
    super.updateElement(element, index, properties, mode);
  }
}

/// A user point class that observes each write by name.
final class _ObservedPoint extends PointElement {
  _ObservedPoint();

  static final List<String> writes = [];

  @override
  void operator []=(String prop, Object? value) {
    writes.add(prop);
    super[prop] = value;
  }
}

/// A user point class that counts the reads of its `active` getter.
final class _CountedActivePoint extends PointElement {
  _CountedActivePoint();

  int activeReads = 0;

  @override
  bool get active {
    activeReads++;
    return super.active;
  }
}

String _bits(Object? value) {
  if (value is double) {
    final data = ByteData(8)..setFloat64(0, value);
    return value.isNaN ? 'nan' : data.getUint64(0).toRadixString(16);
  }
  return '$value';
}

String _optionsText(Object? options) {
  if (options is! ElementOptions) return '$options';
  return [
    for (final key in options.jsKeys()) '$key=${_bits(options.jsRead(key))}',
  ].join(',');
}

/// Each observable property of the points of the dataset 0 of [chart].
List<String> _pointsText(Chart chart) {
  final meta = chart.getDatasetMeta(0);
  final seen = <Object?>[];
  return [
    for (final element in meta.data)
      () {
        final point = element as PointElement;
        final options = point.options;
        seen.add(options);
        return [
          point.runtimeType == PointElement,
          _bits(point['x']),
          _bits(point['y']),
          _bits(point['angle']),
          point['skip'],
          point['stop'],
          point['parsed'],
          point.active,
          _optionsText(options),
          (options! as ElementOptions).isFrozen,
          point[r'$context'] == undefined,
        ].join(' ');
      }(),
    // Each point has its own options object, or the one shared object.
    'distinct ${seen.toSet().length}',
    'parsed ${[for (final item in meta.parsed) _parsedText(item)]}',
  ];
}

String _parsedText(Object? item) => item is ParsedItem
    ? '${item.jsKeys()} ${_bits(item.r)}'
    : 'raw ${_bits(item)}';

AnyObject _config(
  String type, {
  List<Object?>? data,
  int n = 24,
  AnyObject Function()? dataset,
  AnyObject Function()? options,
  AnyObject Function()? scale,
}) {
  final values =
      data ?? <Object?>[for (var i = 0; i < n; i++) ((i * 13) % 50) * 2.0];
  return <String, Object?>{
    'type': type,
    'data': <String, Object?>{
      'labels': <Object?>[for (var i = 0; i < values.length; i++) 'L$i'],
      'datasets': <Object?>[
        <String, Object?>{'data': values, ...?dataset?.call()},
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'events': <String>[],
      'scales': <String, Object?>{
        'r': <String, Object?>{
          'type': 'radialLinear',
          'min': 0.0,
          'max': 100.0,
          ...?scale?.call(),
        },
      },
      ...?options?.call(),
    },
  };
}

/// Compares the points of the exact controller and of the subclass, after the
/// start and after [steps] in order. [calls] holds the user calls of a run.
void _expectTwin(
  AnyObject Function(String type) config, {
  List<void Function(Chart chart)> steps = const [],
  List<String>? calls,
}) {
  ({List<String> points, List<String> calls}) run(String type) {
    calls?.clear();
    final chart = acquireChart(config(type));
    final points = _pointsText(chart);
    for (final step in steps) {
      step(chart);
      points.addAll(_pointsText(chart));
    }
    chart.update('none');
    points.addAll(_pointsText(chart));
    return (points: points, calls: [...?calls]);
  }

  final exact = run('radar');
  final ordinary = run('ordinaryRadar');
  expect(exact.points, ordinary.points);
  expect(exact.calls, ordinary.calls);
}

void main() {
  Chart.register([_OrdinaryRadar.value, _ObservedRadar.value]);

  group('twins', () {
    testWidgets('numbers in the mode none', (tester) async {
      _expectTwin(_config);
    });

    testWidgets('numbers on a growing and shrinking dataset', (tester) async {
      AnyObject config(String type) => _config(type, n: 8);
      void setData(Chart chart, List<Object?> data) {
        final set = (jsGet(chart.data, 'datasets')! as List<Object?>)[0];
        (set! as Map<String, Object?>)['data'] = data;
      }

      _expectTwin(
        config,
        steps: [
          (chart) {
            setData(chart, <Object?>[for (var i = 0; i < 20; i++) i * 3.0]);
            chart.update('none');
          },
          (chart) {
            setData(chart, <Object?>[1.0, 2.0, 3.0]);
            chart.update('none');
          },
        ],
      );
    });

    testWidgets('null, NaN, infinity and undefined items', (tester) async {
      _expectTwin(
        (type) => _config(
          type,
          data: <Object?>[
            5.0,
            null,
            double.nan,
            double.infinity,
            undefined,
            -0.0,
            0,
            7,
            null,
            9.5,
          ],
        ),
      );
    });

    testWidgets('a first item that is null', (tester) async {
      _expectTwin(
        (type) => _config(type, data: <Object?>[null, 1.0, null, 2.0, 3.0]),
      );
    });

    testWidgets('strings, which the parse converts', (tester) async {
      _expectTwin(
        (type) => _config(type, data: <Object?>['5', 'x', '', ' 7 ', '1e1']),
      );
    });

    testWidgets('object items', (tester) async {
      _expectTwin(
        (type) => _config(
          type,
          data: <Object?>[
            <String, Object?>{'r': 5.0},
            <String, Object?>{'r': 6.0, 'extra': 1.0},
            <String, Object?>{'other': 6.0},
            <String, Object?>{'r': null},
          ],
        ),
      );
    });

    testWidgets('parsing false', (tester) async {
      _expectTwin(
        (type) => _config(
          type,
          data: <Object?>[
            <String, Object?>{'r': 5.0},
            <String, Object?>{'r': 6.0},
          ],
          options: () => {'parsing': false},
        ),
      );
    });

    testWidgets('parsing false with numbers', (tester) async {
      _expectTwin(
        (type) => _config(
          type,
          data: const <Object?>[5.0, 3.0, 1.0],
          options: () => {'parsing': false},
        ),
      );
    });

    testWidgets('a reversed scale with a start angle', (tester) async {
      _expectTwin(
        (type) => _config(
          type,
          scale: () => {'reverse': true, 'startAngle': 33.0},
        ),
      );
    });

    testWidgets('a scale with no labels at all', (tester) async {
      _expectTwin((type) {
        final config = _config(type);
        (config['data']! as Map<String, Object?>)['labels'] = <Object?>[];
        return config;
      });
    });

    testWidgets('hidden data points', (tester) async {
      _expectTwin(
        _config,
        steps: [
          (chart) {
            chart
              ..toggleDataVisibility(1)
              ..toggleDataVisibility(4)
              ..update('none');
          },
        ],
      );
    });

    testWidgets('a hidden dataset, shown again', (tester) async {
      _expectTwin(
        _config,
        steps: [
          (chart) => chart
            ..setDatasetVisibility(0, false)
            ..update('none'),
          (chart) => chart
            ..setDatasetVisibility(0, true)
            ..update('none'),
        ],
      );
    });

    testWidgets('an active point stops the loop at its index', (tester) async {
      _expectTwin(
        (type) => _config(
          type,
          options: () => {
            'elements': <String, Object?>{
              'point': <String, Object?>{
                'hoverRadius': 9.0,
                'hoverBackgroundColor': const ui.Color(0xFFFF0000),
              },
            },
          },
        ),
        steps: [
          (chart) => chart
            ..setActiveElements([
              <String, Object?>{'datasetIndex': 0.0, 'index': 3.0},
            ])
            ..update('none'),
          (chart) => chart
            ..setActiveElements([
              <String, Object?>{'datasetIndex': 0.0, 'index': 0.0},
            ])
            ..update('none'),
        ],
      );
    });

    testWidgets('the modes reset, default and resize', (tester) async {
      _expectTwin(
        _config,
        steps: [
          (chart) => chart.update('reset'),
          (chart) => chart.update('none'),
          (chart) => chart.update('resize'),
          (chart) {
            chart.getDatasetMeta(0).controller!.reset();
          },
          (chart) => chart.update(),
        ],
      );
    });

    testWidgets('animated updates take the object', (tester) async {
      _expectTwin(
        (type) => _config(
          type,
          options: () => {
            'animation': <String, Object?>{'duration': 1000.0},
          },
        ),
        steps: [(chart) => chart.update(), (chart) => chart.update('none')],
      );
    });

    testWidgets('a scriptable point option runs with the same contexts', (
      tester,
    ) async {
      final calls = <String>[];
      _expectTwin(
        (type) => _config(
          type,
          dataset: () => {
            'pointRadius': (Object? ctx) {
              final context = ctx! as JsObjectFace;
              calls.add(
                '${context.jsRead('index')} ${context.jsRead('dataIndex')} '
                '${context.jsRead('parsed') is ParsedItem}',
              );
              return 2.0;
            },
          },
        ),
        calls: calls,
      );
      expect(calls, isNotEmpty);
    });

    testWidgets('a scriptable option that writes the scale between points', (
      tester,
    ) async {
      final calls = <String>[];
      _expectTwin(
        (type) {
          late Chart chart;
          return _config(
            type,
            dataset: () => {
              'pointRadius': (Object? ctx) {
                final context = ctx! as JsObjectFace;
                final index = context.jsRead('index')! as double;
                final scale = context.jsRead('chart')! as Chart;
                chart = scale;
                final r = chart.scales['r']!;
                // The next points of the loop read the new range.
                if (index == 5) r.max = 50;
                calls.add('$index ${r.max}');
                return 2.0;
              },
            },
          );
        },
        calls: calls,
      );
    });
  });

  group('guards', () {
    testWidgets('a user subclass gets each updateElement', (tester) async {
      _ObservedRadar.updates.clear();
      final chart = acquireChart(_config('observedRadar', n: 4));
      _ObservedRadar.updates.clear();
      chart.update('none');
      expect(_ObservedRadar.updates, [
        'null none',
        '0.0 none',
        '1.0 none',
        '2.0 none',
        '3.0 none',
      ]);
    });

    testWidgets('a user point class gets each write by name, in order', (
      tester,
    ) async {
      final chart = acquireChart(_config('radar', n: 6));
      final meta = chart.getDatasetMeta(0);
      meta.data
        ..[0] = _ObservedPoint()
        ..[3] = _ObservedPoint();
      _ObservedPoint.writes.clear();
      chart.update('none');
      expect(_ObservedPoint.writes, [
        for (var i = 0; i < 2; i++) ...['x', 'y', 'angle', 'skip', 'options'],
      ]);
      expect(_pointsText(chart).first, startsWith('false '));
      // A point of the built-in class after the user point takes its position.
      final twin = acquireChart(_config('ordinaryRadar', n: 6));
      twin.getDatasetMeta(0).data
        ..[0] = _ObservedPoint()
        ..[3] = _ObservedPoint();
      twin.update('none');
      expect(_pointsText(chart), _pointsText(twin));
    });

    testWidgets('a user point in the rest of the loop gets one active read', (
      tester,
    ) async {
      // The built-in point at the index 0 starts the rest of the loop, and the
      // user point at the index 3 ends it. The class test comes before each
      // read of that point: the ordinary loop makes the one read of upstream.
      int reads(String type) {
        final chart = acquireChart(_config(type, n: 6));
        final meta = chart.getDatasetMeta(0);
        final point = _CountedActivePoint();
        meta.data[3] = point;
        meta.controller!.updateElements(meta.data, 0, 6, 'none');
        return point.activeReads;
      }

      expect(reads('radar'), 1);
      expect(reads('ordinaryRadar'), 1);
    });

    testWidgets('a controller with option sharing shares its cached options', (
      tester,
    ) async {
      final chart = acquireChart(_config('radar', n: 4));
      final controller = chart.getDatasetMeta(0).controller!;
      controller.enableOptionSharing = true;
      chart.update('none');
      final twin = acquireChart(_config('ordinaryRadar', n: 4));
      (twin.getDatasetMeta(0).controller!).enableOptionSharing = true;
      twin.update('none');
      expect(_pointsText(chart), _pointsText(twin));
    });

    testWidgets('a reset before the first layout writes undefined by name', (
      tester,
    ) async {
      final chart = acquireChart(_config('radar', n: 2));
      final scale = chart.scales['r']! as types.RadialLinearScale;
      expect(scale.xCenter, isNotNull);
      chart.update('reset');
      final point = chart.getDatasetMeta(0).data.first as PointElement;
      expect(point.x, scale.xCenter);
      expect(point.y, scale.yCenter);
    });

    testWidgets('the cached options stay frozen, and each copy is not', (
      tester,
    ) async {
      final chart = acquireChart(_config('radar', n: 4));
      final controller = chart.getDatasetMeta(0).controller!;
      chart.update('none');
      final cached = controller.cachedPointNoneOptions;
      expect(cached, isNotNull);
      expect(cached!.isFrozen, isTrue);
      final points = chart.getDatasetMeta(0).data;
      final copies = {
        for (final point in points) (point as PointElement).options,
      };
      expect(copies, hasLength(4));
      expect(copies.contains(cached), isFalse);
      for (final copy in copies) {
        expect((copy! as ElementOptions).isFrozen, isFalse);
      }
    });
  });
}
