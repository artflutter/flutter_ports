// Original code, not ported from Chart.js: stress tab control helpers.

import 'package:chartjs_gallery/demo/demo_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether the control of [key] is on the page.
Future<bool> stressControlExists(WidgetTester tester, String key) async =>
    find.byKey(ValueKey(key)).evaluate().isNotEmpty;

/// Whether the control of [key] is on: the selected segment of a
/// [SegmentChoice], or an option of a [SegmentToggles] that is on.
Future<bool> stressSelected(WidgetTester tester, String key) async {
  final control = tester.widget(
    find.ancestor(
      of: find.byKey(ValueKey(key)),
      matching: find.byWidgetPredicate(
        (w) => w is SegmentChoice || w is SegmentToggles,
      ),
    ),
  );
  return switch (control) {
    final SegmentToggles toggles => toggles.isSelected(key),
    final SegmentChoice<Object?> choice => choice.isSelected(key),
    _ => throw StateError('No segmented control holds $key.'),
  };
}

/// Scrolls the control of [key] into view and taps it.
Future<void> stressTap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}
