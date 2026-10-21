# ECharts ADR 0002: File naming and package layout

- Status: proposed
- Date: 2026-10-21
- Gate: ECharts phase 1. The first ported file needs its Dart path and its header block. The
  forward-type rule of section 9 has gate 2. Phase 2 is the first phase with type references to
  classes of later phases.
- Related: [Chart.js ADR 0012](../../../flutter_chartjs/doc/adr/0012-dart-file-naming.md) (the
  precedent: upstream spelling, Dart-cased identifiers, underscore members),
  [Chart.js ADR 0023](../../../flutter_chartjs/doc/adr/0023-underscore-member-collisions.md)
  (underscore members whose names collide),
  [Chart.js ADR 0028](../../../flutter_chartjs/doc/adr/0028-controller-interfaces.md) (the
  port-only types folder that this ADR does not take),
  [D3 ADR 0002](../../../flutter_d3_port/doc/adr/0002-file-naming-and-layout.md) (the
  `file_names` ignore line and the module index forms),
  [ADR 0007](../../../../docs/adr/0007-package-names.md) (the package name),
  [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (tool 2 and tool 1 for
  all ports), [ECharts ADR 0001](0001-upstream-sources.md) (the pins, the headers and the source
  list), [ECharts ADR 0004](0004-js-values-classes-and-options.md) (the value map, the class
  registry and the mixins), [ECharts ADR 0005](0005-spec-harness-and-reference-tests.md) (the spec
  form and the harness files), [ECharts ADR 0006](0006-renderer-and-canvas-layer.md) (`ZrViewport`
  and the fallback canvas folder),
  [ECharts ADR 0007](0007-environment-host-and-input-events.md) (`EChartsContainer`,
  `EChartsHost` and the handler proxy),
  [ECharts ADR 0008](0008-dates-locales-and-formatting.md) (the locale files),
  [ECharts ADR 0009](0009-dom-features-app-hooks-and-theming.md) (`lib/src/theme/`),
  [porting-flow.md](../porting-flow.md), [parity.md](../parity.md),
  [differences.md](../differences.md)

## Context

The port translates ECharts and zrender file by file (AGENTS.md rules 1 and 2). Tool 2, the bump
review and the header restamp map an upstream path to a Dart path. A mechanical map keeps these
tools simple.

Chart.js ADR 0012 and D3 ADR 0002 give that map for their ports. An ADR of another port binds
only that port. Thus this ADR states the complete ECharts rule.

The counts are at the pins of [ECharts ADR 0001](0001-upstream-sources.md): ECharts `6.1.0`
(`c5a48f5f`) and zrender `6.1.0` (`32b66867`). The Evidence section gives the method.

- **Two repositories in one package.** ECharts `src/` has 596 `.ts` files: 595 modules and
  `global.d.ts`. zrender `src/` has 120: 119 modules and `global.d.ts`. Together they have 716
  files and 169,724 lines. Both trees have the folders `animation/` and `core/`. Both trees have
  a file `global.d.ts`.
- **The bare specifier.** ECharts imports zrender as `zrender/src/<path>`. 362 ECharts source
  files have 784 such import lines. This is the only bare specifier of both `src/` trees. No
  source file has an npm import, a dynamic `import()` or a `require`. zrender never imports
  ECharts.
- **The value graph.** A value edge is an import with at least one binding in a value position.
  The graph of the value edges has no cycle. Its files have 30 value levels, 0 to 29. The top
  file is `echarts.all.ts`. Upstream keeps the back references type-only, for example
  `model/Global.ts` to `model/Series.ts`.
- **Type edges and cycles.** The two trees have 5,184 import edges. 2,195 of them are type-only.
  Only 359 of these use `import type` or `export type`. With the type edges, the graph has 7
  cycles:
  - 248 ECharts files with 80,400 lines: data, model, util, core, coord, scale, view, label and
    most chart and component folders.
  - 28 zrender files with 13,502 lines: `Element.ts`, `Storage.ts`, `Handler.ts`, `zrender.ts`,
    `PainterBase.ts`, the canvas painter, `Displayable.ts`, `Path.ts`, `Text.ts` and the
    animation files.
  - Five cycles with 2 to 4 files. Two of them hold pilot files. `zrender src/core/vector.ts:5`
    imports `MatrixArray` from `matrix.ts`. `matrix.ts:8` imports `VectorArray` from `vector.ts`.
    The other cycle is `core/util.ts`, `core/dom.ts`, `graphic/Pattern.ts` and `svg/core.ts`.

  Dart allows import cycles inside a package.
- **Directories are not layers.** Over value edges, the directory groups form three cycles. One
  cycle has 74 ECharts groups. One has 9 zrender groups. One has zrender `config.ts` and `core/`.
  For example, `util/` imports `model/`. `model/` also imports `util/`. The files of `util/` span
  value levels 0 to 23. The files of `coord/` span 0 to 21. The files of `data/` span 0 to 15.
- **Type hubs.** `util/types.ts` (2,211 lines) is the target of 295 type-only edges and 22
  value edges. Next come `model/Global.ts` (185), `core/ExtensionAPI.ts` (130), `data/SeriesData.ts`
  (87), `model/Model.ts` (82) and zrender `Element.ts` (71).
- **Type-only files.** Only 10 files emit no JavaScript. They have 860 lines in the count of the
  module notes. `wc -l` gives 856, because 4 of the files have no final newline.
  - ECharts `chart/helper/baseDraw.ts`, `component/axisPointer/AxisPointer.ts`,
    `coord/AxisBaseModel.ts`, `coord/geo/geoTypes.ts`, `core/ExtendedElement.ts`,
    `visual/commonVisualTypes.ts` and zrender `PainterBase.ts` declare interfaces and types.
  - ECharts `src/global.d.ts:20` declares `__DEV__`. zrender `src/global.d.ts:1-5` declares the
    type of `process.env.NODE_ENV`. zrender reads this value at 19 sites in 12 files, for example
    `src/Element.ts:1323`.
  - ECharts `coord/cartesian/defaultAxisExtentFromData.ts` (289 lines) has all its code in
    comments. Its doc block says `@obsolete` and "This file is not used anywhere currently."
    (`:37-39`).
  - `export/option.ts` (316 lines) re-exports the option interfaces with plain `export {...}`. The
    graph counts it as a run-time file. In effect, it is type-only too.
- **Forward type references.** The module notes compute a phase as the value closure of its
  roots, without the files of earlier phases. The type edges from a phase to a later phase are
  forward type references:

  | Phase | Edges | Target files |
  |---:|---:|---:|
  | 1 | 4 | 4 |
  | 2 | 132 | 46 |
  | 3 | 1 | 1 |
  | 4 | 30 | 20 |
  | 5 | 7 | 5 |
  | 6 | 10 | 8 |
  | 7 | 13 | 7 |
  | 8, 9, 10 | 0 | 0 |

  - The 4 edges of phase 1 name only type aliases and the interfaces of two type predicates.
    `util/number.ts:30` imports `NullUndefined` (`util/types.ts:73`). zrender `core/util.ts:2-4`
    imports `Dictionary`, `ArrayLike`, `KeyOfDistributive` and `NullUndefined`
    (`core/types.ts:1`, `:9`, `:104`, `:21`), `GradientObject` and `ImagePatternObject`. It uses
    the last two only in the predicates `isGradientObject` and `isImagePatternObject`
    (`core/util.ts:582-588`).
  - The largest targets of phase 2 are `data/SeriesData.ts` (14 edges), `model/Series.ts` (14),
    `model/Global.ts` (13), `model/Model.ts` (11) and zrender `Element.ts` (9). These are classes.
  - The largest targets of phase 4 are `coord/CoordinateSystem.ts` (6 edges), `view/Chart.ts`
    (2), `coord/single/SingleAxis.ts` (2) and `core/Scheduler.ts` (2).
  - The module notes computed the sets before the planner moved zrender `tool/parseSVG.ts` and
    `tool/parseXML.ts` from phase 3 to phase 8. The move changes no number of the table. Only
    files of phases 8 and 10 import the two files.
- **The `file_names` lint.** very_good_analysis enables `file_names`. The lint accepts lowercase
  names with underscores and dots, for example `echarts.all.dart` and `global.d.dart`. At the
  mapped Dart paths, the lint fails for these files:
  - 442 ECharts source files, for example `data/SeriesData.dart` and `model/globalDefault.dart`
  - 80 zrender source files, for example `core/PathProxy.dart`
  - 14 ECharts spec files and 8 zrender spec files, for example `data/SeriesData_test.dart`
  - the two harness files `utHelper.dart` and `extendExpect.dart`

  Thus 544 source and spec files fail the lint, 546 with the two harness files.
- **Directory and hyphen names.** Seven directories are not snake case: `axisPointer`,
  `dataZoom`, `effectScatter`, `singleAxis`, `themeRiver` and `visualMap` of ECharts, and
  `svg-legacy` of zrender. No lint examines directory names. These file names have a hyphen:
  `i18n/langPT-br.ts`, `i18n/langnb-NO.ts`, `test/ut/spec/series/aria-columns-exclude.test.ts`
  and zrender `svg-legacy/svg-legacy.ts`.
- **Namespace imports.** 228 source files have an `import * as` line. 181 of them use a
  camelCase prefix. `zrUtil` occurs in 129 files, with 752 uses of `zrUtil.`. The lint
  `library_prefixes` of very_good_analysis flags a camelCase prefix.
- **Default exports.** The two trees have 348 `export default` lines:
  - 27 `export default class X` and 56 `export default function x`
  - 235 `export default X;` of an earlier declaration, for example `coord/cartesian/Axis2D.ts:135`
  - 30 object literals: 24 locales of `src/i18n/`, `coord/axisDefault.ts:234`,
    `coord/geo/geoSourceManager.ts:49`, `chart/treemap/treemapLayout.ts:85`,
    `chart/treemap/treemapVisual.ts:44`, `model/globalDefault.ts:34` and `echarts.ts:32`.
    Their importers use the base name of the file, for example
    `import axisDefault from './axisDefault';`.

  `src/echarts.ts:32-41` is a legacy default export. Its `init` logs an error under `__DEV__` and
  calls `init` of `core/echarts.ts`.
- **Re-exports.** 11 `export * from` lines exist. The entry files, `export/core.ts:22-23`,
  `export/all.ts:24-25` and zrender `src/all.ts:1-2` have them. `export/api.ts:31-54` has 11
  `export * as <name> from` lines, for example `export * as zrUtil from 'zrender/src/core/util';`.
  Dart has no namespace export.
- **The install pattern.** `src/extension.ts:47` keeps a list of installed extensions. `use`
  (`:101-122`) takes an installer, an `{install}` object or an array. It skips an installed
  extension by identity (`:112`). Then it calls `install(extensionRegisters)`. The installers are
  these files:
  - 22 `chart/<type>/install.ts` files and `chart/bar/installPictorialBar.ts`
  - 36 `component/<name>/install*.ts` files, for example `component/dataZoom/installCommon.ts`
  - `label/installLabelLayout.ts`, `renderer/installCanvasRenderer.ts` and
    `renderer/installSVGRenderer.ts`
- **Import side effects.** Five files call `use` at the top level:
  - `echarts.ts:28` and `:46` (2 calls)
  - `echarts.all.ts:109-374` (36 calls)
  - `echarts.common.ts:49-76` (5 calls) and `echarts.simple.ts:34-42` (3 calls)
  - `export/core.ts:29` (1 call)

  `echarts.blank.ts:20` only re-exports `echarts.ts`. 56 legacy shims hold one `use(install)`
  each: 23 `chart/<type>.ts` and 33 `component/<name>.ts` files, for example
  `chart/line.ts:20-23`. No file of `src/` imports a shim. Other files have 82 more top-level
  calls in 41 files. Examples are `registerVisual` and `registerTheme` at
  `core/echarts.ts:3359-3427`, `registerShape` at `util/graphic.ts:952-961`, `registerLocale` at
  `core/locale.ts:80-81` and `mixin` at `model/Model.ts:254-257`. zrender
  `canvas/canvas.ts:4` calls `registerPainter`.
- **Private members in the harness.** `test/ut/core/utHelper.ts:147-150` reads
  `chart['_chartsMap']`, `chart['_componentsMap']` and `component.__viewId`.
  `core/echarts.ts:482` and `:486` declare the two maps `private`. `model/Component.ts:140`
  declares `__viewId`. `test/ut/spec/model/Global.test.ts:57` reads the private
  `_componentsMap` of `GlobalModel` (`model/Global.ts:166`). `:62` reads `chart._chartsMap`.
- **Members across files.** A `_` member often crosses files. zrender `Element.ts:533` declares
  `protected _init`. `Displayable.ts:219` and `Path.ts:209` override it. `Storage.ts:146-154`
  reads and writes `__dirty` of `Element.ts:409`. `Element.ts:1509` also declares a method
  `dirty()`.
- **Names that Dart already has.** `Pattern` (zrender `graphic/Pattern.ts:49`), `Point`
  (`core/Point.ts:7`) and `Symbol` (ECharts `chart/helper/Symbol.ts:46`) are class names of
  `dart:core` or `dart:math`. `Record` is an interface of `component/axisPointer/globalListener.ts:36`.
- **Test files.** ECharts `test/ut/` has `core/utHelper.ts` (156 lines), `core/extendExpect.ts`
  (69 lines), `core/setup.ts` (only `export {}`), `index.d.ts`, `jest.config.cjs`,
  `tsconfig.json`, `.eslintrc.yaml` and 24 specs. zrender `test/ut/` has `extendExpect.ts` (only
  `expect.extend({})`), `jest.config.js`, `tsconfig.json`, the helper `spec/zrender.ts` and 12
  specs. The helper re-exports `src/export` and `src/zrender`.

## Decision

### 1. Paths

Dart paths are relative to `packages/flutter_echarts_port`. The `targets` of
`tool/port_sources.yaml` hold the map ([ECharts ADR 0001](0001-upstream-sources.md)).

| Upstream | Dart |
|---|---|
| ECharts `src/<path>.ts` | `lib/src/echarts/<path>.dart` |
| zrender `src/<path>.ts` | `lib/src/zrender/<path>.dart` |
| ECharts `test/ut/spec/<path>.test.ts` | `test/specs/echarts/<path>_test.dart` |
| zrender `test/ut/spec/<path>.test.ts` | `test/specs/zrender/<path>_test.dart` |
| zrender `test/ut/spec/zrender.ts` (a helper) | `test/specs/zrender/zrender.dart` (a library, not a test) |
| ECharts `test/ut/core/utHelper.ts` | `test/support/echarts/utHelper.dart` (a file target) |
| ECharts `test/ut/core/extendExpect.ts` | `test/support/echarts/extendExpect.dart` (a file target) |
| ECharts `import ... from 'zrender/src/<path>'` | `import 'package:flutter_echarts_port/src/zrender/<path>.dart'` |

- The map from a pinned file to its Dart file is one prefix substitution for each repository.
  `third_party/echarts/src/` becomes `lib/src/echarts/`. `third_party/zrender/src/` becomes
  `lib/src/zrender/`. The bump diffs, the headers and the Dart paths name the same folders.
- File and directory names keep the upstream spelling, the case, the dots and the hyphens, as in
  Chart.js ADR 0012. Examples are `lib/src/echarts/data/SeriesData.dart`,
  `lib/src/echarts/echarts.all.dart`, `lib/src/echarts/i18n/langPT-br.dart` and
  `lib/src/zrender/svg-legacy/`.
- No two Dart paths of the pins are equal, also with the case ignored. Each `global.d.ts` has its
  own tree.
- A relative import goes to the mapped Dart file. A bare `zrender/src/<path>` import goes to
  `package:flutter_echarts_port/src/zrender/<path>.dart`. All imports in `lib/` are package
  imports, as the lint `always_use_package_imports` asks.
- The scaffold `port_sources.yaml` maps only the two `src/` folders and the two `test/ut/spec/`
  folders. The change that ports the first harness file adds its file target. Phase 1 adds the
  target of `extendExpect.ts`. Phase 5 adds the target of `utHelper.ts`. A file target applies
  before a directory target.
- These upstream test files get no port and the status `n/a` with a reason:
  - ECharts `test/ut/core/setup.ts` (an empty module) and `test/ut/index.d.ts` (types only)
  - zrender `test/ut/extendExpect.ts` (an empty `expect.extend({})`)
  - the jest configs `jest.config.cjs` and `jest.config.js`, both `tsconfig.json` files and
    `.eslintrc.yaml` (configuration of the upstream tools)

### 2. The header block and the ignore line

The header block of a ported file has this order
([ECharts ADR 0001](0001-upstream-sources.md)):
1. Line 1: the `// Ported from` line.
2. Zero or more backport lines.
3. The ignore line `// ignore_for_file: <diagnostics>`, when the file needs one.
4. The upstream license comment block, verbatim, when the upstream file has one.
5. Then `library;`, the imports and the code.

The ignore line names the diagnostics in this order:
- `file_names`, when the file name fails the lint. At the pins, 546 Dart files need it: 442
  ECharts and 80 zrender source files, 14 ECharts and 8 zrender spec files, and the two harness
  files of section 1.
- `library_prefixes`, when the file keeps a camelCase import prefix of section 3. At the pins,
  181 source files have such a prefix. A ported spec with such a prefix needs it too.

An example is `// ignore_for_file: file_names, library_prefixes` in
`lib/src/echarts/data/SeriesData.dart`. The header line directly above the ignore line
satisfies the lint `document_ignores`. In a test file with `@TestOn('vm')`, the annotation comes
after the ignore line.

Tool 2 applies the test of each lint to each Dart file. It fails when a file needs a diagnostic
that its ignore line does not name. It also fails when the ignore line names a diagnostic that
the file does not produce. The lint `unnecessary_ignore` reports the second case too.

### 3. Identifiers

- Identifiers are Dart-cased, as in Chart.js ADR 0012. Classes keep their UpperCamelCase names.
  Constants use lowerCamelCase, for example `DARK_MODE_THRESHOLD` becomes `darkModeThreshold`
  (zrender `src/config.ts:28`). The `///` line of a renamed declaration keeps the upstream name.
- An `export default` becomes a named top-level declaration:
  1. `export default class X` and `export default function x` keep the name of the declaration.
  2. `export default X;` keeps the name `X` of the earlier declaration.
  3. An object literal takes the base name of its file, as its importers do. Examples are
     `axisDefault` and `langEN`. A hyphen of the base name goes away: `langPTbr` and `langnbNO`
     ([ECharts ADR 0008](0008-dates-locales-and-formatting.md)).
- The legacy default export of `src/echarts.ts:32-41` gets no port. The `export *` of that file
  already gives `init`. The status of `echarts.ts` lists the symbol as `n/a`.
- `import * as zrUtil from 'zrender/src/core/util';` becomes
  `import 'package:flutter_echarts_port/src/zrender/core/util.dart' as zrUtil;`. Each namespace
  import keeps its upstream prefix. Thus each line `zrUtil.each(...)` stays as upstream writes it.
  The file names `library_prefixes` in its ignore line (section 2).
- A named import without `as` becomes a Dart import without a prefix. If two imported names
  clash in Dart, the file imports one library with a prefix. The `///` line of the import names
  the reason.
- `export * from './x';` becomes `export 'package:flutter_echarts_port/src/echarts/x.dart';`.
  `export {a, b} from './x';` becomes an `export` with `show a, b`. A renamed specifier `x as y`
  takes the forms of D3 ADR 0002 section 6: a `const` for a function, a getter for a variable and
  a `typedef` for a class.
- The 11 `export * as <name>` lines of `export/api.ts:31-54` have no Dart form yet. The change
  that ports `export/api.ts` (phase 6) decides their form with the public library of section 6.
- A class name that `dart:core` or `dart:math` also declares keeps its name: `Pattern`, `Point`
  and `Symbol`. A library declaration shadows the `dart:core` name. A ported file imports
  `dart:math` as `math`. A file that needs the `dart:core` type imports `dart:core` with a prefix.
- Lib code of the two mapped trees imports no `dart:ui` and no Flutter library (section 5). Thus
  names such as `Path`, `Image`, `Text`, `Element` and `Animation` do not clash there.

### 4. Underscore members

These rules adapt Chart.js ADR 0012 and Chart.js ADR 0023:
- A member whose name starts with `_` or `__` keeps its name when only its own file reads,
  writes, calls or overrides it.
- When another file or a spec reads, writes, calls or overrides the member, the Dart name drops
  the leading underscores. The member carries `@internal` from `package:meta`. Examples:
  - `_chartsMap` and `_componentsMap` of `core/echarts.ts:482`, `:486` become `chartsMap` and
    `componentsMap`. `utHelper.ts:147-150` and `Global.test.ts:57`, `:62` read them.
  - `__viewId` of `model/Component.ts:140` becomes `viewId`.
  - `_init` of zrender `Element.ts:533` becomes `init`. `Displayable.ts:219` and `Path.ts:209`
    override it. A Dart library-private member cannot have an override in another library.
- If the class or a superclass has a member with the name without the underscores, the Dart name
  gets one underscore at its end instead. For example, `__dirty` of `Element.ts:409` becomes
  `dirty_`, because `Element.ts:1509` declares `dirty()`.
- The TS modifiers `private` and `protected` have no Dart form. The rules of this section alone
  give the Dart name.
- The `///` line of the member keeps the upstream name. For a trailing underscore, it also gives
  the reason.
- An ad hoc property that code writes on an object of another class follows
  [ECharts ADR 0004](0004-js-values-classes-and-options.md), not this section.

### 5. Port-only code and the pure trees

- All of `lib/src/echarts/` and `lib/src/zrender/` is pure. No file there imports `dart:ui` or
  `package:flutter`, also not through its indirect imports. Tool 1 has both folders as pure roots
  in the ECharts config of [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md).
- Port-only code lives outside the two mapped trees. These are the port-only locations of `lib/`:

  | Path | Content | Pure |
  |---|---|---|
  | `lib/src/js/` | the runtime that only ECharts uses. The generic runtime goes to `js_semantics` (ADR 0008) | yes |
  | `lib/src/platform/` | the Flutter layer: `EChartsHost`, the handler proxy, the platform API implementation and the image loader. Also the pure stand-ins `EChartsContainer` and `ZrViewport` | per file |
  | `lib/src/theme/` | the map from a Flutter theme to an ECharts theme object ([ECharts ADR 0009](0009-dom-features-app-hooks-and-theming.md)). Ported files never import it | yes |
  | `lib/src/canvas/` | only in the fallback of [ECharts ADR 0006](0006-renderer-and-canvas-layer.md) | per file |
  | `lib/src/dev.dart` | `bool echartsDev`, the run-time switch for `__DEV__` ([ECharts ADR 0004](0004-js-values-classes-and-options.md)) | yes |
  | `lib/src/upstream.dart` | `echartsVersion` and `zrenderVersion` | yes |

- Port-only names:
  - `EChartsContainer`: the pure stand-in for the `HTMLElement dom` of `init`
    ([ECharts ADR 0007](0007-environment-host-and-input-events.md)).
  - `ZrViewport`: the pure root of the layer canvases, in place of the `div` of the painter
    ([ECharts ADR 0006](0006-renderer-and-canvas-layer.md)).
  - `EChartsHost`: the internal Flutter host of a chart (ECharts ADR 0007).
  - `useAll()`: the port of the import side effects of `src/echarts.all.ts` (section 8). It is in
    the ported file `lib/src/echarts/echarts.all.dart`, not in a port-only file.
  - `echartsDev`: the Dart form of `__DEV__`.
- A port-only file starts with `// Original code, not ported from Apache ECharts: <reason>.`
  A port-only file of the zrender side uses the same marker.
- A port-only file never sits at the mapped path of a pinned source. A replaced upstream file
  keeps its mapped path free. Its replacement is in `lib/src/platform/`. An example is zrender
  `dom/HandlerProxy.ts` with the status `replaced`.

### 6. Public library

- `lib/flutter_echarts_port.dart` is the public library of phase 0. It exports only
  `lib/src/upstream.dart`.
- From phase 6, it exports the export set of `src/echarts.ts`: the exports of `export/core.ts`
  and the default installs of section 8. Phase 6 ports `src/echarts.ts`, `export/core.ts` and
  `export/api.ts`.
- Phase 10 decides the Flutter API: the widget, its controller and the use functions of
  section 8. It also decides if a separate pure library exports the chart core for `dart test`
  users.
- The package does not export `lib/src/`. Thus the `@internal` members of section 4 stay inside
  the package.

### 7. Type-only files

- A type-only file gets the status `distributed` when the port mirrors its declarations as Dart
  types. The mirror is in the mapped Dart file or in the files that use the types. The 7 interface files of
  the Context item **Type-only files** can take this status. A file gets `n/a: types only` when
  the value map of [ECharts ADR 0004](0004-js-values-classes-and-options.md) gives all its types
  a raw JS value. The phase of the first importer decides the status.
- These three files get `n/a`:
  - ECharts `src/global.d.ts`: `n/a: __DEV__ is echartsDev`.
  - zrender `src/global.d.ts`: `n/a: the type of process.env.NODE_ENV`. ECharts ADR 0004 gives
    the Dart form of the `NODE_ENV` checks.
  - `coord/cartesian/defaultAxisExtentFromData.ts`: `n/a: all code in comments, @obsolete`.
- A TS type alias or an option interface that the value map of ECharts ADR 0004 gives a raw JS
  value needs no Dart declaration. Examples are `Dictionary<T>` (a `Map<String, Object?>`),
  `NullUndefined` (Dart `null`) and the option interfaces of `util/types.ts`.
- A type predicate such as `value is GradientObject` becomes a `bool` function. Its interface
  needs no Dart declaration until a ported caller reads a member through the type.

### 8. Import side effects

Dart runs no code at import. ECharts relies on the code that an import runs. The port translates
these statements as follows. The row `adapt-module-side-effects` of
[differences.md](../differences.md) records the difference. The first ported file with such a
statement adds the row.

1. **Top-level `use` calls.** Each of the five entry files gets one idempotent function:

   | Upstream | Dart function |
   |---|---|
   | `src/echarts.all.ts` | `useAll()` |
   | `src/echarts.common.ts` | `useCommon()` |
   | `src/echarts.simple.ts` | `useSimple()` |
   | `src/echarts.ts` | `useEcharts()` |
   | `src/export/core.ts` | `useCore()` |

   - The name is `use` and the UpperCamelCase form of the last dot part of the base name.
   - The function first calls the functions of the entry files that the file imports, in import
     order. Then it runs its own `use` calls in source order. For example, `useEcharts()` calls
     `useCore()`, then the calls of `echarts.ts:28` and `:46`.
   - The function is idempotent, because `use` skips an installed extension
     (`extension.ts:112`). A Dart tear-off of a top-level function is a canonical constant.
     Thus the identity test of `use` works for the installers.
   - `src/extension.ts:128` declares a `useSimple` with `declare` and no body. No other file names
     it. Thus it has no run-time value. The Dart port of `extension.ts` declares no `useSimple`.
     The two names do not clash.
   - `echarts.blank.ts` has no `use` call of its own. Its Dart file only re-exports
     `echarts.dart`.
2. **Legacy shims.** The 56 files `chart/<type>.ts` and `component/<name>.ts` get the status
   `n/a: import side-effect shim`. An app calls `use` with the installer, as the shim does.
3. **Other top-level statements.** The 82 other top-level calls in 41 files take one of two forms:
   - A statement of the class system follows
     [ECharts ADR 0004](0004-js-values-classes-and-options.md). These are `enableClassExtend`,
     `enableClassCheck`, `enableClassManagement`, `mountExtend`, `mixin` and `registerClass`.
   - Any other statement moves into a private idempotent function of its file. Each exported
     member of the file that reads the state of these statements calls this function first. The
     function runs the statements once, in source order. Its `///` line cites the upstream lines.
     Examples are the registrations of `core/echarts.ts:3359-3427` and `util/graphic.ts:952-961`.
   - A port-only test pins the result of the statements of each such file. An example is the
     theme list after `init`.

### 9. Forward types

- A class that an earlier phase names as a type is ported at its mapped path in that earlier
  phase. Its file gets the status `partial: <symbols>`. The symbols are the declaration and the
  members that the ported callers need.
- The partial file translates these symbols from the pin. It has the full header block of section
  2. It has no port-only stand-in member. A superclass of a partial class is partial too, with
  the members that the subclass needs.
- The phase of the file in the roadmap ports the rest of the file. Then the status becomes
  `ported`.
- The port has no port-only types folder. ECharts and zrender declare their types in the source
  files. Thus the mapped file is the place of each type.
- Section 7 removes most edges. A type alias, an option interface and a predicate type need no
  Dart declaration. Thus the 4 edges of phase 1 need no partial file. The rule first applies in
  phase 2, to its class targets, for example `SeriesData`, `SeriesModel`, `GlobalModel`, `Model`
  and zrender `Element`.
- Tool 8 reads `partial: <symbols>` from the status column. It does not count a partial file as
  ported.

### 10. Test folders

| Content | Dart path |
|---|---|
| Ported ECharts specs | `test/specs/echarts/<path>_test.dart` |
| Ported zrender specs | `test/specs/zrender/<path>_test.dart` |
| The zrender spec helper | `test/specs/zrender/zrender.dart` |
| Ported ECharts harness files | `test/support/echarts/utHelper.dart`, `test/support/echarts/extendExpect.dart` |
| The port-only jest `expect` stand-in | `test/support/jest_expect.dart` |
| The port-only spec set-up `setUpSpecs()` | `test/support/spec_setup.dart` |
| Port-only tests of `lib/src/<path>.dart` | `test/port/<path>_test.dart`, for example `test/port/echarts/util/number_test.dart` and `test/port/zrender/core/PathProxy_test.dart` |
| Port-only tests of `test/support/` | `test/port/support/` |
| The visual smoke runner (from phase 6) | `test/fixtures/` ([ECharts ADR 0005](0005-spec-harness-and-reference-tests.md)) |
| The reference generators | `tool/reference/` |

- Each test file has the header of AGENTS.md rule 2. A file under `test/port/` or
  `test/support/` is port-only, except the two ported harness files.
- A port-only test keeps the upstream spelling of the file that it tests. Thus it follows the
  ignore-line rule of section 2.
- The harness stays in `test/support/`. The name `echarts_test_utils` stays reserved
  ([ECharts ADR 0005](0005-spec-harness-and-reference-tests.md)).

## Alternatives considered

- **snake_case file names** (`SeriesData.ts` to `series_data.dart`). Rejected. The side-by-side
  review of a bump gets harder for 546 files. The map is not always invertible. The hyphens of
  `langPT-br.ts` and `svg-legacy/` need more rules.
- **One `lib/src/` tree for both repositories.** Rejected. Both `src/` trees have `animation/`,
  `core/` and `global.d.ts`. Tool 2 then needs a lookup for each file in place of a prefix. The
  bump of one repository then touches folders of the other.
- **A port-only types folder** (Chart.js ADR 0003 and Chart.js ADR 0028). Rejected. Chart.js keeps
  its types in `src/types/` apart from the classes. ECharts and zrender declare them in the
  source files. A types folder doubles each declaration. The upstream file and the Dart file then
  differ for each forward type.
- **Merge phases 2 and 4** (135 files, 45,598 lines). Rejected. The merged phase is too large for
  one review. It removes only the 74 edges from phase 2 to phase 4. 58 edges of phase 2 and the 30
  edges of phase 4 still point to phases 3 and 5 to 10.
- **`file_names` off for the package** (a package `analysis_options.yaml`). Rejected. Port-only
  files then also escape the lint. The ignore line marks exactly the files whose upstream name
  fails. The same reason rejects `library_prefixes` off for the package.
- **snake_case import prefixes** (`zr_util`). Rejected. 752 uses of `zrUtil.` and many other
  prefixed calls then differ from upstream.
- **A Dart `part` file for each upstream file.** Rejected. A part file shares the privacy of its
  library. The import graph then has one library for many upstream files. Tool 1 and tool 8 work
  on libraries.
- **Run the side effects at the first use of the package** (one global initializer). Rejected.
  Dart has no hook at import. An app can import `echarts.dart` without `echarts.all.dart`, as
  upstream allows. A global initializer then installs too much.

## Consequences

- The map from an upstream path to a Dart path is mechanical. Tool 2 compares each Dart path with
  the mapped path. Its ECharts config of ADR 0008 stage 1 holds the two prefixes, the file targets
  of section 1 and the two diagnostics of the ignore line.
- 546 Dart files carry `file_names` in the ignore line. 181 source files carry
  `library_prefixes`. A change of these lints needs a new ADR that supersedes this ADR. A lint on
  directory names needs one too.
- Section 4 needs `meta` as a dependency of `flutter_echarts_port`. The first change that adds
  `@internal` adds it. If the root `pubspec.lock` changes, that change follows the deferred-plan
  rule ([porting-flow.md](../porting-flow.md)).
- An `@internal` member is not public API. Code outside the package that reads it gets the
  analyzer warning `invalid_use_of_internal_member`.
- Phase 5 adds `lib/src/echarts/echarts.all.dart` with the status `partial: useAll`, because
  `createChart` of `utHelper.dart` calls `useAll()`. Each later phase adds the `use` calls of the
  installers that it ports, in upstream order. Phase 10 completes the file.
- The row `adapt-module-side-effects` lists each Dart file with a function of section 8.
- Each phase from 2 to 7 has partial files. The status column of [parity.md](../parity.md) lists
  their symbols.
- Tool 8 orders files, not folders, because directories are not layers. The value graph has no
  cycle. Thus a file order exists.
- Risk: the spec `series/aria-columns-exclude_test.dart` has hyphens. No probe ran `flutter test`
  on Windows or dart2wasm with such a name (D3 porting-flow risk 9). The D3 phase 1 probe covers
  the hyphen. If ECharts phase 1 comes first, it runs that probe with an empty test at this path.
  If the probe fails, a new ECharts ADR gives the character a replacement.

## Evidence

The counts come from scripts of the research of 2026-10-21. The scripts read the submodules at
the pins of ECharts ADR 0001. They ran no upstream code.
- **Files and lines.** `git ls-files src` with the suffix `.ts`, and `wc -l`, in each submodule.
- **Import graph.** The tool `module_graph.mjs` of the module notes parsed each file of both
  `src/` trees. It used the parser of TypeScript 5.9.3 with no type check. It ran under Node.js
  v24.12.0 (arm64). These counts are not reference values. The tool records `import`,
  `import type`, `export ... from`, `export * from`, `import('x').T` type nodes and side-effect
  imports. It resolves relative paths and `zrender/src/...`. An edge is a value edge when at least
  one imported binding is in a value position. A side-effect import and `export * from` are value
  edges. An edge to a type-only file is a type edge. The phase sets are the value closures of the
  phase roots without the files of earlier phases. No value edge goes from a phase to a later
  phase.
- **File names.** A probe package had an empty Dart file at the mapped path of each source file,
  each spec file and the two harness files. `dart analyze` with only the `file_names` rule (Dart
  3.12.2) gave 546 infos: 442 ECharts and 80 zrender sources, 14 ECharts and 8 zrender specs, and
  2 harness files. The lint accepts the four entry names `echarts.all`, `echarts.common`,
  `echarts.simple` and `echarts.blank`, and both `global.d` names. A count with the pattern
  `^[a-z_][a-z0-9_]*$` rejects the dots. It gives 446 ECharts sources and 548 files in total,
  without the two harness files. With them, it gives 550 files.
- **Lints of very_good_analysis 10.3.0.** A second probe package had `import ... as zrUtil;`. The
  lint `library_prefixes` reported the prefix. The line
  `// ignore_for_file: file_names, library_prefixes` below a header line gave no issue. A class
  `Pattern` in a probe library and a second library that used it gave no issue.
- **Scans.** `grep` counts at the pins: top-level `use(` lines, `install*.ts` files, the shims
  `src/chart/*.ts` and `src/component/*.ts`, `export default` forms, `export * from`,
  `export * as`, `import * as` prefixes, other column-0 calls (without two template-string lines
  of `model/Global.ts:149` and `:430`) and `process.env`.
- **Path collisions.** `comm` of the two `git ls-files src` lists gave only `global.d.ts` and
  `.eslintrc.yaml` as common files, and `animation/` and `core/` as common folders.
