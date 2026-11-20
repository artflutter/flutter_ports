// Original code, not ported from Chart.js: the entry of the ergonomics app.

import 'package:chartjs_ergonomics/samples/line/index.dart';
import 'package:chartjs_ergonomics/ui/code_panel.dart';
import 'package:chartjs_ergonomics/ui/sample_card.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Chart.register(registerables);
  runApp(const ErgonomicsApp());
}

/// The app: one page of line samples, each a chart with its code.
class const ErgonomicsApp({super.key}) extends StatelessWidget {
  /// Creates the app.
  this;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Chart.js API ergonomics',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: const Color(0xff4f46e5),
      scaffoldBackgroundColor: Colors.white,
    ),
    home: const SamplesPage(),
  );
}

/// The line samples in one scroll, the shared data first.
class const SamplesPage({super.key}) extends StatelessWidget {
  /// Creates the page.
  this;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Line chart: typed API samples')),
    body: ListView.builder(
      key: const ValueKey('samples'),
      padding: const EdgeInsets.symmetric(vertical: 24),
      itemCount: lineSamples.length + 1,
      itemBuilder: (context, index) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: index == 0
                ? const _SharedData()
                : SampleCard(
                    key: ValueKey('sample.${lineSamples[index - 1].file}'),
                    number: index,
                    sample: lineSamples[index - 1],
                    folder: lineFolder,
                  ),
          ),
        ),
      ),
    ),
  );
}

class const _SharedData() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Shared data', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Text(
          'The samples below use these names. Each sample shows one feature.',
          style: TextStyle(color: Color(0xff64748b)),
        ),
        const SizedBox(height: 12),
        const CodePanel(path: '$lineFolder/data.dart'),
      ],
    ),
  );
}
