// Original code, not ported from Chart.js: tests of the platform detection.
@TestOn('vm')
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_chartjs_port/src/platform/index.dart';
import 'package:flutter_test/flutter_test.dart';

// The group platform-detect-host pins the differences.md row of the same
// name: detectPlatform tests for a chart host, not for a DOM.

void main() {
  group('platform-detect-host', () {
    test('gives BasicPlatform for an item that is not a canvas', () {
      expect(detectPlatform('foobar')(), isA<BasicPlatform>());
      expect(detectPlatform(null)(), isA<BasicPlatform>());
    });

    test('gives BasicPlatform for a canvas that no host shows', () {
      final platform = detectPlatform(UiCanvasElement())();
      expect(platform, isA<BasicPlatform>());
      expect(platform, isNot(isA<FlutterPlatform>()));
    });

    testWidgets('gives FlutterPlatform for a canvas that a host shows', (
      tester,
    ) async {
      final canvas = UiCanvasElement();
      await tester.pumpWidget(ChartHost(canvas: canvas));
      expect(detectPlatform(canvas)(), isA<FlutterPlatform>());
      await tester.pumpWidget(const SizedBox());
      expect(detectPlatform(canvas)(), isA<BasicPlatform>());
    });
  });
}
