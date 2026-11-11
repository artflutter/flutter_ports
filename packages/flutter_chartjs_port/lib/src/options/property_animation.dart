// Original code, not ported from Chart.js: the animation of one property.

/// The animation of single properties of the elements: the items of
/// `ChartConfig.animations` (row `adapt-property-animations`).
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
/// made: `ChartView` puts the List on the canvas ([setPropertyAnimations]),
/// and `Animation` of `core.animation.dart` reads the fields of the item.
/// No option scope holds a copy.
///
/// This library is a core layer: it imports `package:flutter/animation.dart`
/// for [Curve] only.
library;

import 'package:flutter/animation.dart' show Curve;
import 'package:flutter_chartjs_port/src/options/animated_prop.dart'
    show AnimatedProp;
import 'package:meta/meta.dart';

/// The animation of one property of the elements: an item of
/// `ChartConfig.animations`. Each property has its ready class.
@immutable
sealed class PropertyAnimation {
  /// The animation options of one property.
  const PropertyAnimation({this.duration, this.delay, this.easing, this.loop});

  /// The length of the animation.
  final Duration? duration;

  /// The wait before the animation starts.
  final Duration? delay;

  /// The curve of the animation, a Flutter [Curve].
  final Curve? easing;

  /// Whether the animation repeats without end.
  final bool? loop;

  /// The property that this class animates. Each class of this library
  /// gives its own, and no other library sees the member.
  AnimatedProp get _property;

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
  const XAnimation({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
  });

  /// No animation of `x`: a change shows at once. It is the
  /// duration 0.
  const XAnimation.off() : super(duration: Duration.zero);

  @override
  AnimatedProp get _property => AnimatedProp.x;
}

/// The animation of `y`: the vertical position of an element.
final class YAnimation extends PropertyAnimation {
  /// The animation options of `y`.
  const YAnimation({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
  });

  /// No animation of `y`: a change shows at once. It is the
  /// duration 0.
  const YAnimation.off() : super(duration: Duration.zero);

  @override
  AnimatedProp get _property => AnimatedProp.y;
}

/// The animation of `base`: the base of a bar.
final class BaseAnimation extends PropertyAnimation {
  /// The animation options of `base`.
  const BaseAnimation({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
  });

  /// No animation of `base`: a change shows at once. It is the
  /// duration 0.
  const BaseAnimation.off() : super(duration: Duration.zero);

  @override
  AnimatedProp get _property => AnimatedProp.base;
}

/// The animation of `width`: the width of a bar.
final class WidthAnimation extends PropertyAnimation {
  /// The animation options of `width`.
  const WidthAnimation({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
  });

  /// No animation of `width`: a change shows at once. It is the
  /// duration 0.
  const WidthAnimation.off() : super(duration: Duration.zero);

  @override
  AnimatedProp get _property => AnimatedProp.width;
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

  @override
  AnimatedProp get _property => AnimatedProp.height;
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

  @override
  AnimatedProp get _property => AnimatedProp.radius;
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

  @override
  AnimatedProp get _property => AnimatedProp.borderWidth;
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

  @override
  AnimatedProp get _property => AnimatedProp.tension;
}

/// The animation of `color`: the text color.
final class ColorAnimation extends PropertyAnimation {
  /// The animation options of `color`.
  const ColorAnimation({
    super.duration,
    super.delay,
    super.easing,
    super.loop,
  });

  /// No animation of `color`: a change shows at once. It is the
  /// duration 0.
  const ColorAnimation.off() : super(duration: Duration.zero);

  @override
  AnimatedProp get _property => AnimatedProp.color;
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

  @override
  AnimatedProp get _property => AnimatedProp.borderColor;
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

  @override
  AnimatedProp get _property => AnimatedProp.backgroundColor;
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

  @override
  AnimatedProp get _property => AnimatedProp.visible;
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

  @override
  AnimatedProp get _property => AnimatedProp.startAngle;
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

  @override
  AnimatedProp get _property => AnimatedProp.endAngle;
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

  @override
  AnimatedProp get _property => AnimatedProp.circumference;
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

  @override
  AnimatedProp get _property => AnimatedProp.innerRadius;
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

  @override
  AnimatedProp get _property => AnimatedProp.outerRadius;
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

  @override
  AnimatedProp get _property => AnimatedProp.offset;
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

  @override
  AnimatedProp get _property => AnimatedProp.spacing;
}

/// The property that the class of [animation] animates.
@internal
AnimatedProp animatedPropertyOf(PropertyAnimation animation) =>
    animation._property;

/// The items of the canvas of each chart.
final Expando<List<PropertyAnimation>> _ofCanvas =
    Expando<List<PropertyAnimation>>('property animations');

/// Gives the chart on [canvas] the items [animations], or no item for Dart
/// `null`. Only `ChartView` calls it, with `ChartConfig.animations`.
///
/// The List is keyed by the canvas, so that the first `update()` of the
/// constructor of a chart reads it.
@internal
void setPropertyAnimations(Object canvas, List<PropertyAnimation>? animations) {
  _ofCanvas[canvas] = animations;
}

/// The items of the chart on [canvas], or Dart `null`.
@internal
List<PropertyAnimation>? propertyAnimationsOf(Object? canvas) =>
    canvas == null ? null : _ofCanvas[canvas];
