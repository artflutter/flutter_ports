# d3-random port differences

This file lists the hunks of ported code that do not translate the upstream lines. Each hunk
carries the line comment `// DIVERGES(d3-random): <ID>, <reason>`. `check:headers` pairs each
marker with a row of this file. A port-only file is not a row.

The ID starts with its category: `adapt`, `platform`, `js-semantics`, `harness` or `not-followed`,
as in the [D3 port](../../flutter_d3_port/doc/differences.md). The column "Upstream
file@version:lines" names the pin at which the porter last checked the row. Each bump checks every
row.

The port uses no JS runtime ([D3 ADR 0007](../../flutter_d3_port/doc/adr/0007-native-dart-forms.md)).
The rows `adapt-random-*` record the native forms of
[D3 ADR 0026](../../flutter_d3_port/doc/adr/0026-random-native-forms.md).

| ID | Dart file and symbol | Upstream file@version:lines | Category | Reason | Upstream reference | Pinning test | Re-check on bump |
|---|---|---|---|---|---|---|---|
| <a id="adapt-random-typed-api"></a>`adapt-random-typed-api` | `lib/src/*.dart` | d3-random `src/*.js`@v3.0.1 | adapt | Native statically typed Dart APIs with zero `dynamic`, zero `Object?` escape hatches, and zero JS runtime ([D3 ADR 0026](../../flutter_d3_port/doc/adr/0026-random-native-forms.md)): typed `RandomSource` (`double Function()`), `RandomGenerator` (`double Function()`), `RandomIntGenerator` (`int Function()`), typed callable `.source(RandomSource)` factory classes (`RandomUniform`, `RandomInt`, `RandomNormal`, `RandomLogNormal`, `RandomBates`, `RandomIrwinHall`, `RandomExponential`, `RandomPareto`, `RandomBernoulli`, `RandomGeometric`, `RandomBinomial`, `RandomGamma`, `RandomBeta`, `RandomWeibull`, `RandomCauchy`, `RandomLogistic`, `RandomPoisson`), `randomLcg([num? seed])`, accurate `randomLog1p` helper, and `RangeError` for degenerate `randomGeometric(0)` where Dart `int` cannot represent `Infinity`. | — | `test/*_test.dart`, `test/port/reference_test.dart` | Check signatures and contracts when the pin changes. |
| <a id="adapt-random-fast-forms"></a>`adapt-random-fast-forms` | `lib/src/*.dart` | d3-random `src/*.js`@v3.0.1 | adapt | Faster native Dart forms with bit-exact seeded outputs ([performance.md](performance.md)): unboxed 32-bit unsigned bitwise arithmetic in `randomLcg`, unboxed state fields and cached Marsaglia polar scale in `randomNormal`, zero-closure direct draw paths in `randomGamma`, `randomBeta`, `randomBinomial`, `randomPoisson`, `randomWeibull`, `randomBates`, `randomIrwinHall`, and `randomBernoulli`, plus typed `Float64List`/`Int32List` batch `fill`/`sample` helpers. | — | `test/port/faster_forms_test.dart`, `test/port/reference_test.dart` | Compare upstream algorithms when the pin changes. |
