import 'package:chartjs_gallery/demo/color_demo.dart';
import 'package:chartjs_gallery/demo/easing_demo.dart';
import 'package:chartjs_gallery/demo/options_demo.dart';
import 'package:chartjs_gallery/demo/spline_demo.dart';
import 'package:chartjs_gallery/demo/ticks_demo.dart';
import 'package:flutter/material.dart';

/// The tabs of [HelpersDemoPage]: label, icon and content.
final List<({String label, IconData icon, Widget Function() build})>
helpersDemoTabs = [
  (label: 'Easing', icon: Icons.show_chart, build: EasingDemo.new),
  (label: 'Colors', icon: Icons.palette_outlined, build: ColorDemo.new),
  (label: 'Ticks', icon: Icons.straighten, build: TicksDemo.new),
  (label: 'Splines', icon: Icons.gesture, build: SplineDemo.new),
  (label: 'Options', icon: Icons.tune, build: OptionsDemo.new),
];

/// A live demo of the phase 2 port: the helpers under the charts.
///
/// Nothing here is a chart: the canvas layer comes in phase 3. Each tab
/// calls the ported Chart.js code (`helpers.easing`, `@kurkle/color` and
/// `helpers.color`, `core.ticks` and `helpers.intl`, `helpers.curve`,
/// `helpers.config`, `core.defaults` and `helpers.options`) and draws the
/// results with Flutter widgets and `CustomPaint`.
class HelpersDemoPage extends StatelessWidget {
  /// Creates the demo page.
  const HelpersDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: helpersDemoTabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Phase 2: ported helpers'),
          bottom: TabBar(
            // Five short labels fit a 360 px phone; a wider text scale
            // scrolls the bar from its start, not from a centered middle.
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            tabs: [
              for (final tab in helpersDemoTabs)
                Tab(icon: Icon(tab.icon), text: tab.label),
            ],
          ),
        ),
        body: TabBarView(
          // Horizontal drags belong to the spline canvas and the sliders.
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final tab in helpersDemoTabs) _KeepAlive(child: tab.build()),
          ],
        ),
      ),
    );
  }
}

/// Keeps a tab's state (locale, dragged points, typed color) when the user
/// switches to another tab and back.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
