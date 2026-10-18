// Original code, not ported from Chart.js: tests of lib/src/js/js_function.dart.
import 'package:flutter_chartjs/src/js/js_function.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:test/test.dart';

// The JavaScript results are the rules of ECMAScript: a call ignores the extra
// arguments, and a parameter without an argument is undefined.

/// A class with a `call` method. Its instances are not Dart functions.
final class _Callable {
  Object? call(Object? value) => value;
}

/// A generic function. Its tear-off is a generic function value.
T _identity<T>(T value) => value;

/// A function with nine required positional parameters.
Object? _nine(
  Object? a,
  Object? b,
  Object? c,
  Object? d,
  Object? e,
  Object? f,
  Object? g,
  Object? h,
  Object? i,
) => i;

/// Closures with 0 to 8 required positional parameters. Each one returns the
/// list of its arguments.
final List<Function> _byArity = [
  () => <Object?>[],
  (Object? a) => [a],
  (Object? a, Object? b) => [a, b],
  (Object? a, Object? b, Object? c) => [a, b, c],
  (Object? a, Object? b, Object? c, Object? d) => [a, b, c, d],
  (Object? a, Object? b, Object? c, Object? d, Object? e) => [a, b, c, d, e],
  (Object? a, Object? b, Object? c, Object? d, Object? e, Object? f) => [
    a,
    b,
    c,
    d,
    e,
    f,
  ],
  (
    Object? a,
    Object? b,
    Object? c,
    Object? d,
    Object? e,
    Object? f,
    Object? g,
  ) => [a, b, c, d, e, f, g],
  (
    Object? a,
    Object? b,
    Object? c,
    Object? d,
    Object? e,
    Object? f,
    Object? g,
    Object? h,
  ) => [a, b, c, d, e, f, g, h],
];

/// The arguments that a JavaScript function with [arity] parameters gets from
/// a call with [args]: the first [arity] items, padded with undefined.
List<Object?> _received(List<Object?> args, int arity) => [
  for (var i = 0; i < arity; i++) i < args.length ? args[i] : undefined,
];

/// The arguments 1 to [count].
List<Object?> _args(int count) => [for (var i = 1; i <= count; i++) i];

void main() {
  group('jsIsFunction', () {
    test('is true for a Dart function and a JsFunction', () {
      expect(jsIsFunction(() {}), isTrue);
      expect(jsIsFunction((Object? a, Object? b) => a), isTrue);
      expect(jsIsFunction(identical), isTrue);
      expect(jsIsFunction(_identity), isTrue);
      expect(jsIsFunction(JsFunction((Object? self) => self)), isTrue);
    });

    test('is false for other values', () {
      expect(jsIsFunction(null), isFalse);
      expect(jsIsFunction(undefined), isFalse);
      expect(jsIsFunction(42), isFalse);
      expect(jsIsFunction('function'), isFalse);
      expect(jsIsFunction(<String, Object?>{}), isFalse);
      expect(jsIsFunction(<Object?>[]), isFalse);
      expect(jsIsFunction(_Callable()), isFalse);
    });
  });

  group('jsCall', () {
    test('passes the arguments that the function declares', () {
      expect(jsCall(() => 'none', []), 'none');
      expect(jsCall((Object? a) => a, ['a']), 'a');
      expect(
        jsCall((Object? a, Object? b, Object? c) => [a, b, c], [1, 2, 3]),
        [1, 2, 3],
      );
    });

    test('drops the arguments that the function does not declare', () {
      expect(jsCall(() => 'none', [1, 2]), 'none');
      expect(jsCall((Object? a) => a, ['a', 'b', 'c']), 'a');
      expect(
        jsCall((Object? a, Object? b) => [a, b], [
          for (var i = 0; i < 12; i++) i,
        ]),
        [0, 1],
      );
    });

    test('pads the missing arguments with undefined', () {
      expect(jsCall((Object? a) => a, []), same(undefined));
      final result = jsCall((Object? a, Object? b, Object? c) => [a, b, c], [
        1,
      ]);
      expect(result, [1, same(undefined), same(undefined)]);
    });

    test('keeps the Dart default of an optional parameter', () {
      Object? f(Object? a, [Object? b = 'default', Object? c]) => [a, b, c];
      expect(jsCall(f, []), [same(undefined), 'default', null]);
      expect(jsCall(f, [1]), [1, 'default', null]);
      expect(jsCall(f, [1, 2]), [1, 2, null]);
      expect(jsCall(f, [1, 2, 3]), [1, 2, 3]);
      expect(jsCall(f, [1, 2, 3, 4]), [1, 2, 3]);
    });

    test('accepts optional named parameters', () {
      Object? f(Object? a, {Object? named = 'named'}) => [a, named];
      expect(jsCall(f, [1, 2]), [1, 'named']);
      expect(jsCall(f, []), [same(undefined), 'named']);
    });

    test('accepts typed parameters and return types', () {
      double twice(double x) => x * 2;
      expect(jsCall(twice, [21.0, 'extra']), 42);
      var called = false;
      void effect() {
        called = true;
      }

      expect(jsCall(effect, [1]), isNull);
      expect(called, isTrue);
    });

    test('returns the result of the function as it is', () {
      expect(jsCall(() => null, []), isNull);
      expect(jsCall(() => undefined, []), same(undefined));
      final object = <String, Object?>{};
      expect(jsCall(() => object, []), same(object));
    });

    test('calls a function with jsMaxArity parameters', () {
      Object? eight(
        Object? a,
        Object? b,
        Object? c,
        Object? d,
        Object? e,
        Object? f,
        Object? g,
        Object? h,
      ) => [a, h];
      expect(jsMaxArity, 8);
      expect(jsCall(eight, [1, 2, 3, 4, 5, 6, 7, 8, 9]), [1, 8]);
      expect(jsCall(eight, [1]), [1, same(undefined)]);
    });

    test('ignores thisArg for a Dart function', () {
      expect(jsCall((Object? a) => a, ['a'], thisArg: 'this'), 'a');
    });

    test('throws for a value that is not a function', () {
      expect(() => jsCall(null, []), throwsArgumentError);
      expect(() => jsCall(undefined, []), throwsArgumentError);
      expect(() => jsCall(42, []), throwsArgumentError);
      expect(() => jsCall(_Callable(), [1]), throwsArgumentError);
    });

    test('throws for a function that it cannot call', () {
      Object? named({required Object? value}) => value;
      expect(() => jsCall(named, []), throwsArgumentError);
      expect(() => jsCall(_nine, List.filled(9, 0)), throwsArgumentError);
      expect(() => jsCall(_identity, [1]), throwsArgumentError);
    });

    test('calls an instantiated generic function', () {
      expect(jsCall(_identity<Object?>, [1, 2]), 1);
    });
  });

  group('JsFunction', () {
    test('gets thisArg as its first argument', () {
      final scope = <String, Object?>{};
      final function = JsFunction(
        (Object? self, Object? a, Object? b) => [self, a, b],
      );
      expect(jsCall(function, [1, 2], thisArg: scope), [same(scope), 1, 2]);
    });

    test('gets undefined as this without a thisArg', () {
      final function = JsFunction((Object? self) => self);
      expect(jsCall(function, []), same(undefined));
    });

    test('gets null and undefined as this, as a strict-mode function', () {
      final function = JsFunction((Object? self) => self);
      expect(jsCall(function, [], thisArg: null), isNull);
      // The explicit undefined is the point of the test.
      // ignore: avoid_redundant_argument_values
      expect(jsCall(function, [], thisArg: undefined), same(undefined));
    });

    test('drops and pads the arguments after this', () {
      final one = JsFunction((Object? self, Object? a) => [self, a]);
      expect(jsCall(one, [1, 2, 3], thisArg: 't'), ['t', 1]);
      expect(jsCall(one, [], thisArg: 't'), ['t', same(undefined)]);

      final none = JsFunction(() => 'none');
      expect(jsCall(none, [1], thisArg: 't'), 'none');
    });

    test('keeps its function', () {
      Object? f(Object? self) => self;
      expect(JsFunction(f).function, same(f));
    });
  });

  // On the VM, jsCall calls a closure that takes 0 to 4 arguments with a
  // dynamic call, and other closures with Function.apply. On the web, it
  // always uses Function.apply. These tests pin the same results for each
  // count, on both sides of the limit.
  group('jsCall by arity', () {
    test('drops, pads and passes the arguments for each arity', () {
      for (var arity = 0; arity <= jsMaxArity; arity++) {
        for (var count = 0; count <= jsMaxArity + 2; count++) {
          final args = _args(count);
          expect(
            jsCall(_byArity[arity], args),
            _received(args, arity),
            reason: 'arity $arity, $count arguments',
          );
        }
      }
    });

    test('gives this and the arguments to a JsFunction for each arity', () {
      for (var arity = 1; arity <= jsMaxArity; arity++) {
        final function = JsFunction(_byArity[arity]);
        for (var count = 0; count <= jsMaxArity + 1; count++) {
          final args = _args(count);
          expect(
            jsCall(function, args, thisArg: 't'),
            _received(['t', ...args], arity),
            reason: 'arity $arity, $count arguments, thisArg',
          );
          expect(
            jsCall(function, args),
            _received([undefined, ...args], arity),
            reason: 'arity $arity, $count arguments, no thisArg',
          );
        }
      }
    });

    test('calls a JsFunction that does not take this', () {
      expect(jsCall(JsFunction(_byArity[0]), [1, 2], thisArg: 't'), isEmpty);
    });

    test('does not change the arguments', () {
      for (var arity = 0; arity <= jsMaxArity; arity++) {
        final args = List<Object?>.unmodifiable(_args(3));
        jsCall(_byArity[arity], args);
        jsCall(JsFunction(_byArity[arity == 0 ? 1 : arity]), args);
        expect(args, [1, 2, 3]);
      }
    });

    test('keeps the Dart defaults of optional parameters past 4', () {
      Object? f(
        Object? a,
        Object? b,
        Object? c, [
        Object? d = 'd',
        Object? e = 'e',
        Object? f,
      ]) => [a, b, c, d, e, f];
      const u = undefined;
      expect(jsCall(f, []), [u, u, u, 'd', 'e', null]);
      expect(jsCall(f, [1, 2, 3]), [1, 2, 3, 'd', 'e', null]);
      expect(jsCall(f, [1, 2, 3, 4]), [1, 2, 3, 4, 'e', null]);
      expect(jsCall(f, [1, 2, 3, 4, 5]), [1, 2, 3, 4, 5, null]);
      expect(jsCall(f, _args(8)), [1, 2, 3, 4, 5, 6]);

      final g = JsFunction(f);
      expect(jsCall(g, [], thisArg: 't'), ['t', u, u, 'd', 'e', null]);
      expect(jsCall(g, [1, 2, 3], thisArg: 't'), ['t', 1, 2, 3, 'e', null]);
      expect(jsCall(g, [1, 2, 3, 4], thisArg: 't'), ['t', 1, 2, 3, 4, null]);
    });

    test('passes NaN, -0 and the number types as they are', () {
      for (final arity in [4, 5]) {
        final result =
            jsCall(_byArity[arity], [double.nan, -0.0, 1, 1.5])! as List;
        expect(result[0], isNaN, reason: 'arity $arity');
        expect(result[1], isZero, reason: 'arity $arity');
        expect(
          (result[1]! as double).isNegative,
          isTrue,
          reason: 'arity $arity',
        );
        expect(result[2], same(1), reason: 'arity $arity');
        expect(result[3], 1.5, reason: 'arity $arity');
      }
    });

    test('throws a TypeError for an argument of a wrong type', () {
      double one(double x) => x;
      double five(Object? a, Object? b, Object? c, Object? d, double x) => x;
      expect(() => jsCall(one, ['1']), throwsA(isA<TypeError>()));
      expect(() => jsCall(five, [1, 2, 3, 4, '5']), throwsA(isA<TypeError>()));
      expect(
        () => jsCall(JsFunction((Object? self, double x) => x), ['1']),
        throwsA(isA<TypeError>()),
      );
      expect(jsCall(one, [2.5]), 2.5);
      expect(jsCall(five, [1, 2, 3, 4, 2.5]), 2.5);
    });

    test('throws for a JsFunction with a required named parameter', () {
      final function = JsFunction(
        (Object? self, {required Object? value}) => value,
      );
      expect(() => jsCall(function, [1], thisArg: 't'), throwsArgumentError);
    });
  });
  group('jsCall1', () {
    test('gives the jsCall result for each arity', () {
      final functions = <Function>[
        () => 'none',
        (Object? a) => [a],
        (Object? a, Object? b) => [a, b],
        (Object? a, [Object? b = 'default']) => [a, b],
        ([Object? a = 'default']) => [a],
        (Object? a, Object? b, Object? c, Object? d, Object? e) => [
          a,
          b,
          c,
          d,
          e,
        ],
      ];
      for (final function in functions) {
        expect(jsCall1(function, 'x'), jsCall(function, ['x']));
      }
      expect(jsCall1((Object? a) => a, 'x'), 'x');
      expect(jsCall1((Object? a, Object? b) => b, 'x'), same(undefined));
      expect(jsCall1(([Object? a = 'default']) => a, 'x'), 'x');
    });

    test('passes NaN, -0, null and undefined as they are', () {
      Object? id(Object? a) => a;
      expect(jsCall1(id, double.nan), isNaN);
      expect((jsCall1(id, -0.0)! as double).isNegative, isTrue);
      expect(jsCall1(id, null), isNull);
      expect(jsCall1(id, undefined), same(undefined));
      expect(jsCall1(id, 1), same(1));
    });

    test('gives this to a JsFunction and ignores it for a Dart function', () {
      final function = JsFunction((Object? self, Object? a) => [self, a]);
      expect(jsCall1(function, 'x', thisArg: 't'), ['t', 'x']);
      expect(jsCall1(function, 'x'), [undefined, 'x']);
      expect(jsCall1((Object? a) => a, 'x', thisArg: 't'), 'x');
    });

    test('throws the jsCall errors', () {
      double one(double x) => x;
      expect(() => jsCall1(one, '1'), throwsA(isA<TypeError>()));
      expect(jsCall1(one, 2.5), 2.5);
      expect(() => jsCall1('f', 'x'), throwsArgumentError);
      expect(() => jsCall1(null, 'x'), throwsArgumentError);
      expect(() => jsCall1(_Callable(), 'x'), throwsArgumentError);
      expect(
        () => jsCall1(({required Object? value}) => value, 'x'),
        throwsArgumentError,
      );
    });
  });
}
