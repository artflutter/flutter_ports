# Sankey ADR 0002: File naming, layout and the Dart forms

- Status: proposed
- Date: 2026-11-13
- Gate: sankey phase 1 (the first ported file).
- Related: [Chart.js ADR 0012](../../../flutter_chartjs_port/doc/adr/0012-file-naming-and-layout.md)
  (the file names of the host port),
  [Zoom ADR 0002](../../../flutter_chartjs_plugin_zoom_port/doc/adr/0002-file-naming-and-layout.md)
  (the layout of the first add-on port), [Sankey ADR 0001](0001-upstream-sources.md),
  [Sankey ADR 0003](0003-host-connection.md)

## Decision

1. **Source files.** `src/<path>.ts` becomes `lib/src/<path>.dart`, also below `src/lib/`. The
   file name keeps the upstream spelling (`index.esm.dart`).
2. **The entries.** `src/index.esm.ts`, the module entry, becomes `lib/src/index.esm.dart`.
   `lib/flutter_chartjs_chart_sankey_port.dart` (port-only) exports it and `lib/src/upstream.dart`.
   `src/index.ts`, the entry that registers the two components at its import, has no Dart file: a
   Dart import runs no code. An app registers the components with the port-only List of the
   public library: `Chart.register(sankeyRegisterables)`. The element keeps the upstream name
   `Flow`, which is also a Flutter widget name (host-seams.md, seam S21). `src/env.d.ts`,
   `src/content.config.ts` and `src/content/` are the docs site and have no Dart file.
3. **Unit tests.** `src/<path>.test.ts` becomes `test/specs/<path>_test.dart`. Each has a file
   target in `tool/port_sources.yaml`. `src/package.test.ts` tests the npm package file and has no
   Dart file.
4. **Specs and set-up.** `test/specs/<name>.spec.js` becomes `test/specs/<name>_test.dart`. A name
   with a hyphen has `// ignore_for_file: file_names`. `test/setup.js` becomes
   `test/flutter_test_config.dart`.
5. **Fixtures.** `test/fixtures/<path>.js` becomes `test/fixtures/hand/<path>.dart`, a hand port
   with the function `fixture()`. Upstream compares each fixture with a PNG image. The port
   compares observations of the chart with the values of the JavaScript chart
   (`tool/reference/fixtures_reference.mjs`, row `harness-fixture-observations`), as the zoom port
   does. `test/utils/` (the image compare, the sprite font, the chart helpers) has no Dart file:
   the chart helpers are those of `packages/chartjs_test_utils`.
6. **Port-only tests.** They go in `test/port/`. Shared test code goes in `test/support/`.
7. **String unions.** A union of string literals of an option is an enum whose value names are the
   upstream strings (`SankeyOrientation`, `SankeyLabelPosition`, `SankeyColorMode`, `SankeyModeX`,
   `SankeyNodePaddingMode`, `SankeySize`). A raw config holds the enum value. A name stops a debug
   build. This is the rule of the host for its own options.
8. **Host objects.** An option that the host holds as a Dart object has that object, also in the
   static `defaults` and `overrides`: a color is a `ChartPaint` (or a `Color`), a font a
   `TextStyle`, a padding an `EdgeInsets`, an easing a `Curve`, an interaction mode an
   `InteractionMode`, the tooltip callbacks a `TooltipCallbacks`.
9. **Objects of the chart.** A node, a flow list item and the custom part of a parsed item are
   classes with typed fields (`SankeyNode`, `FromToElement`, `SankeyParsedCustom`). The node fields
   `in` and `out` are `inFlow` and `outFlow`: `in` is a reserved word of Dart. A data item is a
   `SankeyDataPoint`, or a Map that the keys of the option `parsing` read.
10. **Options.** The options of a dataset and of a flow are objects of the host resolver, read by
    name. A facade (an extension type) gives each key as a getter. The typed option model of the
    host has no entry for the options of an add-on chart type (host-seams.md, seam S10).
11. **Differences.** A hunk that does not translate the upstream lines carries
    `// DIVERGES(sankey): <row id>, <reason>` and a row in `doc/differences.md`. `check:headers`
    pairs the markers and the rows.
