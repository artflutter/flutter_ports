import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FlutterView;

import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/controller.dart';
import 'package:chart_benchmark_lab/benchmark/data.dart';
import 'package:chart_benchmark_lab/benchmark/web_mode.dart';
import 'package:chart_benchmark_lab/charts/chart_adapter.dart';
import 'package:chart_benchmark_lab/ui/change_log.dart';
import 'package:chart_benchmark_lab/ui/page_note.dart';
import 'package:chart_benchmark_lab/ui/results_table.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

String _typeName(BenchmarkConfig config) => config.type.label.toLowerCase();

const String _sdkVersion = FlutterVersion.version ?? 'version unavailable';
const String _sdkChannel = FlutterVersion.channel ?? '';
const String _sdkDart = FlutterVersion.dartVersion ?? 'unavailable';
const String _sdkEngine = FlutterVersion.engineRevision ?? 'unavailable';
const String _sdkFramework = FlutterVersion.frameworkRevision ?? 'unavailable';

/// The version of the lab. A build of the workflow pages stamps it through
/// `--build-name` and `--build-number`, from the `lab/v*` tags of `cliff.toml`.
/// Another build has the version of `pubspec.yaml`.
const String _labVersion = String.fromEnvironment(
  'FLUTTER_BUILD_NAME',
  defaultValue: 'unavailable',
);
const String _labBuild = String.fromEnvironment('FLUTTER_BUILD_NUMBER');

/// Interactive, single-engine benchmark dashboard.
class BenchmarkPage extends StatefulWidget {
  /// Creates the test bed.
  const BenchmarkPage({this.onControllerReady, super.key});

  /// Allows an integration driver to use the same session controls as the UI.
  final ValueChanged<BenchmarkController>? onControllerReady;
  @override
  State<BenchmarkPage> createState() => _BenchmarkPageState();
}

class _BenchmarkPageState extends State<BenchmarkPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final BenchmarkController controller;
  static const _window = MethodChannel(
    'dev.artflutter.chart_benchmark_lab/window',
  );
  final ValueNotifier<bool> _matchingOnly = ValueNotifier(true);
  final GlobalKey _plotKey = GlobalKey();

  /// Keeps the sort of the table when a resize changes the page layout.
  final GlobalKey _resultsKey = GlobalKey();
  Timer? _displayRetry;
  final ValueNotifier<bool> _webModeNoteClosed = ValueNotifier(false);
  int _displayRetries = 0;
  late FlutterView _view;

  /// The size of the chart, from the last layout.
  Size? _plotSize;
  bool _viewportSyncQueued = false;

  @override
  void initState() {
    super.initState();
    controller = BenchmarkController(this);
    widget.onControllerReady?.call(controller);
    controller.addListener(_scheduleViewportSync);
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      _window.setMethodCallHandler((call) async {
        if (!mounted) return;
        if (call.method == 'visibility' && call.arguments is bool) {
          controller.setWindowVisible(visible: call.arguments as bool);
        } else if (call.method == 'screenChanged' &&
            (controller.running || controller.finishing)) {
          controller.pause('Display changed. Run again on the new display.');
        }
      });
      unawaited(_readWindowVisibility());
    }
  }

  Future<void> _readWindowVisibility() async {
    try {
      final visible = await _window.invokeMethod<bool>('isVisible');
      if (mounted && visible != null) {
        controller.setWindowVisible(visible: visible);
      }
    } on MissingPluginException {
      // Widget tests and other embedders may only provide lifecycle events.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _view = View.of(context);
  }

  @override
  void didChangeMetrics() => _scheduleViewportSync();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      controller.setWindowVisible(visible: false);
    } else if (state == AppLifecycleState.resumed) {
      controller.setWindowVisible(visible: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _displayRetry?.cancel();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      _window.setMethodCallHandler(null);
    }
    controller
      ..removeListener(_scheduleViewportSync)
      ..dispose();
    _matchingOnly.dispose();
    _webModeNoteClosed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _PageValue<bool>(
    value: MediaQuery.sizeOf(context).width < 600,
    child: _page,
  );

  // Each section of the page is one widget instance for the life of the page.
  // A rebuild of a parent stops at the same instance, and a section rebuilds
  // only when a value that it reads changes (`_Selected`). A chart frame, a
  // readout, a scroll and a resize step thus leave the other sections alone.
  late final Widget _page = _Selected(
    listenable: Listenable.merge([controller, _webModeNoteClosed]),
    select: () => (
      controller.running || controller.finishing || controller.batchCapturing,
      controller.stopReason,
      _webModeNoteClosed.value,
    ),
    builder: (context) =>
        Scaffold(floatingActionButton: _pageNote(), body: _body),
  );

  late final Widget _body = SafeArea(
    child: Builder(
      builder: (context) {
        final narrow = _isNarrow(context);
        return Padding(
          padding: EdgeInsets.all(narrow ? 12 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _headerSection,
              SizedBox(height: narrow ? 10 : 20),
              Expanded(child: _main),
              const SizedBox(height: 6),
              const Text(
                'Lab version $_labVersion'
                '${_labBuild == "" ? "" : "+$_labBuild"}',
                key: ValueKey('lab.version'),
                style: TextStyle(color: Color(0xff64748b), fontSize: 11),
              ),
            ],
          ),
        );
      },
    ),
  );

  /// The chart fits inside its scroll view, because a test measures only a
  /// chart in full view. Only a short window takes less than the usual height,
  /// and a result keeps its size in its comparison key.
  late final Widget _main = LayoutBuilder(
    builder: (context, constraints) => _PageValue<double>(
      value: math.min(
        MediaQuery.sizeOf(context).width < 700 ? 300 : 420,
        math.max(160, constraints.maxHeight - 8),
      ),
      child: constraints.maxWidth >= 1000 ? _wideLayout : _narrowLayout,
    ),
  );

  // A boundary below a scroll view moves the finished layer: a scroll frame
  // records no paint.
  late final Widget _wideLayout = Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 292,
        child: SingleChildScrollView(
          child: RepaintBoundary(child: _settingsSection(card: true)),
        ),
      ),
      const SizedBox(width: 20),
      Expanded(
        child: _chartScroll(
          SingleChildScrollView(child: RepaintBoundary(child: _content)),
        ),
      ),
    ],
  );

  late final Widget _narrowLayout = _chartScroll(
    SingleChildScrollView(
      child: RepaintBoundary(
        child: Column(
          children: [
            Card(
              // The hover color of the tile stays inside the rounded corners.
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                title: const Text('Test configuration'),
                subtitle: _Selected(
                  listenable: controller,
                  select: () =>
                      (controller.config.type, controller.config.count),
                  builder: (_) => Text(
                    '${controller.config.type.label} · '
                    '${_number(controller.config.count)} items',
                  ),
                ),
                children: [_settingsSection(card: false)],
              ),
            ),
            const SizedBox(height: 16),
            _content,
          ],
        ),
      ),
    ),
  );

  late final Widget _headerSection = RepaintBoundary(
    child: _Selected(
      listenable: controller,
      select: () => (
        controller.running,
        controller.finishing,
        controller.capturing,
        controller.batchCapturing,
        controller.batchPosition,
        controller.batchTotal,
        controller.controlsLocked,
        controller.canRun,
        controller.captureSeconds,
      ),
      builder: _header,
    ),
  );

  Widget _settingsSection({required bool card}) => _Selected(
    listenable: controller,
    select: () => (
      controller.config,
      controller.controlsLocked,
      controller.captureSeconds,
    ),
    builder: (context) => _settings(context, card: card),
  );

  /// The note over the page, except during a run: a widget over the chart must
  /// not change the frames that the run measures. Why a test stopped comes
  /// first, because the status line below the chart can be out of view.
  Widget? _pageNote() {
    if (controller.running ||
        controller.finishing ||
        controller.batchCapturing) {
      return null;
    }
    final stopReason = controller.stopReason;
    if (stopReason != null) {
      return PageNote(
        title: 'TEST STOPPED',
        text: stopReason,
        onClose: controller.clearStopReason,
      );
    }
    final mode = webMode();
    final why = webModeWhy();
    if (mode == null || why == null || _webModeNoteClosed.value) return null;
    return PageNote(
      title: mode,
      text: '$why Figures of different modes do not compare.',
      onClose: () => _webModeNoteClosed.value = true,
    );
  }

  void _retryDisplay() {
    // During a native display move, the view configuration can briefly arrive
    // before its Display entry. Keep the previous rate and retry after metrics
    // settle; never fail chart layout because of this transient engine state.
    if (_displayRetry != null || _displayRetries >= 5) return;
    _displayRetries++;
    _displayRetry = Timer(const Duration(milliseconds: 100), () {
      _displayRetry = null;
      if (mounted) _syncViewport();
    });
  }

  /// After the next frame, gives the controller the size of the chart and the
  /// state of the display, and stops a test with a chart out of view. A change
  /// of the controller, of the layout or of the window can each change them.
  void _scheduleViewportSync() {
    if (_viewportSyncQueued) return;
    _viewportSyncQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewportSyncQueued = false;
      if (mounted) _syncViewport();
    });
  }

  void _syncViewport() {
    final size = _plotSize;
    if (size == null) return;
    var refreshRate = controller.refreshRate;
    try {
      refreshRate = _view.display.refreshRate;
      _displayRetries = 0;
      // Flutter can report a display before its registry entry.
      // ignore: avoid_catching_errors
    } on TypeError {
      _retryDisplay();
      // Debug mode asserts on the same transient condition.
      // ignore: avoid_catching_errors
    } on AssertionError {
      _retryDisplay();
    }
    controller.setViewport(size, _view.devicePixelRatio, refreshRate);
    _checkChartVisibility();
  }

  Widget _chartScroll(Widget child) => NotificationListener<ScrollNotification>(
    onNotification: (notification) {
      if (notification is ScrollStartNotification &&
          (controller.running || controller.finishing)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            controller.pause(
              'You scrolled during the test, so the test stopped and saved no '
              'result. A scroll adds frames that the chart does not cause, and '
              'it can move the chart out of view. Keep the full chart in view, '
              'run again, and do not scroll until the test ends.',
            );
          }
        });
      }
      return false;
    },
    child: child,
  );

  /// Whether the full chart is inside its scroll view.
  bool _chartInView() {
    final plot = _plotKey.currentContext?.findRenderObject();
    if (plot is! RenderBox || !plot.hasSize) return true;
    final viewport = RenderAbstractViewport.maybeOf(plot);
    if (viewport == null || viewport is! RenderBox) return true;
    final viewportBox = viewport as RenderBox;
    final visible = (viewportBox.localToGlobal(Offset.zero) & viewportBox.size)
        .inflate(1);
    final bounds = plot.localToGlobal(Offset.zero) & plot.size;
    return visible.contains(bounds.topLeft) &&
        visible.contains(bounds.bottomRight);
  }

  /// Whether the scroll view of the chart is shorter than the chart.
  bool _windowTooShort() {
    final plot = _plotKey.currentContext?.findRenderObject();
    if (plot is! RenderBox || !plot.hasSize) return false;
    final Object? viewport = RenderAbstractViewport.maybeOf(plot);
    return viewport is RenderBox && viewport.size.height < plot.size.height;
  }

  void _checkChartVisibility() {
    if (!controller.running && !controller.finishing) return;
    if (_chartInView()) return;
    controller.pause(
      _windowTooShort()
          ? 'The test stopped because this window is too short to show the '
                'full chart. Make the window taller, or turn the phone '
                'upright, and run again.'
          : 'The test stopped because part of the chart is out of view. A '
                'test measures only a chart that a person can see in full. '
                'Scroll until the full chart is in view, run again, and do not '
                'scroll until the test ends.',
    );
  }

  /// Moves the chart into view, then does [start]. On a phone the chart is
  /// below the controls, and a test measures only a chart in full view.
  Future<void> _withChartInView(VoidCallback start) async {
    final plot = _plotKey.currentContext;
    if (plot != null && !_chartInView()) {
      await Scrollable.ensureVisible(
        plot,
        alignment: 0.5,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
    if (mounted) start();
  }

  Widget _header(BuildContext context) {
    final narrow = _isNarrow(context);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: narrow ? 6 : 12,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: narrow ? 36 : 46,
              height: narrow ? 36 : 46,
              decoration: BoxDecoration(
                color: const Color(0xff4f46e5),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.monitor_heart_outlined,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chart benchmark lab',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (!narrow)
                    const Text(
                      'One dataset · four native Flutter engines',
                      style: TextStyle(color: Color(0xff64748b), fontSize: 12),
                    ),
                  const Tooltip(
                    message:
                        'Dart $_sdkDart\n'
                        'Engine $_sdkEngine\n'
                        'Framework $_sdkFramework',
                    child: Text(
                      'Flutter $_sdkVersion'
                      '${_sdkChannel == "" ? "" : " · $_sdkChannel"}',
                      key: ValueKey('flutter.version'),
                      style: TextStyle(color: Color(0xff64748b), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Wrap(
          spacing: narrow ? 4 : 8,
          runSpacing: narrow ? 4 : 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _badge(
              kDebugMode
                  ? 'DEBUG · use profile for timing'
                  : kProfileMode
                  ? 'PROFILE'
                  : 'RELEASE',
              kDebugMode ? const Color(0xff9a6700) : const Color(0xff15803d),
            ),
            if (webMode() case final mode?)
              _badge(mode, const Color(0xff475569)),
            ChangeLogButton(
              iconOnly: narrow,
              enabled:
                  !controller.running &&
                  !controller.finishing &&
                  !controller.batchCapturing,
            ),
            _action(
              context,
              key: 'run',
              narrow: narrow,
              label: controller.running ? 'Pause' : 'Run',
              icon: controller.running ? Icons.pause : Icons.play_arrow,
              onPressed: controller.controlsLocked || !controller.canRun
                  ? null
                  : () {
                      if (controller.running) {
                        controller.pause();
                      } else {
                        unawaited(_withChartInView(controller.start));
                      }
                    },
            ),
            _action(
              context,
              key: 'capture',
              narrow: narrow,
              filled: true,
              label: controller.capturing || controller.finishing
                  ? 'Cancel capture'
                  : 'Capture ${controller.captureSeconds}s',
              icon: controller.capturing || controller.finishing
                  ? Icons.stop
                  : Icons.fiber_manual_record,
              onPressed: controller.batchCapturing
                  ? null
                  : controller.capturing || controller.finishing
                  ? () => controller.pause()
                  : !controller.canRun
                  ? null
                  : () => unawaited(
                      _withChartInView(() {
                        controller
                          ..pause()
                          ..start(capture: true);
                      }),
                    ),
            ),
            _action(
              context,
              key: 'capture.all',
              narrow: narrow,
              label: controller.batchCapturing
                  ? 'Cancel all (${controller.batchPosition}/'
                        '${controller.batchTotal})'
                  : 'Capture all ${controller.captureSeconds}s',
              icon: controller.batchCapturing
                  ? Icons.stop
                  : Icons.playlist_play,
              onPressed: controller.batchCapturing
                  ? () => controller.pause()
                  : controller.controlsLocked
                  ? null
                  : () => unawaited(_withChartInView(controller.captureAll)),
            ),
          ],
        ),
      ],
    );
  }

  /// A header action: an icon with a tooltip on a phone, else an icon and a
  /// label.
  Widget _action(
    BuildContext context, {
    required String key,
    required bool narrow,
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool filled = false,
  }) {
    final id = ValueKey(key);
    if (narrow) {
      final scheme = Theme.of(context).colorScheme;
      final style = IconButton.styleFrom(
        fixedSize: const Size.square(36),
        minimumSize: const Size.square(36),
        padding: EdgeInsets.zero,
        iconSize: 20,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: filled ? scheme.onPrimary : scheme.primary,
        backgroundColor: filled ? scheme.primary : null,
      );
      return filled
          ? IconButton.filled(
              key: id,
              style: style,
              tooltip: label,
              onPressed: onPressed,
              icon: Icon(icon),
            )
          : IconButton.outlined(
              key: id,
              style: style,
              tooltip: label,
              onPressed: onPressed,
              icon: Icon(icon),
            );
    }
    return filled
        ? FilledButton.icon(
            key: id,
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          )
        : OutlinedButton.icon(
            key: id,
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          );
  }

  Widget _settings(BuildContext context, {bool card = true}) {
    final config = controller.config;
    final locked = controller.controlsLocked;
    final isLine = config.type == ChartType.line;
    final drawsLine = config.type.drawsLine;
    final body = Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (card) ...[
            const Text('TEST CONFIGURATION', style: _eyebrow),
            const SizedBox(height: 18),
          ],
          const Text(
            'Chart type',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          RepaintBoundary(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final type in ChartType.values)
                  ChoiceChip(
                    key: ValueKey('type.${type.name}'),
                    label: Text(type.label),
                    avatar: Icon(type.icon, size: 17),
                    // Eight types must leave the feature toggles in view.
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    selected: config.type == type,
                    onSelected: locked
                        ? null
                        : (_) =>
                              controller.configure(config.copyWith(type: type)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          RepaintBoundary(
            child: _DatasetSlider(
              value: config.count,
              enabled: !locked,
              onChanged: (value) =>
                  controller.configure(config.copyWith(count: value)),
            ),
          ),
          const Divider(height: 32),
          const Text('Workload', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<Workload>(
            showSelectedIcon: false,
            segments: [
              for (final mode in Workload.values)
                ButtonSegment(
                  value: mode,
                  label: Text(mode.label, style: const TextStyle(fontSize: 12)),
                ),
            ],
            selected: {config.workload},
            onSelectionChanged: locked
                ? null
                : (value) => controller.configure(
                    config.copyWith(workload: value.first),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            config.workload == Workload.live
                ? 'New values each display tick. Native transitions are off.'
                : 'Dispose and recreate the chart every tick, '
                      'using the same values.',
            style: const TextStyle(fontSize: 12, color: Color(0xff64748b)),
          ),
          const Divider(height: 28),
          const Text('FEATURES', style: _eyebrow),
          _toggle(
            'Point markers',
            'markers',
            config.markers,
            !locked && drawsLine,
            (v) => controller.configure(config.copyWith(markers: v)),
            hint: 'Line, radar',
          ),
          _toggle(
            'Smooth lines',
            'curved',
            config.curved,
            !locked && isLine,
            (v) => controller.configure(config.copyWith(curved: v)),
            hint: 'Line only',
          ),
          _toggle(
            'Area fill',
            'fill',
            config.fill,
            !locked && drawsLine,
            (v) => controller.configure(config.copyWith(fill: v)),
            hint: 'Line, radar',
          ),
          _toggle(
            'Axis labels',
            'axes',
            config.axes,
            !locked && config.type.hasAxes,
            (v) => controller.configure(config.copyWith(axes: v)),
          ),
          _toggle(
            'Grid lines',
            'grid',
            config.grid,
            !locked && config.type.hasAxes,
            (v) => controller.configure(config.copyWith(grid: v)),
          ),
          _toggle(
            'Alternate item colors',
            'colors',
            config.alternateColors,
            !locked && config.type.hasItemColors,
            (v) => controller.configure(config.copyWith(alternateColors: v)),
            hint: 'Not line, radar',
          ),
          _toggle(
            'Tooltips',
            'tooltips',
            config.tooltips,
            !locked,
            (v) => controller.configure(config.copyWith(tooltips: v)),
          ),
          const Divider(height: 28),
          const Text(
            'Overlay labels',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: [
              for (final n in [0, 50, 200])
                ButtonSegment(value: n, label: Text('$n')),
            ],
            showSelectedIcon: false,
            selected: {config.overlayLabels},
            onSelectionChanged: locked
                ? null
                : (v) => controller.configure(
                    config.copyWith(overlayLabels: v.first),
                  ),
          ),
          _toggle(
            'Rotate labels',
            'rotate',
            config.rotateLabels,
            !locked && config.overlayLabels > 0,
            (v) => controller.configure(config.copyWith(rotateLabels: v)),
          ),
          const Divider(height: 28),
          Row(
            children: [
              const Expanded(child: Text('Capture length')),
              DropdownButton<int>(
                key: const ValueKey('capture.duration'),
                value: controller.captureSeconds,
                items: [
                  for (final n in [10, 30])
                    DropdownMenuItem(value: n, child: Text('$n seconds')),
                ],
                onChanged: locked
                    ? null
                    : (n) => controller.setCaptureSeconds(n!),
              ),
            ],
          ),
          const Text(
            'Plus 2 seconds of warmup. Keep the chart visible throughout '
            'the capture.',
            style: TextStyle(fontSize: 12, color: Color(0xff64748b)),
          ),
        ],
      ),
    );
    return card ? Card(child: body) : body;
  }

  late final Widget _content = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      RepaintBoundary(
        child: _Selected(
          listenable: controller,
          select: () => (
            controller.library,
            controller.controlsLocked,
            controller.config.type,
          ),
          builder: (_) => _librarySelector(),
        ),
      ),
      const SizedBox(height: 16),
      // A readout comes twice a second during a run.
      RepaintBoundary(
        child: ValueListenableBuilder<RunReadout>(
          valueListenable: controller.readout,
          builder: (context, value, _) => _metrics(context, value),
        ),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Selected(
                listenable: controller,
                select: () => (
                  controller.config.type,
                  controller.config.count,
                  controller.config.workload,
                ),
                builder: (context) => Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 8,
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${controller.config.type.label} · '
                      '${_number(controller.config.count)} items',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _badge(
                      controller.config.workload.label,
                      const Color(0xff64748b),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _plotSection,
              const SizedBox(height: 16),
              RepaintBoundary(child: _statusSection),
              const SizedBox(height: 7),
              _Selected(
                listenable: controller,
                select: () => (
                  controller.viewport,
                  controller.dpr,
                  controller.refreshRate,
                  controller.config.seed,
                ),
                builder: (_) => Text(
                  '${controller.viewport.width.round()} × '
                  '${controller.viewport.height.round()} logical px · DPR '
                  '${controller.dpr.toStringAsFixed(1)} · display '
                  '${controller.refreshRate.round()} Hz · seed '
                  '${controller.config.seed}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff94a3b8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      RepaintBoundary(
        child: _Selected(
          listenable: Listenable.merge([controller, _matchingOnly]),
          select: () => (
            Object.hashAll(controller.results),
            _matchingOnly.value,
            controller.workloadKey,
            // The table needs the key of the window only for this question,
            // and a resize changes the key on each step.
            _shownResultsFromOtherWindow(),
          ),
          builder: _results,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        kIsWeb
            ? 'Browser preview: engine timing availability varies. '
                  'Use native profile mode for UI/raster measurements.'
            : 'Use FPS and frame interval for end-to-end comparison. '
                  'Deferred work can fall outside engine UI-build timings. ',
        style: TextStyle(fontSize: 12, color: Color(0xff64748b)),
      ),
      // The last rows of the table can scroll above the note over the page.
      const SizedBox(height: 180),
    ],
  );

  Widget _librarySelector() => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 620 ? 2 : 4;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final engine in ChartLibrary.values)
            SizedBox(
              width: (constraints.maxWidth - (columns - 1) * 8) / columns,
              child: Semantics(
                selected: engine == controller.library,
                child: OutlinedButton(
                  key: ValueKey('library.${engine.name}'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                    backgroundColor: engine == controller.library
                        ? engine.color.withValues(alpha: .08)
                        : Colors.white,
                    side: BorderSide(
                      color: engine == controller.library
                          ? engine.color
                          : const Color(0xffdfe5ef),
                    ),
                  ),
                  onPressed: controller.controlsLocked
                      ? null
                      : () => controller.selectLibrary(engine),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: engine.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              engine.label,
                              maxLines: 1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xff17243b),
                              ),
                            ),
                            Text(
                              engine.supports(controller.config.type)
                                  ? 'v${engine.version}'
                                  : 'No ${_typeName(controller.config)} '
                                        'chart',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xff64748b),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );

  /// The chart and the overlay. The boundary keeps a chart frame from recording
  /// the column around the chart: the layout builder dirties its own paint each
  /// time that the chart below it builds.
  late final Widget _plotSection = _Selected(
    listenable: controller,
    select: () => (controller.library, controller.revision, controller.config),
    builder: (context) => SizedBox(
      height: _PageValue.of<double>(context),
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            _plotSize = size;
            _scheduleViewportSync();
            return ClipRect(
              key: _plotKey,
              child: ValueListenableBuilder<DatasetFrame>(
                valueListenable: controller.frames,
                builder: (context, frame, _) => Stack(
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: BenchmarkChart(
                          key: ValueKey((
                            controller.library,
                            controller.revision,
                            controller.config.workload == Workload.rebuild
                                ? frame.step
                                : 0,
                          )),
                          library: controller.library,
                          config: controller.config,
                          frame: frame,
                          size: size,
                        ),
                      ),
                    ),
                    if (controller.config.overlayLabels > 0)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: _LabelsPainter(
                                controller.config.overlayLabels,
                                frame.step,
                                rotate: controller.config.rotateLabels,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  late final Widget _statusSection = _Selected(
    listenable: controller,
    select: () => (
      controller.running,
      controller.finishing,
      controller.capturing,
      controller.message,
      controller.captureSeconds,
      controller.batchCapturing,
      controller.batchPosition,
      controller.batchTotal,
      controller.library,
    ),
    builder: (_) => ValueListenableBuilder<RunReadout>(
      valueListenable: controller.readout,
      builder: (context, value, _) {
        final warm = controller.running && value.seconds < 2;
        final progress = (value.seconds - 2)
            .clamp(0, controller.captureSeconds)
            .toStringAsFixed(1);
        final status = controller.finishing
            ? controller.message
            : warm
            ? 'Warming up… ${value.seconds.toStringAsFixed(1)} / 2s'
            : controller.running
            ? controller.capturing
                  ? 'Capturing $progress / ${controller.captureSeconds}s'
                  : 'Live · ${value.timings.samples} '
                        'recent engine frames'
            : controller.message;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.capturing) ...[
              LinearProgressIndicator(
                value: controller.finishing
                    ? 1
                    : (value.seconds / (controller.captureSeconds + 2)).clamp(
                        0,
                        1,
                      ),
                minHeight: 3,
              ),
              const SizedBox(height: 10),
            ],
            Text(
              controller.batchCapturing
                  ? '${controller.batchPosition}/'
                        '${controller.batchTotal} · '
                        '${controller.library.label} · $status'
                  : status,
              style: const TextStyle(fontSize: 12, color: Color(0xff64748b)),
            ),
          ],
        );
      },
    ),
  );

  Widget _metrics(BuildContext context, RunReadout readout) {
    final m = readout.timings;
    String number(double v, [int decimals = 2]) =>
        m.samples == 0 ? '—' : v.toStringAsFixed(decimals);
    final values = [
      ('FPS', number(m.fps, 1), 'engine frames / second', false),
      (
        'FRAME INTERVAL',
        '${number(m.intervalP90)} ms',
        'p90 · includes deferred work',
        m.intervalP90 > 1000 / 60 + 1,
      ),
      (
        'UI FRAME',
        '${number(m.uiP90)} ms',
        'build p90 · mean ${number(m.uiMean)} ms',
        m.uiP90 > 1000 / 60,
      ),
      (
        'RASTER',
        '${number(m.rasterP90)} ms',
        'p90 · mean ${number(m.rasterMean)} ms',
        m.rasterP90 > 1000 / 60,
      ),
      (
        'OVER BUDGET',
        '${number(m.overBudgetPercent, 1)}%',
        'phase budget or late cadence',
        m.overBudgetPercent > 10,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 750 ? 2 : 5;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, value, detail, slow) in values)
              SizedBox(
                width: (constraints.maxWidth - (columns - 1) * 8) / columns,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: _eyebrow),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: slow
                                  ? const Color(0xffb45309)
                                  : const Color(0xff17243b),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          detail,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xff64748b),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Whether a row that the table shows comes from another window.
  bool _shownResultsFromOtherWindow() {
    final current = controller.comparisonKey;
    final workload = controller.workloadKey;
    return controller.results.any(
      (r) =>
          (!_matchingOnly.value || r.workloadKey == workload) &&
          r.comparisonKey != current,
    );
  }

  Widget _results(BuildContext context) {
    final workload = controller.workloadKey;
    final matching = controller.results
        .where((r) => !_matchingOnly.value || r.workloadKey == workload)
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 6,
              children: [
                Text(
                  'Saved comparisons',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text(
                        'Matching setup',
                        style: TextStyle(fontSize: 11),
                      ),
                      selected: _matchingOnly.value,
                      onSelected: (v) => _matchingOnly.value = v,
                    ),
                    IconButton(
                      tooltip: 'Clear captures',
                      onPressed: controller.results.isEmpty
                          ? null
                          : controller.clearResults,
                      icon: const Icon(Icons.delete_outline, size: 19),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('export'),
                      onPressed: controller.results.isEmpty
                          ? null
                          : () async {
                              await Clipboard.setData(
                                ClipboardData(text: controller.exportJson()),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Capture JSON copied to clipboard',
                                    ),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy JSON'),
                    ),
                  ],
                ),
              ],
            ),
            if (matching.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Text(
                  controller.results.isEmpty
                      ? 'Capture a run, switch libraries, and capture again. '
                            'Results stay separate and keep their settings.'
                      : 'No captures match this setup. '
                            'Turn off the filter to inspect earlier runs.',
                  style: const TextStyle(
                    color: Color(0xff64748b),
                    fontSize: 13,
                  ),
                ),
              )
            else
              ResultsTable(
                key: _resultsKey,
                results: matching,
                currentKey: controller.comparisonKey,
              ),
          ],
        ),
      ),
    );
  }
}

const _eyebrow = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.1,
  color: Color(0xff64748b),
);

/// A phone in the upright position, with little height above the chart.
bool _isNarrow(BuildContext context) => _PageValue.of<bool>(context);

/// One value of the page shape. A reader rebuilds when the value changes, and
/// not on each step of a resize.
class _PageValue<T> extends InheritedWidget {
  const _PageValue({required this.value, required super.child});

  final T value;

  static T of<T>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PageValue<T>>()!.value;

  @override
  bool updateShouldNotify(_PageValue<T> oldWidget) => value != oldWidget.value;
}

/// Builds a section of the page, and rebuilds it only when [select] gives
/// another value. [select] must cover each value that [builder] reads.
class _Selected<T> extends StatefulWidget {
  const _Selected({
    required this.listenable,
    required this.select,
    required this.builder,
    super.key,
  });

  final Listenable listenable;
  final T Function() select;
  final WidgetBuilder builder;

  @override
  State<_Selected<T>> createState() => _SelectedState<T>();
}

class _SelectedState<T> extends State<_Selected<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    // The value of the first build: a later change must compare with it.
    _value = widget.select();
    widget.listenable.addListener(_changed);
  }

  @override
  void didUpdateWidget(covariant _Selected<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listenable != widget.listenable) {
      oldWidget.listenable.removeListener(_changed);
      widget.listenable.addListener(_changed);
    }
    _value = widget.select();
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final value = widget.select();
    if (value != _value) setState(() => _value = value);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

String _number(int value) => value >= 1000
    ? '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k'
    : '$value';
Widget _badge(String label, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: color.withValues(alpha: .08),
    borderRadius: BorderRadius.circular(7),
  ),
  child: Text(
    label,
    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
  ),
);
Widget _toggle(
  String label,
  String id,
  bool value,
  bool enabled,
  ValueChanged<bool> onChanged, {
  String? hint,
}) => SwitchListTile(
  key: ValueKey('feature.$id'),
  contentPadding: EdgeInsets.zero,
  dense: true,
  title: Text(label, style: const TextStyle(fontSize: 13)),
  subtitle: hint == null
      ? null
      : Text(hint, style: const TextStyle(fontSize: 10)),
  value: value,
  onChanged: enabled ? onChanged : null,
);

class _DatasetSlider extends StatefulWidget {
  const _DatasetSlider({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;
  @override
  State<_DatasetSlider> createState() => _DatasetSliderState();
}

class _DatasetSliderState extends State<_DatasetSlider> {
  late int value = widget.value;
  @override
  void didUpdateWidget(covariant _DatasetSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) value = widget.value;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Dataset size',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            _number(value),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xff4f46e5),
            ),
          ),
        ],
      ),
      Slider(
        key: const ValueKey('dataset.slider'),
        value: value.toDouble(),
        min: 100,
        max: 20000,
        divisions: 199,
        label: '$value items',
        onChanged: widget.enabled
            ? (v) => setState(() => value = v.round())
            : null,
        onChangeEnd: widget.enabled ? (v) => widget.onChanged(v.round()) : null,
      ),
      Wrap(
        spacing: 6,
        children: [
          for (final n in [100, 1000, 5000, 20000])
            ActionChip(
              key: ValueKey('dataset.$n'),
              label: Text(_number(n)),
              onPressed: widget.enabled
                  ? () {
                      setState(() => value = n);
                      widget.onChanged(n);
                    }
                  : null,
            ),
        ],
      ),
      const SizedBox(height: 6),
      const Text(
        'All items are passed to the library. No harness downsampling.',
        style: TextStyle(fontSize: 11, color: Color(0xff64748b)),
      ),
    ],
  );
}

class _LabelsPainter extends CustomPainter {
  _LabelsPainter(this.count, this.step, {required this.rotate});
  final bool rotate;
  final int count;
  final int step;
  @override
  void paint(Canvas canvas, Size size) {
    final columns = math.max(
      1,
      math.sqrt(count * size.width / size.height).ceil(),
    );
    final rows = (count / columns).ceil();
    for (var i = 0; i < count; i++) {
      final text = TextPainter(
        text: TextSpan(
          text: 'Label $i',
          style: const TextStyle(color: Color(0xff677489), fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas
        ..save()
        ..translate(
          (i % columns + .5) * size.width / columns,
          (i ~/ columns + .5) * size.height / rows,
        )
        ..rotate(
          !rotate ? -math.pi / 4 : math.sin(step / 60 + i * .3) * math.pi / 3,
        );
      text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
      canvas.restore();
      text.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _LabelsPainter oldDelegate) =>
      oldDelegate.count != count || oldDelegate.step != step;
}
