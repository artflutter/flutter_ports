// Original code, not ported from Chart.js: subtitle plugin reference tests.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' show FontWeight;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/light_theme.dart';
import '../../support/plugin_options_plain.dart';
import '../controllers/controller_chart_harness.dart'
    show expectNoStaleScaleKeys;
import '../scales/scale_chart_harness.dart';
import 'plugin_chart_harness.dart';
import 'plugin_subtitle_reference.dart';

// The port-only reference tests of lib/src/plugins/plugin.subtitle.dart
// (Chart.js ADR 0041, section 3). The spec port is
// test/specs/plugin.subtitle_test.dart (the fixture group only).
//
// The reference group compares real charts with the charts of
// tool/reference/plugin_subtitle_reference.mjs: a build of the pinned
// Chart.js in Node.js v24.22.1 on arm64 (Chart.js ADR 0146), with the seven
// plugins registered and `colors.enabled: false` in the defaults. Each case
// is a unit case (the plugins other than `subtitle` and `title` are `false`,
// Chart.js ADR 0041, section 4), except the full case
// `full: subtitle, title and legend`, which has the default plugin options
// (section 4 item 2). The observation has `boxes`,
// `plugins.subtitle` and `plugins.title` (the line count and the resolved
// options of each box), and the draw calls.
//
// The cases run two times: unthemed, and with the light preset (theming.md
// section 8 test 3). In the themed run, the colors compare in their parsed
// form, and the options compare only the keys of upstream.
//
// The groups `plugin object` and `the subtitle map` hold the pin tests of
// Chart.js ADR 0038, sections 5 and 11. The expected results come from a
// probe on the pinned build in Node.js v24.12.0 on x64
// (controller_chart_common.mjs: loadChartJs, registerBuiltins, makeChart).
// The probe read `registry.getPlugin('subtitle')` and logged its keys,
// `defaults`, `defaultRoutes`, `descriptors` and the `length` of `start`,
// `stop` and `beforeUpdate` (`hookLengths`: 3, 1 and 3). It made line
// charts with `plugins.subtitle` and the plugins other than `subtitle` and
// `title` off, and logged the count and the `options.text` of the subtitle
// boxes (each `Title` box that is not `chart.titleBlock`):
// - `twoCharts` [1, 1, true, 'A', 'B']: two charts with the texts A and B,
//   one box each, not the same box.
// - `afterStop` 0 and `otherAfterStop` [1, 'B']: chart A after
//   `plugins.subtitle = false` and `update()`; chart B keeps its box.
// - `afterRestart` [1, true, 'A2']: chart A after `plugins.subtitle =
//   {display: true, text: 'A2'}` and `update()`; a new box.
// - `stopWithoutStart` [3, 3]: `plugin.stop(chart)` on a chart without a
//   subtitle; the box count before and after.
// - `beforeUpdateWithoutStart`: `plugin.beforeUpdate(chart, {}, {})` on the
//   same chart throws `TypeError: Cannot set properties of undefined
//   (setting 'fullSize')`.
// - `startStopStartDirect` [1, 0, 1, 2, 1]: the subtitle box count after
//   the direct calls start x, stop, start y, start z and stop.
// A second probe called `plugin.stop(chart)` on a chart with a subtitle and
// then `plugin.beforeUpdate(chart, {}, {})`. Its output: {before: 4,
// afterStop: 3, beforeUpdateAfterStop: TypeError} (the same message).

/// The subtitle boxes of [chart]: each `Title` box of `chart.boxes` that is
/// not `chart.titleBlock`. The subtitle `Expando` is file-private (Chart.js
/// ADR 0038, section 5).
List<Title> _subtitles(Chart chart) => [
  for (final box in chart.boxes)
    if (box is Title && !identical(box, chart.titleBlock)) box,
];

/// `{lines, options}` of the title box [box], or Dart `null` without a box
/// (`observeBox` of the generator). `lines` is the `lineCount` of
/// plugin.title.js:43, and `options` is the plain copy of the resolved
/// options of the box.
Object? _observeBox(LayoutItem? box) {
  if (box == null) return null;
  final options = (box as Title).options!;
  return <String, Object?>{
    'lines': options.text!.length.toDouble(),
    'options': plainTitleOptions(options),
  };
}

/// The observer `plugins.subtitle` of the generator (`observeSubtitle`).
Object? _observeSubtitle(Chart chart) {
  final boxes = _subtitles(chart);
  expect(boxes.length, lessThanOrEqualTo(1), reason: 'one subtitle box');
  return _observeBox(boxes.isEmpty ? null : boxes.single);
}

/// The observer `plugins.title` of the generator (`observeTitle`).
Object? _observeTitle(Chart chart) => _observeBox(chart.titleBlock);

/// The observers of the cases.
final Map<String, Object? Function(Chart chart)> _observers = {
  'subtitle': _observeSubtitle,
  'title': _observeTitle,
};

/// The hook keys of the default export of plugin.subtitle.js:6-53, in the
/// order of `PluginHook` (the probe output `keys`: `id`, these hooks,
/// `defaults`, `defaultRoutes` and `descriptors`). No `_element`.
const List<String> _upstreamHooks = ['start', 'stop', 'beforeUpdate'];

/// A line chart whose subtitle plugin is disabled when [subtitle] is null.
Chart _lineWithSubtitle([SubtitleOptions? subtitle]) => acquireChartRoot(
  ChartConfigLowering(
    ChartConfig(
      labels: const ['a', 'b'],
      datasets: const [
        LineDataset(data: .values([1, 2])),
      ],
      pluginOptions: [?subtitle],
      disabledPlugins: subtitle == null
          ? const [PluginOff<SubtitlePlugin>()]
          : null,
    ),
  ).lower(),
);

/// A line chart with a subtitle of the one line [text].
Chart _line(String text) => acquireChartRoot(
  ChartConfigLowering(
    ChartConfig(
      labels: const ['a', 'b'],
      datasets: const [
        LineDataset(data: .values([1, 2])),
      ],
      pluginOptions: [
        SubtitleOptions(display: true, text: [text]),
      ],
    ),
  ).lower(),
);

/// The options of a direct `start` call: the box reads `display`, `text`,
/// `position`, `weight` and `fullSize`.
SubtitleOptions _startOptions(String text) => SubtitleOptions(
  display: true,
  text: [text],
  position: ChartPosition.top,
  weight: 1500,
  fullSize: true,
);

/// `plugin.<hook>(chart, args, options)`: the hook field [hook] of the
/// native plugin (Chart.js ADR 0144) with the arguments of its hook. The
/// hooks of the subtitle take the merged [SubtitleOptions] (Chart.js ADR
/// 0197): [options], or the options with no field, the `{}` that the probe
/// gave.
void _hook(String hook, Chart chart, [SubtitleOptions? options]) {
  final view = options ?? const SubtitleOptions();
  switch (hook) {
    case 'start':
      subTitle.start!(chart, const PluginHookArgs(), view);
    case 'stop':
      subTitle.stop!(chart, const PluginHookArgs(), view);
    case 'beforeUpdate':
      subTitle.beforeUpdate!(chart, UpdateHookArgs(), view);
    default:
      throw ArgumentError.value(hook, 'hook');
  }
}

/// `chart.options.plugins` of [chart], the option resolver of the plugins.
JsObjectFace _pluginOptions(Chart chart) =>
    jsGet(chart.options, 'plugins')! as JsObjectFace;

void main() {
  testReferenceOrigin(
    node: pluginSubtitleReferenceNode,
    arch: pluginSubtitleReferenceArch,
    dist: pluginSubtitleReferenceDist,
    commit: pluginSubtitleReferenceCommit,
  );
  testReferenceWidths(pluginSubtitleReferenceWidths);

  test('the reference has the unit cases of Chart.js ADR 0041', () {
    expect(
      [for (final c in pluginSubtitleReference) c.name],
      [
        'alone',
        'with a title',
        'position left',
        'display false (the default)',
        'padding',
        'a text array with font, color and align',
        'full: subtitle, title and legend',
      ],
    );
  });

  testPluginChartCases(pluginSubtitleReference, observers: _observers);

  group('theming.md §8 test 3: the light preset', () {
    testPluginChartCases(
      pluginSubtitleReference,
      observers: _observers,
      theme: compileLightTheme(),
    );

    testWidgets('the light preset leaves no stale scale key', (tester) async {
      final snapshot = jsonDecode(
        File('test/port/theme/light_snapshot.json').readAsStringSync(),
      ) as Map<String, Object?>;
      expectNoStaleScaleKeys(
        acquireReferenceChart(
          pluginSubtitleReference.first.config,
          const AcquireOptions(),
          theme: compileLightTheme(),
        ),
        snapshot,
      );
    });
  });

  group('plugin object', () {
    test('the hooks and the fields are the upstream keys', () {
      // The native plugin of Chart.js ADR 0144: the hook keys of the upstream
      // object are its hooks, and `id` and `defaults` its fields. The
      // `defaultRoutes` and the `descriptors` have no field: the plugin
      // gives the color of the route itself (Chart.js ADR 0197).
      expect(pluginHookNames(subTitle), _upstreamHooks);
      expect(subTitle.id, 'subtitle');
      expect(subTitle.defaults, isNotNull);
      expect(subTitle.defaultRoutes, isNull);
      expect(subTitle.descriptors, isNull);
    });

    test('the registry gives the plugin object', () {
      expect(registry.getPlugin<SubtitlePlugin>(), same(subTitle));
    });

    test('the hooks are typed hook functions', () {
      // The probe output `hookLengths`: start 3, stop 1, beforeUpdate 3.
      // Each hook is a function of the hook type `(chart, args, options)`,
      // in place of the upstream parameter counts of Chart.js ADR 0038,
      // section 3: `fn.length` of a hook changes no behavior of Chart.js.
      // A hook takes the argument class of its hook and the merged
      // [SubtitleOptions] (Chart.js ADR 0197). The `Never` parameter type of
      // the `isNot` matcher rejects each function with one more parameter.
      for (final (hook, function) in <(String, Function?)>[
        ('start', subTitle.start),
        ('stop', subTitle.stop),
      ]) {
        expect(
          function,
          isA<void Function(IChart, PluginHookArgs, SubtitleOptions)>(),
          reason: hook,
        );
        expect(
          function,
          isNot(
            isA<
              void Function(IChart, PluginHookArgs, SubtitleOptions, Never)
            >(),
          ),
          reason: hook,
        );
      }
      expect(
        subTitle.beforeUpdate,
        isA<bool Function(IChart, UpdateHookArgs, SubtitleOptions)>(),
      );
    });

    test('the defaults have the upstream keys and values', () {
      // The probe output `defaults` (plugin.subtitle.js:32-43), one
      // SubtitleOptions (Chart.js ADR 0197).
      expect(
        subTitle.defaults,
        const SubtitleOptions(
          align: ChartAlign.center,
          display: false,
          font: ChartTextStyle(fontWeight: FontWeight.normal),
          fullSize: true,
          padding: EdgeInsets.zero,
          position: ChartPosition.top,
          text: [''],
          weight: 1500,
        ),
      );
    });

    testWidgets('the color routes to Chart.defaults.color', (tester) async {
      // The probe output `defaultRoutes` {color: 'color'}: the box of a chart
      // whose options set no color gets `Chart.defaults.color` (Chart.js ADR
      // 0197).
      final chart = _line('A');
      expect(
        _subtitles(chart).single.options!.color,
        Chart.defaults.colorCell!.raw,
      );
    });
  });

  group('the subtitle map', () {
    testWidgets('stop, then start through the options gives one subtitle '
        'box each time', (tester) async {
      // The probe outputs `afterStop` 0 and `afterRestart` [1, true, 'A2'].
      final chart = _lineWithSubtitle(
        const SubtitleOptions(display: true, text: ['A']),
      );
      final first = _subtitles(chart);
      expect(first, hasLength(1));
      expect(first.single.options!.text, ['A']);

      _pluginOptions(chart)['subtitle'] = false;
      chart.update();
      expect(_subtitles(chart), isEmpty);

      _pluginOptions(chart)['subtitle'] = const SubtitleOptions(
        display: true,
        text: ['A2'],
      );
      chart.update();
      final second = _subtitles(chart);
      expect(second, hasLength(1));
      expect(second.single, isNot(same(first.single)));
      expect(second.single.options!.text, ['A2']);
    });

    testWidgets('two charts each have their own subtitle', (tester) async {
      // The probe outputs `twoCharts` [1, 1, true, 'A', 'B'] and
      // `otherAfterStop` [1, 'B'].
      final a = _line('A');
      final b = _line('B');
      expect(_subtitles(a), hasLength(1));
      expect(_subtitles(b), hasLength(1));
      expect(_subtitles(a).single, isNot(same(_subtitles(b).single)));
      expect(_subtitles(a).single.options!.text, ['A']);
      expect(_subtitles(b).single.options!.text, ['B']);

      final boxOfB = _subtitles(b).single;
      _hook('stop', a);
      expect(_subtitles(a), isEmpty);
      expect(_subtitles(b), [same(boxOfB)]);
      expect(boxOfB.options!.text, ['B']);
    });

    testWidgets('stop without start does not throw', (tester) async {
      // The probe output `stopWithoutStart` [3, 3]: the boxes stay.
      final chart = _lineWithSubtitle();
      expect(_subtitles(chart), isEmpty);
      final boxes = [...chart.boxes];
      _hook('stop', chart);
      expect(chart.boxes, boxes);
    });

    testWidgets('beforeUpdate without start throws a TypeError', (
      tester,
    ) async {
      // The probe output `beforeUpdateWithoutStart`: TypeError, the write
      // of `fullSize` into undefined (core.layouts.js:332).
      final chart = _lineWithSubtitle();
      expect(() => _hook('beforeUpdate', chart), throwsA(isA<TypeError>()));
    });

    testWidgets('stop deletes the map entry: beforeUpdate then throws a '
        'TypeError', (tester) async {
      // The output of the second probe: {before: 4, afterStop: 3,
      // beforeUpdateAfterStop: TypeError} (map.delete of
      // plugin.subtitle.js:23).
      final chart = _line('A');
      final count = chart.boxes.length;
      _hook('stop', chart);
      expect(chart.boxes, hasLength(count - 1));
      expect(() => _hook('beforeUpdate', chart), throwsA(isA<TypeError>()));
    });

    testWidgets('direct start and stop keep only the last box in the map', (
      tester,
    ) async {
      // The probe output `startStopStartDirect` [1, 0, 1, 2, 1]: a second
      // start without stop adds a second box, and stop removes only the box
      // of the last start (map.set replaces the entry).
      final chart = _lineWithSubtitle();
      final counts = <int>[];
      _hook('start', chart, _startOptions('x'));
      counts.add(_subtitles(chart).length);
      _hook('stop', chart);
      counts.add(_subtitles(chart).length);
      _hook('start', chart, _startOptions('y'));
      counts.add(_subtitles(chart).length);
      _hook('start', chart, _startOptions('z'));
      counts.add(_subtitles(chart).length);
      _hook('stop', chart);
      counts.add(_subtitles(chart).length);
      expect(counts, [1, 0, 1, 2, 1]);
      expect(_subtitles(chart).single.options!.text, ['y']);
    });

    testWidgets('the subtitle box is a Title of the chart', (tester) async {
      // plugin.subtitle.js:10-17: the box gets the context and the chart,
      // and `configure` writes the position, the weight and fullSize of the
      // defaults (plugin.subtitle.js:32-43).
      final chart = _line('A');
      final subtitle = _subtitles(chart).single;
      expect(subtitle.position, ChartPosition.top);
      expect(subtitle.weight, 1500);
      expect(subtitle.fullSize, isTrue);
      expect(subtitle.ctx, same(chart.ctx));
      expect(subtitle.chart, same(chart));
    });
  });
}
