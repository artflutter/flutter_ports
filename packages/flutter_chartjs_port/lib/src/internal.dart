// Original code, not ported from Chart.js: one import for the files of lib/src.

/// The internal library of the package: the libraries of `lib/src` that the
/// ported files import, behind one import line.
///
/// Apps and add-on packages import the public libraries, never this one.
library;

export 'package:flutter_chartjs_port/src/controllers/controller.doughnut.dart';
export 'package:flutter_chartjs_port/src/controllers/controller.polarArea.dart';
export 'package:flutter_chartjs_port/src/core/core.config.dart';
export 'package:flutter_chartjs_port/src/core/core.defaults.dart';
export 'package:flutter_chartjs_port/src/js/js_array.dart';
export 'package:flutter_chartjs_port/src/js/js_number.dart';
export 'package:flutter_chartjs_port/src/js/js_object.dart';
export 'package:flutter_chartjs_port/src/options/option_scope.dart';
export 'package:flutter_chartjs_port/src/options/scopes.g.dart';
export 'package:flutter_chartjs_port/src/plugins/plugin_options.dart';
export 'package:flutter_chartjs_port/src/types/chart_paint.dart';
// The interface Defaults of the types has the name of the class of the core.
export 'package:flutter_chartjs_port/src/types/index.dart' hide Defaults;
export 'package:flutter_chartjs_port/src/types/plugin.dart';
