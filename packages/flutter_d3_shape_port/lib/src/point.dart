// Ported from d3-shape v3.2.0 src/point.js (ISC, Mike Bostock).

/// Port of `src/point.js` of d3-shape 3.2.0: default point coordinate
/// accessors.
library;

/// `point.js:1` `x(p)`: returns the x-coordinate of a 2D point
/// `(num, num)` or `List<num>`.
@pragma('vm:prefer-inline')
double pointX(Object? p) {
  if (p is (double, double)) return p.$1;
  if (p is (num, num)) return p.$1.toDouble();
  if (p is List<double>) return p[0];
  if (p is List<num>) return p[0].toDouble();
  throw ArgumentError.value(
    p,
    'p',
    'Expected (num, num) or List<num>, or set a custom x accessor',
  );
}

/// `point.js:5` `y(p)`: returns the y-coordinate of a 2D point
/// `(num, num)` or `List<num>`.
@pragma('vm:prefer-inline')
double pointY(Object? p) {
  if (p is (double, double)) return p.$2;
  if (p is (num, num)) return p.$2.toDouble();
  if (p is List<double>) return p[1];
  if (p is List<num>) return p[1].toDouble();
  throw ArgumentError.value(
    p,
    'p',
    'Expected (num, num) or List<num>, or set a custom y accessor',
  );
}
