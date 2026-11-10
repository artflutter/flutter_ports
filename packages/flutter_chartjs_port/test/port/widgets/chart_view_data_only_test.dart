// Original code, not ported from Chart.js: the data-only path of ChartView.
@TestOn('vm')
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart' hide Element;
import 'package:flutter_chartjs_port/chartjs.dart' as chartjs show Element;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet, jsSet;
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
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

/// A scriptable radius that reads the mode of its context.
Object? _radiusOfMode(Object? context) =>
    (context! as JsObjectFace)['mode'] == 'none' ? 2.0 : 9.0;

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

/// The option [key] of [element].
Object? _option(types.Element element, String key) =>
    (element.options! as JsObjectFace)[key];

/// [_observe] with the options, their key order and the context of each
/// element.
Object _observeDeep(Chart chart) => [
  _observe(chart),
  for (final meta in chart.getSortedVisibleDatasetMetas())
    for (final element in meta.data)
      () {
        final options = element.options! as JsObjectFace;
        final context = (element as chartjs.Element).$context;
        return [
          _plain(options),
          options.jsKeys(),
          element.active,
          context?.jsKeys(),
          for (final key in const [
            'active',
            'dataIndex',
            'datasetIndex',
            'index',
            'mode',
            'parsed',
            'raw',
            'type',
          ])
            _plain(context?.jsRead(key)),
        ];
      }(),
];

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
      );
      expect(spy.layouts, 1);
      final bar = _chart(tester).getDatasetMeta(0).data[1];
      expect(_option(bar, 'backgroundColor'), _blue);
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

    testWidgets('a null updateMode gives the default mode to the hooks', (
      tester,
    ) async {
      final spy = _spyOnChart();
      final labels = _newLabels();
      Widget view(int step) => _view(_bars(step, labels), updateMode: null);
      await _warm(tester, view);
      for (var step = 2; step < 4; step++) {
        spy.clear();
        await tester.pumpWidget(view(step));
        expect(spy.modes, [undefined], reason: 'step $step');
        expect(spy.layouts, 1, reason: 'step $step');
      }
    });

    testWidgets('a null updateMode: a function of the context mode gets the '
        'default mode', (tester) async {
      final spy = _spyOnChart();
      Future<List<Object?>> run({required bool dataOnly}) async {
        final labels = _newLabels();
        ChartConfig line(int step) => ChartConfig(
          type: ChartKind.line,
          labels: labels,
          datasets: [LineDataset(points: _points(step))],
          scales: _categoryAxes,
          animation: ChartAnimation.none,
          extra: const {
            'elements': {
              'point': {'radius': _radiusOfMode},
            },
          },
        );
        Widget view(int step) =>
            _view(line(step), dataOnly: dataOnly, updateMode: null);
        await _warm(tester, view);
        spy.clear();
        await tester.pumpWidget(view(2));
        expect(spy.modes, [undefined]);
        final point =
            _chart(tester).getDatasetMeta(0).data[0]
                as types.ElementPropertyRead;
        final seen = <Object?>[
          (point['options']! as JsObjectFace)['radius'],
          await _pixels(tester, _chart(tester)),
        ];
        await tester.pumpWidget(const SizedBox());
        return seen;
      }

      final fast = await run(dataOnly: true);
      expect(fast.first, 9.0);
      expect(fast, await run(dataOnly: false));
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

  group('native indexed colors (Chart.js ADR 0100)', () {
    const kinds = [
      ChartKind.bar,
      ChartKind.scatter,
      ChartKind.bubble,
      ChartKind.pie,
      ChartKind.doughnut,
      ChartKind.polarArea,
    ];

    /// A dataset of [type] with an indexed background and border color.
    Dataset colored(
      ChartKind type,
      int step, {
      ChartValue<Color> background = const ChartValue.indexed([_red, _green]),
      ChartValue<Color> border = const ChartValue.indexed([
        _blue,
        _red,
        _green,
      ]),
      double radius = 4,
    }) => switch (type) {
      ChartKind.bar => BarDataset(
        key: _a,
        label: 'd',
        data: _values(step),
        backgroundColor: background,
        borderColor: border,
        borderWidth: 1,
      ),
      ChartKind.scatter => ScatterDataset(
        key: _a,
        label: 'd',
        points: _points(step),
        backgroundColor: background,
        borderColor: border,
        pointRadius: 3,
      ),
      ChartKind.bubble => BubbleDataset(
        key: _a,
        label: 'd',
        points: <DataPoint>[
          for (var i = 0; i < _count; i++)
            DataPoint.bubble(i * 10, _value(i, step), radius),
        ],
        backgroundColor: background,
        borderColor: border,
        borderWidth: 1,
      ),
      ChartKind.pie => PieDataset(
        key: _a,
        label: 'd',
        data: _values(step),
        backgroundColor: background,
        borderColor: border,
        borderWidth: 1,
      ),
      ChartKind.doughnut => DoughnutDataset(
        key: _a,
        label: 'd',
        data: _values(step),
        backgroundColor: background,
        borderColor: border,
        borderWidth: 1,
      ),
      _ => PolarAreaDataset(
        key: _a,
        label: 'd',
        data: _values(step),
        backgroundColor: background,
        borderColor: border,
        borderWidth: 1,
      ),
    };

    ChartConfig coloredConfig(
      ChartKind type,
      int step,
      List<Object> labels, {
      Dataset? dataset,
      ChartLegend? legend = const ChartLegend(display: false),
      ChartTitle? title,
    }) => ChartConfig(
      type: type,
      labels: labels,
      datasets: [dataset ?? colored(type, step)],
      scales: switch (type) {
        ChartKind.pie || ChartKind.doughnut => null,
        ChartKind.polarArea => _radialAxis,
        ChartKind.scatter || ChartKind.bubble => _cartesianAxes,
        _ => _categoryAxes,
      },
      animation: ChartAnimation.none,
      legend: legend,
      title: title,
    );

    Offset elementAt(WidgetTester tester, int index) {
      final element = _chart(tester).getDatasetMeta(0).data[index];
      return switch (element) {
        ArcElement(:final x, :final y, :final startAngle, :final endAngle) =>
          () {
            final angle = (startAngle + endAngle) / 2;
            final r = (element.innerRadius + element.outerRadius) / 2;
            return Offset(x + r * math.cos(angle), y + r * math.sin(angle));
          }(),
        _ => Offset(element.x, element.y + 1),
      };
    }

    for (final type in kinds) {
      group(type.name, () {
        /// One run of the steps, with the parameter and without it. [check]
        /// gets the layouts of a tick of new data.
        Future<List<Object>> run(
          WidgetTester tester,
          _Spy spy, {
          required bool dataOnly,
          ChartLegend? legend = const ChartLegend(display: false),
        }) async {
          final labels = _newLabels();
          ChartConfig at(int step, ChartTitle? title) => coloredConfig(
            type,
            step,
            labels,
            legend: legend,
            title: title,
          );
          Widget view(int step, {double width = 400, ChartTitle? title}) =>
              _box(
                ChartView(
                  config: at(step, title),
                  updateMode: 'none',
                  dataOnlyUpdates: dataOnly,
                ),
                width: width,
              );
          final seen = <Object>[];
          Future<void> record() async {
            final chart = _chart(tester);
            seen
              ..add(_observeDeep(chart))
              ..add(await _pixels(tester, chart));
          }

          Future<void> tick(
            int step, {
            double width = 400,
            ChartTitle? title,
          }) async {
            spy.clear();
            await tester.pumpWidget(view(step, width: width, title: title));
            expect(spy.layouts, dataOnly ? 0 : 1, reason: 'tick $step');
            expect(spy.modes, ['none'], reason: 'tick $step');
            expect(spy.draws, 1, reason: 'tick $step');
            await record();
          }

          await _warm(tester, view);
          await tick(2);
          await tick(3);

          // A later full update.
          const title = ChartTitle(display: true, text: 'new');
          spy.clear();
          await tester.pumpWidget(view(4, title: title));
          expect(spy.layouts, 1);
          await record();
          await tick(5, title: title);

          // A hidden item.
          _chart(tester).hide(0, 1);
          await record();
          await tick(6, title: title);
          _chart(tester).show(0, 1);
          await tick(7, title: title);

          // A hover with the mouse, then with the API.
          final mouse = await _mouse(tester);
          await mouse.moveTo(elementAt(tester, 2));
          await tester.pump();
          expect(_chart(tester).getActiveElements(), isNotEmpty);
          await tick(8, title: title);
          await tick(9, title: title);
          await mouse.moveTo(const Offset(399, 299));
          await tester.pump();
          await mouse.removePointer();
          await tester.pump();
          _chart(tester).setActiveElements([
            <String, Object?>{'datasetIndex': 0.0, 'index': 3.0},
          ]);
          await tick(10, title: title);
          _chart(tester).setActiveElements(const <Object?>[]);

          // A resize.
          await tester.pumpWidget(view(11, width: 240, title: title));
          await tester.pump();
          await tester.pump();
          expect(_chart(tester).width, 240);
          await record();
          await tick(12, width: 240, title: title);

          await tester.pumpWidget(const SizedBox());
          return seen;
        }

        testWidgets('matches a full update in the elements, the options, the '
            'contexts and the pixels', (tester) async {
          final spy = _spyOnChart();
          expect(
            await run(tester, spy, dataOnly: true),
            await run(tester, spy, dataOnly: false),
          );
        });

        testWidgets('matches a full update with a visible legend', (
          tester,
        ) async {
          final spy = _spyOnChart();
          const legend = ChartLegend(display: true);
          expect(
            await run(tester, spy, dataOnly: true, legend: legend),
            await run(tester, spy, dataOnly: false, legend: legend),
          );
        });

        testWidgets('a new ChartValue with equal colors stays on the path', (
          tester,
        ) async {
          final spy = _spyOnChart();
          final labels = _newLabels();
          ChartConfig at(int step) => coloredConfig(
            type,
            step,
            labels,
            dataset: colored(
              type,
              step,
              background: ChartValue.indexed(
                List<Color>.of(const [_red, _green]),
              ),
              border: ChartValue.indexed(
                List<Color>.of(const [_blue, _red, _green]),
              ),
            ),
          );
          await _warm(tester, (step) => _view(at(step)));
          spy.clear();
          await tester.pumpWidget(_view(at(2)));
          expect(spy.layouts, 0);
          final seen = _observeDeep(_chart(tester));
          final pixels = await _pixels(tester, _chart(tester));
          await tester.pumpWidget(const SizedBox());
          // The const value gives the same chart.
          await _warm(
            tester,
            (step) => _view(coloredConfig(type, step, labels)),
          );
          spy.clear();
          await tester.pumpWidget(_view(coloredConfig(type, 2, labels)));
          expect(spy.layouts, 0);
          expect(_observeDeep(_chart(tester)), seen);
          expect(await _pixels(tester, _chart(tester)), pixels);
        });

        testWidgets('a new List of other colors takes the full path, and the '
            'next tick the data-only path', (tester) async {
          final spy = _spyOnChart();
          final labels = _newLabels();
          ChartConfig at(int step, List<Color> colors) => coloredConfig(
            type,
            step,
            labels,
            dataset: colored(
              type,
              step,
              background: ChartValue.indexed(colors),
            ),
          );
          await _warm(tester, (step) => _view(at(step, [_red, _green])));
          spy.clear();
          await tester.pumpWidget(_view(at(2, [_red, _green])));
          expect(spy.layouts, 0);
          spy.clear();
          await tester.pumpWidget(_view(at(3, [_green, _blue])));
          expect(spy.layouts, 1);
          final element = _chart(tester).getDatasetMeta(0).data[1];
          expect(_option(element, 'backgroundColor'), _blue);
          spy.clear();
          await tester.pumpWidget(_view(at(4, [_green, _blue])));
          expect(spy.layouts, 0);
        });

        testWidgets('a color resolver takes the full path, with no change of '
            'its calls', (tester) async {
          final spy = _spyOnChart();
          final labels = _newLabels();
          var calls = 0;
          Color resolve(ChartContext _) {
            calls++;
            return _red;
          }

          ChartConfig at(int step) => coloredConfig(
            type,
            step,
            labels,
            dataset: colored(
              type,
              step,
              background: ChartValue.resolver(resolve),
            ),
          );
          await _warm(tester, (step) => _view(at(step)));
          spy.clear();
          calls = 0;
          await tester.pumpWidget(_view(at(2)));
          expect(spy.layouts, 1);
          expect(calls, greaterThan(0));
        });
      });
    }

    testWidgets('a function in the defaults of the element takes the full '
        'path', (tester) async {
      final spy = _spyOnChart();
      final labels = _newLabels();
      var calls = 0;
      jsSet(jsGet(jsGet(defaults, 'elements'), 'arc'), 'offset', (Object? _) {
        calls++;
        return 0.0;
      });
      await _warm(
        tester,
        (step) => _view(coloredConfig(ChartKind.pie, step, labels)),
      );
      spy.clear();
      calls = 0;
      await tester.pumpWidget(_view(coloredConfig(ChartKind.pie, 2, labels)));
      expect(spy.layouts, 1);
      expect(calls, greaterThan(0));
    });

    testWidgets('an overflow that grows runs a layout, with the result of a '
        'full update', (tester) async {
      final spy = _spyOnChart();
      final labels = _newLabels();
      ChartConfig at(int step, double radius) => coloredConfig(
        ChartKind.bubble,
        step,
        labels,
        dataset: colored(ChartKind.bubble, step, radius: radius),
      );
      Future<Object> run({required bool dataOnly}) async {
        await _warm(tester, (step) => _view(at(step, 4), dataOnly: dataOnly));
        spy.clear();
        await tester.pumpWidget(_view(at(2, 12), dataOnly: dataOnly));
        expect(spy.layouts, 1);
        final seen = [
          _observeDeep(_chart(tester)),
          await _pixels(tester, _chart(tester)),
        ];
        spy.clear();
        await tester.pumpWidget(_view(at(3, 12), dataOnly: dataOnly));
        expect(spy.layouts, dataOnly ? 0 : 1);
        seen
          ..add(_observeDeep(_chart(tester)))
          ..add(await _pixels(tester, _chart(tester)));
        await tester.pumpWidget(const SizedBox());
        return seen;
      }

      expect(await run(dataOnly: true), await run(dataOnly: false));
    });

    testWidgets('a theme stays, with the result of a full update', (
      tester,
    ) async {
      final spy = _spyOnChart();
      for (final type in kinds) {
        Future<Object> run({required bool dataOnly}) async {
          final labels = _newLabels();
          Widget view(int step) => _view(
            coloredConfig(type, step, labels),
            dataOnly: dataOnly,
            theme: const ChartThemeData.dark(),
          );
          await _warm(tester, view);
          spy.clear();
          await tester.pumpWidget(view(2));
          expect(spy.layouts, dataOnly ? 0 : 1, reason: type.name);
          final seen = [
            _observeDeep(_chart(tester)),
            await _pixels(tester, _chart(tester)),
          ];
          await tester.pumpWidget(const SizedBox());
          return seen;
        }

        expect(await run(dataOnly: true), await run(dataOnly: false));
      }
    });

    testWidgets('the indexed palette of the colors plugin stays on the path', (
      tester,
    ) async {
      final spy = _spyOnChart();
      for (final (type, make) in <(ChartKind, Dataset Function(List<double>))>[
        (ChartKind.pie, (values) => PieDataset(key: _a, data: values)),
        (
          ChartKind.doughnut,
          (values) => DoughnutDataset(key: _a, data: values),
        ),
        (
          ChartKind.polarArea,
          (values) => PolarAreaDataset(key: _a, data: values),
        ),
      ]) {
        Future<Object> run({required bool dataOnly}) async {
          final labels = _newLabels();
          Widget view(int step) => _view(
            coloredConfig(
              type,
              step,
              labels,
              dataset: make(_values(step)),
            ).copyWith(
              extra: const {
                'plugins': {
                  'colors': {'enabled': true},
                },
              },
            ),
            dataOnly: dataOnly,
          );
          await _warm(tester, view);
          spy.clear();
          await tester.pumpWidget(view(2));
          expect(spy.layouts, dataOnly ? 0 : 1, reason: type.name);
          final seen = [
            _observeDeep(_chart(tester)),
            await _pixels(tester, _chart(tester)),
          ];
          await tester.pumpWidget(const SizedBox());
          return seen;
        }

        expect(await run(dataOnly: true), await run(dataOnly: false));
      }
    });

    testWidgets('two ticks keep the layout, the ticks and the scale objects', (
      tester,
    ) async {
      final labels = _newLabels();
      await _warm(
        tester,
        (step) => _view(coloredConfig(ChartKind.bar, step, labels)),
      );
      final chart = _chart(tester);
      final area = chart.chartArea;
      final ticks = chart.scales['y']!.ticks;
      await tester.pumpWidget(_view(coloredConfig(ChartKind.bar, 2, labels)));
      await tester.pumpWidget(_view(coloredConfig(ChartKind.bar, 3, labels)));
      expect(chart.chartArea, same(area));
      expect(chart.scales['y']!.ticks, same(ticks));
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

  group('the legend', () {
    ChartConfig legendBars(
      int step,
      List<Object> labels,
      ChartPosition position,
    ) => _bars(
      step,
      labels,
      datasets: [
        BarDataset(
          key: _a,
          label: 'a',
          data: _values(step),
          backgroundColor: const ChartValue.constant(_blue),
          borderWidth: 0,
        ),
        BarDataset(
          key: _b,
          label: 'b',
          data: _values(step + 1),
          backgroundColor: const ChartValue.constant(_red),
          borderWidth: 0,
        ),
      ],
    ).copyWith(legend: ChartLegend(position: position));

    List<List<double>> hitBoxes(Chart chart) => [
      for (final box in chart.legend!.legendHitBoxes)
        [box.left, box.top, box.width, box.height],
    ];

    for (final position in const [
      ChartPosition.top,
      ChartPosition.bottom,
      ChartPosition.left,
      ChartPosition.right,
    ]) {
      testWidgets('the hit boxes of a legend at ${position.name} stay', (
        tester,
      ) async {
        final spy = _spyOnChart();
        Future<List<Object>> run({required bool dataOnly}) async {
          final labels = _newLabels();
          Widget view(int step) =>
              _view(legendBars(step, labels, position), dataOnly: dataOnly);
          await _warm(tester, view);
          final seen = <Object>[hitBoxes(_chart(tester))];
          for (var step = 2; step < 6; step++) {
            spy.clear();
            await tester.pumpWidget(view(step));
            expect(spy.layouts, dataOnly ? 0 : 1, reason: 'step $step');
            seen.add(hitBoxes(_chart(tester)));
          }
          seen.add(await _pixels(tester, _chart(tester)));

          // A full update makes new hit boxes from the kept state.
          await tester.pumpWidget(
            _view(
              legendBars(6, labels, position).copyWith(
                title: const ChartTitle(display: true, text: 'new'),
              ),
              dataOnly: dataOnly,
            ),
          );
          seen.add(hitBoxes(_chart(tester)));
          await tester.pumpWidget(const SizedBox());
          return seen;
        }

        expect(await run(dataOnly: true), await run(dataOnly: false));
      });
    }

    testWidgets('a mouse click on a legend item hides its data', (
      tester,
    ) async {
      Future<bool> run({required bool dataOnly}) async {
        final labels = _newLabels();
        Widget view(int step) => _view(
          legendBars(step, labels, ChartPosition.top),
          dataOnly: dataOnly,
        );
        await _warm(tester, view);
        final chart = _chart(tester);
        final box = chart.legend!.legendHitBoxes[0];
        final center =
            tester.getTopLeft(find.byType(ChartView)) +
            Offset(box.left + box.width / 2, box.top + box.height / 2);
        for (var step = 2; step < 6; step++) {
          await tester.pumpWidget(view(step));
        }
        await tester.tapAt(center, kind: PointerDeviceKind.mouse);
        await tester.pump(const Duration(milliseconds: 16));
        final visible = chart.isDatasetVisible(0);
        await tester.pumpWidget(const SizedBox());
        return visible;
      }

      expect(await run(dataOnly: true), isFalse);
      expect(await run(dataOnly: false), isFalse);
    });

    testWidgets('the keys of a legend item hide its data', (tester) async {
      Future<bool> run({required bool dataOnly}) async {
        final node = FocusNode(debugLabel: 'data-only');
        addTearDown(node.dispose);
        final labels = _newLabels();
        Widget view(int step) => _box(
          ChartView(
            config: legendBars(step, labels, ChartPosition.top),
            updateMode: 'none',
            dataOnlyUpdates: dataOnly,
            focusNode: node,
          ),
        );
        await _warm(tester, view);
        for (var step = 2; step < 6; step++) {
          await tester.pumpWidget(view(step));
        }
        node.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump(const Duration(milliseconds: 16));
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump(const Duration(milliseconds: 16));
        final visible = _chart(tester).isDatasetVisible(0);
        await tester.pumpWidget(const SizedBox());
        return visible;
      }

      expect(await run(dataOnly: true), isFalse);
      expect(await run(dataOnly: false), isFalse);
    });
  });

  group('a layout inside a data-only update', () {
    /// A bubble of the radius [radius] with colored grids, so that the order
    /// of the layers shows in the pixels.
    ChartConfig bubbles(
      int step,
      double radius, {
      Map<String, Object?>? xExtra,
      ChartLegend? legend,
    }) => ChartConfig(
      type: ChartKind.bubble,
      datasets: [
        BubbleDataset(
          points: <DataPoint>[DataPoint.bubble(40 + step, 50, radius)],
          backgroundColor: const ChartValue.constant(_blue),
          borderWidth: 0,
        ),
      ],
      scales: {
        'x': LinearAxis(
          min: 0,
          max: 100,
          grid: const AxisGrid(color: _red, lineWidth: 3),
          extra: xExtra,
        ),
        'y': const LinearAxis(
          min: 0,
          max: 100,
          grid: AxisGrid(color: _green, lineWidth: 3),
        ),
      },
      animation: ChartAnimation.none,
      legend: legend,
    );

    /// The pixels of each tick: a new radius runs a layout, and the same
    /// radius keeps the layout that it made.
    Future<void> expectPixels(
      WidgetTester tester, {
      Map<String, Object?>? xExtra,
      ChartLegend? legend,
    }) async {
      final spy = _spyOnChart();
      Future<List<Object>> run({required bool dataOnly}) async {
        Widget view(int step, double radius) => _view(
          bubbles(step, radius, xExtra: xExtra, legend: legend),
          dataOnly: dataOnly,
        );
        await _warm(tester, (step) => view(step, 4));
        final seen = <Object>[];
        for (final (step, radius, layouts) in const [
          (2, 40.0, 1),
          (3, 40.0, 0),
          (4, 80.0, 1),
          (5, 80.0, 0),
        ]) {
          spy.clear();
          await tester.pumpWidget(view(step, radius));
          expect(spy.layouts, dataOnly ? layouts : 1, reason: 'step $step');
          final chart = _chart(tester);
          final hitBoxes = chart.legend!.legendHitBoxes;
          seen
            ..add(_observe(chart))
            ..add(await _pixels(tester, chart))
            ..add([for (final box in hitBoxes) box.left])
            ..add([for (final box in hitBoxes) box.top]);
        }
        await tester.pumpWidget(const SizedBox());
        return seen;
      }

      expect(await run(dataOnly: true), await run(dataOnly: false));
    }

    testWidgets('draws the layers in the order of a full update', (
      tester,
    ) async {
      await expectPixels(tester);
    });

    testWidgets('draws a layer of z above 0 after the datasets, and the other '
        'layers before them', (tester) async {
      await expectPixels(
        tester,
        xExtra: const {
          'ticks': {'z': 1},
        },
      );
    });

    testWidgets('adjusts the hit boxes of its new fit once', (tester) async {
      await expectPixels(
        tester,
        legend: const ChartLegend(position: ChartPosition.left),
      );
    });
  });

  group('an update from a callback of the replay', () {
    testWidgets('runs and draws, as in a full update', (tester) async {
      final spy = _spyOnChart();
      Future<List<Object?>> run({required bool dataOnly}) async {
        final labels = _newLabels();
        var armed = false;
        var nested = 0;
        void onHover(ChartEventDetails details) {
          if (!armed) return;
          armed = false;
          nested++;
          details.chart.update('none');
        }

        Widget view(int step) => _view(
          _bars(step, labels).copyWith(onHover: onHover),
          dataOnly: dataOnly,
        );
        await _warm(tester, view);
        final chart = _chart(tester);
        final mouse = await _mouse(tester);
        final bar =
            chart.getDatasetMeta(0).data[1] as types.ElementPropertyRead;
        await mouse.moveTo(
          tester.getTopLeft(find.byType(ChartView)) +
              Offset(bar['x']! as double, chart.chartArea!.bottom - 2),
        );
        await tester.pump(const Duration(milliseconds: 100));

        armed = true;
        spy.clear();
        await tester.pumpWidget(view(2));
        expect(tester.takeException(), isNull);
        expect(nested, 1);
        // The data-only path has only the layout of the nested update.
        expect(spy.layouts, dataOnly ? 1 : 2);
        expect(spy.draws, 2, reason: 'the nested update and this tick');
        final seen = <Object?>[
          spy.draws,
          _observe(chart),
          chart.getActiveElements().map((e) => e.index).toList(),
          await _pixels(tester, chart),
        ];

        // The update made a new plan, so the path of the next tick is its own.
        spy.clear();
        await tester.pumpWidget(view(3));
        expect(spy.layouts, dataOnly ? 0 : 1);
        seen
          ..add(_observe(chart))
          ..add(await _pixels(tester, chart));
        await mouse.removePointer();
        await tester.pumpWidget(const SizedBox());
        return seen;
      }

      expect(await run(dataOnly: true), await run(dataOnly: false));
    });
  });

  group('a category axis', () {
    const dataBounds = <String, ChartAxis>{
      'x': CategoryAxis(extra: {'bounds': 'data'}),
      'y': LinearAxis(min: 0, max: 100),
    };

    testWidgets('with bounds data takes the range of the prepared data of a '
        'tick', (tester) async {
      final spy = _spyOnChart();
      Future<List<Object?>> run({required bool dataOnly}) async {
        final labels = _newLabels();
        ChartConfig line(int step) => ChartConfig(
          type: ChartKind.line,
          labels: labels,
          datasets: [
            LineDataset(
              points: <DataPoint>[
                DataPoint(step < 2 ? 0 : 3, 10 + step),
                DataPoint(step < 2 ? 1 : 4, 20),
              ],
            ),
          ],
          scales: dataBounds,
          animation: ChartAnimation.none,
          extra: const {'parsing': false},
        );
        Widget view(int step) => _view(line(step), dataOnly: dataOnly);
        await _warm(tester, view);
        spy.clear();
        await tester.pumpWidget(view(2));
        expect(spy.layouts, 1, reason: 'bounds data is not a fixed range');
        final chart = _chart(tester);
        final x = chart.scales['x']!;
        final seen = <Object?>[x.min, x.max, _observe(chart)];
        await tester.pumpWidget(const SizedBox());
        return seen;
      }

      final fast = await run(dataOnly: true);
      expect(fast.take(2), [3.0, 4.0]);
      expect(fast, await run(dataOnly: false));
    });

    testWidgets('with bounds data takes the range of the parsed data of a '
        'tick', (tester) async {
      final spy = _spyOnChart();
      Future<List<Object?>> run({required bool dataOnly}) async {
        final labels = _newLabels();
        ChartConfig line(int step) => _bars(
          step,
          labels,
          scales: dataBounds,
          datasets: [
            BarDataset(
              key: _a,
              data: List<double>.generate(
                _count,
                (i) => step >= 2 && i < 3 ? 500.0 : 50.0,
              ),
              backgroundColor: const ChartValue.constant(_blue),
              borderWidth: 0,
            ),
          ],
        );
        Widget view(int step) => _view(line(step), dataOnly: dataOnly);
        await _warm(tester, view);
        spy.clear();
        await tester.pumpWidget(view(2));
        expect(spy.layouts, 1, reason: 'bounds data is not a fixed range');
        final chart = _chart(tester);
        final x = chart.scales['x']!;
        final seen = <Object?>[x.min, x.max, _observe(chart)];
        await tester.pumpWidget(const SizedBox());
        return seen;
      }

      expect(await run(dataOnly: true), await run(dataOnly: false));
    });

    testWidgets('a label that a data point added leaves at the next tick', (
      tester,
    ) async {
      final spy = _spyOnChart();
      Future<List<Object?>> run({required bool dataOnly}) async {
        final labels = <Object>['a', 'b'];
        ChartConfig line(List<DataPoint> points) => ChartConfig(
          type: ChartKind.line,
          labels: labels,
          datasets: [LineDataset(points: points)],
          scales: _categoryAxes,
          animation: ChartAnimation.none,
        );
        List<DataPoint> numbers(double y) => <DataPoint>[
          DataPoint(0, y),
          DataPoint(1, 20),
        ];
        Widget view(List<DataPoint> points) =>
            _view(line(points), dataOnly: dataOnly);
        await _warm(tester, (step) => view(numbers(10.0 + step)));
        final seen = <Object?>[];
        await tester.pumpWidget(
          view(<DataPoint>[DataPoint.label('new', 10), DataPoint(1, 20)]),
        );
        seen.add(List<Object>.of(labels));

        spy.clear();
        await tester.pumpWidget(view(numbers(30)));
        expect(spy.layouts, 1, reason: 'the added label needs a full update');
        final chart = _chart(tester);
        seen
          ..add(List<Object>.of(labels))
          ..add(chart.scales['x']!.max)
          ..add(_observe(chart))
          ..add(await _pixels(tester, chart));

        spy.clear();
        await tester.pumpWidget(view(numbers(40)));
        expect(spy.layouts, dataOnly ? 0 : 1, reason: 'the label is gone');
        seen.add(_observe(chart));
        await tester.pumpWidget(const SizedBox());
        return seen;
      }

      final fast = await run(dataOnly: true);
      expect(fast[1], ['a', 'b']);
      expect(fast, await run(dataOnly: false));
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
