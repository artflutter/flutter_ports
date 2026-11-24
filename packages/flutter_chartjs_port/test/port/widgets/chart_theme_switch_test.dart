// Original code, not ported from Chart.js: tests of the theme switch.
@TestOn('vm')
library;

import 'dart:ui' as native_ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/data_scope.dart';

// theming.md §8 test 8: the runtime theme switch of ChartView (Chart.js ADR
// 0147 §13). The widget switches in its post-frame update
// callback (Chart.js ADR 0049, section 4): it writes the compiled theme
// under `$theme` of its root config (step 2), puts the recorded user
// `scales` object back into the options (step 3), restores the palette keys
// that the colors plugin wrote (step 4) and calls `chart.update` with the
// theme mode (step 5).
//
// flutter_test_config.dart registers the built-in components with the seven
// plugins and sets `defaults.plugins.colors.enabled = false`, as
// test/index.js:25-28 does. The charts of the palette cases set
// `plugins.colors.enabled: true`. The forms F0, F1 and F3 of the probe F-P4
// run on charts of `acquireChart` with a hand switch: they pin why the
// widget takes form F2.

const Color _red = Color(0xFFFF0000);
const Color _green = Color(0xFF008000);
const Color _blue = Color(0xFF0000FF);
const Color _yellow = Color(0xFFFFFF00);
const Color _cyan = Color(0xFF00FFFF);
const Color _magenta = Color(0xFFFF00FF);

/// The theme A of the probe F-P4: red text and lines, a green palette.
const ChartThemeData _themeA = ChartThemeData(
  color: _red,
  borderColor: _red,
  palette: [_green],
);

/// The theme B of the probe F-P4: blue text, lines and palette.
const ChartThemeData _themeB = ChartThemeData(
  color: _blue,
  borderColor: _blue,
  palette: [_blue],
);

/// A theme of three palette colors.
const ChartThemeData _palette3A = ChartThemeData(
  palette: [_red, _green, _blue],
);

/// Another theme of three palette colors.
const ChartThemeData _palette3B = ChartThemeData(
  palette: [_yellow, _cyan, _magenta],
);

/// The `rgba()` string of a palette color at the alpha [alpha].
Color _rgba(Color c, [double alpha = 1]) => c.withValues(alpha: alpha);

String _rgbaText(Color c, [double alpha = 1]) {
  final a = alpha == 1 ? '1' : '$alpha';
  int channel(double v) => (v * 255).round();
  return 'rgba(${channel(c.r)}, ${channel(c.g)}, ${channel(c.b)}, $a)';
}

/// [child] at the top left of a box of 400 x 300.
Widget _box(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: 400, height: 300, child: child),
  ),
);

/// The dataset [i] of [_typedConfig]: `d<i>` with the data `[1 + i, 3, 2]`
/// and the border color [borderColor].
BarDataset _bar(int i, {ChartPaint? borderColor}) => BarDataset(
  label: 'd$i',
  data: .values([1 + i, 3, 2]),
  borderColor: borderColor == null ? null : .constant(borderColor),
);

/// A bar chart config: labels `a` to `c`, [datasets] datasets (or the
/// datasets of [_bar]), the colors plugin on ([colors]), `animation: false`
/// unless [animated].
ChartConfig _typedConfig({
  bool animated = false,
  List<Plugin<Object?>>? plugins,
  List<Dataset>? datasets,
  ColorsPluginOptions colors = const ColorsPluginOptions(enabled: true),
}) => ChartConfig(
  labels: const ['a', 'b', 'c'],
  datasets: datasets ?? [_bar(0), _bar(1)],
  animation: animated ? const ChartAnimation() : ChartAnimation.none,
  plugins: plugins,
  pluginOptions: [colors],
);

/// A ChartView of [config] with [theme] and [updateMode] in [_box].
Widget _typedView(
  ChartConfig config, {
  ChartThemeData? theme,
  UpdateMode? updateMode,
  Key? key,
}) => _box(
  ChartView(config: config, theme: theme, updateMode: updateMode, key: key),
);

JsObjectFace _typedDataset(Chart chart, int index) =>
    _datasets(chart)[index]! as JsObjectFace;

/// The chart of the one ChartView of the tree.
Chart _chart(WidgetTester tester) {
  final host = tester.renderObject<RenderChartHost>(find.byType(ChartHost));
  return Chart.getChart(host.canvas)!;
}

/// The datasets of [chart].
List<Object?> _datasets(Chart chart) =>
    jsGet(chart.data, 'datasets')! as List<Object?>;

/// The resolved option [key] of the element [index] of the dataset
/// [datasetIndex].
Object? _elementOption(
  Chart chart,
  String key, {
  int datasetIndex = 0,
  int index = 0,
}) {
  final element = chart.getDatasetMeta(datasetIndex).data[index];
  return jsGet(element.options, key);
}

/// The options of the scale [id].
CoreScaleOptions _scaleOptions(Chart chart, String id) =>
    chart.scales[id]!.options;

/// The options of the radial scale [id].
RadialLinearScaleOptions _radialOptions(Chart chart, String id) =>
    _scaleOptions(chart, id) as RadialLinearScaleOptions;

/// A registered plugin whose `beforeUpdate` records the mode of each
/// update of each chart (the spy of `global.defaults_test.dart`). It
/// unregisters at the end of the test.
List<Object?> _spyOnUpdates() {
  final calls = <Object?>[];
  final plugin = Plugin<Object?>(
    id: r'$updateSpy',
    beforeUpdate: (chart, args, options) {
      calls.add(args.mode);
      return true;
    },
  );
  Chart.register([plugin]);
  addTearDown(() => Chart.unregister([plugin]));
  return calls;
}

/// The config of the probe F-P4: a line chart with two datasets, the colors
/// plugin on, the title `user` and an `x` scale with a title.
// A Map config: the forms F0, F1 and F3 copy and edit its `options` Map.
AnyObject _formConfig() => <String, Object?>{
  'type': 'line',
  'data': <String, Object?>{
    'labels': <Object?>['a', 'b', 'c'],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'd0',
        'data': <Object?>[1, 2, 3],
      },
      <String, Object?>{
        'label': 'd1',
        'data': <Object?>[3, 2, 1],
      },
    ],
  },
  'options': <String, Object?>{
    'animation': false,
    'plugins': <String, Object?>{
      'colors': const ColorsPluginOptions(enabled: true),
      'title': const TitleOptions(display: true, text: ['user']),
    },
    'scales': <String, Object?>{
      'x': <String, Object?>{
        'title': <String, Object?>{
          'display': true,
          'text': ['x'],
        },
      },
    },
  },
};

/// The typed config of the probe F-P4 for the widget (form F2): the chart
/// of [_formConfig].
const ChartConfig _typedFormConfig = ChartConfig(
  labels: ['a', 'b', 'c'],
  datasets: [
    LineDataset(label: 'd0', data: .values([1, 2, 3])),
    LineDataset(label: 'd1', data: .values([3, 2, 1])),
  ],
  scales: [
    CategoryAxis(.x, title: AxisTitle(display: true, text: ['x'])),
  ],
  animation: ChartAnimation.none,
  pluginOptions: [
    ColorsPluginOptions(enabled: true),
    TitleOptions(display: true, text: ['user']),
  ],
);

/// The state of the probe F-P4: the `x` tick color, `x.min`, the border
/// color of the dataset 0, the visibility of the dataset 1 and the title.
String _formState(Chart chart) {
  final x = _scaleOptions(chart, 'x');
  // The title options are one object (Chart.js ADR 0197).
  final title =
      jsGet(jsGet(chart.options, 'plugins'), 'title')! as TitleOptions;
  final tickColor = (x.ticks.color as SolidChartPaint).color;
  final borderColor =
      (jsGet(_datasets(chart)[0], 'borderColor')! as SolidChartPaint).color;
  return 'x.ticks.color=${_rgbaText(tickColor)} '
      'x.min=${x.min} '
      'ds0.borderColor=${_rgbaText(borderColor)} '
      'visible1=${chart.isDatasetVisible(1)} '
      'title.text=${title.text!.join()}';
}

const String _formCreated =
    'x.ticks.color=rgba(255, 0, 0, 1) x.min=undefined '
    'ds0.borderColor=rgba(0, 128, 0, 1) visible1=true title.text=user';
const String _formEdited =
    'x.ticks.color=rgba(255, 0, 0, 1) x.min=b '
    'ds0.borderColor=rgba(0, 128, 0, 1) visible1=false title.text=edited';

/// The edits of the probe F-P4: the app hides the dataset 1, and it edits
/// the title text and `x.min` of [options] (a Map or the face of a typed
/// scope) imperatively.
void _formEdits(Chart chart, Object options) {
  chart.hide(1);
  // The title options are one immutable object (Chart.js ADR 0197): the edit
  // writes a new object.
  final plugins = jsGet(options, 'plugins');
  jsSet(
    plugins,
    'title',
    (jsGet(plugins, 'title')! as TitleOptions).merge(
      const TitleOptions(text: ['edited']),
    ),
  );
  // After `initOptions`, `scales` is the typed scale scope of the chart
  // (Chart.js ADR 0054 §5): the edit goes through its face.
  jsSet(jsGet(jsGet(options, 'scales'), 'x'), 'min', 'b');
  chart.update();
}

/// A deep copy of Maps and Lists; other values stay.
Object? _copy(Object? v) => switch (v) {
  final Map<String, Object?> m => <String, Object?>{
    for (final e in m.entries) e.key: _copy(e.value),
  },
  final List<String> l => List<String>.of(l),
  final List<Object?> l => [for (final i in l) _copy(i)],
  _ => v,
};

/// A deep copy of the typed objects (the faces, Chart.js ADR 0054 §5), the
/// Maps and the Lists of [v] as plain Maps and Lists; other values stay.
Object? _plain(Object? v) => switch (v) {
  final JsObjectFace f => <String, Object?>{
    for (final key in f.jsKeys()) key: _plain(f[key]),
  },
  final Map<String, Object?> m => <String, Object?>{
    for (final e in m.entries) e.key: _plain(e.value),
  },
  final List<Object?> l => [for (final i in l) _plain(i)],
  _ => v,
};

/// The palette restore of the probe F-P4: the two palette keys of each
/// dataset back to [snapshot] (absent keys removed).
void _restorePalette(Chart chart, List<AnyObject> snapshot) {
  final datasets = _datasets(chart);
  for (var i = 0; i < datasets.length && i < snapshot.length; i++) {
    final dataset = datasets[i]! as AnyObject;
    for (final key in ['borderColor', 'backgroundColor']) {
      if (snapshot[i].containsKey(key)) {
        dataset[key] = snapshot[i][key];
      } else {
        dataset.remove(key);
      }
    }
  }
}

/// The 5000 input points `(i, f(i))` of `decimation_theme_test.dart`: the
/// data items of `parsing: false`.
List<DataPoint> _decimationInput() => [
  for (var i = 0; i < 5000; i++) DataPoint(i, (i * 37) % 101 + (i ~/ 250)),
];

/// A host whose state sets the config and the theme of its ChartView in one
/// `setState`.
class const _Host({
  required final ChartConfig config,
  final ChartThemeData? theme,
}) extends StatefulWidget {
  @override
  State<_Host> createState() => _HostState();
}

class _HostState() extends State<_Host> {
  late ChartConfig config = widget.config;
  late ChartThemeData? theme = widget.theme;
  UpdateMode? updateMode;

  void show(
    ChartConfig nextConfig,
    ChartThemeData? nextTheme, {
    UpdateMode? mode,
  }) => setState(() {
    config = nextConfig;
    theme = nextTheme;
    updateMode = mode;
  });

  @override
  Widget build(BuildContext context) =>
      _typedView(config, theme: theme, updateMode: updateMode);
}

void main() {
  group('the forms of the probe F-P4', () {
    testWidgets('F0, no reset: the old theme stays in the scales and the '
        'datasets', (tester) async {
      final config = _formConfig();
      final options = config['options']! as AnyObject;
      config[themeConfigKey] = compileThemeData(_themeA);
      final chart = acquireChart(config);
      await tester.pump();
      expect(_formState(chart), _formCreated);
      _formEdits(chart, options);
      config[themeConfigKey] = compileThemeData(_themeB);
      chart.update(const UpdateMode('theme'));
      await tester.pump();
      expect(_formState(chart), _formEdited);
    });

    testWidgets('F1, a copy of the options that the chart changed: the old '
        'ticks stay, and the options lose their identity', (tester) async {
      final config = _formConfig();
      final options = config['options']! as AnyObject;
      // The palette keys of the datasets before the chart: none.
      final palette = [<String, Object?>{}, <String, Object?>{}];
      config[themeConfigKey] = compileThemeData(_themeA);
      final chart = acquireChart(config);
      await tester.pump();
      _formEdits(chart, options);
      config[themeConfigKey] = compileThemeData(_themeB);
      chart.options = _copy(config['options']);
      _restorePalette(chart, palette);
      chart.update(const UpdateMode('theme'));
      await tester.pump();
      expect(
        _formState(chart),
        'x.ticks.color=rgba(255, 0, 0, 1) x.min=b '
        'ds0.borderColor=rgba(0, 0, 255, 1) visible1=false '
        'title.text=edited',
      );
      expect(chart.config.options, isNot(same(options)));
    });

    testWidgets('F2, the widget: the new ticks, the title edit stays, the '
        'options keep their identity, and the edit of x.min goes', (
      tester,
    ) async {
      await tester.pumpWidget(_typedView(_typedFormConfig, theme: _themeA));
      final chart = _chart(tester);
      // The options of the app: the live typed scope of the lowering.
      final options = chart.config.options;
      expect(_formState(chart), _formCreated);
      _formEdits(chart, options);
      expect(_formState(chart), _formEdited);
      await tester.pumpWidget(_typedView(_typedFormConfig, theme: _themeB));
      expect(
        _formState(chart),
        'x.ticks.color=rgba(0, 0, 255, 1) x.min=undefined '
        'ds0.borderColor=rgba(0, 0, 255, 1) visible1=false '
        'title.text=edited',
      );
      expect(chart.config.options, same(options));
      expect(_chart(tester), same(chart));
    });

    testWidgets('F3, a pristine copy of the options: the title edit and the '
        'identity go', (tester) async {
      final config = _formConfig();
      final options = config['options']! as AnyObject;
      final pristine = _copy(options);
      config[themeConfigKey] = compileThemeData(_themeA);
      final chart = acquireChart(config);
      await tester.pump();
      _formEdits(chart, options);
      config[themeConfigKey] = compileThemeData(_themeB);
      chart.options = _copy(pristine);
      _restorePalette(chart, [<String, Object?>{}, <String, Object?>{}]);
      chart.update(const UpdateMode('theme'));
      await tester.pump();
      expect(
        _formState(chart),
        'x.ticks.color=rgba(0, 0, 255, 1) x.min=undefined '
        'ds0.borderColor=rgba(0, 0, 255, 1) visible1=false title.text=user',
      );
      expect(chart.config.options, isNot(same(options)));
    });
  });

  group('a switch', () {
    for (final (type, scale) in const [
      ('bar', 'y'),
      ('line', 'y'),
      ('radar', 'r'),
    ]) {
      testWidgets('$type: the element colors, the scale colors and the '
          'palette', (tester) async {
        final config = ChartConfig(
          labels: const ['a', 'b', 'c'],
          datasets: [
            for (var i = 0; i < 2; i++)
              switch (type) {
                'bar' => BarDataset(label: 'd$i', data: .values([1 + i, 3, 2])),
                'line' => LineDataset(
                  label: 'd$i',
                  data: .values([1 + i, 3, 2]),
                ),
                _ => RadarDataset(label: 'd$i', data: [1 + i, 3, 2]),
              },
          ],
          animation: ChartAnimation.none,
          pluginOptions: const [ColorsPluginOptions(enabled: true)],
        );
        await tester.pumpWidget(
          _box(ChartView(config: config, theme: _themeA)),
        );
        final chart = _chart(tester);
        for (final (theme, line, palette) in [
          (_themeA, _rgba(_red), _green),
          (_themeB, _rgba(_blue), _blue),
        ]) {
          await tester.pumpWidget(
            _box(ChartView(config: config, theme: theme)),
          );
          final reason = '$type, $theme';
          expect(
            jsGet(_datasets(chart)[0], 'borderColor'),
            ChartPaint.solid(_rgba(palette)),
            reason: reason,
          );
          expect(
            _elementOption(chart, 'borderColor'),
            ChartPaint.solid(_rgba(palette)),
            reason: reason,
          );
          expect(
            _elementOption(chart, 'backgroundColor'),
            ChartPaint.solid(_rgba(palette, 0.5)),
            reason: reason,
          );
          expect(
            _scaleOptions(chart, scale).grid.color,
            ChartPaint.solid(line),
            reason: reason,
          );
          expect(
            _scaleOptions(chart, scale).ticks.color,
            ChartPaint.solid(line),
            reason: reason,
          );
          if (type == 'radar') {
            expect(
              _radialOptions(chart, scale).pointLabels.color,
              ChartPaint.solid(line),
              reason: reason,
            );
            expect(
              _radialOptions(chart, scale).angleLines.color,
              ChartPaint.solid(line),
              reason: reason,
            );
          }
        }
        expect(_chart(tester), same(chart));
      });
    }

    testWidgets('keeps a hidden dataset hidden and keeps the controllers, '
        'the data arrays and the dataset objects', (tester) async {
      final config = _typedConfig();
      await tester.pumpWidget(_typedView(config, theme: _themeA));
      final chart = _chart(tester)..hide(1);
      final datasets = [..._datasets(chart)];
      final data = [for (final d in datasets) jsGet(d, 'data')];
      final controllers = [
        for (var i = 0; i < 2; i++) chart.getDatasetMeta(i).controller,
      ];
      expect(chart.isDatasetVisible(1), isFalse);
      await tester.pumpWidget(_typedView(config, theme: _themeB));
      expect(chart.isDatasetVisible(1), isFalse);
      expect(chart.isDatasetVisible(0), isTrue);
      for (var i = 0; i < 2; i++) {
        expect(_datasets(chart)[i], same(datasets[i]));
        expect(jsGet(datasets[i], 'data'), same(data[i]));
        expect(chart.getDatasetMeta(i).controller, same(controllers[i]));
      }
      expect(
        _typedDataset(chart, 0)['borderColor'],
        ChartPaint.solid(_rgba(_blue)),
      );
    });

    for (final (name, decimation) in const [
      (
        'min-max',
        DecimationOptions(
          enabled: true,
          algorithm: MinMaxDecimationAlgorithm(),
        ),
      ),
      (
        'lttb',
        DecimationOptions(
          enabled: true,
          algorithm: LttbDecimationAlgorithm(),
          samples: 50,
        ),
      ),
    ]) {
      testWidgets('keeps the decimated data ($name)', (tester) async {
        final input = _decimationInput();
        final config = ChartConfig(
          datasets: [
            LineDataset(
              label: 'd',
              pointRadius: const .constant(0),
              data: .points(input),
            ),
          ],
          animation: ChartAnimation.none,
          scales: const [LinearAxis(.x)],
          parsing: false,
          pluginOptions: [const ColorsPluginOptions(enabled: true), decimation],
        );
        List<(Object?, Object?)> items(Chart chart) => [
          for (final item in jsGet(_typedDataset(chart, 0), 'data')! as List)
            (jsGet(item, 'x'), jsGet(item, 'y')),
        ];
        await tester.pumpWidget(_typedView(config, theme: _themeA));
        final chart = _chart(tester);
        final before = items(chart);
        expect(before.length, lessThan(5000));
        expect(before.length, greaterThan(0));
        await tester.pumpWidget(_typedView(config, theme: _themeB));
        expect(items(chart), before);
        expect(jsGet(_typedDataset(chart, 0), '_data'), same(input));
        expect(chart.getDatasetMeta(0).data, hasLength(before.length));
        expect(
          _typedDataset(chart, 0)['borderColor'],
          ChartPaint.solid(_rgba(_blue)),
        );
      });
    }

    testWidgets('a removal gives the upstream colors with the mode default', (
      tester,
    ) async {
      final modes = _spyOnUpdates();
      final config = _typedConfig();
      await tester.pumpWidget(_typedView(config, theme: _themeA));
      final chart = _chart(tester);
      expect(modes, [null]);
      await tester.pumpWidget(_typedView(config));
      expect(modes, [null, 'default']);
      expect(chartThemeOf(chart.config), isNull);
      // The first color of BORDER_COLORS (plugin.colors.ts:14-22).
      expect(
        _typedDataset(chart, 0)['borderColor'],
        const ChartPaint.solid(native_ui.Color.fromRGBO(54, 162, 235, 1)),
      );
      expect(
        _elementOption(chart, 'borderColor'),
        const ChartPaint.solid(native_ui.Color.fromRGBO(54, 162, 235, 1)),
      );
      expect(
        _scaleOptions(chart, 'y').ticks.color,
        const ChartPaint.solid(native_ui.Color.fromRGBO(102, 102, 102, 1)),
      );
      expect(
        _scaleOptions(chart, 'y').grid.color,
        const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 0, 0.1)),
      );
    });

    testWidgets("'theme' animates the element colors for 200 ms, linear", (
      tester,
    ) async {
      final modes = _spyOnUpdates();
      final config = _typedConfig(animated: true);
      await tester.pumpWidget(_typedView(config, theme: _themeA));
      final chart = _chart(tester);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(animator.running(chart), isFalse);
      final from = _elementOption(chart, 'backgroundColor');
      expect(from, ChartPaint.solid(_rgba(_green, 0.5)));

      await tester.pumpWidget(_typedView(config, theme: _themeB));
      expect(modes.last, 'theme');
      final to = _rgba(_blue, 0.5);
      // The colors interpolator of core.animation.js:15-21 at 0.5.
      final half = (color(to) as Color).mix(color(from) as Color, 0.5);
      await tester.pump(const Duration(milliseconds: 100));
      expect(_elementOption(chart, 'backgroundColor'), ChartPaint.solid(half));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(_elementOption(chart, 'backgroundColor'), ChartPaint.solid(to));
      expect(animator.running(chart), isFalse);
    });

    testWidgets('an equal theme and an empty theme against none give no '
        'update', (tester) async {
      final modes = _spyOnUpdates();
      final config = _typedConfig();
      await tester.pumpWidget(_typedView(config, theme: _themeA));
      expect(modes, [null]);
      // A new instance with equal tokens.
      final equal = ChartThemeData(
        color: _red,
        borderColor: _red,
        palette: List.of(const [_green]),
      );
      expect(equal, isNot(same(_themeA)));
      expect(equal, _themeA);
      await tester.pumpWidget(_typedView(config, theme: equal));
      await tester.pump();
      expect(modes, [null]);

      // A new chart without a theme, then the empty theme.
      final other = _typedConfig();
      await tester.pumpWidget(_typedView(other, key: const ValueKey('none')));
      expect(modes, [null, null]);
      await tester.pumpWidget(
        _typedView(
          other,
          theme: const ChartThemeData(),
          key: const ValueKey('none'),
        ),
      );
      await tester.pump();
      expect(modes, [null, null]);
      expect(chartThemeOf(_chart(tester).config), isNull);
    });

    testWidgets('a dataset that the app adds after the first colorize gets '
        'the next palette color after a switch', (tester) async {
      await tester.pumpWidget(_typedView(_typedConfig(), theme: _palette3A));
      final chart = _chart(tester);
      expect(
        _typedDataset(chart, 1)['borderColor'],
        ChartPaint.solid(_rgba(_green)),
      );
      final three = _typedConfig(datasets: [_bar(0), _bar(1), _bar(2)]);
      await tester.pumpWidget(_typedView(three, theme: _palette3A));
      await tester.pumpWidget(_typedView(three, theme: _palette3B));
      expect(_chart(tester), same(chart));
      expect(
        _typedDataset(chart, 0)['borderColor'],
        ChartPaint.solid(_rgba(_yellow)),
      );
      expect(
        _typedDataset(chart, 1)['borderColor'],
        ChartPaint.solid(_rgba(_cyan)),
      );
      expect(
        _typedDataset(chart, 2)['borderColor'],
        ChartPaint.solid(_rgba(_magenta)),
      );
      expect(
        _typedDataset(chart, 2)['backgroundColor'],
        ChartPaint.solid(_rgba(_magenta, 0.5)),
      );
    });

    testWidgets('an app color of a dataset stays, and the other datasets '
        'then get no palette color, as a new chart', (tester) async {
      const own = ChartPaint.solid(native_ui.Color.fromRGBO(1, 2, 3, 1));
      final edited = _typedConfig(
        datasets: [
          _bar(0, borderColor: own),
          _bar(1),
        ],
      );
      await tester.pumpWidget(_typedView(_typedConfig(), theme: _palette3A));
      final chart = _chart(tester);
      await tester.pumpWidget(_typedView(edited, theme: _palette3A));
      await tester.pumpWidget(_typedView(edited, theme: _palette3B));
      expect(_chart(tester), same(chart));
      expect(_typedDataset(chart, 0)['borderColor'], own);
      expect(_typedDataset(chart, 0).jsHas('backgroundColor'), isFalse);
      expect(_typedDataset(chart, 1).jsHas('borderColor'), isFalse);
      expect(_typedDataset(chart, 1).jsHas('backgroundColor'), isFalse);
      final switched = [
        for (final key in ['borderColor', 'backgroundColor'])
          for (var i = 0; i < 2; i++)
            _elementOption(chart, key, datasetIndex: i),
      ];

      // A new chart of the theme B with that dataset color.
      await tester.pumpWidget(
        _typedView(edited, theme: _palette3B, key: const ValueKey('fresh')),
      );
      final created = _chart(tester);
      expect(created, isNot(same(chart)));
      expect(_typedDataset(created, 1).jsHas('borderColor'), isFalse);
      expect([
        for (final key in ['borderColor', 'backgroundColor'])
          for (var i = 0; i < 2; i++)
            _elementOption(created, key, datasetIndex: i),
      ], switched);
    });

    testWidgets('forceOverride: the palette keys go back to the values '
        'before the first write', (tester) async {
      const own = ChartPaint.solid(native_ui.Color.fromRGBO(9, 9, 9, 1));
      ChartConfig config({required bool enabled}) => _typedConfig(
        datasets: [
          _bar(0),
          _bar(1, borderColor: own),
        ],
        colors: ColorsPluginOptions(enabled: enabled, forceOverride: true),
      );
      final on = config(enabled: true);
      await tester.pumpWidget(_typedView(on, theme: _palette3A));
      final chart = _chart(tester);
      // forceOverride writes over the dataset color in each update.
      expect(
        _typedDataset(chart, 1)['borderColor'],
        ChartPaint.solid(_rgba(_green)),
      );
      chart
        ..update()
        ..update();
      expect(
        _typedDataset(chart, 1)['borderColor'],
        ChartPaint.solid(_rgba(_green)),
      );
      await tester.pumpWidget(_typedView(on, theme: _palette3B));
      expect(
        _typedDataset(chart, 1)['borderColor'],
        ChartPaint.solid(_rgba(_cyan)),
      );
      // A removal restores the value of the app before the first write, and
      // the colors plugin writes the upstream palette over it.
      await tester.pumpWidget(_typedView(on));
      expect(
        _typedDataset(chart, 1)['borderColor'],
        const ChartPaint.solid(native_ui.Color.fromRGBO(255, 99, 132, 1)),
      );
      // With the plugin off, a switch shows the restored values: the value
      // of the app, and no key where the app had none.
      await tester.pumpWidget(
        _typedView(config(enabled: false), theme: _palette3A),
      );
      expect(_typedDataset(chart, 1)['borderColor'], own);
      expect(_typedDataset(chart, 1).jsHas('backgroundColor'), isFalse);
      expect(_typedDataset(chart, 0).jsHas('borderColor'), isFalse);
    });

    testWidgets('a theme change and a config change in one frame give one '
        'update with the theme mode', (tester) async {
      final modes = _spyOnUpdates();
      final config = _typedConfig();
      await tester.pumpWidget(_Host(config: config, theme: _themeA));
      final host = tester.state<_HostState>(find.byType(_Host));
      final chart = _chart(tester);
      expect(modes, [null]);
      final data = <num?>[4, 5, 6];
      final next = _typedConfig(datasets: [BarDataset(data: .values(data))]);
      host.show(next, _themeB, mode: UpdateMode.none);
      await tester.pump();
      expect(modes, [null, 'theme']);
      expect(_typedDataset(chart, 0)['data'], same(data));
      expect(
        _typedDataset(chart, 0)['borderColor'],
        ChartPaint.solid(_rgba(_blue)),
      );
      // A config change alone takes updateMode.
      host.show(
        _typedConfig(
          datasets: [
            const BarDataset(data: .values([7, 8, 9])),
          ],
        ),
        _themeB,
        mode: UpdateMode.none,
      );
      await tester.pump();
      expect(modes, [null, 'theme', 'none']);
    });

    testWidgets('the inherited theme: ChartTheme above, ChartView.theme '
        'beats it, and the empty theme turns theming off', (tester) async {
      final config = _typedConfig();
      Widget build(ChartThemeData data, {ChartThemeData? own}) => ChartTheme(
        data: data,
        child: _typedView(config, theme: own),
      );
      await tester.pumpWidget(build(_themeA));
      final chart = _chart(tester);
      expect(
        _scaleOptions(chart, 'y').ticks.color,
        ChartPaint.solid(_rgba(_red)),
      );
      await tester.pumpWidget(build(_themeB));
      expect(
        _scaleOptions(chart, 'y').ticks.color,
        ChartPaint.solid(_rgba(_blue)),
      );
      await tester.pumpWidget(build(_themeB, own: _themeA));
      expect(
        _scaleOptions(chart, 'y').ticks.color,
        ChartPaint.solid(_rgba(_red)),
      );
      await tester.pumpWidget(build(_themeB, own: const ChartThemeData()));
      expect(
        _scaleOptions(chart, 'y').ticks.color,
        const ChartPaint.solid(native_ui.Color.fromRGBO(102, 102, 102, 1)),
      );
      expect(chartThemeOf(chart.config), isNull);
      expect(_chart(tester), same(chart));
    });
  });

  group('the widget', () {
    testWidgets(r'the plugin $chartView comes last, after the inline plugins '
        'of the app', (tester) async {
      final app = Plugin<Object?>(id: 'app');
      await tester.pumpWidget(
        _typedView(_typedConfig(plugins: [app]), theme: _themeA),
      );
      final plugins = _chart(tester).config.plugins! as List;
      expect(plugins, hasLength(2));
      expect(plugins.first, same(app));
      expect((plugins.last as Plugin<Object?>).id, chartViewPluginId);
      expect(chartViewPluginId, r'$chartView');
    });

    testWidgets('the diagnostics name the theme', (tester) async {
      final properties = [
        for (final property in const ChartView(
          config: ChartConfig(datasets: [BarDataset()]),
          theme: ChartThemeData.dark(),
        ).toDiagnosticsNode().getProperties())
          if (!property.isFiltered(DiagnosticLevel.info)) property.name,
      ];
      expect(properties, ['type', 'datasets', 'theme']);
    });
  });

  group('reduced motion', () {
    test("ChartThemeSwitch gives 'themeFrame' for a new theme and 'default' "
        'for a removal', () {
      final switcher = ChartThemeSwitch();
      // The root of a ChartView is a typed root scope (Chart.js ADR 0054
      // §7) with the Maps of the app.
      final data = <String, Object?>{'datasets': <Object?>[]};
      final root = ChartConfigurationScope()
        ..jsWrite('options', <String, Object?>{})
        ..jsWrite('data', data);
      switcher.start(root, null);
      final chart = _FakeChart(dataScopeOf(data));
      expect(
        switcher.apply(chart, root, _themeA, reducedMotion: true),
        'themeFrame',
      );
      // No memo (Chart.js ADR 0054 §4): the switch compiles each new theme
      // once and keeps it.
      final compiledA = root.dollarThemeCell?.raw;
      expect(_plain(compiledA), _plain(compileThemeData(_themeA)));
      expect(compiledA, isNot(same(compileThemeData(_themeA))));
      expect(
        switcher.apply(chart, root, _themeB, reducedMotion: false),
        'theme',
      );
      expect(switcher.apply(chart, root, null, reducedMotion: true), 'default');
      expect(root.dollarThemeCell, isNull);
      expect(
        switcher.apply(
          chart,
          root,
          const ChartThemeData(),
          reducedMotion: true,
        ),
        isNull,
      );
      expect(switcher.applied, const ChartThemeData());
    });

    testWidgets("an update(const UpdateMode('themeFrame')) ends in one frame", (
      tester,
    ) async {
      final config = lowerForTest(_typedConfig(animated: true));
      config[themeConfigKey] = compileThemeData(_themeA);
      final chart = acquireChartRoot(config);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(animator.running(chart), isFalse);
      // Steps 2 and 3 of the switch: the config had no user scales.
      config[themeConfigKey] = compileThemeData(_themeB);
      (config.optionsCell!.raw! as ChartOptionsScope).jsDelete('scales');
      chart.update(const UpdateMode('themeFrame'));
      expect(animator.has(chart), isFalse);
      await tester.pump();
      expect(animator.running(chart), isFalse);
      expect(
        _scaleOptions(chart, 'y').ticks.color,
        ChartPaint.solid(_rgba(_blue)),
      );
    });

    group('under MediaQuery(disableAnimations: true)', () {
      testWidgets("a switch updates with 'themeFrame', a removal with "
          "'default', and both end in one frame", (tester) async {
        final modes = _spyOnUpdates();
        final config = _typedConfig(animated: true);
        Widget build(ChartThemeData? theme) => MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _typedView(config, theme: theme),
        );
        await tester.pumpWidget(build(_themeA));
        final chart = _chart(tester);
        await tester.pump();
        expect(animator.running(chart), isFalse);
        await tester.pumpWidget(build(_themeB));
        await tester.pump();
        expect(animator.running(chart), isFalse);
        await tester.pumpWidget(build(null));
        await tester.pump();
        expect(animator.running(chart), isFalse);
        expect(modes, [null, 'themeFrame', 'default']);
      });
    });
  });
}

/// A chart for the unit case of `ChartThemeSwitch`: only [data].
final class _FakeChart(@override final ChartDataScope data) implements IChart {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
