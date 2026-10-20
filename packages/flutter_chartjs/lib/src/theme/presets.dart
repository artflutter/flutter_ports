// Original code, not ported from Chart.js: the internal theme presets.

/// The internal theme presets of Chart.js ADR 0001 (theming.md §5.1), as raw
/// Map themes of `compile.dart`, a pure layer.
///
/// The public presets come with the theme classes in phase 9. Ported files
/// never import this file (Chart.js ADR 0001, invariant 4).
library;

import 'package:flutter_chartjs/src/types/basic.dart';

/// The theme presets (theming.md §5.1).
abstract final class ChartThemes {
  /// The theme with every token of phase 6 at its Chart.js v4.5.1 value
  /// (theming.md §4). It restates these values (theming.md §9):
  ///
  /// - `colors.color`: `Defaults.color` `'#666'` (`core.defaults.js:43`).
  /// - `colors.borderColor`: `Defaults.borderColor` `'rgba(0,0,0,0.1)'`
  ///   (`core.defaults.js:42`). The alpha is 0.1 exactly, not the 8-bit
  ///   alpha of `Color(0x1A000000)`.
  /// - `colors.backgroundColor`: `Defaults.backgroundColor`
  ///   `'rgba(0,0,0,0.1)'` (`core.defaults.js:41`).
  /// - `colors.surface`: the arc `borderColor` `'#fff'`
  ///   (`element.arc.ts:379`) and the tick backdrop
  ///   `'rgba(255, 255, 255, 0.75)'` (`core.scale.defaults.js:81`).
  /// - `typography.font`: `Defaults.font` (`core.defaults.js:54-60`). Its
  ///   `weight` is `null`, which themes nothing.
  /// - `typography.pointLabels`: the point-label size 10
  ///   (`scale.radialLinear.js:383-385`).
  ///
  /// The tokens of the plugins (`colors.inverseSurface`,
  /// `colors.onInverseSurface` and the palette) come in phase 8.
  static const AnyObject light = <String, Object?>{
    'colors': <String, Object?>{
      'color': (alpha: 1.0, red: 102 / 255, green: 102 / 255, blue: 102 / 255),
      'borderColor': (alpha: 0.1, red: 0.0, green: 0.0, blue: 0.0),
      'backgroundColor': (alpha: 0.1, red: 0.0, green: 0.0, blue: 0.0),
      'surface': (alpha: 1.0, red: 1.0, green: 1.0, blue: 1.0),
    },
    'typography': <String, Object?>{
      'font': <String, Object?>{
        'family': "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
        'size': 12.0,
        'style': 'normal',
        'lineHeight': 1.2,
      },
      'pointLabels': <String, Object?>{'size': 10.0},
    },
  };

  /// The theme that themes nothing: `const ChartThemeData()` of phase 9. It
  /// compiles to Dart `null`, a per-chart opt-out (theming.md §5.1).
  static const AnyObject none = <String, Object?>{};
}
