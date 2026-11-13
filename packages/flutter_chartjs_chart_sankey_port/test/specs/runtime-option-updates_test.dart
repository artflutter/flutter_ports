// Ported from chartjs-chart-sankey v0.19.1 test/specs/runtime-option-updates.spec.js (MIT, Jukka Kurkela).
// ignore_for_file: file_names
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart' show Chart, JsObjectFace;
import 'package:flutter_test/flutter_test.dart';

// Same shape as the node-padding-even fixture: four sources feeding two
// middle nodes (M1, M2) is what makes 'auto' vs 'even' nodePaddingMode
// produce a measurably different gap between M1 and M2 -- 'auto' inflates
// the gap between them to clear the nodes stacked above M2 in column 0,
// 'even' does not.
List<Object?> _nodePaddingModeData() => <Object?>[
  <String, Object?>{'flow': 10, 'from': 'S1', 'to': 'M1'},
  <String, Object?>{'flow': 6, 'from': 'S2', 'to': 'M1'},
  <String, Object?>{'flow': 14, 'from': 'S3', 'to': 'M2'},
  <String, Object?>{'flow': 4, 'from': 'S4', 'to': 'M2'},
  <String, Object?>{'flow': 10, 'from': 'M1', 'to': 'T1'},
  <String, Object?>{'flow': 6, 'from': 'M1', 'to': 'T2'},
  <String, Object?>{'flow': 4, 'from': 'M2', 'to': 'T2'},
  <String, Object?>{'flow': 14, 'from': 'M2', 'to': 'T3'},
];

// `nodePaddingMode` and `nodePadding` are deliberately never set on the
// dataset itself: a dataset-level value always outranks a chart-level one in
// Chart.js's option resolution, so a dataset-level value set at creation
// would permanently shadow the chart-level runtime changes this test makes
// afterwards. Leaving them unset here means the controller's resolved
// `this.options.nodePaddingMode` / `.nodePadding` come from `chart.options`.
Chart _buildChart(Map<String, Object?> chartOptionOverrides) => acquireChart(
  {
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{'data': _nodePaddingModeData()},
      ],
    },
    'options': <String, Object?>{
      'animation': false,
      'devicePixelRatio': 1,
      'maintainAspectRatio': false,
      'nodePadding': 20,
      ...chartOptionOverrides,
    },
    'type': 'sankey',
  },
  {
    'canvas': <String, Object?>{'height': 400, 'width': 700},
  },
);

SankeyController _controller(Chart chart) =>
    chart.getDatasetMeta(0).controller! as SankeyController;

// The gap between M1 and M2 in the middle column, in the same flow-value
// units that `nodePadding` (a CSS pixel option) gets scaled into -- so it's
// directly comparable between charts regardless of which one triggered the
// layout, as long as canvas size and data are identical. Order-independent
// (the layout algorithm, not this test, decides which of the two ends up on
// top): it always subtracts the lower node's `y` from the upper node's `y +
// size`, whichever way round that is.
double _middleColumnGap(Chart chart) {
  final nodes = _controller(chart).nodes;
  final m1 = nodes['M1']!;
  final m2 = nodes['M2']!;
  final (top, bottom) = m1.y! <= m2.y! ? (m1, m2) : (m2, m1);
  return bottom.y! - (top.y! + top.size);
}

// Chart.js's per-dataset options resolver (`_createResolver`/`_attachContext`
// in chart.js's `helpers.dataset.js`) caches each property on its very first
// read, for that resolver instance's whole lifetime. `SankeyController`
// itself only ever reads `nodePaddingMode`/`nodePadding` once per update,
// while parsing -- and it always does so on a resolver that has never had
// that property read from it before, so in isolation it would always look
// fresh, bug or no bug. What actually exposes the staleness is an *external*
// read of `controller.options.<prop>` landing between the option change and
// the following `update()`: that read is what primes the cache with the
// about-to-be-stale value, for parsing to pick up next cycle.
//
// This is not a test-only contrivance. It's what a plugin's lifecycle hook,
// a devtools inspection (`chart.getDatasetMeta(0).controller.options` typed
// into a console), or ordinary diagnostic/logging code would do -- reading a
// dataset's resolved options is a completely normal thing to do with
// Chart.js's public API. (We found this the hard way: our first attempt at
// this very test read `nodePaddingMode` inside a logging wrapper around
// `configure()`, purely to print it, and that accidental read was enough to
// manufacture the failure below.)
//
// DO NOT remove this call as unused/dead code. Without it, `chart.update()`
// alone is always correct even on the unfixed controller -- see the root
// cause discussion in this PR -- and the assertions below pass regardless of
// whether the fix is present, silently losing the regression coverage.
void _readResolvedOptionsLikeAPluginOrDevtoolsWould(Chart chart, String prop) {
  // The read by name of the resolver of the dataset options.
  // ignore: unnecessary_statements
  (_controller(chart).options as JsObjectFace)[prop];
}

/// `chart.options[prop] = value`.
void _setOption(Chart chart, String prop, Object? value) {
  (chart.options as JsObjectFace)[prop] = value;
}

void main() {
  group('runtime option updates (#configure-before-parse)', () {
    testWidgets('applies nodePaddingMode changes on the very next update, '
        'even after something reads the resolved options in between', (
      tester,
    ) async {
      // Canonical gaps, each from a chart that had the given mode from
      // creation -- never toggled at runtime. These are what a correctly
      // updated chart must match after switching.
      final evenGap = _middleColumnGap(
        _buildChart({'nodePaddingMode': SankeyNodePaddingMode.even}),
      );
      final autoGap = _middleColumnGap(
        _buildChart({'nodePaddingMode': SankeyNodePaddingMode.auto}),
      );

      // 'auto' (the default) must actually inflate the gap here, or this
      // test is not exercising the cross-column behavior it claims to.
      expect(autoGap, greaterThan(evenGap + 1));

      final chart = _buildChart({
        'nodePaddingMode': SankeyNodePaddingMode.auto,
      });
      _readResolvedOptionsLikeAPluginOrDevtoolsWould(chart, 'nodePaddingMode');

      // Alternate several times: the bug only shows up from the second
      // switch onward, because the very first read after chart creation
      // primes the resolver that's still current (unreplaced) for the first
      // toggle below.
      for (var i = 0; i < 3; i++) {
        _setOption(chart, 'nodePaddingMode', SankeyNodePaddingMode.even);
        chart.update();
        _readResolvedOptionsLikeAPluginOrDevtoolsWould(
          chart,
          'nodePaddingMode',
        );
        expect(
          _middleColumnGap(chart),
          closeTo(evenGap, 5e-7),
          reason: "iteration $i, mode 'even'",
        );

        _setOption(chart, 'nodePaddingMode', SankeyNodePaddingMode.auto);
        chart.update();
        _readResolvedOptionsLikeAPluginOrDevtoolsWould(
          chart,
          'nodePaddingMode',
        );
        expect(
          _middleColumnGap(chart),
          closeTo(autoGap, 5e-7),
          reason: "iteration $i, mode 'auto'",
        );
      }
    });

    testWidgets('applies a nodePadding number change on the very next '
        'update, even after something reads the resolved options in '
        'between', (tester) async {
      final smallGap = _middleColumnGap(
        _buildChart({
          'nodePadding': 10,
          'nodePaddingMode': SankeyNodePaddingMode.even,
        }),
      );
      final largeGap = _middleColumnGap(
        _buildChart({
          'nodePadding': 40,
          'nodePaddingMode': SankeyNodePaddingMode.even,
        }),
      );
      expect(largeGap, greaterThan(smallGap + 1));

      final chart = _buildChart({
        'nodePadding': 10,
        'nodePaddingMode': SankeyNodePaddingMode.even,
      });
      _readResolvedOptionsLikeAPluginOrDevtoolsWould(chart, 'nodePadding');
      expect(_middleColumnGap(chart), closeTo(smallGap, 5e-7));

      for (var i = 0; i < 3; i++) {
        _setOption(chart, 'nodePadding', 40);
        chart.update();
        _readResolvedOptionsLikeAPluginOrDevtoolsWould(chart, 'nodePadding');
        expect(
          _middleColumnGap(chart),
          closeTo(largeGap, 5e-7),
          reason: 'iteration $i, padding 40',
        );

        _setOption(chart, 'nodePadding', 10);
        chart.update();
        _readResolvedOptionsLikeAPluginOrDevtoolsWould(chart, 'nodePadding');
        expect(
          _middleColumnGap(chart),
          closeTo(smallGap, 5e-7),
          reason: 'iteration $i, padding 10',
        );
      }
    });
  });
}
