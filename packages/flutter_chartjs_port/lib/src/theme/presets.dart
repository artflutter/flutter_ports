// Original code, not ported from Chart.js: the internal theme presets.

/// The internal theme presets of Chart.js ADR 0042 (theming.md §5.1), as raw
/// Map themes of `compile.dart`, a pure layer.
///
/// The public presets are `ChartThemeData.light()` and `.dark()` of
/// `theme_data.dart` (Chart.js ADR 0050). [ChartThemes] stays internal for
/// the pure tests and for the oracle of test 3:
/// `themeDataToRaw(const ChartThemeData.light())` equals [ChartThemes.light].
/// The library exports no `ChartThemes`. Ported files never import this
/// file (Chart.js ADR 0042, invariant 4).
library;

import 'package:flutter_chartjs_port/src/types/basic.dart';

/// The theme presets (theming.md §5.1).
abstract final class ChartThemes {
  /// The theme with the tokens of this list at their Chart.js v4.5.1 values
  /// (theming.md §4). It restates these values (theming.md §9):
  ///
  /// - `colors.color`: `Defaults.color` `'#666'` (`core.defaults.js:43`),
  ///   also the value of the title and subtitle color routes
  ///   (`plugin.title.js:158-160`, `plugin.subtitle.js:45-47`).
  /// - `colors.borderColor`: `Defaults.borderColor` `'rgba(0,0,0,0.1)'`
  ///   (`core.defaults.js:42`). The alpha is 0.1 exactly, not the 8-bit
  ///   alpha of `Color(0x1A000000)`.
  /// - `colors.backgroundColor`: `Defaults.backgroundColor`
  ///   `'rgba(0,0,0,0.1)'` (`core.defaults.js:41`).
  /// - `colors.surface`: the arc `borderColor` `'#fff'`
  ///   (`element.arc.ts:379`) and the tick backdrop
  ///   `'rgba(255, 255, 255, 0.75)'` (`core.scale.defaults.js:81`).
  /// - `colors.inverseSurface`: the tooltip `backgroundColor`
  ///   `'rgba(0,0,0,0.8)'` (`plugin.tooltip.js:1279`). It compiles to
  ///   `'rgba(0, 0, 0, 0.8)'`.
  /// - `colors.onInverseSurface`: the `'#fff'` of the tooltip `titleColor`,
  ///   `bodyColor`, `footerColor` and `multiKeyBackground`
  ///   (`plugin.tooltip.js:1280, 1287, 1292, 1305`).
  /// - `typography.font`: `Defaults.font` (`core.defaults.js:54-60`). Its
  ///   `weight` is `null`, which themes nothing. The title, subtitle,
  ///   tooltip title and tooltip footer fonts have no weight in the theme:
  ///   they keep their local `'bold'` (`plugin.title.js:148-150`,
  ///   `plugin.tooltip.js:1281-1283, 1295-1297`) and `'normal'`
  ///   (`plugin.subtitle.js:35-37`).
  /// - `typography.pointLabels`: the point-label size 10
  ///   (`scale.radialLinear.js:383-385`).
  /// - `palette`: the 7 colors of `BORDER_COLORS` at alpha 1
  ///   (`plugin.colors.ts:14-22`) and the alpha 0.5 of `BACKGROUND_COLORS`
  ///   (`plugin.colors.ts:25`), Chart.js ADR 0042. The compiled border
  ///   strings are `rgba(54, 162, 235, 1)`, which parse to the upstream
  ///   `rgb(54, 162, 235)`. The compiled background strings equal the
  ///   upstream strings, for example `rgba(54, 162, 235, 0.5)`.
  static const AnyObject light = <String, Object?>{
    'colors': <String, Object?>{
      'color': (alpha: 1.0, red: 102 / 255, green: 102 / 255, blue: 102 / 255),
      'borderColor': (alpha: 0.1, red: 0.0, green: 0.0, blue: 0.0),
      'backgroundColor': (alpha: 0.1, red: 0.0, green: 0.0, blue: 0.0),
      'surface': (alpha: 1.0, red: 1.0, green: 1.0, blue: 1.0),
      'inverseSurface': (alpha: 0.8, red: 0.0, green: 0.0, blue: 0.0),
      'onInverseSurface': (alpha: 1.0, red: 1.0, green: 1.0, blue: 1.0),
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
    'palette': <String, Object?>{
      'colors': <Object?>[
        (alpha: 1.0, red: 54 / 255, green: 162 / 255, blue: 235 / 255),
        (alpha: 1.0, red: 255 / 255, green: 99 / 255, blue: 132 / 255),
        (alpha: 1.0, red: 255 / 255, green: 159 / 255, blue: 64 / 255),
        (alpha: 1.0, red: 255 / 255, green: 205 / 255, blue: 86 / 255),
        (alpha: 1.0, red: 75 / 255, green: 192 / 255, blue: 192 / 255),
        (alpha: 1.0, red: 153 / 255, green: 102 / 255, blue: 255 / 255),
        (alpha: 1.0, red: 201 / 255, green: 203 / 255, blue: 207 / 255),
      ],
      'backgroundAlpha': 0.5,
    },
  };

  /// The theme that themes nothing, the raw form of `const
  /// ChartThemeData()` (Chart.js ADR 0050). It compiles to Dart `null`, a
  /// per-chart opt-out (theming.md §5.1).
  static const AnyObject none = <String, Object?>{};
}
