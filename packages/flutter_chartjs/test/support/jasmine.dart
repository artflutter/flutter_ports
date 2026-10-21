// Original code, not ported from Chart.js: Jasmine matchers and spies.

/// The Jasmine matchers and spies of the spec ports (Chart.js ADR 0030,
/// section 13).
///
/// The Chart.js lockfile pins jasmine-core 3.99.1
/// (`third_party/Chart.js/pnpm-lock.yaml:9733`). The doc comments name the
/// Jasmine semantics of that version. This library copies no jasmine-core
/// source.
///
/// - [jasmineEquals] (`toEqual`), [objectContaining]
///   (`jasmine.objectContaining`) and [anyFunction] (`jasmine.any(Function)`).
///   [JasmineOptions] gives a resolver to `expect`.
/// - [spyOn], [JasmineSpy], [JasmineSpyStrategy], [spyOf],
///   [toHaveBeenCalled] and [JasmineSpyCalls]: the spy of a function value
///   in a Map.
/// - [JasmineCalls]: `spy.calls`.
/// - [spyOnElementDraw], [spyOnDataset] and [spyOnArrayListener]: the spy of
///   a method. A Dart object cannot replace one of its methods. Thus a spy
///   object takes the slot that the library reads: `meta.data[index]`,
///   `meta.dataset`, or the listeners of a data array.
///
/// This library is a helper of the specs, not a test file. It imports only
/// pure layers and `package:test`. Thus a pure spec can import it.
library;

import 'package:flutter_chartjs/src/canvas/canvas.dart'
    show CanvasRenderingContext2D;
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/elements/element.arc.dart';
import 'package:flutter_chartjs/src/elements/element.bar.dart';
import 'package:flutter_chartjs/src/elements/element.line.dart';
import 'package:flutter_chartjs/src/elements/element.point.dart';
import 'package:flutter_chartjs/src/helpers/helpers.collection.dart'
    show ArrayListener, listenArrayEvents, unlistenArrayEvents;
import 'package:flutter_chartjs/src/helpers/helpers.config.dart'
    show ContextResolver, Resolver;
import 'package:flutter_chartjs/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs/src/js/js_function.dart'
    show JsFunction, jsCall, jsIsFunction;
import 'package:flutter_chartjs/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs/src/js/js_undefined.dart' show undefined;
import 'package:flutter_chartjs/src/types/geometric.dart' show ChartArea;
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// The matchers.

/// A resolver of helpers.config as the actual value of an `expect`.
///
/// A failed `expect` prints its actual value with `prettyPrint`, which
/// reads each key of [Map.keys], the `ownKeys` trap. The `ownKeys` trap of
/// a scale resolver also gives the keys of its fallback scopes, as upstream:
/// the keys of `options.grid` include `grid`. Thus the print of the
/// resolver does not stop, and the test does not end. Jasmine prints to a
/// depth of 8 only. A [JasmineOptions] prints the `Object.keys`
/// ([jsObjectKeys]) of its resolver. [jasmineEquals] and [objectContaining]
/// compare the resolver in it.
final class JasmineOptions {
  /// The resolver [resolver] as an actual value.
  const JasmineOptions(this.resolver);

  /// The resolver.
  final Map<String, Object?> resolver;

  @override
  String toString() => 'resolver {${jsObjectKeys(resolver).join(', ')}}';
}

/// The value that a matcher compares: the resolver of a [JasmineOptions],
/// else [item].
Object? _actual(Object? item) => item is JasmineOptions ? item.resolver : item;

/// `Object.prototype.hasOwnProperty.call(object, key)`: for a resolver, its
/// `getOwnPropertyDescriptor` trap.
bool _hasOwnProperty(Map<String, Object?> object, String key) =>
    switch (object) {
      final Resolver resolver => resolver.hasOwnProperty(key),
      final ContextResolver resolver => resolver.hasOwnProperty(key),
      _ => object.containsKey(key),
    };

/// Jasmine `toEqual(expected)`: the deep equality `MatchersUtil.eq` of
/// jasmine-core 3.99.1, for the values of the specs.
///
/// - Two numbers are equal when both are NaN, or when they have the same
///   value. A zero equals only a zero with the same sign.
/// - Two strings compare by value. Other values that are not objects or
///   arrays compare by identity: booleans, functions, `null` and
///   [undefined].
/// - Two arrays are equal when they have the same length and equal items.
/// - Two objects are equal when they have the same `Object.keys`
///   ([jsObjectKeys]) and equal values. An object is a Map, also a resolver
///   of helpers.config. A value is the property read `object[key]`
///   ([jsGet]), the `get` trap of a resolver. Thus two resolvers that are
///   not identical can be equal.
/// - Jasmine keeps a stack of the objects that it compares, for cyclic
///   values. This matcher keeps the same stack.
///
/// The actual value can be a [JasmineOptions].
Matcher jasmineEquals(Object? expected) => _JasmineEquals(expected);

final class _JasmineEquals extends Matcher {
  const _JasmineEquals(this.expected);

  final Object? expected;

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    final path = <String>[];
    final pass = _eq(_actual(item), expected, [], [], path);
    if (!pass) matchState['path'] = path.isEmpty ? '(root)' : path.join('.');
    return pass;
  }

  @override
  Description describe(Description description) =>
      description.add('a value equal to the expected value (Jasmine eq)');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) => mismatchDescription.add('is different at ${matchState['path']}');

  /// The recursion of `eq`. [path] gets the keys to the first difference.
  static bool _eq(
    Object? a,
    Object? b,
    List<Object?> aStack,
    List<Object?> bStack,
    List<String> path,
  ) {
    if (a is num && b is num) {
      if (a.isNaN || b.isNaN) return a.isNaN && b.isNaN;
      return a == b && (a != 0 || a.isNegative == b.isNegative);
    }
    if (identical(a, b)) return true;
    if (a is String && b is String) return a == b;
    final List<String> keys;
    switch ((a, b)) {
      case (final List<Object?> aList, final List<Object?> bList):
        if (aList.length != bList.length) return false;
        keys = [for (var i = 0; i < aList.length; i++) '$i'];
      case (
        final Map<String, Object?> aMap,
        final Map<String, Object?> bMap,
      ):
        keys = jsObjectKeys(aMap);
        final bKeys = jsObjectKeys(bMap);
        if (keys.length != bKeys.length) return false;
        for (final key in keys) {
          if (!bKeys.contains(key)) {
            path.add(key);
            return false;
          }
        }
      default:
        return false;
    }
    for (var i = aStack.length - 1; i >= 0; i--) {
      if (identical(aStack[i], a)) return identical(bStack[i], b);
    }
    aStack.add(a);
    bStack.add(b);
    for (final key in keys) {
      path.add(key);
      if (!_eq(jsGet(a, key), jsGet(b, key), aStack, bStack, path)) {
        return false;
      }
      path.removeLast();
    }
    aStack.removeLast();
    bStack.removeLast();
    return true;
  }
}

/// `jasmine.objectContaining(expected)`: each key of [expected] is a
/// property of the actual object, with a value that is equal by Jasmine
/// `eq` ([jasmineEquals]).
///
/// Jasmine finds the property with `hasProperty`: `hasOwnProperty`, then
/// the prototype chain.
/// - For a Map, `hasOwnProperty` is [Map.containsKey]. For a resolver, it
///   is the `getOwnPropertyDescriptor` trap. It is not [Map.containsKey],
///   the `has` trap of the `in` operator: the `has` trap rejects the keys
///   that start with `_`, for example `_jasmineCheckA`. A Map has no
///   prototype chain (the row `js-semantics-resolver-objects`).
/// - For the [ElementProps] of `getProps` (core.element.ts:39), a property
///   is a read that does not give [undefined]. `getProps` writes each
///   property that it reads, so an expected key with a defined value has
///   the same result.
///
/// The actual value can be a [JasmineOptions].
Matcher objectContaining(Map<String, Object?> expected) =>
    _JasmineObjectContaining(expected);

final class _JasmineObjectContaining extends Matcher {
  const _JasmineObjectContaining(this.expected);

  final Map<String, Object?> expected;

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    final object = _actual(item);
    if (object is! Map<String, Object?> && object is! ElementProps) {
      return false;
    }
    for (final MapEntry(:key, :value) in expected.entries) {
      final path = <String>[key];
      final (has, actual) = switch (object) {
        final Map<String, Object?> map => (
          _hasOwnProperty(map, key),
          jsGet(map, key),
        ),
        final ElementProps props => (
          !identical(props[key], undefined),
          props[key],
        ),
        _ => (false, null),
      };
      if (!has || !_JasmineEquals._eq(value, actual, [], [], path)) {
        matchState['path'] = path.join('.');
        return false;
      }
    }
    return true;
  }

  @override
  Description describe(Description description) => description.add(
    'an object that contains the expected properties (Jasmine '
    'objectContaining)',
  );

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) => matchState.containsKey('path')
      ? mismatchDescription.add('is different at ${matchState['path']}')
      : mismatchDescription.add('is not an object');
}

/// `jasmine.any(Function)`: a function value, `typeof value ===
/// 'function'` ([jsIsFunction]): a Dart function, a [JsFunction] or a class
/// value.
const Matcher anyFunction = _AnyFunction();

final class _AnyFunction extends Matcher {
  const _AnyFunction();

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) =>
      jsIsFunction(item);

  @override
  Description describe(Description description) =>
      description.add('a function (jasmine.any(Function))');
}

// ---------------------------------------------------------------------------
// The calls of a spy.

/// One call that a Jasmine spy recorded: `this` and the arguments.
typedef JasmineCall = ({Object? object, List<Object?> args});

/// `spy.calls` of Jasmine: the calls of a spy, in order.
final class JasmineCalls {
  final List<JasmineCall> _all = [];

  /// Records a call with the arguments [args] and the receiver [object].
  void add(List<Object?> args, {Object? object}) =>
      _all.add((object: object, args: args));

  /// `calls.count()`.
  int count() => _all.length;

  /// `calls.argsFor(index)`.
  List<Object?> argsFor(int index) => _all[index].args;

  /// `calls.allArgs()`.
  List<List<Object?>> allArgs() => [for (final call in _all) call.args];

  /// `calls.mostRecent()`.
  JasmineCall mostRecent() => _all.last;

  /// `calls.first()`.
  JasmineCall first() => _all.first;

  /// `calls.reset()`.
  void reset() => _all.clear();
}

// ---------------------------------------------------------------------------
// The spy of a function value.

/// The marker of an argument that a call did not pass.
const Object _none = Object();

/// A Jasmine spy of [spyOn]: a function value that records the arguments
/// of each call and returns [undefined], or the result of the original
/// function after `and.callThrough()`.
final class JasmineSpy {
  JasmineSpy._(this._original);

  /// The function value that the spy replaces.
  final Object? _original;

  bool _callThrough = false;

  /// `spy.calls`.
  final JasmineCalls calls = JasmineCalls();

  /// `spy.and`: the strategy of the spy.
  late final JasmineSpyStrategy and = JasmineSpyStrategy._(this);

  /// The function value of the spy. A call gets up to three arguments.
  late final JsFunction function = JsFunction((
    Object? self, [
    Object? a = _none,
    Object? b = _none,
    Object? c = _none,
  ]) {
    final args = [a, b, c].where((arg) => !identical(arg, _none)).toList();
    calls.add(args, object: self);
    return _callThrough ? jsCall(_original, args, thisArg: self) : undefined;
  });
}

/// `spy.and` of a [JasmineSpy].
final class JasmineSpyStrategy {
  JasmineSpyStrategy._(this._spy);

  final JasmineSpy _spy;

  /// `and.callThrough()`: each call also calls the original function, with
  /// the same `this` and arguments, and returns its result.
  void callThrough() => _spy._callThrough = true;
}

/// The spy of each function value of [spyOn].
final Expando<JasmineSpy> _spies = Expando('spy');

/// `spyOn(object, method)`: replaces `object[method]` with a spy, a
/// function value.
JasmineSpy spyOn(Map<String, Object?> object, String method) {
  final spy = JasmineSpy._(object[method]);
  object[method] = spy.function;
  _spies[spy.function] = spy;
  return spy;
}

/// The spy of the function value [value]. As in Jasmine, a value that is not
/// a spy throws.
JasmineSpy spyOf(Object? value) =>
    (value is JsFunction ? _spies[value] : null) ??
    (throw ArgumentError.value(value, 'value', 'is not a spy'));

/// The read `object.method.calls` of a spied function value.
extension JasmineSpyCalls on Object? {
  /// `spy.calls`.
  JasmineCalls get calls => spyOf(this).calls;
}

/// `toHaveBeenCalled()`: the value is a spy with at least one call.
Matcher toHaveBeenCalled() => predicate<Object?>(
  (actual) => spyOf(actual).calls.count() > 0,
  'a spy that has been called',
);

// ---------------------------------------------------------------------------
// The spies of the methods of an element.

/// The properties that a draw spy copies from the original element: the
/// properties of the base class, then those of the class of the element.
/// A property in the `undefined` state stays in that state.
///
/// Upstream, `spyOn` keeps the same object, so a running animation moves
/// the spied element. The spy is a new object, and the target of an
/// `Animation` stays the original element. Thus the spy would keep stale
/// values. An element with a running animation throws a [StateError]: a
/// spy needs `animation: false` (the default of `acquireChart`) or the end
/// of the animations.
void _copyProperties(Element from, Element to, List<String> keys) {
  final running = [
    for (final MapEntry(:key, :value) in (from.$animations ?? const {}).entries)
      if (value.active()) key,
  ];
  if (running.isNotEmpty) {
    throw StateError(
      'A draw spy of an element with running animations of $running: the '
      'animations would move the original element, not the spy.',
    );
  }
  to
    ..active = from.active
    ..options = from.options
    ..hidden = from.hidden;
  for (final key in ['x', 'y', r'$animations', ...keys]) {
    final value = from[key];
    if (!identical(value, undefined)) to[key] = value;
  }
}

/// The class properties of a point that a spy copies.
const List<String> _pointKeys = [
  'parsed',
  'skip',
  'stop',
  'cp1x',
  'cp1y',
  'cp2x',
  'cp2y',
  'angle',
];

/// The class properties of a bar that a spy copies.
const List<String> _barKeys = [
  'horizontal',
  'base',
  'width',
  'height',
  'inflateAmount',
  'borderSkipped',
  'enableBorderRadius',
];

/// The class properties of an arc that a spy copies.
const List<String> _arcKeys = [
  'circumference',
  'endAngle',
  'fullCircles',
  'innerRadius',
  'outerRadius',
  'pixelMargin',
  'startAngle',
  'circular',
];

/// The class properties of a line that a spy copies. `points` gives a new
/// typed copy and drops the segments, the path and the state of the control
/// points, as the setter does.
const List<String> _lineKeys = [
  '_chart',
  '_datasetIndex',
  '_decimated',
  '_loop',
  '_fullLoop',
  'points',
];

/// The draw spy of a point: `spyOn(point, 'draw')`.
final class _PointDrawSpy extends PointElement {
  _PointDrawSpy(PointElement of, {required this.callThrough}) {
    _copyProperties(of, this, _pointKeys);
  }

  /// `.and.callThrough()`.
  final bool callThrough;

  /// `element.draw.calls`.
  final JasmineCalls calls = JasmineCalls();

  @override
  void draw(CanvasRenderingContext2D ctx, [ChartArea? area]) {
    calls.add([ctx, area], object: this);
    if (callThrough) super.draw(ctx, area);
  }
}

/// The draw spy of a bar: `spyOn(bar, 'draw')`.
final class _BarDrawSpy extends BarElement {
  _BarDrawSpy(BarElement of, {required this.callThrough}) {
    _copyProperties(of, this, _barKeys);
  }

  /// `.and.callThrough()`.
  final bool callThrough;

  /// `element.draw.calls`.
  final JasmineCalls calls = JasmineCalls();

  @override
  void draw(CanvasRenderingContext2D ctx, [ChartArea? area]) {
    calls.add([ctx, area], object: this);
    if (callThrough) super.draw(ctx, area);
  }
}

/// The draw spy of an arc: `spyOn(arc, 'draw')`.
final class _ArcDrawSpy extends ArcElement {
  _ArcDrawSpy(ArcElement of, {required this.callThrough}) {
    _copyProperties(of, this, _arcKeys);
  }

  /// `.and.callThrough()`.
  final bool callThrough;

  /// `element.draw.calls`.
  final JasmineCalls calls = JasmineCalls();

  @override
  void draw(CanvasRenderingContext2D ctx, [ChartArea? area]) {
    calls.add([ctx, area], object: this);
    if (callThrough) super.draw(ctx, area);
  }
}

/// The spy of a line: `spyOn(line, 'draw')` and
/// `spyOn(line, 'updateControlPoints')`.
final class _LineSpy extends LineElement {
  _LineSpy(LineElement of, {required this.callThrough}) {
    _copyProperties(of, this, _lineKeys);
  }

  /// `.and.callThrough()`.
  final bool callThrough;

  /// `line.draw.calls`.
  final JasmineCalls draws = JasmineCalls();

  /// `line.updateControlPoints.calls`.
  final JasmineCalls updates = JasmineCalls();

  @override
  void draw(
    CanvasRenderingContext2D ctx, [
    ChartArea? area,
    double? start,
    double? count,
  ]) {
    draws.add([ctx, area, start, count], object: this);
    if (callThrough) super.draw(ctx, area, start, count);
  }

  @override
  void updateControlPoints(ChartArea chartArea, [String? indexAxis]) {
    updates.add([chartArea, indexAxis], object: this);
    if (callThrough) super.updateControlPoints(chartArea, indexAxis);
  }
}

/// `spyOn(meta.data[index], 'draw')`: a draw spy of the class of the
/// element takes the slot. [callThrough] is `.and.callThrough()`.
///
/// The spy copies the properties of the element: `active`, `options`,
/// `hidden`, `x`, `y`, `$animations` and the properties of its class. An
/// element with a running animation throws a [StateError]: the animation
/// would move the original element, not the spy.
/// `DatasetController.draw` calls the draw of the object in the slot
/// (core.datasetController.js:712-741), and an update keeps the slot. The
/// element must be a `PointElement`, a `BarElement` or an `ArcElement`.
JasmineCalls spyOnElementDraw(
  types.ChartMeta meta,
  int index, {
  bool callThrough = false,
}) {
  final element = meta.data[index];
  switch (element) {
    case final PointElement point:
      final spy = _PointDrawSpy(point, callThrough: callThrough);
      meta.data[index] = spy;
      return spy.calls;
    case final BarElement bar:
      final spy = _BarDrawSpy(bar, callThrough: callThrough);
      meta.data[index] = spy;
      return spy.calls;
    case final ArcElement arc:
      final spy = _ArcDrawSpy(arc, callThrough: callThrough);
      meta.data[index] = spy;
      return spy.calls;
    default:
      throw ArgumentError.value(element, 'meta.data[$index]', 'No draw spy');
  }
}

/// `spyOn(meta.dataset, method)` for `'draw'` and `'updateControlPoints'`:
/// one line spy takes the slot `meta.dataset`. The calls of each method.
/// [callThrough] is `.and.callThrough()` for both methods. A line with a
/// running animation throws a [StateError], as in [spyOnElementDraw].
({JasmineCalls draw, JasmineCalls updateControlPoints}) spyOnDataset(
  types.ChartMeta meta, {
  bool callThrough = false,
}) {
  final line = meta.dataset;
  if (line is! LineElement) {
    throw ArgumentError.value(line, 'meta.dataset', 'Not a line element');
  }
  final spy = _LineSpy(line, callThrough: callThrough);
  meta.dataset = spy;
  return (draw: spy.draws, updateControlPoints: spy.updates);
}

// ---------------------------------------------------------------------------
// The spy of the array listener of a controller.

/// The listener of [spyOnArrayListener]: it records each `_onData*` call.
final class _ArrayListenerSpy with ArrayListener<Object?> {
  _ArrayListenerSpy(this._of, {required this.callThrough});

  final ArrayListener<Object?> _of;

  /// `.and.callThrough()`.
  final bool callThrough;

  /// The calls by method name.
  final Map<String, JasmineCalls> calls = {
    for (final name in const [
      '_onDataPush',
      '_onDataPop',
      '_onDataShift',
      '_onDataSplice',
      '_onDataUnshift',
    ])
      name: JasmineCalls(),
  };

  @override
  void onDataPush(List<Object?> items) {
    calls['_onDataPush']!.add(items, object: _of);
    if (callThrough) _of.onDataPush(items);
  }

  @override
  void onDataPop() {
    calls['_onDataPop']!.add(const [], object: _of);
    if (callThrough) _of.onDataPop();
  }

  @override
  void onDataShift() {
    calls['_onDataShift']!.add(const [], object: _of);
    if (callThrough) _of.onDataShift();
  }

  @override
  void onDataSplice(double index, double deleteCount, List<Object?> items) {
    calls['_onDataSplice']!.add([index, deleteCount, ...items], object: _of);
    if (callThrough) _of.onDataSplice(index, deleteCount, items);
  }

  @override
  void onDataUnshift(List<Object?> items) {
    calls['_onDataUnshift']!.add(items, object: _of);
    if (callThrough) _of.onDataUnshift(items);
  }
}

/// `spyOn(controller, '_onData<X>')` for the 5 array methods: a listener
/// takes the place of [controller] in the listeners of [data]. The calls
/// by method name (`'_onDataPush'` and so on). `addTearDown` puts the
/// controller back. [callThrough] is `.and.callThrough()`.
///
/// The spy is the last listener of [data]: a chart has one listener for
/// each data array (core.datasetController.js:386-388). A listener that a
/// Jasmine spy replaces keeps its place.
///
/// The parameter type is the [ArrayListener] mixin of helpers.collection,
/// a pure layer: `DatasetController` mixes in `ArrayListener<Object?>`.
Map<String, JasmineCalls> spyOnArrayListener(
  List<Object?> data,
  ArrayListener<Object?> controller, {
  bool callThrough = false,
}) {
  final spy = _ArrayListenerSpy(controller, callThrough: callThrough);
  unlistenArrayEvents(data, controller);
  listenArrayEvents(data, spy);
  addTearDown(() {
    unlistenArrayEvents(data, spy);
    listenArrayEvents(data, controller);
  });
  return spy.calls;
}
