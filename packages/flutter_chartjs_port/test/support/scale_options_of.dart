// Original code, not ported from Chart.js: typed scale options of a Map.

/// The typed scale options of the plain options object of a fake scale
/// (Chart.js ADR 0183).
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// The view of the plain options object [options]: a resolver over
/// [options] alone, with an empty context.
OptionView _viewOf(Map<String, Object?> options) =>
    attachContext(createResolver([options]), <String, Object?>{});

/// The typed scale options of [options], as `Scale.options` gives them.
CoreScaleOptions scaleOptionsOf(Map<String, Object?> options) =>
    CoreScaleOptions(_viewOf(options));

/// The typed radial linear scale options of [options].
RadialLinearScaleOptions radialScaleOptionsOf(Map<String, Object?> options) =>
    RadialLinearScaleOptions(_viewOf(options));
