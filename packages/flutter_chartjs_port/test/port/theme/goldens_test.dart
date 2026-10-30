// Original code, not ported from Chart.js: theming.md §8 test 9, the goldens of the public presets.
// ignore_for_file: lines_longer_than_80_chars
@TestOn('vm')
@Tags(['golden'])
library;

import 'dart:io';

import 'package:chartjs_test_utils/flutter.dart' show testFontFamilies;
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/theme/theme_data.dart';
import 'package:flutter_chartjs_port/src/widgets/chart_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart' show drawCalls;

// theming.md §8 test 9 (Chart.js ADR 0050, "Goldens"): one golden file for
// each public preset on one bar chart. The pinned runner is `ubuntu-24.04`
// in the CI job `fixtures`: the font manager of the platform rasterizes the
// text (FreeType on Linux, CoreText on macOS), so a golden file of another
// image or OS differs. The tests skip unless `CHART_GOLDENS=1`, which only
// that job sets. Only a `workflow_dispatch` run of that job with
// `update_goldens` writes the files (`--update-goldens`), as the artifact
// `theme-goldens`. A local Mac never writes them.
//
// The chart: a `ChartView` of type `bar` in a box of 800 x 600 over a
// `ColoredBox` of the `surface` of the preset, with
// `maintainAspectRatio: false`, `animation: false`, the labels A to E, two
// datasets, the colors plugin on, the title, the subtitle, the legend with
// its title, the two scale titles and the tooltip of index 2 of both
// datasets at the center of the chart area. flutter_test_config.dart sets
// DPR 1 and installs Liberation Sans 2.1.5 under the families of the
// Chart.js default font (Chart.js ADR 0015).

/// The reason of the skip outside the pinned runner.
const String _skipReason =
    'the goldens run only on the pinned runner (Chart.js ADR 0050)';

/// Whether the goldens run: `CHART_GOLDENS=1`.
final bool _goldens = Platform.environment['CHART_GOLDENS'] == '1';

/// The key of the repaint boundary that the goldens capture.
const ValueKey<String> _boundary = ValueKey('goldens.boundary');

/// The config of the golden chart. The chart writes into it: a new Map for
/// each case.
Map<String, Object?> _config() => <String, Object?>{
  'type': 'bar',
  'data': <String, Object?>{
    'labels': <Object?>['A', 'B', 'C', 'D', 'E'],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'Dataset 1',
        'data': <Object?>[12, 19, 3, 5, 2],
      },
      <String, Object?>{
        'label': 'Dataset 2',
        'data': <Object?>[7, 11, 15, 8, 4],
      },
    ],
  },
  'options': <String, Object?>{
    'maintainAspectRatio': false,
    'animation': false,
    'plugins': <String, Object?>{
      'colors': <String, Object?>{'enabled': true},
      'title': <String, Object?>{'display': true, 'text': 'Title'},
      'subtitle': <String, Object?>{'display': true, 'text': 'Subtitle'},
      'legend': <String, Object?>{
        'title': <String, Object?>{'display': true, 'text': 'Legend'},
      },
    },
    'scales': <String, Object?>{
      'x': <String, Object?>{
        'title': <String, Object?>{'display': true, 'text': 'Label'},
      },
      'y': <String, Object?>{
        'title': <String, Object?>{'display': true, 'text': 'Value'},
      },
    },
  },
};

/// Pumps the golden chart of [theme] and gives its chart, with the tooltip
/// of index 2 of both datasets at the center of the chart area.
Future<Chart> _pumpChart(WidgetTester tester, ChartThemeData theme) async {
  Chart? created;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: _boundary,
          child: ColoredBox(
            color: theme.surface!,
            child: SizedBox(
              width: 800,
              height: 600,
              child: ChartView.raw(
                config: _config(),
                theme: theme,
                onChartCreated: (chart) => created = chart,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  final chart = created!;
  final area = chart.chartArea!;
  chart.tooltip!.setActiveElements(
    [
      <String, Object?>{'datasetIndex': 0, 'index': 2},
      <String, Object?>{'datasetIndex': 1, 'index': 2},
    ],
    <String, Object?>{
      'x': (area.left + area.right) / 2,
      'y': (area.top + area.bottom) / 2,
    },
  );
  chart.update();
  await tester.pump();
  return chart;
}

/// The first family of the CSS font string [font]: the text after the
/// size, up to the first comma, without its quotes.
String _firstFamily(String font) {
  final match = RegExp(r'\dpx\s+(.*)$').firstMatch(font);
  final families = match == null ? font : match.group(1)!;
  var first = families.split(',').first.trim();
  if (first.length >= 2 &&
      (first.startsWith("'") || first.startsWith('"')) &&
      first.endsWith(first[0])) {
    first = first.substring(1, first.length - 1);
  }
  return first;
}

void main() {
  group('theme goldens', () {
    for (final (name, theme) in const [
      ('light', ChartThemeData.light()),
      ('dark', ChartThemeData.dark()),
    ]) {
      testWidgets('bar chart, the $name preset', (tester) async {
        await _pumpChart(tester, theme);
        await expectLater(
          find.byKey(_boundary),
          matchesGoldenFile('goldens/bar_$name.png'),
        );
      });
    }

    testWidgets('each font of the draw calls names an installed family', (
      tester,
    ) async {
      final chart = await _pumpChart(tester, const ChartThemeData.light());
      final fonts = <String>[
        for (final call in drawCalls(chart))
          if (call case {'name': 'setFont', 'args': [final String font]}) font,
      ];
      // The title, the subtitle, the legend title and labels, the ticks,
      // the scale titles and the tooltip.
      expect(fonts, isNotEmpty);
      for (final font in fonts) {
        expect(testFontFamilies, contains(_firstFamily(font)), reason: font);
      }
    });
  }, skip: _goldens ? false : _skipReason);
}
