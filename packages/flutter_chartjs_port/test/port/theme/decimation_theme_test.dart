// Original code, not ported from Chart.js: the decimated data under a theme.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart'
    show themeConfigKey;
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/theme/presets.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

// theming.md section 10, the phase 8 row, and the theme spec of phase 8
// (Chart.js ADR 0042): a theme leaves the decimated data and `_data` of
// plugin.decimation.js:249-265 unchanged.
//
// Each case makes a line chart with `parsing: false`, a linear `x` scale and
// 5000 points `{x, y}`, above the default threshold `4 * availableWidth` of
// plugin.decimation.js:242. The colors plugin is on. The chart runs three
// times: without a theme, with the light preset, and with a local theme
// that sets each color token and a palette. After the first draw and again
// after `chart.update()`, `data` has the same length and the same `x` and
// `y` for each item as the run without a theme, `_data` is the input List
// itself, and the meta has the same element count. Only `borderColor` and
// `backgroundColor` of the dataset can differ (theming.md section 3.7).
//
// The reads use `jsGet`. Thus the test does not depend on the form of the
// differences.md row adapt-decimation-data-accessor.
//
// flutter_test_config.dart registers the plugins with the built-in
// components and sets `defaults.plugins.colors.enabled = false`, as
// test/index.js:25-28 does (Chart.js ADR 0041, sections 1 and 6). Each chart
// sets `plugins.colors.enabled: true`.

/// The color `rgb(200, 0, 0)`.
const RawThemeColor _red = (alpha: 1.0, red: 200 / 255, green: 0.0, blue: 0.0);

/// The color `rgba(0, 0, 255, 0.8)`.
const RawThemeColor _blue = (alpha: 0.8, red: 0.0, green: 0.0, blue: 1.0);

/// A theme with each color token and a palette.
AnyObject _localTheme() => <String, Object?>{
  'colors': <String, Object?>{
    'color': _red,
    'borderColor': _red,
    'backgroundColor': _blue,
    'surface': _blue,
  },
  'palette': <String, Object?>{
    'colors': <Object?>[_red, _blue],
    'backgroundAlpha': 0.25,
  },
};

/// The three runs: the name and the compiled theme (Dart `null` for no
/// theme).
final List<(String, AnyObject? Function())> _runs = [
  ('no theme', () => null),
  ('the light preset', () => compileChartTheme(ChartThemes.light)),
  ('a local theme', () => compileChartTheme(_localTheme())),
];

/// The 5000 input items `{x: i, y: f(i)}`, new for each chart.
List<Object?> _input() => <Object?>[
  for (var i = 0; i < 5000; i++)
    <String, Object?>{'x': i, 'y': (i * 37) % 101 + (i ~/ 250)},
];

/// What the test compares after a draw.
typedef _State = ({
  List<(Object?, Object?)> items,
  bool rawIsInput,
  int metaCount,
  List<String> keys,
  Object? borderColor,
  Object? backgroundColor,
});

/// The state of the dataset 0 of [chart], with [input] the input List.
_State _state(Chart chart, List<Object?> input) {
  final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
  final dataset = datasets[0]! as AnyObject;
  final data = jsGet(dataset, 'data')! as List<Object?>;
  return (
    items: [for (final item in data) (jsGet(item, 'x'), jsGet(item, 'y'))],
    rawIsInput: identical(jsGet(dataset, '_data'), input),
    metaCount: chart.getDatasetMeta(0).data.length,
    keys: jsObjectKeys(dataset),
    borderColor: jsGet(dataset, 'borderColor'),
    backgroundColor: jsGet(dataset, 'backgroundColor'),
  );
}

/// Makes the chart of a case with [algorithm] and [theme], and gives the
/// state after the first draw and after `chart.update()`.
Future<(_State, _State)> _run(
  WidgetTester tester,
  AnyObject algorithm,
  AnyObject? theme,
) async {
  final input = _input();
  final chart = acquireChart(<String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{'label': 'd', 'data': input, 'pointRadius': 0},
      ],
    },
    'options': <String, Object?>{
      'parsing': false,
      'scales': <String, Object?>{
        'x': <String, Object?>{'type': 'linear'},
      },
      'plugins': <String, Object?>{
        'colors': <String, Object?>{'enabled': true},
        'decimation': <String, Object?>{'enabled': true, ...algorithm},
      },
    },
    themeConfigKey: ?theme,
  });
  await tester.pump();
  final first = _state(chart, input);
  chart.update();
  await tester.pump();
  final second = _state(chart, input);
  return (first, second);
}

void main() {
  for (final (name, algorithm) in <(String, AnyObject)>[
    ('min-max', <String, Object?>{'algorithm': 'min-max'}),
    ('lttb', <String, Object?>{'algorithm': 'lttb', 'samples': 50}),
  ]) {
    group(name, () {
      testWidgets('a theme leaves data, _data and the elements unchanged', (
        tester,
      ) async {
        final results = <String, (_State, _State)>{};
        for (final (run, theme) in _runs) {
          results[run] = await _run(tester, algorithm, theme());
        }
        final (base, baseUpdated) = results['no theme']!;
        // The plugin decimated the data.
        expect(base.items.length, lessThan(5000));
        expect(base.items.length, greaterThan(0));
        expect(base.rawIsInput, isTrue);
        expect(base.metaCount, base.items.length);
        expect(baseUpdated.items, base.items);
        for (final (run, _) in _runs.skip(1)) {
          final (first, updated) = results[run]!;
          for (final (step, state, expected) in [
            ('the first draw', first, base),
            ('chart.update()', updated, baseUpdated),
          ]) {
            final reason = '$run, after $step';
            expect(state.items, expected.items, reason: reason);
            expect(state.rawIsInput, isTrue, reason: reason);
            expect(state.metaCount, expected.metaCount, reason: reason);
            expect(state.keys, expected.keys, reason: reason);
          }
        }
        // The local palette reaches the dataset colors: only these keys
        // differ.
        final (local, _) = results['a local theme']!;
        expect(local.borderColor, isNot(base.borderColor));
        expect(local.backgroundColor, isNot(base.backgroundColor));
      });
    });
  }
}
