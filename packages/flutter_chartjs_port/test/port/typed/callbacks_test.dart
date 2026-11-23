// Original code, not ported from Chart.js: tests of the typed callbacks.
@TestOn('vm')
library;

import 'dart:ui' as native_ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/drop_extra_args.dart';

// Chart.js ADR 0052, section 6: the views and the details objects of the
// typed callbacks over the objects of a real chart. The raw callbacks of
// these charts cast the arguments of the chart to the views, as the
// lowering of the typed config does: `ActiveElement`, `ChartContext`,
// `TooltipItem` and `LegendItem` give `int` indexes and the
// values of the objects, and a `List<ActiveElement>` is a `List<ActiveElement>`
// with no copy. The unit cases pin the rule for the JS `undefined`, an
// absent key and a value of another type.
//
// The group "the lowered callbacks in a chart" runs the lowered typed
// config (Chart.js ADR 0052, section 2, rules 6 and 7): the trampolines of
// `onClick`, `onHover` and the legend give the details with `int` indexes
// and call the callback of the newest config; a tooltip text of Dart `null`
// gives the default text; a tick format gets the scale and gives the
// labels of a raw `JsFunction`; an animation callback gets the details of
// the `AnimationEvent`.
//
// VM only: the chart cases are `testWidgets` cases of the harness.

/// A bar chart with the labels `a`, `b`, `c` and the datasets `A` and `B`,
/// with no animation and the options [options].
Map<String, Object?> _bar(Map<String, Object?> options) => <String, Object?>{
  'type': 'bar',
  'data': <String, Object?>{
    'labels': <Object?>['a', 'b', 'c'],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'A',
        'data': <Object?>[1, 2, 3],
      },
      <String, Object?>{
        'label': 'B',
        'data': <Object?>[3, 2, 7],
      },
    ],
  },
  'options': <String, Object?>{'animation': false, ...options},
};

/// The center of the legend hit box [index] of [chart].
Map<String, Object?> _legendBox(Chart chart, int index) {
  final box = chart.legend!.legendHitBoxes[index];
  final left = box.left;
  final top = box.top;
  final width = box.width;
  final height = box.height;
  return <String, Object?>{'x': left + width / 2, 'y': top + height / 2};
}

void main() {
  group('ActiveElement and ChartEventHandler', () {
    testWidgets('onClick gets the hits with int indexes and no copy', (
      tester,
    ) async {
      Object? active;
      ({ChartEvent event, List<ActiveElement> hits, Chart chart})? details;
      final chart = acquireChart(
        _bar(<String, Object?>{
          'onClick': (Object? event, Object? elements, Object? chart) {
            active = elements;
            details = (
              event: event! as ChartEvent,
              hits: elements! as List<ActiveElement>,
              chart: chart! as Chart,
            );
          },
        }),
      );
      final element = chart.getDatasetMeta(1).data[2];
      await triggerMouseEvent(chart, 'click', element);

      final hit = details!.hits.single;
      expect(hit.datasetIndex, isA<int>());
      expect([hit.datasetIndex, hit.index], [1, 2]);
      expect(hit.element, same(element));
      expect(details!.hits, same(active));
      expect(details!.event.type, 'click');
      expect(details!.chart, same(chart));
    });

    testWidgets('the hits go back to setActiveElements', (tester) async {
      List<ActiveElement>? hits;
      final chart = acquireChart(
        _bar(<String, Object?>{
          'onHover': (Object? event, Object? elements, Object? chart) {
            hits = elements! as List<ActiveElement>;
          },
        }),
      );
      await triggerMouseEvent(
        chart,
        'mousemove',
        chart.getDatasetMeta(0).data[1],
      );
      final hovered = List<ActiveElement>.of(hits!);
      chart.setActiveElements([]);
      expect(chart.getActiveElements(), isEmpty);
      chart.setActiveElements(hovered);
      expect(
        [
          for (final element in chart.getActiveElements())
            [element.datasetIndex, element.index],
        ],
        [
          [0, 1],
        ],
      );
    });
  });

  group('the typed contexts', () {
    testWidgets('a scriptable option gets the chart, dataset and data '
        'contexts', (tester) async {
      final contexts = <ContextObject>[];
      // Chart.js keeps one context object for each element and sets its
      // `active` at each resolution: the state at the call.
      final activeAtCall = <(int?, bool)>[];
      ChartPaint record(ScriptableContext context, Object? options) {
        contexts.add(context);
        activeAtCall.add((context.dataIndex, context.active));
        return const ChartPaint.solid(native_ui.Color.fromRGBO(255, 0, 0, 1));
      }

      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': <Object?>['a', 'b'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[5, 7],
              'borderColor': record,
              'hoverBorderColor': record,
            },
          ],
        },
        'options': <String, Object?>{
          'animation': false,
          'layout': <String, Object?>{
            'padding': (ContextObject context, Object? options) {
              contexts.add(context);
              return EdgeInsets.zero;
            },
          },
        },
      });

      final chartContext = contexts.whereType<ScriptableChartContext>().first;
      expect(chartContext.chart, same(chart));
      expect(chartContext.type, 'chart');

      final datasetContext = contexts.whereType<ScriptableContext>().firstWhere(
        (c) => c.type == 'dataset',
      );
      expect(datasetContext.chart, same(chart));
      expect(
        [
          datasetContext.datasetIndex,
          datasetContext.dataIndex,
          datasetContext.active,
          datasetContext.raw,
        ],
        [0, null, false, null],
      );

      final dataContext = contexts.whereType<ScriptableContext>().lastWhere(
        (c) => c.type == 'data' && c.dataIndex == 1,
      );
      expect(dataContext.chart, same(chart));
      expect(
        [
          dataContext.datasetIndex,
          dataContext.dataIndex,
          dataContext.active,
          dataContext.raw,
        ],
        [0, 1, false, 7],
      );
      expect((dataContext.parsed! as ParsedItem).y, 7);

      activeAtCall.clear();
      await triggerMouseEvent(
        chart,
        'mousemove',
        chart.getDatasetMeta(0).data[1],
      );
      expect(
        activeAtCall,
        contains((1, true)),
        reason: 'the hover style resolves in an active context',
      );
    });
  });

  group('TooltipItem', () {
    testWidgets('a tooltip label callback gets the item of the hit', (
      tester,
    ) async {
      final items = <TooltipItem>[];
      final chart = acquireChartRoot(
        ChartConfigLowering(
          ChartConfig(
            labels: const ['a', 'b', 'c'],
            datasets: const [
              BarDataset(label: 'A', data: .values([1, 2, 3])),
              BarDataset(label: 'B', data: .values([3, 2, 7])),
            ],
            animation: ChartAnimation.none,
            pluginOptions: [
              TooltipOptions(
                callbacks: TooltipCallbacks(
                  label: (tooltip, item) {
                    items.add(item);
                    return ['L'];
                  },
                ),
              ),
            ],
          ),
        ).lower(),
      );
      await triggerMouseEvent(
        chart,
        'mousemove',
        chart.getDatasetMeta(1).data[2],
      );

      final item = items.last;
      expect(item.chart, same(chart));
      expect(item.datasetIndex, isA<int>());
      expect(item.dataIndex, isA<int>());
      expect(
        [
          item.label,
          item.formattedValue,
          item.datasetIndex,
          item.dataIndex,
          item.raw,
          item.datasetLabel,
        ],
        [
          ['c'],
          '7',
          1,
          2,
          7,
          'B',
        ],
      );
      expect((item.parsed! as JsObjectFace)['y'], 7);
    });

    test('a dataset without a String label gives no datasetLabel', () {
      final item = TooltipItem(
        chart: _NoChart(),
        dataset: const <String, Object?>{'label': 3},
        raw: null,
        parsed: null,
        label: const [],
        formattedValue: '1',
        datasetIndex: 0,
        dataIndex: 2,
      );
      expect(
        [item.datasetLabel, item.raw, item.label],
        [null, null, <String>[]],
      );
      expect([item.datasetIndex, item.dataIndex], [0, 2]);
      expect(
        TooltipItem(
          chart: _NoChart(),
          dataset: undefined,
          raw: null,
          parsed: null,
          label: const [],
          formattedValue: '',
          datasetIndex: 0,
          dataIndex: 0,
        ).datasetLabel,
        isNull,
      );
    });
  });

  group('LegendItem and LegendEventHandler', () {
    testWidgets('a legend onClick gets a dataset item', (tester) async {
      ({ChartEvent event, LegendItem item, LegendElement legend})? details;
      final chart = acquireChartRoot(
        ChartConfigLowering(
          ChartConfig(
            labels: const ['a', 'b', 'c'],
            datasets: const [
              BarDataset(label: 'A', data: .values([1, 2, 3])),
              BarDataset(label: 'B', data: .values([3, 2, 7])),
            ],
            animation: ChartAnimation.none,
            pluginOptions: [
              LegendOptions(
                onClick: (event, item, legend) {
                  details = (event: event, item: item, legend: legend);
                },
              ),
            ],
          ),
        ).lower(),
      );
      await triggerMouseEvent(chart, 'click', _legendBox(chart, 1));

      final item = details!.item;
      expect(item.datasetIndex, isA<int>());
      expect(
        [item.text, item.datasetIndex, item.index, item.hidden],
        [
          ['B'],
          1,
          null,
          false,
        ],
      );
      expect(details!.legend, same(chart.legend));
      expect(details!.event.type, 'click');
      // The onClick of the app replaces the default toggle.
      expect(chart.isDatasetVisible(1), isTrue);
    });

    testWidgets('a doughnut legend item has the data index', (tester) async {
      LegendItem? clicked;
      final chart =
          acquireChartRoot(
              ChartConfigLowering(
                ChartConfig(
                  labels: const ['a', 'b', 'c'],
                  datasets: const [
                    DoughnutDataset(data: [1, 2, 3]),
                  ],
                  animation: ChartAnimation.none,
                  pluginOptions: [
                    LegendOptions(
                      onClick: (event, item, legend) => clicked = item,
                    ),
                  ],
                ),
              ).lower(),
            )
            ..toggleDataVisibility(2)
            ..update();
      await triggerMouseEvent(chart, 'click', _legendBox(chart, 2));

      expect(clicked!.index, isA<int>());
      expect(
        [clicked!.text, clicked!.datasetIndex, clicked!.index, clicked!.hidden],
        [
          ['c'],
          null,
          2,
          true,
        ],
      );
    });
  });

  group('TickCallback', () {
    testWidgets('a tick callback gets the scale and the tick', (tester) async {
      final calls =
          <({Scale scale, double value, int index, List<Tick> ticks})>[];
      final chart = acquireChart(
        _bar(<String, Object?>{
          'scales': <String, Object?>{
            'y': <String, Object?>{
              'ticks': <String, Object?>{
                'callback':
                    (Scale scale, double value, int index, List<Tick> ticks) {
                      calls.add((
                        scale: scale,
                        value: value,
                        index: index,
                        ticks: ticks,
                      ));
                      return ['T'];
                    },
              },
            },
          },
        }),
      );

      final scale = chart.scales['y']!;
      final last = calls.where((call) => identical(call.scale, scale)).last;
      expect(last.index, last.ticks.length - 1);
      expect(last.value, last.ticks[last.index].value);
      expect(scale.ticks!.first.label, ['T']);
    });
  });

  group('the lowered callbacks in a chart', () {
    /// A typed bar chart with the labels `a`, `b`, `c` and the datasets `A`
    /// and `B`, with no animation, as [_bar].
    ChartConfig typedBar({
      ChartEventHandler? onClick,
      ChartEventHandler? onHover,
      LegendOptions? legend,
      TooltipOptions? tooltip,
      List<ChartAxis>? scales,
    }) => ChartConfig(
      labels: const ['a', 'b', 'c'],
      datasets: const [
        BarDataset(label: 'A', data: .values([1, 2, 3])),
        BarDataset(label: 'B', data: .values([3, 2, 7])),
      ],
      scales: scales,
      animation: ChartAnimation.none,
      pluginOptions: [?legend, ?tooltip],
      onClick: onClick,
      onHover: onHover,
    );

    testWidgets('onClick gets int hits, from the newest config', (
      tester,
    ) async {
      final calls = <(String, List<ActiveElement>, Chart, ChartEvent)>[];
      final lowering = ChartConfigLowering(
        typedBar(
          onClick: (event, hits, chart) =>
              calls.add(('first', hits, chart, event)),
        ),
      );
      final chart = acquireChartRoot(lowering.lower());
      final element = chart.getDatasetMeta(1).data[2];
      await triggerMouseEvent(chart, 'click', element);

      final (name, hits, eventChart, event) = calls.single;
      expect(name, 'first');
      final hit = hits.single;
      expect(hit.datasetIndex, isA<int>());
      expect([hit.datasetIndex, hit.index], [1, 2]);
      expect(hit.element, same(element));
      expect(eventChart, same(chart));
      expect(event.type, 'click');

      // A new config with another closure: the trampoline of the chart
      // calls it with no new lowering.
      lowering.config = typedBar(
        onClick: (event, hits, chart) =>
            calls.add(('second', hits, chart, event)),
      );
      await triggerMouseEvent(chart, 'click', element);
      expect([for (final (name, _, _, _) in calls) name], ['first', 'second']);
    });

    testWidgets('onHover gets the hits of a move', (tester) async {
      final hits = <List<ActiveElement>>[];
      final chart = acquireChartRoot(
        ChartConfigLowering(
          typedBar(onHover: (event, elements, chart) => hits.add(elements)),
        ).lower(),
      );
      await triggerMouseEvent(
        chart,
        'mousemove',
        chart.getDatasetMeta(0).data[1],
      );
      expect(
        [for (final hit in hits.last) (hit.datasetIndex, hit.index)],
        [(0, 1)],
      );
    });

    testWidgets('a legend onClick replaces the default toggle', (tester) async {
      final items = <LegendItem>[];
      final chart = acquireChartRoot(
        ChartConfigLowering(
          typedBar(
            legend: LegendOptions(
              onClick: (event, item, legend) => items.add(item),
            ),
          ),
        ).lower(),
      );
      await triggerMouseEvent(chart, 'click', _legendBox(chart, 1));
      expect(
        [items.single.text, items.single.datasetIndex],
        [
          ['B'],
          1,
        ],
      );
      expect(chart.isDatasetVisible(1), isTrue);
    });

    testWidgets('a tooltip text of null gives the default text', (
      tester,
    ) async {
      /// The title, the label lines and the footer of the tooltip of a
      /// hover on bar 2 of dataset 1 of [config].
      Future<List<Object?>> tooltipOf(Object config) async {
        final chart = acquireChartRoot(config);
        await triggerMouseEvent(
          chart,
          'mousemove',
          chart.getDatasetMeta(1).data[2],
        );
        final tooltip = chart.tooltip!;
        return [
          tooltip.title,
          [for (final item in tooltip.body!) item.lines],
          tooltip.footer,
        ];
      }

      final defaults = await tooltipOf(ChartConfigLowering(typedBar()).lower());
      expect(defaults, [
        ['c'],
        [
          ['B: 7'],
        ],
        <Object?>[],
      ]);
      final nulls = await tooltipOf(
        ChartConfigLowering(
          typedBar(
            tooltip: TooltipOptions(
              callbacks: TooltipCallbacks(
                title: (tooltip, items) => null,
                label: (tooltip, item) => null,
                footer: (tooltip, items) => null,
              ),
            ),
          ),
        ).lower(),
      );
      expect(nulls, defaults);
      final texts = await tooltipOf(
        ChartConfigLowering(
          typedBar(
            tooltip: TooltipOptions(
              callbacks: TooltipCallbacks(
                title: (tooltip, items) => ['T ${items.length}'],
                label: (tooltip, item) => [
                  '${item.datasetLabel} ${item.dataIndex}',
                ],
                footer: (tooltip, items) => [
                  'F ${items.single.formattedValue}',
                ],
              ),
            ),
          ),
        ).lower(),
      );
      expect(texts, [
        ['T 1'],
        [
          ['B 2'],
        ],
        ['F 7'],
      ]);
    });

    testWidgets('a tick callback is the callback of the raw config', (
      tester,
    ) async {
      final scales = <Scale>[];
      List<String>? callback(
        Scale scale,
        double value,
        int index,
        List<Tick> ticks,
      ) {
        scales.add(scale);
        return index.isEven ? ['$value'] : null;
      }

      final typed = acquireChartRoot(
        ChartConfigLowering(
          typedBar(
            scales: [LinearAxis(.y, ticks: AxisTicks(callback: callback))],
          ),
        ).lower(),
      );
      final scale = typed.scales['y']!;
      expect(scales.last, same(scale));
      final twin = acquireChart(
        _bar(<String, Object?>{
          'scales': <String, Object?>{
            'y': <String, Object?>{
              'type': 'linear',
              'ticks': <String, Object?>{'callback': callback},
            },
          },
        }),
      );

      List<Object?> labels(Chart chart) => [
        for (final tick in chart.scales['y']!.ticks!) tick.label,
      ];
      expect(labels(typed), isNotEmpty);
      expect(labels(typed), labels(twin));
    });

    testWidgets('an animation callback gets the event', (tester) async {
      final details = <IAnimationEvent>[];
      final lowering = ChartConfigLowering(
        ChartConfig(
          datasets: const [BarDataset()],
          animation: ChartAnimation(onComplete: details.add),
        ),
      );
      final options = lowering.lower()['options']! as JsObjectFace;
      final onComplete = (options['animation']! as JsObjectFace)['onComplete'];
      final chart = acquireChart(_bar(const <String, Object?>{}));
      callDroppingExtraArgs(onComplete, [
        AnimationEvent(
          chart: chart,
          initial: true,
          numSteps: 1000,
          currentStep: 250,
        ),
      ]);
      callDroppingExtraArgs(onComplete, [AnimationEvent(chart: chart)]);
      expect(
        [
          for (final d in details)
            [identical(d.chart, chart), d.initial, d.numSteps, d.currentStep],
        ],
        [
          [true, true, 1000, 250],
          [true, null, null, null],
        ],
      );
    });
  });
}

final class _NoChart() implements Chart {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
