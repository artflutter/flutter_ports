# D3 ADR 0007: Native Dart forms, no JS runtime

- Status: proposed
- Date: 2026-11-15
- Supersedes: [D3 ADR 0003](0003-number-to-string.md) §2, §3 and §5; [D3 ADR 0004](0004-spec-harness.md) §2 and §5; [D3 ADR 0006](0006-generators-accessors-and-js-values.md) §6
- Related: [D3 ADR 0002](0002-file-naming-and-layout.md), [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md), [Chart.js ADR 0146](../../../flutter_chartjs_port/doc/adr/0146-js-numeric-semantics.md)

## Context

The proposed D3 ADRs 0003, 0004 and 0006 translate D3 through a JS runtime: the `undefined`
sentinel, `jsCall`, JS number methods, `jsAtan2` and a Node `assert` stand-in. The maintainer
decided on 2026-11-15 that the D3 port uses only native Dart and Flutter forms. d3-color is the
first ported module. Its factories overload on their argument count, coerce each argument with
`+x`, and print numbers into CSS texts.

## Decision

1. Ported D3 code uses no JS runtime: no `undefined` sentinel, no `jsCall`, no `jsGet`, no JS
   number methods and no emulated builtins. `package:flutter_d3_port` does not depend on
   `js_semantics` or on `flutter_chartjs_port`.
2. A value has its Dart type: `double` for a number, `String` for a text, a class for an object.
   NaN stays NaN: it is an IEEE double, and D3 uses it as data (an undefined channel of
   d3-color). Dart `null` is the absent value of a nullable parameter or result, for example the
   `null` of `color('bostock')`.
3. An upstream factory that overloads on its argument count becomes Dart constructors:
   `Rgb(70, 130, 180)` for `rgb(70, 130, 180)`, `Rgb.from(color)` for `rgb(color)` and
   `Rgb.parse('steelblue')` for `rgb('steelblue')`. A factory with no class keeps its name as a
   function, for example `gray(50)` and `lch(74, 11, 252)`. An omitted optional argument is the
   upstream default, for example the opacity 1.
4. The `+x` coercion of an argument has no Dart form. A spec case that asserts such a coercion
   keeps its upstream name and skips as `'diverges: <row id>'`.
5. `Math` is `dart:math` as it is, also `pow`, `atan2`, `sin` and `cos`. JavaScript `%` is
   `remainder`. A truthiness test of a number is written out, for example
   `s != 0 && !s.isNaN` for `if (s)`.
6. A number in a text of a module (for example `formatHsl`) is `double.toString`, with no `.0` for
   a whole number and `0` for -0. For the value ranges of the module, this is the text of
   JavaScript `String(x)`. A port-only test compares the texts with upstream in Node.js.
7. Specs use the matchers of `package:test`. An expected NaN is `isNaN`. A ported helper keeps
   its upstream checks with these matchers, for example
   `packages/flutter_d3_color_port/test/asserts.dart`. A spec calls `setUpSpecs()` only when its
   module has module-level state.
8. Reference values come from the engine of Chart.js ADR 0146: Node.js v24.22.1 on darwin-arm64.
   A generator in `tool/reference/` of a module package runs the pinned upstream source and stops
   on another engine.
9. A Flutter form of a D3 value is a port-only extension in `lib/src/ui/` of its module package,
   for example `toUiColor()` and `toD3Rgb()` of d3-color. The pure library of a module package and
   `package:flutter_d3_port/d3.dart` import no Flutter library. The main library of each package
   adds the Flutter layer.
10. A faster Dart form that keeps the results of the upstream form follows porting-flow.md §1.1:
    it gets a `DIVERGES` marker, an `adapt` row and figures in `doc/performance.md` of its
    package.

## Rejected

- The JS runtime of ADR 0008 for D3: it keeps the JS object model in Dart and costs speed.
- One factory function `rgb(Object value)` that tests the type of its argument: a JS union in
  Dart, with no static type check.
- A Node `assert` stand-in: `package:test` gives the same checks with Dart types.

## Consequences

- The d3-color API is Dart: a call with a string channel is a compile error, not NaN.
- Each later module states its overloads as constructors or named parameters in its rows.
- The D3 port needs no part of the shared runtime of ADR 0008.
- The texts of a module can differ from upstream outside the value ranges that the reference
  test covers. A difference that a test finds gets a row.

## Tests

- `packages/flutter_d3_color_port/test/*_test.dart`
- `packages/flutter_d3_color_port/test/port/reference_test.dart`
- `packages/flutter_d3_color_port/test/port/ui_color_test.dart`
