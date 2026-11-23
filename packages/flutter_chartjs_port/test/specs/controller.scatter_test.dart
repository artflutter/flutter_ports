// Ported from Chart.js v4.6.1 test/specs/controller.scatter.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;

// `Chart` is the class of core.controller.dart. The spec runs on the VM: a
// chart reaches the chart host and dart:ui. Each chart case is a
// `testWidgets` case with the harness of Chart.js ADR 0022, section 2. The
// conventions are those of Chart.js ADR 0030, section 13, with items 1
// and 5 to 8 of Chart.js ADR 0180.
//
// flutter_test_config.dart registers the scatter controller with the
// built-in components before main(), as index.umd.ts:28 does (Chart.js ADR
// 0030, section 3 item 4).
//
// The spec forms:
// - `Chart.controllers` is `registry.controllers.items` (index.umd.ts:35):
//   `Chart.registry.controllers.items`.
// - `Chart.elements.LineElement` is the class LineElement of
//   element.line.dart. `x instanceof C` is `x is C`.
// - `toEqual` of an array is `equals`, and of a tooltip body item
//   `_bodyItem`, a matcher of the fields of `TooltipBodyItem`.
//
// The tooltip cases (:8, :146) read `chart.tooltip`, the field of `Chart` (a
// `types.TooltipModel?`), through the interface.
// `chart.options.plugins.tooltip = value` writes the key `tooltip` of the
// options view `chart.options['plugins']`. `{mode: 'dataset'}` is the
// `TooltipOptions` of that mode, the one options object of the tooltip
// (Chart.js ADR 0192).

/// The tooltip body item `{before: [], lines: lines, after: []}`
/// (plugin.tooltip.js:559-563).
Matcher _bodyItem(List<String> lines) => isA<TooltipBodyItem>()
    .having((b) => b.before, 'before', isEmpty)
    .having((b) => b.lines, 'lines', equals(lines))
    .having((b) => b.after, 'after', isEmpty);

void main() {
  group('Chart.controllers.scatter', () {
    group('auto', fixture.specs('controller.scatter'));

    test('should be registered as dataset controller', () {
      expect(Chart.registry.controllers.items['scatter'], isA<JsClass>());
    });

    // :8
    testWidgets(
      'should only show a single point in the tooltip on multiple datasets',
      (tester) async {
        final chart = acquireChartRoot(
          ChartConfigLowering(
            ChartConfig(
              datasets: [
                ScatterDataset(
                  data: .points([DataPoint(10, 15), DataPoint(12, 10)]),
                  label: 'dataset1',
                ),
                ScatterDataset(
                  data: .points([DataPoint(20, 10), DataPoint(4, 8)]),
                  label: 'dataset2',
                ),
              ],
            ),
          ).lower(),
        );
        final point = chart.getDatasetMeta(0).data[1];

        await triggerMouseEvent(chart, 'mousemove', point);
        expect(chart.tooltip!.body!.length, 1);
      },
    );

    testWidgets('should not create line element by default', (tester) async {
      final chart = acquireChartRoot(
        ChartConfigLowering(
          ChartConfig(
            datasets: [
              ScatterDataset(
                data: .points([DataPoint(10, 15), DataPoint(12, 10)]),
                label: 'dataset1',
              ),
              ScatterDataset(
                data: .points([DataPoint(20, 10), DataPoint(4, 8)]),
                label: 'dataset2',
              ),
            ],
          ),
        ).lower(),
      );

      final meta = chart.getDatasetMeta(0);
      expect(meta.dataset is LineElement, false);
    });

    testWidgets(
      'should create line element if showline is true at datasets options',
      (tester) async {
        final chart = acquireChartRoot(
          ChartConfigLowering(
            ChartConfig(
              datasets: [
                ScatterDataset(
                  showLine: true,
                  data: .points([DataPoint(10, 15), DataPoint(12, 10)]),
                  label: 'dataset1',
                ),
                ScatterDataset(
                  data: .points([DataPoint(20, 10), DataPoint(4, 8)]),
                  label: 'dataset2',
                ),
              ],
            ),
          ).lower(),
        );

        final meta = chart.getDatasetMeta(0);
        expect(meta.dataset is LineElement, true);
      },
    );

    testWidgets(
      'should create line element if showline is true at root options',
      (tester) async {
        final chart = acquireChartRoot(
          ChartConfigLowering(
            ChartConfig(
              datasets: [
                ScatterDataset(
                  data: .points([DataPoint(10, 15), DataPoint(12, 10)]),
                  label: 'dataset1',
                ),
                ScatterDataset(
                  data: .points([DataPoint(20, 10), DataPoint(4, 8)]),
                  label: 'dataset2',
                ),
              ],
              extra: const {'showLine': true},
            ),
          ).lower(),
        );

        final meta = chart.getDatasetMeta(0);
        expect(meta.dataset is LineElement, true);
      },
    );

    // :146
    testWidgets('should not override tooltip title and label callbacks', (
      tester,
    ) async {
      final chart = acquireChartRoot(
        ChartConfigLowering(
          ChartConfig(
            datasets: [
              ScatterDataset(
                data: .points([DataPoint(10, 15), DataPoint(12, 10)]),
                label: 'Dataset 1',
              ),
              ScatterDataset(
                data: .points([DataPoint(20, 10), DataPoint(4, 8)]),
                label: 'Dataset 2',
              ),
            ],
            labels: const ['Label 1', 'Label 2'],
            responsive: true,
            maintainAspectRatio: true,
          ),
        ).lower(),
      );
      final tooltip = chart.tooltip!;
      final point = chart.getDatasetMeta(0).data[0];

      await triggerMouseEvent(chart, 'mousemove', point);

      expect(tooltip.title, equals(<String>['Label 1']));
      expect(
        tooltip.body,
        equals(<Matcher>[
          _bodyItem(['Dataset 1: (10, 15)']),
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
          _bodyItem(['Label 1: (10, 15)']),
          _bodyItem(['Label 2: (12, 10)']),
        ]),
      );
    });
  });
}
