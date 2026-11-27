# d3-quadtree port differences

This file lists the hunks of ported code that do not translate the upstream lines. Each hunk
carries the line comment `// DIVERGES(d3-quadtree): <ID>, <reason>`. `check:headers` pairs each
marker with a row of this file. A port-only file is not a row.

The ID starts with its category: `adapt`, `platform`, `js-semantics`, `harness` or `not-followed`,
as in the [D3 port](../../flutter_d3_port/doc/differences.md). The column "Upstream
file@version:lines" names the pin at which the porter last checked the row. Each bump checks every
row.

The port uses no JS runtime ([D3 ADR 0007](../../flutter_d3_port/doc/adr/0007-native-dart-forms.md)).
The rows `adapt-quadtree-*` record the native forms of
[D3 ADR 0019](../../flutter_d3_port/doc/adr/0019-quadtree-native-forms.md).

| ID | Dart file and symbol | Upstream file@version:lines | Category | Reason | Upstream reference | Pinning test | Re-check on bump |
|---|---|---|---|---|---|---|---|
| <a id="adapt-quadtree-typed-api"></a>`adapt-quadtree-typed-api` | `lib/src/*.dart` | d3-quadtree `src/*.js`@v3.0.1 | adapt | Native statically typed Dart APIs with zero `dynamic`, zero `Object?` escape hatches where generics apply, and zero JS runtime ([D3 ADR 0019](../../flutter_d3_port/doc/adr/0019-quadtree-native-forms.md)): generic `Quadtree<T>`, sealed `QuadtreeNode<T>` / `QuadtreeInternalNode<T>` (4 typed `nw`/`ne`/`sw`/`se` slots + `0..3` indexer) / `QuadtreeLeafNode<T>` (`data`, `next`), `quadtree` for `(double, double)` records and `quadtreeBy<T>` for custom types, typed `double Function(T)` `x`/`y` getters & setters, `((double, double), (double, double))?` extent record, `find(double, double, [double?]) -> T?`, and typed `bool`/`void` `visit`/`visitAfter` callbacks. | — | `test/*_test.dart`, `test/port/visit_after_and_api_test.dart`, `test/port/reference_test.dart` | Check signatures and contracts when the pin changes. |
| <a id="adapt-quadtree-fast-forms"></a>`adapt-quadtree-fast-forms` | `lib/src/quadtree.dart`, `lib/src/quad.dart`, `lib/src/add.dart`, `lib/src/cover.dart`, `lib/src/remove.dart`, `lib/src/find.dart`, `lib/src/visit.dart`, `lib/src/visitAfter.dart`, `lib/src/data.dart`, `lib/src/size.dart` | d3-quadtree `src/*.js`@v3.0.1 | adapt | Faster native Dart forms with identical tree topology, traversal order, and query outputs ([performance.md](performance.md)): concrete 4-field `QuadtreeInternalNode<T>` eliminating per-node `List` allocations; iterative pooled mutable `_QuadFrame<T>` stacks in `visit`, `visitAfter` (single O(depth) stack), and `find` with re-entrancy-safe reusable pools eliminating per-step `Quad` allocations; `null`-skipping quadrant push preserving exact upstream tie-breaking in `find`; zero-copy `(double, double)` default-accessor fast paths and `Float64List` custom coordinate batching in `addAll`; leaf-skip wrapper avoidance in `cover`; and direct depth-guarded (fallback at depth 128) `copy`, `data`, and `size`. | — | `test/port/faster_forms_test.dart`, `test/port/reference_test.dart` | Compare upstream algorithms when the pin changes. |
