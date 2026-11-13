# Chart.js ADR 0132: Exports for add-on chart types

- Status: accepted (2026-11-13): the tests of each package and the port checks pass.
- Date: 2026-11-13
- Related: [ADR 0009](../../../../docs/adr/0009-add-on-ports.md) (add-on ports), Chart.js ADR 0048 (the public
  libraries), Chart.js ADR 0108 (the input surface and exports for add-on plugins),
  [Sankey ADR 0003](../../../flutter_chartjs_chart_sankey_port/doc/adr/0003-host-connection.md) (the connection
  of the first add-on chart type).
- Supersedes: of Chart.js ADR 0108, the list of 11 names of `lib/js_semantics.dart`; of Chart.js ADR 0048 §6,
  the hide of `VisualElementRange`.

## Context

Chart.js ADR 0108 gave the public libraries the names that an add-on plugin needs. The first add-on plugin,
chartjs-plugin-zoom, reads the chart from the outside. The second add-on, chartjs-chart-sankey, is a chart type: a
subclass of `DatasetController` and a subclass of `Element` in another package. The port of that add-on found
four needs that no Dart form in the add-on covers:

- `DatasetController.parseObjectData` returns `List<ParsedItem>`. An override makes the items, but `ParsedItem`
  had no public name.
- `Element.tooltipPosition` returns `ElementPoint`. An override that gives another point makes one, but
  `ElementPoint` had no public name.
- The interaction of the host tests an element against `VisualElementRange` for `getRange`. `chartjs.dart` hid the
  interface, so an element of another package could not have a `getRange` that the host sees.
- The sankey layout sorts with `Array.prototype.sort`, a stable sort. `check:js-semantics` tells the porter to use
  `jsSort`, which `lib/js_semantics.dart` did not export.

`lib/js_semantics.dart` exported 11 names with `show` lists. Each new add-on needs other functions of the runtime.

## Decision

1. `lib/chartjs.dart` exports `ParsedItem`, `ElementPoint` and `VisualElementRange`.

   ```dart
   class Flow extends Element implements VisualElementRange {
     @override
     ElementPoint tooltipPosition([bool? useFinalPosition]) =>
         getCenterPoint(useFinalPosition ?? false);

     @override
     Object getRange(ScaleAxis axis) => axis is XAxis ? 0.0 : height / 2;
   }
   ```

2. `lib/js_semantics.dart` exports each library of `lib/src/js/` with each of its names, with no `show` list (the
   maintainer, 2026-11-13). The library stays the JS runtime for ports of add-ons: `chartjs.dart` and the app
   library do not export it.

   ```dart
   import 'package:flutter_chartjs_port/js_semantics.dart' show jsSort;

   jsSort(node.from, (a, b) => b.flow - a.flow);
   ```

3. The other needs of an add-on chart type have a Dart form in the add-on. The sankey port records each one as a
   seam in its `doc/host-seams.md`. They are the input for the work on the public API of the host, and this
   record decides none of them: the public names of the interface types in the signatures of `DatasetController`,
   the class value of a component, the option keys of an add-on, the typed defaults, the element properties, the
   chart kind of the typed config and the theme extension.

## Consequences

- `doc/public_api.txt` has the new names. `test/tool/public_api_test.dart` compares the list.
- A name of `lib/src/js/` is public API of the runtime library. A change of such a name is a change of that
  library.
- When the shared package `js_semantics` of ADR 0008 exists, `lib/js_semantics.dart` exports that package, as
  before.
