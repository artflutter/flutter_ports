// Ported from Chart.js v4.6.1 test/specs/plugin.title.tests.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-title-text-lines, the lines of a title text.
// DIVERGES(chartjs): adapt-direct-colors, native color test inputs.
@TestOn('vm')
library;

import 'dart:math' as math;
import 'dart:ui' as native_ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;

// `Chart` is the class of core.controller.dart, with the static members
// `Chart.registry` and `Chart.defaults`. `Chart.helpers.clone` is `clone` of
// helpers.core.dart. `window.createMockContext()` is createMockContext of
// chartjs_test_utils. A recorded call is a Map with the keys 'name' and
// 'args'. `toEqual` of the calls is `equals`.
//
// `Title` of :3, the plugin entry `_element`, is the Dart class Title of
// plugin.title.dart: the native plugin `title` has no key `_element`
// (Chart.js ADR 0144). `new Title(config)` is the constructor with the
// config record (Chart.js ADR 0038, section 4, and Chart.js ADR 0204).
//
// The cases of `config update` build charts. Thus the file runs on the VM,
// and each chart case is a `testWidgets` case with the harness of Chart.js
// ADR 0022, section 2. `chart.titleBlock` is the field of `Chart`: Dart
// `null` stands for JS `undefined`. A write into `chart.options` is the
// write through `operator []=` of the option resolver, the `set` trap of
// upstream.

/// `new Title(config)`, with the class
/// `Chart.registry.getPlugin('title')._element` (:3).
// DIVERGES(chartjs): adapt-typed-plugins, the class Title.
Title _newTitle(
  ({
    Object? chart,
    TitleBoxOptions<Object?>? options,
    CanvasRenderingContext2D? ctx,
  })
  config,
) => Title(config);

/// `Chart.defaults.plugins.title`: one [TitleOptions] (Chart.js ADR 0197).
TitleOptions _titleDefaults() =>
    (Chart.defaults.pluginsCell!.raw! as PluginOptionsByTypeScope)
            .titleCell!
            .raw!
        as TitleOptions;

/// `Chart.defaults.color`.
ChartPaint _defaultColor() => Chart.defaults.colorCell!.raw! as ChartPaint;

/// `Chart.helpers.clone(Chart.defaults.plugins.title)`: the clone reads the
/// `color` route of plugin.title.js:158-160, so it holds
/// `Chart.defaults.color`.
TitleOptions _cloneTitleDefaults() =>
    _titleDefaults().merge(TitleOptions(color: _defaultColor()));

/// `chart.options.plugins.title.<key> = value` for each field of [over]: the
/// options of the chart with [over] merged over them (Chart.js ADR 0197).
void _writeTitleOptions(Chart chart, TitleOptions over) {
  final plugins = _pluginOptions(chart);
  plugins['title'] = (plugins['title']! as TitleOptions).merge(over);
}

/// `chart.options.plugins`, the option resolver of the plugins.
JsObjectFace _pluginOptions(Chart chart) =>
    jsGet(chart.options, 'plugins')! as JsObjectFace;

/// The draw calls of the title text with the translation [translate] and the
/// rotation [rotate] (:131-158, :192-219, :234-261).
List<Object?> _textCalls(List<Object?> translate, double rotate) => [
  <String, Object?>{'name': 'save', 'args': <Object?>[]},
  // The font of the title: a ChartTextStyle (row adapt-text-style-fonts).
  <String, Object?>{
    'name': 'setFont',
    'args': <Object?>[
      toFont(const ChartTextStyle(fontWeight: native_ui.FontWeight.bold)),
    ],
  },
  <String, Object?>{'name': 'translate', 'args': translate},
  <String, Object?>{
    'name': 'rotate',
    'args': <Object?>[rotate],
  },
  <String, Object?>{
    'name': 'setFillStyle',
    // The mock context records the color of a solid paint.
    'args': <Object?>[const native_ui.Color.fromRGBO(102, 102, 102, 1)],
  },
  <String, Object?>{
    'name': 'setTextAlign',
    'args': <Object?>['center'],
  },
  <String, Object?>{
    'name': 'setTextBaseline',
    'args': <Object?>['middle'],
  },
  <String, Object?>{
    'name': 'fillText',
    'args': <Object?>['My title', 0, 0, 400],
  },
  <String, Object?>{'name': 'restore', 'args': <Object?>[]},
];

void main() {
  // Test the rectangle element

  group('Plugin.title', () {
    group('auto', fixture.specs('plugin.title'));

    test('Should have the correct default config', () {
      // `toEqual`: the value of each key. The `color` of upstream is the
      // route to `Chart.defaults.color` (plugin.title.js:158-160): the
      // plugin gives that color when the options set none (Chart.js ADR
      // 0197), and the clone of the defaults holds it.
      expect(
        _cloneTitleDefaults(),
        TitleOptions(
          align: ChartAlign.center,
          color: _defaultColor(),
          display: false,
          position: ChartPosition.top,
          fullSize: true,
          weight: 2000,
          font: const ChartTextStyle(fontWeight: native_ui.FontWeight.bold),
          padding: const EdgeInsets.all(10),
          text: const [''],
        ),
      );
      expect(_titleDefaults().color, isNull);
    });

    test('should update correctly', () {
      final chart = <String, Object?>{'options': clone(Chart.defaults)};

      final options = _cloneTitleDefaults().merge(
        const TitleOptions(text: ['My title']),
      );

      final title = _newTitle((chart: chart, options: options, ctx: null))
        ..update(400, 200);

      expect(title.width, 0);
      expect(title.height, 0);

      // Now we have a height since we display
      title
        ..options = options.merge(const TitleOptions(display: true))
        ..update(400, 200);

      expect(title.width, 400);
      expect(title.height, 34.4);
    });

    test('should update correctly when vertical', () {
      final chart = <String, Object?>{'options': clone(Chart.defaults)};

      final options = _cloneTitleDefaults().merge(
        const TitleOptions(text: ['My title'], position: ChartPosition.left),
      );

      final title = _newTitle((chart: chart, options: options, ctx: null))
        ..update(200, 400);

      expect(title.width, 0);
      expect(title.height, 0);

      // Now we have a height since we display
      title
        ..options = options.merge(const TitleOptions(display: true))
        ..update(200, 400);

      expect(title.width, 34.4);
      expect(title.height, 400);
    });

    test(
      'should have the correct size when there are multiple lines of text',
      () {
        final chart = <String, Object?>{'options': clone(Chart.defaults)};

        // `options.font.lineHeight = 1.5`: the font merges by field.
        final options = _cloneTitleDefaults().merge(
          const TitleOptions(
            text: <String>['line1', 'line2'],
            position: ChartPosition.left,
            display: true,
            font: ChartTextStyle(height: 1.5),
          ),
        );

        final title = _newTitle((chart: chart, options: options, ctx: null))
          ..update(200, 400);

        expect(title.width, 56);
        expect(title.height, 400);
      },
    );

    test('should draw correctly horizontally', () {
      final chart = <String, Object?>{'options': clone(Chart.defaults)};
      final context = createMockContext();

      final options = _cloneTitleDefaults().merge(
        const TitleOptions(text: ['My title']),
      );

      final title = _newTitle((chart: chart, options: options, ctx: context))
        ..update(400, 200)
        ..draw();

      expect(context.getCalls(), equals(<Object?>[]));

      // Now we have a height since we display
      title
        ..options = options.merge(const TitleOptions(display: true))
        ..update(400, 200)
        ..top = 50
        ..left = 100;
      title
        ..bottom = title.top + title.height
        ..right = title.left + title.width
        ..draw();

      expect(context.getCalls(), equals(_textCalls(<Object?>[300, 67.2], 0)));
    });

    test('should draw correctly vertically', () {
      final chart = <String, Object?>{'options': clone(Chart.defaults)};
      final context = createMockContext();

      final options = _cloneTitleDefaults().merge(
        const TitleOptions(text: ['My title'], position: ChartPosition.left),
      );

      final title = _newTitle((chart: chart, options: options, ctx: context))
        ..update(200, 400)
        ..draw();

      expect(context.getCalls(), equals(<Object?>[]));

      // Now we have a height since we display
      final displayed = options.merge(const TitleOptions(display: true));
      title
        ..options = displayed
        ..update(200, 400)
        ..top = 50
        ..left = 100;
      title
        ..bottom = title.top + title.height
        ..right = title.left + title.width
        ..draw();

      expect(
        context.getCalls(),
        equals(_textCalls(<Object?>[117.2, 250], -0.5 * math.pi)),
      );

      // Rotation is other way on right side
      title.options = displayed.merge(
        const TitleOptions(position: ChartPosition.right),
      );

      // Reset call tracker
      context.resetCalls();

      title
        ..update(200, 400)
        ..top = 50
        ..left = 100;
      title
        ..bottom = title.top + title.height
        ..right = title.left + title.width
        ..draw();

      expect(
        context.getCalls(),
        equals(_textCalls(<Object?>[117.2, 250], 0.5 * math.pi)),
      );
    });

    group('config update', () {
      testWidgets('should update the options', (tester) async {
        // The lowered scopes remain mutable for the option updates below.
        final chart = acquireChartRoot(
          lowerForTest(
            const ChartConfig(
              datasets: [
                LineDataset(data: .values([10, 20, 30, 100])),
              ],
              labels: ['A', 'B', 'C', 'D'],
              pluginOptions: [TitleOptions(display: true)],
            ),
          ),
        );
        expect((chart.titleBlock! as Title).options!.display, true);

        _writeTitleOptions(chart, const TitleOptions(display: false));
        chart.update();
        expect((chart.titleBlock! as Title).options!.display, false);
      });

      testWidgets('should update the associated layout item', (tester) async {
        // The lowered scopes remain mutable for the option updates below.
        final chart = acquireChartRoot(
          lowerForTest(
            const ChartConfig(
              datasets: [LineDataset()],
              pluginOptions: [
                TitleOptions(
                  fullSize: true,
                  position: ChartPosition.top,
                  weight: 150,
                ),
              ],
            ),
          ),
        );

        expect(chart.titleBlock!.fullSize, true);
        expect(chart.titleBlock!.position, ChartPosition.top);
        expect(chart.titleBlock!.weight, 150);

        _writeTitleOptions(
          chart,
          const TitleOptions(
            fullSize: false,
            position: ChartPosition.left,
            weight: 42,
          ),
        );
        chart.update();

        expect(chart.titleBlock!.fullSize, false);
        expect(chart.titleBlock!.position, ChartPosition.left);
        expect(chart.titleBlock!.weight, 42);
      });

      testWidgets('should remove the title if the new options are false', (
        tester,
      ) async {
        // The lowered scopes remain mutable for the option updates below.
        final chart = acquireChartRoot(
          lowerForTest(
            const ChartConfig(
              datasets: [
                LineDataset(data: .values([10, 20, 30, 100])),
              ],
              labels: ['A', 'B', 'C', 'D'],
            ),
          ),
        );
        expect(chart.titleBlock, isNotNull);

        _pluginOptions(chart)['title'] = false;
        chart.update();
        expect(chart.titleBlock, isNull);
      });

      testWidgets(
        'should create the title if the title options are changed to exist',
        (tester) async {
          // A disabled plugin goes through extra; its live options
          // stay mutable.
          final chart = acquireChartRoot(
            lowerForTest(
              const ChartConfig(
                datasets: [
                  LineDataset(data: .values([10, 20, 30, 100])),
                ],
                labels: ['A', 'B', 'C', 'D'],
                disabledPlugins: [PluginOff<TitlePlugin>()],
              ),
            ),
          );
          expect(chart.titleBlock, isNull);

          // `{}`: the title options with no field (Chart.js ADR 0197).
          _pluginOptions(chart)['title'] = const TitleOptions();
          chart.update();
          expect(chart.titleBlock, isNotNull);
          // `toEqualOptions` reads the own keys of the defaults, with the
          // `color` of the route: the box keeps the options with the color
          // of `Chart.defaults` (Chart.js ADR 0197).
          expect((chart.titleBlock! as Title).options, _cloneTitleDefaults());
        },
      );
    });
  });
}
