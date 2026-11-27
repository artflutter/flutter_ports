# d3-chord port differences

This file lists the hunks of ported code that do not translate the upstream lines. Each hunk
carries the line comment `// DIVERGES(d3-chord): <ID>, <reason>`. `check:headers` pairs each
marker with a row of this file. A port-only file is not a row.

The ID starts with its category: `adapt`, `platform`, `js-semantics`, `harness` or `not-followed`,
as in the [D3 port](../../flutter_d3_port/doc/differences.md). The column "Upstream
file@version:lines" names the pin at which the porter last checked the row. Each bump checks every
row.

The port uses no JS runtime ([D3 ADR 0007](../../flutter_d3_port/doc/adr/0007-native-dart-forms.md)).
The rows `adapt-chord-*` record the native forms of
[D3 ADR 0023](../../flutter_d3_port/doc/adr/0023-chord-native-forms.md).

| ID | Dart file and symbol | Upstream file@version:lines | Category | Reason | Upstream reference | Pinning test | Re-check on bump |
|---|---|---|---|---|---|---|---|
| <a id="adapt-chord-typed-api"></a>`adapt-chord-typed-api` | `lib/src/*.dart`, `test/ribbon_test.dart` | d3-chord `src/*.js`@v3.0.1, `test/ribbon-test.js`@v3.0.1 | adapt | Native statically typed Dart APIs with zero `dynamic`, zero `Object?` escape hatches where generics apply, and zero JS runtime ([D3 ADR 0023](../../flutter_d3_port/doc/adr/0023-chord-native-forms.md)): typed immutable `ChordSubgroup`, `Chord`, and `ChordGroup`; `Chords extends ListBase<Chord>` carrying `final List<ChordGroup> groups`; typed `ChordLayout` and `RibbonGenerator<T, S>` with property getters/setters, `*Const` constant setters, `draw(d, CanvasPath)`, and `ribbonBy<T, S>` / `ribbonArrowBy<T, S>` factories; `chord*`-prefixed internal helpers (`chordArraySlice`, `chordConstant`, `chordEpsilon`, `chordPi`, `chordHalfPi`, `chordTau`) avoiding bundle symbol collisions; and stable tie-breaking sorts matching ES2019 `Array.prototype.sort`. | — | `test/chord_test.dart`, `test/ribbon_test.dart`, `test/port/chord_unit_test.dart`, `test/port/reference_test.dart` | Check signatures and defaults when the pin changes. |
| <a id="adapt-chord-fast-forms"></a>`adapt-chord-fast-forms` | `lib/src/chord.dart`, `lib/src/ribbon.dart` | d3-chord `src/chord.js`@v3.0.1, `src/ribbon.js`@v3.0.1 | adapt | Faster native Dart forms with bit-identical outputs ([performance.md](performance.md)): unboxed `Float64List`/`Int32List` matrix flattening, group sums, and subgroup index buffers with inline stable insertion sort for small `n` and compact slot collection in `ChordLayout`; constant-accessor fast paths, single-computation start-point trig reuse (`sx0`, `sy0`), and zero-allocation `draw(d, CanvasPath)` emission into `UiPathContext` in `RibbonGenerator`. | — | `test/port/faster_forms_test.dart`, `test/port/reference_test.dart` | Compare upstream algorithms when the pin changes. |
