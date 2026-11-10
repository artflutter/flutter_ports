// Counts the work of the page around the chart: the widgets that build and the
// render objects that lay out and paint for each interaction. A count does not
// depend on the machine, so these budgets hold on each run. `tool/perf_page.dart`
// measures the same interactions in time, on a device.
import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/controller.dart';
import 'package:chart_benchmark_lab/benchmark/data.dart';
import 'package:chart_benchmark_lab/benchmark/metrics.dart';
import 'package:chart_benchmark_lab/charts/chart_adapter.dart';
import 'package:chart_benchmark_lab/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' as cj;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The work of one interaction.
class _Work {
  int builds = 0;
  int chartBuilds = 0;
  int settingsBuilds = 0;
  final Set<Element> chartElements = {};
  int layouts = 0;
  int paints = 0;

  @override
  String toString() =>
      'builds=$builds chartBuilds=$chartBuilds settingsBuilds=$settingsBuilds '
      'layouts=$layouts paints=$paints';
}

final Map<String, _Work> _table = {};
final RegExp _renderName = RegExp('^_?Render');

int _renderBlocks() {
  var total = 0;
  for (final block in FlutterTimeline.debugCollect().timedBlocks) {
    if (_renderName.hasMatch(block.name)) total++;
  }
  return total;
}

/// Runs [action] twice, first with a count of the layouts and then with a count
/// of the paints. The action must be repeatable. Each run counts the builds,
/// and the result keeps the larger count.
Future<_Work> _measure(
  String name,
  Future<void> Function() action,
) async {
  final work = _Work();
  debugOnRebuildDirtyWidget = (element, _) {
    work.builds++;
    if (element.widget is BenchmarkChart) {
      work.chartBuilds++;
      work.chartElements.add(element);
    }
    if (element.widget is SwitchListTile) work.settingsBuilds++;
  };
  FlutterTimeline.debugCollectionEnabled = true;

  FlutterTimeline.debugReset();
  debugProfileLayoutsEnabled = true;
  await action();
  debugProfileLayoutsEnabled = false;
  work.layouts = _renderBlocks();
  final builds = work.builds;
  final chartBuilds = work.chartBuilds;

  work
    ..builds = 0
    ..chartBuilds = 0;
  FlutterTimeline.debugReset();
  debugProfilePaintsEnabled = true;
  await action();
  debugProfilePaintsEnabled = false;
  work
    ..paints = _renderBlocks()
    ..builds = work.builds > builds ? work.builds : builds
    ..chartBuilds = work.chartBuilds > chartBuilds
        ? work.chartBuilds
        : chartBuilds;

  FlutterTimeline.debugCollectionEnabled = false;
  debugOnRebuildDirtyWidget = null;
  _table[name] = work;
  // The table goes to the test output, for the record of a change.
  // ignore: avoid_print
  print('WORK $name $work');
  return work;
}

BenchmarkResult _result(BenchmarkController c, int i) => BenchmarkResult(
  library: ChartLibrary.values[i % ChartLibrary.values.length],
  config: c.config,
  viewport: c.viewport,
  dpr: c.dpr,
  refreshRate: c.refreshRate,
  metrics: FrameMetrics(samples: 600, fps: 20.0 + i, intervalP90: 16 + i * .1),
  durationSeconds: c.captureSeconds,
  createdAt: DateTime.utc(2026),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Finishes the ink and the animations that an action started.
Future<void> _quiet(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(milliseconds: 20));
}

Future<BenchmarkController> _page(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  late BenchmarkController c;
  await tester.pumpWidget(
    ChartBenchmarkApp(onControllerReady: (value) => c = value),
  );
  await _settle(tester);
  c.configure(const BenchmarkConfig(count: 100));
  await _settle(tester);
  c.results.addAll([for (var i = 0; i < 24; i++) _result(c, i)]);
  c.clearStopReason();
  await _settle(tester);
  // The animations of a new table end before a count starts.
  await _quiet(tester);
  return c;
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 20));
}

void main() {
  setUpAll(() => cj.Chart.register(cj.registerables));
  staleSections();

  testWidgets('the first frames mount the chart once', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final elements = <Element>{};
    debugOnRebuildDirtyWidget = (element, _) {
      if (element.widget is BenchmarkChart) elements.add(element);
    };
    await tester.pumpWidget(const ChartBenchmarkApp());
    await _settle(tester);
    debugOnRebuildDirtyWidget = null;
    // The table goes to the test output, for the record of a change.
    // ignore: avoid_print
    print('WORK startup chartMounts=${elements.length}');
    await _end(tester);
    expect(elements, hasLength(1));
  });

  for (final size in [const Size(1400, 1000), const Size(412, 915)]) {
    final label = size.width < 600 ? 'phone' : 'desktop';

    testWidgets('$label: a readout tick repaints only the readouts', (
      tester,
    ) async {
      final c = await _page(tester, size);
      var seconds = 0.0;
      final work = await _measure('$label readout', () async {
        c.readout.value = RunReadout(
          FrameMetrics(samples: 60, fps: seconds += 1),
          seconds,
          1,
        );
        await tester.pump();
      });
      await _end(tester);
      expect(work.chartBuilds, 0);
      expect(work.builds, lessThan(100));
      expect(work.paints, lessThan(200));
    });

    testWidgets('$label: a chart tick records no page around the chart', (
      tester,
    ) async {
      final c = await _page(tester, size);
      final frame = c.frames.value;
      var step = frame.step;
      final work = await _measure('$label tick', () async {
        c.frames.value = DatasetFrame(frame.values, ++step);
        await tester.pump();
      });
      await _end(tester);
      expect(work.chartBuilds, 1);
      expect(work.builds, lessThan(40));
      // The chart repaints, and the page around it does not.
      expect(work.paints, lessThan(30));
    });

    testWidgets('$label: a change that nothing shows builds nothing', (
      tester,
    ) async {
      final c = await _page(tester, size);
      final work = await _measure('$label notify', () async {
        c.clearStopReason();
        await tester.pump();
      });
      await _end(tester);
      expect(work.chartBuilds, 0);
      expect(work.builds, lessThan(5));
      expect(work.paints, 0);
    });

    testWidgets('$label: a scroll frame paints nothing', (tester) async {
      await _page(tester, size);
      final position = Scrollable.of(
        tester.element(find.byKey(const ValueKey('library.chartjs'))),
      ).position;
      final work = await _measure('$label scroll', () async {
        position.jumpTo(position.pixels + 10);
        await tester.pump();
      });
      await _end(tester);
      expect(work.chartBuilds, 0);
      expect(work.paints, lessThan(5));
    });

    testWidgets('$label: the filter of the table leaves the chart alone', (
      tester,
    ) async {
      await _page(tester, size);
      final work = await _measure('$label filter', () async {
        final chip = tester.widget<FilterChip>(find.byType(FilterChip));
        chip.onSelected!(!chip.selected);
        await tester.pump();
        await _quiet(tester);
      });
      await _end(tester);
      expect(work.chartBuilds, 0);
    });

    testWidgets('$label: a sort leaves the chart alone', (tester) async {
      await _page(tester, size);
      var column = 3;
      final work = await _measure('$label sort', () async {
        final table = tester.widget<DataTable>(find.byType(DataTable));
        table.columns[column].onSort!(column, true);
        column = column == 3 ? 5 : 3;
        await tester.pump();
        await _quiet(tester);
      });
      await _end(tester);
      expect(work.chartBuilds, 0);
    });

    testWidgets('$label: a resize keeps the chart mounted', (tester) async {
      await _page(tester, size);
      var width = size.width;
      final work = await _measure('$label resize', () async {
        width -= 4;
        tester.view.physicalSize = Size(width, size.height);
        await tester.pump();
        await tester.pump();
      });
      await _end(tester);
      expect(work.chartElements, hasLength(1));
      expect(work.chartBuilds, lessThan(3));
      expect(work.builds, lessThan(2500));
    });

    testWidgets('$label: a press of Run builds no settings', (tester) async {
      final c = await _page(tester, size);
      if (size.width < 600) {
        // The settings of a phone are in the tree only when the tile is open.
        await tester.tap(find.text('Test configuration'));
        await _quiet(tester);
      }
      expect(find.byType(SwitchListTile), findsWidgets);
      final work = await _measure('$label run', () async {
        if (c.running) {
          c.pause();
        } else {
          c.start();
        }
        await tester.pump();
      });
      c.pause();
      await _end(tester);
      expect(work.settingsBuilds, 0);
      expect(work.builds, lessThan(1000));
    });
  }

  testWidgets('desktop: a hover repaints only its panel', (tester) async {
    await _page(tester, const Size(1400, 1000));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    final target = find.byKey(const ValueKey('feature.markers'));
    final work = await _measure('desktop hover', () async {
      await gesture.moveTo(tester.getCenter(target));
      await tester.pump();
      await _quiet(tester);
      await gesture.moveTo(Offset.zero);
      await tester.pump();
      await _quiet(tester);
    });
    await _end(tester);
    expect(work.chartBuilds, 0);
    expect(work.paints, lessThan(1500));
  });
}

/// What a person can read and press on the page.
String _screen(WidgetTester tester) {
  final parts = <String>[];
  for (final element in find.bySubtype<Widget>().evaluate()) {
    final widget = element.widget;
    if (widget is Text) {
      parts.add('text ${widget.data}');
    } else if (widget is ButtonStyleButton) {
      parts.add('button ${widget.key} ${widget.onPressed != null}');
    } else if (widget is IconButton) {
      parts.add('icon ${widget.key} ${widget.onPressed != null}');
    } else if (widget is ChoiceChip) {
      parts.add('chip ${widget.key} ${widget.selected} ${widget.isEnabled}');
    } else if (widget is SwitchListTile) {
      parts.add(
        'switch ${widget.key} ${widget.value} ${widget.onChanged != null}',
      );
    } else if (widget is BenchmarkChart) {
      parts.add(
        'chart ${widget.key} ${widget.library} ${widget.config.toJson()} '
        '${widget.size}',
      );
    }
  }
  return parts.join('\n');
}

/// Fails when a section of the page missed a value that it reads: a rebuild of
/// each element must leave the screen as it is.
Future<void> _expectNoStaleSection(WidgetTester tester, String step) async {
  // The check after a frame can stop a test, and the next frame shows that.
  await tester.pump();
  await tester.pump();
  final before = _screen(tester);
  // A finder that matches nothing must not pass.
  expect(before, contains('Chart benchmark lab'), reason: step);
  // Each element builds again, as in a hot reload.
  tester.binding.buildOwner!.reassemble(tester.binding.rootElement!);
  await tester.pump();
  expect(_screen(tester), before, reason: step);
}

void staleSections() {
  for (final size in [const Size(1400, 1000), const Size(412, 915)]) {
    testWidgets('each section follows each state at ${size.width}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late BenchmarkController c;
      await tester.pumpWidget(
        ChartBenchmarkApp(onControllerReady: (value) => c = value),
      );
      await _settle(tester);
      final steps = <String, void Function()>{
        'a setting': () => c.configure(const BenchmarkConfig(count: 100)),
        'a type': () => c.configure(c.config.copyWith(type: ChartType.bar)),
        'a workload': () =>
            c.configure(c.config.copyWith(workload: Workload.rebuild)),
        'a library': () => c.selectLibrary(ChartLibrary.flChart),
        'a type without a chart': () {
          c
            ..selectLibrary(ChartLibrary.syncfusion)
            ..configure(c.config.copyWith(type: ChartType.radar));
        },
        'back to a chart': () {
          c
            ..selectLibrary(ChartLibrary.chartjs)
            ..configure(
              const BenchmarkConfig(count: 100, overlayLabels: 50),
            );
        },
        // The notes of the library selector follow the shadow and the zoom.
        'a shadow': () => c.configure(c.config.copyWith(shadow: true)),
        'a zoom': () => c.configure(c.config.copyWith(zoom: true)),
        'a type without zoom': () =>
            c.configure(c.config.copyWith(type: ChartType.pie)),
        'no shadow and no zoom': () => c.configure(
          const BenchmarkConfig(count: 100, overlayLabels: 50),
        ),
        'a run': c.start,
        'a pause': c.pause,
        'a capture': () => c.start(capture: true),
        'a stop with a reason': () => c.pause('The reason.'),
        'a closed note': c.clearStopReason,
        'a capture length': () => c.setCaptureSeconds(30),
        'saved results': () {
          c.results.addAll([for (var i = 0; i < 4; i++) _result(c, i)]);
          c.clearStopReason();
        },
        'no results': c.clearResults,
        'a batch': c.captureAll,
        'the end of a batch': c.pause,
        'a hidden window': () => c.setWindowVisible(visible: false),
        'a start while hidden': c.start,
        'a visible window': () => c.setWindowVisible(visible: true),
      };
      for (final MapEntry(key: name, value: step) in steps.entries) {
        step();
        await _expectNoStaleSection(tester, name);
      }
      c.pause();
      await _end(tester);
    });
  }

  testWidgets('a resize keeps each section right', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ChartBenchmarkApp());
    await _settle(tester);
    for (final size in const [
      Size(1200, 1000),
      Size(900, 700),
      Size(500, 900),
      Size(1400, 500),
    ]) {
      tester.view.physicalSize = size;
      await _settle(tester);
      await _expectNoStaleSection(tester, '$size');
    }
    await _end(tester);
  });

  testWidgets('the note of the table follows the rows that it shows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late BenchmarkController c;
    await tester.pumpWidget(
      ChartBenchmarkApp(onControllerReady: (value) => c = value),
    );
    await _settle(tester);
    const note = ValueKey('results.otherWindow');
    // One row of this workload, and one of another, which the filter hides and
    // which always comes from another window.
    c.results.add(_result(c, 0));
    final current = c.config;
    c.configure(current.copyWith(count: 500));
    await _settle(tester);
    c.results.add(_result(c, 1));
    c.configure(current);
    await _settle(tester);
    await _expectNoStaleSection(tester, 'two workloads');
    expect(find.byKey(note), findsNothing);

    tester.view.physicalSize = const Size(1300, 1000);
    await _settle(tester);
    await _expectNoStaleSection(tester, 'the visible row is from another size');
    expect(find.byKey(note), findsOneWidget);

    tester.view.physicalSize = const Size(1400, 1000);
    await _settle(tester);
    await _expectNoStaleSection(tester, 'back at the size of the row');
    expect(find.byKey(note), findsNothing);
    await _end(tester);
  });

  testWidgets('the phone settings follow a change after the tile opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late BenchmarkController c;
    await tester.pumpWidget(
      ChartBenchmarkApp(onControllerReady: (value) => c = value),
    );
    await _settle(tester);
    await tester.tap(find.text('Test configuration'));
    await _quiet(tester);
    // The first change after the section mounts.
    c.setCaptureSeconds(30);
    await _expectNoStaleSection(tester, 'a first change');
    expect(find.text('30 seconds'), findsOneWidget);
    await _end(tester);
  });

  testWidgets('the first frames report the size of the chart', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ChartBenchmarkApp());
    await _settle(tester);
    expect(find.textContaining('0 × 0 logical px'), findsNothing);
    expect(find.textContaining('Ready.'), findsOneWidget);
    await _end(tester);
  });

  testWidgets('an idle Graphic bar chart still takes its new width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late BenchmarkController c;
    await tester.pumpWidget(
      ChartBenchmarkApp(onControllerReady: (value) => c = value),
    );
    await _settle(tester);
    c
      ..selectLibrary(ChartLibrary.graphic)
      ..configure(c.config.copyWith(type: ChartType.bar, count: 100));
    await _settle(tester);
    final revision = c.revision;
    tester.view.physicalSize = const Size(1300, 1000);
    await _settle(tester);
    expect(c.revision, greaterThan(revision));
    await _end(tester);
  });

  testWidgets('another idle chart stays mounted, and a test mounts a new one', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late BenchmarkController c;
    await tester.pumpWidget(
      ChartBenchmarkApp(onControllerReady: (value) => c = value),
    );
    await _settle(tester);
    final revision = c.revision;
    tester.view.physicalSize = const Size(1300, 1000);
    await _settle(tester);
    expect(c.revision, revision);
    expect(c.viewport.width, lessThan(1000));
    c.start();
    expect(c.revision, greaterThan(revision));
    c.pause();
    await _end(tester);
  });
}
