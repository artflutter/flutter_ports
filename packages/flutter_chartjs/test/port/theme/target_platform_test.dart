// Original code, not ported from Chart.js: the theme and the target platform.
@TestOn('vm')
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_chartjs/src/core/core.config.dart';
import 'package:flutter_chartjs/src/theme/compile.dart';
import 'package:flutter_chartjs/src/theme/presets.dart';
import 'package:flutter_test/flutter_test.dart';

// theming.md §8 test 1: the theme does not depend on TargetPlatform.
// flutter_test reports TargetPlatform.android on each host (theming.md §2).
// The compiler is a pure layer (tool 1), so it cannot read the platform.
// This test checks the result under each platform of Flutter. The file
// imports flutter_test, so it runs on the VM only. compile_test.dart checks
// the same leaves on the VM, dart2js and dart2wasm.

/// A new copy of the raw theme [theme], Map by Map. The memo of
/// [compileChartTheme] keeps the instance, so each copy compiles again.
Map<String, Object?> _copy(Map<String, Object?> theme) => {
  for (final MapEntry(:key, :value) in theme.entries)
    key: value is Map<String, Object?> ? _copy(value) : value,
};

/// The leaves of [value] by dot path. A List is a leaf.
Map<String, Object?> _leaves(Object? value, [String prefix = '']) {
  if (value is! Map<String, Object?>) return {prefix: value};
  return {
    for (final key in value.keys)
      ..._leaves(value[key], prefix.isEmpty ? key : '$prefix.$key'),
  };
}

void main() {
  test('the compiled light preset is the same on each target platform', () {
    final expected = _leaves(compileChartTheme(_copy(ChartThemes.light)));
    expect(expected, isNotEmpty);
    for (final platform in TargetPlatform.values) {
      debugDefaultTargetPlatformOverride = platform;
      try {
        expect(defaultTargetPlatform, platform);
        final compiled = compileChartTheme(_copy(ChartThemes.light));
        expect(_leaves(compiled), expected, reason: '$platform');
        expect(compileChartTheme(_copy(ChartThemes.none)), isNull);
        final config = Config(<String, Object?>{
          'type': 'tthm',
          themeConfigKey: compiled,
        });
        expect(
          config.createResolver(
            config.chartOptionScopes(),
            <String, Object?>{},
          )['color'],
          'rgba(102, 102, 102, 1)',
          reason: '$platform',
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    }
  });
}
