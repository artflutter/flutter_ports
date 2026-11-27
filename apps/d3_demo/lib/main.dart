// Original code, not ported from D3: entry point of the combined D3 demo app.

import 'package:d3_demo/pages/array_page.dart';
import 'package:d3_demo/pages/chord_page.dart';
import 'package:d3_demo/pages/chromatic_page.dart';
import 'package:d3_demo/pages/color_page.dart';
import 'package:d3_demo/pages/contour_page.dart';
import 'package:d3_demo/pages/format_page.dart';
import 'package:d3_demo/pages/hierarchy_page.dart';
import 'package:d3_demo/pages/interpolate_page.dart';
import 'package:d3_demo/pages/path_page.dart';
import 'package:d3_demo/pages/quadtree_page.dart';
import 'package:d3_demo/pages/shape_page.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final tab = switch (Uri.base.queryParameters['tab']) {
    'interpolate' => 1,
    'chromatic' => 2,
    'path' => 3,
    'shape' => 4,
    'format' => 5,
    'array' => 6,
    'contour' => 7,
    'quadtree' => 8,
    'hierarchy' => 9,
    'chord' => 10,
    _ => 0,
  };
  runApp(D3DemoApp(initialTab: tab));
}

/// Interactive showcase for `flutter_d3_color_port`,
/// `flutter_d3_interpolate_port`, `flutter_d3_scale_chromatic_port`,
/// `flutter_d3_path_port`, `flutter_d3_shape_port`,
/// `flutter_d3_format_port`, `flutter_d3_array_port`,
/// `flutter_d3_contour_port`, `flutter_d3_quadtree_port`,
/// `flutter_d3_hierarchy_port` and `flutter_d3_chord_port`.
class const D3DemoApp({
  /// Initial destination index (`0` = Color, `1` = Interpolate,
  /// `2` = Chromatic, `3` = Path, `4` = Shape, `5` = Format, `6` = Array,
  /// `7` = Contour, `8` = Quadtree, `9` = Hierarchy, `10` = Chord).
  final int initialTab = 0,
  super.key,
}) extends StatefulWidget {
  /// Creates the demo app starting on [initialTab] (`0..10`).
  this;

  @override
  State<D3DemoApp> createState() => _D3DemoAppState();
}

class _D3DemoAppState() extends State<D3DemoApp> {
  late int _index = widget.initialTab.clamp(0, 10);
  ThemeMode _themeMode = ThemeMode.light;

  static const _destinations = <(String, String, IconData, IconData)>[
    ('Color', 'd3-color', Icons.palette_outlined, Icons.palette),
    (
      'Interpolate',
      'd3-interpolate',
      Icons.animation_outlined,
      Icons.animation,
    ),
    (
      'Chromatic',
      'd3-scale-chromatic',
      Icons.gradient_outlined,
      Icons.gradient,
    ),
    ('Path', 'd3-path', Icons.timeline_outlined, Icons.timeline),
    ('Shape', 'd3-shape', Icons.pie_chart_outline, Icons.pie_chart),
    ('Format', 'd3-format', Icons.pin_outlined, Icons.pin),
    ('Array', 'd3-array', Icons.bar_chart_outlined, Icons.bar_chart),
    ('Contour', 'd3-contour', Icons.terrain_outlined, Icons.terrain),
    ('Quadtree', 'd3-quadtree', Icons.grid_4x4_outlined, Icons.grid_4x4),
    (
      'Hierarchy',
      'd3-hierarchy',
      Icons.account_tree_outlined,
      Icons.account_tree,
    ),
    ('Chord', 'd3-chord', Icons.donut_large_outlined, Icons.donut_large),
  ];

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6D28D9)),
    );
    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B5CF6),
        brightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'D3 for Flutter',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 780;
          final body = IndexedStack(
            index: _index,
            children: const [
              ColorDemoPage(),
              InterpolateDemoPage(),
              ChromaticDemoPage(),
              PathDemoPage(),
              ShapeDemoPage(),
              FormatDemoPage(),
              ArrayDemoPage(),
              ContourDemoPage(),
              QuadtreeDemoPage(),
              HierarchyDemoPage(),
              ChordDemoPage(),
            ],
          );
          final (_, pkg, _, _) = _destinations[_index];

          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  const Text('D3 for Flutter'),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      pkg,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: _themeMode == ThemeMode.dark
                      ? 'Switch to light theme'
                      : 'Switch to dark theme',
                  icon: Icon(
                    _themeMode == ThemeMode.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _themeMode = _themeMode == ThemeMode.dark
                          ? ThemeMode.light
                          : ThemeMode.dark;
                    });
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: wide
                ? Row(
                    children: [
                      LayoutBuilder(
                        builder: (context, railConstraints) =>
                            SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: railConstraints.maxHeight,
                                ),
                                child: IntrinsicHeight(
                                  child: NavigationRail(
                                    selectedIndex: _index,
                                    labelType: NavigationRailLabelType.all,
                                    onDestinationSelected: (i) =>
                                        setState(() => _index = i),
                                    destinations: [
                                      for (final (label, _, icon, active)
                                          in _destinations)
                                        NavigationRailDestination(
                                          icon: Icon(icon),
                                          selectedIcon: Icon(active),
                                          label: Text(label),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: body),
                    ],
                  )
                : body,
            bottomNavigationBar: wide
                ? null
                : NavigationBar(
                    selectedIndex: _index,
                    onDestinationSelected: (i) => setState(() => _index = i),
                    destinations: [
                      for (final (label, _, icon, active) in _destinations)
                        NavigationDestination(
                          icon: Icon(icon),
                          selectedIcon: Icon(active),
                          label: label,
                        ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
