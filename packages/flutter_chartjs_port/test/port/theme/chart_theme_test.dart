// Original code, not ported from Chart.js: tests of the inherited theme.
@TestOn('vm')
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/src/theme/chart_theme.dart';
import 'package:flutter_chartjs_port/src/theme/theme_data.dart';
import 'package:flutter_test/flutter_test.dart';

// theming.md §8 test 7, the inherited part (Chart.js ADR 0050, "The public
// classes"): `ChartTheme` has a non-null `data`. `maybeOf` gives a chart
// Dart null with no theme (the Chart.js look), `of` gives the light preset
// to other widgets, `updateShouldNotify` compares the data with `==`, and
// `InheritedTheme.capture` brings the theme into a route of the Navigator.
// The equality, `lerp` and the presets of `ChartThemeData` are in
// theme_data_test.dart.
//
// VM only: the file imports flutter_test and the widgets library.

/// The red of the tests.
const Color _red = Color.from(alpha: 1, red: 200 / 255, green: 0, blue: 0);

/// A theme with one token.
const ChartThemeData _redTheme = ChartThemeData(color: _red);

/// A widget that records the [ChartTheme.maybeOf] of each build.
class _Reader extends StatelessWidget {
  const _Reader(this.log);

  /// The theme of each build.
  final List<ChartThemeData?> log;

  @override
  Widget build(BuildContext context) {
    log.add(ChartTheme.maybeOf(context));
    return const SizedBox();
  }
}

/// A `WidgetsApp` with [home], [navigatorKey] and the page routes of
/// `PageRouteBuilder`: no Material in the tests of `lib/src/theme/`.
Widget _app(Widget home, GlobalKey<NavigatorState> navigatorKey) => WidgetsApp(
  navigatorKey: navigatorKey,
  color: const Color(0xFF000000),
  home: home,
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, _, _) => builder(context),
  ),
);

void main() {
  group('ChartTheme', () {
    testWidgets('maybeOf gives null with no theme', (tester) async {
      final log = <ChartThemeData?>[];
      await tester.pumpWidget(_Reader(log));
      expect(log, [null]);
    });

    testWidgets('maybeOf gives the nearest theme', (tester) async {
      final log = <ChartThemeData?>[];
      await tester.pumpWidget(
        ChartTheme(
          data: const ChartThemeData.dark(),
          child: Column(
            children: [
              _Reader(log),
              ChartTheme(data: _redTheme, child: _Reader(log)),
            ],
          ),
        ),
      );
      expect(log, [const ChartThemeData.dark(), _redTheme]);
    });

    testWidgets('const ChartThemeData() is a theme that themes nothing', (
      tester,
    ) async {
      final log = <ChartThemeData?>[];
      await tester.pumpWidget(
        ChartTheme(data: const ChartThemeData(), child: _Reader(log)),
      );
      expect(log, [const ChartThemeData()]);
    });

    testWidgets('of gives the light preset with no theme', (tester) async {
      late ChartThemeData theme;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            theme = ChartTheme.of(context);
            return const SizedBox();
          },
        ),
      );
      expect(theme, const ChartThemeData.light());
      expect(identical(theme, const ChartThemeData.light()), isTrue);
    });

    testWidgets('of gives the nearest theme', (tester) async {
      late ChartThemeData theme;
      await tester.pumpWidget(
        ChartTheme(
          data: _redTheme,
          child: Builder(
            builder: (context) {
              theme = ChartTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(theme, _redTheme);
    });

    test('updateShouldNotify compares the data with ==', () {
      ChartTheme theme(ChartThemeData data) =>
          ChartTheme(data: data, child: const SizedBox());
      final a = theme(_redTheme);
      expect(a.updateShouldNotify(theme(_redTheme.copyWith())), isFalse);
      expect(a.updateShouldNotify(theme(const ChartThemeData())), isTrue);
      expect(
        theme(const ChartThemeData.light()).updateShouldNotify(
          theme(const ChartThemeData.dark()),
        ),
        isTrue,
      );
    });

    testWidgets('an equal theme does not rebuild the dependents', (
      tester,
    ) async {
      final log = <ChartThemeData?>[];
      final child = _Reader(log);
      await tester.pumpWidget(ChartTheme(data: _redTheme, child: child));
      await tester.pumpWidget(
        ChartTheme(data: _redTheme.copyWith(), child: child),
      );
      expect(log, hasLength(1));
      await tester.pumpWidget(
        ChartTheme(data: const ChartThemeData.dark(), child: child),
      );
      expect(log, [_redTheme, const ChartThemeData.dark()]);
    });

    testWidgets('wrap gives a ChartTheme with the same data', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      );
      const theme = ChartTheme(data: _redTheme, child: SizedBox());
      final wrapped = theme.wrap(context, const SizedBox());
      expect(wrapped, isA<ChartTheme>());
      expect((wrapped as ChartTheme).data, _redTheme);
    });

    testWidgets('InheritedTheme.capture brings the theme into a route', (
      tester,
    ) async {
      final log = <ChartThemeData?>[];
      final navigatorKey = GlobalKey<NavigatorState>();
      late BuildContext pageContext;
      await tester.pumpWidget(
        _app(
          ChartTheme(
            data: _redTheme,
            child: Builder(
              builder: (context) {
                pageContext = context;
                return const SizedBox();
              },
            ),
          ),
          navigatorKey,
        ),
      );
      NavigatorState navigator() => navigatorKey.currentState!;

      // The route is not below the ChartTheme of the page.
      navigator().push(
        PageRouteBuilder<void>(pageBuilder: (_, _, _) => _Reader(log)),
      );
      await tester.pumpAndSettle();
      expect(log, [null]);
      navigator().pop();
      await tester.pumpAndSettle();

      // The captured themes of the page wrap the route.
      final themes = InheritedTheme.capture(
        from: pageContext,
        to: navigator().context,
      );
      navigator().push(
        PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => themes.wrap(_Reader(log)),
        ),
      );
      await tester.pumpAndSettle();
      expect(log.last, _redTheme);
    });

    test('debugFillProperties gives the data', () {
      final builder = DiagnosticPropertiesBuilder();
      const ChartTheme(
        data: _redTheme,
        child: SizedBox(),
      ).debugFillProperties(builder);
      expect(
        builder.properties.map((p) => p.value),
        contains(_redTheme),
      );
    });
  });
}
