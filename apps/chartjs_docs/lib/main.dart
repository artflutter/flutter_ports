// Original code, not ported from Chart.js: the entry of the docs site.

import 'package:chartjs_docs/examples/line_examples.dart';
import 'package:chartjs_docs/pages/bar_chart_page.dart';
import 'package:chartjs_docs/pages/line_chart_page.dart';
import 'package:chartjs_docs/pages/migrate_fl_chart_page.dart';
import 'package:chartjs_docs/pages/migrate_graphic_page.dart';
import 'package:chartjs_docs/pages/migrate_syncfusion_page.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/docs_theme.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerCharts();
  final snippets = await Snippets.load();
  runApp(DocsApp(snippets: snippets));
}

/// The pages of the site, in navigation order. Each chart type is a group:
/// its docs page, then its migration pages. The first page is the home page
/// and the page of an unknown route.
final List<DocPageLink> docPages = [
  const DocPageLink(
    route: '/charts/line',
    group: 'Line chart',
    navLabel: 'Line chart',
    icon: Icons.show_chart,
    build: lineChartPage,
  ),
  const DocPageLink(
    route: '/charts/line/migrate/fl_chart',
    group: 'Line chart',
    navLabel: 'From fl_chart',
    icon: Icons.swap_horiz,
    build: flChartMigrationPage,
  ),
  const DocPageLink(
    route: '/charts/line/migrate/graphic',
    group: 'Line chart',
    navLabel: 'From Graphic',
    icon: Icons.swap_horiz,
    build: graphicMigrationPage,
  ),
  const DocPageLink(
    route: '/charts/line/migrate/syncfusion',
    group: 'Line chart',
    navLabel: 'From Syncfusion',
    icon: Icons.swap_horiz,
    build: syncfusionMigrationPage,
  ),
  const DocPageLink(
    route: '/charts/bar',
    group: 'Bar chart',
    navLabel: 'Bar chart',
    icon: Icons.bar_chart,
    build: barChartPage,
  ),
];

/// The old addresses of the pages that moved, so that a saved link still
/// opens its page.
const Map<String, String> movedRoutes = {
  '/migrate/fl_chart': '/charts/line/migrate/fl_chart',
  '/migrate/graphic': '/charts/line/migrate/graphic',
  '/migrate/syncfusion': '/charts/line/migrate/syncfusion',
};

/// The documentation site.
class const DocsApp({
  /// The code regions of the examples.
  required final Snippets snippets,

  /// The first route, or the route of the browser address.
  final String? initialRoute,
  super.key,
}) extends StatelessWidget {
  /// Creates the site with the code regions [snippets].
  this;

  Route<void> _route(RouteSettings settings) {
    final name = movedRoutes[settings.name] ?? settings.name;
    final page = docPages.firstWhere(
      (page) => page.route == name,
      orElse: () => docPages.first,
    );
    final content = page.build();
    return PageRouteBuilder<void>(
      settings: RouteSettings(name: page.route),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, _, _) => Title(
        title: '${content.title} · Chart.js for Flutter',
        color: DocColors.primary,
        child: DocPage(
          key: ValueKey(page.route),
          content: content,
          snippets: snippets,
          pages: docPages,
          route: page.route,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Chart.js for Flutter',
    debugShowCheckedModeBanner: false,
    theme: docsTheme(),
    initialRoute: initialRoute,
    onGenerateRoute: _route,
    // The address `#/charts/bar` opens that page alone, with no page below
    // it.
    onGenerateInitialRoutes: (name) => [_route(RouteSettings(name: name))],
  );
}
