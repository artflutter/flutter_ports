# Chart.js ADR 0185: Typed element options

- Status: accepted (2026-11-20): the typed element options are on main, and the tests pass.
- Date: 2026-11-20
- Supersedes: nothing
- Related: [Chart.js ADR 0054](0054-typed-internal-model.md), [Chart.js ADR 0183](0183-typed-scale-option-classes.md)

## Context

`Element.options` was `Object?` in the four chart elements. The controllers give them the typed
resolved options (`PointOptions`, `LineOptions`, `BarOptions`, `ArcOptions`), but an element also
took a plain `Map`, and each element kept a second read path for it. The tests and two files of the
filler gave such a `Map`. The maintainer asked for typed element options (2026-11-20).

A user subclass of an element with its own id resolves its options into `GenericElementOptions`, not
into the class of the built-in type.

## Decision

1. **`ElementOptions?`.** `PointElement`, `LineElement`, `BarElement` and `ArcElement` narrow
   `options` to `ElementOptions?`, the base of the four typed classes and of
   `GenericElementOptions`:

   ```dart
   // Before
   final point = PointElement({'options': {'radius': 2}});
   // After
   final point = PointElement({'options': PointOptions({'radius': 2})});
   ```

   Dart `null` is the `undefined` start value. A write of another value, also a `Map`, throws a
   `TypeError`.

2. **The interfaces.** `ILineElement.options`, `PointElementWrites.options` and
   `ArcElementWrites.options` are `ElementOptions?`. The `options` slot of `PointProperties`,
   `BarProperties`, `ArcProperties` and `LineProperties` is `ElementOptions?`: a `Map` written by name
   goes to the foreign slot of the record.

3. **The filler.** `createBoundaryLine` and the stack line of the filler give `LineOptions`, where
   upstream gives an object literal (`{tension: 0}`, `{}`).

4. **The read by name stays for other classes.** An element reads a `GenericElementOptions` by name,
   as it read a `Map`. The point adapter of `drawPoint` is `_GenericPointOptions`.

5. **Row.** The markers use the new row `adapt-native-element-options`.

## Rejected

- The class of the built-in type for each element (`PointOptions?` for a point): a user subclass
  with its own id gets `GenericElementOptions`, and its options would fail the type.

## Consequences

- An app or a plugin that writes element options gives a typed class.
- The reference tests run each case with `GenericElementOptions` and with the typed class, in place
  of a `Map` and the typed class.

## Tests

`test/port/elements/`, `test/specs/element.point_test.dart`, `test/specs/element.arc_test.dart`,
`test/port/options/props_test.dart`.
