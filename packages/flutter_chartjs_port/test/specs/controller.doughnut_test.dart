// Ported from Chart.js v4.5.1+7169e651 test/specs/controller.doughnut.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'dart:math' as math;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/controllers/controller.doughnut.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/elements/element.arc.dart';
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
// flutter_test_config.dart registers the doughnut controller with the
// built-in components before main(), as index.umd.ts:28 does (Chart.js ADR
// 0030, section 3 item 4).
//
// The spec forms:
// - `Chart.controllers` is `registry.controllers.items` (index.umd.ts:35):
//   `Chart.registry.controllers.items`.
// - `Chart.elements.ArcElement` is the class ArcElement of
//   element.arc.dart. `instanceof` is `isA`.
// - `Chart.helpers.merge` is `merge` of helpers.core.dart. A write into
//   `chart.options.elements.arc` writes into the resolver of the last
//   `jsGet`.
// - `chart.data.datasets[i]` is `_dataset(chart, i)`. `meta.data[i]` is an
//   `ArcElement` (`_arc`).
// - `meta.controller` is a `DoughnutController` where the spec reads its
//   own members (`outerRadius`, `innerRadius`, `getMaxBorderWidth`).
// - `spyOn(meta.data[i], 'draw')` is `spyOnElementDraw(meta, i)` of
//   test/support/jasmine.dart.
// - `toEqual` of an object is `jasmineEquals`. `jasmine.objectContaining` is
//   `objectContaining`. `toBeCloseTo` is `_toBeCloseTo`.
// - Jasmine `this.chart` is a `late` variable of the group closure. The
//   `beforeEach` of the group `Interactions` acquires a chart. Thus it is a
//   local function `beforeEach()`, and each test calls it first.
//
// The tooltip case (:418) reads `chart.tooltip`, the field of `Chart` (a
// `types.TooltipModel?`), through the interface.
// `chart.options.plugins.tooltip = value` writes the key `tooltip` of the
// Map `chart.options['plugins']`.

/// Jasmine `toBeCloseTo(expected, precision)`: within half a unit in the
/// `precision`-th decimal place. Jasmine's default precision is 2.
///
/// Jasmine 3.99 rounds the difference to `precision + 1` places before it
/// compares, so it also accepts differences up to about 1.1 times this bound.
Matcher _toBeCloseTo(double expected, [int precision = 2]) =>
    // js-ok: the exponent is an int, as in Jasmine's Math.pow(10, -precision).
    closeTo(expected, math.pow(10.0, -precision) / 2);

/// `chart.data.datasets[index]`.
AnyObject _dataset(Chart chart, int index) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>)[index]! as AnyObject;

/// `meta.data[index]` of [meta], an arc.
ArcElement _arc(ChartMeta meta, int index) => meta.data[index] as ArcElement;

/// `element.options[key]` of [element].
Object? _option(Object element, String key) =>
    jsGet((element as Element).options, key);

/// The options of the arcs of :92-98, :191-197 and :237-243.
AnyObject _arcOptions() => <String, Object?>{
  'arc': <String, Object?>{
    'backgroundColor': 'rgb(255, 0, 0)',
    'borderColor': 'rgb(0, 0, 255)',
    'borderWidth': 2.0,
  },
};

void main() {
  group('Chart.controllers.doughnut', () {
    group('auto', fixture.specs('controller.doughnut'));

    // :4 The case also reads `Chart.controllers.pie`. flutter_test_config.dart
    // registers the pie controller with the built-in components.
    test('should be registered as dataset controller', () {
      expect(
        jsTypeof(Chart.registry.controllers.items['doughnut']),
        'function',
      );
      expect(jsTypeof(Chart.registry.controllers.items['pie']), 'function');
    });

    testWidgets('should be constructed', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'doughnut',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{'data': <Object?>[]},
          ],
          'labels': <Object?>[],
        },
      });

      final meta = chart.getDatasetMeta(0);
      expect(meta.type, 'doughnut');
      expect(meta.controller, isNot(same(undefined)));
      expect(meta.controller, isNotNull);
      expect(meta.controller!.index, 0);
      expect(meta.data, jasmineEquals(<Object?>[]));

      meta.controller!.updateIndex(1);
      expect(meta.controller!.index, 1);
    });

    testWidgets(
      'should create arc elements for each data item during initialization',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'doughnut',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10.0, 15.0, 0.0, 4.0],
              },
            ],
            'labels': <Object?>[],
          },
        });

        final meta = chart.getDatasetMeta(0);
        expect(meta.data.length, 4); // 4 arcs created
        expect(meta.data[0], isA<ArcElement>());
        expect(meta.data[1], isA<ArcElement>());
        expect(meta.data[2], isA<ArcElement>());
        expect(meta.data[3], isA<ArcElement>());
      },
    );

    testWidgets('should default arc spacingMode to angular', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'doughnut',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10.0, 20.0],
            },
          ],
          'labels': <Object?>['a', 'b'],
        },
      });

      final meta = chart.getDatasetMeta(0);
      expect(_option(meta.data[0], 'spacingMode'), 'angular');
      expect(_option(meta.data[1], 'spacingMode'), 'angular');
    });

    testWidgets('should reset and update elements', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'doughnut',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1.0, 2.0, 3.0, 4.0],
              'hidden': true,
            },
            <String, Object?>{
              'data': <Object?>[5.0, 6.0, 0.0, 7.0],
            },
            <String, Object?>{
              'data': <Object?>[8.0, 9.0, 10.0, 11.0],
            },
          ],
          'labels': <Object?>['label0', 'label1', 'label2', 'label3'],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{'legend': false, 'title': false},
          'animation': <String, Object?>{
            'duration': 0.0,
            'animateRotate': true,
            'animateScale': false,
          },
          'cutout': '50%',
          'rotation': 0.0,
          'circumference': 360.0,
          'elements': _arcOptions(),
        },
      });

      final meta = chart.getDatasetMeta(1);

      meta.controller!.reset(); // reset first

      expect(meta.data.length, 4);

      for (final (i, (:c)) in <({double c})>[
        (c: 0),
        (c: 0),
        (c: 0),
        (c: 0),
      ].indexed) {
        final arc = _arc(meta, i);
        expect(arc.x, toBeCloseToPixel(256));
        expect(arc.y, toBeCloseToPixel(256));
        expect(arc.outerRadius, toBeCloseToPixel(256));
        expect(arc.innerRadius, toBeCloseToPixel(192));
        expect(arc.circumference, _toBeCloseTo(c, 8));
        expect(arc.startAngle, toBeCloseToPixel(math.pi * -0.5));
        expect(arc.endAngle, toBeCloseToPixel(math.pi * -0.5));
        expect(
          arc.options,
          objectContaining(<String, Object?>{
            'backgroundColor': 'rgb(255, 0, 0)',
            'borderColor': 'rgb(0, 0, 255)',
            'borderWidth': 2,
          }),
        );
      }

      chart.update();

      for (final (i, (:c, :s, :e)) in <({double c, double s, double e})>[
        (c: 1.7453292519, s: -1.5707963267, e: 0.1745329251),
        (c: 2.0943951023, s: 0.1745329251, e: 2.2689280275),
        (c: 0, s: 2.2689280275, e: 2.2689280275),
        (c: 2.4434609527, s: 2.2689280275, e: 4.7123889803),
      ].indexed) {
        final arc = _arc(meta, i);
        expect(arc.x, toBeCloseToPixel(256));
        expect(arc.y, toBeCloseToPixel(256));
        expect(arc.outerRadius, toBeCloseToPixel(256));
        expect(arc.innerRadius, toBeCloseToPixel(192));
        expect(arc.circumference, _toBeCloseTo(c, 8));
        expect(arc.startAngle, _toBeCloseTo(s, 8));
        expect(arc.endAngle, _toBeCloseTo(e, 8));
        expect(
          arc.options,
          objectContaining(<String, Object?>{
            'backgroundColor': 'rgb(255, 0, 0)',
            'borderColor': 'rgb(0, 0, 255)',
            'borderWidth': 2,
          }),
        );
      }

      // Change the amount of data and ensure that arcs are updated
      // accordingly
      _dataset(chart, 1)['data'] = <Object?>[
        1.0,
        2.0,
      ]; // remove 2 elements from dataset 0
      chart.update();

      expect(meta.data.length, 2);
      expect(meta.data[0], isA<ArcElement>());
      expect(meta.data[1], isA<ArcElement>());

      // Add data
      _dataset(chart, 1)['data'] = <Object?>[1.0, 2.0, 3.0, 4.0];
      chart.update();

      expect(meta.data.length, 4);
      expect(meta.data[0], isA<ArcElement>());
      expect(meta.data[1], isA<ArcElement>());
      expect(meta.data[2], isA<ArcElement>());
      expect(meta.data[3], isA<ArcElement>());
    });

    testWidgets('should rotate and limit circumference', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'doughnut',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[2.0, 4.0],
              'hidden': true,
            },
            <String, Object?>{
              'data': <Object?>[1.0, 3.0],
            },
            <String, Object?>{
              'data': <Object?>[1.0, 0.0],
            },
          ],
          'labels': <Object?>['label0', 'label1', 'label2'],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{'legend': false, 'title': false},
          'cutout': '50%',
          'rotation': 270.0,
          'circumference': 90.0,
          'elements': _arcOptions(),
        },
      });

      final meta = chart.getDatasetMeta(1);

      expect(meta.data.length, 2);

      // Only startAngle, endAngle and circumference should be different.
      for (final (i, (:c, :s, :e)) in <({double c, double s, double e})>[
        (c: math.pi / 8, s: math.pi, e: math.pi + math.pi / 8),
        (
          c: 3 * math.pi / 8,
          s: math.pi + math.pi / 8,
          e: math.pi + math.pi / 2,
        ),
      ].indexed) {
        final arc = _arc(meta, i);
        expect(arc.x, toBeCloseToPixel(512));
        expect(arc.y, toBeCloseToPixel(512));
        expect(arc.outerRadius, toBeCloseToPixel(512));
        expect(arc.innerRadius, toBeCloseToPixel(384));
        expect(arc.circumference, _toBeCloseTo(c, 8));
        expect(arc.startAngle, _toBeCloseTo(s, 8));
        expect(arc.endAngle, _toBeCloseTo(e, 8));
      }
    });

    testWidgets('should treat negative values as positive', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'doughnut',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[-1.0, -3.0],
            },
          ],
          'labels': <Object?>['label0', 'label1'],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{'legend': false, 'title': false},
          'cutout': '50%',
          'rotation': 270.0,
          'circumference': 90.0,
          'elements': _arcOptions(),
        },
      });

      final meta = chart.getDatasetMeta(0);

      expect(meta.data.length, 2);

      // Only startAngle, endAngle and circumference should be different.
      for (final (i, (:c, :s, :e)) in <({double c, double s, double e})>[
        (c: math.pi / 8, s: math.pi, e: math.pi + math.pi / 8),
        (
          c: 3 * math.pi / 8,
          s: math.pi + math.pi / 8,
          e: math.pi + math.pi / 2,
        ),
      ].indexed) {
        final arc = _arc(meta, i);
        expect(arc.circumference, _toBeCloseTo(c, 8));
        expect(arc.startAngle, _toBeCloseTo(s, 8));
        expect(arc.endAngle, _toBeCloseTo(e, 8));
      }
    });

    testWidgets('should draw all arcs', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'doughnut',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10.0, 15.0, 0.0, 4.0],
            },
          ],
          'labels': <Object?>['label0', 'label1', 'label2', 'label3'],
        },
      });

      final meta = chart.getDatasetMeta(0);

      final calls0 = spyOnElementDraw(meta, 0);
      final calls1 = spyOnElementDraw(meta, 1);
      final calls2 = spyOnElementDraw(meta, 2);
      final calls3 = spyOnElementDraw(meta, 3);

      chart.update();

      expect(calls0.count(), 1);
      expect(calls1.count(), 1);
      expect(calls2.count(), 1);
      expect(calls3.count(), 1);
    });

    testWidgets(
      'should calculate radiuses based on the border widths of the visible '
      'outermost dataset',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'doughnut',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[2.0, 4.0],
                'borderWidth': 4.0,
                'hidden': true,
              },
              <String, Object?>{
                'data': <Object?>[1.0, 3.0],
                'borderWidth': 8.0,
              },
              <String, Object?>{
                'data': <Object?>[1.0, 0.0],
                'borderWidth': 12.0,
              },
            ],
            'labels': <Object?>['label0', 'label1'],
          },
          'options': <String, Object?>{
            'plugins': <String, Object?>{'legend': false, 'title': false},
          },
        })..update(); // :313 `chart.update()`

        var controller =
            chart.getDatasetMeta(0).controller! as DoughnutController;
        expect(chart.chartArea!.bottom - chart.chartArea!.top, 512);

        expect(controller.getMaxBorderWidth(), 8);
        expect(controller.outerRadius, 252);
        expect(controller.innerRadius, 189);

        controller = chart.getDatasetMeta(1).controller! as DoughnutController;
        expect(controller.getMaxBorderWidth(), 8);
        expect(controller.outerRadius, 252);
        expect(controller.innerRadius, 189);

        controller = chart.getDatasetMeta(2).controller! as DoughnutController;
        expect(controller.getMaxBorderWidth(), 8);
        expect(controller.outerRadius, 189);
        expect(controller.innerRadius, 126);
      },
    );

    group('Interactions', () {
      late Chart chart;

      // :334 `beforeEach`: it acquires a chart.
      void beforeEach() {
        chart = acquireChart(<String, Object?>{
          'type': 'doughnut',
          'data': <String, Object?>{
            'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10.0, 15.0, 0.0, 4.0],
              },
            ],
          },
          'options': <String, Object?>{
            'cutout': '50%',
            'elements': <String, Object?>{
              'arc': <String, Object?>{
                'backgroundColor': 'rgb(100, 150, 200)',
                'borderColor': 'rgb(50, 100, 150)',
                'borderWidth': 2.0,
              },
            },
          },
        });
      }

      testWidgets('should handle default hover styles', (tester) async {
        beforeEach();
        final arc = chart.getDatasetMeta(0).data[0];

        await triggerMouseEvent(chart, 'mousemove', arc);
        expect(_option(arc, 'backgroundColor'), '#3187DD');
        expect(_option(arc, 'borderColor'), '#175A9D');
        expect(_option(arc, 'borderWidth'), 2);

        await triggerMouseEvent(chart, 'mouseout', arc);
        expect(_option(arc, 'backgroundColor'), 'rgb(100, 150, 200)');
        expect(_option(arc, 'borderColor'), 'rgb(50, 100, 150)');
        expect(_option(arc, 'borderWidth'), 2);
      });

      testWidgets('should handle hover styles defined via dataset properties', (
        tester,
      ) async {
        beforeEach();
        final arc = chart.getDatasetMeta(0).data[0];

        helpers.merge(_dataset(chart, 0), <String, Object?>{
          'hoverBackgroundColor': 'rgb(200, 100, 150)',
          'hoverBorderColor': 'rgb(150, 50, 100)',
          'hoverBorderWidth': 8.4,
        });

        chart.update();

        await triggerMouseEvent(chart, 'mousemove', arc);
        expect(_option(arc, 'backgroundColor'), 'rgb(200, 100, 150)');
        expect(_option(arc, 'borderColor'), 'rgb(150, 50, 100)');
        expect(_option(arc, 'borderWidth'), 8.4);

        await triggerMouseEvent(chart, 'mouseout', arc);
        expect(_option(arc, 'backgroundColor'), 'rgb(100, 150, 200)');
        expect(_option(arc, 'borderColor'), 'rgb(50, 100, 150)');
        expect(_option(arc, 'borderWidth'), 2);
      });

      testWidgets('should handle hover styles defined via element options', (
        tester,
      ) async {
        beforeEach();
        final arc = chart.getDatasetMeta(0).data[0];

        helpers.merge(
          jsGet(jsGet(chart.options, 'elements'), 'arc'),
          <String, Object?>{
            'hoverBackgroundColor': 'rgb(200, 100, 150)',
            'hoverBorderColor': 'rgb(150, 50, 100)',
            'hoverBorderWidth': 8.4,
          },
        );

        chart.update();

        await triggerMouseEvent(chart, 'mousemove', arc);
        expect(_option(arc, 'backgroundColor'), 'rgb(200, 100, 150)');
        expect(_option(arc, 'borderColor'), 'rgb(150, 50, 100)');
        expect(_option(arc, 'borderWidth'), 8.4);

        await triggerMouseEvent(chart, 'mouseout', arc);
        expect(_option(arc, 'backgroundColor'), 'rgb(100, 150, 200)');
        expect(_option(arc, 'borderColor'), 'rgb(50, 100, 150)');
        expect(_option(arc, 'borderWidth'), 2);
      });
    });

    // :418
    testWidgets('should not override tooltip title and label callbacks', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'doughnut',
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
