// Original code, not ported from Chart.js: theming.md §8 test 9, the goldens of the public presets.
// ignore_for_file: lines_longer_than_80_chars
@TestOn('vm')
@Tags(['golden'])
library;

import 'dart:io';

import 'package:chartjs_test_utils/flutter.dart' show testFontFamilies;
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart' show drawCalls;

// theming.md §8 test 9 (Chart.js ADR 0147 §18): one golden file for
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
    'the goldens run only on the pinned runner (Chart.js ADR 0147)';

/// Whether the goldens run: `CHART_GOLDENS=1`.
final bool _goldens = Platform.environment['CHART_GOLDENS'] == '1';

/// The key of the repaint boundary that the goldens capture.
const ValueKey<String> _boundary = ValueKey('goldens.boundary');

/// The typed config of the golden chart.
ChartConfig _config() => const ChartConfig(
  datasets: [
    BarDataset(label: 'Dataset 1', data: .values([12, 19, 3, 5, 2])),
    BarDataset(label: 'Dataset 2', data: .values([7, 11, 15, 8, 4])),
  ],
  labels: ['A', 'B', 'C', 'D', 'E'],
  maintainAspectRatio: false,
  animation: ChartAnimation.none,
  title: ChartTitle(display: true, text: ['Title']),
  subtitle: ChartTitle(display: true, text: ['Subtitle']),
  legend: ChartLegend(
    extra: {
      'title': {
        'display': true,
        'text': ['Legend'],
      },
    },
  ),
  scales: [
    CategoryAxis(.x, title: AxisTitle(display: true, text: ['Label'])),
    LinearAxis(.y, title: AxisTitle(display: true, text: ['Value'])),
  ],
  extra: {
    'plugins': {
      'colors': {'enabled': true},
    },
  },
);

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
              child: ChartView(
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
      const ActiveElement(datasetIndex: 0, index: 2),
      const ActiveElement(datasetIndex: 1, index: 2),
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
      // A font of the canvas is a TextStyle (Chart.js ADR 0116).
      final fonts = <TextStyle>[
        for (final call in drawCalls(chart))
          if (call case {'name': 'setFont', 'args': [final TextStyle font]})
            font,
      ];
      // The title, the subtitle, the legend title and labels, the ticks,
      // the scale titles and the tooltip.
      expect(fonts, isNotEmpty);
      for (final font in fonts) {
        expect(testFontFamilies, contains(font.fontFamily), reason: '$font');
      }
    });
  }, skip: _goldens ? false : _skipReason);
}
