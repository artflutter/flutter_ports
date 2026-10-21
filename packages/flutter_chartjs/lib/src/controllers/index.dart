// Ported from Chart.js v4.5.1+7169e651 src/controllers/index.js (MIT, Chart.js Contributors).

/// Port of `src/controllers/index.js`: the controller classes that upstream
/// exports as `Chart.controllers`.
///
/// - index.js:1 `export {default as BarController} from
///   './controller.bar.js'`
///
/// Each line exports only the default export of its module. The `export`
/// directives below are in code unit order, as the lint
/// `directives_ordering` asks (Chart.js ADR 0028, section 7). The other
/// seven lines (index.js:2-8) come with the controllers of waves 2 and 3 of
/// phase 7.
///
/// This library is not a pure layer: each controller module imports
/// `core.datasetController`, which imports `core.animations`.
library;

export 'package:flutter_chartjs/src/controllers/controller.bar.dart'
    show BarController;
