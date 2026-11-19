// Ported from Chart.js v4.6.1 test/specs/plugin.title.tests.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-title-text-lines, the lines of a title text.
// DIVERGES(chartjs): adapt-direct-colors, native color test inputs.
@TestOn('vm')
library;

import 'dart:math' as math;
import 'dart:ui' as native_ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter/painting.dart' show EdgeInsets, TextStyle;
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/plugin_options_plain.dart';

// `Chart` is the class of core.controller.dart, with the static members
// `Chart.registry` and `Chart.defaults`. `Chart.helpers.clone` is `clone` of
// helpers.core.dart. `window.createMockContext()` is createMockContext of
// chartjs_test_utils. A recorded call is a Map with the keys 'name' and
// 'args'. `toEqual` of the calls is `equals`.
//
// `Title` of :3, the plugin entry `_element`, is the class value
// `Title.jsClass` (Chart.js ADR 0038, section 4): the native plugin `title`
// has no key `_element` (Chart.js ADR 0144). `new Title(config)` is
// jsConstruct with the config object, and the result is the Dart class Title
// of plugin.title.dart.
//
// The cases of `config update` build charts. Thus the file runs on the VM,
// and each chart case is a `testWidgets` case with the harness of Chart.js
// ADR 0022, section 2. `chart.titleBlock` is the field of `Chart`: Dart
// `null` stands for JS `undefined`. A write into `chart.options` is the
// write through `operator []=` of the option resolver, the `set` trap of
// upstream.

/// `Chart.registry.getPlugin('title')._element` (:3): the class value of
/// [Title].
// DIVERGES(chartjs): adapt-typed-plugins, the class value of Title.
JsClass _titleClass() => Title.jsClass;

/// `new Title(config)`.
Title _newTitle(AnyObject config) =>
    jsConstruct(_titleClass(), [config]) as Title;

/// `Chart.helpers.clone(Chart.defaults.plugins.title)`.
JsObjectFace _cloneTitleDefaults() =>
    clone(jsGet(jsGet(Chart.defaults, 'plugins'), 'title'))! as JsObjectFace;

/// `chart.options.plugins.title`, the option resolver of the title.
JsObjectFace _titleOptions(Chart chart) =>
    jsGet(jsGet(chart.options, 'plugins'), 'title')! as JsObjectFace;

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
      final defaults =
          jsGet(jsGet(Chart.defaults, 'plugins'), 'title')!
              as TitleOptionsScope;
      // `toEqual`: the own keys of the object and the value of each key.
      expect(
        defaults.ownKeys,
        unorderedEquals(<Object>[
          OptionKey.align,
          OptionKey.color,
          OptionKey.display,
          OptionKey.position,
          OptionKey.fullSize,
          OptionKey.weight,
          OptionKey.font,
          OptionKey.padding,
          OptionKey.text,
        ]),
      );
      expect(defaults.alignCell?.raw, ChartAlign.center);
      // `color` routes to `Chart.defaults.color` (plugin.title.js:158-160).
      expect(
        defaults.lookup(OptionKey.color)?.raw,
        Chart.defaults.colorCell?.raw,
      );
      expect(defaults.displayCell?.raw, false);
      expect(defaults.positionCell?.raw, ChartPosition.top);
      expect(defaults.fullSizeCell?.raw, true);
      expect(defaults.weightCell?.raw, 2000);
      expect(
        defaults.fontCell?.raw,
        const ChartTextStyle(fontWeight: native_ui.FontWeight.bold),
      );
      expect(defaults.paddingCell?.raw, const EdgeInsets.all(10));
      expect(defaults.textCell?.raw, ['']);
    });

    test('should update correctly', () {
      final chart = <String, Object?>{'options': clone(Chart.defaults)};

      final options = _cloneTitleDefaults();
      options['text'] = ['My title'];

      final title = _newTitle(<String, Object?>{
        'chart': chart,
        'options': options,
      })..update(400, 200);

      expect(title.width, 0);
      expect(title.height, 0);

      // Now we have a height since we display
      options['display'] = true;
      title
        ..options = TitleOptions.of(options)
        ..update(400, 200);

      expect(title.width, 400);
      expect(title.height, 34.4);
    });

    test('should update correctly when vertical', () {
      final chart = <String, Object?>{'options': clone(Chart.defaults)};

      final options = _cloneTitleDefaults();
      options['text'] = ['My title'];
      options['position'] = ChartPosition.left;

      final title = _newTitle(<String, Object?>{
        'chart': chart,
        'options': options,
      })..update(200, 400);

      expect(title.width, 0);
      expect(title.height, 0);

      // Now we have a height since we display
      options['display'] = true;
      title
        ..options = TitleOptions.of(options)
        ..update(200, 400);

      expect(title.width, 34.4);
      expect(title.height, 400);
    });

    test(
      'should have the correct size when there are multiple lines of text',
      () {
        final chart = <String, Object?>{'options': clone(Chart.defaults)};

        final options = _cloneTitleDefaults();
        options['text'] = <String>['line1', 'line2'];
        options['position'] = ChartPosition.left;
        options['display'] = true;
        options['font'] = (options['font']! as TextStyle).merge(
          const ChartTextStyle(height: 1.5),
        );

        final title = _newTitle(<String, Object?>{
          'chart': chart,
          'options': options,
        })..update(200, 400);

        expect(title.width, 56);
        expect(title.height, 400);
      },
    );

    test('should draw correctly horizontally', () {
      final chart = <String, Object?>{'options': clone(Chart.defaults)};
      final context = createMockContext();

      final options = _cloneTitleDefaults();
      options['text'] = ['My title'];

      final title =
          _newTitle(<String, Object?>{
              'chart': chart,
              'options': options,
              'ctx': context,
            })
            ..update(400, 200)
            ..draw();

      expect(context.getCalls(), equals(<Object?>[]));

      // Now we have a height since we display
      options['display'] = true;
      title
        ..options = TitleOptions.of(options)
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

      final options = _cloneTitleDefaults();
      options['text'] = ['My title'];
      options['position'] = ChartPosition.left;

      final title =
          _newTitle(<String, Object?>{
              'chart': chart,
              'options': options,
              'ctx': context,
            })
            ..update(200, 400)
            ..draw();

      expect(context.getCalls(), equals(<Object?>[]));

      // Now we have a height since we display
      options['display'] = true;
      title
        ..options = TitleOptions.of(options)
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
      options['position'] = ChartPosition.right;
      title.options = TitleOptions.of(options);

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
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>['A', 'B', 'C', 'D'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 20, 30, 100],
              },
            ],
          },
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'title': <String, Object?>{'display': true},
            },
          },
        });
        expect((chart.titleBlock! as Title).options!.display, true);

        _titleOptions(chart)['display'] = false;
        chart.update();
        expect((chart.titleBlock! as Title).options!.display, false);
      });

      testWidgets('should update the associated layout item', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{},
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'title': <String, Object?>{
                'fullSize': true,
                'position': ChartPosition.top,
                'weight': 150,
              },
            },
          },
        });

        expect(chart.titleBlock!.fullSize, true);
        expect(chart.titleBlock!.position, ChartPosition.top);
        expect(chart.titleBlock!.weight, 150);

        _titleOptions(chart)
          ..['fullSize'] = false
          ..['position'] = ChartPosition.left
          ..['weight'] = 42;
        chart.update();

        expect(chart.titleBlock!.fullSize, false);
        expect(chart.titleBlock!.position, ChartPosition.left);
        expect(chart.titleBlock!.weight, 42);
      });

      testWidgets('should remove the title if the new options are false', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>['A', 'B', 'C', 'D'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 20, 30, 100],
              },
            ],
          },
        });
        expect(chart.titleBlock, isNotNull);

        _pluginOptions(chart)['title'] = false;
        chart.update();
        expect(chart.titleBlock, isNull);
      });

      testWidgets(
        'should create the title if the title options are changed to exist',
        (tester) async {
          final chart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'labels': <Object?>['A', 'B', 'C', 'D'],
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[10, 20, 30, 100],
                },
              ],
            },
            'options': <String, Object?>{
              'plugins': <String, Object?>{'title': false},
            },
          });
          expect(chart.titleBlock, isNull);

          _pluginOptions(chart)['title'] = <String, Object?>{};
          chart.update();
          expect(chart.titleBlock, isNotNull);
          // `toEqualOptions` reads the own keys of the defaults: the box has
          // the resolved `TitleOptions` (Chart.js ADR 0182), and `color` is a
          // route of the defaults, not an own key.
          final expected = TitleOptions.of(
            jsGet(jsGet(Chart.defaults, 'plugins'), 'title'),
          );
          expect(
            plainTitleOptions((chart.titleBlock! as Title).options)!
              ..remove('color'),
            plainTitleOptions(expected)!..remove('color'),
          );
        },
      );
    });
  });
}
