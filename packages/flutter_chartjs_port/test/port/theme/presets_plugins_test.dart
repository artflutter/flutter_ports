// Original code, not ported from Chart.js: the light preset and the plugins.
@TestOn('vm')
library;

import 'dart:ui' as native_ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart'
    show themeConfigKey;
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show toFont;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/font_record.dart';
import '../../support/light_theme.dart';

// The theme keys of the title, subtitle, legend and tooltip plugins
// (Chart.js ADR 0050): a compiled theme reaches the options of the plugin
// descriptors of a real chart (`chart.plugins.cache`, core.plugins.js:89-94),
// the resolver that each hook of the plugin gets. The fonts compare as
// `toFont` results, as the plugins read them (plugin.title.js:92,
// plugin.legend.js:136, 446, plugin.tooltip.js:152-154). Thus the title,
// tooltip title and tooltip footer fonts keep their local 'bold'
// (plugin.title.js:148-150, plugin.tooltip.js:1281-1283, 1295-1297) and the
// subtitle font its local 'normal' (plugin.subtitle.js:35-37).
//
// The light pixel test (light_pixels_test.dart) shows that the light preset
// paints the bytes of the unthemed chart.
//
// The reads use `jsGet`, and no resolver goes to `equals`.
//
// flutter_test_config.dart registers the plugins with the built-in
// components (Chart.js ADR 0041, section 1).

/// The 19 plugin keys of the theme spec (theming.md section 4).
const List<String> _pluginKeys = [
  'title.color',
  'title.font',
  'subtitle.color',
  'subtitle.font',
  'legend.labels.color',
  'legend.labels.font',
  'legend.title.color',
  'legend.title.font',
  'tooltip.backgroundColor',
  'tooltip.titleColor',
  'tooltip.bodyColor',
  'tooltip.footerColor',
  'tooltip.multiKeyBackground',
  'tooltip.borderColor',
  'tooltip.titleFont',
  'tooltip.bodyFont',
  'tooltip.footerFont',
  'tooltip.boxWidth',
  'tooltip.boxHeight',
];

/// The plugin options of the plugin [id] of [chart]: the options of its
/// descriptor (core.plugins.js:175-188).
Object _pluginOptions(Chart chart, String id) => chart.plugins.cache!
    .firstWhere((descriptor) => jsGet(descriptor.plugin, 'id') == id)
    .options;

/// The value of the dot path [path] in [root].
Object? _at(Object? root, String path) {
  var node = root;
  for (final key in path.split('.')) {
    node = jsGet(node, key);
  }
  return node;
}

/// Whether the key [path] of [_pluginKeys] is a font.
bool _isFont(String path) => path.endsWith('font') || path.endsWith('Font');

/// The keys of [_pluginKeys] in [chart]: a font as the fields of its
/// `toFont` result (`font_record.dart`), else the resolved value.
Map<String, Object?> _resolve(Chart chart) => {
  for (final path in _pluginKeys)
    path: () {
      final dot = path.indexOf('.');
      final options = _pluginOptions(chart, path.substring(0, dot));
      final value = _at(options, path.substring(dot + 1));
      return _isFont(path) ? resolvedFontRecordOf(toFont(value)) : value;
    }(),
};

/// A bar chart with the compiled theme [theme].
Chart _chart(Object? theme) => acquireChart(<String, Object?>{
  'type': 'bar',
  'data': <String, Object?>{
    'labels': <Object?>['a', 'b'],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'd',
        'data': <Object?>[1.0, 2.0],
      },
    ],
  },
  'options': <String, Object?>{},
  themeConfigKey: ?theme,
});

void main() {
  test('the plugin keys have 7 fonts', () {
    expect(_pluginKeys.where(_isFont), hasLength(7));
  });

  group('the theme reaches the plugin options', () {
    testWidgets('the light preset reaches the plugin options', (tester) async {
      // The theme values, not the upstream strings: the theme scope gives
      // the values (hunk H2).
      final options = _resolve(_chart(compileLightTheme()));
      const gray = native_ui.Color.fromRGBO(102, 102, 102, 1);
      const white = native_ui.Color.fromRGBO(255, 255, 255, 1);
      expect(options['title.color'], const ChartPaint.solid(gray));
      expect(options['subtitle.color'], const ChartPaint.solid(gray));
      // plugin.legend.js:661, 707 read chart.options.color.
      expect(options['legend.labels.color'], const ChartPaint.solid(gray));
      expect(options['legend.title.color'], const ChartPaint.solid(gray));
      expect(
        options['tooltip.backgroundColor'],
        const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 0, 0.8)),
      );
      for (final key in [
        'titleColor',
        'bodyColor',
        'footerColor',
        'multiKeyBackground',
      ]) {
        expect(
          options['tooltip.$key'],
          const ChartPaint.solid(white),
          reason: key,
        );
      }
      // No token for the tooltip border (plugin.tooltip.js:1308).
      expect(
        options['tooltip.borderColor'],
        const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 0, 0)),
      );
      // The local weights stay (theming.md §3.4). A weight is the value of
      // a FontWeight (font_record.dart).
      Object? weight(String path) =>
          (options[path]! as Map<String, Object?>)['weight'];
      expect(weight('title.font'), 700);
      expect(weight('tooltip.titleFont'), 700);
      expect(weight('tooltip.footerFont'), 700);
      expect(weight('subtitle.font'), 400);
      expect(weight('tooltip.bodyFont'), isNull);
      expect(weight('legend.labels.font'), isNull);
      expect(weight('legend.title.font'), isNull);
    });

    testWidgets('a theme font keeps the local weights', (tester) async {
      // A theme with other tokens: the tooltip colors, and a font with a
      // weight. The weight reaches the fonts without a local weight only.
      // The tooltip boxes follow the size of the body font
      // (plugin.tooltip.js:1303-1304).
      final options = _resolve(
        _chart(
          compileChartTheme(
            inverseSurface: const native_ui.Color.fromRGBO(0, 0, 255, 1),
            onInverseSurface: const native_ui.Color.fromRGBO(255, 255, 0, 1),
            font: const ChartTextStyle(
              fontFamily: 'serif',
              fontFamilyFallback: [],
              fontSize: 14,
              fontWeight: native_ui.FontWeight.w300,
            ),
          ),
        ),
      );
      expect(
        options['tooltip.backgroundColor'],
        const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 255, 1)),
      );
      expect(
        options['tooltip.bodyColor'],
        const ChartPaint.solid(native_ui.Color.fromRGBO(255, 255, 0, 1)),
      );
      // A weight is the value of a FontWeight (font_record.dart).
      for (final (path, weight) in [
        ('title.font', 700),
        ('subtitle.font', 400),
        ('legend.labels.font', 300),
        ('legend.title.font', 300),
        ('tooltip.titleFont', 700),
        ('tooltip.bodyFont', 300),
        ('tooltip.footerFont', 700),
      ]) {
        final font = options[path]! as Map<String, Object?>;
        expect(font['family'], 'serif', reason: path);
        expect(font['size'], 14.0, reason: path);
        expect(font['weight'], weight, reason: path);
      }
      expect(options['tooltip.boxWidth'], 14.0);
      expect(options['tooltip.boxHeight'], 14.0);
      // The upstream colors without a token stay.
      expect(
        options['title.color'],
        const ChartPaint.solid(native_ui.Color.fromRGBO(102, 102, 102, 1)),
      );
      expect(
        options['tooltip.borderColor'],
        const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 0, 0)),
      );
    });
  });
}
