// Original code, not ported from Chart.js: the option groups of the typed API.

/// The option groups of the typed API (Chart.js ADR 0052, sections 1 and
/// 6): the options [ChartInteraction] and [ChartAnimation] of
/// `ChartConfig`. The options of the seven built-in plugins are one
/// `TitleOptions`, `SubtitleOptions`, `LegendOptions`, `TooltipOptions`,
/// `DecimationOptions`, `FillerOptions` and `ColorsPluginOptions` in
/// `ChartConfig.pluginOptions` (Chart.js ADRs 0192, 0193, 0194, 0196 and
/// 0197).
///
/// The callbacks of a group get one details object. The chart calls the
/// callback of the newest config: `==` of a group compares a callback only
/// by its presence, so a new closure in each build does not update the
/// chart.
library;

import 'package:flutter/animation.dart' show Curve;
import 'package:flutter/foundation.dart'
    show DiagnosticPropertiesBuilder, Diagnosticable, immutable;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The interaction: which elements an event hits, `options.interaction`
/// (`docs/configuration/interactions.md`).
///
/// The hover, the click callbacks and the tooltip read it.
@immutable
final class const ChartInteraction({
  /// The elements that an event hits: `mode`. The default is
  /// `NearestInteractionMode()`.
  final InteractionMode? mode,

  /// Whether an event hits only the elements under the pointer:
  /// `intersect`. The default is `true`.
  final bool? intersect,

  /// The axes of the distance from the event to an element: `axis`. The
  /// default is [InteractionAxis.x] for the mode index and
  /// [InteractionAxis.xy] for the other modes.
  final InteractionAxis? axis,

  /// Whether an event also hits the elements outside the chart area:
  /// `includeInvisible`. The default is `false`.
  final bool? includeInvisible,

  /// The Chart.js interaction options that have no parameter.
  ///
  /// The entries go into the interaction Map last: an entry wins over a
  /// parameter with the same key. A Map value merges into the Map of the
  /// key, a List or another value replaces it. The chart gets a copy of
  /// each Map and the Lists of the app.
  final Map<String, Object?>? extra,
}) with Diagnosticable {
  /// The interaction options.
  this;

  /// A copy of these interaction options with the given parameters. A
  /// parameter that is `null` keeps its value.
  ChartInteraction copyWith({
    InteractionMode? mode,
    bool? intersect,
    InteractionAxis? axis,
    bool? includeInvisible,
    Map<String, Object?>? extra,
  }) => ChartInteraction(
    mode: mode ?? this.mode,
    intersect: intersect ?? this.intersect,
    axis: axis ?? this.axis,
    includeInvisible: includeInvisible ?? this.includeInvisible,
    extra: extra ?? this.extra,
  );

  List<TypedProperty> get _props => [
    ('mode', mode),
    ('intersect', intersect),
    ('axis', axis),
    ('includeInvisible', includeInvisible),
    ('extra', byEntries(extra)),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartInteraction && propsEqual(_props, other._props);

  @override
  int get hashCode => propsHash(_props);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, _props);
  }
}

/// The `interaction` scope of [interaction].
InteractionOptionsScope lowerInteraction(ChartInteraction interaction) {
  final scope = InteractionOptionsScope();
  put(scope, OptionKey.mode, interaction.mode);
  put(scope, OptionKey.intersect, interaction.intersect);
  put(scope, OptionKey.axis, interaction.axis);
  put(scope, OptionKey.includeInvisible, interaction.includeInvisible);
  return mergeExtra(scope, interaction.extra);
}

/// The animation of the chart: `options.animation`
/// (`docs/configuration/animations.md`).
///
/// [ChartAnimation.none] turns the animations off: `animation: false`.
@immutable
final class ChartAnimation extends AnimationSettings with Diagnosticable {
  /// The animation options: the length `duration` (the default is 1000
  /// milliseconds), the wait `delay`, the curve `easing` (a Flutter [Curve],
  /// the default is `Curves.easeOutQuart`), the repeat `loop`, and the
  /// `animateScale` and `animateRotate` of the doughnut, pie and polar area
  /// charts.
  ///
  /// A constant of `Curves` and a `const` curve of the app compare by
  /// identity. A curve that `build` makes anew at each call is a new value,
  /// and it gives a chart update, unless its class has `==`.
  const new({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
    this.animateScale,
    this.animateRotate,
    this.onProgress,
    this.onComplete,
    this.extra,
  }) : _none = false;

  const new _none()
    : animateScale = null,
      animateRotate = null,
      onProgress = null,
      onComplete = null,
      extra = null,
      _none = true;

  /// No animation: `animation: false`. A change of the data then shows at
  /// once. Its copies are [none] too.
  static const ChartAnimation none = ChartAnimation._none();

  /// Whether the doughnut, pie and polar area charts grow their arcs from
  /// the center at the start: `animateScale`. The default is `false` for
  /// doughnut and pie, and `true` for polar area.
  final bool? animateScale;

  /// Whether the doughnut, pie and polar area charts turn their arcs from
  /// the start angle at the start: `animateRotate`. The default is `true`.
  final bool? animateRotate;

  /// The function of each step of the animations: `onProgress`.
  final AnimationEventHandler? onProgress;

  /// The function of the end of the animations: `onComplete`.
  final AnimationEventHandler? onComplete;

  /// The Chart.js animation options that have no parameter. The rules of
  /// [ChartInteraction.extra] apply.
  final Map<String, Object?>? extra;

  /// Whether this is [none].
  final bool _none;

  /// A copy of these animation options with the given parameters. A
  /// parameter that is `null` keeps its value. A copy of [none] is [none].
  ChartAnimation copyWith({
    Duration? duration,
    Duration? delay,
    Curve? easing,
    bool? loop,
    bool? animateScale,
    bool? animateRotate,
    AnimationEventHandler? onProgress,
    AnimationEventHandler? onComplete,
    Map<String, Object?>? extra,
  }) => _none
      ? none
      : ChartAnimation(
          duration: duration ?? this.duration,
          delay: delay ?? this.delay,
          easing: easing ?? this.easing,
          loop: loop ?? this.loop,
          animateScale: animateScale ?? this.animateScale,
          animateRotate: animateRotate ?? this.animateRotate,
          onProgress: onProgress ?? this.onProgress,
          onComplete: onComplete ?? this.onComplete,
          extra: extra ?? this.extra,
        );

  List<TypedProperty> get _props => [
    if (_none) ('none', true),
    ('duration', duration),
    ('delay', delay),
    ('easing', easing),
    ('loop', loop),
    ('animateScale', animateScale),
    ('animateRotate', animateRotate),
    ('onProgress', byPresence(onProgress)),
    ('onComplete', byPresence(onComplete)),
    ('extra', byEntries(extra)),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartAnimation &&
          other._none == _none &&
          propsEqual(_props, other._props);

  @override
  int get hashCode => propsHash(_props);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, _props);
  }
}

/// Gives [scope] each parameter of [settings] that is not `null`:
/// `duration`, `delay`, `easing` and `loop` (row
/// adapt-animation-option-types). A `Duration` goes as its milliseconds, the
/// unit of the options.
void _putSettings(AnimationOptionsScope scope, AnimationSettings settings) {
  if (settings.duration case final duration?) {
    scope.duration = duration.inMicroseconds / 1000;
  }
  if (settings.delay case final delay?) {
    scope.delay = delay.inMicroseconds / 1000;
  }
  if (settings.easing case final easing?) scope.easing = easing;
  if (settings.loop case final loop?) scope.loop = loop;
}

/// The `transitions` option of [transitions]: for each item with a
/// parameter, the scope of its update mode with the item itself in the cell
/// of each parameter. Dart `null` when no item has a parameter.
///
/// The items of `ChartTransition.animations` are not in the options: the
/// animations of the chart read them from the item.
TransitionsSpecScope? lowerTransitions(List<ChartTransition> transitions) {
  TransitionsSpecScope? spec;
  final modes = <String>{};
  for (final transition in transitions) {
    final mode = transitionModeOf(transition);
    // A class of another library: that library reads its items.
    if (mode == null) continue;
    assert(
      modes.add(mode),
      'ChartConfig.transitions has two items of the class '
      '${transition.runtimeType}. Give one item for each class.',
    );
    final animation = AnimationOptionsScope();
    _putSettings(animation, transition);
    if (animation.ownKeyCount == 0) continue;
    (spec ??= TransitionsSpecScope()).store(
      mode,
      OptScope<TransitionOptionsScope>(
        TransitionOptionsScope()..animation = animation,
      ),
    );
  }
  return spec;
}

/// The `animation` option of a dataset: `false` for [ChartAnimation.none],
/// else an `AnimationOptionsScope` with the settings of [animation].
/// `onProgress` and `onComplete` are options of the chart: a dataset gives
/// none.
Object lowerDatasetAnimation(ChartAnimation animation) {
  assert(
    animation.onProgress == null && animation.onComplete == null,
    'onProgress and onComplete are options of ChartConfig.animation.',
  );
  if (animation._none) return false;
  final scope = AnimationOptionsScope();
  _putSettings(scope, animation);
  if (animation.animateScale case final animateScale?) {
    scope.animateScale = animateScale;
  }
  if (animation.animateRotate case final animateRotate?) {
    scope.animateRotate = animateRotate;
  }
  return mergeExtra(scope, animation.extra);
}

/// The `animation` option of [animation]: `false` for
/// [ChartAnimation.none], else an `AnimationOptionsScope`. The scope has no
/// copy of `duration`, `delay`, `easing` and `loop`: each of these cells
/// holds [animation], the object of the app. `animateScale` and
/// `animateRotate` go as their bools. The callbacks
/// lower to trampolines that call the callback of the newest config of
/// [lowering].
Object lowerAnimation(ChartAnimation animation, ChartConfigLowering lowering) {
  if (animation._none) return false;
  final scope = AnimationOptionsScope();
  _putSettings(scope, animation);
  if (animation.animateScale case final animateScale?) {
    scope.animateScale = animateScale;
  }
  if (animation.animateRotate case final animateRotate?) {
    scope.animateRotate = animateRotate;
  }
  if (animation.onProgress != null) {
    scope.onProgress = animationTrampoline(
      () => lowering.config.animation?.onProgress,
    );
  }
  if (animation.onComplete != null) {
    scope.onComplete = animationTrampoline(
      () => lowering.config.animation?.onComplete,
    );
  }
  return mergeExtra(scope, animation.extra);
}
