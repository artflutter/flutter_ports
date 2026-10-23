// Original code, not ported from Chart.js: radar controller reference tests.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.animation.dart' as animation;
import 'package:flutter_chartjs_port/src/core/core.config.dart'
    show themeConfigKey;
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart'
    show notifyArrayListeners;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsSplice;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/theme/presets.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart';
import 'controller_chart_harness.dart';
import 'controller_radar_reference.dart';

// The port-only reference tests of lib/src/controllers/controller.radar.dart
// (Chart.js ADR 0030). The spec port is test/specs/controller.radar_test.dart.
//
// The reference group compares real radar charts with the charts of
// tool/reference/controller_radar_reference.mjs: a build of the pinned
// Chart.js in Node.js v24.12.0 on x64 (Chart.js ADR 0032), with a mock
// context that measures text in Liberation Sans 2.1.5. Each chart comes from
// acquireChart in a testWidgets case (Chart.js ADR 0022). The case runs its
// steps and compares the observations, the hit queries and the draw calls
// with the element draws (controller_chart_harness.dart).
//
// The 8 cases of Chart.js ADR 0030, section 7 run two times: unthemed, and
// with the light preset (theming.md section 8 test 3). The cases whose names
// start with `parsed:` (Chart.js ADR 0036, section 9) or `interfaces:`
// (Chart.js ADR 0028, section 8) run unthemed only. The groups `parsed
// data` and `interfaces` hold the pin tests that need no generated value.
//
// flutter_test_config.dart registers the radar controller with the
// built-in components before main() (Chart.js ADR 0030, section 3 item 4).

/// The probes of the key `extra` of the generator, with the same bodies.
final Map<String, Object? Function(Chart chart)> _extras = {
  'pointAngles': _pointAngles,
};

/// The probe `pointAngles` of the generator: for each dataset, the `angle`
/// of each point.
Object? _pointAngles(Chart chart) => [
  for (var i = 0; i < _datasetCount(chart); i++)
    [
      for (final element in chart.getDatasetMeta(i.toDouble()).data)
        (element as types.ElementPropertyRead)['angle'],
    ],
];

/// `chart.data.datasets.length`.
int _datasetCount(Chart chart) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>).length;

/// The config of a radar chart with the labels [labels] and one dataset
/// with [data] and the keys of [extra].
AnyObject _radar(
  List<Object?> data, {
  List<Object?> labels = const ['a', 'b', 'c'],
  AnyObject extra = const {},
  AnyObject? options,
}) => <String, Object?>{
  'type': 'radar',
  'data': <String, Object?>{
    'labels': <Object?>[...labels],
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[...data],
        ...extra,
      },
    ],
  },
  'options': ?options,
};

/// The `[datasetIndex, index]` pairs of the hit items of [mode] at
/// ([x], [y]) with `intersect: true` and the keys of [extra].
List<List<Object?>> _hitsAt(
  Chart chart,
  double x,
  double y,
  String mode, [
  Map<String, Object?> extra = const {},
]) => [
  for (final item in chart.getElementsAtEventForMode(
    ReferenceEvent(x, y),
    mode,
    <String, Object?>{'intersect': true, ...extra},
    false,
  ))
    [item.datasetIndex, item.index],
];

/// The data List of the dataset 0 of [chart].
List<Object?> _data0(Chart chart) =>
    jsGet(jsGetIndex(jsGet(chart.data, 'datasets'), 0), 'data')!
        as List<Object?>;

/// Expects `line.points` of the dataset 0 of [chart] to hold the elements
/// of `meta.data` in the same order (Chart.js ADR 0028, section 3).
void _expectLinePoints(Chart chart, int length) {
  final meta = chart.getDatasetMeta(0);
  final line = meta.dataset! as LineElement;
  expect(meta.data.length, length);
  expect(line.points.length, meta.data.length);
  for (var i = 0; i < meta.data.length; i++) {
    expect(identical(line.points[i], meta.data[i]), isTrue, reason: '$i');
  }
}

void main() {
  testReferenceOrigin(
    node: controllerRadarReferenceNode,
    arch: controllerRadarReferenceArch,
    dist: controllerRadarReferenceDist,
    commit: controllerRadarReferenceCommit,
  );
  testReferenceWidths(controllerRadarReferenceWidths);

  test('the reference has the 8 cases of Chart.js ADR 0030 first', () {
    final names = [for (final c in controllerRadarReference) c.name];
    bool prefixed(String n) =>
        n.startsWith('parsed:') || n.startsWith('interfaces:');
    expect(names.first, 'default');
    expect(names.length, greaterThan(8));
    expect(names.take(8).where(prefixed), isEmpty);
    expect(names.skip(8).where((n) => !prefixed(n)), isEmpty);
  });

  testControllerChartCases(controllerRadarReference, extras: _extras);

  group('theming.md §8 test 3: the light preset', () {
    testControllerChartCases(
      controllerRadarReference,
      extras: _extras,
      theme: compileChartTheme(ChartThemes.light),
    );

    testWidgets('the light preset leaves no stale scale key', (tester) async {
      final snapshot = jsonDecode(
        File(
          'test/port/theme/light_snapshot.json',
        ).readAsStringSync(),
      ) as Map<String, Object?>;
      final config =
          copyReference(controllerRadarReference.first.config)! as AnyObject;
      config[themeConfigKey] = compileChartTheme(ChartThemes.light);
      expectNoStaleScaleKeys(acquireChart(config), snapshot);
    });
  });

  // The pin tests of the parsed-data spec, section 7.3. The generated cases
  // `parsed: ...` give the upstream values of the same configs.
  group('parsed data', () {
    testWidgets('parsing false with numbers gives NaN points that skip', (
      tester,
    ) async {
      final chart = acquireChart(
        _radar(
          const [5.0, 3.0, 1.0],
          extra: const <String, Object?>{'parsing': false},
        ),
      );
      final meta = chart.getDatasetMeta(0);
      expect(meta.data, hasLength(3));
      for (final point in meta.data) {
        final read = point as types.ElementPropertyRead;
        expect(point.x, isNaN);
        expect(point.y, isNaN);
        expect(read['skip'], isTrue);
      }
    });

    testWidgets('parsing false with a null item throws a TypeError', (
      tester,
    ) async {
      expect(
        () => acquireChart(
          _radar(
            const [
              <String, Object?>{'r': 5.0},
              null,
              <String, Object?>{'r': 1.0},
            ],
            extra: const <String, Object?>{'parsing': false},
          ),
        ),
        throwsA(isA<TypeError>()),
      );
    });

    testWidgets('a label index past the end gives the label undefined', (
      tester,
    ) async {
      final chart = acquireChart(
        _radar(const [1.0, 2.0], labels: const ['a']),
      );
      final controller = chart.getDatasetMeta(0).controller!;
      expect(controller.getLabelAndValue(0).label, 'a');
      expect(identical(controller.getLabelAndValue(1).label, undefined), true);
      expect(controller.getLabelAndValue(1).value, '2');
    });
  });

  // The pin tests of the interfaces spec, section 7.3.
  group('interfaces', () {
    group('line.points', () {
      testWidgets('after chart.update()', (tester) async {
        final chart = acquireChart(_radar(const [10.0, 20.0, 5.0]))..update();
        _expectLinePoints(chart, 3);
      });

      testWidgets('after a push and chart.update()', (tester) async {
        final chart = acquireChart(_radar(const [10.0, 20.0, 5.0]));
        final data = _data0(chart)..add(8.0);
        notifyArrayListeners(data, 'push', [8.0]);
        chart.update();
        _expectLinePoints(chart, 4);
      });

      testWidgets('after a splice and chart.update()', (tester) async {
        final chart = acquireChart(_radar(const [10.0, 20.0, 5.0, 8.0]));
        final data = _data0(chart);
        jsSplice(data, 1, 2, [7.0]);
        notifyArrayListeners(data, 'splice', [1.0, 2.0, 7.0]);
        chart.update();
        _expectLinePoints(chart, 3);
        final meta = chart.getDatasetMeta(0);
        expect(meta.parsed, [
          {'r': 10.0},
          {'r': 7.0},
          {'r': 8.0},
        ]);
      });
    });

    testWidgets('getLabelAndValue gives the raw label', (tester) async {
      final lines = <Object?>['line 1', 'line 2'];
      final chart = acquireChart(
        _radar(
          const [1.0, 2.0, 3.0, 4.0, 5.0, 6.0],
          labels: [lines, 5.0, 0.0, null, 'e'],
        ),
      );
      final controller = chart.getDatasetMeta(0).controller!;
      final labels = [
        for (var i = 0; i < 6; i++)
          controller.getLabelAndValue(i.toDouble()).label,
      ];
      expect(identical(labels[0], lines), isTrue);
      expect(labels[1], 5.0);
      expect(labels[2], 0.0);
      expect(labels[3], isNull);
      expect(labels[4], 'e');
      expect(identical(labels[5], undefined), isTrue);
    });

    testWidgets('an r scale that is not radial and no data: update does not '
        'throw', (tester) async {
      final chart = acquireChart(
        _radar(
          const [],
          labels: const [],
          options: <String, Object?>{
            'scales': <String, Object?>{
              'r': <String, Object?>{'type': 'linear'},
            },
          },
        ),
      );
      expect(chart.update, returnsNormally);
    });

    testWidgets('an r scale that is not radial with data: update throws a '
        'TypeError', (tester) async {
      expect(
        () => acquireChart(
          _radar(
            const [1.0, 2.0],
            labels: const ['a', 'b'],
            options: <String, Object?>{
              'scales': <String, Object?>{
                'r': <String, Object?>{'type': 'linear'},
              },
            },
          ),
        ),
        throwsA(isA<TypeError>()),
      );
    });
  });

  // The reset of a new point on a new radial scale (Chart.js ADR 0033).
  // `_insertElements` resets the new
  // point before the first layout of the new scale. Upstream then reads
  // `xCenter` and `yCenter` as `undefined` (scale.radialLinear.js:416-418).
  // An x64 Node.js probe on the build at the pin gives:
  // before the layout, `x` and `y` are `undefined` and `skip` is true; after
  // the update, the animation `x` goes from 41 to 41 and the animation `y`
  // from 272 to 272 (the phase 8 probe pins_plugins_probe.mjs with the seven
  // plugins registered, `pin1 radar`: the legend moves the center down by
  // 16 and the scale r2 to the right by 16).
  group('the reset on a new radial scale', () {
    testWidgets('writes x and y undefined, and the animations start at the '
        'target', (tester) async {
      Map<String, Object?>? beforeLayout;
      final config =
          _radar(
              const [1.0, 2.0, 3.0],
              labels: const ['a', 'b', 'c', 'd'],
              options: <String, Object?>{'animation': <String, Object?>{}},
            )
            ..['plugins'] = <Object?>[
              <String, Object?>{
                'id': 'probeLayout',
                'beforeLayout': (Object? chart, Object? args, Object? options) {
                  final data = (chart! as Chart).getDatasetMeta(0).data;
                  if (data.length > 3 && beforeLayout == null) {
                    final point = data[3] as types.ElementPropertyRead;
                    beforeLayout = {
                      'x': point['x'],
                      'y': point['y'],
                      'skip': point['skip'],
                    };
                  }
                },
              },
            ];
      final chart = acquireChart(config);
      final meta = chart.getDatasetMeta(0);
      final dataset =
          jsGetIndex(jsGet(chart.data, 'datasets'), 0)! as AnyObject;
      dataset['rAxisID'] = 'r2';
      _data0(chart).add(4.0);
      chart.update();

      expect(meta.rScale!.id, 'r2');
      expect(identical(beforeLayout!['x'], undefined), isTrue);
      expect(identical(beforeLayout!['y'], undefined), isTrue);
      expect(beforeLayout!['skip'], isTrue);
      final point = meta.data[3] as Element;
      final x = point.$animations!['x']! as animation.Animation;
      final y = point.$animations!['y']! as animation.Animation;
      expect([x.from, x.to], [41.0, 41.0]);
      expect([y.from, y.to], [272.0, 272.0]);
      // At 500 ms the new point is at its target, drawn and hit
      // (pins_plugins_probe.out, `pin1 radar`). A NaN start gives x NaN and
      // no hit.
      await tester.pump(const Duration(milliseconds: 500));
      expect([point.x, point.y], [41.0, 272.0]);
      expect(_hitsAt(chart, 41, 272, 'point'), [
        [0, 3],
      ]);
      expect(_hitsAt(chart, 41, 272, 'nearest'), [
        [0, 3],
      ]);
      await tester.pump(const Duration(milliseconds: 600));
      expect([point.x, point.y], [41.0, 272.0]);
    });

    // A reset at a NaN center writes NaN, not undefined. The next animation
    // then starts at NaN, and the point is not drawn and not hit until it
    // ends (Chart.js ADR 0033; the phase 8 probe pins_plugins_probe.mjs with
    // the seven plugins registered, `E2 radar`).
    testWidgets('a reset at a NaN center keeps NaN, and the next animation '
        'starts at NaN', (tester) async {
      final chart = acquireChart(
        _radar(
          const [65.0, 59.0, 90.0, 81.0, 56.0],
          labels: const ['a', 'b', 'c', 'd', 'e'],
          options: <String, Object?>{'animation': <String, Object?>{}},
        ),
      );
      await tester.pump(const Duration(milliseconds: 5000));
      final meta = chart.getDatasetMeta(0);
      final point = meta.data[1] as Element;
      final dataset =
          jsGetIndex(jsGet(chart.data, 'datasets'), 0)! as AnyObject;
      (jsGet(chart.options, 'scales')! as AnyObject)['r2'] = <String, Object?>{
        'type': 'radialLinear',
        'position': 'left',
      };
      dataset['rAxisID'] = 'r2';
      chart.update();
      await tester.pump(const Duration(milliseconds: 5000));
      expect((meta.rScale! as types.RadialLinearScale).xCenter, isNaN);

      chart.reset();
      final read = point as types.ElementPropertyRead;
      expect(read['x'], isNaN);
      expect(read['y'], isNaN);
      expect(read['skip'], isTrue);

      dataset['rAxisID'] = 'r';
      chart.update();
      expect((meta.rScale! as types.RadialLinearScale).xCenter, 376.0);
      final x = point.$animations!['x']! as animation.Animation;
      final y = point.$animations!['y']! as animation.Animation;
      expect(x.from, isNaN);
      expect(x.to, closeTo(389.4495078835456, 1e-9));
      expect(y.from, isNaN);
      expect(y.to, closeTo(267.62998998399627, 1e-9));
      const qx = 389.4495078835456;
      const qy = 267.62998998399627;
      await tester.pump(const Duration(milliseconds: 1));
      expect(point.x, isNaN);
      expect(_hitsAt(chart, qx, qy, 'point'), isEmpty);
      await tester.pump(const Duration(milliseconds: 499));
      expect(point.x, isNaN);
      expect(_hitsAt(chart, qx, qy, 'point'), isEmpty);
      await tester.pump(const Duration(milliseconds: 600));
      expect(point.x, closeTo(389.4495078835456, 1e-9));
      expect(_hitsAt(chart, qx, qy, 'point'), [
        [0, 1],
      ]);
    });

    // A point with r null has x and y NaN. When it gets a value, its
    // animation starts at NaN, as upstream (the phase 8 probe
    // pins_plugins_probe.mjs with the seven plugins registered, `pin3 radar`;
    // Chart.js ADR 0033). A NaN that stands for undefined would start it at
    // the target.
    testWidgets('a point with a null value animates from NaN when it gets a '
        'value', (tester) async {
      final chart = acquireChart(
        _radar(
          const <Object?>[1.0, null, 3.0, 2.0],
          labels: const ['a', 'b', 'c', 'd'],
          options: <String, Object?>{'animation': <String, Object?>{}},
        ),
      );
      await tester.pump(const Duration(milliseconds: 5000));
      final point = chart.getDatasetMeta(0).data[1] as Element;
      final read = point as types.ElementPropertyRead;
      expect(read['x'], isNaN);
      expect(read['y'], isNaN);
      expect(read['skip'], isTrue);

      _data0(chart)[1] = 2.0;
      chart.update();
      expect(read['skip'], isFalse);
      final x = point.$animations!['x']! as animation.Animation;
      final y = point.$animations!['y']! as animation.Animation;
      expect(x.from, isNaN);
      expect(x.to, 363.5);
      expect(y.from, isNaN);
      expect(y.to, 272.0);
      await tester.pump(const Duration(milliseconds: 1));
      expect(point.x, isNaN);
      expect(_hitsAt(chart, 363.5, 272, 'point'), isEmpty);
      await tester.pump(const Duration(milliseconds: 499));
      expect(point.x, isNaN);
      expect(_hitsAt(chart, 363.5, 272, 'point'), isEmpty);
      await tester.pump(const Duration(milliseconds: 600));
      expect([point.x, point.y], [363.5, 272.0]);
      expect(_hitsAt(chart, 363.5, 272, 'point'), [
        [0, 1],
      ]);
    });
  });
}
