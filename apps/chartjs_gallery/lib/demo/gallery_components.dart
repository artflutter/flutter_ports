// Original code, not ported from Chart.js: the gallery chart components.

// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The gallery imports the ported files directly.
// ignore_for_file: implementation_imports

import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/index.dart' show registerables;
import 'package:flutter_chartjs_port/src/types/basic.dart';

bool _registered = false;

/// Registers the built-in components once: `registerables`, as
/// `src/index.umd.ts:28` does. After phase 7, they include the eight
/// controllers.
void registerGalleryComponents() {
  if (_registered) return;
  _registered = true;
  Chart.register(registerables);
}

/// Two hidden linear scales of the fractions 0 to 1 (Chart.js ADR 0031
/// section 3). x has suggested bounds: a user `min` or `max` on unsorted
/// data with `parsing: false` drops points (helpers.extras.ts:94-133).
/// y has user bounds: `getMinMax` does not read the data
/// (core.scale.js:307-309). [hideTicks] adds `ticks: {display: false}`,
/// which skips the auto skip of a hidden scale (core.scale.js:457).
AnyObject unitScales({bool hideTicks = false}) => <String, Object?>{
  'x': <String, Object?>{
    'type': 'linear',
    'display': false,
    if (hideTicks) 'ticks': <String, Object?>{'display': false},
    'suggestedMin': 0.0,
    'suggestedMax': 1.0,
  },
  'y': <String, Object?>{
    'type': 'linear',
    'display': false,
    if (hideTicks) 'ticks': <String, Object?>{'display': false},
    'min': 0.0,
    'max': 1.0,
  },
};
