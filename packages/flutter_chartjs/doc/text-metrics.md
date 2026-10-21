# Text-metric probe

- Scope: the text-metric probe of the phase 3 exit criterion ([porting-flow.md](porting-flow.md)
  §5).
- Date: 2026-10-19
- Related: [porting-flow.md](porting-flow.md) §2.8 (Text) and §3 (Test harness),
  [Chart.js ADR 0015](adr/0015-text.md) (Text, proposed),
  [Chart.js ADR 0034](adr/0034-no-display-only-js-exactness.md).

This document compares the text metrics of the canvas layer (`UiCanvasContext.measureText` in
`lib/src/canvas/canvas_ui.dart`) with the text metrics of the Chrome canvas. Both sides use the
same font files: Liberation Sans 2.1.5 (SIL OFL 1.1) in `packages/chartjs_test_utils/lib/fonts/`.

## 1. Result

- **Widths.** All 80 widths are equal. The largest difference is 5.0e-7 px (7.9e-6 %). This value
  is the rounding of the Chrome values to 6 decimals. The `toBeCloseToPixel` tolerance (0.5 % or
  less than 2 px) holds for all widths, with a margin of more than 1.9 px.
- **Baseline offsets.** The canvas layer puts each `textBaseline` less than 1 px from Chrome. The
  largest difference is 0.701 px (`top`, `middle` and `bottom` in bold 16px). `alphabetic` has no
  difference.
- **Bounding boxes.** The `actualBoundingBox*` values are different. Chrome gives the ink box of
  the glyphs. The canvas layer gives the advance box and the font ascent and descent, because
  `dart:ui` gives no glyph ink boxes (Chart.js ADR 0015). The signs agree. The box of the canvas
  layer holds the Chrome ink box, except for descenders: the Chrome descent is up to 0.291 px
  larger (`January` in 10px).

The widths control behavior: Chart.js uses `measureText(...).width` for the tick, legend and
tooltip layout. The baseline offsets and the bounding boxes only move pixels. Chart.js reads
`actualBoundingBox*` only in `helpers.canvas.ts:422-426`, for the underline and the strikethrough
of `renderText`. Thus these differences are display-only (Chart.js ADR 0034). The port keeps
them.

`test/port/canvas/text_metrics_test.dart` checks the result on each run. It fails when a width is
outside `toBeCloseToPixel`, when a baseline offset is more than 1 px from Chrome, or when the Chrome
ink box is more than 0.5 px outside the box of the canvas layer.

## 2. Set-up

| Item | Value |
|---|---|
| Chrome | Google Chrome 155.0.8059.80, headless (`--headless=new`), user agent `HeadlessChrome/155.0.0.0` |
| Flutter | Flutter 3.44.9 (engine `5a2a6a42cc`), `flutter test` on the host (flutter_tester) |
| OS | macOS 26.5.1 (build 25F80), arm64 (Apple silicon). Both sides ran on the same machine |
| Font | Liberation Sans 2.1.5: Regular and Bold. The italic faces are loaded but not measured |
| Chrome font set-up | `FontFace` with the same files under the names `Helvetica Neue`, `Helvetica`, `Arial` and `Liberation Sans`, as `testFontFamilies` of the harness. `document.fonts.load` for each font before the measurement |
| Flutter font set-up | `installTestFont()` in `test/flutter_test_config.dart` (`FontLoader` with the same files under the same names and `sans-serif`) |
| Text state | `textAlign` `start`, `direction` `ltr`, `textBaseline` `alphabetic` (the baseline table uses all six values) |

The fonts are the Chart.js default family list in the `toFontString` form
(`helpers.canvas.ts`), `<style> <weight> <size>px 'Helvetica Neue', 'Helvetica', 'Arial',
sans-serif`:

- `normal 12px` (the Chart.js default font)
- `normal bold 12px`
- `normal bold 16px` (a title)
- `normal 10px`
- `normal 24px`

The texts are tick values (`0`, `-10`, `100`, `1,000`, `0.25`, `-0.5`, `1.5e-7`), labels
(`January`, `February`, `Dataset 1`), titles (`My title`, `Total revenue (USD)`), a wide run
(`WWWWWWWWWW`), a narrow run (`iiiiiiiiii`), a precomposed Latin letter with an accent (`Ẁ`,
U+1E80) and a Hebrew word (`שלום`, an RTL script). The texts have no emoji.

The Chrome page compares each width with the width in a family name that only the page defines
(`Probe Liberation`). The two widths were equal for all 80 cases. Thus the Chart.js family list
resolved to the loaded files, and not to the system Helvetica Neue of macOS.

## 3. Widths

The difference is Flutter minus Chrome. The percentage is the difference divided by the Chrome
width. The table rounds to 3 decimals.

| Font | Text | Chrome (px) | Flutter (px) | Difference (px) | Difference (%) | toBeCloseToPixel |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| 12px | `0` | 6.674 | 6.674 | 0.000 | 0.000 | yes |
| 12px | `-10` | 17.344 | 17.344 | 0.000 | 0.000 | yes |
| 12px | `100` | 20.021 | 20.021 | 0.000 | 0.000 | yes |
| 12px | `1,000` | 30.029 | 30.029 | 0.000 | 0.000 | yes |
| 12px | `0.25` | 23.355 | 23.355 | 0.000 | 0.000 | yes |
| 12px | `-0.5` | 20.678 | 20.678 | 0.000 | 0.000 | yes |
| 12px | `1.5e-7` | 34.025 | 34.025 | 0.000 | 0.000 | yes |
| 12px | `January` | 42.691 | 42.691 | 0.000 | 0.000 | yes |
| 12px | `February` | 48.018 | 48.018 | 0.000 | 0.000 | yes |
| 12px | `Dataset 1` | 51.363 | 51.363 | 0.000 | 0.000 | yes |
| 12px | `My title` | 38.004 | 38.004 | 0.000 | 0.000 | yes |
| 12px | `Total revenue (USD)` | 108.709 | 108.709 | 0.000 | 0.000 | yes |
| 12px | `WWWWWWWWWW` | 113.262 | 113.262 | 0.000 | 0.000 | yes |
| 12px | `iiiiiiiiii` | 26.660 | 26.660 | 0.000 | 0.000 | yes |
| 12px | `Ẁ` | 11.326 | 11.326 | 0.000 | 0.000 | yes |
| 12px | `שלום` (Hebrew) | 26.373 | 26.373 | 0.000 | 0.000 | yes |
| bold 12px | `0` | 6.674 | 6.674 | 0.000 | 0.000 | yes |
| bold 12px | `-10` | 17.344 | 17.344 | 0.000 | 0.000 | yes |
| bold 12px | `100` | 20.021 | 20.021 | 0.000 | 0.000 | yes |
| bold 12px | `1,000` | 30.029 | 30.029 | 0.000 | 0.000 | yes |
| bold 12px | `0.25` | 23.355 | 23.355 | 0.000 | 0.000 | yes |
| bold 12px | `-0.5` | 20.678 | 20.678 | 0.000 | 0.000 | yes |
| bold 12px | `1.5e-7` | 34.025 | 34.025 | 0.000 | 0.000 | yes |
| bold 12px | `January` | 46.025 | 46.025 | 0.000 | 0.000 | yes |
| bold 12px | `February` | 51.352 | 51.352 | 0.000 | 0.000 | yes |
| bold 12px | `Dataset 1` | 53.361 | 53.361 | 0.000 | 0.000 | yes |
| bold 12px | `My title` | 41.338 | 41.338 | 0.000 | 0.000 | yes |
| bold 12px | `Total revenue (USD)` | 113.795 | 113.795 | 0.000 | 0.000 | yes |
| bold 12px | `WWWWWWWWWW` | 113.262 | 113.262 | 0.000 | 0.000 | yes |
| bold 12px | `iiiiiiiiii` | 33.340 | 33.340 | 0.000 | 0.000 | yes |
| bold 12px | `Ẁ` | 11.326 | 11.326 | 0.000 | 0.000 | yes |
| bold 12px | `שלום` (Hebrew) | 28.787 | 28.787 | 0.000 | 0.000 | yes |
| bold 16px | `0` | 8.898 | 8.898 | 0.000 | 0.000 | yes |
| bold 16px | `-10` | 23.125 | 23.125 | 0.000 | 0.000 | yes |
| bold 16px | `100` | 26.695 | 26.695 | 0.000 | 0.000 | yes |
| bold 16px | `1,000` | 40.039 | 40.039 | 0.000 | 0.000 | yes |
| bold 16px | `0.25` | 31.141 | 31.141 | 0.000 | 0.000 | yes |
| bold 16px | `-0.5` | 27.570 | 27.570 | 0.000 | 0.000 | yes |
| bold 16px | `1.5e-7` | 45.367 | 45.367 | 0.000 | 0.000 | yes |
| bold 16px | `January` | 61.367 | 61.367 | 0.000 | 0.000 | yes |
| bold 16px | `February` | 68.469 | 68.469 | 0.000 | 0.000 | yes |
| bold 16px | `Dataset 1` | 71.148 | 71.148 | 0.000 | 0.000 | yes |
| bold 16px | `My title` | 55.117 | 55.117 | 0.000 | 0.000 | yes |
| bold 16px | `Total revenue (USD)` | 151.727 | 151.727 | 0.000 | 0.000 | yes |
| bold 16px | `WWWWWWWWWW` | 151.016 | 151.016 | 0.000 | 0.000 | yes |
| bold 16px | `iiiiiiiiii` | 44.453 | 44.453 | 0.000 | 0.000 | yes |
| bold 16px | `Ẁ` | 15.102 | 15.102 | 0.000 | 0.000 | yes |
| bold 16px | `שלום` (Hebrew) | 38.383 | 38.383 | 0.000 | 0.000 | yes |
| 10px | `0` | 5.562 | 5.562 | 0.000 | 0.000 | yes |
| 10px | `-10` | 14.453 | 14.453 | 0.000 | 0.000 | yes |
| 10px | `100` | 16.685 | 16.685 | 0.000 | 0.000 | yes |
| 10px | `1,000` | 25.024 | 25.024 | 0.000 | 0.000 | yes |
| 10px | `0.25` | 19.463 | 19.463 | 0.000 | 0.000 | yes |
| 10px | `-0.5` | 17.231 | 17.231 | 0.000 | 0.000 | yes |
| 10px | `1.5e-7` | 28.354 | 28.354 | 0.000 | 0.000 | yes |
| 10px | `January` | 35.576 | 35.576 | 0.000 | 0.000 | yes |
| 10px | `February` | 40.015 | 40.015 | 0.000 | 0.000 | yes |
| 10px | `Dataset 1` | 42.803 | 42.803 | 0.000 | 0.000 | yes |
| 10px | `My title` | 31.670 | 31.670 | 0.000 | 0.000 | yes |
| 10px | `Total revenue (USD)` | 90.591 | 90.591 | 0.000 | 0.000 | yes |
| 10px | `WWWWWWWWWW` | 94.385 | 94.385 | 0.000 | 0.000 | yes |
| 10px | `iiiiiiiiii` | 22.217 | 22.217 | 0.000 | 0.000 | yes |
| 10px | `Ẁ` | 9.438 | 9.438 | 0.000 | 0.000 | yes |
| 10px | `שלום` (Hebrew) | 21.978 | 21.978 | 0.000 | 0.000 | yes |
| 24px | `0` | 13.348 | 13.348 | 0.000 | 0.000 | yes |
| 24px | `-10` | 34.688 | 34.688 | 0.000 | 0.000 | yes |
| 24px | `100` | 40.043 | 40.043 | 0.000 | 0.000 | yes |
| 24px | `1,000` | 60.059 | 60.059 | 0.000 | 0.000 | yes |
| 24px | `0.25` | 46.711 | 46.711 | 0.000 | 0.000 | yes |
| 24px | `-0.5` | 41.355 | 41.355 | 0.000 | 0.000 | yes |
| 24px | `1.5e-7` | 68.051 | 68.051 | 0.000 | 0.000 | yes |
| 24px | `January` | 85.383 | 85.383 | 0.000 | 0.000 | yes |
| 24px | `February` | 96.035 | 96.035 | 0.000 | 0.000 | yes |
| 24px | `Dataset 1` | 102.727 | 102.727 | 0.000 | 0.000 | yes |
| 24px | `My title` | 76.008 | 76.008 | 0.000 | 0.000 | yes |
| 24px | `Total revenue (USD)` | 217.418 | 217.418 | 0.000 | 0.000 | yes |
| 24px | `WWWWWWWWWW` | 226.523 | 226.523 | 0.000 | 0.000 | yes |
| 24px | `iiiiiiiiii` | 53.320 | 53.320 | 0.000 | 0.000 | yes |
| 24px | `Ẁ` | 22.652 | 22.652 | 0.000 | 0.000 | yes |
| 24px | `שלום` (Hebrew) | 52.746 | 52.746 | 0.000 | 0.000 | yes |

## 4. Baseline offsets

The offset is the distance of the alphabetic baseline below the anchor point, for each
`textBaseline`. The probe calculates it from `actualBoundingBoxAscent` of `Dataset 1`: the
`alphabetic` value minus the value for the `textBaseline`. The ink box has a fixed position on the
alphabetic baseline. Thus the subtraction removes the ink box. The difference is Flutter minus
Chrome.

| Font | textBaseline | Chrome (px) | Flutter (px) | Difference (px) |
| --- | --- | ---: | ---: | ---: |
| 12px | `top` | 9.313 | 9.480 | 0.167 |
| 12px | `hanging` | 8.800 | 8.848 | 0.048 |
| 12px | `middle` | 3.312 | 3.480 | 0.167 |
| 12px | `alphabetic` | 0.000 | 0.000 | 0.000 |
| 12px | `ideographic` | -3.000 | -2.739 | 0.261 |
| 12px | `bottom` | -2.688 | -2.520 | 0.167 |
| bold 12px | `top` | 9.313 | 9.480 | 0.167 |
| bold 12px | `hanging` | 8.800 | 8.848 | 0.048 |
| bold 12px | `middle` | 3.312 | 3.480 | 0.167 |
| bold 12px | `alphabetic` | 0.000 | 0.000 | 0.000 |
| bold 12px | `ideographic` | -3.000 | -2.739 | 0.261 |
| bold 12px | `bottom` | -2.688 | -2.520 | 0.167 |
| bold 16px | `top` | 12.406 | 13.108 | 0.701 |
| bold 16px | `hanging` | 11.200 | 11.797 | 0.597 |
| bold 16px | `middle` | 4.406 | 5.108 | 0.701 |
| bold 16px | `alphabetic` | 0.000 | 0.000 | 0.000 |
| bold 16px | `ideographic` | -3.000 | -3.652 | -0.652 |
| bold 16px | `bottom` | -3.594 | -2.892 | 0.701 |
| 10px | `top` | 7.750 | 8.378 | 0.628 |
| 10px | `hanging` | 7.200 | 7.373 | 0.173 |
| 10px | `middle` | 2.750 | 3.378 | 0.628 |
| 10px | `alphabetic` | 0.000 | 0.000 | 0.000 |
| 10px | `ideographic` | -2.000 | -2.283 | -0.283 |
| 10px | `bottom` | -2.250 | -1.622 | 0.628 |
| 24px | `top` | 18.625 | 18.959 | 0.334 |
| 24px | `hanging` | 17.600 | 17.695 | 0.095 |
| 24px | `middle` | 6.625 | 6.959 | 0.334 |
| 24px | `alphabetic` | 0.000 | 0.000 | 0.000 |
| 24px | `ideographic` | -5.000 | -5.479 | -0.479 |
| 24px | `bottom` | -5.375 | -5.041 | 0.334 |

The causes of the differences:

- `top`, `middle` and `bottom`: Chrome puts them on the em box. The em box of Chrome comes from
  the OS/2 typographic ascender and descender of the font (1491 and 431 font units). The top is
  1491 / 1922 = 0.776 of the font size above the baseline. `dart:ui` does not give the OS/2
  values. The canvas layer scales its ascent and descent to the font size
  (`canvasBaselineShift` in `lib/src/canvas/canvas_ui_text.dart`). Its top is 0.790 of the font
  size at 12px.
- `hanging`: both sides use 80 % of the ascent. Chrome rounds the ascent to a whole pixel (11 px
  at 12px). The canvas layer uses the paragraph ascent (11.060 px at 12px).
- `ideographic`: Chrome uses the font descent, rounded to a whole pixel. The canvas layer uses the
  ideographic baseline of the paragraph.

The font box values (`fontBoundingBoxAscent` and `fontBoundingBoxDescent` of Chrome) show the
rounding. The canvas layer does not implement the `fontBoundingBox*` members. The table gives
the ascent and the descent of the canvas layer for comparison:

| Font | Chrome (px) | Flutter ascent, descent (px) |
| --- | --- | --- |
| 12px | 11.000, 3.000 | 11.060, 2.940 |
| bold 12px | 11.000, 3.000 | 11.060, 2.940 |
| bold 16px | 14.000, 3.000 | 14.746, 3.254 |
| 10px | 9.000, 2.000 | 9.216, 1.784 |
| 24px | 22.000, 5.000 | 22.119, 5.881 |

The ascent of the canvas layer is the alphabetic baseline of the paragraph. It contains half of
the line gap of the font (67 font units). The descent is the paragraph height minus the ascent.
The paragraph height was a whole number of pixels for each font of the probe (14, 14, 18, 11 and
28 px).

## 5. Bounding boxes

The values are `actualBoundingBoxLeft`, `actualBoundingBoxRight`, `actualBoundingBoxAscent` and
`actualBoundingBoxDescent`, in this order. The table gives the 12px font. The other fonts have
the same pattern at their size. All 80 rows are in the output of the test (see §6).

| Font | Text | Chrome (px) | Flutter (px) |
| --- | --- | --- | --- |
| 12px | `0` | -0.469, 6.205, 8.379, 0.117 | 0.000, 6.674, 11.060, 2.940 |
| 12px | `-10` | -0.533, 16.875, 8.379, 0.117 | 0.000, 17.344, 11.060, 2.940 |
| 12px | `100` | -0.914, 19.553, 8.379, 0.117 | 0.000, 20.021, 11.060, 2.940 |
| 12px | `1,000` | -0.914, 29.561, 8.379, 1.535 | 0.000, 30.029, 11.060, 2.940 |
| 12px | `0.25` | -0.469, 22.852, 8.379, 0.117 | 0.000, 23.355, 11.060, 2.940 |
| 12px | `-0.5` | -0.533, 20.174, 8.379, 0.117 | 0.000, 20.678, 11.060, 2.940 |
| 12px | `1.5e-7` | -0.914, 33.422, 8.256, 0.117 | 0.000, 34.025, 11.060, 2.940 |
| 12px | `January` | -0.188, 42.668, 8.256, 2.490 | 0.000, 42.691, 11.060, 2.940 |
| 12px | `February` | -0.984, 47.994, 8.695, 2.490 | 0.000, 48.018, 11.060, 2.940 |
| 12px | `Dataset 1` | -0.984, 50.777, 8.256, 0.117 | 0.000, 51.363, 11.060, 2.940 |
| 12px | `My title` | -0.984, 37.471, 8.695, 2.490 | 0.000, 38.004, 11.060, 2.940 |
| 12px | `Total revenue (USD)` | -0.270, 107.965, 8.695, 2.484 | 0.000, 108.709, 11.060, 2.940 |
| 12px | `WWWWWWWWWW` | -0.053, 113.221, 8.256, 0.000 | 0.000, 113.262, 11.060, 2.940 |
| 12px | `iiiiiiiiii` | -0.803, 25.852, 8.695, 0.000 | 0.000, 26.660, 11.060, 2.940 |
| 12px | `Ẁ` | -0.053, 11.285, 10.406, 0.000 | 0.000, 11.326, 11.060, 2.940 |
| 12px | `שלום` (Hebrew) | -1.020, 25.857, 9.756, 0.264 | 0.000, 26.373, 11.060, 2.940 |

Over all 80 cases, the difference (Flutter minus Chrome) is:

| Value | Smallest difference (px) | Largest difference (px) |
|---|---:|---:|
| `actualBoundingBoxLeft` | 0.012 (`WWWWWWWWWW`, bold 12px) | 2.039 (Hebrew, 24px) |
| `actualBoundingBoxRight` | 0.012 (`WWWWWWWWWW`, bold 12px) | 1.617 (`iiiiiiiiii`, 24px) |
| `actualBoundingBoxAscent` | 0.425 (`Ẁ`, bold 12px) | 5.607 (`1.5e-7`, 24px) |
| `actualBoundingBoxDescent` | -0.291 (`January`, 10px) | 5.881 (`WWWWWWWWWW`, 24px) |

Chrome gives a negative `actualBoundingBoxLeft` when the first glyph has a left side bearing. The
canvas layer gives 0 for `start` alignment.

An underline of `renderText` uses `actualBoundingBoxDescent`. Thus the canvas layer draws an
underline lower than Chrome: for text with no descender, 2.8 px lower at 12px. The underline
and the strikethrough span the advance box, not the ink box. These are pixel differences only
(Chart.js ADR 0034).

## 6. Repeat the probe

The probe has three parts:

| File | Part |
|---|---|
| `tool/reference/text_metrics/text_metrics.html` | The Chrome page. It has the fonts and the texts of the probe. It loads the font files and writes the `measureText` values as JSON |
| `tool/reference/text_metrics/text_metrics_reference.mjs` | The generator. It serves `packages/` on a local HTTP port, runs headless Chrome on the page with `--dump-dom` and writes `test/port/canvas/text_metrics_reference.dart` |
| `test/port/canvas/text_metrics_test.dart` | The Flutter side. It measures the same cases with `UiCanvasContext.measureText` and compares them with the reference |

Do these steps from `packages/flutter_chartjs`:

1. Run the generator. It needs Google Chrome, Node.js 22.15 or later and the Dart SDK on the
   `PATH`. The `CHROME` environment variable sets another Chrome binary.

   ```sh
   node tool/reference/text_metrics/text_metrics_reference.mjs
   ```

2. Run the test. Set `TEXT_METRICS_REPORT` to write the tables of this document to a file:

   ```sh
   TEXT_METRICS_REPORT=/tmp/text-metrics.md flutter test test/port/canvas/text_metrics_test.dart
   ```

3. Copy the new tables into this document. Update the Chrome version, the Flutter version and the
   OS in §2.

The reference engine is Chrome, not V8. Thus the x64 rule of
[Chart.js ADR 0032](adr/0032-js-numeric-semantics.md) does not apply to this probe.

## 7. Limits

- The probe ran on macOS. Upstream runs its specs in Chrome on Ubuntu. Chrome on Linux can use
  other font hinting and other subpixel settings. A probe on Ubuntu is not done yet.
- The probe measures the canvas layer in `flutter test` on the host. It does not measure the
  canvas layer on web (CanvasKit or skwasm) or on a device.
- The probe does not measure italic faces or fallback fonts. All texts of the probe have glyphs
  in Liberation Sans.
