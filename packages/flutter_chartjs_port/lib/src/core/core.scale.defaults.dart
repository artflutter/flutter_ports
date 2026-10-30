// Ported from Chart.js v4.6.1 src/core/core.scale.defaults.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.scale.defaults.js`.
///
/// The value objects of `defaults.set` and `defaults.describe` are typed
/// option scopes of the kind of their path (Chart.js ADR 0054 §3), and
/// numbers are `double` (Chart.js ADR 0045). A scriptable option is a Dart
/// closure (`lib/src/js/js_function.dart`). [Defaults] is the interface of
/// the `defaults` object of `core.defaults.js`.
library;

import 'package:flutter_chartjs_port/src/core/core.ticks.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/opt.dart' show OptFunction;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show
        BorderOptionsScope,
        DescriptorsScope,
        GridLineOptionsScope,
        MajorTickOptionsScope,
        MinorTickOptionsScope,
        PaddingScope,
        ScaleOptionsScope,
        ScaleTitleOptionsScope,
        TickOptionsScope;
import 'package:flutter_chartjs_port/src/types/index.dart';

/// core.scale.defaults.js:3 `applyScaleDefaults`.
///
/// The scriptable options `tickWidth` and `tickColor` read a key of their
/// resolved `options` object, a `Map<String, Object?>`, with the JavaScript
/// property read: an absent key gives [undefined].
void applyScaleDefaults(Defaults defaults) {
  defaults
    ..set(
      'scale',
      ScaleOptionsScope()
        ..display = true
        ..offset = false
        ..reverse = false
        ..beginAtZero = false
        // Scale boundary strategy (bypassed by min/max time options)
        // - `data`: make sure data are fully visible, ticks outside are
        //   removed
        // - `ticks`: make sure ticks are fully visible, data outside are
        //   truncated
        // @see https://github.com/chartjs/Chart.js/pull/4556
        // @since 3.0.0
        ..bounds = 'ticks'
        ..clip = true
        // Addition grace added to max and reduced from min data value.
        // @since 3.0.0
        ..grace = 0.0
        // grid line settings
        ..grid = (GridLineOptionsScope()
          ..display = true
          ..lineWidth = 1.0
          ..drawOnChartArea = true
          ..drawTicks = true
          ..tickLength = 8.0
          ..tickWidthCell = const OptFunction<double>(_tickWidth)
          ..tickColor = _tickColor
          ..offset = false)
        ..border = (BorderOptionsScope()
          ..display = true
          ..dash = <Object?>[]
          ..dashOffset = 0.0
          ..width = 1.0)
        // scale title
        ..title = (ScaleTitleOptionsScope()
          // display property
          ..display = false
          // actual label
          ..text = ''
          // top/bottom padding
          ..padding = (PaddingScope()
            ..top = 4.0
            ..bottom = 4.0))
        // label settings
        ..ticks = (TickOptionsScope()
          ..minRotation = 0.0
          ..maxRotation = 50.0
          ..mirror = false
          ..textStrokeWidth = 0.0
          ..textStrokeColor = ''
          ..padding = 3.0
          ..display = true
          ..autoSkip = true
          ..autoSkipPadding = 3.0
          ..labelOffset = 0.0
          // We pass through arrays to be rendered as multiline labels, we
          // convert Others to strings here.
          ..callback = (ticks['formatters']! as Map<String, Object?>)['values']!
          ..minor = MinorTickOptionsScope()
          ..major = MajorTickOptionsScope()
          ..align = 'center'
          ..crossAlign = 'near'
          ..showLabelBackdrop = false
          ..backdropColor = 'rgba(255, 255, 255, 0.75)'
          ..backdropPadding = 2.0),
    )
    ..route('scale.ticks', 'color', '', 'color')
    ..route('scale.grid', 'color', '', 'borderColor')
    ..route('scale.border', 'color', '', 'borderColor')
    ..route('scale.title', 'color', '', 'color')
    ..describe(
      'scale',
      DescriptorsScope()
        ..descFallback = false
        ..descScriptable = _scaleScriptable
        ..descIndexable = _scaleIndexable,
    )
    ..describe('scales', DescriptorsScope()..descFallback = 'scale')
    ..describe(
      'scale.ticks',
      DescriptorsScope()
        ..descScriptable = _ticksScriptable
        ..descIndexable = _ticksIndexable,
    );
}

/// core.scale.defaults.js:34 the default `grid.tickWidth`.
Object? _tickWidth(Object? _, Object? options) => jsGet(options, 'lineWidth');

/// core.scale.defaults.js:35 the default `grid.tickColor`.
Object? _tickColor(Object? _, Object? options) => jsGet(options, 'color');

/// core.scale.defaults.js:93 the `_scriptable` descriptor of `scale`.
bool _scaleScriptable(String name) =>
    !name.startsWith('before') &&
    !name.startsWith('after') &&
    name != 'callback' &&
    name != 'parser';

/// core.scale.defaults.js:94 the `_indexable` descriptor of `scale`.
bool _scaleIndexable(String name) =>
    name != 'borderDash' && name != 'tickBorderDash' && name != 'dash';

/// core.scale.defaults.js:102 the `_scriptable` descriptor of
/// `scale.ticks`.
bool _ticksScriptable(String name) =>
    name != 'backdropPadding' && name != 'callback';

/// core.scale.defaults.js:103 the `_indexable` descriptor of `scale.ticks`.
bool _ticksIndexable(String name) => name != 'backdropPadding';
