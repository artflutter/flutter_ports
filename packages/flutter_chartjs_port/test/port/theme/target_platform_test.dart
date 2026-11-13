// Original code, not ported from Chart.js: the theme and the target platform.
@TestOn('vm')
library;

import 'dart:ui' as native_ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/types/axis_border.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:flutter_test/flutter_test.dart';

import '../../support/light_theme.dart';
import '../../support/scale_border.dart';

// theming.md §8 test 1: the theme does not depend on TargetPlatform.
// flutter_test reports TargetPlatform.android on each host (theming.md §2).
// The compiler is a pure layer (tool 1), so it cannot read the platform.
// This test checks the result under each platform of Flutter. The file
// imports flutter_test, so it runs on the VM only. compile_test.dart checks
// the same leaves on the VM, dart2js and dart2wasm.

/// The leaves of [value] by dot path. A List is a leaf.
Map<String, Object?> _leaves(Object? value, [String prefix = '']) {
  // A border gives its fields (row adapt-native-scale-border).
  if (value is ScaleBorder) return borderLeaves(prefix, value);
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

void main() {
  test('the compiled light preset is the same on each target platform', () {
    final expected = _leaves(compileLightTheme());
    expect(expected, isNotEmpty);
    for (final platform in TargetPlatform.values) {
      debugDefaultTargetPlatformOverride = platform;
      try {
        expect(defaultTargetPlatform, platform);
        final compiled = compileLightTheme();
        expect(_leaves(compiled), expected, reason: '$platform');
        expect(compileChartTheme(), isNull);
        final config = Config(<String, Object?>{
          'type': 'tthm',
          themeConfigKey: compiled,
        });
        expect(
          config.createResolver(
            config.chartOptionScopes(),
            <String, Object?>{},
          )['color'],
          const ChartPaint.solid(native_ui.Color.fromRGBO(102, 102, 102, 1)),
          reason: '$platform',
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    }
  });
}
