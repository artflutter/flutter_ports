// Original code, not ported from Chart.js: the public chart widget.

/// The public chart widget [ChartView] (Chart.js ADR 0049).
///
/// The widget owns one canvas for the life of its state, shows it in the
/// internal chart host and starts its chart in the first layout of the host
/// (Chart.js ADR 0049, section 2). It gives the chart a root Map that it
/// owns, and it applies a new config in one post-frame callback (section
/// 4). The theme of Chart.js ADR 0050 builds on the root Map and on that
/// callback: the widget writes the compiled theme under `$theme` of the
/// root Map, and it switches the theme in the same callback
/// (`chart_theme_switch.dart`) with its inline plugin `$chartView`
/// (`chart_view_plugin.dart`). The keyboard of Chart.js ADR 0051
/// (`chart_keyboard.dart`) builds on them too: one `Focus` around the host
/// moves a virtual mouse over the legend items and the data elements, and
/// the widget plugin draws the focus ring.
///
/// The widget registers no component (Chart.js ADR 0048, section 3): no
/// file of `lib/src/widgets/` imports a controller, a scale, an element, a
/// plugin or an index of them. It never writes `defaults` or `overrides`,
/// also not for the theme (Chart.js ADR 0050).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.animator.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart'
    show themeConfigKey;
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_chartjs_port/src/theme/chart_theme.dart';
import 'package:flutter_chartjs_port/src/theme/theme_data.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/widgets/chart_keyboard.dart';
import 'package:flutter_chartjs_port/src/widgets/chart_theme_switch.dart';
import 'package:flutter_chartjs_port/src/widgets/chart_view_plugin.dart';

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
///
/// Theme: [theme], or the [ChartTheme] above, themes the chart (Chart.js
/// ADR 0050). Chart.js options beat each key of the theme. A new theme
/// switches the chart after the frame: the element colors animate for
/// 200 ms, and the scales, the legend, the title and the tooltip switch at
/// once. A switch keeps the chart, its datasets, its hidden datasets and
/// the imperative edits of `chart.options`, except an edit inside
/// `chart.options.scales`. The widget owns the config key `$theme` and the
/// inline plugin id `$chartView`.
///
/// Keyboard: the chart is one focus stop (Chart.js ADR 0051). With the
/// focus, the arrow keys move a virtual mouse over the legend items and the
/// data elements: Right and Left move in a group, Down and Up move to the
/// next or the previous group (the legend, then each visible dataset), Home
/// and End move to the ends of the group. Enter and Space click at the
/// target, and Escape clears the hover. Each move is a `mousemove` at the
/// target: the hover mode, the tooltip, `onHover`, `onClick`, the legend
/// callbacks and `options.events` give the result of a mouse at that point.
/// An arrow at an end, and a key with a modifier, go on to the ancestors:
/// the focus moves on, or a web page scrolls. With `options.events` that
/// lists `keydown`, `keypress` or `keyup`, the chart also gets these
/// events, with NaN coordinates. A focus ring shows the focus in the
/// traditional highlight mode, in the color `options.color`.
class ChartView extends StatefulWidget {
  /// Creates a widget that shows the chart of [config].
  const ChartView({
    required this.config,
    this.updateMode,
    this.onChartCreated,
    this.theme,
    this.focusNode,
    this.autofocus = false,
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
  /// the next new `options` object. A theme switch keeps it, except an edit
  /// inside `chart.options.scales`.
  ///
  /// The key `$theme` belongs to the widget: in debug mode, a config with
  /// it fails an assert. A `plugins` value is a List.
  final Map<String, Object?> config;

  /// The mode of the `chart.update` call for a new [config]. Null is the
  /// default mode. When the same frame also switches the theme, the one
  /// update takes the mode of the theme switch.
  final String? updateMode;

  /// Called after the frame in which the widget starts a chart, and again
  /// after a new `platform` replaces the chart.
  final ValueChanged<Chart>? onChartCreated;

  /// The theme of this chart. Null reads [ChartTheme.maybeOf].
  /// `const ChartThemeData()` turns theming off for this chart.
  final ChartThemeData? theme;

  /// The focus node of the chart. Null: the widget owns one. The chart is one
  /// focus stop: the arrow keys move a virtual mouse over the legend items and
  /// the data elements, Enter and Space click there, Escape clears the hover.
  /// Wrap the chart in ExcludeFocus to remove the stop.
  final FocusNode? focusNode;

  /// Whether the chart takes the focus at its first build.
  final bool autofocus;

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
      ..add(
        DiagnosticsProperty<ChartThemeData>('theme', theme, defaultValue: null),
      )
      ..add(StringProperty('updateMode', updateMode, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<Chart>>.has(
          'onChartCreated',
          onChartCreated,
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
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

  /// The effective theme of the last build: [ChartView.theme], else the
  /// theme of the [ChartTheme] above (Chart.js ADR 0050, step 1).
  ChartThemeData? _theme;

  /// The theme state of the chart (Chart.js ADR 0050, "Runtime switch").
  final ChartThemeSwitch _themeSwitch = ChartThemeSwitch();

  /// The keyboard of the chart (Chart.js ADR 0051).
  late final ChartKeyboard _keyboard = ChartKeyboard(
    canvas: _canvas,
    chart: () => _chart,
  );

  /// The inline plugin of the widget, last in the root `plugins`.
  late final AnyObject _viewPlugin = createChartViewPlugin(
    _themeSwitch,
    _keyboard,
  );

  /// The reduced-motion preference (Chart.js ADR 0049, section 7). False
  /// until the flag of that section lands; then it reads the preference of
  /// the last build, and a theme switch under it updates with
  /// `'themeFrame'` (Chart.js ADR 0050, step 5).
  bool get _reducedMotion => false;

  @override
  void didUpdateWidget(ChartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.config, widget.config)) _scheduleUpdate();
  }

  @override
  void dispose() {
    _keyboard.dispose();
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
    _themeSwitch.recordUserScales(config['options']);
    final root = _root = Map<String, Object?>.of(config);
    root['plugins'] = _rootPlugins(jsGet(config, 'plugins'));
    _themeSwitch.start(root, _theme);
    _create(notify: notify);
  }

  /// The debug checks of the app config [config]: no value under `$theme`
  /// (row `theme-H0`, Chart.js ADR 0050, step 2) and a `plugins` value that
  /// is a List, so that the widget plugin can join it.
  static void _debugCheckConfig(Map<String, Object?> config) {
    assert(
      !config.containsKey(themeConfigKey),
      'The key $themeConfigKey of a ChartView config belongs to the widget. '
      'Give the theme as ChartView.theme or with a ChartTheme above '
      '(Chart.js ADR 0050).',
    );
    assert(
      config['plugins'] == null || config['plugins'] is List,
      'The plugins of a ChartView config are a List of plugin Maps, not '
      '${config['plugins'].runtimeType}.',
    );
  }

  /// `new Chart(canvas, root)`. An exception goes to
  /// `FlutterError.reportError`, and a post-frame callback destroys the
  /// partial chart that `Chart.instances` keeps (core.controller.js:177),
  /// so that the next new config can start the chart.
  void _create({required bool notify}) {
    // A new chart has no keyboard target (Chart.js ADR 0051, section 2).
    _keyboard.reset();
    final Chart chart;
    try {
      _debugCheckConfig(_applied);
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
  /// the inline plugins of the app (a List, else none) and the inline plugin
  /// of the widget (Chart.js ADRs 0050 and 0051).
  List<Object?> _rootPlugins(Object? app) => [
    if (app is List) ...app,
    _viewPlugin,
  ];

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
  /// config that are new objects go to the chart, then the theme switch of
  /// Chart.js ADR 0050 (steps 1 to 4), then one `chart.update`: with the
  /// mode of the theme switch when the theme changed, else with
  /// [ChartView.updateMode]. It runs after the frame, so every hook of the
  /// update, also the replay of the last event (core.controller.js:529-532),
  /// runs outside the build.
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
    final configChanged = !identical(config, applied);
    if (!configChanged && _theme == _themeSwitch.applied) return;
    final root = _root!;
    if (configChanged) _applyConfig(chart, root, config, applied);
    // Chart.js ADR 0050, steps 1 to 4, also before a new chart of a new
    // platform: the root, the user scales and the palette keys then have
    // the new theme.
    final themeMode = _themeSwitch.apply(
      chart,
      root,
      _theme,
      reducedMotion: _reducedMotion,
    );
    if (configChanged && !identical(config['platform'], applied['platform'])) {
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
    if (themeMode != null) {
      // Step 5: the mode of the theme switch wins over updateMode.
      chart.update(themeMode);
      return;
    }
    if (!configChanged) return;
    final mode = widget.updateMode;
    if (mode == null) {
      chart.update();
    } else {
      chart.update(mode);
    }
  }

  /// Steps 1 to 4 of the update of Chart.js ADR 0049, section 4: the values
  /// of [config] that are not the values of [applied] go to [chart] and to
  /// [root]. A new options object records its user `scales` first (Chart.js
  /// ADR 0050, step 3).
  void _applyConfig(
    Chart chart,
    AnyObject root,
    Map<String, Object?> config,
    Map<String, Object?> applied,
  ) {
    _debugCheckConfig(config);
    _applied = config;
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
      _themeSwitch.recordUserScales(options);
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
    final theme = _theme = widget.theme ?? ChartTheme.maybeOf(context);
    // A new theme after the start switches in the update callback (Chart.js
    // ADR 0050, step 1). The start reads the theme of the last build.
    if (_laidOut && theme != _themeSwitch.applied) _scheduleUpdate();
    // Chart.js ADR 0051, section 1: one focus stop with no Shortcuts and no
    // Actions, so that a key that the chart does not use goes on to the
    // ancestors.
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _keyboard.onKeyEvent,
      onFocusChange: _keyboard.onFocusChange,
      child: ChartHost(
        canvas: _canvas,
        onTickerModeChanged: _onTickerModeChanged,
        onFirstLayout: _onFirstLayout,
      ),
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
