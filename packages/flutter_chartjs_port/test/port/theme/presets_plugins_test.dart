// Original code, not ported from Chart.js: the light preset and the plugins.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart'
    show themeConfigKey;
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ParsedFont, toFont;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/color.dart' show Color;
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/theme/presets.dart';
import 'package:flutter_test/flutter_test.dart';

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

/// The fields of the `toFont` result [font], as the generator writes them.
Map<String, Object?> _fontFields(ParsedFont font) => {
  'family': font.family,
  'lineHeight': font.lineHeight,
  'size': font.size,
  'style': font.style,
  'weight': font.weight,
  'string': font.string,
};

/// The parsed form of the CSS color [value].
String? _parsed(Object? value) => Color(value).rgbString();

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
        expect(options[path], upstream, reason: path);
      }
    });

    testWidgets('with the light preset, the plugin options equal upstream', (
      tester,
    ) async {
      final options = _resolve(_chart(compileChartTheme(ChartThemes.light)));
      for (final MapEntry(key: path, value: upstream)
          in themeLightPlugins.entries) {
        if (_isColor(path)) {
          expect(_parsed(options[path]), _parsed(upstream), reason: path);
          expect(_parsed(upstream), isNotNull, reason: path);
        } else {
          expect(options[path], upstream, reason: path);
        }
      }
      // The local weights stay (theming.md §3.4).
      Object? weight(String path) =>
          (options[path]! as Map<String, Object?>)['weight'];
      expect(weight('title.font'), 'bold');
      expect(weight('tooltip.titleFont'), 'bold');
      expect(weight('tooltip.footerFont'), 'bold');
      expect(weight('subtitle.font'), 'normal');
      expect(weight('tooltip.bodyFont'), isNull);
      expect(weight('legend.labels.font'), isNull);
      expect(weight('legend.title.font'), isNull);
    });

    testWidgets('the light preset reaches the plugin options', (tester) async {
      // The theme strings, not the upstream strings: the theme scope gives
      // the values (hunk H2).
      final options = _resolve(_chart(compileChartTheme(ChartThemes.light)));
      const gray = 'rgba(102, 102, 102, 1)';
      const white = 'rgba(255, 255, 255, 1)';
      expect(options['title.color'], gray);
      expect(options['subtitle.color'], gray);
      // plugin.legend.js:661, 707 read chart.options.color.
      expect(options['legend.labels.color'], gray);
      expect(options['legend.title.color'], gray);
      expect(options['tooltip.backgroundColor'], 'rgba(0, 0, 0, 0.8)');
      for (final key in [
        'titleColor',
        'bodyColor',
        'footerColor',
        'multiKeyBackground',
      ]) {
        expect(options['tooltip.$key'], white, reason: key);
      }
      // No token for the tooltip border (plugin.tooltip.js:1308).
      expect(options['tooltip.borderColor'], 'rgba(0,0,0,0)');
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
          compileChartTheme({
            'colors': <String, Object?>{
              'inverseSurface': (alpha: 1.0, red: 0.0, green: 0.0, blue: 1.0),
              'onInverseSurface': (
                alpha: 1.0,
                red: 1.0,
                green: 1.0,
                blue: 0.0,
              ),
            },
            'typography': <String, Object?>{
              'font': <String, Object?>{
                'family': 'serif',
                'size': 14.0,
                'weight': 'lighter',
              },
            },
          }),
        ),
      );
      expect(options['tooltip.backgroundColor'], 'rgba(0, 0, 255, 1)');
      expect(options['tooltip.bodyColor'], 'rgba(255, 255, 0, 1)');
      for (final (path, weight) in [
        ('title.font', 'bold'),
        ('subtitle.font', 'normal'),
        ('legend.labels.font', 'lighter'),
        ('legend.title.font', 'lighter'),
        ('tooltip.titleFont', 'bold'),
        ('tooltip.bodyFont', 'lighter'),
        ('tooltip.footerFont', 'bold'),
      ]) {
        final font = options[path]! as Map<String, Object?>;
        expect(font['family'], 'serif', reason: path);
        expect(font['size'], 14.0, reason: path);
        expect(font['weight'], weight, reason: path);
      }
      expect(options['tooltip.boxWidth'], 14.0);
      expect(options['tooltip.boxHeight'], 14.0);
      // The upstream colors without a token stay.
      expect(options['title.color'], '#666');
      expect(options['tooltip.borderColor'], 'rgba(0,0,0,0)');
    });
  });
}
