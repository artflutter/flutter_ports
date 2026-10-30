// Original code, not ported from Chart.js: tests of the semantics of ChartView.
@TestOn('vm')
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/widgets/chart_view.dart';
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0051, section 8: the chart is one semantics node, as the
// upstream canvas with `role="img"` and `aria-label`
// (docs/general/accessibility.md). The node is a container also without a
// label, because the chart is a focus stop (probe J1a of the design panel).
// `SemanticsTester` is a helper of the Flutter repository, not of
// flutter_test: the tests read the nodes with `tester.ensureSemantics()`,
// `tester.getSemantics` and `matchesSemantics`.

/// A bar chart config with 3 values. [animated] keeps the default
/// animation.
Map<String, Object?> _config({bool animated = false}) => <String, Object?>{
  'type': 'bar',
  'data': <String, Object?>{
    'labels': <Object?>['a', 'b', 'c'],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'd0',
        'data': <Object?>[1, 3, 2],
      },
    ],
  },
  'options': <String, Object?>{'animation': ?animated ? null : false},
};

/// [child] at the top left of the test view, in a box of 400 x 300.
Widget _top(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: 400, height: 300, child: child),
  ),
);

/// The nodes of the semantics tree of the test view.
List<SemanticsNode> _nodes(WidgetTester tester) {
  final nodes = <SemanticsNode>[];
  bool visit(SemanticsNode node) {
    nodes.add(node);
    node.visitChildren(visit);
    return true;
  }

  visit(
    tester.binding.renderViews.single.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return nodes;
}

void main() {
  testWidgets('the node has the label, the image flag, the focus flag and '
      'the action focus', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _top(ChartView(config: _config(), semanticLabel: 'Sales by month')),
    );
    expect(
      tester.getSemantics(find.byType(ChartView)),
      matchesSemantics(
        label: 'Sales by month',
        textDirection: TextDirection.ltr,
        isImage: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    expect(find.bySemanticsLabel('Sales by month'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a null label gives an unlabeled node of its own under a '
      'labeled parent', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _top(
        Semantics(
          container: true,
          label: 'parent',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('sibling'),
              Expanded(child: ChartView(config: _config())),
            ],
          ),
        ),
      ),
    );
    final chart = tester.getSemantics(find.byType(ChartView));
    expect(
      chart,
      matchesSemantics(isImage: true, isFocusable: true, hasFocusAction: true),
    );
    expect(chart.label, isEmpty);
    // The parent keeps its label and the text of its other child, and has
    // neither the image flag nor the focus flag (probe J1a).
    final parent = tester.getSemantics(find.text('sibling'));
    expect(parent, isNot(same(chart)));
    expect(parent.label, 'parent\nsibling');
    expect(
      parent,
      matchesSemantics(
        label: 'parent\nsibling',
        textDirection: TextDirection.ltr,
        children: [anything],
      ),
    );
    expect(chart.parent, same(parent));
    handle.dispose();
  });

  testWidgets('excludeFromSemantics gives no node of the chart', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _top(
        ChartView(
          config: _config(),
          semanticLabel: 'Sales by month',
          excludeFromSemantics: true,
        ),
      ),
    );
    expect(find.bySemanticsLabel('Sales by month'), findsNothing);
    for (final node in _nodes(tester)) {
      final data = node.getSemanticsData();
      expect(data.flagsCollection.isImage, isFalse);
      expect(data.hasAction(SemanticsAction.focus), isFalse);
    }
    handle.dispose();
  });

  testWidgets('a data update and the frames of its animation give no '
      'semantics update', (tester) async {
    final handle = tester.ensureSemantics();
    late Chart chart;
    Widget build(String label) => _top(
      ChartView(
        config: _config(animated: true),
        semanticLabel: label,
        onChartCreated: (created) => chart = created,
      ),
    );
    await tester.pumpWidget(build('Sales'));
    // The entry animation ends after 1000 ms.
    for (var i = 0; i < 70; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final owner = tester.binding.renderViews.single.owner!.semanticsOwner!;
    var updates = 0;
    void count() => updates++;
    owner.addListener(count);
    addTearDown(() => owner.removeListener(count));

    final data =
        jsGet(jsGet(jsGet(chart.data, 'datasets'), 0.0), 'data')!
            as List<Object?>;
    data[1] = 9;
    chart.update();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(updates, 0);

    // A new label is one update: the listener works.
    await tester.pumpWidget(build('Sales and costs'));
    expect(updates, 1);
    handle.dispose();
  });

  testWidgets('the diagnostics name the label and the exclusion', (
    tester,
  ) async {
    List<String> properties(Diagnosticable object) => [
      for (final property in object.toDiagnosticsNode().getProperties())
        if (!property.isFiltered(DiagnosticLevel.info)) property.toString(),
    ];
    expect(
      properties(
        const ChartView(
          config: {},
          semanticLabel: 'Sales',
          excludeFromSemantics: true,
        ),
      ),
      ['type: null', 'semanticLabel: "Sales"', 'excluded from semantics'],
    );
  });
}
