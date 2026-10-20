# D3 packages for Dart and Flutter

This page tells how each D3-related package on pub.dev and GitHub works, from its Dart API to its
output. It is part of the [prior-art survey](README.md) of 2026-10-20. Facts that change (versions,
downloads, likes, stars) are as of that date.

The survey put each package archive or repository in its own directory and read it statically. It
ran no package code and no `pub get`. It compared the code with the upstream D3 modules at their
release tags. Evidence cites `path:line` inside the inspected package. Upstream evidence has the
form `<module>@<version> <file>:<line>`.

Terms:

- **Native port**: D3 logic in Dart. No JavaScript runs.
- **Line for line**: the function bodies follow the upstream statements in the upstream order.
- **Loose port**: the upstream algorithm with a structure of its own.
- **Inspired**: D3 names or D3 defaults with code of its own.
- **JS interop**: Dart bindings that call the real D3 in a browser page.
- **By transcription**: a result of a Python transcription of the upstream algorithm. The survey
  wrote these transcriptions. They are not runs of the real JavaScript in Node.js.
- **Code lines**: lines that are not blank and not comments.

**Re-check marks.**

- The row **Re-check** of each facts table names the claims that a second reader confirmed in the
  cited files on 2026-10-20. The main session of this change or the author of this page read
  these files again.
- The mark *(no re-check)* follows a claim, a table or a subsection that comes from one survey
  pass only. Nobody examined its evidence a second time.
- Dates, adoption figures and repository states (archived, stars, forks, pub points) come from the
  pub.dev and GitHub APIs in one survey pass. They are all *(no re-check)*.

Packages: [`d4`](#pkg-d4) · [`fluent_2`](#pkg-fluent_2) · [`charted`](#pkg-charted) ·
[`sankey_flutter`](#pkg-sankey_flutter) · [`flex_org_chart`](#pkg-flex_org_chart) ·
[d3-force ports](#pkg-d3_force) · [`e_chart_ext`](#pkg-e_chart_ext) ·
[d3-hierarchy fragments](#pkg-treemap) · [`delaunay`](#pkg-delaunay) · [`topo`](#pkg-topo) ·
[D3 code in larger libraries](#pkg-larger) · [older D3 code and JS interop](#pkg-legacy) ·
[fragments in apps](#pkg-fragments) · [inspired or independent](#pkg-inspired) ·
[ruled out](#pkg-ruleouts)

<a id="pkg-d4"></a>

## `d4`: pure-Dart ports of 16 D3 v7 modules that do not draw, stalled since 2024-12-01

| | |
|---|---|
| Where | [pub.dev/packages/d4](https://pub.dev/packages/d4) and 17 `d4_*` packages, verified publisher `luizbarboza.com`. One GitHub repository for each package under [github.com/luizbarboza](https://github.com/luizbarboza) |
| Maintainer | Luiz Felipe Machado Barboza, alone. His earlier GitHub login was `SBanksX`, with the same user id 32441588 *(no re-check)* |
| Inspected | The latest archive of each package (table below). Four repository trees agree with their archives file for file *(no re-check)* |
| Status | Stalled. The last publish was `d4_scale` 0.1.1 on 2024-12-01. The umbrella `d4` 0.6.0 is of 2024-09-08. The `d4` repository has 13 commits, 39 stars and 5 forks |
| Approach | Native port: one Dart package for each D3 module and one Dart file for each upstream source file. The function bodies are line for line. The public API has Dart shapes: classes for closures and separate functions for JS overloads |
| Upstream | 16 of the 30 modules of D3 v7 (table below). No file names its upstream version. The survey dated each module from code markers *(no re-check)* |
| Works on | The 17 packages other than `d4_selection` import only `dart:collection`, `dart:math`, `dart:typed_data`, other `d4` packages and `jsontool`. They are pure Dart. `d4_selection` imports `dart:html`, `dart:js_interop` and `package:web`. It runs in a browser only. No package imports `dart:ui` or `package:flutter` |
| License | ISC. Each `LICENSE` names only "Luiz Felipe Machado Barboza" (2023 or 2024). No package has the D3 notice "Copyright 2010-2023 Mike Bostock" |
| Adoption (2026-10-20) | `d4`: 32 likes, 97 downloads in 30 days. `d4_array`, `d4_time` and `d4_time_format` have 14.4k-16.6k downloads, almost all through the Liquid template engine `liquify`. `d4_shape`, `d4_path` and `d4_polygon` have about 2k each. The other packages have 28-118 |
| Re-check | The versions, the `lib/` line counts and the Dart test counts of the table below. The upstream test counts. The first line of each `LICENSE`. The imports of each package. `_appendRound` of `d4_path`. The `digits` default of `d4_shape`. The overload pairs, `ScaleLinear`, `StackSeries` and `PieArc`. The UTC tests of `d4_time` |

### Packages

The column "Pin of this port" gives the tag that [D3 ADR 0001](../adr/0001-upstream-sources.md)
pins for the same module. The column "Upstream state" is *(no re-check)*. The author of this page
counted the lines and the tests again. "Tests" compares the Dart lines that start with `test(` with
the upstream lines that start with `it(` at the tag of the "Upstream state" column.

| Package | Latest, date | Upstream state (evidence) | Pin of this port | `lib/` lines | Tests: Dart / upstream |
|---|---|---|---|---:|---|
| `d4` | 0.6.0, 2024-09-08 | Umbrella. `lib/d4.dart` exports 16 packages. `lib/d4_web.dart` adds `d4_selection` | | 68 | none |
| `d4_array` | 1.0.0, 2023-08-06 | d3-array 3.2.4: the `quantileIndex` fix of 3.2.4 (#276) is at `lib/src/quantile.dart:128` | 3.2.4 | 2,969 | 334 / 529 |
| `d4_color` | 1.0.0, 2023-08-06 | d3-color 3.1.0: `formatHex8` (#103) is at `lib/src/color.dart:228` | 3.1.0 | 1,003 | 117 / 170 |
| `d4_dsv` | 1.0.0, 2023-08-06 | d3-dsv 3.0.1 (the file set agrees) | 3.0.1 | 608 | 130 / 136 |
| `d4_format` | 1.0.0, 2023-10-17 | d3-format 3.1.0: the 59 locale files are equal to those of v3.1.0. `formatDecimalParts` has the form before 3.1.1 | 3.1.2 | 1,022 | 148 / 154 |
| `d4_geo` | 2.0.0, 2024-08-05 | d3-geo `main` at `788c48a` (2022-11-21), between 3.0.1 and 3.1.0. That commit is the upstream PR #269 of the same author. No `path.digits` (3.1.0) | 3.1.1 | 4,921 | 334 / 334 (v3.0.1) |
| `d4_geo_parse` | 1.0.1, 2023-03-10 | No D3 counterpart: a GeoJSON parser into typed Dart classes | | 63 | none |
| `d4_hierarchy` | 0.1.0, 2024-07-31 | d3-hierarchy 3.1.2: the `encloseBasis3` fix is at `lib/src/pack/enclose.dart:154`. The `lcg` of 3.1.2 is at `lib/src/lcg.dart` | 3.1.2 | 2,654 | 76 / 83 |
| `d4_interpolate` | 1.0.4, 2024-03-08 | d3-interpolate 3.0.1 without `src/transform/` | 3.0.1 | 1,103 | 138 / 150. One of the 150 lines is in the block comment of `test/transformCss-test.js:1-25`. [parity.md](../parity.md) counts 149 |
| `d4_path` | 1.0.0, 2024-02-14 | d3-path 3.1.0: `pathRound` is `Path.round` (`lib/src/path.dart:49`) | 3.1.0 | 331 | 61 / 64 |
| `d4_polygon` | 1.0.0, 2024-02-14 | d3-polygon 3.0.1 | 3.0.1 | 235 | 23 / 23 |
| `d4_random` | 1.0.0, 2024-02-14 | d3-random 3.0.1 | 3.0.1 | 1,406 | 67 / 67 |
| `d4_scale` | 0.1.1, 2024-12-01 | d3-scale 4.0.2: the log `tickFormat` with `"~s"` of 4.0.2 is at `lib/src/log.dart:188-202` | 4.0.2 | 3,410 | 383 / 433 |
| `d4_scale_chromatic` | 1.0.0, 2024-02-14 | d3-scale-chromatic 3.0.0: no `schemeObservable10` (added in 3.1.0) | 3.1.0 | 3,968 | 1 / 1 |
| `d4_selection` | 0.1.1, 2024-09-05 | d3-selection 3.0.0 | 3.0.0 | 3,028 | 212 / 236, Chrome only |
| `d4_shape` | 1.1.0, 2024-09-07 | d3-shape 3.2.0: `digits` (#205) and `symbolTimes`. A port-only `StackTidy` too (`lib/src/stack_tidy.dart`) | 3.2.0 | 7,779 | 255 / 268 |
| `d4_time` | 1.0.0, 2023-10-17 | d3-time 3.1.0 tests, without the `utc*` and `unix*` intervals | 3.1.0 | 849 | 440 / 465 |
| `d4_time_format` | 1.0.0, 2023-10-17 | d3-time-format 4.1.0 and later `main`: the test locales have `vi-VN` | 4.1.0 | 971 | 140 / 146 |

The 16 module ports have 36,257 lines in `lib/` (36,388 with `d4` and `d4_geo_parse`). They have
2,859 Dart tests against 3,259 upstream tests (88%). The survey counted about 16.5k Dart code lines
against about 12.6k upstream JavaScript code lines *(no re-check)*.

D3 v7.9.0 has 30 modules. `d4` has none of these 14: d3-axis, d3-brush, d3-chord, d3-contour,
d3-delaunay, d3-dispatch, d3-drag, d3-ease, d3-fetch, d3-force, d3-quadtree, d3-timer,
d3-transition and d3-zoom. On issue d4#4 (2024), the owner wrote that d3-force needs d3-dispatch,
d3-quadtree and d3-timer first *(no re-check)*. No port followed.

The pins of this port are newer than `d4` for three modules: d3-format, d3-geo and
d3-scale-chromatic.

### How it works

The packages do not draw. As in D3, the generators compute data and path geometry.

1. Scales such as `ScaleLinear` and `ScaleTime` map values and give `ticks()` and `tickFormat()`.
2. The shape generators (`Line`, `Area`, `Arc`, `Pie`, `Stack`, `Symbol`, `Link`) and `GeoPath`
   return an SVG path string. As an alternative, they call methods on a `context` of the `d4_path`
   type `Path?` (`d4_shape/lib/src/line.dart:16,62-67`) *(no re-check)*.
3. `Path` of `d4_path` (`lib/src/path.dart:30`) is a concrete class. It builds an SVG string with
   the Canvas path methods (`moveTo`, `lineTo`, `quadraticCurveTo`, `bezierCurveTo`, `arcTo`,
   `arc`, `rect`). A caller can implement `Path` to receive the calls, as the tests do.
4. No package has a Flutter adapter, a `dart:ui` example, a `CustomPainter` or an `example/`
   directory *(no re-check)*. To draw on Flutter, a user writes a `Path` over `dart:ui.Path`, with
   an own `arc()` conversion. As an alternative, the user parses the SVG string. Both classes have
   the name `Path`. Thus one import needs a prefix.
5. `d4_selection` is the only DOM part. It ports d3-selection over `package:web` for Dart web apps,
   not Flutter. It keeps the data join and the listeners in the JS properties `__data__` and `__on`
   (`lib/src/selection/on.dart:24`) *(no re-check)*.

Two GitHub projects use the packages *(no re-check)*. `weebi-com/weebi_server` builds SVG strings
with `Pie` and `Arc`. `fanglu0411/sgs`, a single-cell genomics browser, uses `d4_scale` in Flutter
painters.

### How it handles JavaScript semantics

- **Overloads.** An optional JS accessor becomes a second function: `extent`/`extentBy` and
  `max`/`maxBy` (`d4_array/lib/src/d4_array.dart:9,17`). JS `undefined` becomes `null`. The
  result type is nullable *(no re-check)*.
- **Closures.** The closure scales of D3 become classes, for example `final class ScaleLinear<Y>`
  (`d4_scale/lib/src/linear.dart:176`). The mixins `Linearish`, `Loggish`, `Powish` and
  `Symlogish` share the methods *(no re-check)*.
- **JS arrays with extra properties.** `StackSeries` extends a port-only `DelegatingList`
  (`d4_shape/lib/src/stack.dart:302`). `PieArc` extends `DelegatingMap<String, num>`
  (`d4_shape/lib/src/pie.dart:415`).
- **`Date`.** D3's `Date` becomes `DateTime`. `d4_time` has the 3.1.0 test file
  `test/unix_day_test.dart`. Its library has no `unixDay` and no `utc*` intervals. The test calls
  `timeDay` on UTC dates. The tests need `TZ=America/Los_Angeles`, as the upstream tests do
  *(no re-check)*.
- **Coercion.** `+value` becomes `num.tryParse`. The strict ISO date pattern becomes
  `DateTime.tryParse`. The port changed the upstream test to agree: it drops `"2018-01"` and
  expects local midnight for `"2018-01-01"`, where JS gives UTC
  (`d4_dsv/test/auto_type_test.dart:16-19`) *(no re-check)*.
- **Int32 arithmetic.** Masks emulate it in `randomLcg` (`d4_random/lib/src/lcg.dart`) *(no
  re-check)*.
- **Number to string.** The packages do not emulate JS. Path and format output use the Dart
  `toString`, `toStringAsFixed`, `toStringAsExponential` and `toRadixString`.
  - `_appendRound` of `d4_path` writes `(x * k).roundToDouble() / k` with `join(",")`
    (`lib/src/path.dart:8-26`). The result is a `double`. Thus the Dart VM prints `1.0` where
    JavaScript prints `1`. dart2js prints `1`.
  - The shape generators use 3 digits by default (`d4_shape/lib/src/digits.dart:4`). Thus a pie
    arc on the VM has the arc flags `1.0,1.0`. Strict SVG parsers reject `1.0` as an arc flag.
  - `weebi_server` patches the output with `replaceAll('.0,', ',')` *(no re-check)*. The ported
    test matcher normalizes numbers as the upstream `assertPathEqual` does. Thus the tests do not
    find the problem (`d4_path/test/equals_path.dart:14-25`) *(no re-check)*.
- **`Math.round`.** It became `round()` or `roundToDouble()`. Dart rounds halves away from zero.
  JavaScript rounds halves toward positive infinity. `Math.round(-2.5)` is -2. Dart gives -3.
  This changes `Path.round` and `format("d")` for negative halves *(no re-check)*.
- **`Math.log10`.** It became `log(x) / ln10` (`d4_array/lib/src/ticks.dart:7`).
  `log(1000) / ln10` is 2.9999999999999996. In the cases that the survey traced, the factor of 10
  compensates. Nobody proved full equivalence *(no re-check)*.
- **Integer saturation.** `formatDecimal` runs `x.round().toString()` for `x < 1e21`
  (`d4_format/lib/src/format_decimal.dart:2`). On the VM, `double.round()` saturates at 2^63−1.
  Thus `format("d")(1e20)` will print `9223372036854775807` on native platforms. The survey
  inferred this bug and did not execute it *(no re-check)*.

### Tests

- The Dart tests use `package:test` on the Dart VM. Only `d4_selection` runs in Chrome
  *(no re-check)*.
- The test names are the upstream names. The assertions follow the upstream assertions one for
  one. For example, `1 / ticks(-1, 0, 5).removeLast()` equals `double.infinity`
  (`d4_array/test/ticks_test.dart:45-47`) *(no re-check)*.
- The packages keep copies of the upstream test data (CSV, TopoJSON, flare) under `test/data`.
  The tests read the data with `dart:io` *(no re-check)*.
- No test runs on dart2js or dart2wasm. Thus nobody tested the number output on the web and on
  WebAssembly *(no re-check)*.
- `d4_scale_chromatic` has only the single export test of upstream.

### Limitations

- **License gap.** No package has the ISC notice of Mike Bostock. ISC requires the notice in
  copies. The docs adapt the D3 READMEs and the D3 docs. These texts are ISC too *(no re-check)*.
  No file has a "Ported from" header or an upstream version *(no re-check)*.
- **`d4_selection` fails on current SDKs.** pana (runtime 2026.10.13) reports 29 analysis errors,
  for example `ARGUMENT_TYPE_NOT_ASSIGNABLE` at `lib/src/selection/on.dart:28` *(no re-check)*.
- **The umbrella can fail to resolve.** `d4_selection` needs `web: ^0.4.2`. `http` 1.6.0 needs
  `web >=0.5.0`. The survey inferred the conflict from the constraints and did not run a resolve
  *(no re-check)*. `d4` also exports the top-level names `max`, `min`, `map`, `filter`, `sort`
  and `index`. They clash with `dart:math` and need prefixes.
- **No interaction and no animation modules**: no d3-transition, d3-ease, d3-timer, d3-zoom,
  d3-drag, d3-brush or d3-axis.
- **No layer that draws, no examples and no Flutter integration.**

### Takeaways for flutter_d3_port

- `d4` is the nearest prior art to the method of this repository. It ports from a known upstream
  state. It keeps the file split and the test names. It translates function bodies line for line.
- It has no pins, no source headers, no D3 notice, no web or wasm test legs and no JS
  number-to-string. This port adds them:
  [D3 ADR 0001](../adr/0001-upstream-sources.md), [D3 ADR 0002](../adr/0002-file-naming-and-layout.md),
  [D3 ADR 0003](../adr/0003-number-to-string.md) and [D3 ADR 0004](../adr/0004-spec-harness.md).
- Its gaps give a list of cases that the specs must cover. The list: `double.toString` on the VM in
  path strings, `round()` against `Math.round`, `log10`, the saturation of `round()` and the
  `Date`/UTC split.
- It has no `dart:ui` path context and no painter host. [D3 ADR 0005](../adr/0005-path-context.md)
  and phase 4 of this port supply them.
- It has no interaction modules (dispatch, timer, ease, transition, zoom, drag, brush) and no
  quadtree or force. Phases 2, 6 and 7 of this port cover them.
- [AGENTS.md](../../../../AGENTS.md) rule 1 forbids a port from `d4`. `d4` is prior art only: it
  is neither a source nor a dependency of this port. Three of its modules are also older than the
  pins of this port.

Evidence: `d4_array/lib/src/d4_array.dart:9,17`, `d4_array/lib/src/ticks.dart:3,7`,
`d4_path/lib/src/path.dart:8-26,49`, `d4_shape/lib/src/digits.dart:4`,
`d4_shape/lib/src/stack.dart:302`, `d4_shape/lib/src/pie.dart:415`,
`d4_scale/lib/src/linear.dart:176`, `d4_time/test/unix_day_test.dart:1-20`,
`d4_selection/pubspec.yaml:11`, `d4_color/LICENSE:1`, against `d3-array@3.2.4 src/ticks.js:1-27`
and `d3-path@3.1.0 src/path.js`.

<a id="pkg-fluent_2"></a>

## `fluent_2`: a line-cited port of parts of 10 D3 modules inside a Fluent 2 widget library

| | |
|---|---|
| Where | [pub.dev/packages/fluent_2](https://pub.dev/packages/fluent_2). Source: [B1Digital/fluent_ui_2_flutter](https://github.com/B1Digital/fluent_ui_2_flutter), directory `packages/fluent_2/lib/src/charts/internal/d3/` |
| Inspected | The pub.dev archive of 0.0.7 (2026-09-25) and a shallow clone of the repository |
| Status | New. The repository is of 2026-08-04, with the last push on 2026-09-25 and 4 stars. The package is a widget library: "Microsoft Fluent 2 components for Flutter web and desktop: 90+ widgets, 20 chart types" (`pubspec.yaml:2-4`) |
| Approach | Native port of the D3 parts that the charts of `@fluentui/react-charts` use. The Fluent charts port that React library. That library uses D3. The D3 code is internal (`lib/src/charts/internal/d3/`). It is not a public D3 API |
| Upstream | d3-array 3.2.4, d3-color 3.1.0, d3-format 3.1.2, d3-interpolate 3.0.1, d3-path 3.1.0, d3-sankey 0.12.3, d3-scale 4.0.2, d3-shape 3.2.0, d3-time 3.1.0 and d3-time-format 3.0.0 (`test/charts/d3/README.md:35-38`). d3-time-format is 3.0.0 because `@fluentui/react-charts` declares `^3.0.0` |
| Works on | Flutter. 4 of the 28 D3 files import `dart:ui` (`Offset`, `Path`, `Radius`, `Rect`). The others import only `dart:math` and each other |
| License | MIT, "Copyright (c) 2026 ICITECH Teknoloji A.Ş." (`LICENSE:3`). `LICENSE` and `THIRD_PARTY_NOTICES.md` have no D3 ISC notice and no "Bostock" |
| Adoption (2026-10-20) | 4 GitHub stars. The survey did not record pub.dev figures |
| Re-check | The main session read the 0.0.7 archive. It confirmed 28 files and 6,602 lines in the D3 directory and `jsRound` in `js_math.dart`. It confirmed line-cited comments, such as `ticks.dart` with `d3-array/src/ticks.js:1`. It found no D3 or Bostock notice. The author of this page read the clone: the version, `LICENSE`, the imports, `path_sink.dart`, `stable_sort.dart`, the test counts and the metadata of the golden file |

### How it works

1. The Fluent chart widgets compute scales, ticks, shapes and the sankey layout with the internal
   D3 port.
2. The shape generators send their geometry to a path sink (`path_sink.dart`). The sink has the
   method names of d3-path. Thus a reader can follow `d3-shape/src/curve/*.js` line for line
   (`path_sink.dart:16-20`).
3. In production, `UiPathSink` builds a `dart:ui` `Path`. In the tests, a string recorder
   (`test/charts/d3/golden_support.dart`) writes path strings for the golden comparison.
4. The chart widgets paint the `Path` on the Flutter canvas *(no re-check)*.

### How it handles JavaScript semantics

- `js_math.dart` has `jsRound`, the JavaScript `Math.round` that rounds halves up
  (`js_math.dart:9-20`). It also has a `log10` that is exact at each decade boundary
  (`js_math.dart:33-40`).
- `stable_sort.dart` gives a stable sort for three call sites that tie. One of them is the
  d3-sankey comparator `ascendingBreadth` (`stable_sort.dart:1-12`). The Dart docs do not call
  `List.sort` stable.
- Comments cite upstream lines. For example, `ticks.dart:5-7` cites `d3-array/src/ticks.js:1` for
  `e10`.
- The test README names three number traps (`test/charts/d3/README.md:10-23`):
  1. `log(1000) / ln10` is 2.9999999999999996, where `Math.log10(1000)` is 3.
  2. `Math.round` rounds halves up. Dart `round()` rounds halves away from zero.
  3. `d3.ticks` stores a negated reciprocal and divides by it. A port that multiplies by the
     fractional step gives `0.006000000000000001` for `ticks(0.001, 0.009, 4)`. D3 gives `0.006`.

### Tests

- `test/charts/d3/` has 31 Dart files with 5,063 lines and 184 `test(` calls.
- They compare the port with `d3_golden.json`, "Oracle A". The file holds outputs of the real
  Node.js d3 modules (`test/charts/d3/README.md:3-6`).
- The generator `crawlers/d3-golden/generate.mjs` is not in git. The root `.gitignore:49` ignores
  `crawlers/`. Thus nobody can make the corpus again from the repository.
- The `meta` object of the golden file records the module versions. It does not record the
  Node.js version or build.

### Limitations

- It ports only the D3 parts that the Fluent charts use. It has no public D3 API.
- d3-time-format is 3.0.0, not the 4.1.0 of D3 v7.9.0.
- The package has no D3 notice. ISC requires the notice in copies.
- The golden corpus has no generator in git and no record of the reference engine.

### Takeaways for flutter_d3_port

- `fluent_2` has the most rigorous D3 port that the survey found. Its method is near to the method
  of this repository: line citations, JS-semantics shims, a stable sort and golden values from
  Node.js.
- Its path sink is the design of [D3 ADR 0005](../adr/0005-path-context.md). It has one interface
  with the d3-path method names, a `dart:ui` builder and a string recorder for the tests.
- Commit the reference generator. Record the reference engine. This port takes reference values
  only from an x64 Node.js v24.12.0
  ([Chart.js ADR 0010](../../../flutter_chartjs/doc/adr/0010-js-numeric-semantics.md),
  [D3 ADR 0004](../adr/0004-spec-harness.md)).
- The three number traps of its test README must have cases in the phase 1 pilot (d3-array
  `ticks.js`). [D3 ADR 0003](../adr/0003-number-to-string.md) and
  [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) give the JS math of
  this port.
- [AGENTS.md](../../../../AGENTS.md) rule 1 forbids a port from `fluent_2`. Its code is prior art
  only.

Evidence: `packages/fluent_2/lib/src/charts/internal/d3/ticks.dart:5-7`, `js_math.dart:9-20,33-40`,
`path_sink.dart:1-20`, `stable_sort.dart:1-12`, `test/charts/d3/README.md:3-6,10-23,27,35-38`,
`.gitignore:49`, `packages/fluent_2/LICENSE:3`.

<a id="pkg-charted"></a>

## `charted`: Google's archived reimplementation of a D3 v3 subset on `dart:html`

| | |
|---|---|
| Where | [pub.dev/packages/charted](https://pub.dev/packages/charted), [github.com/google/charted](https://github.com/google/charted) |
| Inspected | The pub.dev archive of 0.6.1 (2018-07-17). Git `master` at `946509279f41` (2019-09-04) has pubspec 0.6.2, never published *(no re-check)* |
| Status | Archived on GitHub, with the last push on 2019-09-04. 34 versions from 2014-08-13 to 2018-07-17. pub.dev: 5/160 points, `is:dart3-incompatible`, `license:unknown` |
| Approach | Hand reimplementation of a D3 v3 subset in typed Dart, with a large Google chart layer (`lib/charts`) on top. It is not line for line *(no re-check)* |
| Upstream | D3 v3, in agreement with 3.4.x. No file cites a version. `SvgArc` gives the D3 3.4.13 arc path strings. `createZoomInterpolator` has the form of 3.4 *(no re-check)* |
| Works on | Browser only (`dart:html`, `dart:svg`). SDK `'>=2.0.0-dev.55.0 <3.0.0'`. Not Flutter, not dart2wasm and not Dart 3 |
| License | BSD-3-Clause: "Copyright (c) 2014, Michael Bostock and Google Inc." One text merges the D3 v3 notice with the Google notice |
| Adoption | 157 stars, 57 forks, 0 likes, 80 downloads in 30 days |
| Re-check | The version, the SDK constraint (`pubspec.yaml:10`), `LICENSE:1`, `lib/charted.dart:9` ("implementation/port of D3.js in Dart"), and 83 files with 17,333 lines in `lib/` |

### How it works *(no re-check)*

- The selection API works on real `dart:html` elements. It keeps the bound data in an `Expando` of
  a `SelectionScope`, not in a `__data__` property (`lib/selection/selection_scope.dart:13,57-60`).
- Charts are SVG DOM trees that the selection API builds.
- Transitions run on `window.animationFrame` (`lib/core/timer.dart:9-51`).
- A hidden canvas measures text with `measureText`. Generated Unicode 7.0 tables (3,571 lines)
  give the grapheme breaks.

### What it ports *(no re-check)*

- **Ported, with Dart APIs:**
  - selection, transition and the timer
  - the linear, log, ordinal and time scales, and the axis
  - the arc, and the line (linear interpolation only)
  - the interpolators, the easings, `rgb` and `hsl`
  - number format, the en-US locale and the time intervals
  - the pie and treemap layouts
- **Different from D3:** the area generator is a stub (`path()` returns `null`). Time format maps
  strftime codes to `intl` patterns. It does not give the D3 output. The pie keeps the input order,
  where D3 sorts by value, largest first. The hierarchy layout has its own design.
- **Not ported:** geo, zoom, drag, force, tree, cluster, pack, partition, stack, histogram, chord,
  bundle, symbols, brush, fetch and `d3.nest`.
- The chart layer (`lib/charts`, 39 files) is Google code, not D3.

### Tests *(no re-check)*

`test.disabled/` has 43 files with 221 `test(` calls. Google wrote them. They are not ports of the
D3 tests. Six of their imports point to libraries that no longer exist.

### Limitations

- It stopped at D3 3.4. Nothing follows upstream: no pin and no source for each file *(no
  re-check)*.
- The SDK constraint ends at `<3.0.0` with a lower bound before null safety. Thus Dart 3 cannot
  resolve it. The code also uses Dart 1 constants, colon defaults and discontinued packages
  (`browser`, `observable`) *(no re-check)*.
- It depends on the DOM. No part runs on Flutter.

### Takeaways for flutter_d3_port

- It shows the D3 module split in typed Dart. Its `attr`/`attrWithCallback` pairs are one answer to
  the JS "value or function" arguments. [D3 ADR 0006](../adr/0006-generators-accessors-and-js-values.md)
  decides this for this port.
- Without a pin, source headers and ported tests, it could not follow D3 v4. Its own tests became
  stale. This port pins each repository and ports the upstream tests.
- d3-selection, d3-transition and SVG output do not apply to Flutter. Phase 7 of this port
  decides the DOM layer after a design doc.
- The merged notice is valid. pub.dev shows `license:unknown` for it. Keep the upstream license
  text unchanged as a separate component ([D3 ADR 0001](../adr/0001-upstream-sources.md)).

Evidence: `pubspec.yaml:10`, `LICENSE:1`, `lib/charted.dart:9`, `lib/svg/shapes/arc.dart:45-82`
against D3 3.4.13 `d3.js:7804-7808`, `lib/svg/shapes/area.dart:11-13`,
`lib/layout/src/pie_layout.dart:39,56-58`.

<a id="pkg-sankey_flutter"></a>

## `sankey_flutter`: a transcription of d3-sankey 0.12.3 with a layout divergence and a changed license line

| | |
|---|---|
| Where | [pub.dev/packages/sankey_flutter](https://pub.dev/packages/sankey_flutter), [github.com/Jason-Gregoire/sankey_flutter](https://github.com/Jason-Gregoire/sankey_flutter) |
| Inspected | The pub.dev archive of 0.0.3 (2025-12-29) and git `main` at `fb71ea49f12a`. They have the same content |
| Status | Small, low activity. 3 versions from 2025-04-16 to 2025-12-29. Open issue #3 asks for a way to tap links |
| Approach | Function-by-function transcription of d3-sankey `src/sankey.js` and `src/align.js` into one Dart class. It renames the fields: `x0`, `x1`, `y0`, `y1` become `left`, `right`, `top`, `bottom`. The code that draws is new *(no re-check)* |
| Upstream | d3-sankey 0.12.3 by its code. No file cites the version. README and CHANGELOG say "adapted from d3-sankey" *(no re-check)* |
| Works on | All Flutter platforms. The layout imports `dart:ui` (`lib/sankey_node.dart:3`) *(no re-check)* |
| License | BSD-3-Clause. `LICENSE` is the d3-sankey `LICENSE` with one change: "Mike Bostock" became "Jason Gregoire" ("Copyright 2015, Jason Gregoire"). No file keeps the Bostock notice |
| Adoption | 9 stars, 8 likes, 3,103 downloads in 30 days, 8 forks |
| Re-check | `LICENSE:1` against d3-sankey `LICENSE:1` ("Copyright 2015, Mike Bostock"), and the version |

### How it works *(no re-check)*

- `SankeyDiagramWidget` is a `GestureDetector` around a `CustomPaint` with a fixed size (default
  1000 x 600).
- Each link is one `Path`: `moveTo(source.right, y0)`, then `cubicTo` with the control points at
  the x midpoint. This is the curve of `sankeyLinkHorizontal`. A `LinearGradient` shader goes from
  the source color to the target color.
- Nodes are `drawRect`. Labels are `TextPainter`s.
- A tap selects the first node whose rectangle contains the point. Links have no hit test.

### What it ports *(no re-check)*

The port has the alignments, the defaults (`nodeWidth` 24, `nodePadding` 8, `iterations` 6),
`computeNodeLinks`, `computeNodeValues`, `computeNodeDepths`, `computeNodeHeights`,
`computeNodeBreadths`, the relaxation, `resolveCollisions`, `computeLinkBreadths`, `targetTop` and
`sourceTop`. It has no `nodeId`, no `nodes()` and `links()` accessors, no `update()` and no lookup
by string id.

Differences from d3-sankey 0.12.3:

1. `_reorderNodeLinks` (`lib/sankey.dart:445-456`) sorts the lists of the node itself. d3-sankey
   (`src/sankey.js:320-329`) sorts the lists of the neighbors of the node. By transcription, this
   moves 40 of the 48 nodes of the energy example.
2. The port stores the clamped padding in the public `nodePadding` (`lib/sankey.dart:301-303`). A
   second layout starts from the smaller padding.
3. d3 tests `sort === undefined`. Thus `nodeSort(null)` keeps the input order. In the Dart port,
   `null` means the default sort. The port lost the input-order mode.
4. JS `Array.prototype.sort` is stable. The Dart column sort has no tie-breaker
   (`lib/sankey.dart:358,388`). Dart does not guarantee a stable sort for long lists.
5. With one column, d3 divides by zero. The Dart port guards it (`lib/sankey.dart:234-235`).

### Tests *(no re-check)*

- `test/sankey_test.dart` has 1 layout test on the d3-sankey `energy.json`. It compares the result
  with `test/energy_nodes.json` and `test/energy_links.json`.
- The expected files do not come from d3-sankey. The d3-sankey energy test is `tape.skip`
  (`d3-sankey@0.12.3 test/sankey-test.js:4`).
- By transcription, the faithful d3-sankey 0.12.3 algorithm misses 40 of 48 nodes and 68 of 68
  links of the fixture. With the Dart `_reorderNodeLinks`, it misses none. Thus the port made its
  own fixture. The CHANGELOG claim "Test fixture parity with d3's energy.json example" is false.

### Takeaways for flutter_d3_port

- A small module ports well function by function. The d3 function names made the review easy.
  They showed the `reorderNodeLinks` slip.
- Parity values must come from the pinned JavaScript, not from the port
  ([D3 ADR 0004](../adr/0004-spec-harness.md)). Be careful with an upstream test that skips.
- Keep the JS `null` and `undefined` semantics of options. In d3, `nodeSort(null)` is a feature
  ([D3 ADR 0006](../adr/0006-generators-accessors-and-js-values.md)).
- A stable sort is behavior. The Chart.js port has `jsSort` for this.
  [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) proposes to share it.
- Never change the upstream copyright line. Add the holder of the port next to it
  ([D3 ADR 0001](../adr/0001-upstream-sources.md)).
- d3-sankey is not a module of D3 v7.9.0. It is not a pin of this port.

Evidence: `LICENSE:1`, `CHANGELOG.md:51,54`, `lib/sankey.dart:445-456` against
`d3-sankey@0.12.3 src/sankey.js:320-329`, `lib/sankey.dart:301-303,357-359`,
`test/sankey_test.dart:83-118`.

<a id="pkg-flex_org_chart"></a>

## `flex_org_chart`: a partial port of the d3-org-chart layout with new Flutter widgets

| | |
|---|---|
| Where | [pub.dev/packages/flex_org_chart](https://pub.dev/packages/flex_org_chart), [github.com/tps-reports/flex_org_chart](https://github.com/tps-reports/flex_org_chart) |
| Inspected | The pub.dev archive of 0.5.1 (2026-09-04) and git `main` at `634c53314a81`. `lib/` and `test/` are the same. Git adds `CLAUDE.md` and specification documents |
| Status | New and active. 6 versions from 2026-08-02 to 2026-09-04. Verified publisher `coyoteforge.com`. 160/160 points |
| Approach | Partial port. It ports the tidy-tree pass, the compact passes of d3-org-chart and the two link-path generators. The widget, controller, viewport, drag, edit and group-box code is new Flutter code *(no re-check)* |
| Upstream | d3-org-chart 3.1.1: the `REF src/d3-org-chart.js:<lines>` comments agree with the 3.1.1 file line for line. No file records the version. The code claims d3-flextree. It transcribes van der Ploeg 2013 Appendix C. d3-org-chart 3.1.1 uses d3-flextree 2.1.2. The code does not follow that version *(no re-check)* |
| Works on | All Flutter platforms. `lib/src/layout/` does not use Flutter *(no re-check)* |
| License | BSD-3-Clause, "Copyright (c) 2026 Michael Hunter". `THIRD_PARTY_LICENSES.md` has the MIT text of d3-org-chart with "Copyright (c) 2019 bumbeishvili" |
| Adoption | 1 like, 236 downloads in 30 days |
| Re-check | The version, `LICENSE:3`, `THIRD_PARTY_LICENSES.md:1-5`, `lib/src/layout/flextree.dart:1-3`, `lib/src/layout/compact.dart:3-5`, 4,047 lines in `lib/`, and 149 `test(` and `testWidgets(` calls |

### How it works *(no re-check)*

- `OrgChart` builds a `Stack`: group boxes, links (`EdgePainter`), connections, node widgets in
  `Positioned`, expand buttons and a drag ghost.
- Links are lists of path commands (`MoveTo`, `LineTo`, `CubicTo`). During a layout animation,
  `EdgePainter` interpolates the commands in pairs.
- Pan and zoom use a custom `ChartViewport` with a `Listener` and a `GestureDetector`, not
  `InteractiveViewer`.

### What it ports *(no re-check)*

- The compact passes of d3-org-chart (`calculateCompactFlexDimensions`,
  `calculateCompactFlexPositions`, lines 757-830) are faithful (`lib/src/layout/compact.dart`).
- The link generators `diagonal` and `hdiagonal` agree command for command
  (`lib/src/layout/link_geometry.dart:73-167`).
- The default margins of d3-org-chart are the same.
- The tidy tree (`lib/src/layout/flextree.dart`, 237 lines) follows van der Ploeg 2013 Appendix C.
  It does not have the `dist < 0 && isFirst` move of d3-flextree 2.x (`flextree.js:242`).
- By transcription, take a root with two children: a leaf and a node with four children. With
  250 x 150 nodes and the default margins, d3-flextree 2.1.2 places the children at x = ∓135. The
  port places them at x = ∓202.5.
- `stratify` is new code with the d3 name. There is no d3 `hierarchy()` or `tree()`.

### Tests *(no re-check)*

- 20 test files. Eight JSON fixture pairs hold node positions that the author captured from the
  JavaScript (`CLAUDE.md:94-95`). The fixture generator is not in the repository.
- By transcription, d3-flextree 2.1.2 and the compact passes of d3-org-chart 3.1.1 give all 16
  fixtures exactly. The fixtures do not have the tree shape of the divergence above.

### Takeaways for flutter_d3_port

- A `REF <upstream file>:<lines>` comment on each ported function and fixtures from the upstream
  JavaScript are cheap and effective. Commit the fixture generator too.
- Write the upstream version next to each reference. Port from the version that the target uses,
  not from an older relative.
- A layout core without Flutter under a widget layer agrees with the pure-layer rule of this
  repository.
- Fixtures must cover the known edge cases of the upstream algorithm.
- d3-org-chart and d3-flextree are not modules of D3 v7.9.0.

Evidence: `lib/src/layout/flextree.dart:1-3,117-149` against `d3-flextree@2.1.2
src/flextree.js:225-266`, `lib/src/layout/compact.dart:3-5`, `lib/src/layout/link_geometry.dart:73,125`,
`THIRD_PARTY_LICENSES.md:1-5`.

<a id="pkg-d3_force"></a>

## d3-force ports: `MathGaps/d3-force-flutter`, `d3-quadtree-flutter` and `theiskaa/force_graph`

### `MathGaps/d3-force-flutter` and `MathGaps/d3-quadtree-flutter`

| | |
|---|---|
| Where | [github.com/MathGaps/d3-force-flutter](https://github.com/MathGaps/d3-force-flutter) and its git dependency [github.com/MathGaps/d3-quadtree-flutter](https://github.com/MathGaps/d3-quadtree-flutter). Not on pub.dev (`publish_to: "none"`) |
| Inspected | `master` at `58c69a2943` (2021-11-27), pubspec 0.0.2. The quadtree repository at `e756b73567` (2021-11-27), 0.0.3 *(no re-check)* |
| Status | Archived. 18 stars and 6 forks. The push of 2023-12-15 comes from a `renovate/configure` branch and the archive step, not from code. The owner archived `d3-quadtree-flutter` too. It has 4 stars |
| Approach | Hand port of d3-force 3.0.0, module by module, with typed `Node` and `Edge` classes. It renames `forceLink` to `Edges` and `forceX`/`forceY` to `XPositioning`/`YPositioning`. d3-quadtree is a separate package *(no re-check)* |
| Upstream | d3-force 3.0.0: the LCG random source of 3.x and `jiggle(random)`. The tests are d3-force v3.0.0 tests with the same names and values *(no re-check)*. The d3-quadtree version is not known |
| Works on | Pure Dart: `dart:math`, `quiver` and the quadtree package. SDK `">=2.13.0 <3.0.0"`. The example is a Flutter app |
| License | MIT, "Copyright (c) 2021 Richard Mathieson". The d3-force ISC notice is absent. `d3-quadtree-flutter` has no `LICENSE` file. Its `README.md` is the d3-quadtree README |
| Re-check | The main session confirmed the `velocityDecay` bug. The author of this page read `lib/src/simulation.dart:19,49-52,95-105`, `lib/src/models/edge.dart:78-86`, `test/collide_test.dart:51`, `LICENSE:3`, `pubspec.yaml:6,18` and the file list of the quadtree repository |

**How it works.** The library does not draw. The example calls `simulation.tick()` in `setState`
from a `Ticker` on each frame *(no re-check)*. It has no d3-timer, no `restart` or `stop`, and no
stop at `alphaMin` *(no re-check)*. A custom `MultiChildRenderObjectWidget` places the node
widgets and draws the edges with `canvas.drawLine` *(no re-check)*.

**What it ports** *(no re-check)*. `forceSimulation` with `alpha`, `alphaMin`, `alphaDecay`,
`alphaTarget`, `velocityDecay`, `tick(n)`, `find`, the phyllotaxis start and `randomSource`. The
forces center, collide, link, many-body (Barnes-Hut over the quadtree), radial, x and y. The
quadtree package ports `add`, `addAll`, `cover`, `data`, `extent`, `find`, `remove`, `size`,
`visit`, `visitAfter`, `x` and `y`. The simulation timer and the `tick` and `end` events are
absent.

**Bugs and divergences.**

1. **`velocityDecay`.** The constructor stores 0.6 in `_velocityDecay` by default
   (`lib/src/simulation.dart:19`). `tick()` multiplies the velocities by the public getter
   `velocityDecay` (`:97,104`). The getter returns `1 - _velocityDecay`, thus 1 - 0.6 = 0.4
   (`:50`). d3 multiplies by its internal 0.6 (`d3-force@3.0.0 src/simulation.js:22,53,55`). Thus
   the Dart velocities decay faster.
2. **Link jiggle.** `x == 0 ? jiggle(random!) : x;` discards its result
   (`lib/src/models/edge.dart:82-83`).
   Two linked nodes at the same point give `0/0` and NaN velocities. d3 writes
   `x = … || jiggle(random)`.
3. **Setters apply the force.** The `Edges.edges` setter and three `ManyBody` setters call the force
   (`edge.dart:63-66`, `many_body.dart:35-48`). In d3, these setters store the value or call
   `initialize` *(no re-check)*.
4. **Points at the same position.** The `ManyBody` loop over points at the same position differs
   from d3 (`many_body.dart:116-124`). d3 tests `quad.data !== node` for each point *(no
   re-check)*.
5. **A test that fails.** `test/collide_test.dart:51` reads "TODO: these tests fail". The part
   that fails compares the exact numbers of d3 after a collision. Item 1 can explain it. The survey
   did not run the tests.

**Tests** *(no re-check)*. 10 of the 16 upstream d3-force tests: center 2/2, collide 4/4, find
2/2, simulation 1/2, x 1/6. `forceY` and the accessor tests are absent. The quadtree package has 36
tests with the upstream test names.

### `theiskaa/force_graph`

- [github.com/theiskaa/force_graph](https://github.com/theiskaa/force_graph): GitHub only, a
  project of one day (2026-06-15). MIT, "Copyright (c) 2026 Ismael Shakverdiev". It has no d3
  notice. The pub.dev name `force_graph` belongs to an unrelated Forge2D package.
- It ports the simulation, many-body, link and collide forces, the d3-force `lcg`
  (`lib/src/lcg.dart:1-2`) and "a focused port of d3-quadtree". It has no center, radial, x or y
  force *(no re-check)*.
- It stores the retained fraction `velocityRetain = 0.6` and multiplies by it. Thus its decay
  agrees with d3 (`lib/src/simulation.dart:34-37,92-102`).
- Its defaults come from react-force-graph, not d3: `alphaTarget` 0.02 and `alphaDecay` 0.008
  *(no re-check)*. Its tests are its own *(no re-check)*.

Other finds *(no re-check)*: `graphview_plus` 0.1.3 is "in the spirit of d3-force", a loose
reimplementation. `dkbast/d3_force_flutter` is an empty repository. No pub.dev package other than
`e_chart_ext` ports d3-force.

### Takeaways for flutter_d3_port

- A d3-force port is small: about 900 lines. The quadtree adds about 800 lines *(no re-check)*.
  The upstream tests are small and exact. They found the drift here.
- An upstream case that fails must stop a release. Here it became a TODO. In this port, a case
  passes or skips with a valid reason ([D3 ADR 0004](../adr/0004-spec-harness.md)).
- d3-force 3.x is deterministic: an LCG with seed 1. The value `a * s + c` stays below 2^53. Thus
  the LCG is exact in doubles. Exact-value cases can run on the VM and on the web.
- Some JS idioms do not map one to one
  ([D3 ADR 0006](../adr/0006-generators-accessors-and-js-values.md)). Examples are
  `x = expr || jiggle()`, the internal and public `velocityDecay`, setters that call
  `initialize()`, and `!value` against `== null`.
- This port ports d3-quadtree with its tests in phase 2, before d3-force in phase 6.

Evidence: `lib/src/simulation.dart:19,49-52,95-105` against `d3-force@3.0.0 src/simulation.js:22,53,55`,
`lib/src/models/edge.dart:78-86` against `src/link.js:36-37`, `test/collide_test.dart:51`,
`LICENSE:3`. For `theiskaa/force_graph`: `lib/src/simulation.dart:34-37,92-102`, `lib/src/lcg.dart:1-2`.

<a id="pkg-e_chart_ext"></a>

## `e_chart_ext` and `chart_xutil`: d3-force, d3-hierarchy, d3-sankey and d3-quadtree ports in an abandoned chart library

| | |
|---|---|
| Where | [pub.dev/packages/e_chart_ext](https://pub.dev/packages/e_chart_ext) and [pub.dev/packages/chart_xutil](https://pub.dev/packages/chart_xutil) (discontinued). The base package is `e_chart` 0.0.1. Author: Go-oG, also the author of `dart_dagre` and `dart_graph`. The GitHub repositories no longer exist *(no re-check)* |
| Inspected | `e_chart_ext` 0.0.1 (2023-05-10, the only version) and `chart_xutil` 1.0.6 (2023-06-08) |
| Status | Abandoned. pub.dev reports an analysis error for `e_chart_ext` |
| Approach | Native ports inside an ECharts-like Flutter chart library |
| Upstream | d3-force 3.x: simulation, center, collide, link, many-body, radial, x, y, `jiggle` and `lcg`. d3-hierarchy 3.x: pack `enclose` with the LCG, `siblings`, the treemap tiles with `resquarify`, and `tree` *(no re-check)*. d3-sankey 0.12: `sankey/layout.dart:11` cites `d3-sankey/blob/master/src/sankey.js` *(no re-check)*. d3-quadtree in `chart_xutil` *(no re-check)* |
| Works on | Flutter (`dart:ui`, `material`). SDK `'>=2.19.4 <3.0.0'` |
| License | Apache-2.0. `LICENSE` has no D3 notice |
| Adoption | `e_chart_ext`: 0 likes, 40 points, 26 downloads. `chart_xutil`: 0 likes, 120 points, 34 downloads |
| Re-check | The main session confirmed the version, the date, the SDK constraint and the d3-force port with `lcg`, `initialAngle` and `velocityDecay` 0.6. The author of this page read `force_simulation.dart:12,21,102,109,167`. The internal value 0.6 multiplies the velocities. The setter stores `1 - value`, as in d3. `LICENSE` has no "Bostock" and no "d3" |

**Takeaways.** The simulation keeps the internal `velocityDecay` of d3 correctly. The package is
abandoned. It has no tests other than a template. Its D3 code has no notice. It gives this port no
code. It is one more sign that d3-force ports are common in Dart.

Evidence: `pubspec.yaml:7`, `lib/src/graph/layout/force/force_simulation.dart:12,21,102,109,167`,
`lib/src/sankey/layout.dart:11` *(no re-check)*.

<a id="pkg-treemap"></a>

## d3-hierarchy fragments: `treemap`, `bubble_chart`, `circle_packing` and others

### `treemap`

| | |
|---|---|
| Where | [pub.dev/packages/treemap](https://pub.dev/packages/treemap), [github.com/lpongetti/treemap](https://github.com/lpongetti/treemap) |
| Inspected | 0.4.0 (2021-11-09) |
| Status | Abandoned since 2021. 10 stars |
| Approach | Direct port of the d3-hierarchy treemap tiles (`squarify`, `binary`, `dice`, `slice`, `sliceDice`), the treemap layout loop and `eachBefore`. The variable names, the comments and the control flow are the same. The coordinates are `left`, `top`, `right`, `bottom` *(no re-check)* |
| Upstream | d3-hierarchy. `squarify.js` of 1.1.8 and of 3.1.2 differ only in the `.js` import suffix *(no re-check)* |
| Works on | Flutter. The layout is plain math. The output is a `Stack` of `Positioned` widgets |
| License | BSD-3-Clause, "Copyright (c) 2018, Lorenzo Pongetti" only. No D3 notice. d3-hierarchy 1.x was BSD-3-Clause. d3-hierarchy 3.x is ISC. Both licenses require the notice |
| Adoption | 8 likes, 53 downloads in 30 days, 130 points |
| Re-check | `lib/src/tiles/squarify.dart:34`, the d3 comment "Find the next non-empty node." (main session). `squarify.dart:8` (`_ratio = (1 + sqrt(5.0)) / 2`), `LICENSE:1` and the version (author of this page) |

Differences from d3 *(no re-check)*: `Squarify` skips `value < 0`, where d3 skips a zero value.
`Binary` drops the `value ?` guard of d3 against a division by zero. `Squarify.ratio` writes a
static field. Thus it changes the ratio for each instance. Two copies exist: `RekeningkuDev/treemap`
and `caseyryan/flutter_lite_forms`.

### Other fragments *(no re-check)*

| Package | D3 code | License | Latest |
|---|---|---|---|
| [`bubble_chart`](https://pub.dev/packages/bubble_chart) (lpongetti) | d3-hierarchy `packSiblings` (front chain) and `packEnclose` (`lib/src/bubble_chart.dart:244-329`) | BSD-3-Clause, author only | 0.5.0 |
| [`circle_packing`](https://pub.dev/packages/circle_packing) | d3-hierarchy `pack/enclose.js` in the older form without shuffle, inside its own packer (`lib/src/circle_packing.dart:191,228,255`) | MIT, author only | 1.0.1 (2025-12-22) |
| [`smol/flutter_circle_packing`](https://github.com/smol/flutter_circle_packing) (GitHub) | d3-hierarchy pack, 2.x line: Dart `shuffle()`, not the seeded LCG of 3.x | none | 2022-03-19 |

**Takeaway.** d3-hierarchy code is the most copied D3 code in Dart. None of these copies keeps the
D3 notice.

<a id="pkg-delaunay"></a>

## `delaunay`: a port of Delaunator 4.0.x without the Mapbox notice in `LICENSE`

| | |
|---|---|
| Where | [pub.dev/packages/delaunay](https://pub.dev/packages/delaunay), [github.com/zanderso/delaunay.dart](https://github.com/zanderso/delaunay.dart) (13 stars) |
| Inspected | 3.0.0 (2025-10-11) |
| Status | Maintained. 5 versions since 2020-06-14 |
| Approach | Native port of Delaunator, the triangulator under d3-delaunay. `Delaunay32` and `Delaunay64`. No Voronoi part |
| Upstream | Delaunator 4.0.x: it has the `orientIfSure` robustness of 4.0.1 (`lib/src/delaunay_base_64.dart:729`). Delaunator 5 uses robust-predicates *(no re-check)* |
| Works on | Pure Dart, wasm-ready. The output is typed lists |
| License | BSD-3-Clause, "Copyright 2014 The Flutter Authors". The docs credit Delaunator. `LICENSE` has no Mapbox ISC notice |
| Adoption | 8 likes, 160 points, 334 downloads in 30 days |
| Re-check | The version, `LICENSE:1`, no Mapbox or Agafonkin name in `LICENSE`, and `lib/src/delaunay_base_64.dart:38` ("This implementation is adapted from the Delaunator JavaScript library.") |

The tests port the Delaunator cases and the fixtures `ukraine` and `robustness1` *(no re-check)*.

**Takeaways.** This port pins delaunator v5.1.0 with robust-predicates v3.0.3 for phase 5. The
`delaunay` package is the older 4.0.x line without `orient2d`. The Delaunator fixtures are upstream
test data. This port takes them from the pinned delaunator repository, not from the Dart copy.

<a id="pkg-topo"></a>

## `topo` family: ports of topojson-client, topojson-server and topojson-simplify *(no re-check)*

| | |
|---|---|
| Where | [pub.dev/packages/topo](https://pub.dev/packages/topo), `topo_client`, `topo_server`, `topo_simplify` and the helper `topo_parse`. The author of `d4` |
| Inspected | `topo_client` 1.0.4, `topo_server` 1.0.3, `topo_simplify` 1.0.1 (all 2023-08-06), `topo` 1.0.1 (2023-08-11) |
| Status | Stale since 2023-08 |
| Approach | Native ports of the topojson projects of Mike Bostock. They keep the upstream comments and the test names (`topo_client/lib/src/stitch.dart:8`, `topo_client/test/mesh_test.dart:6`) |
| Works on | Pure Dart, wasm-ready |
| License | ISC, Barboza only |
| Adoption | `topo_client`: 0 likes, 135 points, 80 downloads. The others: 7-11 downloads |

**Takeaway.** topojson-client is not a D3 module and not a pin of this port. The test data of later
phases comes from the upstream projects ([D3 ADR 0001](../adr/0001-upstream-sources.md)). The
`d4_geo` tests use `topo_client` and `topo_parse`.

<a id="pkg-larger"></a>

## D3 code in larger libraries: `graphic` and `mermaid_core`

### `graphic`

| | |
|---|---|
| Where | [pub.dev/packages/graphic](https://pub.dev/packages/graphic), github.com/entronad/graphic |
| Inspected | 2.7.0 (2026-02-25) |
| Status | Active. 901 likes, 42,881 downloads in 30 days |
| Approach | An independent grammar of graphics after AntV G2. One D3 function arrives through AntV: `linearNiceRange` in `lib/src/scale/util/nice_range.dart`. It is the d3-array 2.x `tickIncrement` and the d3-scale 2.x `linear.nice()` *(no re-check for the versions)* |
| Upstream | The 2.x forms: d3-array 3.x replaced this code with `tickSpec` and `Math.log10`. The default tick method of `LinearScale` is the Wilkinson Extended method of AntV, not D3 *(no re-check)* |
| License | MIT. `LICENSE_APPENDIX` names d3: "ISC License / Copyright 2010-2021 Mike Bostock". The appendix does not map files to projects |
| Re-check | `nice_range.dart:43`, the comment "From d3-scale." (main session). `nice_range.dart:5-7` (`sqrt(50)`, `sqrt(10)`, `sqrt(2)`), `LICENSE_APPENDIX:66-70` and the version (author of this page) |

### `mermaid_core`

| | |
|---|---|
| Where | [pub.dev/packages/mermaid_core](https://pub.dev/packages/mermaid_core), github.com/orestesgaolin/mermaid (24 stars). The painter is in `mermaid_flutter` |
| Inspected | 0.3.2 (2026-10-19) |
| Status | Very active. 8 versions since 2026-08-30. 4,253 downloads in 30 days |
| Approach | A pure-Dart port of mermaid.js. It transcribes the D3 parts that mermaid uses: the d3-sankey layout steps, the d3-array ticks, the d3-shape `curveBasis`, the pie defaults and the Tableau10 scheme. It vendors `dart_dagre` 1.0.0 *(no re-check, except the two lines below)* |
| License | MIT, with the Apache-2.0 `dart_dagre` *(no re-check)* |
| Re-check | The version. `lib/src/diagrams/sankey/sankey.dart:233` ("mirroring d3-sankey's"). `lib/src/edge_geometry.dart:42` ("Matches d3-shape's `curveBasis` point emission.") |

**Takeaways.** D3 algorithms reach Dart through ports of other JS libraries: AntV, mermaid.js and
`@fluentui/react-charts`. Their D3 parts can be old forms, such as the d3-array 2.x code in
`graphic`. `graphic` shows one notice form: an appendix that names d3. A notice for each component,
with its paths, is clearer ([D3 ADR 0001](../adr/0001-upstream-sources.md)).

<a id="pkg-legacy"></a>

## Older D3 code, JS interop and dagre ports *(no re-check)*

| Package | Kind | Upstream | Latest | License |
|---|---|---|---|---|
| [`d3`](https://pub.dev/packages/d3) (rwl) | JS interop (`dart:js`) over a bundled `lib/d3.js` | D3 3.5.10 | 0.2.0 (2015-12-15), unlisted | The bundled D3 has its BSD-3 notice. The package license is unknown |
| [`d3d`](https://pub.dev/packages/d3d) | Partial native port: core, format, selection on `dart:html` | D3 v3 | 0.0.1 (2014-07-19) | The D3 BSD-3 text, "Copyright (c) 2010-2014, Michael Bostock" |
| [`d3dart`](https://pub.dev/packages/d3dart) | Partial native port on `dart:html` and `dart:svg`: selection, scales, line, arc, axis, layouts | D3 v3 (the examples ship 3.3.8) | 0.0.1 (2015-09-08) | MIT template without a holder. No D3 notice |
| `grizzly_vizdom`, `vizzie_dom`, `vizdom_select` | Loose port of the d3-selection v1 data join on `dart:html` | d3-selection v1 | 2017-2019 | BSD-3-Clause (author) or none |
| [`grizzly_range`](https://pub.dev/packages/grizzly_range) | Port of the d3-array `ticks`, `tickIncrement` and `tickStep`. `tickStep` lost the `else` chain | d3-array 2.x | 3.0.7 (2024-03-16) | BSD-3-Clause (author). No D3 notice |
| [`nvd3`](https://pub.dev/packages/nvd3) | A mechanical rewrite of NVD3 1.8.6-dev that does not compile | NVD3 (D3 v3) | 0.0.1 (2020-05-29) | MIT (author) |
| [`choropleth_map_angular_dart`](https://pub.dev/packages/choropleth_map_angular_dart) | AngularDart 2 with `dart:js` over a bundled d3 and d3-geomap | D3 3.5.17 | 0.1.0 (2016-11-23) | BSD-3-Clause |
| `jacob314/js_facade_examples` (GitHub) | Generated `package:js` facades for the D3 v4 typings, 40 modules | D3 v4 | 2016 | none |
| `dagre`, `graphlib`, `dagre_charted`, `dart_dagre` | Ports of dagre and graphlib (Chris Pettitt), not D3 | dagre | 2015, 2024 | MIT (Pettitt). `dart_dagre` is Apache-2.0 without the MIT notice of Pettitt |

**Takeaways.** Other packages hold the pub.dev names `d3`, `d3d`, `d3dart` and `d4`
([ADR 0007](../../../../docs/adr/0007-package-names.md)). The Dart 1 code shows that JS interop and
`dart:html` code did not survive Dart 2 and Dart 3. That is one reason for native ports
([ADR 0001](../../../../docs/adr/0001-native-ports-not-wrappers.md)).

<a id="pkg-fragments"></a>

## Fragments in apps and small repositories *(no re-check)*

| Repository | D3 code | License |
|---|---|---|
| `iceice666/pirc` (app) | `d3_sankey_layout.dart`: "adapted from d3-sankey 0.12.3. Copyright 2015 Mike Bostock; BSD-3-Clause, see D3_SANKEY_LICENSE.txt". The only Dart file found that names the upstream version and ships the upstream notice | none at the root |
| `kevinzhow/raft-flutter` (app, 88 stars) | The d3-zoom `ZoomTransform` and the wheel, pan and pinch math, "a line-for-line port" | none |
| `rlch/d3-flutter` | A monorepo stub with a d3-dispatch port (153 lines) | none |
| `Grizzly-dart/range` | The d3-array ticks of `grizzly_range`. The doc comment is the d3-array README text | BSD-3-Clause |
| `andry-brill/a-sparklines` (`any_sparklines`) | The d3-shape arc `cornerTangents` without credit | a non-commercial license |
| `Roaa94/flutter-meets-art` | Delaunator through `delaunay`, and a Voronoi after d3-delaunay `voronoi.js` | none |
| `romanbsd/mermaid-dart` | d3-array ticks, a d3-hierarchy treemap ("port of d3") and a vendored dagre | none at the root |
| `random-knights/earth` (app) | d3-geo in JavaScript, through a `window.__earth2d` shim in an `HtmlElementView` | MIT |
| `fanglu0411/sgs` (app, 101 stars) | A user of `d4` (`d4_scale` in Flutter painters) | none |
| More than 10 app repositories | d3-force-style simulations with the d3 defaults (`alphaDecay` 0.0228, `velocityDecay`, `jiggle`) and their own code | mostly none |

On GitHub, only apps and demos host the D3 JavaScript in a WebView or an `HtmlElementView`. No
pub.dev package does.

<a id="pkg-inspired"></a>

## Inspired or independent *(no re-check)*

| Package | Relation to D3 | License | Latest |
|---|---|---|---|
| `data_visualization` and 35 `dv_*` packages | The visx package split with D3 names and loose code. `dv_scale` uses `_e10 = sqrt2^5 ≈ 5.66` where d3-array uses √50 ≈ 7.07. Thus its ticks differ from D3. `dv_delaunay` follows the Delaunator sweep hull under a "Bowyer-Watson" comment | MIT | 1.1.0 (2026-01-27) |
| `duskmoon_visualization` | Vendors the `dv_*` sources | MIT | 2.1.1 (2026-10-19) |
| `graphview_plus` | "Force-directed layout in the spirit of d3-force", own code | MIT | 0.1.3 (2026-10-08) |
| `sankey_diagram_flutter` | "matching d3-sankey behaviour", own relaxation | MIT | 1.1.0 (2026-06-21) |
| `bharat_choropleth` | "Mirrors d3-geo's geoMercator().fitExtent", own Mercator | MIT | 0.3.0 (2026-09-06) |
| `uyava_core`, `crystal_charts`, `xtal_dataview`, `dart_graph`, `grizzly_scales`, `grizzly_axis` | D3 names or D3 doc text, own code | MIT or BSD-3-Clause | 2019-2026 |
| `fl_chart` | Independent. Its tick thresholds are 1.6, 2.6 and 7.6, where D3 uses √2, √10 and √50. Its curves have no D3 form | MIT | 1.2.0 (2026-03-13) |
| `syncfusion_flutter_charts` | Independent. Proprietary license: do not reuse | Syncfusion | 35.1.40+1 |
| `graphview` | A port of the Android library Team-Blox GraphView (Apache-2.0), not D3 | MIT | 1.5.1 (2025-10-17) |
| `force_directed_graphview` | Its own Fruchterman-Reingold layout, without a quadtree or alpha | MIT | 0.6.2 (2024-03-04) |

**Takeaway.** A D3 name or a D3 constant does not make a port. Compare the constants: the tick
thresholds of `dv_scale` differ from d3-array.

<a id="pkg-ruleouts"></a>

## Ruled out *(no re-check)*

These packages have "d3" or a D3 topic in the name or the text. They have no D3 code and no D3
wrapper:

- `d3_ui` (a design system), `d3122` (a calculator template), `d3d11` and `d3d12` (Direct3D), and
  the ID3 tag packages.
- `chord`, `chord_diagrams` and `chord_pro` (music chords).
- `plotly_js`, `plotly`, `vega_embed_flutter`, `flutter_echarts` and `graphify`: they wrap other JS
  libraries that use D3 inside.
- `force_directed_graph`, `flutter_force_directed_graph`, `force_graph` (Forge2D), `plough`,
  `flutter_graph_view` and `graph_layout`: their own force layouts.
- `treemap_ui`, `any_treemap`, `flutter_treemap` (GPL-3.0), `quadtree`, `quadtree_dart`,
  `voronoi`, `delaunay_triangulation`, `topojson`, `word_cloud` and `word_cloud_plus`: their own
  algorithms.
- `ploeg_tree_layout`: a port of the Java code of van der Ploeg, not d3-flextree.
- `dependency_graph`: a Dart CLI that writes an HTML page. The page loads d3 7.9.0 from cdnjs.
