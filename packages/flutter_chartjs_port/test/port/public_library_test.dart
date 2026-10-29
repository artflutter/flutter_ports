// Original code, not ported from Chart.js: the app library next to Material.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/pure.dart' show removeBuiltins;
import 'package:flutter/material.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0048, sections 3 and 5: a file of an app imports
// `package:flutter/material.dart` and the app library with no prefix and no
// `hide`. A name that both export would be an `ambiguous_import` error of
// the analysis of this file. The app registers the components of its chart
// types: here the line set of docs/getting-started/integration.md (the line
// controller, its two elements and the two cartesian scales).
//
// flutter_test_config.dart registers the built-in components before main()
// (harness-register-builtins). Thus main() removes them first, as an app
// starts with an empty registry.

/// The line set: the components of a line chart on the default scales.
final List<Object?> _lineSet = [
  LineController.jsClass,
  LineElement.jsClass,
  PointElement.jsClass,
  CategoryScale.jsClass,
  LinearScale.jsClass,
];

void main() {
  removeBuiltins();

  testWidgets('an app registers the line set next to Material', (
    tester,
  ) async {
    expect(() => registry.getController('line'), throwsStateError);
    Chart.register(_lineSet);
    addTearDown(() => Chart.unregister(_lineSet));
    expect(registry.getController('line'), same(LineController.jsClass));
    expect(registry.getScale('category'), same(CategoryScale.jsClass));

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Chart.js'))),
    );
    expect(find.text('Chart.js'), findsOneWidget);
  });

  testWidgets('an app shows a line chart in ChartView next to Material', (
    tester,
  ) async {
    Chart.register(_lineSet);
    addTearDown(() => Chart.unregister(_lineSet));
    Chart? created;
    // A config is never const: Chart.js writes into its `data` and
    // `options` objects (core.config.js:115-126).
    final config = <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'labels': <Object?>['a', 'b', 'c'],
        'datasets': <Object?>[
          <String, Object?>{
            'data': <Object?>[1, 3, 2],
          },
        ],
      },
      'options': <String, Object?>{'animation': false},
    };
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChartView(
            config: config,
            onChartCreated: (chart) => created = chart,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(created, isA<Chart>());
    expect(created!.config.type, 'line');
    expect(created!.getDatasetMeta(0).data, hasLength(3));
  });
}
