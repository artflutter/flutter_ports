// Original code, not ported from Chart.js: stress tab control helpers.

import 'package:chartjs_gallery/demo/demo_controls.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Whether the control of [key] is on the page.
Future<bool> stressControlExists(WidgetTester tester, String key) async =>
    find.byKey(ValueKey(key), skipOffstage: false).evaluate().isNotEmpty;

/// Whether the control of [key] is on: the selected segment of a
/// [SegmentChoice], or an option of a [SegmentToggles] that is on.
Future<bool> stressSelected(WidgetTester tester, String key) async {
  if (key.startsWith('stress.mode.') &&
      find.byKey(ValueKey(key)).evaluate().isEmpty) {
    return false;
  }
  final control = tester.widget(
    find.ancestor(
      of: find.byKey(ValueKey(key), skipOffstage: false),
      matching: find.byWidgetPredicate(
        (w) => w is SegmentChoice || w is SegmentToggles,
        skipOffstage: false,
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
  if (find.byKey(ValueKey(key)).evaluate().isEmpty) {
    final drawing = const {
      'stress.mode.primitives',
      'stress.mode.elements',
      'stress.mode.bars',
      'stress.mode.arcs',
    }.contains(key);
    final opener = find.byKey(
      ValueKey(drawing ? 'stress.target.drawing' : 'stress.options'),
    );
    await tester.ensureVisible(opener);
    await tester.tap(opener);
    await tester.pump();
  }
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}
