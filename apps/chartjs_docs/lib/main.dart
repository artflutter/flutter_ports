// Original code, not ported from Chart.js: the entry of the docs site.

import 'package:chartjs_docs/examples/line_examples.dart';
import 'package:chartjs_docs/pages/line_chart_page.dart';
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

/// The documentation site.
class DocsApp extends StatelessWidget {
  /// Creates the site with the code regions [snippets].
  const DocsApp({required this.snippets, super.key});

  /// The code regions of the examples.
  final Snippets snippets;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Chart.js for Flutter',
    debugShowCheckedModeBanner: false,
    theme: docsTheme(),
    home: DocPage(content: lineChartPage(), snippets: snippets),
  );
}
