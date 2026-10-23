// Original code, not ported from Chart.js: tests of the stress mode plugins.

import 'dart:convert';

import 'package:chartjs_gallery/bench/chart_bench.dart';
import 'package:chartjs_gallery/canvas_host_demo.dart';
import 'package:chartjs_gallery/demo/stress_demo.dart';
import 'package:chartjs_gallery/main_stress.dart';
import 'package:flutter/material.dart' hide Tooltip;
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/platform/chart_host.dart'
    show
        addCanvasEventListener,
        hasCanvasEventListener,
        removeCanvasEventListener;
import 'package:flutter_chartjs_port/src/platform/native_event.dart'
    show NativeEvent;
import 'package:flutter_chartjs_port/src/platform/platform.flutter.dart'
    show FlutterPlatform;
import 'package:flutter_chartjs_port/src/plugins/plugin.legend.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.tooltip.dart';
import 'package:flutter_test/flutter_test.dart';

import 'stress_controls.dart';

/// The points of each dataset in these tests: small, so that a frame is
/// fast.
const int _n = 24;

/// A Pixel 8a: 412 x 915 logical pixels at DPR 2.625.
const Size _phone = Size(412, 915);

/// Each case of the mode plugins: each scene, and the bases and the
/// dataset counts of the benchmark cases.
const List<StressPluginCase> _cases = [
  StressPluginCase(StressPluginScene.legend),
  StressPluginCase(StressPluginScene.legend, legend: false),
  StressPluginCase(StressPluginScene.title),
  StressPluginCase(StressPluginScene.hover),
  StressPluginCase(StressPluginScene.hover, tooltip: false),
  StressPluginCase(StressPluginScene.hover, datasets: 3),
  StressPluginCase(StressPluginScene.still),
  StressPluginCase(StressPluginScene.still, tooltip: false),
  StressPluginCase(StressPluginScene.fade),
  StressPluginCase(StressPluginScene.fade, datasets: 3),
  StressPluginCase(StressPluginScene.gaps),
  StressPluginCase(StressPluginScene.stack),
  StressPluginCase(StressPluginScene.radar),
];

/// Pumps [count] frames of 20 ms. The loop runs, so pumpAndSettle would not
/// return.
Future<void> _frames(WidgetTester tester, [int count = 4]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Pumps a stress tab in the mode plugins with the case [pluginCase] and
/// the call [call]. It gives the list that receives the published figures.
Future<List<StressStats>> _pumpPlugins(
  WidgetTester tester,
  StressPluginCase pluginCase, {
  StressChartCall call = StressChartCall.draw,
  int n = _n,
  bool autoStart = true,
}) async {
  final stats = <StressStats>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StressDemo(
          initialMode: StressMode.plugins,
          initialN: n,
          initialM: 0,
          initialCall: call,
          initialPluginCase: pluginCase,
          autoStart: autoStart,
          onStats: stats.add,
        ),
      ),
    ),
  );
  return stats;
}

/// Lets one window of the figures pass: the window is 500 ms of the
/// Stopwatch, real time, so runAsync lets it pass. The frame after it
/// publishes the figures.
Future<void> _window(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 520)),
  );
  await _frames(tester, 3);
}

/// The state of the stress tab.
StressDemoState _state(WidgetTester tester) =>
    tester.state<StressDemoState>(find.byType(StressDemo));

/// The chart of the stress tab.
Chart _chart(WidgetTester tester) => _state(tester).debugChart!;

/// The active index of the tooltip of [chart].
Object? _tooltipIndex(Chart chart) =>
    (chart.tooltip! as Tooltip).getActiveElements().first.index;

/// The config of the benchmark case of [pluginCase] with [call] for [n]
/// points, without its inline plugins.
Map<String, Object?> _benchConfig(
  StressPluginCase pluginCase,
  StressChartCall call,
  int n,
) {
  final config = stressPluginBenchCase(pluginCase, call).scene(n).config;
  return {...config}..remove('plugins');
}

/// Collects the STRESS lines of [body].
Future<List<Map<String, Object?>>> _stressLines(
  Future<void> Function() body,
) async {
  final lines = <String>[];
  final old = debugPrint;
  debugPrint = (message, {wrapWidth}) {
    if (message != null && message.startsWith('STRESS {')) {
      lines.add(message);
    }
  };
  try {
    await body();
  } finally {
    // flutter_test checks the debug variables before the tearDown.
    debugPrint = old;
  }
  return [
    for (final line in lines)
      jsonDecode(line.substring('STRESS '.length)) as Map<String, Object?>,
  ];
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  test('each plugin case selects one benchmark case for each of its calls, '
      'and the cases cover the plugin cases of the benchmark', () {
    final selected = <ChartBenchCase>{};
    final all = {
      for (final scene in StressPluginScene.values)
        for (final legend in [true, false])
          for (final tooltip in [true, false])
            for (final datasets in stressPluginDatasets)
              StressPluginCase(
                scene,
                legend: legend,
                tooltip: tooltip,
                datasets: datasets,
              ),
    };
    // Each benchmark case of a scene once.
    expect(all, hasLength(2 + 1 + 4 + 4 + 2 + 3));
    expect(all, containsAll(_cases));
    for (final pluginCase in all) {
      for (final call in pluginCase.scene.calls) {
        final benchCase = stressPluginBenchCase(pluginCase, call);
        expect(benchCase.id, pluginCase.scene.benchId);
        expect(benchCase.call.name, call.name);
        expect(benchCase.keys, pluginCase.benchKeys);
        selected.add(benchCase);
      }
    }
    // All plugin cases of the benchmark, except the dispatch of
    // plugins.line: the modes chart and axes run the seven plugins.
    expect(selected, {
      for (final c in chartBenchCases)
        if (const {'tooltip', 'fill', 'legend', 'title'}.contains(c.mode)) c,
    });
    expect(
      () => stressPluginBenchCase(
        const StressPluginCase(StressPluginScene.hover),
        StressChartCall.draw,
      ),
      throwsArgumentError,
    );
    // The keys that a scene does not have do not change the case.
    expect(
      const StressPluginCase(StressPluginScene.gaps, legend: false),
      const StressPluginCase(StressPluginScene.gaps, datasets: 3),
    );
    expect(
      const StressPluginCase(StressPluginScene.fade, tooltip: false),
      const StressPluginCase(StressPluginScene.fade),
    );
    expect(
      const StressPluginCase(StressPluginScene.hover, tooltip: false),
      isNot(const StressPluginCase(StressPluginScene.hover)),
    );
  });

  test('stressHostConfig keeps the config of the benchmark case, without '
      'the options of the frameless chart', () {
    for (final pluginCase in _cases) {
      for (final call in pluginCase.scene.calls) {
        final reason = '$pluginCase ${call.name}';
        final bench = _benchConfig(pluginCase, call, _n);
        final host = stressHostConfig(
          stressPluginBenchCase(pluginCase, call).scene(_n).config,
        );
        expect(host.keys, isNot(contains('platform')), reason: reason);
        final options = host['options']! as Map<String, Object?>;
        for (final key in chartBenchOptions.keys) {
          expect(options.keys, isNot(contains(key)), reason: reason);
        }
        expect(options['maintainAspectRatio'], false, reason: reason);
        final benchOptions = {...bench['options']! as Map<String, Object?>}
          ..removeWhere((key, _) => chartBenchOptions.containsKey(key));
        expect(
          {...options}..remove('maintainAspectRatio'),
          benchOptions,
          reason: reason,
        );
        expect(host['type'], bench['type'], reason: reason);
        expect(host['data'], bench['data'], reason: reason);
        // The timing plugins of the case stay.
        expect(host['plugins'], isNotEmpty, reason: reason);
      }
    }
  });

  for (final pluginCase in _cases) {
    final call = pluginCase.scene.calls.first;
    testWidgets('plugins, $pluginCase: the chart of the benchmark case runs '
        'in the frames', (tester) async {
      final stats = await _pumpPlugins(tester, pluginCase, call: call);
      await _frames(tester, 30);
      final chart = _chart(tester);
      final state = _state(tester);
      expect(state.debugFrames, greaterThan(20));
      expect(chart.platform, isA<FlutterPlatform>());
      expect(chart.options['maintainAspectRatio'], false);
      expect(chart.options['responsive'], true);
      expect(
        chart.config.type,
        pluginCase.scene == StressPluginScene.radar ? 'radar' : 'line',
      );
      final datasets = chart.data['datasets']! as List<Object?>;
      expect(datasets, hasLength(pluginCase.benchKeys['datasets']));
      for (final dataset in datasets) {
        expect(jsGet(dataset, 'data'), hasLength(_n));
      }
      // The config of the benchmark case.
      final bench = _benchConfig(pluginCase, call, _n);
      final benchData = bench['data']! as Map<String, Object?>;
      expect(
        jsGet(datasets.first, 'fill'),
        jsGet((benchData['datasets']! as List<Object?>).first, 'fill'),
      );
      // The plugins of the case.
      final legend =
          pluginCase.scene == StressPluginScene.legend && pluginCase.legend;
      expect(chart.legend != null, legend);
      expect(chart.boxes.whereType<Legend>().isNotEmpty, legend);
      // The title plugin makes its block also with `display: false`.
      expect(chart.titleBlock, isNotNull);
      expect(
        jsGet(jsGet(chart.options['plugins'], 'title'), 'display'),
        pluginCase.scene == StressPluginScene.title,
      );
      final tooltipPlugin =
          pluginCase.scene.tooltip && pluginCase.benchKeys['tooltip'] == true;
      // The other scenes keep the tooltip plugin: they listen to no event.
      expect(
        chart.tooltip == null,
        pluginCase.scene.tooltip && !tooltipPlugin,
      );
      expect(
        chart.options['events'],
        pluginCase.scene.tooltip ? isNotEmpty : isEmpty,
      );
      expect(
        chart.options['animation'],
        pluginCase.scene == StressPluginScene.still ||
                pluginCase.scene == StressPluginScene.fade
            ? isNot(false)
            : false,
      );
      if (pluginCase.scene == StressPluginScene.still && tooltipPlugin) {
        // The preparation of the benchmark: the middle point, still.
        expect((chart.tooltip! as Tooltip).opacity, 1);
        expect(_tooltipIndex(chart), _n ~/ 2);
      }

      await _window(tester);
      final last = stats.last;
      expect(last.mode, StressMode.plugins);
      expect(last.points, _n);
      expect(last.frames, greaterThan(20));
      expect(last.drawMs, greaterThan(0));
      expect(last.datasetsDrawMs, greaterThan(0));
      expect(last.tooltipDrawMs > 0, tooltipPlugin);
      if (pluginCase.scene.calls.first == StressChartCall.draw) {
        // A draw has no element update, no layout and no dataset update.
        expect(last.layoutMs, 0);
        expect(last.datasetsUpdateMs, 0);
      }
      if (pluginCase.scene == StressPluginScene.hover) {
        // The event draws the chart: the update is the event.
        expect(last.updateMs, greaterThan(0));
      }
      if (pluginCase.scene != StressPluginScene.fade) {
        expect(last.animatorMs, 0);
      }

      // Stopping stops the loop.
      await stressTap(tester, 'stress.start');
      await _frames(tester);
      final frames = _state(tester).debugFrames;
      await _frames(tester, 3);
      expect(_state(tester).debugFrames, frames);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('plugins, update: each frame changes the data and updates the '
      'chart', (tester) async {
    final stats = await _pumpPlugins(
      tester,
      const StressPluginCase(StressPluginScene.gaps),
      call: StressChartCall.update,
    );
    await _frames(tester, 10);
    final data =
        jsGet(
              (_chart(tester).data['datasets']! as List<Object?>).first,
              'data',
            )!
            as List<Object?>;
    final before = [...data];
    await _frames(tester, 3);
    expect(data, isNot(before));
    // The gaps stay.
    expect(data[11], isNull);
    await _window(tester);
    expect(stats.last.updateMs, greaterThan(0));
    expect(stats.last.layoutMs, greaterThan(0));
    expect(stats.last.datasetsUpdateMs, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('plugins, hover: each frame moves the tooltip to the next '
      'point', (tester) async {
    await _pumpPlugins(
      tester,
      const StressPluginCase(StressPluginScene.hover, datasets: 3),
      call: StressChartCall.frame,
      n: 6,
    );
    await _frames(tester, 3);
    final chart = _chart(tester);
    final indexes = <Object?>[];
    for (var i = 0; i < 8; i++) {
      await _frames(tester, 1);
      indexes.add(_tooltipIndex(chart));
      // The mode index makes the point of each dataset active.
      expect(chart.getActiveElements(), hasLength(3));
    }
    for (var i = 1; i < indexes.length; i++) {
      expect(
        indexes[i],
        ((indexes[i - 1]! as num) + 1) % 6,
        reason: '$indexes',
      );
    }
    expect(tester.takeException(), isNull);
  });

  for (final scene in [StressPluginScene.hover, StressPluginScene.fade]) {
    testWidgets('plugins, ${scene.name}: the events go directly to the event '
        'handler of the chart, around the host input path', (tester) async {
      await _pumpPlugins(
        tester,
        StressPluginCase(scene, datasets: 3),
        call: StressChartCall.frame,
        n: 6,
      );
      await _frames(tester, 2);
      final chart = _chart(tester);
      final canvas = chart.canvas!;
      // The platform listens to the events of the scene on the canvas
      // (createProxyAndListen, platform.dom.js:240-254).
      expect(hasCanvasEventListener(canvas, 'mousemove'), isTrue);
      expect(hasCanvasEventListener(canvas, 'mouseout'), isTrue);
      final hostEvents = <String>[];
      void listener(NativeEvent event) => hostEvents.add(event.type);
      addCanvasEventListener(canvas, 'mousemove', listener);
      addCanvasEventListener(canvas, 'mouseout', listener);
      addTearDown(() {
        removeCanvasEventListener(canvas, 'mousemove', listener);
        removeCanvasEventListener(canvas, 'mouseout', listener);
      });
      final tooltip = chart.tooltip! as Tooltip;
      final states = <Object?>{};
      for (var i = 0; i < 2 * chartBenchFadeFrames + 2; i++) {
        await _frames(tester, 1);
        states.add(
          scene == StressPluginScene.hover
              ? _tooltipIndex(chart)
              : tooltip.opacity,
        );
      }
      // The scene changes the tooltip, but no event of the scene passes
      // through the listeners of the canvas.
      expect(states.length, greaterThan(2), reason: '$states');
      expect(hostEvents, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('plugins, fade: the animator of the chart ticks the fade in '
      'the frames, and the event changes each '
      '$chartBenchFadeFrames frames', (tester) async {
    final stats = await _pumpPlugins(
      tester,
      const StressPluginCase(StressPluginScene.fade, datasets: 3),
      call: StressChartCall.frame,
    );
    await _frames(tester, 2);
    final chart = _chart(tester);
    final tooltip = chart.tooltip! as Tooltip;
    final opacities = <double>[];
    for (var i = 0; i < 4 * chartBenchFadeFrames; i++) {
      await _frames(tester, 1);
      opacities.add(tooltip.opacity.isNaN ? 0 : tooltip.opacity);
    }
    // The frames of 20 ms run each fade of 200 ms to its end: a fade in to
    // 1 and a fade out to 0, in turn, each $chartBenchFadeFrames frames. The
    // opacity changes in each frame of a fade.
    const period = 2 * chartBenchFadeFrames;
    for (var i = 0; i < period; i++) {
      expect(
        opacities[i + period],
        closeTo(opacities[i], 1e-9),
        reason: '$i $opacities',
      );
    }
    var up = 0;
    var down = 0;
    for (var i = 0; i < period; i++) {
      if (opacities[i + 1] > opacities[i]) up++;
      if (opacities[i + 1] < opacities[i]) down++;
    }
    expect(up, greaterThanOrEqualTo(9), reason: '$opacities');
    expect(down, greaterThanOrEqualTo(9), reason: '$opacities');
    expect(opacities, contains(1.0));
    expect(opacities, contains(0.0));
    await _frames(tester, 20);
    await _window(tester);
    // This callback runs before the animator callback of each frame, so
    // the tick of the animator has its own time.
    expect(stats.last.animatorMs, greaterThan(0));
    expect(stats.last.drawMs, greaterThan(0));
    expect(stats.last.tooltipDrawMs, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('plugins: the controls have keys and make a new chart', (
    tester,
  ) async {
    await _pumpPlugins(
      tester,
      const StressPluginCase(StressPluginScene.legend),
      autoStart: false,
    );
    await _frames(tester);
    for (final scene in StressPluginScene.values) {
      expect(
        await stressControlExists(tester, 'stress.plugins.scene.${scene.name}'),
        isTrue,
      );
    }
    expect(await stressSelected(tester, 'stress.mode.plugins'), isTrue);
    expect(await stressSelected(tester, 'stress.plugins.scene.legend'), isTrue);
    expect(await stressControlExists(tester, 'stress.n.100'), isTrue);
    expect(await stressControlExists(tester, 'stress.n.1000'), isTrue);
    expect(await stressControlExists(tester, 'stress.n.5000'), isFalse);
    expect(await stressSelected(tester, 'stress.plugins.legend'), isTrue);
    expect(
      await stressControlExists(tester, 'stress.plugins.tooltip'),
      isFalse,
    );
    expect(
      await stressControlExists(tester, 'stress.plugins.datasets.10'),
      isFalse,
    );
    expect(
      await stressControlExists(tester, 'stress.chart.call.update'),
      isTrue,
    );
    expect(
      await stressControlExists(tester, 'stress.chart.call.frame'),
      isFalse,
    );
    var chart = _chart(tester);
    expect(chart.legend, isNotNull);

    // The legend off: the base, on a new chart.
    await stressTap(tester, 'stress.plugins.legend');
    await _frames(tester);
    expect(_chart(tester), isNot(same(chart)));
    expect(_chart(tester).legend, isNull);

    // The call update keeps the chart.
    chart = _chart(tester);
    await stressTap(tester, 'stress.chart.call.update');
    await _frames(tester);
    expect(await stressSelected(tester, 'stress.chart.call.update'), isTrue);
    expect(_chart(tester), same(chart));

    // The scene hover takes the call frame, and has the tooltip and the
    // datasets.
    await stressTap(tester, 'stress.plugins.scene.hover');
    await _frames(tester);
    expect(await stressSelected(tester, 'stress.chart.call.frame'), isTrue);
    expect(
      await stressControlExists(tester, 'stress.chart.call.draw'),
      isFalse,
    );
    expect(await stressControlExists(tester, 'stress.plugins.legend'), isFalse);
    expect(await stressSelected(tester, 'stress.plugins.tooltip'), isTrue);
    expect(await stressSelected(tester, 'stress.plugins.datasets.10'), isTrue);
    expect(_chart(tester).data['datasets'], hasLength(10));
    await stressTap(tester, 'stress.plugins.datasets.3');
    await _frames(tester);
    expect(_chart(tester).data['datasets'], hasLength(3));
    await stressTap(tester, 'stress.plugins.tooltip');
    await _frames(tester);
    expect(_chart(tester).tooltip, isNull);

    // A new N makes a new chart.
    chart = _chart(tester);
    await stressTap(tester, 'stress.n.100');
    await _frames(tester);
    expect(_chart(tester), isNot(same(chart)));
    expect(
      jsGet((_chart(tester).data['datasets']! as List<Object?>).first, 'data'),
      hasLength(100),
    );

    // The scene fade keeps the datasets, and has no tooltip toggle.
    await stressTap(tester, 'stress.plugins.scene.fade');
    await _frames(tester);
    expect(
      await stressControlExists(tester, 'stress.plugins.tooltip'),
      isFalse,
    );
    expect(await stressSelected(tester, 'stress.plugins.datasets.3'), isTrue);
    expect(_chart(tester).tooltip, isNotNull);

    // The mode chart has no call frame: it takes the call draw.
    await stressTap(tester, 'stress.mode.chart');
    await _frames(tester);
    expect(await stressSelected(tester, 'stress.chart.call.draw'), isTrue);
    expect(
      await stressControlExists(tester, 'stress.chart.call.frame'),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('stress tab: in each scene of the mode plugins, the host is in '
      'view at 412 x 915 (Chart.js ADR 0031, section 10)', (tester) async {
    tester.view
      ..physicalSize = _phone * 2.625
      ..devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorSchemeSeed: const Color(0xFFFF6384)),
        home: const CanvasHostDemoPage(),
      ),
    );
    await _frames(tester);
    final tab = find.byKey(const ValueKey('phase3.tab.stress'));
    await tester.ensureVisible(tab);
    await tester.pump();
    await tester.tap(tab);
    await _frames(tester, 25);
    // The mode line is at the top of the tab: a tap needs no scroll.
    await tester.tap(find.byKey(const ValueKey('stress.mode.plugins')));
    await _frames(tester, 6);
    final page = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first;
    final view = Offset.zero & _phone;
    for (final scene in StressPluginScene.values) {
      await tester.tap(
        find.byKey(ValueKey('stress.plugins.scene.${scene.name}')),
      );
      await _frames(tester, 6);
      final position = tester.state<ScrollableState>(page).position;
      expect(position.pixels, 0, reason: scene.name);
      final rect = tester.getRect(
        find.byKey(const ValueKey('stress.plugins.host')),
      );
      expect(rect.height, greaterThan(0), reason: scene.name);
      expect(view.contains(rect.topLeft), isTrue, reason: '$scene $rect');
      expect(
        view.contains(rect.bottomRight - const Offset(0.01, 0.01)),
        isTrue,
        reason: '$scene $rect',
      );
    }
    // Only segmented controls on the lines of the mode.
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(FilterChip), findsNothing);
    expect(find.byType(Slider), findsNothing);
    expect(find.byType(DropdownButton<Object?>), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final (pluginCase, call) in [
    (
      const StressPluginCase(StressPluginScene.hover, tooltip: false),
      StressChartCall.frame,
    ),
    (const StressPluginCase(StressPluginScene.legend), StressChartCall.update),
  ]) {
    testWidgets('main_stress gives the keys of the mode plugins, '
        '$pluginCase, ${call.name}', (tester) async {
      final lines = await _stressLines(() async {
        await tester.pumpWidget(
          StressProfileApp(
            mode: StressMode.plugins,
            scenarios: const [(_n, 0)],
            call: call,
            pluginCase: pluginCase,
          ),
        );
        await _frames(tester, 40);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 600)),
        );
        await _frames(tester, 5);
        await tester.pump(const Duration(seconds: stressSeconds));
      });
      expect(lines, hasLength(1));
      final line = lines.single;
      expect(line['mode'], 'plugins');
      expect(line['n'], _n);
      expect(line['m'], 0);
      expect(line['call'], call.name);
      expect(line['scene'], pluginCase.scene.name);
      expect(line['benchCase'], pluginCase.scene.benchId);
      for (final MapEntry(:key, :value) in pluginCase.benchKeys.entries) {
        expect(line[key], value, reason: key);
      }
      final figures = [
        'fps',
        'drawMs',
        'updateMs',
        'animatorMs',
        'elementsMs',
        'layoutMs',
        'datasetsUpdateMs',
        'datasetsDrawMs',
        'buildMs',
        'rasterMs',
        if (pluginCase.scene.tooltip) 'tooltipDrawMs',
      ];
      for (final key in figures) {
        expect(line[key], matches(RegExp(r'^\d+\.\d\d$')), reason: key);
      }
      if (!pluginCase.scene.tooltip) {
        expect(line.keys, isNot(contains('tooltipDrawMs')));
      }
      // The keys of the other modes do not come.
      for (final key in ['type', 'sharing', 'scale', 'ticks']) {
        expect(line.keys, isNot(contains(key)), reason: key);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  test('the defines SCENE, LEGEND, TOOLTIP, DATASETS and CALL of the mode '
      'plugins', () {
    const plugins = StressMode.plugins;
    StressPluginCase parse({
      String scene = '',
      String legend = '',
      String tooltip = '',
      String datasets = '',
      StressMode mode = plugins,
    }) => parseStressPluginCase(
      scene: scene,
      legend: legend,
      tooltip: tooltip,
      datasets: datasets,
      mode: mode,
    );
    expect(parse(), const StressPluginCase(StressPluginScene.legend));
    for (final scene in StressPluginScene.values) {
      expect(parse(scene: scene.name).scene, scene);
    }
    expect(parse(legend: '0').legend, isFalse);
    expect(parse(scene: 'hover', tooltip: '0').tooltip, isFalse);
    expect(parse(scene: 'still', tooltip: '1').tooltip, isTrue);
    expect(parse(scene: 'fade').datasets, 10);
    expect(parse(scene: 'hover', datasets: '3').datasets, 3);
    // An unknown scene, and a define of another scene or mode.
    expect(() => parse(scene: 'pie'), throwsArgumentError);
    expect(() => parse(scene: 'title', legend: '1'), throwsArgumentError);
    expect(() => parse(scene: 'fade', tooltip: '0'), throwsArgumentError);
    expect(() => parse(scene: 'gaps', datasets: '3'), throwsArgumentError);
    expect(() => parse(scene: 'hover', datasets: '5'), throwsArgumentError);
    expect(() => parse(scene: 'hover', datasets: 'x'), throwsArgumentError);
    expect(() => parse(legend: '2'), throwsArgumentError);
    for (final mode in StressMode.values.where((m) => m != plugins)) {
      expect(
        parse(mode: mode),
        const StressPluginCase(StressPluginScene.legend),
      );
      expect(() => parse(scene: 'hover', mode: mode), throwsArgumentError);
      expect(() => parse(legend: '1', mode: mode), throwsArgumentError);
      expect(() => parse(tooltip: '1', mode: mode), throwsArgumentError);
      expect(() => parse(datasets: '3', mode: mode), throwsArgumentError);
    }

    // CALL: without the define, the first call of the mode or the scene.
    expect(parseStressCall('', StressMode.chart), StressChartCall.draw);
    expect(parseStressCall('', StressMode.axes), StressChartCall.draw);
    expect(
      parseStressCall('', plugins, StressPluginScene.hover),
      StressChartCall.frame,
    );
    expect(
      parseStressCall('', plugins, StressPluginScene.still),
      StressChartCall.draw,
    );
    expect(
      parseStressCall('update', plugins, StressPluginScene.stack),
      StressChartCall.update,
    );
    expect(
      parseStressCall('animate', StressMode.chart),
      StressChartCall.animate,
    );
    expect(
      () => parseStressCall('animate', StressMode.axes),
      throwsArgumentError,
    );
    expect(
      () => parseStressCall('frame', StressMode.chart),
      throwsArgumentError,
    );
    expect(
      () => parseStressCall('frame', StressMode.bars),
      throwsArgumentError,
    );
    expect(
      () => parseStressCall('draw', plugins, StressPluginScene.fade),
      throwsArgumentError,
    );
    expect(
      () => parseStressCall('frame', plugins, StressPluginScene.title),
      throwsArgumentError,
    );
    expect(
      () => parseStressCall('animate', plugins, StressPluginScene.gaps),
      throwsArgumentError,
    );
    expect(
      () => parseStressCall('jump', StressMode.chart),
      throwsArgumentError,
    );

    // The calls of each mode.
    expect(
      stressCallOf(
        StressMode.axes,
        StressChartCall.animate,
        StressPluginScene.legend,
      ),
      StressChartCall.draw,
    );
    expect(
      stressCallOf(plugins, StressChartCall.update, StressPluginScene.fade),
      StressChartCall.frame,
    );
    expect(
      stressCallOf(plugins, StressChartCall.update, StressPluginScene.radar),
      StressChartCall.update,
    );
  });

  test('stressDefaultScenarios of the mode plugins: the counts of the plugin '
      'cases of the benchmark', () {
    expect(stressDefaultScenarios(StressMode.plugins), [(100, 0), (1000, 0)]);
    expect(StressMode.plugins.counts, chartBenchPluginCounts);
    expect(StressMode.plugins.runsChart, isTrue);
  });
}
