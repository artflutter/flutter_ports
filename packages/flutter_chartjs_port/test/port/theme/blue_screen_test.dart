// Original code, not ported from Chart.js: theming.md §8 test 6, no plugins.
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
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/color.dart' as kurkle;
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart' show drawCalls;

// theming.md §8 test 6 without plugins (Chart.js ADR 0030, section 11): a
// theme that sets each color token to one blue, over a background of the
// same blue, gives a bitmap with no other pixel. A pixel of another color
// shows a color that the theme does not reach (a leak).
//
// Phase 7 registers no plugin. Thus the colors plugin, the legend, the
// title and the tooltip are off. The case with an active element waits for
// `IdentityChartHover` (theming.md §8 item 6).
//
// The read is the paint call of the chart host (chart_host.dart:707,
// `_paintCanvas`): `UiCanvasContext.paint` of the chart canvas into a
// `ui.PictureRecorder` over an opaque rectangle of the blue. Each pixel must
// be exactly `20 50 c0 ff`. No tolerance and no golden file. On a failure,
// the reason lists each style setter of the draw calls (with the element
// draws, Chart.js ADR 0030, section 1) whose value does not parse to the
// blue or to alpha 0.

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

/// A raw Map theme that sets each color token of compile.dart to [_blue]:
/// `color`, `borderColor`, `backgroundColor` and `surface` (theming.md §4).
const AnyObject _blueTheme = <String, Object?>{
  'colors': <String, Object?>{
    'color': _blueColor,
    'borderColor': _blueColor,
    'backgroundColor': _blueColor,
    'surface': _blueColor,
  },
};

/// The key that the token `surface` emits at alpha 0.75 (compile.dart,
/// `_backdropKey`): the scale tick backdrop.
const String _backdropPath = 'scale.ticks.backdropColor';

/// The known leaks of phase 7: chart type to the leaking setter values
/// (`<setter> <value>`), each with its upstream file:line. Empty in phase 7.
/// The test fails when a set changes in either direction.
const Map<String, Set<String>> knownLeaks = {};

/// The 8 chart types of phase 7, in code unit order.
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

/// The configuration of the chart of the type [type]: 2 datasets, labels,
/// the scale titles on for the cartesian types, the point labels and the
/// angle lines on for the radial types, and borders on bars and arcs. With
/// [theme], the configuration has `themeConfigKey: compileChartTheme(theme)`.
AnyObject _config(String type, {AnyObject? theme}) {
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

/// The bytes of the bitmap of [chart] over an opaque [background], as the
/// chart host paints it (chart_host.dart:707).
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

/// The leaking style setters of the draw calls of [chart]: the call index
/// and the value `<setter> <value>`.
List<(int, String)> _leaks(Chart chart) {
  final calls = drawCalls(chart);
  return [
    for (var i = 0; i < calls.length; i++)
      if (calls[i]
          case {
            'name': final String name,
            'args': [final Object? value, ...],
          }
          when _styleSetters.contains(name) && !_keepsBlue(value))
        (i, '$name $value'),
  ];
}

/// The style setters of the draw calls of [chart] whose value does not
/// parse to [_blue] or to alpha 0, with the call index.
List<String> leakingSetters(Chart chart) => [
  for (final (index, value) in _leaks(chart)) '#$index $value',
];

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
/// a key that is `color` or ends in `Color`.
Iterable<(String, Object?)> _themeColors(Object? node, [String path = '']) =>
    switch (node) {
      final Map<String, Object?> map => [
        for (final MapEntry(:key, :value) in map.entries)
          if (key == 'color' || key.endsWith('Color'))
            ('$path$key', value)
          else
            ..._themeColors(value, '$path$key.'),
      ],
      _ => const [],
    };

void main() {
  test('the compiled blue theme emits each color as the blue', () {
    final colors = _themeColors(compileChartTheme(_blueTheme)).toList();
    expect(colors, isNotEmpty);
    for (final (path, value) in colors) {
      expect(value, isA<String>(), reason: path);
      final rgb = kurkle.Color(value).rgb;
      expect(rgb, isNotNull, reason: path);
      expect([rgb!.r, rgb.g, rgb.b], [32, 80, 192], reason: path);
      // The token `surface` gives the tick backdrop at alpha 0.75.
      expect(rgb.a, path == _backdropPath ? 0.75 : 1, reason: path);
    }
    expect(
      colors.map((c) => c.$1),
      contains(_backdropPath),
      reason: 'the token surface emits the tick backdrop',
    );
  });

  for (final type in _chartTypes) {
    testWidgets('a $type chart with the blue theme paints only the blue', (
      tester,
    ) async {
      final chart = acquireChart(_config(type, theme: _blueTheme));
      await tester.pump();
      expect(chart.getActiveElements(), isEmpty);
      final pixels = await chartPixelsOver(
        tester,
        chart,
        const ui.Color(_blue),
      );
      final off = offPixels(pixels, _blueRgba);
      final leaks = _leaks(chart);
      final known = knownLeaks[type] ?? const <String>{};
      expect(
        {for (final (_, value) in leaks) value},
        known,
        reason: 'the leaking setters: ${leakingSetters(chart)}',
      );
      if (known.isEmpty) {
        expect(
          off,
          0,
          reason:
              'the pixels that are not #2050c0; '
              'the leaking setters: ${leakingSetters(chart)}',
        );
      }
      // The chart paints: over white, its blue pixels differ.
      final overWhite = await chartPixelsOver(
        tester,
        chart,
        const ui.Color(0xFFFFFFFF),
      );
      expect(offPixels(overWhite, 0xFFFFFFFF), greaterThan(0));
    });
  }

  testWidgets('a bar chart without the theme paints other pixels', (
    tester,
  ) async {
    // The negative control: the default colors are not the blue.
    final chart = acquireChart(_config('bar'));
    await tester.pump();
    final pixels = await chartPixelsOver(tester, chart, const ui.Color(_blue));
    expect(offPixels(pixels, _blueRgba), greaterThan(0));
    expect(leakingSetters(chart), isNotEmpty);
  });

  testWidgets('the 8 blue charts leave defaults unchanged', (tester) async {
    // theming.md §6: a theme does not write `defaults`.
    final before = _plain(defaults);
    for (final type in _chartTypes) {
      final chart = acquireChart(_config(type, theme: _blueTheme));
      await tester.pump();
      drawCalls(chart);
    }
    expect(_plain(defaults), equals(before));
  });
}
