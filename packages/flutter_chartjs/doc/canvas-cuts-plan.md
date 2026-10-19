# Canvas and host cuts plan

- Status: proposed, deferred
- Date: 2026-10-19
- Related: [Chart.js ADR 0009](adr/0009-no-display-only-js-exactness.md) (accepted),
  [Chart.js ADR 0013](adr/0013-canvas-model.md), [Chart.js ADR 0014](adr/0014-input-events-and-chart-host.md),
  [Chart.js ADR 0015](adr/0015-text.md), [Chart.js ADR 0016](adr/0016-frame-scheduling.md) (all
  proposed), [performance.md](performance.md), [porting-flow.md](porting-flow.md) §2.2

This plan removes code of the phase 3 canvas layer and of the chart host where Dart or Flutter
already gives the function. It has three cuts and nine work packages. Each work package has one
owner. An owner can take one work package without the history of this plan. All paths are
relative to `packages/flutter_chartjs/` unless they start with `apps/` or `third_party/`. The line
numbers are the line numbers on 2026-10-19. Read the file again before an edit, because other
work changes the tree.

## Deferral

The port does not do this plan now ([porting-flow.md](porting-flow.md) §5.1). The revisit point is
after phase 8, before phase 9. Until then:
- A change that edits a file that this plan cites updates this plan in the same commit: the file
  and line references, the code inventory (§1.1), the tests that pin the behavior (§2.6, §3.5) and
  the estimates. The cited files are `lib/src/canvas/*.dart`, `lib/src/platform/chart_host.dart`,
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
default spec canvas before phase 5 depends on it.

### 1.1 Code inventory

| Part | File:lines | Lines | Flutter API that replaces it | Verdict |
|---|---|---:|---|---|
| `UiPathBuilder._bezierArc` (cubic Béziers for a skew, a non-uniform scale with rotation, a rotated ellipse) | `lib/src/canvas/canvas_ui_path.dart:734-787` | 54 | `ui.Path.arcTo` in user space, then `extendWithPath(arc, Offset.zero, matrix4: m)` | **Remove** (cut 1) |
| `_addArc`, axis-aligned branch with the reflection cases `a < 0`, `d < 0` and both | `canvas_ui_path.dart:658-688` | 31 | The same matrix path | **Remove** (cut 1) |
| `_addArc`, similarity branch (rotation, uniform scale, mirror) | `canvas_ui_path.dart:640-657` | 18 | It already calls `ui.Path.arcTo` in bitmap space | **Keep**. It is the hot path: `retinaScale` and `translate` give a similarity. |
| `_nativeArc` (half arcs for a sweep over pi, sweep 0, `forceMoveTo`) | `canvas_ui_path.dart:692-732` | 41 | None. A sweep of `2 * pi - 1e-12` rounds to 360 degrees and `arcTo` adds nothing. | **Keep**. The matrix path shares its half split. |
| `canvasArcSweep` (Chromium `AdjustEndAngle`) | `canvas_ui_path.dart:239-254` | 16 | None. Skia takes the sweep modulo 360 degrees. | **Keep**. The full sweeps change behavior. |
| `UiTransform` (a-f, the operations, `mapX`/`mapY`, the flags, the matrix writers) | `canvas_ui_path.dart:37-237` | 201 | None. `dart:ui` has no affine type. `Canvas.getTransform` needs a live recording and allocates. `vector_math` `Matrix4` is 4 x 4 and not a dependency. | **Keep** |
| Current point and subpath start (`_lastX`, `_startX`, `hasSubpath`) | `canvas_ui_path.dart:294-378` | ~25 | None. `ui.Path` has no current point. | **Keep** |
| DOM `arcTo` (tangent arc) math | `canvas_ui_path.dart:557-620` | ~60 | None. `ui.Path.arcToPoint` is the SVG end-point arc. | **Keep**. It calls `_addArc`. |
| `rect()` with four mapped corners | `canvas_ui_path.dart:447-477` | 30 | None. `addRect` sorts the corners and changes the winding when `w < 0` or `h < 0`. | **Keep** |
| Pending full circle (`singleCircle`, `_materializeCircle`) | `canvas_ui_path.dart:274-339`, `:501-523` | ~50 | None | **Keep** (cut 3) |
| `CircleBatch` | `lib/src/canvas/canvas_ui_batch.dart` | whole file | None. Flutter does not merge `drawCircle` calls. | **Keep** (cut 3) |
| Text rotation snap of 2 degrees | `lib/src/canvas/canvas_ui.dart:1430-1451` | ~30 | Fixed on Flutter `master`, not in a stable release | **Keep** until a stable release has the fixes (cut 3) |
| `RenderChartHost.chartSize`, the CSS rule for one style (keep the render aspect) | `lib/src/platform/chart_host.dart:470-491` | ~20 | The harness matcher `toBeChartOfSize` | **Move** to the harness (cut 2) |
| `UiCanvasElement.devicePixelRatio` and `logicalSize` | `canvas_ui.dart:142`, `:175-192` | ~20 | The host gives the paint scale | **Remove** (cut 2) |
| Bitmap stretch (display / (bitmap / canvas DPR)) | `chart_host.dart:633-658` | ~25 | `Canvas.scale` in the host paint | **Keep** as the one mapping from the bitmap to the display size (cut 2) |
| `initCanvas` with `getAttribute` always `null` | `lib/src/platform/platform.flutter.dart:104-123` | ~20 | A small attribute model on `UiCanvasElement` | **Replace** (cut 2) |
| `releaseContext` with the hard-coded 300 x 150 branch | `platform.flutter.dart:455-495` | ~40 | The same attribute model | **Replace** with the line-by-line port (cut 2) |
| `getMaximumSize`, `retinaScale`, `readUsedSize` (ported, with `DIVERGES` rows) | `lib/src/helpers/helpers.dom.dart` | — | None. `AspectRatio` and `SizedBox` give other sizes than upstream. | **Keep**, no change |
| Host attach at the first layout, resize observers, host follows the chart size, unbounded rule, clip | `chart_host.dart:129-225`, `:385-459`, `:493-631`; `platform.flutter.dart:561-613` | ~280 | None. Flutter layout cannot know the size that Chart.js picks. | **Keep** |

## 2. Cut 1: arcs and transforms on dart:ui

### 2.1 Current code

`lib/src/canvas/canvas_ui_path.dart` has 812 lines.

- 1-27: the library doc. It says that arcs become cubic Béziers under other transforms.
- 37-237: `UiTransform`. The flags are `isAxisAligned` (64), `isSimilarity` (69), `scaleFactor`
  (72), `angle` (75), `isReflected` (78), `isInvertible` (81) and `isTranslation` (84).
  `writeMatrix4` is at 188-200 and `writeInverseMatrix4` is at 204-217.
- 239-254: `canvasArcSweep`.
- 262-788: `UiPathBuilder`.
  - 480-526: `arc`, with the full-circle fast path at 501-523.
  - 529-555: `ellipse`.
  - 558-620: `arcTo` (the DOM tangent arc).
  - 626-690: `_addArc`. The similarity branch is 640-657. The axis-aligned branch with the
    reflection cases is 658-688. The Bézier fall-back is 689.
  - 696-732: `_nativeArc`.
  - 736-787: `_bezierArc`.
- 790-812: `_CachedPath` and `uiPathOf`.

`lib/src/canvas/canvas_ui.dart` uses `UiTransform` for the state (246, 270), the shared matrix
buffer `_m4` (341), the transform setters (777-815), the shader matrix (578-582), the strokes
(633-704), the rectangles (718-976), `fill` (1046-1103), `stroke` (1106-1124), `clip`
(1128-1153), the text (1389-1451) and `drawImage` (1526-1545). `canvas_ui_batch.dart` gets
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

- `canvas_ui.dart:1122`: `stroke()` under a transform that is not a similarity calls
  `_strokeUser(_path.path.transform(t.writeInverseMatrix4(_m4)))`. `_strokeUser` then writes the
  forward matrix into `_m4` (`:700`) before `drawPath` builds the lazy path. The probe was
  `transform(1, 0, 0, 3, 0, 0)`, a line at y = 10 and `stroke()`. On the VM, rows 27 to 32 had ink.
  On CanvasKit and on skwasm, nothing was drawn.
- `canvas_ui.dart:1140`: a `Path2D` clip calls `uiPathOf(path2d).transform(s.transform.writeMatrix4(_m4))`.
  The state keeps the clip and replays it into later recordings. After the frame arena discards
  the built path, the path builds again with the value that `_m4` has then. The probe did not show
  it, because the probe rendered no second frame.
- `canvas_ui_paint.dart:136` and `:373-377`: `shaderFor` keeps a copy in `_lastMatrix`, but
  `_build(matrix)` gives the caller's matrix (the shared `_m4`, from `canvas_ui.dart:581`) to
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
   `fix(flutter_chartjs): copy the matrices that the web paths read late`):
   - `canvas_ui.dart:1122`: `t.writeInverseMatrix4(Float64List(16))`.
   - `canvas_ui.dart:1140`: `s.transform.writeMatrix4(Float64List(16))`.
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
3. Delete the axis-aligned branch (`:658-688`) and `_bezierArc` (`:734-787`).
4. Do not change `arc`, `ellipse`, `arcTo`, the pending circle, `UiTransform`, `canvas_ui.dart`
   or `canvas_ui_batch.dart`.
5. Update the library doc (`canvas_ui_path.dart:1-27`) and the doc of `_addArc`: the direct path,
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
(`@TestOn('vm')`): the group `transforms` (234-317), the group `paths` (486 and later, with "a
full circle and a negative radius", "a sweep just under a full turn fills a circle", the group "a
full circle on an empty path", "arc connects to the current point with a line", "a rotated
ellipse and arcTo draw", "fill and stroke a Path2D under the transform"), the group `rotated text`
(1071-1113) and the group `circle batch` (1342 and later, 28 tests). They must stay green without
a change. The `helpers.canvas` specs use `MockContext`. They record calls and never reach
`dart:ui`, so they are no evidence for cut 1.

Only two current tests reach the code that goes: "a rotated ellipse and arcTo draw" (ink probes
only) and the last part of "a sweep just under a full turn fills a circle" (`scale(1, 0.5)`, the
positive axis-aligned case). No test covers a partial arc under a mirror, a skew or a non-uniform
scale. Thus work package A1 adds a new file before the cut.

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
`packages/flutter_chartjs`, and run `flutter test --platform chrome` and
`flutter test --platform chrome --wasm` on a copy of tests 1, 8 and 10 and of these two probes:
- A stroke under `transform(1, 0, 0, 3, 0, 0)` of a line at y = 10 must ink y = 30.
- A `Path2D` clip under `translate`, replayed after at least one more rendered frame with other
  draws.

Run each probe in the first frame and again after at least one more frame, so that the frame arena
builds the path again. Record the result in the Evidence section of Chart.js ADR 0013. Before W,
the stroke probe fails on CanvasKit and on skwasm. Work package I can put the same probes in a
gallery integration test.

### 2.7 ADR and doc changes

Chart.js ADR 0013 is proposed, so the owner edits it in place. Do not change its status line.
- §6 (lines 143-158): replace "An arc uses `ui.Path.arcTo` when ... cubic Béziers of 90 degrees
  or less" with the direct path and the matrix path of §2.4. State that each `extendWithPath` call
  and each `Path.transform` call gets its own `ui.Path` and `Float64List`, because the web
  renderers read them when they build the path.
- §7 or §8: one sentence on step 0, and one sentence on the cost of the matrix path.
- Evidence: the new test file, the probe figures of §2.8 and the web runs.
- Open: no repository suite runs the `dart:ui` layer on the web. Name the scratch-package method.
- `parity.md`: row 357 (`canvas_ui_path.dart`), "else cubic Béziers" becomes "else a user-space
  `ui.Path.arcTo` that `extendWithPath(matrix4:)` appends". Row 356 and row 358 get the matrix
  copies of step 0. Add a row for `test/port/canvas/canvas_ui_path_test.dart`.
- `performance.md`: a new section with the arc figures (§2.8 and §6.3).
- Chart.js ADR 0009 (accepted) does not change. Conics in place of Béziers give a display-only
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

### 3.1 Current code

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

`lib/src/canvas/canvas.dart` (pure interface): `HTMLCanvasElement` (164-185) gets
`getAttribute`, `setAttribute` and `removeAttribute`. `CSSStyleDeclaration`, `CanvasNode` and
`CanvasContainer` do not change.

`lib/src/canvas/canvas_ui.dart`:
- `UiCssStyleDeclaration` (94-127) stays. `retinaScale` writes it, and `direction` reads it.
- `UiCanvasElement` (129-216): the constructor (136-138), the `width` and `height` setters
  (145-165), `_devicePixelRatio` (142), the `devicePixelRatio` getter and setter (175-187) and
  `logicalSize` (189-192).
- `UiCanvasContext.paint` (381-401) draws with `scale(1 / dpr)` at 391 and 395.
- The library doc at 25-31 describes that scale.

`lib/src/helpers/helpers.dom.dart` does not change. `getMaximumSize`, `retinaScale` and
`readUsedSize` are ported, and their rows `platform-dom-no-css`, `platform-dom-container` and
`platform-dom-computed-style` stay valid.

Users outside the package: `apps/chartjs_gallery/lib/demo/demo_chart.dart` (`DemoChart` with a
default `UiCanvasElement()`, responsive only) and `apps/chartjs_gallery/lib/demo/canvas_demo.dart:125`
(`UiCanvasElement(width: 32, height: 32)` for `toImageSource`). No gallery code reads
`devicePixelRatio`, `logicalSize` or `chartSize`.

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
- The size changes the ticks and the hit tests, so Chart.js ADR 0009 requires the upstream size.

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
(chartjs-test-utils `utils.js:43`). Today `UiCanvasElement(width: 512, height: 512)` goes through
`initCanvas` with no attribute and no style, and `initCanvas` sets the height to 512 / 2 = 256
(`platform.flutter.dart:121-172`). The test "acquireContext initializes the canvas" shows the same
rule. Every spec that uses the default canvas would get a 512 x 256 chart.

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
  evidence base of Chart.js ADR 0014 §4 and Chart.js ADR 0016.

### 3.4 Change list

Work package C2 does these steps. It starts after W, because both edit `canvas_ui.dart`.

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
- `test/port/platform/chart_host_test.dart` (32 tests): "first layout" (2), the group "resize"
  (throttle, DPR change, content drawn before the host at the display size, clip, a later resize
  keeps the ratio), "unbounded constraints" (4), "dry layout", the group "attach and detach".
- `test/port/platform/platform.flutter_test.dart` (18 tests): `initCanvas` (5), "acquireContext
  initializes the canvas", "releaseContext restores the canvas", `getDevicePixelRatio`,
  `getMaximumSize` (4).
- `test/port/helpers/helpers.dom_test.dart`: `getMaximumSize`, `retinaScale` (8), `readUsedSize`
  (10), `platform-dom-computed-style`.
- `test/port/canvas/canvas_ui_test.dart`: "device pixel ratio" (2), "toImageSource snapshots the
  bitmap in device pixels" (836), "the pictures are in bitmap space at a device pixel ratio"
  (2.625, 1972). The `_render` helper at line 89 reads `logicalSize` and has about 88 callers.
- `test/specs/helpers.dom_test.dart` (5 cases pass).
- `apps/chartjs_gallery/test/` (`canvas_host_demo_test.dart` line 94 expects a non-empty
  `canvas.style` width).

No current test pins the stretch. Work package A2 adds these tests to `chart_host_test.dart`. They
must be green on the current code:
1. `FakeChart(devicePixelRatio: 1)` on a DPR 2 view: bitmap 400 x 200, host 400 x 200, and a
   `fillRect` of the left half of the chart covers the left half of the `RepaintBoundary` image.
2. `FakeChart(devicePixelRatio: 3)` on a DPR 1 view: bitmap 1200 x 600, host 400 x 200, ink at the
   display size.
3. A pointer at the center of the host under test 1 gives a chart event at
   (`chart.width / 2`, `chart.height / 2`).
4. DPR 1.5 and width 101 give bitmap 151 and a factor of 1.0033: the stretch applies. DPR 2.625
   and a box 387.43 wide (the Pixel 8a Stress tab) give a factor within 1e-3: the paint scale is
   exactly 1 / 2.625. Read it through a `@visibleForTesting` getter `debugPaintScale` or through
   the `TransformLayer`.
5. A non-responsive chart with styles 345 x 125 and a bitmap of 165 x 85: the host is 345 x 125.
6. One style only (`width: 600px`): the host keeps the render aspect. Work package C2 changes this
   expectation, because the rule moves to the harness.
7. After `releaseContext`, the host shows 300 x 150.

Work package C2 changes these tests:
- `canvas_ui_test.dart`: `_render` takes an optional `dpr` (default 1), computes the size from
  `canvas.width / dpr` and paints with `1 / dpr`. The group "device pixel ratio" becomes "paint
  maps the bitmap pixels with the given scale". The assertion "`onChanged` on a DPR write" goes.
  Delete `..devicePixelRatio = 2` at 837. The 2.625 test paints with `1 / dpr`.
- `chart_host_test.dart`: delete `expect(canvas.devicePixelRatio, 2)` (126, 149). `chartSize`
  becomes `displaySize` (172). "clips a chart that is larger than the box" uses
  `UiCanvasElement(width: 600, height: 300)`.

Work package C2 adds these tests (they fail on the current code):
1. `canvas_ui_test.dart`, group "attributes": no attribute gives `null` and 300 x 150. The
   constructor sizes give `'512'`. A setter reflects into the attribute. `removeAttribute`
   restores the default and clears the bitmap. `setAttribute` parses, and a bad value gives the
   default.
2. `platform.flutter_test.dart`: `initCanvas` keeps a 512 x 512 canvas. A width attribute of 400
   with ratio 1 gives 400 x 400. Attributes 165 x 85 with styles 345 x 125 keep the render size
   165 x 85. `releaseContext` restores a given attribute (180) and removes an absent one (height
   back to 150) after `retinaScale` changed both.
3. `chart_host_test.dart`: a non-responsive chart on `UiCanvasElement(width: 320, height: 240)`
   at DPR 3 gives a chart of 320 x 240, a canvas of 960 x 720 and a host of 320 x 240.

### 3.6 Spec case impact (phase 5)

Today every case below is `blocked: core.controller`, except the 5 `helpers.dom` cases that pass.
"Current code" means the result that the current code would give when phase 5 runs the case.
`toBeChartOfSize` (chartjs-test-utils `matchers.js:131-171`) reads the display size from the style.
The specs never see `chartSize` or the stretch. Only `initCanvas`, `releaseContext` and the
attributes reach them.

| Spec file | Case | Depends on | Current code | After option A | Option B (rejected) |
|---|---|---|---|---|---|
| `platform.dom` | Context acquisition (5 cases) | — | pass | pass | pass |
| `platform.dom` | aspectRatio "default global" (620), "user" (405), "not apply when height specified" (400 x 410) | `initCanvas` style read, one-style rule | pass | pass (rule in `toBeChartOfSize`) | `diverges:` |
| `platform.dom` | aspectRatio "default chart aspect ratio" (425) | doughnut controller | `blocked: controller.doughnut` | pass after the doughnut port | `diverges:` |
| `platform.dom` | responsive false, "default canvas size" | — | pass | pass | pass |
| `platform.dom` | responsive false, "canvas attributes" (305 x 245) | attributes | **fail** (305 x 152) | **pass** | `diverges:` |
| `platform.dom` | responsive false, "canvas style" (345 x 125), "decimal display" (345.42) | `initCanvas` style read | pass | pass | `diverges:` |
| `platform.dom` | responsive false, "attributes for the render size and style for the display size" (165 x 85, 345 x 125) | attributes, stretch | **fail** (render from the style) | **pass** | `diverges:` |
| `platform.dom` | responsive true, "fit parent using aspect ratio" (150 x 245 to 214 x 350) | `initCanvas` style read | pass | pass | fail or `diverges:` |
| `platform.dom` | destroy, "reset context to default values" | `canvas.width = canvas.width` | pass | pass | pass |
| `platform.dom` | destroy, "restore canvas initial values" (attribute 180) | attributes, style restore | `n/a` | **pass** | `diverges:` |
| `platform.dom` | event handling | — | pass | pass | pass |
| `platform.dom` | isAttached | — | `n/a` | `n/a` | `n/a` |
| `helpers.dom` | "leave styled height and width" (attributes 200, style 400) | style read | pass | pass | pass |
| `helpers.dom` | "handle devicePixelRatio correctly" (attributes 800 x 400) | attributes | pass by chance (800 / 2 = 400) | pass | pass by chance |
| `helpers.dom` | "Should not return NaN with a custom event", "consistent results" | — | pass | pass | pass |
| `helpers.dom` | 2 cases `diverges: platform-relative-position` | — | unchanged | unchanged | unchanged |
| `core.controller` | `maintainAspectRatio: false` group: fill parent, onResize, parent width, parent height, invisible (`SizedBox.shrink`), RTL, parent padding (`Padding`), wrapper `display: none` to block | constraints | pass | pass | pass |
| `core.controller` | `maintainAspectRatio: false`, DPR option change (render width 800, display width 400) | stretch | pass | pass | spec passes, the visible chart has the wrong scale |
| `core.controller` | canvas `display: none` to block | harness | pass or `n/a: Flutter has no CSS display on the canvas` | same | same |
| `core.controller` | `max-width` and `max-height` with `display: none` | CSS | `n/a: Flutter has no CSS max-width` | same | same |
| `core.controller` | `maintainAspectRatio: true` (2 cases, `canvas: {style: ''}`) | ratio 2 | pass | pass | pass |
| `core.controller` | Retina scale and `config.options.devicePixelRatio`, "implicit display size" (2 cases, attributes 320 x 240) | attributes | **fail** (320 x 160) | **pass** | fail |
| `core.controller` | Retina scale and `config.options.devicePixelRatio`, "explicit display size" (2 cases, style 320 x 240) | `initCanvas` style read | pass | pass | `diverges:` |
| `core.controller` | `config.options.aspectRatio` (attribute width 400, ratio 1, then 2) | harness wrapper | pass if the default wrapper is a box of the canvas display size | same | same |
| `core.controller` | attach and detach cases, "re-creating the chart" | — | unchanged | unchanged | unchanged |
| 14 of the 23 core, element and scale spec files | every case on the `acquireChart` default canvas | attributes | 512 x 256 | 512 x 512 | 512 x 256 |

Net for option A: 5 named cases and the default 512 x 512 canvas go from fail or `n/a` to pass. No
new `differences.md` row. No skip reason changes now, because every affected case is still
`blocked: core.controller`. Thus `test:cases` gives the same output.

### 3.7 ADR and doc changes

Chart.js ADR 0013 and Chart.js ADR 0014 are proposed, so the owner edits them in place. Do not
change their status lines. Chart.js ADR 0009 and Chart.js ADR 0016 do not change.
- **Chart.js ADR 0014:**
  - §2 (lines 90-92): "the display size of the canvas" is the px styles that `retinaScale` writes,
    else the render size.
  - §5 (lines 145-156): the display size rule, "paint maps the bitmap to the display size with one
    scale, exactly 1 / DPR within 1e-3" in place of the stretch bullet, why the stretch stays
    (`options.devicePixelRatio`), and the attribute model.
  - Alternatives: add option B, the paint at `1 / dpr` only, and the host size from Flutter
    layout, with the reasons of §3.3.
  - Evidence (lines 299-330): the new tests and their counts.
- **Chart.js ADR 0013:** §2 (line 81): the `devicePixelRatio` and `logicalSize` bullet becomes the
  attributes bullet. §4 (about line 111): the `paint` signature. §5 (lines 122-138): `paint`
  applies the scale that the host gives. Delete the bullet on the `UiCanvasElement.devicePixelRatio`
  write. "The content keeps bitmap pixels across a DPR change" stays. The stretch bullet points to
  Chart.js ADR 0014 §5. Evidence: the test names.
- **`porting-flow.md`** (proposed): §2.2 (line 180), "`paint` applies `scale(1 / devicePixelRatio)`"
  becomes "`paint` maps the bitmap pixels with the scale of the host". §2.7: one bullet on the
  canvas attributes. §3, harness table (line 444), `acquireChart`: 512 x 512 as attributes
  (`UiCanvasElement(width: 512, height: 512)`), the `canvas.style` option fills the inline style, a
  wrapper style becomes a `SizedBox`, `ConstrainedBox` or `Padding`, and the default wrapper is a
  box of the canvas display size. `toBeChartOfSize`: the display width and height come from the
  display size with the CSS rule for one style.
- **`parity.md`:** row 356 (`canvas_ui.dart`: no `devicePixelRatio` and no `logicalSize`, the
  attributes, the paint scale), row 363 (`platform.flutter.dart`: `initCanvas` and
  `releaseContext` line by line over the attributes), row 364 (`chart_host.dart`: "the DOM bitmap
  stretch" becomes "paint maps the bitmap to the display size"), row 369 (`canvas_ui_test.dart`)
  and row 396 (`chart_host_test.dart`). The spec rows do not change.
- **`differences.md`:** no row for option A.
- **`performance.md`:** record the figures after the change (§6.3).

### 3.8 Risks

1. **Sharpness** (medium). The paint mapping must keep the exact 1 / DPR snap. Without it,
   fractional `round1` sizes resample the flattened images and the atlas of the circle batch. Test
   4 of A2 pins it. Check the Stress tab on the Pixel 8a by eye.
2. **The attributes change the initial ratio** (low). A responsive chart on a canvas that has
   explicit `width` and `height` now takes its initial `_aspectRatio` from them. That is the
   upstream behavior. The gallery uses default canvases and does not change.
3. **The interface grows** (low). `HTMLCanvasElement` gets 3 members. All fakes use
   `noSuchMethod`. `MockContext.canvas` does not change.
4. **The one-style rule moves to the harness** (medium, phase 5). If the harness does not carry
   it, the 3 aspectRatio cases of `platform.dom` fail.
5. **The saving is small.** About 90 lines go and about 80 lines come. The gain is correctness and
   one paint mapping in place of two.

### 3.9 Estimated lines

| Area | Removed | Added |
|---|---:|---:|
| `chart_host.dart` (`chartSize` branches, stretch block, DPR writes, doc) | ~45 | ~15 |
| `canvas_ui.dart` (DPR field and accessors, `logicalSize`, paint, doc) | ~25 | ~3 |
| `UiCanvasElement` attributes | 0 | ~35 |
| `canvas.dart` interface | 0 | ~18 |
| `platform.flutter.dart` (doc, the `null` constants, the 300 x 150 branch) | ~20 | ~8 |
| **Library total** | **~90** | **~80** (net about -10) |
| Tests (A2 and C2) | ~45 | ~140 to 200 |

## 4. Cut 3: record only

Cut 3 changes no code.

### 4.1 Circle batch

`CircleBatch` (`lib/src/canvas/canvas_ui_batch.dart`, Chart.js ADR 0013 §8.1, performance.md
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
  Chart.js ADR 0013 §8.1 (a new ADR if 0013 is accepted by then).

### 4.2 Text rotation snap

The 2 degree snap of text rotation (Chart.js ADR 0015 §3, performance.md §5.5) stays. It avoids
the skwasm strike-cache race. The fixes are on Flutter `master`:
- [flutter/flutter#190048](https://github.com/flutter/flutter/pull/190048) gives each thread its
  own strike cache.
- [flutter/flutter#191014](https://github.com/flutter/flutter/pull/191014) makes that flag
  official.
- [flutter/flutter#194139](https://github.com/flutter/flutter/pull/194139) makes the semaphores
  of the FreeType locks work.

On 2026-10-19, the stable release 3.47.7 has none of the three. **Removal criterion:** the
toolchain pin (`.fvmrc`) is a stable release with all three changes. Then remove the snap and its
test group "rotated text", and run the crash case of performance.md §5.5 (20000 + 200, `SPIN=true`)
6 times with 0 crashes.

## 5. Work packages

Each work package has one owner and its own commit (or commits) on `main`, signed off, in
Conventional Commits form. Each work package updates its own rows of `parity.md` in the same
commit. The rows differ, so the edits do not overlap. Run the gates of §6.2 before each commit.

| ID | Title | Files touched | Depends on | Parallel with | Deliverable | Acceptance | Estimate |
|---|---|---|---|---|---|---|---|
| A1 | Cut 1 tests | `test/port/canvas/canvas_ui_path_test.dart` (new), `doc/parity.md` (new row) | — | A2, A3, I | The 20 tests of §2.6. The web probe results of the current code, in the commit message. | Green on the current code. Gates of §6.2. | ~400 test lines, 1 day |
| A2 | Cut 2 tests | `test/port/platform/chart_host_test.dart`, `test/port/platform/platform.flutter_test.dart`, `doc/parity.md` (row 396) | — | A1, A3, I | The 7 tests of §3.5 that pin the stretch and the display size | Green on the current code. Gates. | ~180 test lines, 0.5 day |
| A3 | Arc scenario and new baselines | `apps/chartjs_gallery/lib/demo/stress_demo.dart`, `apps/chartjs_gallery/lib/main_stress.dart`, `apps/chartjs_gallery/test/canvas_host_demo_test.dart` (if needed), `apps/chartjs_gallery/test/stress_elements_test.dart` (if needed), `doc/performance.md` (new baseline section) | — | A1, A2, I | `--dart-define=POINT_STYLE=<style>` in the stress entry. The baseline of §6.3 on 3 platforms. A scratch micro-benchmark of 5000 wedges (not committed). See the note on A3 below. | Baseline recorded with the commit hash. Old tables marked stale. | ~40 lines, 1 day of runs |
| I | Renderer probes (optional) | `apps/chartjs_gallery/integration_test/canvas_paths_test.dart` (new), `apps/chartjs_gallery/pubspec.yaml`, root `pubspec.lock` | — | A1, A2, A3 | The web probes of §2.6 as a gallery integration test | Runs on the Pixel 8a, on macOS and in Chrome (dart2js and `--wasm`). Merge alone (lock file). | ~150 lines, 1 day |
| W | Web matrix aliasing fix | `lib/src/canvas/canvas_ui.dart` (1122, 1140), `lib/src/canvas/canvas_ui_paint.dart` (`shaderFor`), `doc/parity.md` (rows 356, 358) | A1 | A2, A3 | Step 0 of §2.5 | VM pixels unchanged. The stroke probe and the clip probe pass on CanvasKit and on skwasm. | ~6 lines, 0.5 day |
| C1 | Cut 1 code | `lib/src/canvas/canvas_ui_path.dart`, `test/port/canvas/canvas_ui_path_test.dart` (thresholds only), `doc/parity.md` (row 357) | A1, W | C2 | Steps 1 to 6 of §2.5 | All tests green. Web probes pass. Perf of §6.3 within the thresholds. | ~-45 net library lines, 1 day |
| C2 | Cut 2 code (option A) | `lib/src/canvas/canvas.dart`, `lib/src/canvas/canvas_ui.dart`, `lib/src/platform/platform.flutter.dart`, `lib/src/platform/chart_host.dart`, `test/port/canvas/canvas_ui_test.dart`, `test/port/platform/chart_host_test.dart`, `test/port/platform/platform.flutter_test.dart`, `doc/parity.md` (rows 356, 363, 364, 369, 396) | A2, W | C1 | Steps 1 to 6 of §3.4 and the test changes of §3.5 | All tests green. Gallery unchanged on web, macOS and the Pixel 8a. Perf within the thresholds. | ~-10 net library lines, ~+100 test lines, 1.5 days |
| D | Docs | `doc/adr/0013-canvas-model.md`, `doc/adr/0014-input-events-and-chart-host.md`, `doc/porting-flow.md` | C1, C2 | P | §2.7 and §3.7 (ADR and porting-flow parts), and a "Removal" bullet in Chart.js ADR 0013 §8.1 (§4.1) | Status lines unchanged. Links resolve. | ~60 changed lines, 0.5 day |
| P | Perf results and cut 3 notes | `doc/performance.md` (results section, §7), this plan (status of each work package) | A3, C1, C2 | D | The figures of §6.3 after C1 and after C2. The removal criteria of §4. The draft of the Flutter feature request. | Every scenario within the thresholds of §6.3, or the miss explained | ~60 lines, 1 day of runs |

**Note on A3 (phase 4).** Phase 4 added the scene modes of the stress tab (§6.3). The stress
entry takes `--dart-define=MODE=<primitives|elements|bars|arcs>`, and the default is
`primitives`. For A3, this means:
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

C1 and C2 touch different library files and can merge in either order. Run the perf checks after
each. Other work commits to the same tree. Before each commit, run `git status` and stage only the
files of the work package.

Commit message examples:
- `test(flutter_chartjs): pin arcs under skew, mirror and non-uniform scale`
- `fix(flutter_chartjs): copy the matrices that the web paths read late`
- `refactor(flutter_chartjs): build arcs under other transforms with dart:ui`
- `refactor(flutter_chartjs): give the canvas attributes and one paint scale`

## 6. Verification and acceptance

### 6.1 Tests

- The tests of §2.6 and §3.5 that exist now stay green without a change, except the changes that
  §3.5 names.
- The new tests of A1 and A2 are green on the current code before C1 and C2 start.
- `check:headers` needs the port-only line-1 marker on the new test files. `check:lib-imports`
  needs `@TestOn('vm')` on each test file that imports `dart:ui` or `flutter_test`.

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
  against the display size), no blur, and the sizes. This also closes the Chart.js ADR 0014 Open
  item "A DPR change on a real device is not verified".
