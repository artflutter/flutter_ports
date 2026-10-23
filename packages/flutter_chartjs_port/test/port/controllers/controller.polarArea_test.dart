// Original code, not ported from Chart.js: polar area reference tests.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.polarArea.dart';
import 'package:flutter_chartjs_port/src/core/core.animation.dart' as animation;
import 'package:flutter_chartjs_port/src/core/core.config.dart'
    show themeConfigKey;
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show controllerArgs;
import 'package:flutter_chartjs_port/src/core/core.defaults.dart'
    show overrides;
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart'
    show notifyArrayListeners;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart'
    show jsCall, jsIsFunction;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.legend.dart'
    show Legend;
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/theme/presets.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart';
import 'controller_chart_harness.dart';
import 'controller_polar_area_reference.dart';

// The port-only reference tests of
// lib/src/controllers/controller.polarArea.dart (Chart.js ADR 0030). The
// spec port is test/specs/controller.polarArea_test.dart.
//
// The reference group compares real polar area charts with the charts of
// tool/reference/controller_polar_area_reference.mjs: a build of the pinned
// Chart.js in Node.js v24.12.0 on x64 (Chart.js ADR 0032), with a mock
// context that measures text in Liberation Sans 2.1.5. Each chart comes from
// acquireChart in a testWidgets case (Chart.js ADR 0022). The case runs its
// steps and compares the observations, the hit queries and the draw calls
// with the element draws (controller_chart_harness.dart).
//
// The 9 cases of Chart.js ADR 0030, section 7 run two times: unthemed, and with
// the light preset (theming.md section 8 test 3). The cases whose names start
// with `parsed:` (Chart.js ADR 0036, section 9) or `interfaces:` (Chart.js ADR
// 0028, section 8) run unthemed only. The cases `interfaces: sharing, ...` run
// in a group that registers the test subclass with option sharing before each
// case and unregisters it after the case (Chart.js ADR 0030, section 3 item 4).
// The cases whose names start with `legend:` (Chart.js ADR 0041, section 5) run
// the real legend with the legend functions of the overrides: the items, the
// hit boxes, a click on the item 1, a chart without labels, and `legend: off`
// (the override `generateLabels` without a legend). They also run unthemed
// only. The groups `parsed data` and `interfaces` hold the pin tests that need
// no generated value.
//
// flutter_test_config.dart registers the polar area controller with the built-
// in components before main() (Chart.js ADR 0030, section 3 item 4), and the
// seven plugins with `defaults.plugins.colors.enabled = false` (Chart.js ADR
// 0041, section 1). The generator registers the same components
// (registerBuiltins).

/// The named functions of the generator (`'fn:<name>'`), with the same
/// bodies.
final Map<String, Object?> _functions = {
  'angleByIndex': (Object? ctx) =>
      jsToNumber(jsGet(ctx, 'dataIndex')) * 30 + 30,
  'zero': () => 0.0,
};

/// The probes of the key `extra` of the generator, with the same bodies.
final Map<String, Object? Function(Chart chart)> _extras = {
  'polarState': _polarState,
  'realLegend': _realLegend,
  'noLegend': _noLegend,
};

/// `chart.data.datasets.length`.
int _datasetCount(Chart chart) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>).length;

/// The probe `polarState` of the generator: for each dataset,
/// countVisibleElements(), the range of getMinMax(), innerRadius and
/// outerRadius, and whether the options of each arc are frozen.
Object? _polarState(Chart chart) => [
  for (var i = 0; i < _datasetCount(chart); i++)
    _state(
      chart.getDatasetMeta(i.toDouble()).controller! as PolarAreaController,
    ),
];

/// The values of the probe `polarState` for the controller [c].
Map<String, Object?> _state(PolarAreaController c) {
  // `c.getMinMax()`: the polar area method reads no argument.
  final (:min, :max) = c.getMinMax(c.cachedMeta.rScale!);
  return <String, Object?>{
    'count': c.countVisibleElements(),
    'minMax': [jsToNumber(min), jsToNumber(max)],
    'radii': [c.innerRadius ?? undefined, c.outerRadius ?? undefined],
    'frozen': [
      for (final arc in c.cachedMeta.data) jsObjectIsFrozen(arc.options),
    ],
  };
}

/// `C.Chart.overrides.polarArea.plugins.legend`.
Object? _legendFunctions() =>
    jsGet(jsGet(jsGet(overrides, 'polarArea'), 'plugins'), 'legend');

/// The probe `realLegend` of the generator: the items and the hit boxes of
/// the real legend. It reads `legendItems` through `types.LegendElement`
/// (Chart.js ADR 0028 Open 2), and `legendHitBoxes` through a cast to
/// [Legend]: the member is not in index.d.ts (Chart.js ADR 0038, section 6;
/// Chart.js ADR 0041, section 5). `keys` is the key list of each item in
/// order (`Object.keys`): the harness compares only the expected keys of a
/// Map.
Object? _realLegend(Chart chart) {
  final legend = chart.legend!;
  return <String, Object?>{
    'items': legend.legendItems,
    'keys': [
      for (final item in legend.legendItems!) jsObjectKeys(item! as AnyObject),
    ],
    'hitBoxes': (legend as Legend).legendHitBoxes,
  };
}

/// The probe `noLegend` of the generator: the override `generateLabels` on
/// a chart with the legend plugin off (no `chart.legend`), or the name of
/// its error.
Object? _noLegend(Chart chart) {
  final generateLabels = jsGet(
    jsGet(_legendFunctions(), 'labels'),
    'generateLabels',
  );
  try {
    return jsCall(generateLabels, [chart]);
    // The JS `catch (e)` of the probe: a JS TypeError is a Dart TypeError.
    // ignore: avoid_catching_errors
  } on TypeError {
    return 'TypeError';
  }
}

/// The test subclass of Chart.js ADR 0028, section 5: the polar area
/// controller with `enableOptionSharing = true` (`PolarAreaSharing` of the
/// generator).
final class _SharingController extends PolarAreaController {
  _SharingController(super.chart, super.datasetIndex, [super.newTarget]);

  @override
  void initialize() {
    enableOptionSharing = true;
    super.initialize();
  }
}

/// `class PolarAreaSharing extends PolarAreaController { static id =
/// 'polarAreaSharing'; }` as a value. `defaults` and `overrides` come from
/// the superclass chain.
final JsClass _sharingClass = JsClass(
  'PolarAreaSharing',
  superclass: PolarAreaController.jsClass,
  statics: {'id': 'polarAreaSharing'},
  construct: (newTarget, args) {
    final (:chart, :datasetIndex) = controllerArgs(args);
    return _SharingController(chart, datasetIndex, newTarget);
  },
);

/// Whether the case [c] uses the test subclass.
bool _isSharing(ScaleChartCase c) => c.name.startsWith('interfaces: sharing');

/// The config of a polar area chart with the labels [labels] and one
/// dataset with [data].
AnyObject _one(List<Object?> labels, List<Object?> data) => <String, Object?>{
  'type': 'polarArea',
  'data': <String, Object?>{
    'labels': labels,
    'datasets': <Object?>[
      <String, Object?>{'data': data},
    ],
  },
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

void main() {
  testReferenceOrigin(
    node: controllerPolarAreaReferenceNode,
    arch: controllerPolarAreaReferenceArch,
    dist: controllerPolarAreaReferenceDist,
    commit: controllerPolarAreaReferenceCommit,
  );
  testReferenceWidths(controllerPolarAreaReferenceWidths);

  test('the reference has the 9 cases of Chart.js ADR 0030 first', () {
    final names = [for (final c in controllerPolarAreaReference) c.name];
    bool prefixed(String n) =>
        n.startsWith('parsed:') ||
        n.startsWith('interfaces:') ||
        n.startsWith('legend:');
    expect(names.first, 'default');
    expect(names.length, greaterThan(9));
    expect(names.take(9).where(prefixed), isEmpty);
    expect(names.skip(9).where((n) => !prefixed(n)), isEmpty);
  });

  testControllerChartCases(
    [
      for (final c in controllerPolarAreaReference)
        if (!_isSharing(c)) c,
    ],
    functions: _functions,
    extras: _extras,
  );

  group('the option-sharing subclass', () {
    setUp(() => Chart.register([_sharingClass]));
    tearDown(() => Chart.unregister([_sharingClass]));

    test('the reference has the 11 rows of the ADR 0028 table', () {
      expect(controllerPolarAreaReference.where(_isSharing), hasLength(11));
    });

    testControllerChartCases(
      controllerPolarAreaReference.where(_isSharing).toList(),
      functions: _functions,
      extras: _extras,
    );
  });

  group('theming.md §8 test 3: the light preset', () {
    // The `legend:` cases run unthemed only, as the `interfaces:` cases:
    // their probe compares the item colors as strings, and
    // test/port/plugins/plugin.legend_test.dart runs the legend with the
    // light preset.
    testControllerChartCases(
      [
        for (final c in controllerPolarAreaReference)
          if (!c.name.startsWith('legend:')) c,
      ],
      functions: _functions,
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
          copyReference(controllerPolarAreaReference.first.config)!
              as AnyObject;
      config[themeConfigKey] = compileChartTheme(ChartThemes.light);
      expectNoStaleScaleKeys(acquireChart(config), snapshot);
    });
  });

  // The pin tests of the parsed-data spec, section 7.3, that need no
  // generated value. The generated cases `parsed: ...` give the upstream
  // values of the same configs.
  group('parsed data', () {
    testWidgets("string r values keep the range '10'..'9' of upstream", (
      tester,
    ) async {
      ({double min, double max}) range(List<Object?> data) {
        final chart = acquireChart(<String, Object?>{
          'type': 'polarArea',
          'data': <String, Object?>{
            'labels': <Object?>['a', 'b', 'c'],
            'datasets': <Object?>[
              <String, Object?>{'data': data, 'parsing': false},
            ],
          },
        });
        final meta = chart.getDatasetMeta(0);
        return meta.controller!.getMinMax(meta.rScale!);
      }

      expect(
        range(<Object?>[
          <String, Object?>{'r': '10'},
          <String, Object?>{'r': '9'},
          <String, Object?>{'r': '30'},
        ]),
        (min: 10.0, max: 9.0),
      );
      expect(
        range(<Object?>[
          <String, Object?>{'r': 10.0},
          <String, Object?>{'r': 9.0},
          <String, Object?>{'r': 30.0},
        ]),
        (min: 9.0, max: 30.0),
      );
    });
  });

  // The pin tests of the interfaces spec, section 7.3, that need no
  // generated value.
  group('interfaces', () {
    testWidgets('getLabelAndValue keeps the label values', (tester) async {
      final lines = <Object?>['line 1', 'line 2'];
      final chart = acquireChart(
        _one(
          <Object?>[lines, 5.0, 0.0, 'd', undefined],
          <Object?>[1.0, 2.0, 3.0, 4.0, 5.0, 6.0],
        ),
      );
      final controller = chart.getDatasetMeta(0).controller!;
      final labels = [
        for (var i = 0; i < 6; i++)
          controller.getLabelAndValue(i.toDouble()).label,
      ];
      expect(labels[0], same(lines));
      expect(labels.skip(1), [5.0, '', 'd', '', '']);
      expect(controller.getLabelAndValue(1).value, '2');
    });

    test('overrides holds the same legend functions in each read', () {
      Object? generateLabels(Object? fns) =>
          jsGet(jsGet(fns, 'labels'), 'generateLabels');
      final own = jsGet(
        jsGet(PolarAreaController.overrides, 'plugins'),
        'legend',
      );
      final first = _legendFunctions();
      final second = _legendFunctions();
      expect(jsIsFunction(generateLabels(first)), isTrue);
      expect(generateLabels(first), same(generateLabels(second)));
      expect(generateLabels(first), same(generateLabels(own)));
      expect(jsIsFunction(jsGet(first, 'onClick')), isTrue);
      expect(jsGet(first, 'onClick'), same(jsGet(second, 'onClick')));
      expect(jsGet(first, 'onClick'), same(jsGet(own, 'onClick')));
    });

    testWidgets('onClick toggles the index and updates the chart once', (
      tester,
    ) async {
      var updates = 0;
      final config = _one(
        <Object?>['a', 'b', 'c'],
        <Object?>[1.0, 2.0, 3.0],
      );
      config['plugins'] = <Object?>[
        <String, Object?>{
          'id': 'countUpdates',
          'afterUpdate': (Object? chart, Object? args, Object? options) {
            updates++;
          },
        },
      ];
      final chart = acquireChart(config);
      final legend = chart.legend!;
      updates = 0;
      jsCall(jsGet(_legendFunctions(), 'onClick'), [
        <String, Object?>{},
        <String, Object?>{'index': 1.0},
        legend,
      ]);
      expect(updates, 1);
      expect(chart.getDataVisibility(1), isFalse);
      expect(chart.getDataVisibility(0), isTrue);
      expect(chart.getDataVisibility(2), isTrue);
      expect(
        (chart.getDatasetMeta(0).data[1] as Element)['outerRadius'],
        0,
      );
    });

    // The key `ToString(index)` of core.controller.js:882 (the fix F1 of the
    // wave 2 review). The visibility of the data indices 0, 1 and 2 after one
    // onClick, from the x64 Node.js probe `onclick_keys.mjs` of the unit.
    for (final (name, index, visible) in <(String, Object?, String)>[
      ('null', null, '111'),
      ('undefined', undefined, '111'),
      ('true', true, '111'),
      ('false', false, '111'),
      ("''", '', '111'),
      ("'01'", '01', '111'),
      ("'1'", '1', '101'),
      ("'1.0'", '1.0', '111'),
      ("'2'", '2', '110'),
      ('NaN', double.nan, '111'),
      ('-0', -0.0, '011'),
      ("'-0'", '-0', '111'),
      ('[2]', <Object?>[2.0], '110'),
      ('{}', <String, Object?>{}, '111'),
      ('1', 1.0, '101'),
      ('1.5', 1.5, '111'),
    ]) {
      testWidgets('onClick with the index $name toggles the upstream key', (
        tester,
      ) async {
        final chart = acquireChart(
          _one(<Object?>['a', 'b', 'c'], <Object?>[1.0, 2.0, 3.0]),
        );
        jsCall(jsGet(_legendFunctions(), 'onClick'), [
          <String, Object?>{},
          <String, Object?>{'index': index},
          chart.legend,
        ]);
        expect(
          [
            for (var i = 0; i < 3; i++)
              if (chart.getDataVisibility(i.toDouble())) '1' else '0',
          ].join(),
          visible,
        );
      });
    }

    // The key after a data insert (Chart.js ADR 0028 §6).
    // `_updateHiddenIndices` moves the key '01' to '2'
    // (core.controller.js:72-84). A probe of the build at the pin in x64
    // Node.js v24.12.0 with the seven plugins registered (phase 8
    // `pins_plugins_probe.mjs`, `onclick01 polarArea`) gives the visibility
    // 1101 and the outer radii 232, 25.777778, 0 and 77.333333 (rounded).
    testWidgets("onClick with the index '01', then unshift, hides the data "
        'index 2', (tester) async {
      final chart = acquireChart(
        _one(<Object?>['a', 'b', 'c'], <Object?>[1.0, 2.0, 3.0]),
      );
      jsCall(jsGet(_legendFunctions(), 'onClick'), [
        <String, Object?>{},
        <String, Object?>{'index': '01'},
        chart.legend,
      ]);
      final data =
          jsGet(jsGetIndex(jsGet(chart.data, 'datasets'), 0), 'data')!
                as List<Object?>
            ..insert(0, 9.0);
      notifyArrayListeners(data, 'unshift', const [9.0]);
      chart.update();
      expect(
        [
          for (var i = 0; i < 4; i++)
            if (chart.getDataVisibility(i.toDouble())) '1' else '0',
        ].join(),
        '1101',
      );
      expect(
        [
          for (final arc in chart.getDatasetMeta(0).data)
            (arc as Element)['outerRadius'],
        ],
        [
          closeTo(232, 1e-6),
          closeTo(25.777778, 1e-6),
          0,
          closeTo(77.333333, 1e-6),
        ],
      );
    });
  });

  // The reset of a new arc on a new radial scale (Chart.js ADR 0033).
  // `_insertElements` resets the new arc before the first layout of the new
  // scale. Upstream then reads `xCenter` and `yCenter` as `undefined`
  // (scale.radialLinear.js:416-418). An x64 Node.js probe on the build at
  // the pin gives: before the layout, `x` and `y` are
  // `undefined`; after the update, the animations `x` and `y` go from 256 to
  // 256.
  group('the reset on a new radial scale', () {
    testWidgets('writes x and y undefined, and the animations start at the '
        'target', (tester) async {
      Map<String, Object?>? beforeLayout;
      final config = _one(
        <Object?>['a', 'b', 'c', 'd'],
        <Object?>[1.0, 2.0, 3.0],
      );
      config['options'] = <String, Object?>{
        'animation': <String, Object?>{},
      };
      config['plugins'] = <Object?>[
        <String, Object?>{
          'id': 'probeLayout',
          'beforeLayout': (Object? chart, Object? args, Object? options) {
            final data = (chart! as Chart).getDatasetMeta(0).data;
            if (data.length > 3 && beforeLayout == null) {
              final arc = data[3] as types.ElementPropertyRead;
              beforeLayout = {'x': arc['x'], 'y': arc['y']};
            }
          },
        },
      ];
      final chart = acquireChart(config);
      final meta = chart.getDatasetMeta(0);
      final dataset =
          jsGetIndex(jsGet(chart.data, 'datasets'), 0)! as AnyObject;
      dataset['rAxisID'] = 'r2';
      (dataset['data']! as List<Object?>).add(4.0);
      chart.update();

      expect(meta.rScale!.id, 'r2');
      expect(identical(beforeLayout!['x'], undefined), isTrue);
      expect(identical(beforeLayout!['y'], undefined), isTrue);
      final arc = meta.data[3] as Element;
      final x = arc.$animations!['x']! as animation.Animation;
      final y = arc.$animations!['y']! as animation.Animation;
      expect([x.from, x.to], [256.0, 256.0]);
      expect([y.from, y.to], [272.0, 272.0]);
      // At 500 ms the new arc is drawn and hit at the middle of its final
      // area (the phase 8 probe pins_plugins_probe.mjs with the seven
      // plugins registered, `pin1 polarArea`: the legend moves the center
      // down by 16). A NaN start gives x NaN and no hit in each mode.
      await tester.pump(const Duration(milliseconds: 500));
      expect([arc.x, arc.y], [256.0, 272.0]);
      const qx = 173.97561338236045;
      const qy = 189.9756133823605;
      expect(_hitsAt(chart, qx, qy, 'point'), [
        [0, 3],
      ]);
      expect(_hitsAt(chart, qx, qy, 'nearest'), [
        [0, 3],
      ]);
      expect(_hitsAt(chart, qx, qy, 'nearest', {'axis': 'r'}), [
        [0, 3],
      ]);
      expect(_hitsAt(chart, qx, qy, 'index', {'axis': 'r'}), [
        [0, 3],
      ]);
      await tester.pump(const Duration(milliseconds: 600));
      expect([arc.x, arc.y], [256.0, 272.0]);
    });

    // A center that is NaN after a layout is not `undefined` (finding F1 of
    // the X-fix review). A new radial scale with `position: 'left'` gets
    // the center NaN in its layout. The animation of `x` then goes to NaN.
    // An `undefined` target would keep the old value (core.animation.js:31,
    // `resolve` skips `undefined`), and the arc would stay drawn. Thus
    // `xCenter` needs two values: Dart `null` and NaN. The x64 Node.js probe
    // of the X-fix fixer on the build at the pin
    // (`wave3/X-fix-fix/probe_f1c.mjs`, case `newAxisId`) gives the
    // animation of `x` from 256 to NaN. With the seven plugins registered,
    // the arc starts at (256, 272) (phase 8 `pins_plugins_probe.mjs`,
    // `F1 polarArea`).
    testWidgets('a NaN center after a layout animates x to NaN', (
      tester,
    ) async {
      final config = _one(
        <Object?>['January', 'February', 'March', 'April', 'May'],
        <Object?>[65.0, 59.0, 90.0, 81.0, 56.0],
      );
      config['options'] = <String, Object?>{
        'animation': <String, Object?>{},
      };
      final chart = acquireChart(config);
      await tester.pump(const Duration(milliseconds: 1100));
      final meta = chart.getDatasetMeta(0);
      final arc = meta.data[1] as Element;
      expect([arc.x, arc.y], [256.0, 272.0]);

      (chart.options['scales']! as AnyObject)['r2'] = <String, Object?>{
        'type': 'radialLinear',
        'position': 'left',
      };
      (jsGetIndex(jsGet(chart.data, 'datasets'), 0)! as AnyObject)['rAxisID'] =
          'r2';
      chart.update();

      expect(meta.rScale!.id, 'r2');
      final radial = meta.rScale! as types.RadialLinearScale;
      expect(radial.xCenter, isNaN);
      final x = arc.$animations!['x']! as animation.Animation;
      expect(x.from, 256.0);
      expect(x.to, isNaN);
    });

    // A reset at a NaN center writes NaN, not undefined. The next animation
    // then starts at NaN, and the arc is not drawn and not hit until it ends
    // (Chart.js ADR 0033; the phase 8 probe pins_plugins_probe.mjs with the
    // seven plugins registered, `E2 polarArea`).
    testWidgets('a reset at a NaN center keeps NaN, and the next animation '
        'starts at NaN', (tester) async {
      final config = _one(
        <Object?>['a', 'b', 'c', 'd', 'e'],
        <Object?>[65.0, 59.0, 90.0, 81.0, 56.0],
      );
      config['options'] = <String, Object?>{
        'animation': <String, Object?>{},
      };
      final chart = acquireChart(config);
      await tester.pump(const Duration(milliseconds: 5000));
      final meta = chart.getDatasetMeta(0);
      final arc = meta.data[1] as Element;
      final dataset =
          jsGetIndex(jsGet(chart.data, 'datasets'), 0)! as AnyObject;
      (jsGet(chart.options, 'scales')! as AnyObject)['r2'] = <String, Object?>{
        'type': 'radialLinear',
        'position': 'left',
      };
      dataset['rAxisID'] = 'r2';
      chart.update();
      await tester.pump(const Duration(milliseconds: 5000));

      chart.reset();
      expect((meta.rScale! as types.RadialLinearScale).xCenter, isNaN);
      final read = arc as types.ElementPropertyRead;
      expect(read['x'], isNaN);
      expect(read['y'], isNaN);

      dataset['rAxisID'] = 'r';
      chart.update();
      expect((meta.rScale! as types.RadialLinearScale).xCenter, 376.0);
      final x = arc.$animations!['x']! as animation.Animation;
      final y = arc.$animations!['y']! as animation.Animation;
      expect(x.from, isNaN);
      expect(x.to, 376.0);
      expect(y.from, isNaN);
      expect(y.to, 272.0);
      const qx = 411.91189405530497;
      const qy = 283.668481707598;
      await tester.pump(const Duration(milliseconds: 1));
      expect(arc.x, isNaN);
      expect(_hitsAt(chart, qx, qy, 'nearest'), isEmpty);
      await tester.pump(const Duration(milliseconds: 499));
      expect(arc.x, isNaN);
      expect(_hitsAt(chart, qx, qy, 'nearest'), isEmpty);
      await tester.pump(const Duration(milliseconds: 600));
      expect([arc.x, arc.y], [376.0, 272.0]);
      expect(_hitsAt(chart, qx, qy, 'nearest'), [
        [0, 1],
      ]);
    });
  });
}
