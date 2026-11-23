# Chart.js ADR 0200: Native canvas style members and typed harness options

- Status: proposed
- Date: 2026-11-24
- Supersedes: of [Chart.js ADR 0022](0022-chart-test-harness.md), §3 for the CSS subset of the DOM stand-in
  and `CssProperties`, §4 for the `style` reflection and the attribute Maps of `acquireChart`, §9 for the display
  size rule of `toBeChartOfSize`; of [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md), §5 for the
  display size from the styles and the restore of the `display`, `height` and `width` styles; of
  [Chart.js ADR 0055](0055-native-draw-path.md), §2 for the map-backed `style`; of
  [Chart.js ADR 0108](0108-input-surface-and-exports-for-add-on-plugins.md), §8 for the read of `touch-action` from
  the style, §9 (`CssStyleProperties`) and §11 for `left` and `top` of the DOM stand-in; of
  [Chart.js ADR 0124](0124-native-text-direction.md), item 2 for the inheritance from the element style
- Related: [Zoom ADR 0009](../../../flutter_chartjs_plugin_zoom_port/doc/adr/0009-native-canvas-style-members.md)
- Difference: `adapt-native-canvas-style`, `platform-dom-computed-style`, `harness-acquire-options`,
  `harness-chart-matchers`.

## Context

The canvas element and the harness keep CSS text: a map-backed `CSSStyleDeclaration` with a declaration
parser, `'512px'` strings that `retinaScale` writes and the host parses back, `touch-action` as a string
property, and the harness lays out `div` elements from parsed CSS (`'width: 320px; position: absolute'`).
Flutter has no CSS: the layout facts are the constraints and the size of the chart host. Each CSS value of
the port is one of five facts: a display size, a touch action, a select flag, a text direction, or a box of the
test layout.

## Decision

1. The canvas has typed members in place of its style.

   ```dart
   // Before
   canvas.style.setProperty('width', '${jsToString(chart.width)}px');
   _touchActionNone = _canvas.style.touchAction.trim().toLowerCase() == 'none';
   return _element.style.getPropertyValue('direction') == 'rtl';
   // After
   canvas.displayWidth = chart.width;                 // double?, null: the render width
   _touchActionNone = _canvas.touchAction == CanvasTouchAction.none;
   return _element.textDirection == TextDirection.rtl; // TextDirection?, null: ltr
   ```

   `HTMLCanvasElement` has `double? displayWidth`, `double? displayHeight`, `CanvasTouchAction touchAction`
   (`auto`, `none`), `bool userSelect` and `TextDirection? textDirection`. `UiCanvasElement` holds them as
   fields. The `style` attribute has no reflection: `setAttribute('style', ...)` throws an `ArgumentError`.

2. `helpers.dom` reads the display size. `getComputedStyle` and `getStyle` have no port.

   ```dart
   // Before
   double? readUsedSize(HTMLCanvasElement element, String property)  // '300.5px' -> 300
   // After
   double? readUsedSize(HTMLCanvasElement element, Axis axis)        // 300.5 -> 300
   ```

   The result is the integer part of a non-negative finite size, else `null`.

3. `initCanvas` writes no `display: block` and no `box-sizing: border-box`: the host is a block box with no
   border. `releaseContext` restores the attributes and the display size. The host size is
   `constraints.constrain(displaySize)`, where the display size is both display sides when both are set, else
   the render size.

4. The touch action is the enum. The host reads it at the start of each touch sequence; the rest of Chart.js
   ADR 0108 §8 stays. `CssStyleProperties` is gone.

   ```dart
   // Before
   _canvas.style.touchAction = 'none';
   // After
   _canvas.touchAction = CanvasTouchAction.none;
   ```

5. `acquireChart` and `acquireChartRoot` take `AcquireOptions`, not attribute Maps.

   ```dart
   // Before
   acquireChartRoot(config, {
     'canvas': {'style': 'width: 150px; height: 245px'},
     'wrapper': {'style': 'width: 300px; height: 350px'},
   });
   // After
   acquireChartRoot(config, const AcquireOptions(
     canvas: HarnessCanvas(displayWidth: 150, displayHeight: 245),
     wrapper: HarnessBox(width: 300, height: 350),
   ));
   ```

   `HarnessCanvas` has the render size (`int? width`, `int? height`, the attributes), the display size and
   `hidden`. `HarnessBox` has `width`, `height`, `maxWidth`, `maxHeight` (`double?`), `padding` (`EdgeInsets`),
   `hidden`, `absolute`, `offset` (`Offset?`, the `left` and `top` of an absolute box) and `direction`. Without
   `canvas`, the canvas has the attributes 512 x 512; without `wrapper`, the wrapper is `absolute` (the rule of
   `injectWrapperCSS`). `persistent`, `useOffscreenCanvas` and `useShadowDOM` are `bool`. `chart.$test` is a
   record `({bool persistent, HarnessElement wrapper})`.

6. The DOM stand-in lays out a `HarnessElement` from the same typed fields, with the rules of Chart.js ADR 0022
   §3. A spec writes them as Dart values.

   ```dart
   // Before
   wrapper.style.width = '455px';
   wrapper.style.cssText = 'width: 455px; height: 355px';
   canvas.style.display = 'block';
   // After
   wrapper.width = 455;
   wrapper.box = const HarnessBox(width: 455, height: 355);
   canvas.hidden = false;
   ```

   `hidden` of a canvas is a harness extension (`display: none`): only the layout of the stand-in reads it.

7. `toBeChartOfSize` reads the display size: a set side has its value, one set side keeps the aspect ratio of the
   render size for the other, and an unset pair gives the render size, truncated toward zero. A hidden canvas
   has no `auto` rule: no spec checks the size of a hidden canvas.

8. Two forms wait for other changes and then go: `HTMLCanvasElement.style`, a read-only view of the typed
   members (`'<n>px'`, `'none'`, `'rtl'`) for the gallery and a tooltip test, and the Map form of the
   `acquireChart` options (numeric `canvas` sizes, `useOffscreenCanvas`, `persistent`; a `style` or a `wrapper`
   key throws) for the fixture runner and the reference harnesses.

## Rejected

- A `Size? displaySize`: the specs set one side alone, and the other side keeps the aspect ratio.
- A CSS parser that writes the typed members: it keeps CSS text in the port.
- More `CanvasTouchAction` values (`pan-x`, `pan-y`): the host has two behaviors.

## Consequences

- No library and no harness file parses or writes CSS text, except the two waits of item 8.
- Public API: `getStyle`, `CssStyleProperties` and `UiCssStyleDeclaration` are removed; `readUsedSize` takes an
  `Axis`.
- The spec cases keep their names; a CSS value becomes its typed value.

## Tests

`test/port/helpers/helpers.dom_test.dart`, `helpers.dom_web_test.dart`, `test/port/platform/platform.flutter_test.dart`,
`chart_host_test.dart`, `test/port/canvas/canvas_ui_test.dart`, `packages/chartjs_test_utils/test/dom_test.dart`,
`utils_test.dart`, `matchers_test.dart`, and the specs `platform.dom`, `helpers.dom` and `core.controller`.
