// Ported from Chart.js v4.6.1 test/specs/controller.bar.tests.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-bar-thickness-class, the bar thickness values.
// DIVERGES(chartjs): adapt-scale-display-enum, the scale display values.
// DIVERGES(chartjs): adapt-stacked-option-enum, the scale stacked values.
// DIVERGES(chartjs): adapt-direct-colors, native color test inputs.
@TestOn('vm')
library;

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
// flutter_test_config.dart registers the bar controller with the built-in
// components before main(), as index.umd.ts:28 does (Chart.js ADR 0030,
// section 3 item 4).
//
// The spec forms:
// - `Chart.controllers` is `registry.controllers.items` (index.umd.ts:35):
//   `Chart.registry.controllers.items`.
// - `Chart.elements.BarElement` is the class BarElement of element.bar.dart.
//   `instanceof` is `isA`.
// - `Chart.defaults` is the static `Chart.defaults`. A property chain of the
//   spec, for example `Chart.defaults.datasets.bar`, is a chain of `jsGet`.
//   A write into a chain, for example `chart.options.elements.bar.x = v`,
//   writes into the Map of the last `jsGet`.
// - `chart.data.datasets[i]` is `_dataset(chart, i)`. `meta.data[i]` is a
//   `BarElement` (`_bar`). `meta._parsed` is `meta.parsed`.
// - `meta.controller._getStackCount` and `_getStackIndex` are
//   `getStackCount` and `getStackIndex` of BarController (Chart.js ADR 0012,
//   underscore members).
// - Jasmine `this.data`, `this.config` and `this.chart` are `late` variables
//   of the group closure. A `beforeEach` that acquires a chart is a local
//   function `beforeEach()`, and each test calls it first. An `afterEach`
//   that acquires a chart is a local function `afterEach()`, and each test
//   calls it last. A `beforeEach` without a chart is a `setUp`.
// - `spyOn(meta.data[i], 'draw')` is `recordElementDraws(meta, i)` of
//   test/support/draw_recorder.dart.
// - `toEqual` of a value is `equals`, of a tooltip body item `_bodyItem`
//   (the fields of `TooltipBodyItem`). `jasmine.objectContaining` of the
//   element options is `isA<...Options>()` with `having` for each key.
// - `toEqual` of the `{min, max}` of `getMinMax` compares the record.
// - `removeHoverStyle(bar)` has no index upstream. The port gives NaN for
//   the two absent numbers: `getStyle` reads `index || 0` and
//   `_resolveAnimations` gives the dataset context for an index that is not
//   `>= 0`, the same results as for `undefined`.
// - `ctx.resetTransform = function() {}` is a subclass of MockContext with a
//   `resetTransform` that does nothing.
//
// Three cases need the line controller of wave 2 (:70, :310, :671). The
// lift of wave 2 gave them their bodies (test-strategy spec, section 4.2).
// The tooltip case (:1808) reads `chart.tooltip`, the field of `Chart` (a
// `types.TooltipModel?`), through the interface.
// `chart.options.plugins.tooltip = value` writes the key `tooltip` of the
// options view `chart.options['plugins']`. `{mode: 'dataset'}` is the
// `TooltipOptions` of that mode, the one options object of the tooltip
// (Chart.js ADR 0192).

/// `chart.data.datasets[index]`.
JsObjectFace _dataset(Chart chart, int index) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>)[index]! as JsObjectFace;

/// `meta.data[index]` of [meta], a bar.
BarElement _bar(ChartMeta meta, int index) => meta.data[index] as BarElement;

/// `element.options` of [element].
Object? _options(Object element) => (element as Element).options;

/// The resolved options of the bar [bar].
BarOptions _barOptions(BarElement bar) => bar.options! as BarOptions;

/// The mock context of :1677-1678: `ctx.resetTransform = function() {}`.
final class _ResetTransformContext() extends MockContext {
  @override
  void resetTransform() {}
}

/// The tooltip body item `{before: [], lines: lines, after: []}`
/// (plugin.tooltip.js:559-563).
Matcher _bodyItem(List<String> lines) => isA<TooltipBodyItem>()
    .having((b) => b.before, 'before', isEmpty)
    .having((b) => b.lines, 'lines', equals(lines))
    .having((b) => b.after, 'after', isEmpty);

/// A chart of the typed [config]: its root scope through
/// `ChartConfigLowering` (Chart.js ADR 0054 §7).
Chart _acquire(ChartConfig config) =>
    acquireChartRoot(ChartConfigLowering(config).lower());

void main() {
  group('Chart.controllers.bar', () {
    group('auto', fixture.specs('controller.bar'));

    test('should be registered as dataset controller', () {
      expect(Chart.registry.controllers.items['bar'], isA<JsClass>());
    });

    testWidgets('should be constructed', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([])),
            BarDataset(data: .values([])),
          ],
          labels: [],
        ),
      );

      final meta = chart.getDatasetMeta(1);
      expect(meta.type, 'bar');
      expect(meta.data, isEmpty);
      expect(meta.hidden, isNull);
      expect(meta.controller, isNot(same(undefined)));
      expect(meta.controller, isNotNull);
      expect(meta.controller!.index, 1);
      expect(meta.xAxisID, isNotNull);
      expect(meta.yAxisID, isNotNull);

      meta.controller!.updateIndex(0);
      expect(meta.controller!.index, 0);
    });

    testWidgets('should set null bars to the reset state', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([10, null, 0, -4]), label: 'dataset1'),
          ],
          labels: ['label1', 'label2', 'label3', 'label4'],
        ),
      );

      final meta = chart.getDatasetMeta(0);
      final bar = _bar(meta, 1);
      final props = bar.getProps(const ['x', 'y', 'base'], true);
      expect(jsIsNaN(props['x']), false);
      expect(jsIsNaN(props['y']), false);
      expect(jsIsNaN(props['base']), false);
    });

    testWidgets(
      'should use the first scale IDs if the dataset does not specify them',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([])),
              BarDataset(data: .values([])),
            ],
            labels: [],
          ),
        );

        final meta = chart.getDatasetMeta(1);
        expect(meta.xAxisID, 'x');
        expect(meta.yAxisID, 'y');
      },
    );

    // :70
    testWidgets(
      'should correctly count the number of stacks ignoring datasets of '
      'other types and hidden datasets',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              LineDataset(data: .values([])),
              BarDataset(data: .values([]), hidden: true),
              BarDataset(data: .values([])),
              BarDataset(data: .values([])),
            ],
            labels: [],
          ),
        );

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackCount(), 2);
      },
    );

    // :88
    testWidgets(
      'should correctly count the number of stacks when a group is not '
      'specified',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([])),
              BarDataset(data: .values([])),
              BarDataset(data: .values([])),
              BarDataset(data: .values([])),
            ],
            labels: [],
          ),
        );

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackCount(), 4);
      },
    );

    // :106
    testWidgets(
      'should correctly count the number of stacks when a group is not '
      'specified and the scale is stacked',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([])),
              BarDataset(data: .values([])),
              BarDataset(data: .values([])),
              BarDataset(data: .values([])),
            ],
            labels: [],
            scales: [
              CategoryAxis(.x, stacked: StackMode.on),
              LinearAxis(.y, stacked: StackMode.on),
            ],
          ),
        );

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackCount(), 1);
      },
    );

    // :134
    testWidgets(
      'should correctly count the number of stacks when a group is not '
      'specified and the scale is not stacked',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([])),
              BarDataset(data: .values([])),
              BarDataset(data: .values([])),
              BarDataset(data: .values([])),
            ],
            labels: [],
            scales: [
              CategoryAxis(.x, stacked: StackMode.off),
              LinearAxis(.y, stacked: StackMode.off),
            ],
          ),
        );

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackCount(), 4);
      },
    );

    // :162
    testWidgets('should correctly count the number of stacks when a group is '
        'specified for some', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([]), stack: 'stack1'),
            BarDataset(data: .values([]), stack: 'stack1'),
            BarDataset(data: .values([])),
            BarDataset(data: .values([])),
          ],
          labels: [],
        ),
      );

      final meta = chart.getDatasetMeta(3);
      final controller = meta.controller! as BarController;
      expect(controller.getStackCount(), 3);
    });

    // :180
    testWidgets('should correctly count the number of stacks when a group is '
        'specified for some and the scale is stacked', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([]), stack: 'stack1'),
            BarDataset(data: .values([]), stack: 'stack1'),
            BarDataset(data: .values([])),
            BarDataset(data: .values([])),
          ],
          labels: [],
          scales: [
            CategoryAxis(.x, stacked: StackMode.on),
            LinearAxis(.y, stacked: StackMode.on),
          ],
        ),
      );

      final meta = chart.getDatasetMeta(3);
      final controller = meta.controller! as BarController;
      expect(controller.getStackCount(), 2);
    });

    // :208
    testWidgets('should correctly count the number of stacks when a group is '
        'specified for some and the scale is not stacked', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([]), stack: 'stack1'),
            BarDataset(data: .values([]), stack: 'stack1'),
            BarDataset(data: .values([])),
            BarDataset(data: .values([])),
          ],
          labels: [],
          scales: [
            CategoryAxis(.x, stacked: StackMode.off),
            LinearAxis(.y, stacked: StackMode.off),
          ],
        ),
      );

      final meta = chart.getDatasetMeta(3);
      final controller = meta.controller! as BarController;
      expect(controller.getStackCount(), 4);
    });

    // :236
    testWidgets('should correctly count the number of stacks when a group is '
        'specified for all', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([]), stack: 'stack1'),
            BarDataset(data: .values([]), stack: 'stack1'),
            BarDataset(data: .values([]), stack: 'stack2'),
            BarDataset(data: .values([]), stack: 'stack2'),
          ],
          labels: [],
        ),
      );

      final meta = chart.getDatasetMeta(3);
      final controller = meta.controller! as BarController;
      expect(controller.getStackCount(), 2);
    });

    // :254
    testWidgets('should correctly count the number of stacks when a group is '
        'specified for all and the scale is stacked', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([]), stack: 'stack1'),
            BarDataset(data: .values([]), stack: 'stack1'),
            BarDataset(data: .values([]), stack: 'stack2'),
            BarDataset(data: .values([]), stack: 'stack2'),
          ],
          labels: [],
          scales: [
            CategoryAxis(.x, stacked: StackMode.on),
            LinearAxis(.y, stacked: StackMode.on),
          ],
        ),
      );

      final meta = chart.getDatasetMeta(3);
      final controller = meta.controller! as BarController;
      expect(controller.getStackCount(), 2);
    });

    // :282
    testWidgets('should correctly count the number of stacks when a group is '
        'specified for all and the scale is not stacked', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([]), stack: 'stack1'),
            BarDataset(data: .values([]), stack: 'stack1'),
            BarDataset(data: .values([]), stack: 'stack2'),
            BarDataset(data: .values([]), stack: 'stack2'),
          ],
          labels: [],
          scales: [
            CategoryAxis(.x, stacked: StackMode.off),
            LinearAxis(.y, stacked: StackMode.off),
          ],
        ),
      );

      final meta = chart.getDatasetMeta(3);
      final controller = meta.controller! as BarController;
      expect(controller.getStackCount(), 4);
    });

    // :310
    testWidgets(
      'should correctly get the stack index accounting for datasets of '
      'other types and hidden datasets',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([])),
              BarDataset(data: .values([]), hidden: true),
              LineDataset(data: .values([])),
              BarDataset(data: .values([])),
            ],
            labels: [],
          ),
        );

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackIndex(0), 0);
        expect(controller.getStackIndex(3), 1);
      },
    );

    // :329
    testWidgets('should correctly get the stack index when a group is not '
        'specified', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([])),
            BarDataset(data: .values([])),
            BarDataset(data: .values([])),
            BarDataset(data: .values([])),
          ],
          labels: [],
        ),
      );

      final meta = chart.getDatasetMeta(1);
      final controller = meta.controller! as BarController;
      expect(controller.getStackIndex(0), 0);
      expect(controller.getStackIndex(1), 1);
      expect(controller.getStackIndex(2), 2);
      expect(controller.getStackIndex(3), 3);
    });

    // :350
    testWidgets('should correctly get the stack index when a group is not '
        'specified and the scale is stacked', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([])),
            BarDataset(data: .values([])),
            BarDataset(data: .values([])),
            BarDataset(data: .values([])),
          ],
          labels: [],
          scales: [
            CategoryAxis(.x, stacked: StackMode.on),
            LinearAxis(.y, stacked: StackMode.on),
          ],
        ),
      );

      final meta = chart.getDatasetMeta(1);
      final controller = meta.controller! as BarController;
      expect(controller.getStackIndex(0), 0);
      expect(controller.getStackIndex(1), 0);
      expect(controller.getStackIndex(2), 0);
      expect(controller.getStackIndex(3), 0);
    });

    // :381
    testWidgets('should correctly get the stack index when a group is not '
        'specified and the scale is not stacked', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([])),
            BarDataset(data: .values([])),
            BarDataset(data: .values([])),
            BarDataset(data: .values([])),
          ],
          labels: [],
          scales: [
            CategoryAxis(.x, stacked: StackMode.off),
            LinearAxis(.y, stacked: StackMode.off),
          ],
        ),
      );

      final meta = chart.getDatasetMeta(1);
      final controller = meta.controller! as BarController;
      expect(controller.getStackIndex(0), 0);
      expect(controller.getStackIndex(1), 1);
      expect(controller.getStackIndex(2), 2);
      expect(controller.getStackIndex(3), 3);
    });

    // :412
    testWidgets(
      'should correctly get the stack index when a group is specified '
      'for some',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([]), stack: 'stack1'),
              BarDataset(data: .values([]), stack: 'stack1'),
              BarDataset(data: .values([])),
              BarDataset(data: .values([])),
            ],
            labels: [],
          ),
        );

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackIndex(0), 0);
        expect(controller.getStackIndex(1), 0);
        expect(controller.getStackIndex(2), 1);
        expect(controller.getStackIndex(3), 2);
      },
    );

    // :433
    testWidgets(
      'should correctly get the stack index when a group is specified '
      'for some and the scale is stacked',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([]), stack: 'stack1'),
              BarDataset(data: .values([]), stack: 'stack1'),
              BarDataset(data: .values([])),
              BarDataset(data: .values([])),
            ],
            labels: [],
            scales: [
              CategoryAxis(.x, stacked: StackMode.on),
              LinearAxis(.y, stacked: StackMode.on),
            ],
          ),
        );

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackIndex(0), 0);
        expect(controller.getStackIndex(1), 0);
        expect(controller.getStackIndex(2), 1);
        expect(controller.getStackIndex(3), 1);
      },
    );

    // :464
    testWidgets(
      'should correctly get the stack index when a group is specified '
      'for some and the scale is not stacked',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([]), stack: 'stack1'),
              BarDataset(data: .values([]), stack: 'stack1'),
              BarDataset(data: .values([])),
              BarDataset(data: .values([])),
            ],
            labels: [],
            scales: [
              CategoryAxis(.x, stacked: StackMode.off),
              LinearAxis(.y, stacked: StackMode.off),
            ],
          ),
        );

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackIndex(0), 0);
        expect(controller.getStackIndex(1), 1);
        expect(controller.getStackIndex(2), 2);
        expect(controller.getStackIndex(3), 3);
      },
    );

    // :495
    testWidgets(
      'should correctly get the stack index when a group is specified '
      'for all',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([]), stack: 'stack1'),
              BarDataset(data: .values([]), stack: 'stack1'),
              BarDataset(data: .values([]), stack: 'stack2'),
              BarDataset(data: .values([]), stack: 'stack2'),
            ],
            labels: [],
          ),
        );

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackIndex(0), 0);
        expect(controller.getStackIndex(1), 0);
        expect(controller.getStackIndex(2), 1);
        expect(controller.getStackIndex(3), 1);
      },
    );

    // :516
    testWidgets(
      'should correctly get the stack index when a group is specified '
      'for all and the scale is stacked',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([]), stack: 'stack1'),
              BarDataset(data: .values([]), stack: 'stack1'),
              BarDataset(data: .values([]), stack: 'stack2'),
              BarDataset(data: .values([]), stack: 'stack2'),
            ],
            labels: [],
            scales: [
              CategoryAxis(.x, stacked: StackMode.on),
              LinearAxis(.y, stacked: StackMode.on),
            ],
          ),
        );

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackIndex(0), 0);
        expect(controller.getStackIndex(1), 0);
        expect(controller.getStackIndex(2), 1);
        expect(controller.getStackIndex(3), 1);
      },
    );

    // :547
    testWidgets(
      'should correctly get the stack index when a group is specified '
      'for all and the scale is not stacked',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([]), stack: 'stack1'),
              BarDataset(data: .values([]), stack: 'stack1'),
              BarDataset(data: .values([]), stack: 'stack2'),
              BarDataset(data: .values([]), stack: 'stack2'),
            ],
            labels: [],
            scales: [
              CategoryAxis(.x, stacked: StackMode.off),
              LinearAxis(.y, stacked: StackMode.off),
            ],
          ),
        );

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackIndex(0), 0);
        expect(controller.getStackIndex(1), 1);
        expect(controller.getStackIndex(2), 2);
        expect(controller.getStackIndex(3), 3);
      },
    );

    testWidgets(
      'should create bar elements for each data item during initialization',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([])),
              BarDataset(data: .values([10, 15, 0, -4])),
            ],
            labels: [],
          ),
        );

        final meta = chart.getDatasetMeta(1);
        expect(meta.data.length, 4); // 4 bars created
        expect(meta.data[0], isA<BarElement>());
        expect(meta.data[1], isA<BarElement>());
        expect(meta.data[2], isA<BarElement>());
        expect(meta.data[3], isA<BarElement>());
      },
    );

    testWidgets('should update elements when modifying data', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([1, 2]), label: 'dataset1'),
            BarDataset(
              data: .values([10, 15, 0, -4]),
              label: 'dataset2',
              borderColor: ChartValue.constant(
                ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 255, 1)),
              ),
            ),
          ],
          labels: ['label1', 'label2', 'label3', 'label4'],
          elements: ChartElements(
            bar: BarElementStyle(
              backgroundColor: ChartPaint.solid(
                native_ui.Color.fromRGBO(255, 0, 0, 1),
              ),
              borderColor: ChartPaint.solid(
                native_ui.Color.fromRGBO(0, 128, 0, 1),
              ),
              borderWidth: 2,
              borderSkipped: BorderSkip.top,
            ),
          ),
          scales: [
            CategoryAxis(.x, display: ScaleDisplay.off),
            LinearAxis(.y, display: ScaleDisplay.off, beginAtZero: false),
          ],
          disabledPlugins: [
            PluginOff<LegendPlugin>(),
            PluginOff<TitlePlugin>(),
          ],
        ),
      );

      final meta = chart.getDatasetMeta(1);
      expect(meta.data.length, 4);

      _dataset(chart, 1)['data'] = <Object?>[1, 2]; // remove 2 items
      _dataset(chart, 1)['borderWidth'] = 1;
      chart.update();

      expect(meta.data.length, 2);
      expect(meta.parsed.length, 2);

      final expectedValues = [(x: 89, y: 512), (x: 217, y: 0)];
      for (var i = 0; i < expectedValues.length; i++) {
        final expected = expectedValues[i];
        expect(_bar(meta, i).x, toBeCloseToPixel(expected.x));
        expect(_bar(meta, i).y, toBeCloseToPixel(expected.y));
        expect(_bar(meta, i).base, toBeCloseToPixel(1024));
        expect(_bar(meta, i).width, toBeCloseToPixel(46));
        expect(
          _options(meta.data[i]),
          isA<BarOptions>()
              .having(
                (o) => o.backgroundColor,
                'backgroundColor',
                const ChartPaint.solid(native_ui.Color.fromRGBO(255, 0, 0, 1)),
              )
              .having(
                (o) => o.borderSkipped,
                'borderSkipped',
                BorderSkippedEdge.top,
              )
              .having(
                (o) => o.borderColor,
                'borderColor',
                const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 255, 1)),
              )
              .having((o) => o.borderWidth, 'borderWidth', 1),
        );
      }

      _dataset(chart, 1)['data'] = <Object?>[1, 2, 3]; // add 1 items
      chart.update();

      expect(meta.data.length, 3); // should add a new meta data item
    });

    // :671
    testWidgets(
      'should get the correct bar points when datasets of different types '
      'exist',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([1, 2]), label: 'dataset1'),
              LineDataset(data: .values([4, 6]), label: 'dataset2'),
              BarDataset(data: .values([8, 10]), label: 'dataset3'),
            ],
            labels: ['label1', 'label2'],
            scales: [
              CategoryAxis(.x, display: ScaleDisplay.off),
              LinearAxis(.y, display: ScaleDisplay.off, beginAtZero: false),
            ],
            disabledPlugins: [
              PluginOff<LegendPlugin>(),
              PluginOff<TitlePlugin>(),
            ],
          ),
        );

        final meta = chart.getDatasetMeta(2);
        expect(meta.data.length, 2);

        final bar1 = _bar(meta, 0);
        final bar2 = _bar(meta, 1);

        expect(bar1.x, toBeCloseToPixel(179));
        expect(bar1.y, toBeCloseToPixel(117));
        expect(bar2.x, toBeCloseToPixel(431));
        expect(bar2.y, toBeCloseToPixel(4));
      },
    );

    testWidgets('should get the bar points for hidden dataset', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([1, 2]), label: 'dataset1', hidden: true),
          ],
          labels: ['label1', 'label2'],
          scales: [
            CategoryAxis(.x, display: ScaleDisplay.off),
            LinearAxis(.y, min: 0, max: 2, display: ScaleDisplay.off),
          ],
          disabledPlugins: [
            PluginOff<LegendPlugin>(),
            PluginOff<TitlePlugin>(),
          ],
        ),
      );

      final meta = chart.getDatasetMeta(0);
      expect(meta.data.length, 2);

      final bar1 = _bar(meta, 0);
      final bar2 = _bar(meta, 1);

      expect(bar1.x, toBeCloseToPixel(128));
      expect(bar1.y, toBeCloseToPixel(256));
      expect(bar2.x, toBeCloseToPixel(384));
      expect(bar2.y, toBeCloseToPixel(0));
    });

    testWidgets('should update elements when the scales are stacked', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([10, -10, 10, -10]), label: 'dataset1'),
            BarDataset(data: .values([10, 15, 0, -4]), label: 'dataset2'),
          ],
          labels: ['label1', 'label2', 'label3', 'label4'],
          scales: [
            CategoryAxis(.x, display: ScaleDisplay.off),
            LinearAxis(.y, display: ScaleDisplay.off, stacked: StackMode.on),
          ],
          disabledPlugins: [
            PluginOff<LegendPlugin>(),
            PluginOff<TitlePlugin>(),
          ],
        ),
      );

      final meta0 = chart.getDatasetMeta(0);

      _expectBars(meta0, const [
        (b: 293, w: 92 / 2, x: 38, y: 146),
        (b: 293, w: 92 / 2, x: 166, y: 439),
        (b: 293, w: 92 / 2, x: 295, y: 146),
        (b: 293, w: 92 / 2, x: 422, y: 439),
      ]);

      final meta1 = chart.getDatasetMeta(1);

      _expectBars(meta1, const [
        (b: 146, w: 92 / 2, x: 89, y: 0),
        (b: 293, w: 92 / 2, x: 217, y: 73),
        (b: 146, w: 92 / 2, x: 345, y: 146),
        (b: 439, w: 92 / 2, x: 473, y: 497),
      ]);
    });

    testWidgets(
      'should update elements when the scales are stacked and the y axis has '
      'a user defined minimum',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([50, 20, 10, 100]), label: 'dataset1'),
              BarDataset(data: .values([50, 80, 90, 0]), label: 'dataset2'),
            ],
            labels: ['label1', 'label2', 'label3', 'label4'],
            scales: [
              CategoryAxis(.x, display: ScaleDisplay.off),
              LinearAxis(
                .y,
                display: ScaleDisplay.off,
                stacked: StackMode.on,
                min: 50,
                max: 100,
              ),
            ],
            disabledPlugins: [
              PluginOff<LegendPlugin>(),
              PluginOff<TitlePlugin>(),
            ],
          ),
        );

        final meta0 = chart.getDatasetMeta(0);

        _expectBars(meta0, const [
          (b: 1024, w: 92 / 2, x: 38, y: 512),
          (b: 1024, w: 92 / 2, x: 166, y: 819),
          (b: 1024, w: 92 / 2, x: 294, y: 922),
          (b: 1024, w: 92 / 2, x: 422.5, y: 0),
        ]);

        final meta1 = chart.getDatasetMeta(1);

        _expectBars(meta1, const [
          (b: 512, w: 92 / 2, x: 89, y: 0),
          (b: 819.2, w: 92 / 2, x: 217, y: 0),
          (b: 921.6, w: 92 / 2, x: 345, y: 0),
          (b: 0, w: 92 / 2, x: 473.5, y: 0),
        ]);
      },
    );

    testWidgets('should update elements when only the category scale is '
        'stacked', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([20, -10, 10, -10]), label: 'dataset1'),
            BarDataset(data: .values([10, 15, 0, -14]), label: 'dataset2'),
          ],
          labels: ['label1', 'label2', 'label3', 'label4'],
          scales: [
            CategoryAxis(.x, display: ScaleDisplay.off, stacked: StackMode.on),
            LinearAxis(.y, display: ScaleDisplay.off),
          ],
          disabledPlugins: [
            PluginOff<LegendPlugin>(),
            PluginOff<TitlePlugin>(),
          ],
        ),
      );

      final meta0 = chart.getDatasetMeta(0);

      _expectBars(meta0, const [
        (b: 293, w: 92, x: 64, y: 0),
        (b: 293, w: 92, x: 192, y: 439),
        (b: 293, w: 92, x: 320, y: 146),
        (b: 293, w: 92, x: 448, y: 439),
      ]);

      final meta1 = chart.getDatasetMeta(1);

      _expectBars(meta1, const [
        (b: 293, w: 92, x: 64, y: 146),
        (b: 293, w: 92, x: 192, y: 73),
        (b: 293, w: 92, x: 320, y: 293),
        (b: 293, w: 92, x: 448, y: 497),
      ]);
    });

    testWidgets('should update elements when the scales are stacked and data '
        'is strings', (tester) async {
      // Native scopes preserve string data for the parser.
      final chart = acquireChartRoot(
        ChartConfigurationScope()
          ..type = 'bar'
          ..data = (ChartDataScope()
            ..datasets = [
              mergeExtra(BarControllerDatasetOptionsScope(), <String, Object?>{
                'data': <Object?>['10', '-10', '10', '-10'],
                'label': 'dataset1',
              }),
              mergeExtra(BarControllerDatasetOptionsScope(), <String, Object?>{
                'data': <Object?>['10', '15', '0', '-4'],
                'label': 'dataset2',
              }),
            ]
            ..labels = <Object?>['label1', 'label2', 'label3', 'label4'])
          ..options = mergeExtra(ChartOptionsScope(), <String, Object?>{
            'plugins': <String, Object?>{'legend': false, 'title': false},
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'type': 'category',
                'display': ScaleDisplay.off,
              },
              'y': <String, Object?>{
                'type': 'linear',
                'display': ScaleDisplay.off,
                'stacked': StackMode.on,
              },
            },
          }),
      );

      final meta0 = chart.getDatasetMeta(0);

      _expectBars(meta0, const [
        (b: 293, w: 92 / 2, x: 38, y: 146),
        (b: 293, w: 92 / 2, x: 166, y: 439),
        (b: 293, w: 92 / 2, x: 295, y: 146),
        (b: 293, w: 92 / 2, x: 422, y: 439),
      ]);

      final meta1 = chart.getDatasetMeta(1);

      _expectBars(meta1, const [
        (b: 146, w: 92 / 2, x: 89, y: 0),
        (b: 293, w: 92 / 2, x: 217, y: 73),
        (b: 146, w: 92 / 2, x: 345, y: 146),
        (b: 439, w: 92 / 2, x: 473, y: 497),
      ]);
    });

    testWidgets(
      'should get the correct bar points for grouped stacked chart if the '
      'group name is same',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(
                data: .values([10, -10, 10, -10]),
                label: 'dataset1',
                stack: 'stack1',
              ),
              BarDataset(
                data: .values([10, 15, 0, -4]),
                label: 'dataset2',
                stack: 'stack1',
              ),
            ],
            labels: ['label1', 'label2', 'label3', 'label4'],
            scales: [
              CategoryAxis(.x, display: ScaleDisplay.off),
              LinearAxis(.y, display: ScaleDisplay.off, stacked: StackMode.on),
            ],
            disabledPlugins: [
              PluginOff<LegendPlugin>(),
              PluginOff<TitlePlugin>(),
            ],
          ),
        );

        final meta0 = chart.getDatasetMeta(0);

        _expectBars(meta0, const [
          (b: 293, w: 92, x: 64, y: 146),
          (b: 293, w: 92, x: 192, y: 439),
          (b: 293, w: 92, x: 320, y: 146),
          (b: 293, w: 92, x: 448, y: 439),
        ]);

        final meta = chart.getDatasetMeta(1);

        _expectBars(meta, const [
          (b: 146, w: 92, x: 64, y: 0),
          (b: 293, w: 92, x: 192, y: 73),
          (b: 146, w: 92, x: 320, y: 146),
          (b: 439, w: 92, x: 448, y: 497),
        ]);
      },
    );

    testWidgets(
      'should get the correct bar points for grouped stacked chart if the '
      'group name is different',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([1, 2]), stack: 'stack1'),
              BarDataset(data: .values([1, 2]), stack: 'stack2'),
            ],
            labels: ['label1', 'label2', 'label3', 'label4'],
            scales: [
              CategoryAxis(.x, display: ScaleDisplay.off),
              LinearAxis(.y, display: ScaleDisplay.off, stacked: StackMode.on),
            ],
            disabledPlugins: [
              PluginOff<LegendPlugin>(),
              PluginOff<TitlePlugin>(),
            ],
          ),
        );

        final meta = chart.getDatasetMeta(1);

        final values = [(x: 89, y: 256), (x: 217, y: 0)];
        for (var i = 0; i < values.length; i++) {
          expect(_bar(meta, i).base, toBeCloseToPixel(512));
          expect(_bar(meta, i).width, toBeCloseToPixel(46));
          expect(_bar(meta, i).x, toBeCloseToPixel(values[i].x));
          expect(_bar(meta, i).y, toBeCloseToPixel(values[i].y));
        }
      },
    );

    testWidgets('should get the correct bar points for grouped stacked chart', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([1, 2]), stack: 'stack1'),
            BarDataset(data: .values([0.5, 1]), stack: 'stack2'),
            BarDataset(data: .values([0.5, 1]), stack: 'stack2'),
          ],
          labels: ['label1', 'label2', 'label3', 'label4'],
          scales: [
            CategoryAxis(.x, display: ScaleDisplay.off),
            LinearAxis(.y, display: ScaleDisplay.off, stacked: StackMode.on),
          ],
          disabledPlugins: [
            PluginOff<LegendPlugin>(),
            PluginOff<TitlePlugin>(),
          ],
        ),
      );

      final meta = chart.getDatasetMeta(2);

      final values = [(b: 384, x: 89, y: 256), (b: 256, x: 217, y: 0)];
      for (var i = 0; i < values.length; i++) {
        expect(_bar(meta, i).base, toBeCloseToPixel(values[i].b));
        expect(_bar(meta, i).width, toBeCloseToPixel(46));
        expect(_bar(meta, i).x, toBeCloseToPixel(values[i].x));
        expect(_bar(meta, i).y, toBeCloseToPixel(values[i].y));
      }
    });

    testWidgets('should draw all bars', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([])),
            BarDataset(data: .values([10, 15, 0, -4]), label: 'dataset2'),
          ],
          labels: ['label1', 'label2', 'label3', 'label4'],
        ),
      );

      final meta = chart.getDatasetMeta(1);

      final draw0 = recordElementDraws(meta, 0);
      final draw1 = recordElementDraws(meta, 1);
      final draw2 = recordElementDraws(meta, 2);
      final draw3 = recordElementDraws(meta, 3);

      chart.update();

      expect(draw0, hasLength(1));
      expect(draw1, hasLength(1));
      expect(draw2, hasLength(1));
      expect(draw3, hasLength(1));
    });

    testWidgets('should set hover styles on bars', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([])),
            BarDataset(data: .values([10, 15, 0, -4]), label: 'dataset2'),
          ],
          labels: ['label1', 'label2', 'label3', 'label4'],
          elements: ChartElements(
            bar: BarElementStyle(
              backgroundColor: ChartPaint.solid(
                native_ui.Color.fromRGBO(255, 0, 0, 1),
              ),
              borderColor: ChartPaint.solid(
                native_ui.Color.fromRGBO(0, 0, 255, 1),
              ),
              borderWidth: 2,
            ),
          ),
        ),
      );

      final meta = chart.getDatasetMeta(1);
      final bar = _bar(meta, 0);

      meta.controller!.setHoverStyle(bar, 1, 0);
      expect(
        _barOptions(bar).backgroundColor,
        const ChartPaint.solid(native_ui.Color.fromRGBO(230, 0, 0, 1)),
      );
      expect(
        _barOptions(bar).borderColor,
        const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 230, 1)),
      );
      expect(_barOptions(bar).borderWidth, 2);

      // Set a dataset style
      _dataset(chart, 1)['hoverBackgroundColor'] = const ChartPaint.solid(
        native_ui.Color.fromRGBO(128, 128, 128, 1),
      );
      _dataset(chart, 1)['hoverBorderColor'] = const ChartPaint.solid(
        native_ui.Color.fromRGBO(0, 0, 0, 1),
      );
      _dataset(chart, 1)['hoverBorderWidth'] = 5;
      chart.update();

      meta.controller!.setHoverStyle(bar, 1, 0);
      expect(
        _barOptions(bar).backgroundColor,
        const ChartPaint.solid(native_ui.Color.fromRGBO(128, 128, 128, 1)),
      );
      expect(
        _barOptions(bar).borderColor,
        const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 0, 1)),
      );
      expect(_barOptions(bar).borderWidth, 5);

      // Should work with array styles so that we can set per bar
      _dataset(chart, 1)['hoverBackgroundColor'] = <Object?>[
        const ChartPaint.solid(native_ui.Color.fromRGBO(255, 255, 255, 1)),
        const ChartPaint.solid(native_ui.Color.fromRGBO(128, 128, 128, 1)),
      ];
      _dataset(chart, 1)['hoverBorderColor'] = <Object?>[
        const ChartPaint.solid(native_ui.Color.fromRGBO(9, 9, 9, 1)),
        const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 0, 1)),
      ];
      _dataset(chart, 1)['hoverBorderWidth'] = <Object?>[2.5, 5];
      chart.update();

      meta.controller!.setHoverStyle(bar, 1, 0);
      expect(
        _barOptions(bar).backgroundColor,
        const ChartPaint.solid(native_ui.Color.fromRGBO(255, 255, 255, 1)),
      );
      expect(
        _barOptions(bar).borderColor,
        const ChartPaint.solid(native_ui.Color.fromRGBO(9, 9, 9, 1)),
      );
      expect(_barOptions(bar).borderWidth, 2.5);
    });

    testWidgets('should remove a hover style from a bar', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([])),
            BarDataset(data: .values([10, 15, 0, -4]), label: 'dataset2'),
          ],
          labels: ['label1', 'label2', 'label3', 'label4'],
          elements: ChartElements(
            bar: BarElementStyle(
              backgroundColor: ChartPaint.solid(
                native_ui.Color.fromRGBO(255, 0, 0, 1),
              ),
              borderColor: ChartPaint.solid(
                native_ui.Color.fromRGBO(0, 0, 255, 1),
              ),
              borderWidth: 2,
            ),
          ),
        ),
      );

      final meta = chart.getDatasetMeta(1);
      final bar = _bar(meta, 0);

      // Change default
      final barOptions =
          jsGet(jsGet(chart.options, 'elements'), 'bar')! as JsObjectFace;
      barOptions['backgroundColor'] = const ChartPaint.solid(
        native_ui.Color.fromRGBO(128, 128, 128, 1),
      );
      barOptions['borderColor'] = const ChartPaint.solid(
        native_ui.Color.fromRGBO(15, 15, 15, 1),
      );
      barOptions['borderWidth'] = 3.14;

      chart.update();
      expect(
        _barOptions(bar).backgroundColor,
        const ChartPaint.solid(native_ui.Color.fromRGBO(128, 128, 128, 1)),
      );
      expect(
        _barOptions(bar).borderColor,
        const ChartPaint.solid(native_ui.Color.fromRGBO(15, 15, 15, 1)),
      );
      expect(_barOptions(bar).borderWidth, 3.14);
      meta.controller!.setHoverStyle(bar, 1, 0);
      expect(
        _barOptions(bar).backgroundColor,
        getHoverColor(
          const ChartPaint.solid(native_ui.Color.fromRGBO(128, 128, 128, 1)),
        ),
      );
      expect(
        _barOptions(bar).borderColor,
        getHoverColor(
          const ChartPaint.solid(native_ui.Color.fromRGBO(15, 15, 15, 1)),
        ),
      );
      expect(_barOptions(bar).borderWidth, 3.14);
      meta.controller!.removeHoverStyle(bar);
      expect(
        _barOptions(bar).backgroundColor,
        const ChartPaint.solid(native_ui.Color.fromRGBO(128, 128, 128, 1)),
      );
      expect(
        _barOptions(bar).borderColor,
        const ChartPaint.solid(native_ui.Color.fromRGBO(15, 15, 15, 1)),
      );
      expect(_barOptions(bar).borderWidth, 3.14);

      // Should work with array styles so that we can set per bar
      _dataset(chart, 1)['backgroundColor'] = <Object?>[
        const ChartPaint.solid(native_ui.Color.fromRGBO(255, 255, 255, 1)),
        const ChartPaint.solid(native_ui.Color.fromRGBO(128, 128, 128, 1)),
      ];
      _dataset(chart, 1)['borderColor'] = <Object?>[
        const ChartPaint.solid(native_ui.Color.fromRGBO(9, 9, 9, 1)),
        const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 0, 1)),
      ];
      _dataset(chart, 1)['borderWidth'] = <Object?>[2.5, 5];

      chart.update();
      expect(
        _barOptions(bar).backgroundColor,
        const ChartPaint.solid(native_ui.Color.fromRGBO(255, 255, 255, 1)),
      );
      expect(
        _barOptions(bar).borderColor,
        const ChartPaint.solid(native_ui.Color.fromRGBO(9, 9, 9, 1)),
      );
      expect(_barOptions(bar).borderWidth, 2.5);
      meta.controller!.setHoverStyle(bar, 1, 0);
      expect(
        _barOptions(bar).backgroundColor,
        getHoverColor(
          const ChartPaint.solid(native_ui.Color.fromRGBO(255, 255, 255, 1)),
        ),
      );
      expect(
        _barOptions(bar).borderColor,
        getHoverColor(
          const ChartPaint.solid(native_ui.Color.fromRGBO(9, 9, 9, 1)),
        ),
      );
      expect(_barOptions(bar).borderWidth, 2.5);
      meta.controller!.removeHoverStyle(bar);
      expect(
        _barOptions(bar).backgroundColor,
        const ChartPaint.solid(native_ui.Color.fromRGBO(255, 255, 255, 1)),
      );
      expect(
        _barOptions(bar).borderColor,
        const ChartPaint.solid(native_ui.Color.fromRGBO(9, 9, 9, 1)),
      );
      expect(_barOptions(bar).borderWidth, 2.5);
    });

    group('Bar width', () {
      // `this.data` is a typed config with the labels and the datasets, and
      // each case gives its options through `copyWith`.
      late ChartConfig data;
      late ChartConfig config;

      setUp(() {
        // 2 datasets
        data = const ChartConfig(
          labels: [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
          ],
          datasets: [
            BarDataset(data: .values([10, 20, 30, 40, 50, 60, 70])),
            BarDataset(data: .values([10, 20, 30, 40, 50, 60, 70])),
          ],
        );
      });

      // :1325 the afterEach acquires a chart: each test calls it last.
      void afterEach() {
        final chart = _acquire(config);
        final meta = chart.getDatasetMeta(0);
        final xScale = chart.scales[meta.xAxisID]!;
        final options = jsGet(jsGet(Chart.defaults, 'datasets'), 'bar');

        final categoryPercentage = jsGet(options, 'categoryPercentage');
        final barPercentage = jsGet(options, 'barPercentage');
        final stacked = xScale.options.stacked;

        var totalBarWidth = 0.0;
        final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
        for (var i = 0; i < datasets.length; i++) {
          final bars = chart.getDatasetMeta(i).data;
          for (var j = xScale.min; j <= xScale.max; j++) {
            totalBarWidth += (bars[j.toInt()] as BarElement).width;
          }
          if (jsTruthy(stacked)) {
            break;
          }
        }

        final actualValue = totalBarWidth;
        final expectedValue =
            xScale.width *
            jsToNumber(categoryPercentage) *
            jsToNumber(barPercentage);
        expect(actualValue, toBeCloseToPixel(expectedValue));
      }

      testWidgets('should correctly set bar width when min and max option is '
          'set.', (tester) async {
        config = data.copyWith(
          scales: const [CategoryAxis(.x, min: 'March', max: 'May')],
        );
        afterEach();
      });

      testWidgets('should correctly set bar width when scale are stacked with '
          'min and max options.', (tester) async {
        config = data.copyWith(
          scales: const [
            CategoryAxis(.x, min: 'March', max: 'May'),
            LinearAxis(.y, stacked: StackMode.on),
          ],
        );
        afterEach();
      });
    });

    // The two cases of this group get bodies (Chart.js ADR 0030 §12 item 6):
    // the default legend changes the asserted heights. The assertion is
    // relative to the scale height. Thus it passed before the legend was
    // registered, and it also passes with the legend.
    group('Bar height (horizontal type)', () {
      // `this.data` is a typed config with the labels and the datasets, and
      // each case gives its options through `copyWith`.
      late ChartConfig data;
      late ChartConfig config;

      setUp(() {
        // 2 datasets
        data = const ChartConfig(
          labels: [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
          ],
          datasets: [
            BarDataset(data: .values([10, 20, 30, 40, 50, 60, 70])),
            BarDataset(data: .values([10, 20, 30, 40, 50, 60, 70])),
          ],
        );
      });

      // :1399 the afterEach acquires a chart: each test calls it last.
      void afterEach() {
        final chart = _acquire(config);
        final meta = chart.getDatasetMeta(0);
        final yScale = chart.scales[meta.yAxisID]!;

        final config0 = meta.controller!.options;
        final categoryPercentage = jsGet(config0, 'categoryPercentage');
        final barPercentage = jsGet(config0, 'barPercentage');
        final stacked = yScale.options.stacked;

        var totalBarHeight = 0.0;
        final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
        for (var i = 0; i < datasets.length; i++) {
          final bars = chart.getDatasetMeta(i).data;
          for (var j = yScale.min; j <= yScale.max; j++) {
            totalBarHeight += (bars[j.toInt()] as BarElement).height;
          }
          if (jsTruthy(stacked)) {
            break;
          }
        }

        final actualValue = totalBarHeight;
        final expectedValue =
            yScale.height *
            jsToNumber(categoryPercentage) *
            jsToNumber(barPercentage);
        expect(actualValue, toBeCloseToPixel(expectedValue));
      }

      testWidgets('should correctly set bar height when min and max option is '
          'set.', (tester) async {
        config = data.copyWith(
          indexAxis: const YAxis(),
          scales: const [CategoryAxis(.y, min: 'March', max: 'May')],
        );
        afterEach();
      });

      testWidgets('should correctly set bar height when scale are stacked '
          'with min and max options.', (tester) async {
        config = data.copyWith(
          indexAxis: const YAxis(),
          scales: const [
            LinearAxis(.x, stacked: StackMode.on),
            CategoryAxis(.y, min: 'March', max: 'May'),
          ],
        );
        afterEach();
      });
    });

    group('Bar thickness with a category scale', () {
      for (final barThickness in <Object?>[undefined, 20]) {
        group('When barThickness is ${jsToString(barThickness)}', () {
          late Chart chart;

          // :1465 the beforeEach acquires a chart: each test calls it first.
          void beforeEach() {
            chart = _acquire(
              ChartConfig(
                datasets: const [
                  BarDataset(data: .values([1, 2])),
                  BarDataset(data: .values([1, 2])),
                ],
                labels: const ['label1', 'label2', 'label3'],
                scales: const [
                  CategoryAxis(.x, extra: {'id': 'x'}),
                  LinearAxis(.y),
                ],
                extra: {
                  'legend': false,
                  'title': false,
                  'datasets': {
                    'bar': {
                      // `barThickness: undefined` reads as an absent key.
                      if (jsTruthy(barThickness))
                        'barThickness': BarThickness.pixels(
                          jsToNumber(barThickness),
                        ),
                    },
                  },
                },
              ),
            );
          }

          testWidgets('should correctly set bar width', (tester) async {
            beforeEach();
            Object? expected;

            if (jsTruthy(barThickness)) {
              expected = barThickness;
            } else {
              final scale = chart.scales['x']!;
              final options = jsGet(jsGet(Chart.defaults, 'datasets'), 'bar');
              final categoryPercentage = jsToNumber(
                jsGet(options, 'categoryPercentage'),
              );
              final barPercentage = jsToNumber(jsGet(options, 'barPercentage'));
              final tickInterval =
                  scale.getPixelForTick(1)! - scale.getPixelForTick(0)!;

              expected = tickInterval * categoryPercentage / 2 * barPercentage;
            }

            final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
            for (var i = 0, ilen = datasets.length; i < ilen; ++i) {
              final meta = chart.getDatasetMeta(i);
              expect(_bar(meta, 0).width, toBeCloseToPixel(expected));
              expect(_bar(meta, 1).width, toBeCloseToPixel(expected));
            }
          });

          testWidgets(
            'should correctly set bar width if maxBarThickness is specified',
            (tester) async {
              beforeEach();

              _dataset(chart, 0)['maxBarThickness'] = 10;
              _dataset(chart, 1)['maxBarThickness'] = 10;
              chart.update();

              final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
              for (var i = 0, ilen = datasets.length; i < ilen; ++i) {
                final meta = chart.getDatasetMeta(i);
                expect(_bar(meta, 0).width, toBeCloseToPixel(10));
                expect(_bar(meta, 1).width, toBeCloseToPixel(10));
              }
            },
          );
        });
      }
    });

    // Chart.js ADR 0030 §12 item 6: the default legend changes the y
    // positions of the bars. The assertion is relative to `base`. Thus it
    // passed before the legend was registered, and it also passes with the
    // legend.
    testWidgets('minBarLength settings should be used on Y axis on bar chart', (
      tester,
    ) async {
      const minBarLength = 4.0;
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(
              minBarLength: minBarLength,
              data: .values([0.05, -0.05, 10, 15, 20, 25, 30, 35]),
            ),
          ],
        ),
      );

      final data = chart.getDatasetMeta(0).data;
      final halfBaseLine = chart.scales['y']!.getLineWidthForValue(0) / 2;

      final bar0 = data[0] as BarElement;
      final bar1 = data[1] as BarElement;
      expect(bar0.base - minBarLength + halfBaseLine, bar0.y);
      expect(bar1.base + minBarLength - halfBaseLine, bar1.y);
    });

    testWidgets(
      'minBarLength settings should be used on X axis on horizontal bar chart',
      (tester) async {
        const minBarLength = 4.0;
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(
                indexAxis: YAxis(),
                minBarLength: minBarLength,
                data: .values([0.05, -0.05, 10, 15, 20, 25, 30, 35]),
              ),
            ],
          ),
        );

        final data = chart.getDatasetMeta(0).data;
        final halfBaseLine = chart.scales['x']!.getLineWidthForValue(0) / 2;

        final bar0 = data[0] as BarElement;
        final bar1 = data[1] as BarElement;
        expect(bar0.base + minBarLength - halfBaseLine, bar0.x);
        expect(bar1.base - minBarLength + halfBaseLine, bar1.x);
      },
    );

    testWidgets('should respect the data visibility settings', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([1, 2, 3, 4])),
          ],
          labels: ['A', 'B', 'C', 'D'],
          scales: [
            CategoryAxis(.x, display: ScaleDisplay.off),
            LinearAxis(.y, display: ScaleDisplay.off),
          ],
          disabledPlugins: [
            PluginOff<LegendPlugin>(),
            PluginOff<TitlePlugin>(),
          ],
        ),
      );

      var data = chart.getDatasetMeta(0).data;
      expect((data[0] as BarElement).base, toBeCloseToPixel(512));
      expect((data[0] as BarElement).y, toBeCloseToPixel(384));

      chart
        ..toggleDataVisibility(0)
        ..update();

      data = chart.getDatasetMeta(0).data;
      expect((data[0] as BarElement).base, toBeCloseToPixel(512));
      expect((data[0] as BarElement).y, toBeCloseToPixel(512));
    });

    testWidgets('should hide bar dataset beneath the chart for correct '
        'animations', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([1, 2, 3, 4])),
            BarDataset(data: .values([1, 2, 3, 4])),
          ],
          labels: ['A', 'B', 'C', 'D'],
          scales: [
            CategoryAxis(.x, display: ScaleDisplay.off, stacked: StackMode.on),
            LinearAxis(.y, display: ScaleDisplay.off, stacked: StackMode.on),
          ],
          disabledPlugins: [
            PluginOff<LegendPlugin>(),
            PluginOff<TitlePlugin>(),
          ],
        ),
      );

      var data = chart.getDatasetMeta(0).data;
      expect((data[0] as BarElement).base, toBeCloseToPixel(512));
      expect((data[0] as BarElement).y, toBeCloseToPixel(448));

      chart
        ..setDatasetVisibility(0, false)
        ..update();

      data = chart.getDatasetMeta(0).data;
      expect((data[0] as BarElement).base, toBeCloseToPixel(640));
      expect((data[0] as BarElement).y, toBeCloseToPixel(512));
    });

    group('Float bar', () {
      testWidgets('Should return correct values from getMinMax', (
        tester,
      ) async {
        // Keep the floating bar `[10, -10]` as one data item.
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..type = 'bar'
            ..data = (ChartDataScope()
              ..labels = <Object?>['a']
              ..datasets = [
                mergeExtra(
                  BarControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'data': <Object?>[
                      <Object?>[10, -10],
                    ],
                  },
                ),
              ]),
        );

        // `getMinMax()` without an argument: `canStack` is `undefined`,
        // falsy.
        final minMax = chart.scales['y']!.getMinMax(false);
        expect(minMax, equals((min: -10.0, max: 10.0)));
      });
    });

    group('clip', () {
      testWidgets('Should not use ctx.clip when clip=false', (tester) async {
        final ctx = _ResetTransformContext();

        final chart = _acquire(
          const ChartConfig(
            labels: ['a', 'b', 'c'],
            datasets: [
              BarDataset(
                data: .values([1, 2, 3]),
                // DIVERGES(chartjs): adapt-chart-clip-option, the clip class.
                clip: ChartClip.none,
              ),
            ],
          ),
        );
        final orig = chart.ctx;

        // Draw on mock context
        chart
          ..ctx = ctx
          ..draw()
          ..ctx = orig;

        expect(ctx.getCalls().where((x) => x['name'] == 'clip').length, 0);
      });
    });

    testWidgets('should not crash with skipNull and uneven datasets', (
      tester,
    ) async {
      void unevenChart() {
        _acquire(
          const ChartConfig(
            labels: [1, 2],
            datasets: [
              BarDataset(data: .values([1, 2])),
              BarDataset(data: .values([1, 2, 3])),
            ],
            datasetDefaults: [BarDataset(skipNull: true)],
          ),
        );
      }

      expect(unevenChart, returnsNormally);
    });

    testWidgets('should correctly count the number of stacks when skipNull '
        'and different order datasets', (tester) async {
      // Preserve the custom data keys read through `parsing`.
      final chart = acquireChartRoot(
        ChartConfigurationScope()
          ..type = 'bar'
          ..data = (ChartDataScope()
            ..datasets = [
              mergeExtra(BarControllerDatasetOptionsScope(), <String, Object?>{
                'id': '1',
                'label': 'USA',
                'data': <Object?>[
                  <String, Object?>{
                    'xScale': 'First',
                    'Country': 'USA',
                    'yScale': 524,
                  },
                  <String, Object?>{
                    'xScale': 'Second',
                    'Country': 'USA',
                    'yScale': 325,
                  },
                ],

                'yAxisID': 'yScale',
                'xAxisID': 'xScale',

                'parsing': <String, Object?>{
                  'yAxisKey': 'yScale',
                  'xAxisKey': 'xScale',
                },
              }),
              mergeExtra(BarControllerDatasetOptionsScope(), <String, Object?>{
                'id': '2',
                'label': 'BRA',
                'data': <Object?>[
                  <String, Object?>{
                    'xScale': 'Second',
                    'Country': 'BRA',
                    'yScale': 183,
                  },
                  <String, Object?>{
                    'xScale': 'First',
                    'Country': 'BRA',
                    'yScale': 177,
                  },
                ],

                'yAxisID': 'yScale',
                'xAxisID': 'xScale',

                'parsing': <String, Object?>{
                  'yAxisKey': 'yScale',
                  'xAxisKey': 'xScale',
                },
              }),
              mergeExtra(BarControllerDatasetOptionsScope(), <String, Object?>{
                'id': '3',
                'label': 'DEU',
                'data': <Object?>[
                  <String, Object?>{
                    'xScale': 'First',
                    'Country': 'DEU',
                    'yScale': 162,
                  },
                ],

                'yAxisID': 'yScale',
                'xAxisID': 'xScale',

                'parsing': <String, Object?>{
                  'yAxisKey': 'yScale',
                  'xAxisKey': 'xScale',
                },
              }),
            ])
          ..options = mergeExtra(ChartOptionsScope(), <String, Object?>{
            'skipNull': true,
          }),
      );

      final meta = chart.getDatasetMeta(0);
      final controller = meta.controller! as BarController;
      expect(controller.getStackCount(0), 3);
      expect(controller.getStackCount(1), 2);
    });

    // :1808
    testWidgets('should not override tooltip title and label callbacks', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          labels: ['Label 1', 'Label 2'],
          datasets: [
            BarDataset(data: .values([21, 79]), label: 'Dataset 1'),
            BarDataset(data: .values([33, 67]), label: 'Dataset 2'),
          ],
          responsive: true,
          maintainAspectRatio: true,
        ),
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

/// The `forEach` of :797-807 and of the same blocks: `base`, `width`, `x`
/// and `y` of each bar of [meta] against [values].
void _expectBars(ChartMeta meta, List<({num b, num w, num x, num y})> values) {
  for (var i = 0; i < values.length; i++) {
    final bar = _bar(meta, i);
    expect(bar.base, toBeCloseToPixel(values[i].b));
    expect(bar.width, toBeCloseToPixel(values[i].w));
    expect(bar.x, toBeCloseToPixel(values[i].x));
    expect(bar.y, toBeCloseToPixel(values[i].y));
  }
}
