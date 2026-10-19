# Chart.js ADR 0022: Chart test harness on Flutter

- Status: proposed
- Date: 2026-10-19
- Related: [Chart.js ADR 0006](0006-options-representation-and-resolver.md) (objects as Maps),
  [Chart.js ADR 0009](0009-no-display-only-js-exactness.md) (the protected behavior),
  [Chart.js ADR 0010](0010-js-numeric-semantics.md) (`jsDateNow` on `clock.now()`),
  [Chart.js ADR 0011](0011-third-party-sources.md) (chartjs-test-utils 0.4.0),
  [Chart.js ADR 0012](0012-dart-file-naming.md) (paths, underscore names, collisions),
  [Chart.js ADR 0013](0013-canvas-model.md) (the canvas attributes),
  [Chart.js ADR 0014](0014-input-events-and-chart-host.md) (the chart host),
  [Chart.js ADR 0016](0016-frame-scheduling.md) (frames, `throttled`, teardown frames),
  [Chart.js ADR 0019](0019-animation.md) (animation),
  [Chart.js ADR 0020](0020-registry-and-component-classes.md) (registry and component classes)
  and [Chart.js ADR 0021](0021-typed-options-in-the-resolver.md) (typed options in the resolver),
  the parallel phase 5 decisions,
  [porting-flow.md](../porting-flow.md) §1.1 and §3 (the harness table),
  [canvas-cuts-plan.md](../canvas-cuts-plan.md) §3.3 and §3.7 (cut 2)

## Context

Phase 5 ports the chart helpers of chartjs-test-utils 0.4.0. The harness table of
[porting-flow.md](../porting-flow.md) §3 lists them: `acquireChart`, `afterEvent`,
`triggerMouseEvent` and `waitForResize` of `src/utils.js`, and `toBeValidChart` and
`toBeChartOfSize` of `src/matchers.js`. Phase 5 also adds `releaseCharts()` to
`test/flutter_test_config.dart` (`test/index.js:34-36`). The specs of `test/specs/*.tests.js`
call these helpers through the globals of Chart.js `test/index.js`. The specs also need the
built-in components that the UMD entry `src/index.umd.ts` registers (`karma.conf.cjs:110`).

### Upstream helpers

- `_acquireChart(config, options)` (`src/utils.js:36-105`) creates a `div` wrapper and a canvas
  (`:37-38`).
  - The canvas attributes default to `{height: 512, width: 512}` (`:43`). The wrapper attributes
    default to `{class: 'chartjs-wrapper'}` (`:44`). The helper copies both objects into
    attributes with `setAttribute` (`:46-56`).
  - It sets `animation` and `responsive` to `false` when they are `undefined` (`:60-61`). It sets
    a falsy `locale` to `'en-US'` (`:62`).
  - It appends the wrapper to `document.body` (`:73`). Then it calls `new Chart(ctx, config)`
    (`:93`). Thus the canvas is in the document at construction.
  - A throw removes the wrapper and continues (`:94-97`). `chart.$test` keeps `persistent` and the
    wrapper (`:99-102`).
- `acquireChart` (`src/index.js:22-26`) adds the chart to the module object `charts` (`:9`).
  `releaseChart` (`:28-31`) releases one chart and deletes it from `charts`. `releaseCharts`
  (`:54-61`) releases each chart of `charts` that is not persistent. It never deletes a chart.
  Thus each later call destroys the earlier charts again.
- `_releaseChart` (`src/utils.js:107-115`) calls `chart.destroy()`. Then it removes the wrapper
  from its parent.
- `injectWrapperCSS` (`src/index.js:37-48`, called at `test/index.js:13`) gives the class
  `chartjs-wrapper` the rule `position: absolute`, with no border, margin or padding.
- `waitForResize(chart, callback)` (`src/utils.js:130-137`) replaces the own property
  `chart.resize`. The replacement restores the old value, calls it, and then calls `callback`.
  Every call of `this.resize` in `core.controller.js` reaches it: `_initialize` (`:241`), the
  resize listener (`:1017`), the attach listener (`:1026`) and a call in a spec.
- `afterEvent(chart, type, callback)` (`src/utils.js:139-149`) replaces `chart._eventHandler` in
  the same way. The replacement calls `override.call(this, event)` (`:142`). Thus it drops the
  second argument `replay`. It calls `callback` after the whole handler, also after
  `this.render()` (`core.controller.js:1181-1183`). The replay of `update()`
  (`core.controller.js:531`) also reaches the replacement.
- `triggerMouseEvent(chart, type, el)` (`src/utils.js:163-184`) makes a `MouseEvent` at
  `clientX: rect.left + point.x` and `clientY: rect.top + point.y` (`:167-173`). It installs
  `afterEvent` (`:175-177`). Then it calls `node.dispatchEvent(event)` (`:179`). The DOM call
  reaches the listeners of the canvas without a hit test. The throttled proxy
  (`platform.dom.js:240-254`) calls the chart in the next animation frame. The promise resolves
  after that call. The function returns the event (`:183`).
- `toBeValidChart` (`src/matchers.js:106-129`) tests the class `Chart`, the `toString` tags of
  the canvas and of the context, and a finite `height` and `width`. `toBeChartOfSize`
  (`:131-174`) reads the display size with `parseInt(style.width, 10) || 0` of
  `getComputedStyle(canvas)` (`:141-144`). Its pixel ratio is
  `actual.options.devicePixelRatio || window.devicePixelRatio` (`:142`).
- `test/index.js:34-36` calls `releaseCharts()` in a global `afterEach`. Jasmine runs it after
  the `afterEach` blocks of the `describe` blocks.

### Call sites

A count over the 54 spec files of Chart.js v4.5.1 gave these figures (Evidence E1):

| Call site | Count | Files |
|---|---:|---:|
| `acquireChart(` | 547 | 33 |
| `acquireChart` with a second argument (`canvas` 69, `wrapper` 25, `useOffscreenCanvas` 4, `useShadowDOM` 3, `persistent` 0) | 74 | 12 |
| `new Chart(` | 13 | 2 |
| `waitForResize(` | 32 | 2 |
| `waitForResize(` on a chart of `new Chart(` | 6 | 2 |
| `afterEvent(` (the helper) | 0 | 0 |
| `triggerMouseEvent(` (`mousemove` 75, `mouseout` 20, `click` 5, `pointerdown`, `pointerleave`, `test` and `test2` 1 each) | 104 | 13 |
| `setTimeout(` | 10 | 2 |
| `it` with a `done` callback | 31 | 8 |
| `it` with an `async` function | 67 | 13 |
| `beforeEach` that acquires a chart | 29 | 10 |
| `afterEach` that reads or acquires a chart | 3 | 2 |
| `toBeChartOfSize(` | 56 | 2 |
| `toBeValidChart(` | 6 | 1 |
| `canvas.parentNode` | 21 | 2 |
| a spec that replaces `chart.resize` (`core.controller.tests.js:719`) | 1 | 1 |
| `spyOn(chart, ` | 2 | 1 |
| `document.getElementById` | 5 | 1 |

The fixtures of `test/fixtures` call `jasmine.triggerMouseEvent` 5 times, for example
`core.interaction/drawActiveElementsOnTop-false.js:38`. The fixture runner `src/fixture.js` of
phase 7 calls `_acquireChart` and `_releaseChart` (`fixture.js:1`, `:50`, `:59`).

### Facts of the port and of Flutter 3.44.9

- `detectPlatform` gives `FlutterPlatform` only for a canvas whose parent node is a
  `RenderChartHost` ([Chart.js ADR 0014](0014-input-events-and-chart-host.md) §1). A canvas
  without a host gets `BasicPlatform`. `BasicPlatform.updateConfig` sets `animation: false`
  (`platform.basic.js:20-22`). Its device pixel ratio is 1 (`platform.base.js:48-50`). The Retina
  specs (`core.controller.tests.js:1386-1431`) set `window.devicePixelRatio = 3` and expect a
  render size of 960 x 720.
- The first `performLayout` of a host reports the attach at once (Chart.js ADR 0014 §3,
  [Chart.js ADR 0016](0016-frame-scheduling.md) decision 9). The host gives a new
  `ContainerResizeObserver` the current size at once when the host is laid out
  (`RenderChartHost._addResizeObserver`). The DOM gives the first `ResizeObserver` notification
  in the HTML step "update the rendering" of the next frame.
- After the first layout, a net detach or attach reaches the chart in a post-frame callback of the
  host (Chart.js ADR 0016 decision 9). The DOM delivers the `MutationObserver` records of one task
  at its microtask checkpoint (`platform.dom.js:129-159`).
- `getCanvas` looks up a string id only when `_isDomSupported()` is true
  (`core.controller.js:51-53`). The port has no DOM. Thus `new Chart(canvasId)` has no port.
  Chart.js ADR 0014 (Consequences) skips the element id cases as `n/a`.
- `_runTestBody` of `testWidgets` (`flutter_test/lib/src/binding.dart:1935-1978`) runs these
  steps:
  1. `runApp` of a fresh tree and one `pump` (`:1940-1941`).
  2. The test body (`:1952`).
  3. Only when no exception is pending (`:1955`): `runApp` of another fresh tree (`:1959-1961`).
     The test binding attaches the root at once (`scheduleAttachRootWidget`, `:2382-2388`). Its
     warm-up frame runs synchronously (`scheduleWarmUpFrame`, `:2351-2359`). Then one `pump`
     runs (`:1962`).
  4. The assertions "An animation is still running even after the widget tree was disposed."
     (`:1982-1987`) and "A Timer is still pending even after the widget tree was disposed."
     (`:2523-2543`).
  5. The `tearDown` functions of `package:test` run after these steps (probes P6 and PP5).
- `package:test` runs the `tearDown` functions of one group in the reverse order of their
  declaration. It runs the inner groups first (probes P6 and PP5).
- The `expect` of flutter_test is a guarded function. An `expect` in a `Timer` that the test body
  created throws "Guarded function conflict." when `binding.pump` fires the `Timer` (probe J1).
  An `expect` works in a frame callback, in a post-frame callback, and in a microtask or `Timer`
  that a frame callback created (probe J1).
- A `setState` call during the layout of a host throws "Build scheduled during frame." (probe
  P12).
- `setUp` runs outside the `FakeAsync` zone of `testWidgets`. Then step 1 replaces the root
  widget. Thus a chart that `setUp` acquires loses its host before the body (probe SP4).
- A Dart class cannot implement or override a method with a field of the same name, or a field
  with a method. The analyzer gives `conflicting_field_and_method` and
  `conflicting_method_and_field` (probe J3). A function-typed getter in an interface accepts a
  field.
- An `@internal` member that another package uses gives the diagnostic
  `invalid_use_of_internal_member` (probe E4).

### Gaps of the current host

The prototypes ported spec shapes onto the current host. These shapes fail (probes P2, P3, J2,
PP7, SP6):
- A wrapper write after `acquireChart` in the same task. On the upstream shape of
  `core.controller.tests.js:657`, the callbacks saw the widths 300 and 455 (probe J2), or 300 and
  150 (probe P2). Upstream gives 455 and 150. The family is `:657`, `:750`, `:790`, `:830`,
  `:1304`, `:1345` and `:1816`.
- A detach, an attach and a detach in one task (`:1147`). The chart got 1 `resize()` call.
  Upstream gives 0.
- A detach and a later attach (`:1065`). The attach calls were `[attached]` and the update modes
  `default`, `resize`, `resize`. Upstream gives `[attached, detached, attached]` and `default`,
  `attach`, `resize` (probes PP7 and F2b).

The cause: the first notification enters `throttled` at `observe()`, before the DOM writes of the
same task. A detach outside a frame also reaches the chart only after the next frame.

## Decision

### 1. Files and the pure split

- `packages/chartjs_test_utils/lib/src/utils.dart` ports `src/utils.js`. It is not a pure layer:
  it imports `package:flutter_test`, `core.controller`, the chart host and `dom.dart`.
- `lib/src/index.dart` ports `src/index.js`. It imports `utils.dart` with the prefix `utils`. The
  reason: the Dart names of `_acquireChart` and `_releaseChart` collide with `acquireChart` and
  `releaseChart` ([Chart.js ADR 0012](0012-dart-file-naming.md), Collisions). It is not a pure
  layer.
- `createMockContext` (`src/index.js:33-35`) moves to `lib/src/context.dart`. Thus `pure.dart`
  keeps it. One `DIVERGES` marker in `context.dart` carries the row `harness-index-pure-split`.
  `index.dart` keeps a comment at the place of `:33`.
- `toBeValidChart` and `toBeChartOfSize` go in `lib/src/matchers.dart`, the mapped path of
  `src/matchers.js`. They read only pure interfaces (section 9). Thus `matchers.dart` stays pure.
- The port-only file `lib/src/dom.dart` declares the DOM stand-in, the harness body, the harness
  tasks and the frame helpers (sections 3, 7 and 8). It is not a pure layer.
- `pure.dart` exports `ContextCall`, `MockContext`, `createMockContext`, the six matchers,
  `setUpSpecs` and `setUpDefaultsRestore`.
- `flutter.dart` exports `acquireChart`, `releaseChart`, `releaseCharts`, `afterEvent`,
  `waitForResize` and `triggerMouseEvent` from `index.dart` (`src/index.js:6`). It exports
  `document`, `window`, `setTimeout`, `afterEachChart`, `pumpFrames`, `waitForDone`,
  `frameInterval`, `specTimeout` and the extensions `CanvasParentElement` and `CssProperties` from
  `dom.dart`. It keeps the font exports.
- The pubspec of `chartjs_test_utils` moves `flutter_test` from `dev_dependencies` to
  `dependencies`, because `utils.dart` and `dom.dart` import it. It adds `clock: ^1.1.2`, because
  the harness tasks read `clock.now()`. Neither package is code from another project. Thus
  `LICENSE` and `REUSE.toml` do not change.
- A spec file that creates a chart imports `flutter.dart` and `flutter_test`. It has
  `@TestOn('vm')` below its header lines. The specs of a pure layer stay on `package:test`.

### 2. Spec form

- Each spec case that creates a chart or calls the harness DOM is a `testWidgets` test. Its name
  is the upstream `it` name. Frames run only when a test pumps
  ([Chart.js ADR 0016](0016-frame-scheduling.md), decision 10).
- `acquireChart` throws a `StateError` outside the body of a `testWidgets` test. Thus all chart
  specs have one form.
- A ported `beforeEach` that acquires a chart is a local function. Each test calls it first in
  its body ([porting-flow.md](../porting-flow.md) §3).
- A ported `afterEach` that reads or acquires a chart is also a local function. Each test calls
  it last in its body. Thus it runs before `releaseCharts`, as in Jasmine. The cases are
  `controller.bar.tests.js:1325`, `:1399` and `core.controller.tests.js:1968`.
- Other `beforeEach` and `afterEach` blocks stay `setUp` and `tearDown`. An example is the
  `window.devicePixelRatio` writes of `core.controller.tests.js:1387-1394`.
- An `it` with a `done` callback becomes `await waitForDone((done) { ... });` (section 7).
- An `async` `it` becomes an `async` body. `await jasmine.triggerMouseEvent(...)` becomes
  `await triggerMouseEvent(...)`.
- `setTimeout(fn, ms)` keeps its text. It is the harness task of section 7, not a `dart:async`
  `Timer`.
- `new Chart(item, config)` becomes `Chart(item, config)`.
- `chart.canvas.parentNode` becomes `chart.canvas!.parentElement` (section 3). In the port, the
  `parentNode` of a canvas is its host. The `parentNode` of a harness element keeps its text.

Example (`core.controller.tests.js:1065-1113`):

```dart
testWidgets(
  'should resize the canvas after the wrapper has been re-attached to the DOM',
  (tester) async {
    await waitForDone((done) {
      final chart = acquireChart({
        'options': {'responsive': true, 'maintainAspectRatio': false},
      }, {
        'canvas': {'style': ''},
        'wrapper': {'style': 'width: 320px; height: 350px'},
      });

      expect(chart, toBeChartOfSize({'dw': 320, 'dh': 350, 'rw': 320, 'rh': 350}));

      final wrapper = chart.canvas!.parentElement!;
      final parent = wrapper.parentNode!;

      waitForResize(chart, () {
        expect(chart, toBeChartOfSize({'dw': 320, 'dh': 355, 'rw': 320, 'rh': 355}));

        waitForResize(chart, () {
          expect(chart, toBeChartOfSize({'dw': 455, 'dh': 355, 'rw': 455, 'rh': 355}));

          done();
        });

        parent.removeChild(wrapper);
        wrapper.style.width = '455px';
        parent.appendChild(wrapper);
      });

      parent.removeChild(wrapper);
      setTimeout(() {
        parent.appendChild(wrapper);
        wrapper.style.height = '355px';
      }, 0);
    });
  },
);
```

### 3. The DOM stand-in

`lib/src/dom.dart` (port-only) gives the specs and `utils.dart` the DOM parts that they use:

```dart
/// `window.document` of the specs.
final HarnessDocument document;

/// `window` of the specs.
final HarnessWindow window;

final class HarnessDocument {
  /// `document.body`.
  HarnessElement get body;

  /// `document.createElement(tagName)`: a [HarnessElement] for 'div', a
  /// UiCanvasElement with a standby host for 'canvas' (section 4).
  T createElement<T extends Object>(String tagName);

  /// `document.getElementById(id)`.
  T? getElementById<T extends Object>(String id);
}

final class HarnessWindow {
  /// `window.devicePixelRatio`: the device pixel ratio of the test view.
  double get devicePixelRatio;
  set devicePixelRatio(double value);
}

final class HarnessElement {
  CSSStyleDeclaration get style;
  HarnessElement? get parentNode;
  int get clientWidth;
  int get clientHeight;
  void appendChild(Object node);
  void removeChild(Object node);
  bool contains(Object node);
  void remove();
  void setAttribute(String name, String value);
  String? getAttribute(String name);
}

/// The DOM parent of a canvas, and `remove()`.
extension CanvasParentElement on HTMLCanvasElement {
  HarnessElement? get parentElement;
  void remove();
}

/// The style properties that the specs read and write.
extension CssProperties on CSSStyleDeclaration {
  String get width;
  set width(String value);
  String get height;
  set height(String value);
  String get display;
  set display(String value);
  String get cssText;
  set cssText(String value);
}
```

- A node is a `HarnessElement` or a `UiCanvasElement`. `createElement` throws an `ArgumentError`
  for another tag name, or when the node is not a `T`. A spec gives the type through the declared
  type of its variable: `final HTMLCanvasElement canvas = document.createElement('canvas');`.
- `getElementById` searches the harness tree for the `id` attribute. `platform.dom.tests.js:8-16`
  needs it, with `setAttribute('id', ...)` and `remove()`.
- `window.devicePixelRatio` writes the device pixel ratio of
  `TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView`. The `setUp` of
  `flutter_test_config.dart` sets it back to 1 before each test.
- `wrapper.style.width = '455px'` and `canvas.style.display = 'block'` keep the upstream text
  through `CssProperties`.

**The harness body.** A port-only `StatefulWidget` shows `document.body` as the root widget of
the test. The first harness DOM write or `acquireChart` of a test attaches it with
`binding.attachRootWidget(binding.wrapWithDefaultView(...))`. It replaces the tree of
flutter_test. The body has the size of the test view (800 x 600 logical pixels). It places each
child at its top left corner, with the view width and an unbounded height.

**Layout of an element.** Each `HarnessElement` is one port-only render box. A canvas child is a
`ChartHost` ([Chart.js ADR 0014](0014-input-events-and-chart-host.md) §2). The element gives the
host loose constraints whose max size is the content box, with `parentUsesSize: true`. Thus the
container size of the chart is the content box, as `getMaximumSize` reads it upstream
(`helpers.dom.ts:163-200`). The harness reads this CSS subset:

| Property | Effect |
|---|---|
| `width`, `height` (px) | The size of the content box. |
| no `width` | The content width of the parent. With `position: absolute` or the class `chartjs-wrapper`: the width of the content (shrink-to-fit). |
| no `height` | The height of the content. |
| `max-width`, `max-height` (px) | A cap of the content box. |
| `padding` (one px value) | The padding lies outside the content box (CSS `box-sizing: content-box`). |
| `display: none` | The element and its subtree get the size 0 (`SizedBox.shrink`, Chart.js ADR 0014 §4). The host stays mounted. |
| `direction: rtl` | A `Directionality` with `TextDirection.rtl`. |
| other properties and attributes | Kept. No effect on the layout. |

- The size of the content of a canvas child is the display size of the canvas (section 9).
- The class `chartjs-wrapper` has the effect of `injectWrapperCSS` (`src/index.js:37-48`): no
  padding and `position: absolute`. Thus the default wrapper is a box of the display size of the
  canvas ([canvas-cuts-plan.md](../canvas-cuts-plan.md) §3.7).
- A static block `div` without a `width` takes the content width of the body. With
  `max-width: 600px`, this gives the width 600 of `core.controller.tests.js:918`.

**DOM writes.** A write is a `style` write, `appendChild`, `removeChild`, `remove()` or
`setAttribute`.
- A write changes the element tree at once. It then calls `setState` on the body.
- A write during build, layout or paint waits. This covers the phases
  `SchedulerPhase.persistentCallbacks` and `midFrameMicrotasks`, and a forced layout of the
  harness (section 4). The harness applies the writes that wait in a post-frame callback in their
  order. It also schedules a frame. The reason is the throw of probe P12.
- Such a write occurs when the attach of a host calls a spec callback. Examples are
  `core.controller.tests.js:1007`, `:1054-1056` and `:1103-1105`.
- After the body unmounts, a write changes only the element tree. It does not attach the body
  again.

**Mutation checkpoint.** An `appendChild`, `removeChild` or `remove()` schedules one microtask
for all the writes of the current task:
1. The microtask does the forced build and layout of the harness body:
   `binding.buildOwner!.buildScope(binding.rootElement!)`, then
   `binding.rootPipelineOwner.flushLayout()`. It skips this step when no append or removal came
   after the last forced layout. The forced layout of `acquireChart` (section 4) counts.
2. Then it calls `flushCanvasMutations()` of `chart_host.dart` (section 10). That call reports the
   net attach state of each changed host at once.

Thus a detach and an attach reach the chart at the microtask checkpoint of the task, as the
`MutationObserver` records do (`platform.dom.js:129-159`). A `style` write alone waits for the
layout of the next frame. Upstream, a style change also reaches the `ResizeObserver` only in the
next HTML step "update the rendering". The post-frame connection check of the host stays as the
fallback.

### 4. `acquireChart` and the canvas

`acquireChart` is synchronous. It returns the chart:

```dart
/// index.js:22 `acquireChart(config, options)`.
Chart acquireChart([Map<String, Object?>? config, Map<String, Object?>? options]);

/// index.js:28 `releaseChart(chart)`.
void releaseChart(Chart chart);

/// index.js:54 `releaseCharts()`.
void releaseCharts();
```

- `config` and `options` are JS objects. Thus their Dart type is `Map<String, Object?>`
  ([Chart.js ADR 0006](0006-options-representation-and-resolver.md)).
- The registry `charts` (`src/index.js:9`) is a `Map<Object, Chart>` keyed by `chart.id`. The ids
  grow. Thus its insertion order is the order of `Object.keys` for the integer keys.
- `chart.$test` is an `Expando<Map<String, Object?>>` named `$test` in `utils.dart`.

`utils.acquireChart` (`src/utils.js:36-105`) is a line-by-line port with these hunks (row
`harness-acquire-chart`):
1. The wrapper and the canvas come from `document.createElement`. The canvas attributes go
   through `canvas.setAttribute`. The wrapper attributes go through `wrapper.setAttribute`.
2. After `document.body.appendChild(wrapper)` (`:73`), one added line does the forced build and
   layout of the harness body (section 3). It runs no frame callback and no paint. It is the
   counterpart of the layout that a browser forces when `getMaximumSize` reads the container.
   Thus `new Chart` (`:93`) finds the canvas in a laid-out host. The chart is attached at
   construction, as upstream (probe P1).
3. `useOffscreenCanvas: true` gives the chart the context of a second `UiCanvasElement`, made
   without `document`. No host shows it. Thus `detectPlatform` gives `BasicPlatform`, as
   `platform/index.js:7` does for an `OffscreenCanvas`.
4. `useShadowDOM: true` throws an `UnsupportedError`, in place of `pending()` (`:64-68`). Its 3
   spec cases skip as `'n/a: Flutter has no shadow DOM'`.
5. `spritingOn` (`:90-92`) and `spritingOff` (`:108`) have no port. The port has no image
   comparison ([Chart.js ADR 0009](0009-no-display-only-js-exactness.md)).

`acquireChart` throws a `StateError` when `binding.inTest` is false. It also throws a `StateError`
during build, layout or paint, because the forced layout cannot run there. It can run in a frame
callback (probe P11).

**Standby host.** `document.createElement('canvas')` gives a `UiCanvasElement` with a standby
host: a `RenderChartHost` that the harness creates and never attaches.
- Thus `new Chart(canvas, config)` gets `FlutterPlatform`. The chart starts detached, as upstream
  for a canvas outside the document (`core.controller.tests.js:981-1015`, probe F6).
- When a `ChartHost` of the body shows the canvas, it replaces the standby host as the parent
  node. Its first layout attaches the chart (Chart.js ADR 0014 §3).
- The harness disposes each standby host at the end of the test.

**Canvas attributes.** The canvas layer needs these changes in `UiCanvasElement`
([Chart.js ADR 0013](0013-canvas-model.md), section 2):
- `setAttribute('style', text)` replaces the inline style with the declarations of `text`.
  `getAttribute('style')` gives the text of the inline style. This is the DOM reflection of the
  `style` attribute. `src/utils.js:46-50` and `platform.dom.tests.js:336` call it.
- Another attribute name keeps its value as a string. `getAttribute` gives it back.
  `platform.dom.tests.js:10` sets `id`.
- `width` and `height` keep the attribute model of cut 2 ([canvas-cuts-plan.md](../canvas-cuts-plan.md)
  §3.3).

### 5. `waitForResize` and `afterEvent`

`core.controller.dart` declares `resize` and `eventHandler` as fields that hold a function. A
field initializer gives each field the tear-off of a private method with the upstream body:

```dart
/// core.controller.js:269 `resize(width, height)`. A test can replace the
/// function of one chart, as it replaces a JS own property (Chart.js ADR 0022).
// DIVERGES(chartjs): harness-method-fields, a test replaces it per chart.
late void Function([double? width, double? height]) resize = _resizeMethod;

/// core.controller.js:1163 `_eventHandler(e, replay)`.
// DIVERGES(chartjs): harness-method-fields, a test replaces it per chart.
@internal
// ignore: avoid_positional_boolean_parameters
late void Function(ChartEvent e, [bool? replay]) eventHandler =
    _eventHandlerMethod;
```

- A call `chart.resize()` keeps its upstream text. The Dart call of a field that holds a function
  has the form of a method call.
- `_eventHandler` drops its underscore, because chartjs-test-utils reads it
  (`src/utils.js:140-141`, [Chart.js ADR 0012](0012-dart-file-naming.md), Underscore members).
- Each call site in `core.controller.dart` calls the field: `:241`, `:531`, `:988`, `:1017` and
  `:1026`. Thus a replacement sees every call, as a JS own property does.
- `chart.runtimeType` stays `Chart`. Thus `core.controller.tests.js:11`
  (`expect(chart.constructor).toBe(Chart)`) keeps its expectation.
- `lib/src/types/index.dart` must not declare `resize` or `eventHandler` as a method, because a
  field cannot implement a method (probe J3). A function-typed getter is valid:
  `void Function([double? width, double? height]) get resize;`.

`utils.dart` ports `waitForResize` and `afterEvent` line by line, with no hunk:

```dart
/// utils.js:130 `waitForResize(chart, callback)`.
void waitForResize(Chart chart, void Function() callback) {
  final override = chart.resize;
  chart.resize = ([width, height]) {
    chart.resize = override;
    override(width, height);
    callback();
  };
}

/// utils.js:139 `afterEvent(chart, type, callback)`.
void afterEvent(Chart chart, String type, void Function() callback) {
  final override = chart.eventHandler;
  chart.eventHandler = (event, [replay]) {
    override(event);
    if (event.type == type || event.native?.type == type) {
      chart.eventHandler = override;
      callback();
    }
  };
}
```

`utils.dart` carries `// ignore_for_file: invalid_use_of_internal_member` below its header lines
(probe E4). The time order is the upstream order:
- The `waitForResize` callback runs synchronously, after the whole `resize` call. That call can
  include `_resize`, the plugin hook `resize`, `onResize` and the update.
- The `afterEvent` callback runs after the whole handler, also after `render()` (probes P4 and
  F8).
- A replay through the replacement has no `replay` argument, as `override.call(this, event)`
  upstream (probe F9).
- A callback that the attach of a host starts runs inside the forced layout of a mutation
  checkpoint, or inside the layout of a frame. Its DOM writes wait (section 3, probes P8 and F6).
- A callback that the throttled resize starts runs in the transient callbacks of a frame (probes
  F1 and F7).
- An `expect` works in both kinds of callback (probes J1 and F).

The spec `core.controller.tests.js:718-735` saves `chart.resize`, replaces it with a failure and
restores it. It keeps its upstream lines.

### 6. `triggerMouseEvent`

```dart
/// utils.js:163 `triggerMouseEvent(chart, type, el)`.
Future<NativeEvent> triggerMouseEvent(Chart chart, String type, [Object? el]);
```

- `_resolveElementPoint` (`:151-161`) is a line-by-line port. It keeps its underscore, because
  only `utils.dart` calls it. An element with `getCenterPoint` gives its center point. Another
  value gives `jsGet(el, 'x')` and `jsGet(el, 'y')` when both are not `undefined`. Else the point
  is (0, 0).
- The event is `NativeEvent(type: type, offsetX: point.x, offsetY: point.y, target: canvas)`.
  The DOM `offsetX` of the upstream event is `clientX - rect.left`. For a canvas without a border,
  that value is `point.x`.
- Chrome rounds `offsetX` and `offsetY` of a synthetic `MouseEvent` to integers (probes PP6 and
  SP1). `getRelativePosition` applies `jsRound` to the offsets
  ([Chart.js ADR 0014](0014-input-events-and-chart-host.md) §9). Thus the chart event gets the
  Chrome position. Only `event.native.offsetX` keeps the fraction.
- `dispatchCanvasEvent(canvas, event)` (`chart_host.dart`, Chart.js ADR 0014 §8) replaces
  `node.dispatchEvent(event)` (`:179`). It calls the listeners of the canvas directly, without a
  hit test and without the gesture arena, as the DOM call does. Thus the throttled proxy of
  `createProxyAndListen` gets the event.
- `afterEvent` is installed before the dispatch, as `:175-177` does.
- `await promise` (`:181`) becomes `await pumpFrames(() => resolved)` (section 7). One frame is
  enough (probes P4 and F8: 1 frame, 16 ms of fake time). The Future then completes with the
  event, as `:183` returns it.
- A type without a listener never resolves. `pumpFrames` then fails with the Jasmine timeout
  message, as upstream fails after 5 s.
- The row `harness-trigger-mouse-event` covers the event fields, the dispatch call and the pumps.

The Flutter input path (pointer events, `PointerDeviceKind`, the tap recognizer) stays covered by
`chart_host_test.dart` (Chart.js ADR 0014, Evidence).

### 7. Frames, time, harness tasks and `done`

`dom.dart` declares these port-only members:

```dart
/// One browser frame at 60 Hz, rounded down to whole ms.
const Duration frameInterval = Duration(milliseconds: 16);

/// The Jasmine default timeout (`jasmine.DEFAULT_TIMEOUT_INTERVAL`).
const Duration specTimeout = Duration(milliseconds: 5000);

/// `window.setTimeout(callback, delay)` of a spec: a harness task that is
/// due at `clock.now()` plus [delay] ms.
void setTimeout(void Function() callback, [int delay = 0]);

/// Pumps frames of [frameInterval] until [condition] holds. Runs the due
/// harness tasks between the pumps. Fails with the Jasmine timeout message
/// after [specTimeout].
Future<int> pumpFrames(bool Function() condition);

/// Runs [spec] with a Jasmine `done` callback. Then calls [pumpFrames] until
/// the spec calls `done`.
Future<void> waitForDone(void Function(void Function() done) spec);
```

`pumpFrames` repeats these steps:
1. It lets the microtasks of the test body run. Thus a mutation checkpoint of the body runs in
   the body zone.
2. It runs each due harness task: the earliest due time first, then the insertion order. The
   microtasks run before each task, as the microtask checkpoint of a browser task.
3. It returns when `condition` holds.
4. It fails with "Timeout - Async function did not complete within 5000ms" after `specTimeout`.
5. It calls `binding.pump(frameInterval)`. The pump advances the fake clock. It runs the frame
   callbacks, then the build, the layout and the paint. This is the order of the HTML event loop:
   `requestAnimationFrame` callbacks, then layout with `ResizeObserver`, then paint.

Rules:
- A harness task runs in the test-body zone, outside the guarded pump. Thus an `expect` in a task
  works (probes F3 and F10). An `expect` in a body `Timer` throws "Guarded function conflict."
  (probes J1 and F10). The upstream `setTimeout` callbacks with an `expect` are
  `core.animations.tests.js:87`, `:119`, `:124`, `:156` and `:167`, and
  `core.controller.tests.js:726`, `:1173`, `:1199` and `:1209`.
- A harness task is not a `Timer`. Thus flutter_test reports no pending `Timer` for it. The first
  task of a test registers an `addTearDown` that clears the queue. Thus a task never reaches the
  next test.
- A harness task is synchronous. A spec calls `triggerMouseEvent` and `waitForDone` only in the
  test body. No upstream `setTimeout` callback calls `triggerMouseEvent`.
- `jsDateNow` reads `clock.now()` ([Chart.js ADR 0010](0010-js-numeric-semantics.md)). Thus the
  animations advance by 16 ms in each pump.
- `waitForResize` does not pump. The pumps of `waitForDone` run its callback.
- Probe P10: a callback with a delay of 200 ms ran after 13 pumps, at 208 ms of fake time.

### 8. `releaseCharts`, the unmount and the built-in components

`flutter_test_config.dart` ports `test/index.js:34-36` with one hunk. The two lines follow
`setUpDefaultsRestore()` in the file:

```dart
// index.js:34-36 afterEach(function() { releaseCharts(); });
// DIVERGES(chartjs): harness-release-at-unmount, release before checks.
afterEachChart(releaseCharts);
tearDown(releaseCharts);
```

- `afterEachChart(callback)` (`dom.dart`) adds `callback` to a list. The `dispose` of the harness
  body calls each callback of the list.
- flutter_test disposes the body in the warm-up frame of its post-body `runApp`
  (`binding.dart:1959-1961`, `:2351-2359`). Thus `releaseCharts` runs inside the `FakeAsync`
  zone, before the `pump` of `:1962` and before the end-of-test assertions (probes P5 and F11).
- `tearDown(releaseCharts)` is the fallback. After a failed test, flutter_test keeps the tree
  (`:1955`). The fallback then releases the charts of that test. After a normal test, it finds
  only destroyed charts.
- The order is the upstream order:
  1. The inline `afterEach` function of the spec (section 2).
  2. `releaseCharts` at the unmount of the body.
  3. The end-of-test assertions of flutter_test.
  4. The `tearDown` functions of the spec groups.
  5. The `tearDown` functions of `flutter_test_config.dart` in reverse order: the fallback, then
     the restore of `harness-defaults-restore`.

  Thus the restore never runs before a chart is destroyed (probes P6 and F11).
- `releaseCharts` keeps the upstream registry: it never deletes a chart. Thus the unmount of each
  later test destroys the earlier charts of the file again, as upstream does after each spec.
  `destroy()` on a destroyed chart must not throw. Upstream skips the canvas part
  (`core.controller.js:944`).
- `persistent: true` keeps a chart out of `releaseCharts`, as `:57` does. Its host still unmounts
  with the tree. No spec uses it.
- `_releaseChart` removes the wrapper after `destroy()`, as `:111-114` does. After the unmount,
  that write changes only the element tree (section 3).
- A test that calls `tester.pumpWidget` replaces the body. The release runs at that time. The
  ported specs do not call `pumpWidget`.

**Built-in components and the registry.**
- The specs run on the UMD entry `src/index.umd.ts` (`karma.conf.cjs:110`). That entry registers
  the built-in components before the first spec: `Chart.register(controllers, scales, elements,
  plugins)` (`src/index.umd.ts:28`).
- `flutter_test_config.dart` makes the same call before `setUpDefaultsRestore()`:
  `Chart.register([controllers, scales, elements, plugins])`. The four Maps are the namespace Maps
  of [Chart.js ADR 0020](0020-registry-and-component-classes.md) §6. In phase 5, only `elements`
  has entries. Thus the snapshot of `harness-defaults-restore` holds the defaults of the ported
  components.
- The call is not a line of `test/index.js`. It carries
  `// DIVERGES(chartjs): harness-register-builtins, src/index.umd.ts:28.`
- The restore resets `defaults`, `overrides` and `descriptors`. It does not reset the `items` of
  `registry`. It does not reset the static properties that `jsAssign` writes on class values
  (Chart.js ADR 0020 §14). Upstream resets none of them.
- A component that several tests of a file need registers in the `main()` of the file. That call
  runs before the snapshot. A component of one test registers in the body of the test. The test
  unregisters it at its end, as `core.registry.tests.js` does.
- A spec that leaves a component registered keeps it in `items`, as upstream does. The restore
  removes its defaults after the test. Upstream keeps them. The ids of such components occur in one
  spec only (`core.scale.tests.js:522`, `:555`, `:585` and `core.plugin.tests.js:416-417`). Thus no
  later `register` finds a stale item.
- `dart test` does not read `flutter_test_config.dart`. Thus a pure-layer test file registers the
  components that it needs in its `main()`, through a new `TypedRegistry` (Chart.js ADR 0020 §5).

### 9. `toBeValidChart` and `toBeChartOfSize`

```dart
/// matchers.js:106 `toBeValidChart()`.
Matcher toBeValidChart();

/// matchers.js:131 `toBeChartOfSize()`. [expected] is the spec object with
/// the keys `dw`, `dh`, `rw` and `rh`.
Matcher toBeChartOfSize(Map<String, Object?> expected);
```

Both read only pure interfaces: `types.Chart` (`lib/src/types/index.dart`), `HTMLCanvasElement`,
`CanvasRenderingContext2D` and `CSSStyleDeclaration`. The row `harness-chart-matchers` covers
three hunks:
- `actual instanceof Chart` becomes `actual is types.Chart`. The two `toString` tags become
  `is HTMLCanvasElement` and `is CanvasRenderingContext2D`, as the row `platform-color-brand`
  does for the color brands.
- `window.devicePixelRatio` (`:142`) becomes `actual.platform.getDevicePixelRatio()`. The
  `actual.options.devicePixelRatio ||` part stays, with `jsTruthy`. For a chart on
  `FlutterPlatform`, the platform gives the device pixel ratio of the view of its host.
- `getComputedStyle(canvas)` (`:141`) becomes the display size rule of the harness:
  - A side with an inline px style has that value.
  - With one px style only, the other side keeps the aspect ratio of the render size. This is
    the CSS rule for a replaced element ([canvas-cuts-plan.md](../canvas-cuts-plan.md) §3.3).
  - Without a px style, a side has the render size.
  - A canvas with its own `display: none` and without a px style on a side gives `auto` for that
    side.
  - `parseInt(..., 10) || 0` truncates the value toward zero. `auto` gives 0.

The messages and their order are the upstream messages of `:111-121` and `:150-166`.
`matchers_test.dart` tests the matchers with a pure fake of `types.Chart`, also on dart2js and
dart2wasm. Its values come from Chrome (probe SP2):
- `width: 405px` on a 300 x 150 canvas gives `dh` 202 (202.5, truncated).
- `width: 425px` on a 400 x 410 canvas gives `dh` 435.
- `height: 401px` on a 400 x 200 canvas gives `dw` 802.
- `345.42px` gives 345.
- A canvas without a px style in a `display: none` subtree gives `auto`, thus 0. The matcher
  applies this value to a `display: none` of the canvas itself.

### 10. Host changes

The harness needs two port-only changes in `RenderChartHost` (`lib/src/platform/chart_host.dart`).
The file is port-only. Thus the changes get no `DIVERGES` marker.

**First notification at the next layout.** An observer that starts on a laid-out host gets its
first notification at the next layout of the host, not at once. This is the DOM rule: the first
notification comes in the HTML step "update the rendering" of the next frame.
- Outside a layout of the host, `_addResizeObserver` marks the host for layout. Inside a layout,
  it calls `markNeedsLayout` in a post-frame callback (`_scheduleRelayout`). It also schedules a
  frame.
- The next layout gives the pending observers the current size. A size change gives all
  observers the new size and clears the pending set.
- `ContainerResizeObserver.disconnect` removes the observer from the pending set. Thus a detach
  before the next layout gives no notification.
- A new host that replaces an old host as the parent node of the canvas also receives the
  pending set. Its first layout gives the size to the observers that it received. The observers
  that its attach report adds wait for its next layout.

**Mutation checkpoint.** `attach` and `detach` of a host add the host to a set of pending
connection checks. A new top-level function reports them:

```dart
/// The delivery of the MutationObserver records at a microtask checkpoint:
/// reports now the net attached state of each host with a pending
/// connection check.
void flushCanvasMutations();
```

The post-frame callback of Chart.js ADR 0014 §4 stays. After a checkpoint, it finds no change.
Only the harness calls `flushCanvasMutations`.

The spec shapes of the Context section ("Gaps of the current host") then give the upstream
results (probes P2, P3, PP7 and F1 to F7). One host test needs a second pump: "a later resize
with the container height keeps the ratio" (probes E3, PP9 and F). The DOM also gives that
resize in the second animation frame. The `ResizeObserver` callback runs in frame 1. Its
`throttled` call then runs in frame 2 (`platform.dom.js:197-224`).

[Chart.js ADR 0014](0014-input-events-and-chart-host.md) is proposed. Its owner edits the third
bullet of §3: the second resize of a responsive chart comes two frames after an attach outside a
frame. The owner also adds the checkpoint to §4.
[Chart.js ADR 0016](0016-frame-scheduling.md) is proposed too. Decision 9 of it states that the
first layout gives the resize observers the first size ("Later size and DPR changes"). The first
notification at the next layout changes that sentence. The checkpoint adds a harness-only report
beside the post-frame callback of "Later attach and detach". The owner of Chart.js ADR 0016 edits
decision 9, or a successor ADR states it again.
[canvas-cuts-plan.md](../canvas-cuts-plan.md) cites `chart_host.dart` and `chart_host_test.dart`.
The same commit updates the plan ([porting-flow.md](../porting-flow.md) §5.1).

### 11. Rows, tests and parity

`differences.md` gets seven `harness` rows:

| Row | Dart file and symbol | Upstream |
|---|---|---|
| `harness-method-fields` | `lib/src/core/core.controller.dart` `resize`, `eventHandler` | `src/core/core.controller.js`@v4.5.1:269-275, 1163-1186 |
| `harness-acquire-chart` | `packages/chartjs_test_utils/lib/src/utils.dart` `acquireChart`, `releaseChart` | chartjs-test-utils `src/utils.js`@v0.4.0:36-115 |
| `harness-trigger-mouse-event` | `packages/chartjs_test_utils/lib/src/utils.dart` `triggerMouseEvent` | chartjs-test-utils `src/utils.js`@v0.4.0:163-184 |
| `harness-release-at-unmount` | `test/flutter_test_config.dart` `testExecutable` | `test/index.js`@v4.5.1:34-36 |
| `harness-register-builtins` | `test/flutter_test_config.dart` `testExecutable` | `src/index.umd.ts`@v4.5.1:28, `karma.conf.cjs`@v4.5.1:110 |
| `harness-chart-matchers` | `packages/chartjs_test_utils/lib/src/matchers.dart` `toBeValidChart`, `toBeChartOfSize` | chartjs-test-utils `src/matchers.js`@v0.4.0:106-174 |
| `harness-index-pure-split` | `packages/chartjs_test_utils/lib/src/context.dart` `createMockContext` | chartjs-test-utils `src/index.js`@v0.4.0:33-35 |

On a bump of Chart.js or of chartjs-test-utils, compare the cited lines. Tests that pin the rows
and the host changes:
- `packages/chartjs_test_utils/test/utils_test.dart` (`@TestOn('vm')`):
  - Group `harness-acquire-chart`:
    - the 512 x 512 canvas through attributes
    - the defaults of `animation`, `responsive` and `locale`
    - `FlutterPlatform` and the attach at construction
    - `useOffscreenCanvas`
    - the removal of the wrapper after a throw
    - the standby host
  - Group `harness-trigger-mouse-event`: 1 frame, the event order, the custom types `test` and
    `test2`, a `mouseout` inside the chart, and the Chrome positions of probe SP1.
  - The time order of `waitForResize` and `afterEvent`, with the dropped `replay` (probe F9).
  - The harness tasks: the order, the microtasks before each task, an `expect` in a task, and the
    timeout message.
  - The DOM stand-in: each line of the CSS table, `clientWidth` and `clientHeight` with
    `display: none`, `getElementById`, the writes that wait, and the mutation checkpoint.
  - The spec-port matrix of the host changes: `core.controller.tests.js:657`, `:697`, `:1065`,
    `:1116`, `:1147`, `:1179` and `:1218`. `:1065` also expects the attach calls
    `[attached, detached, attached]` and the update modes `default`, `attach` and `resize`.
- `packages/chartjs_test_utils/test/matchers_test.dart`, group `harness-chart-matchers`, with the
  values of section 9.
- `packages/chartjs_test_utils/test/context_test.dart`, group `harness-index-pure-split`.
- `packages/flutter_chartjs/test/port/core/core.controller_test.dart`, group
  `harness-method-fields`. A replacement of `chart.resize` sees the calls of `_initialize`, the
  attach listener, the resize listener and the spec. The restore gives the method again.
- `packages/flutter_chartjs/test/port/flutter_test_config_test.dart`, group
  `harness-release-at-unmount`. A chart with an animation that runs at the end of the body passes
  the end-of-test assertions (probe P5). The release runs before the `tearDown` functions (probe
  P6). `releaseCharts` on released charts calls `destroy()` again without a throw.
- The same file, group `harness-register-builtins`. Each test finds the ported built-in components
  in `registry` and their entries in `defaults`. A default that a test writes is gone in the next
  test. A component that a test leaves registered stays in `items`.
- `packages/flutter_chartjs/test/port/platform/chart_host_test.dart`: the first notification at
  the next layout, a `disconnect()` before it, a new host with a pending observer, and
  `flushCanvasMutations` with a net detach.

`parity.md` updates the rows of `src/utils.js`, `src/index.js` and `src/matchers.js` of
chartjs-test-utils, and of `chart_host.dart` and `canvas_ui.dart`. It lists `dom.dart` as
port-only.

### 12. What this ADR needs from the parallel ADRs and ports

The decisions above stay valid for any form of these ADRs and ports that gives these items:
- **The port of `core.controller.js`** (phase 5, no ADR of its own).
  - A Dart class `Chart` with the constructor `Chart(Object? item, Object? config)`, the members
    `id` and `destroy()`, and instance fields.
  - `acquireChart` constructs `Chart` itself, not a subclass.
  - `destroy()` on a destroyed chart does not throw, as upstream.
  - `types.Chart` keeps `platform` and `options` for the matchers. `lib/src/types/index.dart`
    declares both now.
- **[Chart.js ADR 0020](0020-registry-and-component-classes.md).**
  - Chart.js ADR 0020 §6 sets only the statics of `Chart`. No static of `Chart` has the name
    `resize` or `eventHandler`. Thus the fields of section 5 give no name conflict.
  - Chart.js ADR 0020 §14 adds no `resize` and no `eventHandler` to `types.Chart`. A later change
    that adds them uses a function-typed getter (section 5). `index.d.ts:524` declares `resize` in
    the class `Chart`.
  - Chart.js ADR 0020 §6 gives the namespace Maps `controllers`, `elements`, `plugins` and `scales`
    for the registration of section 8.
- **[Chart.js ADR 0021](0021-typed-options-in-the-resolver.md).** Nothing. It changes only the
  element options. The user config stays a `Map<String, Object?>` before construction. The
  resolver of `chart.options` gives `devicePixelRatio` through the `Map` protocol
  ([Chart.js ADR 0006](0006-options-representation-and-resolver.md)).
- **[Chart.js ADR 0019](0019-animation.md).** `destroy()` removes the chart from the animator
  (`core.controller.js:941`, `:930`). The animator loop then ends in the next frame
  (`core.animator.js:104-106`), within the `pump` of `binding.dart:1962`. The animator runs on
  `requestAnimFrame` and reads `jsDateNow()` ([Chart.js ADR 0016](0016-frame-scheduling.md),
  decision 6). Chart.js ADR 0019 §12 ports `setTimeout` and `done` of the animation specs with
  the harness tasks and `waitForDone` of section 7.

## Alternatives considered

Each option has a score in the order of [porting-flow.md](../porting-flow.md) §1.1: behavior,
performance, structure, code.

**The three drafts.** A panel wrote three drafts. A judge scored them (0 to 10, higher is
better):

| Draft | Behavior | Performance | Structure | Less code |
|---|---:|---:|---:|---:|
| Fidelity (chosen, with grafts) | 8 | 9 | 8 | 4 |
| Performance | 7 | 10 | 6 | 5 |
| Simplicity | 4 | 10 | 5 | 9 |

- **Fidelity** keeps the upstream callback time of `waitForResize` and `afterEvent`. It keeps the
  spec text at nearly all call sites, also the 13 `new Chart` sites and `:719`. Its host change
  passes the same-task wrapper writes (probes P2 and J2). Its release at the unmount passes the
  end-of-test assertions. This ADR fixes its defects with grafts from the other drafts: the
  harness tasks, the mutation checkpoint, `override(event)` and the getter rule for
  `types.Chart`.
- **Performance** runs the `waitForResize` callbacks as harness tasks after the frame. This needs
  a `DIVERGES` row. Its reason was that an `expect` fails in a callback that a pump runs. Probe
  J1 shows that this is false for frame and post-frame callbacks, where resize callbacks run. Its
  `HarnessChart` subclass breaks `core.controller.tests.js:11`. Its `tearDown` release runs after
  the end-of-test assertions. Its wrapper rule "no width gives the canvas display size" gives a
  wrong width for `:918`. Its performance gain is test-suite time only.
- **Simplicity** keeps the current host. On the upstream shape of `:657`, a judge run of its
  prototype gave the widths 300 and 455. Upstream gives 455 and 150. `:1147` gave 1 `resize()`
  call. Upstream gives 0 (probe J2). It rewrites the 32 nested `waitForResize` calls and the 31
  `done` specs into sequential `await`s. It counts `resize()` calls in place of
  `chart.resize = fail`.

**`acquireChart`:**
- **An async `acquireChart` with `tester.pumpWidget`.** Behavior: the pump runs the frame
  callbacks of the earlier charts before the new chart exists. Upstream runs no frame during
  `acquireChart`. Structure: 547 call sites get an `await`. Rejected.
- **No host for a chart that is not responsive.** Behavior: `BasicPlatform` sets
  `animation: false` and gives a device pixel ratio of 1. The Retina specs then give 320 x 240 in
  place of 960 x 720. The spec "should use the DomPlatform by default" also fails. Rejected.
- **The chart before the first layout of its host.** Behavior: the chart starts detached. It
  calls `_resize(0, 0)` and later gets an `'attach'` update. The hook order of
  `core.controller.tests.js:1816` changes. Rejected.
- **A `WidgetTester` argument.** The forced layout needs only the binding. Structure: 547 call
  sites change. Rejected.
- **Plain `test()` cases for the 422 of 514 chart cases that reach no frame** (draft Performance).
  Behavior: the frame callbacks of a plain test run in the next `testWidgets` test, before its
  body ([Chart.js ADR 0016](0016-frame-scheduling.md), Context). Performance: the gain is test
  time only, about 1 s for each run (probe PP1). The product frame, draw and raster times do not
  change. Structure: two spec forms. Code: a second mode of the harness. Rejected.

**The monkey patches:**
- **A harness subclass of `Chart` that `acquireChart` constructs.** Behavior: the 13 `new Chart`
  sites (6 `waitForResize` calls) get no hook. `chart.constructor === Chart`
  (`core.controller.tests.js:11`) fails. The patch of `:719` needs another hook. Structure: spec
  lines change. A subclass in another package cannot override a private `_eventHandler`.
  Rejected.
- **Port-only callback hooks in `core.controller`.** Structure: the same number of hunks as the
  method fields, and a harness that does not translate `src/utils.js:130-149`. The spec `:719`
  needs a second hook. Rejected.
- **Plugin hooks `resize` and `afterEvent`.** Behavior: the hook `resize` runs only when
  `retinaScale` reports a change (`core.controller.js:288-292`). The first notification of an
  unchanged size never reaches it (`core.controller.tests.js:1116`, `:1218`). The hook
  `afterEvent` runs before `render()` (`core.controller.js:1179-1183`). It does not run when
  `beforeEvent` returns `false` (`:1172-1174`). A harness plugin also changes the plugin lists
  of `core.plugin.tests.js`. Rejected.
- **A second throttled canvas listener for `afterEvent`.** Behavior: equal for the specs. It
  misses the replay of `update()` (`:531`). Structure: one more hunk. The field of `resize` is
  still necessary. Rejected.
- **`override(event, replay)` in `afterEvent`** (the first form of draft Fidelity). Behavior: a
  replay through the replacement reaches `_handleEvent` with `replay: true`. Upstream gives
  `undefined` there (`src/utils.js:142`). Structure: a hunk without a reason. Rejected.
- **Performance of the method fields.** A call through the field costs 1.0 to 1.2 ns more on AOT
  (probe B1). On dart2wasm, the difference is not measurable. The throttle gives at most one
  `eventHandler` call for each event type in a frame. `resize` runs only on a resize. The cost is
  below 1e-6 of a 16.7 ms frame. The other forms add nothing to the product. This tie does not
  outweigh the behavior and structure lead.

**`setTimeout`:**
- **A `dart:async` `Timer`** (the first form of draft Fidelity). Behavior: an `expect` in the
  callback throws "Guarded function conflict." (probes J1 and F10). Rejected.
- **`await tester.pump(Duration(milliseconds: ms))`, then the callback code** (draft Simplicity).
  Structure: nested callbacks become sequential code. Rejected.
- **A harness task on `clock.now()`** (draft Performance). Chosen.

**The detach and attach report:**
- **No mutation checkpoint** (the first form of draft Fidelity). Behavior: in `:1065`, the
  `setTimeout` callback runs before the frame. The removal and the append then fall into one
  build. No detach and no attach reach the chart. The update modes are `default`, `resize`,
  `resize` (probes PP7 and F2b). The size expectations still pass. Rejected.
- **A checkpoint on each mutation and each style write.** Behavior: equal for the specs. A style
  change then resizes one frame earlier than upstream (probes PP7 and F1b). Rejected.
- **A checkpoint on each append and removal.** Behavior: `:1065` gives the upstream attach calls
  and update modes (probes PP7 and F2). Chosen.

**`triggerMouseEvent`:**
- **Real pointer events through `GestureBinding` with a mouse `PointerDeviceKind`.** Behavior: a
  `mouseout` comes from an exit outside the box (probe PP8: x = 500 for a box of 400). Upstream
  gives it the point of the spec (20 calls). The legend reads the position of a `mouseout`
  (`plugin.legend.js:535-537`). Flutter has no pointer event for the types `test` and `test2`. A
  `click` needs a down, an up and the arena. A real tap also gives `pointerup` (probe SP3).
  Rejected.
- **A direct call of the chart listener.** Behavior: it skips the throttle and the guard of
  `platform.dom.js:246`. The event then runs at once, not in the next frame. Rejected.
- **A `StateError` for a type without a listener** (drafts Performance and Simplicity). Behavior:
  the spec fails in both forms. Structure: the timeout keeps the upstream path. Rejected.

**`releaseCharts`:**
- **`tearDown(releaseCharts)` only.** Behavior: probe P9 fails with "An animation is still running
  even after the widget tree was disposed." `plugin.tooltip.tests.js:1158-1226` ends with a pie
  chart animation that runs. A pending `resizeDelay` timer fails "A Timer is still pending" (probe
  SP5). The unmount also detaches a responsive chart before its `destroy()`. Rejected.
- **A harness test function or a `TestVariant` with the release.** Behavior: equal. Structure:
  every chart spec changes its `testWidgets` call or adds `variant:`. Rejected.
- **Delete each released chart from the registry** (drafts Performance and Simplicity). Behavior:
  no spec result changes. Performance: test time only. Structure: it does not translate
  `src/index.js:54-61`. It needs a `DIVERGES` row. Rejected.

**`done`:**
- **`pumpAndSettle`.** Behavior: it stops when no frame is scheduled. It does not wait for a
  harness task or a `Timer` ([Chart.js ADR 0016](0016-frame-scheduling.md)). Rejected.
- **Pumps of `Duration.zero`.** Behavior: the fake clock does not advance. The tasks and the
  animations stop. Rejected.

**The split:**
- **The registry functions in `utils.dart`, `index.dart` pure** (drafts Performance and
  Simplicity). Structure: about 25 lines of `src/index.js` move, in place of 3 lines. Rejected.
- **The chart matchers in a non-pure file.** Structure: the file is not the mapped path of
  `src/matchers.js`. Thus `check:headers` fails. Rejected.
- **`toBeChartOfSize` with named arguments** (draft Simplicity). Structure: the spec object is a
  JS object, thus a `Map` ([Chart.js ADR 0006](0006-options-representation-and-resolver.md)).
  Rejected.

## Consequences

- Every spec case that creates a chart runs on the VM only (`@TestOn('vm')`).
- `acquireChart` keeps its upstream call form at all 547 call sites. The 13 `new Chart` sites keep
  their arguments. The 32 `waitForResize` calls and the replacement of `:719` keep their text.
- `core.controller.dart` has two `DIVERGES` markers for the method fields. `chart.resize` is a
  public mutable field. User code can replace it, as JavaScript allows. A Dart subclass of
  `Chart` cannot declare a method `resize` (probe J3). It can override the field.
- The public `eventHandler` with an optional `bool` parameter needs
  `// ignore: avoid_positional_boolean_parameters` (probe E4).
- A chart that a spec creates with `Chart(...)` on a canvas that the same task appended starts
  detached. The mutation checkpoint attaches it. Upstream attaches it at construction. The cases
  are `platform.dom.tests.js:48`, `:60`, `:71`, `:304` and `:342`. Their expectations do not
  depend on it. `:342` gets its 475 x 450 through the attach resize.
- Frame counts differ from upstream in two places. No spec counts frames:
  - A forced layout of a checkpoint delivers a pending first notification. Thus the resize of
    `:1116` runs in frame 1. Upstream runs it in frame 2 (probe F5). The skip of step 1 of the
    checkpoint keeps the upstream frames for `:657` (probes F1 and F1b).
  - An observer that an attach inside a layout adds waits for a post-frame relayout. Thus its
    first resize can come one frame later than upstream.
- The continuation after `await triggerMouseEvent` runs after the whole frame. Upstream runs it
  after the callback of the proxy, before the later callbacks of the frame. A callback that the
  event handler schedules runs in the next frame in both.
- The warm-up frame after the body runs its transient callbacks first. A pending throttled resize
  or animator frame then runs on a live chart. Then the build disposes the body and releases the
  chart. Upstream releases first. No spec found reads the difference.
- The unmount of each test destroys the charts of the earlier tests of the file again. A file
  with N charts makes about N²/2 `destroy()` calls. The `beforeDestroy` and `afterDestroy` hooks
  of earlier charts run again, as upstream. `core.controller.tests.js` has 75 `acquireChart`
  calls.
- A pending harness task does not survive its test. Upstream lets a `setTimeout` callback run
  after its spec. No spec depends on it.
- `chart_host.dart`, `chart_host_test.dart` and `canvas_ui.dart` change.
  [canvas-cuts-plan.md](../canvas-cuts-plan.md) cites these files. The same commit updates the
  plan (porting-flow.md §5.1).
- `test:cases` reports the 3 `useShadowDOM` cases as `'n/a: Flutter has no shadow DOM'`.
- Each phase that ports a built-in component adds it to the namespace Map of Chart.js ADR 0020 §6.
  The registration of section 8 then gives it to every test file of `flutter_chartjs`.
- A test file registers its own components in its `main()`, or registers and unregisters them in
  one test (section 8).

## Open

- **The owners of Chart.js ADRs 0014 and 0016** accept or reject the two host changes of section
  10. The owner of Chart.js ADR 0013 accepts or rejects the `style` reflection and the string
  attributes of section 4.
- **The auto height of a block wrapper.** `core.controller.tests.js:918` has
  `display: none; max-width: 600px; max-height: 400px` and `maintainAspectRatio: false`. It
  expects 600 x 300. No draft built a prototype of this CSS subset. A Chrome probe must give the
  rule before the spec runs.
- **A hidden ancestor in `toBeChartOfSize`.** The pure matcher does not see a `display: none` on
  an element that contains the canvas. Chrome then gives `auto` for a side without a px style
  (probe SP2). No spec found needs it.
- **The body width.** The port uses the width of the test view (800). Upstream uses the width of
  the Karma frame. `karma.conf.cjs` does not set it. Only the static block wrapper of `:918`
  reads it, through its `max-width`.
- **`spyOn(chart, 'update')`** (`global.defaults.tests.js:110`, `:186`). The spy design is outside
  this ADR. The method field form can extend to `update`.
- **`chart.canvas.id`** in the error of `core.controller.js:127-131`. `HTMLCanvasElement` has no
  `id` getter in the port. `core.controller.tests.js:35` reads it. The string attribute of
  section 4 can give it.
- **The fixtures of phase 7.** `fixture.dart` imports `utils.dart` with the prefix `utils`. It
  calls `utils.acquireChart` and `utils.releaseChart` (`fixture.js:1`, `:50`, `:59`). The `run`
  hook of a fixture calls `triggerMouseEvent` (5 calls). Phase 7 decides the rest.
- **The frame interval** of 16 ms against 16.67 ms. No spec found depends on the difference.
- **A name conflict** of `window` or `document` with another library that a spec imports. A spec
  can hide the other name.

## Evidence

All probe files are in the session scratchpad
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/42473ad1-0196-429c-8b17-c32d881d14b9/scratchpad/design/harness/`
(below: `<harness>`). The Flutter probes ran on Flutter 3.44.9 and Dart 3.12.2 on macOS (Apple
silicon), in copies of `packages/flutter_chartjs` and `packages/chartjs_test_utils` at commit
`69f9d97`.

- **E1, call sites.** `<harness>/fidelity/count/count_sites.mjs` and `count_it.mjs` tokenize the
  specs with `tool/upstream_manifest/src/js_tokens.mjs`. The output is
  `<harness>/fidelity/count/counts.json`. A `grep -F` count on 2026-10-19 gave the same figures
  for `acquireChart(` (547), `new Chart(` (13), `waitForResize(` (32), `triggerMouseEvent(` (104),
  `canvas.parentNode` (21), `setTimeout(` (10), `done` callbacks (31) and `async` `it` lines (67).
  The drafts Performance and Simplicity gave the same option counts.
- **P, the prototype of draft Fidelity.** `<harness>/fidelity/proto/repo`, probe files in
  `packages/flutter_chartjs/test/port/proto/` (`proto_chart.dart`, `proto_harness.dart`,
  `harness_proto_test.dart`, `teardown_release_probe_test.dart`, `phase_probe_test.dart`).
  Outputs: `<harness>/fidelity/proto/out_current_host.txt`, `out_patched_host.txt` and
  `out_p9_p11_p12.txt`.
  - P1: the synchronous acquire ran 0 frames. The chart had `FlutterPlatform`, was attached at
    construction and had 300 x 350. With the host change, the first notification resize came
    after the second pump.
  - P2: `waitForResize` with a wrapper write in the same task. Current host: callbacks at the
    widths 300 and 150. Changed host: 455 and 150, as upstream.
  - P3: a removal, an append and a removal in one task. Current host: the `waitForResize`
    callback ran. Changed host: it did not run, as upstream. `attached` was false.
  - P4: `triggerMouseEvent` resolved after 1 pump (16 ms). The log was `dispatched >
    _eventHandler(mousemove) > render > afterEvent callback`. A custom type `test` also resolved.
  - P5: a chart with an animation loop at the end of the body passed with the release at the
    unmount.
  - P6: the log at `addTearDown` was `body.dispose > destroy`. The `tearDown` declared second ran
    first.
  - P8: a canvas in a standby host gave `FlutterPlatform` and started detached. The first
    callback ran in `persistentCallbacks`. One DOM write waited for the post-frame callback.
  - P9: a `tearDown` release with an animation loop failed with "An animation is still running
    even after the widget tree was disposed."
  - P10: a callback with a delay of 200 ms ran after 13 pumps, at 208 ms of fake time.
  - P11: `acquireChart` inside a frame callback gave an attached 200 x 100 chart.
  - P12: `setState` in the first layout of a host threw "Build scheduled during frame.".
- **E3, the host change of draft Fidelity.** `<harness>/fidelity/proto/host_patch_a.diff`. With
  it, 71 of the 72 tests of `test/port/platform/` passed
  (`<harness>/fidelity/proto/out_host_tests_patched.txt`). The test "a later resize with the
  container height keeps the ratio" needs a second `pump`.
- **E4, analyzer.** `<harness>/fidelity/proto/repo/packages/flutter_chartjs/lib/src/probe_internal.dart`
  and `packages/chartjs_test_utils/lib/src/probe_use.dart`. A replacement of an `@internal` field
  from the harness package gave 3 `invalid_use_of_internal_member` warnings. The field type with
  `[bool? replay]` gave `avoid_positional_boolean_parameters`.
- **B1, method field cost.** `<harness>/fidelity/bench/method_field_bench.dart`, 5e7 iterations
  of two calls in three rounds (`<harness>/fidelity/bench/results.txt`).
  - AOT (`dart compile exe`, macOS arm64): method 2.70 to 2.81 ns, field 3.79 to 3.84 ns, a
    difference of 1.03 to 1.13 ns for each call.
  - A re-run on 2026-10-19 gave 1.00 to 1.18 ns. The judge re-run gave 1.07 to 1.19 ns.
  - dart2wasm (`dart compile wasm`, Node.js 24.12.0, `run_wasm.mjs`): -0.21 to +0.04 ns, not
    measurable.
- **J1, guarded calls (judge).** `<harness>/judge/proto/test/j1_guard_test.dart`, output
  `<harness>/judge/j1_j2.out`. An `expect` in a `Timer` from the body, fired by `binding.pump`,
  threw "Guarded function conflict.". An `expect` in a frame callback, a post-frame callback, a
  microtask from a frame callback and a `Timer` from a frame callback worked. `expectSync` in a
  body `Timer` worked.
- **J2, the current host on the upstream shapes (judge).**
  `<harness>/judge/proto/test/j2_simplicity_658_test.dart`, output `<harness>/judge/j1_j2.out`.
  `:657`: the waits returned at the widths 300 and 455 (upstream 455 and 150). `:1147`: 1
  `resize()` call (upstream 0), `attached` false.
- **J3, field against method (judge).** `<harness>/judge/dart_field/field_vs_method.dart`,
  output `<harness>/final/out_field_vs_method.txt`. A field that implements an interface method
  gave `conflicting_field_and_method`. A subclass method over a field gave
  `conflicting_method_and_field`. A field that implements a function-typed getter compiled.
- **PP, the probes of draft Performance.** Under `<harness>/performance/`.
  - PP1 (`proto/p1_*_test.dart`, `proto/p1_summary.py`): the mean time of one `test()` case was
    1.26 to 1.67 ms. The mean time of one `testWidgets` case with a synchronous acquire was 3.27 to
    4.64 ms.
  - PP5 (`proto/teardown_order_test.dart`): the group `tearDown` ran first, then the top-level
    ones in reverse order. A chain of frame callbacks at the end of a body failed with "An
    animation is still running even after the widget tree was disposed."
  - PP6 (`chrome/mouse_event.html`, headless Chrome 155.0.8059.80): `clientX` is truncated and
    `offsetX` is rounded. The point (150.6, 20.4) gave `offsetX` 151 and `offsetY` 20. (255.5,
    255.5) gave 256 and 256. (99.99, 0.01) gave 100 and 0.
  - PP7 (`proto/detach_test.dart`, `proto/more_specs_test.dart`, `proto/harness_proto.dart`): the
    ports of `:657`, `:697`, `:1065`, `:1116`, `:1147`, `:1179` and `:1218` against 9 forms of
    the host and the checkpoint. The current host failed `:657`, `:1065` and `:1147`. The first
    notification at the next layout with a checkpoint on each append and removal passed all of
    them. Without a checkpoint, `:1065` gave the attach calls `[attached]` and the modes
    `default`, `resize`, `resize`. With it, `[attached, detached, attached]` and `default`,
    `attach`, `resize`. A checkpoint on each style write resized `:657` in frames 1 and 2, in
    place of 2 and 4.
  - PP8 (`proto/timing_test.dart`, `proto/timing.out`): a responsive chart was attached at
    construction with 300 x 350. Its first observer resize ran in frame 2. A real mouse gave a
    `mouseout` at x = 500 for a box of 400. A direct dispatch kept the given point. The binding
    pumped without a `WidgetTester`.
  - PP9 (`snap/packages/flutter_chartjs/test/port/platform/`): with the first notification at the
    next layout, 32 of 33 host tests passed. "a later resize with the container height keeps the
    ratio" gave 400 x 200 after one pump and 200 x 100 after two pumps.
- **SP, the probes of draft Simplicity.** Under `<harness>/simplicity/`.
  - SP1 (`probe_mouse/probe.html`, headless Chrome 155): `rect.left` was 8. The points (100,
    50), (100.2, 50.2), (100.5, 50.5), (100.7, 50.7), (30.4999, 0.6) and (255.75, 128.25) gave
    the offsets (100, 50), (100, 50), (101, 51), (101, 51), (30, 1) and (256, 128). `jsRound` of
    each point gives the same values.
  - SP2 (`probe_style/probe.html`): no style on 300 x 150 gave 300 x 150. `width: 620px` gave
    620 x 310. `width: 405px` gave 405 x 202.5. `width: 425px` on 400 x 410 gave 435.625.
    `height: 401px` gave a width of 802. `345.42px` gave `345.406px`. A block canvas of 512 x 512
    in the default wrapper gave a wrapper of 512 x 512. A canvas without a px style inside
    `display: none` gave `auto`.
  - SP3 (`proto/test/harness_proto_test.dart` and others, 13 tests): a real mouse tap gave
    `pointerdown` and `pointerup`. A direct `pointerdown` gave one event.
  - SP4 (`proto/test/harness_proto2_test.dart`): a chart from `setUp` had a `null` canvas in the
    body.
  - SP5 (`proto/test/harness_proto5_test.dart`): with the release in `dispose`, a frame loop and
    a 50 ms `Timer` at the end of the body passed. With a `tearDown` release only, the loop failed
    with "An animation is still running even after the widget tree was disposed." The `Timer`
    failed with "A Timer is still pending even after the widget tree was disposed."
  - SP6 (`proto/test/harness_proto6_test.dart`): on the current host, `:1147` got 1 `resize()`
    call.
- **F, the prototype of this decision.** `<harness>/final/repo` is a copy of the Fidelity
  prototype. The host `packages/flutter_chartjs/lib/src/platform/chart_host.dart` has the two
  changes of section 10 (`<harness>/final/host_patch.diff`, against
  `<harness>/fidelity/proto/chart_host.head.dart`). The harness is
  `packages/flutter_chartjs/test/port/proto2/proto2_harness.dart`. It has the body, the forced
  layout, the writes that wait and the mutation checkpoint. It also has the method fields,
  `afterEvent` with `override(event)`, the harness tasks and `waitForDone`. The chart
  `proto2_chart.dart` is a copy of `FakeChart` with the method fields, an attach log, the update
  modes and the replay of `core.controller.js:529-534`. The probes are `proto2_test.dart`. The
  output is `<harness>/final/out_proto2.txt`. All 14 tests passed. `proto2_harness_v1.dart.txt` is
  the harness without the skip of the checkpoint step 1.
  - F1 (`:657`): the callbacks saw 455 x 350 and 150 x 350. They ran in frames 2 and 3. The
    order of the HTML event loop gives the same frames upstream. The `ResizeObserver` callback
    runs in frame N. The `throttled` call runs in frame N + 1.
  - F1b (`:657` with a forced layout at every checkpoint): the same sizes in frames 1 and 2.
  - F2 (`:1065`): 320 x 350, 320 x 355 and 455 x 355. The attach calls were
    `[attached, detached, attached]`. The update modes were `default`, `attach` and `resize`. 3
    DOM writes waited.
  - F2b (`:1065` without the checkpoint): the same sizes, the attach calls `[attached]` and the
    modes `default`, `resize`, `resize`.
  - F3 (`:1147`): no callback, 0 `resize()` calls after the acquire, `attached` false. The
    `expect` in the `setTimeout` task of 100 ms passed.
  - F4 (`:1179`): `attached` was false in both tasks. No callback ran.
  - F5 (`:1116`): one callback at 320 x 350 after 1 pump. The attach calls were `[attached]`.
  - F6 (`:981`): `FlutterPlatform`, detached at 0 x 0 before the append. The callback ran at
    455 x 355 in the mutation checkpoint (`SchedulerPhase.idle`), before any pump.
  - F7 (`:1017`): the callbacks saw 455 x 355 and 640 x 480 after 2 pumps.
  - F8: `triggerMouseEvent` resolved after 16 ms of fake time. The log was `dispatched >
    _eventHandler(mousemove) > render > afterEvent callback`.
  - F9: a replay without the replacement had `replay` true. A replay through the replacement had
    `replay` null.
  - F10: an `expect` in a harness task passed. An `expect` in a body `Timer` threw "Guarded
    function conflict.".
  - F11: a chart with an animation loop and a harness task of 10 s at the end of the body passed.
    The log at `addTearDown` ended with `destroy`.
  - F12: a `removeChild` in a callback in `transientCallbacks` ran its checkpoint in the same
    frame, with no assertion. The attach calls were `[attached, detached]`.
  - The callbacks ran in `transientCallbacks` and in `idle` (the checkpoint). No `expect` in a
    callback threw.
  - The platform tests of the copy: 71 of 72 passed. "a later resize with the container height
    keeps the ratio" failed, as in E3 (`<harness>/final/out_platform_tests.txt`).
- **Upstream sources read.** chartjs-test-utils v0.4.0 `src/utils.js:1-184`, `src/index.js:1-61`,
  `src/matchers.js:100-180` and `src/fixture.js:1`, `:45-62`. Chart.js v4.5.1 `test/index.js:1-36`,
  `src/core/core.controller.js:51-64`, `:120-310`, `:515-540`, `:683-706`, `:930-1060` and
  `:1155-1235`, `src/core/core.animator.js:36-56`, `:95-110` and `:195-214`,
  `src/platform/platform.dom.js:120-260`, `src/platform/platform.basic.js:10-23`,
  `src/platform/platform.base.js:48-50` and `:72-74`, `src/platform/index.js:1-13`,
  `src/types/index.d.ts:494` and `:524`, and the spec and fixture lines that this ADR cites.
- **flutter_test sources read.** `widget_tester.dart:180-200`, and `binding.dart:1935-1990`,
  `:2248-2265`, `:2345-2388` and `:2515-2545` of Flutter 3.44.9. `widgets/binding.dart:1948-1953`.
