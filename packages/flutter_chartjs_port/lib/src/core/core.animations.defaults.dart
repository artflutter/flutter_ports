// Ported from Chart.js v4.5.1+7169e651 src/core/core.animations.defaults.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.animations.defaults.js`.
///
/// Option objects are `Map<String, Object?>`, `undefined` is the [undefined]
/// sentinel and numbers are `double` (Chart.js ADRs 0032 and 0043). A
/// function value is a Dart closure (`lib/src/js/js_function.dart`).
/// [Defaults] is the interface of the `defaults` object of
/// `core.defaults.js`.
library;

import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';

/// core.animations.defaults.js:1 `numbers`.
const List<String> _numbers = ['x', 'y', 'borderWidth', 'radius', 'tension'];

/// core.animations.defaults.js:2 `colors`.
const List<String> _colors = ['color', 'borderColor', 'backgroundColor'];

/// core.animations.defaults.js:4 `applyAnimationsDefaults`.
///
/// `defaults.set` copies the values with `merge`. Thus the const lists
/// [_numbers] and [_colors] reach the defaults as new lists.
void applyAnimationsDefaults(Defaults defaults) {
  defaults
    ..set('animation', <String, Object?>{
      'delay': undefined,
      'duration': 1000.0,
      'easing': 'easeOutQuart',
      'fn': undefined,
      'from': undefined,
      'loop': undefined,
      'to': undefined,
      'type': undefined,
    })
    ..describe('animation', <String, Object?>{
      '_fallback': false,
      '_indexable': false,
      '_scriptable': (String name) =>
          name != 'onProgress' && name != 'onComplete' && name != 'fn',
    })
    ..set('animations', <String, Object?>{
      'colors': <String, Object?>{
        'type': 'color',
        'properties': _colors,
      },
      'numbers': <String, Object?>{
        'type': 'number',
        'properties': _numbers,
      },
    })
    ..describe('animations', <String, Object?>{
      '_fallback': 'animation',
    })
    ..set('transitions', <String, Object?>{
      'active': <String, Object?>{
        'animation': <String, Object?>{
          'duration': 400.0,
        },
      },
      'resize': <String, Object?>{
        'animation': <String, Object?>{
          'duration': 0.0,
        },
      },
      'show': <String, Object?>{
        'animations': <String, Object?>{
          'colors': <String, Object?>{
            'from': 'transparent',
          },
          'visible': <String, Object?>{
            'type': 'boolean',
            'duration': 0.0, // show immediately
          },
        },
      },
      'hide': <String, Object?>{
        'animations': <String, Object?>{
          'colors': <String, Object?>{
            'to': 'transparent',
          },
          'visible': <String, Object?>{
            'type': 'boolean',
            'easing': 'linear',
            // for keeping the dataset visible all the way through the
            // animation. `v | 0` is ToInt32 of ToNumber.
            'fn': (Object? v) => jsToInt32(jsToNumber(v)),
          },
        },
      },
    });
}
