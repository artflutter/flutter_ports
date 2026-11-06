// Original code, not ported from Chart.js: the data-only path of ChartView.
@TestOn('vm')
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart' hide Element;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/plugin.dart' show EventHookArgs;
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0098: with `dataOnlyUpdates`, a new typed config that differs
// from the last one only in its data Lists calls `chart.updateData()`. The
// layout count of a registered spy plugin tells the two paths apart: a full
// update runs `beforeLayout`, and the data-only lifecycle of Chart.js ADR 0074
// does not while the layout stays valid.
//
// The first resize notification of a new host invalidates the plan of the
// first update, also with no change of the size (`_resize`). Thus the first
// tick after the start is a full update, and [_warm] takes the chart past it.
//
// flutter_test_config.dart registers the built-in components with the seven
// plugins and sets `defaults.plugins.colors.enabled = false`.

const Color _blue = Color(0xFF0000FF);
const Color _red = Color(0xFFFF0000);
const Color _green = Color(0xFF00FF00);

const ValueKey<String> _a = ValueKey('a');
const ValueKey<String> _b = ValueKey('b');

const Map<String, ChartAxis> _cartesianAxes = {
  'x': LinearAxis(min: 0, max: 100),
  'y': LinearAxis(min: 0, max: 100),
};

const Map<String, ChartAxis> _categoryAxes = {
  'x': CategoryAxis(),
  'y': LinearAxis(min: 0, max: 100),
};

const Map<String, ChartAxis> _radialAxis = {
  'r': RadialLinearAxis(min: 0, max: 100),
};

/// The labels of the charts of [_count] items: one growable List for a test
/// run, as an app with stable labels keeps it.
const int _count = 6;
List<Object> _newLabels() => <Object>[
  for (var i = 0; i < _count; i++) '$i',
];

double _value(int i, int step) => (10 + (i * 7 + step * 13) % 80).toDouble();

List<double> _values(int step, {int count = _count}) => <double>[
  for (var i = 0; i < count; i++) _value(i, step),
];

List<DataPoint> _points(int step, {int count = _count}) => <DataPoint>[
  for (var i = 0; i < count; i++) DataPoint(i * 10, _value(i, step)),
];

/// A dataset of the chart type [type], with new data for [step].
Dataset _dataset(ChartKind type, int step, {ChartValue<Color>? color}) =>
    switch (type) {
      ChartKind.bar => BarDataset(
        label: 'd',
        data: _values(step),
        backgroundColor: color ?? const ChartValue.constant(_blue),
        borderWidth: 0,
      ),
      ChartKind.line => LineDataset(
        label: 'd',
        points: _points(step),
        borderColor: color ?? const ChartValue.constant(_blue),
        pointRadius: 3,
        tension: .3,
        fill: ChartFill.origin,
      ),
      ChartKind.scatter => ScatterDataset(
        label: 'd',
        points: _points(step),
        backgroundColor: color ?? const ChartValue.constant(_blue),
        pointRadius: 3,
      ),
      ChartKind.bubble => BubbleDataset(
        label: 'd',
        points: <DataPoint>[
          for (var i = 0; i < _count; i++)
            DataPoint.bubble(i * 10, _value(i, step), 4),
        ],
        backgroundColor: color ?? const ChartValue.constant(_blue),
        borderWidth: 0,
      ),
      ChartKind.pie => PieDataset(
        label: 'd',
        data: _values(step),
        backgroundColor: color ?? const ChartValue.constant(_blue),
        borderWidth: 0,
      ),
      ChartKind.doughnut => DoughnutDataset(
        label: 'd',
        data: _values(step),
        backgroundColor: color ?? const ChartValue.constant(_blue),
        borderWidth: 0,
      ),
      ChartKind.polarArea => PolarAreaDataset(
        label: 'd',
        data: _values(step),
        backgroundColor: color ?? const ChartValue.constant(_blue),
        borderWidth: 0,
      ),
      _ => RadarDataset(
        label: 'd',
        data: _values(step),
        borderColor: color ?? const ChartValue.constant(_blue),
        pointRadius: 3,
        fill: ChartFill.start,
      ),
    };

const List<ChartKind> _kinds = [
  ChartKind.bar,
  ChartKind.line,
  ChartKind.scatter,
  ChartKind.bubble,
  ChartKind.pie,
  ChartKind.doughnut,
  ChartKind.polarArea,
  ChartKind.radar,
];

/// The config of [type] at [step]: axes with a fixed range and no animation.
ChartConfig _config(ChartKind type, int step, List<Object> labels) =>
    ChartConfig(
      type: type,
      labels: labels,
      datasets: [_dataset(type, step)],
      scales: switch (type) {
        ChartKind.pie || ChartKind.doughnut => null,
        ChartKind.polarArea || ChartKind.radar => _radialAxis,
        ChartKind.scatter || ChartKind.bubble => _cartesianAxes,
        _ => _categoryAxes,
      },
      animation: ChartAnimation.none,
    );

/// A raw config of a bar chart with a fixed range and no animation.
Map<String, Object?> _rawBars(int step) => <String, Object?>{
  'type': 'bar',
  'data': <String, Object?>{
    'labels': <Object?>['a', 'b'],
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[1.0 + step, 2.0],
      },
    ],
  },
  'options': <String, Object?>{
    'animation': false,
    'scales': <String, Object?>{
      'y': <String, Object?>{'min': 0.0, 'max': 100.0},
    },
  },
};

/// The bar chart that most tests vary.
ChartConfig _bars(
  int step,
  List<Object> labels, {
  List<Dataset>? datasets,
  Map<String, ChartAxis>? scales = _categoryAxes,
  ChartAnimation? animation = ChartAnimation.none,
  ChartTitle? title,
  List<Map<String, Object?>>? plugins,
  Map<String, Object?>? extra,
}) => ChartConfig(
  type: ChartKind.bar,
  labels: labels,
  datasets:
      datasets ??
      [
        BarDataset(
          key: _a,
          label: 'd',
          data: _values(step),
          backgroundColor: const ChartValue.constant(_blue),
          borderWidth: 0,
        ),
      ],
  scales: scales,
  animation: animation,
  title: title,
  plugins: plugins,
  extra: extra,
);

Widget _box(Widget child, {double width = 400, double height = 300}) =>
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, height: height, child: child),
      ),
    );

Widget _view(
  ChartConfig config, {
  bool dataOnly = true,
  String? updateMode = 'none',
  ChartThemeData? theme,
}) => _box(
  ChartView(
    config: config,
    updateMode: updateMode,
    dataOnlyUpdates: dataOnly,
    theme: theme,
  ),
);

Chart _chart(WidgetTester tester) => Chart.getChart(
  tester.renderObject<RenderChartHost>(find.byType(ChartHost)).canvas,
)!;

/// The updates and the layouts of the chart since the last [clear].
final class _Spy {
  final List<Object?> modes = <Object?>[];
  int layouts = 0;
  int draws = 0;

  void clear() {
    modes.clear();
    layouts = 0;
    draws = 0;
  }
}

/// A registered spy plugin that opts in to the data-only lifecycle. It
/// unregisters at the end of the test.
_Spy _spyOnChart() {
  final spy = _Spy();
  final plugin = <String, Object?>{
    'id': r'$dataOnlySpy',
    'supportsDataUpdates': true,
    'beforeUpdate': (Object? chart, JsObjectFace args, Object? options) {
      spy.modes.add(args['mode']);
    },
    'beforeLayout': (Object? chart, Object? args, Object? options) {
      spy.layouts++;
    },
    'afterDraw': (Object? chart, Object? args, Object? options) {
      spy.draws++;
    },
  };
  Chart.register([plugin]);
  addTearDown(() => Chart.unregister([plugin]));
  return spy;
}

Object? _plain(Object? value) {
  if (value is double &&
      (!value.isFinite || (value == 0 && value.isNegative))) {
    return value.toString();
  }
  if (value is JsObjectFace) {
    return {for (final key in value.jsKeys()) key: _plain(value.jsRead(key))};
  }
  if (value is Map) {
    return {for (final e in value.entries) e.key: _plain(e.value)};
  }
  if (value is List) return value.map(_plain).toList();
  return value;
}

/// What the chart shows: the chart area, the parsed values, the element
/// geometry and the hit result at the center.
Object _observe(Chart chart) {
  final area = chart.chartArea;
  final result = <Object?>[
    [area?.left, area?.top, area?.right, area?.bottom],
  ];
  for (var d = 0; d < chart.getSortedVisibleDatasetMetas().length; d++) {
    final meta = chart.getSortedVisibleDatasetMetas()[d];
    result.add(_plain(meta.parsed));
    for (final element in meta.data) {
      result.add([
        for (final key in const [
          'x',
          'y',
          'base',
          'width',
          'height',
          'startAngle',
          'endAngle',
          'circumference',
          'innerRadius',
          'outerRadius',
          'skip',
          'stop',
        ])
          _plain((element as types.ElementPropertyRead)[key]),
      ]);
    }
  }
  return result;
}

/// The bytes of the chart canvas over white.
Future<Uint8List> _pixels(WidgetTester tester, Chart chart) async {
  final canvas = chart.canvas! as UiCanvasElement;
  final w = canvas.width;
  final h = canvas.height;
  final recorder = ui.PictureRecorder();
  final c = ui.Canvas(recorder)
    ..drawRect(
      ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
  canvas.getContext2d().paint(c, ui.Offset.zero, 1, 1);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(w, h);
  try {
    final data = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawStraightRgba),
    );
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
  }
}

/// The start of a chart and its first tick, which is a full update.
Future<void> _warm(WidgetTester tester, Widget Function(int step) view) async {
  await tester.pumpWidget(view(0));
  await tester.pump();
  await tester.pumpWidget(view(1));
}

Future<TestGesture> _mouse(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(mouse.removePointer);
  await mouse.addPointer(location: const Offset(399, 299));
  return mouse;
}

void main() {
  group('a data-only change takes updateData', () {
    for (final type in _kinds) {
      testWidgets('${type.name} keeps the layout and matches a full update', (
        tester,
      ) async {
        final spy = _spyOnChart();
        Future<(List<Object>, Uint8List)> run({required bool dataOnly}) async {
          final labels = _newLabels();
          final seen = <Object>[];
          await _warm(
            tester,
            (step) => _view(_config(type, step, labels), dataOnly: dataOnly),
          );
          for (var step = 2; step < 5; step++) {
            spy.clear();
            await tester.pumpWidget(
              _view(_config(type, step, labels), dataOnly: dataOnly),
            );
            expect(spy.modes, ['none'], reason: 'step $step');
            expect(spy.layouts, dataOnly ? 0 : 1, reason: 'step $step');
            expect(spy.draws, 1, reason: 'step $step');
            seen.add(_observe(_chart(tester)));
          }
          final pixels = await _pixels(tester, _chart(tester));
          await tester.pumpWidget(const SizedBox());
          return (seen, pixels);
        }

        final (fast, fastPixels) = await run(dataOnly: true);
        final (full, fullPixels) = await run(dataOnly: false);
        expect(fast, full);
        expect(fastPixels, fullPixels);
      });
    }

    testWidgets('it keeps the scale objects and the ticks', (tester) async {
      final labels = _newLabels();
      await _warm(tester, (step) => _view(_bars(step, labels)));
      final chart = _chart(tester);
      final area = chart.chartArea;
      final ticks = chart.scales['y']!.ticks;
      await tester.pumpWidget(_view(_bars(2, labels)));
      expect(chart.chartArea, same(area));
      expect(chart.scales['y']!.ticks, same(ticks));
    });

    testWidgets('a null updateMode gives the mode none to the hooks', (
      tester,
    ) async {
      final spy = _spyOnChart();
      final labels = _newLabels();
      Widget view(int step) => _view(_bars(step, labels), updateMode: null);
      await tester.pumpWidget(view(0));
      await tester.pump();
      spy.clear();
      await tester.pumpWidget(view(1));
      expect(spy.modes, ['none'], reason: 'updateData goes to update(none)');
      expect(spy.layouts, 1);
      spy.clear();
      await tester.pumpWidget(view(2));
      expect(spy.modes, ['none']);
      expect(spy.layouts, 0);
    });

    /// The twin of [view] over [steps] ticks: the elements and the pixels
    /// with the parameter and without it.
    Future<void> expectTwin(
      WidgetTester tester,
      Widget Function(int step, {required bool dataOnly}) view, {
      int steps = 3,
    }) async {
      final spy = _spyOnChart();
      Future<List<Object>> run({required bool dataOnly}) async {
        await _warm(tester, (step) => view(step, dataOnly: dataOnly));
        final seen = <Object>[];
        for (var step = 2; step < 2 + steps; step++) {
          spy.clear();
          await tester.pumpWidget(view(step, dataOnly: dataOnly));
          expect(spy.layouts, dataOnly ? 0 : 1, reason: 'step $step');
          seen.add(_observe(_chart(tester)));
        }
        seen.add(await _pixels(tester, _chart(tester)));
        await tester.pumpWidget(const SizedBox());
        return seen;
      }

      expect(await run(dataOnly: true), await run(dataOnly: false));
    }

    testWidgets('a null updateMode matches a full update of the default mode', (
      tester,
    ) async {
      final labels = _newLabels();
      await expectTwin(
        tester,
        (step, {required dataOnly}) =>
            _view(_bars(step, labels), dataOnly: dataOnly, updateMode: null),
      );
    });

    testWidgets('the palette of the colors plugin stays', (tester) async {
      final labels = _newLabels();
      await expectTwin(
        tester,
        (step, {required dataOnly}) => _view(
          _bars(
            step,
            labels,
            datasets: [BarDataset(key: _a, data: _values(step))],
            extra: const {
              'plugins': {
                'colors': {'enabled': true},
              },
            },
          ),
          dataOnly: dataOnly,
        ),
      );
    });

    testWidgets('a theme stays', (tester) async {
      final labels = _newLabels();
      await expectTwin(
        tester,
        (step, {required dataOnly}) => _view(
          _bars(step, labels),
          dataOnly: dataOnly,
          theme: const ChartThemeData.dark(),
        ),
      );
    });

    testWidgets('an overflow that changes runs the layout, with the result of '
        'a full update', (tester) async {
      final spy = _spyOnChart();
      ChartConfig bubbles(int step) => ChartConfig(
        type: ChartKind.bubble,
        datasets: [
          BubbleDataset(
            points: <DataPoint>[DataPoint.bubble(50, 50, 4.0 + step)],
          ),
        ],
        scales: _cartesianAxes,
        animation: ChartAnimation.none,
      );
      Future<Object> run({required bool dataOnly}) async {
        await _warm(
          tester,
          (_) => _view(bubbles(0), dataOnly: dataOnly),
        );
        spy.clear();
        await tester.pumpWidget(_view(bubbles(3), dataOnly: dataOnly));
        expect(spy.layouts, 1);
        final seen = _observe(_chart(tester));
        await tester.pumpWidget(const SizedBox());
        return seen;
      }

      expect(await run(dataOnly: true), await run(dataOnly: false));
    });

    testWidgets('a full update after data-only updates matches the updates '
        'that were all full', (tester) async {
      Future<Object> run({required bool dataOnly}) async {
        final labels = _newLabels();
        await tester.pumpWidget(_view(_bars(0, labels), dataOnly: dataOnly));
        await tester.pump();
        await tester.pumpWidget(_view(_bars(1, labels), dataOnly: dataOnly));
        await tester.pumpWidget(_view(_bars(2, labels), dataOnly: dataOnly));
        await tester.pumpWidget(
          _view(
            _bars(
              3,
              labels,
              title: const ChartTitle(display: true, text: 'new'),
            ),
            dataOnly: dataOnly,
          ),
        );
        final seen = _observe(_chart(tester));
        await tester.pumpWidget(const SizedBox());
        return seen;
      }

      expect(await run(dataOnly: true), await run(dataOnly: false));
    });
  });

  group('each other change takes the full path', () {
    /// Starts a chart of [first], or of a bar chart, with `dataOnlyUpdates`,
    /// checks the path of a tick of new data ([eligible]: the data-only path),
    /// and pumps the config of [next]. Gives the spy of that update.
    Future<_Spy> afterChange(
      WidgetTester tester,
      ChartConfig Function(List<Object> labels) next, {
      ChartConfig Function(int step, List<Object> labels)? first,
      bool eligible = true,
    }) async {
      final spy = _spyOnChart();
      final labels = _newLabels();
      ChartConfig before(int step) =>
          first == null ? _bars(step, labels) : first(step, labels);
      await _warm(tester, (step) => _view(before(step)));
      spy.clear();
      await tester.pumpWidget(_view(before(2)));
      expect(spy.layouts, eligible ? 0 : 1, reason: 'the tick of new data');
      spy.clear();
      await tester.pumpWidget(_view(next(labels)));
      await tester.pump();
      return spy;
    }

    testWidgets('without the parameter', (tester) async {
      final spy = _spyOnChart();
      final labels = _newLabels();
      await _warm(
        tester,
        (step) => _view(_bars(step, labels), dataOnly: false),
      );
      spy.clear();
      await tester.pumpWidget(_view(_bars(2, labels), dataOnly: false));
      expect(spy.layouts, 1);
      expect(spy.modes, ['none']);
    });

    testWidgets('a raw config', (tester) async {
      final spy = _spyOnChart();
      Widget view(int step) =>
          _box(ChartView.raw(config: _rawBars(step), updateMode: 'none'));
      await _warm(tester, view);
      spy.clear();
      await tester.pumpWidget(view(2));
      expect(spy.layouts, 1);
      expect(
        tester.widget<ChartView>(find.byType(ChartView)).dataOnlyUpdates,
        isFalse,
      );
    });

    testWidgets('a change from a typed config to a raw one and back', (
      tester,
    ) async {
      final spy = _spyOnChart();
      final labels = _newLabels();
      await _warm(tester, (step) => _view(_bars(step, labels)));
      spy.clear();
      await tester.pumpWidget(
        _box(ChartView.raw(config: _rawBars(0), updateMode: 'none')),
      );
      expect(spy.layouts, 1);
      spy.clear();
      await tester.pumpWidget(_view(_bars(2, labels)));
      expect(spy.layouts, 1, reason: 'the typed config lowers again');
    });

    testWidgets('a new labels List', (tester) async {
      final spy = await afterChange(
        tester,
        (labels) => _bars(1, <Object>[...labels]),
      );
      expect(spy.layouts, 1);
    });

    testWidgets('an option field', (tester) async {
      final spy = await afterChange(
        tester,
        (labels) =>
            _bars(1, labels, title: const ChartTitle(display: true, text: 't')),
      );
      expect(spy.layouts, 1);
    });

    testWidgets('an entry of extra', (tester) async {
      final spy = await afterChange(
        tester,
        (labels) => _bars(1, labels, extra: const {'locale': 'de-DE'}),
      );
      expect(spy.layouts, 1);
    });

    testWidgets('a replaced plugin list', (tester) async {
      final plugin = <String, Object?>{
        'id': r'$replaced',
        'supportsDataUpdates': true,
      };
      final spy = await afterChange(
        tester,
        (labels) => _bars(1, labels, plugins: [plugin]),
      );
      expect(spy.layouts, 1);
    });

    testWidgets('the chart type', (tester) async {
      final spy = await afterChange(
        tester,
        (labels) => _config(ChartKind.line, 1, labels),
      );
      expect(spy.layouts, 1);
    });

    testWidgets('a dataset key', (tester) async {
      final spy = await afterChange(
        tester,
        (labels) => _bars(
          1,
          labels,
          datasets: [BarDataset(key: _b, data: _values(1))],
        ),
      );
      expect(spy.layouts, 1);
    });

    testWidgets('two keyed datasets in a new order', (tester) async {
      final spy = await afterChange(
        tester,
        (labels) => _bars(
          1,
          labels,
          datasets: [
            BarDataset(key: _b, data: _values(1)),
            BarDataset(key: _a, data: _values(2)),
          ],
        ),
        first: (step, labels) => _bars(
          step,
          labels,
          datasets: [
            BarDataset(key: _a, data: _values(step)),
            BarDataset(key: _b, data: _values(step + 3)),
          ],
        ),
      );
      expect(spy.layouts, 1);
    });

    testWidgets('a new dataset', (tester) async {
      final spy = await afterChange(
        tester,
        (labels) => _bars(
          1,
          labels,
          datasets: [
            BarDataset(key: _a, data: _values(1)),
            BarDataset(key: _b, data: _values(2)),
          ],
        ),
        first: (step, labels) => _bars(
          step,
          labels,
          datasets: [BarDataset(key: _a, data: _values(step))],
        ),
      );
      expect(spy.layouts, 1);
    });

    for (final (name, dataset) in <(String, Dataset Function(List<double>))>[
      (
        'a label',
        (data) => BarDataset(key: _a, label: 'new', data: data),
      ),
      (
        'a constant color',
        (data) => BarDataset(
          key: _a,
          data: data,
          backgroundColor: const ChartValue.constant(_red),
        ),
      ),
      ('hidden', (data) => BarDataset(key: _a, data: data, hidden: true)),
      ('an order', (data) => BarDataset(key: _a, data: data, order: 2)),
      ('a stack', (data) => BarDataset(key: _a, data: data, stack: 's')),
      (
        'a border width',
        (data) => BarDataset(key: _a, data: data, borderWidth: 3),
      ),
    ]) {
      testWidgets('a dataset field: $name', (tester) async {
        final spy = await afterChange(
          tester,
          (labels) => _bars(1, labels, datasets: [dataset(_values(1))]),
          first: (step, labels) => _bars(
            step,
            labels,
            datasets: [BarDataset(key: _a, data: _values(step))],
          ),
        );
        expect(spy.layouts, 1);
      });
    }

    testWidgets('a replaced indexed color', (tester) async {
      Dataset colored(int step, List<Color> colors) => BarDataset(
        key: _a,
        data: _values(step),
        backgroundColor: ChartValue.indexed(colors),
      );
      final spy = await afterChange(
        tester,
        (labels) => _bars(
          1,
          labels,
          datasets: [
            colored(1, [_red, _blue]),
          ],
        ),
        first: (step, labels) => _bars(
          step,
          labels,
          datasets: [
            colored(step, [_red, _green]),
          ],
        ),
        eligible: false,
      );
      expect(spy.layouts, 1);
    });

    testWidgets('an equal indexed color: updateData goes to the full update '
        'by itself', (tester) async {
      Dataset colored(int step) => BarDataset(
        key: _a,
        data: _values(step),
        backgroundColor: const ChartValue.indexed([_red, _green]),
      );
      final spy = await afterChange(
        tester,
        (labels) => _bars(3, labels, datasets: [colored(3)]),
        first: (step, labels) => _bars(step, labels, datasets: [colored(step)]),
        eligible: false,
      );
      expect(spy.layouts, 1);
      expect(spy.modes, ['none']);
    });

    testWidgets('a data List of another length', (tester) async {
      final spy = await afterChange(
        tester,
        (labels) => _bars(
          1,
          labels,
          datasets: [
            BarDataset(
              key: _a,
              data: _values(1, count: _count + 1),
            ),
          ],
        ),
        first: (step, labels) => _bars(
          step,
          labels,
          datasets: [BarDataset(key: _a, data: _values(step))],
        ),
      );
      expect(spy.layouts, 1);
    });

    testWidgets('a scale with no fixed range: updateData goes to the full '
        'update by itself', (tester) async {
      final spy = await afterChange(
        tester,
        (labels) => _bars(3, labels, scales: null),
        first: (step, labels) => _bars(step, labels, scales: null),
        eligible: false,
      );
      expect(spy.layouts, 1);
      expect(spy.modes, ['none']);
    });

    testWidgets('a plugin that does not opt in: updateData goes to the full '
        'update by itself', (tester) async {
      var layouts = 0;
      final plugin = <String, Object?>{
        'id': r'$noOptIn',
        'beforeLayout': (Object? chart, Object? args, Object? options) {
          layouts++;
        },
      };
      await afterChange(
        tester,
        (labels) => _bars(3, labels, plugins: [plugin]),
        first: (step, labels) => _bars(step, labels, plugins: [plugin]),
        eligible: false,
      );
      expect(layouts, 4, reason: 'the start and each update');
    });

    testWidgets('a mode other than none', (tester) async {
      final spy = _spyOnChart();
      final labels = _newLabels();
      Widget view(int step) => _view(_bars(step, labels), updateMode: 'resize');
      await _warm(tester, view);
      spy.clear();
      await tester.pumpWidget(view(2));
      expect(spy.modes, ['resize']);
      expect(spy.layouts, 1);
    });

    testWidgets('a config with animation', (tester) async {
      final spy = _spyOnChart();
      final labels = _newLabels();
      ChartConfig animated(int step) => _bars(
        step,
        labels,
        animation: const ChartAnimation(duration: Duration(seconds: 1)),
      );
      await tester.pumpWidget(_view(animated(0)));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_view(animated(1)));
      await tester.pumpAndSettle();
      spy.clear();
      await tester.pumpWidget(_view(animated(2)));
      expect(spy.modes, ['none']);
      expect(spy.layouts, 1);
      await tester.pumpAndSettle();
    });

    testWidgets('a config with the default animation', (tester) async {
      final spy = _spyOnChart();
      final labels = _newLabels();
      await tester.pumpWidget(_view(_bars(0, labels, animation: null)));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_view(_bars(1, labels, animation: null)));
      await tester.pumpAndSettle();
      spy.clear();
      await tester.pumpWidget(_view(_bars(2, labels, animation: null)));
      expect(spy.layouts, 1);
      await tester.pumpAndSettle();
    });

    testWidgets('an animation of extra over ChartAnimation.none', (
      tester,
    ) async {
      final spy = _spyOnChart();
      final labels = _newLabels();
      ChartConfig animated(int step) => _bars(
        step,
        labels,
        extra: const {
          'animation': {'duration': 500},
        },
      );
      await tester.pumpWidget(_view(animated(0)));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_view(animated(1)));
      await tester.pumpAndSettle();
      spy.clear();
      await tester.pumpWidget(_view(animated(2)));
      expect(spy.layouts, 1);
      await tester.pumpAndSettle();
    });

    testWidgets('a new theme gives the mode of the theme switch', (
      tester,
    ) async {
      final spy = _spyOnChart();
      final labels = _newLabels();
      Widget light(int step) =>
          _view(_bars(step, labels), theme: const ChartThemeData.light());
      await _warm(tester, light);
      spy.clear();
      await tester.pumpWidget(light(2));
      expect(spy.layouts, 0, reason: 'the same theme');
      spy.clear();
      await tester.pumpWidget(
        _view(_bars(3, labels), theme: const ChartThemeData.dark()),
      );
      expect(spy.modes, ['theme']);
      expect(spy.layouts, 1);
      await tester.pumpAndSettle();
    });

    testWidgets('the reduced-motion preference gives the default mode', (
      tester,
    ) async {
      final spy = _spyOnChart();
      final labels = _newLabels();
      Widget view(int step, {required bool reduced}) => MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: _view(_bars(step, labels)),
      );
      await _warm(tester, (step) => view(step, reduced: false));
      spy.clear();
      await tester.pumpWidget(view(2, reduced: false));
      expect(spy.layouts, 0);
      spy.clear();
      await tester.pumpWidget(view(3, reduced: true));
      expect(spy.modes, [undefined]);
      expect(spy.layouts, 1);
      spy.clear();
      await tester.pumpWidget(view(4, reduced: true));
      expect(spy.modes, ['none']);
      expect(spy.layouts, 0, reason: 'the preference stays on');
    });

    testWidgets('a resize, with the result of a full update', (tester) async {
      final spy = _spyOnChart();
      Future<Object> run({required bool dataOnly}) async {
        final labels = _newLabels();
        Widget view(int step, double width) => _box(
          ChartView(
            config: _bars(step, labels),
            updateMode: 'none',
            dataOnlyUpdates: dataOnly,
          ),
          width: width,
        );
        await _warm(tester, (step) => view(step, 400));
        spy.clear();
        await tester.pumpWidget(view(2, 400));
        expect(spy.layouts, dataOnly ? 0 : 1);
        spy.clear();
        await tester.pumpWidget(view(3, 320));
        await tester.pump();
        await tester.pump();
        expect(spy.layouts, greaterThanOrEqualTo(1));
        expect(_chart(tester).width, 320);
        final seen = _observe(_chart(tester));
        spy.clear();
        await tester.pumpWidget(view(4, 320));
        expect(spy.layouts, dataOnly ? 0 : 1, reason: 'the new layout stays');
        final next = _observe(_chart(tester));
        await tester.pumpWidget(const SizedBox());
        return [seen, next];
      }

      expect(await run(dataOnly: true), await run(dataOnly: false));
    });
  });

  group('the visibility of a dataset', () {
    ChartConfig two(int step, List<Object> labels) => _bars(
      step,
      labels,
      datasets: [
        BarDataset(key: _a, data: _values(step)),
        BarDataset(key: _b, data: _values(step + 1)),
      ],
    );

    testWidgets('chart.hide runs a full update, and the next data tick shows '
        'what a full update shows', (tester) async {
      final spy = _spyOnChart();
      Future<Object> run({required bool dataOnly}) async {
        final labels = _newLabels();
        await _warm(
          tester,
          (step) => _view(two(step, labels), dataOnly: dataOnly),
        );
        spy.clear();
        _chart(tester).hide(0);
        expect(spy.layouts, 1);
        expect(_chart(tester).isDatasetVisible(0), isFalse);
        final hidden = _observe(_chart(tester));
        await tester.pumpWidget(_view(two(2, labels), dataOnly: dataOnly));
        final next = _observe(_chart(tester));
        final pixels = await _pixels(tester, _chart(tester));
        expect(_chart(tester).isDatasetVisible(0), isFalse);
        await tester.pumpWidget(const SizedBox());
        return [hidden, next, pixels];
      }

      expect(await run(dataOnly: true), await run(dataOnly: false));
    });

    testWidgets('setDatasetVisibility with no update makes the next tick a '
        'full update', (tester) async {
      final spy = _spyOnChart();
      final labels = _newLabels();
      await _warm(tester, (step) => _view(two(step, labels)));
      spy.clear();
      await tester.pumpWidget(_view(two(2, labels)));
      expect(spy.layouts, 0);
      _chart(tester).setDatasetVisibility(0, false);
      spy.clear();
      await tester.pumpWidget(_view(two(3, labels)));
      expect(spy.layouts, 1);
      spy.clear();
      await tester.pumpWidget(_view(two(4, labels)));
      expect(spy.layouts, 0, reason: 'the full update made a new plan');
      expect(_chart(tester).isDatasetVisible(0), isFalse);
    });

    testWidgets('toggleDataVisibility with no update makes the next tick a '
        'full update', (tester) async {
      final spy = _spyOnChart();
      final labels = _newLabels();
      await _warm(tester, (step) => _view(_bars(step, labels)));
      spy.clear();
      await tester.pumpWidget(_view(_bars(2, labels)));
      expect(spy.layouts, 0);
      _chart(tester).toggleDataVisibility(0);
      spy.clear();
      await tester.pumpWidget(_view(_bars(3, labels)));
      expect(spy.layouts, 1);
    });
  });

  group('the mouse of a live chart (Chart.js ADR 0091)', () {
    /// The events and the draws since the last [clear].
    final events = <String>[];
    var draws = 0;
    void clear() {
      events.clear();
      draws = 0;
    }

    final plugin = <String, Object?>{
      'id': r'$dataOnlyMouse',
      'supportsDataUpdates': true,
      'afterEvent': (Object? chart, Object? args, Object? options) {
        final event = args! as EventHookArgs;
        events.add(
          '${event.event!.type} '
          '${event.replay == true ? 'replay' : 'real'}',
        );
      },
      'afterDraw': (Object? chart, Object? args, Object? options) {
        draws++;
      },
    };

    ChartConfig live(int step, List<Object> labels) =>
        _bars(step, labels, plugins: [plugin]);

    /// A point inside each bar at [index]: above the base of the bars.
    Offset point(WidgetTester tester, int index) {
      final chart = _chart(tester);
      final bar =
          chart.getDatasetMeta(0).data[index] as types.ElementPropertyRead;
      return tester.getTopLeft(find.byType(ChartView)) +
          Offset(bar['x']! as double, chart.chartArea!.bottom - 2);
    }

    setUp(clear);

    testWidgets('each frame has one hover pass and one draw', (tester) async {
      final spy = _spyOnChart();
      final labels = _newLabels();
      await _warm(tester, (step) => _view(live(step, labels)));
      final mouse = await _mouse(tester);
      // A display of 120 Hz. The steps take longer than the window of 34 ms of
      // Chart.js ADR 0091, so each data-only update must renew the window.
      for (var step = 2; step < 9; step++) {
        await mouse.moveTo(point(tester, 1) + Offset(step * .1, 0));
        clear();
        spy.clear();
        await tester.pumpWidget(
          _view(live(step, labels)),
          duration: const Duration(milliseconds: 8),
        );
        expect(events, ['mousemove replay'], reason: 'step $step');
        expect(draws, 1, reason: 'step $step');
        expect(spy.layouts, 0, reason: 'step $step');
        expect(_chart(tester).getActiveElements().single.index, 1);
      }
    });

    testWidgets('a live chart that stops releases the move after its frame', (
      tester,
    ) async {
      final labels = _newLabels();
      await _warm(tester, (step) => _view(live(step, labels)));
      final mouse = await _mouse(tester);
      await mouse.moveTo(point(tester, 1));
      clear();
      await tester.pump();
      expect(events, ['mousemove real']);
      expect(draws, 1);
      expect(_chart(tester).getActiveElements().single.index, 1);
    });

    testWidgets('the replay finds the element of the new data, as in a full '
        'update', (tester) async {
      Future<Object> run({required bool dataOnly}) async {
        final labels = _newLabels();
        await _warm(
          tester,
          (step) => _view(live(step, labels), dataOnly: dataOnly),
        );
        final mouse = await _mouse(tester);
        final seen = <Object?>[];
        for (var step = 2; step < 5; step++) {
          await mouse.moveTo(point(tester, step));
          await tester.pumpWidget(
            _view(live(step, labels), dataOnly: dataOnly),
          );
          seen
            ..add(
              _chart(tester).getActiveElements().map((e) => e.index).toList(),
            )
            ..add(_chart(tester).tooltip!.opacity)
            ..add(_observe(_chart(tester)))
            ..add(await _pixels(tester, _chart(tester)));
        }
        await mouse.removePointer();
        await tester.pumpWidget(const SizedBox());
        return seen;
      }

      expect(await run(dataOnly: true), await run(dataOnly: false));
    });
  });

  testWidgets('the diagnostics name the flag', (tester) async {
    final view = ChartView(
      config: _bars(0, _newLabels()),
      dataOnlyUpdates: true,
    );
    expect(view.toDiagnosticsNode().toStringDeep(), contains('data-only'));
  });
}
