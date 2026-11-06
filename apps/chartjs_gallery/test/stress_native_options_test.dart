// Original code, not ported from Chart.js: stress native option regression.
import 'package:chartjs_gallery/demo/stress_demo.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Native behavior plus an eligibility counter, with no state-changing hooks.
class _ProbePoint extends PointElement {
  int nativeReads = 0;

  @override
  bool get supportsNativePointOptions {
    nativeReads++;
    return true;
  }

  @override
  bool get typedWrites => true;
}

void main() {
  for (final host in StressHost.values) {
    testWidgets('indexed scatter activates native options in stress $host', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StressDemo(
              initialMode: StressMode.chart,
              initialType: StressChartType.scatter,
              initialCall: StressChartCall.update,
              initialN: 24,
              initialM: 0,
              initialIndexed: true,
              autoStart: false,
              host: host,
            ),
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      final state = tester.state<StressDemoState>(find.byType(StressDemo));
      final chart = state.debugChart!;
      final elements = chart.getDatasetMeta(0).data;
      final probes = <_ProbePoint>[];
      for (var i = 0; i < elements.length; i++) {
        final point = _ProbePoint();
        elements[i] = point;
        probes.add(point);
      }
      chart.update('none');
      expect(
        probes.any((point) => point.nativeReads > 0),
        isTrue,
        reason: 'The actual stress chart must enter the native option loops.',
      );
      expect(
        probes.every((point) => point.x.isFinite && point.y.isFinite),
        isTrue,
      );
      expect(identical(probes[3].options, probes[4].options), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
