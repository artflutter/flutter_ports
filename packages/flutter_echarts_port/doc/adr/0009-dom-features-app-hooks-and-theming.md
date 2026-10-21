# ECharts ADR 0009: DOM-bound features, app hooks and theming

- Status: proposed
- Date: 2026-10-21
- Gate: split gates. ECharts phase 6 for the tooltip, aria, export, links and themes. Phase 6
  ports the tooltip, aria, export and title files. It also starts the gallery. ECharts phase 7
  for the heatmap pixels and the decal tiles, because phase 7 ports the heatmap series. ECharts
  phase 8 for the XML parser of SVG maps and the GeoJSON fallback, because phase 8 ports geo and
  map. ECharts phase 9 for the toolbox features `SaveAsImage` and `DataView`, because phase 9
  ports the toolbox.
- Related: [ECharts ADR 0002](0002-file-naming-and-layout.md) (port-only folders, import side
  effects), [ECharts ADR 0003](0003-numbers-and-js-semantics.md) (`jsJsonDecode`, protected
  values), [ECharts ADR 0004](0004-js-values-classes-and-options.md) (option values, user
  callbacks), [ECharts ADR 0005](0005-spec-harness-and-reference-tests.md) (pure chart specs, the
  smoke runner), [ECharts ADR 0006](0006-renderer-and-canvas-layer.md) (the Canvas 2D layer, a
  canvas as image source, the SVG string painter),
  [ECharts ADR 0007](0007-environment-host-and-input-events.md) (`env.domSupported`, the platform
  API, `EChartsContainer`, `EChartsHost`), [ECharts ADR 0008](0008-dates-locales-and-formatting.md)
  (locales of the toolbox texts),
  [Chart.js ADR 0001](../../../flutter_chartjs/doc/adr/0001-theming.md) (the four theme
  invariants), [Chart.js ADR 0031](../../../flutter_chartjs/doc/adr/0031-gallery-chart-types.md)
  (the gallery layout rule),
  [Chart.js ADR 0034](../../../flutter_chartjs/doc/adr/0034-no-display-only-js-exactness.md)
  (accepted 2026-10-21: no display-only JS exactness),
  [ADR 0007](../../../../docs/adr/0007-package-names.md) (adapter names),
  [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (no port depends on
  another port), [AGENTS.md](../../../../AGENTS.md) rule 5 (no JavaScript at runtime),
  [differences.md](../differences.md) (the rows of this ADR)

## Context

**ECharts touches the DOM in few places.** zrender holds the DOM layer
([ECharts ADR 0006](0006-renderer-and-canvas-layer.md),
[ECharts ADR 0007](0007-environment-host-and-input-events.md)). ECharts `src/` reaches the DOM,
the window or the browser in the features of this ADR: the tooltip, aria, export, the toolbox,
links, the heatmap, decals and maps. ECharts has no `fetch`, no `XMLHttpRequest` and no
`new Image` in `src/`. The app gives all external data through the API.

**The tooltip.** ECharts has two tooltip contents.
- `getTooltipRenderMode` (`echarts src/util/model.ts:1044-1052`) gives `'richText'` for `'auto'`
  when `env.domSupported` is false. Else it gives `'html'`. An unset value gives `'html'`.
- The option default is `renderMode: 'auto'` (`src/component/tooltip/TooltipModel.ts:113`).
  `TooltipView.ts:170` is the only caller of `getTooltipRenderMode`.
- `TooltipView.init` returns early when `env.node` is true or `api.getDom()` is null
  (`src/component/tooltip/TooltipView.ts:164-178`). It makes `TooltipRichContent` for
  `'richText'`. Else it makes `TooltipHTMLContent` with `appendTo`.
- A `formatter` returns `string | HTMLElement | HTMLElement[]`. A function formatter can give the
  content later through a callback with a ticket (`TooltipView.ts:837-870`).
- `TooltipRichContent.ts` (243 lines) draws a zrender `Text` with rich styles in the chart. It
  throws for DOM content (`TooltipRichContent.ts:85-87`).
- `TooltipHTMLContent.ts` (568 lines) is a `div` over the chart:
  - `gCssText` (`:48`) sets `position:absolute` and `z-index:9999999`.
  - `assembleTransition`, `assembleTransform`, `assembleFont` and `assembleCssText` (`:106-225`)
    make CSS text from the model.
  - The constructor (`:300-330`) calls `document.createElement('div')` (`:309`), sets
    `domBelongToZr` (`:311`) and resolves `appendTo` with `document.querySelector` (`:318`). It
    appends the `div` to that container or to `api.getDom()` (`:326`).
  - `onmouseenter`, `onmousemove` and `onmouseleave` (`:336-369`) support `enterable`.
  - `show` and `setContent` (`:404-475`) write `innerHTML` and append DOM nodes.
  - `getSize` reads `offsetWidth` and `offsetHeight` (`:483`). `TooltipView` places the tooltip
    with this size at once.
- `src/component/tooltip/tooltipMarkup.ts` (580 lines) makes the content text. It has an `html`
  branch (`<div style=...>`, `<span style=...>`, for example `:306`, `:429-459`) and a `richText`
  branch (`:284-300`, `:358`, `:505`). `src/util/format.ts:204-208` makes the HTML marker `span`.
  `TooltipView.ts:634` joins blocks with `<br/>` in the `html` mode.
- zrender `src/dom/HandlerProxy.ts:139-150` (`isLocalEl`) reads `domBelongToZr`. Thus a pointer
  that moves onto an enterable HTML tooltip does not give `globalout` (`:233`).

**aria.** `src/visual/aria.ts:138-160` reads `api.getZr().dom`. It writes `role="img"` and the
`aria-label` attribute on it. `:246` writes the label from the series. The spec
`test/ut/spec/series/aria-columns-exclude.test.ts:83-84` reads
`chart.getDom().getAttribute('aria-label')`.

**Export.** `src/core/echarts.ts:910-1122` has the export methods.
- `renderToCanvas` (`:922-937`) calls `getRenderedCanvas` of the canvas painter
  (`zrender src/canvas/Painter.ts:1280-1328`). It returns an `HTMLCanvasElement`.
- `renderToSVGString` (`:939-952`) and `getSvgDataURL` (`:957-966`) need the SVG painter. The SVG
  `toDataURL` makes its text from `renderToString` (`zrender src/svg/Painter.ts:347-355`). It
  needs no DOM.
- `getDataURL` (`:968-1009`) hides the `excludeComponents` views, calls
  `renderToCanvas(opts).toDataURL('image/' + type)` and shows the views again. All steps are
  synchronous.
- `getConnectedDataURL` (`:1012-1122`) reads `getBoundingClientRect()` of each connected chart
  (`:1043`). It makes a zrender on `platformApi.createCanvas()` (`:1062-1065`). It draws each
  rendered canvas as a `graphic.Image` (`:1104-1113`). Its SVG branch reads and writes the
  `innerHTML` of the live SVG DOM (`:1041`, `:1079`).
- A browser `canvas.toDataURL(type)` with a type that it cannot encode returns a PNG URL (HTML
  standard, "Serialising bitmaps to a file").

**The toolbox.**
- `src/component/toolbox/feature/SaveAsImage.ts` (148 lines). `onclick` (`:47-124`) gets the URL
  from `api.getConnectedDataURL` (`:52-59`). In Chrome, Firefox and the new Edge it makes an `a`
  element with `download` and dispatches a `MouseEvent` (`:61-74`). The other branch (`:76-124`)
  serves IE and the old Edge: `msSaveOrOpenBlob`, `atob`, `Blob`, an `iframe` with
  `execCommand('SaveAs')`, and `window.open()` with `document.write`.
- `src/component/toolbox/feature/DataView.ts` (535 lines). `onclick` (`:323-447`) builds a panel
  with `div`, `h4`, `textarea` and two button `div`s over the whole container. It sets the height
  of the view to `container.clientHeight - 80` (`:444`). `dispose` (`:450-452`) removes the panel.
  The options `optionToContent` (returns `string | HTMLElement`) and `contentToOption` (takes the
  view `HTMLDivElement`) are at `:302-303`. The functions `groupSeries`,
  `assembleSeriesWithCategoryAxis`, `assembleOtherSeries`, `getContentFromModel`,
  `parseContents` and `tryMergeDataOption` (`:70-297`, `:480-501`) are pure. `:505-533`
  registers the action `changeDataView` at module level.

**Links.** `src/util/format.ts:322-332` (`windowOpen`) calls `window.open`. It sets
`opener = null` for a blank target. The callers are the title `link` and `sublink`
(`src/component/title/install.ts:195`, `:200`), the treemap
(`src/chart/treemap/TreemapView.ts:623`) and the sunburst
(`src/chart/sunburst/SunburstView.ts:213`).

**Offscreen pixels.**
- `src/chart/heatmap/HeatmapLayer.ts` (178 lines) draws a blurred brush for each point with
  `globalAlpha` (`:76-87`). It reads the pixels with `getImageData` (`:96`). It maps the alpha
  to a gradient color (`:98-121`). It writes the pixels with `putImageData` (`:122`). The brush is
  a circle with `shadowBlur` (`:130-154`).
- Only the geo-like coordinate systems use `HeatmapLayer`
  (`src/chart/heatmap/HeatmapView.ts:123-133`, `:351-424`). `:364` reads
  `this._hmLayer || (this._hmLayer || new HeatmapLayer())`. Thus each render makes a new layer
  with a new canvas.
- `src/util/decal.ts:132-214` draws a decal tile on `platformApi.createCanvas()` at the device
  pixel ratio. It draws symbols with `brushSingle` (`:300`). The canvas becomes the `image` of a
  pattern. An LRU of 100 entries (`:36`) keeps the tiles.

**Maps.**
- `zrender src/tool/parseXML.ts` has 22 lines. `:6-22` calls `new DOMParser()` and
  `parseFromString(svg, 'text/xml')` for a string (`:8-9`). It walks `nodeType`, `nodeName` and
  `nextSibling` to the `svg` element.
- `zrender src/tool/parseSVG.ts` (965 lines) reads 6 node members: `getAttribute` (52 sites),
  `nodeType` (4), `firstChild` (3), `nextSibling` (3), `nodeName` (2) and `textContent` (1).
- `src/coord/geo/GeoSVGResource.ts:20,26,97` imports both files. `GeoSVGSourceInput` is
  `string | Document | SVGElement` (`src/coord/geo/geoTypes.ts:26`).
- `src/coord/geo/GeoJSONResource.ts:163-169` (`parseInput`) calls `JSON.parse` for a string. The
  `new Function('return (' + source + ');')` branch (`:168`) runs only when `JSON` is absent.
- ECharts ships no map data. The pin has no `map/` folder. `test/data/map/` (76 files) is test
  data. The app calls `registerMap` (`src/core/echarts.ts:3326-3333`).

**Themes.**
- `ECharts.setTheme(theme, opts)` (`src/core/echarts.ts:826-870`) changes the theme of one
  instance. `init(dom, theme, opts)` (`:2926-2930`) takes a theme name or a theme object.
- `:3426-3427` registers `'default'` (`{}`) and `'dark'` at module level.
- `src/theme/dark.ts` (329 lines) builds the dark theme from `tokens.darkColor` of
  `src/visual/tokens.ts` (233 lines). The pin has no light theme file. The light look is the
  default model.
- The folder `theme/` at the root of the pin has 36 theme files directly in `theme/` (43 `.js`
  files with the subfolders, `git ls-files 'theme/*.js'`). They are
  hand-written UMD files that call `echarts.registerTheme`. The build does not make them from
  `src/` (`theme/dark.js:223` differs from `src/theme/dark.ts`). `theme/tool/` has 7 more `.js`
  files of a thumbnail page.
- Chart.js has only global defaults. Thus Chart.js ADR 0001 needs a resolver scope and theme
  hunks. The four invariants of Chart.js ADR 0001 are accepted. Section 8 restates them for this
  port.

**Other browser code.**
- `extension-src/bmap/` needs the Baidu Maps JS SDK (the global `BMap`).
- `ssr/client/src/index.ts` hydrates a server SVG in a browser.
- `src/core/echarts.ts:540-551` reads three dev defaults from `window` or `global`.
  `:1611` throttles the flush in WeChat. `TooltipHTMLContent.ts:305` returns early in a WeChat
  mini app.

**The gallery.** Chart.js ADR 0031 §10 item 4 keeps the chart host fully in view after the first
frame at 412 x 915. The type pages are also in view at 360 x 640. A widget test pins each case.

## Decision

### 1. The tooltip (gate 6)

1. With `env.domSupported` false ([ECharts ADR 0007](0007-environment-host-and-input-events.md)),
   `'auto'` gives `'richText'`. The first target is `TooltipRichContent.ts`, a zrender `Text`. It
   ports line by line with no change.
2. An explicit `renderMode: 'html'` and an unset `renderMode` also give `'richText'`. The hunk is
   in `getTooltipRenderMode` (`src/util/model.ts:1044-1052`). It carries
   `// DIVERGES(echarts): platform-tooltip-html, no HTML overlay`. The row stays until a later
   ECharts ADR decides a Flutter overlay.
   - `shouldTooltipConfine` (`src/component/tooltip/helper.ts:27-33`) tests the resolved render
     mode of `getTooltipRenderMode`, not the raw option. Upstream tests
     `tooltipModel.get('renderMode') === 'richText'` (`:32`). Thus the default `'auto'` gives a
     richText tooltip with no confine. The upstream comment at `:31` says: "In richText mode, the
     outside part can not be visible".
   - This hunk carries
     `// DIVERGES(echarts): platform-tooltip-html, confine the richText tooltip that 'auto' selects`.
     Without the hunk, the canvas of the chart host cuts off a default tooltip near an edge.
3. A formatter that returns an `HTMLElement` is `n/a`. The `richText` content throws for it, as
   upstream does (`TooltipRichContent.ts:85-87`).
4. The `html` branch of `tooltipMarkup.ts` ports as pure string code with its module. Only the
   overlay of item 5 reads its output.
5. `src/component/tooltip/helper.ts` ports in phase 6, because `TooltipView.ts:54` imports
   `shouldTooltipConfine`. `testStyle`, `toCSSVendorPrefix` and `getComputedStyle`
   (`helper.ts:35-73`) port as plain code. Their only callers are in `TooltipHTMLContent.ts`.
   `TooltipHTMLContent.ts` gets the status
   `partial: TooltipHTMLContent (constructor throws UnsupportedError)` in phase 6, because
   `TooltipView.ts:21` imports it by value. The hunk of item 2 makes its branch at
   `TooltipView.ts:172-178` unreachable. The later overlay ADR ports the rest of the file. It
   decides these points:
   - the HTML and CSS subset: the tags `div`, `span` and `br`, the entities, and the inline
     styles of `tooltipMarkup.ts`, `format.ts:204-208` and `TooltipView.ts:634`.
   - the size: `TooltipView` reads `getSize()` at once (`TooltipHTMLContent.ts:483`). A widget
     knows its size only after layout. The ADR selects a measure pass or a one-frame lag.
   - `appendTo` and `appendToBody`: an `OverlayPortal` to the root `Overlay`.
   - `enterable` and `domBelongToZr`: a pointer on an enterable overlay does not give
     `globalout` to the handler proxy of ECharts ADR 0007.
   - `extraCssText` and `className`: `n/a` or a subset.
6. The trigger of the overlay ADR is a gallery or user need for `renderMode: 'html'`
   ([porting-flow.md](../porting-flow.md) §5.1).

### 2. aria (gate 6)

1. `src/visual/aria.ts` ports as is. It writes `role` and `aria-label` on the zrender `dom`. That
   object is the `EChartsContainer` of ECharts ADR 0007.
2. The container tells `EChartsHost` about a change of these two attributes. The host then marks
   its semantics dirty.
3. In `describeSemanticsConfiguration`, the host sets `isImage` when `role` is `'img'`. It sets
   `label` to the value of `aria-label`. With no `aria-label`, the host adds no label.
4. The spec `series/aria-columns-exclude` reads the attribute of the pure container. It runs
   with no host ([ECharts ADR 0005](0005-spec-harness-and-reference-tests.md)).

### 3. Export (gate 6)

1. `renderToCanvas` returns the canvas element of the Canvas 2D layer of
   [ECharts ADR 0006](0006-renderer-and-canvas-layer.md). That element is an image source (gap
   "a canvas as image source"). Thus `getConnectedDataURL` draws it as a `graphic.Image`, as
   upstream does. The app reads a `ui.Image` from it through the accessor of the layer.
2. `getDataURL` and `getConnectedDataURL` return `Future<String>`. `dart:ui` encodes an image
   only asynchronously (`ui.Image.toByteData`). Each method carries
   `// DIVERGES(echarts): platform-data-url-async, dart:ui encodes images asynchronously`.
3. The synchronous part stays in the upstream order. `getDataURL` hides the excluded views,
   draws, takes the image and shows the views again. Only the encoder runs after the return.
4. The Canvas 2D interface gets `Future<String> toDataURL([String type])`. The `dart:ui`
   implementation encodes PNG with `ui.ImageByteFormat.png`. It returns
   `'data:image/png;base64,'` and the base64 text.
5. `dart:ui` has no JPEG encoder. A type other than PNG gives a PNG URL, as a browser does for a
   type that it cannot encode. A JPEG encoder stays open (a later decision, with its dependency
   under item 7.3).
6. The PNG bytes are display values (Chart.js ADR 0034). A port-only test decodes the PNG. It
   compares the size and the pixel ratio, not the bytes of a browser.
7. `renderToSVGString` and `getSvgDataURL` come with the SVG string painter of phase 10
   ([ECharts ADR 0006](0006-renderer-and-canvas-layer.md)). They stay synchronous and return a
   `String`. With the SVG renderer, `getDataURL` returns a completed `Future`.
8. The SVG branch of `getConnectedDataURL` (`echarts.ts:1041`, `:1071-1087`) reads the live SVG
   DOM. Phase 10 decides its string form with the SVG string painter.
9. `getConnectedDataURL` reads the rect of `getBoundingClientRect` of each chart from
   `EChartsContainer` ([ECharts ADR 0007](0007-environment-host-and-input-events.md)).

### 4. App hooks (gates 6 and 9)

1. Browser actions become app hooks. `lib/` adds no plugin and no `dart:js_interop`
   ([AGENTS.md](../../../../AGENTS.md) rule 5). The app gives the hooks. It can use
   `url_launcher`, `share_plus` or `file_selector` in its own code.
2. The port-only pure library `lib/src/platform/app_hooks.dart` holds the hooks in one settable
   object, as `setPlatformAPI` does for `platformApi`. Its header is
   `// Original code, not ported from Apache ECharts: the app hooks of the browser actions.`
3. `openLink(String url, String target)` (gate 6). The body of `windowOpen`
   (`src/util/format.ts:322-332`) calls the hook with the upstream `link` and `target`. It carries
   `// DIVERGES(echarts): platform-window-open, no window object`. With no hook, nothing opens.
   With `echartsDev` on, the port logs a warning through the log sink of
   [ECharts ADR 0004](0004-js-values-classes-and-options.md).
4. `onSaveAsImage(Uint8List bytes, String fileName, String type)` (gate 9). `SaveAsImage.onclick`
   awaits `getConnectedDataURL`. It decodes the data URL and calls the hook with
   `title + '.' + type`. This replaces the `a` element branch (`SaveAsImage.ts:61-74`). The marker
   is `// DIVERGES(echarts): platform-data-url-async, the download goes to an app hook`.
5. The IE and old Edge branch (`SaveAsImage.ts:76-124`) is `n/a`. `env.browser.ie` and
   `env.browser.edge` are false ([ECharts ADR 0007](0007-environment-host-and-input-events.md)).
6. An image resolver (gate 6). The Flutter `platformApi.loadImage` of ECharts ADR 0007 decodes a
   `data:` URI itself. For another source, it calls the resolver of the app. The resolver returns
   an `ImageProvider` or null. With no resolver, `http` and `https` URLs load through
   `NetworkImage`. Other sources call `onerror`. The resolver lives in the Flutter part of
   `lib/src/platform/`, not in the pure hooks file.
7. Each hook is a Dart function value. A ported caller calls it at the upstream site. The widget
   API of phase 10 can set the hooks for the app.

### 5. DataView (gate 9)

1. The pure parts of `DataView.ts` port line by line: `groupSeries`,
   `assembleSeriesWithCategoryAxis`, `assembleOtherSeries`, `getContentFromModel`,
   `parseContents`, `tryMergeDataOption` and the action `changeDataView`. The module-level
   `registerAction` (`:505-533`) follows the import side-effect rule of
   [ECharts ADR 0002](0002-file-naming-and-layout.md).
2. The DOM part of `onclick` (`:331-447`) and `dispose` (`:450-452`) is a port-only hunk. It
   gives a pure panel request to the overlay children of `EChartsContainer`. The request holds the
   title, the text, `readOnly`, the colors of the model, the `lang` labels and two callbacks:
   refresh with the current text, and close.
3. `EChartsHost` shows the request as a Flutter panel over the chart. The panel has a monospace
   `EditableText`, a refresh button and a close button. It takes the colors of the model. It uses
   no Material widget (section 8).
4. `optionToContent` returns a `String`. The panel shows it as editable text, not as HTML.
   `contentToOption` takes the current text of the panel and the old option. The user callbacks
   go through `jsCall` ([ECharts ADR 0004](0004-js-values-classes-and-options.md)). The row is
   `platform-dataview-dom`.
5. The refresh callback keeps the upstream rules (`:398-430`). It warns when only one of the two
   functions is set. It throws `Data view format error` for a parse error. It dispatches
   `changeDataView` for a new option.

### 6. Heatmap pixels and decal tiles (gate 7)

1. The heatmap needs the alpha of its blurred brushes. `dart:ui` reads pixels only
   asynchronously. Thus `HeatmapLayer.update` computes the alpha field in Dart. It does not draw
   the brushes and read them back.
2. The field is a port-only pure function. The brush is the disc of radius `pointSize` with a
   Gaussian blur of sigma `blurSize / 2`, the shadow rule of ECharts ADR 0006. Each point adds its
   brush with source-over alpha at `normalize(value)`. The field stores 8-bit alpha, as a canvas
   does.
3. The gradient loop (`HeatmapLayer.ts:98-121`) and `_getGradient` port line by line on a
   `Uint8ClampedList`.
4. `putImageData` of the Canvas 2D layer uploads the pixels asynchronously. The canvas shows its
   old content until the upload ends. Then it marks the zrender image dirty, as an image that
   loads through `zrender src/graphic/helper/image.ts` does.
5. The hunk carries `// DIVERGES(echarts): platform-heatmap-pixels, no synchronous pixel read`.
   The field values are display values (Chart.js ADR 0034). A port-only test pins the field of one
   point: the maximum at the center, symmetry, and zero alpha past `pointSize + blurSize`.
6. The port keeps the upstream line `HeatmapView.ts:364`. Each render makes a new layer, as
   upstream does.
7. Decal tiles need no row. `decal.ts` draws on a canvas of `platformApi.createCanvas()`. The
   Canvas 2D layer gives that canvas as an image source through `Picture.toImageSync`
   ([ECharts ADR 0006](0006-renderer-and-canvas-layer.md)). The SVG branch of `decal.ts` waits
   for the SVG string painter of phase 10.

### 7. Maps (gate 8)

1. ECharts ships no map data. The app loads its GeoJSON or SVG text, for example from its assets.
   It calls `registerMap`.
2. A GeoJSON source is a decoded `Map` or a JSON `String`. `parseInput`
   (`GeoJSONResource.ts:163-169`) decodes a string with `jsJsonDecode` of
   [ECharts ADR 0003](0003-numbers-and-js-semantics.md). That decode gives each number as a
   `double`, as `JSON.parse` does. The `new Function` branch (`:168`) goes. The hunk carries
   `// DIVERGES(echarts): platform-geojson-function, no JS evaluation`.
3. An SVG map source is a `String` or a node of the XML parser. `Document` and `SVGElement` are
   `n/a`. Phase 8 selects the parser from two options:
   - a port-only minimal XML parser in a port-only folder (ECharts ADR 0002 item 5). It gives a
     node interface with the 6 members that `parseSVG.ts` reads, and `nodeType`, `nodeName` and
     `nextSibling` for `parseXML.ts`.
   - `package:xml` (MIT). This is a new dependency. It changes the root `pubspec.lock`.
     `packages/flutter_chartjs/doc/canvas-cuts-plan.md` cites that file (work package I). Thus the
     change updates that deferred plan in the same commit
     ([porting-flow.md](../porting-flow.md) §5.1).
4. The criteria of the selection: the XML features of the SVG maps of the visual pages, the error
   behavior of `DOMParser`, the size, and the build on all platforms and on dart2wasm.
5. `parseXML.ts` and `parseSVG.ts` port as zrender files in phase 8. `parseXML.ts` gets a hunk at
   `:7-10` for the parser call.

### 8. Themes (gate 6)

1. The four invariants of Chart.js ADR 0001 apply to this port:
   1. Specs run unthemed. A spec passes a theme only where the upstream spec passes one.
   2. `lib/` imports no forui and no Material.
   3. Ported code never writes `model/globalDefault.ts` values or calls `registerTheme` to
      apply a theme. The upstream `registerTheme('default', {})` and
      `registerTheme('dark', darkTheme)` (`echarts.ts:3426-3427`) stay. They follow the import
      side-effect rule of ECharts ADR 0002.
   4. Ported files never import `lib/src/theme/`.

   `check:lib-imports` enforces invariants 2 and 4 when ADR 0008 stage 1 adds the ECharts
   configuration.
2. ECharts themes are per instance (`init(dom, theme)`, `setTheme`). Thus the port needs no theme
   hunks and no resolver scope. `differences.md` has no `theme` category.
3. The port-only pure folder `lib/src/theme/` maps a Flutter theme to an ECharts theme object. The
   input is a set of tokens that the app gives: the brightness, the text color, the background,
   the palette and the font family. The output is a raw option `Map`
   ([ECharts ADR 0004](0004-js-values-classes-and-options.md)). The widget passes it to `init`. It
   calls `setTheme` when the tokens change.
4. `src/theme/dark.ts` and `src/visual/tokens.ts` are ported code (phases 5 and 2). They are not
   part of `lib/src/theme/`.
5. A design-system adapter takes the name `flutter_echarts_port_<system>`
   ([ADR 0007](../../../../docs/adr/0007-package-names.md) item 5). No adapter comes before
   0.1.0.
6. The 36 theme files directly in `theme/` are not ported for 0.1.0. A later change can add them as data
   files with rule-2 headers. That change adds their source path to `tool/port_sources.yaml`. The
   deferred plan has the trigger "a user request" ([porting-flow.md](../porting-flow.md) §5.1).
7. The default for the dark mode of the app is open. Until an ADR decides it, the widget uses the
   theme that the app gives, else no theme.

### 9. Out of scope

| Upstream code | Status | Reason |
|---|---|---|
| `extension-src/bmap/` | `n/a` | needs the Baidu Maps JS SDK in a browser |
| `extension-src/dataTool/` | not ported for 0.1.0 | optional. `gexf.ts` needs the XML parser of section 7 |
| `ssr/client/src/index.ts` | `n/a` | a browser script for a server SVG |
| IE and old Edge branches (`SaveAsImage.ts:76-124`) | `n/a` | `env.browser.ie` and `env.browser.edge` are false |
| WeChat branches (`echarts.ts:1611`, `TooltipHTMLContent.ts:305`) | ported as is | `env.browser.weChat` and `env.wxa` are false |
| dev globals (`echarts.ts:540-551`) | ported with no global object | the three defaults keep their values of `:534-536` |

### 10. The gallery rule for overlays

1. The rule of Chart.js ADR 0031 §10 applies to `apps/echarts_gallery` (phase 6).
2. The tooltip and the DataView panel stay inside the chart host. A widget test pins each at
   412 x 915 and at 360 x 640.
3. A later HTML tooltip overlay follows the same rule. Its `appendTo` portal must keep the
   tooltip in view at both sizes.

### 11. Rows

This ADR reserves these rows of [differences.md](../differences.md). The change that ports the
code adds the row.

| Row id | Category | Gate | Site |
|---|---|---|---|
| `platform-tooltip-html` | `platform` | 6 | `src/util/model.ts:1044-1052` |
| `platform-data-url-async` | `platform` | 6 | `src/core/echarts.ts:968-1122`, `SaveAsImage.ts:47-74` |
| `platform-window-open` | `platform` | 6 | `src/util/format.ts:322-332` |
| `platform-heatmap-pixels` | `platform` | 7 | `src/chart/heatmap/HeatmapLayer.ts:57-122` |
| `platform-geojson-function` | `platform` | 8 | `src/coord/geo/GeoJSONResource.ts:163-169` |
| `platform-dataview-dom` | `platform` | 9 | `src/component/toolbox/feature/DataView.ts:302-303`, `:323-452` |

## Alternatives considered

- **An HTML renderer in phase 6.** Rejected. The tooltip works upstream with `richText` when no
  DOM exists. An HTML and CSS subset, a measure pass and the overlay events are new port-only
  code. No phase 6 exit needs them. The later overlay ADR keeps the option.
- **Synchronous data URLs through `toImageSync` and a pure-Dart encoder.** Rejected. A PNG encoder
  in Dart is new port-only code. It runs on the UI thread for each export. `toImageSync` still
  needs a raster step. The `Future` keeps the platform encoder and the upstream draw order.
- **`url_launcher` or file plugins in `lib/`.** Rejected. A plugin adds platform channels to each
  app and a dependency to the root `pubspec.lock`. The pure files cannot call it. App hooks keep
  `lib/` free of plugins (AGENTS.md rule 5).
- **A Chart.js-style theme resolver with hunks.** Rejected. ECharts already has per-instance
  themes through `init` and `setTheme`. Hunks then change upstream code for no gain.
- **`package:xml` now.** Rejected. Phase 8 is the first caller. A dependency now changes the root
  `pubspec.lock` with no user. Phase 8 compares it with a minimal parser on the real map files.
- **A DOM stand-in for the DataView panel.** Rejected. `DataView.ts` builds the panel with
  `innerHTML` and CSS text. A stand-in then needs an HTML and CSS layout. The panel request gives
  the same content to a Flutter widget.
- **Read the heatmap pixels back with `toByteData`.** Rejected. The read is asynchronous in the
  middle of `update`. `HeatmapView` then needs a second render pass. The Dart field gives the
  pixels at once and uploads them once.

## Consequences

- Phase 6 gets a tooltip, aria labels and PNG export with no overlay code.
- A tooltip stays in the chart host. A tooltip larger than a small chart (360 x 640) is cut off.
  The gallery widget test of each type pins one hover tooltip in view.
- An app that sets `renderMode: 'html'` gets the rich-text tooltip. HTML tags in a formatter
  string show as text until the overlay ADR.
- Export calls in Dart are asynchronous. An app awaits `getDataURL`.
- Links, downloads and network images need no plugin in the library. An app without hooks gets no
  link action and no download.
- The DataView panel is a Flutter widget. A custom `optionToContent` gives text, not HTML.
- Heatmap pixels on geo differ from Chrome in the blur. The difference is display only.
- Phase 8 can add one dependency. That change updates the deferred plan that cites the root
  `pubspec.lock`.
- Themes need no hunk. `lib/src/theme/` is port-only code. The specs stay unthemed.
- Seven topics stay open: the HTML overlay, the JPEG encoder, the XML parser, the SVG branch of
  `getConnectedDataURL`, the root themes, the dark-mode default and the adapters.

## Evidence

- The DOM sites: a grep of `src/`, `extension-src/` and `ssr/client/src/` of
  `third_party/echarts` at `c5a48f5f` and of `src/` of `third_party/zrender` at `32b66867` for
  `document.`, `window.`, `navigator.`, `innerHTML`, `DOMParser`, `getImageData`, `toDataURL`,
  `createCanvas`, `setAttribute` and `windowOpen`. Each site was read at the pin on 2026-10-21.
- The callers of `getTooltipRenderMode` and `windowOpen`: `grep -rn` over `src/` of the pin.
- The node members of `parseSVG.ts`: `grep -oE` of `.getAttribute`, `.nodeType`, `.firstChild`,
  `.nextSibling`, `.nodeName` and `.textContent`, counted with `uniq -c`.
- The line counts: `wc -l` of each file at the pin.
- The root themes: `git ls-files theme` gives 45 files. Of them, 36 are `theme/*.js` at the top
  level, 7 are `.js` files in `theme/tool/`, 1 is `theme/tool/thumb.html` and 1 is
  `theme/package.json`.
- The map data: `git ls-files` gives no path under `map/`. `test/data/map/` has 76 files.
- The PNG fallback: the HTML standard, `HTMLCanvasElement.toDataURL`, "Serialising bitmaps to a
  file".
