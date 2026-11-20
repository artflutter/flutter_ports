// Original code, not ported from Chart.js: legend plugin reference tests.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as native_ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart' show createMockContext;
import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_kurkle_color_port/flutter_kurkle_color_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/color_json.dart';
import '../../support/drop_extra_args.dart';
import '../../support/legend_item.dart';
import '../../support/light_theme.dart';
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
// Chart.js in Node.js v24.22.1 on arm64 (Chart.js ADR 0146), with the seven
// plugins registered and `colors.enabled: false` in the defaults. Each case
// is a unit case (the other plugins are `false`, Chart.js ADR 0041, section
// 4), except the full cases (the names that start with `full:`), which have
// the default plugin options (section 4 item 2). The observation has `boxes`
// and `plugins.legend` (the items, the hit boxes, the line widths, the column
// sizes, the callback log and the label options), and the draw calls.
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
void _log(String name, Object? e, Object? item, LegendElement legend) {
  (_logs[legend.chart] ??= <String>[]).add(
    '$name ${(e! as ChartEvent).type} '
    '${jsToString((item! as LegendItem).text)}',
  );
}

/// The named functions of the configs of the generator, with the same
/// bodies.
final Map<String, Object?> _functions = {
  // (e, item, legend) => log('onClick', e, item, legend)
  'logClick': (Object? e, Object? item, LegendElement legend) =>
      _log('onClick', e, item, legend),
  // (e, item, legend) => log('onHover', e, item, legend)
  'logHover': (Object? e, Object? item, LegendElement legend) =>
      _log('onHover', e, item, legend),
  // (e, item, legend) => log('onLeave', e, item, legend)
  'logLeave': (Object? e, Object? item, LegendElement legend) =>
      _log('onLeave', e, item, legend),
  // (item) => !String(item.text).endsWith('2')
  'legendFilter': (Object? item, Object? _) =>
      !jsToString((item! as LegendItem).text).endsWith('2'),
  // (a, b) => b.datasetIndex - a.datasetIndex
  'legendSort': (Object? a, Object? b, Object? _) =>
      (b! as LegendItem).datasetIndex! - (a! as LegendItem).datasetIndex!,
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
    // A column size is a Flutter `Size`: the object `{width, height}` of the
    // generator.
    'columnSizes': box.columnSizes == null
        ? undefined
        : [
            for (final size in box.columnSizes!)
              <String, Object?>{'width': size.width, 'height': size.height},
          ],
    'log': [...?_logs[chart]],
    // The own keys of the resolved label options: the box keeps the
    // `LegendOptions` of its resolved view (Chart.js ADR 0182).
    'labels': _withoutFunctions(plainValue(jsGet(box.options.view, 'labels'))),
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
  final String s => referenceParsedColor(s)?.rgbString() ?? s,
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
        for (final item in items)
          if (item is! AnyObject)
            item
          else
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

/// The hook keys of the default export of plugin.legend.js:592-720, in the
/// order of `PluginHook` (the probe output `keys`: `id`, `_element`, these
/// hooks, `defaults` and `descriptors`).
const List<String> _upstreamHooks = [
  'start',
  'stop',
  'beforeUpdate',
  'afterUpdate',
  'afterEvent',
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
// Keep the malformed legend inputs and labels that these cases exercise.
ChartConfigurationScope _mapLine(Object? legendOptions) =>
    ChartConfigurationScope()
      ..type = 'line'
      ..data = (ChartDataScope()
        ..labels = <Object?>['a', 'b']
        ..datasets = <Object?>[
          LineControllerDatasetOptionsScope()
            ..label = 'one'
            ..data = <Object?>[1, 2],
          LineControllerDatasetOptionsScope()
            ..label = 'two'
            ..data = <Object?>[2, 1],
        ])
      ..options = (ChartOptionsScope()
        ..plugins = (PluginOptionsByTypeScope()
          ..jsWrite('legend', legendOptions)));

/// The typed config of a line chart with two datasets and the legend
/// [legend].
ChartConfig _config([ChartLegend? legend, Map<String, Object?>? extra]) =>
    ChartConfig(
      labels: const ['a', 'b'],
      datasets: const [
        LineDataset(label: 'one', data: [1, 2]),
        LineDataset(label: 'two', data: [2, 1]),
      ],
      legend: legend,
      extra: extra,
    );

/// A line chart with two datasets and the legend [legend].
Chart _line([ChartLegend? legend]) =>
    acquireChartRoot(ChartConfigLowering(_config(legend)).lower());

/// The resolved legend options of a box that a test builds: the values of
/// `LegendOptions.of({})` for each option that the test does not give.
LegendOptions _legendOptions({
  bool display = false,
  LayoutPosition? position,
  LegendEventHandler? onClick,
}) => LegendOptions(
  align: null,
  display: display,
  fullSize: false,
  labels: LegendLabelOptions(
    borderRadius: null,
    boxHeight: null,
    boxWidth: null,
    color: null,
    filter: null,
    font: toFont(null),
    generateLabels: null,
    padding: double.nan,
    pointStyle: null,
    pointStyleWidth: null,
    sort: null,
    textAlign: null,
    useBorderRadius: false,
    usePointStyle: false,
  ),
  maxHeight: null,
  maxWidth: null,
  onClick: onClick,
  onHover: null,
  onLeave: null,
  position: position,
  reverse: false,
  rtl: false,
  textDirection: null,
  title: LegendTitleOptions(
    color: null,
    display: false,
    font: toFont(null),
    padding: paddingOption(null),
    position: null,
    text: const [],
  ),
  weight: null,
);

/// The label font of the case 'fit leaves the label font in the context'.
const _arial17 = ChartTextStyle(
  fontSize: 17,
  fontFamily: 'Arial',
  fontFamilyFallback: [],
);

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
      observers: {'legend': (chart) => _parseItemColors(_observeLegend(chart))},
      functions: _functions,
      theme: compileLightTheme(),
    );

    testWidgets('the light preset leaves no stale scale key', (tester) async {
      final snapshot = jsonDecode(
        File('test/port/theme/light_snapshot.json').readAsStringSync(),
      ) as Map<String, Object?>;
      final config =
          copyReference(pluginLegendReference.first.config, _functions)!
              as AnyObject;
      config[themeConfigKey] = compileLightTheme();
      nativeFixtureColors(config);
      expectNoStaleScaleKeys(acquireChartRoot(config), snapshot);
    });
  });

  group('class value', () {
    test('the superclass is Element.jsClass', () {
      expect(Legend.jsClass.superclass, same(Element.jsClass));
    });

    test('new Legend(config) keeps the chart, the options and the ctx', () {
      // Map options: the test pins the read of a JS config object.
      final chart = _FakeChart();
      final options = <String, Object?>{'display': true};
      final constructed = _construct([
        <String, Object?>{'chart': chart, 'options': options},
      ]);
      expect(constructed, isA<Legend>());
      final value = constructed! as Legend;
      expect(value.chart, same(chart));
      expect(value.options.display, isTrue);
      expect(value.options.view, same(options));
      expect(value.ctx, isNull);
    });

    test('new Legend() and new Legend(undefined) throw a TypeError', () {
      // Upstream: the read config.chart of undefined and null (probe:
      // newNoArg, newUndefined, newNull).
      expect(() => _construct(const []), throwsA(isA<TypeError>()));
      expect(() => _construct([undefined]), throwsA(isA<TypeError>()));
      expect(() => _construct([null]), throwsA(isA<TypeError>()));
    });

    test('the plugin has the hooks and the keys of the upstream object', () {
      // The native plugin of Chart.js ADR 0144: the hook keys of the upstream
      // object are its hooks, and `id`, `defaults` and `descriptors` its
      // fields. `_element` is no field: the class is `Legend.jsClass`.
      expect(pluginHookNames(legend), _upstreamHooks);
      expect(legend.id, 'legend');
      expect(legend.descriptors, isNotNull);
      expect(legend.defaultRoutes, isNull);
      expect(jsObjectKeys(legend.defaults), _upstreamDefaultsKeys);
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
      expect(box.position, isNull);
      expect(box.weight, isNull);
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
          options: _legendOptions(onClick: (e, item, l) => calls.add(item)),
          ctx: null,
        ))
        ..handleEvent(_Event('click', 1, 1))
        ..handleEvent(_Event('click', null, null));
      expect(calls, isEmpty);
    });

    test('draw() with display false draws nothing', () {
      // The probe drawDisplayFalse: 0 calls.
      final ctx = createMockContext();
      Legend((chart: _FakeChart(), options: _legendOptions(), ctx: ctx)).draw();
      expect(ctx.getCalls(), isEmpty);
    });

    test('draw() with display true before update throws a TypeError', () {
      // The probes drawBeforeUpdateMock and drawBeforeUpdateTop: the read
      // `columnSizes[0]` or `lineWidths[0]` of undefined.
      // The probe drawBeforeUpdateTop gives `'top'`: the position is the
      // enum value (row `adapt-chart-position-enum`).
      for (final position in <LayoutPosition?>[null, ChartPosition.top]) {
        final box = Legend((
          chart: _FakeChart(),
          options: _legendOptions(display: true, position: position),
          ctx: createMockContext(),
        ));
        expect(box.draw, throwsA(isA<TypeError>()));
      }
    });

    test('update without margins throws a TypeError', () {
      // The probe updateNoMargins: the read _margins.left of undefined.
      final box = Legend((
        chart: _FakeChart(),
        options: _legendOptions(position: ChartPosition.top),
        ctx: null,
      ));
      expect(() => box.update(100, 100), throwsA(isA<TypeError>()));
    });

    test('update(w, h, margins) reads the margins', () {
      // A vertical legend takes `top` of the margins (plugin.legend.js:99),
      // and `fit` with `display: false` gives the height 0 (:131).
      final box = Legend((
        chart: _FakeChart(),
        options: _legendOptions(position: ChartPosition.left),
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
      final chart = acquireChartRoot(_mapLine(false));
      expect(chart.legend, isNull);
      expect(chart.boxes.whereType<Legend>(), isEmpty);
    });

    testWidgets('stop with a foreign legend removes no box', (tester) async {
      // The probe stopForeign: [true, true].
      final chart = acquireChartRoot(_mapLine(false));
      final boxes = [...chart.boxes];
      chart.legend = _ForeignLegend();
      legend.stop!(chart, const PluginHookArgs(), _legendOptions());
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
      final chart = acquireChartRoot(_mapLine(false))
        ..legend = _ForeignLegend();
      expect(
        () => legend.beforeUpdate!(chart, UpdateHookArgs(), _legendOptions()),
        throwsA(isA<TypeError>()),
      );
      // The typed hook takes `(chart, args, options)` (Chart.js ADR 0054
      // §12): the TypeError comes from the cast of the legend.
      expect(
        () => legend.afterUpdate!(chart, UpdateHookArgs(), _legendOptions()),
        throwsA(isA<TypeError>()),
      );
      chart.legend = null;
    });

    testWidgets('stop without a legend does not throw', (tester) async {
      // The probe stopWithoutLegend.
      final chart = acquireChartRoot(_mapLine(false));
      final boxes = [...chart.boxes];
      legend.stop!(chart, const PluginHookArgs(), _legendOptions());
      expect(chart.legend, isNull);
      expect(chart.boxes, boxes);
    });

    testWidgets('stop removes the legend box', (tester) async {
      final chart = _line();
      final box = chart.legend;
      expect(box, isA<Legend>());
      expect(chart.boxes, contains(same(box)));
      legend.stop!(chart, const PluginHookArgs(), _legendOptions());
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
      final chart = _line(const ChartLegend(labelFont: _arial17));
      final ctx = chart.ctx!
        ..font = const TextStyle(fontFamily: 'sans-serif', fontSize: 10);
      (chart.legend! as Legend).fit();
      expect(ctx.font, toFont(_arial17));
    });
  });

  group('item width', () {
    testWidgets('an empty array text in a vertical legend throws a '
        'TypeError', (tester) async {
      // plugin.legend.js:564 `[].reduce(fn)` with no initial value. The
      // probe review-empty-array-text.mjs (review-empty-array-text.out):
      // emptyArrayLeft throws `TypeError: Reduce of empty array with no
      // initial value`.
      final config = _mapLine(<String, Object?>{
        'position': ChartPosition.left,
      });
      ((jsGet(config['data'], 'datasets')! as List<Object?>)[0]!
              as JsObjectFace)['label'] =
          <Object?>[];
      expect(() => acquireChartRoot(config), throwsA(isA<TypeError>()));
    });
  });

  group('box default color', () {
    /// The chart option `color` and the `fillStyle` and `strokeStyle`
    /// writes of the legend draw of a chart with the option `color`
    /// [color] and the theme [theme], whose item has no `fillStyle` and no
    /// `strokeStyle`.
    (Object?, List<List<Object?>>) styles({
      Object? color,
      ChartThemeData? theme,
    }) {
      final root = ChartConfigLowering(
        _config(
          ChartLegend(
            extra: {
              'labels': {
                'generateLabels': (Chart chart) => <LegendItem>[
                  LegendItem(text: ['item'], datasetIndex: 0),
                ],
              },
            },
          ),
          {'color': ?color},
        ),
      ).lower();
      if (theme != null) root.dollarTheme = compileThemeData(theme)!;
      final chart = acquireChartRoot(root, <String, Object?>{
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
      ['setStrokeStyle', native_ui.Color.fromRGBO(0, 128, 0, 1)],
      ['setFillStyle', native_ui.Color.fromRGBO(0, 128, 0, 1)],
      ['setFillStyle', native_ui.Color.fromRGBO(102, 102, 102, 1)],
      ['setStrokeStyle', native_ui.Color.fromRGBO(102, 102, 102, 1)],
    ];

    testWidgets('the box reads defaults.color, not the chart color', (
      tester,
    ) async {
      final (color, calls) = styles(
        color: const ChartPaint.solid(native_ui.Color.fromRGBO(0, 128, 0, 1)),
      );
      expect(
        color,
        const ChartPaint.solid(native_ui.Color.fromRGBO(0, 128, 0, 1)),
      );
      expect(calls, expected);
    });

    testWidgets('a theme color does not reach the box', (tester) async {
      // Chart.js ADR 0147: a theme does not write `defaults`. A copy of the
      // light preset with a green color gives the chart option `color`, and
      // the box keeps `defaults.color`.
      final (color, calls) = styles(
        theme: const ChartThemeData.light().copyWith(
          color: const native_ui.Color.fromRGBO(0, 128, 0, 1),
        ),
      );
      expect(
        color,
        const ChartPaint.solid(native_ui.Color.fromRGBO(0, 128, 0, 1)),
      );
      expect(calls, expected);
    });
  });

  // The groups `native legend items`, `adapt-native-callbacks` and `sort`
  // pin the writes into the legend items and the result of a user
  // `generateLabels`. Each upstream value in a comment comes from a probe on
  // the pinned build in Node.js v24.12.0 on x64 (controller_chart_common.mjs:
  // loadChartJs, registerBuiltins, makeChart) with the chart of [_line], the
  // other plugins `false` and a canvas of 400 x 300.
  group('native legend items', () {
    testWidgets('the default click mutates the native item', (tester) async {
      final chart = _line();
      final item = LegendItem(text: ['Apples'], datasetIndex: 0);
      callDroppingExtraArgs((chart.legend! as Legend).options.onClick, [
        null,
        item,
        chart.legend,
      ]);
      expect(item.hidden, isTrue);
      expect(chart.isDatasetVisible(0), isFalse);
    });
  });

  group('adapt-native-callbacks', () {
    // Chart.js ADR 0130: `generateLabels` holds a `LegendLabelsGenerator`,
    // which gives a `List<LegendItem>`. A function of another type (a Map
    // item, `undefined`, a value that is not a List) stops a debug build.
    for (final (name, generator) in <(String, Object)>[
      (
        'Map items',
        (Object? chart) => [
          {'text': 'Apples'},
        ],
      ),
      ('undefined items', (Object? chart) => [undefined]),
      ('a string', (Object? chart) => 'abc'),
      ('an object', (Object? chart) => <String, Object?>{}),
      ('a number', (Object? chart) => 5),
      ('true', (Object? chart) => true),
    ]) {
      testWidgets('a generator of $name stops a debug build', (tester) async {
        expect(
          () => acquireChartRoot(
            _mapLine(<String, Object?>{
              'labels': <String, Object?>{'generateLabels': generator},
            }),
            <String, Object?>{
              'canvas': <String, Object?>{'width': 400, 'height': 300},
            },
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    }
  });

  group('sort', () {
    testWidgets('native items sort stably and keep their identity', (
      tester,
    ) async {
      final a = LegendItem(text: ['a']);
      final b = LegendItem(text: ['b']);
      final c = LegendItem(text: ['c']);
      final chart = _line(
        ChartLegend(
          display: false,
          extra: {
            'labels': {
              'generateLabels': (Chart chart) => [a, b, c],
              'sort': (LegendItem x, LegendItem y, Object? data) => 0,
            },
          },
        ),
      );
      expect(chart.legend!.legendItems, [same(a), same(b), same(c)]);
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
      final chart = acquireChartRoot(
        _mapLine(<String, Object?>{'position': ?position, 'labels': labels}),
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
      expect(
        layout(<String, Object?>{'padding': '10'}),
        legendObservationMatcher(number),
      );
    });

    testWidgets('a string boxWidth lays out as its number', (tester) async {
      // Upstream (stringBoxWidth): the hit box widths are the strings
      // '20620.021484375' and '20618.673828125'. The port adds 20.
      final number = layout(<String, Object?>{'boxWidth': 20});
      expect(
        layout(<String, Object?>{'boxWidth': '20'}),
        legendObservationMatcher(number),
      );
    });
  });

  group('native legend dataset index', () {
    testWidgets('an integer index toggles the selected dataset', (
      tester,
    ) async {
      final chart = _line();
      final item = chart.legend!.legendItems![1];
      final click = (chart.legend! as Legend).options.onClick;
      callDroppingExtraArgs(click, [null, item, chart.legend]);
      expect(item.hidden, isTrue);
      expect(chart.isDatasetVisible(1), isFalse);
      callDroppingExtraArgs(click, [null, item, chart.legend]);
      expect(item.hidden, isFalse);
      expect(chart.isDatasetVisible(1), isTrue);
    });
    testWidgets('a descriptive item does not toggle a dataset', (tester) async {
      final chart = _line();
      final item = LegendItem(text: ['description']);
      callDroppingExtraArgs((chart.legend! as Legend).options.onClick, [
        null,
        item,
        chart.legend,
      ]);
      expect(item.hidden, isFalse);
      expect(chart.isDatasetVisible(0), isTrue);
      expect(chart.isDatasetVisible(1), isTrue);
    });
  });

  group('input', () {
    /// A chart whose legend is at x 0 and y 0: `position: 'left'`, `align:
    /// 'start'`, `labels.padding: 0`, with the callbacks of [log] (the
    /// probe `leftBox` and `leftHitBoxes`).
    Chart leftChart(List<String> log) => _line(
      ChartLegend(
        position: ChartPosition.left,
        align: ChartAlign.start,
        labelPadding: 0,
        onClick: (e, item, l) => log.add('click ${jsToString(item.text)}'),
        onHover: (e, item, l) => log.add('hover ${jsToString(item.text)}'),
        onLeave: (e, item, l) => log.add('leave ${jsToString(item.text)}'),
      ),
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
      final left = hb.left;
      final top = hb.top;
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
      expect(box.legendHitBoxes.first.left, 0);
      expect(box.legendHitBoxes.first.top, 0);
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
      final right = hb.left + hb.width;
      final top = hb.top;
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
      final chart = _line(
        ChartLegend(
          onHover: (e, item, l) =>
              log.add('hover ${e.type} ${jsToString(item.text)}'),
          onLeave: (e, item, l) =>
              log.add('leave ${e.type} ${jsToString(item.text)}'),
        ),
      );
      final hb = (chart.legend! as Legend).legendHitBoxes.first;
      final x = hb.left + hb.width / 2;
      final y = hb.top + hb.height / 2;
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
final class _FakeChart() implements IChart {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A `types.LegendElement` that is not a [Legend].
final class _ForeignLegend() implements LegendElement {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A chart event of [type] at ([x], [y]).
final class _Event(
  @override final String type,
  @override final double? x,
  @override final double? y,
) implements ChartEvent {
  @override
  NativeEvent? get native => null;

  @override
  Chart? get chart => null;
}

/// The margins `{left, top, right, bottom}` of `core.layouts.js:167`.
final class _Margins(
  @override final double left,
  @override final double top,
  @override final double right,
  @override final double bottom,
) implements TRBL;
