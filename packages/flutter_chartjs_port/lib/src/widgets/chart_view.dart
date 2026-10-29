// Original code, not ported from Chart.js: the public chart widget.

/// The public chart widget [ChartView] (Chart.js ADR 0049).
///
/// The widget owns one canvas for the life of its state, shows it in the
/// internal chart host and starts its chart in the first layout of the host
/// (Chart.js ADR 0049, section 2). It gives the chart a root Map that it
/// owns, and it applies a new config in one post-frame callback (section
/// 4). The theme of Chart.js ADR 0050 and the input of Chart.js ADR 0051
/// build on the root Map and on that callback.
///
/// The widget registers no component (Chart.js ADR 0048, section 3): no
/// file of `lib/src/widgets/` imports a controller, a scale, an element, a
/// plugin or an index of them. It never writes `defaults` or `overrides`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.animator.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';

/// Shows one Chart.js chart: `new Chart(canvas, config)` on a canvas that the
/// widget owns. Register the components first: `Chart.register(registerables)`.
///
/// Size: the constraints and the options `responsive`, `maintainAspectRatio`
/// and `aspectRatio` give the size (the table of Chart.js ADR 0049 §5). In a
/// `Column` or a scroll view, the aspect ratio gives the height. In a
/// `SizedBox` or an `Expanded`, set `maintainAspectRatio: false`.
///
/// Callbacks: the options `onHover`, `onClick` and `onResize` and the plugin
/// hooks are function values in [config]. The table of the phases where a
/// callback can call `setState` is in Chart.js ADR 0049 §6. The hooks of
/// the start (`install`, `start`, `beforeInit`, `afterInit`, the first
/// update and the first `onResize`) run in the layout of the host: there, a
/// callback must not call `setState`, and it calls
/// `WidgetsBinding.instance.addPostFrameCallback` instead.
class ChartView extends StatefulWidget {
  /// Creates a widget that shows the chart of [config].
  const ChartView({
    required this.config,
    this.updateMode,
    this.onChartCreated,
    super.key,
  });

  /// The raw configuration `{type, data, options, plugins, platform}`
  /// (`jsonDecode` output works). The chart writes into its `data` and
  /// `options` Maps, as `initConfig` does. A nested Map literal needs the
  /// type `<String, Object?>`.
  ///
  /// A new Map updates the chart after the frame; the same Map gives no
  /// update. The update sets `type`, `data` and `options` when they are new
  /// objects, as the upstream setters do, and the inline plugins when
  /// `plugins` is a new List: the chart, its hidden datasets and its
  /// animations stay. A new `platform` makes a new chart. Keep the dataset
  /// Maps to keep the dataset metas.
  ///
  /// After a change in place, call `chart.update()` from an event handler or
  /// a post-frame callback, never from `build`. A change of a data List in
  /// place also calls `notifyArrayListeners` for `push`, `pop`, `shift`,
  /// `splice` and `unshift`. An imperative `chart.options` edit lasts until
  /// the next new `options` object.
  final Map<String, Object?> config;

  /// The mode of the `chart.update` call for a new [config]. Null is the
  /// default mode.
  final String? updateMode;

  /// Called after the frame in which the widget starts a chart, and again
  /// after a new `platform` replaces the chart.
  final ValueChanged<Chart>? onChartCreated;

  @override
  State<ChartView> createState() => _ChartViewState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final data = config['data'];
    final datasets = data is Map ? data['datasets'] : null;
    properties
      ..add(DiagnosticsProperty<Object?>('type', config['type']))
      ..add(
        IntProperty(
          'datasets',
          datasets is List ? datasets.length : null,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('updateMode', updateMode, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<Chart>>.has(
          'onChartCreated',
          onChartCreated,
        ),
      );
  }
}

class _ChartViewState extends State<ChartView> {
  /// The canvas of the chart, for the life of the state (Chart.js ADR
  /// 0016:300).
  final UiCanvasElement _canvas = UiCanvasElement();

  /// The chart, or null before the start and after a failed start.
  Chart? _chart;

  /// The root Map of the chart (Chart.js ADR 0049, section 4): a shallow
  /// copy of the app config that the widget owns. `data` and `options` keep
  /// the identity of the app objects.
  AnyObject? _root;

  /// The app config whose values the chart has: the config of the start or
  /// of the last update.
  AnyObject _applied = const {};

  /// The `enabled` value of the `TickerMode` of the host.
  bool _tickerEnabled = true;

  /// Whether the host had its first layout.
  bool _laidOut = false;

  /// Whether a post-frame update is pending.
  bool _updatePending = false;

  @override
  void didUpdateWidget(ChartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.config, widget.config)) _scheduleUpdate();
  }

  @override
  void dispose() {
    // A partial chart of a failed start is in `Chart.instances` too.
    final chart = _chart ?? Chart.getChart(_canvas);
    _chart = null;
    try {
      chart?.destroy();
    } finally {
      _canvas.getContext2d().dispose();
    }
    super.dispose();
  }

  /// The first layout of the host: the start (Chart.js ADR 0049, section 2,
  /// step 3). A later call, after a new host took over the canvas, does
  /// nothing: a state with a chart keeps it, and a state after a failed
  /// start waits for a new config.
  void _onFirstLayout() {
    if (_laidOut) return;
    _laidOut = true;
    _start(notify: false);
  }

  /// Builds the root Map of the current config and starts the chart. With
  /// [notify], it calls `onChartCreated` at once (in a post-frame callback),
  /// else after the frame.
  void _start({required bool notify}) {
    final config = _applied = widget.config;
    final root = _root = Map<String, Object?>.of(config);
    root['plugins'] = _rootPlugins(jsGet(config, 'plugins'));
    _create(notify: notify);
  }

  /// `new Chart(canvas, root)`. An exception goes to
  /// `FlutterError.reportError`, and a post-frame callback destroys the
  /// partial chart that `Chart.instances` keeps (core.controller.js:177),
  /// so that the next new config can start the chart.
  void _create({required bool notify}) {
    final Chart chart;
    try {
      chart = Chart(_canvas, _root);
    } on Object catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'flutter_chartjs_port',
          context: ErrorDescription('while the ChartView started its chart'),
        ),
      );
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _destroyPartialChart();
      }, debugLabel: 'ChartView.destroyPartialChart');
      return;
    }
    _chart = chart;
    if (!_tickerEnabled) animator.mute(chart);
    if (notify) {
      widget.onChartCreated?.call(chart);
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(_chart, chart)) {
        widget.onChartCreated?.call(chart);
      }
    }, debugLabel: 'ChartView.onChartCreated');
  }

  /// Destroys the chart on the canvas that is not the chart of the state:
  /// the partial chart of a failed start.
  void _destroyPartialChart() {
    final partial = Chart.getChart(_canvas);
    if (partial != null && !identical(partial, _chart)) partial.destroy();
  }

  /// The `plugins` of the root Map for the app value [app]: a new List with
  /// the inline plugins of the app (a List, else none) and the entries of
  /// the widget. Chart.js ADRs 0050 and 0051 add the widget entries.
  static List<Object?> _rootPlugins(Object? app) => [if (app is List) ...app];

  /// Schedules one post-frame update, none when one is pending (Chart.js
  /// ADR 0049, section 4).
  void _scheduleUpdate() {
    if (_updatePending) return;
    _updatePending = true;
    SchedulerBinding.instance
      ..addPostFrameCallback(_update, debugLabel: 'ChartView.update')
      ..ensureVisualUpdate();
  }

  /// The update of Chart.js ADR 0049, section 4: the values of the last
  /// config that are new objects go to the chart, then one `chart.update`.
  /// It runs after the frame, so every hook of the update, also the replay
  /// of the last event (core.controller.js:529-532), runs outside the build.
  void _update(Duration _) {
    _updatePending = false;
    // The first layout starts the chart with the last config.
    if (!mounted || !_laidOut) return;
    final chart = _chart;
    if (chart == null) {
      // After a failed start.
      _destroyPartialChart();
      _start(notify: true);
      return;
    }
    final config = widget.config;
    final applied = _applied;
    if (identical(config, applied)) return;
    _applied = config;
    final root = _root!;
    final type = jsGet(config, 'type');
    if (!identical(type, jsGet(applied, 'type'))) {
      // core.config.js:173 `set type(type)`.
      chart.config.type = type;
    }
    final data = jsGet(config, 'data');
    if (!identical(data, jsGet(applied, 'data'))) {
      // core.controller.js:217 `set data(data)`.
      chart.data = data;
    }
    final options = jsGet(config, 'options');
    if (!identical(options, jsGet(applied, 'options'))) {
      // core.controller.js:225 `set options(options)`.
      chart.options = options;
    }
    final plugins = jsGet(config, 'plugins');
    if (!identical(plugins, jsGet(applied, 'plugins'))) {
      // The next notify reads `config.plugins` again
      // (core.plugins.js:101-106) and calls `stop` and `start` for each id
      // that left or came (:113-119).
      root['plugins'] = _rootPlugins(plugins);
    }
    if (!identical(config['platform'], applied['platform'])) {
      // The constructor reads `platform` once (core.controller.js:136).
      if (config.containsKey('platform')) {
        root['platform'] = config['platform'];
      } else {
        root.remove('platform');
      }
      _chart = null;
      chart.destroy();
      _create(notify: true);
      return;
    }
    final mode = widget.updateMode;
    if (mode == null) {
      chart.update();
    } else {
      chart.update(mode);
    }
  }

  /// `animator.mute` or `animator.unmute` for the new `TickerMode` of the
  /// host (Chart.js ADR 0016, decision 7).
  void _onTickerModeChanged(bool enabled) {
    _tickerEnabled = enabled;
    final chart = _chart;
    if (chart == null) return;
    if (enabled) {
      animator.unmute(chart);
    } else {
      animator.mute(chart);
    }
  }

  @override
  Widget build(BuildContext context) {
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    return ChartHost(
      canvas: _canvas,
      onTickerModeChanged: _onTickerModeChanged,
      onFirstLayout: _onFirstLayout,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final chart = _chart;
    properties
      ..add(IntProperty('id', chart?.id.toInt(), ifNull: 'no chart'))
      ..add(
        FlagProperty(
          'attached',
          value: chart?.attached,
          ifTrue: 'attached',
          ifFalse: 'detached',
        ),
      )
      ..add(
        DiagnosticsProperty<Size>(
          'size',
          chart == null ? null : Size(chart.width, chart.height),
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'muted',
          value: chart != null && !_tickerEnabled,
          ifTrue: 'muted',
        ),
      );
  }
}
