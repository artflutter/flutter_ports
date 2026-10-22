// Original code, not ported from Chart.js: radial tests of the light preset.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/core/core.typedRegistry.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ParsedFont, toFont;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/color.dart' show Color;
import 'package:flutter_chartjs_port/src/scales/scale.radialLinear.dart';
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/theme/presets.dart';
import 'package:test/test.dart';

import 'light_reference.dart';

// theming.md §8 test 3, the radial linear scale case of phase 6: the light
// preset equals upstream for the options of a radial linear scale. The
// expected values are themeLightRadial of light_reference.dart. The
// generator tool/reference/theme_light_reference.mjs resolves the scale `r`
// of the type `radialLinear` through `chartOptionScopes` in Node.js v24.12.0
// on x64, with the radial linear scale registered, and without a theme.
//
// The scales import core.scale, which is not a pure layer. Thus this file
// runs on the VM only, and presets_test.dart keeps the other cases of test 3
// on the VM, dart2js and dart2wasm. main() calls setUpSpecs() and then
// registers the radial linear scale through a new TypedRegistry
// (core.typedRegistry.js:24-53, Chart.js ADR 0022, section 8), before the
// snapshot of the restore.

/// The parsed form of the CSS color [value]: the `rgbString` of the ported
/// @kurkle/color, as the canvas layer parses a color.
String? _parsed(Object? value) => Color(value).rgbString();

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

/// The options of the scale `r` of the type `radialLinear`, by the keys of
/// [themeLightRadial], with the theme [theme].
Map<String, Object?> _resolveRadial(Object? theme) {
  final config = Config(<String, Object?>{
    'type': 'tthm',
    'data': <String, Object?>{
      'datasets': [
        <String, Object?>{'data': <Object?>[]},
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'r': <String, Object?>{'type': 'radialLinear'},
      },
    },
    themeConfigKey: theme,
  });
  final chartOptions = config.createResolver(
    config.chartOptionScopes(),
    <String, Object?>{'chart': <String, Object?>{}},
  );
  final r = _at(chartOptions, 'scales.r');
  return {
    for (final key in themeLightRadial.keys)
      key: key.endsWith('.font')
          ? _fontFields(toFont(_at(r, key)))
          : _at(r, key),
  };
}

void main() {
  setUpSpecs();

  TypedRegistry(Scale.jsClass, 'scales').register(RadialLinearScale.jsClass);

  test('the reference comes from Node.js v24.12.0 on x64', () {
    expect(themeLightReferenceNode, 'v24.12.0');
    expect(themeLightReferenceArch, 'x64');
  });

  group('theming.md §8 test 3, the radial linear scale', () {
    test('the radial options equal upstream with the light preset', () {
      final themed = _resolveRadial(compileChartTheme(ChartThemes.light));
      for (final MapEntry(:key, value: upstream) in themeLightRadial.entries) {
        if (upstream is Map<String, Object?>) {
          // A font: the same fields, the size 10 of
          // scale.radialLinear.js:383-385 included.
          expect(themed[key], upstream, reason: key);
        } else if (identical(upstream, undefined)) {
          expect(themed[key], same(undefined), reason: key);
        } else {
          expect(_parsed(themed[key]), _parsed(upstream), reason: key);
          expect(_parsed(themed[key]), isNotNull, reason: key);
        }
      }
    });

    test('without a theme, the radial options equal upstream exactly', () {
      final plain = _resolveRadial(null);
      for (final MapEntry(:key, value: upstream) in themeLightRadial.entries) {
        expect(
          plain[key],
          identical(upstream, undefined) ? same(undefined) : upstream,
          reason: key,
        );
      }
    });

    test('the light preset themes the radial keys', () {
      // The preset values come from the theme scope, not from the routes of
      // scale.radialLinear.js:400-404: the strings are the rgba() form of
      // the compiler (theming.md §3.3).
      final themed = _resolveRadial(compileChartTheme(ChartThemes.light));
      expect(themed['pointLabels.color'], 'rgba(102, 102, 102, 1)');
      expect(themed['angleLines.color'], 'rgba(0, 0, 0, 0.1)');
      expect(themed['ticks.color'], 'rgba(102, 102, 102, 1)');
    });
  });
}
