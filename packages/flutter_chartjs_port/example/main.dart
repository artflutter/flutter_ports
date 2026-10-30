// Original code, not ported from Chart.js: the example app of the package.

/// A small app with one bar chart (Chart.js ADR 0047, decision 5).
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

  /// The data of the chart. The chart reads this List, and the button
  /// changes its items in place.
  final List<double> _votes = [12, 19, 3, 5, 2, 3];

  /// The Chart.js configuration. It is made once and is not `const`:
  /// Chart.js writes into its `data` and `options` Maps. A nested Map has
  /// the type `<String, Object?>`, because Chart.js also writes into the
  /// dataset Maps (for example the colors of the `colors` plugin).
  late final Map<String, Object?> _config = {
    'type': 'bar',
    'data': <String, Object?>{
      'labels': ['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
      'datasets': [
        <String, Object?>{
          'label': '# of Votes',
          'data': _votes,
          'borderWidth': 1,
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'y': <String, Object?>{'beginAtZero': true},
      },
      'onClick': (ChartEvent event, List<ActiveElement> elements, Chart chart) {
        if (elements.isNotEmpty) {
          // A Chart.js index is a JavaScript number: a double.
          final index = elements.first.index.toInt();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_votes[index].round()} votes')),
          );
        }
      },
    },
  };

  /// The chart, from `onChartCreated`.
  Chart? _chart;

  void _shuffle() {
    for (var i = 0; i < _votes.length; i++) {
      _votes[i] = _random.nextInt(20).toDouble();
    }
    // A change in place needs an explicit update, as in Chart.js.
    _chart?.update();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_chartjs_port')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // In a scroll view, the width and the aspect ratio of the options
          // (2 for a bar chart) give the height.
          ChartView.raw(
            config: _config,
            theme: dark
                ? const ChartThemeData.dark()
                : const ChartThemeData.light(),
            semanticLabel: 'Bar chart of the votes for six colors',
            onChartCreated: (chart) => _chart = chart,
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
