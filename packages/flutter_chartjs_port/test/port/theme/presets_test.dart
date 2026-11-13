// Original code, not ported from Chart.js: tests of the theme presets.
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.typedRegistry.dart';
import 'package:flutter_chartjs_port/src/elements/element.arc.dart';
import 'package:flutter_chartjs_port/src/elements/element.bar.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show toFont;
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
import 'package:test/test.dart';

import '../../support/color_json.dart';
import '../../support/font_record.dart';
import '../../support/light_theme.dart';
import 'light_reference.dart';

// theming.md §8 test 3, the parts of phases 5 and 6, and the values that
// the light preset restates: the light preset equals upstream for
// core.defaults, the four elements, core.scale.defaults and the keys of
// scales.radialLinear, and each emitted key restates its upstream value,
// also the plugin keys and the palette of phase 8. The expected values are in
// light_reference.dart. The generator tool/reference/theme_light_reference.mjs
// runs the pinned upstream sources in Node.js v24.22.1 on arm64, with the
// four elements, the radial linear scale and five plugins registered, and
// without a theme.
//
// main() registers the four element classes through a new TypedRegistry
// (core.typedRegistry.js:24-53, Chart.js ADR 0022, section 8), before the
// snapshot of the restore. The scales and the plugins are not pure layers.
// Thus the radial linear scale case is in presets_radial_test.dart, and the
// resolved options of the title, subtitle, legend and tooltip plugins are in
// presets_plugins_test.dart. Both run on the VM only. The 8 chart types with
// their controllers and the light palette are in precedence_test.dart (test
// 3: the light palette).

/// The parsed form of the CSS color [value]: the `rgbString` of the ported
/// @kurkle/color, as the canvas layer parses a color.
String? _parsed(Object? value) => referenceParsedColor(value).rgbString();

/// Whether [key] names a color option.
bool _isColorKey(String key) => key.endsWith('Color');

/// The value of the dot path [path] in [root].
Object? _at(Object? root, String path) {
  var node = root;
  for (final key in path.split('.')) {
    node = jsGet(node, key);
  }
  return node;
}

/// The leaves of [value] by dot path. A List is a leaf.
Map<String, Object?> _leaves(Object? value, [String prefix = '']) {
  if (!_isObject(value)) return {prefix: value};
  return {
    for (final key in jsObjectKeys(value))
      ..._leaves(jsGet(value, key), prefix.isEmpty ? key : '$prefix.$key'),
  };
}

/// Whether [value] is an object of a compiled theme: a Map, or a typed scope
/// with its face (Chart.js ADR 0054 §5).
bool _isObject(Object? value) =>
    value is Map<String, Object?> || value is JsObjectFace;

/// The fields of the `toFont` result [font], as the generator writes them
/// (`font_record.dart`).
Map<String, Object?> _fontFields(ChartTextStyle font) =>
    resolvedFontRecordOf(font);

/// A configuration of the chart type `tthm` with one dataset, the user
/// options [options] and the theme [theme].
Config _config(Object? theme, [Map<String, Object?>? options]) =>
    Config(<String, Object?>{
      'type': 'tthm',
      'data': <String, Object?>{
        'datasets': [
          <String, Object?>{'data': <Object?>[]},
        ],
      },
      'options': options ?? <String, Object?>{},
      themeConfigKey: theme,
    });

/// The options of [elementCase], resolved as the generator resolves them,
/// with the theme [theme].
Map<String, Object?> _resolveElement(
  ThemeLightElementCase elementCase,
  Object? theme,
) {
  final config = _config(theme);
  final dataset = (jsGet(config.data, 'datasets')! as List<Object?>).first;
  final scopes = config.getOptionScopes(
    dataset,
    config.datasetElementScopeKeys('tthm', elementCase.type),
  );
  final active = elementCase.mode == 'active';
  return config.resolveNamedOptions(
    scopes,
    elementCase.names,
    () => <String, Object?>{'active': active, 'mode': elementCase.mode},
    elementCase.prefixes,
  ) as Map<String, Object?>;
}

/// The options of the scale `x` of the type `tlin`, by the keys of
/// [themeLightScale], with the theme [theme].
Map<String, Object?> _resolveScale(Object? theme) {
  final config = _config(theme, <String, Object?>{
    'scales': <String, Object?>{
      'x': <String, Object?>{'type': 'tlin'},
    },
  });
  final chartOptions = config.createResolver(
    config.chartOptionScopes(),
    <String, Object?>{'chart': <String, Object?>{}},
  );
  final x = _at(chartOptions, 'scales.x');
  return {
    for (final key in themeLightScale.keys)
      key: switch (key) {
        'ticks.font' => _fontFields(toFont(_at(x, key))),
        'title.font' => _fontFields(
          toFont(_at(x, key), _at(chartOptions, 'font')),
        ),
        _ => _at(x, key),
      },
  };
}

void main() {
  setUpSpecs();

  [
    ArcElement.jsClass,
    BarElement.jsClass,
    LineElement.jsClass,
    PointElement.jsClass,
  ].forEach(TypedRegistry(Element.jsClass, 'elements').register);

  test('the reference comes from Node.js v24.22.1 on arm64', () {
    expect(themeLightReferenceNode, 'v24.22.1');
    expect(themeLightReferenceArch, 'arm64');
  });

  group('theming.md §8 test 3, the parts of phases 5 and 6', () {
    test('the light preset restates the upstream values', () {
      // theming.md §9: the values that the preset restates.
      final compiled = compileLightTheme()!;
      final emitted = {
        for (final path in compiled.jsKeys())
          if (path != 'transitions') path,
      };
      final keys = <String>{};
      for (final path in themeLightRestated.keys) {
        keys.add(path);
        final value = _at(compiled, path);
        final upstream = themeLightRestated[path];
        if (upstream is Map<String, Object?>) {
          // A font: its record (font_record.dart).
          expect(value, isA<TextStyle>(), reason: path);
          expect(
            fontObjectRecordOf(value! as TextStyle),
            upstream,
            reason: path,
          );
        } else if (upstream is List<Object?>) {
          // A palette: the colors after the parse (plugin.colors.ts:14-25).
          expect(value, isA<List<Object?>>(), reason: path);
          expect(
            [for (final color in value! as List<Object?>) _parsed(color)],
            [for (final color in upstream) _parsed(color)],
            reason: path,
          );
          expect(upstream.map(_parsed), everyElement(isNotNull));
        } else {
          expect(_parsed(value), _parsed(upstream), reason: path);
          expect(_parsed(value), isNotNull, reason: path);
        }
      }
      // The preset emits these keys and no other key. A font is one leaf, a
      // TextStyle (Chart.js ADR 0116).
      final leafPaths = _leaves(compiled).keys
          .where((path) => !path.startsWith('transitions'))
          .toSet();
      expect(leafPaths, keys);
      expect(emitted, {'color', 'scale', 'scales', 'plugins', 'elements'});
    });

    test('the element options equal upstream in both modes', () {
      final theme = compileLightTheme();
      for (final elementCase in themeLightElements) {
        final reason = '${elementCase.type} ${elementCase.mode}';
        final upstream = elementCase.options;
        final themed = _resolveElement(elementCase, theme);
        expect(jsObjectKeys(themed), jsObjectKeys(upstream), reason: reason);
        for (final key in upstream.keys) {
          final value = themed[key];
          if (_isColorKey(key)) {
            expect(
              _parsed(value),
              _parsed(upstream[key]),
              reason: '$reason $key',
            );
            if (elementCase.mode == 'active') {
              // The hover colors of the defaults derive from the themed base
              // color (core.defaults.js:62-64): equal hex strings.
              expect(
                value,
                upstream[key] is String
                    ? referenceColorOrString(upstream[key]! as String)
                    : upstream[key],
                reason: '$reason $key',
              );
            }
          } else if (identical(upstream[key], undefined)) {
            expect(value, same(undefined), reason: '$reason $key');
          } else {
            expect(
              value,
              upstream[key] is String
                  ? referenceColorOrString(upstream[key]! as String)
                  : upstream[key],
              reason: '$reason $key',
            );
          }
        }
      }
    });

    test('without a theme, the element options equal upstream exactly', () {
      for (final elementCase in themeLightElements) {
        final options = _resolveElement(elementCase, null);
        expect(jsObjectKeys(options), jsObjectKeys(elementCase.options));
        for (final key in elementCase.options.keys) {
          final upstream = elementCase.options[key];
          expect(
            options[key],
            identical(upstream, undefined)
                ? same(undefined)
                : upstream is String
                ? referenceColorOrString(upstream)
                : upstream,
            reason: '${elementCase.type} ${elementCase.mode} $key',
          );
        }
      }
    });

    test('the scale options equal upstream', () {
      final themed = _resolveScale(compileLightTheme());
      final plain = _resolveScale(null);
      for (final key in themeLightScale.keys) {
        final upstream = themeLightScale[key];
        if (upstream is Map<String, Object?>) {
          expect(themed[key], upstream, reason: key);
        } else {
          expect(_parsed(themed[key]), _parsed(upstream), reason: key);
        }
        expect(
          plain[key],
          upstream is String ? referenceColorOrString(upstream) : upstream,
          reason: key,
        );
      }
    });

    test('the chart-level color equals upstream', () {
      Object? color(Object? theme) {
        final config = _config(theme);
        return config.createResolver(
          config.chartOptionScopes(),
          <String, Object?>{},
        )['color'];
      }

      final themed = color(compileLightTheme());
      expect(
        themed,
        const ChartPaint.solid(ui.Color.fromRGBO(102, 102, 102, 1)),
      );
      expect(_parsed(themed), _parsed(themeLightChartColor));
      expect(color(null), referenceColorOrString(themeLightChartColor));
    });

    test('the 8-bit alpha of Color(0x1A000000) gives another hover color', () {
      // theming.md §4: the preset keeps the alpha 0.1 exactly.
      final theme = compileChartTheme(
        backgroundColor: const ui.Color.fromRGBO(0, 0, 0, 26 / 255),
      );
      final pointActive = themeLightElements.firstWhere(
        (c) => c.type == 'point' && c.mode == 'active',
      );
      expect(
        pointActive.options['backgroundColor'],
        '#00000019',
      );
      expect(
        _resolveElement(pointActive, theme)['backgroundColor'],
        const ChartPaint.solid(ui.Color.fromRGBO(0, 0, 0, 26 / 255)),
      );
    });
  });
}
