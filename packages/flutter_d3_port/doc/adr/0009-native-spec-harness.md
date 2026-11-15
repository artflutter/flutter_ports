# D3 ADR 0009: Native spec harness

- Status: accepted (2026-11-15): its code and the tests of section Tests pass.
- Date: 2026-11-15
- Supersedes: [D3 ADR 0004](0004-spec-harness.md) §1, §2, §3, §4 and §5
- Related: [D3 ADR 0007](0007-native-dart-forms.md), [D3 ADR 0008](0008-module-packages.md), [D3 ADR 0010](0010-native-values-and-factories.md)

## Context

D3 ADR 0004 (proposed) ports the D3 specs with a stand-in of the Node `assert` module, a spec
set-up call in each spec file, ported helpers on the JS runtime and reference values from an x64
build of Node.js. The D3 port uses only native Dart forms. The specs of d3-color 3.1.0 use the
matchers of `package:test`. This ADR keeps the section numbers of D3 ADR 0004.

## Decision

### 1. Spec form

- `test('<name>', …)`: the name of the upstream `it()` or `test()`, in the upstream order. A
  `describe` becomes a `group()`.
- `' #2'`, `' #3'`: a name that occurs again in one file gets the next number.
- A loop that makes cases stays a loop with the upstream names. A name from a JS value that Dart
  does not have, for example `Function.name`, is a string; an anonymous default export gives
  `default`.
- `test(name, () async {…})` translates `it(name, async () => {…})`.
- `skip: 'n/a: skipped upstream'` translates `it.skip`.
- `import 'package:test/test.dart'`: each spec uses `package:test`.
- `@TestOn('vm')`: only a test file that imports `dart:io` or a library that runs only on the VM.
  A test that imports `dart:ui` runs under `flutter test` in the browser too.
- `skip: 'diverges: <row id>'`: a case that asserts a JS coercion that the Dart types do not
  have keeps its name and its body, as a comment.

### 2. Assertions

- `expect(a, b)` translates `assert.strictEqual(a, b)`. An expected NaN is `isNaN`, and an
  expected `null` is `isNull`.
- `expect(a, same(b))` translates `assert.strictEqual(a, b)` of two objects.
- `expect(x, isA<C>())` translates `assert(x instanceof C)`.
- `expect(x, isTrue)` translates `assert(x)` and `assert.ok(x)` of a boolean.
- `expect(a, equals(b))` translates `assert.deepStrictEqual(a, b)`. A list with NaN items takes a
  matcher of the test helpers of the module that reads NaN as equal to NaN.
- `expect(f, throwsA(isA<E>()))` translates `assert.throws(f, E)`, with the Dart error type of
  the port.
- No stand-in of the Node `assert` module exists.

### 3. Ported helpers

- `test/<path>.dart`: an upstream helper that a test file imports is a ported file with the
  header of its repository, for example `test/asserts.dart` of d3-color. It keeps the upstream
  checks, with the matchers of §2.
- The jsdom wrappers, the snapshot generators and the date builders wait for the decisions of
  the DOM layer, the image snapshots and the dates.

### 4. Module-level state

- `tearDown`: a module whose specs change a module-level variable, for example the default
  locale of d3-format, restores it through a set-up function in the `test/support/` folder of its
  package. The ported `finally` blocks stay.
- A module with no such state has no set-up call.

### 5. Reference values

- V8 13.6.233.17-node.58 in Node.js v24.22.1 for darwin-arm64 gives the reference values, never
  a browser.
- `tool/reference/`: a generator of the module package runs the pinned upstream source. It stops
  on another Node.js version or architecture, and when the submodule is not at its pin.
- The output of a generator records the Node.js version, the V8 version and the architecture. Do
  not edit a generated file by hand.
- The upstream specs carry their expected values and need no generator.

## Rejected

- A stand-in of the Node `assert` module: `package:test` gives the same checks with Dart types.
- A set-up call in each spec file: most modules have no module-level state.
- Reference values from an x64 build of Node.js: the repository runs one reference engine.

## Consequences

- A spec reads as a plain `package:test` file.
- A port-only reference test compares a module with upstream on many inputs.
- D3 ADR 0004 §6 to §10 (proposed) stay as they are.

## Tests

- `packages/flutter_d3_color_port/test/*_test.dart`
- `packages/flutter_d3_color_port/test/asserts.dart`
- `packages/flutter_d3_color_port/test/port/reference_test.dart`
