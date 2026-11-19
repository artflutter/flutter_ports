# Chart.js ADR 0180: Native matchers and recorders in the spec ports

- Status: accepted (2026-11-19): `jasmine.dart` is gone, and the tests, the fixtures and the port checks pass.
- Date: 2026-11-19
- Supersedes: of [Chart.js ADR 0030](0030-controller-test-strategy.md), in §13 items 1, 5, 6, 7 and 8.
- Related: [Chart.js ADR 0054](0054-typed-internal-model.md), [Zoom ADR 0006](../../../flutter_chartjs_plugin_zoom_port/doc/adr/0006-native-test-matchers.md)

## Context

The spec ports used `test/support/jasmine.dart`, a Dart copy of the Jasmine semantics:
`jasmineEquals` compared any two values by name, key by key, as `MatchersUtil.eq` of
jasmine-core 3.99.1 does, and `spyOn` replaced a function value in a Map. The library code holds
typed objects (Chart.js ADR 0054), so a test that compares an expected Map with a typed object
reads the object by name: the test keeps a JS-shaped model alive that the library no longer has.
The maintainer asked for native tests with no emulation of Jasmine (2026-11-19).

## Decision

### 13. The conventions of the spec files

1. **File.** A spec port is `test/specs/<base>_test.dart`. Line 1 is the rule-2 header of the pin,
   then `@TestOn('vm')` when it creates a chart, and `library;`. The imports are `flutter_test`
   (or `package:test` for a pure spec), `package:chartjs_test_utils/flutter.dart`,
   `package:chartjs_test_utils/pure.dart`, `../support/draw_recorder.dart` when a case records a
   draw, and the public libraries of the port. No file of `test/` imports `jasmine.dart`, and no
   such file exists.
5. **Recorders of methods.** A Dart object cannot replace one of its methods. A recorder is a
   subclass of the concrete element class that takes the slot that the library reads:
   `recordElementDraws(meta, i)` for `meta.data[i]` and `recordLineCalls(meta)` for
   `meta.dataset`. It copies the element by its typed fields and adds each call to a typed `List`
   (`ElementDraw`, `LineDraw`, `ControlPointsUpdate`). With `drawThrough` or `callThrough`, it
   also runs the method of the class. An element with a running animation throws a `StateError`.
6. **Recorders of array listeners.** `recordArrayCalls(data, controller)` puts a listener in the
   place of the controller in the listeners of the data array and returns `ArrayCalls` (`pushes`,
   `pops`, `shifts`, `splices`, `unshifts`). `addTearDown` puts the controller back.
7. **Native matchers.** A spec compares with the matchers of package:test: `equals` on native
   values and on objects with `==` (`ActiveElement`, records, `ChartPaint`), `same` for identity,
   `closeTo`, and `isA<T>().having(...)` on the typed members of an object with no `==`. A spy of
   a function value or of a plugin hook is a local closure that adds its arguments to a local
   `List`. A test reads a typed object through its typed members; it reads by name only an object
   of the user.
8. **Context of an assertion.** `expect(x).withContext(i).toEqual(y)` is
   `expect(x, equals(y), reason: '$i')`, with the native matcher of item 7 in place of `equals`
   where the value is a typed object.

## Rejected

- Keep `jasmineEquals` and rename it: it still compares typed objects by name.
- Copy the element by name in a recorder: the typed fields give the same copy with no access by
  name.

## Consequences

- The spec ports read the same typed API as an app.
- An expected value in a spec is the native object, not the upstream object literal. The upstream
  line stays in the comment.
- A new typed object of the library needs `==` or a `having` chain in the spec that compares it.

## Tests

- `test/support/draw_recorder.dart`
- `test/specs/`
