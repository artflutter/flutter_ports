// Original code, not ported from Chart.js: the typed animation keys.

/// The animation keys of Chart.js ADR 0054 §10.
///
/// This library is a pure layer.
library;

import 'package:flutter_chartjs_port/src/core/core.animation.dart'
    show readProperty, writeProperty;
import 'package:flutter_chartjs_port/src/core/core.element.dart'
    show Element, ElementXProp, ElementYProp;
import 'package:flutter_chartjs_port/src/elements/element.arc.dart'
    show
        ArcCircumferenceProp,
        ArcEndAngleProp,
        ArcInnerRadiusProp,
        ArcOuterRadiusProp,
        ArcStartAngleProp;
import 'package:flutter_chartjs_port/src/elements/element.bar.dart'
    show BarBaseProp, BarHeightProp, BarWidthProp;
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsToNumber;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/element_options_base.dart'
    show ElementOptions;
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/options/property_animation.dart';
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
///
/// A built-in property of an element has an animation class
/// (`RadiusAnimation` for [radius]). The class is a type argument of its
/// instance, so [itemIn] finds the item of `ChartConfig.animations` for the
/// property by the type of the item, with no table.
///
/// A numeric property of an element class has its own class, next to the
/// element (`ElementXProp`, `BarBaseProp`, `ArcStartAngleProp`): it reads
/// and writes the field of the element with no `switch` by an id ([write],
/// [read], [markUndefined], [isUndefined]). A style property ([StyleProp]) has
/// the key of the resolved options of an element: an animation reads and
/// writes the typed field of the options ([valueOf], [store]).
@immutable
base class AnimatedProp {
  /// A built-in property with the name [name] and the index [id].
  @internal
  const AnimatedProp.builtIn(String name, this.id) : _name = name;

  /// A built-in property that gives its own [name], with the index [id].
  @internal
  const AnimatedProp.keyed(this.id) : _name = null;

  /// A name that is not built in: [id] is -1.
  const AnimatedProp.custom(String name) : _name = name, id = -1;

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

  /// The name of a property that has no typed key, or Dart `null`.
  final String? _name;

  /// The JS property name.
  String get name => _name!;

  /// The index of a built-in name in [builtIns], or -1.
  final int id;

  /// Whether the name is not built in.
  bool get isCustom => id < 0;

  /// The item of [items] that sets the animation of this property, or Dart
  /// `null`: the first item of the animation class of the property. A
  /// property with no animation class has no item.
  PropertyAnimation? itemIn(List<PropertyAnimation>? items) => null;

  /// Writes the number [value] to this property of [element]. A property
  /// class of an element writes its own field. This base writes by name.
  void write(Element element, double value) => element[name] = value;

  /// The number of this property of [element]: NaN in the `undefined`
  /// state. A property class of an element reads its own field. This base
  /// reads by name.
  double read(Element element) => jsToNumber(element[name]);

  /// Puts this property of [element] in the `undefined` state.
  void markUndefined(Element element) => element[name] = undefined;

  /// Whether this property of [element] is in the `undefined` state, or
  /// [element] does not have it.
  bool isUndefined(Element element) => identical(element[name], undefined);

  /// The value of this property of [target], the target of an animation: an
  /// element, the resolved options of an element or another object. A style
  /// property reads the typed field of the options. This base reads by
  /// name.
  Object? valueOf(Object target) => readProperty(target, name);

  /// Writes [value] to this property of [target], the target of an
  /// animation. A style property writes the typed field of the options.
  /// This base writes by name.
  void store(Object target, Object? value) =>
      writeProperty(target, name, value);

  /// `x`.
  static const AnimatedProp x = ElementXProp();

  /// `y`.
  static const AnimatedProp y = ElementYProp();

  /// `borderWidth`.
  static const AnimatedProp borderWidth = StyleProp<BorderWidthAnimation>(
    OptionKey.borderWidth,
    2,
  );

  /// `radius`.
  static const AnimatedProp radius = StyleProp<RadiusAnimation>(
    OptionKey.radius,
    3,
  );

  /// `tension`.
  static const AnimatedProp tension = StyleProp<TensionAnimation>(
    OptionKey.tension,
    4,
  );

  /// `color`.
  static const AnimatedProp color = StyleProp<ColorAnimation>(
    OptionKey.color,
    5,
  );

  /// `borderColor`.
  static const AnimatedProp borderColor = StyleProp<BorderColorAnimation>(
    OptionKey.borderColor,
    6,
  );

  /// `backgroundColor`.
  static const AnimatedProp backgroundColor =
      StyleProp<BackgroundColorAnimation>(OptionKey.backgroundColor, 7);

  /// `visible` (the transitions `show` and `hide`).
  static const AnimatedProp visible = AnimatedBy<VisibleAnimation>(
    'visible',
    8,
  );

  /// `base`.
  static const AnimatedProp base = BarBaseProp();

  /// `width`.
  static const AnimatedProp width = BarWidthProp();

  /// `height`.
  static const AnimatedProp height = BarHeightProp();

  /// `circumference`.
  static const AnimatedProp circumference = ArcCircumferenceProp();

  /// `endAngle`.
  static const AnimatedProp endAngle = ArcEndAngleProp();

  /// `innerRadius`.
  static const AnimatedProp innerRadius = ArcInnerRadiusProp();

  /// `outerRadius`.
  static const AnimatedProp outerRadius = ArcOuterRadiusProp();

  /// `startAngle`.
  static const AnimatedProp startAngle = ArcStartAngleProp();

  /// `offset`.
  static const AnimatedProp offset = StyleProp<OffsetAnimation>(
    OptionKey.offset,
    17,
  );

  /// `spacing`.
  static const AnimatedProp spacing = StyleProp<SpacingAnimation>(
    OptionKey.spacing,
    18,
  );

  /// `caretX`.
  static const AnimatedProp caretX = AnimatedProp.builtIn('caretX', 19);

  /// `caretY`.
  static const AnimatedProp caretY = AnimatedProp.builtIn('caretY', 20);

  /// `opacity`.
  static const AnimatedProp opacity = AnimatedProp.builtIn('opacity', 21);

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

/// A built-in property with the animation class [T]: the type of an item of
/// `ChartConfig.animations` selects the property.
base class AnimatedBy<T extends PropertyAnimation> extends AnimatedProp {
  /// A built-in property with the animation class [T].
  @internal
  const AnimatedBy(super.name, super.id) : super.builtIn();

  /// A built-in property with the animation class [T] that gives its own
  /// name.
  @internal
  const AnimatedBy.keyed(super.id) : super.keyed();

  @override
  PropertyAnimation? itemIn(List<PropertyAnimation>? items) {
    if (items == null) return null;
    for (final item in items) {
      if (item is T) return item;
    }
    return null;
  }
}

/// A style property of an element: a key of its resolved options
/// (`radius`, `borderColor`). An animation reads and writes the typed field
/// of the options by the key, with no name.
base class StyleProp<T extends PropertyAnimation> extends AnimatedBy<T> {
  /// The style property of the option [key].
  @internal
  const StyleProp(this.key, super.id) : super.keyed();

  /// The key of the resolved options of an element.
  final OptionKey key;

  /// The name of [key]: a style property has no name of its own.
  @override
  String get name => key.jsName;

  @override
  Object? valueOf(Object target) =>
      target is ElementOptions ? target.valueOf(key) : super.valueOf(target);

  @override
  void store(Object target, Object? value) {
    if (target is ElementOptions) {
      target.storeKey(key, value);
    } else {
      super.store(target, value);
    }
  }
}
