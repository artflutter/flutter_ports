// Original code, not ported from Chart.js: the set of the stepped lines.

/// The keywords of the line option `stepped` (row `adapt-stepped-line-enum`).
///
/// The option holds a boolean or a value of [SteppedLine], also in a raw
/// config: `true` is a stepped line of the form [SteppedLine.before], as
/// upstream draws it. The line closes the set: `steppedLineTo` and
/// `steppedInterpolation` draw each form. The name of each value is the
/// keyword of Chart.js.
///
/// This library is a pure layer.
library;

/// `stepped` of a line (index.d.ts:1994 `'before' | 'after' | 'middle'`, with
/// `boolean`): where the step of each segment of a stepped line lies.
enum SteppedLine() {
  /// `'before'`: the step at the start of the segment, the form of `true`.
  before,

  /// `'after'`: the step at the end of the segment.
  after,

  /// `'middle'`: the step in the middle of the segment.
  middle,
}
