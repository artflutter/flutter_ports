// Original code, not ported from Chart.js: the gallery chart components.

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    show Chart, registerables;

bool _registered = false;

/// Registers the built-in components once: `registerables`, as
/// `src/index.umd.ts:28` does. They include the eight controllers and the
/// seven plugins.
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
Map<String, Object?> unitScales({bool hideTicks = false}) => <String, Object?>{
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
