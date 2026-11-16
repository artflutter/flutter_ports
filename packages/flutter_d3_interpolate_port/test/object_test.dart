// Ported from d3-interpolate v3.0.1 test/object-test.js (ISC, Mike Bostock).
import 'package:test/test.dart';

// src/object.js has no Dart form: the generic interpolate takes typed values
// only (adapt-interpolate-typed-values). Each case keeps its name and its
// body as a comment (D3 ADR 0009 §1).

void main() {
  test(
    'interpolateObject(a, b) interpolates defined properties in a and b',
    () {
      // assert.deepStrictEqual(
      //   interpolateObject({a: 2, b: 12}, {a: 4, b: 24})(0.5), {a: 3, b: 18});
      //
      // interpolateObject has no Dart form.
    },
    skip: 'diverges: adapt-interpolate-typed-values',
  );

  test('interpolateObject(a, b) interpolates inherited properties in a '
      'and b', () {
    // function a(a) { this.a = a; }
    // a.prototype.b = 12;
    // assert.deepStrictEqual(
    //   interpolateObject(new a(2), {a: 4, b: 12})(0.5), {a: 3, b: 12});
    // assert.deepStrictEqual(
    //   interpolateObject({a: 2, b: 12}, new a(4))(0.5), {a: 3, b: 12});
    // assert.deepStrictEqual(
    //   interpolateObject(new a(4), new a(2))(0.5), {a: 3, b: 12});
    //
    // interpolateObject has no Dart form.
  }, skip: 'diverges: adapt-interpolate-typed-values');

  test('interpolateObject(a, b) interpolates color properties as rgb', () {
    // assert.deepStrictEqual(
    //   interpolateObject({background: "red"}, {background: "green"})(0.5),
    //   {background: "rgb(128, 64, 0)"});
    // assert.deepStrictEqual(
    //   interpolateObject({fill: "red"}, {fill: "green"})(0.5),
    //   {fill: "rgb(128, 64, 0)"});
    // assert.deepStrictEqual(
    //   interpolateObject({stroke: "red"}, {stroke: "green"})(0.5),
    //   {stroke: "rgb(128, 64, 0)"});
    // assert.deepStrictEqual(
    //   interpolateObject({color: "red"}, {color: "green"})(0.5),
    //   {color: "rgb(128, 64, 0)"});
    //
    // interpolateObject has no Dart form.
  }, skip: 'diverges: adapt-interpolate-typed-values');

  test('interpolateObject(a, b) interpolates nested objects and arrays', () {
    // assert.deepStrictEqual(
    //   interpolateObject({foo: [2, 12]}, {foo: [4, 24]})(0.5),
    //   {foo: [3, 18]});
    // assert.deepStrictEqual(
    //   interpolateObject({foo: {bar: [2, 12]}}, {foo: {bar: [4, 24]}})(0.5),
    //   {foo: {bar: [3, 18]}});
    //
    // interpolateObject has no Dart form.
  }, skip: 'diverges: adapt-interpolate-typed-values');

  test('interpolateObject(a, b) ignores properties in a that are not in b', () {
    // assert.deepStrictEqual(
    //   interpolateObject({foo: 2, bar: 12}, {foo: 4})(0.5), {foo: 3});
    //
    // interpolateObject has no Dart form.
  }, skip: 'diverges: adapt-interpolate-typed-values');

  test('interpolateObject(a, b) uses constant properties in b that are '
      'not in a', () {
    // assert.deepStrictEqual(
    //   interpolateObject({foo: 2}, {foo: 4, bar: 12})(0.5),
    //   {foo: 3, bar: 12});
    //
    // interpolateObject has no Dart form.
  }, skip: 'diverges: adapt-interpolate-typed-values');

  test('interpolateObject(a, b) treats undefined as an empty object', () {
    // assert.deepStrictEqual(interpolateObject(NaN, {foo: 2})(0.5), {foo: 2});
    // assert.deepStrictEqual(interpolateObject({foo: 2}, undefined)(0.5), {});
    // assert.deepStrictEqual(interpolateObject(undefined, {foo: 2})(0.5),
    //   {foo: 2});
    // assert.deepStrictEqual(interpolateObject({foo: 2}, null)(0.5), {});
    // assert.deepStrictEqual(interpolateObject(null, {foo: 2})(0.5), {foo: 2});
    // assert.deepStrictEqual(interpolateObject(null, NaN)(0.5), {});
    //
    // interpolateObject has no Dart form.
  }, skip: 'diverges: adapt-interpolate-typed-values');

  test('interpolateObject(a, b) interpolates objects without prototype', () {
    // assert.deepStrictEqual(
    //   interpolateObject(noproto({foo: 0}), noproto({foo: 2}))(0.5),
    //   {foo: 1});
    //
    // interpolateObject has no Dart form.
  }, skip: 'diverges: adapt-interpolate-typed-values');
}
