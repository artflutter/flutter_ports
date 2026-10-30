// Ported from Chart.js v4.6.1 src/core/core.animations.defaults.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.animations.defaults.js`.
///
/// The value objects of `defaults.set` and `defaults.describe` are typed
/// option scopes of the kind of their path (Chart.js ADR 0054 §3).
/// `undefined` is the [optUndefined] cell and numbers are `double` (Chart.js
/// ADR 0045). A function value is a Dart closure
/// (`lib/src/js/js_function.dart`). [Defaults] is the interface of the
/// `defaults` object of `core.defaults.js`.
library;

import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/options/opt.dart' show optUndefined;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show
        AnimationOptionsScope,
        AnimationsSpecScope,
        DescriptorsScope,
        TransitionOptionsScope,
        TransitionsSpecScope;
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
    ..set(
      'animation',
      AnimationOptionsScope()
        ..delayCell = optUndefined
        ..duration = 1000.0
        ..easing = 'easeOutQuart'
        ..fnCell = optUndefined
        ..fromCell = optUndefined
        ..loopCell = optUndefined
        ..toCell = optUndefined
        ..typeCell = optUndefined,
    )
    ..describe(
      'animation',
      DescriptorsScope()
        ..descFallback = false
        ..descIndexable = false
        ..descScriptable = _animationScriptable,
    )
    ..set(
      'animations',
      AnimationsSpecScope()
        ..colors = (AnimationOptionsScope()
          ..type = 'color'
          ..properties = _colors)
        ..numbers = (AnimationOptionsScope()
          ..type = 'number'
          ..properties = _numbers),
    )
    ..describe('animations', DescriptorsScope()..descFallback = 'animation')
    ..set(
      'transitions',
      TransitionsSpecScope()
        ..active = (TransitionOptionsScope()
          ..animation = (AnimationOptionsScope()..duration = 400.0))
        ..resize = (TransitionOptionsScope()
          ..animation = (AnimationOptionsScope()..duration = 0.0))
        ..show = (TransitionOptionsScope()
          ..animations = (AnimationsSpecScope()
            ..colors = (AnimationOptionsScope()..from = 'transparent')
            ..visible = (AnimationOptionsScope()
              ..type = 'boolean'
              // show immediately
              ..duration = 0.0)))
        ..hide = (TransitionOptionsScope()
          ..animations = (AnimationsSpecScope()
            ..colors = (AnimationOptionsScope()..to = 'transparent')
            ..visible = (AnimationOptionsScope()
              ..type = 'boolean'
              ..easing = 'linear'
              // for keeping the dataset visible all the way through the
              // animation
              ..fn = _visibleFn))),
    );
}

/// core.animations.defaults.js:19 the `_scriptable` descriptor of
/// `animation`.
bool _animationScriptable(String name) =>
    name != 'onProgress' && name != 'onComplete' && name != 'fn';

/// core.animations.defaults.js:67 the `fn` of the `visible` animation of
/// `transitions.hide`: `v => v | 0`. `v | 0` is ToInt32 of ToNumber.
double _visibleFn(Object? v) => jsToInt32(jsToNumber(v));
