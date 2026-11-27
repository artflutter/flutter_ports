# D3 ADR 0018: Native forms of d3-hierarchy

- Status: accepted (2026-11-27): its code and the tests of section Tests pass.
- Date: 2026-11-27
- Related: [D3 ADR 0007](0007-native-dart-forms.md), [D3 ADR 0008](0008-module-packages.md), [D3 ADR 0009](0009-native-spec-harness.md), [D3 ADR 0010](0010-native-values-and-factories.md), [D3 ADR 0015](0015-shape-native-forms.md), [D3 ADR 0016](0016-format-native-forms.md), [D3 ADR 0017](0017-array-native-forms.md), [ADR 0011](../../../../docs/adr/0011-public-library-exports-every-file.md)

## Context

`d3-hierarchy` 3.1.2 provides 2D hierarchical data structures and layout algorithms for
visualizing trees, dendrograms, treemaps, sunburst/icicle partitions, and circle packs:

- **Hierarchy construction & traversal:** `hierarchy`, `HierarchyNode` (`ancestors`, `descendants`,
  `leaves`, `find`, `path`, `links`, `sum`, `count`, `sort`, `each`, `eachAfter`, `eachBefore`,
  `copy`, and breadth-first `Iterable` iteration).
- **Tabular stratification:** `stratify` (`id`, `parentId`, and slash-delimited `path` with
  internal-node imputation and escaped-slash handling).
- **Node-link layouts:** `cluster` (dendrogram with aligned leaves) and `tree` (Reingold-Tilford /
  Buchheim et al. tidy tree).
- **Space-filling layouts:** `treemap` with all 6 tiling algorithms (`treemapBinary`,
  `treemapDice`, `treemapSlice`, `treemapSliceDice`, `treemapSquarify`, `treemapResquarify`) and
  `partition` (icicle / sunburst).
- **Enclosure layouts:** `pack` (nested circle packing), `packSiblings` (Wang et al. front-chain
  circle packing), and `packEnclose` (Matoušek-Sharir-Welzl randomized smallest enclosing circle).

Upstream JavaScript relies on mutating layout properties (`x`, `y`, `r`, `x0`, `y0`, `x1`, `y1`,
`_squarify`) directly onto untyped `Node` objects, duck-typing `d.children` / `d.id` /
`d.parentId`, passing plain `{value, children}` objects to tiling functions, accepting
`function | number` union arguments for padding, coercing arbitrary values to strings/numbers, and
imputing `data = null` for missing path ancestors in `stratify().path(...)`.

Following [D3 ADR 0007](0007-native-dart-forms.md) (zero JS runtime),
[D3 ADR 0008](0008-module-packages.md) (one package per D3 module),
[D3 ADR 0009](0009-native-spec-harness.md) (native `package:test` specs and Node.js reference
tests), and [D3 ADR 0010](0010-native-values-and-factories.md) (typed native parameters),
`d3-hierarchy` 3.1.2 is ported as a standalone pure-Dart package `flutter_d3_hierarchy_port` with
**zero `dynamic`, zero `Object?` escape hatches where generics apply, zero JS runtime, and zero
Flutter dependency**.

## Decision

1. **Pure Dart package (`d3_hierarchy.dart` + `flutter_d3_hierarchy_port.dart`).**
   `package:flutter_d3_hierarchy_port/d3_hierarchy.dart` exports every pure file in `lib/src/`
   without `show`/`hide` combinators (ADR 0011), and
   `package:flutter_d3_hierarchy_port/flutter_d3_hierarchy_port.dart` re-exports
   `d3_hierarchy.dart`. The package has zero runtime dependencies and compiles for the Dart VM,
   AOT, `dart2js`, and `dart2wasm`. Internal helpers use `hierarchy*` / `treemap*`-prefixed names
   (`hierarchyOptional`, `hierarchyRequired`, `hierarchyArray`, `hierarchyShuffle`,
   `hierarchyConstant`, `hierarchyConstantZero`, `hierarchyLcg`, `treemapRoundNode`, `treemapPhi`)
   so the `flutter_d3_port` bundle re-exports all D3 modules without symbol collisions.

2. **Typed node hierarchy (`HierarchyNode<T>` and layout node subclasses).**
   - `class HierarchyNode<T> extends Iterable<HierarchyNode<T>>` holds typed fields:
     `T data`, `int depth`, `int height`, `HierarchyNode<T>? parent`,
     `List<HierarchyNode<T>>? children`, `double? value`, and `String? id`.
   - Three typed layout subclasses extend `HierarchyNode<T>` and override `iterator`, `parent`,
     `children`, and every traversal, collection, and link method so call sites preserve the
     concrete layout node type with zero casts:
     - `final class HierarchyRectangularNode<T> extends HierarchyNode<T>` with unboxed
       `double x0, y0, x1, y1` (produced by `TreemapLayout<T>` and `PartitionLayout<T>`).
     - `final class HierarchyCircularNode<T> extends HierarchyNode<T> implements PackCircle` with
       unboxed `double x, y, r` (produced by `PackLayout<T>`).
     - `final class HierarchyPointNode<T> extends HierarchyNode<T>` with unboxed `double x, y`
       (produced by `TreeLayout<T>` and `ClusterLayout<T>`).
   - Reference identity (`Object.==`) is preserved on all `HierarchyNode` instances so ancestor,
     path, and sibling-parent comparisons match upstream semantics.
   - `abstract interface class HierarchyDatum<T>` (`Iterable<T>? get children`) lets user data
     models opt into the default `children` accessor of `hierarchy<T>(data)` without duck typing;
     passing an explicit `Iterable<T>? Function(T d) children` callback works for any type `T`.

3. **Typed traversals, transforms, and links.**
   - `typedef HierarchyLink<T> = ({HierarchyNode<T> source, HierarchyNode<T> target});` plus
     covariant record aliases `HierarchyRectangularLink<T>`, `HierarchyCircularLink<T>`, and
     `HierarchyPointLink<T>` give structural equality, zero-boilerplate destructuring, and
     covariant overrides of `links()` on each layout node subclass.
   - Traversals provide concise 1-arg forms (`each`, `eachBefore`, `eachAfter`, `find`) and
     upstream 3-arg forms (`eachIndexed`, `eachBeforeIndexed`, `eachAfterIndexed`, `findIndexed`
     receiving `(node, index, root)`), avoiding `(_, _)` noise on common calls while preserving
     full upstream behavior.
   - `ancestors()`, `descendants()`, `leaves()`, and `path(target)` return typed `List<Self>`.
   - `sum(num? Function(T d) value)` coerces `null` and `NaN` to `0.0` matching JS `+value(d) || 0`,
     while `count()` counts leaves into `node.value`.
   - `sort(num Function(Self a, Self b) compare)` accepts `int` or `double` comparators and
     preserves ES2019 sort stability across all child counts (Dart's `List.sort` is not guaranteed
     stable for `n > 32`).
   - `copy()` deep-clones the node tree (preserving subclass type, `value`, `id`, and layout
     coordinates).
   - Each `src/hierarchy/*.js` module maps 1:1 to `lib/src/hierarchy/*.dart` exposing its
     standalone `hierarchy*` operation, which `HierarchyNode<T>` delegates to.

4. **Typed `StratifyOperator<T>` and `stratify<T>()` with sound null safety for `path`.**
   - `abstract interface class StratifyDatum` (`String? get id`, `String? get parentId`) supports
     default `id` / `parentId` extraction without duck typing.
   - `final class StratifyOperator<T>` configures `id` / `idIndexed`, `parentId` /
     `parentIdIndexed`, and `path` / `pathIndexed` with cascade-friendly properties and optional
     constructor parameters on `stratify<T>()`.
   - `HierarchyNode<T> call(Iterable<T> data)` returns a non-nullable `HierarchyNode<T>` in
     `id`/`parentId` mode (and in `path` mode when no internal nodes are imputed or when `T` is
     already nullable).
   - `HierarchyNode<T?> callPath(Iterable<T> data)` (and top-level convenience
     `stratifyPath<T>(Iterable<T> data, String Function(T d) path)`) always returns
     `HierarchyNode<T?>` so imputed internal nodes carry `data == null` with full sound null
     safety for any non-nullable `T`.
   - Throws `StateError` with upstream diagnostic messages (`missing: <id>`, `ambiguous: <id>`,
     `multiple roots`, `no root`, `cycle`).

5. **Typed layout classes (`TreemapLayout<T>`, `PartitionLayout<T>`, `PackLayout<T>`,
   `TreeLayout<T>`, `ClusterLayout<T>`).**
   - Each layout is a callable `final class` with typed properties, optional named factory
     parameters, and `*Const` setters for numeric constants (following
     [D3 ADR 0015](0015-shape-native-forms.md) and [D3 ADR 0017](0017-array-native-forms.md)):
     - `TreemapLayout<T>` (`treemap<T>()`): `(double, double) size`, `bool round`,
       `TreemapTile<T> tile`, `padding` / `paddingInner` / `paddingOuter` / `paddingTop` /
       `paddingRight` / `paddingBottom` / `paddingLeft` accessors plus `*Const(double)` setters.
     - `PartitionLayout<T>` (`partition<T>()`): `(double, double) size`, `bool round`,
       `double padding`.
     - `PackLayout<T>` (`pack<T>()`): `(double, double) size`, `PackRadiusAccessor<T>? radius`,
       `PackPaddingAccessor<T> padding` + `paddingConst(double)`.
     - `TreeLayout<T>` (`tree<T>()`): `(double, double)? size`, `(double, double)? nodeSize`,
       `TreeSeparation<T> separation`.
     - `ClusterLayout<T>` (`cluster<T>()`): `(double, double)? size`, `(double, double)? nodeSize`,
       `TreeSeparation<T> separation`.
   - Passing a plain `HierarchyNode<T>` lifts the tree into the layout's typed node subclass;
     passing an instance that is already of that subclass updates coordinates **in-place** (avoiding
     re-allocation and preserving `treemapResquarify` row caches).
   - Immutable `(double, double)` records for `size` and `nodeSize` guarantee defensive-copy
     semantics automatically with zero heap list allocation.

6. **Typed `TreemapTile<T>` callbacks and all 6 tiling algorithms.**
   - `typedef TreemapTile<T> = void Function(HierarchyRectangularNode<T> parent, double x0, double y0, double x1, double y1);`
   - `treemapBinary<T>`, `treemapDice<T>`, `treemapSlice<T>`, `treemapSliceDice<T>` are generic
     top-level functions matching `TreemapTile<T>`.
   - `treemapSquarify` (`const TreemapSquarify(treemapPhi)`) and `treemapResquarify`
     (`const TreemapResquarify(treemapPhi)`) are immutable callable objects with generic
     `void call<T>(...)` and `.ratio(double x)` returning a new instance with `max(1.0, x)`.
   - `treemapResquarify` stores its typed cached row partitions (`TreemapResquarifyCache<T>`)
     directly on `HierarchyRectangularNode<T>` with zero `Expando` overhead.

7. **Typed `PackCircle` for `packSiblings` and `packEnclose`.**
   - `class PackCircle` holds mutable `double x, y, r`.
   - `HierarchyCircularNode<T>` implements `PackCircle`, so `packSiblings<C extends PackCircle>`
     and `packEnclose<C extends PackCircle>` operate directly on both standalone `PackCircle`
     lists and `List<HierarchyCircularNode<T>>` with zero wrapper allocation.

8. **Hot-path optimizations across AOT, Wasm, and dart2js.**
   - Iterative, allocation-light `eachBefore`, `eachAfter`, `sum`, `count`, `descendants`,
     `leaves`, and BFS `each`/`find` avoiding generator (`sync*`) overhead in hot paths.
   - Hash-map indexed `stratify` with `codeUnitAt` path scanning and single-pass linking.
   - Unboxed `Float64List` prefix sums in `treemapBinary`, slice-free index ranges in
     `treemapSquarify`, and direct unboxed coordinate arithmetic across `treemap`/`partition`.
   - Unboxed geometry and allocation-light front-chain in `packSiblings` and `packEnclose`.
   - Flat/unboxed Reingold-Tilford `tree`, `cluster`, and `partition` walks.

## Rejected

- Putting `x, y, r, x0, y0, x1, y1` as nullable fields on a single `HierarchyNode<T>` class: forces
  `!` null-assertions at every rendering call site and lets users accidentally read `x0` on a
  circular pack node.
- F-bounded polymorphism (`HierarchyNode<T, Self extends HierarchyNode<T, Self>>`) in the public
  API: leaks a second type parameter onto every user variable and function signature.
- `Object?` / `dynamic` duck typing for `d.children`, `d.id`, `d.parentId`, or `padding` unions:
  breaks static type safety and adds runtime reflection/type-dispatch overhead.
- `Expando` storage for `treemapResquarify`'s `_squarify` cache: slower than a direct nullable
  field on `HierarchyRectangularNode<T>` and unnecessary when the node class is owned by the port.

## Consequences

- Upstream spec cases testing JS runtime type errors (`stratify.id(42)`, `stratify.parentId("nope")`),
  JS string/object coercion (`treemap.round("yes")`, `treemap.padding("42")`,
  `treemap.size(["6", {valueOf: ...}])`, non-iterable numeric `children: 42`, `{toString()}`
  coercion in `stratify`), or `root instanceof hierarchy` adapt to native Dart types or skip with
  `diverges: adapt-hierarchy-typed-api` (recorded in
  `packages/flutter_d3_hierarchy_port/doc/differences.md`).
- Downstream D3 apps and widgets (`apps/d3_demo`, `flutter_d3_port`) can compose
  `flutter_d3_hierarchy_port` directly with `flutter_d3_shape_port` (`arc`, `linkHorizontal`,
  `linkRadial`) and `flutter_d3_scale_chromatic_port` with full static type safety across VM,
  Flutter, `dart2js`, and `dart2wasm`.

## Tests

- `packages/flutter_d3_hierarchy_port/test/hierarchy/*_test.dart`,
  `packages/flutter_d3_hierarchy_port/test/pack/*_test.dart`,
  `packages/flutter_d3_hierarchy_port/test/treemap/*_test.dart`, and
  `packages/flutter_d3_hierarchy_port/test/stratify_test.dart` (all 18 upstream spec files, 83 cases)
- `packages/flutter_d3_hierarchy_port/test/port/reference_test.dart`
- `packages/flutter_d3_hierarchy_port/test/port/faster_forms_test.dart`
- `packages/flutter_d3_hierarchy_port/test/upstream_test.dart`
- `packages/flutter_d3_port/test/port/d3/index_test.dart`
