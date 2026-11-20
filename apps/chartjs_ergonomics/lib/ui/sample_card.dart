// Original code, not ported from Chart.js: the card of one sample.

import 'package:chartjs_ergonomics/sample.dart';
import 'package:chartjs_ergonomics/ui/code_panel.dart';
import 'package:material_ui/material_ui.dart';

/// The card of [sample]: its number, title and note, the chart, and the
/// code under the chart.
class const SampleCard({
  required final int number,
  required final Sample sample,
  required final String folder,
  super.key,
}) extends StatelessWidget {
  /// Creates the card of [sample], with the number [number] and the source
  /// file in [folder].
  this;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('$number. ${sample.title}', style: text.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${sample.note}  ·  ${sample.file}.dart',
            style: text.bodyMedium?.copyWith(color: const Color(0xff64748b)),
          ),
          const SizedBox(height: 12),
          sample.child,
          const SizedBox(height: 12),
          CodePanel(path: '$folder/${sample.file}.dart'),
        ],
      ),
    );
  }
}
