// Ported from Chart.js v4.5.1+7169e651 src/types/animation.d.ts (MIT, Chart.js Contributors).

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
/// [AnimationEvent] is the event of the animator listeners
/// (core.animator.js:27-32). The concrete class of `core.animator.dart`
/// implements it (Chart.js ADR 0019, section 1).
///
/// The declarations of `Animator` and `Animations` wait for their first
/// ported caller, which adds the interface and its members, for example the
/// chart options of `index.d.ts`. `Animation` and `Animator` are also the
/// names of the concrete classes (core.animation.js:27, core.animator.js:12),
/// and `Animation` is a class of `package:flutter/animation.dart`. A file
/// that needs two of them imports this library with the prefix `types`.
library;

import 'package:flutter_chartjs_port/src/types/index.dart' show Chart;

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

/// animation.d.ts:13 `AnimationEvent`, the event that the animator gives to
/// its `progress` and `complete` listeners (core.animator.js:27-32).
///
/// Dart `null` stands for JS `undefined` in [initial], [numSteps] and
/// [currentStep]. `core.controller.js:694` passes `{chart: this}` only. JS
/// `null` never reaches these members.
abstract interface class AnimationEvent {
  /// animation.d.ts:14 `chart: Chart`.
  Chart get chart;

  /// animation.d.ts:15 `numSteps: number`: the duration of the animations
  /// of the chart, in milliseconds (core.animator.js:25).
  double? get numSteps;

  /// animation.d.ts:16 `initial: boolean`: true until the first `complete`
  /// of the chart (core.animator.js:96).
  bool? get initial;

  /// animation.d.ts:17 `currentStep: number`: the milliseconds since the
  /// start, at most [numSteps] (core.animator.js:31).
  double? get currentStep;
}
