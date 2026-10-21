import 'package:chartjs_gallery/demo/axes_demo.dart';
import 'package:chartjs_gallery/demo/canvas_demo.dart';
import 'package:chartjs_gallery/demo/core_demo.dart';
import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:chartjs_gallery/demo/elements_demo.dart';
import 'package:chartjs_gallery/demo/events_demo.dart';
import 'package:chartjs_gallery/demo/stress_demo.dart';
import 'package:chartjs_gallery/demo/text_demo.dart';
import 'package:flutter/material.dart';

/// The tabs of [CanvasHostDemoPage]: key, label, icon and content.
final List<({String key, String label, IconData icon, Widget Function() build})>
canvasHostDemoTabs = [
  (
    key: 'canvas',
    label: 'Canvas',
    icon: Icons.brush_outlined,
    build: CanvasDemo.new,
  ),
  (
    key: 'events',
    label: 'Events',
    icon: Icons.touch_app_outlined,
    build: EventsDemo.new,
  ),
  (
    key: 'text',
    label: 'Text',
    icon: Icons.text_fields,
    build: TextDemo.new,
  ),
  (key: 'stress', label: 'Stress', icon: Icons.speed, build: StressDemo.new),
  (
    key: 'elements',
    label: 'Elements',
    icon: Icons.bar_chart,
    build: ElementsDemo.new,
  ),
  (key: 'core', label: 'Core', icon: Icons.hub_outlined, build: CoreDemo.new),
  (key: 'axes', label: 'Axes', icon: Icons.straighten, build: AxesDemo.new),
];

/// A live demo of the phase 3 to 7 ports: the canvas layer, the canvas and
/// DOM helpers, the Flutter platform, the internal chart host, the
/// elements, the core, the scales and the controllers.
///
/// Each drawing is a chart host (`ChartHost`) that shows a
/// `UiCanvasElement`. In the first five tabs, a small demo chart makes the
/// platform calls of `core.controller` (`acquireContext`, `getMaximumSize`,
/// `retinaScale`, `addEventListener`) and draws with the ported
/// `helpers.canvas`, `helpers.rtl` and `helpers.dom`. The Elements tab draws
/// the ported `BarElement`, `LineElement`, `PointElement` and `ArcElement` of
/// phase 4, and tests the pointer with their `inRange`. The `chart` mode of
/// the Stress tab runs a real `Chart` of each of the eight ported
/// controllers of phase 7 (Chart.js ADR 0031). The Core tab, the Axes tab
/// and the `axes` mode of the Stress tab run a `LineController` chart, the
/// last two on the scales of phase 6.
class CanvasHostDemoPage extends StatelessWidget {
  /// Creates the demo page.
  const CanvasHostDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: canvasHostDemoTabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Phase 3: canvas and host'),
          // The tabs show their icons only, with the label as a tooltip:
          // the seven tabs fit a phone without a horizontal scroll (Chart.js
          // ADR 0031, section 10).
          bottom: TabBar(
            tabs: [
              for (final tab in canvasHostDemoTabs)
                Tooltip(
                  message: tab.label,
                  child: Tab(
                    key: ValueKey('phase3.tab.${tab.key}'),
                    icon: Icon(tab.icon),
                  ),
                ),
            ],
          ),
        ),
        body: DemoTabBarView(
          children: [for (final tab in canvasHostDemoTabs) tab.build()],
        ),
      ),
    );
  }
}
