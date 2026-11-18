# Chart.js ADR 0170: Typed gallery type pages

- Status: accepted (2026-11-18): its code and the tests of section Tests pass.
- Date: 2026-11-18
- Supersedes: of [Chart.js ADR 0052](0052-typed-public-api.md), section 13, the item "The docs pages of the
  gallery stay raw".
- Related: `test/port/typed/docs_twins_test.dart`

## Context

Chart.js ADR 0052 kept the docs pages of the gallery raw, because they are ports of the docs blocks with rule-2
headers. The docs twin test of the same ADR (section 11) has a typed `ChartConfig` for each of the 12 docs configs
of the gallery. The test proves that each typed config draws the chart of its raw block: the same observations,
hits and draw calls, unthemed and under `ChartThemeData.light()`. The gallery is the first code that an app author
reads, and the typed config is the entry of an app.

## Decision

1. **The chart type pages are typed.** The 9 chart type pages show a `ChartView` with a typed `ChartConfig`. The 12
   config functions of `apps/chartjs_gallery/lib/docs/charts/` and `lib/docs/samples/area/line_boundaries.dart`
   return a `ChartConfig`. Each function is a copy of the typed config of its docs twin.

   ```dart
   ChartConfig barVerticalConfig() => const ChartConfig(
     type: .bar,
     labels: _months,
     datasets: [BarDataset(label: 'My First Dataset', data: [65, 59, 80, 81, 56, 55, 40], ...)],
     scales: {'y': LinearAxis(beginAtZero: true)},
   );
   ```

2. **The page adds its parts with `copyWith`.** `ChartTypePage` adds the option `onHover` and its readout plugin to
   the config of the variant with `ChartConfig.copyWith`, once for each variant.

3. **The files stay docs ports.** Each file keeps its rule-2 header. `check:headers` does not scan the gallery, so
   the files have no new marker and `differences.md` has no new row. The doc comment of a config names each typed
   form that differs from the docs block. Three forms differ:
   - The horizontal bar and the vertical line leave out the dataset key `axis`. Chart.js 4.6.1 does not read it.
   - The horizontal bar leaves out `fill: false`. The filler reads `fill` only for a dataset with a line element.
   - The title of the Area sample is the constant text of each variant, in place of the function of
     `line-boundaries.md:106`. `ChartTitle.text` is a `String`, and a `FillTarget` has no text.

4. **Two pages stay raw.** The zoom page stays raw, because its actions write new zoom options into the live config,
   as the docs do. A new typed config with another option resets the zoom range (row `theme-switch-zoom-range`). The
   sankey page stays raw, because a `ChartConfig` takes no dataset of another package.

5. **The twins keep both forms.** The typed config of each docs twin is the copy of the gallery config. The raw twin
   keeps each key and value of the docs block.

## Rejected

- Keep the type pages raw: an app author reads the gallery first, and the typed config is the entry of an app.
- Move the zoom page too: an action of a docs sample then resets the zoom range, and the docs keep it.

## Consequences

- `gallery-web` compiles the typed path of 9 pages.
- A change of a docs config of the gallery changes the typed config of its docs twin in the same commit.

## Tests

- `apps/chartjs_gallery/test/chart_types_test.dart` and `apps/chartjs_gallery/test/gallery_test.dart`
- `test/port/typed/docs_twins_test.dart`
