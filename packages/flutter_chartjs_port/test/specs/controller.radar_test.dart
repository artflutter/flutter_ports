// Ported from Chart.js v4.5.1+7169e651 test/specs/controller.radar.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart' as helpers;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/jasmine.dart';

// `Chart` is the class of core.controller.dart. The spec runs on the VM: a
// chart reaches the chart host and dart:ui. Each chart case is a
// `testWidgets` case with the harness of Chart.js ADR 0022, section 2. The
// conventions are those of Chart.js ADR 0030, section 13.
//
// flutter_test_config.dart registers the radar controller with the
// built-in components before main(), as index.umd.ts:28 does (Chart.js ADR
// 0030, section 3 item 4).
//
// The spec forms:
// - `Chart.controllers` is `registry.controllers.items` (index.umd.ts:35):
//   `Chart.registry.controllers.items`.
// - `Chart.elements.LineElement` and `Chart.elements.PointElement` are the
//   classes of element.line.dart and element.point.dart. `instanceof` is
//   `isA`.
// - `Chart.defaults` is the static `Chart.defaults`. A property read is
//   `jsGet`.
// - `Chart.helpers.merge` is `merge` of helpers.core.dart.
// - `chart.data.datasets[i]` is `_dataset(chart, i)`.
// - `spyOn(meta.dataset, 'draw')` is `spyOnDataset(meta)`, and
//   `spyOn(meta.data[i], 'draw')` is `spyOnElementDraw(meta, i)` of
//   test/support/jasmine.dart.
// - `toEqual` of an object is `jasmineEquals`.
// - Jasmine `this.chart` is a `late` variable of the group closure. The
//   `beforeEach` of the group `Interactions` acquires a chart. Thus it is a
//   local function `beforeEach()`, and each test calls it first.
//
// One case needs the filler plugin of phase 8 (:103): only the filler calls
// `updateControlPoints` of a radar line. One case needs the tooltip plugin
// of phase 8 (:410).

/// `chart.data.datasets[index]`.
AnyObject _dataset(Chart chart, int index) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>)[index]! as AnyObject;

/// `element.options` of [element].
AnyObject? _options(Object element) => (element as Element).options;

/// `element.options[key]` of [element].
Object? _option(Object element, String key) => jsGet(_options(element), key);

void main() {
  group('Chart.controllers.radar', () {
    group('auto', fixture.specs('controller.radar'));

    test('should be registered as dataset controller', () {
      expect(jsTypeof(Chart.registry.controllers.items['radar']), 'function');
    });

    testWidgets('Should be constructed', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'radar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{'data': <Object?>[]},
          ],
          'labels': <Object?>[],
        },
      });

      final meta = chart.getDatasetMeta(0);
      expect(meta.type, 'radar');
      expect(meta.controller, isNot(same(undefined)));
      expect(meta.controller, isNotNull);
      expect(meta.controller!.index, 0);
      expect(meta.data, jasmineEquals(<Object?>[]));

      meta.controller!.updateIndex(1);
      expect(meta.controller!.index, 1);
    });

    testWidgets(
      'Should create arc elements for each data item during initialization',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 15, 0, 4],
              },
            ],
            'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
          },
        });

        final meta = chart.getDatasetMeta(0);
        expect(meta.dataset, isA<LineElement>()); // line element
        expect(meta.data.length, 4); // 4 points created
        expect(meta.data[0], isA<PointElement>());
        expect(meta.data[1], isA<PointElement>());
        expect(meta.data[2], isA<PointElement>());
        expect(meta.data[3], isA<PointElement>());
      },
    );

    testWidgets('should draw all elements', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'radar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 15, 0, 4],
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
      });

      final meta = chart.getDatasetMeta(0);

      final dataset = spyOnDataset(meta);
      final draw0 = spyOnElementDraw(meta, 0);
      final draw1 = spyOnElementDraw(meta, 1);
      final draw2 = spyOnElementDraw(meta, 2);
      final draw3 = spyOnElementDraw(meta, 3);

      chart.update();

      expect(dataset.draw.count(), 1);
      expect(draw0.count(), 1);
      expect(draw1.count(), 1);
      expect(draw2.count(), 1);
      expect(draw3.count(), 1);
    });

    testWidgets(
      'should draw all elements with object notation and default key',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'r': 10},
                  <String, Object?>{'r': 20},
                  <String, Object?>{'r': 15},
                ],
              },
            ],
            'labels': <Object?>['label1', 'label2', 'label3'],
          },
        });

        final meta = chart.getDatasetMeta(0);

        final dataset = spyOnDataset(meta);
        final draw0 = spyOnElementDraw(meta, 0);
        final draw1 = spyOnElementDraw(meta, 1);
        final draw2 = spyOnElementDraw(meta, 2);

        chart.update();

        expect(dataset.draw.count(), 1);
        expect(draw0.count(), 1);
        expect(draw1.count(), 1);
        expect(draw2.count(), 1);
      },
    );

    // controller.radar.tests.js:103 it('should update elements'): it reads
    // the control points that only the filler plugin computes for a radar
    // line.
    test('should update elements', () {}, skip: 'blocked: plugin.filler');

    group('Interactions', () {
      late Chart chart;

      void beforeEach() {
        chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 15, 0, 4],
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
        expect(_option(point, 'radius'), 4);

        await triggerMouseEvent(chart, 'mouseout', point);
        expect(_option(point, 'backgroundColor'), 'rgb(100, 150, 200)');
        expect(_option(point, 'borderColor'), 'rgb(50, 100, 150)');
        expect(_option(point, 'borderWidth'), 2);
        expect(_option(point, 'radius'), 3);
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
        expect(_option(point, 'radius'), 4.2);

        await triggerMouseEvent(chart, 'mouseout', point);
        expect(_option(point, 'backgroundColor'), 'rgb(100, 150, 200)');
        expect(_option(point, 'borderColor'), 'rgb(50, 100, 150)');
        expect(_option(point, 'borderWidth'), 2);
        expect(_option(point, 'radius'), 3);
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
        expect(_option(point, 'radius'), 4.2);

        await triggerMouseEvent(chart, 'mouseout', point);
        expect(_option(point, 'backgroundColor'), 'rgb(100, 150, 200)');
        expect(_option(point, 'borderColor'), 'rgb(50, 100, 150)');
        expect(_option(point, 'borderWidth'), 2);
        expect(_option(point, 'radius'), 3);
      });
    });

    testWidgets('should allow pointBorderWidth to be set to 0', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'radar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 15, 0, 4],
              'pointBorderWidth': 0,
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
      });

      final meta = chart.getDatasetMeta(0);
      final point = meta.data[0];
      expect(_option(point, 'borderWidth'), 0);
    });

    testWidgets('should use the pointRadius setting over the radius setting', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'radar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 15, 0, 4],
              'pointRadius': 10,
              'radius': 15,
            },
            <String, Object?>{
              'data': <Object?>[20, 20, 20, 20],
              'radius': 20,
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
      });

      final meta0 = chart.getDatasetMeta(0);
      final meta1 = chart.getDatasetMeta(1);
      expect(_option(meta0.data[0], 'radius'), 10);
      expect(_option(meta1.data[0], 'radius'), 20);
    });

    testWidgets('should return id for value scale', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'radar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 15, 0, 4],
              'pointBorderWidth': 0,
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'test': <String, Object?>{'axis': 'r'},
          },
        },
      });

      final meta = chart.getDatasetMeta(0);
      expect(meta.vScale!.id, 'test');
    });

    // controller.radar.tests.js:410 it('should not override tooltip title
    // and label callbacks'): it reads chart.tooltip.
    test(
      'should not override tooltip title and label callbacks',
      () {},
      skip: 'blocked: plugin.tooltip',
    );
  });
}
