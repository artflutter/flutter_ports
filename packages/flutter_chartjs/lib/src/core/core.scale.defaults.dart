// Ported from Chart.js v4.5.1+7169e651 src/core/core.scale.defaults.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.scale.defaults.js`.
///
/// Option objects are `Map<String, Object?>` and numbers are `double`
/// (Chart.js ADRs 0006 and 0010). A scriptable option is a Dart closure
/// (`lib/src/js/js_function.dart`). [Defaults] is the interface of the
/// `defaults` object of `core.defaults.js`.
library;

import 'package:flutter_chartjs/src/core/core.ticks.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/index.dart';

/// core.scale.defaults.js:3 `applyScaleDefaults`.
///
/// The scriptable options `tickWidth` and `tickColor` read a key of their
/// resolved `options` object, a `Map<String, Object?>`, with the JavaScript
/// property read: an absent key gives [undefined].
void applyScaleDefaults(Defaults defaults) {
  defaults
    ..set('scale', <String, Object?>{
      'display': true,
      'offset': false,
      'reverse': false,
      'beginAtZero': false,

      // Scale boundary strategy (bypassed by min/max time options)
      // - `data`: make sure data are fully visible, ticks outside are removed
      // - `ticks`: make sure ticks are fully visible, data outside are
      //   truncated
      // @see https://github.com/chartjs/Chart.js/pull/4556
      // @since 3.0.0
      'bounds': 'ticks',

      'clip': true,

      // Addition grace added to max and reduced from min data value.
      // @since 3.0.0
      'grace': 0.0,

      // grid line settings
      'grid': <String, Object?>{
        'display': true,
        'lineWidth': 1.0,
        'drawOnChartArea': true,
        'drawTicks': true,
        'tickLength': 8.0,
        'tickWidth': (Object? _, Object? options) =>
            jsGet(options, 'lineWidth'),
        'tickColor': (Object? _, Object? options) => jsGet(options, 'color'),
        'offset': false,
      },

      'border': <String, Object?>{
        'display': true,
        'dash': <Object?>[],
        'dashOffset': 0.0,
        'width': 1.0,
      },

      // scale title
      'title': <String, Object?>{
        // display property
        'display': false,

        // actual label
        'text': '',

        // top/bottom padding
        'padding': <String, Object?>{
          'top': 4.0,
          'bottom': 4.0,
        },
      },

      // label settings
      'ticks': <String, Object?>{
        'minRotation': 0.0,
        'maxRotation': 50.0,
        'mirror': false,
        'textStrokeWidth': 0.0,
        'textStrokeColor': '',
        'padding': 3.0,
        'display': true,
        'autoSkip': true,
        'autoSkipPadding': 3.0,
        'labelOffset': 0.0,
        // We pass through arrays to be rendered as multiline labels, we
        // convert Others to strings here.
        'callback': (ticks['formatters']! as Map<String, Object?>)['values'],
        'minor': <String, Object?>{},
        'major': <String, Object?>{},
        'align': 'center',
        'crossAlign': 'near',

        'showLabelBackdrop': false,
        'backdropColor': 'rgba(255, 255, 255, 0.75)',
        'backdropPadding': 2.0,
      },
    })
    ..route('scale.ticks', 'color', '', 'color')
    ..route('scale.grid', 'color', '', 'borderColor')
    ..route('scale.border', 'color', '', 'borderColor')
    ..route('scale.title', 'color', '', 'color')
    ..describe('scale', <String, Object?>{
      '_fallback': false,
      '_scriptable': (String name) =>
          !name.startsWith('before') &&
          !name.startsWith('after') &&
          name != 'callback' &&
          name != 'parser',
      '_indexable': (String name) =>
          name != 'borderDash' && name != 'tickBorderDash' && name != 'dash',
    })
    ..describe('scales', <String, Object?>{
      '_fallback': 'scale',
    })
    ..describe('scale.ticks', <String, Object?>{
      '_scriptable': (String name) =>
          name != 'backdropPadding' && name != 'callback',
      '_indexable': (String name) => name != 'backdropPadding',
    });
}
