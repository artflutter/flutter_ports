import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// A note over the page, for what the page cannot show next to the chart.
///
/// The page puts it in the floating slot of its `Scaffold`, outside each scroll
/// view, so that it stays in place when the page scrolls.
class const PageNote({
  /// The short name of the subject.
  required final String title,

  /// The explanation, in plain words.
  required final String text,

  /// Called when the person closes the note.
  required final VoidCallback onClose,
  super.key,
}) extends StatelessWidget {
  /// Creates the note.
  this;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: math.min(380, MediaQuery.sizeOf(context).width - 32),
    ),
    child: Material(
      key: const ValueKey('page.note'),
      color: Colors.white,
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xffe1e6ef)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff475569),
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('page.note.close'),
                  tooltip: 'Close',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                text,
                style: const TextStyle(fontSize: 13, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
