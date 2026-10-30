// Original code, not ported from Chart.js: a ChartView with no components.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/pure.dart' show removeBuiltins;
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_chartjs_port/src/widgets/chart_view.dart';
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0048, section 3: no library code and no widget code
// registers a component. An app that shows a chart of an unregistered type
// gets the upstream error (core.registry.js:178).

void main() {
  // The harness registers the built-in components before main()
  // (harness-register-builtins). This file runs without them.
  removeBuiltins();

  testWidgets('an unregistered type reports the upstream error, and the host '
      'keeps a size', (tester) async {
    final details = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = details.add;
    addTearDown(() => FlutterError.onError = previous);
    // The chart writes into the config: it is not const.
    final config = <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'labels': <Object?>['a', 'b'],
        'datasets': <Object?>[
          <String, Object?>{
            'data': <Object?>[1, 2],
          },
        ],
      },
    };
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 400, child: ChartView.raw(config: config)),
        ),
      ),
    );
    expect(details, hasLength(1));
    final error = details.single.exception;
    expect(error, isA<StateError>());
    expect(
      (error as StateError).message,
      '"line" is not a registered controller.',
    );
    expect(details.single.library, 'flutter_chartjs_port');
    final host = tester.renderObject<RenderChartHost>(find.byType(ChartHost));
    expect(host.size.isEmpty, isFalse);
    // The post-frame callback destroyed the partial chart.
    expect(Chart.instances, isEmpty);
    await tester.pump();
    expect(host.size.isEmpty, isFalse);
  });
}
