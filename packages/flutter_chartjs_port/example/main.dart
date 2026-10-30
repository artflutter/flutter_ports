// Original code, not ported from Chart.js: the example app of the package.

/// A small app with one bar chart (Chart.js ADR 0047, decision 5): the typed
/// config of Chart.js ADR 0052, a data update with `setState` and a click
/// callback with `int` indexes.
///
/// Run it from a Flutter app of your own: copy this file to `lib/main.dart`
/// and add `flutter_chartjs_port` to the dependencies.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

void main() {
  // Chart.js registers nothing by itself. Register the components before the
  // first chart: all of them, or only the ones of your chart types.
  Chart.register(registerables);
  runApp(const ExampleApp());
}

/// The example app: one bar chart that follows the platform brightness.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_chartjs_port',
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: const VotesPage(),
    );
  }
}

/// A page with a bar chart and a button that changes its data.
class VotesPage extends StatefulWidget {
  /// Creates the page.
  const VotesPage({super.key});

  @override
  State<VotesPage> createState() => _VotesPageState();
}

class _VotesPageState extends State<VotesPage> {
  final Random _random = Random();

  /// The data of the chart. The chart reads this List with no copy.
  List<double> _votes = [12, 19, 3, 5, 2, 3];

  /// New votes in a new List: the next build gives the chart a new config,
  /// and the bars animate to the new values.
  void _shuffle() => setState(() {
    _votes = [for (final _ in _votes) _random.nextInt(20).toDouble()];
  });

  /// A click on a bar shows its votes. The indexes of a hit are `int`s.
  void _onClick(ChartEventDetails details) {
    final hit = details.hits.firstOrNull;
    if (hit == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_votes[hit.index].round()} votes')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_chartjs_port')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // In a scroll view, the width and the aspect ratio of the chart (2
          // for a bar chart) give the height. A build with the same votes
          // gives an equal config and no update.
          ChartView(
            config: ChartConfig(
              type: .bar,
              labels: const [
                'Red',
                'Blue',
                'Yellow',
                'Green',
                'Purple',
                'Orange',
              ],
              datasets: [
                BarDataset(label: '# of Votes', data: _votes, borderWidth: 1),
              ],
              scales: const {'y': LinearAxis(beginAtZero: true)},
              onClick: _onClick,
            ),
            theme: dark
                ? const ChartThemeData.dark()
                : const ChartThemeData.light(),
            semanticLabel: 'Bar chart of the votes for six colors',
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: _shuffle,
              child: const Text('New votes'),
            ),
          ),
        ],
      ),
    );
  }
}
