// Original code, not ported from Chart.js: ChartTheme of Chart.js ADR 0050.

/// The inherited chart theme of Chart.js ADR 0050 (theming.md §5.1).
///
/// Not a pure layer: the file imports the widgets library. Ported files never
/// import it (Chart.js ADR 0050, invariant 4).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/src/theme/theme_data.dart';

/// The chart theme of a subtree (Chart.js ADR 0050).
///
/// A chart below reads [maybeOf]: Dart `null` gives the Chart.js look.
/// `const ChartThemeData()` themes nothing. The theme is not animated:
/// Chart.js animates the element colors itself.
class ChartTheme extends InheritedTheme {
  /// Gives [data] to the charts of [child].
  const ChartTheme({required this.data, required super.child, super.key});

  /// The theme of the charts below.
  final ChartThemeData data;

  /// The nearest theme, or Dart `null` when no [ChartTheme] is above
  /// [context]. A chart reads this theme.
  static ChartThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChartTheme>()?.data;

  /// The nearest theme, or `const ChartThemeData.light()`. For widgets other
  /// than charts, for example a legend of the app.
  static ChartThemeData of(BuildContext context) =>
      maybeOf(context) ?? const ChartThemeData.light();

  @override
  Widget wrap(BuildContext context, Widget child) =>
      ChartTheme(data: data, child: child);

  @override
  bool updateShouldNotify(ChartTheme oldWidget) => data != oldWidget.data;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<ChartThemeData>('data', data, showName: false),
    );
  }
}
