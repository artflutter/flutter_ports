# D3 ADR 0019: Native forms of d3-quadtree

- Status: accepted (2026-11-27): its code and the tests of section Tests pass.
- Date: 2026-11-27
- Related: [D3 ADR 0007](0007-native-dart-forms.md), [D3 ADR 0008](0008-module-packages.md), [D3 ADR 0009](0009-native-spec-harness.md), [D3 ADR 0010](0010-native-values-and-factories.md), [D3 ADR 0017](0017-array-native-forms.md), [ADR 0011](../../../../docs/adr/0011-public-library-exports-every-file.md)

## Context

`d3-quadtree` 3.0.1 implements two-dimensional recursive spatial subdivision for nearest-neighbor
lookup, range queries, collision detection, and Barnes–Hut force approximation (`d3-force`):

- Factory & container: `quadtree([data[, x, y]])`, `Quadtree`
- Accessors & extent: `x`, `y`, `extent`, `cover`
- Mutation & cloning: `add`, `addAll`, `remove`, `removeAll`, `copy`
- Inspection & traversal: `root`, `data`, `size`, `find`, `visit`, `visitAfter`
- Node representation: 4-element sparse arrays for internal nodes (`node.length === 4`) and
  `{data, next}` objects for leaf nodes (`!node.length`).

Upstream JavaScript relies on untyped arrays/objects for nodes, dual getter/setter functions
dispatching on `arguments.length`, `+x` unary numeric coercion, and untyped `[x, y]` array
indexing in default `x`/`y` accessors.

Following [D3 ADR 0007](0007-native-dart-forms.md) (zero JS runtime),
[D3 ADR 0008](0008-module-packages.md) (one package per D3 module),
[D3 ADR 0009](0009-native-spec-harness.md) (native `package:test` specs and Node.js reference
tests), and [D3 ADR 0010](0010-native-values-and-factories.md) (typed native parameters),
`d3-quadtree` 3.0.1 is ported as a standalone pure-Dart package `flutter_d3_quadtree_port` with
**zero `dynamic`, zero `Object?` escape hatches where generics apply, zero JS runtime, and zero
Flutter dependency**.

## Decision

1. **Pure Dart package (`d3_quadtree.dart` + `flutter_d3_quadtree_port.dart`).**
   `package:flutter_d3_quadtree_port/d3_quadtree.dart` exports every pure library in `lib/src/`
   without `show`/`hide` combinators (ADR 0011), and
   `package:flutter_d3_quadtree_port/flutter_d3_quadtree_port.dart` re-exports `d3_quadtree.dart`.
   All 15 upstream `src/*.js` files map 1:1 to `lib/src/*.dart`, with the 12 prototype-method
   files (`add.dart`, `cover.dart`, `data.dart`, `extent.dart`, `find.dart`, `remove.dart`,
   `root.dart`, `size.dart`, `visit.dart`, `visitAfter.dart`, `x.dart`, `y.dart`) declared as
   `part of 'quadtree.dart'` so `Quadtree<T>` exposes real instance methods while keeping internal
   fields private.

2. **Sealed typed node hierarchy (`QuadtreeNode<T>`).**
   - `sealed class QuadtreeNode<T>` enables exhaustive Dart 3 `switch` pattern matching without
     JS `node.length` sniffing.
   - `final class QuadtreeInternalNode<T> extends QuadtreeNode<T>` stores four concrete nullable
     quadrant fields `nw` (index `0`, top-left), `ne` (index `1`, top-right), `sw` (index `2`,
     bottom-left), and `se` (index `3`, bottom-right), avoiding a second `List` heap allocation
     per internal node. It also provides typed `operator [](int index)` and
     `operator []=(int index, QuadtreeNode<T>? node)` for `0..3` indexed access.
   - `final class QuadtreeLeafNode<T> extends QuadtreeNode<T>` stores `final T data` and
     `QuadtreeLeafNode<T>? next` forming a typed singly linked list for coincident points.

3. **Typed factories and accessors (`quadtree`, `quadtreeBy`, `Quadtree<T>`).**
   - `typedef QuadtreeAccessor<T> = double Function(T datum);`
   - `typedef QuadtreeExtent = ((double, double), (double, double));`
   - `typedef QuadtreeVisitCallback<T> = bool Function(QuadtreeNode<T> node, double x0, double y0, double x1, double y1);`
   - `typedef QuadtreeVisitAfterCallback<T> = void Function(QuadtreeNode<T> node, double x0, double y0, double x1, double y1);`
   - Default point accessors operate on unboxed `(double, double)` records:
     `double defaultQuadtreeX((double, double) d) => d.$1;` and
     `double defaultQuadtreeY((double, double) d) => d.$2;`.
   - `Quadtree<(double, double)> quadtree([Iterable<(double, double)>? data, QuadtreeAccessor<(double, double)>? x, QuadtreeAccessor<(double, double)>? y])`
     creates a quadtree over `(double, double)` point records using default `$1`/`$2` accessors
     when `x`/`y` are omitted.
   - `Quadtree<T> quadtreeBy<T>({required QuadtreeAccessor<T> x, required QuadtreeAccessor<T> y, Iterable<T>? data})`
     and the `Quadtree<T>({required QuadtreeAccessor<T> x, required QuadtreeAccessor<T> y, Iterable<T>? data})`
     constructor create a quadtree for any custom datum type `T` with zero `dynamic` or `Object?`
     escape hatches.

4. **Typed getters, setters, and methods on `Quadtree<T>`.**
   - `QuadtreeAccessor<T> get x` / `set x(QuadtreeAccessor<T> value)` and
     `QuadtreeAccessor<T> get y` / `set y(QuadtreeAccessor<T> value)`.
   - `QuadtreeExtent? get extent` returns `((x0, y0), (x1, y1))` or `null` when no extent has been
     established. `set extent(QuadtreeExtent? value)` and chainable
     `Quadtree<T> setExtent(QuadtreeExtent extent)` expand the tree via
     `cover(x0, y0).cover(x1, y1)`.
   - `Quadtree<T> cover(double x, double y)` uses `floorToDouble()` (safe for huge coordinates
     such as `1e23`) and skips internal node wrapping when `root` is `null` or a leaf.
   - `Quadtree<T> add(T datum)` and `Quadtree<T> addAll(Iterable<T> data)`.
   - `Quadtree<T> remove(T datum)` and `Quadtree<T> removeAll(Iterable<T> data)` compare data
     with Dart `==` (identity for `List` and reference classes; structural equality for records and
     value classes) and collapse superfluous internal parents using `identical`.
   - `Quadtree<T> copy()` deep-copies internal and leaf nodes while sharing `T` data by reference.
   - `QuadtreeNode<T>? get root`, `List<T> data()`, `int size()`.
   - `T? find(double x, double y, [double? radius])` returns the closest datum within `radius`
     (default `double.infinity`), or `null` when none exists.
   - `Quadtree<T> visit(QuadtreeVisitCallback<T> callback)` traverses in pre-order (`nw`, `ne`,
     `sw`, `se`), pruning children when `callback` returns `true`.
   - `Quadtree<T> visitAfter(QuadtreeVisitAfterCallback<T> callback)` traverses in post-order.

5. **Hot-path optimizations across AOT, Wasm, and dart2js.**
   - Concrete 4-field `QuadtreeInternalNode<T>` eliminates per-node 4-element `List` allocations.
   - Iterative traversal in `visit`, `visitAfter`, and `find` uses parallel typed stacks
     (`List<QuadtreeNode<T>?>` + `Float64List` bounds) with re-entrancy-safe scratch buffers on
     `Quadtree<T>`, eliminating `Quad` object allocations on every node visited.
   - `find` skips `null` children before pushing and preserves exact upstream tie-breaking order.
   - `addAll` precomputes coordinates into `Float64List` buffers with a direct monomorphic
     `List<(double, double)>` fast path when using default `$1`/`$2` accessors, avoiding closure
     indirection and iterator overhead.
   - `add`, `remove`, and `find` use an unboxed `(double, double)` fast path when default
     accessors are active.

## Rejected

- Representing internal nodes as `List<QuadtreeNode<T>?>`: incurs two heap allocations per
  internal node, requires runtime length/bounds checks, and prevents exhaustive `sealed` pattern
  matching against `QuadtreeLeafNode<T>`.
- Single untyped `Quadtree<dynamic>` or `Object?` accessors accepting `[x, y]` lists, records,
  and maps via runtime type dispatch: breaks static typing and adds runtime dispatch on hot paths.
- Dual getter/setter methods (`Object? x([accessor])`, `Object? extent([ext])`): forces `Object?`
  return types and manual casts at every call site.
- Requiring `bool?` return from `visit` callbacks: forces nullable return checks when a concise
  `bool` predicate (`true` to prune, `false` to descend) is cleaner and faster.

## Consequences

- All 62 upstream test cases across 13 test files port cleanly with 0 skipped cases, adapting JS
  `[x, y]` tuples to typed `(double, double)` records (and `List<double>` / custom classes where
  reference identity or named fields are tested).
- `d3-force` (phase 6) and interactive Flutter visualizations can build, update, and query
  quadtrees with full static typing and zero JS runtime overhead across VM, AOT, `dart2js`, and
  `dart2wasm`.

## Tests

- `packages/flutter_d3_quadtree_port/test/*_test.dart` (all 13 upstream spec files, 62 cases)
- `packages/flutter_d3_quadtree_port/test/port/visit_after_and_api_test.dart`
- `packages/flutter_d3_quadtree_port/test/port/reference_test.dart`
- `packages/flutter_d3_quadtree_port/test/port/faster_forms_test.dart`
- `packages/flutter_d3_quadtree_port/test/upstream_test.dart`
- `packages/flutter_d3_port/test/port/d3/index_test.dart`
