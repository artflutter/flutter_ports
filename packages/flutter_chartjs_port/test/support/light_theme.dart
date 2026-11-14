// Original code, not ported from Chart.js: the light preset of the tests.

/// The compiled light preset of the tests: `compileChartTheme` of
/// `compile.dart` with the tokens of `LightThemeTokens` (Chart.js ADR
/// 0147 §11), as `compileThemeData(const ChartThemeData.light())` gives it.
/// A pure layer, for the tests of the web legs too.
library;

import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show ChartOptionsScope;
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/theme/presets.dart';

/// The compiled light preset: a new frozen scope at each call.
ChartOptionsScope? compileLightTheme() => compileChartTheme(
  color: LightThemeTokens.color,
  borderColor: LightThemeTokens.borderColor,
  backgroundColor: LightThemeTokens.backgroundColor,
  surface: LightThemeTokens.surface,
  inverseSurface: LightThemeTokens.inverseSurface,
  onInverseSurface: LightThemeTokens.onInverseSurface,
  font: LightThemeTokens.font,
  pointLabelsFont: LightThemeTokens.pointLabelsFont,
  palette: LightThemeTokens.palette,
  // LightThemeTokens.paletteBackgroundAlpha is the default 0.5.
);
