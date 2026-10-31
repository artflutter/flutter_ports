// Original code, not ported from Chart.js: the light preset in pixels.
@TestOn('vm')
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart'
    show themeConfigKey;
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/theme/theme_data.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

// The light identity of Chart.js ADR 0050 ("The presets", "Goldens"): a
// chart with `const ChartThemeData.light()` paints the bytes of the
// unthemed chart. Test 3 compares the resolved options. This test compares
// the bitmaps, so `const ChartThemeData()` (no theme) needs no golden file
// of its own. It runs on the VM of each OS of the CI job `test`, untagged.
//
// 16 cases: the 8 chart types with the colors plugin on and off, on charts of
// `acquireChart` at 512 x 512 (Chart.js ADR 0022). Each chart is a chart of
// blue_screen_test.dart: the title, the subtitle, the legend with
// its title, the scale titles or the point labels and angle lines, borders
// on bars and arcs, and a visible tooltip with a footer. The element 0 of
// the dataset 0 is active (`chart.setActiveElements`), and the tooltip is
// active at it. Thus the hover colors of the preset are on the bitmap too.
// The theme is the compiled preset under `themeConfigKey`
// (`compileThemeData`).
//
// The read is the read of blue_screen_test.dart: `UiCanvasContext.paint` of
// the chart canvas into a `ui.PictureRecorder` over an opaque white
// rectangle, then the bytes of `ui.ImageByteFormat.rawStraightRgba`. The
// probe F-P6 of Chart.js ADR 0050 found 0 of 262144 pixels that differ in
// each case.

/// The 8 chart types, in code unit order.
const List<String> _chartTypes = [
  'bar',
  'bubble',
  'doughnut',
  'line',
  'pie',
  'polarArea',
  'radar',
  'scatter',
];

/// The configuration of the chart of the type [type], as `_config` of
/// blue_screen_test.dart: 2 datasets, labels, the scale titles on for the
/// cartesian types, the point labels and the angle lines on for the radial
/// types, borders on bars and arcs, the title, the subtitle, the legend
/// title, a tooltip `footer` callback and `plugins.colors.enabled` from
/// [colors]. With [theme], the configuration has `themeConfigKey: theme`.
AnyObject _config(String type, {required bool colors, Object? theme}) {
  final cartesian = const {'bar', 'bubble', 'line', 'scatter'}.contains(type);
  final radial = type == 'polarArea' || type == 'radar';
  final bordered = const {'bar', 'doughnut', 'pie', 'polarArea'}.contains(
    type,
  );
  List<Object?> data(int d) => switch (type) {
    'bubble' => <Object?>[
      for (final (x, y) in [(1, 2 + d), (5, 8 - d), (9, 4 + d)])
        <String, Object?>{'x': x, 'y': y, 'r': 6},
    ],
    'scatter' => <Object?>[
      for (final (x, y) in [(1, 2 + d), (5, 8 - d), (9, 4 + d)])
        <String, Object?>{'x': x, 'y': y},
    ],
    _ => <Object?>[3 + d, 5, 2 + d],
  };
  return <String, Object?>{
    'type': type,
    'data': <String, Object?>{
      'labels': <Object?>['alpha', 'beta', 'gamma'],
      'datasets': <Object?>[
        for (var d = 0; d < 2; d++)
          <String, Object?>{
            'label': 'dataset $d',
            'data': data(d),
            if (bordered) 'borderWidth': 2,
          },
      ],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{
        'colors': <String, Object?>{'enabled': colors},
        'title': <String, Object?>{'display': true, 'text': 'Title'},
        'subtitle': <String, Object?>{'display': true, 'text': 'Subtitle'},
        'legend': <String, Object?>{
          'title': <String, Object?>{'display': true, 'text': 'Legend title'},
        },
        'tooltip': <String, Object?>{
          'callbacks': <String, Object?>{'footer': () => 'Footer'},
        },
      },
      if (cartesian)
        'scales': <String, Object?>{
          for (final id in ['x', 'y'])
            id: <String, Object?>{
              'title': <String, Object?>{'display': true, 'text': '$id axis'},
            },
        },
      if (radial)
        'scales': <String, Object?>{
          'r': <String, Object?>{
            'pointLabels': <String, Object?>{'display': true},
            'angleLines': <String, Object?>{'display': true},
          },
        },
    },
    themeConfigKey: ?theme,
  };
}

/// Acquires the chart of [config], pumps a frame, makes the element 0 of
/// the dataset 0 active with the tooltip at it, and pumps a frame.
///
/// `setActiveElements` of the chart and of the tooltip request no render
/// (`core.controller.js:1096-1117`, `plugin.tooltip.js:1106-1130`). Thus
/// `chart.update()` draws the chart again, as
/// docs/samples/advanced/programmatic-events.md:29-46 does. `acquireChart`
/// gives `animation: false`: the active colors and the tooltip need no
/// frames.
Future<Chart> _acquireActive(WidgetTester tester, AnyObject config) async {
  final chart = acquireChart(config);
  await tester.pump();
  final active = [
    <String, Object?>{'datasetIndex': 0, 'index': 0},
  ];
  final element = chart.getDatasetMeta(0).data[0] as Element;
  chart
    ..setActiveElements(active)
    ..tooltip!.setActiveElements(active, <String, Object?>{
      'x': element['x'],
      'y': element['y'],
    })
    ..update();
  await tester.pump();
  expect(chart.getActiveElements(), hasLength(1), reason: 'the hover');
  expect(chart.tooltip!.opacity, 1, reason: 'the tooltip is visible');
  return chart;
}

/// The bytes of the bitmap of [chart] over opaque white, as the chart host
/// paints it (`_paintCanvas` of chart_host.dart), in the order of
/// `rawStraightRgba`.
Future<ByteData> _pixels(WidgetTester tester, Chart chart) async {
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
    return (await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawStraightRgba),
    ))!;
  } finally {
    image.dispose();
    picture.dispose();
  }
}

/// The count of the pixels of [data] that are not the RGBA [rgba].
int _offPixels(ByteData data, int rgba) {
  var count = 0;
  for (var i = 0; i + 3 < data.lengthInBytes; i += 4) {
    if (data.getUint32(i) != rgba) count++;
  }
  return count;
}

void main() {
  test('the light preset compiles to a theme', () {
    // The identity is not the trivial one of a theme that compiles to Dart
    // null.
    expect(compileThemeData(const ChartThemeData.light()), isNotNull);
  });

  for (final colors in [true, false]) {
    final state = colors ? 'on' : 'off';
    for (final type in _chartTypes) {
      testWidgets('a $type chart with the light preset and the colors plugin '
          '$state paints the bytes of the unthemed chart', (tester) async {
        final unthemed = await _acquireActive(
          tester,
          _config(type, colors: colors),
        );
        final light = await _acquireActive(
          tester,
          _config(
            type,
            colors: colors,
            theme: compileThemeData(const ChartThemeData.light()),
          ),
        );
        final a = await _pixels(tester, unthemed);
        final b = await _pixels(tester, light);
        expect(a.lengthInBytes, 512 * 512 * 4);
        expect(b.lengthInBytes, a.lengthInBytes);
        var differ = 0;
        for (var i = 0; i + 3 < a.lengthInBytes; i += 4) {
          if (a.getUint32(i) != b.getUint32(i)) differ++;
        }
        expect(differ, 0, reason: 'the pixels that differ');
        // The chart paints: its bitmap is not white.
        expect(_offPixels(a, 0xFFFFFFFF), greaterThan(0));
      });
    }
  }
}
