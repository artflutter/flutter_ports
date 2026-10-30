// Original code, not ported from Chart.js: tests of the typed change test.
@TestOn('vm')
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0052, section 9: the change test of a typed config is
// `ChartConfig ==`. An `==` config gives no update, also from a parent that
// builds the config in each build. The event and tooltip callbacks lower to
// trampolines that call the callback of the newest config, so a new closure
// there gives no update. A new `...For` closure is a new value and gives an
// update. `ChartView.raw` keeps the identity test of Chart.js ADR 0049,
// section 4. The update count is the `beforeUpdate` count of a registered
// spy plugin, which the config does not name.

const Color _red = Color(0xFFFF0000);

/// [child] at the top left of a box of 400 x 300.
Widget _box(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: 400, height: 300, child: child),
  ),
);

/// The chart of the one ChartView of the tree.
Chart _chart(WidgetTester tester) {
  final host = tester.renderObject<RenderChartHost>(find.byType(ChartHost));
  return Chart.getChart(host.canvas)!;
}

/// A registered plugin whose `beforeUpdate` records the mode of each
/// update. It unregisters at the end of the test.
List<Object?> _spyOnUpdates() {
  final modes = <Object?>[];
  final plugin = <String, Object?>{
    'id': r'$updateSpy',
    'beforeUpdate': (Object? chart, Map<String, Object?> args, Object? o) {
      modes.add(args['mode']);
    },
  };
  Chart.register([plugin]);
  addTearDown(() => Chart.unregister([plugin]));
  return modes;
}

/// A parent that builds a new [ChartConfig] in each build from its fields.
class _Parent extends StatefulWidget {
  const _Parent({required this.data});

  final List<num?> data;

  @override
  State<_Parent> createState() => _ParentState();
}

class _ParentState extends State<_Parent> {
  late List<num?> data = widget.data;
  String? title;
  ValueChanged<ChartEventDetails>? onClick;
  ChartScript<Color>? colorFor;
  String label = '';

  /// Rebuilds with the given values: the fields that are not given stay.
  void show({
    List<num?>? data,
    String? title,
    ValueChanged<ChartEventDetails>? onClick,
    ChartScript<Color>? colorFor,
  }) => setState(() {
    this.data = data ?? this.data;
    this.title = title ?? this.title;
    this.onClick = onClick ?? this.onClick;
    this.colorFor = colorFor ?? this.colorFor;
  });

  void write(String text) => setState(() => label = text);

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChartView(
              config: ChartConfig(
                type: .bar,
                labels: const ['a', 'b', 'c'],
                datasets: [
                  BarDataset(
                    label: 'votes',
                    data: data,
                    backgroundColorFor: colorFor,
                  ),
                ],
                title: title == null
                    ? null
                    : ChartTitle(display: true, text: title),
                animation: ChartAnimation.none,
                onClick: onClick,
              ),
            ),
            Text(label, key: const ValueKey('label')),
          ],
        ),
      ),
    ),
  );
}

/// The point of the bar [index] of the dataset 0, in global coordinates.
Offset _barPoint(WidgetTester tester, Chart chart, int index) {
  final bar = chart.getDatasetMeta(0).data[index];
  return tester.getTopLeft(find.byType(ChartView)) +
      Offset(bar.x, (bar.y + chart.chartArea!.bottom) / 2);
}

Color _blueFor(ChartContext context) => const Color(0xFF0000FF);

void main() {
  group('the change test', () {
    testWidgets('a parent that builds an == config in each build gives no '
        'update', (tester) async {
      final modes = _spyOnUpdates();
      await tester.pumpWidget(const _Parent(data: [1, 2, 3]));
      final parent = tester.state<_ParentState>(find.byType(_Parent));
      expect(modes, hasLength(1));
      for (var i = 0; i < 3; i++) {
        parent.write('$i');
        await tester.pump();
      }
      expect(find.text('2'), findsOneWidget);
      expect(modes, hasLength(1));
    });

    testWidgets('a const config in a new widget gives no update', (
      tester,
    ) async {
      final modes = _spyOnUpdates();
      const config = ChartConfig(
        type: .line,
        labels: ['a', 'b'],
        datasets: [
          LineDataset(data: [1, 2]),
        ],
      );
      await tester.pumpWidget(_box(const ChartView(config: config)));
      await tester.pumpWidget(
        _box(
          const ChartView(
            config: ChartConfig(
              type: .line,
              labels: ['a', 'b'],
              datasets: [
                LineDataset(data: [1, 2]),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(modes, hasLength(1));
    });

    testWidgets('a new data List gives one update, and a changed field gives '
        'one update', (tester) async {
      final modes = _spyOnUpdates();
      await tester.pumpWidget(const _Parent(data: [1, 2, 3]));
      final parent = tester.state<_ParentState>(find.byType(_Parent));
      final chart = _chart(tester);

      final data = <num?>[4, 5, 6];
      parent.show(data: data);
      await tester.pump();
      expect(modes, [undefined, undefined]);
      expect(_chart(tester), same(chart));
      final dataset = (chart.data['datasets']! as List).first! as Map;
      expect(dataset['data'], same(data));

      parent.show(title: 'T');
      await tester.pump();
      expect(modes, hasLength(3));
      expect(chart.titleBlock, isNotNull);

      // The same values again: no update.
      parent.show(data: data, title: 'T');
      await tester.pump();
      expect(modes, hasLength(3));
    });

    testWidgets('a new xFor closure gives one update, the same tear-off '
        'none', (tester) async {
      final modes = _spyOnUpdates();
      await tester.pumpWidget(const _Parent(data: [1, 2, 3]));
      final parent = tester.state<_ParentState>(find.byType(_Parent));
      final chart = _chart(tester);

      parent.show(colorFor: _blueFor);
      await tester.pump();
      expect(modes, hasLength(2));
      expect(
        chart.getDatasetMeta(0).data.first.options!['backgroundColor'],
        'rgba(0, 0, 255, 1)',
      );
      parent.show(colorFor: _blueFor);
      await tester.pump();
      expect(modes, hasLength(2));

      parent.show(colorFor: (context) => _red);
      await tester.pump();
      expect(modes, hasLength(3));
      expect(
        chart.getDatasetMeta(0).data.first.options!['backgroundColor'],
        'rgba(255, 0, 0, 1)',
      );
    });

    testWidgets('ChartView.raw keeps the identity test', (tester) async {
      final modes = _spyOnUpdates();
      Map<String, Object?> config() => <String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'labels': <Object?>['a'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1],
            },
          ],
        },
        'options': <String, Object?>{'animation': false},
      };
      final raw = config();
      await tester.pumpWidget(_box(ChartView.raw(config: raw)));
      await tester.pumpWidget(_box(ChartView.raw(config: raw)));
      expect(modes, hasLength(1));
      // An equal Map that is a new object updates the chart.
      await tester.pumpWidget(_box(ChartView.raw(config: config())));
      expect(modes, hasLength(2));
    });

    testWidgets('a change of the form updates the same chart: raw, typed, '
        'raw', (tester) async {
      final modes = _spyOnUpdates();
      final raw = <String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'labels': <Object?>['a', 'b'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1, 2],
            },
          ],
        },
        'options': <String, Object?>{'animation': false},
      };
      await tester.pumpWidget(_box(ChartView.raw(config: raw)));
      final chart = _chart(tester);
      const typed = ChartConfig(
        type: .line,
        labels: ['a', 'b'],
        datasets: [
          LineDataset(label: 'typed', data: [3, 4]),
        ],
        animation: ChartAnimation.none,
      );
      await tester.pumpWidget(_box(const ChartView(config: typed)));
      expect(modes, hasLength(2));
      expect(_chart(tester), same(chart));
      expect(chart.config.type, 'line');
      expect(
        ((chart.data['datasets']! as List).first! as Map)['label'],
        'typed',
      );
      // The same typed config: no update.
      await tester.pumpWidget(_box(const ChartView(config: typed)));
      expect(modes, hasLength(2));

      await tester.pumpWidget(_box(ChartView.raw(config: raw)));
      expect(modes, hasLength(3));
      expect(_chart(tester), same(chart));
      expect(chart.config.type, 'bar');
      expect(chart.data, same(raw['data']));
    });

    testWidgets('two ChartViews with one const config lower their own Maps', (
      tester,
    ) async {
      const config = ChartConfig(
        type: .bar,
        labels: ['a'],
        datasets: [
          BarDataset(data: [1]),
        ],
        animation: ChartAnimation.none,
      );
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              SizedBox(
                width: 200,
                height: 100,
                child: ChartView(config: config),
              ),
              SizedBox(
                width: 200,
                height: 100,
                child: ChartView(config: config),
              ),
            ],
          ),
        ),
      );
      final hosts = tester
          .renderObjectList<RenderChartHost>(find.byType(ChartHost))
          .toList();
      final first = Chart.getChart(hosts[0].canvas)!;
      final second = Chart.getChart(hosts[1].canvas)!;
      expect(first.data, isNot(same(second.data)));
      expect(first.config.options, isNot(same(second.config.options)));
      expect(
        (first.data['datasets']! as List).first,
        isNot(same((second.data['datasets']! as List).first)),
      );
    });

    testWidgets('the diagnostics of a typed ChartView name the type and the '
        'dataset count', (tester) async {
      const widget = ChartView(
        config: ChartConfig(
          type: .pie,
          datasets: [
            PieDataset(data: [1]),
            PieDataset(data: [2]),
          ],
        ),
      );
      final properties = [
        for (final property in widget.toDiagnosticsNode().getProperties())
          if (!property.isFiltered(DiagnosticLevel.info)) property.toString(),
      ];
      expect(properties, ['type: pie', 'datasets: 2']);
    });
  });

  group('callbacks', () {
    testWidgets('a new inline onClick closure gives no update, and the next '
        'click calls it with int indexes', (tester) async {
      final modes = _spyOnUpdates();
      await tester.pumpWidget(const _Parent(data: [1, 2, 3]));
      final parent = tester.state<_ParentState>(find.byType(_Parent));
      final chart = _chart(tester);
      final point = _barPoint(tester, chart, 1);

      parent.show(
        onClick: (details) => parent.write('first ${details.hits.length}'),
      );
      await tester.pump();
      // The presence of onClick changed: one update.
      expect(modes, hasLength(2));
      await tester.tapAt(point);
      await tester.pump();
      await tester.pump();
      expect(find.text('first 1'), findsOneWidget);

      parent.show(
        onClick: (details) {
          final hit = details.hits.single;
          final index = hit.index;
          final datasetIndex = hit.datasetIndex;
          parent.write('second $datasetIndex $index');
        },
      );
      await tester.pump();
      expect(modes, hasLength(2));
      await tester.tapAt(point);
      await tester.pump();
      await tester.pump();
      expect(find.text('second 0 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a legend onClick replaces the toggle and gets the item; a '
        'new closure gives no update', (tester) async {
      final modes = _spyOnUpdates();
      final clicks = <String>[];
      ChartConfig config(String name) => ChartConfig(
        type: .bar,
        labels: const ['a', 'b'],
        datasets: const [
          BarDataset(label: 'A', data: [1, 2]),
          BarDataset(label: 'B', data: [3, 4]),
        ],
        legend: ChartLegend(
          onClick: (details) => clicks.add(
            '$name ${details.item.text} ${details.item.datasetIndex}',
          ),
        ),
        animation: ChartAnimation.none,
      );
      await tester.pumpWidget(_box(ChartView(config: config('first'))));
      final chart = _chart(tester);
      final box = chart.legend!.legendHitBoxes[1];
      final center =
          tester.getTopLeft(find.byType(ChartView)) +
          Offset(
            (box['left']! as num) + (box['width']! as num) / 2,
            (box['top']! as num) + (box['height']! as num) / 2,
          );
      await tester.tapAt(center);
      await tester.pump();
      expect(clicks, ['first B 1']);
      expect(chart.isDatasetVisible(1), isTrue);

      await tester.pumpWidget(_box(ChartView(config: config('second'))));
      expect(modes, hasLength(1));
      await tester.tapAt(center);
      await tester.pump();
      expect(clicks, ['first B 1', 'second B 1']);
    });

    testWidgets('a tooltip labelText of the newest config gives the text, and '
        'null gives the default text', (tester) async {
      String? text;
      ChartConfig config() => ChartConfig(
        type: .bar,
        labels: const ['a', 'b'],
        datasets: const [
          BarDataset(label: 'A', data: [1, 2]),
        ],
        tooltip: ChartTooltip(labelText: (item) => text),
        animation: ChartAnimation.none,
      );
      await tester.pumpWidget(_box(ChartView(config: config())));
      final chart = _chart(tester);
      final point = _barPoint(tester, chart, 1);
      List<Object?> lines() => [
        for (final item in chart.tooltip!.body!)
          ...(item! as Map<String, Object?>)['lines']! as List<Object?>,
      ];

      text = 'typed';
      await tester.pumpWidget(_box(ChartView(config: config())));
      await tester.tapAt(point);
      await tester.pump();
      expect(lines(), ['typed']);

      // The tooltip makes new lines for another element (plugin.tooltip.js,
      // `handleEvent`).
      text = null;
      await tester.pumpWidget(_box(ChartView(config: config())));
      await tester.tapAt(_barPoint(tester, chart, 0));
      await tester.pump();
      expect(lines(), ['A: 1']);
    });
  });

  group('dispose', () {
    testWidgets('the unmount destroys the chart, also with an update that is '
        'pending', (tester) async {
      await tester.pumpWidget(const _Parent(data: [1, 2, 3]));
      final parent = tester.state<_ParentState>(find.byType(_Parent));
      final chart = _chart(tester);
      expect(Chart.instances, isNotEmpty);

      // A new config before the frame: the update callback is pending.
      parent.show(data: [4, 5, 6]);
      tester.binding.buildOwner!.buildScope(tester.binding.rootElement!);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
      expect(Chart.instances, isEmpty);
      expect(chart.canvas, isNull);
    });
  });
}
