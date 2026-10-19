// Original code, not ported from Chart.js: tests of test/flutter_test_config.dart.
@TestOn('vm')
library;

import 'dart:ui' as ui;

import 'package:flutter_chartjs/src/core/core.defaults.dart';
import 'package:flutter_test/flutter_test.dart';

// The set-up of test/flutter_test_config.dart, the port of Chart.js
// test/index.js. This file does not call setUpSpecs(): the restore of the
// global scopes comes from the config file alone.

/// The width of 'Hello' in a paragraph of [family] at 12px.
double _helloWidth(String family) {
  final builder = ui.ParagraphBuilder(ui.ParagraphStyle())
    ..pushStyle(ui.TextStyle(fontFamily: family, fontSize: 12))
    ..addText('Hello');
  final paragraph = builder.build()
    ..layout(const ui.ParagraphConstraints(width: double.infinity));
  final width = paragraph.maxIntrinsicWidth;
  paragraph.dispose();
  return width;
}

void main() {
  group('devicePixelRatio', () {
    testWidgets('the test view has a ratio of 1 and 800 x 600', (tester) async {
      expect(tester.view.devicePixelRatio, 1);
      expect(tester.view.physicalSize, const ui.Size(800, 600));
      // A test that resets the view gets the flutter_test default back.
      tester.view.reset();
      expect(tester.view.devicePixelRatio, 3);
    });

    testWidgets('the next test has a ratio of 1 again', (tester) async {
      expect(tester.view.devicePixelRatio, 1);
      expect(tester.view.physicalSize, const ui.Size(800, 600));
    });
  });

  group('harness-defaults-restore', () {
    // Each test checks the state of the snapshot first and then changes the
    // scopes. In any test order, the other test finds the restored state.
    late Object? color;

    setUpAll(() {
      color = defaults['color'];
    });

    void checkAndChange() {
      expect(defaults['color'], same(color));
      expect(defaults.containsKey('harnessKey'), isFalse);
      expect(overrides.containsKey('harnessType'), isFalse);
      defaults['color'] = 'changed';
      defaults['harnessKey'] = 1;
      overrides['harnessType'] = <String, Object?>{};
    }

    test('a test changes defaults and overrides', checkAndChange);

    test('the next test finds them restored', checkAndChange);
  });

  group('harness-test-font', () {
    test('Arial and the Chart.js default families use Liberation Sans', () {
      // 'Hello' is 4667 units of 2048 in Liberation Sans and in Arial.
      for (final family in ['Helvetica Neue', 'Helvetica', 'Arial']) {
        expect(
          _helloWidth(family),
          closeTo(4667 * 12 / 2048, 0.01),
          reason: family,
        );
      }
    });
  });
}
