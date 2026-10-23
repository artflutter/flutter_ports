// Original code, not ported from Chart.js: tooltip plugin reference tests.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart' show MockContext;
import 'package:flutter_chartjs_port/src/canvas/canvas.dart'
    show CSSStyleDeclaration, HTMLCanvasElement;
import 'package:flutter_chartjs_port/src/core/core.animation.dart';
import 'package:flutter_chartjs_port/src/core/core.animations.dart';
import 'package:flutter_chartjs_port/src/core/core.animator.dart' show animator;
import 'package:flutter_chartjs_port/src/core/core.config.dart'
    show themeConfigKey;
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.registry.dart' show registry;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart' show noop;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/color.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.tooltip.dart';
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/theme/presets.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart' show Point;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../../support/jasmine.dart' show jasmineEquals;
import '../controllers/controller_chart_harness.dart'
    show expectNoStaleScaleKeys, plainValue;
import '../core/animation_reference.dart';
import '../scales/scale_chart_harness.dart';
import 'plugin_chart_harness.dart';
import 'plugin_tooltip_more_reference.dart';
import 'plugin_tooltip_reference.dart';

// The port-only reference tests of lib/src/plugins/plugin.tooltip.dart
// (Chart.js ADR 0041, section 3) and the pin tests of Chart.js ADR 0039,
// section 15. The spec port is test/specs/plugin.tooltip_test.dart.
//
// The reference group compares real charts with the charts of
// tool/reference/plugin_tooltip_reference.mjs: a build of the pinned
// Chart.js in Node.js v24.12.0 on x64 (Chart.js ADR 0032), with the seven
// plugins registered and `colors.enabled: false` in the defaults. Each case
// is a unit case (the plugins other than the legend and the tooltip are
// `false`, Chart.js ADR 0041, section 4), except the full case
// `full: title, filler and clickLegend`, which has the default plugin options
// (section 4 item 2). The observation has `boxes` and
// `plugins.tooltip` (the model, the lines, the label styles, the tooltip
// items, the active items and the log of `external`), and the draw calls.
// The cases run two times: unthemed, and with the light preset (theming.md
// section 8 test 3). In the themed run, the colors compare in their parsed
// form, and the options compare only the keys of upstream.
//
// The other groups pin the decisions of Chart.js ADR 0039. Their expected
// values come from a probe on the pinned build in Node.js v24.12.0 on x64
// (controller_chart_common.mjs: loadChartJs, registerBuiltins, makeChart),
// on the charts of the groups: a line chart of 512 x 512 with the labels
// A, B and C, one dataset `one` with the data 10, 20 and 30, and the legend
// off. The probe called `setActiveElements` with the event position
// {x: 150, y: 100}, the default callbacks without `this`, the positioners
// with results of other forms, `average` with fake elements, the events of
// the chart, `update` through a replaced function, and the draw with an
// inline plugin. Each test comment gives the values of the probe output
// that it pins.

/// The log of each chart: the calls of the callback `external` (`logs` of
/// the generator).
final Expando<List<String>> _logs = Expando<List<String>>('tooltip log');

/// Adds [entry] to the log of [chart] (`log` of the generator).
void _log(types.Chart chart, String entry) =>
    (_logs[chart] ??= <String>[]).add(entry);

/// The named functions of the configs of the generator, with the same
/// bodies.
final Map<String, Object?> _functions = {
  // () => ['Title A', 'Title B']
  'cbTitle': () => <Object?>['Title A', 'Title B'],
  // () => 'After 1\nAfter 2'
  'cbAfterTitle': () => 'After 1\nAfter 2',
  // () => 5
  'cbBeforeBody': () => 5.0,
  // (item) => 'Item ' + item.datasetIndex + '.' + item.dataIndex
  'cbBeforeLabel': (Object? item) => jsAdd(
    jsAdd(jsAdd('Item ', jsGet(item, 'datasetIndex')), '.'),
    jsGet(item, 'dataIndex'),
  ),
  // (item) => item.datasetIndex === 0 ? ['Line 1', 'Line 2'] : undefined
  'cbLabel': (Object? item) => jsGet(item, 'datasetIndex') == 0.0
      ? <Object?>['Line 1', 'Line 2']
      : undefined,
  // () => null
  'cbAfterLabel': () => null,
  // () => 'End 1\nEnd 2'
  'cbAfterBody': () => 'End 1\nEnd 2',
  // () => 'Before footer'
  'cbBeforeFooter': () => 'Before footer',
  // (items) => 'Count: ' + items.length
  'cbFooter': (Object? items) => jsAdd('Count: ', jsGet(items, 'length')),
  // () => ''
  'cbAfterFooter': () => '',
  // (item) => item.datasetIndex === 0 ? 'red' : 'blue'
  'cbLabelTextColor': (Object? item) =>
      jsGet(item, 'datasetIndex') == 0.0 ? 'red' : 'blue',
  // (item) => item.datasetIndex !== 1
  'tooltipFilter': (Object? item) => jsGet(item, 'datasetIndex') != 1.0,
  // (a, b) => b.datasetIndex - a.datasetIndex
  'tooltipSort': (Object? a, Object? b) =>
      jsToNumber(jsGet(b, 'datasetIndex')) -
      jsToNumber(jsGet(a, 'datasetIndex')),
  // function (context) { log(this.chart, 'external ' + ...) }
  'tooltipExternal': JsFunction((Object? self, Object? context) {
    _log(
      (self! as types.TooltipModel).chart,
      'external ${jsToString(jsGet(context, 'replay'))} '
      '${identical(jsGet(context, 'tooltip'), self)} '
      '${jsObjectKeys(context! as AnyObject).join(',')}',
    );
  }),
  // (item) => ({borderColor: item.datasetIndex === 0 ? 'red' : 'green',
  // backgroundColor: 'blue', borderWidth: {top: 1, left: 2}, borderDash:
  // [2, 1], borderDashOffset: 1, borderRadius: 3})
  'roundLabelColor': (Object? item) => <String, Object?>{
    'borderColor': jsGet(item, 'datasetIndex') == 0.0 ? 'red' : 'green',
    'backgroundColor': 'blue',
    'borderWidth': <String, Object?>{'top': 1.0, 'left': 2.0},
    'borderDash': <Object?>[2.0, 1.0],
    'borderDashOffset': 1.0,
    'borderRadius': 3.0,
  },
};

/// The custom positioner of the generator (`Tooltip.positioners.custom`):
/// it reads `this`, the tooltip.
///
/// ```js
/// function (items, eventPosition) {
///   if (!items.length) return false;
///   const area = this.chart.chartArea;
///   return {x: area.left + 20, y: eventPosition.y, xAlign: 'left',
///     yAlign: 'top'};
/// }
/// ```
final JsFunction _customPositioner = JsFunction((
  Object? self,
  Object? items,
  Object? eventPosition,
) {
  if (!jsTruthy(jsGet(items, 'length'))) {
    return false;
  }
  final area = (self! as types.TooltipModel).chart.chartArea!;
  return <String, Object?>{
    'x': area.left + 20,
    'y': eventPosition is Point ? eventPosition.y : jsGet(eventPosition, 'y'),
    'xAlign': 'left',
    'yAlign': 'top',
  };
});

/// The observer `plugins.tooltip` of the generator (`observeTooltip`): Dart
/// `null` without a tooltip, else the members of the model through the read
/// by name (the `undefined` sentinel for JS `undefined`), the plain tooltip
/// items without `chart`, `dataset` and `element`, the active items and the
/// log of `external`. It reads the tooltip through `types.TooltipModel`
/// and `types.ElementPropertyRead` (Chart.js ADR 0039, section 14).
Object? _observeTooltip(Chart chart) {
  final model = chart.tooltip;
  if (model == null) return null;
  final byName = model as types.ElementPropertyRead;
  return <String, Object?>{
    for (final key in const [
      'opacity',
      'x',
      'y',
      'width',
      'height',
      'caretX',
      'caretY',
      'xAlign',
      'yAlign',
    ])
      key: byName[key],
    for (final key in const [
      'title',
      'beforeBody',
      'body',
      'afterBody',
      'footer',
      'labelColors',
      'labelPointStyles',
      'labelTextColors',
    ])
      key: plainValue(byName[key]),
    'dataPoints': switch (model.dataPoints) {
      null => undefined,
      final points => [
        for (final p in points)
          <String, Object?>{
            'datasetIndex': jsGet(p, 'datasetIndex'),
            'dataIndex': jsGet(p, 'dataIndex'),
            'label': jsGet(p, 'label'),
            'formattedValue': jsGet(p, 'formattedValue'),
            'parsed': plainValue(jsGet(p, 'parsed')),
            'raw': plainValue(jsGet(p, 'raw')),
          },
      ],
    },
    'active': [
      for (final a in model.getActiveElements()) [a.datasetIndex, a.index],
    ],
    'log': [...?_logs[chart]],
  };
}

/// [value] in its parsed form when it is a color: `Color(value).rgbString()`.
Object? _parseColor(Object? value) => switch (value) {
  final String s => Color(s).rgbString() ?? s,
  _ => value,
};

/// The observation `plugins.tooltip` [tooltip] with the parsed form of the
/// colors of `labelTextColors`. The themed run compares the colors in their
/// parsed form (theming.md section 8 test 3), and the harness parses only
/// the keys `color` and `*Color`.
Object? _parseTextColors(Object? tooltip) => switch (tooltip) {
  final Map<String, Object?> map => <String, Object?>{
    ...map,
    'labelTextColors': switch (map['labelTextColors']) {
      final List<Object?> colors => [for (final c in colors) _parseColor(c)],
      final other => other,
    },
  },
  _ => tooltip,
};

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
/// `null` in `datasets`: the empty `linkScales` of the pie and the polar
/// area keeps the JS `null`, and the Dart field `ChartMeta.xAxisID` has
/// Dart `null` for both (the form of `_undefinedAxisIds` of
/// controller.doughnut_test.dart).
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

/// The reference cases of both data files with the axis ids of
/// [_undefinedAxisIds]. The generator splits the cases into two files,
/// because one file is above the limit of 2,500,000 bytes (Chart.js ADR
/// 0041, section 4 item 4).
/// The probes of the generator: `canvasDirection`, the `direction` value
/// and priority of the canvas style after the draw (helpers.rtl.ts:55-73).
final Map<String, Object? Function(Chart chart)> _extras = {
  'canvasDirection': (chart) => [
    chart.canvas!.style.getPropertyValue('direction'),
    chart.canvas!.style.getPropertyPriority('direction'),
  ],
};

final List<ScaleChartCase> _reference = _mapObservations(
  [...pluginTooltipReference, ...pluginTooltipMoreReference],
  _undefinedAxisIds,
);

/// The reference cases of the themed run: [_reference] with the parsed text
/// colors of [_parseTextColors].
final List<ScaleChartCase> _themedReference = _mapObservations(
  _reference,
  (observation) => <String, Object?>{
    ...observation,
    'plugins.tooltip': _parseTextColors(observation['plugins.tooltip']),
  },
);

/// The keys of the default export of plugin.tooltip.js:1223-1350, in their
/// order.
const List<String> _upstreamKeys = [
  'id',
  '_element',
  'positioners',
  'afterInit',
  'beforeUpdate',
  'reset',
  'afterDraw',
  'afterEvent',
  'defaults',
  'defaultRoutes',
  'descriptors',
  'additionalOptionScopes',
];

/// The keys of the `defaults` of plugin.tooltip.js:1275-1325.
const List<String> _upstreamDefaultsKeys = [
  'enabled',
  'external',
  'position',
  'backgroundColor',
  'titleColor',
  'titleFont',
  'titleSpacing',
  'titleMarginBottom',
  'titleAlign',
  'bodyColor',
  'bodySpacing',
  'bodyFont',
  'bodyAlign',
  'footerColor',
  'footerSpacing',
  'footerMarginTop',
  'footerFont',
  'footerAlign',
  'padding',
  'caretPadding',
  'caretSize',
  'cornerRadius',
  'boxHeight',
  'boxWidth',
  'multiKeyBackground',
  'displayColors',
  'boxPadding',
  'borderColor',
  'borderWidth',
  'animation',
  'animations',
  'callbacks',
];

/// The 14 keys of `defaultCallbacks` (plugin.tooltip.js:361-436).
const List<String> _callbackNames = [
  'beforeTitle',
  'title',
  'afterTitle',
  'beforeBody',
  'beforeLabel',
  'label',
  'labelColor',
  'labelTextColor',
  'labelPointStyle',
  'afterLabel',
  'afterBody',
  'beforeFooter',
  'footer',
  'afterFooter',
];

/// The names whose callback gets the list of the tooltip items. The other
/// names get one item.
const Set<String> _listCallbacks = {
  'beforeTitle',
  'title',
  'afterTitle',
  'beforeBody',
  'afterBody',
  'beforeFooter',
  'footer',
  'afterFooter',
};

/// `new Tooltip(config)` through the class value.
Object? _construct(List<Object?> args) => jsConstruct(Tooltip.jsClass, args);

/// A chart that is a `types.Chart` and nothing else. A member that a test
/// does not stub throws a `NoSuchMethodError`.
final class _FakeChart implements types.Chart {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The chart of the cache test: `getContext()` and `options` with an
/// animation object, as a chart whose `chart.options.animation` is truthy.
final class _CacheChart implements types.Chart {
  @override
  AnyObject getContext() => <String, Object?>{};

  @override
  AnyObject get options => <String, Object?>{
    'animation': <String, Object?>{'duration': 0},
  };

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// An element whose `tooltipPosition` gives ([px], 1) and whose `hasValue`
/// is true: the fake element `{hasValue: () => true, tooltipPosition: () =>
/// ({x, y: 1})}` of the probe.
final class _FakeElement extends Element {
  _FakeElement(this.px);

  final double px;

  @override
  bool hasValue() => true;

  @override
  ElementPoint tooltipPosition([bool? useFinalPosition]) => ElementPoint(px, 1);
}

/// The probe chart of the groups: a line chart with the labels A, B and C,
/// one dataset `one` with the data 10, 20 and 30, the legend off, and the
/// tooltip options [tooltipOptions]. [extra] goes into the chart options.
AnyObject _probeChart([Object? tooltipOptions, AnyObject extra = const {}]) =>
    <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'labels': <Object?>['A', 'B', 'C'],
        'datasets': <Object?>[
          <String, Object?>{
            'label': 'one',
            'data': <Object?>[10, 20, 30],
          },
        ],
      },
      'options': <String, Object?>{
        'plugins': <String, Object?>{
          'legend': false,
          'tooltip': tooltipOptions ?? <String, Object?>{},
        },
        ...extra,
      },
    };

/// The tooltip of [chart], as the class of the plugin.
Tooltip _tooltipOf(Chart chart) => chart.tooltip! as Tooltip;

/// `setActiveElements([{datasetIndex: 0, index}], {x: 150, y: 100})` on the
/// tooltip of [chart], the call of the probe.
void _activate(Chart chart, [Object? index = 1]) =>
    _tooltipOf(chart).setActiveElements(
      [
        <String, Object?>{'datasetIndex': 0, 'index': index},
      ],
      <String, Object?>{'x': 150, 'y': 100},
    );

/// The point `{x, y}`.
AnyObject _point(num x, num y) => <String, Object?>{'x': x, 'y': y};

/// The active items of [items] as `[datasetIndex, index]`.
List<Object?> _pairs(List<types.ActiveElement> items) => [
  for (final item in items) [item.datasetIndex, item.index],
];

/// `[...[body item].lines]` of each body item of [tooltip].
List<Object?> _bodyLines(Tooltip tooltip) => [
  for (final item in tooltip.body!) jsGet(item, 'lines'),
];

/// Whether [actual] is the reference value [expected]: the same type and
/// value, NaN for NaN, and the sign of a zero (the form of
/// core.animation_test.dart).
bool _same(Object? actual, Object? expected) {
  if (expected is double) {
    if (actual is! num) return false;
    final value = actual.toDouble();
    if (expected.isNaN) return value.isNaN;
    return value == expected && value.isNegative == expected.isNegative;
  }
  return identical(actual, expected) || actual == expected;
}

/// A matcher for the reference value [expected] ([_same]).
Matcher _isValue(Object? expected) => predicate<Object?>(
  (actual) => _same(actual, expected),
  'is ${expected is String ? "'$expected'" : expected} of the reference',
);

/// The JavaScript name of the class of [error], as `e.constructor.name`.
String _errorName(Object error) =>
    error is TypeError ? 'TypeError' : error.runtimeType.toString();

/// Replays [scenario] on the property [prop] of [target] (the replay of
/// core.animation_test.dart, group `adapt-animation-number-path`, with the
/// plain Map cfg). It compares each step with the reference.
void _replay(
  AnimationScenario scenario, {
  required Object target,
  required String prop,
  required String label,
}) {
  if (!identical(scenario.current, animationAbsent)) {
    writeProperty(target, prop, scenario.current);
  }
  final anim = Animation(
    scenario.cfg,
    target,
    prop,
    identical(scenario.to, animationAbsent) ? undefined : scenario.to,
  );
  final startBase = anim.start;
  for (final (i, (step, expected)) in scenario.steps.indexed) {
    final reason = '$label, ${scenario.name}, step $i (${step.$1})';
    String? error;
    try {
      switch (step.$1) {
        case 'tick':
          anim.tick(anim.start + step.$2);
        case 'from':
          anim.from = step.$3;
        case 'to':
          anim.to = step.$3;
        case 'update':
          anim.update(step.$4!, step.$3, anim.start + step.$2);
      }
      // The steps compare the error of the port with the error of upstream.
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      error = _errorName(e);
    }
    expect(error, expected.$3, reason: '$reason: error');
    expect(anim.active(), expected.$1, reason: '$reason: active');
    expect(readProperty(target, prop), _isValue(expected.$2), reason: reason);
    final fields = expected.$4;
    if (fields != null) {
      expect(anim.from, _isValue(fields.from), reason: '$reason: from');
      expect(anim.to, _isValue(fields.to), reason: '$reason: to');
      expect(anim.duration, _isValue(fields.duration), reason: '$reason: dur');
      expect(anim.total, _isValue(fields.total), reason: '$reason: total');
      expect(
        anim.start - startBase,
        _isValue(fields.start),
        reason: '$reason: start',
      );
    }
  }
}

/// A new tooltip of a [_FakeChart] without options.
Tooltip _newTooltip() => Tooltip((chart: _FakeChart(), options: null));

void main() {
  // The custom positioner of the generator.
  Tooltip.positioners['custom'] = _customPositioner;

  testReferenceOrigin(
    node: pluginTooltipReferenceNode,
    arch: pluginTooltipReferenceArch,
    dist: pluginTooltipReferenceDist,
    commit: pluginTooltipReferenceCommit,
  );
  testReferenceWidths(pluginTooltipReferenceWidths);
  testReferenceOrigin(
    node: pluginTooltipMoreReferenceNode,
    arch: pluginTooltipMoreReferenceArch,
    dist: pluginTooltipMoreReferenceDist,
    commit: pluginTooltipMoreReferenceCommit,
  );
  testReferenceWidths(pluginTooltipMoreReferenceWidths);

  test('the reference has the unit cases of Chart.js ADR 0041', () {
    expect(
      [
        for (final c in [
          ...pluginTooltipReference,
          ...pluginTooltipMoreReference,
        ])
          c.name,
      ],
      [
        'mode index with intersect false',
        'mode nearest with intersect true',
        'mode point',
        'mode dataset',
        'mode x with intersect false',
        'mode y with intersect false',
        'position nearest',
        'a custom positioner',
        'the callbacks of each text part',
        'the options xAlign and yAlign',
        'a caret near the left edge',
        'a caret near the right edge',
        'a caret near the top edge',
        'a caret near the bottom edge',
        'rtl',
        'textDirection rtl',
        'displayColors false',
        'usePointStyle',
        'boxPadding and padding',
        'filter',
        'itemSort',
        'footer and the text aligns',
        'external',
        'enabled false',
        'hover then mouseout',
        'setTooltip on a bar chart',
        'click with events click',
        'a bar chart in mode index',
        'a pie chart',
        'a polar area chart',
        'a scatter chart with the positioner nearest',
        'a label color with a border radius',
        'a corner radius object and a border',
        'bodyAlign center with the color boxes',
        'full: title, filler and clickLegend',
      ],
    );
  });

  testPluginChartCases(
    _reference,
    observers: {'tooltip': _observeTooltip},
    functions: _functions,
    extras: _extras,
  );

  group('theming.md §8 test 3: the light preset', () {
    testPluginChartCases(
      _themedReference,
      observers: {
        'tooltip': (chart) => _parseTextColors(_observeTooltip(chart)),
      },
      functions: _functions,
      extras: _extras,
      theme: compileChartTheme(ChartThemes.light),
    );

    testWidgets('the light preset leaves no stale scale key', (tester) async {
      final snapshot = jsonDecode(
        File('test/port/theme/light_snapshot.json').readAsStringSync(),
      ) as Map<String, Object?>;
      final config =
          copyReference(pluginTooltipReference.first.config, _functions)!
              as AnyObject;
      config[themeConfigKey] = compileChartTheme(ChartThemes.light);
      expectNoStaleScaleKeys(acquireChart(config), snapshot);
    });
  });

  group('class value', () {
    test('the superclass is Element.jsClass', () {
      expect(Tooltip.jsClass.superclass, same(Element.jsClass));
    });

    test('the plugin entry _element is Tooltip.jsClass', () {
      expect(
        jsGet(registry.getPlugin('tooltip'), '_element'),
        same(Tooltip.jsClass),
      );
      expect(tooltip['_element'], same(Tooltip.jsClass));
    });

    test('the three positioners are one Map', () {
      // The probe output `samePositioners`: true.
      expect(tooltip['positioners'], same(Tooltip.positioners));
      expect(Tooltip.jsClass['positioners'], same(Tooltip.positioners));
      expect(
        jsGet(registry.getPlugin('tooltip'), 'positioners'),
        same(Tooltip.positioners),
      );
    });

    test('new Tooltip(config) keeps the chart and the options', () {
      final chart = _FakeChart();
      final options = <String, Object?>{'enabled': true};
      final constructed = _construct([
        <String, Object?>{'chart': chart, 'options': options},
      ]);
      expect(constructed, isA<Tooltip>());
      final value = constructed! as Tooltip;
      expect(value.chart, same(chart));
      expect(value.options, same(options));
    });

    test('new Tooltip() and new Tooltip(undefined) throw a TypeError', () {
      // Upstream: the read config.chart of undefined and null.
      expect(() => _construct(const []), throwsA(isA<TypeError>()));
      expect(() => _construct([undefined]), throwsA(isA<TypeError>()));
      expect(() => _construct([null]), throwsA(isA<TypeError>()));
    });

    test('the keys of the plugin object are the upstream keys', () {
      expect(jsObjectKeys(tooltip), _upstreamKeys);
      final defaults = tooltip['defaults']! as AnyObject;
      expect(jsObjectKeys(defaults), _upstreamDefaultsKeys);
      expect(
        jsObjectKeys(defaults['callbacks']! as AnyObject),
        _callbackNames,
      );
    });
  });

  group('adapt-component-class-role', () {
    test('a chart that is not a types.Chart throws a TypeError', () {
      // Upstream stores the value and reads its members later.
      expect(
        () => _construct([
          <String, Object?>{'chart': <String, Object?>{}},
        ]),
        throwsA(isA<TypeError>()),
      );
    });

    test('options that are not a Map throw a TypeError', () {
      expect(
        () => _construct([
          <String, Object?>{'chart': _FakeChart(), 'options': 5},
        ]),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('access by name', () {
    test('the start values of the 24 names', () {
      // The probe output `start`: opacity 0, `_active` and `_tooltipItems`
      // [], the other names undefined; `_ignoreReplayEvents` is not an own
      // key, so its read gives undefined too.
      final t = _newTooltip();
      expect(t['opacity'], 0.0);
      expect(t['_active'], isEmpty);
      expect(t['_tooltipItems'], isEmpty);
      expect(t['chart'], same(t.chart));
      for (final name in const [
        'width',
        'height',
        'caretX',
        'caretY',
        'xAlign',
        'yAlign',
        'title',
        'beforeBody',
        'body',
        'afterBody',
        'footer',
        'dataPoints',
        'labelColors',
        'labelPointStyles',
        'labelTextColors',
        '_eventPosition',
        '_size',
        '_cachedAnimations',
        r'$context',
        '_ignoreReplayEvents',
      ]) {
        expect(identical(t[name], undefined), isTrue, reason: name);
      }
      expect(t.width, isNaN);
      expect(t.opacity, 0);
    });

    test('a write by name stores the value, and the read gives it', () {
      final t = _newTooltip();
      final chart = _FakeChart();
      final list = <Object?>['a'];
      final active = <types.ActiveElement>[];
      final animations = Animations(chart, false);
      final context = <String, Object?>{};
      final values = <String, Object?>{
        'opacity': 0.5,
        'width': 10.0,
        'height': 20.0,
        'caretX': 1.0,
        'caretY': 2.0,
        'xAlign': 'left',
        'yAlign': 'top',
        'title': list,
        'beforeBody': list,
        'body': list,
        'afterBody': list,
        'footer': list,
        'dataPoints': list,
        'labelColors': list,
        'labelPointStyles': list,
        'labelTextColors': list,
        'chart': chart,
        '_active': active,
        '_eventPosition': 'any value',
        '_size': (width: 3.0, height: 4.0),
        '_cachedAnimations': animations,
        '_tooltipItems': list,
        r'$context': context,
        '_ignoreReplayEvents': true,
      };
      expect(values.length, 24);
      for (final MapEntry(:key, :value) in values.entries) {
        t[key] = value;
        expect(t[key], value, reason: key);
      }
      expect(t.chart, same(chart));
      expect(t.getActiveElements(), same(active));
      expect(t.title, same(list));
      expect(t.width, 10);
      // An int becomes a double.
      t['caretX'] = 7;
      expect(t['caretX'], isA<double>());
      // undefined again.
      for (final name in const ['width', 'xAlign', 'title', '_size']) {
        t[name] = undefined;
        expect(identical(t[name], undefined), isTrue, reason: name);
      }
    });

    test('a value outside the type throws an ArgumentError', () {
      // Chart.js ADR 0017, section 5. Upstream stores the value.
      final t = _newTooltip();
      for (final (name, value) in <(String, Object?)>[
        ('opacity', 'a'),
        ('width', null),
        ('xAlign', 5.0),
        ('yAlign', <String, Object?>{'o': 1}),
        ('title', 'a'),
        ('body', 5),
        ('chart', undefined),
        ('chart', <String, Object?>{}),
        ('_active', undefined),
        ('_active', <Object?>[1]),
        ('_tooltipItems', undefined),
        ('_size', <String, Object?>{}),
        ('_cachedAnimations', 1),
        (r'$context', 1),
        ('_ignoreReplayEvents', 1),
      ]) {
        expect(
          () => t[name] = value,
          throwsA(isA<ArgumentError>()),
          reason: name,
        );
      }
    });

    test('the names of Element still work', () {
      final t = _newTooltip()
        ..['x'] = 3
        ..['other'] = 'extra';
      expect(t.x, 3);
      expect(t['other'], 'extra');
      expect(t['active'], false);
    });
  });

  group('_active by name', () {
    testWidgets('a write of _active changes getActiveElements', (
      tester,
    ) async {
      final chart = acquireChart(_probeChart());
      final t = _tooltipOf(chart);
      final element = chart.getDatasetMeta(0).data[2];
      final items = <types.ActiveElement>[
        _Item(datasetIndex: 0, index: 2, element: element),
      ];
      t['_active'] = items;
      expect(t.getActiveElements(), same(items));
      expect(t['_active'], same(items));
    });
  });

  group('harness-method-fields', () {
    testWidgets('a replaced update sees each call of the tooltip', (
      tester,
    ) async {
      // The probe output `updateCalls`: [true, undefined] for the mousemove,
      // [true, true] for the replay of chart.update(), [true] for
      // setActiveElements (one argument: replay is undefined), and no call
      // for the replay of chart.update() after setActiveElements.
      final chart = acquireChart(_probeChart());
      final t = _tooltipOf(chart);
      final calls = <Object?>[];
      final original = t.update;
      t.update = ([changed = undefined, replay = undefined]) {
        calls.add([changed, replay]);
        original(changed, replay);
      };
      final point = chart.getDatasetMeta(0).data[1];

      await triggerMouseEvent(chart, 'mousemove', point);
      calls.add('after mousemove');
      chart.update();
      calls.add('after update');
      t.setActiveElements([
        <String, Object?>{'datasetIndex': 0, 'index': 2},
      ], _point(10, 10));
      calls.add('after setActiveElements');
      chart.update();
      calls.add('after update 2');

      expect(calls, [
        [true, undefined],
        'after mousemove',
        [true, true],
        'after update',
        [true, undefined],
        'after setActiveElements',
        'after update 2',
      ]);
    });
  });

  group('positioners', () {
    testWidgets('a function positioner gets the tooltip as this', (
      tester,
    ) async {
      // The probe output `thisIsTooltip` true, `thisArgs` [true, 150], and
      // `pos_thisProbe`: caretX 10, caretY 20, xAlign left, yAlign top.
      Object? self;
      List<Object?>? args;
      Tooltip.positioners['thisProbe'] = JsFunction((
        Object? s,
        Object? items,
        Object? eventPosition,
      ) {
        self = s;
        args = [items is List, jsGet(eventPosition, 'x')];
        return <String, Object?>{'x': 10, 'y': 20};
      });
      addTearDown(() => Tooltip.positioners.remove('thisProbe'));
      final chart = acquireChart(
        _probeChart(<String, Object?>{'position': 'thisProbe'}),
      );
      _activate(chart);
      final t = _tooltipOf(chart);
      expect(self, same(t));
      expect(args, [true, 150]);
      expect(t.caretX, 10);
      expect(t.caretY, 20);
      expect(t.xAlign, 'left');
      expect(t.yAlign, 'top');
    });

    testWidgets('a result with xAlign and yAlign sets the alignment', (
      tester,
    ) async {
      // The probe output `pos_fixedAlign`: x 44.962890625, y 46.2, caretX
      // 100, caretY 100, xAlign right, yAlign bottom.
      Tooltip.positioners['fixedAlign'] = () => <String, Object?>{
        'x': 100,
        'y': 100,
        'xAlign': 'right',
        'yAlign': 'bottom',
      };
      addTearDown(() => Tooltip.positioners.remove('fixedAlign'));
      final chart = acquireChart(
        _probeChart(<String, Object?>{'position': 'fixedAlign'}),
      );
      _activate(chart);
      final t = _tooltipOf(chart);
      expect(t.xAlign, 'right');
      expect(t.yAlign, 'bottom');
      expect(t.caretX, 100);
      expect(t.caretY, 100);
      expect(t.x, closeTo(44.962890625, 1e-9));
      expect(t.y, closeTo(46.2, 1e-9));
    });

    testWidgets('a result {} gives no coordinates', (tester) async {
      // The probe output `pos_empty`: x NaN, y NaN, caretX and caretY
      // undefined, xAlign right, yAlign center.
      Tooltip.positioners['empty'] = () => <String, Object?>{};
      addTearDown(() => Tooltip.positioners.remove('empty'));
      final chart = acquireChart(
        _probeChart(<String, Object?>{'position': 'empty'}),
      );
      _activate(chart);
      final t = _tooltipOf(chart);
      expect(t.x, isNaN);
      expect(t.y, isNaN);
      expect(identical(t['caretX'], undefined), isTrue);
      expect(identical(t['caretY'], undefined), isTrue);
      expect(t.xAlign, 'right');
      expect(t.yAlign, 'center');
    });

    testWidgets('a string coordinate throws an ArgumentError', (tester) async {
      // Upstream stores it (the probe output `pos_strings`: caretX '100',
      // caretY '50', y 26.6). The write by name of caretX throws (Chart.js
      // ADR 0039, section 5).
      Tooltip.positioners['strings'] = () => <String, Object?>{
        'x': '100',
        'y': '50',
      };
      addTearDown(() => Tooltip.positioners.remove('strings'));
      final chart = acquireChart(
        _probeChart(<String, Object?>{'position': 'strings'}),
      );
      expect(() => _activate(chart), throwsA(isA<ArgumentError>()));
    });

    testWidgets('a JS null coordinate throws an ArgumentError', (tester) async {
      // Upstream stores null. A probe on the pinned build in Node.js
      // v24.12.0 on x64 with this positioner and `setActiveElements` gave no
      // throw, caretX null, caretY null, opacity 1, x 0, y 7, xAlign left,
      // yAlign top, width 66.037109375 and height 46.8. Without an
      // animation, the write by name of caretX in update throws after the
      // writes of opacity, x, y, width and height (Chart.js ADR 0039,
      // section 5).
      Tooltip.positioners['nulls'] = () => <String, Object?>{
        'x': null,
        'y': null,
      };
      addTearDown(() => Tooltip.positioners.remove('nulls'));
      final chart = acquireChart(
        _probeChart(<String, Object?>{'position': 'nulls'}),
      );
      expect(() => _activate(chart), throwsA(isA<ArgumentError>()));
      final t = _tooltipOf(chart);
      expect(t.x, 0);
      expect(t.y, closeTo(7, 1e-9));
      expect(t.width, closeTo(66.037109375, 1e-9));
      expect(t.height, closeTo(46.8, 1e-9));
      expect(t.xAlign, 'left');
      expect(t.yAlign, 'top');
      expect(identical(t['caretX'], undefined), isTrue);
    });

    testWidgets('a JS null coordinate throws in the animator update', (
      tester,
    ) async {
      // With `animation: {duration: 1000}`, the same probe gave the same
      // values after the first tick, and no throw. The port update does not
      // throw: the next update of the animator throws at the write of
      // Animation.tick (Chart.js ADR 0039, section 5). The test calls
      // animator.update and does not pump a frame: a throw in the frame
      // callback keeps `_request` set, and the animator then stops for the
      // later tests of the file. The remove keeps Chart.destroy from the
      // second throw of Animation.cancel.
      Tooltip.positioners['nulls'] = () => <String, Object?>{
        'x': null,
        'y': null,
      };
      addTearDown(() => Tooltip.positioners.remove('nulls'));
      final chart = acquireChart(
        _probeChart(
          <String, Object?>{'position': 'nulls'},
          <String, Object?>{
            'animation': <String, Object?>{'duration': 1000},
          },
        ),
      );
      _activate(chart);
      expect(animator.update, throwsA(isA<ArgumentError>()));
      expect(animator.remove(chart), isTrue);
    });

    test('average keeps the semantics of new Set()', () {
      // The probe outputs `averageNaN` {x: NaN, y: 1}, `averageZeros`
      // {x: 2, y: 1} and `averageMinusZero` {x: +0, y: 1}: the add step of
      // Set.prototype.add stores +0 for -0.
      final average = jsGet(Tooltip.positioners, 'average');
      Object? run(List<double> xs) => jsCall(average, [
        [
          for (final x in xs) <String, Object?>{'element': _FakeElement(x)},
        ],
      ]);
      final nan = run([double.nan, double.nan, 2])! as AnyObject;
      expect(nan['x'], isNaN);
      expect(nan['y'], 1);
      final zeros = run([0, -0.0, 4])! as AnyObject;
      expect(zeros['x'], 2);
      final minusZero = run([-0.0])! as AnyObject;
      expect(minusZero['x'], 0);
      expect((minusZero['x']! as double).isNegative, isFalse);
      expect(minusZero['y'], 1);
    });

    test('average of a plain item without element gives false', () {
      // The probe output `averagePlain`: false.
      final average = jsGet(Tooltip.positioners, 'average');
      expect(
        jsCall(average, [
          [
            <String, Object?>{'x': 1, 'y': 2},
          ],
        ]),
        false,
      );
    });
  });

  group('callbacks', () {
    for (final (name, callback, title, height)
        in <(String, Object?, List<Object?>, double)>[
          // The probe output `titleUndefined`: title [B], height 46.8.
          ('undefined takes the default', () => undefined, ['B'], 46.8),
          // The probe output `titleNull`: title [], height 26.4.
          ('null skips the default', () => null, [], 26.4),
          // The probe output `titleNumber`: title [5], height 46.8.
          ('a number is a line', () => 5.0, [5], 46.8),
          // The probe output `titleNoop`: title [B]. noop gives undefined.
          ('noop takes the default', noop, ['B'], 46.8),
        ]) {
      testWidgets('a title callback: $name', (tester) async {
        final chart = acquireChart(
          _probeChart(<String, Object?>{
            'callbacks': <String, Object?>{'title': callback},
          }),
        );
        _activate(chart);
        final t = _tooltipOf(chart);
        expect(t.title, title);
        expect(t.height, closeTo(height, 1e-9));
        // The probe outputs: width 66.037109375 for each case.
        expect(t.width, closeTo(66.037109375, 1e-9));
        expect(_bodyLines(t), [
          ['one: 20'],
        ]);
      });
    }

    test('labelTextColor without this throws a TypeError', () {
      // The probe output `labelTextColorNoThis`: TypeError.
      final callbacks =
          (tooltip['defaults']! as AnyObject)['callbacks']! as AnyObject;
      expect(
        () => jsCall(callbacks['labelTextColor'], const []),
        throwsA(isA<TypeError>()),
      );
    });

    testWidgets('a scatter chart keeps the raw label', (tester) async {
      // The probe outputs `scatter0` {label: 7, title: [7]} and `scatter1`
      // {label: '', title: []}.
      final chart = acquireChart(<String, Object?>{
        'type': 'scatter',
        'data': <String, Object?>{
          'labels': <Object?>[7, null],
          'datasets': <Object?>[
            <String, Object?>{
              'label': 's',
              'data': <Object?>[
                <String, Object?>{'x': 1, 'y': 1},
                <String, Object?>{'x': 2, 'y': 2},
              ],
            },
          ],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{'legend': false},
        },
      });
      final t = _tooltipOf(chart);
      _activate(chart, 0);
      expect(jsGet(t.dataPoints![0], 'label'), 7);
      expect(t.title, [7]);
      _activate(chart);
      expect(jsGet(t.dataPoints![0], 'label'), '');
      expect(t.title, isEmpty);
    });

    testWidgets('the dataset mode joins the label and the value', (
      tester,
    ) async {
      // The probe output `datasetMode`: title [d], body [['1: 10'],
      // ['undefined: 20']].
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': <Object?>[1, null],
          'datasets': <Object?>[
            <String, Object?>{
              'label': 'd',
              'data': <Object?>[10, 20],
            },
          ],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{
            'legend': false,
            'tooltip': <String, Object?>{'mode': 'dataset'},
          },
        },
      });
      final t = _tooltipOf(chart)
        ..setActiveElements(
          [
            <String, Object?>{'datasetIndex': 0, 'index': 0},
            <String, Object?>{'datasetIndex': 0, 'index': 1},
          ],
          _point(150, 100),
        );
      expect(t.title, ['d']);
      expect(_bodyLines(t), [
        ['1: 10'],
        ['undefined: 20'],
      ]);
    });

    testWidgets('the callbacks of a dataset override the label callbacks', (
      tester,
    ) async {
      // plugin.tooltip.js:356-359, :564 and :625. A probe on the pinned
      // build in Node.js v24.12.0 on x64 (this chart, the items [0, 1] and
      // [1, 1] at {x: 150, y: 100}):
      // title [B] (the dataset title is not used), body lines
      // [['one: 20'], ['D1 15']], before [[], ['pre']], labelTextColors
      // ['#fff', 'red'], width 66.037109375, height 79.6,
      // x 273.00732421875, y 207.09999999999997.
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': <Object?>['A', 'B', 'C'],
          'datasets': <Object?>[
            <String, Object?>{
              'label': 'one',
              'data': <Object?>[10, 20, 30],
            },
            <String, Object?>{
              'label': 'two',
              'data': <Object?>[5, 15, 25],
              'tooltip': <String, Object?>{
                'callbacks': <String, Object?>{
                  'label': (Object? item) =>
                      jsAdd('D1 ', jsGet(item, 'formattedValue')),
                  'beforeLabel': () => 'pre',
                  'labelTextColor': () => 'red',
                  'title': () => 'not used',
                },
              },
            },
          ],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{
            'legend': false,
            'tooltip': <String, Object?>{'mode': 'index', 'intersect': false},
          },
        },
      });
      final t = _tooltipOf(chart)
        ..setActiveElements([
          <String, Object?>{'datasetIndex': 0, 'index': 1},
          <String, Object?>{'datasetIndex': 1, 'index': 1},
        ], _point(150, 100));
      expect(t.title, ['B']);
      expect(_bodyLines(t), [
        ['one: 20'],
        ['D1 15'],
      ]);
      expect(jsGet(t.body![0], 'before'), isEmpty);
      expect(jsGet(t.body![1], 'before'), ['pre']);
      expect(t.labelTextColors, ['#fff', 'red']);
      expect(t.width, closeTo(66.037109375, 1e-9));
      expect(t.height, closeTo(79.6, 1e-9));
      expect(t.x, closeTo(273.00732421875, 1e-9));
      expect(t.y, closeTo(207.1, 1e-9));
    });
  });

  group('noop test', () {
    testWidgets('the helper gives the result of the two upstream calls', (
      tester,
    ) async {
      // Chart.js ADR 0039, section 8: the test of noop gives the result of
      // `callbacks[name].call(ctx, arg)` and, for an undefined result,
      // `defaultCallbacks[name].call(ctx, arg)`, for each of the 14 names.
      final chart = acquireChart(_probeChart());
      _activate(chart);
      final t = _tooltipOf(chart);
      final items = t.dataPoints!;
      final defaults =
          (tooltip['defaults']! as AnyObject)['callbacks']! as AnyObject;
      var userCalls = 0;
      Object? twoCalls(AnyObject callbacks, String name, Object? arg) {
        final result = jsCall1(callbacks[name], arg, thisArg: t);
        return identical(result, undefined)
            ? jsCall1(defaults[name], arg, thisArg: t)
            : result;
      }

      for (final name in _callbackNames) {
        final arg = _listCallbacks.contains(name) ? items : items[0];
        for (final (label, value) in <(String, Object?)>[
          ('noop', noop),
          ('a user function', () => 'user'),
          (
            'a function that returns undefined',
            () {
              userCalls++;
              return undefined;
            },
          ),
        ]) {
          final callbacks = <String, Object?>{name: value};
          userCalls = 0;
          final helper = invokeCallbackWithFallback(callbacks, name, t, arg);
          final helperCalls = userCalls;
          userCalls = 0;
          final upstream = twoCalls(callbacks, name, arg);
          expect(
            helper,
            jasmineEquals(upstream),
            reason: '$name: $label',
          );
          expect(helperCalls, userCalls, reason: '$name: $label: the calls');
        }
      }
    });

    testWidgets('a user title that is noop gives the default title', (
      tester,
    ) async {
      // The probe output `titleNoop`: title [B].
      final chart = acquireChart(
        _probeChart(<String, Object?>{
          'callbacks': <String, Object?>{'title': noop},
        }),
      );
      _activate(chart);
      expect(_tooltipOf(chart).title, ['B']);
    });
  });

  group('animations', () {
    testWidgets('an animated update starts the seven animations', (
      tester,
    ) async {
      // The probe output `animations`: the keys caretY, caretX, height,
      // width, y, x, opacity; `_cachedAnimations` undefined; `_cacheable`
      // false on the options and on `options.animations`.
      final chart = acquireChart(
        _probeChart(null, <String, Object?>{
          'animation': <String, Object?>{'duration': 1000},
        }),
      );
      final t = _tooltipOf(chart);
      _activate(chart);
      expect(t.$animations!.keys.toList(), [
        'caretY',
        'caretX',
        'height',
        'width',
        'y',
        'x',
        'opacity',
      ]);
      expect(identical(t['_cachedAnimations'], undefined), isTrue);
      final options =
          jsCall(
                jsGet(t.options, 'setContext'),
                [t.getContext()],
                thisArg: t.options,
              )!
              as AnyObject;
      expect(jsGet(options, '_cacheable'), false);
      expect(jsGet(jsGet(options, 'animations'), '_cacheable'), false);

      // After the end of the animations, $animations keeps its entries
      // (Chart.js ADR 0039, section 13 item 2).
      await pumpFrames(() => !animator.running(chart));
      expect(t.$animations!.containsKey('x'), isTrue);
      expect(t.$animations!['x']!.active(), isFalse);
      expect(t.opacity, 1);
    });

    test('options without a context cache and freeze the animations', () {
      // plugin.tooltip.js:518-520 runs only for options whose `_cacheable`
      // is truthy (js-semantics-object-freeze). A plain Map with a
      // `setContext` function stands for options without a context.
      final options = <String, Object?>{};
      options.addAll(<String, Object?>{
        'setContext': () => options,
        'enabled': true,
        'animations': <String, Object?>{'_cacheable': true},
      });
      final t = Tooltip((chart: _CacheChart(), options: null))
        ..initialize(options)
        ..['opacity'] = 1.0;
      t.update();
      final cached = t['_cachedAnimations'];
      expect(cached, isA<Animations>());
      expect(jsObjectIsFrozen(cached), isFalse);
      expect(t.opacity, 0);
      t
        ..['opacity'] = 1.0
        ..update();
      expect(t['_cachedAnimations'], same(cached));
      // initialize clears the cache.
      t.initialize(options);
      expect(identical(t['_cachedAnimations'], undefined), isTrue);
    });
  });

  group('adapt-animation-number-path', () {
    test('each numeric scenario on the tooltip x and y', () {
      final numeric = animationScenarioReference.where((s) => s.numeric);
      expect(numeric, isNotEmpty);
      for (final scenario in numeric) {
        for (final prop in ['x', 'y']) {
          _replay(
            scenario,
            target: _newTooltip(),
            prop: prop,
            label: 'Tooltip $prop',
          );
        }
      }
    });
  });

  group('draw order', () {
    List<String> drawOrder({bool cancel = false}) {
      final order = <String>[];
      final chart = acquireChart(<String, Object?>{
        ..._probeChart(),
        'plugins': <Object?>[
          <String, Object?>{
            'id': 'probe',
            'afterDatasetsDraw': (Object? c) {
              order.add('afterDatasetsDraw');
            },
            'beforeTooltipDraw': (Object? c, Object? args) {
              order.add(
                'beforeTooltipDraw '
                '${jsObjectKeys(args! as AnyObject).join(',')}',
              );
              return cancel ? false : undefined;
            },
            'afterTooltipDraw': (Object? c, Object? args) {
              order.add(
                'afterTooltipDraw '
                '${jsObjectKeys(args! as AnyObject).join(',')}',
              );
            },
            'afterDraw': (Object? c) {
              order.add('afterDraw');
            },
          },
        ],
      });
      _activate(chart);
      order.clear();
      chart.draw();
      return order;
    }

    testWidgets('the tooltip hooks come between the datasets and afterDraw', (
      tester,
    ) async {
      // The probe output `drawOrder`.
      expect(drawOrder(), [
        'afterDatasetsDraw',
        'beforeTooltipDraw tooltip,cancelable',
        'afterTooltipDraw tooltip',
        'afterDraw',
      ]);
    });

    testWidgets('false of beforeTooltipDraw cancels the draw', (
      tester,
    ) async {
      // plugin.tooltip.js:1254-1256: the return before the draw and
      // afterTooltipDraw.
      expect(drawOrder(cancel: true), [
        'afterDatasetsDraw',
        'beforeTooltipDraw tooltip,cancelable',
        'afterDraw',
      ]);
    });
  });

  group('options false', () {
    testWidgets('plugins.tooltip false gives no chart.tooltip', (
      tester,
    ) async {
      // The probe output `optionsFalse`: no tooltip, also after the enable
      // and update(): only afterInit writes chart.tooltip.
      final chart = acquireChart(_probeChart(false));
      expect(chart.tooltip, isNull);
      (jsGet(chart.options, 'plugins')! as AnyObject)['tooltip'] =
          <String, Object?>{};
      chart.update();
      expect(chart.tooltip, isNull);
    });
  });

  group('reset', () {
    testWidgets('the hook reset calls initialize', (tester) async {
      // plugin.tooltip.js:1240-1244: chart.reset() gives the plugin options
      // to initialize (:498-502), which writes options and clears $context.
      // A probe on the pinned build in Node.js v24.12.0 on x64 called
      // initialize({}), wrote `$context = {}` and called chart.reset(): the
      // options were the resolver of the plugin options again, and $context
      // was undefined.
      final chart = acquireChart(_probeChart());
      final t = _tooltipOf(chart);
      final options = t.options;
      t
        ..initialize(<String, Object?>{})
        ..[r'$context'] = <String, Object?>{};
      chart.reset();
      expect(identical(t.options, options), isTrue);
      expect(identical(t[r'$context'], undefined), isTrue);
    });
  });

  group('external', () {
    testWidgets('external gets the tooltip as this and replay', (
      tester,
    ) async {
      // The probe output `external`: [undefined, true,
      // 'chart,tooltip,replay'] for the mousemove, [true, ...] for the replay
      // of chart.update(), [undefined, ...] for setActiveElements.
      final entries = <String>[];
      final chart = acquireChart(
        _probeChart(<String, Object?>{
          'external': JsFunction((Object? self, Object? context) {
            entries.add(
              '${jsToString(jsGet(context, 'replay'))} '
              '${identical(jsGet(context, 'tooltip'), self)} '
              '${jsObjectKeys(context! as AnyObject).join(',')}',
            );
          }),
        }),
      );
      final point = chart.getDatasetMeta(0).data[1];
      await triggerMouseEvent(chart, 'mousemove', point);
      chart.update();
      _tooltipOf(chart).setActiveElements([
        <String, Object?>{'datasetIndex': 0, 'index': 2},
      ], _point(10, 10));
      expect(entries, [
        'undefined true chart,tooltip,replay',
        'true true chart,tooltip,replay',
        'undefined true chart,tooltip,replay',
      ]);
    });
  });

  group('setActiveElements', () {
    testWidgets('an index without an element throws after _active changed', (
      tester,
    ) async {
      // The probe output `index99`: TypeError (the read of the parsed item
      // in getLabelAndValue), `_active` with one item, index 99, element
      // undefined.
      final chart = acquireChart(_probeChart());
      final t = _tooltipOf(chart);
      expect(
        () => t.setActiveElements([
          <String, Object?>{'datasetIndex': 0, 'index': 99},
        ], _point(1, 1)),
        throwsA(isA<TypeError>()),
      );
      final active = t.getActiveElements();
      expect(active.length, 1);
      expect(active[0].index, 99);
      expect(active[0].element, isNull);
    });
  });

  group('adapt-active-elements-number-index', () {
    testWidgets('a string index becomes a number', (tester) async {
      // The probe output `stringIndex`: upstream keeps the index '1' (and
      // the dataIndex '1'), the title [B], the body [['D: 20']], one call
      // of update; a later call with the number 1 counts as a change (two
      // calls), and Chart.setActiveElements keeps '2'. The port reads the
      // number: the lines are the same, and the later call is no change.
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': <Object?>['A', 'B', 'C'],
          'datasets': <Object?>[
            <String, Object?>{
              'label': 'D',
              'data': <Object?>[10, 20, 30],
            },
          ],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{'legend': false},
        },
      });
      final t = _tooltipOf(chart);
      var calls = 0;
      final original = t.update;
      t.update = ([changed = undefined, replay = undefined]) {
        calls++;
        original(changed, replay);
      };
      _activate(chart, '1');
      final a = t.getActiveElements()[0];
      expect(a.index, 1.0);
      expect(jsGet(t.dataPoints![0], 'dataIndex'), 1.0);
      expect(t.title, ['B']);
      expect(_bodyLines(t), [
        ['D: 20'],
      ]);
      expect(calls, 1);
      _activate(chart);
      expect(calls, 1);

      chart.setActiveElements([
        <String, Object?>{'datasetIndex': 0, 'index': '2'},
      ]);
      expect(chart.getActiveElements()[0].index, 2.0);
    });
  });

  group('this of filter and itemSort', () {
    // plugin.tooltip.js:615 and :620 are method calls: `this` is the
    // options resolver. The expected values come from a probe of phase 8
    // (the pinned Chart.js build in Node.js v24.12.0 on x64), on the probe
    // chart with a second dataset `two`
    // (data 1, 2 and 3), mode index, intersect false, and the items
    // {datasetIndex: 0, index: 1} and {datasetIndex: 1, index: 1}.
    AnyObject twoDatasets(AnyObject tooltipOptions) {
      final config = _probeChart(tooltipOptions);
      ((config['data']! as AnyObject)['datasets']! as List<Object?>).add(
        <String, Object?>{
          'label': 'two',
          'data': <Object?>[1, 2, 3],
        },
      );
      return config;
    }

    void activateBoth(Chart chart) => _tooltipOf(chart).setActiveElements(
      [
        <String, Object?>{'datasetIndex': 0, 'index': 1},
        <String, Object?>{'datasetIndex': 1, 'index': 1},
      ],
      <String, Object?>{'x': 150, 'y': 100},
    );

    String position(Object? self) =>
        identical(self, undefined) ? 'undefined' : '${jsGet(self, 'position')}';

    testWidgets('filter and itemSort get the options as this', (tester) async {
      // The probe output `thisOfCallbacks`: [[filter, average], [filter,
      // average], [itemSort, average]].
      final seen = <List<String>>[];
      final chart = acquireChart(
        twoDatasets(<String, Object?>{
          'mode': 'index',
          'intersect': false,
          'filter': JsFunction(
            (Object? self, Object? a, Object? b, Object? c, Object? d) {
              seen.add(['filter', position(self)]);
              return true;
            },
          ),
          'itemSort': JsFunction(
            (Object? self, Object? a, Object? b, Object? c) {
              seen.add(['itemSort', position(self)]);
              return 0;
            },
          ),
        }),
      );
      activateBoth(chart);
      expect(seen, [
        ['filter', 'average'],
        ['filter', 'average'],
        ['itemSort', 'average'],
      ]);
    });

    testWidgets('a filter and an itemSort that read this', (tester) async {
      // The probe output `readsThis`: the data points [1, 0] and the body
      // [[two: 2], [one: 20]].
      final chart = acquireChart(
        twoDatasets(<String, Object?>{
          'mode': 'index',
          'intersect': false,
          'filter': JsFunction(
            (Object? self, Object? a, Object? b, Object? c, Object? d) =>
                jsGet(self, 'position') == 'average',
          ),
          'itemSort': JsFunction(
            (Object? self, Object? a, Object? b, Object? c) =>
                jsGet(self, 'mode') == 'index'
                ? jsToNumber(jsGet(b, 'datasetIndex')) -
                      jsToNumber(jsGet(a, 'datasetIndex'))
                : 0,
          ),
        }),
      );
      activateBoth(chart);
      final t = _tooltipOf(chart);
      expect(
        [for (final p in t.dataPoints!) jsGet(p, 'datasetIndex')],
        [
          1,
          0,
        ],
      );
      expect(_bodyLines(t), [
        ['two: 2'],
        ['one: 20'],
      ]);
    });
  });

  group('textDirection', () {
    // plugin.tooltip.js:1074 and :1087 (helpers.rtl.ts:55-73). The
    // reference cases `rtl` and `textDirection rtl` compare the style after
    // one draw (the probe `canvasDirection`). This group pins each style
    // call of two draws in a row. The expected values come from a
    // probe of phase 8 (the pinned Chart.js build in Node.js v24.12.0 on
    // x64): two draws of the probe chart after `setActiveElements`, on a
    // canvas style with the DOM rules of `setProperty`. The restore gives
    // the direction String as the `[value, priority]` pair, so its call
    // reads `'r'` and `'t'` (or `'l'` and `'t'`), and the DOM ignores it: the
    // override stays.
    List<List<String?>> drawTwice(Chart chart) {
      final t = _tooltipOf(chart);
      final ctx = _StyleContext();
      t
        ..draw(ctx)
        ..draw(ctx);
      return ctx.canvas.style.log;
    }

    for (final (direction, l) in [('rtl', 'r'), ('ltr', 'l')]) {
      testWidgets('textDirection $direction', (tester) async {
        // The probe output `textDirection.$direction`, the first and the
        // second draw.
        final chart = acquireChart(
          _probeChart(<String, Object?>{'textDirection': direction}),
        );
        _activate(chart);
        expect(drawTwice(chart), [
          ['get', 'direction', ''],
          ['prio', 'direction', ''],
          ['set', 'direction', direction, 'important'],
          ['set', 'direction', l, 't'],
          ['get', 'direction', direction],
          ['prio', 'direction', 'important'],
          ['set', 'direction', direction, 'important'],
          ['set', 'direction', l, 't'],
        ]);
      });
    }

    testWidgets('no textDirection leaves the style', (tester) async {
      // The probe output `textDirection.undefined`: no call.
      final chart = acquireChart(_probeChart());
      _activate(chart);
      expect(drawTwice(chart), isEmpty);
    });
  });

  group('input', () {
    testWidgets('the hit tests of the chart and of the tooltip differ', (
      tester,
    ) async {
      // Input spec section 4.3 item 1. The probe output `input`: at 6 px
      // right of the point, the chart has [[0, 1]] and the tooltip []; on
      // the point both have [[0, 1]].
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': <Object?>['A', 'B', 'C'],
          'datasets': <Object?>[
            <String, Object?>{
              'label': 'one',
              'data': <Object?>[10, 20, 30],
              'pointHoverRadius': 1,
              'pointRadius': 6,
              'pointHitRadius': 1,
            },
          ],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{'legend': false},
        },
      });
      final point = chart.getDatasetMeta(0).data[1];
      await triggerMouseEvent(chart, 'mousemove', _point(point.x + 6, point.y));
      expect(_pairs(chart.getActiveElements()), [
        [0, 1],
      ]);
      expect(_pairs(chart.tooltip!.getActiveElements()), isEmpty);

      await triggerMouseEvent(chart, 'mousemove', _point(point.x, point.y));
      expect(_pairs(chart.getActiveElements()), [
        [0, 1],
      ]);
      expect(_pairs(chart.tooltip!.getActiveElements()), [
        [0, 1],
      ]);

      // Input spec section 4.3 item 2. The probe output `input.outside` and
      // `input.mouseout`: an event outside the chart area keeps the items,
      // and mouseout empties them.
      await triggerMouseEvent(chart, 'mousemove', _point(1, 1));
      expect(_pairs(chart.getActiveElements()), [
        [0, 1],
      ]);
      expect(_pairs(chart.tooltip!.getActiveElements()), [
        [0, 1],
      ]);
      await triggerMouseEvent(chart, 'mouseout', _point(1, 1));
      expect(chart.getActiveElements(), isEmpty);
      expect(chart.tooltip!.getActiveElements(), isEmpty);
    });
  });
}

/// An active item `{datasetIndex, index, element}` of a test.
final class _Item implements types.ActiveElement {
  _Item({required this.datasetIndex, required this.index, this.element});

  @override
  final double datasetIndex;

  @override
  final double index;

  @override
  final types.Element? element;
}

/// A canvas style with the DOM rules of `setProperty` (as `_Style` of
/// test/port/helpers/helpers.rtl_test.dart). It logs each call with its
/// result, as the `domStyle` of the probe fix-node.mjs: `[get, name,
/// value]`, `[prio, name, priority]` and `[set, name, value, priority]`.
final class _LogStyle implements CSSStyleDeclaration {
  final Map<String, (String, String)> _properties = {};

  /// The calls.
  final List<List<String?>> log = [];

  static const _directions = {
    'ltr',
    'rtl',
    'inherit',
    'initial',
    'unset',
    'revert',
    'revert-layer',
  };

  @override
  String getPropertyValue(String property) {
    final value = _properties[property]?.$1 ?? '';
    log.add(['get', property, value]);
    return value;
  }

  @override
  String getPropertyPriority(String property) {
    final priority = _properties[property]?.$2 ?? '';
    log.add(['prio', property, priority]);
    return priority;
  }

  @override
  void setProperty(String property, String? value, [String? priority]) {
    log.add(['set', property, value, priority]);
    final important = priority?.toLowerCase() == 'important';
    if (priority != null && priority.isNotEmpty && !important) return;
    if (value == null || value.isEmpty) {
      _properties.remove(property);
      return;
    }
    if (property == 'direction' && !_directions.contains(value)) return;
    _properties[property] = (value, important ? 'important' : '');
  }
}

/// A canvas element that has only a [_LogStyle].
final class _StyleCanvas implements HTMLCanvasElement {
  @override
  final _LogStyle style = _LogStyle();

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A mock context whose canvas has a [_LogStyle].
final class _StyleContext extends MockContext {
  @override
  final _StyleCanvas canvas = _StyleCanvas();
}
