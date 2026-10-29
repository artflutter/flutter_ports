// Ported from Chart.js v4.6.1 test/specs/controller.radar.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
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
// - `toEqual` of an object is `jasmineEquals`. `jasmine.objectContaining` is
//   `objectContaining`. `.withContext(i)` is `reason: '$i'`.
// - Jasmine `this.chart` is a `late` variable of the group closure. The
//   `beforeEach` of the group `Interactions` acquires a chart. Thus it is a
//   local function `beforeEach()`, and each test calls it first.
//
// The case :103 reads the control points of the points. For a radar line,
// only the `beforeDraw` hook of the filler plugin calls
// `updateControlPoints` (plugin.filler/index.js:51-61, element.line.js:299).
// flutter_test_config.dart registers the filler plugin with the other
// built-in components.
//
// The tooltip case (:410) reads `chart.tooltip`, the field of `Chart` (a
// `types.TooltipModel?`), through the interface.
// `chart.options.plugins.tooltip = value` writes the key `tooltip` of the
// Map `chart.options['plugins']`.

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

    // :103 The control points come from the `beforeDraw` hook of the filler
    // plugin (plugin.filler/index.js:61).
    testWidgets('should update elements', (tester) async {
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
        'options': <String, Object?>{
          'showLine': true,
          'plugins': <String, Object?>{'legend': false, 'title': false},
          'elements': <String, Object?>{
            'line': <String, Object?>{
              'backgroundColor': 'rgb(255, 0, 0)',
              'borderCapStyle': 'round',
              'borderColor': 'rgb(0, 255, 0)',
              'borderDash': <Object?>[],
              'borderDashOffset': 0.1,
              'borderJoinStyle': 'bevel',
              'borderWidth': 1.2,
              'fill': true,
              'tension': 0.1,
            },
            'point': <String, Object?>{
              'backgroundColor': jsGet(Chart.defaults, 'backgroundColor'),
              'borderWidth': 1,
              'borderColor': jsGet(Chart.defaults, 'borderColor'),
              'hitRadius': 1,
              'hoverRadius': 4,
              'hoverBorderWidth': 1,
              'radius': 3,
              'pointStyle': 'circle',
            },
          },
        },
      });

      final meta = chart.getDatasetMeta(0);

      chart.reset(); // reset first

      // Line element
      expect(
        _options(meta.dataset!),
        objectContaining(<String, Object?>{
          'backgroundColor': 'rgb(255, 0, 0)',
          'borderCapStyle': 'round',
          'borderColor': 'rgb(0, 255, 0)',
          'borderDash': <Object?>[],
          'borderDashOffset': 0.1,
          'borderJoinStyle': 'bevel',
          'borderWidth': 1.2,
          'fill': true,
          'tension': 0.1,
        }),
      );

      const resetValues = [
        (x: 256, y: 256),
        (x: 256, y: 256),
        (x: 256, y: 256),
        (x: 256, y: 256),
      ];
      for (var i = 0; i < resetValues.length; i++) {
        final expected = resetValues[i];
        expect(meta.data[i].x, toBeCloseToPixel(expected.x), reason: '$i');
        expect(meta.data[i].y, toBeCloseToPixel(expected.y), reason: '$i');
        expect(
          _options(meta.data[i]),
          objectContaining(<String, Object?>{
            'backgroundColor': jsGet(Chart.defaults, 'backgroundColor'),
            'borderWidth': 1,
            'borderColor': jsGet(Chart.defaults, 'borderColor'),
            'hitRadius': 1,
            'radius': 3,
            'pointStyle': 'circle',
          }),
          reason: '$i',
        );
      }

      chart.update();

      const updateValues = [
        (x: 256, y: 122, cppx: 246, cppy: 122, cpnx: 272, cpny: 122),
        (x: 457, y: 256, cppx: 457, cppy: 249, cpnx: 457, cpny: 262),
        (x: 256, y: 256, cppx: 277, cppy: 256, cpnx: 250, cpny: 256),
        (x: 202, y: 256, cppx: 202, cppy: 260, cpnx: 202, cpny: 246),
      ];
      for (var i = 0; i < updateValues.length; i++) {
        final expected = updateValues[i];
        final point = meta.data[i] as PointElement;
        expect(point.x, toBeCloseToPixel(expected.x), reason: '$i');
        expect(point.y, toBeCloseToPixel(expected.y), reason: '$i');
        expect(point.cp1x, toBeCloseToPixel(expected.cppx), reason: '$i');
        expect(point.cp1y, toBeCloseToPixel(expected.cppy), reason: '$i');
        expect(point.cp2x, toBeCloseToPixel(expected.cpnx), reason: '$i');
        expect(point.cp2y, toBeCloseToPixel(expected.cpny), reason: '$i');
        expect(
          _options(point),
          objectContaining(<String, Object?>{
            'backgroundColor': jsGet(Chart.defaults, 'backgroundColor'),
            'borderWidth': 1,
            'borderColor': jsGet(Chart.defaults, 'borderColor'),
            'hitRadius': 1,
            'radius': 3,
            'pointStyle': 'circle',
          }),
          reason: '$i',
        );
      }

      // Use dataset level styles for lines & points
      _dataset(chart, 0)['tension'] = 0;
      _dataset(chart, 0)['backgroundColor'] = 'rgb(98, 98, 98)';
      _dataset(chart, 0)['borderColor'] = 'rgb(8, 8, 8)';
      _dataset(chart, 0)['borderWidth'] = 0.55;
      _dataset(chart, 0)['borderCapStyle'] = 'butt';
      _dataset(chart, 0)['borderDash'] = <Object?>[2, 3];
      _dataset(chart, 0)['borderDashOffset'] = 7;
      _dataset(chart, 0)['borderJoinStyle'] = 'miter';
      _dataset(chart, 0)['fill'] = false;

      // point styles
      _dataset(chart, 0)['pointRadius'] = 22;
      _dataset(chart, 0)['hitRadius'] = 3.3;
      _dataset(chart, 0)['pointBackgroundColor'] = 'rgb(128, 129, 130)';
      _dataset(chart, 0)['pointBorderColor'] = 'rgb(56, 57, 58)';
      _dataset(chart, 0)['pointBorderWidth'] = 1.123;

      chart.update();

      expect(
        _options(meta.dataset!),
        objectContaining(<String, Object?>{
          'backgroundColor': 'rgb(98, 98, 98)',
          'borderCapStyle': 'butt',
          'borderColor': 'rgb(8, 8, 8)',
          'borderDash': <Object?>[2, 3],
          'borderDashOffset': 7,
          'borderJoinStyle': 'miter',
          'borderWidth': 0.55,
          'fill': false,
          'tension': 0,
        }),
      );

      // Since tension is now 0, we don't care about the control points
      const tensionZeroValues = [
        (x: 256, y: 122),
        (x: 457, y: 256),
        (x: 256, y: 256),
        (x: 202, y: 256),
      ];
      for (var i = 0; i < tensionZeroValues.length; i++) {
        final expected = tensionZeroValues[i];
        expect(meta.data[i].x, toBeCloseToPixel(expected.x), reason: '$i');
        expect(meta.data[i].y, toBeCloseToPixel(expected.y), reason: '$i');
        expect(
          _options(meta.data[i]),
          objectContaining(<String, Object?>{
            'backgroundColor': 'rgb(128, 129, 130)',
            'borderWidth': 1.123,
            'borderColor': 'rgb(56, 57, 58)',
            'hitRadius': 3.3,
            'radius': 22,
            'pointStyle': 'circle',
          }),
          reason: '$i',
        );
      }
    });

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

    // :410
    testWidgets('should not override tooltip title and label callbacks', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'radar',
        'data': <String, Object?>{
          'labels': <Object?>['Label 1', 'Label 2'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[21, 79],
              'label': 'Dataset 1',
            },
            <String, Object?>{
              'data': <Object?>[33, 67],
              'label': 'Dataset 2',
            },
          ],
        },
        'options': <String, Object?>{
          'responsive': true,
          'maintainAspectRatio': true,
        },
      });
      final tooltip = chart.tooltip!;
      final point = chart.getDatasetMeta(0).data[0];

      await triggerMouseEvent(chart, 'mousemove', point);

      expect(tooltip.title, jasmineEquals(<Object?>['Label 1']));
      expect(
        tooltip.body,
        jasmineEquals(<Object?>[
          <String, Object?>{
            'before': <Object?>[],
            'lines': <Object?>['Dataset 1: 21'],
            'after': <Object?>[],
          },
        ]),
      );

      (chart.options['plugins']! as Map<String, Object?>)['tooltip'] =
          <String, Object?>{'mode': 'dataset'};
      chart.update();
      await triggerMouseEvent(chart, 'mousemove', point);

      expect(tooltip.title, jasmineEquals(<Object?>['Dataset 1']));
      expect(
        tooltip.body,
        jasmineEquals(<Object?>[
          <String, Object?>{
            'before': <Object?>[],
            'lines': <Object?>['Label 1: 21'],
            'after': <Object?>[],
          },
          <String, Object?>{
            'before': <Object?>[],
            'lines': <Object?>['Label 2: 79'],
            'after': <Object?>[],
          },
        ]),
      );
    });
  });
}
