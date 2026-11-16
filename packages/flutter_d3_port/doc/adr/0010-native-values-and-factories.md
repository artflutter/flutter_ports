# D3 ADR 0010: Native values and factories

- Status: accepted (2026-11-15): its code and the tests of section Tests pass.
- Date: 2026-11-15
- Superseded in part by: [D3 ADR 0011](0011-interpolate-native-forms.md) for §6, the bullet of the parameter types, in d3-interpolate (2026-11-16)
- Supersedes: [D3 ADR 0006](0006-generators-accessors-and-js-values.md) §6, and the bullet "Keyed accessors and other overloads" of §2 for the factories of a class
- Related: [D3 ADR 0007](0007-native-dart-forms.md), [D3 ADR 0009](0009-native-spec-harness.md)

## Context

D3 ADR 0006 (proposed) keeps the JS values `undefined`, `null` and an absent argument through the
sentinels `undefined` and `absent` of a JS runtime. It also keeps a function that overloads on
`arguments.length` as one function with `absent` defaults. The D3 port uses only native Dart
forms. The factories of d3-color overload on their argument count: `rgb(r, g, b)`,
`rgb(specifier)` and `rgb(color)`. This ADR keeps the section numbers of D3 ADR 0006.

## Decision

### 2. Factories that overload on their argument count

- `Rgb(70, 130, 180)`: a factory that overloads on its argument count and makes an object of a
  class is that class. The form with values is the unnamed constructor.
- `Rgb.from(color)`: the form with one object of the module is the named constructor `from`.
- `Rgb.parse('steelblue')`: the form with one text is the named constructor `parse`.
- `gray(50)`, `lch(74, 11, 252)`: a factory whose form with values makes an object of another
  class stays a top-level function with that form.
- This section applies to the factories of a class. It does not change the accessors and the
  other methods.

### 6. Values

- `null`: JS `null` is Dart `null`.
- `double`: a number is a `double`, and an index or a count is an `int`. NaN is NaN, also as the
  undefined channel of a d3-color color.
- An absent argument is an omitted optional parameter with the upstream default, for example the
  opacity 1. No `undefined` or `absent` sentinel exists.
- `Color? color(String specifier)`: a result that upstream gives as `null` or `undefined` for "no
  value" is Dart `null`, with a nullable type.
- `double r`, `String specifier`: a parameter has the Dart type of the values that the upstream
  docs allow. The `+x` coercion of a value of another type has no Dart form.

## Rejected

- One factory `rgb(Object value)` that tests the type of its argument: a JS union in Dart, with
  no static type check.
- The sentinels `undefined` and `absent`: they keep the JS object model in Dart.

## Consequences

- A call with a string channel, for example `Rgb('12', '34', '56')`, is a compile error, not NaN.
- The upstream spec cases of such coercions skip as `'diverges: adapt-color-factories'`.
- Each later module states the overloads of its factories with constructors.

## Tests

- `packages/flutter_d3_color_port/test/rgb_test.dart`
- `packages/flutter_d3_color_port/test/hsl_test.dart`
- `packages/flutter_d3_color_port/test/lab_test.dart`
- `packages/flutter_d3_color_port/test/hcl_test.dart`
