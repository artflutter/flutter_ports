import 'package:chartjs_gallery/canvas_host_demo.dart';
import 'package:chartjs_gallery/charts/chart_type_page.dart';
import 'package:chartjs_gallery/charts/chart_types.dart';
import 'package:chartjs_gallery/helpers_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

void main() {
  runApp(const GalleryApp());
}

/// The light theme of the gallery.
final ThemeData galleryLightTheme = ThemeData(
  colorSchemeSeed: const Color(0xFFFF6384),
);

/// The dark theme of the gallery. The app takes it when the platform
/// brightness is dark.
final ThemeData galleryDarkTheme = ThemeData(
  colorSchemeSeed: const Color(0xFFFF6384),
  brightness: Brightness.dark,
);

/// The chart theme of [galleryDarkTheme]: the dark preset with the surface
/// of the dark color scheme (Chart.js ADR 0050).
///
/// One instance for the life of the app: the compiled theme is kept for
/// each instance, and the `==` of the theme skips a rebuild with the same
/// brightness.
final ChartThemeData galleryDarkChartTheme = const ChartThemeData.dark()
    .copyWith(surface: galleryDarkTheme.colorScheme.surface);

/// Gallery of Chart.js samples rendered by `flutter_chartjs_port`.
///
/// The list has each chart type of the Chart.js docs (`galleryChartTypes`).
/// Each tile opens a page with the charts of the docs blocks of its type
/// (Chart.js ADR 0031). Each page shows the full chart of its docs blocks,
/// with the plugins of `registerables`. Above the list, two demo pages show
/// the ported code: the canvas layer and the chart host of phase 3 with the
/// elements of phase 4, the core of phase 5, the scales of phase 6, the
/// controllers of phase 7 and the plugins of phase 8, and the helpers of
/// phase 2.
///
/// The app follows the platform brightness. The builder of the app puts a
/// [ChartTheme] above each route: the light preset in the light theme, and
/// [galleryDarkChartTheme] in the dark theme (Chart.js ADR 0050). A change
/// of the brightness switches the theme of each chart once, at the middle
/// of the theme animation of the app, where the brightness of the animated
/// theme changes.
class GalleryApp extends StatelessWidget {
  /// Creates the gallery.
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chart.js for Flutter',
      theme: galleryLightTheme,
      darkTheme: galleryDarkTheme,
      builder: (context, child) => ChartTheme(
        data: Theme.of(context).brightness == Brightness.dark
            ? galleryDarkChartTheme
            : const ChartThemeData.light(),
        child: child!,
      ),
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
              'The chart types render through the ported controllers and '
              'plugins.',
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
          for (final entry in galleryChartTypes)
            ListTile(
              key: ValueKey('gallery.type.${entry.stem}'),
              leading: const Icon(Icons.check_circle_outline),
              title: Text(entry.title),
              subtitle: Text('docs/charts/${entry.stem}.md'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChartTypePage(entry: entry),
                ),
              ),
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
