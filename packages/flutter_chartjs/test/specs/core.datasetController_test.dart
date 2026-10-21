// Ported from Chart.js v4.5.1+7169e651 test/specs/core.datasetController.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'dart:convert';

import 'package:chartjs_test_utils/flutter.dart';
// The spec builds charts of flutter_chartjs, which does not export lib/src
// yet.
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/jasmine.dart';

// The spec tests Chart.DatasetController, the DatasetController of
// lib/src/core/core.datasetController.dart. Each case acquires a line, bar,
// scatter or radar chart with datasets. Thus each case needs a controller of
// phase 7 and the scales of phase 6. A case whose controller is not ported
// yet skips with the blocking module of the classification. The bodies come
// with the controllers. A chart case is a `testWidgets` case, and the file
// runs on the VM (Chart.js ADR 0030, section 12 item 5). It does not call
// `setUpSpecs()`: its charts need the built-in components.
//
// The spec forms:
// - `chart._stacks` is `chart.stacks`. The keys of a stack are the
//   `ToString` of the index values, as the JS property keys.
// - `chart.data.datasets[i]` is `_dataset(chart, i)`.
// - `expect(fn).not.toThrow()` is `expect(fn, returnsNormally)`.
//
// The three
// `Object.isFrozen` assertions of :975, :997 and :1018 become
// `jsObjectIsFrozen` (Chart.js ADR 0021, section 7).
// test/port/core/core.datasetController_test.dart covers the controller with
// a fake chart, fake scales and a test controller.

/// `chart.data.datasets[index]`.
AnyObject _dataset(Chart chart, int index) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>)[index]! as AnyObject;

void main() {
  group('Chart.DatasetController', () {
    // describe('auto', jasmine.fixture.specs('core.datasetController')): a
    // fixture group of phase 7, not a case.

    test(
      'should listen for dataset data insertions or removals',
      () {},
      skip: 'blocked: controller.line',
    );

    testWidgets('should not try to delete non existent stacks', (
      tester,
    ) async {
      void createAndUpdateChart() {
        acquireChart(<String, Object?>{
            'data': <String, Object?>{
              'labels': <Object?>['q'],
              'datasets': <Object?>[
                <String, Object?>{
                  'id': 'dismissed',
                  'label': 'Test before',
                  'yAxisID': 'count',
                  'data': <Object?>[816],
                  'type': 'bar',
                  'stack': 'stack',
                },
              ],
            },
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'count': <String, Object?>{'axis': 'y', 'type': 'linear'},
              },
            },
          })
          ..data = <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'id': 'tests',
                'yAxisID': 'count',
                'label': 'Test after',
                'data': <Object?>[38300],
                'type': 'bar',
              },
            ],
            'labels': <Object?>['q'],
          }
          ..update();
      }

      expect(createAndUpdateChart, returnsNormally);
    });

    group('inextensible data', () {
      test(
        'should handle a frozen data object',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should handle a sealed data object',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should handle an unextendable data object',
        () {},
        skip: 'blocked: controller.line',
      );
    });

    test(
      'should parse data using correct scales',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should parse using provided keys',
      () {},
      skip: 'blocked: controller.line',
    );

    group('labels array synchronization', () {
      // :255-263 `data1` and `data2`: the data of the cases. They come with
      // the bodies. :264-271 loops over the three `parsing` values.
      for (final parsing in <Object?>[
        true,
        false,
        <String, Object?>{'xAxisKey': 'name', 'yAxisKey': 'value'},
      ]) {
        group('when parsing is ${jsonEncode(parsing)}', () {
          test(
            'should remove old labels when data is updated',
            () {},
            skip: 'blocked: controller.line',
          );

          test(
            'should not remove any user added labels',
            () {},
            skip: 'blocked: controller.line',
          );

          test(
            'should not remove any user defined labels',
            () {},
            skip: 'blocked: controller.line',
          );

          test(
            'should keep up with multiple datasets',
            () {},
            skip: 'blocked: controller.line',
          );
        });
      }
    });

    test(
      'should synchronize metadata when data are inserted or removed and '
      'parsing is on',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should synchronize metadata when data are inserted or removed and '
      'parsing is off',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should synchronize insert before removal when parsing is off',
      () {},
      skip: 'blocked: controller.scatter',
    );

    test(
      'should re-synchronize metadata when the data object reference changes',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should re-synchronize metadata when the data object reference '
      'changes, with animation',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should re-synchronize metadata when data are unusually altered',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should re-synchronize metadata when data is moved and values are equal',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should re-synchronize metadata when data is objects and directly '
      'altered',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should re-synchronize metadata when scaleID changes',
      () {},
      skip: 'blocked: controller.line',
    );

    testWidgets('should re-synchronize stacks when stack is changed', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'labels': <Object?>['a', 'b'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1, 10],
              'stack': '1',
            },
            <String, Object?>{
              'data': <Object?>[2, 20],
              'stack': '2',
            },
            <String, Object?>{
              'data': <Object?>[3, 30],
              'stack': '1',
            },
          ],
        },
      });

      expect(
        chart.stacks,
        jasmineEquals(<String, Object?>{
          'x.y.1': <String, Object?>{
            '0': <String, Object?>{
              '0': 1,
              '2': 3,
              '_top': 2,
              '_bottom': null,
              '_visualValues': <String, Object?>{'0': 1, '2': 3},
            },
            '1': <String, Object?>{
              '0': 10,
              '2': 30,
              '_top': 2,
              '_bottom': null,
              '_visualValues': <String, Object?>{'0': 10, '2': 30},
            },
          },
          'x.y.2': <String, Object?>{
            '0': <String, Object?>{
              '1': 2,
              '_top': 1,
              '_bottom': null,
              '_visualValues': <String, Object?>{'1': 2},
            },
            '1': <String, Object?>{
              '1': 20,
              '_top': 1,
              '_bottom': null,
              '_visualValues': <String, Object?>{'1': 20},
            },
          },
        }),
      );

      _dataset(chart, 2)['stack'] = '2';
      chart.update();

      expect(
        chart.stacks,
        jasmineEquals(<String, Object?>{
          'x.y.1': <String, Object?>{
            '0': <String, Object?>{
              '0': 1,
              '_top': 2,
              '_bottom': null,
              '_visualValues': <String, Object?>{'0': 1},
            },
            '1': <String, Object?>{
              '0': 10,
              '_top': 2,
              '_bottom': null,
              '_visualValues': <String, Object?>{'0': 10},
            },
          },
          'x.y.2': <String, Object?>{
            '0': <String, Object?>{
              '1': 2,
              '2': 3,
              '_top': 2,
              '_bottom': null,
              '_visualValues': <String, Object?>{'1': 2, '2': 3},
            },
            '1': <String, Object?>{
              '1': 20,
              '2': 30,
              '_top': 2,
              '_bottom': null,
              '_visualValues': <String, Object?>{'1': 20, '2': 30},
            },
          },
        }),
      );
    });

    testWidgets('should re-synchronize stacks when data is removed', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'labels': <Object?>['a', 'b'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1, 10],
              'stack': '1',
            },
            <String, Object?>{
              'data': <Object?>[2, 20],
              'stack': '2',
            },
            <String, Object?>{
              'data': <Object?>[3, 30],
              'stack': '1',
            },
          ],
        },
      });

      expect(
        chart.stacks,
        jasmineEquals(<String, Object?>{
          'x.y.1': <String, Object?>{
            '0': <String, Object?>{
              '0': 1,
              '2': 3,
              '_top': 2,
              '_bottom': null,
              '_visualValues': <String, Object?>{'0': 1, '2': 3},
            },
            '1': <String, Object?>{
              '0': 10,
              '2': 30,
              '_top': 2,
              '_bottom': null,
              '_visualValues': <String, Object?>{'0': 10, '2': 30},
            },
          },
          'x.y.2': <String, Object?>{
            '0': <String, Object?>{
              '1': 2,
              '_top': 1,
              '_bottom': null,
              '_visualValues': <String, Object?>{'1': 2},
            },
            '1': <String, Object?>{
              '1': 20,
              '_top': 1,
              '_bottom': null,
              '_visualValues': <String, Object?>{'1': 20},
            },
          },
        }),
      );

      _dataset(chart, 2)['data'] = <Object?>[4];
      chart.update();

      expect(
        chart.stacks,
        jasmineEquals(<String, Object?>{
          'x.y.1': <String, Object?>{
            '0': <String, Object?>{
              '0': 1,
              '2': 4,
              '_top': 2,
              '_bottom': null,
              '_visualValues': <String, Object?>{'0': 1, '2': 4},
            },
            '1': <String, Object?>{
              '0': 10,
              '_top': 2,
              '_bottom': null,
              '_visualValues': <String, Object?>{'0': 10},
            },
          },
          'x.y.2': <String, Object?>{
            '0': <String, Object?>{
              '1': 2,
              '_top': 1,
              '_bottom': null,
              '_visualValues': <String, Object?>{'1': 2},
            },
            '1': <String, Object?>{
              '1': 20,
              '_top': 1,
              '_bottom': null,
              '_visualValues': <String, Object?>{'1': 20},
            },
          },
        }),
      );
    });

    test(
      'should cleanup attached properties when the reference changes or when '
      'the chart is destroyed',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should resolve data element options to the default color',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should read parsing from options when default is false',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should not fail to produce stacks when parsing is off',
      () {},
      skip: 'blocked: controller.line',
    );

    group('resolveDataElementOptions', () {
      test(
        'should cache options when possible',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should not cache options when option sharing is disabled',
        () {},
        skip: 'blocked: controller.radar',
      );

      test(
        'should not cache options when functions are used',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should support nested scriptable options',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should support nested scriptable defaults',
        () {},
        skip: 'blocked: controller.line',
      );
    });

    group('_resolveAnimations', () {
      // :1068-1078 `animationsExpectations(anims, props)`: the helper of the
      // case of :1118. It comes with the body of that case.

      test(
        'should resolve to empty Animations when globally disabled',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should resolve to empty Animations when disabled at dataset level',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should fallback properly',
        () {},
        skip: 'blocked: controller.line',
      );
    });

    group('getContext', () {
      test(
        'should reflect updated data',
        () {},
        skip: 'blocked: controller.scatter',
      );
    });
  });
}
