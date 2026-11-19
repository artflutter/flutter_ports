# Zoom ADR 0006: Native matchers and spies in the zoom specs

- Status: accepted (2026-11-19): `jasmine.dart` is gone, and the tests, the fixtures and the port checks pass.
- Date: 2026-11-19
- Supersedes: of [Zoom ADR 0002](0002-file-naming-and-layout.md), in item 4 the bullet of `test/support/jasmine.dart`.
- Related: [Chart.js ADR 0180](../../../flutter_chartjs_port/doc/adr/0180-native-spec-matchers.md)

## Context

The zoom specs used `test/support/jasmine.dart`, a Dart copy of the jasmine-core 5.4.0 spies and
matchers: `createSpy`, `toHaveBeenCalled*`, `jasmineEquals` (a compare by name of Maps and typed
objects), `toBe` (the JS `===`) and `toBeCloseTo`. The zoom options, the contexts of the
callbacks and the ranges are native Dart objects and records (Zoom ADRs 0004 and 0005). The
maintainer asked for native tests with no emulation of Jasmine (2026-11-19).

## Decision

4. **The test support.** No file of `test/` imports `jasmine.dart`, and no such file exists.
   - A spy of a callback is a typed closure of the callback type that adds its arguments to a
     local `List`. `toHaveBeenCalled` is `isNotEmpty`, `toHaveBeenCalledTimes(n)` is
     `hasLength(n)`, and `toHaveBeenCalledWith` reads the recorded arguments.
   - A spy of the hook `beforeUpdate` is a closure in the hook field of the native plugin that
     records and returns `true`. `addTearDown` puts the old hook back.
   - `toEqual` is `equals` on native values, records and objects with `==`. `toBe` is `equals`
     for a number, a string or a bool, and `same` for an object. `toBeCloseTo(e, p)` is
     `closeTo(e, 0.5 * pow(10, -p))`.

## Rejected

- Keep the jasmine-core formula of `toBeCloseTo`: it rounds the difference at one more digit,
  and no case needs that rounding.

## Consequences

- The specs read the same native API as an app.
- A new callback context is a record or a class with `==`, so `equals` compares it.

## Tests

- `test/specs/`
- `test/port/`
