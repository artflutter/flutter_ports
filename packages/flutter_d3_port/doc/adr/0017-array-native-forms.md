# D3 ADR 0017: Native forms of d3-array

- Status: accepted (2026-11-27): its code and the tests of section Tests pass.
- Date: 2026-11-27
- Related: [D3 ADR 0007](0007-native-dart-forms.md), [D3 ADR 0008](0008-module-packages.md), [D3 ADR 0009](0009-native-spec-harness.md), [D3 ADR 0010](0010-native-values-and-factories.md), [D3 ADR 0015](0015-shape-native-forms.md), [D3 ADR 0016](0016-format-native-forms.md), [ADR 0011](../../../../docs/adr/0011-public-library-exports-every-file.md)

## Context

`d3-array` 3.2.4 provides the core numerical, statistical, searching, binning, grouping,
transformation, blur, ordering, and set-operation utilities used across D3 (`d3-scale`,
`d3-axis`, `d3-contour`, `d3-hierarchy`, `d3-force`, and user data pipelines):

- Statistics & summarization: `min`, `minIndex`, `max`, `maxIndex`, `extent`, `least`,
  `leastIndex`, `greatest`, `greatestIndex`, `scan`, `sum`, `fsum`, `fcumsum`, `Adder`, `cumsum`,
  `mean`, `median`, `medianIndex`, `quantile`, `quantileSorted`, `quantileIndex`, `variance`,
  `deviation`, `mode`, `count`.
- Search & ordering: `ascending`, `descending`, `bisector`, `bisect`, `bisectLeft`, `bisectRight`,
  `bisectCenter`, `quickselect`, `sort`, `rank`.
- Ticks, nice, & ranges: `ticks`, `tickIncrement`, `tickStep`, `nice`, `range`.
- Binning & thresholds: `bin` (and deprecated alias `histogram`), `thresholdSturges`,
  `thresholdScott`, `thresholdFreedmanDiaconis`.
- Grouping & aggregation: `group`, `groups`, `rollup`, `rollups`, `index`, `indexes`, `flatGroup`,
  `flatRollup`, `groupSort`, plus `InternMap`/`InternSet`.
- Blur: `blur`, `blur2`, `blurImage`.
- Transformations & combinators: `cross`, `pairs`, `pair`, `merge`, `permute`, `shuffle`,
  `shuffler`, `transpose`, `zip`, `every`, `some`, `filter`, `map`, `reduce`, `reverse`.
- Set operations: `union`, `intersection`, `difference`, `disjoint`, `subset`, `superset`.

Upstream JavaScript relies heavily on untyped variadic arguments (`group(data, k1, k2, ...)`),
dynamic type-sniffing (`f.length !== 2` to distinguish accessors from comparators, `+value` string
coercion, `Array.isArray`), arrays with expando properties (`bin.x0`, `bin.x1`), and `internmap`
because JavaScript `Date` objects compare by reference in `Map`/`Set`.

Following [D3 ADR 0007](0007-native-dart-forms.md) (zero JS runtime),
[D3 ADR 0008](0008-module-packages.md) (one package per D3 module),
[D3 ADR 0009](0009-native-spec-harness.md) (native `package:test` specs and Node.js reference
tests), and [D3 ADR 0010](0010-native-values-and-factories.md) (typed native parameters),
`d3-array` 3.2.4 is ported as a standalone pure-Dart package `flutter_d3_array_port` with **zero
`dynamic`, zero `Object?` escape hatches where generics apply, zero JS runtime, and zero Flutter
dependency**.

## Decision

1. **Pure Dart package (`d3_array.dart` + `flutter_d3_array_port.dart`).**
   `package:flutter_d3_array_port/d3_array.dart` exports every pure file in `lib/src/` without
   `show`/`hide` combinators (ADR 0011), and
   `package:flutter_d3_array_port/flutter_d3_array_port.dart` re-exports `d3_array.dart`. The
   package has zero runtime dependencies and compiles for the Dart VM, AOT, `dart2js`, and
   `dart2wasm`. Internal helpers (`array.dart`, `constant.dart`, `identity.dart`, `number.dart`)
   use `array*`-prefixed names (`arraySlice`, `arrayConstant`, `arrayIdentity`, `arrayNumber`,
   `arrayNumbers`) so the `flutter_d3_port` bundle re-exports all D3 modules without symbol
   collisions.

2. **Typed comparators & ordering (`ascending`, `descending`, `sort`, `quickselect`, `rank`).**
   - `double ascending<T extends Comparable<Object>>(T? a, T? b)` and
     `double descending<T extends Comparable<Object>>(T? a, T? b)` return `-1.0`, `0.0`, `1.0`, or
     `double.nan` when either operand is `null` or `NaN` (matching JS order semantics rather than
     Dart's `double.compareTo`, which sorts `NaN` above `+Infinity`).
   - `int ascendingDefined<T extends Comparable<Object>>(T? a, T? b)` and
     `int Function(T, T) compareDefined<T>(num Function(T, T))` produce total-order `int`
     comparators compatible with `List.sort`, placing `null` and unorderable (`NaN`) elements last.
   - `sort<T extends Comparable<Object>>(Iterable<T>, [num Function(T, T)?])`,
     `sortNullable<T extends Comparable<Object>>(Iterable<T?>, [num Function(T?, T?)?])`,
     `sortWith<T>(Iterable<T>, num Function(T, T))`, `sortBy<T, K>`, `sortBy2<T, K1, K2>`,
     `sortBy3<T, K1, K2, K3>`, and `sortByAll<T, K>` replace JS's arity-sniffing variadic `sort`.
     Sorting preserves ES2019 stability via index tie-breaking.
   - `quickselect<T extends Comparable<Object>>`, `quickselectNullable<T>`, and
     `quickselectWith<T>` partition lists in-place in expected `O(n)` time using Floyd-Rivest
     selection, with unboxed `Float64List` / `List<double>` fast paths.
   - `rank<T extends Comparable<Object>>`, `rankNullable<T>`, `rankWith<T>`, and `rankBy<T, K>`
     return `Float64List` with `double.nan` for unorderable or `null` values and competition ranks
     for ties.

3. **Typed accessors & statistics (`sum`, `fsum`, `Adder`, `min`/`max`/`extent`, `mean`,
   `variance`, `deviation`, `quantile`, `median`, `mode`, `count`).**
   - Direct numeric functions (`sum`, `fsum`, `cumsum`, `fcumsum`, `mean`, `variance`, `deviation`,
     `count`, `quantile`, `quantileSorted`, `quantileIndex`, `median`, `medianIndex`) take
     `Iterable<num?>` (or `List<num?>` for indexed/sorted variants) with unboxed fast paths for
     `Float64List`, `List<double>`, `List<int>`, and `List<num>`.
   - Accessor variants split cleanly into concise 1-arg `*By` (`num? Function(T)`) and full
     upstream 3-arg `*ByIndexed` (`num? Function(T, int, Iterable<T>)`) — e.g. `sumBy` /
     `sumByIndexed`, `meanBy` / `meanByIndexed`, `quantileBy` / `quantileByIndexed` — avoiding
     `Object?` unions and avoiding `(_, _, _)` noise on common calls.
   - `min`, `max`, `extent`, `minIndex`, `maxIndex` accept `Iterable<T?>` for any
     `T extends Comparable<Object>` (`num`, `double`, `int`, `String`, `DateTime`, custom
     `Comparable`), plus `*By` and `*ByIndexed` variants. `extent` returns a typed `(T, T)?` record
     (`null` when no valid comparable value exists).
   - `least`, `leastIndex`, `greatest`, `greatestIndex`, and deprecated `scan` provide natural-order
     default, `*With` comparator, and `*By` accessor forms without JS `.length === 1` sniffing.
   - `Adder` implements Shewchuk's exact adaptive floating-point summation backed by
     `Float64List(32)` with typed `Adder add(double x)` and `double valueOf()` (plus `double get value`).
   - `cumsum` and `fcumsum` return `Float64List`.

4. **Typed `Bisector<T, X>` & `bisect*`.**
   - `final class Bisector<T, X>` exposes `left(List<T>, X, [int lo, int? hi])`, `right(...)`, and
     `center(...)`.
   - `bisector<T, X extends Comparable<Object>>(X? Function(T) accessor, {double Function(X, X)? delta})`
     constructs an accessor-backed bisector (automatically computing numeric and `DateTime` deltas
     for `center` when `delta` is omitted), while `bisectorCompare<T, X>(num Function(T, X) compare)`
     and `bisectorComparator<T>(num Function(T, T) compare)` construct comparator-backed bisectors.
   - Top-level `bisect`, `bisectRight`, `bisectLeft` accept `List<T?>` for any
     `T extends Comparable<Object>` with specialized fast paths for `Float64List`, `List<double>`,
     and `List<int>`. `bisectCenter` operates on `List<num?>` and `bisectCenterDate` on
     `List<DateTime?>`.

5. **Ticks, `nice`, and `range`.**
   - `ticks(num start, num stop, num count)` returns `List<double>`.
   - `tickIncrement(num start, num stop, num count)` and `tickStep(num start, num stop, num count)`
     return `double`.
   - `nice(num start, num stop, num count)` returns a typed `(double, double)` record.
   - `range(num start, [num? stop, num? step])` returns `List<double>`, interpreting a single
     argument `range(stop)` as `range(0, stop, 1)` matching upstream.

6. **Typed `Bin<T>`, `BinGenerator<T>`, and threshold rules.**
   - `final class Bin<T> extends ListBase<T>` holds `double x0`, `double x1`, and its element list
     with zero expando properties.
   - `final class BinGenerator<T>` is callable (`List<Bin<T>> call(Iterable<T> data)`) with
     cascade-friendly typed properties and `*Const` setters following
     [D3 ADR 0015](0015-shape-native-forms.md): `value` / `valueSimple` / `valueConst`,
     `domain` / `domainConst`, `thresholdsCount` / `thresholdsCountConst`, and
     `thresholdsValues` / `thresholdsValuesConst`.
   - `bin<T extends num?>()` (and deprecated alias `histogram`) creates a numeric bin generator
     defaulting to identity value, `extent` domain, and `thresholdSturges`. `binBy<T>(num? Function(T))`
     and `binByIndexed<T>(num? Function(T, int, List<T>))` create typed object bin generators.
   - `thresholdSturges`, `thresholdScott`, and `thresholdFreedmanDiaconis` take `Iterable<num?>`
     and return `int` (guarding `count == 0` / non-finite spreads cleanly to return `1`).

7. **Strongly typed multi-level grouping, rollup, and indexing (`group*`, `rollup*`, `index*`,
   `flatGroup*`, `flatRollup*`, `groupSort`).**
   - Because Dart's `Map<K, V>` and `Set<T>` already provide value equality for `DateTime`,
     `String`, `num`, records, and value classes, all grouping and set operations return native
     insertion-ordered Dart `Map<K, V>` and `Set<T>` directly.
   - Multi-level nesting uses fixed-arity typed functions with exact nested return types — zero
     untyped `Map<dynamic, dynamic>` or `List<dynamic>`:
     - 1-level: `group<T, K>` (`Map<K, List<T>>`), `groups<T, K>` (`List<(K, List<T>)>`),
       `rollup<T, K, R>` (`Map<K, R>`), `rollups<T, K, R>` (`List<(K, R)>`),
       `index<T, K>` (`Map<K, T>`), `indexes<T, K>` (`List<(K, T)>`),
       `flatGroup<T, K>`, `flatRollup<T, K, R>` (plus `*Indexed` variants for 3-arg key accessors).
     - 2-level: `group2<T, K1, K2>` (`Map<K1, Map<K2, List<T>>>`), `groups2`, `rollup2`,
       `rollups2`, `index2`, `indexes2`, `flatGroup2` (`List<(K1, K2, List<T>)>`),
       `flatRollup2` (`List<(K1, K2, R)>`).
     - 3-level: `group3<T, K1, K2, K3>` (`Map<K1, Map<K2, Map<K3, List<T>>>>`), `groups3`,
       `rollup3`, `rollups3`, `index3`, `indexes3`, `flatGroup3` (`List<(K1, K2, K3, List<T>)>`),
       `flatRollup3` (`List<(K1, K2, K3, R)>`).
   - `groupSort<T, K extends Comparable<Object>, R extends Comparable<Object>>` (reducer-based) and
     `groupSortCompare<T, K extends Comparable<Object>>` (group-comparator-based) return `List<K>`.
   - `InternMap<K, V, I>` and `InternSet<T, I>` provide a typed wrapper for custom key
     canonicalization (`I Function(K) key`) preserving first-inserted keys when native `==` is not
     the desired equivalence relation (e.g. case-insensitive strings or key-projected objects).

8. **Typed 1D, 2D, and RGBA `blur`, `blur2`, and `blurImage`.**
   - `List<double> blur(List<double> values, double r)` blurs in-place and returns `values`.
   - `final class Blur2Data({required List<double> data, required int width, int? height})` and
     `Blur2Data blur2(Blur2Data data, double rx, [double? ry])` blur 2D scalar grids in-place.
   - `final class BlurImageData({required Uint8ClampedList data, required int width, int? height})`
     and `BlurImageData blurImage(BlurImageData data, double rx, [double? ry])` blur 4-channel RGBA
     buffers in-place with JS `Uint8ClampedArray` round-to-even clamping.

9. **Typed transformations, combinators, and set operations.**
   - `cross<A, B>` → `List<(A, B)>`, `crossWith<A, B, R>`, `cross3<A, B, C>` → `List<(A, B, C)>`,
     `cross3With<A, B, C, R>`, `crossAll<T>` → `List<List<T>>`, `crossAllWith<T, R>`.
   - `pair<T>(T a, T b)` → `(T, T)`, `pairs<T>` → `List<(T, T)>`, `pairsWith<T, R>`.
   - `merge<T>(Iterable<Iterable<T>>)` → `List<T>`.
   - `permute<T>(List<T>, Iterable<int>)` → `List<T>` (and `permuteNullable<T>` for out-of-range
     indices, plus `permuteMap<K, V>(Map<K, V>, Iterable<K>)` → `List<V?>`).
   - `shuffle<T>(List<T>, [int i0, int? i1])` and callable generic `Shuffler` returned by
     `shuffler(double Function() random)`.
   - `transpose<T>(List<List<T>>)` → `List<List<T>>`, `zip<T>(List<List<T>>)` → `List<List<T>>`,
     plus typed tuple zips `zip2<A, B>` → `List<(A, B)>` and `zip3<A, B, C>` → `List<(A, B, C)>`.
   - `every`, `some`, `filter`, `map`, `reduce`, `reduceFirst`, `reverse`.
   - `union`, `union2`, `intersection`, `intersection2`, `difference`, `difference2`, `disjoint`,
     `subset`, `superset` returning/operating on native Dart `Set<T>` with `SameValueZero` `NaN`
     handling for `double` sets.

10. **Hot-path optimizations across AOT, Wasm, and dart2js.**
    Numeric statistics (`sum`, `fsum`, `cumsum`, `fcumsum`, `min`, `max`, `extent`, `mean`,
    `variance`, `deviation`, `count`), `quickselect`, `quantile`, `bisect*`, `bin`, `ticks`,
    `blur`/`blur2`/`blurImage`, `sort`, `group`/`rollup`, and `shuffle` specialize directly on
    `Float64List` / `List<double>` / `List<int>` / `List<num>` with tight indexed loops avoiding
    iterator allocation, closure indirection, and per-element boxing.

## Rejected

- Untyped recursive `Map<dynamic, dynamic>` / `List<dynamic>` for multi-level `group`/`rollup`/
  `index`/`flatGroup`/`flatRollup` and `cross`: forfeits static typing and forces unsafe casts at
  every call site.
- Accepting `Object?` with JS string-to-number coercion (`+"42"`) or runtime `.length` arity
  sniffing (`Function` union of accessor and comparator): breaks static type safety and adds
  per-element runtime type dispatch.
- Representing `Bin<T>` as `List<T>` plus external `Expando<double>` for `x0`/`x1`: slow hash
  lookups and poor ergonomics compared to a typed `Bin<T> extends ListBase<T>`.
- Returning `(T?, T?)` with `(null, null)` from `extent`: forces redundant null checks on both
  fields instead of a single null check on `(T, T)?`.

## Consequences

- Upstream spec cases testing JS string/object-to-number coercion (`"1"`, `new OneTimeNumber()`,
  `{valueOf: ...}`), JS `undefined` vs `null` distinction, sparse JS arrays (`[ , 1, , ]`),
  non-iterable `TypeError` checks enforced at compile time by Dart, or JS `InternMap` lookup by
  coerced timestamp `+date` adapt to native Dart types or skip with
  `diverges: adapt-array-typed-api` (recorded in
  `packages/flutter_d3_array_port/doc/differences.md`).
- Downstream D3 modules (`d3-scale`, `d3-axis`, `d3-contour`, `d3-hierarchy`, `d3-force`,
  `d3-quadtree`, `d3-geo`) can depend directly on `flutter_d3_array_port` with full static type
  safety across VM, Flutter, `dart2js`, and `dart2wasm`.

## Tests

- `packages/flutter_d3_array_port/test/*_test.dart` and
  `packages/flutter_d3_array_port/test/threshold/*_test.dart` (all 65 upstream spec files, 530 cases)
- `packages/flutter_d3_array_port/test/port/reference_test.dart`
- `packages/flutter_d3_array_port/test/port/faster_forms_test.dart`
- `packages/flutter_d3_array_port/test/upstream_test.dart`
- `packages/flutter_d3_port/test/port/d3/index_test.dart`
