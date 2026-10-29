// Ported from Chart.js v4.6.1 src/helpers/index.ts (MIT, Chart.js Contributors).

/// Port of `src/helpers/index.ts`: the helpers that upstream exports as
/// `Chart.helpers`. The export list is the upstream list. The
/// `directives_ordering` lint sorts it.
///
/// index.ts:8 exports the default export of `helpers.easing.ts` as
/// `easingEffects`. Dart has no renamed export. Thus this library declares
/// [easingEffects], the same Map as `effects` of `helpers.easing.dart`, and
/// exports no other name of that library, as upstream.
///
/// The library exports `helpers.extras`, which imports
/// `package:flutter/scheduler.dart`. Thus it is not a pure layer
/// (porting-flow.md section 3).
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.easing.dart'
    show effects;

export 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.color.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.config.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.core.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.curve.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.dataset.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.dom.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.extras.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.interpolation.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.intl.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.math.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.rtl.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.segment.dart';

/// index.ts:8 `export {default as easingEffects} from './helpers.easing.js'`.
final Map<String, double Function(double t)> easingEffects = effects;
