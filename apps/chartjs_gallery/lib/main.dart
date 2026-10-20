import 'package:chartjs_gallery/canvas_host_demo.dart';
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
/// list, two demo pages show the ported code: the canvas layer and the chart
/// host of phase 3 with the elements of phase 4, the core of phase 5 and the
/// scales of phase 6, and the helpers of phase 2.
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

/// The home page of the gallery: the two demos, then the chart types.
class GalleryHome extends StatelessWidget {
  /// Creates the home page.
  const GalleryHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chart.js for Flutter')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Tracking Chart.js $chartJsVersion'),
            subtitle: Text(
              'Native port in progress. The canvas layer, the chart host, '
              'the elements, the core and the scales draw, but no chart type '
              'renders yet.',
            ),
          ),
          _DemoEntry(
            entryKey: const ValueKey('gallery.canvasHostDemo'),
            icon: Icons.brush,
            title: 'Phase 3: canvas layer and chart host — live demo',
            subtitle:
                'Point styles, text, gradients and clipping on the dart:ui '
                'canvas. Input events, sizing and a stress test in the chart '
                'host. Phase 4 elements: bars, a line with points and a '
                'doughnut of arcs, with hover and hit tests. Phase 5 core: a '
                'real Chart with interaction modes and animated hover. '
                'Phase 6 scales: linear, logarithmic, category and time axes '
                'with ticks, rotation, auto skip and the pixel mapping of '
                'the pointer.',
            builder: (_) => const CanvasHostDemoPage(),
          ),
          _DemoEntry(
            entryKey: const ValueKey('gallery.helpersDemo'),
            icon: Icons.play_circle_fill,
            title: 'Phase 2: ported helpers — live demo',
            subtitle:
                'Easing, colors, tick labels, splines and options, '
                'computed by the ported Chart.js code.',
            builder: (_) => const HelpersDemoPage(),
          ),
          const SizedBox(height: 4),
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

/// A highlighted entry of the home page that opens a demo page.
class _DemoEntry extends StatelessWidget {
  const _DemoEntry({
    required this.entryKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final Key entryKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Card(
        color: scheme.primaryContainer,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          key: entryKey,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(icon, size: 40, color: scheme.primary),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: builder)),
        ),
      ),
    );
  }
}
