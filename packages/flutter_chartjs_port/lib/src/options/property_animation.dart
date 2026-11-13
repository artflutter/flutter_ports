// Original code, not ported from Chart.js: the animation of one property.

/// The animation of single properties of the elements and of the update
/// modes: the items of `ChartConfig.animations` and of
/// `ChartConfig.transitions` (row `adapt-property-animations`).
///
/// Each property of an element that Chart.js animates has one ready class,
/// for example [RadiusAnimation] and [BorderColorAnimation]. A class has no
/// name of a property and no key. An item sets the length, the wait, the
/// curve and the repeat of the animation of its property. A parameter that
/// is `null` takes the value that the property has without the item. The
/// constructor `off` turns the animation of the property off: it is the
/// duration 0. A List has one item for each class.
///
/// An item goes to the animations of a chart as the object that the app
/// made: `ChartView` gives the List to the chart, which keeps it in a field
/// ([ChartAnimationItems]), and `Animation` of `core.animation.dart` reads
/// the fields of the item. No option scope holds a copy.
///
/// This library is a core layer: it imports `package:flutter/animation.dart`
/// for [Curve] only.
library;

import 'package:flutter/animation.dart' show Curve;
import 'package:meta/meta.dart';

/// The four parameters of an animation: the base of each object of the app
/// that sets an animation (an item of `ChartConfig.animations`, an item of
/// `ChartConfig.transitions` and the `ChartAnimation` of
/// `ChartConfig.animation`). `Animation` of `core.animation.dart` reads the
/// object itself. No option holds a copy of a parameter.
@immutable
abstract class AnimationSettings {
  /// The parameters of an animation.
  const AnimationSettings({this.duration, this.delay, this.easing, this.loop});

  /// The length of the animation.
  final Duration? duration;

  /// The wait before the animation starts.
  final Duration? delay;

  /// The curve of the animation, a Flutter [Curve].
  final Curve? easing;

  /// Whether the animation repeats without end.
  final bool? loop;
}

/// The animation of one property of the elements: an item of
/// `ChartConfig.animations`. Each property has its ready class. The type of
/// an item names its property: an item has no other name of it.
///
/// Another library can add a class for a property of its own element. The
/// chart does not read such an item: the library that made the class finds
/// its items in the List by their type.
abstract class PropertyAnimation extends AnimationSettings {
  /// The animation options of one property.
  const PropertyAnimation({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyAnimation &&
          other.runtimeType == runtimeType &&
          other.duration == duration &&
          other.delay == delay &&
          other.easing == easing &&
          other.loop == loop;

  @override
  int get hashCode => Object.hash(runtimeType, duration, delay, easing, loop);
}

/// The animation of `x`: the horizontal position of an element.
final class XAnimation extends PropertyAnimation {
  /// The animation options of `x`.
  const XAnimation({super.duration, super.delay, super.easing, super.loop});

  /// No animation of `x`: a change shows at once. It is the
  /// duration 0.
  const XAnimation.off() : super(duration: Duration.zero);
}

/// The animation of `y`: the vertical position of an element.
final class YAnimation extends PropertyAnimation {
  /// The animation options of `y`.
  const YAnimation({super.duration, super.delay, super.easing, super.loop});

  /// No animation of `y`: a change shows at once. It is the
  /// duration 0.
  const YAnimation.off() : super(duration: Duration.zero);
}

/// The animation of `base`: the base of a bar.
final class BaseAnimation extends PropertyAnimation {
  /// The animation options of `base`.
  const BaseAnimation({super.duration, super.delay, super.easing, super.loop});

  /// No animation of `base`: a change shows at once. It is the
  /// duration 0.
  const BaseAnimation.off() : super(duration: Duration.zero);
}

/// The animation of `width`: the width of a bar.
final class WidthAnimation extends PropertyAnimation {
  /// The animation options of `width`.
  const WidthAnimation({super.duration, super.delay, super.easing, super.loop});

  /// No animation of `width`: a change shows at once. It is the
  /// duration 0.
  const WidthAnimation.off() : super(duration: Duration.zero);
}

/// The animation of `height`: the height of a bar.
final class HeightAnimation extends PropertyAnimation {
  /// The animation options of `height`.
  const HeightAnimation({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
  });

  /// No animation of `height`: a change shows at once. It is the
  /// duration 0.
  const HeightAnimation.off() : super(duration: Duration.zero);
}

/// The animation of `radius`: the radius of a point.
final class RadiusAnimation extends PropertyAnimation {
  /// The animation options of `radius`.
  const RadiusAnimation({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
  });

  /// No animation of `radius`: a change shows at once. It is the
  /// duration 0.
  const RadiusAnimation.off() : super(duration: Duration.zero);
}

/// The animation of `borderWidth`: the width of the border of an element.
final class BorderWidthAnimation extends PropertyAnimation {
  /// The animation options of `borderWidth`.
  const BorderWidthAnimation({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
  });

  /// No animation of `borderWidth`: a change shows at once. It is the
  /// duration 0.
  const BorderWidthAnimation.off() : super(duration: Duration.zero);
}

/// The animation of `tension`: the tension of the curve of a line.
final class TensionAnimation extends PropertyAnimation {
  /// The animation options of `tension`.
  const TensionAnimation({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
  });

  /// No animation of `tension`: a change shows at once. It is the
  /// duration 0.
  const TensionAnimation.off() : super(duration: Duration.zero);
}

/// The animation of `color`: the text color.
final class ColorAnimation extends PropertyAnimation {
  /// The animation options of `color`.
  const ColorAnimation({super.duration, super.delay, super.easing, super.loop});

  /// No animation of `color`: a change shows at once. It is the
  /// duration 0.
  const ColorAnimation.off() : super(duration: Duration.zero);
}

/// The animation of `borderColor`: the color of the border of an element.
final class BorderColorAnimation extends PropertyAnimation {
  /// The animation options of `borderColor`.
  const BorderColorAnimation({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
  });

  /// No animation of `borderColor`: a change shows at once. It is the
  /// duration 0.
  const BorderColorAnimation.off() : super(duration: Duration.zero);
}

/// The animation of `backgroundColor`: the fill color of an element.
final class BackgroundColorAnimation extends PropertyAnimation {
  /// The animation options of `backgroundColor`.
  const BackgroundColorAnimation({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
  });

  /// No animation of `backgroundColor`: a change shows at once. It is the
  /// duration 0.
  const BackgroundColorAnimation.off() : super(duration: Duration.zero);
}

/// The animation of `visible`: whether a dataset shows.
final class VisibleAnimation extends PropertyAnimation {
  /// The animation options of `visible`.
  const VisibleAnimation({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
  });

  /// No animation of `visible`: a change shows at once. It is the
  /// duration 0.
  const VisibleAnimation.off() : super(duration: Duration.zero);
}

/// The animation of `startAngle`: the start angle of an arc.
final class StartAngleAnimation extends PropertyAnimation {
  /// The animation options of `startAngle`.
  const StartAngleAnimation({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
  });

  /// No animation of `startAngle`: a change shows at once. It is the
  /// duration 0.
  const StartAngleAnimation.off() : super(duration: Duration.zero);
}

/// The animation of `endAngle`: the end angle of an arc.
final class EndAngleAnimation extends PropertyAnimation {
  /// The animation options of `endAngle`.
  const EndAngleAnimation({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
  });

  /// No animation of `endAngle`: a change shows at once. It is the
  /// duration 0.
  const EndAngleAnimation.off() : super(duration: Duration.zero);
}

/// The animation of `circumference`: the circumference of an arc.
final class CircumferenceAnimation extends PropertyAnimation {
  /// The animation options of `circumference`.
  const CircumferenceAnimation({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
  });

  /// No animation of `circumference`: a change shows at once. It is the
  /// duration 0.
  const CircumferenceAnimation.off() : super(duration: Duration.zero);
}

/// The animation of `innerRadius`: the inner radius of an arc.
final class InnerRadiusAnimation extends PropertyAnimation {
  /// The animation options of `innerRadius`.
  const InnerRadiusAnimation({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
  });

  /// No animation of `innerRadius`: a change shows at once. It is the
  /// duration 0.
  const InnerRadiusAnimation.off() : super(duration: Duration.zero);
}

/// The animation of `outerRadius`: the outer radius of an arc.
final class OuterRadiusAnimation extends PropertyAnimation {
  /// The animation options of `outerRadius`.
  const OuterRadiusAnimation({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
  });

  /// No animation of `outerRadius`: a change shows at once. It is the
  /// duration 0.
  const OuterRadiusAnimation.off() : super(duration: Duration.zero);
}

/// The animation of `offset`: the offset of an arc from the center.
final class OffsetAnimation extends PropertyAnimation {
  /// The animation options of `offset`.
  const OffsetAnimation({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
  });

  /// No animation of `offset`: a change shows at once. It is the
  /// duration 0.
  const OffsetAnimation.off() : super(duration: Duration.zero);
}

/// The animation of `spacing`: the space between two arcs.
final class SpacingAnimation extends PropertyAnimation {
  /// The animation options of `spacing`.
  const SpacingAnimation({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
  });

  /// No animation of `spacing`: a change shows at once. It is the
  /// duration 0.
  const SpacingAnimation.off() : super(duration: Duration.zero);
}

/// The animation of one update mode of a chart: an item of
/// `ChartConfig.transitions`. Each mode has its ready class. The type of an
/// item names its mode.
///
/// A parameter that is not `null` goes before the parameter of
/// `ChartConfig.animation` in that mode. [animations] sets single properties
/// in that mode, and goes before `ChartConfig.animations`. A List has one
/// item for each class.
abstract class ChartTransition extends AnimationSettings {
  /// The animation options of one update mode.
  const ChartTransition({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
    this.animations,
  });

  /// The animation of single properties in this mode. Each property has its
  /// ready class ([PropertyAnimation]).
  final List<PropertyAnimation>? animations;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartTransition &&
          other.runtimeType == runtimeType &&
          other.duration == duration &&
          other.delay == delay &&
          other.easing == easing &&
          other.loop == loop &&
          _sameItems(other.animations, animations);

  @override
  int get hashCode => Object.hash(
    runtimeType,
    duration,
    delay,
    easing,
    loop,
    animations == null ? null : Object.hashAll(animations!),
  );
}

/// Whether [a] and [b] are both `null`, or have equal items in the same
/// order.
bool _sameItems(List<PropertyAnimation>? a, List<PropertyAnimation>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The animation of the update mode `active`: an element is active, for
/// example the pointer is over it.
final class HoverTransition extends ChartTransition {
  /// The animation options of the mode `active`.
  const HoverTransition({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
    super.animations,
  });

  /// No animation in the mode `active`: a change shows at once. It is the
  /// duration 0.
  const HoverTransition.off() : super(duration: Duration.zero);
}

/// The animation of the update mode `show`: a dataset shows again.
final class ShowTransition extends ChartTransition {
  /// The animation options of the mode `show`.
  const ShowTransition({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
    super.animations,
  });

  /// No animation in the mode `show`: a change shows at once. It is the
  /// duration 0.
  const ShowTransition.off() : super(duration: Duration.zero);
}

/// The animation of the update mode `hide`: a dataset hides.
final class HideTransition extends ChartTransition {
  /// The animation options of the mode `hide`.
  const HideTransition({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
    super.animations,
  });

  /// No animation in the mode `hide`: a change shows at once. It is the
  /// duration 0.
  const HideTransition.off() : super(duration: Duration.zero);
}

/// The animation of the update mode `resize`: the chart changes its size.
final class ResizeTransition extends ChartTransition {
  /// The animation options of the mode `resize`.
  const ResizeTransition({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
    super.animations,
  });

  /// No animation in the mode `resize`: a change shows at once. It is the
  /// duration 0.
  const ResizeTransition.off() : super(duration: Duration.zero);
}

/// The animation of the update mode `reset`: the chart resets.
final class ResetTransition extends ChartTransition {
  /// The animation options of the mode `reset`.
  const ResetTransition({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
    super.animations,
  });

  /// No animation in the mode `reset`: a change shows at once. It is the
  /// duration 0.
  const ResetTransition.off() : super(duration: Duration.zero);
}

/// The update mode of the class of [transition], as `Chart.update` names
/// it, or Dart `null` for a class of another library.
@internal
String? transitionModeOf(ChartTransition transition) => switch (transition) {
  HoverTransition() => 'active',
  ShowTransition() => 'show',
  HideTransition() => 'hide',
  ResizeTransition() => 'resize',
  ResetTransition() => 'reset',
  _ => null,
};

/// The item of [transitions] for the update mode [mode], or Dart `null`:
/// the object that the app made.
@internal
ChartTransition? transitionIn(
  List<ChartTransition>? transitions,
  String? mode,
) {
  if (transitions == null || mode == null) return null;
  for (final transition in transitions) {
    if (transitionModeOf(transition) == mode) return transition;
  }
  return null;
}

/// A chart that holds the items of the app as its own fields. `Chart` of
/// `core.controller.dart` implements it.
abstract interface class ChartAnimationItems {
  /// The items of `ChartConfig.animations`, or Dart `null`.
  List<PropertyAnimation>? get propertyAnimations;

  /// The items of `ChartConfig.transitions`, or Dart `null`.
  List<ChartTransition>? get chartTransitions;
}
