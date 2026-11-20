// Original code, not ported from Chart.js: the card of one sample.

import 'package:chartjs_ergonomics/sample.dart';
import 'package:chartjs_ergonomics/ui/code_panel.dart';
import 'package:material_ui/material_ui.dart';

/// The card of [sample]: its number, title and note, the chart, and the
/// code under the chart.
class const SampleCard({
  /// The number of the sample on the page.
  required final int number,

  /// The sample of the card.
  required final Sample sample,

  /// The asset folder of the source file of [sample].
  required final String folder,
  super.key,
}) extends StatelessWidget {
  /// Creates the card of [sample], with the number [number] and the source
  /// file in [folder].
  this;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final title = Text('$number. ${sample.title}', style: text.titleLarge);
    final note = Text(
      '${sample.note}  ·  ${sample.file}.dart',
      style: text.bodyMedium?.copyWith(color: const Color(0xff64748b)),
    );
    final body = [
      sample.child,
      const SizedBox(height: 12),
      CodePanel(path: '$folder/${sample.file}.dart'),
    ];
    if (sample.accepted) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: ExpansionTile(
          key: ValueKey('accepted.${sample.file}'),
          leading: const Icon(Icons.check_circle, color: Color(0xff16a34a)),
          title: title,
          subtitle: note,
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 12),
          shape: const Border(),
          collapsedShape: const Border(),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: body,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: 4),
          note,
          const SizedBox(height: 12),
          ...body,
        ],
      ),
    );
  }
}
