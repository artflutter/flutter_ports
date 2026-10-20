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
];

/// A live demo of the phase 3, 4 and 5 ports: the canvas layer, the canvas
/// and DOM helpers, the Flutter platform, the internal chart host, the
/// elements and the core.
///
/// Each drawing is a chart host (`ChartHost`) that shows a
/// `UiCanvasElement`. In the first five tabs, a small demo chart makes the
/// platform calls of `core.controller` (`acquireContext`, `getMaximumSize`,
/// `retinaScale`, `addEventListener`) and draws with the ported
/// `helpers.canvas`, `helpers.rtl` and `helpers.dom`. The Elements tab draws
/// the ported `BarElement`, `LineElement`, `PointElement` and `ArcElement` of
/// phase 4, and tests the pointer with their `inRange`. The Core tab and the
/// `chart` mode of the Stress tab run a real `Chart` of phase 5 with a
/// gallery controller. No chart type renders yet: the scales and the
/// controllers come in phases 6 and 7.
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
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 14),
            tabs: [
              for (final tab in canvasHostDemoTabs)
                Tab(
                  key: ValueKey('phase3.tab.${tab.key}'),
                  icon: Icon(tab.icon),
                  text: tab.label,
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
