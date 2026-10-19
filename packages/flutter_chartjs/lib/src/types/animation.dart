// Ported from Chart.js v4.5.1 src/types/animation.d.ts (MIT, Chart.js Contributors).

/// The declarations of `src/types/animation.d.ts` (Chart.js ADR 0003,
/// porting-flow.md 2.4).
///
/// animation.d.ts declares the classes `Animation` (:4), `Animator` (:20) and
/// `Animations` (:30), and the interface `AnimationEvent` (:13). `index.d.ts`
/// imports `AnimationEvent` (index.d.ts:7) and re-exports all four (:18).
///
/// `core.element.ts:3` imports `Animation`. Thus this library declares
/// [Animation] with the two members that `getProps` reads
/// (core.element.ts:41). Its other members wait for their first ported
/// caller.
///
/// The other declarations wait for their first ported caller, which adds
/// the interface and its members: `core.animation`, `core.animations` and
/// `core.animator` (Chart.js ADR 0007), or the chart options of `index.d.ts`.
/// `Animation` and `Animator` are also the names of the concrete classes
/// (core.animation.js:27, core.animator.js:12), and `Animation` is a class of
/// `package:flutter/animation.dart`. A file that needs two of them imports
/// this library with the prefix `types`.
library;

/// animation.d.ts:4 `Animation`, the type of one running animation of a
/// property. The concrete class is `core.animation.js:27`.
///
/// An element keeps its animations in `$animations`, a Map from the
/// property name to the [Animation] (core.element.ts:15). `getProps` reads
/// [active] and [to] (core.element.ts:41).
abstract interface class Animation {
  /// animation.d.ts:6 `active(): boolean`. True while the animation runs.
  bool active();

  /// animation.d.ts:10 `readonly _to: unknown`, the target value of the
  /// property.
  ///
  /// The value is any JS value (Chart.js ADR 0006): a `double` for a number
  /// property, a `String` for a color, a `bool`, Dart `null` for JS `null`,
  /// or the `undefined` sentinel of `lib/src/js/js_undefined.dart`, when no
  /// value resolves (core.animation.js:31).
  Object? get to;
}
