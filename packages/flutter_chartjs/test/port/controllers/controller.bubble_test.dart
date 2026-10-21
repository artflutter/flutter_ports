// Original code, not ported from Chart.js: bubble controller reference tests.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs/src/core/core.config.dart' show themeConfigKey;
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/theme/compile.dart';
import 'package:flutter_chartjs/src/theme/presets.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart';
import 'controller_bubble_reference.dart';
import 'controller_chart_harness.dart';

// The port-only reference tests of
// lib/src/controllers/controller.bubble.dart (Chart.js ADR 0030). The spec
// port is test/specs/controller.bubble_test.dart.
//
// The reference group compares real bubble charts with the charts of
// tool/reference/controller_bubble_reference.mjs: a build of the pinned
// Chart.js in Node.js v24.12.0 on x64 (Chart.js ADR 0032), with a mock
// context that measures text in Liberation Sans 2.1.5. Each chart comes from
// acquireChart in a testWidgets case (Chart.js ADR 0022). The case runs its
// steps and compares the observations, the hit queries and the draw calls
// with the element draws (controller_chart_harness.dart).
//
// The 7 cases of Chart.js ADR 0030, section 7 run two times: unthemed, and
// with the light preset (theming.md section 8 test 3). The cases whose names
// start with `parsed:` (Chart.js ADR 0027, section 9) or `interfaces:`
// (Chart.js ADR 0028, section 8) run unthemed only. The groups `parsed
// data` and `interfaces` hold the pin tests that need no generated value.
//
// flutter_test_config.dart registers the bubble controller with the
// built-in components before main() (Chart.js ADR 0030, section 3 item 4).

/// The named functions of the configs of the generator, with the same
/// bodies.
final Map<String, Object?> _functions = {
  'radiusOfIndex': _radiusOfIndex,
  'rawRadius': _rawRadius,
};

/// The function `radiusOfIndex` of the generator: `(ctx) => 2 +
/// ctx.dataIndex * 3`.
Object? _radiusOfIndex(Object? ctx) =>
    2 + jsToNumber(jsGet(ctx, 'dataIndex')) * 3;

/// The function `rawRadius` of the generator: `(ctx) => ctx.raw`.
Object? _rawRadius(Object? ctx) => jsGet(ctx, 'raw');

/// The config of a bubble chart with one dataset with [data] and the keys of
/// [extra] (`one` of the generator).
AnyObject _one(AnyObject extra, List<Object?> data) => <String, Object?>{
  'type': 'bubble',
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[...data],
        ...extra,
      },
    ],
  },
};

/// The labels of the pin cases of the interfaces spec, section 7.3, with
/// one more data item than labels.
AnyObject _labelsConfig(List<Object?> labels) => <String, Object?>{
  'type': 'bubble',
  'data': <String, Object?>{
    'labels': labels,
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[
          for (var v = 1.0; v <= 6; v++)
            <String, Object?>{'x': v, 'y': 7 - v, 'r': v},
        ],
      },
    ],
  },
};

void main() {
  testReferenceOrigin(
    node: controllerBubbleReferenceNode,
    arch: controllerBubbleReferenceArch,
    dist: controllerBubbleReferenceDist,
    commit: controllerBubbleReferenceCommit,
  );
  testReferenceWidths(controllerBubbleReferenceWidths);

  test('the reference has the 7 cases of Chart.js ADR 0030 first', () {
    final names = [for (final c in controllerBubbleReference) c.name];
    bool prefixed(String n) =>
        n.startsWith('parsed:') || n.startsWith('interfaces:');
    expect(names.first, 'default');
    expect(names.length, greaterThanOrEqualTo(7));
    expect(names.take(7).where(prefixed), isEmpty);
    expect(names.skip(7).where((n) => !prefixed(n)), isEmpty);
  });

  testControllerChartCases(controllerBubbleReference, functions: _functions);

  group('theming.md §8 test 3: the light preset', () {
    testControllerChartCases(
      controllerBubbleReference,
      functions: _functions,
      theme: compileChartTheme(ChartThemes.light),
    );

    testWidgets('the light preset leaves no stale scale key', (tester) async {
      final snapshot =
          jsonDecode(
                File(
                  'test/port/theme/light_snapshot.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final config =
          copyReference(controllerBubbleReference.first.config)! as AnyObject;
      config[themeConfigKey] = compileChartTheme(ChartThemes.light);
      expectNoStaleScaleKeys(acquireChart(config), snapshot);
    });
  });

  // The pin tests of the parsed-data spec, section 7.3, that need no
  // generated value. The generated cases `parsed: ...` give the upstream
  // values of the same configs.
  group('parsed data', () {
    testWidgets('parsing false and [x, y, r] arrays give x and y NaN, skip '
        'true and radius 3', (tester) async {
      final chart = acquireChart(
        _one(
          <String, Object?>{'parsing': false},
          <Object?>[
            <Object?>[1.0, 2.0, 5.0],
            <Object?>[3.0, 4.0, 6.0],
          ],
        ),
      );
      for (final point in chart.getDatasetMeta(0).data) {
        final read = point as types.ElementPropertyRead;
        expect(read['x'], isNaN);
        expect(read['y'], isNaN);
        expect(read['skip'], isTrue);
        expect(jsGet(point.options, 'radius'), 3);
      }
    });

    testWidgets('parsing false and a null item throw a TypeError', (
      tester,
    ) async {
      expect(
        () => acquireChart(
          _one(
            <String, Object?>{'parsing': false},
            <Object?>[
              <String, Object?>{'x': 1.0, 'y': 2.0, 'r': 3.0},
              null,
            ],
          ),
        ),
        throwsA(isA<TypeError>()),
      );
    });

    testWidgets("r '7' of an array gives the radius '07' (the + of strings)", (
      tester,
    ) async {
      final chart = acquireChart(
        _one(<String, Object?>{}, <Object?>[
          <Object?>[1.0, 2.0, '7'],
        ]),
      );
      final point = chart.getDatasetMeta(0).data[0];
      expect(jsGet(point.options, 'radius'), '07');
    });
  });

  // The pin tests of the interfaces spec, section 7.3, that need no
  // generated value: the label is `labels[index] || ''`, any value.
  group('interfaces', () {
    testWidgets('getLabelAndValue gives the label value, or an empty string '
        'for a falsy label', (tester) async {
      for (final (labels, expected) in <(List<Object?>, List<Object?>)>[
        (
          <Object?>[
            <Object?>['line 1', 'line 2'],
            5.0,
            0.0,
            'd',
            undefined,
          ],
          <Object?>[5.0, '', 'd', '', ''],
        ),
        (
          <Object?>[
            <Object?>['line 1', 'line 2'],
            7.0,
            '',
            null,
            'e',
          ],
          <Object?>[7.0, '', '', 'e', ''],
        ),
      ]) {
        final chart = acquireChart(_labelsConfig(labels));
        final chartLabels = jsGet(chart.data, 'labels')! as List<Object?>;
        final controller = chart.getDatasetMeta(0).controller!;
        final first = controller.getLabelAndValue(0).label;
        expect(first, same(chartLabels[0]));
        expect(first, isA<List<Object?>>());
        expect([
          for (var i = 1; i < 6; i++)
            controller.getLabelAndValue(i.toDouble()).label,
        ], expected);
      }
    });
  });
}
