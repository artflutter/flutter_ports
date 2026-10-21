// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The demo imports the ported files directly.
// ignore_for_file: implementation_imports

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs/src/helpers/helpers.canvas.dart'
    as helpers
    show isPointInArea;
import 'package:flutter_chartjs/src/helpers/index.dart'
    show DrawPointOptions, clearCanvas, retinaScale;
import 'package:flutter_chartjs/src/platform/chart_host.dart';
import 'package:flutter_chartjs/src/platform/index.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;

/// Draws one frame of a [DemoChart] on its context. The transform is the
/// one of `retinaScale`, so the units are logical pixels, and the canvas is
/// already clear.
typedef DemoDraw = void Function(DemoChart chart, CanvasRenderingContext2D ctx);

/// A small stand-in for the Chart.js `Chart` (`core.controller` comes in
/// phase 5): it makes the platform calls of `core.controller.js`, so that
/// the gallery runs the real phase 3 code.
///
/// - The constructor: `detectPlatform`, `acquireContext`, `resize()` and
///   `bindEvents()` (core.controller.js:122-196).
/// - `_resize`: `platform.getMaximumSize` and `retinaScale`
///   (core.controller.js:258-300).
/// - `bindEvents`: `platform.addEventListener` for each type of the
///   `events` option, and the `attach`, `detach` and `resize` listeners of a
///   responsive chart (core.controller.js:964-1049).
/// - [render] clears the canvas with `clearCanvas` and calls [drawFrame].
///   [draw], the method of `types.Chart` that the animator calls, renders.
/// - [destroy] removes the listeners and calls `releaseContext`.
///
/// It has no scales, datasets, boxes, plugins or animations. The members
/// of `types.Chart` for these parts give an empty result.
final class DemoChart implements types.Chart {
  /// `new Chart(item, {options})`: a responsive chart on [item].
  DemoChart(
    Object? item, {
    required DemoDraw draw,
    bool maintainAspectRatio = false,
    double aspectRatio = 2,
    List<String> events = const [],
    this.onEvent,
    this.onResize,
  }) : drawFrame = draw,
       options = {
         'responsive': true,
         'maintainAspectRatio': maintainAspectRatio,
         'aspectRatio': aspectRatio,
         'events': events,
       } {
    platform = detectPlatform(item)();
    final context = platform.acquireContext(item, aspectRatio);
    ctx = context;
    canvas = context?.canvas;
    width = canvas?.width.toDouble() ?? 0;
    height = canvas?.height.toDouble() ?? 0;
    _aspectRatio = this.aspectRatio;
    if (context == null) {
      return;
    }
    resize();
    _bindEvents();
    if (attached) {
      render();
    }
  }

  /// Draws a frame.
  DemoDraw drawFrame;

  /// Called with each event that the platform delivers.
  void Function(types.ChartEvent event)? onEvent;

  /// Called after each resize that changed the canvas.
  VoidCallback? onResize;

  @override
  late final BasePlatform platform;

  @override
  HTMLCanvasElement? canvas;

  @override
  CanvasRenderingContext2D? ctx;

  @override
  Map<String, Object?>? platformProxies = {};

  /// The configuration `{options}` of the chart.
  @override
  late final types.ChartConfiguration config = _DemoConfiguration(options);

  /// No stacks: the demo has no datasets.
  @override
  Map<String, Object?>? stacks;

  /// The demo has no animated updates.
  @override
  bool? get animationsDisabled => null;

  /// No data changes: the demo has no datasets.
  @override
  final List<List<Object?>> dataChanges = [];

  @override
  double width = 0;

  @override
  double height = 0;

  @override
  double currentDevicePixelRatio = double.nan;

  @override
  final Map<String, Object?> options;

  /// The chart area: the whole canvas, until a caller sets another area.
  @override
  ChartArea get chartArea => _chartArea ?? Box(0, 0, width, height);

  @override
  set chartArea(ChartArea value) => _chartArea = value;

  ChartArea? _chartArea;

  /// No layout boxes.
  @override
  List<types.LayoutItem> get boxes => const [];

  /// No scales.
  @override
  Map<String, types.Scale> get scales => const {};

  /// The data of a chart without datasets.
  @override
  final Map<String, Object?> data = {
    'labels': <Object?>[],
    'datasets': <Object?>[],
  };

  /// core.controller.js:845 `isPointInArea`, without the padding of the
  /// layout.
  @override
  bool isPointInArea(Point point) => helpers.isPointInArea(point, chartArea);

  /// No datasets.
  @override
  List<types.ChartMeta> getSortedVisibleDatasetMetas() => const [];

  /// No datasets: every index throws.
  @override
  types.ChartMeta getDatasetMeta(double datasetIndex) =>
      throw RangeError('The demo chart has no datasets.');

  /// No datasets.
  @override
  List<types.ChartMeta> getSortedDatasetMetas(bool filterVisible) => const [];

  /// core.controller.js:885 `getDataVisibility(index)`:
  /// `!this._hiddenIndices[index]`. The demo chart hides no index.
  @override
  bool getDataVisibility(double index) => true;

  /// No plugins: no plugin cancels the hook.
  @override
  bool notifyPlugins(String hook, [Map<String, Object?>? args]) => true;

  /// No plugins.
  @override
  bool isPluginEnabled(String pluginId) => false;

  @override
  Map<String, Object?> getContext() => {'chart': this, 'type': 'chart'};

  /// core.controller.js:863 `isDatasetVisible(datasetIndex)`. The demo
  /// chart has no datasets.
  @override
  bool isDatasetVisible(double datasetIndex) => false;

  /// core.controller.js:859 `getVisibleDatasetCount()`. The demo chart has
  /// no datasets.
  @override
  double getVisibleDatasetCount() => 0;

  /// core.controller.js:881 `toggleDataVisibility(index)`. The demo chart
  /// has no data.
  @override
  void toggleDataVisibility(double index) {}

  /// core.controller.js:475 `update(mode)`. core.controller.js:536: an
  /// update ends with a render. The demo chart has only the render.
  @override
  void update([Object? mode]) => render();

  /// index.d.ts:543 `legend`. The demo chart has no legend.
  @override
  types.LegendElement? get legend => null;

  double? _aspectRatio;

  /// `chart.attached`: the canvas is shown by a laid-out host.
  bool attached = false;

  /// The count of [render] calls.
  int renders = 0;

  /// The time of the last [drawFrame], in microseconds.
  int lastDrawMicros = 0;

  final Map<String, Function> _listeners = {};
  Map<String, Function>? _responsiveListeners;

  /// core.controller.js:198 `get aspectRatio`.
  double? get aspectRatio {
    final option = options['aspectRatio'] as double?;
    if (option != null) {
      return option;
    }
    if (options['maintainAspectRatio'] == true &&
        _aspectRatio != null &&
        _aspectRatio != 0) {
      return _aspectRatio;
    }
    return height != 0 ? width / height : null;
  }

  /// Whether the chart keeps [aspectRatio] (the `maintainAspectRatio`
  /// option). The next resize reads it.
  bool get maintainAspectRatio => options['maintainAspectRatio'] == true;

  set maintainAspectRatio(bool value) {
    options['maintainAspectRatio'] = value;
  }

  /// core.controller.js:258 `resize(width, height)`.
  void resize([double? width, double? height]) {
    final canvas = this.canvas;
    if (canvas == null) {
      return;
    }
    final newSize = platform.getMaximumSize(
      canvas,
      width,
      height,
      maintainAspectRatio ? aspectRatio : null,
    );
    final newRatio = platform.getDevicePixelRatio();
    this
      ..width = newSize.width
      ..height = newSize.height;
    _aspectRatio = aspectRatio;
    if (!retinaScale(this, newRatio, true)) {
      return;
    }
    onResize?.call();
    if (attached) {
      render();
    }
  }

  /// `render()`: clears the canvas (`clearCanvas`, as
  /// core.controller.js:765 does) and draws a frame.
  void render() {
    final context = ctx;
    if (context == null || !attached) {
      return;
    }
    final stopwatch = Stopwatch()..start();
    clearCanvas(canvas, context);
    context.save();
    drawFrame(this, context);
    context.restore();
    lastDrawMicros = stopwatch.elapsedMicroseconds;
    renders++;
  }

  /// core.controller.js:964 `bindEvents`.
  void _bindEvents() {
    for (final type in options['events']! as List<String>) {
      void listener(types.ChartEvent e) => onEvent?.call(e);
      platform.addEventListener(this, type, listener);
      _listeners[type] = listener;
    }
    _bindResponsiveEvents();
  }

  /// core.controller.js:1000 `bindResponsiveEvents`.
  void _bindResponsiveEvents() {
    final listeners = _responsiveListeners ??= {};
    void add(String type, Function listener) {
      platform.addEventListener(this, type, listener);
      listeners[type] = listener;
    }

    void remove(String type, Function listener) {
      if (listeners.containsKey(type)) {
        platform.removeEventListener(this, type, listener);
        listeners.remove(type);
      }
    }

    void listener([double? width, double? height]) {
      if (canvas != null) {
        resize(width, height);
      }
    }

    late void Function() detached;
    void attachedFn() {
      remove('attach', attachedFn);
      attached = true;
      resize();
      add('resize', listener);
      add('detach', detached);
    }

    detached = () {
      attached = false;
      remove('resize', listener);
      add('attach', attachedFn);
    };

    if (platform.isAttached(canvas)) {
      attachedFn();
    } else {
      detached();
    }
  }

  /// core.controller.js:697 `draw()`: the animator calls it in each frame of
  /// an animation (core.animator.js:89). The demo has no layers, so it
  /// renders.
  @override
  void draw() => render();

  /// core.controller.js:937 `destroy`.
  void destroy() {
    final context = ctx;
    if (canvas == null || context == null) {
      return;
    }
    _listeners
      ..forEach((type, listener) {
        platform.removeEventListener(this, type, listener);
      })
      ..clear();
    _responsiveListeners?.forEach((type, listener) {
      platform.removeEventListener(this, type, listener);
    });
    _responsiveListeners = null;
    platform.releaseContext(context);
    canvas = null;
    ctx = null;
  }
}

/// The `config` of a [DemoChart]: only its `options`.
final class _DemoConfiguration implements types.ChartConfiguration {
  _DemoConfiguration(this.options);

  @override
  final Map<String, Object?> options;
}

/// A [ChartHost] that shows a [DemoChart].
///
/// The widget owns a `UiCanvasElement`. The chart starts after the first
/// frame, once the host shows the canvas, so that `detectPlatform` gives the
/// `FlutterPlatform` (a canvas without a host gets the `BasicPlatform`).
/// Each rebuild of the widget draws the chart again.
///
/// With a [height], the host has that height and the chart fills its box.
/// Without one, the chart keeps [aspectRatio] (`maintainAspectRatio`).
class DemoCanvas extends StatefulWidget {
  /// Creates a host for a chart that [draw] draws.
  const DemoCanvas({
    required this.draw,
    this.height,
    this.aspectRatio = 2,
    this.events = const [],
    this.onEvent,
    this.onChart,
    this.onResize,
    this.onTickerModeChanged,
    super.key,
  });

  /// Draws a frame of the chart.
  final DemoDraw draw;

  /// The height of the host, or `null` to keep [aspectRatio].
  final double? height;

  /// The `aspectRatio` option.
  final double aspectRatio;

  /// The `events` option: the DOM event types that the chart listens to.
  final List<String> events;

  /// Called with each event that the platform delivers.
  final void Function(types.ChartEvent event)? onEvent;

  /// Called once the chart exists.
  final ValueChanged<DemoChart>? onChart;

  /// Called after each resize of the canvas.
  final VoidCallback? onResize;

  /// The `onTickerModeChanged` callback of the host.
  final ValueChanged<bool>? onTickerModeChanged;

  @override
  State<DemoCanvas> createState() => DemoCanvasState();
}

/// The state of a [DemoCanvas]: it owns the canvas and the chart.
class DemoCanvasState extends State<DemoCanvas> {
  final UiCanvasElement _canvas = UiCanvasElement();
  DemoChart? _chart;

  /// The chart, once it exists.
  DemoChart? get chart => _chart;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final chart = _chart = DemoChart(
        _canvas,
        draw: (chart, ctx) => widget.draw(chart, ctx),
        maintainAspectRatio: widget.height == null,
        aspectRatio: widget.aspectRatio,
        events: widget.events,
        onEvent: (event) => widget.onEvent?.call(event),
        onResize: () => widget.onResize?.call(),
      );
      widget.onChart?.call(chart);
    }, debugLabel: 'DemoCanvas.start');
  }

  @override
  void didUpdateWidget(DemoCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    final chart = _chart;
    if (chart == null) {
      return;
    }
    // The next resize reads the option. The host reports the new
    // constraints after its layout.
    chart
      ..maintainAspectRatio = widget.height == null
      ..render();
  }

  @override
  void dispose() {
    _chart?.destroy();
    _canvas.getContext2d().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final host = ChartHost(
      canvas: _canvas,
      onTickerModeChanged: widget.onTickerModeChanged,
    );
    // The host keeps its place in the tree for both modes: a new host for
    // the same canvas would report the attach before the old host reports
    // its detach after the frame, which leaves the chart detached.
    return SizedBox(height: widget.height, child: host);
  }
}

/// The options of `drawPoint` and `drawPointLegend`: the resolved options
/// of a point element.
final class PointOptions implements DrawPointOptions {
  /// Creates the options.
  const PointOptions({
    required this.pointStyle,
    required this.radius,
    this.borderWidth = 1,
    this.rotation,
  });

  @override
  final Object? pointStyle;

  @override
  final double radius;

  @override
  final double borderWidth;

  @override
  final double? rotation;
}

/// The options of `renderText` (`RenderTextOpts`, index.d.ts:1434). Dart
/// `null` is an absent key.
final class TextOpts implements types.RenderTextOpts {
  /// Creates the options.
  const TextOpts({
    this.color,
    this.decorationWidth,
    this.maxWidth,
    this.rotation,
    this.strikethrough,
    this.strokeColor,
    this.strokeWidth,
    this.textAlign,
    this.textBaseline,
    this.translation,
    this.underline,
    this.backdrop,
  });

  @override
  final Object? color;

  @override
  final double? decorationWidth;

  @override
  final double? maxWidth;

  @override
  final double? rotation;

  @override
  final bool? strikethrough;

  @override
  final Object? strokeColor;

  @override
  final double? strokeWidth;

  @override
  final String? textAlign;

  @override
  final String? textBaseline;

  @override
  final (double, double)? translation;

  @override
  final bool? underline;

  @override
  final types.BackdropOptions? backdrop;
}

/// The label backdrop of [TextOpts.backdrop].
final class Backdrop implements types.BackdropOptions {
  /// Creates a backdrop rectangle of [color].
  const Backdrop(this.left, this.top, this.width, this.height, this.color);

  @override
  final double left;

  @override
  final double top;

  @override
  final double width;

  @override
  final double height;

  @override
  final Object? color;
}

/// A box `{left, top, right, bottom}`, the `TRBL` of `clipArea`.
final class Box implements ChartArea {
  /// Creates the box.
  const Box(this.left, this.top, this.right, this.bottom);

  @override
  final double left;

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;

  @override
  double get width => right - left;

  @override
  double get height => bottom - top;
}

/// The corner radii of a [RoundedBox].
final class Corners implements TRBLCorners {
  /// Creates the radii.
  const Corners({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  @override
  final double topLeft;

  @override
  final double topRight;

  @override
  final double bottomLeft;

  @override
  final double bottomRight;
}

/// The rectangle of `addRoundedRectPath`: a `RoundedRect` whose radius is a
/// [Corners].
final class RoundedBox implements RoundedRect {
  /// Creates the rectangle.
  const RoundedBox(this.x, this.y, this.w, this.h, this.radius);

  @override
  final double x;

  @override
  final double y;

  @override
  final double w;

  @override
  final double h;

  @override
  final Corners radius;
}

/// A point `{x, y}` with the control points that `helpers.curve` writes.
final class CurvePoint implements SplinePoint {
  /// Creates the point.
  CurvePoint(this.x, this.y);

  @override
  final double x;

  @override
  final double y;

  @override
  bool? get skip => null;

  @override
  double cp1x = double.nan;

  @override
  double cp1y = double.nan;

  @override
  double cp2x = double.nan;

  @override
  double cp2y = double.nan;
}
