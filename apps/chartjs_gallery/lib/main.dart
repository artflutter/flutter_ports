import 'package:chartjs_gallery/helpers_demo.dart';
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
/// lands, so the gallery doubles as a visual progress tracker. Above the
/// list, a demo page shows the ported helpers of phase 2.
class GalleryApp extends StatelessWidget {
  /// Creates the gallery.
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chart.js for Flutter',
      theme: ThemeData(colorSchemeSeed: const Color(0xFFFF6384)),
      home: const GalleryHome(),
    );
  }
}

/// The home page of the gallery: the helpers demo, then the chart types.
class GalleryHome extends StatelessWidget {
  /// Creates the home page.
  const GalleryHome({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Chart.js for Flutter')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Tracking Chart.js $chartJsVersion'),
            subtitle: Text('Native port in progress. No chart renders yet.'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Card(
              color: scheme.primaryContainer,
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                key: const ValueKey('gallery.helpersDemo'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Icon(
                  Icons.play_circle_fill,
                  size: 40,
                  color: scheme.primary,
                ),
                title: const Text('Phase 2: ported helpers — live demo'),
                subtitle: const Text(
                  'Easing, colors, tick labels, splines and options, '
                  'computed by the ported Chart.js code.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HelpersDemoPage(),
                  ),
                ),
              ),
            ),
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
    );
  }
}
