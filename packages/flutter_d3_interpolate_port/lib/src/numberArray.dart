// Ported from d3-interpolate v3.0.1 src/numberArray.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/numberArray.js` of d3-interpolate 3.0.1: the interpolator of
/// two lists of numbers.
library;

import 'dart:math' as math;
import 'dart:typed_data';

/// numberArray.js:1 the default export, as array.js and value.js import it
/// (`numberArray`): the interpolator from the numbers of [a] to the numbers
/// of [b], whose result is typed as [R].
///
/// The result is `b.sublist(0)`, a list of the class of [b]: one list that
/// each call writes and returns, as upstream. A list of integers, also an
/// integer typed-data list, stores `value.toInt()` with the rules of its
/// class: a `Uint8List` keeps the low 8 bits and a `Uint8ClampedList`
/// clamps. On the VM and with dart2wasm, `toInt()` saturates a value of
/// magnitude 2^63 or more at the bounds of a 64-bit [int] before the store
/// ([interpolateNumberArray]). [R] must be a supertype of that class: the
/// generic `interpolate<T>` and `interpolateArray<E>` give the type of their
/// result.
R Function(double t) numberArray<R>(List<num> a, List<num> b) {
  // DIVERGES(d3-interpolate): adapt-interpolate-typed-values, no undefined.
  final n = math.min(b.length, a.length);
  final c = b.sublist(0);
  final result = c as R;
  // DIVERGES(d3-interpolate): adapt-interpolate-typed-loops, typed reads.
  // The same loop with the static types of the lists: the reads and the
  // writes of a Float64List or a Float32List take no box and no dispatch.
  if (c is Float64List && b is Float64List) {
    final bf = b;
    if (a is Float64List) {
      final af = a;
      return (t) {
        for (var i = 0; i < n; ++i) {
          c[i] = af[i] * (1 - t) + bf[i] * t;
        }
        return result;
      };
    }
    return (t) {
      for (var i = 0; i < n; ++i) {
        c[i] = a[i].toDouble() * (1 - t) + bf[i] * t;
      }
      return result;
    };
  }
  if (c is Float32List && b is Float32List && a is Float32List) {
    final af = a;
    final bf = b;
    return (t) {
      for (var i = 0; i < n; ++i) {
        c[i] = af[i] * (1 - t) + bf[i] * t;
      }
      return result;
    };
  }
  if (c is List<int>) {
    final ints = c;
    return (t) {
      for (var i = 0; i < n; ++i) {
        ints[i] = (a[i] * (1 - t) + b[i] * t).toInt();
      }
      return result;
    };
  }
  if (c is List<double>) {
    final doubles = c;
    return (t) {
      for (var i = 0; i < n; ++i) {
        doubles[i] = a[i] * (1 - t) + b[i] * t;
      }
      return result;
    };
  }
  return (t) {
    for (var i = 0; i < n; ++i) {
      c[i] = a[i] * (1 - t) + b[i] * t;
    }
    return result;
  };
}

/// numberArray.js:1 the default export (`interpolateNumberArray` of
/// index.js:9): the interpolator from the numbers of [a] to the numbers of
/// [b].
///
/// The interpolator returns a list of the class of [b] (`b.sublist(0)`), as
/// upstream `b.slice()`: a `Float64List` [b] gives a `Float64List`, a
/// `Uint8List` [b] a `Uint8List`. Each call writes the same list and returns
/// it. The items of [b] past the end of [a] stay as they are, and the items
/// of [a] past the end of [b] do not count. A list of integers stores
/// `value.toInt()` with the rules of its class: a `Uint8List` keeps the low
/// 8 bits of the value truncated toward zero. For a finite value below 2^63
/// in magnitude, these are the bits that a JavaScript typed array stores.
/// On the VM and with dart2wasm, `toInt()` saturates a finite value of
/// magnitude 2^63 or more at the bounds of a 64-bit [int] before the store:
/// 1e20 stores -1 in an `Int32List` and 255 in a `Uint8List`, where
/// JavaScript stores 1661992960 and 0. DDC and dart2js store the bits of
/// JavaScript. A NaN or infinite value throws in a list of integers, where
/// JavaScript stores 0.
///
/// ```dart
/// final i = interpolateNumberArray(
///   Float64List.fromList([2, 12]),
///   Float64List.fromList([4, 24]),
/// );
/// i(0.5); // [3.0, 18.0], a Float64List
/// ```
T Function(double t) interpolateNumberArray<T extends List<num>>(
  List<num> a,
  T b,
) => numberArray<T>(a, b);

/// numberArray.js:12 `isNumberArray(x)`: whether [x] is a typed-data list of
/// numbers, `ArrayBuffer.isView(x) && !(x instanceof DataView)`.
///
/// A [ByteData] (the `DataView` of Dart) is not one, and neither is a list
/// of SIMD values, such as a `Float32x4List`, which JavaScript does not have.
bool isNumberArray(Object? x) => x is TypedData && x is List<num>;
