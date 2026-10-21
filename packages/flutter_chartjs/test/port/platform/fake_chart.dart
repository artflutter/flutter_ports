// Original code, not ported from Chart.js: a chart fake for platform tests.
import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/helpers/helpers.dom.dart';
import 'package:flutter_chartjs/src/platform/index.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;

/// A chart with the platform calls of core.controller.js: the constructor
/// (:122-196), `_resize` (:258-300), `bindEvents` (:964-1049),
/// `unbindEvents` (:1054) and `destroy` (:937). `update` and `render` clear
/// the canvas and fill it, and count the calls. The fake has no scales,
/// datasets, plugins or animations.
final class FakeChart implements types.Chart {
  /// `new Chart(item, {options})`.
  FakeChart(
    Object? item, {
    bool responsive = true,
    bool maintainAspectRatio = true,
    double? aspectRatio,
    double? devicePixelRatio,
    List<String> events = const [
      'mousemove',
      'mouseout',
      'click',
      'touchstart',
      'touchmove',
    ],
  }) : options = {
         'responsive': responsive,
         'maintainAspectRatio': maintainAspectRatio,
         'aspectRatio': aspectRatio,
         'devicePixelRatio': devicePixelRatio,
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
    if (responsive) {
      resize();
    } else {
      retinaScale(this, devicePixelRatio ?? platform.getDevicePixelRatio());
    }
    bindEvents();
    if (attached) {
      update();
    }
  }

  @override
  late final BasePlatform platform;

  @override
  HTMLCanvasElement? canvas;

  @override
  CanvasRenderingContext2D? ctx;

  @override
  Map<String, Object?>? platformProxies = {};

  @override
  double width = 0;

  @override
  double height = 0;

  @override
  double currentDevicePixelRatio = double.nan;

  @override
  final Map<String, Object?> options;

  double? _aspectRatio;

  /// `chart.attached`.
  bool attached = false;

  /// The events of `_eventHandler`.
  final List<types.ChartEvent> events = [];

  /// The sizes of the `resize` plugin hook.
  final List<({double width, double height})> resizes = [];

  /// The modes of the `update` calls.
  final List<String> updates = [];

  /// The calls of `attached` and `detached`.
  final List<String> attachCalls = [];

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

  /// core.controller.js:258 `resize(width, height)`.
  void resize([double? width, double? height]) => _resize(width, height);

  void _resize(double? w, double? h) {
    final maintain = options['maintainAspectRatio'] == true;
    final newSize = platform.getMaximumSize(
      canvas!,
      w,
      h,
      maintain ? aspectRatio : null,
    );
    final newRatio =
        (options['devicePixelRatio'] as double?) ??
        platform.getDevicePixelRatio();
    final mode = width != 0 ? 'resize' : 'attach';
    width = newSize.width;
    height = newSize.height;
    _aspectRatio = aspectRatio;
    if (!retinaScale(this, newRatio, true)) {
      return;
    }
    resizes.add(newSize);
    if (attached) {
      update(mode);
    }
  }

  /// `update(mode)`: renders the chart. The fake takes a mode string.
  @override
  void update([Object? mode = 'default']) {
    updates.add(mode! as String);
    final context = ctx!;
    final pixelRatio = currentDevicePixelRatio;
    context
      ..save()
      ..resetTransform()
      ..clearRect(0, 0, width * pixelRatio, height * pixelRatio)
      ..restore()
      ..fillStyle = '#ff0000'
      ..fillRect(0, 0, width, height);
  }

  /// core.controller.js:964 `bindEvents`.
  void bindEvents() {
    for (final type in options['events']! as List<String>) {
      void listener(types.ChartEvent e) => events.add(e);
      platform.addEventListener(this, type, listener);
      _listeners[type] = listener;
    }
    if (options['responsive'] == true) {
      _bindResponsiveEvents();
    } else {
      attached = true;
    }
  }

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
      attachCalls.add('attached');
      remove('attach', attachedFn);
      attached = true;
      resize();
      add('resize', listener);
      add('detach', detached);
    }

    detached = () {
      attachCalls.add('detached');
      attached = false;
      remove('resize', listener);
      _resize(0, 0);
      add('attach', attachedFn);
    };

    if (platform.isAttached(canvas)) {
      attachedFn();
    } else {
      detached();
    }
  }

  /// core.controller.js:1054 `unbindEvents`.
  void unbindEvents() {
    _listeners
      ..forEach((type, listener) {
        platform.removeEventListener(this, type, listener);
      })
      ..clear();
    _responsiveListeners?.forEach((type, listener) {
      platform.removeEventListener(this, type, listener);
    });
    _responsiveListeners = null;
  }

  /// core.controller.js:937 `destroy`.
  void destroy() {
    final context = ctx;
    if (canvas != null && context != null) {
      unbindEvents();
      platform.releaseContext(context);
      canvas = null;
      ctx = null;
    }
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
