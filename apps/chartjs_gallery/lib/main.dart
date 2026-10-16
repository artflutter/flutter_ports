import 'package:flutter/material.dart';
import 'package:flutter_chartjs/flutter_chartjs.dart';

void main() {
  runApp(const GalleryApp());
}

/// The chart types Chart.js ships, in the order of its documentation.
const chartTypes = <String>[
  'Area',
  'Bar',
  'Bubble',
  'Doughnut and Pie',
  'Line',
  'Mixed',
  'Polar Area',
  'Radar',
  'Scatter',
];

/// Gallery of Chart.js samples rendered by `flutter_chartjs`.
///
/// Every chart type is listed up front and marked as pending until its port
/// lands, so the gallery doubles as a visual progress tracker.
class GalleryApp extends StatelessWidget {
  /// Creates the gallery.
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chart.js for Flutter',
      theme: ThemeData(colorSchemeSeed: const Color(0xFFFF6384)),
      home: Scaffold(
        appBar: AppBar(title: const Text('Chart.js for Flutter')),
        body: ListView(
          children: [
            const ListTile(
              title: Text('Tracking Chart.js $chartJsVersion'),
              subtitle: Text('Native port in progress. Nothing renders yet.'),
            ),
            for (final type in chartTypes)
              ListTile(
                enabled: false,
                leading: const Icon(Icons.hourglass_empty),
                title: Text(type),
                subtitle: const Text('Not ported yet'),
              ),
          ],
        ),
      ),
    );
  }
}
