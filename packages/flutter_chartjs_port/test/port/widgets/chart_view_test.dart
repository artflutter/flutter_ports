// Original code, not ported from Chart.js: tests of the ChartView widget.
@TestOn('vm')
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.animator.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart'
    show notifyArrayListeners;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_chartjs_port/src/platform/platform.basic.dart';
import 'package:flutter_chartjs_port/src/platform/platform.flutter.dart';
import 'package:flutter_chartjs_port/src/theme/theme_data.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/widgets/chart_view.dart';
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0049: the widget starts its chart in the first layout of
// the host (section 2), applies a new config in one post-frame callback
// (section 4), takes its size from the constraints and the options
// (section 5), the callbacks follow the setState table (section 6), and
// the reduced-motion preference sets the flag of the canvas (section 7).
// flutter_test_config.dart registers the built-in components.

/// A config of [type] with three values, `animation: false` unless
/// [options] gives it, and the inline [plugins].
Map<String, Object?> _config({
  String type = 'bar',
  Map<String, Object?> options = const {},
  List<Object?>? plugins,
  List<Object?>? data,
}) => <String, Object?>{
  'type': type,
  'data': <String, Object?>{
    'labels': <Object?>['a', 'b', 'c'],
    'datasets': <Object?>[
      <String, Object?>{
        'data': data ?? <Object?>[1, 2, 3],
      },
    ],
  },
  'options': <String, Object?>{'animation': false, ...options},
  'plugins': ?plugins,
};

/// [child] at the top left of a loose box of [width] x [height].
Widget _box(Widget child, {double width = 400, double height = 300}) =>
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints.loose(Size(width, height)),
          child: child,
        ),
      ),
    );

RenderChartHost _host(WidgetTester tester) =>
    tester.renderObject<RenderChartHost>(find.byType(ChartHost));

UiCanvasElement _canvas(WidgetTester tester) => _host(tester).canvas;

/// The chart of the one ChartView of the tree.
Chart? _chart(WidgetTester tester) => Chart.getChart(_canvas(tester));

/// [child] under a `MediaQuery` with `disableAnimations: [reduced]`.
Widget _motion(Widget child, {required bool reduced}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduced),
  child: child,
);

/// A plugin that counts the calls of [hook] in [counts].
AnyObject _counter(String id, String hook, Map<String, int> counts) =>
    <String, Object?>{
      'id': id,
      hook: (Object? chart, Object? args, Object? options) {
        counts[hook] = (counts[hook] ?? 0) + 1;
      },
    };

/// The diagnostics of [object] at the level info, as strings.
List<String> _properties(Diagnosticable object) => [
  for (final property in object.toDiagnosticsNode().getProperties())
    if (!property.isFiltered(DiagnosticLevel.info)) property.toString(),
];

/// A parent that shows a ChartView of its config and a [Text] of its label.
class _Parent extends StatefulWidget {
  const _Parent({required this.config});

  final Map<String, Object?> config;

  @override
  State<_Parent> createState() => _ParentState();
}

class _ParentState extends State<_Parent> {
  late Map<String, Object?> config = widget.config;
  String label = '';
  String? updateMode;

  void show(Map<String, Object?> next, {String? mode}) => setState(() {
    config = next;
    updateMode = mode;
  });

  void write(String text) => setState(() => label = text);

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChartView(config: config, updateMode: updateMode),
            Text(label, key: const ValueKey('label')),
          ],
        ),
      ),
    ),
  );
}

void main() {
  group('start', () {
    testWidgets('the host has the chart size after one pump, and the widget '
        'below does not move', (tester) async {
      const below = ValueKey('below');
      await tester.pumpWidget(
        _box(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChartView(config: _config()),
              const SizedBox(key: below, width: 10, height: 10),
            ],
          ),
          height: 600,
        ),
      );
      expect(tester.getSize(find.byType(ChartView)), const Size(400, 200));
      expect(tester.getTopLeft(find.byKey(below)).dy, 200);
      expect(_canvas(tester).getContext2d().isEmpty, isFalse);
      await tester.pump();
      expect(tester.getSize(find.byType(ChartView)), const Size(400, 200));
      expect(tester.getTopLeft(find.byKey(below)).dy, 200);
    });

    testWidgets('the entry animation calls onComplete once, onProgress in '
        'each frame and afterRender', (tester) async {
      var complete = 0;
      var progress = 0;
      final counts = <String, int>{};
      await tester.pumpWidget(
        _box(
          ChartView(
            config: _config(
              options: <String, Object?>{
                'animation': <String, Object?>{
                  'onComplete': (Object? context) => complete++,
                  'onProgress': (Object? context) => progress++,
                },
              },
              plugins: [_counter('render', 'afterRender', counts)],
            ),
          ),
        ),
      );
      expect((complete, progress, counts['afterRender']), (0, 0, null));
      var frames = 0;
      while (complete == 0 && frames < 100) {
        await tester.pump(const Duration(milliseconds: 16));
        frames++;
      }
      // The animator ticks and draws in each frame of the 1000 ms animation
      // (onProgress). The frame after the last tick removes the animations
      // and completes them (core.animator.js:79-104): no onProgress there.
      expect(complete, 1);
      expect(progress, frames - 1);
      expect(frames, inInclusiveRange(63, 65));
      expect(counts['afterRender'], 1);
      await tester.pump(const Duration(milliseconds: 100));
      expect((complete, progress), (1, frames - 1));
    });

    testWidgets('the chart has the FlutterPlatform and is attached in its '
        'constructor', (tester) async {
      Chart? created;
      bool? attachedAtInit;
      await tester.pumpWidget(
        _box(
          ChartView(
            config: _config(
              plugins: [
                <String, Object?>{
                  'id': 'init',
                  'afterInit': (Object? chart, Object? args, Object? options) {
                    attachedAtInit = (chart! as Chart).attached;
                  },
                },
              ],
            ),
            onChartCreated: (chart) => created = chart,
          ),
        ),
      );
      expect(attachedAtInit, isTrue);
      expect(created, isNotNull);
      expect(created, same(_chart(tester)));
      expect(created!.platform, isA<FlutterPlatform>());
      expect(created!.attached, isTrue);
      expect((created!.width, created!.height), (400.0, 200.0));
    });

    testWidgets('a start under TickerMode(enabled: false) is muted, and a '
        'change unmutes it', (tester) async {
      var progress = 0;
      final config = _config(
        options: <String, Object?>{
          'animation': <String, Object?>{
            'onProgress': (Object? context) => progress++,
          },
        },
      );
      Widget build({required bool enabled}) => TickerMode(
        enabled: enabled,
        child: _box(ChartView(config: config)),
      );
      await tester.pumpWidget(build(enabled: false));
      final chart = _chart(tester)!;
      expect(animator.has(chart), isTrue);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(progress, 0);
      expect(
        _properties(tester.state(find.byType(ChartView))),
        contains('muted'),
      );
      await tester.pumpWidget(build(enabled: true));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(progress, greaterThan(0));
      expect(
        _properties(tester.state(find.byType(ChartView))),
        isNot(contains('muted')),
      );
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('onChartCreated runs once after the frame, and a setState in '
        'it does not throw', (tester) async {
      final phases = <SchedulerPhase>[];
      late StateSetter setOuter;
      var builds = 0;
      final config = _config();
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setOuter = setState;
            builds++;
            return _box(
              ChartView(
                config: config,
                onChartCreated: (chart) {
                  phases.add(SchedulerBinding.instance.schedulerPhase);
                  setOuter(() {});
                },
              ),
            );
          },
        ),
      );
      expect(phases, [SchedulerPhase.postFrameCallbacks]);
      expect(tester.takeException(), isNull);
      await tester.pump();
      await tester.pump();
      expect(builds, 2);
      expect(phases, hasLength(1));
    });

    testWidgets('a setState in afterInit fails with "Build scheduled during '
        'frame."', (tester) async {
      late StateSetter setOuter;
      final config = _config(
        plugins: [
          <String, Object?>{
            'id': 'init',
            'afterInit': (Object? chart, Object? args, Object? options) {
              setOuter(() {});
            },
          },
        ],
      );
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setOuter = setState;
            return _box(ChartView(config: config));
          },
        ),
      );
      final error = tester.takeException();
      expect(error, isA<FlutterError>());
      expect('$error', contains('Build scheduled during frame.'));
      // The post-frame callback destroyed the partial chart.
      expect(Chart.instances, isEmpty);
    });

    testWidgets('an error in a plugin install hook is reported, the host '
        'keeps a size, and a new config starts the chart', (tester) async {
      final boom = <String, Object?>{
        'id': 'boom',
        'install': (Object? chart, Object? args, Object? options) {
          throw StateError('boom');
        },
      };
      final details = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = details.add;
      addTearDown(() => FlutterError.onError = previous);
      await tester.pumpWidget(
        _box(ChartView(config: _config(plugins: [boom]))),
      );
      expect(details, hasLength(1));
      expect(details.single.exception, isA<StateError>());
      expect(details.single.library, 'flutter_chartjs_port');
      expect(
        details.single.context.toString(),
        'while the ChartView started its chart',
      );
      // The canvas default: initCanvas gave the canvas its render size.
      expect(_host(tester).size, const Size(300, 150));
      // The post-frame callback destroyed the partial chart.
      expect(Chart.instances, isEmpty);

      await tester.pumpWidget(_box(ChartView(config: _config(plugins: []))));
      await tester.pump();
      expect(details, hasLength(1));
      final chart = _chart(tester)!;
      expect(chart.attached, isTrue);
      expect(Chart.instances.values, [chart]);
      expect(_host(tester).size, const Size(400, 200));
    });

    testWidgets('a chart in an offstage overlay entry starts at its first '
        'layout', (tester) async {
      final cover = OverlayEntry(
        opaque: true,
        builder: (context) => const SizedBox.expand(),
      );
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                maintainState: true,
                builder: (context) => Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 400,
                    child: ChartView(config: _config()),
                  ),
                ),
              ),
              cover,
            ],
          ),
        ),
      );
      // The theater builds the offstage entry, but it does not lay it out
      // (widgets/overlay.dart, _Theater): no first layout, no chart.
      expect(find.byType(ChartView, skipOffstage: false), findsOneWidget);
      expect(Chart.instances, isEmpty);

      cover.remove();
      await tester.pump();
      final chart = Chart.instances.values.single;
      expect(chart.attached, isTrue);
      expect((chart.width, chart.height), (400.0, 200.0));
      cover.dispose();
    });
  });

  group('life cycle and keys', () {
    testWidgets('a rebuild keeps the canvas and the chart', (tester) async {
      final config = _config();
      await tester.pumpWidget(_box(ChartView(config: config)));
      final canvas = _canvas(tester);
      final chart = _chart(tester);
      await tester.pumpWidget(_box(ChartView(config: config), width: 380));
      await tester.pump();
      expect(_canvas(tester), same(canvas));
      expect(_chart(tester), same(chart));
      expect(Chart.instances.values, [chart]);
    });

    testWidgets('a new key makes a new chart', (tester) async {
      final config = _config();
      await tester.pumpWidget(
        _box(ChartView(key: const ValueKey(1), config: config)),
      );
      final canvas = _canvas(tester);
      final chart = _chart(tester)!;
      await tester.pumpWidget(
        _box(ChartView(key: const ValueKey(2), config: config)),
      );
      expect(_canvas(tester), isNot(same(canvas)));
      expect(chart.canvas, isNull);
      expect(_chart(tester), isNot(same(chart)));
      expect(Chart.instances, hasLength(1));
    });

    testWidgets('a GlobalKey move keeps the chart', (tester) async {
      final key = GlobalKey();
      final config = _config(options: {'maintainAspectRatio': false});
      Widget build({required bool left}) => _box(
        Row(
          children: [
            SizedBox(
              width: 200,
              child: left ? ChartView(key: key, config: config) : null,
            ),
            SizedBox(
              width: 200,
              child: left ? null : ChartView(key: key, config: config),
            ),
          ],
        ),
      );
      await tester.pumpWidget(build(left: true));
      final chart = _chart(tester)!;
      final host = _host(tester);
      await tester.pumpWidget(build(left: false));
      await tester.pump();
      expect(_host(tester), same(host));
      expect(_chart(tester), same(chart));
      expect(chart.attached, isTrue);
      expect(tester.getTopLeft(find.byType(ChartView)).dx, 200);
    });

    testWidgets('an unmount destroys the chart, disposes the context and '
        'empties Chart.instances', (tester) async {
      final counts = <String, int>{};
      await tester.pumpWidget(
        _box(
          ChartView(
            config: _config(
              plugins: [_counter('destroy', 'afterDestroy', counts)],
            ),
          ),
        ),
      );
      final canvas = _canvas(tester);
      final chart = _chart(tester)!;
      await tester.pumpWidget(_box(const SizedBox()));
      expect(counts['afterDestroy'], 1);
      expect(chart.canvas, isNull);
      expect(Chart.instances, isEmpty);
      // A disposed context draws nothing.
      final context = canvas.getContext2d()..fillRect(0, 0, 10, 10);
      expect(context.isEmpty, isTrue);
    });
  });

  group('diagnostics', () {
    testWidgets('the widget and the state describe the chart, not the '
        'config', (tester) async {
      final widget = ChartView(
        config: _config(),
        updateMode: 'none',
        onChartCreated: (chart) {},
      );
      expect(_properties(widget), [
        'type: bar',
        'datasets: 1',
        'updateMode: "none"',
        'has onChartCreated',
      ]);
      expect(_properties(const ChartView(config: {})), ['type: null']);

      await tester.pumpWidget(_box(widget));
      final chart = _chart(tester)!;
      expect(_properties(tester.state(find.byType(ChartView))), [
        'id: ${chart.id.toInt()}',
        'attached',
        'size: Size(400.0, 200.0)',
      ]);
    });
  });

  group('update', () {
    testWidgets('the same Map gives no update', (tester) async {
      final counts = <String, int>{};
      final config = _config(
        plugins: [_counter('update', 'beforeUpdate', counts)],
      );
      await tester.pumpWidget(_box(ChartView(config: config)));
      expect(counts['beforeUpdate'], 1);
      await tester.pumpWidget(_box(ChartView(config: config)));
      await tester.pump();
      expect(counts['beforeUpdate'], 1);
    });

    testWidgets('a new Map gives one update in the post-frame phase', (
      tester,
    ) async {
      final phases = <SchedulerPhase>[];
      final plugins = <Object?>[
        <String, Object?>{
          'id': 'update',
          'beforeUpdate': (Object? chart, Object? args, Object? options) {
            phases.add(SchedulerBinding.instance.schedulerPhase);
          },
        },
      ];
      final config = _config(plugins: plugins);
      await tester.pumpWidget(_box(ChartView(config: config)));
      // The start updates the chart in the layout of the host.
      expect(phases, [SchedulerPhase.persistentCallbacks]);
      await tester.pumpWidget(
        _box(ChartView(config: Map<String, Object?>.of(config))),
      );
      expect(phases, [
        SchedulerPhase.persistentCallbacks,
        SchedulerPhase.postFrameCallbacks,
      ]);
      await tester.pump();
      expect(phases, hasLength(2));
    });

    testWidgets('three new Maps in one frame give one update with the last', (
      tester,
    ) async {
      final counts = <String, int>{};
      final plugins = <Object?>[_counter('update', 'beforeUpdate', counts)];
      await tester.pumpWidget(_Parent(config: _config(plugins: plugins)));
      final parent = tester.state<_ParentState>(find.byType(_Parent));
      final chart = _chart(tester)!;
      final owner = tester.binding.buildOwner!;
      final root = tester.binding.rootElement!;
      late Map<String, Object?> last;
      for (final values in const [
        <Object?>[4, 5, 6],
        <Object?>[7, 8, 9],
        <Object?>[10, 11, 12],
      ]) {
        parent.show(last = _config(plugins: plugins, data: values));
        // A build outside a frame: the three builds come before the frame.
        owner.buildScope(root);
      }
      expect(counts['beforeUpdate'], 1);
      await tester.pump();
      expect(counts['beforeUpdate'], 2);
      expect(_chart(tester), same(chart));
      expect(chart.data, same(last['data']));
      expect(chart.getDatasetMeta(0).data, hasLength(3));
      expect(
        jsGet(chart.getDatasetMeta(0).controller!.getParsed(0), 'y'),
        10,
      );
    });

    testWidgets('a replayed onHover with setState gives no exception', (
      tester,
    ) async {
      late _ParentState parent;
      var hovers = 0;
      Map<String, Object?> make() => _config(
        options: <String, Object?>{
          'onHover': (types.ChartEvent event, List<Object?> active, Chart c) {
            hovers++;
            parent.write('hover $hovers');
          },
        },
      );
      final first = make();
      await tester.pumpWidget(_Parent(config: first));
      parent = tester.state<_ParentState>(find.byType(_Parent));
      final chart = _chart(tester)!;
      final center = tester.getCenter(find.byType(ChartView));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: center);
      await mouse.moveTo(center + const Offset(1, 0));
      await tester.pump();
      await tester.pump();
      expect(hovers, 1);
      expect(find.text('hover 1'), findsOneWidget);
      expect(chart.lastEvent, isNotNull);

      // The update replays the last event (core.controller.js:529-532) after
      // the frame, where setState is allowed.
      final second = Map<String, Object?>.of(first);
      parent.show(second);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(hovers, 2);
      await tester.pump();
      expect(find.text('hover 2'), findsOneWidget);
      await tester.pump();
      expect(hovers, 2);
    });

    testWidgets('a new type changes the controllers', (tester) async {
      final config = _config();
      await tester.pumpWidget(_box(ChartView(config: config)));
      final chart = _chart(tester)!;
      expect(chart.getDatasetMeta(0).type, 'bar');
      await tester.pumpWidget(
        _box(ChartView(config: {...config, 'type': 'line'})),
      );
      expect(_chart(tester), same(chart));
      expect(chart.config.type, 'line');
      expect(chart.getDatasetMeta(0).type, 'line');
    });

    testWidgets('a new plugins List calls stop and start and keeps the chart', (
      tester,
    ) async {
      final log = <String>[];
      AnyObject plugin(String id) => <String, Object?>{
        'id': id,
        'start': (Object? chart, Object? args, Object? options) {
          log.add('$id.start');
        },
        'stop': (Object? chart, Object? args, Object? options) {
          log.add('$id.stop');
        },
      };
      final config = _config(plugins: [plugin('a')]);
      await tester.pumpWidget(_box(ChartView(config: config)));
      final chart = _chart(tester)!;
      final id = chart.id;
      expect(log, ['a.start']);
      await tester.pumpWidget(
        _box(
          ChartView(
            config: {
              ...config,
              'plugins': [plugin('b')],
            },
          ),
        ),
      );
      expect(log, ['a.start', 'a.stop', 'b.start']);
      expect(_chart(tester), same(chart));
      expect(chart.id, id);
    });

    testWidgets('a new platform makes a new chart and calls onChartCreated '
        'again', (tester) async {
      final created = <Chart>[];
      final config = _config();
      Widget build(Map<String, Object?> config) => _box(
        ChartView(config: config, onChartCreated: created.add),
      );
      await tester.pumpWidget(build(config));
      expect(created, hasLength(1));
      final first = created.single;
      await tester.pumpWidget(
        build({...config, 'platform': BasicPlatform.jsClass}),
      );
      expect(created, hasLength(2));
      expect(first.canvas, isNull);
      expect(created.last, isNot(same(first)));
      expect(created.last.platform, isA<BasicPlatform>());
      expect(created.last.platform, isNot(isA<FlutterPlatform>()));
      expect(created.last.canvas, same(_canvas(tester)));
      expect(Chart.instances.values, [created.last]);
    });

    testWidgets('updateMode reaches beforeUpdate as args.mode', (tester) async {
      final modes = <Object?>[];
      final config = _config(
        plugins: [
          <String, Object?>{
            'id': 'mode',
            'beforeUpdate': (Object? chart, Object? args, Object? options) {
              modes.add(jsGet(args, 'mode'));
            },
          },
        ],
      );
      await tester.pumpWidget(_Parent(config: config));
      final parent = tester.state<_ParentState>(find.byType(_Parent))
        ..show(Map.of(config), mode: 'none');
      await tester.pump();
      parent.show(Map.of(config));
      await tester.pump();
      expect(modes, [undefined, 'none', undefined]);
    });

    testWidgets('notifyArrayListeners after a push animates the insert', (
      tester,
    ) async {
      final data = <Object?>[1, 2, 3];
      final config = _config(
        data: data,
        options: <String, Object?>{'animation': <String, Object?>{}},
      );
      await tester.pumpWidget(_box(ChartView(config: config)));
      final chart = _chart(tester)!;
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(animator.has(chart), isFalse);

      (jsGet(config['data'], 'labels')! as List<Object?>).add('d');
      data.add(4);
      notifyArrayListeners(data, 'push', [4]);
      chart.update();
      expect(chart.getDatasetMeta(0).data, hasLength(4));
      expect(animator.has(chart), isTrue);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(animator.has(chart), isFalse);
    });

    testWidgets('a chart.options edit stays after chart.update() and goes '
        'after a new options object', (tester) async {
      final config = _config();
      await tester.pumpWidget(_box(ChartView(config: config)));
      final chart = _chart(tester)!;
      expect(chart.options['indexAxis'], 'x');
      chart.options['indexAxis'] = 'y';
      chart.update();
      expect(chart.options['indexAxis'], 'y');
      expect(chart.getDatasetMeta(0).indexAxis, 'y');

      // A new config Map with the same options object keeps the edit.
      await tester.pumpWidget(_box(ChartView(config: Map.of(config))));
      expect(chart.options['indexAxis'], 'y');

      // A new options object drops it. The chart writes into the options:
      // they are not const.
      final options = <String, Object?>{'animation': false};
      await tester.pumpWidget(
        _box(ChartView(config: {...config, 'options': options})),
      );
      expect(chart.options['indexAxis'], 'x');
      expect(chart.getDatasetMeta(0).indexAxis, 'x');
    });
  });

  group('size', () {
    // The rows of the table of Chart.js ADR 0049 §5: the bar chart has the
    // aspect ratio 2, the doughnut chart 1 (controller.doughnut.js:89). The
    // sizes come from FlutterPlatform.getMaximumSize and Chart.js ADR 0037
    // §5.
    final cases =
        <
          (
            String,
            Widget Function(Widget chart),
            Map<String, Object?>,
            Size,
            Size,
          )
        >[
          (
            'bounded width and height',
            _box,
            const {},
            const Size(400, 200),
            const Size(300, 300),
          ),
          (
            'bounded width, unbounded height (Column)',
            (chart) => _box(
              SingleChildScrollView(child: Column(children: [chart])),
            ),
            const {},
            const Size(400, 200),
            const Size(400, 400),
          ),
          (
            'unbounded width, bounded height (Row)',
            (chart) => _box(
              SizedBox(height: 120, child: Row(children: [chart])),
            ),
            const {},
            const Size(240, 120),
            const Size(120, 120),
          ),
          (
            'unbounded width and height',
            (chart) => _box(UnconstrainedBox(child: chart)),
            const {},
            const Size(300, 150),
            const Size(150, 150),
          ),
          (
            'maintainAspectRatio: false in a box',
            (chart) => _box(SizedBox(width: 350, height: 250, child: chart)),
            const {'maintainAspectRatio': false},
            const Size(350, 250),
            const Size(350, 250),
          ),
          (
            'maintainAspectRatio: false, unbounded height',
            (chart) => _box(
              SingleChildScrollView(child: Column(children: [chart])),
            ),
            const {'maintainAspectRatio': false},
            const Size(400, 150),
            const Size(400, 150),
          ),
          (
            'responsive: false',
            _box,
            const {'responsive': false},
            const Size(300, 150),
            const Size(300, 300),
          ),
        ];
    for (final (name, wrap, options, bar, doughnut) in cases) {
      for (final (type, expected) in [('bar', bar), ('doughnut', doughnut)]) {
        testWidgets('$name: $type', (tester) async {
          await tester.pumpWidget(
            wrap(
              ChartView(
                config: _config(type: type, options: options),
              ),
            ),
          );
          // The first ResizeObserver notification comes at the next layout.
          await tester.pump();
          await tester.pump();
          final chart = _chart(tester)!;
          expect(Size(chart.width, chart.height), expected);
          expect(tester.getSize(find.byType(ChartView)), expected);
        });
      }
    }

    testWidgets('a change of the parent width resizes the chart in the next '
        'frame', (tester) async {
      final config = _config();
      await tester.pumpWidget(_box(ChartView(config: config)));
      final chart = _chart(tester)!;
      await tester.pumpWidget(_box(ChartView(config: config), width: 300));
      expect(chart.width, 400);
      await tester.pump();
      expect((chart.width, chart.height), (300.0, 150.0));
      expect(tester.getSize(find.byType(ChartView)), const Size(300, 150));
    });

    testWidgets('the intrinsic height before the start is the canvas default '
        '(Open 1)', (tester) async {
      await tester.pumpWidget(
        _box(IntrinsicHeight(child: ChartView(config: _config()))),
      );
      // IntrinsicHeight asks the host before its first layout: the canvas
      // has its default height of 150, not the 200 of the chart. The chart
      // starts in a box of that height and takes 400 x 200: the first
      // `resize()` has no size, so `getMaximumSize` does not cap the height
      // (helpers.dom.ts@v4.6.1:192-197). The host clips it in frame 1. The
      // intrinsic height then follows the display size of the canvas, so
      // the box grows to 200 in a later frame: the shift of Chart.js ADR
      // 0049, Open 1.
      expect(tester.getSize(find.byType(ChartView)).height, 150);
      final chart = _chart(tester)!;
      expect((chart.width, chart.height), (400.0, 200.0));
      await tester.pump();
      await tester.pump();
      expect(tester.getSize(find.byType(ChartView)).height, 200);
      expect((chart.width, chart.height), (400.0, 200.0));
    });
  });

  group('reduced motion', () {
    testWidgets('a start under the preference makes no animator entry, '
        'calls onComplete once and onProgress never', (tester) async {
      var complete = 0;
      var progress = 0;
      final config = _config(
        options: <String, Object?>{
          'animation': <String, Object?>{
            'onComplete': (Object? context) => complete++,
            'onProgress': (Object? context) => progress++,
          },
        },
      );
      await tester.pumpWidget(
        _motion(_box(ChartView(config: config)), reduced: true),
      );
      final chart = _chart(tester)!;
      expect(animator.has(chart), isFalse);
      expect((complete, progress), (1, 0));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(animator.has(chart), isFalse);
      expect((complete, progress), (1, 0));
      // The resolved options keep the durations (core.animations.js:68).
      expect(jsGet(chart.options['animation'], 'duration'), 1000);
      expect(
        _properties(tester.state(find.byType(ChartView))),
        contains('reduced motion'),
      );
    });

    testWidgets('a change of the preference to on ends a loop: true '
        'animation', (tester) async {
      final counts = <String, int>{};
      final config = _config(
        options: <String, Object?>{
          'animation': <String, Object?>{'loop': true},
        },
        plugins: [_counter('update', 'beforeUpdate', counts)],
      );
      Widget build({required bool reduced}) =>
          _motion(_box(ChartView(config: config)), reduced: reduced);
      await tester.pumpWidget(build(reduced: false));
      final chart = _chart(tester)!;
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      // The loop runs on after the 1000 ms of the animation.
      expect(animator.running(chart), isTrue);
      expect(counts['beforeUpdate'], 1);

      // The post-frame callback of the frame calls chart.update(): each
      // running animation ends at its target (core.animations.js:94-103).
      await tester.pumpWidget(build(reduced: true));
      expect(counts['beforeUpdate'], 2);
      await tester.pump(const Duration(milliseconds: 16));
      expect(animator.running(chart), isFalse);
      expect(animator.has(chart), isFalse);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(animator.has(chart), isFalse);
      expect(counts['beforeUpdate'], 2);
    });

    testWidgets('a change of the preference to off makes no update, and the '
        'next update animates', (tester) async {
      final counts = <String, int>{};
      final config = _config(
        options: <String, Object?>{'animation': <String, Object?>{}},
        plugins: [_counter('update', 'beforeUpdate', counts)],
      );
      Widget build(Map<String, Object?> config, {required bool reduced}) =>
          _motion(_box(ChartView(config: config)), reduced: reduced);
      await tester.pumpWidget(build(config, reduced: true));
      final chart = _chart(tester)!;
      expect(animator.has(chart), isFalse);

      await tester.pumpWidget(build(config, reduced: false));
      await tester.pump();
      expect(counts['beforeUpdate'], 1);
      expect(animator.has(chart), isFalse);
      expect(
        _properties(tester.state(find.byType(ChartView))),
        isNot(contains('reduced motion')),
      );

      await tester.pumpWidget(build(Map.of(config), reduced: false));
      expect(counts['beforeUpdate'], 2);
      expect(animator.has(chart), isTrue);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(animator.has(chart), isFalse);
    });

    testWidgets('a theme switch and a theme removal draw once', (
      tester,
    ) async {
      final counts = <String, int>{};
      final config = _config(
        options: <String, Object?>{'animation': <String, Object?>{}},
        plugins: [_counter('draw', 'afterDraw', counts)],
      );
      const themeA = ChartThemeData(color: Color(0xFFFF0000));
      const themeB = ChartThemeData(color: Color(0xFF0000FF));
      Widget build(ChartThemeData? theme) => _motion(
        _box(ChartView(config: config, theme: theme)),
        reduced: true,
      );
      await tester.pumpWidget(build(themeA));
      final chart = _chart(tester)!;
      await tester.pump(const Duration(seconds: 2));
      expect(counts['afterDraw'], 1);

      await tester.pumpWidget(build(themeB));
      expect(animator.has(chart), isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(counts['afterDraw'], 2);

      await tester.pumpWidget(build(null));
      expect(animator.has(chart), isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(counts['afterDraw'], 3);
    });

    testWidgets('defaults.animation stays unchanged', (tester) async {
      final animation = defaults['animation']! as AnyObject;
      final before = Map<String, Object?>.of(animation);
      final config = _config(
        options: <String, Object?>{'animation': <String, Object?>{}},
      );
      Widget build(Map<String, Object?> config, {required bool reduced}) =>
          _motion(_box(ChartView(config: config)), reduced: reduced);
      await tester.pumpWidget(build(config, reduced: true));
      await tester.pumpWidget(build(Map.of(config), reduced: true));
      await tester.pump();
      expect(defaults['animation'], same(animation));
      expect(animation, before);
      // The widget writes no animation option into the app config.
      expect(jsGet(config['options'], 'animation'), <String, Object?>{});
    });
  });

  group('callbacks', () {
    testWidgets('a tap and a mouse hover call onClick and onHover with typed '
        'parameters, and a setState in each updates a Text', (tester) async {
      late _ParentState parent;
      final calls = <String>[];
      final config = _config(
        options: <String, Object?>{
          'onHover':
              (
                types.ChartEvent event,
                List<types.ActiveElement> active,
                Chart chart,
              ) {
                calls.add('hover ${event.type} ${active.length}');
                parent.write(calls.last);
              },
          'onClick':
              (
                types.ChartEvent event,
                List<types.ActiveElement> active,
                Chart chart,
              ) {
                calls.add('click ${event.type} ${active.length}');
                parent.write(calls.last);
              },
        },
      );
      await tester.pumpWidget(_Parent(config: config));
      parent = tester.state<_ParentState>(find.byType(_Parent));
      final chart = _chart(tester)!;
      final bar = chart.getDatasetMeta(0).data[1];
      final point =
          tester.getTopLeft(find.byType(ChartView)) +
          Offset(bar.x, (bar.y + chart.chartArea!.bottom) / 2);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: point);
      await mouse.moveTo(point + const Offset(1, 0));
      await tester.pump();
      await tester.pump();
      expect(calls, ['hover mousemove 1']);
      expect(find.text('hover mousemove 1'), findsOneWidget);

      await mouse.removePointer();
      await tester.tapAt(point);
      await tester.pump();
      await tester.pump();
      expect(calls.last, 'click click 1');
      expect(find.text('click click 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a setState in the first onResize fails with the assert', (
      tester,
    ) async {
      late StateSetter setOuter;
      final config = _config(
        options: <String, Object?>{
          'onResize': (Object? chart, Object? size) => setOuter(() {}),
        },
      );
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setOuter = setState;
            return _box(ChartView(config: config));
          },
        ),
      );
      final error = tester.takeException();
      expect('$error', contains('Build scheduled during frame.'));
    });

    testWidgets('a setState in a post-frame callback of the first onResize '
        'passes', (tester) async {
      late StateSetter setOuter;
      var resizes = 0;
      var builds = 0;
      final config = _config(
        options: <String, Object?>{
          'onResize': (Object? chart, Object? size) {
            resizes++;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => setOuter(() {}),
            );
          },
        },
      );
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setOuter = setState;
            builds++;
            return _box(ChartView(config: config));
          },
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pump();
      expect(resizes, 1);
      expect(builds, 2);
      expect(_chart(tester)!.attached, isTrue);
    });
  });
}
