// Original code, not ported from Chart.js: subtitle plugin reference tests.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart'
    show themeConfigKey;
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.registry.dart' show registry;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.subtitle.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.title.dart';
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/theme/presets.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../controllers/controller_chart_harness.dart'
    show expectNoStaleScaleKeys, plainValue;
import '../scales/scale_chart_harness.dart';
import 'plugin_chart_harness.dart';
import 'plugin_subtitle_reference.dart';

// The port-only reference tests of lib/src/plugins/plugin.subtitle.dart
// (Chart.js ADR 0041, section 3). The spec port is
// test/specs/plugin.subtitle_test.dart (the fixture group only).
//
// The reference group compares real charts with the charts of
// tool/reference/plugin_subtitle_reference.mjs: a build of the pinned
// Chart.js in Node.js v24.12.0 on x64 (Chart.js ADR 0032), with the seven
// plugins registered and `colors.enabled: false` in the defaults. Each case
// is a unit case: the plugins other than `subtitle` and `title` are `false`
// (Chart.js ADR 0041, section 4). The observation has `boxes`,
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
Object? _observeBox(types.LayoutItem? box) {
  if (box == null) return null;
  final text = jsGet(box.options, 'text');
  return <String, Object?>{
    'lines': text is List ? text.length.toDouble() : 1.0,
    'options': plainValue(box.options),
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

/// The keys of the default export of plugin.subtitle.js:6-53, in their
/// order (the probe output `keys`). No `_element`.
const List<String> _upstreamKeys = [
  'id',
  'start',
  'stop',
  'beforeUpdate',
  'defaults',
  'defaultRoutes',
  'descriptors',
];

/// A line chart with the subtitle options [subtitleOptions] and the
/// plugins other than `subtitle` and `title` off.
AnyObject _line(Object? subtitleOptions) => <String, Object?>{
  'type': 'line',
  'data': <String, Object?>{
    'labels': <Object?>['a', 'b'],
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[1, 2],
      },
    ],
  },
  'options': <String, Object?>{
    'plugins': <String, Object?>{'subtitle': subtitleOptions},
  },
};

/// The resolved options of a direct `start` call: the box reads `display`,
/// `text`, `position`, `weight` and `fullSize`.
AnyObject _startOptions(String text) => <String, Object?>{
  'display': true,
  'text': text,
  'position': 'top',
  'weight': 1500,
  'fullSize': true,
};

/// `plugin.<hook>(chart, {}, options)` through the plugin Map.
void _hook(String hook, Chart chart, [AnyObject? options]) {
  jsCall(subTitle[hook], [
    chart,
    <String, Object?>{},
    options ?? <String, Object?>{},
  ]);
}

/// `chart.options.plugins` of [chart], the option resolver of the plugins.
AnyObject _pluginOptions(Chart chart) =>
    jsGet(chart.options, 'plugins')! as AnyObject;

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
      theme: compileChartTheme(ChartThemes.light),
    );

    testWidgets('the light preset leaves no stale scale key', (tester) async {
      final snapshot = jsonDecode(
        File('test/port/theme/light_snapshot.json').readAsStringSync(),
      ) as Map<String, Object?>;
      final config =
          copyReference(pluginSubtitleReference.first.config)! as AnyObject;
      config[themeConfigKey] = compileChartTheme(ChartThemes.light);
      expectNoStaleScaleKeys(acquireChart(config), snapshot);
    });
  });

  group('plugin object', () {
    test('the keys are the upstream keys, with no _element', () {
      expect(jsObjectKeys(subTitle), _upstreamKeys);
      expect(subTitle.containsKey('_element'), isFalse);
    });

    test('the registry gives the plugin Map', () {
      expect(registry.getPlugin('subtitle'), same(subTitle));
    });

    test('the hooks have the upstream parameter counts', () {
      // The probe output `hookLengths`: start 3, stop 1, beforeUpdate 3.
      // jsCall gives a closure as many arguments as it takes, so the
      // closure arity is the JS `length` (Chart.js ADR 0038, section 3).
      // A closure with more optional parameters also matches the shorter
      // function type. The `Never` parameter type of the `isNot` matcher
      // rejects each closure with one more parameter.
      expect(subTitle['stop'], isA<void Function(types.Chart)>());
      expect(subTitle['stop'], isNot(isA<void Function(types.Chart, Never)>()));
      for (final hook in ['start', 'beforeUpdate']) {
        expect(
          subTitle[hook],
          isA<void Function(types.Chart, AnyObject, AnyObject)>(),
          reason: hook,
        );
        expect(
          subTitle[hook],
          isNot(isA<void Function(types.Chart, AnyObject, AnyObject, Never)>()),
          reason: hook,
        );
      }
    });

    test('the defaults have the upstream keys and values', () {
      // The probe output `defaults`, `defaultRoutes` and `descriptors`.
      final defaults = subTitle['defaults']! as AnyObject;
      expect(jsObjectKeys(defaults), [
        'align',
        'display',
        'font',
        'fullSize',
        'padding',
        'position',
        'text',
        'weight',
      ]);
      expect(defaults['align'], 'center');
      expect(defaults['display'], isFalse);
      expect(defaults['font'], <String, Object?>{'weight': 'normal'});
      expect(defaults['fullSize'], isTrue);
      expect(defaults['padding'], 0);
      expect(defaults['position'], 'top');
      expect(defaults['text'], '');
      expect(defaults['weight'], 1500);
      expect(subTitle['defaultRoutes'], <String, Object?>{'color': 'color'});
      expect(subTitle['descriptors'], <String, Object?>{
        '_scriptable': true,
        '_indexable': false,
      });
    });
  });

  group('the subtitle map', () {
    testWidgets('stop, then start through the options gives one subtitle '
        'box each time', (tester) async {
      // The probe outputs `afterStop` 0 and `afterRestart` [1, true, 'A2'].
      final chart = acquireChart(
        _line(<String, Object?>{'display': true, 'text': 'A'}),
      );
      final first = _subtitles(chart);
      expect(first, hasLength(1));
      expect(jsGet(first.single.options, 'text'), 'A');

      _pluginOptions(chart)['subtitle'] = false;
      chart.update();
      expect(_subtitles(chart), isEmpty);

      _pluginOptions(chart)['subtitle'] = <String, Object?>{
        'display': true,
        'text': 'A2',
      };
      chart.update();
      final second = _subtitles(chart);
      expect(second, hasLength(1));
      expect(second.single, isNot(same(first.single)));
      expect(jsGet(second.single.options, 'text'), 'A2');
    });

    testWidgets('two charts each have their own subtitle', (tester) async {
      // The probe outputs `twoCharts` [1, 1, true, 'A', 'B'] and
      // `otherAfterStop` [1, 'B'].
      final a = acquireChart(
        _line(<String, Object?>{'display': true, 'text': 'A'}),
      );
      final b = acquireChart(
        _line(<String, Object?>{'display': true, 'text': 'B'}),
      );
      expect(_subtitles(a), hasLength(1));
      expect(_subtitles(b), hasLength(1));
      expect(_subtitles(a).single, isNot(same(_subtitles(b).single)));
      expect(jsGet(_subtitles(a).single.options, 'text'), 'A');
      expect(jsGet(_subtitles(b).single.options, 'text'), 'B');

      final boxOfB = _subtitles(b).single;
      _hook('stop', a);
      expect(_subtitles(a), isEmpty);
      expect(_subtitles(b), [same(boxOfB)]);
      expect(jsGet(boxOfB.options, 'text'), 'B');
    });

    testWidgets('stop without start does not throw', (tester) async {
      // The probe output `stopWithoutStart` [3, 3]: the boxes stay.
      final chart = acquireChart(_line(false));
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
      final chart = acquireChart(_line(false));
      expect(() => _hook('beforeUpdate', chart), throwsA(isA<TypeError>()));
    });

    testWidgets('stop deletes the map entry: beforeUpdate then throws a '
        'TypeError', (tester) async {
      // The output of the second probe: {before: 4, afterStop: 3,
      // beforeUpdateAfterStop: TypeError} (map.delete of
      // plugin.subtitle.js:23).
      final chart = acquireChart(
        _line(<String, Object?>{'display': true, 'text': 'A'}),
      );
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
      final chart = acquireChart(_line(false));
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
      expect(jsGet(_subtitles(chart).single.options, 'text'), 'y');
    });

    testWidgets('the subtitle box is a Title of the chart', (tester) async {
      // plugin.subtitle.js:10-17: the box gets the context and the chart,
      // and `configure` writes the position, the weight and fullSize of the
      // defaults (plugin.subtitle.js:32-43).
      final chart = acquireChart(
        _line(<String, Object?>{'display': true, 'text': 'A'}),
      );
      final subtitle = _subtitles(chart).single;
      expect(subtitle.position, 'top');
      expect(subtitle.weight, 1500);
      expect(subtitle.fullSize, isTrue);
      expect(subtitle.ctx, same(chart.ctx));
      expect(subtitle.chart, same(chart));
    });
  });
}
