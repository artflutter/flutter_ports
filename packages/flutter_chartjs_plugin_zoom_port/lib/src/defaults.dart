// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/defaults.ts (MIT, chartjs-plugin-zoom contributors).

/// The default options of the plugin, `zoomPlugin.defaults`.
///
/// The registry of the host merges the plugin defaults into
/// `defaults.plugins.zoom`. It merges a `Map<String, Object?>` with nested
/// Maps, so the defaults keep that form, in the key order of upstream. The
/// Map stays mutable, as an app can change the upstream object. The public
/// library does not export it: the name clashes with `defaults` of the host.
library;

import 'package:flutter_chartjs_plugin_zoom_port/src/options.dart';

/// defaults.ts:3 `defaults`: the default `ZoomPluginOptions`.
///
/// The numbers are doubles, as in the host. `modifierKey: null` is the
/// JavaScript `null`, a value that the resolver keeps.
final Map<String, Object?> defaults = <String, Object?>{
  'pan': <String, Object?>{
    'enabled': false,
    'mode': Mode.xy,
    'threshold': 10.0,
    'modifierKey': null,
  },
  'zoom': <String, Object?>{
    'wheel': <String, Object?>{
      'enabled': false,
      'speed': 0.1,
      'modifierKey': null,
    },
    'drag': <String, Object?>{
      'enabled': false,
      'drawTime': DrawTime.beforeDatasetsDraw,
      'modifierKey': null,
    },
    'pinch': <String, Object?>{
      'enabled': false,
    },
    'mode': Mode.xy,
  },
};
