# Chart.js ADR 0143: `Date.now()` is `clock.now()`

- Status: accepted (2026-11-14): its code and the tests of section Tests pass.
- Date: 2026-11-14
- Supersedes: the `jsDateNow` parts of [Chart.js ADR 0045](0045-reference-engine-arm64.md): the
  first sentence of section 6, the `js_date.dart` row of the runtime table, the `Date.now()` row of
  the translation table and the rule "Call `jsDateNow()`".
- Related: Chart.js ADRs [0034](0034-no-display-only-js-exactness.md) (no display-only JS
  exactness), [0016](0016-frame-scheduling.md) (the animator) and
  [0138](0138-math-round-as-round-to-double.md) (a JS function that left `lib/src/js/`).

## Context

Chart.js ADR 0045 added `jsDateNow()` to `lib/src/js/js_date.dart`:
`clock.now().millisecondsSinceEpoch * 1.0`, the JavaScript `Date.now()` as a `double`. The function
does no JavaScript conversion. It only reads `clock.now()` of package:clock and changes the `int`
to a `double`. The fake clock of `testWidgets` and of `withClock` is a feature of package:clock, not
of the function.

Each caller can read `clock.now()` itself, in the Dart type that its arithmetic needs. Some callers
need an `int` (the current day of the date parse, the timer of a test). For them the function
changed an `int` to a `double` and back.

## Decision

1. `Date.now()` of ported code is `clock.now().millisecondsSinceEpoch` of package:clock. A caller
   that computes with `double` values adds `.toDouble()`. A caller that computes with `int` values
   keeps the `int`.
2. `lib/src/js/js_date.dart` and `test/port/js/js_date_test.dart` go. `jsDateNow` leaves
   `lib/js_semantics.dart`, the app library and `doc/public_api.txt`. No function with another name
   replaces it.
3. The callers are `core.animation.dart`, `core.animations.dart`, `core.animator.dart`,
   `date_parse.dart` and `scale.time.dart`, the benchmark of the gallery and the tests. The comments
   keep the upstream `Date.now()` citations.
4. `check:js-semantics` still fails on `DateTime.now(`: `DateTime.now()` reads the system clock in
   each zone. Its advice names `clock.now()`.
5. `check:lib-imports` allows `package:clock/clock.dart` in `lib/`, in the core layers and in the
   tests that the web legs compile. The gallery has package:clock as a direct dependency.

## Tests

- The animation specs and the port tests of the animator, the animations and `Animation.cancel()`
  run in the fake time of `testWidgets` and `withClock`, as before.
- The time scale specs read the current day and year from `clock.now()`.
- `test/tool/check_js_semantics_test.dart` pins the new advice, and
  `test/tool/check_lib_imports_test.dart` the import of package:clock in a core layer.
- The full suite, `test:web`, `test:cases`, `test:fixtures` and `check:port` pass.

## Consequences

- The behavior does not change: the time is the whole milliseconds since the epoch of the same
  clock.
- `lib/src/js/` has no clock code. An add-on port reads `clock.now()` itself.
