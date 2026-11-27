# d3-hierarchy port differences

This file lists the hunks of ported code that do not translate the upstream lines. Each hunk
carries the line comment `// DIVERGES(d3-hierarchy): <ID>, <reason>`. `check:headers` pairs each
marker with a row of this file. A port-only file is not a row.

The ID starts with its category: `adapt`, `platform`, `js-semantics`, `harness` or `not-followed`,
as in the [D3 port](../../flutter_d3_port/doc/differences.md). The column "Upstream
file@version:lines" names the pin at which the porter last checked the row. Each bump checks every
row.

The port uses no JS runtime ([D3 ADR 0007](../../flutter_d3_port/doc/adr/0007-native-dart-forms.md)).
The rows `adapt-hierarchy-*` record the native forms of
[D3 ADR 0018](../../flutter_d3_port/doc/adr/0018-hierarchy-native-forms.md).

| ID | Dart file and symbol | Upstream file@version:lines | Category | Reason | Upstream reference | Pinning test | Re-check on bump |
|---|---|---|---|---|---|---|---|
| <a id="adapt-hierarchy-typed-api"></a>`adapt-hierarchy-typed-api` | `lib/src/*.dart`, `lib/src/hierarchy/*.dart`, `lib/src/pack/*.dart`, `lib/src/treemap/*.dart` | d3-hierarchy `src/**/*.js`@v3.1.2 | adapt | Native statically typed Dart APIs with zero `dynamic`, zero `Object?` escape hatches where generics apply, and zero JS runtime ([D3 ADR 0018](../../flutter_d3_port/doc/adr/0018-hierarchy-native-forms.md)): typed `HierarchyNode<T>` and subclasses (`HierarchyRectangularNode<T>`, `HierarchyCircularNode<T>`, `HierarchyPointNode<T>`), typed `HierarchyLink<T>` record aliases, split 1-arg and 3-arg `*Indexed` callbacks, typed `StratifyOperator<T>` with sound null-safe `callPath`/`stratifyPath`, typed layout classes (`TreemapLayout<T>`, `PartitionLayout<T>`, `PackLayout<T>`, `TreeLayout<T>`, `ClusterLayout<T>`), typed `TreemapTile<T>` callbacks and callable `TreemapSquarify`/`TreemapResquarify`, and typed `PackCircle` implemented by `HierarchyCircularNode<T>`. | — | `test/hierarchy/*_test.dart`, `test/pack/*_test.dart`, `test/treemap/*_test.dart`, `test/stratify_test.dart`, `test/port/reference_test.dart` | Check signatures and error contracts when the pin changes. |
| <a id="adapt-hierarchy-fast-forms"></a>`adapt-hierarchy-fast-forms` | `lib/src/hierarchy/*.dart`, `lib/src/stratify.dart`, `lib/src/treemap/*.dart`, `lib/src/pack/*.dart`, `lib/src/tree.dart`, `lib/src/cluster.dart`, `lib/src/partition.dart` | d3-hierarchy `src/**/*.js`@v3.1.2 | adapt | Faster native Dart forms with identical outputs ([performance.md](performance.md)): iterative allocation-light traversals (`eachBefore`, `eachAfter`, `sum`, `count`, `descendants`, `leaves`, BFS `each`/`find`) without `sync*` generator overhead; `codeUnitAt` path parsing and single-pass hash-map indexing in `stratify`; unboxed `Float64List` prefix sums in `treemapBinary` and slice-free index ranges in `treemapSquarify`; direct typed `TreemapResquarifyCache` field on `HierarchyRectangularNode`; unboxed geometry and front-chain in `packSiblings`/`packEnclose`; and allocation-light Reingold-Tilford `tree`, `cluster`, and `partition` walks. | — | `test/port/faster_forms_test.dart`, `test/port/reference_test.dart` | Compare upstream algorithms when the pin changes. |
| <a id="adapt-hierarchy-stable-sort"></a>`adapt-hierarchy-stable-sort` | `lib/src/hierarchy/sort.dart` | d3-hierarchy `src/hierarchy/sort.js`@v3.1.2:1-7 | adapt | Dart's `List.sort` is not guaranteed stable for `n > 32`, whereas JS ES2019 `Array.prototype.sort` is stable. `hierarchySort` / `HierarchyNode.sort` uses a stable sort (insertion sort for small lists, merge sort for larger lists) so sibling tie-breaking matches upstream. | — | `test/treemap/flare_test.dart`, `test/pack/flare_test.dart`, `test/port/faster_forms_test.dart` | Re-check stability requirements when the pin changes. |
