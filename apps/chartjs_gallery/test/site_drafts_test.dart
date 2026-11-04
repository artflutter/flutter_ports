// Original code, not ported from Chart.js: responsive site draft checks.
import 'package:chartjs_gallery/site_drafts/package_health.dart';
import 'package:chartjs_gallery/site_drafts/site_drafts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => Chart.register(registerables));

  for (var direction = 0; direction < 3; direction++) {
    for (final width in [390.0, 1440.0]) {
      testWidgets('direction $direction lays out at $width', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1000);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(SiteDraftsApp(initialDirection: direction));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Built with Flutter. Including this page.'),
          450,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('community credits and suggestion destination are available', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1100);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const SiteDraftsApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Community'));
    await tester.pumpAndSettle();
    expect(find.text('Awesome Flutter Ports'), findsOneWidget);
    expect(find.text('By Akvelon & contributors'), findsOneWidget);
    await tester.ensureVisible(find.text('Suggest a port'));
    await tester.tap(find.text('Suggest a port'));
    await tester.pumpAndSettle();
    expect(find.text('Suggest a community port'), findsOneWidget);
    expect(
      find.text(
        'https://github.com/artflutter/flutter_ports/issues/new?'
        'title=Awesome+Flutter+Ports+suggestion',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final available in [true, false]) {
    testWidgets('health distinguishes zero and unknown ($available)', (
      tester,
    ) async {
      final snapshot = PackageHealthSnapshot.fromJson({
        'checked_at': '2026-01-01T12:00:00Z',
        'packages': <String, Object?>{
          'sample': <String, Object?>{
            'repository': 'example/project',
            'activity_path': 'packages/sample',
            'open_issues': available ? 0 : null,
            'open_prs': available ? 3 : null,
            'commits_90d': available ? 0 : null,
            'release_status': available ? 'unpublished' : 'unknown',
          },
        },
      });
      String? destination;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PackageHealth(
              package: 'sample',
              snapshot: Future.value(snapshot),
              onSource: (_, _, url) => destination = url,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(available ? '0 issues' : '— issues'), findsOneWidget);
      expect(find.text(available ? '3 PRs' : '— PRs'), findsOneWidget);
      if (available) {
        expect(find.text('0 commits / 90 days'), findsOneWidget);
        expect(find.text('Not published'), findsOneWidget);
      } else {
        expect(find.text('Unknown'), findsNWidgets(3));
        expect(find.text('0 commits / 90 days'), findsNothing);
      }
      expect(
        find.text(
          'Activity: this package · Issues & PRs: shared repository',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(available ? '3 PRs' : '— PRs'));
      expect(
        destination,
        'https://github.com/example/project/pulls?q=is%3Apr+is%3Aopen',
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('drafts and live chart controls switch content', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1100);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const SiteDraftsApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bar'));
    await tester.pumpAndSettle();
    ChartView chart() => tester.widget<ChartView>(find.byType(ChartView));
    expect(chart().config!.type, ChartKind.bar);
    final before = (chart().config!.datasets.first as BarDataset).data;
    await tester.tap(find.byTooltip('Change sample data'));
    await tester.pumpAndSettle();
    expect((chart().config!.datasets.first as BarDataset).data, isNot(before));
    await tester.tap(find.text('Doughnut'));
    await tester.pumpAndSettle();
    expect(chart().config!.type, ChartKind.doughnut);
    await tester.tap(find.text('2  Workbench'));
    await tester.pumpAndSettle();
    expect(find.text('Same curiosity.\nNew canvas.'), findsOneWidget);
    await tester.tap(find.text('3  Fieldnotes'));
    await tester.pumpAndSettle();
    expect(find.text('Good libraries\ntravel well.'), findsOneWidget);
    await tester.tap(find.text('Explore Chart.js  ↗'));
    await tester.pumpAndSettle();
    expect(find.text('Chart.js for Flutter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
