// Ported from Chart.js v4.5.1 src/types/animation.d.ts (MIT, Chart.js Contributors).

/// The declarations of `src/types/animation.d.ts` (Chart.js ADR 0003,
/// porting-flow.md 2.4).
///
/// animation.d.ts declares the classes `Animation` (:4), `Animator` (:20) and
/// `Animations` (:30), and the interface `AnimationEvent` (:13). `index.d.ts`
/// imports `AnimationEvent` (index.d.ts:7) and re-exports all four (:18).
/// No phase 2 file names one of them: `core.animations.defaults.js` holds
/// option values only.
///
/// Each declaration waits for its first ported caller, which adds the
/// interface and its members: `core.animation`, `core.animations` and
/// `core.animator` (Chart.js ADR 0007), or the chart options of `index.d.ts`.
/// `Animation` and `Animator` are also the names of the concrete classes
/// (core.animation.js:27, core.animator.js:12), and `Animation` is a class of
/// `package:flutter/animation.dart`. A file that needs two of them imports
/// this library with the prefix `types`.
library;
