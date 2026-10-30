// Original code, not ported from Chart.js: the typed animation keys.

/// The animation keys of Chart.js ADR 0054 §10.
///
/// This library is a pure layer.
library;

import 'package:meta/meta.dart';

/// The name of an animated property, with an `id` for the `switch` of a
/// target class (an element or a resolved options object).
///
/// The built-in names have `const` instances: the names of U
/// `core.animations.defaults.js:1-2` and of its transitions, and the
/// `properties` of the controllers and of the tooltip (U
/// `controller.bar.js:276`, `controller.doughnut.js:56`,
/// `controller.polarArea.js:20`, `controller.bubble.js:18`,
/// `plugin.tooltip.js:1317`). [AnimatedProp.of] maps a name of a raw
/// `properties` list to its instance. Another name gives
/// [AnimatedProp.custom], whose [id] is -1: a target reads and writes it by
/// name. There is no intern table.
@immutable
final class AnimatedProp {
  const AnimatedProp._(this.name, this.id);

  /// A name that is not built in: [id] is -1.
  const AnimatedProp.custom(this.name) : id = -1;

  /// The instance of the name [name]: a built-in instance, or a new
  /// [AnimatedProp.custom].
  factory AnimatedProp.of(String name) => switch (name) {
    'x' => x,
    'y' => y,
    'borderWidth' => borderWidth,
    'radius' => radius,
    'tension' => tension,
    'color' => color,
    'borderColor' => borderColor,
    'backgroundColor' => backgroundColor,
    'visible' => visible,
    'base' => base,
    'width' => width,
    'height' => height,
    'circumference' => circumference,
    'endAngle' => endAngle,
    'innerRadius' => innerRadius,
    'outerRadius' => outerRadius,
    'startAngle' => startAngle,
    'offset' => offset,
    'spacing' => spacing,
    'caretX' => caretX,
    'caretY' => caretY,
    'opacity' => opacity,
    _ => AnimatedProp.custom(name),
  };

  /// The JS property name.
  final String name;

  /// The index of a built-in name in [builtIns], or -1.
  final int id;

  /// Whether the name is not built in.
  bool get isCustom => id < 0;

  /// `x`.
  static const AnimatedProp x = AnimatedProp._('x', 0);

  /// `y`.
  static const AnimatedProp y = AnimatedProp._('y', 1);

  /// `borderWidth`.
  static const AnimatedProp borderWidth = AnimatedProp._('borderWidth', 2);

  /// `radius`.
  static const AnimatedProp radius = AnimatedProp._('radius', 3);

  /// `tension`.
  static const AnimatedProp tension = AnimatedProp._('tension', 4);

  /// `color`.
  static const AnimatedProp color = AnimatedProp._('color', 5);

  /// `borderColor`.
  static const AnimatedProp borderColor = AnimatedProp._('borderColor', 6);

  /// `backgroundColor`.
  static const AnimatedProp backgroundColor = AnimatedProp._(
    'backgroundColor',
    7,
  );

  /// `visible` (the transitions `show` and `hide`).
  static const AnimatedProp visible = AnimatedProp._('visible', 8);

  /// `base`.
  static const AnimatedProp base = AnimatedProp._('base', 9);

  /// `width`.
  static const AnimatedProp width = AnimatedProp._('width', 10);

  /// `height`.
  static const AnimatedProp height = AnimatedProp._('height', 11);

  /// `circumference`.
  static const AnimatedProp circumference = AnimatedProp._('circumference', 12);

  /// `endAngle`.
  static const AnimatedProp endAngle = AnimatedProp._('endAngle', 13);

  /// `innerRadius`.
  static const AnimatedProp innerRadius = AnimatedProp._('innerRadius', 14);

  /// `outerRadius`.
  static const AnimatedProp outerRadius = AnimatedProp._('outerRadius', 15);

  /// `startAngle`.
  static const AnimatedProp startAngle = AnimatedProp._('startAngle', 16);

  /// `offset`.
  static const AnimatedProp offset = AnimatedProp._('offset', 17);

  /// `spacing`.
  static const AnimatedProp spacing = AnimatedProp._('spacing', 18);

  /// `caretX`.
  static const AnimatedProp caretX = AnimatedProp._('caretX', 19);

  /// `caretY`.
  static const AnimatedProp caretY = AnimatedProp._('caretY', 20);

  /// `opacity`.
  static const AnimatedProp opacity = AnimatedProp._('opacity', 21);

  /// The built-in names, by [id].
  static const List<AnimatedProp> builtIns = [
    x,
    y,
    borderWidth,
    radius,
    tension,
    color,
    borderColor,
    backgroundColor,
    visible,
    base,
    width,
    height,
    circumference,
    endAngle,
    innerRadius,
    outerRadius,
    startAngle,
    offset,
    spacing,
    caretX,
    caretY,
    opacity,
  ];

  /// Two instances are equal when their names are equal.
  @override
  bool operator ==(Object other) => other is AnimatedProp && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'AnimatedProp($name)';
}
