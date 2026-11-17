// Original code, not ported from Chart.js: a count of option calls.

/// The count of the events after which a resolution of the animation options
/// of one element can give another result than the same resolution of the
/// element before it (Chart.js ADR 0151).
///
/// `SharedBarAnimations` of `animation_share.dart` keeps the `Animations`
/// object of one bar for the next bars of the same `BarController.update`
/// call only while this count stays the same. The count is not a cache: it
/// keeps no value of a resolution.
///
/// This library has no import, so each layer can read it. It is a pure layer.
library;

/// The count of the events that can make the animation options of the next
/// element differ from those of the element before it. These places add one:
///
/// - `_resolveScriptable` of `helpers.config.dart`: a function of the app
///   ran as an option, with the context of any resolver.
/// - `_resolveArray` of `helpers.config.dart`: an indexable option gave the
///   item at the index of the context.
/// - `Animation.cancel()` of an active animation: its last tick can call an
///   interpolator or a curve of the app.
///
/// The count wraps at the bounds of an `int` only after 2^63 events.
int optionCallEpoch = 0;
