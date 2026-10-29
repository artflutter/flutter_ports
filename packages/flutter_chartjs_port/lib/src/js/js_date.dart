// Original code, not ported from Chart.js: Date.now() on package:clock.

/// `Date.now()` for ported code (Chart.js ADR 0045, sections 1 and 6).
///
/// [jsDateNow] reads `clock.now()` of `package:clock`. Inside `testWidgets`,
/// the `FakeAsync` zone replaces that clock, and `tester.pump` moves it.
/// Thus the animations of a test run in fake time. `withClock` also replaces
/// it. `DateTime.now()` reads the system clock in each zone, so ported code
/// does not call it (`check:js-semantics`).
///
/// This library is a pure layer. It imports neither `dart:ui` nor
/// `package:flutter`.
library;

import 'package:clock/clock.dart';

/// `Date.now()`: the milliseconds since the epoch of `clock.now()`, as a
/// `double` (Chart.js ADR 0045, section 6).
///
/// The value is a whole number, as `Date.now()` gives. Ported code calls it
/// at each upstream `Date.now()`: `core.animator.js:57`, `:169` and `:201`,
/// `core.animation.js:37` and `:70`, `core.animations.js:73` and
/// `scale.time.js:342-343`.
///
/// Chart animations ignore `timeDilation`, as upstream ignores the speed of
/// the browser animations.
double jsDateNow() => clock.now().millisecondsSinceEpoch.toDouble();
