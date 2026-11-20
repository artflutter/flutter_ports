# Canvas and host cuts plan

- Status: proposed, deferred; the native draw path of §7 is brought forward (2026-10-30), and
  [Chart.js ADR 0055](adr/0055-native-draw-path.md) (proposed) states its decision
- Date: 2026-10-19
- Related: [Chart.js ADR 0034](adr/0034-no-display-only-js-exactness.md) (accepted),
  [Chart.js ADR 0055](adr/0055-native-draw-path.md), [Chart.js ADR 0015](adr/0015-text.md),
  [Chart.js ADR 0016](adr/0016-frame-scheduling.md),
  [Chart.js ADR 0037](adr/0037-legend-and-tooltip-input-path.md) (all accepted),
  [performance.md](performance.md), [porting-flow.md](porting-flow.md) §2.2

This plan removes code of the phase 3 canvas layer and of the chart host where Dart or Flutter
already gives the function. It has three cuts and nine work packages. §7 adds the native draw
path of phase 10: native `dart:ui` forms for the slow draw cells. Each work package has one
owner. An owner can take one work package without the history of this plan. All paths are
relative to `packages/flutter_chartjs_port/` unless they start with `apps/` or `third_party/`. The line
numbers are the line numbers on 2026-10-19. Read the file again before an edit, because other
work changes the tree.

## Deferral

The port does not do this plan now ([porting-flow.md](porting-flow.md) §5.1). The revisit point was
after phase 8, before phase 9. Work packages A2 and C2 are done in phase 5 (trigger 1, below).

Decision at the revisit point (2026-10-29): the maintainer kept work packages A1, A3, I, W, C1, D
and P deferred. No trigger occurred in phase 8, the expected gain is small (about 45 library
lines, no speed gain), and no ported code reaches the web defect of §2.3. The plan has no new
revisit point. It waits for a trigger below. While the plan waits:
- A change that edits a file that this plan cites updates this plan in the same commit: the file
  and line references, the code inventory (§1.1), the tests that pin the behavior (§2.6, §3.5) and
  the estimates. It writes no entry that only says that nothing changed. The cited files are `lib/src/canvas/*.dart`, `lib/src/platform/chart_host.dart`,
  `lib/src/platform/platform.flutter.dart`, `lib/src/helpers/helpers.dom.dart`, the tests of §2.6
  and §3.5, `doc/performance.md`, `doc/parity.md` (the rows of §2.7, §3.7 and §5),
  `doc/porting-flow.md` (§2.2 and the harness table of §3), `doc/adr/0013-canvas-model.md` and
  `doc/adr/0014-input-events-and-chart-host.md` (the lines of §2.7 and §3.7).
- A change that makes a step unnecessary, or adds a new reason for it, says so here.

These triggers bring the plan, or one work package of it, forward:
1. **Phase 5 starts the `acquireChart` harness.** With the current `initCanvas`, the default spec
   canvas of 512 x 512 becomes 512 x 256 (§3.3). Do cut 2 (work packages A2 and C2) then, or give
   the harness a workaround and record it here.
2. **Ported code strokes or clips a path under a skew or a non-uniform scale, or uses a pattern
   shader, on the web.** Do work package W (§2.3) then. Chart.js core does not do this today.
3. **The toolchain pin moves to a stable Flutter release with flutter/flutter#190048, #191014
   and #194139.** Remove the text rotation snap (§4.2).
4. **Flutter batches `drawCircle` calls on Impeller and skwasm.** Measure and remove the circle
   batch (§4.1).

Record each trigger that occurs, and the decision, in this section and in porting-flow.md §5.1.

Triggers that occurred:
- 2026-10-19, trigger 1 occurred: phase 5 starts the `acquireChart` harness. The decision
  protocol of phase 5 compared cut 2 (work packages A2 and C2, option A of §3.3) with a harness
  workaround, for example a 512px style on the default spec canvas. Cut 2 passes the 5 named spec
  cases of §3.6 and gives the 512 x 512 default canvas. A workaround gives only the default size.
  The cases with canvas attributes then need `diverges:` rows. Cut 2 also makes `initCanvas` and
  `releaseContext` line-by-line ports. The decision expected about 10 library lines fewer (the
  estimate of §3.9). The real change added 25 lines net (§3.9), so the fourth priority went
  against cut 2. The first and the third priority still decide for cut 2. The figures of §6.3
  ([performance.md](performance.md) §9) decide the performance criterion. Decision: cut 2. Work
  package W stays deferred, because trigger 2 did not occur. C2 depended on W only because both
  edit `canvas_ui.dart`.
- 2026-10-30, a decision of the maintainer in phase 10 brings the native draw path of §7 forward.
  The typed internal model of phase 10 removes the update cost, but not the draw cost of the arcs,
  of the circles with one paint for each item and of the end of the bar recording. The maintainer
  wants the native forms of `dart:ui` for these draws, with no layer on top of a layer. A sixth
  agent does §7 in `lib/src/canvas/` only, in parallel with the agents of the typed model, and §7.6
  gives the A/B of the measurement night. Work packages A1, A3, I, W, C1, D and P stay deferred:
  the forms of §7 do not reach the matrix path of cut 1 or the web defect of §2.3. This change edits
  only the canvas files, their tests, this plan and the rows of `doc/status.yaml`. The porting lead
  records the trigger in porting-flow.md §5.1.

## 1. Why

The maintainer asked to cut the code that implements again what Dart or Flutter already gives.
Phase 3 ports Chart.js line by line onto a Canvas 2D layer over `dart:ui` (porting-flow.md §2.2).
That decision stays. This plan does not rewrite the drawing code for `dart:ui` directly. Inside
that decision, three areas were candidates:

1. **Cut 1.** The arc math and the 2 x 3 affine class `UiTransform` (first estimate: 450 lines).
2. **Cut 2.** The chart host sizing that emulates a CSS replaced element (first estimate: 400
   lines).
3. **Cut 3.** The circle batch and the 2 degree text rotation snap. These stay. The plan records
   only their removal criteria.

Three read-only analyses and scratch probes (Flutter 3.44.9, on the VM, in Chrome with CanvasKit
and in Chrome with skwasm) measured each part. The first estimates were too high. Cut 1 removes
about 45 lines of library code net. Cut 2 removes about 10 lines net, but it fixes the size of the
default spec canvas before phase 5 depends on it. Work package C2 did cut 2 in phase 5. The
library got 25 lines more net, because the attribute model and the interface need more lines than
the estimate (§3.9).

### 1.1 Code inventory

ADR 0057 changes the solid-color setters in `canvas_ui.dart` to accept native
Color values and reject strings through `canvas_colors.dart`. It removes the CSS
parser/cache path from `canvas_ui_paint.dart`. This independent color adaptation
does not implement any path or host cut below; the historical line references in
the cut inventory describe their original review snapshots.

| Part | File:lines | Lines | Flutter API that replaces it | Verdict |
|---|---|---:|---|---|
| Typed composite operation | `canvas.dart` `CanvasCompositeOperation`; `canvas_ui_paint.dart` `blendModeOf`/`compositeOperationOf`; `canvas_ui.dart` `globalCompositeOperation` | 26 supported operations | Native `ui.BlendMode` stored directly; pure enum at the public boundary | **Keep**. No string map or duplicate operation state; no per-draw conversion. |
| `UiPathBuilder._bezierArc` (cubic Béziers for a skew, a non-uniform scale with rotation, a rotated ellipse) | `lib/src/canvas/canvas_ui_path.dart:1582-1634` | 53 | `ui.Path.arcTo` in user space, then `extendWithPath(arc, Offset.zero, matrix4: m)` | **Remove** (cut 1) |
| `_addArc`, axis-aligned branch with the reflection cases `a < 0`, `d < 0` and both | `canvas_ui_path.dart:1518-1540` | 23 | The same matrix path | **Remove** (cut 1) |
| `_addArc`, similarity branch (rotation, uniform scale, mirror) | `canvas_ui_path.dart:1508-1517` | 10 | It already calls `ui.Path.arcTo` in bitmap space | **Keep**. It is the hot path: `retinaScale` and `translate` give a similarity. |
| `_nativeArc` (half arcs for a sweep over pi, sweep 0, `forceMoveTo`) | `canvas_ui_path.dart:1544-1580` | 37 | None. A sweep of `2 * pi - 1e-12` rounds to 360 degrees and `arcTo` adds nothing. | **Keep**. The matrix path shares its half split. |
| `canvasArcSweep` (Chromium `AdjustEndAngle`) | `canvas_ui_path.dart:255-270` | 16 | None. Skia takes the sweep modulo 360 degrees. | **Keep**. The full sweeps change behavior. |
| `UiTransform` (a-f, the operations, `mapX`/`mapY`, the flags, the matrix writers) | `canvas_ui_path.dart:53-253` | 201 | None. `dart:ui` has no affine type. `Canvas.getTransform` needs a live recording and allocates. `vector_math` `Matrix4` is 4 x 4 and not a dependency. | **Keep** |
| Current point and subpath start (`_PathPoint`, `_last`, `_start`, `hasSubpath`; a point on an arc keeps its arc, N3 of §7) | `canvas_ui_path.dart:337-395`, `:831-836`, `:1111-1146` | ~100 | None. `ui.Path` has no current point. | **Keep** |
| DOM `arcTo` (tangent arc) math | `canvas_ui_path.dart:1425-1488` | ~60 | None. `ui.Path.arcToPoint` is the SVG end-point arc. | **Keep**. It calls `_addArc`. |
| `rect()` with four mapped corners | `canvas_ui_path.dart:1214-1246` | 33 | None. `addRect` sorts the corners and changes the winding when `w < 0` or `h < 0`. | **Keep** |
| Pending full circle (`singleCircle`, `_deferCircle`) | `canvas_ui_path.dart:818-829`, `:885-889`, `:1067-1109`, `:1372-1391` | ~50 | None | **Keep** (cut 3) |
| `roundRect` of the path builder: `UiPathBuilder.roundRect` (one `addRRect` under an axis-aligned transform, else the HTML segments through `_addArc`), `addRoundRect` and `addClockwiseRRect` (its second part, also for the fused rounded bar of Chart.js ADR 0158), `mappedRRect` and `mappedRRectOf` (the former `_mappedRRect`), `_roundRectSegments` | `canvas_ui_path.dart:1389-1585` (2026-11-17) | 197 | None. `ui.Path.addRRect` has no direction and no Canvas 2D checks, flips, scale or subpath at (x, y). | **Keep**. A performance addition (porting-flow.md §1.1), not a cut. |
| The shape tracking of the fast paths (`singleRRect`, `shapePair`, `_trackShape`, the fields `_rrect`, `_shape0`, `_shape1`) | `canvas_ui_path.dart:838-843`, `:853-883` | 37 | None. `ui.Path` does not tell its shapes. | **Keep**. A performance addition (porting-flow.md §1.1). |
| `rrectContains` and `_cornerContains` (the inner rounded rectangle is inside the outer one) | `canvas_ui_path.dart:1637-1748` | 112 | None. `RRect.contains` tests one point. | **Keep**. A performance addition (porting-flow.md §1.1): the condition of `drawDRRect`. |
| N3 of §7: the deferred commands of the path builder (`deferredPathCommands`, the command codes, `_codes`, `_numbers`, `_rrects`, `path`, `debugBuilt`, `_build`, `_replay`, `_direct` and the `_path` writers) | `canvas_ui_path.dart:272-300`, `:411-816` | ~220 | None. `ui.Path` builds each command at once. | **Added** (§7). A performance addition (porting-flow.md §1.1). |
| N4 of §7: the sector fill (`UiSector`, the tolerances, `_sameAngle`, `singleSector`, `_near`, `_nearEnd`, `_nearStart` and the item buffers; in the context `_sectorPaint`, `_shaderSectorPaint` (Chart.js ADR 0149), the sector branch of `fill` and `_fillSector`) | `canvas_ui_path.dart:302-335`, `:428-455`, `:891-1065`; `canvas_ui.dart:526-528`, `:1393-1398`, `:1405-1437` | ~250 | `Canvas.drawArc` draws the sector; no `dart:ui` API tells the sector of a path. | **Added** (§7). A performance addition (porting-flow.md §1.1). |
| `roundRect` of the interface: `CanvasPath.roundRect`, `RoundRectGeometry`, `roundRectGeometry` (the HTML steps 1 to 11), `roundRectCornersGeometry` and `roundRectRadiusScale` (the flips and step 11 for four radii, Chart.js ADR 0158), `Path2D.roundRect`, `RoundRectCommand` | `lib/src/canvas/canvas.dart:184-196`, `:199-345`, `:1008-1023`, `:1321-1343`; `roundRectCornersGeometry` and `roundRectRadiusScale` at `canvas.dart:328-430` (2026-11-17) | 199 before Chart.js ADR 0158, 256 after | None. The pure layer has no `dart:ui`. | **Keep**. A performance addition (porting-flow.md §1.1). |
| The fast paths of the context: `_RRectClip`, `roundRect`, the `drawRRect`, sole shape and `drawDRRect` branch of `fill` (with no draw call for a shape with no area, N2 of §7), `_soleShape`, `_ring`, the `clipRRect` branch of `clip`, `debugPath`, `debugRing`, `debugSoleShape` and `debugClips` | `canvas_ui.dart:407-414`, `:571-622`, `:1312-1314`, `:1373-1400`, `:1438-1472`, `:1514-1518` | 115 | None | **Keep**. A performance addition (porting-flow.md §1.1). |
| N1 of §7: the save of the recording canvas only for a state with a clip of its own (`_begin`, `_ownsClips`, `save`, `restore`, the first save in `clip`), and `debugPendingCircles` | `canvas_ui.dart:566-569`, `:700-723`, `:1017-1040`, `:1522-1529` | ~60 | None. A `ui.Canvas` has no state stack without its saves. | **Added** (§7). A performance addition (porting-flow.md §1.1). |
| `CircleBatch`, with a color for each instance of a run that meets another color below 16 circles (N5 of §7), and the held run of a run of markers (`hold`, `addHeld`, `addHeldColors`, `release`; the held paths of `UiCanvasContext.tryAddRunCircle` and `tryAddRunCircleColors`) | `lib/src/canvas/canvas_ui_batch.dart` | whole file | None. Flutter does not merge `drawCircle` calls. | **Keep** (cut 3) |
| Text rotation snap of 2 degrees | `lib/src/canvas/canvas_ui.dart:114-117` (`_textAngleStep`), `:2779-2816` (`_snappedTextMatrix`) | ~40 | Fixed on Flutter `master`, not in a stable release | **Keep** until a stable release has the fixes (cut 3) |
| `RenderChartHost.displaySize` (was `chartSize`): the two px styles, else the render size. The host has no CSS rule for one style. | `lib/src/platform/chart_host.dart:1047-1060` | 14 | The harness matcher `toBeChartOfSize` takes the rule for one style | **Done** (C2): the rule for one style moves to the harness of phase 5 |
| `UiCanvasElement.devicePixelRatio` and `logicalSize` | removed (`canvas_ui.dart:143`, `:176-193` at 69f9d97) | 0 | The host gives the paint scale | **Done** (C2): removed |
| The paint mapping: display / bitmap for each axis, exactly 1 / DPR within 1e-3 | `chart_host.dart:1220-1224`, `:1247-1256`, `:1280-1281` | 17 | `Canvas.scale` in `UiCanvasContext.paint` | **Done** (C2): the one mapping from the bitmap to the display size |
| `initCanvas` over the attributes (`getAttribute`) | `lib/src/platform/platform.flutter.dart:111-180` | 70 | A small attribute model on `UiCanvasElement` | **Done** (C2): line by line |
| `releaseContext` over the attributes (`removeAttribute`, `setAttribute`) and `_Initial[prop]` | `platform.flutter.dart:477-512`, `:87-88` | 38 | The same attribute model | **Done** (C2): line by line |
| The attribute model: `UiCanvasElement({int? width, int? height})`, `getAttribute`, `setAttribute`, `removeAttribute`, `_setSize`, and the 3 members of `HTMLCanvasElement` | `canvas_ui.dart:239-332`, `canvas.dart:479-491` | 107 | None. `dart:ui` has no attributes. | **Added** (C2). Chart.js ADR 0022 §4 adds the `style` attribute and the string attributes. |
| The reflection of the `style` attribute in `UiCssStyleDeclaration`: `cssText`, `styleAttribute`, the declaration parser and the serialization after a CSSOM write | `canvas_ui.dart:101-227` | ~95 | None. `dart:ui` has no CSS. | **Added** (Chart.js ADR 0022 §4): `acquireChart` sets the canvas attributes with `setAttribute` |
| `getMaximumSize`, `retinaScale`, `readUsedSize` (ported, with `DIVERGES` rows) | `lib/src/helpers/helpers.dom.dart` | — | None. `AspectRatio` and `SizedBox` give other sizes than upstream. | **Keep**, no change |
| The first `ResizeObserver` notification at the next layout (`_pendingFirstResize`) and the mutation checkpoint (`flushCanvasMutations`, `_pendingConnectionChecks`) | `chart_host.dart:632-648`, `:692`, `:927-928`, `:979-996`, `:1021-1036`, `:1158-1185`, `:1202-1211` | ~60 | None. Flutter layout has no rendering step for observers and no microtask checkpoint for the tree. | **Added** (Chart.js ADR 0022 §10): the harness gives the specs the DOM timing |
| Host attach at the first layout, resize observers, host follows the chart size, unbounded rule, clip | `chart_host.dart:578-695`, `:945-1032`, `:1080-1245`; `platform.flutter.dart:578-630` | ~340 | None. Flutter layout cannot know the size that Chart.js picks. | **Keep** |

## 2. Cut 1: arcs and transforms on dart:ui

### 2.1 Current code

`lib/src/canvas/canvas_ui_path.dart` has 1554 lines.

- 1-42: the library doc. It says that arcs become cubic Béziers under other transforms.
- 53-253: `UiTransform`. The flags are `isAxisAligned` (80), `isSimilarity` (85), `scaleFactor`
  (88), `angle` (91), `isReflected` (94), `isInvertible` (97) and `isTranslation` (100).
  `writeMatrix4` is at 204-216 and `writeInverseMatrix4` is at 220-233.
- 255-270: `canvasArcSweep`.
- 272-384: the deferred commands (§7, N3), `UiSector` with the tolerances of `singleSector` (§7,
  N4), and `_PathPoint` (N3).
- 392-1417: `UiPathBuilder`. The deferred commands are 400-605, and `singleSector` is 680-849.
  - 627-632 and 642-672: the shape tracking of the rounded rectangle fast paths (`singleRRect`,
    `shapePair`).
  - 1030-1130: `roundRect`, `_mappedRRect` and `_roundRectSegments`. The segments call `_addArc`.
    Since Chart.js ADR 0158 (2026-11-17), `_mappedRRect` is `mappedRRect` and `mappedRRectOf`, and
    `roundRect` ends in `addRoundRect`; use the named anchors.
  - 1132-1176: `arc`, with the full-circle fast path at 1154-1173.
  - 1179-1205: `ellipse`.
  - 1208-1270: `arcTo` (the DOM tangent arc).
  - 1276-1324: `_addArc`. The similarity branch is 1290-1299. The axis-aligned branch with the
    reflection cases is 1300-1322. The Bézier fall-back is 1323.
  - 1331-1362: `_nativeArc`.
  - 1366-1416: `_bezierArc`.
- 1419-1530: `rrectContains` and `_cornerContains`.
- 1532-1554: `_CachedPath` and `uiPathOf`.

`lib/src/canvas/canvas_ui.dart` uses `UiTransform` for the state (275, 299), the shared matrix
buffer `_m4` (370), the transform setters (836-874), the shader matrix (637-641), the strokes
(692-763), the rectangles (777-1035), `fill` (1109-1176), `stroke` (1199-1217), `clip`
(1221-1249), the text (1485-1547) and `drawImage` (1622-1641). `canvas_ui_batch.dart` gets
centers that are already in bitmap space. It does not use `UiTransform`.

### 2.2 What dart:ui does (Flutter 3.44.9, probed)

The results were the same on the VM, on CanvasKit and on skwasm.

| API | Behavior |
|---|---|
| `arcTo(rect, start, sweep, forceMoveTo)` | It converts the angles to float degrees. A sweep of 2 pi adds nothing. A sweep of `2 * pi - 1e-12` adds nothing. A sweep of 3 pi adds a half circle. With `forceMoveTo: false` on an empty path, Skia starts with a move. After `close()`, Skia draws a line from the start of the closed subpath to the arc start. |
| `addArc`, `addOval` | They start a new contour, and a full sweep gives a closed contour. Do not use them: they have no connecting line. |
| `extendWithPath(src, offset, matrix4:)` | Skia `addPath` in extend mode. On an empty path, the first point is a move. Otherwise, a line connects the current point to the first point of `src`, also after `close()`. Conic segments map with their weights, so a skewed arc is exact (radius error 1e-5 user units at radius 100). |
| `addPath(..., matrix4:)` | It always starts a new contour. Do not use it: `moveTo(c)`, `arc`, `closePath` would close to the arc start and not to `c`. |
| `transform(matrix4)` | It returns a copy and keeps the fill type. |

**The web renderers read the source path and the matrix late.** On CanvasKit and on skwasm,
`LazyPath` (`engine/src/flutter/lib/web_ui/lib/src/engine/lazy_path.dart:316-340, 375-381,
423-443`) keeps a reference to the source path of `extendWithPath` and to the `Float64List` of
`extendWithPath` and `Path.transform`. It builds the native path at draw time. The frame arena
discards the built path at the end of a frame, and the next use builds it again from the same
references. The probe reset the source path and wrote a new matrix after the call. On the VM the
path ended at (50, 60), which is correct. On CanvasKit and on skwasm it ended at (115, 15), which
is wrong. Thus each `extendWithPath` call and each `Path.transform` call must get its own `ui.Path`
and its own `Float64List`. Never reuse a scratch path or `_m4` for them.

### 2.3 A web defect in the current code

The same aliasing is a defect today, on the web only. Work package W fixes it before cut 1.

- `canvas_ui.dart:1491`: `stroke()` under a transform that is not a similarity calls
  `_strokeUser(_path.path.transform(t.writeInverseMatrix4(_m4)))`. `_strokeUser` then writes the
  forward matrix into `_m4` (`:936`) before `drawPath` builds the lazy path. The probe was
  `transform(1, 0, 0, 3, 0, 0)`, a line at y = 10 and `stroke()`. On the VM, rows 27 to 32 had ink.
  On CanvasKit and on skwasm, nothing was drawn.
- `canvas_ui.dart:1509`: a `Path2D` clip calls `uiPathOf(path2d).transform(s.transform.writeMatrix4(_m4))`.
  The state keeps the clip and replays it into later recordings. After the frame arena discards
  the built path, the path builds again with the value that `_m4` has then. The probe did not show
  it, because the probe rendered no second frame.
- `canvas_ui_paint.dart:136` and `:373-377`: `shaderFor` keeps a copy in `_lastMatrix`, but
  `_build(matrix)` gives the caller's matrix (the shared `_m4`, from `canvas_ui.dart:837`) to
  `ui.ImageShader`. CanvasKit keeps that reference (`canvaskit/shader.dart:252`) and builds the
  shader again from it when the filter quality changes. The risk is low.

The canvas tests are `@TestOn('vm')`. `test:web` runs `dart test -p chrome` and cannot compile
`dart:ui`. Thus no repository test sees these defects.

### 2.4 Target design

- **The direct path stays.** When `rx == ry` and `t.isSimilarity`, `_addArc` keeps the current
  similarity branch: a `ui.Path.arcTo` on a circle in bitmap space, with `t.angle` and
  `t.isReflected` in the start angle. This covers every arc of Chart.js core (`retinaScale` plus
  `translate`), the point styles, `rectRounded`, the doughnut and the polar area.
- **The matrix path replaces the rest.** For every other case (a skew, a non-uniform scale, a
  mirror with a non-uniform scale, an ellipse with `rx != ry`, a rotated ellipse), a new method
  `_matrixArc(cx, cy, rx, ry, rotation, start, sweep)` does these steps:
  1. It builds a **new** `ui.Path` and adds the arc in user space on
     `Rect.fromLTRB(-rx, -ry, rx, ry)` with the half split of `_nativeArc` (one `arcTo`, or two
     half arcs when the absolute sweep is more than pi).
  2. It builds a **new** `Float64List(16)` for `T * [cos(rotation), -sin(rotation), cx;
     sin(rotation), cos(rotation), cy]`, column-major. `T` is the current `UiTransform`.
  3. It calls `path.extendWithPath(arc, Offset.zero, matrix4: m)`.
  4. It computes the user-space start point and end point (rotated by `rotation`, moved to
     (cx, cy)) and maps them with `t.mapX` and `t.mapY`. When `hasSubpath` is false, it sets
     `_startX`, `_startY` and `hasSubpath` from the start point. It sets `_lastX` and `_lastY`
     from the end point.
  5. A sweep of 0 does a line (or a move on an empty subpath) to the mapped start point, as
     `_nativeArc` does today. Do not depend on the Skia rule for a sweep of 0.
- **The rule "a point maps at add time" stays.** The arc maps with the transform of the call. A
  later transform change does not move it, and the path survives `save` and `restore`.
- **`UiTransform` does not change.** The similarity branch, the pending circle and
  `_snappedTextMatrix` read `angle`, `isReflected` and `scaleFactor`. The skwasm race of
  performance.md §5.5 depends on the snap. A later change can compute `angle` at its users, but it
  is not part of this plan.
- **Everything else stays:** `canvasArcSweep`, the half split, the current point, the DOM `arcTo`
  math, `rect()`, the pending circle, `CircleBatch` and `uiPathOf`.

### 2.5 Change list

Do step 0 in work package W. Do steps 1 to 6 in work package C1.

0. **Fix the web aliasing** (work package W, its own commit,
   `fix(flutter_chartjs_port): copy the matrices that the web paths read late`):
   - `canvas_ui.dart:1491`: `t.writeInverseMatrix4(Float64List(16))`.
   - `canvas_ui.dart:1509`: `s.transform.writeMatrix4(Float64List(16))`.
   - `canvas_ui_paint.dart` `shaderFor`: call `_build(_lastMatrix)`, so that the shader keeps the
     copy and not the buffer of the caller.
   - Add a comment at each place: the web renderers read the path and the matrix when they build
     the path.
   - The VM pixels do not change. Prove the fix in Chrome (§6.4).
1. Add `_matrixArc` as §2.4 describes. Give the half split one shared helper, for example
   `_appendArc(ui.Path p, ui.Rect oval, double start, double sweep, bool forceMoveTo)`, and call
   it from `_nativeArc` and from `_matrixArc`.
2. In `_addArc`, keep the zero-radius case and the similarity branch. Send every other case to
   `_matrixArc`.
3. Delete the axis-aligned branch (`:1300-1322`) and `_bezierArc` (`:1364-1416`).
4. Do not change `arc`, `ellipse`, `arcTo`, the pending circle, `UiTransform`, `canvas_ui.dart`
   or `canvas_ui_batch.dart`.
5. Update the library doc (`canvas_ui_path.dart:1-42`) and the doc of `_addArc`: the direct path,
   the matrix path, and the rule of §2.2 (a new path and a new matrix for each call).
6. If a threshold of the new test file (work package A1) fails only on antialiased edges, adjust
   the threshold in the same commit and say why in the commit message.

Rejected options:
- **Send the similarity branch through the matrix path too** (about 50 more lines out). The matrix
  path is about 3 times slower (§2.8), and on the web it adds one lazy command chain and two
  allocations for each arc. Doughnut slices and rounded bars would pay that cost.
- **Replace `UiTransform` with `vector_math` `Matrix4`.** It removes at most 20 lines, adds a
  dependency and keeps every flag.
- **Map the whole path at draw time with `Canvas.transform`.** A path whose points were added
  under different transforms has no single transform.

### 2.6 Tests

The tests that pin the current behavior are in `test/port/canvas/canvas_ui_test.dart`
(`@TestOn('vm')`): the group `transforms` (400-482), the group `paths` (667 and later, with "a
full circle and a negative radius", "a sweep just under a full turn fills a circle", the group "a
full circle on an empty path", "arc connects to the current point with a line", "a rotated
ellipse and arcTo draw", "fill and stroke a Path2D under the transform"), the group `rotated text`
(1251-1293) and the group `circle batch` (1522 and later, 28 tests). They must stay green without
a change. The `helpers.canvas` specs use `MockContext`. They record calls and never reach
`dart:ui`, so they are no evidence for cut 1.

Only two current tests reach the code that goes: "a rotated ellipse and arcTo draw" (ink probes
only) and the last part of "a sweep just under a full turn fills a circle" (`scale(1, 0.5)`, the
positive axis-aligned case). No test covers a partial arc under a mirror, a skew or a non-uniform
scale. Thus work package A1 adds a new file before the cut.

`test/port/canvas/canvas_ui_round_rect_test.dart` (`@TestOn('vm')`) also reaches `_addArc`.
`roundRect` under a rotation or a skew adds the HTML segments, and their arcs go through
`_addArc`. The test "the path under a rotation and a skew" compares them with the upstream arcs.
Under a skew both paths have Bézier arcs that go round in opposite directions, so its edge
tolerance is 48 of 255. It must stay green after C1. If C1 makes the edges closer, C1 can lower
that tolerance. The other tests of the file pin the rounded rectangle fast paths and do not reach
the code that goes.

**New file `test/port/canvas/canvas_ui_path_test.dart`.** It starts with the port-only header
line and `@TestOn('vm')`. It copies the small `_render` and pixel helpers of `canvas_ui_test.dart`.
Each pixel test compares with a reference that plain `dart:ui` draws: `canvas.transform(M)` and a
user-space `Path.arcTo` or `addOval` of the same shape. The thresholds:
- The probes inside and outside the shape are exact.
- The worst channel differs by at most 24 of 255, on antialiased edge pixels only.
- The ink count is within 1 %.
- Each probe is at least 2 pixels from an edge.

The test list:
1. A partial arc (sweep 3 pi / 2), clockwise and counterclockwise, under the skew
   `transform(1, 0, 0.5, 1, 0, 0)`.
2. Partial arcs under `scale(2, 0.5)`, `scale(-2, 0.5)`, `scale(2, -0.5)` and `scale(-2, -0.5)`,
   clockwise and counterclockwise. The wedge is in the mirrored quadrant. These pin the four
   reflection cases that go.
3. Partial arcs (0 to pi / 2 wedges from the center) under `scale(-1, 1)`, `scale(1, -1)` and
   `scale(-1, -1)`. These stay on the direct path and pin it.
4. A partial arc under `rotate(pi / 3)` and `scale(2)`: the start point, through a `lineTo` back
   to the center.
5. A rotated ellipse (rx 40, ry 15, rotation pi / 6) under the identity, under `rotate(pi / 5)`
   and under `scale(2, 1)`, with start and end angles, clockwise and counterclockwise.
6. A full sweep and a sweep of `2 * pi - 1e-9` under a skew: a near-full ellipse (two halves).
7. A sweep of 0 under a skew: only the connecting line. The current point is the arc start.
8. `moveTo(c)`, a skewed arc, `closePath`, `fill`: the wedge closes to `c`. This guards against
   `addPath`.
9. `closePath`, then a skewed arc: the line starts at the start of the closed subpath.
10. Map at add time: a skewed arc, then `setTransform(1, 0, 0, 1, 0, 0)`, then `lineTo`. The arc
    does not move, and the line starts at the bitmap end point of the arc.
11. The path survives `save` and `restore`: `save`, skew, `arc`, `restore`, `stroke`.
12. A DOM `arcTo` after a skewed arc. It reads the current point back through the inverse.
13. An `ellipse` with one radius of 0 under a skew: a line when stroked, nothing when filled.
    Both radii 0 under a skew: a line or a move to the center.
14. A dashed stroke of a skewed arc: the count of dash runs on one probe row.
15. A clip with a skewed arc path.
16. A `Path2D` with a rotated ellipse, with `fill(path2d)` and `stroke(path2d)` under a skew.
17. A nonzero ring: an outer circle under the identity and an inner circle under a mirror about
    its center.
18. Unit checks without pixels: `singleCircle` is `null` for a full circle under a skew or a
    non-uniform scale, and not `null` under a similarity. `hasSubpath`, `isEmpty` and `singleRect`
    after arcs.
19. The order of argument errors under a singular transform: a negative radius throws before the
    invertibility test. A non-finite rotation does nothing.
20. Rotated text under a mirror (the snap reads `UiTransform`).

All tests must be green on the current code before C1 starts.

**Web probes (work package A1, and again in W and C1).** No repository suite runs the `dart:ui`
layer on the web. Use a scratch package outside the repository, with a path dependency on
`packages/flutter_chartjs_port`, and run `flutter test --platform chrome` and
`flutter test --platform chrome --wasm` on a copy of tests 1, 8 and 10 and of these two probes:
- A stroke under `transform(1, 0, 0, 3, 0, 0)` of a line at y = 10 must ink y = 30.
- A `Path2D` clip under `translate`, replayed after at least one more rendered frame with other
  draws.

Run each probe in the first frame and again after at least one more frame, so that the frame arena
builds the path again. Record the result in the Evidence section of Chart.js ADR 0013. Before W,
the stroke probe fails on CanvasKit and on skwasm. Work package I can put the same probes in a
gallery integration test.

### 2.7 ADR and doc changes

Chart.js ADR 0013 is accepted (2026-10-21), so the owner does not edit its text. A new ADR states
the complete decision with the changes below and supersedes Chart.js ADR 0013.
- §6 (lines 150-165): replace "An arc uses `ui.Path.arcTo` when ... cubic Béziers of 90 degrees
  or less" with the direct path and the matrix path of §2.4. State that each `extendWithPath` call
  and each `Path.transform` call gets its own `ui.Path` and `Float64List`, because the web
  renderers read them when they build the path.
- §7 or §8: one sentence on step 0, and one sentence on the cost of the matrix path.
- Evidence: the new test file, the probe figures of §2.8 and the web runs.
- Open: no repository suite runs the `dart:ui` layer on the web. Name the scratch-package method.
- `parity.md`: row 376 (`canvas_ui_path.dart`), "else cubic Béziers" becomes "else a user-space
  `ui.Path.arcTo` that `extendWithPath(matrix4:)` appends". Row 375 and row 377 get the matrix
  copies of step 0. Add a row for `test/port/canvas/canvas_ui_path_test.dart`.
- `performance.md`: a new section with the arc figures (§2.8 and §6.3).
- Chart.js ADR 0034 does not change. Conics in place of Béziers give a display-only
  difference. Thus there is no `DIVERGES` row and no superseding ADR.
- `porting-flow.md` §2.2 and `differences.md` do not change.

### 2.8 Speed of the matrix path

Scratch probe, debug build (JIT), 20000 partial arcs:

| Case | VM | skwasm |
|---|---:|---:|
| Current code, retina scale (direct arc) | 4.8 ms | 6.0 ms |
| Current code, rotation (direct arc) | 4.9 ms | 6.2 ms |
| Current code, skew (Bézier arc) | 5.2 ms | 6.5 ms |
| Matrix path, a new path and a new matrix for each arc | 13.5 ms | 23.4 ms |

The matrix path is about 2.8 times slower on the VM and 3.6 times slower on skwasm (about 0.7
microseconds for each arc on the VM). Chart.js core draws no arc under a skew or a non-uniform
scale, so a chart keeps its current speed.

### 2.9 Risks

1. **The web reads the path and the matrix late** (proven, high). The VM tests cannot see a reuse
   of a scratch path or of `_m4`. Step 0, the rule of §2.4 and the web probes cover it.
2. **Extend-mode rules are engine behavior** (medium). The line after `close()` and the skipped
   line of length 0 come from Skia. Impeller (`DlPath`, Metal and Vulkan) can differ. Tests 7, 9
   and 17 pin them on the VM. The Canvas tab of the gallery on macOS and on the Pixel 8a, or work
   package I, checks Impeller.
3. **No current test pins the code that goes** (high). Work package A1 lands first and is green
   on the current code.
4. **Precision** (low, display-only). Exact conics replace Béziers of 90 degrees. Dash positions
   on a skewed arc move by sub-pixels. Use the edge thresholds and the run counts of §2.6, not
   exact pixels.
5. **Speed of the matrix path** (low). It is about 3 times slower for each arc, and only off the
   Chart.js core paths.

### 2.10 Estimated lines

| Item | Removed | Added | Net |
|---|---:|---:|---:|
| `canvas_ui_path.dart` | ~95 (`_bezierArc` 54, axis-aligned branch 31, doc 10) | ~50 (`_matrixArc`, the matrix, `_appendArc`, doc) | about -45 |
| Step 0 (`canvas_ui.dart`, `canvas_ui_paint.dart`) | 0 | ~6 | about +6 |
| `canvas_ui_path_test.dart` (new) | 0 | ~350 to 400 | — |
| Docs (ADR 0013, `parity.md`, `performance.md`) | — | ~40 changed | — |

## 3. Cut 2: host sizing on Flutter layout

### 3.1 Code before C2

This section gives the code at commit 69f9d97, before work package C2. The line numbers are the
lines of that commit. §3.10 gives the code after C2.

`lib/src/platform/chart_host.dart` (916 lines, port-only):

| Lines | Part | Kind | Verdict |
|---|---|---|---|
| 21-35 | Library doc, "Sizing" | doc | Rewrite lines 31-33 |
| 129-181 | `CanvasMutationObserver`, `_notifyConnection` | Flutter adaptation | Keep |
| 183-225 | `ContainerResizeObserver` (`ResizeObserver` and DPR change) | Flutter adaptation | Keep |
| 252-255 | `_devicePixelRatio(context)` | Flutter | Keep |
| 323-338 | `devicePixelRatio` setter. Line 332 writes `_canvas.devicePixelRatio`. | mixed | Delete line 332 |
| 354-373 | `_show`. Line 371 writes `..devicePixelRatio`. | mixed | Delete line 371 |
| 385-459 | Container: `contentWidth`, `contentHeight`, `isConnected` | Flutter adaptation | Keep |
| 461-468 | `_pixels`, `_readPixels` | style parse | Keep. The style that `retinaScale` writes carries the display size. |
| 470-491 | `chartSize`: px styles, else the render size. One style keeps the render aspect (480-489). | CSS emulation | Simplify and rename to `displaySize` |
| 493-523 | `_laidOutChartSize`, `_handleCanvasChanged`, the `_checkChartSize` microtask | Flutter adaptation | Keep |
| 527-550 | Repaint boundary, `computeDryLayout`, intrinsics | Flutter | Keep, rename |
| 552-590 | `performLayout`: first attach, observers, `size = constrain(chartSize)` | Flutter adaptation | Keep |
| 592-605 | `_scheduleRelayout`, paint fall-back | Flutter adaptation | Keep |
| 609-631 | `paint`: clip of a larger chart | Flutter | Keep |
| 633-658 | `_paintCanvas`: the DOM bitmap stretch, with a fast path within 1e-3 | stretch emulation | Keep as the one mapping from the bitmap to the display size |
| 914 | `debugFillProperties` `chartSize` | debug | Rename |

`lib/src/platform/platform.flutter.dart` (624 lines, port-only, replaces `platform.dom.js`):

| Lines | Part | Verdict |
|---|---|---|
| 49-82 | `_expando`, `_ChartjsExpando`, `_Initial` | Keep |
| 104-117 | `initCanvas` doc, "A Flutter canvas has no attributes ..." | Delete lines 111-117 |
| 121-123 | `const String? renderHeight = null` and `renderWidth = null` | Read `canvas.getAttribute('height')` and `getAttribute('width')` (`platform.dom.js:45-46`) |
| 138-147 | `display: block`, `box-sizing: border-box` | Keep (upstream lines, no effect in Flutter) |
| 149-172 | Render size from `readUsedSize(style)` or the aspect ratio | Keep (upstream lines) |
| 177-187 | `_toUint32` | Keep |
| 455-495 | `releaseContext`: an absent attribute gives 300 x 150 (470-477), styles restored, `canvas.width = canvas.width` | Port `platform.dom.js:300-307` line by line with `removeAttribute` and `setAttribute` |
| 545-559 | `getDevicePixelRatio` from the host | Keep |
| 561-613 | `getMaximumSize` with the rule for unbounded constraints | Keep |
| 615-623 | `isAttached` from the host | Keep |

`lib/src/canvas/canvas.dart` (pure interface): `HTMLCanvasElement` (326-347) gets
`getAttribute`, `setAttribute` and `removeAttribute`. `CSSStyleDeclaration`, `CanvasNode` and
`CanvasContainer` do not change.

`lib/src/canvas/canvas_ui.dart`:
- `UiCssStyleDeclaration` (94-127) stays. `retinaScale` writes it, and `direction` reads it.
- `UiCanvasElement` (129-216): the constructor (136-138), the `width` and `height` setters
  (145-165), `_devicePixelRatio` (142), the `devicePixelRatio` getter and setter (175-187) and
  `logicalSize` (189-192).
- `UiCanvasContext.paint` (415-435) draws with `scale(1 / dpr)` at 425 and 429.
- The library doc at 25-31 describes that scale.

`lib/src/helpers/helpers.dom.dart` does not change. `getMaximumSize`, `retinaScale` and
`readUsedSize` are ported, and their rows `platform-dom-no-css`, `platform-dom-container` and
`platform-dom-computed-style` stay valid.

Users outside the package: `apps/chartjs_gallery/lib/demo/demo_chart.dart` (`DemoChart` with a
default `UiCanvasElement()`, responsive only) and `apps/chartjs_gallery/lib/demo/canvas_demo.dart:125`
(`UiCanvasElement(width: 32, height: 32)` for `toImageSource`). This line number is the line of
2026-10-29 (the gallery on the public libraries). On 2026-10-21 the line was 124, and at 69f9d97
it was 125. No gallery code reads `devicePixelRatio`, `logicalSize` or `chartSize`.

### 3.2 Why Flutter layout does not replace the Chart.js sizing

Chart.js must stay the one source of the chart size. The ported `getMaximumSize` and
`retinaScale`, and `core.controller._resize` of phase 5, give sizes that `AspectRatio` or
`SizedBox` do not give:
- The attach resize ignores the container height. Later observer resizes cap by it
  (`maintainHeight`, `helpers.dom.ts:191-197`). The test "a later resize with the container
  height keeps the ratio" of `chart_host_test.dart` pins it.
- `round1`, `Math.floor` and the default ratio of 2 (#4659) shape the size.
- `onResize`, the `resize` plugin hook and `resizeDelay` run from `_resize`.
- A change of `options.aspectRatio` and then `chart.resize()` runs inside Chart.js.
- The size changes the ticks and the hit tests, so Chart.js ADR 0034 requires the upstream size.

Flutter layout still has a role. The parent widgets (`SizedBox`, `AspectRatio`, `Expanded`,
`Padding`) set the constraints, and the constraints are the container of `getMaximumSize`.

The bitmap stretch also stays. It shows `options.devicePixelRatio` at the right size. Without
it, a chart with `devicePixelRatio: 1` on a DPR 3 view paints at one third of its box, the
pointer positions do not agree with the drawn elements, and the hit element changes.

### 3.3 Target design (option A)

- **An attribute model.** `UiCanvasElement({int? width, int? height})`. A size given at creation
  is the `width` or `height` attribute. A `null` side has no attribute and the DOM default (300 or
  150). The `width` and `height` setters also set the attribute, as the DOM reflects the IDL
  attribute. `removeAttribute('width')` sets 300 and resets the context.
  `removeAttribute('height')` sets 150. `setAttribute` parses a non-negative integer and falls
  back to the default. Other attribute names give `null` or do nothing.
- **`initCanvas` and `releaseContext` become line-by-line ports** over the attributes.
- **One paint mapping.** The host computes `sx = display.width / canvas.width` and
  `sy = display.height / canvas.height` (with guards for a size of 0). When `|sx * dpr - 1|` and
  `|sy * dpr - 1|` are both less than 1e-3, it uses exactly `1 / dpr`. Then it calls
  `ctx.paint(canvas, offset, sx, sy)`. `UiCanvasContext.paint` applies that scale. The canvas has
  no `devicePixelRatio` and no `logicalSize`.
- **The display size** is the two px styles that `retinaScale` writes, when both are px, else the
  render size (`canvas.width`, `canvas.height`). The CSS rule for one style moves to the harness
  matcher `toBeChartOfSize` of phase 5.
- **Everything else stays:** the attach at the first layout, the observers, the microtask check
  and the paint fall-back, the unbounded rule, the clip, `getMaximumSize` and `retinaScale`.

This fixes the default spec canvas. `acquireChart` makes a 512 x 512 canvas through its attributes
(chartjs-test-utils `utils.js:43`). Before C2, `UiCanvasElement(width: 512, height: 512)` went
through `initCanvas` with no attribute and no style, and `initCanvas` set the height to 512 / 2 =
256 (`platform.flutter.dart:121-172` at 69f9d97). The test "acquireContext initializes the canvas"
shows the same rule. Every spec that uses the default canvas would get a 512 x 256 chart.

Rejected options:
- **Option B: no attributes, no style reads in `initCanvas`, no style restore.** It removes about
  150 lines and adds 30. Upstream gives a non-responsive doughnut, pie, polar area or radar chart
  on a canvas without a height 300 x 300. The port would give 300 x 150. It needs a new
  `differences.md` row (for example `platform-canvas-css-size`), a `DIVERGES` marker, about 11
  phase 5 spec cases skipped as `diverges:`, and a new mechanism for `options.devicePixelRatio`.
- **Remove the stretch and paint at `1 / dpr` only.** `options.devicePixelRatio` breaks (§3.2).
- **Host size from `AspectRatio` or `SizedBox` in place of `getMaximumSize`.** It is a second
  source of truth, it caps the attach resize by the height, it has no `round1`, and `onResize`
  and the hook need `_resize`.
- **A size listener on `UiCanvasElement` in place of the microtask and the paint fall-back.** A
  `markNeedsLayout` from chart code that runs inside the layout of another render object (for
  example a `LayoutBuilder`) trips the layout assertions of Flutter. The microtask design is the
  evidence base of Chart.js ADR 0037 §4 and Chart.js ADR 0016.

### 3.4 Change list

Work package C2 does these steps. The plan put it after W, because both edit `canvas_ui.dart`.
C2 ran in phase 5 without W (Deferral, trigger 1). The line numbers below are the lines of commit
69f9d97. §3.10 gives the result and the differences from these steps.

1. `lib/src/canvas/canvas.dart`: add `String? getAttribute(String name)`,
   `void setAttribute(String name, String value)` and `void removeAttribute(String name)` to
   `HTMLCanvasElement`, with docs for `width` and `height` (about 18 lines). The test fakes use
   `noSuchMethod`, so they do not break.
2. `lib/src/canvas/canvas_ui.dart`, `UiCanvasElement`: the constructor `{int? width, int? height}`,
   the fields `_widthAttribute` and `_heightAttribute`, the reflection in the setters, and the
   three attribute methods (about 35 lines).
3. `lib/src/canvas/canvas_ui.dart`, the context: delete `_devicePixelRatio`, the
   `devicePixelRatio` getter and setter, and `logicalSize` (142, 175-192).
   `UiCanvasContext.paint(ui.Canvas canvas, ui.Offset offset, double scaleX, double scaleY)`
   replaces `if (dpr != 1) canvas.scale(1 / dpr)` with `canvas.scale(scaleX, scaleY)`. Rewrite the
   library doc at 25-31: the host gives the scale from bitmap pixels to logical pixels.
4. `lib/src/platform/platform.flutter.dart`: read `canvas.getAttribute('height')` and
   `getAttribute('width')` at 121-123. Delete the doc at 111-117. Port `releaseContext` (455-477)
   as the `['height', 'width'].forEach` of `platform.dom.js:300-307`, with `removeAttribute` and
   `setAttribute`. Delete the hard-coded 300 x 150 branch and its doc. Keep `_Initial`, the
   `display` and `box-sizing` writes and the `readUsedSize` lines.
5. `lib/src/platform/chart_host.dart`: rename `chartSize` to `displaySize` and delete the
   one-style branches (480-489). Rewrite `_paintCanvas` (633-658) as the one mapping of §3.3.
   Delete lines 332 and 371. Rename in 914, in the intrinsics and in the dry layout. Rewrite the
   library doc at 31-33.
6. Change the tests (§3.5).
7. Update the docs (§3.7).

### 3.5 Tests

Tests that pin the current behavior (run them before and after):
- `test/port/platform/chart_host_test.dart`: 40 tests, 41 after C2, 50 after Chart.js ADR
  0022, 73 after Chart.js ADR 0037, 111 after Chart.js ADR 0049, 112 after Chart.js ADR 0051 and
  170 after Chart.js ADR 0108. The tests are "first layout" (2), "onFirstLayout" (3, Chart.js
  ADR 0049) and the group "resize". The group "resize" tests the throttle, a DPR change, content drawn before the host
  at the display size, the clip and a later resize that keeps the ratio. Then come the group
  "display size and bitmap stretch" (7, from work package A2, 8 after C2), "unbounded
  constraints" (4), "dry layout" and the group "attach and detach". The group "ADR 0051 §9: two
  mouse models" (1, Chart.js ADR 0051) comes before the last group of the file.
- `test/port/platform/platform.flutter_test.dart` (18 tests, 21 after C2, 22 after Chart.js ADR
  0108): `initCanvas` (5, 7 after C2), "acquireContext initializes the canvas", "releaseContext
  restores the canvas", "releaseContext restores the initial attributes" (after C2), `getDevicePixelRatio`,
  `getMaximumSize` (4).
- `test/port/helpers/helpers.dom_test.dart`: `getMaximumSize`, `retinaScale` (10, with the
  `Math.floor` of the canvas size of ledger row #12142), `readUsedSize` (10),
  `platform-dom-computed-style`.
- `test/port/canvas/canvas_ui_test.dart`: "device pixel ratio" (2), "toImageSource snapshots the
  bitmap in device pixels" (836, 926 after C2, 1016 after Chart.js ADR 0022), "the pictures are
  in bitmap space at a device pixel ratio" (2.625, 1972, 2061 after C2, 2151 after Chart.js ADR
  0022). The `_render` helper at line 89 reads `logicalSize` and has about 88 callers. After C2,
  `_render` is at line 84 and takes `dpr`.
- `test/specs/helpers.dom_test.dart` (7 cases pass. The 2 `retinaScale` cases run through
  `acquireChart`. Thus the file runs on the VM only.)
- `test/port/helpers/helpers.dom_web_test.dart` (since the review of phase 5): the 5
  `getMaximumSize` cases of the spec and `retinaScale` (5), on the VM, dart2js and dart2wasm.
- `apps/chartjs_gallery/test/` (`canvas_host_demo_test.dart` line 94 expects a non-empty
  `canvas.style` width).

Before work package A2, only the test "shows content drawn before the host at the display size"
reached the stretch. It did not pin the stretch of a chart, the exact paint scale or the one-style
rule. Work package A2 added these tests to the group "display size and bitmap stretch" of
`chart_host_test.dart`. They were green on the code before C2:
1. `FakeChart(devicePixelRatio: 1)` on a DPR 2 view: bitmap 400 x 200, host 400 x 200, and a
   `fillRect` of the left half of the chart covers the left half of the `RepaintBoundary` image.
   The test is "a chart at devicePixelRatio 1 on a view at 2 fills its display size".
2. `FakeChart(devicePixelRatio: 3)` on a DPR 1 view: bitmap 1200 x 600, host 400 x 200, ink at the
   display size. The test is "a chart at devicePixelRatio 3 on a view at 1 fills its display
   size".
3. A pointer at the center of the host under test 1 gives a chart event at
   (`chart.width / 2`, `chart.height / 2`). The test is "a pointer at the center of a stretched
   chart gives the center of the chart".
4. DPR 1.5 and width 101 give bitmap 151 and a factor of 1.0033: the stretch applies. DPR 2.625
   and a box 387.43 wide (the Pixel 8a Stress tab) give a factor within 1e-3: the paint scale is
   exactly 1 / 2.625. The host paint has no `TransformLayer`. Thus the test reads the
   `Canvas.scale` calls of the host paint with a `TestRecordingCanvas`. The test is "a factor
   within 1e-3 paints at exactly 1 / devicePixelRatio".
5. A non-responsive chart with styles 345 x 125 and a bitmap of 165 x 85: the host is 345 x 125.
   The current `initCanvas` takes the render size from the styles. Thus the test sets the bitmap
   and the chart size to 165 x 85 after the construction. The test is "a non-responsive chart
   shows its bitmap at the size of its styles". C2 changed the test to
   `UiCanvasElement(width: 165, height: 85)`. The test then needs no workaround.
6. One style only (`width: 600px`): the host keeps the render aspect. A bitmap of 200 x 100 gives
   a host of 600 x 300. The style `height: 50px` alone gives 100 x 50. Work package C2 changes this
   expectation, because the rule moves to the harness. The test is "one style keeps the aspect
   ratio of the render size". C2 renamed the test to "one style alone shows the render size".
7. After `releaseContext`, the host shows 300 x 150. The test is "releaseContext gives the host the
   default 300 x 150".

Work package C2 changed these tests (the line numbers of commit 69f9d97):
- `canvas_ui_test.dart`: `_render` takes an optional `dpr` (default 1), computes the size from
  `canvas.width / dpr` and paints with `1 / dpr`. The group "device pixel ratio" becomes "paint
  maps the bitmap pixels with the given scale". The assertion "`onChanged` on a DPR write" goes.
  Delete `..devicePixelRatio = 2` at 837. The 2.625 test paints with `1 / dpr`.
- `chart_host_test.dart`: delete `expect(canvas.devicePixelRatio, 2)` (126, 149). `chartSize`
  becomes `displaySize` (172). "clips a chart that is larger than the box" uses
  `UiCanvasElement(width: 600, height: 300)`. In the group "display size and bitmap stretch",
  test 4 expects one `scale` call of (101 / 151, 50.5 / 75) at DPR 1.5. Test 6 expects the render
  size 200 x 100 for both canvases.
- Not in the list above, also changed by C2: test 5 of A2 (see above). The `paint` calls of
  `canvas_ui_test.dart` "the points stay in place under the transform of the host",
  `canvas_ui_round_rect_test.dart` "an RRect clip replays into a new recording" and
  `pixel_compare.dart` `renderContext` give the scale (1, 1). The `_Canvas` fakes of
  `test/port/elements/element.arc_test.dart` and `test/port/helpers/helpers.canvas_test.dart` do
  not use `noSuchMethod`. They get the 3 attribute members.

Work package C2 added these tests. They fail on the code before C2:
1. `canvas_ui_test.dart`, group "attributes": no attribute gives `null` and 300 x 150. The
   constructor sizes give `'512'`. A setter reflects into the attribute. `removeAttribute`
   restores the default and clears the bitmap. `setAttribute` parses, and a bad value gives the
   default. The tests are "a canvas without attributes has the default size", "a write of width
   or height sets the attribute", "removeAttribute gives the default size and clears the bitmap"
   and "setAttribute parses a non-negative integer, else the default". The group "paint maps the
   bitmap pixels with the given scale" also gets "a scale for each axis stretches the bitmap".
2. `platform.flutter_test.dart`: `initCanvas` keeps a 512 x 512 canvas. A width attribute of 400
   with ratio 1 gives 400 x 400. Attributes 165 x 85 with styles 345 x 125 keep the render size
   165 x 85. `releaseContext` restores a given attribute (180) and removes an absent one (height
   back to 150) after `retinaScale` changed both. The tests are "keeps the render size of the
   attributes", "applies the aspect ratio to a width attribute alone" and "releaseContext
   restores the initial attributes".
3. `chart_host_test.dart`: a non-responsive chart on `UiCanvasElement(width: 320, height: 240)`
   at DPR 3 gives a chart of 320 x 240, a canvas of 960 x 720 and a host of 320 x 240. The paint
   scale is exactly 1 / 3. The test is "a non-responsive chart on canvas attributes at
   devicePixelRatio 3 keeps its display size".

### 3.6 Spec case impact (phase 5)

On 2026-10-19, every case below was `blocked: core.controller`, except the 5 `helpers.dom` cases
that pass. Since 2026-10-20, the cases that need only ported modules skip as `blocked: harness`.
The others skip with the module of the latest phase that they need: the two `helpers.dom` event
cases as `blocked: controller.bar`, and the `platform.dom` event case as
`blocked: controller.line`.
Since the harness step of 2026-10-20, no case skips as `blocked: harness`. The cases of this table
give the results of the column "After option A". Where a real result differs from the prediction,
the column "After option A" gives the real result. The two
`helpers.dom` cases "leave styled height and width" and "handle devicePixelRatio correctly" pass
through `acquireChart`. The 31 `core.controller` cases of the port step pass. The Retina and
`devicePixelRatio` cases with the attributes 320 x 240 pass. The case with `data: []` passes
since the review fix of 2026-10-20: an array data gives a new Map (row `adapt-config-objects`).
"Current code" means the result that the current code would give when phase 5 runs the case.
It is the code before C2. After C2, the column "After option A" applies.
`toBeChartOfSize` (chartjs-test-utils `matchers.js:131-171`) reads the display size from the style.
The specs never see `chartSize` (`displaySize` after C2) or the stretch. Only `initCanvas`,
`releaseContext` and the attributes reach them.

| Spec file | Case | Depends on | Current code | After option A | Option B (rejected) |
|---|---|---|---|---|---|
| `platform.dom` | Context acquisition (5 cases) | — | pass | pass | pass |
| `platform.dom` | aspectRatio "default global" (620), "user" (405), "not apply when height specified" (400 x 410) | `initCanvas` style read, one-style rule | pass | pass (rule in `toBeChartOfSize`) | `diverges:` |
| `platform.dom` | aspectRatio "default chart aspect ratio" (425) | doughnut controller | `blocked: controller.doughnut` | pass after the doughnut port | `diverges:` |
| `platform.dom` | responsive false, "default canvas size" | — | pass | pass | pass |
| `platform.dom` | responsive false, "canvas attributes" (305 x 245) | attributes | **fail** (305 x 152) | **pass** | `diverges:` |
| `platform.dom` | responsive false, "canvas style" (345 x 125), "decimal display" (345.42) | `initCanvas` style read | pass | pass | `diverges:` |
| `platform.dom` | responsive false, "attributes for the render size and style for the display size" (165 x 85, 345 x 125) | attributes, stretch | **fail** (render from the style) | **pass** | `diverges:` |
| `platform.dom` | responsive true, "fit parent using aspect ratio" (150 x 245 to 214 x 350) | `initCanvas` style read | pass | pass. The callback never runs, as upstream. The construction gives 300 x 490, the first observer resize 214 x 350. `test/port/core/core.controller_test.dart`, group "the platform.dom spec cases", pins both sizes | fail or `diverges:` |
| `platform.dom` | destroy, "reset context to default values" | `canvas.width = canvas.width`, the shadow attributes | passes (Chart.js ADR 0106) | passes. Cut 2 does not change this result | passes |
| `platform.dom` | destroy, "restore canvas initial values" (attribute 180) | attributes, style restore | `n/a` | **pass** | `diverges:` |
| `platform.dom` | event handling | — | pass | `blocked: controller.line` (pass after the controller port) | pass |
| `platform.dom` | isAttached | — | `n/a` | `n/a` | `n/a` |
| `helpers.dom` | "leave styled height and width" (attributes 200, style 400) | style read | pass | pass | pass |
| `helpers.dom` | "handle devicePixelRatio correctly" (attributes 800 x 400) | attributes | pass by chance (800 / 2 = 400) | pass | pass by chance |
| `helpers.dom` | "Should not return NaN with a custom event", "consistent results" | — | pass | `blocked: controller.bar` (pass after the controller port) | pass |
| `helpers.dom` | 2 cases `diverges: platform-relative-position` | — | unchanged | unchanged | unchanged |
| `core.controller` | `maintainAspectRatio: false` group: fill parent, onResize, parent width, parent height, invisible (`SizedBox.shrink`), RTL, parent padding (`Padding`), wrapper `display: none` to block | constraints | pass | pass | pass |
| `core.controller` | `maintainAspectRatio: false`, DPR option change (render width 800, display width 400) | stretch | pass | pass | spec passes, the visible chart has the wrong scale |
| `core.controller` | canvas `display: none` to block | harness | pass or `n/a: Flutter has no CSS display on the canvas` | pass, through the first notification of the resize observer | same |
| `core.controller` | `max-width` and `max-height` with `display: none` | CSS | `n/a: Flutter has no CSS max-width` | pass. The harness CSS subset has `max-width` and `max-height`. `getMaximumSize` gives the height width / 2 for a zero height (`helpers.dom.ts:186-190`) | same |
| `core.controller` | `maintainAspectRatio: true` (2 cases, `canvas: {style: ''}`) | ratio 2 | pass | pass | pass |
| `core.controller` | Retina scale and `config.options.devicePixelRatio`, "implicit display size" (2 cases, attributes 320 x 240) | attributes | **fail** (320 x 160) | **pass** | fail |
| `core.controller` | Retina scale and `config.options.devicePixelRatio`, "explicit display size" (2 cases, style 320 x 240) | `initCanvas` style read | pass | pass | `diverges:` |
| `core.controller` | `config.options.aspectRatio` (attribute width 400, ratio 1, then 2) | harness wrapper | pass if the default wrapper is a box of the canvas display size | same | same |
| `core.controller` | attach and detach cases, "re-creating the chart" | — | unchanged | unchanged | unchanged |
| 14 of the 23 core, element and scale spec files | every case on the `acquireChart` default canvas | attributes | 512 x 256 | 512 x 512 | 512 x 256 |

Net for option A: 5 named cases and the default 512 x 512 canvas go from fail or `n/a` to pass. No
new `differences.md` row. No skip reason changes now, because every affected case is still
`blocked: core.controller`. Thus `test:cases` gives the same output. The integration of
2026-10-20 changed these reasons to `blocked: harness` and to the modules above. The counts of
`test:cases` did not change. The harness step changed the counts of `test:cases`.

### 3.7 ADR and doc changes

Chart.js ADR 0013 and Chart.js ADR 0014 were proposed in phase 5, so work package C2 edited them
in place. The porting lead accepted them on 2026-10-21. Thus a later change of these decisions
gets a new ADR that supersedes the old ADR. Chart.js ADR 0037 supersedes Chart.js ADR 0014
(2026-10-29) and keeps the host rules of its sections 2 and 5. Thus a later change of the host
rules gets a new ADR that supersedes Chart.js ADR 0037. Chart.js ADR 0034 and Chart.js ADR 0016
do not change.

Work package C2 made these changes in phase 5, except the `performance.md` figures. These figures
are for work package P. The line numbers below are the lines after C2. The lines of Chart.js ADR
0014 are the lines after its status line of 2026-10-29 (the lines after C2, plus 1). The
porting-flow.md line numbers are the lines of 2026-10-31, after the pin of Flutter 3.47.8.
- **Chart.js ADR 0014:**
  - §2 (lines 87-94): "the display size of the canvas" is the px styles that `retinaScale` writes,
    else the render size.
  - §5 (lines 147-171): the display size rule, "paint maps the bitmap to the display size with one
    scale, exactly 1 / DPR within 1e-3" in place of the stretch bullet, why the stretch stays
    (`options.devicePixelRatio`), and the attribute model.
  - Alternatives (lines 289-300): add option B, the paint at `1 / dpr` only, and the host size
    from Flutter layout, with the reasons of §3.3.
  - Evidence (lines 320-370): the new tests and their counts.
- **Chart.js ADR 0013:** §2 (lines 81-87): the `devicePixelRatio` and `logicalSize` bullet becomes
  the attributes bullet. §4 (lines 119-120): the `paint` signature. §5 (lines 128-146): `paint`
  applies the scale that the host gives. Delete the bullet on the `UiCanvasElement.devicePixelRatio`
  write. "The content keeps bitmap pixels across a DPR change" stays. The stretch bullet points to
  Chart.js ADR 0014 §5. Evidence: the test names.
- **`porting-flow.md`** (proposed): §2.2 (lines 266-267), "`paint` applies
  `scale(1 / devicePixelRatio)`" becomes "`paint` maps the bitmap pixels with the scale of the
  host". §2.7 (lines 361-364): one bullet on the canvas attributes. §3, harness table (lines
  831-832), `acquireChart`: 512 x 512 as attributes (`UiCanvasElement(width: 512, height: 512)`),
  the `canvas.style` option fills the inline style, a wrapper style becomes a `SizedBox`,
  `ConstrainedBox` or `Padding`, and the default wrapper is a box of the canvas display size. `toBeChartOfSize`: the display size rule of
  Chart.js ADR 0022 §9 (the inline px styles, else the render size, with the CSS rule for one
  style), in a pure layer. The harness step of
  2026-10-20 changed the wrapper part: a wrapper style goes through the CSS subset of `dom.dart`.
- **`parity.md`:** row 375 (`canvas_ui.dart`: no `devicePixelRatio` and no `logicalSize`, the
  attributes, the paint scale), row 382 (`platform.flutter.dart`: `initCanvas` and
  `releaseContext` line by line over the attributes), row 383 (`chart_host.dart`: "the DOM bitmap
  stretch" becomes "paint maps the bitmap to the display size"), row 389 (`canvas_ui_test.dart`)
  and row 419 (`chart_host_test.dart`). The spec rows do not change. C2 also changed row 380
  (`canvas.dart`: the 3 attribute members) and row 418 (`platform.flutter_test.dart`: the new
  tests).
- **`differences.md`:** no row for option A.
- **`performance.md`:** record the figures after the change (§6.3). C2 did not record them.

### 3.8 Risks

1. **Sharpness** (medium). The paint mapping must keep the exact 1 / DPR snap. Without it,
   fractional `round1` sizes resample the flattened images and the atlas of the circle batch. Test
   4 of A2 pins it. Check the Stress tab on the Pixel 8a by eye.
2. **The attributes change the initial ratio** (low). A responsive chart on a canvas that has
   explicit `width` and `height` now takes its initial `_aspectRatio` from them. That is the
   upstream behavior. The gallery uses default canvases and does not change.
3. **The interface grows** (low). `HTMLCanvasElement` gets 3 members. Most fakes use
   `noSuchMethod`. Two fakes did not use it: C2 gave them the 3 members (§3.5).
   `MockContext.canvas` does not change.
4. **The one-style rule moves to the harness** (medium, phase 5). If the harness does not carry
   it, the 3 aspectRatio cases of `platform.dom` fail.
5. **The saving is small.** About 90 lines go and about 80 lines come. The gain is correctness and
   one paint mapping in place of two. C2 removed 134 library lines and added 159 (§3.9).

### 3.9 Estimated lines

| Area | Removed | Added | Removed by C2 | Added by C2 |
|---|---:|---:|---:|---:|
| `chart_host.dart` (`chartSize` branches, stretch block, DPR writes, doc) | ~45 | ~15 | 65 | 51 |
| `canvas_ui.dart` (DPR field and accessors, `logicalSize`, paint, doc) | ~25 | ~3 | 50 | 75 |
| `UiCanvasElement` attributes | 0 | ~35 | (in `canvas_ui.dart`) | (in `canvas_ui.dart`) |
| `canvas.dart` interface | 0 | ~18 | 0 | 16 |
| `platform.flutter.dart` (doc, the `null` constants, the 300 x 150 branch) | ~20 | ~8 | 19 | 17 |
| **Library total** | **~90** | **~80** (net about -10) | **134** | **159** (net +25) |
| Tests (A2 and C2) | ~45 | ~340 (A2: 241) | 67 (C2) | 223 (C2), 241 (A2) |

The counts of C2 are the `git diff --numstat` lines against commit 69f9d97 (for the library) and
against the tree after A2 (for the tests). `canvas_ui.dart` is 1644 lines after C2: the attribute
model is 68 lines (137-204). The two test fakes and the 3 other `paint` callers of §3.5 are in the
test counts.

### 3.10 Result of work package C2

Work package C2 landed in phase 5 on 2026-10-19 (Deferral, trigger 1). The code after C2:
- `lib/src/canvas/canvas.dart` (983 lines): `HTMLCanvasElement` (326-363) has `getAttribute`,
  `setAttribute` and `removeAttribute` (350-362).
- `lib/src/canvas/canvas_ui.dart` (1644 lines): the library doc of the paint scale (25-33).
  `UiCanvasElement` (131-237) has the constructor `{int? width, int? height}` (137-143), the
  reflection in the `width` and `height` setters (157, 165), `getAttribute`, `setAttribute` and
  `removeAttribute` (167-180), and `_setSize` (182-204). `UiCanvasContext.paint(canvas, offset,
  scaleX, scaleY)` is at 435-460.
- `lib/src/platform/chart_host.dart` (902 lines): the library doc (31-36), the DPR setter with
  `markNeedsPaint` (331-342), `displaySize` (473-486), `_laidOutDisplaySize` and
  `_checkDisplaySize` (488-518), the paint doc and the one mapping (606-610, 633-644), and
  `debugFillProperties` (900).
- `lib/src/platform/platform.flutter.dart` (622 lines): `_Initial[prop]` (85-86), `initCanvas`
  (109-178, the `getAttribute` reads at 125-126) and `releaseContext` (458-493, the attribute loop
  at 468-475).

Differences from §3.4:
- Step 1: §3.4 said that all test fakes use `noSuchMethod`. Two fakes do not use it (§3.5).
- Step 2: the attribute model has 68 lines, not 35. The setters, `setAttribute` and
  `removeAttribute` share `_setSize`. `_setSize` applies the HTML rules for parsing non-negative
  integers, except for `-0`. The removal of an absent attribute does nothing, as in the DOM. The
  attribute names are ASCII case-insensitive.
- Step 3: `paint` calls `canvas.scale` only when a scale is not 1.
- Step 4: the doc of `initCanvas` keeps the sentence on `display` and `box-sizing`. `_Initial` gets
  `operator []` for `initial[prop]`. `releaseContext` calls `isNullOrUndef` of `helpers.core`, as
  upstream does.
- Step 5: line 332 (the DPR write to the canvas) becomes `markNeedsPaint()`, because the snap to
  `1 / DPR` reads the DPR of the host. A bitmap side of 0 gives a scale of 1. `_laidOutChartSize`
  and `_checkChartSize` become `_laidOutDisplaySize` and `_checkDisplaySize`. C2 did not add
  `debugPaintScale`: the tests read the `Canvas.scale` calls.
- The gallery code did not change. `apps/chartjs_gallery` builds for the web (wasm) and for
  Android. Its tests pass.

Not done in C2: the figures of §6.3 (work package P), the cut 2 checks of §6.4 (the browser zoom,
a move between displays) and the look at the Stress tab on the Pixel 8a (§3.8, risk 1). The
figures of §6.3 for C2 are now in [performance.md](performance.md) §9 (§5).

## 4. Cut 3: record only

Cut 3 changes no code.

### 4.1 Circle batch

`CircleBatch` (`lib/src/canvas/canvas_ui_batch.dart`, Chart.js ADR 0055 §8.5, performance.md
§5.4) stays. On the Pixel 8a it raised 20000 + 0 from 11.4 to 55.2 FPS and cut the raster time
from 82.7 ms to 9.8 ms (performance.md §4.2). Flutter does not merge `drawCircle` calls on
Impeller. Chrome's Skia does.

- **Upstream report.** Work package P drafts a Flutter feature request: "Impeller: batch
  consecutive `drawCircle` calls with one paint". It gives the baseline A scene of performance.md
  §4.4 (a `CustomPainter` with `drawCircle`) and the Pixel 8a figures. The maintainer files it.
  Then P records the issue link in performance.md §7.
- **Removal criterion.** Remove the batch when a stable Flutter release batches or merges
  `drawCircle` calls on Impeller (Vulkan and Metal) and on skwasm, so that baseline A reaches the
  figures of the batch within noise on the Pixel 8a at 20000 + 0. Then run the six scenarios of
  §6.3 with and without the batch, and remove the batch with its test group "circle batch" and
  Chart.js ADR 0055 §8.5 (through a new ADR, because 0055 is accepted). The held run of
  `tryAddRunCircle` goes with the batch, with `test/port/canvas/canvas_ui_circle_run_test.dart`.

### 4.2 Text rotation snap

The 2 degree snap of text rotation (Chart.js ADR 0015 §3, performance.md §5.5) stays. It avoids
the skwasm strike-cache race. The fixes are on Flutter `master`:
- [flutter/flutter#190048](https://github.com/flutter/flutter/pull/190048) gives each thread its
  own strike cache.
- [flutter/flutter#191014](https://github.com/flutter/flutter/pull/191014) makes that flag
  official.
- [flutter/flutter#194139](https://github.com/flutter/flutter/pull/194139) makes the semaphores
  of the FreeType locks work.

On 2026-10-19, the stable release 3.47.7 has none of the three.

On 2026-10-21, the toolchain pin (`.fvmrc`) is the stable release 3.47.7 (Dart 3.13.5, engine
`deb287481e`). It has none of the three changes. Its release branch `flutter-3.47-candidate.0`
left `master` on 2026-07-08, before the three merges. The cherry-pick of #190048 to that branch
(flutter/flutter#192115) closed without a merge. The engine sources of 3.47.7 have no
`skwasm/wasm_worker_semaphore.cc`, and `skwasm/surface.cc` does not set a strike cache for each
thread. #190048 is in the beta releases from 3.48.0-0.1.pre, and #191014 is in the beta releases
from 3.49.0-0.1.pre. #194139 merged on 2026-10-17. Only `master` has it: the beta release
3.50.0-0.1.pre does not. Thus trigger 3 did not occur.

On 2026-10-31, the toolchain pin moves to the stable release 3.47.8 (Dart 3.13.7, engine
`cf636b1dfb`), on the same release branch. Its four commits after 3.47.7 are two fixes of
`flutter_tools` (#194578 and #194740), the Dart roll (#195123) and the engine sync (#195136). Its
engine sources still have no `skwasm/wasm_worker_semaphore.cc`, and `skwasm/surface.cc` still
sets no strike cache for each thread. It has none of the three changes. Thus trigger 3 did not
occur.

**Removal criterion:** the toolchain pin (`.fvmrc`) is a stable release with all three changes.
Then remove the snap and its test group "rotated text", and run the crash case of performance.md
§5.5 (20000 + 200, `SPIN=true`) 6 times with 0 crashes.

## 5. Work packages

Each work package has one owner and its own commit (or commits) on `main`, signed off, in
Conventional Commits form. Each work package updates its own rows of `parity.md` in the same
commit. The rows differ, so the edits do not overlap. Run the gates of §6.2 before each commit.

| ID | Title | Files touched | Depends on | Parallel with | Deliverable | Acceptance | Estimate |
|---|---|---|---|---|---|---|---|
| A1 | Cut 1 tests | `test/port/canvas/canvas_ui_path_test.dart` (new), `doc/parity.md` (new row) | — | A2, A3, I | The 20 tests of §2.6. The web probe results of the current code, in the commit message. | Green on the current code. Gates of §6.2. | ~400 test lines, 1 day |
| A2 | Cut 2 tests | `test/port/platform/chart_host_test.dart`, `test/port/platform/platform.flutter_test.dart`, `doc/parity.md` (row 419) | — | A1, A3, I | The 7 tests of §3.5 that pin the stretch and the display size | Green on the current code. Gates. | 241 test lines, 0.5 day. **Done in phase 5** (2026-10-19, trigger 1) |
| A3 | Arc scenario and new baselines | `apps/chartjs_gallery/lib/demo/stress_demo.dart`, `apps/chartjs_gallery/lib/main_stress.dart`, `apps/chartjs_gallery/test/canvas_host_demo_test.dart` (if needed), `apps/chartjs_gallery/test/stress_elements_test.dart` (if needed), `doc/performance.md` (new baseline section) | — | A1, A2, I | `--dart-define=POINT_STYLE=<style>` in the stress entry. The baseline of §6.3 on 3 platforms. A scratch micro-benchmark of 5000 wedges (not committed). See the note on A3 below. | Baseline recorded with the commit hash. Old tables marked stale. | ~40 lines, 1 day of runs |
| I | Renderer probes (optional) | `apps/chartjs_gallery/integration_test/canvas_paths_test.dart` (new), `apps/chartjs_gallery/pubspec.yaml`, root `pubspec.lock` | — | A1, A2, A3 | The web probes of §2.6 as a gallery integration test | Runs on the Pixel 8a, on macOS and in Chrome (dart2js and `--wasm`). Merge alone (lock file). | ~150 lines, 1 day |
| W | Web matrix aliasing fix | `lib/src/canvas/canvas_ui.dart` (1464, 1482), `lib/src/canvas/canvas_ui_paint.dart` (`shaderFor`), `doc/parity.md` (rows 375, 377) | A1 | A2, A3 | Step 0 of §2.5 | VM pixels unchanged. The stroke probe and the clip probe pass on CanvasKit and on skwasm. | ~6 lines, 0.5 day |
| C1 | Cut 1 code | `lib/src/canvas/canvas_ui_path.dart`, `test/port/canvas/canvas_ui_path_test.dart` (thresholds only), `doc/parity.md` (row 376) | A1, W | C2 | Steps 1 to 6 of §2.5 | All tests green. Web probes pass. Perf of §6.3 within the thresholds. | ~-45 net library lines, 1 day |
| C2 | Cut 2 code (option A) | `lib/src/canvas/canvas.dart`, `lib/src/canvas/canvas_ui.dart`, `lib/src/platform/platform.flutter.dart`, `lib/src/platform/chart_host.dart`, `test/port/canvas/canvas_ui_test.dart`, `test/port/platform/chart_host_test.dart`, `test/port/platform/platform.flutter_test.dart`, `doc/parity.md` (rows 375, 382, 383, 389, 419) | A2, W | C1 | Steps 1 to 6 of §3.4 and the test changes of §3.5 | All tests green. Gallery unchanged on web, macOS and the Pixel 8a. Perf within the thresholds. | ~-10 net library lines, ~+100 test lines, 1.5 days. **Done in phase 5** (2026-10-19, trigger 1) without W, with steps 1 to 7 of §3.4: net +25 library lines, +223 and -67 test lines (§3.9, §3.10). It also changed `canvas_ui_round_rect_test.dart`, `pixel_compare.dart`, `element.arc_test.dart`, `helpers.canvas_test.dart`, Chart.js ADR 0013, Chart.js ADR 0014, `porting-flow.md` and the `parity.md` rows 380 and 418. Its perf runs are in [performance.md](performance.md) §9 (the C2 acceptance below this table). |
| D | Docs | `doc/adr/0013-canvas-model.md`, `doc/adr/0014-input-events-and-chart-host.md`, `doc/porting-flow.md` | C1, C2 | P | §2.7 and §3.7 (ADR and porting-flow parts), and a "Removal" bullet in Chart.js ADR 0013 §8.1 (§4.1). C2 did the §3.7 part in phase 5. | Status lines unchanged. Links resolve. | ~60 changed lines, 0.5 day |
| P | Perf results and cut 3 notes | `doc/performance.md` (results section, §7), this plan (status of each work package) | A3, C1, C2 | D | The figures of §6.3 after C1 and after C2. The removal criteria of §4. The draft of the Flutter feature request. | Every scenario within the thresholds of §6.3, or the miss explained | ~60 lines, 1 day of runs. The figures after C2 are done in phase 5 ([performance.md](performance.md) §9). |

**C2 performance acceptance** (2026-10-19, [performance.md](performance.md) §9). All scenarios
pass on macOS and in Chrome. On the Pixel 8a, 9 of 10 scenarios pass: `bars` 1000 fails the FPS
criterion of §6.3 in the first series and in the rerun, with draw and raster in the limits.
Section 9.5 of `performance.md` gives an A/A control: on two identical APKs, the 3-pair rule also
misses. Over 21 pairs, the frame rate and the raster time have no measured change. Decision: cut 2
stays (priority 1, the upstream behavior). The two iPhone 17 Pro smoke pairs pass, at the 120 Hz
limit on both sides (§9.2 and §9.3 of `performance.md`).

**Note on A3 (phase 4).** Phase 4 added the scene modes of the stress tab (§6.3). The stress
entry takes `--dart-define=MODE=<primitives|elements|bars|arcs|chart|axes|plugins>`, and the
default is `primitives`. Phase 5 added the mode `chart`: a real chart path with the typed options
of the resolver. Phase 6 added the mode `axes`: the points of the mode `chart` on the real scales
of phase 6. Phase 8 added the mode `plugins`: the plugin cases of the frameless benchmark in the
real frame loop. For A3, this means:
- The `arcs` mode draws `ArcElement` wedges under the retina scale. Thus `MODE=arcs` at 5000 + 0
  can serve the arc micro-benchmark (a) on all three platforms.
- The micro-benchmark (b), under a skew, still needs the scratch package. No mode draws under a
  skew.
- `POINT_STYLE` is still absent.
- `apps/chartjs_gallery/test/stress_elements_test.dart` tests the modes, their N choices and
  their controls. A change of the stress controls can need a change of that test.
- `performance.md` §1 and §6 describe the modes and `MODE`. Each `STRESS {json}` line of the stress
  entry starts with the key `mode`.
- `performance.md` §8.1 has the first figures of the four modes on the three platforms. They are
  not the baseline of §6.3, because each mode ran in one process, not in 3 fresh processes for
  each scenario. They show the scale of the arc cost before A3: at 1000 arcs, about 13.5 ms of
  draw time on the Pixel 8a. §8.2 shows that the native `Path.arcTo` calls are most of that cost.
- On macOS, a stress process with several scenarios stopped to give frames after about 28
  seconds in the phase 4 runs (`performance.md` §6). Run one scenario in each process, as §6.3
  asks.

### 5.1 Merge order

1. A1, A2 and A3 in any order. Each is green on the unchanged library.
2. I, if it is done. Merge it alone, because it changes the root `pubspec.lock`.
3. W, with the web probes.
4. C1, with its perf runs against the A3 baseline.
5. C2, with its own perf runs, so that a regression has one cause.
6. D.
7. P.

A2 and C2 landed in phase 5, before the other work packages (Deferral, trigger 1). The other
work packages stay deferred.

C1 and C2 touch different library files and can merge in either order. Run the perf checks after
each. Other work commits to the same tree. Before each commit, run `git status` and stage only the
files of the work package.

Commit message examples:
- `test(flutter_chartjs_port): pin arcs under skew, mirror and non-uniform scale`
- `fix(flutter_chartjs_port): copy the matrices that the web paths read late`
- `refactor(flutter_chartjs_port): build arcs under other transforms with dart:ui`
- `refactor(flutter_chartjs_port): give the canvas attributes and one paint scale`

## 6. Verification and acceptance

### 6.1 Tests

- The tests of §2.6 and §3.5 that exist now stay green without a change, except the changes that
  §3.5 names.
- The new tests of A1 and A2 are green on the current code before C1 and C2 start.
- `check:headers` needs the port-only line-1 marker on the new test files. Each test file that
  imports `dart:ui` or `flutter_test` needs `@TestOn('vm')`, so that `test:web` does not compile it.

### 6.2 Gates

Run these from the repository root before each commit (AGENTS.md):
- `dart run melos run format:check`
- `dart run melos run analyze`
- `dart run melos run test --no-select`
- `dart run melos run test:web`
- `dart run melos run test:cases`
- `dart run melos run check:port`
- `dart run melos run gallery:build:web` (wasm)

Before a push, also run the dart2js and dart2wasm tests and the gallery on wasm in the VS Code
integrated browser. `test:web` does not compile `dart:ui`, so it gives no web coverage for these
cuts. The web probes of §2.6 and the checks of §6.4 give it.

### 6.3 Performance

Use `apps/chartjs_gallery/lib/main_stress.dart` (performance.md §6): profile build, fresh process,
7 seconds for each scenario, the figures of the first seconds.

- **Scenarios:** 1000 + 0, 1000 + 50, 5000 + 50, 20000 + 0, 1000 + 200 and 20000 + 200. Add
  `POINT_STYLE=rectRounded` at 5000 + 0 and 20000 + 0 (four quarter arcs for each point, on the
  direct arc path).
- **Arc micro-benchmark:** 5000 wedges with `arc` and `closePath`, (a) under the retina scale and
  (b) under a skew, in the scratch package (VM and skwasm). (a) must not change. (b) costs about
  3 times more (§2.8).
- **Modes (phase 4):** `--dart-define=MODE=<primitives|elements|bars|arcs>` selects the scene of
  the stress entry. The default is `primitives`, the scene of the six scenarios above. `elements`
  draws the same scene with `PointElement` and `LineElement`. `bars` draws N `BarElement` objects
  with rounded corners. `arcs` draws N `ArcElement` wedges, in doughnuts of 2 rings with 5 slices,
  under the retina scale. Its default scenarios are 100 + 0, 1000 + 0 and 5000 + 0. Thus
  `MODE=arcs` at 5000 + 0 can serve the arc micro-benchmark (a) on all three platforms. Each of
  these wedges has rounded corners and a border, so its figures do not compare with the figures
  of §2.8. The micro-benchmark (b) still needs the scratch package, because no mode draws under a
  skew. `POINT_STYLE` is still absent. In the element modes, the draw figure also has the writes
  of the element properties.
- **Runs:** 3 fresh processes for each scenario. Take the median FPS, draw (ms) and raster (ms).
  The spread from the minimum to the maximum is the noise.
- **Platforms:** the Pixel 8a (Impeller on Vulkan, 60 Hz), Chrome with dart2wasm and skwasm (raster
  time on the worker), macOS (Apple M3 Max). A CanvasKit smoke run at 5000 + 50 and with
  `rectRounded`.

**A new baseline is necessary.** The figures in performance.md cannot serve as the baseline: §2
(macOS) and §3 (Chrome) are from before the circle batch, and §4.2 (Pixel 8a) used nearest
sampling of the atlas. Work package A3 measures the baseline on the commit before W, in the same
session and the same device state. The current figures are for orientation only:

| Scenario | macOS FPS / draw / raster (§2.2, before the batch) | Chrome draw / raster (§3, before the batch) | Pixel 8a FPS / draw / raster (§4.2, after the batch, nearest sampling) |
|---|---|---|---|
| 1000 + 0 | 60 / 0.9 / 2.8 | 0.8 / 5.9 | 58.2 / 4.9 / 4.8 |
| 1000 + 50 | 60 / 0.9 / 2.7 | — | 57.7 / 5.0 / 5.5 |
| 5000 + 50 | 60 / 3.1 / 9.5 | 2.4 / 16.3 | 58.9 / 6.7 / 6.3 |
| 20000 + 0 | 39.9 / 11.9 / 23.9 | 9.3 / 38.6 | 55.2 / 11.4 / 9.8 |
| 1000 + 200 | 60 / 1.2 / 2.7 | — | 58.2 / 6.9 / 7.5 |
| 20000 + 200 | 39.9 / 12.1 / 23.8 | 10.0 / 42.1 | 54.9 / 12.0 / 11.0 |

**Acceptance for each scenario and platform:**
- The median FPS is at least the baseline median minus the larger of 1 FPS and 2 %.
- The median draw and the median raster are at most the baseline median times 1.05 plus 0.2 ms.
- No single run is outside the baseline range widened by the same margins.

A miss runs 3 more times. A miss that stays fails the work package. On the Pixel 8a, the FPS is
at the 60 Hz limit at 1000 points, so draw and raster are the main figures there. The batch
figure on the phone must hold (about 55 FPS at 20000 + 0).

Expected results: W, C1 and C2 are neutral. The `primitives` and `elements` scenes draw full
circles (the pending circle and the batch), lines and text. The `bars` and `arcs` scenes also draw
arcs, but only under the retina scale. No scene reaches the matrix path. `rectRounded` stays on
the direct path. C2 changes only the transform of the host paint.

### 6.4 Web checks

- **The aliasing probes** (§2.6) on CanvasKit (`flutter test --platform chrome`) and on skwasm
  (`--wasm`), in the first frame and after at least one more frame. Before W the stroke probe
  fails. After W and C1 all probes pass.
- **Skwasm `drawRawAtlas` cap:** run 20000 + 0 for 60 seconds with no `memory access out of
  bounds`. `git diff --stat` shows no change in `canvas_ui_batch.dart`.
- **Strike-cache race:** run 20000 + 200 with `SPIN=true` 6 times with 0 crashes (performance.md
  §5.5).
- **CanvasKit:** `flutter run -d chrome --profile` without `--wasm`. Check the Canvas tab (arcs,
  `rectRounded`, the dashed arc, the `Path2D` card) and the stress run at 5000 + 50.
- **Memory:** a `rectRounded` stress scene for 60 seconds. The heap stays flat.
- **Cut 2:** browser zoom at 90 %, 110 % and 125 % (fractional DPR), and a move of the window from
  a Retina display to a non-Retina display. Check the Events tab readout (`canvas.width x height`
  against the display size), no blur, and the sizes. This also closes the Chart.js ADR 0037 Open
  item 8, "A DPR change on a real device is not verified".

## 7. The native draw path (phase 10)

The decision of the maintainer of 2026-10-30 brings this section forward (Deferral). It keeps the
canvas calls of the ported code and changes only how `lib/src/canvas/` gives them to `dart:ui`.
Thus the recorded draw calls of the reference tests do not change: they record the Canvas 2D calls
above the layer. The pixels stay equivalent: they differ on antialiased edge pixels only, as for
the fast paths of §1.1 (Chart.js ADR 0034).

### 7.1 The draw cells

The figures are those of [performance.md](performance.md) §13.6: Pixel 8a, ms for each call. The
end is the end of the recording: `(draw + end) / upstream draw` times the upstream draw, minus the
draw.

| Cells | Port draw | Upstream draw | End | (draw + end) / upstream | Cost (performance.md §13.6, §13.7 item 11) |
|---|---|---|---|---|---|
| `chart.doughnut` draw at N 100 / 1000 / 5000 | 0.612 / 6.081 / 32.591 | 0.279 / 2.939 / 15.429 | 0.07 / 0.65 / 6.0 | 2.44 / 2.29 / 2.50 | at N 1000, the `drawPath` FFI 36.8 % and `_NativePath._arcTo` 24.2 % |
| `chart.pie` draw | 0.517 / 5.270 / 28.632 | 0.261 / 2.560 / 13.560 | 0.05 / 1.03 / 17.6 | 2.16 / 2.46 / 3.41 | the same arc path |
| `chart.polarArea` draw | 0.507 / 5.008 / 27.912 | 0.237 / 2.507 / 13.407 | 0.03 / 0.71 / 15.0 | 2.27 / 2.28 / 3.20 | the same arc path |
| `chart.c`, the draw of the update call at N 1000 / 5000 / 20000 | 1.635 / 8.670 / 34.648 | 0.372 / 1.844 / 9.707 | 1.35 / 5.14 / 12.5 | 8.02 / 7.49 / 4.86 | two colors give runs of 2 circles: `CircleBatch._drawDirect` 6.07 ms at N 5000 |
| `chart.bubble` draw at N 1000 / 5000 | 1.492 / 7.431 | 0.308 / 1.520 | 1.22 / 4.17 | 8.80 / 7.63 | a radius for each item: `_drawDirect` 5.43 ms at N 5000 |
| `chart.bar` draw at N 1000 / 5000 / 20000, after `bar-ring-zero-inner` | 2.070 / 10.544 / 42.248 | 2.524 / 14.087 / 70.767 | 5.434 / 9.359 / 80.244 | 2.97 / 1.41 / 1.73 | before `bar-ring-zero-inner`: `UiCanvasContext.fill` 5.57 ms at N 5000, `_dropPictures` 2.08 ms in the bar update at N 5000 |

The unit costs of §7.3 come from the same profile:
- `drawPath`: 2.24 ms for 2000 calls in the doughnut draw at N 1000, 1.12 µs for each call.
- `ui.Path.arcTo`: 1.47 ms for 8000 calls, 0.18 µs for each call.
- `drawCircle`: 5.43 ms for 10000 calls in the bubble draw at N 5000, 0.54 µs for each call. §7.3
  uses this cost for each draw of one shape with a paint (`drawArc`, `drawRect`).
- A leaf FFI call (`Path.moveTo`, `lineTo`, `close`, `reset`, `Canvas.save`, `restore`): about
  0.02 µs. This is an estimate: no profile gives it alone.

### 7.2 The candidate forms

| ID | Form | Native API | Cells | Semantics | Verdict |
|---|---|---|---|---|---|
| N1 | `save()` and `restore()` touch the `ui.Canvas` only for a state with a clip of its own. The first clip of a state makes its native save. A new recording replays only the levels with clips. | `Canvas.save`, `Canvas.restore` | arcs, bars, text, tooltip, legend | Exact. The layer applies the transform to the points (Chart.js ADR 0055 §6), so a native save and restore with no clip between them changes no pixel. A circle run goes on across them. | **Adopt** |
| N2 | `fill()` of one `rect`, one `roundRect` or a sole shape with no area makes no draw call. | none | bars at N 1000 and more: the inner rectangle of each bar has a width of 0 | Exact. A fill of a shape with no area has no pixel in Chromium, Skia and Impeller. | **Adopt** |
| N3 | The path builder keeps the first 32 commands of a path in a typed buffer. It builds the `ui.Path` only when a draw, a clip, a dash or a reader needs it, and then sends the later commands directly. The current point and the subpath start on an arc keep the arc, and get their coordinates at the first read. | `ui.Path` (fewer calls) | each fast path (rectangles, rounded rectangles, rings, circles, the sectors of N4) and each arc | Exact. The replay makes the calls of today, in the same order and with the same values. | **Adopt** |
| N4 | `fill()` of a circular sector draws `drawArc`: a wedge with its center (`useCenter: true`), or a ring sector as a stroke with butt caps on the middle circle, with the width of the ring. | `Canvas.drawArc` | doughnut, pie and polar area fills | Exact region: the butt stroke of a circular arc covers the ring sector between its radii. The edges differ by antialiasing only. | **Adopt** |
| N5 | A run of the circle batch with fewer than 16 circles that meets a fill or a stroke of another color goes on with a color for each instance: white sprites and `BlendMode.modulate`. A run of one color keeps the present code. | `drawRawAtlas` with `colors` | `chart.c`, `chart.c.indexable` | Exact color: white times the color is the color. The positions and the edges are those of the batch (§4.1). | **Adopt** |
| R1 | The stroke of a sector as two arcs, two lines and four bevel triangles. | `drawArc`, `drawLine`, `drawVertices` | the arc borders | Not equivalent: an overlap doubles the alpha of a border color with an alpha below 1, and edges that touch give antialiasing seams. | Reject |
| R2 | A cache of built paths across frames, keyed by their commands. | `ui.Path` | the `draw` cells only | A hit needs the same geometry. Each miss (an update, an animation) keeps a new native path for each element and frame: a layer on top, and an allocation for each item. | Reject |
| R3 | Circles of any radius and color as triangles with feathered edges, in one call. | `drawVertices` | bubble, `chart.c` | No coverage antialiasing: the feather is an approximation. About 9 triangles for each segment of a circle: more data than the draws that it replaces. | Reject |
| R4 | The fills of one color and radius with `drawPoints` and round caps. | `drawPoints` | `chart.a` | One paint for each call: the fills and the strokes of the points cannot alternate, so the paint order of overlapping points changes. The atlas keeps the order. | Reject |
| R5 | Bubbles: an atlas of radius classes of 1/4 pixel in one image, for a run of one paint with several radii. | `drawRawAtlas` | `chart.bubble` | Display-only: a radius moves by at most 1/8 pixel. But the atlas is about 0.5 MB at a DPR of 1 and 1.3 to 5.4 MB at a DPR of 2.6 for the bubble radii of the benchmark (2 to 6 CSS pixels), and an animated radius makes a new atlas in each frame. | Deferred (§7.8) |
| R6 | The bars as one atlas call of a white sprite, or as triangles. | `drawRawAtlas`, `drawVertices` | `chart.bar` | An `RSTransform` has one scale for both axes, and neither call antialiases the edges of a bar at a fractional pixel. | Reject |

### 7.3 The expected gain

Pixel 8a, with the figures and the unit costs of §7.1. A range gives the uncertain parts: the leaf
calls, the cosines and sines that N3 does not compute, and the cost of the end of a recording for
each operation of the picture.

- **Doughnut** (N1, N3, N4). For each arc, the fill draws `drawArc` (+0.54 µs) in place of
  `drawPath` (-1.12 µs), and its path makes no `arcTo` (-4 x 0.18 µs): -1.30 µs. The leaf calls (2
  `lineTo`, `close`, one `reset`, `save`, `restore`) and the 32 cosines and sines of the 8 arcs
  add -0.2 to -0.6 µs. Thus -1.5 to -1.9 µs for each arc: the draw at N 1000 goes from 6.08 to 4.2
  to 4.6 ms (-24 to -31 %). The picture has 2 operations for each arc in place of 4, so the end
  goes from 0.65 to 0.33 to 0.45 ms. (draw + end) / upstream goes from 2.29 to 1.5 to 1.7 at N
  1000, from 2.50 to 1.7 to 1.9 at N 5000 and from 2.44 to 1.6 to 1.8 at N 100.
- **Pie and polar area** (N1, N3, N4). The inner arcs of a wedge are not finite and add nothing
  (`innerEnd / innerRadius` is NaN), so each path has 2 `arcTo`: -1.12 + 0.54 - 2 x 0.18 = -0.94
  µs, and -0.15 to -0.35 µs of leaf calls and cosines, thus -1.1 to -1.3 µs for each arc. Pie at
  N 1000: the draw goes from 5.27 to 4.0 to 4.2 ms, the end from 1.03 to 0.5 to 0.7 ms, and the
  ratio from 2.46 to 1.75 to 1.9. Polar area at N 1000: the draw goes from 5.01 to 3.7 to 3.9 ms,
  the end from 0.71 to 0.36 to 0.5 ms, and the ratio from 2.28 to 1.6 to 1.75.
- **Bar** (N1, N2, N3). For each bar: no draw of the inner rectangle of width 0 (-0.54 µs) and no
  path call: 2 `reset`, 2 x 5 calls of the two rectangles of the ring, 5 calls of the inner
  rectangle, `save` and `restore` (19 leaf calls, -0.38 µs). Thus -0.9 µs for each bar: the draw
  at N 1000 goes from 2.07 to about 1.15 ms (-44 %). The picture has 1 operation for each bar in
  place of 4. When each operation costs the same at the end, the end goes from 5.43 to 1.4 ms; when
  only the draw operations cost, to 2.7 ms. (draw + end) / upstream goes from 2.97 to 1.0 to 1.5
  at N 1000, from 1.41 to 0.6 to 0.76 at N 5000 and from 1.73 to 0.6 to 0.9 at N 20000.
- **`chart.c`** (N5, N3). The code A/B of `circle-batch-instance-colors` on the Pixel 8a
  ([performance.md](performance.md) §13.6) gave the draw -76.4 / -74.4 / -73.1 %, the end -91.5 /
  -89.1 / -80.0 % and the frame -25.0 / -23.3 / -17.5 % at N 1000 / 5000 / 20000. That candidate
  also sent the runs of one color through the colors. N5 does not, so the runs of one color keep
  their figures, and the cost of that candidate in `chart.a` (+1.9 to +5.3 %) does not apply.
  (draw + end) / upstream goes from 8.02 / 7.49 / 4.86 to about 1.35 / 1.5 / 1.2.
- **`chart.a`, `chart.b`, radar and the other point draws** (N3). The pending circle of each point
  computes no cosine and sine (4 for each point). The other calls do not change. Expected: 0 to
  -10 % of the draw. No figure gives the cost of a cosine on the phone.
- **Bubble** (N3 only): 0 to -5 %. The bubble cells stay above 4 (R5).
- **Text, tooltip and legend** (N1, N3): fewer native saves and path calls, 0 to -5 %.
- **The browser** (P3, dart2wasm, skwasm). Each call that the forms remove goes from Dart through
  JavaScript to the Wasm module of skwasm. No unit figure of these calls exists. The night of §7.6
  measures them.
- **The update cells** have the same draws in their frame and gain the same absolute times.

### 7.4 The adopted forms

- **N1** (`canvas_ui.dart`). The `ui.Canvas` has a save for a state only when that state has a
  clip of its own: its clip list is not the list of the state below it. `clip()` draws the pending
  circles, makes the native save of a state at its first clip, and applies the clip. `restore()` of
  a state with a clip of its own draws the pending circles and restores the native canvas.
  `save()`, and `restore()` of a state with no clip of its own, do not touch the native canvas and
  do not draw the pending circles. A new recording replays a save and the clips only for the levels
  with clips of their own.
- **N2** (`canvas_ui.dart`). `fill()` of a `singleRect`, a `singleRRect` or a sole shape with no
  area makes no draw call. It still starts the recording and marks the content as drawn, as
  before.
- **N3** (`canvas_ui_path.dart`). `UiPathBuilder` writes each `ui.Path` command (move, line,
  quadratic, cubic, arc, rounded rectangle, close) into a buffer of 32 commands. The getter `path`
  and a 33rd command replay the buffer into the `ui.Path`; the later commands of the path go
  directly to it. `beginPath()` resets the native path only when it has commands. An arc command
  keeps its center, its radii and its angles. The replay gives the oval of today:
  `Rect.fromLTRB(cx - r, cy - r, cx + r, cy + r)` equals `Rect.fromCircle` of the radius r. The
  current point and the subpath start on an arc keep the arc. Only the DOM `arcTo` reads them, and
  then their cosine and sine come from the expressions of today.
- **N4** (`canvas_ui_path.dart`, `canvas_ui.dart`). `UiPathBuilder.singleSector` reads the buffer
  of one subpath: moves at the start only, lines, circular arcs and a close at the end only. It
  merges the arcs that continue each other into one arc group. It drops each point within 1e-6
  bitmap pixels of the end of the item before it or of the start of the arc after it. The result
  is a sector when it is one of:
  - one arc group and the center of its circle: a wedge;
  - two arc groups on one center with two radii, where the second group starts at the end angle of
    the first and goes back over the same sweep (each within 1e-9 radians): a ring sector.

  The sweep of the first group is between 0 and 2π. `fill()` with the nonzero or the even-odd rule
  draws a wedge with `drawArc(..., useCenter: true)`, and a ring sector with `drawArc(...,
  useCenter: false)` and a stroke paint with butt caps, the width of the ring and the color or the
  shader of the fill. `stroke()` and `clip()` keep the path.
- **N5** (`canvas_ui_batch.dart`). `CircleBatch.accepts` takes a fill or a stroke of another color
  when the run has fewer than `minAtlasRun` circles. `add` then writes the color of each instance
  of the run, and the run takes each later color. `flush` draws such a run with white sprites, the
  colors and `BlendMode.modulate`, or, below `minAtlasRun` circles, with `drawCircle` and the color
  of each instance. A run of `minAtlasRun` circles or more of one color that meets another color
  draws first, as before.

### 7.5 Tests

The new file `test/port/canvas/canvas_ui_native_test.dart` (`@TestOn('vm')`) pins the forms. Each
pixel test compares a form with the same drawing on the path of today, for example a `Path2D` fill
of the same commands, which takes `drawPath`. The thresholds are those of the fast paths
(`test/port/helpers/helpers.canvas_ui_test.dart`): no pixel differs in area, the worst channel
differs by at most 24 of 255, and the inked areas differ by less than 1 %. The tests of §2.6 stay
green with no change, and so do the theme goldens of the CI runner, the text-metric probe and the
reference tests.

The sector fill of N4 needs other thresholds. A probe on flutter_tester (Skia on the CPU,
2026-10-30) compared four forms of one ring sector (radii 120 and 60 bitmap pixels, 1.8 radians):
`drawArc` against the bitmap-space path of the fill before N4 differs by at most 38 of 255 on edge
pixels with a color of alpha 0.45, and by 85 with an opaque gradient. The same path in user space
under `Canvas.transform` (a `Path2D` fill) differs from the bitmap-space path by 41 and 89. Thus
the difference comes from the flattening of the curves, about 1/3 of a pixel on an edge, and not
from the form. The tests of N4 thus compare the fill of a sector with the fill of the same calls
with the path built (`drawPath`) at two scales: at the device scale, no pixel differs in area and
no pixel flips from opaque to transparent; at four times the scale, with the mean of each block of
4 x 4 pixels, the worst channel differs by at most 24 of 255 and the inked areas by less than
1 %.

The runs of several colors of N5 compare with `drawCircle` at the centers of the batch, with the
tolerance of 8 of 255 of the group "circle batch" of `canvas_ui_test.dart`. One case needs more: on
flutter_tester, a stroke of 1 pixel in a translucent color blends some edge pixels twice where the
pieces of its outline meet, and an opaque white stroke clamps them. Thus a white sprite times the
color gives up to 13 of 255 less on these pixels than `drawCircle` and the colored sprite of a run
of one color, and about 3.5 % less ink in each ring (a probe of 2026-10-30). The test of
`globalAlpha` 0.5 has the tolerance 16 and no pixel that differs in area.

### 7.6 The night A/B (the rule is written now, 2026-10-30, before any run)

The rule follows judge-r §5.1-§5.2 and the rule of the typed series of phase 10.
- **Sides.** B is the tree of the night with the forms. A is the same tree with
  `packages/flutter_chartjs_port/lib/src/canvas/` at commit `62b5477` (the base of §7). The A and B
  worktrees differ only in `lib/src/canvas/`, and the SHA-256 of their diff equals that of the
  frozen patch `git diff 62b5477 <the last commit of §7> -- packages/flutter_chartjs_port/lib/src/canvas`.
  The benchmark files are the same on both sides.
- **Builds.** Profile builds of `apps/chartjs_gallery/lib/main_bench.dart`, one at a time, with
  `taskpolicy -b` and the SHA-256 of each binary before each run. The stress entry
  `lib/main_stress.dart` for the raster check.
- **Platforms.** Deciding: macOS AOT (Apple M3 Max, the gate of the quiet Mac) and the dedicated
  Chrome with dart2wasm. Added: the Pixel 8a and the iPhone 17 Pro (stage 1).
- **Method.** A fresh process (or a page load after `about:blank`) for each run; the run value is
  the median of 15 batches; ABBA; stage 1 pairs 1-6, stage 2 pairs 7-12 when a primary interval
  includes 0 or a cell has fewer than 6 valid pairs; the cell value is the mean of the pair
  differences B - A with a 95 % percentile bootstrap (20000 resamples, seed 20261023); the warm-up
  rule after a gate wait of more than 300 s.
- **Selector.** `CASES=chart,chart.c.indexable,plugins,tooltip,fill,legend,title`: 103 cells (the
  48 cells of `chart`, the 3 cells of `chart.c.indexable` and the 52 plugin cells of
  [performance.md](performance.md) §14.9).
- **Metric.** `draw+end` for a cell of the call `draw`; the frame sum `update+draw+end` for a cell
  of the call `update`; the primary metric of the BENCH line for a plugin cell.
- **Primary cells** (18): `chart.doughnut`, `chart.pie` and `chart.polarArea` draw at N 100, 1000
  and 5000; `chart.bar` draw at N 1000, 5000 and 20000; `chart.c` and `chart.c.indexable` update at
  N 1000, 5000 and 20000.
- **Guard cells** (9): `chart.a` draw at N 1000, 5000 and 20000; `chart.bubble` draw at N 1000 and
  5000; `chart.radar` draw at N 1000; `chart.b` line update at N 5000; `tooltip.still` with the
  tooltip and 3 datasets at N 1000; `legend.line` draw with the legend at N 1000.
- **Control cells:** the other 76 cells. h* = 5, the smallest h with P(X >= h) <= 0.05 for
  X ~ Bin(76, 0.025).
- **Classes** (each cell, each deciding platform, after its last stage): GAIN when the upper end of
  the interval lies below 0; REGRESSION when the lower end lies above the larger of +0.1 ms and
  +2 % of the A mean; else NEUTRAL.
- **Decision** (each deciding platform): ACCEPT when each primary cell is GAIN, no guard cell is
  REGRESSION, h < h* (h: the control cells with the interval wholly above 0), and no large control
  hit (a lower end of 0.1 ms or more and of 5 % or more of the A mean) repeats in a 6-pair
  confirmation series. REJECT when a primary or a guard cell is REGRESSION, h >= h* or a large
  control hit repeats. Else OPEN. The forms stay when both deciding platforms give ACCEPT and the
  raster check passes. After a REJECT or an OPEN, the forms stay in the tree for one more night.
  That night runs the frozen patch of each form (N1 to N5, each alone on A) with this rule for the
  cells that failed, and a form that the rule rejects goes out of the tree.
- **Added platforms.** A primary or guard interval wholly above 0 starts a 6-pair confirmation. A
  confirmed REGRESSION is a REJECT.
- **Raster check** (the benchmark times the UI thread only). Stress builds of A and B on macOS
  (the Pixel 8a added): `MODE=chart`, `CALL=draw`, `TYPE` doughnut, pie, polarArea and bar at
  `SCENARIO=1000x0` and `5000x0`, and `TYPE=line`, `SCRIPTABLE=1`, `CALL=update` at `5000x0`. 3
  fresh runs of each side, A B A B A B, 7 s each. The check fails when the median `rasterMs` of B
  is more than the larger of 0.1 ms and 2 % above A, or the median FPS of B is more than 1 FPS
  below A.
- **Expected:** §7.3.
- No rule changes after the first run. An independent agent recomputes each figure and decision
  from the raw files in the morning.

### 7.7 ADR and doc changes

- Chart.js ADR 0013 is accepted. N1 changes the flush points of its §8.1 (a `save()` and a
  `restore()` with no clip of their own are no flush points), N5 changes the run of §8.1 (a short
  run takes several colors), and N3 and N4 add to its §6 and §8 (the buffer of the path builder
  and the sector fill). [Chart.js ADR 0055](adr/0055-native-draw-path.md) (proposed) states the
  complete decision. It waits for the night of §7.6, and on acceptance it supersedes Chart.js ADR
  0013. A form that the night rejects goes out of the tree and out of the ADR before the
  acceptance.
- porting-flow.md §5.1 records the trigger. `performance.md` gets the figures of the night (the
  porting lead).
- `differences.md` gets no row: the canvas calls of the ported code do not change, as for
  `bar-ring-zero-inner`.

### 7.8 Open

1. **Bubble** (R5). The bubble draw stays at about 7.6 times upstream. Measure first: the share of
   `_drawDirect` at a DPR of 2.6, and the count of radius classes of real bubble charts.
2. **The stroke of a sector** keeps `drawPath` (1.12 µs for each arc), because no native form
   gives the bevel joins of the border with equivalent pixels (R1).
3. **The end of the bar recording.** §7.3 gives a range, because no profile splits the end into
   its operations. A profile of `chart.bar` draw on the Pixel 8a after the night tells it.
4. **The web.** No repository suite runs the `dart:ui` layer on the web (§2.6). The forms use
   `drawArc` and `drawRawAtlas` with colors, which skwasm and CanvasKit have. The browser runs of
   the night check them.

### 7.9 Bounded recordings after the bar pipeline investigation

2026-11-02. The new evidence in [bar-performance.md](bar-performance.md) isolates
native `Canvas.drawPicture` bounds consolidation as the dominant cost of dense
bar painting. [ADR 0066](adr/0066-bounded-canvas-recordings.md) splits recordings
after 256 non-batched paint calls, preserving operation order and replaying the
existing clip stack at the next recording. This addresses §7.8 item 3's recording
question: the large local cost is embedding the picture, not endRecording itself.

The previous picture-count flattening rule becomes a paint-generation limit:
eight completed generations, independently of their internal picture chunks.
Small recordings and circle batching retain their existing paths. This adds no
shape aggregation, atlas approximation, sampling or layer at a split. The
`canvas_ui_chunks_test.dart` regressions cover all composite modes and mixed
gradient/pattern/text/image/stroke work across boundaries, clip restoration,
partial clears, full clear, snapshots, resize, history flattening and circle runs.
The performance figures and retained full-call control measurements are in
performance.md §33. No mobile gain is inferred
from the macOS measurement, and this does not reopen the rejected R1–R6 forms.

### 7.10 Scalar preparation of ordinary bars

2026-11-02. [ADR 0067](adr/0067-scalar-bar-geometry.md) removes temporary bounds,
corner and inflated-rectangle objects from the ordinary typed BarElement draw.
It keeps the canvas calls (including the empty inner fill) unchanged and leaves
rounded/inflated/custom/degenerate cases on the existing path. N1–N5 and the
recording chunks of ADR 0066 are unchanged; this is element preparation rather
than a new renderer shape or batching rule. Exact trace and pixel regressions
are in `test/port/elements/element.bar_rectangular_test.dart`. The measurements
and fallback/other-chart controls are in performance.md §34. Do not infer gains for the rejected R1–R6 forms.

### 7.11 Bulk numeric updates before drawing

2026-11-02. [ADR 0069](adr/0069-bulk-numeric-bar-updates.md) changes the controller's
numeric update preparation and adds a guarded native element writer. It does not
change BarElement.draw, native shape calls, paint order, the N1–N5 renderer paths
or ADR 0066's recording chunks. The update improves while drawing remains a major
frame cost. Eligibility and exact-state/callback regressions are in
`test/port/controllers/bar_bulk_update_test.dart`; timings and controls are in
performance.md §36. No rejected rendering approximation
is introduced by this update path.

### 7.12 Native ordinary rectangle-bar operation

ADR 0070 fuses the already-computed ordinary bar rectangles into the existing
native rectangle/ring draws. The final path, draw order, clipping and recording
counts remain. Observable callbacks and unsupported styles/transforms/geometry
retain the Canvas 2D sequence. This removes path/state preparation without
reopening R6's atlas/triangle approximations. Pixel/state regressions are in
`test/port/canvas/canvas_rect_bar_test.dart`; measurements are in performance.md
§37. ADR 0066's recording limit remains unchanged.

[Chart.js ADR 0149](adr/0149-bar-chart-small-costs.md) (2026-11-16) adds three forms to this operation. The
operation maps one rectangle for a bar with no border. It keeps the identity of four colors that passed its full
test. It also takes a bar with a shadow when the bar has no border and its rectangle has an area in 32-bit numbers:
the shadow is one `drawRect` with a kept paint (`_castShadowRect`). A bar with a border under a shadow keeps the
Canvas 2D sequence. The twins are in `test/port/canvas/canvas_ui_solid_paint_test.dart` and
`test/port/canvas/canvas_ui_shadow_rect_test.dart`; the figures are in performance.md §76.

[Chart.js ADR 0158](adr/0158-fused-rounded-bar.md) (2026-11-17, proposed, row `adapt-native-rounded-bar`) adds the
rounded bar to this operation. `BarElement.draw` computes the numbers of `boundingRects` as scalars and offers the
outer and the inner rounded rectangle to `RectBarCanvas.tryDrawRoundedBar`. A bar whose corners are all 0 takes the
rectangular operation. The native context makes each rounded rectangle with the code of `roundRect`
(`roundRectRadiusScale` and `UiPathBuilder.mappedRRectOf`) and selects the draw call of `fill`: the sole shape or
the `drawDRRect` ring for the border, and `drawRRect` for the fill. A shadow, a ring that is not nested, a value that
is not finite, a negative side or radius, a transform that is not axis-aligned and each observer decline to the
Canvas 2D sequence. The byte twins are in `test/port/canvas/canvas_rounded_bar_test.dart`; the CI job
`test-impeller` also runs them on Impeller.

### 7.13 Numeric category parsing before geometry

ADR 0071 reduces repeated label-source reads during primitive parsing in the bar
and base dataset controllers. It leaves the canvas operations, renderer shapes,
recording limit and bulk element writes unchanged. Reference/activation tests
are in `test/port/core/primitive_parse_test.dart`; performance.md §38 records measurements and fallback controls.

### 7.14 Bar spacing preparation

ADR 0072 evaluated per-ruler position reuse but failed the full-workload gate;
its prototypes were removed. ADR 0073 replaces hashing of owned finite sorted
bar indexes with linear duplicate removal. Renderer shapes, draw calls, native
recordings and scale projection order remain unchanged. Tests are in
`test/port/core/bar_sorted_values_test.dart`; performance.md §39 retains the sequential experiments and decisions.

### 7.15 Incremental data lifecycle

ADR 0074 changes update granularity, not the native renderer. The explicit
Chart.updateData path retains stable layout and category index geometry while
refreshing parsed data, controller geometry and compatible plugin state. It
keeps all bars/points/arcs and the existing draw order and recording boundaries.
Source/metadata/interaction twins are in `test/port/core/data_update_test.dart`;
measurements are in performance.md §41.

### 7.16 Stress-screen presentation

ADR 0075 reorganizes the Stress controls and readout without changing benchmark
loops, workloads, canvas-size calculation or renderer calls. Named targets and
operations replace abbreviations; detailed source/timing information remains
available under Diagnostics. The performance experiments above remain comparable
at the same canvas dimensions and configuration.
