# d3-array port differences

This file lists the hunks of ported code that do not translate the upstream lines. Each hunk
carries the line comment `// DIVERGES(d3-array): <ID>, <reason>`. `check:headers` pairs each marker
with a row of this file. A port-only file is not a row.

The ID starts with its category: `adapt`, `platform`, `js-semantics`, `harness` or `not-followed`,
as in the [D3 port](../../flutter_d3_port/doc/differences.md). The column "Upstream
file@version:lines" names the pin at which the porter last checked the row. Each bump checks every
row.

The port uses no JS runtime ([D3 ADR 0007](../../flutter_d3_port/doc/adr/0007-native-dart-forms.md)).
The rows `adapt-array-*` record the native forms of
[D3 ADR 0017](../../flutter_d3_port/doc/adr/0017-array-native-forms.md).

| ID | Dart file and symbol | Upstream file@version:lines | Category | Reason | Upstream reference | Pinning test | Re-check on bump |
|---|---|---|---|---|---|---|---|
| <a id="adapt-array-typed-api"></a>`adapt-array-typed-api` | `lib/src/*.dart`, `lib/src/threshold/*.dart` | d3-array `src/**/*.js`@v3.2.4 | adapt | Native statically typed Dart APIs with zero `dynamic`, zero `Object?` escape hatches where generics apply, and zero JS runtime ([D3 ADR 0017](../../flutter_d3_port/doc/adr/0017-array-native-forms.md)): typed `<T extends Comparable<Object>>` comparators and extrema, `(T, T)?` records for `extent`/`pairs`/`cross`/`nice`, split `*By` (1-arg) and `*ByIndexed` (3-arg) accessors, typed `Bin<T> extends ListBase<T>` and `BinGenerator<T>`, typed `Bisector<T, X>`, typed `Adder`, typed `Blur2Data`/`BlurImageData`, fixed-arity multi-level `group*`/`rollup*`/`index*`/`flatGroup*`/`flatRollup*` returning native Dart `Map<K, V>`/`Set<T>`, and typed `InternMap<K, V, I>`/`InternSet<T, I>` for custom key canonicalization. | — | `test/*_test.dart`, `test/threshold/*_test.dart`, `test/port/reference_test.dart` | Check signatures and error contracts when the pin changes. |
| <a id="adapt-array-fast-forms"></a>`adapt-array-fast-forms` | `lib/src/sum.dart`, `lib/src/fsum.dart`, `lib/src/cumsum.dart`, `lib/src/min.dart`, `lib/src/max.dart`, `lib/src/extent.dart`, `lib/src/mean.dart`, `lib/src/variance.dart`, `lib/src/deviation.dart`, `lib/src/count.dart`, `lib/src/quickselect.dart`, `lib/src/quantile.dart`, `lib/src/bisect.dart`, `lib/src/bin.dart`, `lib/src/ticks.dart`, `lib/src/range.dart`, `lib/src/blur.dart`, `lib/src/sort.dart`, `lib/src/rank.dart`, `lib/src/group.dart`, `lib/src/shuffle.dart` | d3-array `src/*.js`@v3.2.4 | adapt | Faster native Dart forms with identical outputs ([performance.md](performance.md)): unboxed indexed fast paths for `Float64List`, `List<double>`, `List<int>`, and `List<num>` avoiding per-element iterator and closure overhead; inline Shewchuk summation without intermediate wrapper allocations; specialized `Float64List` Floyd-Rivest `quickselect` and `quantile`; precomputed `pow10` binary search in `ticks`/`nice` and `Float64List` output in `range`; branch-split `Float64List` `blur`/`blur2`/`blurImage` inner loops; unboxed 3-way quicksort for `sort` and `rank`; direct bucket-list accumulation in `bin`; and single-pass grouping/rollup builders. | — | `test/port/faster_forms_test.dart`, `test/port/reference_test.dart` | Compare upstream algorithms when the pin changes. |
| <a id="adapt-array-stable-sort"></a>`adapt-array-stable-sort` | `lib/src/sort.dart`, `lib/src/rank.dart`, `lib/src/groupSort.dart` | d3-array `src/sort.js`@v3.2.4:1-36, `src/rank.js`@v3.2.4:1-25, `src/groupSort.js`@v3.2.4:1-10 | adapt | Dart's `List.sort` is not guaranteed stable for `n > 32`, whereas JS ES2019 `Array.prototype.sort` is stable. `sort`, `sortNullable`, `sortWith`, `sortBy*`, and `rank*` preserve ES2019 stability via index tie-breaking or stable merge sort. | — | `test/sort_test.dart`, `test/rank_test.dart`, `test/groupSort_test.dart` | Re-check stability requirements when the pin changes. |
