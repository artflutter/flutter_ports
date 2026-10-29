// Original code, not ported from Chart.js: tests of the theme switch.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart' show acquireChart;
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/src/core/core.animator.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.color.dart' show color;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/index.esm.dart' as kurkle;
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_chartjs_port/src/theme/chart_theme.dart';
import 'package:flutter_chartjs_port/src/theme/theme_data.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/widgets/chart_theme_switch.dart';
import 'package:flutter_chartjs_port/src/widgets/chart_view.dart';
import 'package:flutter_chartjs_port/src/widgets/chart_view_plugin.dart';
import 'package:flutter_test/flutter_test.dart';

// theming.md §8 test 8: the runtime theme switch of ChartView (Chart.js ADR
// 0050, "Runtime switch"). The widget switches in its post-frame update
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
String _rgba(Color c, [double alpha = 1]) {
  final a = alpha == 1 ? '1' : '$alpha';
  int channel(double v) => (v * 255).round();
  return 'rgba(${channel(c.r)}, ${channel(c.g)}, ${channel(c.b)}, $a)';
}

/// A chart config of [type]: labels `a` to `c`, [datasets] datasets, the
/// colors plugin on, `animation: false` unless [animated].
Map<String, Object?> _config({
  String type = 'bar',
  int datasets = 2,
  bool animated = false,
  List<Object?>? plugins,
}) => <String, Object?>{
  'type': type,
  'data': <String, Object?>{
    'labels': <Object?>['a', 'b', 'c'],
    'datasets': <Object?>[
      for (var i = 0; i < datasets; i++)
        <String, Object?>{
          'label': 'd$i',
          'data': <Object?>[1 + i, 3, 2],
        },
    ],
  },
  'options': <String, Object?>{
    if (!animated) 'animation': false,
    'plugins': <String, Object?>{
      'colors': <String, Object?>{'enabled': true},
    },
  },
  'plugins': ?plugins,
};

/// [child] at the top left of a box of 400 x 300.
Widget _box(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: 400, height: 300, child: child),
  ),
);

/// A ChartView of [config] with [theme] in [_box].
Widget _view(
  Map<String, Object?> config, {
  ChartThemeData? theme,
  String? updateMode,
  Key? key,
}) => _box(
  ChartView(config: config, theme: theme, updateMode: updateMode, key: key),
);

/// The chart of the one ChartView of the tree.
Chart _chart(WidgetTester tester) {
  final host = tester.renderObject<RenderChartHost>(find.byType(ChartHost));
  return Chart.getChart(host.canvas)!;
}

/// The datasets of [chart].
List<Object?> _datasets(Chart chart) =>
    jsGet(chart.data, 'datasets')! as List<Object?>;

/// The dataset [i] of [chart].
AnyObject _dataset(Chart chart, int i) => _datasets(chart)[i]! as AnyObject;

/// The resolved option [key] of the element [index] of the dataset
/// [datasetIndex].
Object? _elementOption(
  Chart chart,
  String key, {
  int datasetIndex = 0,
  int index = 0,
}) {
  final element = chart.getDatasetMeta(datasetIndex.toDouble()).data[index];
  return jsGet(element.options, key);
}

/// The option at [path] of the scale [id].
Object? _scaleOption(Chart chart, String id, List<String> path) {
  Object? value = chart.scales[id]!.options;
  for (final key in path) {
    value = jsGet(value, key);
  }
  return value;
}

/// A registered plugin whose `beforeUpdate` records the mode of each
/// update of each chart (the spy of `global.defaults_test.dart`). It
/// unregisters at the end of the test.
List<Object?> _spyOnUpdates() {
  final calls = <Object?>[];
  final plugin = <String, Object?>{
    'id': r'$updateSpy',
    'beforeUpdate': (types.Chart chart, AnyObject args, AnyObject options) {
      calls.add(jsGet(args, 'mode'));
    },
  };
  Chart.register([plugin]);
  addTearDown(() => Chart.unregister([plugin]));
  return calls;
}

/// The config of the probe F-P4: a line chart with two datasets, the colors
/// plugin on, the title `user` and an `x` scale with a title.
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
      'colors': <String, Object?>{'enabled': true},
      'title': <String, Object?>{'display': true, 'text': 'user'},
    },
    'scales': <String, Object?>{
      'x': <String, Object?>{
        'title': <String, Object?>{'display': true, 'text': 'x'},
      },
    },
  },
};

/// The state of the probe F-P4: the `x` tick color, `x.min`, the border
/// color of the dataset 0, the visibility of the dataset 1 and the title.
String _formState(Chart chart) {
  final x = chart.scales['x']!.options;
  final title = jsGet(jsGet(chart.options, 'plugins'), 'title');
  return 'x.ticks.color=${jsGet(jsGet(x, 'ticks'), 'color')} '
      'x.min=${jsGet(x, 'min')} '
      'ds0.borderColor=${_dataset(chart, 0)['borderColor']} '
      'visible1=${chart.isDatasetVisible(1)} '
      'title.text=${jsGet(title, 'text')}';
}

const String _formCreated =
    'x.ticks.color=rgba(255, 0, 0, 1) x.min=undefined '
    'ds0.borderColor=rgba(0, 128, 0, 1) visible1=true title.text=user';
const String _formEdited =
    'x.ticks.color=rgba(255, 0, 0, 1) x.min=b '
    'ds0.borderColor=rgba(0, 128, 0, 1) visible1=false title.text=edited';

/// The edits of the probe F-P4: the app hides the dataset 1, and it edits
/// the title text and `x.min` of [options] imperatively.
void _formEdits(Chart chart, AnyObject options) {
  chart.hide(1);
  ((options['plugins']! as AnyObject)['title']! as AnyObject)['text'] =
      'edited';
  ((options['scales']! as AnyObject)['x']! as AnyObject)['min'] = 'b';
  chart.update();
}

/// A deep copy of Maps and Lists; other values stay.
Object? _copy(Object? v) => switch (v) {
  final Map<String, Object?> m => <String, Object?>{
    for (final e in m.entries) e.key: _copy(e.value),
  },
  final List<Object?> l => [for (final i in l) _copy(i)],
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

/// The 5000 input items `{x: i, y: f(i)}` of `decimation_theme_test.dart`.
List<Object?> _decimationInput() => <Object?>[
  for (var i = 0; i < 5000; i++)
    <String, Object?>{'x': i, 'y': (i * 37) % 101 + (i ~/ 250)},
];

/// A host whose state sets the config and the theme of its ChartView in one
/// `setState`.
class _Host extends StatefulWidget {
  const _Host({required this.config, this.theme});

  final Map<String, Object?> config;
  final ChartThemeData? theme;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late Map<String, Object?> config = widget.config;
  late ChartThemeData? theme = widget.theme;
  String? updateMode;

  void show(
    Map<String, Object?> nextConfig,
    ChartThemeData? nextTheme, {
    String? mode,
  }) => setState(() {
    config = nextConfig;
    theme = nextTheme;
    updateMode = mode;
  });

  @override
  Widget build(BuildContext context) => _view(
    config,
    theme: theme,
    updateMode: updateMode,
  );
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
      chart.update('theme');
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
      chart.update('theme');
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
      final config = _formConfig();
      final options = config['options']! as AnyObject;
      await tester.pumpWidget(_view(config, theme: _themeA));
      final chart = _chart(tester);
      expect(_formState(chart), _formCreated);
      _formEdits(chart, options);
      expect(_formState(chart), _formEdited);
      await tester.pumpWidget(_view(config, theme: _themeB));
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
      chart.update('theme');
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
        final config = _config(type: type);
        await tester.pumpWidget(_view(config, theme: _themeA));
        final chart = _chart(tester);
        for (final (theme, line, palette) in [
          (_themeA, _rgba(_red), _green),
          (_themeB, _rgba(_blue), _blue),
        ]) {
          await tester.pumpWidget(_view(config, theme: theme));
          final reason = '$type, $theme';
          expect(
            _dataset(chart, 0)['borderColor'],
            _rgba(palette),
            reason: reason,
          );
          expect(
            _elementOption(chart, 'borderColor'),
            _rgba(palette),
            reason: reason,
          );
          expect(
            _elementOption(chart, 'backgroundColor'),
            _rgba(palette, 0.5),
            reason: reason,
          );
          expect(
            _scaleOption(chart, scale, ['grid', 'color']),
            line,
            reason: reason,
          );
          expect(
            _scaleOption(chart, scale, ['ticks', 'color']),
            line,
            reason: reason,
          );
          if (type == 'radar') {
            expect(
              _scaleOption(chart, scale, ['pointLabels', 'color']),
              line,
              reason: reason,
            );
            expect(
              _scaleOption(chart, scale, ['angleLines', 'color']),
              line,
              reason: reason,
            );
          }
        }
        expect(_chart(tester), same(chart));
      });
    }

    testWidgets('keeps a hidden dataset hidden and keeps the controllers, '
        'the data arrays and the dataset objects', (tester) async {
      final config = _config();
      await tester.pumpWidget(_view(config, theme: _themeA));
      final chart = _chart(tester)..hide(1);
      final datasets = [..._datasets(chart)];
      final data = [for (final d in datasets) jsGet(d, 'data')];
      final controllers = [
        for (var i = 0; i < 2; i++)
          chart.getDatasetMeta(i.toDouble()).controller,
      ];
      expect(chart.isDatasetVisible(1), isFalse);
      await tester.pumpWidget(_view(config, theme: _themeB));
      expect(chart.isDatasetVisible(1), isFalse);
      expect(chart.isDatasetVisible(0), isTrue);
      for (var i = 0; i < 2; i++) {
        expect(_datasets(chart)[i], same(datasets[i]));
        expect(jsGet(datasets[i], 'data'), same(data[i]));
        expect(
          chart.getDatasetMeta(i.toDouble()).controller,
          same(controllers[i]),
        );
      }
      expect(_dataset(chart, 0)['borderColor'], _rgba(_blue));
    });

    for (final (name, algorithm) in <(String, AnyObject)>[
      ('min-max', <String, Object?>{'algorithm': 'min-max'}),
      ('lttb', <String, Object?>{'algorithm': 'lttb', 'samples': 50}),
    ]) {
      testWidgets('keeps the decimated data ($name)', (tester) async {
        final input = _decimationInput();
        final config = <String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'label': 'd', 'data': input, 'pointRadius': 0},
            ],
          },
          'options': <String, Object?>{
            'animation': false,
            'parsing': false,
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'linear'},
            },
            'plugins': <String, Object?>{
              'colors': <String, Object?>{'enabled': true},
              'decimation': <String, Object?>{'enabled': true, ...algorithm},
            },
          },
        };
        List<(Object?, Object?)> items(Chart chart) => [
          for (final item in jsGet(_dataset(chart, 0), 'data')! as List)
            (jsGet(item, 'x'), jsGet(item, 'y')),
        ];
        await tester.pumpWidget(_view(config, theme: _themeA));
        final chart = _chart(tester);
        final before = items(chart);
        expect(before.length, lessThan(5000));
        expect(before.length, greaterThan(0));
        await tester.pumpWidget(_view(config, theme: _themeB));
        expect(items(chart), before);
        expect(jsGet(_dataset(chart, 0), '_data'), same(input));
        expect(chart.getDatasetMeta(0).data, hasLength(before.length));
        expect(_dataset(chart, 0)['borderColor'], _rgba(_blue));
      });
    }

    testWidgets('a removal gives the upstream colors with the mode default', (
      tester,
    ) async {
      final modes = _spyOnUpdates();
      final config = _config();
      await tester.pumpWidget(_view(config, theme: _themeA));
      final chart = _chart(tester);
      expect(modes, [undefined]);
      await tester.pumpWidget(_view(config));
      expect(modes, [undefined, 'default']);
      expect(chartThemeOf(chart.config), isNull);
      // The first color of BORDER_COLORS (plugin.colors.ts:14-22).
      expect(_dataset(chart, 0)['borderColor'], 'rgb(54, 162, 235)');
      expect(_elementOption(chart, 'borderColor'), 'rgb(54, 162, 235)');
      expect(_scaleOption(chart, 'y', ['ticks', 'color']), '#666');
      expect(_scaleOption(chart, 'y', ['grid', 'color']), 'rgba(0,0,0,0.1)');
    });

    testWidgets("'theme' animates the element colors for 200 ms, linear", (
      tester,
    ) async {
      final modes = _spyOnUpdates();
      final config = _config(animated: true);
      await tester.pumpWidget(_view(config, theme: _themeA));
      final chart = _chart(tester);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(animator.running(chart), isFalse);
      final from = _elementOption(chart, 'backgroundColor');
      expect(from, _rgba(_green, 0.5));

      await tester.pumpWidget(_view(config, theme: _themeB));
      expect(modes.last, 'theme');
      final to = _rgba(_blue, 0.5);
      // The colors interpolator of core.animation.js:15-21 at 0.5.
      final half = (color(to) as kurkle.Color)
          .mix(color(from) as kurkle.Color, 0.5)
          .hexString();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_elementOption(chart, 'backgroundColor'), half);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(_elementOption(chart, 'backgroundColor'), to);
      expect(animator.running(chart), isFalse);
    });

    testWidgets('an equal theme and an empty theme against none give no '
        'update', (tester) async {
      final modes = _spyOnUpdates();
      final config = _config();
      await tester.pumpWidget(_view(config, theme: _themeA));
      expect(modes, [undefined]);
      // A new instance with equal tokens.
      final equal = ChartThemeData(
        color: _red,
        borderColor: _red,
        palette: List.of(const [_green]),
      );
      expect(equal, isNot(same(_themeA)));
      expect(equal, _themeA);
      await tester.pumpWidget(_view(config, theme: equal));
      await tester.pump();
      expect(modes, [undefined]);

      // A new chart without a theme, then the empty theme.
      final other = _config();
      await tester.pumpWidget(_view(other, key: const ValueKey('none')));
      expect(modes, [undefined, undefined]);
      await tester.pumpWidget(
        _view(
          other,
          theme: const ChartThemeData(),
          key: const ValueKey('none'),
        ),
      );
      await tester.pump();
      expect(modes, [undefined, undefined]);
      expect(chartThemeOf(_chart(tester).config), isNull);
    });

    testWidgets('a dataset that the app pushes after the first colorize gets '
        'the next palette color after a switch', (tester) async {
      final config = _config();
      await tester.pumpWidget(_view(config, theme: _palette3A));
      final chart = _chart(tester);
      expect(_dataset(chart, 1)['borderColor'], _rgba(_green));
      _datasets(chart).add(<String, Object?>{
        'label': 'd2',
        'data': <Object?>[2, 2, 2],
      });
      chart.update();
      // The colors plugin skips: the datasets hold colors
      // (plugin.colors.ts:113-121).
      expect(_dataset(chart, 2).containsKey('borderColor'), isFalse);
      await tester.pumpWidget(_view(config, theme: _palette3B));
      expect(_dataset(chart, 0)['borderColor'], _rgba(_yellow));
      expect(_dataset(chart, 1)['borderColor'], _rgba(_cyan));
      expect(_dataset(chart, 2)['borderColor'], _rgba(_magenta));
      expect(_dataset(chart, 2)['backgroundColor'], _rgba(_magenta, 0.5));
    });

    testWidgets('an app edit of a dataset color stays, and the other '
        'datasets then get no palette color, as a new chart', (tester) async {
      final config = _config();
      await tester.pumpWidget(_view(config, theme: _palette3A));
      final chart = _chart(tester);
      _dataset(chart, 0)['borderColor'] = 'rgb(1, 2, 3)';
      chart.update();
      await tester.pumpWidget(_view(config, theme: _palette3B));
      expect(_dataset(chart, 0)['borderColor'], 'rgb(1, 2, 3)');
      expect(_dataset(chart, 0).containsKey('backgroundColor'), isFalse);
      expect(_dataset(chart, 1).containsKey('borderColor'), isFalse);
      expect(_dataset(chart, 1).containsKey('backgroundColor'), isFalse);
      final switched = [
        for (final key in ['borderColor', 'backgroundColor'])
          for (var i = 0; i < 2; i++)
            _elementOption(chart, key, datasetIndex: i),
      ];

      // A new chart of the theme B with that dataset color.
      final fresh = _config();
      (_datasetsOf(fresh)[0]! as AnyObject)['borderColor'] = 'rgb(1, 2, 3)';
      await tester.pumpWidget(
        _view(fresh, theme: _palette3B, key: const ValueKey('fresh')),
      );
      final created = _chart(tester);
      expect(created, isNot(same(chart)));
      expect(_dataset(created, 1).containsKey('borderColor'), isFalse);
      expect([
        for (final key in ['borderColor', 'backgroundColor'])
          for (var i = 0; i < 2; i++)
            _elementOption(created, key, datasetIndex: i),
      ], switched);
    });

    testWidgets('forceOverride: the palette keys go back to the values '
        'before the first write', (tester) async {
      final config = _config();
      final colors =
          ((config['options']! as AnyObject)['plugins']!
                  as AnyObject)['colors']!
              as AnyObject;
      colors['forceOverride'] = true;
      (_datasetsOf(config)[1]! as AnyObject)['borderColor'] = 'rgb(9, 9, 9)';
      await tester.pumpWidget(_view(config, theme: _palette3A));
      final chart = _chart(tester);
      // forceOverride writes over the dataset color in each update.
      expect(_dataset(chart, 1)['borderColor'], _rgba(_green));
      chart
        ..update()
        ..update();
      expect(_dataset(chart, 1)['borderColor'], _rgba(_green));
      await tester.pumpWidget(_view(config, theme: _palette3B));
      expect(_dataset(chart, 1)['borderColor'], _rgba(_cyan));
      // A removal restores the value of the app before the first write, and
      // the colors plugin writes the upstream palette over it.
      await tester.pumpWidget(_view(config));
      expect(_dataset(chart, 1)['borderColor'], 'rgb(255, 99, 132)');
      // With the plugin off, a switch shows the restored values: the value
      // of the app, and no key where the app had none.
      colors['enabled'] = false;
      await tester.pumpWidget(_view(config, theme: _palette3A));
      expect(_dataset(chart, 1)['borderColor'], 'rgb(9, 9, 9)');
      expect(_dataset(chart, 1).containsKey('backgroundColor'), isFalse);
      expect(_dataset(chart, 0).containsKey('borderColor'), isFalse);
    });

    testWidgets('a theme change and a config change in one frame give one '
        'update with the theme mode', (tester) async {
      final modes = _spyOnUpdates();
      final config = _config();
      await tester.pumpWidget(_Host(config: config, theme: _themeA));
      final host = tester.state<_HostState>(find.byType(_Host));
      final chart = _chart(tester);
      expect(modes, [undefined]);
      final next = <String, Object?>{
        ...config,
        'data': <String, Object?>{
          'labels': <Object?>['a', 'b', 'c'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[4, 5, 6],
            },
          ],
        },
      };
      host.show(next, _themeB, mode: 'none');
      await tester.pump();
      expect(modes, [undefined, 'theme']);
      expect(chart.data, same(next['data']));
      expect(_dataset(chart, 0)['borderColor'], _rgba(_blue));
      // A config change alone takes updateMode.
      host.show({...next}, _themeB, mode: 'none');
      await tester.pump();
      expect(modes, [undefined, 'theme', 'none']);
    });

    testWidgets('the inherited theme: ChartTheme above, ChartView.theme '
        'beats it, and the empty theme turns theming off', (tester) async {
      final config = _config();
      Widget build(ChartThemeData data, {ChartThemeData? own}) => ChartTheme(
        data: data,
        child: _view(config, theme: own),
      );
      await tester.pumpWidget(build(_themeA));
      final chart = _chart(tester);
      expect(_scaleOption(chart, 'y', ['ticks', 'color']), _rgba(_red));
      await tester.pumpWidget(build(_themeB));
      expect(_scaleOption(chart, 'y', ['ticks', 'color']), _rgba(_blue));
      await tester.pumpWidget(build(_themeB, own: _themeA));
      expect(_scaleOption(chart, 'y', ['ticks', 'color']), _rgba(_red));
      await tester.pumpWidget(build(_themeB, own: const ChartThemeData()));
      expect(_scaleOption(chart, 'y', ['ticks', 'color']), '#666');
      expect(chartThemeOf(chart.config), isNull);
      expect(_chart(tester), same(chart));
    });
  });

  group('the widget', () {
    testWidgets(r'the plugin $chartView comes last, after the inline plugins '
        'of the app', (tester) async {
      final app = <String, Object?>{'id': 'app'};
      await tester.pumpWidget(_view(_config(plugins: [app]), theme: _themeA));
      final plugins = _chart(tester).config.plugins! as List;
      expect(plugins, hasLength(2));
      expect(plugins.first, same(app));
      expect(jsGet(plugins.last, 'id'), chartViewPluginId);
      expect(chartViewPluginId, r'$chartView');
    });

    testWidgets('the diagnostics name the theme', (tester) async {
      final properties = [
        for (final property in const ChartView(
          config: {},
          theme: ChartThemeData.dark(),
        ).toDiagnosticsNode().getProperties())
          if (!property.isFiltered(DiagnosticLevel.info)) property.name,
      ];
      expect(properties, ['type', 'theme']);
    });

    testWidgets(r'an app value under $theme fails the debug assert', (
      tester,
    ) async {
      final config = _config()..[themeConfigKey] = <String, Object?>{};
      await tester.pumpWidget(_view(config));
      expect(tester.takeException(), isA<AssertionError>());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('an app plugins value that is not a List fails the debug '
        'assert', (tester) async {
      final config = _config()..['plugins'] = <String, Object?>{};
      await tester.pumpWidget(_view(config));
      expect(tester.takeException(), isA<AssertionError>());
    });
  });

  group('reduced motion', () {
    test("ChartThemeSwitch gives 'themeFrame' for a new theme and 'default' "
        'for a removal', () {
      final switcher = ChartThemeSwitch();
      final root = <String, Object?>{
        'options': <String, Object?>{},
        'data': <String, Object?>{'datasets': <Object?>[]},
      };
      switcher.start(root, null);
      final chart = _FakeChart(root['data']! as AnyObject);
      expect(
        switcher.apply(chart, root, _themeA, reducedMotion: true),
        'themeFrame',
      );
      expect(root[themeConfigKey], same(compileThemeData(_themeA)));
      expect(
        switcher.apply(chart, root, _themeB, reducedMotion: false),
        'theme',
      );
      expect(switcher.apply(chart, root, null, reducedMotion: true), 'default');
      expect(root.containsKey(themeConfigKey), isFalse);
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

    testWidgets("an update('themeFrame') ends in one frame", (tester) async {
      final config = _config(animated: true);
      (config['options']! as AnyObject)['animation'] = <String, Object?>{};
      config[themeConfigKey] = compileThemeData(_themeA);
      final chart = acquireChart(config);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(animator.running(chart), isFalse);
      // Steps 2 and 3 of the switch: the config had no user scales.
      config[themeConfigKey] = compileThemeData(_themeB);
      (config['options']! as AnyObject).remove('scales');
      chart.update('themeFrame');
      expect(animator.has(chart), isFalse);
      await tester.pump();
      expect(animator.running(chart), isFalse);
      expect(_scaleOption(chart, 'y', ['ticks', 'color']), _rgba(_blue));
    });

    group(
      'under MediaQuery(disableAnimations: true)',
      () {
        testWidgets("a switch updates with 'themeFrame', a removal with "
            "'default', and both end in one frame", (tester) async {
          final modes = _spyOnUpdates();
          final config = _config(animated: true);
          Widget build(ChartThemeData? theme) => MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: _view(config, theme: theme),
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
          expect(modes, [undefined, 'themeFrame', 'default']);
        });
      },
      skip:
          'n/a: ChartView reads the reduced-motion preference with the flag '
          'of Chart.js ADR 0049 section 7, which lands after the night run '
          'A-N3',
    );
  });
}

/// The datasets of the raw [config].
List<Object?> _datasetsOf(Map<String, Object?> config) =>
    (config['data']! as AnyObject)['datasets']! as List<Object?>;

/// A chart for the unit case of `ChartThemeSwitch`: only [data].
final class _FakeChart implements types.Chart {
  _FakeChart(this.data);

  @override
  final AnyObject data;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
