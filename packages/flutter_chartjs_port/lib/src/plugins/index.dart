// Ported from Chart.js v4.5.1+7169e651 src/plugins/index.js (MIT, Chart.js Contributors).

/// Port of `src/plugins/index.js`: the plugins that upstream exports as
/// `Chart.plugins` (Chart.js ADR 0038, section 2).
///
/// - index.js:1 `export {default as Colors} from './plugin.colors.js'`
/// - index.js:2 `export {default as Decimation} from
///   './plugin.decimation.js'`
/// - index.js:3 `export {default as Filler} from
///   './plugin.filler/index.js'`
/// - index.js:4 `export {default as Legend} from './plugin.legend.js'`
/// - index.js:5 `export {default as SubTitle} from './plugin.subtitle.js'`
/// - index.js:6 `export {default as Title} from './plugin.title.js'`
/// - index.js:7 `export {default as Tooltip} from './plugin.tooltip.js'`
///
/// Each line exports only the default export of its module: the plugin
/// object. The Dart name of each plugin object is the export name in
/// lowerCamelCase (Chart.js ADR 0038, section 1). Thus this library exports
/// no class `Title`, `Legend` or `Tooltip`.
///
/// This library is not a pure layer: `plugin.tooltip.dart` imports
/// `core.animations`.
library;

export 'package:flutter_chartjs_port/src/plugins/plugin.colors.dart'
    show colors;
export 'package:flutter_chartjs_port/src/plugins/plugin.decimation.dart'
    show decimation;
export 'package:flutter_chartjs_port/src/plugins/plugin.filler/index.dart'
    show filler;
export 'package:flutter_chartjs_port/src/plugins/plugin.legend.dart'
    show legend;
export 'package:flutter_chartjs_port/src/plugins/plugin.subtitle.dart'
    show subTitle;
export 'package:flutter_chartjs_port/src/plugins/plugin.title.dart' show title;
export 'package:flutter_chartjs_port/src/plugins/plugin.tooltip.dart'
    show tooltip;
