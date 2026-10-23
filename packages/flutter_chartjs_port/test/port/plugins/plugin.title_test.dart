// Original code, not ported from Chart.js: title plugin reference tests.
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
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsToString;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.title.dart';
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/theme/presets.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart' show TRBL;
import 'package:flutter_test/flutter_test.dart';

import '../controllers/controller_chart_harness.dart'
    show expectNoStaleScaleKeys, plainValue;
import '../scales/scale_chart_harness.dart';
import 'plugin_chart_harness.dart';
import 'plugin_title_reference.dart';

// The port-only reference tests of lib/src/plugins/plugin.title.dart
// (Chart.js ADR 0041, section 3). The spec port is
// test/specs/plugin.title_test.dart.
//
// The reference group compares real charts with the charts of
// tool/reference/plugin_title_reference.mjs: a build of the pinned Chart.js
// in Node.js v24.12.0 on x64 (Chart.js ADR 0032), with the seven plugins
// registered and `colors.enabled: false` in the defaults. Each case is a
// unit case: the other plugins are `false` (Chart.js ADR 0041, section 4).
// The observation has `boxes` and `plugins.title` (the line count and the
// resolved options of the title block), and the draw calls.
//
// The cases run two times: unthemed, and with the light preset (theming.md
// section 8 test 3). In the themed run, the colors compare in their parsed
// form, and the options compare only the keys of upstream.
//
// The groups `class value`, `start state`, `stop` and
// `adapt-component-class-role` hold the pin tests of Chart.js ADR 0038,
// section 11. The expected results come from a probe on the pinned build in
// Node.js v24.12.0 on x64 (controller_chart_common.mjs: loadChartJs,
// registerBuiltins, makeChart). The probe read `registry.getPlugin('title')`
// and its `_element` (the class `Title`), called the constructor with bad
// arguments, read the start values, and called `draw`, `update`, `stop` and
// `beforeUpdate` on a line chart with all plugins off. It logged:
// - `keys`: id, _element, start, stop, beforeUpdate, defaults,
//   defaultRoutes, descriptors. `superIsElement` true, `staticKeys` [].
// - `newNoArg`, `newUndefined` and `newNull`: each throws a TypeError.
//   `newChart5` 5, `newOptions5` 5 and `newCtxString` 'x': the constructor
//   stores the value.
// - `start`: top, bottom, left, right, width, height, position, weight,
//   fullSize and _padding are all undefined.
// - `drawBeforeUpdate`, `updateNullOptions` and `isHorizontalNoOptions`:
//   each throws a TypeError.
// - `updateWithMargins` [0, 0, 300, 100, 300, 34.4]: `update(300, 100,
//   margins)` ignores the margins.
// - `noTitle` [true, 0] (no titleBlock, no box), `stopWithoutBlock` 0 (no
//   throw), `beforeUpdateWithoutBlock` throws a TypeError.

/// The named functions of the configs of the generator, with the same
/// bodies.
final Map<String, Object?> _functions = {
  // (ctx) => `Chart of type ${ctx.chart.config.type}`
  'titleText': (Object? ctx) =>
      'Chart of type '
      '${jsToString((jsGet(ctx, 'chart')! as Chart).config.type)}',
};

/// The observer `plugins.title` of the generator (`observeTitle`): Dart
/// `null` without a title block, else `{lines, options}`. `lines` is the
/// `lineCount` of plugin.title.js:43, and `options` is the plain copy of the
/// resolved options of the box.
Object? _observeTitle(Chart chart) {
  final titleBlock = chart.titleBlock;
  if (titleBlock == null) return null;
  final text = jsGet(titleBlock.options, 'text');
  return <String, Object?>{
    'lines': text is List ? text.length.toDouble() : 1.0,
    'options': plainValue(titleBlock.options),
  };
}

/// The keys of the default export of plugin.title.js:120-166, in their
/// order (the probe output `keys`).
const List<String> _upstreamKeys = [
  'id',
  '_element',
  'start',
  'stop',
  'beforeUpdate',
  'defaults',
  'defaultRoutes',
  'descriptors',
];

/// `new Title(config)` through the class value.
Object? _construct(List<Object?> args) => jsConstruct(Title.jsClass, args);

/// A line chart with the title options [titleOptions] and every other
/// plugin off.
AnyObject _line(Object? titleOptions) => <String, Object?>{
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
    'plugins': <String, Object?>{'title': titleOptions},
  },
};

void main() {
  testReferenceOrigin(
    node: pluginTitleReferenceNode,
    arch: pluginTitleReferenceArch,
    dist: pluginTitleReferenceDist,
    commit: pluginTitleReferenceCommit,
  );
  testReferenceWidths(pluginTitleReferenceWidths);

  test('the reference has the unit cases of Chart.js ADR 0041', () {
    expect(
      [for (final c in pluginTitleReference) c.name],
      [
        'display false (the default)',
        'display true',
        'position bottom',
        'position left with align start',
        'position left with align end',
        'position right with align start',
        'position right with align end',
        'align start and end',
        'align end and start',
        'fullSize false',
        'padding as a number',
        'padding as an object',
        'a text array',
        'font and color',
        'a scriptable text',
        'a number text',
        'full: title with the default legend',
      ],
    );
  });

  testPluginChartCases(
    pluginTitleReference,
    observers: {'title': _observeTitle},
    functions: _functions,
  );

  group('theming.md §8 test 3: the light preset', () {
    testPluginChartCases(
      pluginTitleReference,
      observers: {'title': _observeTitle},
      functions: _functions,
      theme: compileChartTheme(ChartThemes.light),
    );

    testWidgets('the light preset leaves no stale scale key', (tester) async {
      final snapshot = jsonDecode(
        File('test/port/theme/light_snapshot.json').readAsStringSync(),
      ) as Map<String, Object?>;
      final config =
          copyReference(pluginTitleReference.first.config, _functions)!
              as AnyObject;
      config[themeConfigKey] = compileChartTheme(ChartThemes.light);
      expectNoStaleScaleKeys(acquireChart(config), snapshot);
    });
  });

  group('class value', () {
    test('the superclass is Element.jsClass', () {
      expect(Title.jsClass.superclass, same(Element.jsClass));
    });

    test('the plugin entry _element is Title.jsClass', () {
      expect(
        jsGet(registry.getPlugin('title'), '_element'),
        same(Title.jsClass),
      );
      expect(title['_element'], same(Title.jsClass));
    });

    test('new Title(config) keeps a plain chart object', () {
      final chart = <String, Object?>{'options': <String, Object?>{}};
      final options = <String, Object?>{'display': true, 'text': 'a'};
      final constructed = _construct([
        <String, Object?>{'chart': chart, 'options': options},
      ]);
      expect(constructed, isA<Title>());
      final value = constructed! as Title;
      expect(value.chart, same(chart));
      expect(value.options, same(options));
      expect(value.ctx, isNull);
    });

    test('new Title() and new Title(undefined) throw a TypeError', () {
      // Upstream: the read config.chart of undefined (probe: newNoArg,
      // newUndefined, newNull).
      expect(() => _construct(const []), throwsA(isA<TypeError>()));
      expect(() => _construct([undefined]), throwsA(isA<TypeError>()));
      expect(() => _construct([null]), throwsA(isA<TypeError>()));
    });

    test('the keys of the plugin object are the upstream keys', () {
      expect(jsObjectKeys(title), _upstreamKeys);
    });
  });

  group('start state', () {
    test('a new Title has the start values of plugin.title.js:17-26', () {
      final box = Title((chart: null, options: null, ctx: null));
      for (final value in [
        box.top,
        box.bottom,
        box.left,
        box.right,
        box.width,
        box.height,
      ]) {
        expect(value, isNaN);
      }
      expect(box.position, same(undefined));
      expect(box.weight, same(undefined));
      expect(box.fullSize, isFalse);
      expect(box.layers, isNull);
      expect(box.axis, isNull);
    });

    test('draw() with display false draws nothing', () {
      final ctx = createMockContext();
      Title((
        chart: null,
        options: <String, Object?>{'display': false},
        ctx: ctx,
      )).draw();
      expect(ctx.getCalls(), isEmpty);
    });

    test('draw() with display true before update throws a TypeError', () {
      // Upstream: the read this._padding.top of undefined (probe:
      // drawBeforeUpdate).
      final box = Title((
        chart: null,
        options: <String, Object?>{'display': true, 'text': 'a'},
        ctx: createMockContext(),
      ));
      expect(box.draw, throwsA(isA<TypeError>()));
    });

    test('update and isHorizontal without options throw a TypeError', () {
      // Upstream: the reads opts.display and this.options.position of
      // undefined (probe: updateNullOptions, isHorizontalNoOptions).
      final box = Title((chart: null, options: null, ctx: null));
      expect(() => box.update(10, 10), throwsA(isA<TypeError>()));
      expect(box.isHorizontal, throwsA(isA<TypeError>()));
    });

    test('update(w, h, margins) ignores the margins', () {
      // The probe updateWithMargins: [0, 0, 300, 100, 300, 34.4].
      List<double> edges(Title box) => [
        box.left,
        box.top,
        box.right,
        box.bottom,
        box.width,
        box.height,
      ];
      AnyObject options() => <String, Object?>{
        'display': true,
        'text': 'a',
        'padding': 10,
        'font': <String, Object?>{'size': 12},
        'position': 'top',
      };
      final withMargins = Title((chart: null, options: options(), ctx: null))
        ..update(300, 100, _Margins(5, 7, 9, 11));
      final without = Title((chart: null, options: options(), ctx: null))
        ..update(300, 100);
      expect(edges(withMargins), [0, 0, 300, 100, 300, closeTo(34.4, 1e-12)]);
      expect(edges(withMargins), edges(without));
    });
  });

  group('stop', () {
    testWidgets('a chart with plugins.title false has no title block', (
      tester,
    ) async {
      final chart = acquireChart(_line(false));
      expect(chart.titleBlock, isNull);
      // The seven plugins of registerables are registered (Chart.js ADR
      // 0041, section 1). Thus the one Title box is the box of the subtitle
      // plugin (plugin.subtitle.js:9-18), with the weight 1500 of
      // plugin.subtitle.js:42. A probe on the pinned build with the seven
      // plugins logged the same boxes: Legend 1000, Title 1500, then the two
      // scales.
      final titles = chart.boxes.whereType<Title>().toList();
      expect(titles, hasLength(1));
      expect(titles.single.weight, 1500);
    });

    testWidgets('the stop hook on a chart without a title block does not '
        'throw', (tester) async {
      // The probe stopWithoutBlock: no throw, the boxes stay.
      final chart = acquireChart(_line(false));
      final boxes = [...chart.boxes];
      jsCall(title['stop'], [chart, <String, Object?>{}, <String, Object?>{}]);
      expect(chart.titleBlock, isNull);
      expect(chart.boxes, boxes);
    });

    testWidgets('the beforeUpdate hook on a chart without a title block '
        'throws a TypeError', (tester) async {
      // The probe beforeUpdateWithoutBlock.
      final chart = acquireChart(_line(false));
      expect(
        () => jsCall(title['beforeUpdate'], [
          chart,
          <String, Object?>{},
          <String, Object?>{},
        ]),
        throwsA(isA<TypeError>()),
      );
    });

    testWidgets('stop removes the title box', (tester) async {
      final chart = acquireChart(
        _line(<String, Object?>{'display': true, 'text': 'a'}),
      );
      final box = chart.titleBlock;
      expect(box, isA<Title>());
      expect(chart.boxes, contains(same(box)));
      jsCall(title['stop'], [chart, <String, Object?>{}, <String, Object?>{}]);
      expect(chart.titleBlock, isNull);
      expect(chart.boxes.where((b) => identical(b, box)), isEmpty);
    });
  });

  group('adapt-component-class-role', () {
    test('an options value that is not a Map throws a TypeError', () {
      // Upstream stores the value (probe: newOptions5 gives 5).
      expect(
        () => _construct([
          <String, Object?>{'options': 5},
        ]),
        throwsA(isA<TypeError>()),
      );
    });

    test('a ctx value that is not a context throws a TypeError', () {
      // Upstream stores the value (probe: newCtxString gives 'x').
      expect(
        () => _construct([
          <String, Object?>{'ctx': 'x'},
        ]),
        throwsA(isA<TypeError>()),
      );
    });

    test('a chart of any value stays', () {
      // The probe newChart5 gives 5: Title never reads the chart.
      for (final chart in <Object?>[5, 'x', true, <Object?>[]]) {
        final box =
            _construct([
                  <String, Object?>{'chart': chart},
                ])!
                as Title;
        expect(box.chart, same(chart));
      }
      final empty = _construct([<String, Object?>{}])! as Title;
      expect(empty.chart, isNull);
      expect(empty.options, isNull);
    });
  });
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
