// Original code, not ported from Chart.js: the DOM stand-in of the harness.

/// The DOM stand-in of the chart harness (Chart.js ADR 0022, sections 3, 7
/// and 8). The specs and `utils.dart` read and write the DOM through it.
///
/// - [document] and [window] stand for the globals of the specs. A node is a
///   [HarnessElement] (a `div`, and `document.body`) or a `UiCanvasElement`.
/// - The harness body: the first DOM write or forced layout in a
///   `testWidgets` body makes `document.body` the root widget of the test.
///   Each [HarnessElement] is one port-only render box with a subset of CSS.
///   A canvas child is a `ChartHost`.
/// - A DOM write changes the element tree at once. It then rebuilds the
///   body. During build, layout or paint, the rebuild waits for a
///   post-frame callback.
/// - The mutation checkpoint: an append or a removal schedules one
///   microtask. It does the forced build and layout of the body, then calls
///   `flushCanvasMutations`. Thus a detach and an attach reach the chart in
///   the task of the write, as the `MutationObserver` records do.
/// - [setTimeout] makes a harness task on `clock.now()`. [pumpFrames] and
///   [waitForDone] pump frames of [frameInterval] and run the due tasks
///   between the pumps. [pumpFrame] runs the due tasks and pumps one frame
///   (the fixture runner, Chart.js ADR 0029).
/// - [afterEachChart] registers a function that the unmount of the body
///   calls: `releaseCharts` (`harness-release-at-unmount`).
///
/// This library is not a pure layer. A test that imports it needs
/// `@TestOn('vm')`.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:chartjs_test_utils/src/matchers.dart' show computedCanvasSize;
import 'package:clock/clock.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
// The harness shows the canvas elements of the canvas layer in chart hosts.
// flutter_chartjs_port does not export lib/src.
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
// The canvas element and its style of the canvas layer.
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
// The chart host and the mutation checkpoint of Chart.js ADR 0022.
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_test/flutter_test.dart';

// The globals.

/// `window.document` of the specs.
final HarnessDocument document = HarnessDocument._();

/// `window` of the specs.
final HarnessWindow window = HarnessWindow._();

/// `window.document`: the body, `createElement` and `getElementById`.
final class HarnessDocument {
  HarnessDocument._();

  /// `document.body`. The harness body shows it (see [HarnessElement]).
  final HarnessElement body = HarnessElement._(true);

  /// `document.createElement(tagName)`: a [HarnessElement] for `'div'`, a
  /// `UiCanvasElement` with a standby host for `'canvas'`.
  ///
  /// The standby host is a `RenderChartHost` that the harness creates and
  /// never attaches. Thus a chart on the canvas gets `FlutterPlatform` and
  /// starts detached, as upstream for a canvas outside the document. A host
  /// of the body that shows the canvas replaces it as the parent node. The
  /// harness disposes each standby host at the end of the test.
  ///
  /// A spec gives the type as a type argument:
  /// `final canvas = document.createElement<HTMLCanvasElement>('canvas');`.
  /// The declared type of a variable also gives it, but the lint
  /// `omit_local_variable_types` flags that form. Throws an [ArgumentError]
  /// for another tag name, or when the node is not a [T].
  T createElement<T extends Object>(String tagName) {
    final node = switch (tagName.toLowerCase()) {
      'div' => HarnessElement._(),
      'canvas' => _createCanvas(),
      _ => throw ArgumentError.value(
        tagName,
        'tagName',
        'The harness has only div and canvas elements',
      ),
    };
    if (node is! T) {
      throw ArgumentError.value(tagName, 'tagName', 'The node is not a $T');
    }
    return node;
  }

  UiCanvasElement _createCanvas() {
    _harness.begin();
    final canvas = UiCanvasElement();
    final standby = RenderChartHost(
      canvas: canvas,
      devicePixelRatio: _view.devicePixelRatio,
    );
    _harness.standbyHosts[canvas] = standby;
    _canvasOfStyle[canvas.style] = canvas;
    return canvas;
  }

  /// `document.getElementById(id)`: the first node of the tree of [body],
  /// in tree order, whose `id` attribute is [id], or `null`. Throws an
  /// [ArgumentError] when the node is not a [T].
  T? getElementById<T extends Object>(String id) {
    final node = _findById(body, id);
    if (node == null) return null;
    if (node is! T) {
      throw ArgumentError.value(id, 'id', 'The node is not a $T');
    }
    return node;
  }

  static Object? _findById(HarnessElement element, String id) {
    for (final child in element._children) {
      switch (child) {
        case final HarnessElement childElement:
          if (childElement._attributes['id'] == id) return childElement;
          final found = _findById(childElement, id);
          if (found != null) return found;
        case final HTMLCanvasElement canvas:
          if (canvas.getAttribute('id') == id) return canvas;
      }
    }
    return null;
  }
}

/// `window`: the device pixel ratio.
final class HarnessWindow {
  HarnessWindow._();

  /// `window.devicePixelRatio`: the device pixel ratio of the implicit test
  /// view.
  ///
  /// A write is a real change of the ratio of the test view. It keeps the
  /// logical size of the view, as a write of the JS value does not change
  /// the CSS layout. It also sets the ratio of the standby hosts. An
  /// attached host reports the new ratio to its chart, and the chart calls
  /// `resize()` (`platform.flutter.dart`). Upstream, the write only shadows
  /// the property and fires no event: a chart sees the new ratio at the next
  /// window `resize` event (platform.dom.js:161-189). The specs write the
  /// ratio only before a chart exists or after its release. The `setUp` of
  /// `flutter_test_config.dart` sets the ratio back to 1 before each test.
  double get devicePixelRatio => _view.devicePixelRatio;

  set devicePixelRatio(double value) {
    final view = _view;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    view
      ..devicePixelRatio = value
      ..physicalSize = logicalSize * value;
    for (final host in _harness.standbyHosts.values) {
      host.devicePixelRatio = value;
    }
  }
}

TestFlutterView get _view => _harness.binding.platformDispatcher.implicitView!;

// The elements.

/// The parent element of each canvas in the harness tree.
final Expando<HarnessElement> _canvasParents = Expando('canvas parent');

/// The canvas of each canvas style that the harness knows.
final Expando<UiCanvasElement> _canvasOfStyle = Expando('style canvas');

/// A `div` element of the harness, or `document.body`.
///
/// The harness lays out each element with this CSS subset (Chart.js ADR
/// 0022, section 3). All lengths are in logical pixels:
/// - `width`, `height` (px): the size of the content box.
/// - No `width`: the content width of the parent. With `position: absolute`
///   or the class `chartjs-wrapper`: the width of the content
///   (shrink-to-fit).
/// - No `height`: the height of the content. The content of a canvas child
///   is the display size of the canvas, 0 x 0 for a canvas with its own
///   `display: none`.
/// - `max-width`, `max-height` (px): a cap of the content box.
/// - `padding` (one px value): the padding lies outside the content box
///   (`box-sizing: content-box`).
/// - `display: none`: the element and its subtree get the size 0. The
///   hosts stay mounted.
/// - `direction: rtl`: a `Directionality` with `TextDirection.rtl` for the
///   subtree.
/// - Other properties and attributes are kept, with no effect on the
///   layout.
///
/// The class `chartjs-wrapper` has the effect of `injectWrapperCSS`
/// (`src/index.js:37-48`): no padding and `position: absolute`, unless the
/// inline style sets them. An element gives a canvas child loose
/// constraints whose max size is its content box. Thus the container size
/// of the chart is the content box, as `getMaximumSize` reads it upstream.
/// An element child gets the content width of its parent as its max width:
/// an element that is wider than its parent's content box is cut to it,
/// where CSS lets it overflow.
///
/// `document.body` has the size of the test view (800 x 600 logical
/// pixels). It places each child at its top left corner, with the view
/// width as its content width.
final class HarnessElement {
  HarnessElement._([this._isBody = false]) {
    style = _HarnessStyle(this);
  }

  final bool _isBody;

  /// `element.style`: the inline style.
  late final CSSStyleDeclaration style;

  final Map<String, String> _attributes = {};

  final List<Object> _children = [];

  HarnessElement? _parent;

  /// The render box that shows the element, while one does.
  _RenderHarnessElement? _box;

  /// A count of the writes that change the layout of the element without a
  /// change of its own style: the style writes of a canvas child.
  int _revision = 0;

  UiCssStyleDeclaration get _declarations => (style as _HarnessStyle)._inner;

  /// `element.parentNode`.
  HarnessElement? get parentNode => _parent;

  /// `element.childNodes`: the child nodes in tree order, as an
  /// unmodifiable list.
  List<Object> get childNodes => List.unmodifiable(_children);

  /// `element.clientWidth`: the width of the padding box, rounded to an
  /// integer. 0 when no harness body shows the element, or in a
  /// `display: none` subtree. The read does the forced layout of the body
  /// first, as a DOM read does, except during build, layout or paint.
  int get clientWidth => _clientSize()?.width.round() ?? 0;

  /// `element.clientHeight`: the height of the padding box, rounded to an
  /// integer. See [clientWidth].
  int get clientHeight => _clientSize()?.height.round() ?? 0;

  Size? _clientSize() {
    if (_harness.mounted && _harness.canForceLayout) _forcedLayout();
    final box = _box;
    if (box == null || !box.attached || !box.hasSize) return null;
    return box.size;
  }

  /// `element.appendChild(node)`: [node] is a [HarnessElement] or a
  /// `UiCanvasElement`. A node with a parent leaves it first. Throws a
  /// [StateError] (the DOM `HierarchyRequestError`) when [node] contains
  /// this element or is `document.body`.
  void appendChild(Object node) {
    _checkNode(node);
    if (node is HarnessElement && (node._isBody || node.contains(this))) {
      throw StateError(
        'HierarchyRequestError: The new child element contains the parent.',
      );
    }
    _parentOf(node)?._detach(node);
    _children.add(node);
    _setParent(node, this);
    if (node is UiCanvasElement) _canvasOfStyle[node.style] = node;
    _harness.write(mutation: true);
  }

  /// `element.removeChild(node)`. Throws a [StateError] (the DOM
  /// `NotFoundError`) when [node] is not a child of this element.
  void removeChild(Object node) {
    _checkNode(node);
    if (!identical(_parentOf(node), this)) {
      throw StateError(
        'NotFoundError: The node to be removed is not a child of this node.',
      );
    }
    _detach(node);
    _harness.write(mutation: true);
  }

  /// `element.contains(node)`: whether [node] is this element or one of its
  /// descendants.
  bool contains(Object node) {
    for (
      Object? current = node;
      current != null;
      current = _parentOf(current)
    ) {
      if (identical(current, this)) return true;
    }
    return false;
  }

  /// `element.remove()`: removes the element from its parent, if it has
  /// one.
  void remove() => _parent?.removeChild(this);

  /// `element.setAttribute(name, value)`. `style` replaces the inline style
  /// with the declarations of [value]. Names are ASCII case-insensitive.
  void setAttribute(String name, String value) {
    final key = name.toLowerCase();
    if (key == 'style') {
      _declarations.styleAttribute = value;
    } else {
      _attributes[key] = value;
    }
    _harness.write();
  }

  /// `element.getAttribute(name)`: the value, or `null` when the element
  /// does not have the attribute.
  String? getAttribute(String name) {
    final key = name.toLowerCase();
    return key == 'style' ? _declarations.styleAttribute : _attributes[key];
  }

  /// `element.removeAttribute(name)`.
  void removeAttribute(String name) {
    final key = name.toLowerCase();
    if (key == 'style') {
      _declarations.styleAttribute = null;
    } else {
      _attributes.remove(key);
    }
    _harness.write();
  }

  void _detach(Object node) {
    _children.remove(node);
    _setParent(node, null);
  }

  static void _checkNode(Object node) {
    if (node is! HarnessElement && node is! UiCanvasElement) {
      throw ArgumentError.value(node, 'node', 'Not a node of the harness');
    }
  }

  static HarnessElement? _parentOf(Object node) => switch (node) {
    final HarnessElement element => element._parent,
    final UiCanvasElement canvas => _canvasParents[canvas],
    _ => null,
  };

  static void _setParent(Object node, HarnessElement? parent) {
    switch (node) {
      case final HarnessElement element:
        element._parent = parent;
      case final UiCanvasElement canvas:
        _canvasParents[canvas] = parent;
    }
  }

  @override
  String toString() => _isBody ? 'HarnessElement(body)' : 'HarnessElement(div)';
}

/// The inline style of a [HarnessElement]: a write rebuilds the harness
/// body.
final class _HarnessStyle implements CSSStyleDeclaration {
  _HarnessStyle(this._element);

  final HarnessElement _element;

  final UiCssStyleDeclaration _inner = UiCssStyleDeclaration();

  @override
  String getPropertyValue(String property) => _inner.getPropertyValue(property);

  @override
  String getPropertyPriority(String property) =>
      _inner.getPropertyPriority(property);

  @override
  void setProperty(String property, String? value, [String? priority]) {
    _inner.setProperty(property, value, priority);
    _harness.write();
  }

  String get cssText => _inner.cssText;

  set cssText(String value) {
    _inner.cssText = value;
    _harness.write();
  }

  @override
  String toString() => 'CSSStyleDeclaration(${_inner.cssText}) of $_element';
}

/// The DOM parent of a canvas, and `remove()`.
extension CanvasParentElement on HTMLCanvasElement {
  /// `canvas.parentElement`: the [HarnessElement] that contains the canvas.
  ///
  /// The specs write `chart.canvas.parentNode`. In the port, the
  /// `parentNode` of a canvas is its chart host. Thus a spec port reads
  /// `chart.canvas!.parentElement` (Chart.js ADR 0022, section 2).
  HarnessElement? get parentElement => _canvasParents[this];

  /// `canvas.remove()`: removes the canvas from its parent element, if it
  /// has one.
  void remove() => parentElement?.removeChild(this);
}

/// The style properties that the specs read and write, with the upstream
/// text: `wrapper.style.width = '455px'`.
///
/// A write is a `setProperty` call. An empty value removes the property. A
/// write of the style of a canvas in the harness tree also lays out its
/// parent element again.
extension CssProperties on CSSStyleDeclaration {
  /// `style.width`.
  String get width => getPropertyValue('width');
  set width(String value) => _write('width', value);

  /// `style.height`.
  String get height => getPropertyValue('height');
  set height(String value) => _write('height', value);

  /// `style.maxWidth`.
  String get maxWidth => getPropertyValue('max-width');
  set maxWidth(String value) => _write('max-width', value);

  /// `style.maxHeight`.
  String get maxHeight => getPropertyValue('max-height');
  set maxHeight(String value) => _write('max-height', value);

  /// `style.padding`.
  String get padding => getPropertyValue('padding');
  set padding(String value) => _write('padding', value);

  /// `style.display`.
  String get display => getPropertyValue('display');
  set display(String value) => _write('display', value);

  /// `style.position`.
  String get position => getPropertyValue('position');
  set position(String value) => _write('position', value);

  /// `style.direction`.
  String get direction => getPropertyValue('direction');
  set direction(String value) => _write('direction', value);

  /// `style.cssText`: the declarations as text. A write replaces them.
  String get cssText => switch (this) {
    final _HarnessStyle style => style.cssText,
    final UiCssStyleDeclaration style => style.cssText,
    _ => throw UnsupportedError('cssText of $runtimeType'),
  };

  set cssText(String value) {
    switch (this) {
      case final _HarnessStyle style:
        style.cssText = value;
      case final UiCssStyleDeclaration style:
        style.cssText = value;
        _canvasStyleWritten(style);
      default:
        throw UnsupportedError('cssText of $runtimeType');
    }
  }

  void _write(String property, String value) {
    setProperty(property, value);
    final self = this;
    if (self is UiCssStyleDeclaration) _canvasStyleWritten(self);
  }
}

/// Lays out the parent element of the canvas of [style] again.
void _canvasStyleWritten(UiCssStyleDeclaration style) {
  final canvas = _canvasOfStyle[style];
  final parent = canvas == null ? null : _canvasParents[canvas];
  if (parent == null) return;
  parent._revision++;
  _harness.write();
}

// The state of the harness.

final _Harness _harness = _Harness();

/// The state of the harness in the current test.
final class _Harness {
  /// The generation of the current test. A body of an earlier test does
  /// nothing at its unmount.
  int generation = 0;

  /// Whether the current test attached the body.
  bool attached = false;

  /// The state of the mounted body of the current test.
  _HarnessBodyState? state;

  /// Whether the body of the current test unmounted. Then a write changes
  /// only the element tree.
  bool unmounted = false;

  bool inForcedLayout = false;

  /// Whether an append or a removal came after the last forced layout.
  bool mutationSinceLayout = false;

  bool checkpointScheduled = false;

  /// Whether a rebuild waits for a post-frame callback, and whether a
  /// mutation waits with it.
  bool rebuildWaits = false;
  bool mutationWaits = false;

  bool tearDownRegistered = false;

  /// The standby host of each canvas of `document.createElement`.
  final Map<UiCanvasElement, RenderChartHost> standbyHosts = {};

  /// The functions of [afterEachChart].
  final List<void Function()> afterEach = [];

  /// The harness tasks, in insertion order.
  final List<_Task> tasks = [];
  int taskOrder = 0;

  /// Whether a [pumpFrames] loop holds the pump: it drains the microtasks,
  /// runs the due tasks or pumps a frame.
  bool pumping = false;

  /// The step that a waiting [pumpFrames] loop awaits. The loop that holds
  /// the pump completes it after each step.
  Completer<void>? step;

  TestWidgetsFlutterBinding get binding =>
      TestWidgetsFlutterBinding.ensureInitialized();

  /// Whether a write rebuilds the body: in a `testWidgets` body, before the
  /// unmount of the body.
  bool get live => binding.inTest && !unmounted;

  /// Whether the body of the current test is attached and mounted.
  bool get mounted => attached && !unmounted && binding.inTest;

  /// Whether a rebuild must wait: during build, layout or paint, and during
  /// a forced layout.
  bool get mustWait {
    if (inForcedLayout) return true;
    final phase = SchedulerBinding.instance.schedulerPhase;
    return phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;
  }

  /// Whether a forced layout can run: not during build, layout or paint,
  /// and not in a forced layout. It can run in a frame callback and in the
  /// microtasks after the transient callbacks.
  bool get canForceLayout =>
      !inForcedLayout &&
      SchedulerBinding.instance.schedulerPhase !=
          SchedulerPhase.persistentCallbacks;

  /// Registers the end of the test, once in each test.
  void begin() {
    if (tearDownRegistered) return;
    tearDownRegistered = true;
    addTearDown(end);
  }

  /// The end of the test: clears the tasks and the state of the test, and
  /// disposes the standby hosts. The element tree stays, as the DOM stays
  /// between the specs upstream.
  void end() {
    generation++;
    attached = false;
    state = null;
    unmounted = false;
    inForcedLayout = false;
    mutationSinceLayout = false;
    checkpointScheduled = false;
    rebuildWaits = false;
    mutationWaits = false;
    tearDownRegistered = false;
    pumping = false;
    step = null;
    tasks.clear();
    for (final host in standbyHosts.values) {
      host.dispose();
    }
    standbyHosts.clear();
  }

  /// A DOM write: the element tree changed. [mutation] is an append or a
  /// removal.
  void write({bool mutation = false}) {
    if (!live) return;
    begin();
    if (mustWait) {
      mutationWaits |= mutation;
      if (rebuildWaits) return;
      rebuildWaits = true;
      final writeGeneration = generation;
      SchedulerBinding.instance
        ..addPostFrameCallback((_) {
          if (writeGeneration != generation) return;
          final waitingMutation = mutationWaits;
          rebuildWaits = false;
          mutationWaits = false;
          if (live) _rebuild(mutation: waitingMutation);
        }, debugLabel: 'HarnessBody.write')
        ..ensureVisualUpdate();
      return;
    }
    _rebuild(mutation: mutation);
  }

  void _rebuild({required bool mutation}) {
    final current = state;
    if (current != null) {
      current.changed();
    } else {
      attachBody();
    }
    if (mutation) {
      mutationSinceLayout = true;
      _scheduleCheckpoint();
    }
  }

  /// Attaches the body as the root widget of the test, once in each test.
  void attachBody() {
    if (attached) return;
    begin();
    attached = true;
    binding.attachRootWidget(
      binding.wrapWithDefaultView(_HarnessBody(generation: generation)),
    );
  }

  /// The mutation checkpoint: one microtask for the appends and removals of
  /// one task.
  void _scheduleCheckpoint() {
    if (checkpointScheduled) return;
    checkpointScheduled = true;
    final checkpointGeneration = generation;
    scheduleMicrotask(() {
      if (checkpointGeneration != generation) return;
      checkpointScheduled = false;
      if (mutationSinceLayout && mounted && canForceLayout) _forcedLayout();
      flushCanvasMutations();
    });
  }
}

/// The forced build and layout of the harness body, with no frame callback
/// and no paint: the layout that a browser forces when a script reads a
/// layout value.
void _forcedLayout() {
  final harness = _harness;
  final binding = harness.binding;
  harness
    ..inForcedLayout = true
    ..mutationSinceLayout = false;
  try {
    binding.buildOwner!.buildScope(binding.rootElement!);
    binding.rootPipelineOwner.flushLayout();
  } finally {
    harness.inForcedLayout = false;
  }
}

/// The forced build and layout of the harness body (Chart.js ADR 0022,
/// section 4): `acquireChart` calls it after `document.body.appendChild`
/// (`src/utils.js:73`), so that the chart finds its canvas in a laid-out
/// host. It attaches the body first when the test has not attached it.
///
/// Throws a [StateError] outside the body of a `testWidgets` test, after
/// the unmount of the body, and during build, layout or paint. It can run
/// in a frame callback.
void forceHarnessLayout() {
  final harness = _harness;
  if (!harness.binding.inTest) {
    throw StateError('The harness lays out only in a testWidgets body.');
  }
  if (harness.unmounted) {
    throw StateError('The harness body of this test is unmounted.');
  }
  if (!harness.canForceLayout) {
    throw StateError(
      'The harness cannot lay out during build, layout or '
      'paint.',
    );
  }
  harness.attachBody();
  _forcedLayout();
}

/// Adds [callback] to the functions that the unmount of the harness body
/// calls (Chart.js ADR 0022, section 8). `flutter_test_config.dart` adds
/// `releaseCharts`. flutter_test disposes the body in the warm-up frame of
/// its `runApp` after the test body. Thus [callback] runs before the
/// end-of-test checks of flutter_test and before the `tearDown` functions.
/// A [callback] that the list has already is not added again.
void afterEachChart(void Function() callback) {
  if (!_harness.afterEach.contains(callback)) _harness.afterEach.add(callback);
}

// The harness body.

/// The root widget of a test: it shows `document.body`.
final class _HarnessBody extends StatefulWidget {
  const _HarnessBody({required this.generation});

  final int generation;

  @override
  State<_HarnessBody> createState() => _HarnessBodyState();
}

final class _HarnessBodyState extends State<_HarnessBody> {
  bool get _current => widget.generation == _harness.generation;

  @override
  void initState() {
    super.initState();
    if (_current) _harness.state = this;
  }

  void changed() => setState(() {});

  @override
  void dispose() {
    if (_current && identical(_harness.state, this)) {
      _harness
        ..state = null
        ..unmounted = true;
      for (final callback in List.of(_harness.afterEach)) {
        callback();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _buildElement(document.body, TextDirection.ltr);

  static Widget _buildElement(HarnessElement element, TextDirection inherited) {
    final layout = _Layout.of(element);
    final direction = layout.direction ?? inherited;
    return Directionality(
      key: ObjectKey(element),
      textDirection: direction,
      child: _ElementBox(
        element: element,
        layout: layout,
        revision: element._revision,
        children: [
          for (final child in element._children)
            switch (child) {
              final HarnessElement childElement => _buildElement(
                childElement,
                direction,
              ),
              final UiCanvasElement canvas => _CanvasSlot(
                key: ObjectKey(canvas),
                canvas: canvas,
              ),
              _ => const SizedBox.shrink(),
            },
        ],
      ),
    );
  }
}

/// A canvas child: a `ChartHost`. When the host leaves the tree, the canvas
/// gets its standby host back as its parent node, after the frame. Thus a
/// removed canvas keeps `FlutterPlatform`, as a removed canvas keeps the
/// DOM platform upstream.
final class _CanvasSlot extends StatefulWidget {
  const _CanvasSlot({required this.canvas, super.key});

  final UiCanvasElement canvas;

  @override
  State<_CanvasSlot> createState() => _CanvasSlotState();
}

final class _CanvasSlotState extends State<_CanvasSlot> {
  @override
  void dispose() {
    final canvas = widget.canvas;
    final generation = _harness.generation;
    // The post-frame connection check of the host runs first: it reports the
    // detach while the host is still the parent node.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final standby = _harness.standbyHosts[canvas];
      if (generation == _harness.generation &&
          standby != null &&
          canvas.parentNode == null) {
        canvas.parentNode = standby;
      }
    }, debugLabel: 'HarnessBody.standby');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChartHost(canvas: widget.canvas);
}

/// The CSS subset of one element, read at the build of the body.
@immutable
final class _Layout {
  const _Layout({
    required this.isBody,
    required this.none,
    required this.absolute,
    required this.padding,
    this.width,
    this.height,
    this.maxWidth,
    this.maxHeight,
    this.direction,
  });

  factory _Layout.of(HarnessElement element) {
    final style = element._declarations;
    final classes = (element._attributes['class'] ?? '').split(_spaces);
    final wrapper = classes.contains('chartjs-wrapper');
    final position = style.getPropertyValue('position').trim().toLowerCase();
    final absolute = position.isEmpty
        ? wrapper
        : position == 'absolute' || position == 'fixed';
    final display = style.getPropertyValue('display').trim().toLowerCase();
    final direction = switch (style
        .getPropertyValue('direction')
        .trim()
        .toLowerCase()) {
      'rtl' => TextDirection.rtl,
      'ltr' => TextDirection.ltr,
      _ => null,
    };
    return _Layout(
      isBody: element._isBody,
      none: display == 'none',
      absolute: absolute,
      padding: _pixels(style.getPropertyValue('padding')) ?? 0,
      width: _pixels(style.getPropertyValue('width')),
      height: _pixels(style.getPropertyValue('height')),
      maxWidth: _pixels(style.getPropertyValue('max-width')),
      maxHeight: _pixels(style.getPropertyValue('max-height')),
      direction: direction,
    );
  }

  static final RegExp _spaces = RegExp(r'[\t\n\f\r ]+');

  static final RegExp _length = RegExp(
    r'^\s*(\d*\.?\d+(?:e[+-]?\d+)?)(px)?\s*$',
    caseSensitive: false,
  );

  /// A px length, or `0` without a unit. `null` for another value.
  static double? _pixels(String value) {
    final match = _length.firstMatch(value);
    if (match == null) return null;
    final number = double.parse(match[1]!);
    return match[2] != null || number == 0 ? number : null;
  }

  final bool isBody;
  final bool none;

  /// `position: absolute`: shrink-to-fit width, out of the flow.
  final bool absolute;
  final double padding;
  final double? width;
  final double? height;
  final double? maxWidth;
  final double? maxHeight;
  final TextDirection? direction;

  @override
  bool operator ==(Object other) =>
      other is _Layout &&
      other.isBody == isBody &&
      other.none == none &&
      other.absolute == absolute &&
      other.padding == padding &&
      other.width == width &&
      other.height == height &&
      other.maxWidth == maxWidth &&
      other.maxHeight == maxHeight &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(
    isBody,
    none,
    absolute,
    padding,
    width,
    height,
    maxWidth,
    maxHeight,
    direction,
  );
}

/// The render widget of one element.
final class _ElementBox extends MultiChildRenderObjectWidget {
  const _ElementBox({
    required this.element,
    required this.layout,
    required this.revision,
    super.children,
  });

  final HarnessElement element;
  final _Layout layout;
  final int revision;

  @override
  _RenderHarnessElement createRenderObject(BuildContext context) =>
      _RenderHarnessElement(element, layout, revision);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHarnessElement renderObject,
  ) {
    renderObject
      ..element = element
      ..elementLayout = layout
      ..revision = revision;
  }
}

final class _ElementParentData extends ContainerBoxParentData<RenderBox> {}

/// The render box of one [HarnessElement] (see its CSS subset).
final class _RenderHarnessElement extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ElementParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ElementParentData> {
  _RenderHarnessElement(this._element, this._layout, this._revision) {
    _element._box = this;
  }

  HarnessElement get element => _element;
  HarnessElement _element;
  set element(HarnessElement value) {
    if (identical(value, _element)) return;
    if (identical(_element._box, this)) _element._box = null;
    _element = value;
    _element._box = this;
    markNeedsLayout();
  }

  _Layout get elementLayout => _layout;
  _Layout _layout;
  set elementLayout(_Layout value) {
    if (value == _layout) return;
    _layout = value;
    markNeedsLayout();
  }

  /// Whether an ancestor has `display: none`. Then the element and its
  /// subtree get the size 0, as in CSS. The parent sets it before each
  /// layout of this element. A change of the value comes with other
  /// constraints: tight 0 x 0 in a hidden subtree, loose outside it.
  bool _hiddenByAncestor = false;

  int get revision => _revision;
  int _revision;
  set revision(int value) {
    if (value == _revision) return;
    _revision = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ElementParentData) {
      child.parentData = _ElementParentData();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _element._box = this;
  }

  @override
  void dispose() {
    if (identical(_element._box, this)) _element._box = null;
    super.dispose();
  }

  /// The content size of a canvas child: the display size of the canvas
  /// (Chart.js ADR 0022, sections 3 and 9), 0 x 0 for a canvas with its own
  /// `display: none`.
  ///
  /// The display size is the one of `toBeChartOfSize`
  /// ([computedCanvasSize]): with one px style, the other side keeps the
  /// aspect ratio of the render size, the CSS rule for a replaced element.
  /// `RenderChartHost.displaySize` does not apply that rule.
  static Size _contentOf(RenderChartHost host) {
    final display = host.canvas.style.getPropertyValue('display');
    if (display.trim().toLowerCase() == 'none') return Size.zero;
    final (:width, :height) = computedCanvasSize(host.canvas);
    return Size(width!, height!);
  }

  /// The min-content and max-content widths of the children, for a
  /// shrink-to-fit width.
  (double, double) _contentWidths() {
    var minWidth = 0.0;
    var maxWidth = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      switch (child) {
        case final RenderChartHost host:
          final width = _contentOf(host).width;
          minWidth = math.max(minWidth, width);
          maxWidth = math.max(maxWidth, width);
        case final _RenderHarnessElement element:
          final layout = element._layout;
          if (layout.none) continue;
          final fixed = layout.width;
          if (fixed != null) {
            final width = fixed + 2 * layout.padding;
            minWidth = math.max(minWidth, width);
            maxWidth = math.max(maxWidth, width);
          } else {
            final (childMin, childMax) = element._contentWidths();
            minWidth = math.max(minWidth, childMin + 2 * layout.padding);
            maxWidth = math.max(maxWidth, childMax + 2 * layout.padding);
          }
      }
    }
    return (minWidth, maxWidth);
  }

  List<Size> _hostContents() => [
    for (var child = firstChild; child != null; child = childAfter(child))
      if (child is RenderChartHost) _contentOf(child),
  ];

  @override
  void performLayout() {
    final layout = _layout;
    if (layout.isBody) {
      _layoutBody();
    } else if (layout.none || _hiddenByAncestor) {
      // `display: none` hides the whole subtree: each descendant element
      // and each canvas host gets the size 0.
      for (var child = firstChild; child != null; child = childAfter(child)) {
        if (child is _RenderHarnessElement) child._hiddenByAncestor = true;
        child.layout(const BoxConstraints.tightFor(width: 0, height: 0));
        (child.parentData! as _ElementParentData).offset = Offset.zero;
      }
      size = constraints.smallest;
    } else {
      // The first layout of a host can resize its chart (the attach). Then
      // the content of an auto size changes: lay out again, at most twice.
      for (var pass = 0; pass < 3; pass++) {
        final before = _hostContents();
        _layoutElement(layout);
        if (_sameSizes(before, _hostContents())) break;
      }
    }
  }

  static bool _sameSizes(List<Size> a, List<Size> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _layoutBody() {
    size = constraints.biggest.isFinite
        ? constraints.biggest
        : constraints.constrain(const Size(800, 600));
    final width = size.width;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      if (child is RenderChartHost) {
        _layoutHost(child, width, null, null);
      } else {
        if (child is _RenderHarnessElement) child._hiddenByAncestor = false;
        child.layout(BoxConstraints(maxWidth: width));
      }
      (child.parentData! as _ElementParentData).offset = Offset.zero;
    }
  }

  void _layoutElement(_Layout layout) {
    final padding = layout.padding;
    final available = math.max<double>(0, constraints.maxWidth - 2 * padding);
    var width = layout.width;
    if (width == null) {
      if (layout.absolute) {
        final (minContent, maxContent) = _contentWidths();
        width = math.min(math.max(minContent, available), maxContent);
      } else {
        width = available;
      }
    }
    final maxWidth = layout.maxWidth;
    if (maxWidth != null) width = math.min(width, maxWidth);
    var height = layout.height;
    final maxHeight = layout.maxHeight;
    if (height != null && maxHeight != null) {
      height = math.min(height, maxHeight);
    }

    var flow = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      // The height of the child in the flow. Without a fixed height, a
      // canvas takes the height of its box: its CSS display height (see
      // [_contentOf]), capped by [maxHeight].
      double childHeight;
      if (child is RenderChartHost) {
        final boxHeight = _layoutHost(child, width, height, maxHeight);
        childHeight = height == null ? boxHeight : child.size.height;
      } else {
        if (child is _RenderHarnessElement) child._hiddenByAncestor = false;
        child.layout(BoxConstraints(maxWidth: width), parentUsesSize: true);
        childHeight = child.size.height;
      }
      (child.parentData! as _ElementParentData).offset = Offset(
        padding,
        padding + flow,
      );
      final outOfFlow =
          child is _RenderHarnessElement &&
          child._layout.absolute &&
          !child._layout.none;
      if (!outOfFlow) flow += childHeight;
    }
    var contentHeight = height ?? flow;
    if (height == null && maxHeight != null) {
      contentHeight = math.min(contentHeight, maxHeight);
    }
    size = constraints.constrain(
      Size(width + 2 * padding, contentHeight + 2 * padding),
    );
  }

  /// Lays out a canvas child with loose constraints whose max size is the
  /// content box: [height] when it is fixed, else the content of the canvas,
  /// capped by [maxHeight]. Returns the height of that box.
  static double _layoutHost(
    RenderChartHost host,
    double width,
    double? height,
    double? maxHeight,
  ) {
    var boxHeight = height;
    if (boxHeight == null) {
      boxHeight = _contentOf(host).height;
      if (maxHeight != null) boxHeight = math.min(boxHeight, maxHeight);
    }
    host.layout(
      BoxConstraints(maxWidth: width, maxHeight: boxHeight),
      parentUsesSize: true,
    );
    return boxHeight;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_layout.none) return;
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (_layout.none) return false;
    return defaultHitTestChildren(result, position: position);
  }
}

// Frames, time and the harness tasks.

/// One browser frame at 60 Hz, rounded down to whole ms.
const Duration frameInterval = Duration(milliseconds: 16);

/// The Jasmine default timeout (`jasmine.DEFAULT_TIMEOUT_INTERVAL`).
const Duration specTimeout = Duration(milliseconds: 5000);

/// One harness task: a [callback] due at [due].
final class _Task {
  _Task(this.due, this.order, this.callback);

  final DateTime due;
  final int order;
  final void Function() callback;
}

/// `window.setTimeout(callback, delay)` of a spec: a harness task that is
/// due at `clock.now()` plus [delay] ms. A negative [delay] is 0.
///
/// A harness task is not a `Timer`. [pumpFrames] runs it between the pumps,
/// in the zone of the test body. Thus an `expect` in it works, where an
/// `expect` in a `Timer` that a pump fires throws "Guarded function
/// conflict.". The end of the test clears the tasks: a task never reaches
/// the next test, and flutter_test reports no pending `Timer` for it.
void setTimeout(void Function() callback, [int delay = 0]) {
  final harness = _harness..begin();
  harness.tasks.add(
    _Task(
      clock.now().add(Duration(milliseconds: math.max(0, delay))),
      harness.taskOrder++,
      callback,
    ),
  );
}

/// Runs the due harness tasks: the earliest due time first, then the
/// insertion order. The microtasks run before each task, as at the
/// microtask checkpoint of a browser task: also the microtasks that a
/// microtask queues, until the queue of the fake async zone is empty.
Future<void> _runDueTasks() async {
  final tasks = _harness.tasks;
  final binding = _harness.binding;
  while (true) {
    // One await gives one turn of the queue. A microtask that a microtask
    // queues comes after the continuation of the await. Thus the loop
    // awaits again until no microtask is left.
    do {
      await Future<void>.value();
    } while (binding.microtaskCount > 0);
    final now = clock.now();
    _Task? next;
    for (final task in tasks) {
      if (task.due.isAfter(now)) continue;
      if (next == null ||
          task.due.isBefore(next.due) ||
          (task.due == next.due && task.order < next.order)) {
        next = task;
      }
    }
    if (next == null) return;
    tasks.remove(next);
    next.callback();
  }
}

/// Pumps frames of [frameInterval] until [condition] holds, and returns the
/// count of the pumps.
///
/// Each step lets the microtasks of the test body run, runs the due harness
/// tasks, and then tests [condition]. Then it calls `binding.pump`, which
/// advances the fake clock and runs the frame callbacks, the build, the
/// layout and the paint: the order of the HTML event loop. After
/// [specTimeout] of fake time, it fails with the Jasmine timeout message.
///
/// Only one loop holds the pump at a time. A loop that starts while another
/// loop holds it (the fixture runner settles a `run` hook that awaits
/// `triggerMouseEvent`) does not drain and does not pump: it awaits each
/// step of the other loop and then tests [condition]. Two loops that drain
/// at the same time wait for each other without end, because the await of
/// each drain is a microtask that the other drain counts. A waiting loop
/// does not test the timeout: the loop that holds the pump has its own.
/// When that loop ends, the waiting loop takes the pump.
Future<int> pumpFrames(bool Function() condition) async {
  final harness = _harness;
  final binding = harness.binding;
  final end = clock.now().add(specTimeout);
  var frames = 0;
  while (true) {
    if (harness.pumping) {
      await (harness.step ??= Completer<void>()).future;
      if (condition()) return frames;
      frames++;
      continue;
    }
    harness.pumping = true;
    try {
      await _runDueTasks();
      if (condition()) return frames;
      if (!clock.now().isBefore(end)) {
        fail(
          'Timeout - Async function did not complete within '
          '${specTimeout.inMilliseconds}ms',
        );
      }
      await binding.pump(frameInterval);
      frames++;
    } finally {
      harness.pumping = false;
      final step = harness.step;
      harness.step = null;
      step?.complete();
    }
  }
}

/// One frame for the image load task of the fixture runner (Chart.js ADR
/// 0029, section 7): runs the due harness tasks, and then one pump of
/// [frameInterval] with the frame callbacks, the build, the layout and the
/// paint.
///
/// `fixture.js:57` loads the PNG in a later task. The port compares no image
/// (Chart.js ADR 0034, section 4). Thus this frame stands for that task, and
/// it puts the paint of the chart into each smoke test
/// (`harness-fixture-frame`).
Future<void> pumpFrame() async {
  await _runDueTasks();
  await _harness.binding.pump(frameInterval);
}

/// Runs [spec] with a Jasmine `done` callback. Then calls [pumpFrames]
/// until the spec calls `done`: `it(name, function(done) {...})` becomes
/// `await waitForDone((done) {...});`.
Future<void> waitForDone(void Function(void Function() done) spec) async {
  var isDone = false;
  spec(() => isDone = true);
  await pumpFrames(() => isDone);
}
