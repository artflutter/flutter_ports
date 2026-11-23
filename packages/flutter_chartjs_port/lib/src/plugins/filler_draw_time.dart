// Original code, not ported from Chart.js: the set of the filler draw times.

/// The draw time of the filler plugin (row `adapt-filler-draw-time-enum`):
/// the hook in which it fills the area of each dataset.
///
/// The option `drawTime` of `options.plugins.filler` holds a value of this
/// enum, also in a raw config. The filler plugin closes the set: it fills in
/// the hook of the value. The name of each value is the keyword of Chart.js.
///
/// This library is a pure layer.
library;

/// `drawTime` of the filler options (index.d.ts:2296
/// `'beforeDraw' | 'beforeDatasetDraw' | 'beforeDatasetsDraw'`).
enum FillerDrawTime() {
  /// `'beforeDraw'`: the filler fills each area in the hook `beforeDraw`,
  /// before the chart draws its scales.
  beforeDraw,

  /// `'beforeDatasetDraw'` (the default): the filler fills the area of each
  /// dataset just before the dataset draws.
  beforeDatasetDraw,

  /// `'beforeDatasetsDraw'`: the filler fills each area after the scales,
  /// before the first dataset draws.
  beforeDatasetsDraw,
}
