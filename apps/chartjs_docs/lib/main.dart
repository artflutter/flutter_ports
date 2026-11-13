// Original code, not ported from Chart.js: the entry of the docs site.

import 'package:chartjs_docs/examples/line_examples.dart';
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

/// The pages of the site, in navigation order. The first page is the home
/// page and the page of an unknown route.
final List<DocPageLink> docPages = [
  const DocPageLink(
    route: '/',
    group: 'Chart types',
    navLabel: 'Line chart',
    icon: Icons.show_chart,
    build: lineChartPage,
  ),
  const DocPageLink(
    route: '/migrate/fl_chart',
    group: 'Migrate from',
    navLabel: 'fl_chart',
    icon: Icons.swap_horiz,
    build: flChartMigrationPage,
  ),
  const DocPageLink(
    route: '/migrate/graphic',
    group: 'Migrate from',
    navLabel: 'Graphic',
    icon: Icons.swap_horiz,
    build: graphicMigrationPage,
  ),
  const DocPageLink(
    route: '/migrate/syncfusion',
    group: 'Migrate from',
    navLabel: 'Syncfusion',
    icon: Icons.swap_horiz,
    build: syncfusionMigrationPage,
  ),
];

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
    final page = docPages.firstWhere(
      (page) => page.route == settings.name,
      orElse: () => docPages.first,
    );
    return PageRouteBuilder<void>(
      settings: RouteSettings(name: page.route),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, _, _) => Title(
        title: '${page.navLabel} · Chart.js for Flutter',
        color: DocColors.primary,
        child: DocPage(
          key: ValueKey(page.route),
          content: page.build(),
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
    // The address `#/migrate/fl_chart` opens that page alone, with no page
    // below it.
    onGenerateInitialRoutes: (name) => [_route(RouteSettings(name: name))],
  );
}
