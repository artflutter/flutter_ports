// Original code, not ported from Chart.js: the DartPad buttons in the tests.

import 'package:chartjs_docs/ui/dartpad.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The sample files that the **Try in DartPad** buttons of the page open,
/// over each form of each example: the test taps each choice chip.
Future<Set<String>> dartPadFiles(WidgetTester tester) async {
  final files = <String>{};
  void collect() => files.addAll(
    tester.widgetList<DartPadLink>(find.byType(DartPadLink)).map((l) => l.file),
  );
  collect();
  final chips = find.byType(ChoiceChip);
  final count = chips.evaluate().length;
  for (var i = 0; i < count; i++) {
    await tester.ensureVisible(chips.at(i));
    await tester.pump();
    await tester.tap(chips.at(i));
    await tester.pump();
    collect();
  }
  return files;
}
