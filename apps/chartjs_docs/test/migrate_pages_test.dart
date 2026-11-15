// Original code, not ported from Chart.js: the tests of the migration pages.
@TestOn('vm')
library;

import 'dart:io';

import 'package:chartjs_docs/examples/line_examples.dart';
import 'package:chartjs_docs/main.dart';
import 'package:chartjs_docs/ui/code_block.dart';
import 'package:chartjs_docs/ui/dartpad.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/file_sources.dart';

Future<void> _open(
  WidgetTester tester,
  String route, {
  double width = 1400,
}) async {
  tester.view
    ..physicalSize = Size(width, 1000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(DocsApp(sources: fileSources(), initialRoute: route));
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

  for (final page in docPages.where(
    (page) => page.route.contains('/migrate/'),
  )) {
    group(page.route, () {
      testWidgets('the page builds, and each replica draws', (tester) async {
        await _open(tester, page.route);
        final content = page.build();
        expect(find.text(content.tabTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
        for (final section in content.sections.skip(1)) {
          if (section.id == 'kit') continue;
          final replica = find.byKey(
            ValueKey('${section.id}.replica'),
            skipOffstage: false,
          );
          expect(replica, findsOneWidget, reason: section.id);
          // The DartPad button opens the replica, which has a main function.
          final link = tester.widget<DartPadLink>(
            find.byKey(ValueKey('${section.id}.dartpad'), skipOffstage: false),
          );
          expect(
            File(link.file).readAsStringSync(),
            contains('\nvoid main() {'),
            reason: section.id,
          );
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
        await tester.pump();
        expect(find.text('Hide code'), findsOneWidget);
        expect(find.byType(CodeBlock), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('the page builds on a phone', (tester) async {
        await _open(tester, page.route, width: 390);
        expect(tester.takeException(), isNull);
      });
    });
  }

  test('each migration page is in the group of its chart type', () {
    for (final page in docPages) {
      final type = docPages.firstWhere((other) => other.group == page.group);
      expect(page.route, startsWith(type.route), reason: page.route);
    }
  });

  testWidgets('the sidebar opens another page', (tester) async {
    await _open(tester, '/');
    await tester.tap(
      find.byKey(const ValueKey('page./charts/line/migrate/fl_chart')),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Migrate line charts from fl_chart'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('page./charts/line')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Line Chart'), findsWidgets);
  });

  for (final MapEntry(key: old, value: route) in movedRoutes.entries) {
    testWidgets('the old address $old opens $route', (tester) async {
      await _open(tester, old);
      final page = docPages.firstWhere((page) => page.route == route);
      expect(find.text(page.build().tabTitle), findsOneWidget);
    });
  }

  testWidgets('an unknown route opens the line chart page', (tester) async {
    await _open(tester, '/nothing');
    expect(find.byKey(const ValueKey('page.title')), findsOneWidget);
    expect(find.text('Line Chart'), findsWidgets);
  });
}
