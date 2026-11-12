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
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/color_json.dart';
import '../../support/font_record.dart';
import '../../support/light_theme.dart';
import 'light_reference.dart';

// theming.md §8 test 3, the plugin keys (Chart.js ADR 0050): the options of
// the title, subtitle, legend and tooltip plugins of a chart with the light
// preset equal the upstream options without a theme. The expected values
// are `themeLightPlugins` of light_reference.dart. The generator
// tool/reference/theme_light_reference.mjs resolves them as `pluginOpts`
// does (core.plugins.js:175-188), in Node.js v24.12.0 on x64.
//
// Each case reads the options of the plugin descriptors of a real chart
// (`chart.plugins.cache`, core.plugins.js:89-94), the resolver that each
// hook of the plugin gets. The colors compare after the parse of the ported
// @kurkle/color, as the canvas layer parses them. The fonts compare as
// `toFont` results, as the plugins read them (plugin.title.js:92,
// plugin.legend.js:136, 446, plugin.tooltip.js:152-154). Thus the title,
// tooltip title and tooltip footer fonts keep their local 'bold'
// (plugin.title.js:148-150, plugin.tooltip.js:1281-1283, 1295-1297) and the
// subtitle font its local 'normal' (plugin.subtitle.js:35-37).
//
// The reads use `jsGet`, and no resolver goes to `equals`.
//
// flutter_test_config.dart registers the plugins with the built-in
// components (Chart.js ADR 0041, section 1).

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

/// The fields of the `toFont` result [font], as the generator writes them
/// (`font_record.dart`).
Map<String, Object?> _fontFields(ChartTextStyle font) =>
    resolvedFontRecordOf(font);

/// The parsed form of the CSS color [value].
String? _parsed(Object? value) => referenceParsedColor(value).rgbString();

/// Whether the key [path] of `themeLightPlugins` is a font.
bool _isFont(String path) => themeLightPlugins[path] is Map<String, Object?>;

/// Whether the key [path] of `themeLightPlugins` is a color.
bool _isColor(String path) => !_isFont(path) && !path.contains('.box');

/// The keys of `themeLightPlugins` in [chart]: a font as its `toFont`
/// fields, else the resolved value.
Map<String, Object?> _resolve(Chart chart) => {
  for (final path in themeLightPlugins.keys)
    path: () {
      final dot = path.indexOf('.');
      final options = _pluginOptions(chart, path.substring(0, dot));
      final value = _at(options, path.substring(dot + 1));
      return _isFont(path) ? _fontFields(toFont(value)) : value;
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
  test('the plugin keys are the 19 keys of the theme spec', () {
    expect(themeLightPlugins.keys, [
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
    ]);
    expect(themeLightPlugins.keys.where(_isFont), hasLength(7));
    expect(themeLightPlugins.keys.where(_isColor), hasLength(10));
  });

  group('theming.md §8 test 3, the plugin keys', () {
    testWidgets('without a theme, the plugin options equal upstream', (
      tester,
    ) async {
      final options = _resolve(_chart(null));
      for (final MapEntry(key: path, value: upstream)
          in themeLightPlugins.entries) {
        expect(
          options[path],
          upstream is String ? referenceColorOrString(upstream) : upstream,
          reason: path,
        );
      }
    });

    testWidgets('with the light preset, the plugin options equal upstream', (
      tester,
    ) async {
      final options = _resolve(_chart(compileLightTheme()));
      for (final MapEntry(key: path, value: upstream)
          in themeLightPlugins.entries) {
        if (_isColor(path)) {
          expect(_parsed(options[path]), _parsed(upstream), reason: path);
          expect(_parsed(upstream), isNotNull, reason: path);
        } else {
          expect(
            options[path],
            upstream is String ? referenceColorOrString(upstream) : upstream,
            reason: path,
          );
        }
      }
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

    testWidgets('the light preset reaches the plugin options', (tester) async {
      // The theme strings, not the upstream strings: the theme scope gives
      // the values (hunk H2).
      final options = _resolve(_chart(compileLightTheme()));
      const gray = native_ui.Color.fromRGBO(102, 102, 102, 1);
      const white = native_ui.Color.fromRGBO(255, 255, 255, 1);
      expect(options['title.color'], gray);
      expect(options['subtitle.color'], gray);
      // plugin.legend.js:661, 707 read chart.options.color.
      expect(options['legend.labels.color'], gray);
      expect(options['legend.title.color'], gray);
      expect(
        options['tooltip.backgroundColor'],
        const native_ui.Color.fromRGBO(0, 0, 0, 0.8),
      );
      for (final key in [
        'titleColor',
        'bodyColor',
        'footerColor',
        'multiKeyBackground',
      ]) {
        expect(options['tooltip.$key'], white, reason: key);
      }
      // No token for the tooltip border (plugin.tooltip.js:1308).
      expect(
        options['tooltip.borderColor'],
        const native_ui.Color.fromRGBO(0, 0, 0, 0),
      );
    });

    testWidgets('a theme font keeps the local weights', (tester) async {
      // A theme with other tokens: the tooltip colors, and a font with a
      // weight. The weight reaches the fonts without a local weight only.
      // The tooltip boxes follow the size of the body font
      // (plugin.tooltip.js:1303-1304). A probe of the JavaScript prototype
      // of the hunks H0-H5 at the pin, with the compiled form of this theme
      // in `$theme`, gives the same colors, fonts and box sizes.
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
        const native_ui.Color.fromRGBO(0, 0, 255, 1),
      );
      expect(
        options['tooltip.bodyColor'],
        const native_ui.Color.fromRGBO(255, 255, 0, 1),
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
        const native_ui.Color.fromRGBO(102, 102, 102, 1),
      );
      expect(
        options['tooltip.borderColor'],
        const native_ui.Color.fromRGBO(0, 0, 0, 0),
      );
    });
  });
}
