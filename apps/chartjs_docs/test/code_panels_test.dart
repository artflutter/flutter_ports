// Original code, not ported from Chart.js: the tests of the code panels.
@TestOn('vm')
library;

import 'dart:io';

import 'package:chartjs_docs/examples/line_examples.dart';
import 'package:chartjs_docs/main.dart';
import 'package:chartjs_docs/ui/code_block.dart';
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/file_sources.dart';

Snippets _regionsOf(String source) =>
    Snippets.parse(File(source).readAsStringSync());

Future<void> _open(
  WidgetTester tester,
  String route,
  CodeSources sources,
) async {
  tester.view
    ..physicalSize = const Size(1400, 1000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(DocsApp(sources: sources, initialRoute: route));
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _tap(WidgetTester tester, String key) async {
  final button = find.byKey(ValueKey(key));
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await tester.pump();
  await tester.pump();
}

Finder _code(String code) => find.byWidgetPredicate(
  (widget) => widget is CodeBlock && widget.code == code,
);

void main() {
  setUpAll(registerCharts);

  test('the region names are unique over the source files', () {
    expect(sourceFiles(), isNotEmpty);
    expect(() => regionsOf(snippetFolders), returnsNormally);
  });

  test('each source file of the code panels has one region', () {
    for (final path in sourceFiles()) {
      expect(_regionsOf(path).names, hasLength(1), reason: path);
    }
  });

  for (final page in docPages) {
    testWidgets('each code panel of ${page.route} names a region of its '
        'file', (tester) async {
      await _open(tester, page.route, fileSources());
      final regions = [
        for (final toggle in tester.widgetList<CodeToggle>(
          find.byType(CodeToggle, skipOffstage: false),
        ))
          toggle.region,
        for (final example in tester.widgetList<LiveExample>(
          find.byType(LiveExample, skipOffstage: false),
        ))
          for (final variant in example.variants) variant.region,
      ];
      expect(regions, isNotEmpty);
      for (final region in regions) {
        expect(isSnippetSource(region.source), isTrue, reason: '$region');
        expect(
          _regionsOf(region.source).names,
          contains(region.name),
          reason: '$region',
        );
      }
    });
  }

  testWidgets('a page reads no source file before a tap on Code', (
    tester,
  ) async {
    final reads = <String>[];
    await _open(tester, '/charts/bar', fileSources(reads));
    expect(reads, isEmpty);
    expect(find.byType(CodeBlock, skipOffstage: false), findsNothing);
    expect(find.byType(CodeToggle, skipOffstage: false), findsWidgets);
  });

  testWidgets('a tap on Code reads the file of its panel once', (tester) async {
    final reads = <String>[];
    await _open(tester, '/charts/bar', fileSources(reads));

    const basic = '$barExamples/basic.dart';
    const scopes = '$barExamples/scopes.dart';
    const register = '$lineExamples/register.dart';
    final basicCode = _code(_regionsOf(basic)['bar-basic']);

    await _tap(tester, 'basic.code');
    expect(reads, [basic]);
    expect(basicCode, findsOneWidget);

    await _tap(tester, 'scopes.code');
    expect(reads, [basic, scopes]);
    expect(_code(_regionsOf(scopes)['bar-scopes']), findsOneWidget);

    await _tap(tester, 'register.code');
    expect(reads, [basic, scopes, register]);
    expect(_code(_regionsOf(register)['register']), findsOneWidget);

    await _tap(tester, 'basic.code');
    expect(basicCode, findsNothing);
    await _tap(tester, 'basic.code');
    expect(basicCode, findsOneWidget);
    expect(reads, [basic, scopes, register]);
  });

  testWidgets('a file that does not load shows a text, and the next open '
      'reads it again', (tester) async {
    var reads = 0;
    await _open(
      tester,
      '/charts/line',
      CodeSources((path) async {
        reads++;
        throw FileSystemException('no file', path);
      }),
    );
    await _tap(tester, 'basic.code');
    expect(find.text('The code did not load.'), findsOneWidget);
    expect(reads, 1);

    await _tap(tester, 'basic.code');
    await _tap(tester, 'basic.code');
    expect(reads, 2);
  });
}
