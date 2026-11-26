# d3-path port differences

This file lists the hunks of ported code that do not translate the upstream lines. Each hunk
carries the line comment `// DIVERGES(d3-path): <ID>, <reason>`. `check:headers` pairs each marker
with a row of this file. A port-only file is not a row.

The ID starts with its category: `adapt`, `platform`, `js-semantics`, `harness` or `not-followed`,
as in the [D3 port](../../flutter_d3_port/doc/differences.md). The column "Upstream
file@version:lines" names the pin at which the porter last checked the row. Each bump checks every
row.

The port uses no JS runtime ([D3 ADR 0007](../../flutter_d3_port/doc/adr/0007-native-dart-forms.md)).
The rows `adapt-path-*` record the native forms of
[D3 ADR 0014](../../flutter_d3_port/doc/adr/0014-path-native-forms.md).

| ID | Dart file and symbol | Upstream file@version:lines | Category | Reason | Upstream reference | Pinning test | Re-check on bump |
|---|---|---|---|---|---|---|---|
| <a id="adapt-path-typed-args"></a>`adapt-path-typed-args` | `lib/src/path.dart` `Path`, `Path.arc`, `pathRound` | d3-path `src/path.js`@v3.1.0:13-16, 27-31, 100-101, 154-156 | adapt | Upstream accepts arbitrary JS values for `ccw` (coerced with `!!ccw`) and `digits` (coerced with `+digits`, so `pathRound(null)` becomes `pathRound(0)` and `pathRound(NaN)` throws). In native Dart ([D3 ADR 0014](../../flutter_d3_port/doc/adr/0014-path-native-forms.md)), `arc` takes `[bool ccw = false]`, `Path([int? digits])` takes an optional integer (throwing `RangeError` for negative digits), and `pathRound([int digits = 3])` takes a non-nullable `int`. Negative radii throw `RangeError`. | — | `test/path_test.dart` (2 truthy/falsy `ccw` cases skip with `diverges: adapt-path-typed-args`); `test/pathRound_test.dart` (`pathRound(null)` skips with `diverges: adapt-path-typed-args`) | Check `src/path.js` constructor, `arc`, and `pathRound` when the pin changes. |
| <a id="platform-path-math-last-bit"></a>`platform-path-math-last-bit` | `lib/src/path.dart` `Path.arc`, `Path.arcTo` | d3-path `src/path.js`@v3.1.0:86-88, 106-107, 136 | platform | `math.cos`, `math.sin`, `math.acos`, `math.tan`, and `math.sqrt` call `dart:math` directly ([D3 ADR 0007](../../flutter_d3_port/doc/adr/0007-native-dart-forms.md) §5). On native platforms, the platform libm can differ from V8's fdlibm in the last bit (~1e-16 relative), which only affects unrounded full-precision coordinates. | — | `test/port/reference_test.dart` (compares rounded paths byte-for-byte and unrounded paths with upstream `assertPathEqual` 1e-6 normalization against Node.js) | None: the platform libm decides. |
| <a id="adapt-path-fast-forms"></a>`adapt-path-fast-forms` | `lib/src/path.dart` `Path` | d3-path `src/path.js`@v3.1.0:6-24, 26-145 | adapt | Faster native Dart serialization with identical SVG outputs ([performance.md](performance.md)): on native AOT and WebAssembly, `Path` writes ASCII bytes directly into a growable `Uint8List` buffer (single `String.fromCharCodes` in `toString()`), emits integers and `pathRound(0..6)` decimals directly from integer digits via a 2-digit lookup table without `double.toString()`, and formats full-precision doubles via a clean-room 30-bit-limb Ryū shortest-decimal emitter directly into the byte buffer; on dart2js, `Path` appends directly to a native JS `String`. | — | `test/port/faster_forms_test.dart` (verifies 200k+ IEEE-754 doubles, subnormals, extremes and `pathRound(0..15)` bit-for-bit against the direct reference); `test/port/reference_test.dart` | Compare `src/path.js` formatting and rounding rules when the pin changes. |
