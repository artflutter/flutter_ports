// Ported from Chart.js v4.5.1 src/types/color.d.ts (MIT, Chart.js Contributors).

/// The declaration of `src/types/color.d.ts` (Chart.js ADR 0003,
/// porting-flow.md 2.4).
///
/// color.d.ts:1 declares the union
/// `Color = string | CanvasGradient | CanvasPattern`. Dart cannot declare a
/// union as a type alias. The union waits for its first ported caller, which
/// names `Color` in a signature: the option types of `index.d.ts`. No phase 2
/// file names it. `helpers.color.ts:1` imports the `Color` class of
/// `@kurkle/color`, not this type.
///
/// The proposed Dart form is `Object`, as for every option value (Chart.js
/// ADR 0006). The value is a CSS color `String`, or a gradient or pattern of
/// the canvas layer (`lib/src/canvas/`, phase 3).
/// `isPatternOrGradient` (helpers.color.ts:3) tells the two kinds apart. The
/// form is not the `Color` of `dart:ui`, and it is not the `Color` of
/// `@kurkle/color`. A file that imports one of these and this type uses an
/// import prefix.
///
/// The two other members of the union are the DOM types `CanvasGradient`
/// and `CanvasPattern` (lib.dom.d.ts). `helpers.color.ts` is their first
/// ported caller. Its type predicate `value is CanvasPattern |
/// CanvasGradient` (:3) needs a Dart type for each. Thus this library
/// declares [CanvasGradient] and [CanvasPattern] as interfaces (Chart.js
/// ADR 0003), and `isPatternOrGradient` tests them with `is`. The canvas
/// layer of phase 3 implements them. They are free of `dart:ui`, so this
/// library stays a pure layer. Each interface gets its members when a ported
/// caller needs them.
library;

/// lib.dom.d.ts `CanvasGradient`, a member of the union `Color`
/// (color.d.ts:1).
abstract interface class CanvasGradient {}

/// lib.dom.d.ts `CanvasPattern`, a member of the union `Color`
/// (color.d.ts:1).
abstract interface class CanvasPattern {}
