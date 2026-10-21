// Ported from Chart.js v4.5.1+7169e651 test/specs/controller.bubble.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec builds charts of flutter_chartjs, which does not export lib/src
// yet.
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/elements/element.point.dart';
import 'package:flutter_chartjs/src/helpers/helpers.core.dart' as helpers;
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/jasmine.dart';

// `Chart` is the class of core.controller.dart. The spec runs on the VM: a
// chart reaches the chart host and dart:ui. Each chart case is a
// `testWidgets` case with the harness of Chart.js ADR 0022, section 2. The
// conventions are those of Chart.js ADR 0030, section 13.
//
// flutter_test_config.dart registers the bubble controller with the
// built-in components before main(), as index.umd.ts:28 does (Chart.js ADR
// 0030, section 3 item 4).
//
// The spec forms:
// - `Chart.controllers` is `registry.controllers.items` (index.umd.ts:35):
//   `Chart.registry.controllers.items`.
// - `Chart.elements.PointElement` is the class PointElement of
//   element.point.dart. `instanceof` is `isA`.
// - `Chart.defaults` is the static `Chart.defaults`. A property read is
//   `jsGet`.
// - `Chart.helpers.merge` is `merge` of helpers.core.dart. A write into
//   `chart.options.elements.point` writes into the resolver of the last
//   `jsGet`.
// - `chart.data.datasets[i]` is `_dataset(chart, i)`.
// - `spyOn(meta.data[i], 'draw')` is `spyOnElementDraw(meta, i)` of
//   test/support/jasmine.dart.
// - `toEqual` of an object is `jasmineEquals`. `jasmine.objectContaining` is
//   `objectContaining`.
// - Jasmine `this.chart` is a `late` variable of the group closure. The
//   `beforeEach` of the group `Interactions` acquires a chart. Thus it is a
//   local function `beforeEach()`, and each test calls it first.
//
// One case needs the tooltip plugin of phase 8 (:363).

/// `chart.data.datasets[index]`.
AnyObject _dataset(Chart chart, int index) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>)[index]! as AnyObject;

/// `meta.data[index]` of [meta], a point.
PointElement _point(ChartMeta meta, int index) =>
    meta.data[index] as PointElement;

/// `element.options` of [element].
AnyObject? _options(Object element) => (element as Element).options;

/// `element.options[key]` of [element].
Object? _option(Object element, String key) => jsGet(_options(element), key);

void main() {
  group('Chart.controllers.bubble', () {
    // describe('auto', jasmine.fixture.specs('controller.bubble')): a fixture
    // group of phase 7 (Chart.js ADR 0029), not a case.

    test('should be registered as dataset controller', () {
      expect(jsTypeof(Chart.registry.controllers.items['bubble']), 'function');
    });

    testWidgets('should be constructed', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bubble',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{'data': <Object?>[]},
          ],
        },
      });

      final meta = chart.getDatasetMeta(0);
      expect(meta.type, 'bubble');
      expect(meta.controller, isNot(same(undefined)));
      expect(meta.controller, isNotNull);
      expect(meta.controller!.index, 0);
      expect(meta.data, jasmineEquals(<Object?>[]));

      meta.controller!.updateIndex(1);
      expect(meta.controller!.index, 1);
    });

    testWidgets(
      'should use the first scale IDs if the dataset does not specify them',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bubble',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[]},
            ],
          },
        });

        final meta = chart.getDatasetMeta(0);

        expect(meta.xAxisID, 'x');
        expect(meta.yAxisID, 'y');
      },
    );

    testWidgets(
      'should create point elements for each data item during initialization',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bubble',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 15, 0, -4],
              },
            ],
          },
        });

        final meta = chart.getDatasetMeta(0);

        expect(meta.data.length, 4); // 4 points created
        expect(meta.data[0], isA<PointElement>());
        expect(meta.data[1], isA<PointElement>());
        expect(meta.data[2], isA<PointElement>());
        expect(meta.data[3], isA<PointElement>());
      },
    );

    testWidgets('should draw all elements', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bubble',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 15, 0, -4],
            },
          ],
        },
        'options': <String, Object?>{'animation': false, 'showLine': true},
      });

      final meta = chart.getDatasetMeta(0);

      final draw0 = spyOnElementDraw(meta, 0);
      final draw1 = spyOnElementDraw(meta, 1);
      final draw2 = spyOnElementDraw(meta, 2);
      final draw3 = spyOnElementDraw(meta, 3);

      chart.update();

      expect(draw0.count(), 1);
      expect(draw1.count(), 1);
      expect(draw2.count(), 1);
      expect(draw3.count(), 1);
    });

    testWidgets('should update elements when modifying style', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bubble',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[
                <String, Object?>{'x': 10, 'y': 10, 'r': 5},
                <String, Object?>{'x': -15, 'y': -10, 'r': 1},
                <String, Object?>{'x': 0, 'y': -9, 'r': 2},
                <String, Object?>{'x': -4, 'y': 10, 'r': 1},
              ],
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{'legend': false, 'title': false},
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'category', 'display': false},
            'y': <String, Object?>{'type': 'linear', 'display': false},
          },
        },
      });

      final meta = chart.getDatasetMeta(0);

      final expectedValues = [
        (r: 5, x: 5, y: 5),
        (r: 1, x: 171, y: 507),
        (r: 2, x: 341, y: 482),
        (r: 1, x: 507, y: 5),
      ];
      for (var i = 0; i < expectedValues.length; i++) {
        final expected = expectedValues[i];
        expect(_point(meta, i).x, toBeCloseToPixel(expected.x));
        expect(_point(meta, i).y, toBeCloseToPixel(expected.y));
        expect(
          _options(meta.data[i]),
          objectContaining(<String, Object?>{
            'backgroundColor': jsGet(Chart.defaults, 'backgroundColor'),
            'borderColor': jsGet(Chart.defaults, 'borderColor'),
            'borderWidth': 1,
            'hitRadius': 1,
            'radius': expected.r,
          }),
        );
      }

      // Use dataset level styles for lines & points
      _dataset(chart, 0)['backgroundColor'] = 'rgb(98, 98, 98)';
      _dataset(chart, 0)['borderColor'] = 'rgb(8, 8, 8)';
      _dataset(chart, 0)['borderWidth'] = 0.55;

      // point styles
      _dataset(chart, 0)['radius'] = 22;
      _dataset(chart, 0)['hitRadius'] = 3.3;

      chart.update();

      for (var i = 0; i < 4; ++i) {
        expect(
          _options(meta.data[i]),
          objectContaining(<String, Object?>{
            'backgroundColor': 'rgb(98, 98, 98)',
            'borderColor': 'rgb(8, 8, 8)',
            'borderWidth': 0.55,
            'hitRadius': 3.3,
          }),
        );
      }
    });

    testWidgets('should handle number of data point changes in update', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bubble',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[
                <String, Object?>{'x': 10, 'y': 10, 'r': 5},
                <String, Object?>{'x': -15, 'y': -10, 'r': 1},
                <String, Object?>{'x': 0, 'y': -9, 'r': 2},
                <String, Object?>{'x': -4, 'y': 10, 'r': 1},
              ],
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
      });

      final meta = chart.getDatasetMeta(0);

      expect(meta.data.length, 4);

      _dataset(chart, 0)['data'] = <Object?>[
        <String, Object?>{'x': 1, 'y': 1, 'r': 10},
        <String, Object?>{'x': 10, 'y': 5, 'r': 2},
      ]; // remove 2 items

      chart.update();

      expect(meta.data.length, 2);
      expect(meta.data[0], isA<PointElement>());
      expect(meta.data[1], isA<PointElement>());

      _dataset(chart, 0)['data'] = <Object?>[
        <String, Object?>{'x': 10, 'y': 10, 'r': 5},
        <String, Object?>{'x': -15, 'y': -10, 'r': 1},
        <String, Object?>{'x': 0, 'y': -9, 'r': 2},
        <String, Object?>{'x': -4, 'y': 10, 'r': 1},
        <String, Object?>{'x': -5, 'y': 0, 'r': 3},
      ]; // add 3 items

      chart.update();

      expect(meta.data.length, 5);
      expect(meta.data[0], isA<PointElement>());
      expect(meta.data[1], isA<PointElement>());
      expect(meta.data[2], isA<PointElement>());
      expect(meta.data[3], isA<PointElement>());
      expect(meta.data[4], isA<PointElement>());
    });

    group('Interactions', () {
      late Chart chart;

      // :255 beforeEach: acquires a chart.
      void beforeEach() {
        chart = acquireChart(<String, Object?>{
          'type': 'bubble',
          'data': <String, Object?>{
            'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 5, 'y': 5, 'r': 20},
                  <String, Object?>{'x': -15, 'y': -10, 'r': 15},
                  <String, Object?>{'x': 15, 'y': 10, 'r': 10},
                  <String, Object?>{'x': -15, 'y': 10, 'r': 5},
                ],
              },
            ],
          },
          'options': <String, Object?>{
            'elements': <String, Object?>{
              'point': <String, Object?>{
                'backgroundColor': 'rgb(100, 150, 200)',
                'borderColor': 'rgb(50, 100, 150)',
                'borderWidth': 2,
                'radius': 3,
              },
            },
          },
        });
      }

      testWidgets('should handle default hover styles', (tester) async {
        beforeEach();
        final point = chart.getDatasetMeta(0).data[0];

        await triggerMouseEvent(chart, 'mousemove', point);
        expect(_option(point, 'backgroundColor'), '#3187DD');
        expect(_option(point, 'borderColor'), '#175A9D');
        expect(_option(point, 'borderWidth'), 1);
        expect(_option(point, 'radius'), 20 + 4);

        await triggerMouseEvent(chart, 'mouseout', point);
        expect(_option(point, 'backgroundColor'), 'rgb(100, 150, 200)');
        expect(_option(point, 'borderColor'), 'rgb(50, 100, 150)');
        expect(_option(point, 'borderWidth'), 2);
        expect(_option(point, 'radius'), 20);
      });

      testWidgets('should handle hover styles defined via dataset properties', (
        tester,
      ) async {
        beforeEach();
        final point = chart.getDatasetMeta(0).data[0];

        helpers.merge(_dataset(chart, 0), <String, Object?>{
          'hoverBackgroundColor': 'rgb(200, 100, 150)',
          'hoverBorderColor': 'rgb(150, 50, 100)',
          'hoverBorderWidth': 8.4,
          'hoverRadius': 4.2,
        });

        chart.update();

        await triggerMouseEvent(chart, 'mousemove', point);
        expect(_option(point, 'backgroundColor'), 'rgb(200, 100, 150)');
        expect(_option(point, 'borderColor'), 'rgb(150, 50, 100)');
        expect(_option(point, 'borderWidth'), 8.4);
        expect(_option(point, 'radius'), 20 + 4.2);

        await triggerMouseEvent(chart, 'mouseout', point);
        expect(_option(point, 'backgroundColor'), 'rgb(100, 150, 200)');
        expect(_option(point, 'borderColor'), 'rgb(50, 100, 150)');
        expect(_option(point, 'borderWidth'), 2);
        expect(_option(point, 'radius'), 20);
      });

      testWidgets('should handle hover styles defined via element options', (
        tester,
      ) async {
        beforeEach();
        final point = chart.getDatasetMeta(0).data[0];

        helpers.merge(
          jsGet(jsGet(chart.options, 'elements'), 'point'),
          <String, Object?>{
            'hoverBackgroundColor': 'rgb(200, 100, 150)',
            'hoverBorderColor': 'rgb(150, 50, 100)',
            'hoverBorderWidth': 8.4,
            'hoverRadius': 4.2,
          },
        );

        chart.update();

        await triggerMouseEvent(chart, 'mousemove', point);
        expect(_option(point, 'backgroundColor'), 'rgb(200, 100, 150)');
        expect(_option(point, 'borderColor'), 'rgb(150, 50, 100)');
        expect(_option(point, 'borderWidth'), 8.4);
        expect(_option(point, 'radius'), 20 + 4.2);

        await triggerMouseEvent(chart, 'mouseout', point);
        expect(_option(point, 'backgroundColor'), 'rgb(100, 150, 200)');
        expect(_option(point, 'borderColor'), 'rgb(50, 100, 150)');
        expect(_option(point, 'borderWidth'), 2);
        expect(_option(point, 'radius'), 20);
      });
    });

    // :363 The case reads `chart.tooltip` and writes
    // `chart.options.plugins.tooltip`: it needs the tooltip plugin of
    // phase 8.
    test(
      'should not override tooltip title and label callbacks',
      () {},
      skip: 'blocked: plugin.tooltip',
    );
  });
}
