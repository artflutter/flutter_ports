// Original code, not ported from Chart.js: the tests of the migration pages.
@TestOn('vm')
library;

import 'dart:io';

import 'package:chartjs_docs/examples/line_examples.dart';
import 'package:chartjs_docs/main.dart';
import 'package:chartjs_docs/ui/replica_block.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The regions of all the source files that the pages show, as
/// `Snippets.load` reads them from the assets.
final Snippets _snippets = Snippets.parseAll([
  for (final folder in snippetFolders)
    if (Directory(folder).existsSync())
      for (final file
          in Directory(folder).listSync().whereType<File>().toList()
            ..sort((a, b) => a.path.compareTo(b.path)))
        if (isSnippetSource(file.path)) file.readAsStringSync(),
]);

Future<void> _open(
  WidgetTester tester,
  String route, {
  double width = 1400,
}) async {
  tester.view
    ..physicalSize = Size(width, 1000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(DocsApp(snippets: _snippets, initialRoute: route));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(registerCharts);

  test('pubspec.yaml lists each folder of the code panels', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final folder in snippetFolders) {
      expect(pubspec, contains('    - $folder\n'), reason: folder);
    }
  });

  for (final page in docPages.where((page) => page.group == 'Migrate from')) {
    group(page.route, () {
      test('each demo has its code region', () {
        final content = page.build();
        for (final section in content.sections.skip(1)) {
          if (section.id == 'kit') continue;
          final region = (section.body.single as ReplicaBlock).demo.region;
          expect(_snippets.names, contains(region), reason: section.id);
        }
      });

      testWidgets('the page builds, and each replica draws', (tester) async {
        await _open(tester, page.route);
        final content = page.build();
        expect(find.text(content.title), findsOneWidget);
        expect(tester.takeException(), isNull);
        for (final section in content.sections.skip(1)) {
          if (section.id == 'kit') continue;
          final replica = find.byKey(
            ValueKey('${section.id}.replica'),
            skipOffstage: false,
          );
          expect(replica, findsOneWidget, reason: section.id);
        }
      });

      testWidgets('the code of a demo opens on a tap', (tester) async {
        final content = page.build();
        if (content.sections.length < 2) return;
        await _open(tester, page.route);
        final id = content.sections[1].id;
        final button = find.byKey(ValueKey('$id.code'));
        await tester.ensureVisible(button);
        await tester.pump();
        await tester.tap(button);
        await tester.pump();
        expect(find.text('Hide code'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('the page builds on a phone', (tester) async {
        await _open(tester, page.route, width: 390);
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('the sidebar opens another page', (tester) async {
    await _open(tester, '/');
    await tester.tap(find.byKey(const ValueKey('page./migrate/fl_chart')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Migrate from fl_chart'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('page./')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Line Chart'), findsWidgets);
  });

  testWidgets('an unknown route opens the line chart page', (tester) async {
    await _open(tester, '/nothing');
    expect(find.byKey(const ValueKey('page.title')), findsOneWidget);
    expect(find.text('Line Chart'), findsWidgets);
  });
}
