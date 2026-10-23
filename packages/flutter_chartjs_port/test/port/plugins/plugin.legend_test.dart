// Original code, not ported from Chart.js: legend plugin reference tests.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart' show createMockContext;
import 'package:flutter_chartjs_port/src/core/core.config.dart'
    show themeConfigKey;
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.registry.dart' show registry;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/color.dart';
import 'package:flutter_chartjs_port/src/platform/chart_host.dart'
    show dispatchCanvasEvent;
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.legend.dart';
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/theme/presets.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart' show TRBL;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../controllers/controller_chart_harness.dart'
    show expectNoStaleScaleKeys, plainValue;
import '../scales/scale_chart_harness.dart';
import 'plugin_chart_harness.dart';
import 'plugin_legend_reference.dart';

// The port-only reference tests of lib/src/plugins/plugin.legend.dart
// (Chart.js ADR 0041, section 3). The spec ports are
// test/specs/plugin.legend_test.dart and test/specs/global.defaults_test.dart.
//
// The reference group compares real charts with the charts of
// tool/reference/plugin_legend_reference.mjs: a build of the pinned
// Chart.js in Node.js v24.12.0 on x64 (Chart.js ADR 0032), with the seven
// plugins registered and `colors.enabled: false` in the defaults. Each case
// is a unit case: the other plugins are `false` (Chart.js ADR 0041, section
// 4). The observation has `boxes` and `plugins.legend` (the items, the hit
// boxes, the line widths, the column sizes, the callback log and the label
// options), and the draw calls.
//
// The cases run two times: unthemed, and with the light preset (theming.md
// section 8 test 3). In the themed run, the colors compare in their parsed
// form, and the options compare only the keys of upstream.
//
// The groups `class value`, `start state`, `stop`,
// `adapt-component-class-role`, `adapt-legend-dataset-index` and `input`
// hold the pin tests of Chart.js ADR 0038, section 11, and of Chart.js ADR
// 0037, section 14. The expected results come from a probe on the pinned
// build in Node.js v24.12.0 on x64 (controller_chart_common.mjs:
// loadChartJs, registerBuiltins, makeChart). The probe read
// `registry.getPlugin('legend')` and its `_element` (the class `Legend`),
// called the constructor with bad arguments, read the start values, called
// the hit test, `handleEvent`, `update`, `draw`, `stop` and `beforeUpdate`
// before a layout, and called the default `onClick` with raw dataset
// indexes. The groups `item width` and `box default color` and the index
// keys of `adapt-legend-dataset-index` hold the results of three more
// probes of the same form (review-empty-array-text, review-default-color
// and fix-dataset-index). Each test comment gives the names and the values
// of the probe output that it pins.

/// The callback log of each chart: `<callback> <event type> <item text>`
/// (`logs` of the generator).
final Expando<List<String>> _logs = Expando<List<String>>('legend log');

/// Adds the entry of the callback [name] to the log of the chart of
/// [legend] (`log` of the generator).
void _log(String name, Object? e, Object? item, types.LegendElement legend) {
  (_logs[legend.chart] ??= <String>[]).add(
    '$name ${(e! as types.ChartEvent).type} '
    '${jsToString(jsGet(item, 'text'))}',
  );
}

/// The named functions of the configs of the generator, with the same
/// bodies.
final Map<String, Object?> _functions = {
  // (e, item, legend) => log('onClick', e, item, legend)
  'logClick': (Object? e, Object? item, types.LegendElement legend) =>
      _log('onClick', e, item, legend),
  // (e, item, legend) => log('onHover', e, item, legend)
  'logHover': (Object? e, Object? item, types.LegendElement legend) =>
      _log('onHover', e, item, legend),
  // (e, item, legend) => log('onLeave', e, item, legend)
  'logLeave': (Object? e, Object? item, types.LegendElement legend) =>
      _log('onLeave', e, item, legend),
  // (item) => !String(item.text).endsWith('2')
  'legendFilter': (Object? item) =>
      !jsToString(jsGet(item, 'text')).endsWith('2'),
  // (a, b) => b.datasetIndex - a.datasetIndex
  'legendSort': (Object? a, Object? b) =>
      jsToNumber(jsGet(b, 'datasetIndex')) -
      jsToNumber(jsGet(a, 'datasetIndex')),
};

/// The plain copy [value] without the keys whose values are functions
/// (`withoutFunctions` of the generator).
Object? _withoutFunctions(Object? value) => switch (value) {
  final List<Object?> list => [
    for (final item in list) _withoutFunctions(item),
  ],
  final Map<String, Object?> map => <String, Object?>{
    for (final MapEntry(:key, :value) in map.entries)
      if (value != '<fn>') key: _withoutFunctions(value),
  },
  _ => value,
};

/// The observer `plugins.legend` of the generator (`observeLegend`): Dart
/// `null` without a legend, else the items, the hit boxes, the line widths,
/// the column sizes, the callback log and the plain label options without
/// the function values. It reads `legendItems` through
/// `types.LegendElement`, and the other members through a cast to [Legend]
/// (Chart.js ADR 0038, section 6).
Object? _observeLegend(Chart chart) {
  final legendElement = chart.legend;
  if (legendElement == null) return null;
  final box = legendElement as Legend;
  return <String, Object?>{
    'legendItems': legendElement.legendItems == null
        ? undefined
        : plainValue(legendElement.legendItems),
    'legendHitBoxes': plainValue(box.legendHitBoxes),
    'lineWidths': box.lineWidths == null
        ? undefined
        : plainValue(box.lineWidths),
    'columnSizes': box.columnSizes == null
        ? undefined
        : plainValue(box.columnSizes),
    'log': [...?_logs[chart]],
    'labels': _withoutFunctions(plainValue(jsGet(box.options, 'labels'))),
  };
}

/// [cases] with [map] applied to the observation of `initial` and of each
/// step.
List<ScaleChartCase> _mapObservations(
  List<ScaleChartCase> cases,
  AnyObject Function(AnyObject observation) map,
) => [
  for (final c in cases)
    (
      name: c.name,
      config: c.config,
      options: c.options,
      expected: <String, Object?>{
        for (final MapEntry(:key, :value) in c.expected.entries)
          key: switch (key) {
            'initial' => map(value! as AnyObject),
            'steps' => [
              for (final step in (value! as List<Object?>).cast<AnyObject>())
                <String, Object?>{
                  for (final MapEntry(:key, :value) in step.entries)
                    key: key == 'observations'
                        ? map(value! as AnyObject)
                        : value,
                },
            ],
            _ => value,
          },
      },
    ),
];

/// [observation] with `undefined` for each `xAxisID` and `yAxisID` of JS
/// `null` in `datasets`: the empty `linkScales` of the doughnut keeps the
/// JS `null`, and the Dart field `ChartMeta.xAxisID` has Dart `null` for
/// both (the form of `_undefinedAxisIds` of controller.doughnut_test.dart).
AnyObject _undefinedAxisIds(AnyObject observation) => <String, Object?>{
  ...observation,
  'datasets': [
    for (final dataset
        in (observation['datasets']! as List<Object?>).cast<AnyObject>())
      <String, Object?>{
        for (final MapEntry(:key, :value) in dataset.entries)
          key: (key == 'xAxisID' || key == 'yAxisID') && value == null
              ? undefined
              : value,
      },
  ],
};

/// [value] in its parsed form when it is a color: `Color(value).rgbString()`
/// (`_parseColor` of controller_chart_harness.dart).
Object? _parseColor(Object? value) => switch (value) {
  final String s => Color(s).rgbString() ?? s,
  _ => value,
};

/// The observation `plugins.legend` [legend] with the parsed form of the
/// item colors `fillStyle` and `strokeStyle`. The themed run compares the
/// colors in their parsed form (theming.md section 8 test 3), and the
/// harness parses only the keys `color` and `*Color`.
Object? _parseItemColors(Object? legend) => switch (legend) {
  final Map<String, Object?> map => <String, Object?>{
    ...map,
    'legendItems': switch (map['legendItems']) {
      final List<Object?> items => [
        for (final item in items.cast<AnyObject>())
          <String, Object?>{
            for (final MapEntry(:key, :value) in item.entries)
              key: key == 'fillStyle' || key == 'strokeStyle'
                  ? _parseColor(value)
                  : value,
          },
      ],
      final other => other,
    },
  },
  _ => legend,
};

/// The reference cases with the axis ids of [_undefinedAxisIds].
final List<ScaleChartCase> _reference = _mapObservations(
  pluginLegendReference,
  _undefinedAxisIds,
);

/// The reference cases of the themed run: [_reference] with the parsed item
/// colors of [_parseItemColors].
final List<ScaleChartCase> _themedReference = _mapObservations(
  _reference,
  (observation) => <String, Object?>{
    ...observation,
    'plugins.legend': _parseItemColors(observation['plugins.legend']),
  },
);

/// The keys of the default export of plugin.legend.js:592-720, in their
/// order (the probe output `keys`).
const List<String> _upstreamKeys = [
  'id',
  '_element',
  'start',
  'stop',
  'beforeUpdate',
  'afterUpdate',
  'afterEvent',
  'defaults',
  'descriptors',
];

/// The keys of the `defaults` of plugin.legend.js:636-712 (the probe output
/// `defaultsKeys`).
const List<String> _upstreamDefaultsKeys = [
  'display',
  'position',
  'align',
  'fullSize',
  'reverse',
  'weight',
  'onClick',
  'onHover',
  'onLeave',
  'labels',
  'title',
];

/// `new Legend(config)` through the class value.
Object? _construct(List<Object?> args) => jsConstruct(Legend.jsClass, args);

/// A line chart with two datasets and the legend options [legendOptions].
AnyObject _line(Object? legendOptions, {List<Object?>? plugins}) =>
    <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'labels': <Object?>['a', 'b'],
        'datasets': <Object?>[
          <String, Object?>{
            'label': 'one',
            'data': <Object?>[1, 2],
          },
          <String, Object?>{
            'label': 'two',
            'data': <Object?>[2, 1],
          },
        ],
      },
      'options': <String, Object?>{
        'plugins': <String, Object?>{'legend': legendOptions},
      },
      'plugins': ?plugins,
    };

void main() {
  testReferenceOrigin(
    node: pluginLegendReferenceNode,
    arch: pluginLegendReferenceArch,
    dist: pluginLegendReferenceDist,
    commit: pluginLegendReferenceCommit,
  );
  testReferenceWidths(pluginLegendReferenceWidths);

  test('the reference has the unit cases of Chart.js ADR 0041', () {
    expect(
      [for (final c in pluginLegendReference) c.name],
      [
        'position top (the default)',
        'position bottom',
        'position left',
        'position right',
        'position chartArea',
        'align start',
        'align end',
        'align start at the left',
        'align end at the right',
        'rtl',
        'rtl at the left',
        'reverse',
        'fullSize false',
        'maxWidth',
        'maxHeight',
        'usePointStyle',
        'pointStyleWidth',
        'boxWidth and boxHeight',
        'padding',
        'filter',
        'sort',
        'textAlign',
        'title with position start',
        'title with position end at the left',
        'rows that wrap',
        'columns that overflow',
        'a hidden dataset',
        'hoverLegend with onHover and onLeave',
        'clickLegend',
        'clickLegend with onClick',
        'display false',
        'useBorderRadius',
        'doughnut with multiline labels',
        'full: hoverLegend with the tooltip',
      ],
    );
  });

  testPluginChartCases(
    _reference,
    observers: {'legend': _observeLegend},
    functions: _functions,
  );

  group('theming.md §8 test 3: the light preset', () {
    testPluginChartCases(
      _themedReference,
      observers: {
        'legend': (chart) => _parseItemColors(_observeLegend(chart)),
      },
      functions: _functions,
      theme: compileChartTheme(ChartThemes.light),
    );

    testWidgets('the light preset leaves no stale scale key', (tester) async {
      final snapshot = jsonDecode(
        File('test/port/theme/light_snapshot.json').readAsStringSync(),
      ) as Map<String, Object?>;
      final config =
          copyReference(pluginLegendReference.first.config, _functions)!
              as AnyObject;
      config[themeConfigKey] = compileChartTheme(ChartThemes.light);
      expectNoStaleScaleKeys(acquireChart(config), snapshot);
    });
  });

  group('class value', () {
    test('the superclass is Element.jsClass', () {
      expect(Legend.jsClass.superclass, same(Element.jsClass));
    });

    test('the plugin entry _element is Legend.jsClass', () {
      expect(
        jsGet(registry.getPlugin('legend'), '_element'),
        same(Legend.jsClass),
      );
      expect(legend['_element'], same(Legend.jsClass));
    });

    test('new Legend(config) keeps the chart, the options and the ctx', () {
      final chart = _FakeChart();
      final options = <String, Object?>{'display': true};
      final constructed = _construct([
        <String, Object?>{'chart': chart, 'options': options},
      ]);
      expect(constructed, isA<Legend>());
      final value = constructed! as Legend;
      expect(value.chart, same(chart));
      expect(value.options, same(options));
      expect(value.ctx, isNull);
    });

    test('new Legend() and new Legend(undefined) throw a TypeError', () {
      // Upstream: the read config.chart of undefined and null (probe:
      // newNoArg, newUndefined, newNull).
      expect(() => _construct(const []), throwsA(isA<TypeError>()));
      expect(() => _construct([undefined]), throwsA(isA<TypeError>()));
      expect(() => _construct([null]), throwsA(isA<TypeError>()));
    });

    test('the keys of the plugin object are the upstream keys', () {
      expect(jsObjectKeys(legend), _upstreamKeys);
      expect(
        jsObjectKeys(legend['defaults']! as AnyObject),
        _upstreamDefaultsKeys,
      );
    });
  });

  group('start state', () {
    test('a new Legend has the start values of plugin.legend.js:49-79', () {
      // The probe: `start` gives undefined for each value, `startOther`
      // gives [false, 0, null, false].
      final box = Legend((chart: _FakeChart(), options: null, ctx: null));
      for (final value in [
        box.top,
        box.bottom,
        box.left,
        box.right,
        box.width,
        box.height,
        box.maxWidth,
        box.maxHeight,
      ]) {
        expect(value, isNaN);
      }
      expect(box.position, same(undefined));
      expect(box.weight, same(undefined));
      expect(box.fullSize, isFalse);
      expect(box.legendItems, isNull);
      expect(box.columnSizes, isNull);
      expect(box.lineWidths, isNull);
      expect(box.legendHitBoxes, isEmpty);
      expect(box.doughnutMode, isFalse);
      expect(box.layers, isNull);
      expect(box.axis, isNull);
    });

    test('a hit query before the first layout hits no item and does not '
        'throw', () {
      // The probe: hitBeforeLayout, hitBeforeLayoutNull and
      // handleEventBeforeLayout.
      final calls = <Object?>[];
      Legend((
          chart: _FakeChart(),
          options: <String, Object?>{
            'onClick': (Object? e, Object? item, Object? l) => calls.add(item),
          },
          ctx: null,
        ))
        ..handleEvent(_Event('click', 1, 1))
        ..handleEvent(_Event('click', null, null));
      expect(calls, isEmpty);
    });

    test('draw() with display false draws nothing', () {
      // The probe drawDisplayFalse: 0 calls.
      final ctx = createMockContext();
      Legend((
        chart: _FakeChart(),
        options: <String, Object?>{'display': false},
        ctx: ctx,
      )).draw();
      expect(ctx.getCalls(), isEmpty);
    });

    test('draw() with display true before update throws a TypeError', () {
      // The probes drawBeforeUpdateMock and drawBeforeUpdateTop: the read
      // `columnSizes[0]` or `lineWidths[0]` of undefined.
      for (final position in <Object?>[undefined, 'top']) {
        final box = Legend((
          chart: _FakeChart(),
          options: <String, Object?>{
            'display': true,
            'position': position,
            'labels': <String, Object?>{},
            'title': <String, Object?>{},
          },
          ctx: createMockContext(),
        ));
        expect(box.draw, throwsA(isA<TypeError>()));
      }
    });

    test('update without margins throws a TypeError', () {
      // The probe updateNoMargins: the read _margins.left of undefined.
      final box = Legend((
        chart: _FakeChart(),
        options: <String, Object?>{'position': 'top'},
        ctx: null,
      ));
      expect(() => box.update(100, 100), throwsA(isA<TypeError>()));
    });

    test('update(w, h, margins) reads the margins', () {
      // A vertical legend takes `top` of the margins (plugin.legend.js:99),
      // and `fit` with `display: false` gives the height 0 (:131).
      final box = Legend((
        chart: _FakeChart(),
        options: <String, Object?>{'position': 'left', 'display': false},
        ctx: null,
      ))..update(100, 200, _Margins(5, 7, 9, 11));
      expect([box.top, box.bottom, box.width, box.height], [7, 200, 0, 0]);
      expect(box.legendItems, isEmpty);
    });

    test('a legend without options throws a TypeError at its first read', () {
      final box = Legend((chart: _FakeChart(), options: null, ctx: null));
      expect(() => box.options, throwsA(isA<TypeError>()));
      expect(box.isHorizontal, throwsA(isA<TypeError>()));
    });
  });

  group('stop', () {
    testWidgets('a chart with plugins.legend false has no legend', (
      tester,
    ) async {
      final chart = acquireChart(_line(false));
      expect(chart.legend, isNull);
      expect(chart.boxes.whereType<Legend>(), isEmpty);
    });

    testWidgets('stop with a foreign legend removes no box', (tester) async {
      // The probe stopForeign: [true, true].
      final chart = acquireChart(_line(false));
      final boxes = [...chart.boxes];
      chart.legend = _ForeignLegend();
      jsCall(legend['stop'], [chart, <String, Object?>{}, <String, Object?>{}]);
      expect(chart.legend, isNull);
      expect(chart.boxes, boxes);
    });

    testWidgets('beforeUpdate with a foreign legend throws a TypeError', (
      tester,
    ) async {
      // Upstream: beforeUpdate does not throw, and afterUpdate of the same
      // update throws a TypeError at `legend.buildLabels` (probe:
      // beforeUpdateForeign, afterUpdateForeign). Chart.js ADR 0038,
      // section 6.
      final chart = acquireChart(_line(false))..legend = _ForeignLegend();
      expect(
        () => jsCall(legend['beforeUpdate'], [
          chart,
          <String, Object?>{},
          <String, Object?>{},
        ]),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => jsCall(legend['afterUpdate'], [chart, <String, Object?>{}]),
        throwsA(isA<TypeError>()),
      );
      chart.legend = null;
    });

    testWidgets('stop without a legend does not throw', (tester) async {
      // The probe stopWithoutLegend.
      final chart = acquireChart(_line(false));
      final boxes = [...chart.boxes];
      jsCall(legend['stop'], [chart, <String, Object?>{}, <String, Object?>{}]);
      expect(chart.legend, isNull);
      expect(chart.boxes, boxes);
    });

    testWidgets('stop removes the legend box', (tester) async {
      final chart = acquireChart(_line(<String, Object?>{}));
      final box = chart.legend;
      expect(box, isA<Legend>());
      expect(chart.boxes, contains(same(box)));
      jsCall(legend['stop'], [chart, <String, Object?>{}, <String, Object?>{}]);
      expect(chart.legend, isNull);
      expect(chart.boxes.where((b) => identical(b, box)), isEmpty);
    });
  });

  group('fit', () {
    testWidgets('fit leaves the label font in the context', (tester) async {
      // plugin.legend.js:143 `ctx.font = labelFont.string` with no save and
      // no restore: the layout of the next box measures in this font, also
      // when it does not set its own (the cases of scale.time.tests.js that
      // wait for the legend).
      final chart = acquireChart(
        _line(<String, Object?>{
          'labels': <String, Object?>{
            'font': <String, Object?>{'size': 17, 'family': 'Arial'},
          },
        }),
      );
      final ctx = chart.ctx!..font = '10px sans-serif';
      (chart.legend! as Legend).fit();
      expect(ctx.font, 'normal 17px Arial');
    });
  });

  group('item width', () {
    testWidgets('an empty array text in a vertical legend throws a '
        'TypeError', (tester) async {
      // plugin.legend.js:564 `[].reduce(fn)` with no initial value. The
      // probe review-empty-array-text.mjs (review-empty-array-text.out):
      // emptyArrayLeft throws `TypeError: Reduce of empty array with no
      // initial value`.
      final config = _line(<String, Object?>{'position': 'left'});
      (((config['data']! as AnyObject)['datasets']! as List<Object?>)[0]!
              as AnyObject)['label'] =
          <Object?>[];
      expect(() => acquireChart(config), throwsA(isA<TypeError>()));
    });
  });

  group('box default color', () {
    /// The chart option `color` and the `fillStyle` and `strokeStyle`
    /// writes of the legend draw of a chart with the option `color`
    /// [color] and the theme [theme], whose item has no `fillStyle` and no
    /// `strokeStyle`.
    (Object?, List<List<Object?>>) styles({String? color, AnyObject? theme}) {
      final config = _line(<String, Object?>{
        'labels': <String, Object?>{
          'generateLabels': (Object? chart) => <Object?>[
            <String, Object?>{'text': 'item', 'datasetIndex': 0},
          ],
        },
      });
      if (color != null) (config['options']! as AnyObject)['color'] = color;
      if (theme != null) config[themeConfigKey] = compileChartTheme(theme);
      final chart = acquireChart(config, <String, Object?>{
        'canvas': <String, Object?>{'width': 400, 'height': 300},
      });
      final ctx = createMockContext();
      (chart.legend! as Legend)
        ..ctx = ctx
        ..draw();
      return (
        jsGet(chart.options, 'color'),
        [
          for (final c in ctx.getCalls())
            if (jsGet(c, 'name') == 'setFillStyle' ||
                jsGet(c, 'name') == 'setStrokeStyle')
              [jsGet(c, 'name'), (jsGet(c, 'args')! as List<Object?>)[0]],
        ],
      );
    }

    /// The upstream writes of the probe review-default-color.mjs
    /// (review-default-color.out), with the chart option `color: 'green'`:
    /// the text color `fontColor` of the item is undefined (Dart `null` in
    /// the mock context), and the box reads the singleton `defaults.color`
    /// (plugin.legend.js:286, :314 and :319), not the chart option.
    const expected = [
      ['setStrokeStyle', null],
      ['setFillStyle', null],
      ['setFillStyle', '#666'],
      ['setStrokeStyle', '#666'],
    ];

    testWidgets('the box reads defaults.color, not the chart color', (
      tester,
    ) async {
      final (color, calls) = styles(color: 'green');
      expect(color, 'green');
      expect(calls, expected);
    });

    testWidgets('a theme color does not reach the box', (tester) async {
      // Chart.js ADR 0001: a theme does not write `defaults`. A copy of the
      // light preset with a green color gives the chart option `color`, and
      // the box keeps `defaults.color`.
      final (color, calls) = styles(
        theme: <String, Object?>{
          ...ChartThemes.light,
          'colors': <String, Object?>{
            ...ChartThemes.light['colors']! as AnyObject,
            'color': (alpha: 1.0, red: 0.0, green: 128 / 255, blue: 0.0),
          },
        },
      );
      expect(color, 'rgba(0, 128, 0, 1)');
      expect(calls, expected);
    });
  });

  group('adapt-component-class-role', () {
    test('a chart that is not a types.Chart throws a TypeError', () {
      // Upstream stores the value (probe: newChart5 gives 5, newEmpty gives
      // undefined).
      for (final chart in <Object?>[5, 'x', <String, Object?>{}, undefined]) {
        expect(
          () => _construct([
            <String, Object?>{'chart': chart},
          ]),
          throwsA(isA<TypeError>()),
        );
      }
      expect(
        () => _construct([<String, Object?>{}]),
        throwsA(isA<TypeError>()),
      );
    });

    test('an options value that is not a Map throws a TypeError', () {
      // Upstream stores the value (probe: newOptions5 gives 5).
      expect(
        () => _construct([
          <String, Object?>{'chart': _FakeChart(), 'options': 5},
        ]),
        throwsA(isA<TypeError>()),
      );
    });

    test('a ctx value that is not a context throws a TypeError', () {
      // Upstream stores the value (probe: newCtxString gives 'x').
      expect(
        () => _construct([
          <String, Object?>{'chart': _FakeChart(), 'ctx': 'x'},
        ]),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('adapt-legend-number-options', () {
    /// The edges of the legend and its hit boxes for the label options
    /// [labels] on a canvas of 400 x 300.
    List<Object?> layout(Map<String, Object?> labels, [String? position]) {
      final chart = acquireChart(
        _line(<String, Object?>{'position': ?position, 'labels': labels}),
        <String, Object?>{
          'canvas': <String, Object?>{'width': 400, 'height': 300},
        },
      );
      final box = chart.legend! as Legend;
      return [
        [box.left, box.top, box.right, box.bottom, box.width, box.height],
        plainValue(box.legendHitBoxes),
      ];
    }

    testWidgets('a string padding lays out as its number', (tester) async {
      // Upstream (probe legend_string_options_probe.mjs, stringPadding):
      // the `+` joins the string. The legend height is 150, the hit box tops
      // are the string '-12101210010' and the lefts are NaN. The port gives
      // the layout of `padding: 10` (numberPadding: the height 32, the tops
      // 10, the lefts 129.65 and 205.67).
      final number = layout(<String, Object?>{'padding': 10});
      expect(number[0], [0, 0, 400, 32, 400, 32]);
      expect(layout(<String, Object?>{'padding': '10'}), number);
    });

    testWidgets('a string boxWidth lays out as its number', (tester) async {
      // Upstream (stringBoxWidth): the hit box widths are the strings
      // '20620.021484375' and '20618.673828125'. The port adds 20.
      final number = layout(<String, Object?>{'boxWidth': 20});
      expect(layout(<String, Object?>{'boxWidth': '20'}), number);
    });
  });

  group('adapt-legend-dataset-index', () {
    /// The modes of `beforeDatasetUpdate` of each dataset after the default
    /// `onClick` with the item of dataset 1 and the index [datasetIndex].
    Future<Map<String, Object?>> modes(Object? datasetIndex) async {
      final seen = <List<Object?>>[];
      final spy = <String, Object?>{
        'id': 'spy',
        'beforeDatasetUpdate': (Object? chart, Object? args) =>
            seen.add([jsGet(args, 'index'), jsGet(args, 'mode')]),
      };
      final chart = acquireChart(
        _line(<String, Object?>{}, plugins: <Object?>[spy]),
      );
      final onClick = jsGet(chart.legend!.options, 'onClick');
      final item = <String, Object?>{
        ...chart.legend!.legendItems![1]! as Map<String, Object?>,
        'datasetIndex': datasetIndex,
      };
      seen.clear();
      jsCall(onClick, [null, item, chart.legend]);
      final first = [...seen];
      final hidden = item['hidden'];
      final visible = [chart.isDatasetVisible(0), chart.isDatasetVisible(1)];
      seen.clear();
      jsCall(onClick, [null, item, chart.legend]);
      return <String, Object?>{
        'modes': first,
        'hidden': hidden,
        'visible': visible,
        'modes2': [...seen],
        'hidden2': item['hidden'],
        'visible2': [chart.isDatasetVisible(0), chart.isDatasetVisible(1)],
      };
    }

    testWidgets('a number index gives the upstream result', (tester) async {
      // The probe onClickNumber: modes [[0, undefined], [1, 'hide']], then
      // [[0, undefined], [1, 'show']].
      final r = await modes(1.0);
      expect((r['modes']! as List<Object?>).map((m) => (m! as List)[1]), [
        same(undefined),
        'hide',
      ]);
      expect(r['hidden'], true);
      expect(r['visible'], [true, false]);
      expect((r['modes2']! as List<Object?>).map((m) => (m! as List)[1]), [
        same(undefined),
        'show',
      ]);
      expect(r['hidden2'], false);
      expect(r['visible2'], [true, true]);
    });

    testWidgets('a string index hides the dataset with the mode of a number '
        'index', (tester) async {
      // Upstream (probe onClickString): the same visibility and `hidden`,
      // but each mode is undefined, because `ctx.datasetIndex === '1'` is
      // false (core.controller.js:904). The port converts the index with
      // ToNumber (differences.md adapt-legend-dataset-index).
      final r = await modes('1');
      expect((r['modes']! as List<Object?>).map((m) => (m! as List)[1]), [
        same(undefined),
        'hide',
      ]);
      expect(r['hidden'], true);
      expect(r['visible'], [true, false]);
      expect(r['hidden2'], false);
      expect(r['visible2'], [true, true]);
    });

    testWidgets('an index key of a dataset finds the dataset', (tester) async {
      // Upstream reads `datasets[ToString(index)]` (core.controller.js:864,
      // :830). The probe fix-dataset-index.mjs (fix-dataset-index.out): '0'
      // and -0 hide dataset 0, [1] hides dataset 1, and `hidden` becomes
      // true. -0 gives the modes [[0, 'hide'], [1, undefined]]. '0' and [1]
      // give the mode undefined for each dataset, the port gives the mode
      // of a number index (differences.md adapt-legend-dataset-index).
      for (final (index, visible) in <(Object?, List<bool>)>[
        ('0', [false, true]),
        (-0.0, [false, true]),
        (<Object?>[1], [true, false]),
      ]) {
        final r = await modes(index);
        expect(r['hidden'], true, reason: '$index');
        expect(r['visible'], visible, reason: '$index');
        expect(r['hidden2'], false, reason: '$index');
        expect(r['visible2'], [true, true], reason: '$index');
      }
      final r = await modes(-0.0);
      expect((r['modes']! as List<Object?>).map((m) => (m! as List)[1]), [
        'hide',
        same(undefined),
      ]);
    });

    testWidgets('an index with no dataset key throws a TypeError', (
      tester,
    ) async {
      // The probes onClickUndefined and onClickFloat, and the probe
      // fix-dataset-index.mjs (fix-dataset-index.out): the key
      // `ToString(index)` names no dataset (core.controller.js:864, :830),
      // so the read `meta.controller._resolveAnimations` of the new meta
      // throws a TypeError (core.controller.js:895). `hidden` stays false,
      // and both datasets stay visible.
      for (final index in <Object?>[
        undefined,
        1.5,
        null,
        true,
        false,
        '',
        '01',
        '1.0',
        ' 1',
        'x',
      ]) {
        final chart = acquireChart(_line(<String, Object?>{}));
        final onClick = jsGet(chart.legend!.options, 'onClick');
        final item = <String, Object?>{
          ...chart.legend!.legendItems![1]! as Map<String, Object?>,
          'datasetIndex': index,
        };
        expect(
          () => jsCall(onClick, [null, item, chart.legend]),
          throwsA(isA<TypeError>()),
          reason: '$index',
        );
        expect(item['hidden'], false, reason: '$index');
        expect(
          [chart.isDatasetVisible(0), chart.isDatasetVisible(1)],
          [true, true],
          reason: '$index',
        );
      }
    });
  });

  group('input', () {
    /// A chart whose legend is at x 0 and y 0: `position: 'left'`, `align:
    /// 'start'`, `labels.padding: 0`, with the callbacks of [log] (the
    /// probe `leftBox` and `leftHitBoxes`).
    Chart leftChart(List<String> log) => acquireChart(
      _line(<String, Object?>{
        'position': 'left',
        'align': 'start',
        'labels': <String, Object?>{'padding': 0},
        'onClick': (Object? e, Object? item, Object? l) => log.add(
          'click ${jsToString(jsGet(item, 'text'))}',
        ),
        'onHover': (Object? e, Object? item, Object? l) => log.add(
          'hover ${jsToString(jsGet(item, 'text'))}',
        ),
        'onLeave': (Object? e, Object? item, Object? l) => log.add(
          'leave ${jsToString(jsGet(item, 'text'))}',
        ),
      }),
    );

    testWidgets('the hover callbacks of a mousemove and of a mouseout', (
      tester,
    ) async {
      // The probe hitLog: hover two; no leave for the mouseout inside the
      // same hit box; leave two at (300, 300); hover two; leave two and
      // hover one for the mouseout at (0, 0), which is in the hit box of
      // item one.
      final log = <String>[];
      final box = leftChart(log).legend! as Legend;
      final hb = box.legendHitBoxes[1];
      final left = hb['left']! as double;
      final top = hb['top']! as double;
      box
        ..handleEvent(_Event('mousemove', left + 1, top + 1))
        ..handleEvent(_Event('mouseout', left + 2, top + 2))
        ..handleEvent(_Event('mouseout', 300, 300))
        ..handleEvent(_Event('mousemove', left + 1, top + 1))
        ..handleEvent(_Event('mouseout', 0, 0));
      expect(log, [
        'hover two',
        'leave two',
        'hover two',
        'leave two',
        'hover one',
      ]);
    });

    testWidgets('a click at null coordinates reads 0, and NaN hits nothing', (
      tester,
    ) async {
      // The probe leftBox [0, 0, 76.02, 512, 76.02, 512], hitLog: a click at
      // JS null hits item one; NaN and undefined hit nothing.
      final log = <String>[];
      final box = leftChart(log).legend! as Legend;
      expect([box.left, box.top], [0, 0]);
      expect(box.legendHitBoxes.first['left'], 0);
      expect(box.legendHitBoxes.first['top'], 0);
      box
        ..handleEvent(_Event('click', null, null))
        ..handleEvent(_Event('click', double.nan, double.nan));
      expect(log, ['click one']);
    });

    testWidgets('a click on the right edge of a hit box hits it', (
      tester,
    ) async {
      // The probe hitLog: 5e-7 past the right edge hits (the epsilon 1e-6
      // of _isBetween, helpers.math.ts:205); 2e-6 past it hits nothing.
      final log = <String>[];
      final box = leftChart(log).legend! as Legend;
      final hb = box.legendHitBoxes[1];
      final right = (hb['left']! as double) + (hb['width']! as double);
      final top = hb['top']! as double;
      box
        ..handleEvent(_Event('click', right + 5e-7, top + 1))
        ..handleEvent(_Event('click', right + 2e-6, top + 1));
      expect(log, ['click two']);
    });

    testWidgets('a mousemove and a mouseout in one frame call onHover, then '
        'onLeave', (tester) async {
      // Each event type has its own throttle (platform.dom.js:96-110). Both
      // run in the next frame, in the order of their events.
      final log = <String>[];
      final chart = acquireChart(
        _line(<String, Object?>{
          'onHover': (Object? e, Object? item, Object? l) => log.add(
            'hover ${(e! as types.ChartEvent).type} '
            '${jsToString(jsGet(item, 'text'))}',
          ),
          'onLeave': (Object? e, Object? item, Object? l) => log.add(
            'leave ${(e! as types.ChartEvent).type} '
            '${jsToString(jsGet(item, 'text'))}',
          ),
        }),
      );
      final hb = (chart.legend! as Legend).legendHitBoxes.first;
      final x = (hb['left']! as double) + (hb['width']! as double) / 2;
      final y = (hb['top']! as double) + (hb['height']! as double) / 2;
      final canvas = chart.canvas!;
      dispatchCanvasEvent(
        canvas,
        NativeEvent(type: 'mousemove', offsetX: x, offsetY: y, target: canvas),
      );
      dispatchCanvasEvent(
        canvas,
        NativeEvent(type: 'mouseout', offsetX: 0, offsetY: 0, target: canvas),
      );
      expect(log, isEmpty);
      await pumpFrame();
      expect(log, ['hover mousemove one', 'leave mouseout one']);
    });
  });
}

/// A `types.Chart` that no test reads.
final class _FakeChart implements types.Chart {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A `types.LegendElement` that is not a [Legend].
final class _ForeignLegend implements types.LegendElement {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A chart event of [type] at ([x], [y]).
final class _Event implements types.ChartEvent {
  _Event(this.type, this.x, this.y);

  @override
  final String type;

  @override
  final double? x;

  @override
  final double? y;

  @override
  NativeEvent? get native => null;

  @override
  Chart? get chart => null;
}

/// The margins `{left, top, right, bottom}` of `core.layouts.js:167`.
final class _Margins implements TRBL {
  _Margins(this.left, this.top, this.right, this.bottom);

  @override
  final double left;

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;
}
