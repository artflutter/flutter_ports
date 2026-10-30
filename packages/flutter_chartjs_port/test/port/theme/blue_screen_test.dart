// Original code, not ported from Chart.js: theming.md §8 test 6.
@TestOn('vm')
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart'
    show themeConfigKey;
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.color.dart'
    show getHoverColor;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/color.dart' as kurkle;
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart' show drawCalls;

// theming.md §8 test 6, the full blue screen (Chart.js ADR 0050, "The blue
// screen"; Chart.js ADR 0030, section 11): a theme that sets each color
// token and the palette (alpha 1) to one blue, over a background of the
// same blue, gives a bitmap with no other pixel. A pixel of another color
// shows a color that the theme does not reach (a leak).
//
// flutter_test_config.dart registers `registerables` with the seven plugins
// and sets `defaults.plugins.colors.enabled = false` (test/index.js:25-28).
// Each chart has the title, the subtitle, the legend (with its title) and a
// visible tooltip with a footer, and sets `plugins.colors.enabled` (on and
// off). The 8 chart types with the colors plugin on and off are 16 cases.
//
// 16 more cases have an active element (Chart.js ADR 0050, "The blue
// screen"): `chart.setActiveElements` for the element 0 of the dataset 0,
// the tooltip active at it, and `chart.update()`. The hover colors are the
// root scriptables of core.defaults.js:62-64, `getHoverColor` of the themed
// base color (helpers.color.ts:28-32). Thus the known active setters are
// `setFillStyle` and `setStrokeStyle` of the ported `getHoverColor` of the
// blue (`#003CCA`). A bar draws its border as a fill
// (element.bar.js:191-192), so the bar has `setFillStyle` only. Each pixel
// that is not the blue lies on the segment from the blue to that color,
// within 2 units for each channel: the antialiasing of an active element
// mixes the two colors. The probes F-P2 and Pf-B7 of Chart.js ADR 0050 found
// these setters in 16 of 16 cases, and each pixel within 1 unit (bubble: 1
// pixel at 2 units). The setter check finds any other color, so the active
// cases need no test-only identity hover (theming.md §8 item 6).
//
// The tooltip shows through `chart.tooltip.setActiveElements` and
// `chart.update()`, the form of docs/samples/advanced/programmatic-events.md
// (:29-46): `setActiveElements` does not request a render
// (plugin.tooltip.js:1105-1129). `acquireChart` gives `animation: false`,
// and the tooltip reads `chart.options.animation` (plugin.tooltip.js:516).
// Thus the tooltip has no animation.
//
// The read is the paint call of the chart host (chart_host.dart:728,
// `_paintCanvas`): `UiCanvasContext.paint` of the chart canvas into a
// `ui.PictureRecorder` over an opaque rectangle of the blue. Each pixel must
// be exactly `20 50 c0 ff`. No tolerance and no golden file. On a failure,
// the reason lists each style setter of the draw calls (with the element,
// title and legend draws, Chart.js ADR 0030, section 1) whose value does
// not parse to the blue or to alpha 0.
//
// The reference values (no leak in the 16 cases, `#666` twice in the pin
// case) come from the probe P2 of Chart.js ADR 0042
// (`fidelity/blue_screen_plugins.mjs` in the x64 Node.js at the pin).

/// The blue of the theme and of the background: #2050c0, alpha 1. Its
/// channels are not 0 or 255, so a rounding fault shows.
const int _blue = 0xFF2050C0;

/// The RGBA bytes of [_blue], in the order of `rawStraightRgba`.
const int _blueRgba = 0x2050C0FF;

/// The blue as a raw theme color.
const RawThemeColor _blueColor = (
  alpha: 1.0,
  red: 32 / 255,
  green: 80 / 255,
  blue: 192 / 255,
);

/// The color tokens of compile.dart, each set to [_blue]: `color`,
/// `borderColor`, `backgroundColor`, `surface`, `inverseSurface` and
/// `onInverseSurface` (theming.md §4).
const AnyObject _blueColors = <String, Object?>{
  'color': _blueColor,
  'borderColor': _blueColor,
  'backgroundColor': _blueColor,
  'surface': _blueColor,
  'inverseSurface': _blueColor,
  'onInverseSurface': _blueColor,
};

/// A raw Map theme that sets each color token and the palette to [_blue].
/// The palette has `backgroundAlpha: 1.0`, so the background colors of the
/// colors plugin are opaque (Chart.js ADR 0050, `plugin.colors.ts:25`).
const AnyObject _blueTheme = <String, Object?>{
  'colors': _blueColors,
  'palette': <String, Object?>{
    'colors': <RawThemeColor>[_blueColor],
    'backgroundAlpha': 1.0,
  },
};

/// [_blueTheme] without the palette: the colors plugin then uses the
/// upstream palette (rows `theme-H4b` and `theme-H4c`).
const AnyObject _blueThemeWithoutPalette = <String, Object?>{
  'colors': _blueColors,
};

/// The key that the token `surface` emits at alpha 0.75 (compile.dart,
/// `_backdropKey`): the scale tick backdrop.
const String _backdropPath = 'scale.ticks.backdropColor';

/// The two palette keys of `plugins.colors` in a compiled theme.
const List<String> _palettePaths = [
  r'plugins.colors.$borderColors',
  r'plugins.colors.$backgroundColors',
];

/// The known leaks of the 8 default charts: chart type to the leaking
/// setter values (`<setter> <value>`), each with its upstream file:line.
/// Empty (Chart.js ADR 0050). The test fails when a set changes in either
/// direction.
const Map<String, Set<String>> knownLeaks = {};

/// The known leaks of the pin case, a legend item without `fillStyle` and
/// `strokeStyle`: the legend box reads the singleton `defaults.color`
/// (plugin.legend.js:286), not the options, for its fill (:314) and its
/// stroke (:319). If upstream removes the read, the pin case fails and this
/// list changes.
const Set<String> knownSingletonLeaks = {
  'setFillStyle #666',
  'setStrokeStyle #666',
};

/// The hover color of the blue: the ported `getHoverColor` of `#2050c0`
/// (helpers.color.ts:28-32), the value of the root hover scriptables of
/// core.defaults.js:62-64 over the themed base color.
final Object? _hoverBlue = getHoverColor('#2050c0');

/// The known setters of an active case of the chart type [type]: the
/// setters with the value [_hoverBlue]. The bar draws its border as a fill
/// (element.bar.js:191-192), so it has `setFillStyle` only. The test fails
/// when a set changes in either direction.
Set<String> knownActiveSetters(String type) => {
  'setFillStyle $_hoverBlue',
  if (type != 'bar') 'setStrokeStyle $_hoverBlue',
};

/// The largest distance from the segment of the blue to the hover color
/// that the pixels of an active case can have, in 8-bit units for each
/// channel (Chart.js ADR 0050, "The blue screen").
const int _segmentUnits = 2;

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

/// The texts of the title, the subtitle, the legend title and the tooltip
/// footer.
const List<String> _pluginTexts = [
  'Title',
  'Subtitle',
  'Legend title',
  'Footer',
];

/// The configuration of the chart of the type [type]: 2 datasets, labels,
/// the scale titles on for the cartesian types, the point labels and the
/// angle lines on for the radial types, and borders on bars and arcs.
///
/// The plugins: the title and the subtitle on with a text, the legend title
/// on with a text, a tooltip `footer` callback, and
/// `plugins.colors.enabled` from [colors]. [legendLabels] replaces the
/// legend `labels` options. With [theme], the configuration has
/// `themeConfigKey: compileChartTheme(theme)`.
AnyObject _config(
  String type, {
  AnyObject? theme,
  bool colors = false,
  AnyObject? legendLabels,
}) {
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
          'labels': ?legendLabels,
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
    if (theme != null) themeConfigKey: compileChartTheme(theme),
  };
}

/// Acquires the chart of [config], pumps a frame and shows the tooltip
/// ([_showTooltip]).
Future<Chart> _acquireWithTooltip(WidgetTester tester, AnyObject config) async {
  final chart = acquireChart(config);
  await tester.pump();
  await _showTooltip(tester, chart);
  return chart;
}

/// Shows the tooltip of the item 1 of the dataset 0 of [chart] at the event
/// position `{x: 0, y: 0}` and pumps a frame.
///
/// `chart.update()` draws the chart again with the tooltip
/// (docs/samples/advanced/programmatic-events.md:29-46). Without it, the
/// bitmap has no tooltip (the test `the tooltip reaches the bitmap`). The
/// function checks that no chart element is active and that the tooltip is
/// visible.
Future<void> _showTooltip(WidgetTester tester, Chart chart) async {
  chart.tooltip!.setActiveElements(
    [
      <String, Object?>{'datasetIndex': 0, 'index': 1},
    ],
    <String, Object?>{'x': 0, 'y': 0},
  );
  chart.update();
  await tester.pump();
  expect(chart.getActiveElements(), isEmpty, reason: 'no chart hover');
  expect(chart.tooltip!.opacity, 1, reason: 'the tooltip is visible');
  expect(chart.tooltip!.getActiveElements(), hasLength(1));
}

/// The bytes of the bitmap of [chart] over an opaque [background], as the
/// chart host paints it (chart_host.dart:728).
Future<ByteData> chartPixelsOver(
  WidgetTester tester,
  Chart chart,
  ui.Color background,
) async {
  final canvas = chart.canvas! as UiCanvasElement;
  final w = canvas.width;
  final h = canvas.height;
  final recorder = ui.PictureRecorder();
  final c = ui.Canvas(recorder)
    ..drawRect(
      ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      ui.Paint()..color = background,
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

/// The count of pixels of [data] that are not the RGBA [rgba].
int offPixels(ByteData data, int rgba) {
  var count = 0;
  for (var i = 0; i + 3 < data.lengthInBytes; i += 4) {
    if (data.getUint32(i) != rgba) count++;
  }
  return count;
}

/// The style setters of the canvas calls.
const Set<String> _styleSetters = {'setFillStyle', 'setStrokeStyle'};

/// Whether the style [value] keeps a pixel blue over the blue background:
/// a color with the channels of [_blue] (any alpha), or alpha 0.
bool _keepsBlue(Object? value) {
  final rgb = kurkle.Color(value).rgb;
  if (rgb == null) return false;
  return rgb.a == 0 ||
      (rgb.r == ((_blue >> 16) & 0xFF) &&
          rgb.g == ((_blue >> 8) & 0xFF) &&
          rgb.b == (_blue & 0xFF));
}

/// The leaking style setters of the draw [calls]: the call index and the
/// value `<setter> <value>`.
///
/// A setter value of Dart `null` is not a leak: `canvasStyle` gives `null`
/// for the `undefined` of a legend item without `fontColor`
/// (plugin.legend.js:395-396), and the canvas ignores it, as the DOM
/// ignores `undefined`.
List<(int, String)> _leaks(List<Object?> calls) => [
  for (var i = 0; i < calls.length; i++)
    if (calls[i]
        case {
          'name': final String name,
          'args': [final Object value, ...],
        }
        when _styleSetters.contains(name) && !_keepsBlue(value))
      (i, '$name $value'),
];

/// The leaking style setters of the draw [calls], with the call index.
List<String> leakingSetters(List<Object?> calls) => [
  for (final (index, value) in _leaks(calls)) '#$index $value',
];

/// The text arguments of the `fillText` calls of the draw [calls].
Set<Object?> _filledTexts(List<Object?> calls) => {
  for (final call in calls)
    if (call case {'name': 'fillText', 'args': [final Object? text, ...]}) text,
};

/// A deep plain copy of [value] through `jsObjectKeys`: Maps and Lists are
/// copies, other values stay as they are.
Object? _plain(Object? value, [int depth = 0]) {
  if (depth > 64) throw StateError('A copy of an object with a cycle');
  return switch (value) {
    final List<Object?> list => [
      for (final item in list) _plain(item, depth + 1),
    ],
    final Map<String, Object?> map => <String, Object?>{
      for (final key in jsObjectKeys(map))
        key: _plain(jsGet(map, key), depth + 1),
    },
    _ => value,
  };
}

/// Each color option of the compiled theme [node] at the dot path [path]:
/// a key that is `color` or ends in `Color` or `Background`
/// (`plugins.tooltip.multiKeyBackground`), and each item of the palette
/// Lists, at `<path>[<index>]`.
Iterable<(String, Object?)> _themeColors(
  Object? node, [
  String path = '',
]) => switch (node) {
  final Map<String, Object?> map => [
    for (final MapEntry(:key, :value) in map.entries)
      if (key == 'color' || key.endsWith('Color') || key.endsWith('Background'))
        ('$path$key', value)
      else if (_palettePaths.contains('$path$key') && value is List<Object?>)
        for (var i = 0; i < value.length; i++) ('$path$key[$i]', value[i])
      else
        ..._themeColors(value, '$path$key.'),
  ],
  _ => const [],
};

/// Acquires the chart of [config], pumps a frame, makes the element 0 of
/// the dataset 0 active with the tooltip at it, and pumps a frame.
///
/// `setActiveElements` of the chart and of the tooltip request no render
/// (`core.controller.js:1096-1117`, `plugin.tooltip.js:1106-1130`). Thus
/// `chart.update()` draws the chart again. `acquireChart` gives
/// `animation: false`: the active colors and the tooltip need no frames.
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
  expect(chart.tooltip!.getActiveElements(), hasLength(1));
  return chart;
}

/// The pixels of [data] that are not the blue, and those of them that lie
/// farther than [_segmentUnits] from the segment of the blue to the color
/// [hover], with the largest distance. The distance of a pixel is the
/// largest channel difference, rounded up, to its projection on the
/// segment.
({int notBlue, int offSegment, int worst}) _segmentCheck(
  ByteData data,
  List<int> hover,
) {
  const blue = [0x20, 0x50, 0xC0];
  final d = [for (var k = 0; k < 3; k++) hover[k] - blue[k]];
  final dd = d.fold<int>(0, (sum, x) => sum + x * x);
  var notBlue = 0;
  var offSegment = 0;
  var worst = 0;
  for (var i = 0; i + 3 < data.lengthInBytes; i += 4) {
    final p = [data.getUint8(i), data.getUint8(i + 1), data.getUint8(i + 2)];
    if (p[0] == blue[0] && p[1] == blue[1] && p[2] == blue[2]) continue;
    notBlue++;
    var dot = 0;
    for (var k = 0; k < 3; k++) {
      dot += (p[k] - blue[k]) * d[k];
    }
    final t = dd == 0 ? 0.0 : (dot / dd).clamp(0.0, 1.0);
    var distance = 0;
    for (var k = 0; k < 3; k++) {
      final e = (p[k] - (blue[k] + t * d[k])).abs().ceil();
      if (e > distance) distance = e;
    }
    if (distance > worst) worst = distance;
    if (distance > _segmentUnits) offSegment++;
  }
  return (notBlue: notBlue, offSegment: offSegment, worst: worst);
}

/// Runs the blue-screen check on [chart]: the leaking setters equal
/// [known], and with no known leak each pixel over the blue is the blue.
/// Gives the count of the pixels over the blue that are not the blue.
Future<int> _expectBlue(
  WidgetTester tester,
  Chart chart,
  Set<String> known,
) async {
  final pixels = await chartPixelsOver(tester, chart, const ui.Color(_blue));
  final off = offPixels(pixels, _blueRgba);
  final calls = drawCalls(chart);
  expect(
    {for (final (_, value) in _leaks(calls)) value},
    known,
    reason: 'the leaking setters: ${leakingSetters(calls)}',
  );
  if (known.isEmpty) {
    expect(
      off,
      0,
      reason:
          'the pixels that are not #2050c0; '
          'the leaking setters: ${leakingSetters(calls)}',
    );
  }
  // The plugins draw their texts.
  expect(_filledTexts(calls), containsAll(_pluginTexts));
  // The chart paints: over white, its blue pixels differ.
  final overWhite = await chartPixelsOver(
    tester,
    chart,
    const ui.Color(0xFFFFFFFF),
  );
  expect(offPixels(overWhite, 0xFFFFFFFF), greaterThan(0));
  return off;
}

void main() {
  test('the compiled blue theme emits each color as the blue', () {
    final colors = _themeColors(compileChartTheme(_blueTheme)).toList();
    expect(colors, isNotEmpty);
    for (final (path, value) in colors) {
      expect(value, isA<String>(), reason: path);
      final rgb = kurkle.Color(value).rgb;
      expect(rgb, isNotNull, reason: path);
      expect([rgb!.r, rgb.g, rgb.b], [32, 80, 192], reason: path);
      // The token `surface` gives the tick backdrop at alpha 0.75. The
      // palette has `backgroundAlpha: 1.0`.
      expect(rgb.a, path == _backdropPath ? 0.75 : 1, reason: path);
    }
    final paths = colors.map((c) => c.$1);
    expect(
      paths,
      contains(_backdropPath),
      reason: 'the token surface emits the tick backdrop',
    );
    expect(
      paths,
      containsAll(<String>[
        'plugins.title.color',
        'plugins.subtitle.color',
        'plugins.tooltip.backgroundColor',
        'plugins.tooltip.titleColor',
        'plugins.tooltip.bodyColor',
        'plugins.tooltip.footerColor',
        'plugins.tooltip.multiKeyBackground',
        r'plugins.colors.$borderColors[0]',
        r'plugins.colors.$backgroundColors[0]',
      ]),
      reason: 'the plugin tokens and the palette',
    );
  });

  for (final colors in [true, false]) {
    final state = colors ? 'on' : 'off';
    for (final type in _chartTypes) {
      testWidgets('a $type chart with the blue theme and the colors plugin '
          '$state paints only the blue', (tester) async {
        final chart = await _acquireWithTooltip(
          tester,
          _config(type, theme: _blueTheme, colors: colors),
        );
        await _expectBlue(tester, chart, knownLeaks[type] ?? const {});
      });
    }
  }

  for (final type in ['bar', 'doughnut']) {
    testWidgets('a $type chart with a legend item without fillStyle and '
        'strokeStyle paints the singleton defaults.color', (tester) async {
      // The pin case of Chart.js ADR 0050: a user `generateLabels` gives an
      // item without `fillStyle`, `strokeStyle` and `fontColor`.
      final chart = await _acquireWithTooltip(
        tester,
        _config(
          type,
          theme: _blueTheme,
          colors: true,
          legendLabels: <String, Object?>{
            'generateLabels': (Object? chart) => <Object?>[
              <String, Object?>{'text': 'x', 'datasetIndex': 0},
            ],
          },
        ),
      );
      final off = await _expectBlue(tester, chart, knownSingletonLeaks);
      expect(off, greaterThan(0), reason: 'the legend box is #666');
    });
  }

  test('the hover color of the blue is #003CCA', () {
    // The value of the probes F-P2 and Pf-B7 of Chart.js ADR 0050.
    expect(_hoverBlue, '#003CCA');
  });

  for (final colors in [true, false]) {
    final state = colors ? 'on' : 'off';
    for (final type in _chartTypes) {
      testWidgets('a $type chart with an active element, the blue theme and '
          'the colors plugin $state paints only the blue and its hover '
          'color', (tester) async {
        final chart = await _acquireActive(
          tester,
          _config(type, theme: _blueTheme, colors: colors),
        );
        final pixels = await chartPixelsOver(
          tester,
          chart,
          const ui.Color(_blue),
        );
        final rgb = kurkle.Color(_hoverBlue).rgb!;
        final check = _segmentCheck(pixels, [
          rgb.r.round(),
          rgb.g.round(),
          rgb.b.round(),
        ]);
        final calls = drawCalls(chart);
        expect(
          {for (final (_, value) in _leaks(calls)) value},
          knownActiveSetters(type),
          reason: 'the leaking setters: ${leakingSetters(calls)}',
        );
        expect(
          check.notBlue,
          greaterThan(0),
          reason: 'the active element paints its hover color',
        );
        expect(
          check.offSegment,
          0,
          reason:
              'the pixels off the segment from #2050c0 to $_hoverBlue '
              '(the largest distance ${check.worst})',
        );
        expect(_filledTexts(calls), containsAll(_pluginTexts));
      });
    }
  }

  testWidgets('the tooltip reaches the bitmap', (tester) async {
    // In the blue charts, the blue tooltip can lie on a blue element and
    // change no pixel. Thus this check uses a chart without a theme.
    final chart = acquireChart(_config('bar'));
    await tester.pump();
    const white = ui.Color(0xFFFFFFFF);
    final before = await chartPixelsOver(tester, chart, white);
    await _showTooltip(tester, chart);
    final after = await chartPixelsOver(tester, chart, white);
    var changed = 0;
    for (var i = 0; i + 3 < after.lengthInBytes; i += 4) {
      if (before.getUint32(i) != after.getUint32(i)) changed++;
    }
    expect(changed, greaterThan(0));
  });

  testWidgets('a bar chart without the theme paints other pixels', (
    tester,
  ) async {
    // The negative control: the default colors are not the blue.
    final chart = await _acquireWithTooltip(tester, _config('bar'));
    final pixels = await chartPixelsOver(tester, chart, const ui.Color(_blue));
    expect(offPixels(pixels, _blueRgba), greaterThan(0));
    expect(leakingSetters(drawCalls(chart)), isNotEmpty);
  });

  testWidgets('a bar chart with a blue theme without palette and the colors '
      'plugin on paints the upstream palette', (tester) async {
    // The negative control of the palette (rows theme-H4b and theme-H4c):
    // without a theme palette, the colors plugin gives the upstream
    // BORDER_COLORS and BACKGROUND_COLORS (plugin.colors.ts:14-33) to the
    // two datasets.
    final chart = await _acquireWithTooltip(
      tester,
      _config('bar', theme: _blueThemeWithoutPalette, colors: true),
    );
    final pixels = await chartPixelsOver(tester, chart, const ui.Color(_blue));
    expect(offPixels(pixels, _blueRgba), greaterThan(0));
    final leaks = {for (final (_, value) in _leaks(drawCalls(chart))) value};
    expect(
      leaks,
      containsAll(<String>[
        'setStrokeStyle rgb(54, 162, 235)',
        'setFillStyle rgba(54, 162, 235, 0.5)',
        'setStrokeStyle rgb(255, 99, 132)',
        'setFillStyle rgba(255, 99, 132, 0.5)',
      ]),
    );
  });

  testWidgets('the 16 blue charts leave defaults unchanged', (tester) async {
    // theming.md §6: a theme does not write `defaults`.
    final before = _plain(defaults);
    for (final colors in [true, false]) {
      for (final type in _chartTypes) {
        final chart = await _acquireWithTooltip(
          tester,
          _config(type, theme: _blueTheme, colors: colors),
        );
        drawCalls(chart);
      }
    }
    expect(_plain(defaults), equals(before));
  });
}
