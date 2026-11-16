// Ported from d3-interpolate v3.0.1 test/value-test.js (ISC, Mike Bostock).
import 'dart:typed_data';

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

/// `assert.deepStrictEqual` of two typed arrays: the same class and the same
/// items.
Matcher _typedEquals<T extends List<num>>(T expected) =>
    allOf(isA<T>(), equals(expected));

void main() {
  test(
    'interpolate(a, b) interpolates strings if b is a string and not a color',
    () {
      // assert.strictEqual(interpolate("foo", "bar")(0.5), "bar");
      //
      // A String has no interpolator: interpolateString has no Dart form,
      // and interpolate throws an ArgumentError for a String.
    },
    skip: 'diverges: adapt-interpolate-typed-values',
  );

  test('interpolate(a, b) interpolates strings if b is a string and not a '
      'color, even if b is coercible to a number', () {
    // assert.strictEqual(interpolate("1", "2")(0.5), "1.5");
    // assert.strictEqual(interpolate(" 1", " 2")(0.5), " 1.5");
    //
    // A String has no interpolator: interpolateString has no Dart form.
  }, skip: 'diverges: adapt-interpolate-typed-values');

  test(
    'interpolate(a, b) interpolates RGB colors if b is a string and a color',
    () {
      // The CSS texts convert at the call site with color(text)!, and the
      // result is an Rgb, whose text is the upstream result
      // (adapt-interpolate-color-values).
      String mix(String a, String b) =>
          interpolate<Color>(color(a)!, color(b)!)(0.5).toString();
      expect(mix('red', 'blue'), 'rgb(128, 0, 128)');
      expect(mix('#ff0000', '#0000ff'), 'rgb(128, 0, 128)');
      expect(mix('#f00', '#00f'), 'rgb(128, 0, 128)');
      expect(mix('rgb(255, 0, 0)', 'rgb(0, 0, 255)'), 'rgb(128, 0, 128)');
      expect(
        mix('rgba(255, 0, 0, 1.0)', 'rgba(0, 0, 255, 1.0)'),
        'rgb(128, 0, 128)',
      );
      expect(mix('rgb(100%, 0%, 0%)', 'rgb(0%, 0%, 100%)'), 'rgb(128, 0, 128)');
      expect(
        mix('rgba(100%, 0%, 0%, 1.0)', 'rgba(0%, 0%, 100%, 1.0)'),
        'rgb(128, 0, 128)',
      );
      expect(
        mix('rgba(100%, 0%, 0%, 0.5)', 'rgba(0%, 0%, 100%, 0.7)'),
        'rgba(128, 0, 128, 0.6)',
      );
    },
  );

  test('interpolate(a, b) interpolates RGB colors if b is a color', () {
    expect(
      interpolate<Color>(color('red')!, Rgb.parse('blue'))(0.5).toString(),
      'rgb(128, 0, 128)',
    );
    expect(
      interpolate<Color>(color('red')!, Hsl.parse('blue'))(0.5).toString(),
      'rgb(128, 0, 128)',
    );
  });

  test('interpolate(a, b) interpolates arrays if b is an array', () {
    expect(
      interpolate<List<Color>>([color('red')!], [color('blue')!])(0.5)
          .map((c) => c.toString()),
      ['rgb(128, 0, 128)'],
    );
  });

  test('interpolate(a, b) interpolates arrays if b is an array, even if b is '
      'coercible to a number', () {
    expect(interpolate<List<double>>([1], [2])(0.5), [1.5]);
  });

  test('interpolate(a, b) interpolates numbers if b is a number', () {
    expect(interpolate<double>(1, 2)(0.5), 1.5);
    expect(interpolate<double>(1, double.nan)(0.5), isNaN);
  });

  test('interpolate(a, b) interpolates objects if b is an object that is not '
      'coercible to a number', () {
    // assert.deepStrictEqual(
    //   interpolate({color: "red"}, {color: "blue"})(0.5),
    //   {color: "rgb(128, 0, 128)"});
    //
    // A Map has no interpolator: interpolateObject has no Dart form, and
    // interpolate throws an ArgumentError for a Map.
  }, skip: 'diverges: adapt-interpolate-typed-values');

  test('interpolate(a, b) interpolates numbers if b is an object that is '
      'coercible to a number', () {
    // assert.strictEqual(interpolate(1, new Number(2))(0.5), 1.5);
    // assert.strictEqual(interpolate(1, new String("2"))(0.5), 1.5);
    //
    // Dart has no wrapper objects and no valueOf: a number is a double.
  }, skip: 'diverges: adapt-interpolate-typed-values');

  test('interpolate(a, b) interpolates dates if b is a date', () {
    final i = interpolate(DateTime(2000), DateTime(2000, 1, 2));
    final d = i(0.5);
    expect(d, isA<DateTime>());
    expect(i(0.5), DateTime(2000, 1, 1, 12));
  });

  test('interpolate(a, b) returns the constant b if b is null, undefined or a '
      'boolean', () {
    expect(interpolate<Object?>(0.0, null)(0.5), isNull);
    // assert.strictEqual(interpolate(0, undefined)(0.5), undefined);
    //
    // Dart has no undefined (adapt-interpolate-typed-values).
    expect(interpolate<Object>(0.0, true)(0.5), isTrue);
    expect(interpolate<Object>(0.0, false)(0.5), isFalse);
  });

  test('interpolate(a, b) interpolates objects without prototype', () {
    // assert.deepStrictEqual(
    //   interpolate(noproto({foo: 0}), noproto({foo: 2}))(0.5), {foo: 1});
    //
    // Dart has no objects without prototype and no interpolateObject.
  }, skip: 'diverges: adapt-interpolate-typed-values');

  test(
    'interpolate(a, b) interpolates objects with numeric valueOf as numbers',
    () {
      // const proto = {valueOf: foo};
      // assert.deepStrictEqual(
      //   interpolate(noproto({foo: 0}, proto), noproto({foo: 2}, proto))(0.5),
      //   1);
      //
      // Dart has no valueOf coercion: a number is a double.
    },
    skip: 'diverges: adapt-interpolate-typed-values',
  );

  test('interpolate(a, b) interpolates objects with string valueOf as numbers '
      'if valueOf result is coercible to number', () {
    // const proto = {valueOf: fooString};
    // assert.deepStrictEqual(
    //   interpolate(noproto({foo: 0}, proto), noproto({foo: 2}, proto))(0.5),
    //   1);
    //
    // Dart has no valueOf coercion: a number is a double.
  }, skip: 'diverges: adapt-interpolate-typed-values');

  test('interpolate(a, b) interpolates objects with string valueOf as objects '
      'if valueOf result is not coercible to number', () {
    // const proto = {valueOf: fooString};
    // assert.deepStrictEqual(
    //   interpolate(noproto({foo: "bar"}, proto),
    //     noproto({foo: "baz"}, proto))(0.5),
    //   {foo: "baz", valueOf: {}});
    //
    // Dart has no valueOf coercion and no interpolateObject.
  }, skip: 'diverges: adapt-interpolate-typed-values');

  test('interpolate(a, b) interpolates objects with toString as numbers if '
      'toString result is coercible to number', () {
    // const proto = {toString: fooString};
    // assert.deepStrictEqual(
    //   interpolate(noproto({foo: 0}, proto), noproto({foo: 2}, proto))(0.5),
    //   1);
    //
    // Dart has no toString coercion to a number: a number is a double.
  }, skip: 'diverges: adapt-interpolate-typed-values');

  test('interpolate(a, b) interpolates objects with toString as objects if '
      'toString result is not coercible to number', () {
    // const proto = {toString: fooString};
    // assert.deepStrictEqual(
    //   interpolate(noproto({foo: "bar"}, proto),
    //     noproto({foo: "baz"}, proto))(0.5),
    //   {foo: "baz", toString: {}});
    //
    // Dart has no toString coercion and no interpolateObject.
  }, skip: 'diverges: adapt-interpolate-typed-values');

  test(
    'interpolate(a, b) interpolates number arrays if b is a typed array',
    () {
      expect(
        interpolate<List<num>>([0, 0], Float64List.fromList([-1, 1]))(0.5),
        _typedEquals(Float64List.fromList([-0.5, 0.5])),
      );
      expect(
        interpolate<List<num>>([0, 0], Float64List.fromList([-1, 1]))(0.5),
        isA<Float64List>(),
      );
      expect(
        interpolate<List<num>>([0, 0], Float32List.fromList([-1, 1]))(0.5),
        _typedEquals(Float32List.fromList([-0.5, 0.5])),
      );
      expect(
        interpolate<List<num>>([0, 0], Float32List.fromList([-1, 1]))(0.5),
        isA<Float32List>(),
      );
      // Uint32Array.of(-2, 2) and Uint32List.fromList([-2, 2]) both hold
      // [2^32 - 2, 2]; the result is [2^31 - 1, 1].
      expect(
        interpolate<List<num>>([0, 0], Uint32List.fromList([-2, 2]))(0.5),
        _typedEquals(Uint32List.fromList([2147483647, 1])),
      );
      expect(
        interpolate<List<num>>([0, 0], Uint32List.fromList([-1, 1]))(0.5),
        isA<Uint32List>(),
      );
      expect(
        interpolate<List<num>>([0, 0], Uint8List.fromList([-2, 2]))(0.5),
        _typedEquals(Uint8List.fromList([127, 1])),
      );
      expect(
        interpolate<List<num>>([0, 0], Uint8List.fromList([-1, 1]))(0.5),
        isA<Uint8List>(),
      );
    },
  );
}
