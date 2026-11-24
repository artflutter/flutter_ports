// Ported from Chart.js v4.6.1 test/specs/controller.doughnut.tests.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native color test inputs.
@TestOn('vm')
library;

import 'dart:math' as math;
import 'dart:ui' as native_ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/draw_recorder.dart';

// `Chart` is the class of core.controller.dart. The spec runs on the VM: a
// chart reaches the chart host and dart:ui. Each chart case is a
// `testWidgets` case with the harness of Chart.js ADR 0022, section 2. The
// conventions are those of Chart.js ADR 0030, section 13, with items 1
// and 5 to 8 of Chart.js ADR 0180.
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
// - `spyOn(meta.data[i], 'draw')` is `recordElementDraws(meta, i)` of
//   test/support/draw_recorder.dart.
// - `toEqual` of a value is `equals`, of a tooltip body item `_bodyItem`
//   (the fields of `TooltipBodyItem`). `jasmine.objectContaining` of the
//   element options is `isA<...Options>()` with `having` for each key.
// - `toBeCloseTo(e, p)` is `closeTo(e, 5e-(p + 1))`.
// - Jasmine `this.chart` is a `late` variable of the group closure. The
//   `beforeEach` of the group `Interactions` acquires a chart. Thus it is a
//   local function `beforeEach()`, and each test calls it first.
//
// The tooltip case (:418) reads `chart.tooltip`, the field of `Chart` (a
// `types.TooltipModel?`), through the interface.
// `chart.options.plugins.tooltip = value` writes the key `tooltip` of the
// options view `chart.options['plugins']`. `{mode: 'dataset'}` is the
// `TooltipOptions` of that mode, the one options object of the tooltip
// (Chart.js ADR 0192).

/// `chart.data.datasets[index]`.
JsObjectFace _dataset(Chart chart, int index) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>)[index]! as JsObjectFace;

/// `meta.data[index]` of [meta], an arc.
ArcElement _arc(ChartMeta meta, int index) => meta.data[index] as ArcElement;

/// The resolved options of the arc [element].
ArcOptions _arcOptionsOf(Object element) =>
    (element as Element).options! as ArcOptions;

/// The options of the arcs of :92-98, :191-197 and :237-243.
AnyObject _arcOptions() => <String, Object?>{
  'arc': <String, Object?>{
    'backgroundColor': const ChartPaint.solid(
      native_ui.Color.fromRGBO(255, 0, 0, 1),
    ),
    'borderColor': const ChartPaint.solid(
      native_ui.Color.fromRGBO(0, 0, 255, 1),
    ),
    'borderWidth': 2.0,
  },
};

/// The tooltip body item `{before: [], lines: lines, after: []}`
/// (plugin.tooltip.js:559-563).
Matcher _bodyItem(List<String> lines) => isA<TooltipBodyItem>()
    .having((b) => b.before, 'before', isEmpty)
    .having((b) => b.lines, 'lines', equals(lines))
    .having((b) => b.after, 'after', isEmpty);

void main() {
  group('Chart.controllers.doughnut', () {
    group('auto', fixture.specs('controller.doughnut'));

    // :4 The case also reads `Chart.controllers.pie`. flutter_test_config.dart
    // registers the pie controller with the built-in components.
    test('should be registered as dataset controller', () {
      expect(Chart.registry.controllers.items['doughnut'], isA<JsClass>());
      expect(Chart.registry.controllers.items['pie'], isA<JsClass>());
    });

    testWidgets('should be constructed', (tester) async {
      final chart = acquireChartRoot(
        ChartConfigurationScope()
          ..type = 'doughnut'
          ..data = (ChartDataScope()
            ..datasets = [
              scopeFromMap(
                DoughnutControllerDatasetOptionsScope(),
                <String, Object?>{'data': <Object?>[]},
              ),
            ]
            ..labels = <Object?>[]),
      );

      final meta = chart.getDatasetMeta(0);
      expect(meta.type, 'doughnut');
      expect(meta.controller, isNot(same(undefined)));
      expect(meta.controller, isNotNull);
      expect(meta.controller!.index, 0);
      expect(meta.data, isEmpty);

      meta.controller!.updateIndex(1);
      expect(meta.controller!.index, 1);
    });

    testWidgets(
      'should create arc elements for each data item during initialization',
      (tester) async {
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..type = 'doughnut'
            ..data = (ChartDataScope()
              ..datasets = [
                scopeFromMap(
                  DoughnutControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'data': <Object?>[10.0, 15.0, 0.0, 4.0],
                  },
                ),
              ]
              ..labels = <Object?>[]),
        );

        final meta = chart.getDatasetMeta(0);
        expect(meta.data.length, 4); // 4 arcs created
        expect(meta.data[0], isA<ArcElement>());
        expect(meta.data[1], isA<ArcElement>());
        expect(meta.data[2], isA<ArcElement>());
        expect(meta.data[3], isA<ArcElement>());
      },
    );

    testWidgets('should default arc spacingMode to angular', (tester) async {
      final chart = acquireChartRoot(
        ChartConfigurationScope()
          ..type = 'doughnut'
          ..data = (ChartDataScope()
            ..datasets = [
              scopeFromMap(
                DoughnutControllerDatasetOptionsScope(),
                <String, Object?>{
                  'data': <Object?>[10.0, 20.0],
                },
              ),
            ]
            ..labels = <Object?>['a', 'b']),
      );

      final meta = chart.getDatasetMeta(0);
      expect(_arcOptionsOf(meta.data[0]).spacingMode, ArcSpacingMode.angular);
      expect(_arcOptionsOf(meta.data[1]).spacingMode, ArcSpacingMode.angular);
    });

    testWidgets('should reset and update elements', (tester) async {
      final chart = acquireChartRoot(
        ChartConfigurationScope()
          ..type = 'doughnut'
          ..data = (ChartDataScope()
            ..datasets = [
              scopeFromMap(
                DoughnutControllerDatasetOptionsScope(),
                <String, Object?>{
                  'data': <Object?>[1.0, 2.0, 3.0, 4.0],
                  'hidden': true,
                },
              ),
              scopeFromMap(
                DoughnutControllerDatasetOptionsScope(),
                <String, Object?>{
                  'data': <Object?>[5.0, 6.0, 0.0, 7.0],
                },
              ),
              scopeFromMap(
                DoughnutControllerDatasetOptionsScope(),
                <String, Object?>{
                  'data': <Object?>[8.0, 9.0, 10.0, 11.0],
                },
              ),
            ]
            ..labels = <Object?>['label0', 'label1', 'label2', 'label3'])
          ..options = scopeFromMap(ChartOptionsScope(), <String, Object?>{
            'plugins': <String, Object?>{'legend': false, 'title': false},
            'animation': <String, Object?>{
              'duration': 0.0,
              'animateRotate': true,
              'animateScale': false,
            },
            // DIVERGES(chartjs): adapt-length-objects, the length class.
            'cutout': const PercentRadius(50),
            'rotation': 0.0,
            'circumference': 360.0,
            'elements': _arcOptions(),
          }),
      );

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
        expect(arc.circumference, closeTo(c, 5e-9));
        expect(arc.startAngle, toBeCloseToPixel(math.pi * -0.5));
        expect(arc.endAngle, toBeCloseToPixel(math.pi * -0.5));
        expect(
          arc.options,
          isA<ArcOptions>()
              .having(
                (o) => o.backgroundColor,
                'backgroundColor',
                const ChartPaint.solid(native_ui.Color.fromRGBO(255, 0, 0, 1)),
              )
              .having(
                (o) => o.borderColor,
                'borderColor',
                const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 255, 1)),
              )
              .having((o) => o.borderWidth, 'borderWidth', 2),
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
        expect(arc.circumference, closeTo(c, 5e-9));
        expect(arc.startAngle, closeTo(s, 5e-9));
        expect(arc.endAngle, closeTo(e, 5e-9));
        expect(
          arc.options,
          isA<ArcOptions>()
              .having(
                (o) => o.backgroundColor,
                'backgroundColor',
                const ChartPaint.solid(native_ui.Color.fromRGBO(255, 0, 0, 1)),
              )
              .having(
                (o) => o.borderColor,
                'borderColor',
                const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 255, 1)),
              )
              .having((o) => o.borderWidth, 'borderWidth', 2),
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
      final chart = acquireChartRoot(
        ChartConfigurationScope()
          ..type = 'doughnut'
          ..data = (ChartDataScope()
            ..datasets = [
              scopeFromMap(
                DoughnutControllerDatasetOptionsScope(),
                <String, Object?>{
                  'data': <Object?>[2.0, 4.0],
                  'hidden': true,
                },
              ),
              scopeFromMap(
                DoughnutControllerDatasetOptionsScope(),
                <String, Object?>{
                  'data': <Object?>[1.0, 3.0],
                },
              ),
              scopeFromMap(
                DoughnutControllerDatasetOptionsScope(),
                <String, Object?>{
                  'data': <Object?>[1.0, 0.0],
                },
              ),
            ]
            ..labels = <Object?>['label0', 'label1', 'label2'])
          ..options = scopeFromMap(ChartOptionsScope(), <String, Object?>{
            'plugins': <String, Object?>{'legend': false, 'title': false},
            // DIVERGES(chartjs): adapt-length-objects, the length class.
            'cutout': const PercentRadius(50),
            'rotation': 270.0,
            'circumference': 90.0,
            'elements': _arcOptions(),
          }),
      );

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
        expect(arc.circumference, closeTo(c, 5e-9));
        expect(arc.startAngle, closeTo(s, 5e-9));
        expect(arc.endAngle, closeTo(e, 5e-9));
      }
    });

    testWidgets('should treat negative values as positive', (tester) async {
      final chart = acquireChartRoot(
        ChartConfigurationScope()
          ..type = 'doughnut'
          ..data = (ChartDataScope()
            ..datasets = [
              scopeFromMap(
                DoughnutControllerDatasetOptionsScope(),
                <String, Object?>{
                  'data': <Object?>[-1.0, -3.0],
                },
              ),
            ]
            ..labels = <Object?>['label0', 'label1'])
          ..options = scopeFromMap(ChartOptionsScope(), <String, Object?>{
            'plugins': <String, Object?>{'legend': false, 'title': false},
            // DIVERGES(chartjs): adapt-length-objects, the length class.
            'cutout': const PercentRadius(50),
            'rotation': 270.0,
            'circumference': 90.0,
            'elements': _arcOptions(),
          }),
      );

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
        expect(arc.circumference, closeTo(c, 5e-9));
        expect(arc.startAngle, closeTo(s, 5e-9));
        expect(arc.endAngle, closeTo(e, 5e-9));
      }
    });

    testWidgets('should draw all arcs', (tester) async {
      final chart = acquireChartRoot(
        ChartConfigurationScope()
          ..type = 'doughnut'
          ..data = (ChartDataScope()
            ..datasets = [
              scopeFromMap(
                DoughnutControllerDatasetOptionsScope(),
                <String, Object?>{
                  'data': <Object?>[10.0, 15.0, 0.0, 4.0],
                },
              ),
            ]
            ..labels = <Object?>['label0', 'label1', 'label2', 'label3']),
      );

      final meta = chart.getDatasetMeta(0);

      final calls0 = recordElementDraws(meta, 0);
      final calls1 = recordElementDraws(meta, 1);
      final calls2 = recordElementDraws(meta, 2);
      final calls3 = recordElementDraws(meta, 3);

      chart.update();

      expect(calls0, hasLength(1));
      expect(calls1, hasLength(1));
      expect(calls2, hasLength(1));
      expect(calls3, hasLength(1));
    });

    testWidgets(
      'should calculate radiuses based on the border widths of the visible '
      'outermost dataset',
      (tester) async {
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..type = 'doughnut'
            ..data = (ChartDataScope()
              ..datasets = [
                scopeFromMap(
                  DoughnutControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'data': <Object?>[2.0, 4.0],
                    'borderWidth': 4.0,
                    'hidden': true,
                  },
                ),
                scopeFromMap(
                  DoughnutControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'data': <Object?>[1.0, 3.0],
                    'borderWidth': 8.0,
                  },
                ),
                scopeFromMap(
                  DoughnutControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'data': <Object?>[1.0, 0.0],
                    'borderWidth': 12.0,
                  },
                ),
              ]
              ..labels = <Object?>['label0', 'label1'])
            ..options = scopeFromMap(ChartOptionsScope(), <String, Object?>{
              'plugins': <String, Object?>{'legend': false, 'title': false},
            }),
        )..update(); // :313 `chart.update()`

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
        chart = acquireChartRoot(
          ChartConfigurationScope()
            ..type = 'doughnut'
            ..data = (ChartDataScope()
              ..labels = <Object?>['label1', 'label2', 'label3', 'label4']
              ..datasets = [
                scopeFromMap(
                  DoughnutControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'data': <Object?>[10.0, 15.0, 0.0, 4.0],
                  },
                ),
              ])
            ..options = scopeFromMap(ChartOptionsScope(), <String, Object?>{
              // DIVERGES(chartjs): adapt-length-objects, the length class.
              'cutout': const PercentRadius(50),
              'elements': <String, Object?>{
                'arc': <String, Object?>{
                  'backgroundColor': const ChartPaint.solid(
                    native_ui.Color.fromRGBO(100, 150, 200, 1),
                  ),
                  'borderColor': const ChartPaint.solid(
                    native_ui.Color.fromRGBO(50, 100, 150, 1),
                  ),
                  'borderWidth': 2.0,
                },
              },
            }),
        );
      }

      testWidgets('should handle default hover styles', (tester) async {
        beforeEach();
        final arc = chart.getDatasetMeta(0).data[0];

        await triggerMouseEvent(chart, 'mousemove', arc);
        expect(
          _arcOptionsOf(arc).backgroundColor,
          const ChartPaint.solid(native_ui.Color.fromRGBO(49, 135, 221, 1)),
        );
        expect(
          _arcOptionsOf(arc).borderColor,
          const ChartPaint.solid(native_ui.Color.fromRGBO(23, 90, 157, 1)),
        );
        expect(_arcOptionsOf(arc).borderWidth, 2);

        await triggerMouseEvent(chart, 'mouseout', arc);
        expect(
          _arcOptionsOf(arc).backgroundColor,
          const ChartPaint.solid(native_ui.Color.fromRGBO(100, 150, 200, 1)),
        );
        expect(
          _arcOptionsOf(arc).borderColor,
          const ChartPaint.solid(native_ui.Color.fromRGBO(50, 100, 150, 1)),
        );
        expect(_arcOptionsOf(arc).borderWidth, 2);
      });

      testWidgets('should handle hover styles defined via dataset properties', (
        tester,
      ) async {
        beforeEach();
        final arc = chart.getDatasetMeta(0).data[0];

        merge(_dataset(chart, 0), <String, Object?>{
          'hoverBackgroundColor': const ChartPaint.solid(
            native_ui.Color.fromRGBO(200, 100, 150, 1),
          ),
          'hoverBorderColor': const ChartPaint.solid(
            native_ui.Color.fromRGBO(150, 50, 100, 1),
          ),
          'hoverBorderWidth': 8.4,
        });

        chart.update();

        await triggerMouseEvent(chart, 'mousemove', arc);
        expect(
          _arcOptionsOf(arc).backgroundColor,
          const ChartPaint.solid(native_ui.Color.fromRGBO(200, 100, 150, 1)),
        );
        expect(
          _arcOptionsOf(arc).borderColor,
          const ChartPaint.solid(native_ui.Color.fromRGBO(150, 50, 100, 1)),
        );
        expect(_arcOptionsOf(arc).borderWidth, 8.4);

        await triggerMouseEvent(chart, 'mouseout', arc);
        expect(
          _arcOptionsOf(arc).backgroundColor,
          const ChartPaint.solid(native_ui.Color.fromRGBO(100, 150, 200, 1)),
        );
        expect(
          _arcOptionsOf(arc).borderColor,
          const ChartPaint.solid(native_ui.Color.fromRGBO(50, 100, 150, 1)),
        );
        expect(_arcOptionsOf(arc).borderWidth, 2);
      });

      testWidgets('should handle hover styles defined via element options', (
        tester,
      ) async {
        beforeEach();
        final arc = chart.getDatasetMeta(0).data[0];

        merge(jsGet(jsGet(chart.options, 'elements'), 'arc'), <String, Object?>{
          'hoverBackgroundColor': const ChartPaint.solid(
            native_ui.Color.fromRGBO(200, 100, 150, 1),
          ),
          'hoverBorderColor': const ChartPaint.solid(
            native_ui.Color.fromRGBO(150, 50, 100, 1),
          ),
          'hoverBorderWidth': 8.4,
        });

        chart.update();

        await triggerMouseEvent(chart, 'mousemove', arc);
        expect(
          _arcOptionsOf(arc).backgroundColor,
          const ChartPaint.solid(native_ui.Color.fromRGBO(200, 100, 150, 1)),
        );
        expect(
          _arcOptionsOf(arc).borderColor,
          const ChartPaint.solid(native_ui.Color.fromRGBO(150, 50, 100, 1)),
        );
        expect(_arcOptionsOf(arc).borderWidth, 8.4);

        await triggerMouseEvent(chart, 'mouseout', arc);
        expect(
          _arcOptionsOf(arc).backgroundColor,
          const ChartPaint.solid(native_ui.Color.fromRGBO(100, 150, 200, 1)),
        );
        expect(
          _arcOptionsOf(arc).borderColor,
          const ChartPaint.solid(native_ui.Color.fromRGBO(50, 100, 150, 1)),
        );
        expect(_arcOptionsOf(arc).borderWidth, 2);
      });
    });

    // :418
    testWidgets('should not override tooltip title and label callbacks', (
      tester,
    ) async {
      final chart = acquireChartRoot(
        ChartConfigurationScope()
          ..type = 'doughnut'
          ..data = (ChartDataScope()
            ..labels = <Object?>['Label 1', 'Label 2']
            ..datasets = [
              scopeFromMap(
                DoughnutControllerDatasetOptionsScope(),
                <String, Object?>{
                  'data': <Object?>[21, 79],
                  'label': 'Dataset 1',
                },
              ),
              scopeFromMap(
                DoughnutControllerDatasetOptionsScope(),
                <String, Object?>{
                  'data': <Object?>[33, 67],
                  'label': 'Dataset 2',
                },
              ),
            ])
          ..options = scopeFromMap(ChartOptionsScope(), <String, Object?>{
            'responsive': true,
            'maintainAspectRatio': true,
          }),
      );
      final tooltip = chart.tooltip!;
      final point = chart.getDatasetMeta(0).data[0];

      await triggerMouseEvent(chart, 'mousemove', point);

      expect(tooltip.title, equals(<String>['Label 1']));
      expect(
        tooltip.body,
        equals(<Matcher>[
          _bodyItem(['Dataset 1: 21']),
        ]),
      );

      (chart.options['plugins']! as JsObjectFace)['tooltip'] =
          const TooltipOptions(mode: DatasetInteractionMode());
      chart.update();
      await triggerMouseEvent(chart, 'mousemove', point);

      expect(tooltip.title, equals(<String>['Dataset 1']));
      expect(
        tooltip.body,
        equals(<Matcher>[
          _bodyItem(['Label 1: 21']),
          _bodyItem(['Label 2: 79']),
        ]),
      );
    });
  });
}
