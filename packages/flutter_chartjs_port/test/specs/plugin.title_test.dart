// Ported from Chart.js v4.5.1+7169e651 test/specs/plugin.title.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'dart:math' as math;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart' show clone;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.title.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/jasmine.dart';

// `Chart` is the class of core.controller.dart, with the static members
// `Chart.registry` and `Chart.defaults`. `Chart.helpers.clone` is `clone` of
// helpers.core.dart. `window.createMockContext()` is createMockContext of
// chartjs_test_utils. A recorded call is a Map with the keys 'name' and
// 'args'. `toEqual` is jasmineEquals of test/support/jasmine.dart.
//
// `Title` of :3 is the class value of the plugin entry `_element`
// (Chart.js ADR 0038, section 4). `new Title(config)` is jsConstruct with
// the config object, and the result is the Dart class Title of
// plugin.title.dart.
//
// The cases of `config update` build charts. Thus the file runs on the VM,
// and each chart case is a `testWidgets` case with the harness of Chart.js
// ADR 0022, section 2. `chart.titleBlock` is the field of `Chart`: Dart
// `null` stands for JS `undefined`. A write into `chart.options` is the
// write through `operator []=` of the option resolver, the `set` trap of
// upstream.

/// `Chart.registry.getPlugin('title')._element` (:3), read in each case.
JsClass _titleClass() =>
    jsGet(Chart.registry.getPlugin('title'), '_element')! as JsClass;

/// `new Title(config)`.
Title _newTitle(AnyObject config) =>
    jsConstruct(_titleClass(), [config]) as Title;

/// `Chart.helpers.clone(Chart.defaults.plugins.title)`.
AnyObject _cloneTitleDefaults() =>
    clone(jsGet(jsGet(Chart.defaults, 'plugins'), 'title'))! as AnyObject;

/// `chart.options.plugins.title`, the option resolver of the title.
AnyObject _titleOptions(Chart chart) =>
    jsGet(jsGet(chart.options, 'plugins'), 'title')! as AnyObject;

/// `chart.options.plugins`, the option resolver of the plugins.
AnyObject _pluginOptions(Chart chart) =>
    jsGet(chart.options, 'plugins')! as AnyObject;

/// The draw calls of the title text with the translation [translate] and the
/// rotation [rotate] (:131-158, :192-219, :234-261).
List<Object?> _textCalls(List<Object?> translate, double rotate) => [
  <String, Object?>{'name': 'save', 'args': <Object?>[]},
  <String, Object?>{
    'name': 'setFont',
    'args': <Object?>[
      "normal bold 12px 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
    ],
  },
  <String, Object?>{'name': 'translate', 'args': translate},
  <String, Object?>{
    'name': 'rotate',
    'args': <Object?>[rotate],
  },
  <String, Object?>{
    'name': 'setFillStyle',
    'args': <Object?>['#666'],
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
      expect(
        jsGet(jsGet(Chart.defaults, 'plugins'), 'title'),
        jasmineEquals(<String, Object?>{
          'align': 'center',
          'color': jsGet(Chart.defaults, 'color'),
          'display': false,
          'position': 'top',
          'fullSize': true,
          'weight': 2000,
          'font': <String, Object?>{'weight': 'bold'},
          'padding': 10,
          'text': '',
        }),
      );
    });

    test('should update correctly', () {
      final chart = <String, Object?>{'options': clone(Chart.defaults)};

      final options = _cloneTitleDefaults();
      options['text'] = 'My title';

      final title = _newTitle(<String, Object?>{
        'chart': chart,
        'options': options,
      })..update(400, 200);

      expect(title.width, 0);
      expect(title.height, 0);

      // Now we have a height since we display
      title.options!['display'] = true;

      title.update(400, 200);

      expect(title.width, 400);
      expect(title.height, 34.4);
    });

    test('should update correctly when vertical', () {
      final chart = <String, Object?>{'options': clone(Chart.defaults)};

      final options = _cloneTitleDefaults();
      options['text'] = 'My title';
      options['position'] = 'left';

      final title = _newTitle(<String, Object?>{
        'chart': chart,
        'options': options,
      })..update(200, 400);

      expect(title.width, 0);
      expect(title.height, 0);

      // Now we have a height since we display
      title.options!['display'] = true;

      title.update(200, 400);

      expect(title.width, 34.4);
      expect(title.height, 400);
    });

    test(
      'should have the correct size when there are multiple lines of text',
      () {
        final chart = <String, Object?>{'options': clone(Chart.defaults)};

        final options = _cloneTitleDefaults();
        options['text'] = <Object?>['line1', 'line2'];
        options['position'] = 'left';
        options['display'] = true;
        (options['font']! as AnyObject)['lineHeight'] = 1.5;

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
      options['text'] = 'My title';

      final title =
          _newTitle(<String, Object?>{
              'chart': chart,
              'options': options,
              'ctx': context,
            })
            ..update(400, 200)
            ..draw();

      expect(context.getCalls(), jasmineEquals(<Object?>[]));

      // Now we have a height since we display
      title.options!['display'] = true;

      title
        ..update(400, 200)
        ..top = 50
        ..left = 100;
      title
        ..bottom = title.top + title.height
        ..right = title.left + title.width
        ..draw();

      expect(
        context.getCalls(),
        jasmineEquals(_textCalls(<Object?>[300, 67.2], 0)),
      );
    });

    test('should draw correctly vertically', () {
      final chart = <String, Object?>{'options': clone(Chart.defaults)};
      final context = createMockContext();

      final options = _cloneTitleDefaults();
      options['text'] = 'My title';
      options['position'] = 'left';

      final title =
          _newTitle(<String, Object?>{
              'chart': chart,
              'options': options,
              'ctx': context,
            })
            ..update(200, 400)
            ..draw();

      expect(context.getCalls(), jasmineEquals(<Object?>[]));

      // Now we have a height since we display
      title.options!['display'] = true;

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
        jasmineEquals(_textCalls(<Object?>[117.2, 250], -0.5 * math.pi)),
      );

      // Rotation is other way on right side
      title.options!['position'] = 'right';

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
        jasmineEquals(_textCalls(<Object?>[117.2, 250], 0.5 * math.pi)),
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
        expect(jsGet(chart.titleBlock!.options, 'display'), true);

        _titleOptions(chart)['display'] = false;
        chart.update();
        expect(jsGet(chart.titleBlock!.options, 'display'), false);
      });

      testWidgets('should update the associated layout item', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{},
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'title': <String, Object?>{
                'fullSize': true,
                'position': 'top',
                'weight': 150,
              },
            },
          },
        });

        expect(chart.titleBlock!.fullSize, true);
        expect(chart.titleBlock!.position, 'top');
        expect(chart.titleBlock!.weight, 150);

        _titleOptions(chart)
          ..['fullSize'] = false
          ..['position'] = 'left'
          ..['weight'] = 42;
        chart.update();

        expect(chart.titleBlock!.fullSize, false);
        expect(chart.titleBlock!.position, 'left');
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
          expect(
            chart.titleBlock!.options,
            toEqualOptions(
              jsGet(jsGet(Chart.defaults, 'plugins'), 'title')!
                  as Map<String, Object?>,
            ),
          );
        },
      );
    });
  });
}
