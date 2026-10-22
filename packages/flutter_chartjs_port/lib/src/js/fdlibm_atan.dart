// Ported from fdlibm 5.3 s_atan.c (SunPro, Sun Microsystems, Inc.).
// Ported from fdlibm 5.3 e_atan2.c (SunPro, Sun Microsystems, Inc.).

// Both source files carry this notice:
//
// ====================================================
// Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
//
// Developed at SunSoft, a Sun Microsystems, Inc. business.
// Permission to use, copy, modify, and distribute this
// software is freely granted, provided that this notice
// is preserved.
// ====================================================
//
// Sources: https://www.netlib.org/fdlibm/s_atan.c (@(#)s_atan.c 1.3 95/01/18)
// and https://www.netlib.org/fdlibm/e_atan2.c (@(#)e_atan2.c 1.3 95/01/18),
// kept unchanged in third_party/fdlibm/.
//
// Port notes:
// - __HI(x) and __LO(x) read the words of x through a ByteData, so the code
//   gives the same bits on the VM, dart2js and dart2wasm.
// - e_atan2.c tests `(lx|-lx)>>31` on a C unsigned, which is 1 when lx is
//   not 0. The port writes that test as `lx != 0`, because dart2js and the VM
//   give `|` and `>>` different widths.
// - dart2js makes the result of `>>` unsigned. `k = (iy-ix)>>20` in
//   __ieee754_atan2 uses toSigned(32) to keep the C int semantics.
// - `__HI(z) ^= 0x80000000` becomes `-z`. z is never NaN there, so the two
//   give the same bits.
// - One line is not in netlib fdlibm 5.3: `m &= 1` when |y/x| > 2**60 (see
//   its comment). V8 13.6 has it, and the port matches V8.

// The C code assigns to its argument x.
// ignore_for_file: parameter_assignments

/// The fdlibm 5.3 arctangents (`Math.atan`, `Math.atan2`).
library;

import 'dart:typed_data';

// Scratch space for the high and low 32-bit words of a double.
final ByteData _words = ByteData(8);

/// `__HI(x)`: the high word of [x], as a C `int`.
int _hi(double x) {
  _words.setFloat64(0, x, Endian.little);
  return _words.getInt32(4, Endian.little);
}

/// `__LO(x)`: the low word of [x], as a C `unsigned`.
int _lo(double x) {
  _words.setFloat64(0, x, Endian.little);
  return _words.getUint32(0, Endian.little);
}

// s_atan.c

/* atan(x)
 * Method
 *   1. Reduce x to positive by atan(x) = -atan(-x).
 *   2. According to the integer k=4t+0.25 chopped, t=x, the argument
 *      is further reduced to one of the following intervals and the
 *      arctangent of t is evaluated by the corresponding formula:
 *
 *      [0,7/16]      atan(x) = t-t^3*(a1+t^2*(a2+...(a10+t^2*a11)...)
 *      [7/16,11/16]  atan(x) = atan(1/2) + atan( (t-0.5)/(1+t/2) )
 *      [11/16.19/16] atan(x) = atan( 1 ) + atan( (t-1)/(1+t) )
 *      [19/16,39/16] atan(x) = atan(3/2) + atan( (t-1.5)/(1+1.5t) )
 *      [39/16,INF]   atan(x) = atan(INF) + atan( -1/t )
 *
 * Constants:
 * The hexadecimal values are the intended ones for the following
 * constants. The decimal values may be used, provided that the
 * compiler will convert from decimal to binary accurately enough
 * to produce the hexadecimal values shown.
 */

const List<double> _atanhi = [
  4.63647609000806093515e-01, // atan(0.5)hi 0x3FDDAC67, 0x0561BB4F
  7.85398163397448278999e-01, // atan(1.0)hi 0x3FE921FB, 0x54442D18
  9.82793723247329054082e-01, // atan(1.5)hi 0x3FEF730B, 0xD281F69B
  1.57079632679489655800e+00, // atan(inf)hi 0x3FF921FB, 0x54442D18
];

const List<double> _atanlo = [
  2.26987774529616870924e-17, // atan(0.5)lo 0x3C7A2B7F, 0x222F65E2
  3.06161699786838301793e-17, // atan(1.0)lo 0x3C81A626, 0x33145C07
  1.39033110312309984516e-17, // atan(1.5)lo 0x3C700788, 0x7AF0CBBD
  6.12323399573676603587e-17, // atan(inf)lo 0x3C91A626, 0x33145C07
];

const List<double> _aT = [
  3.33333333333329318027e-01, // 0x3FD55555, 0x5555550D
  -1.99999999998764832476e-01, // 0xBFC99999, 0x9998EBC4
  1.42857142725034663711e-01, // 0x3FC24924, 0x920083FF
  -1.11111104054623557880e-01, // 0xBFBC71C6, 0xFE231671
  9.09088713343650656196e-02, // 0x3FB745CD, 0xC54C206E
  -7.69187620504482999495e-02, // 0xBFB3B0F2, 0xAF749A6D
  6.66107313738753120669e-02, // 0x3FB10D66, 0xA0D03D51
  -5.83357013379057348645e-02, // 0xBFADDE2D, 0x52DEFD9A
  4.97687799461593236017e-02, // 0x3FA97B4B, 0x24760DEB
  -3.65315727442169155270e-02, // 0xBFA2B444, 0x2C6A6C2F
  1.62858201153657823623e-02, // 0x3F90AD3A, 0xE322DA11
];

const double _one = 1;
const double _huge = 1.0e300;

/// s_atan.c:86 `atan`, the arctangent of [x].
double atan(double x) {
  int id;

  final hx = _hi(x);
  final ix = hx & 0x7fffffff;
  if (ix >= 0x44100000) {
    // if |x| >= 2^66
    if (ix > 0x7ff00000 || (ix == 0x7ff00000 && (_lo(x) != 0))) {
      return x + x; // NaN
    }
    if (hx > 0) {
      return _atanhi[3] + _atanlo[3];
    } else {
      return -_atanhi[3] - _atanlo[3];
    }
  }
  if (ix < 0x3fdc0000) {
    // |x| < 0.4375
    if (ix < 0x3e200000) {
      // |x| < 2^-29
      if (_huge + x > _one) return x; // raise inexact
    }
    id = -1;
  } else {
    x = x.abs();
    if (ix < 0x3ff30000) {
      // |x| < 1.1875
      if (ix < 0x3fe60000) {
        // 7/16 <=|x|<11/16
        id = 0;
        x = (2.0 * x - _one) / (2.0 + x);
      } else {
        // 11/16<=|x|< 19/16
        id = 1;
        x = (x - _one) / (x + _one);
      }
    } else {
      if (ix < 0x40038000) {
        // |x| < 2.4375
        id = 2;
        x = (x - 1.5) / (_one + 1.5 * x);
      } else {
        // 2.4375 <= |x| < 2^66
        id = 3;
        x = -1.0 / x;
      }
    }
  }
  // end of argument reduction
  var z = x * x;
  final w = z * z;
  // break sum from i=0 to 10 aT[i]z**(i+1) into odd and even poly
  final s1 =
      z *
      (_aT[0] +
          w *
              (_aT[2] +
                  w * (_aT[4] + w * (_aT[6] + w * (_aT[8] + w * _aT[10])))));
  final s2 =
      w * (_aT[1] + w * (_aT[3] + w * (_aT[5] + w * (_aT[7] + w * _aT[9]))));
  if (id < 0) {
    return x - x * (s1 + s2);
  } else {
    z = _atanhi[id] - ((x * (s1 + s2) - _atanlo[id]) - x);
    return (hx < 0) ? -z : z;
  }
}

// e_atan2.c

/* __ieee754_atan2(y,x)
 * Method :
 *	1. Reduce y to positive by atan2(y,x)=-atan2(-y,x).
 *	2. Reduce x to positive by (if x and y are unexceptional):
 *		ARG (x+iy) = arctan(y/x)   	   ... if x > 0,
 *		ARG (x+iy) = pi - arctan[y/(-x)]   ... if x < 0,
 *
 * Special cases:
 *
 *	ATAN2((anything), NaN ) is NaN;
 *	ATAN2(NAN , (anything) ) is NaN;
 *	ATAN2(+-0, +(anything but NaN)) is +-0  ;
 *	ATAN2(+-0, -(anything but NaN)) is +-pi ;
 *	ATAN2(+-(anything but 0 and NaN), 0) is +-pi/2;
 *	ATAN2(+-(anything but INF and NaN), +INF) is +-0 ;
 *	ATAN2(+-(anything but INF and NaN), -INF) is +-pi;
 *	ATAN2(+-INF,+INF ) is +-pi/4 ;
 *	ATAN2(+-INF,-INF ) is +-3pi/4;
 *	ATAN2(+-INF, (anything but,0,NaN, and INF)) is +-pi/2;
 *
 * Constants:
 * The hexadecimal values are the intended ones for the following
 * constants. The decimal values may be used, provided that the
 * compiler will convert from decimal to binary accurately enough
 * to produce the hexadecimal values shown.
 */

const double _tiny = 1.0e-300;
const double _zero = 0;
const double _piO4 = 7.8539816339744827900E-01; // 0x3FE921FB, 0x54442D18
const double _piO2 = 1.5707963267948965580E+00; // 0x3FF921FB, 0x54442D18
const double _pi = 3.1415926535897931160E+00; // 0x400921FB, 0x54442D18
const double _piLo = 1.2246467991473531772E-16; // 0x3CA1A626, 0x33145C07

/// e_atan2.c:57 `__ieee754_atan2`, the angle of the point ([x], [y]) from
/// the positive x axis.
double ieee754Atan2(double y, double x) {
  double z;

  final hx = _hi(x);
  final ix = hx & 0x7fffffff;
  final lx = _lo(x);
  final hy = _hi(y);
  final iy = hy & 0x7fffffff;
  final ly = _lo(y);
  if (((ix | (lx != 0 ? 1 : 0)) > 0x7ff00000) ||
      ((iy | (ly != 0 ? 1 : 0)) > 0x7ff00000)) {
    // x or y is NaN
    return x + y;
  }
  if (((hx - 0x3ff00000) | lx) == 0) return atan(y); // x=1.0
  var m = ((hy >> 31) & 1) | ((hx >> 30) & 2); // 2*sign(x)+sign(y)

  // when y = 0
  if ((iy | ly) == 0) {
    switch (m) {
      case 0:
      case 1:
        return y; // atan(+-0,+anything)=+-0
      case 2:
        return _pi + _tiny; // atan(+0,-anything) = pi
      case 3:
        return -_pi - _tiny; // atan(-0,-anything) =-pi
    }
  }
  // when x = 0
  if ((ix | lx) == 0) return (hy < 0) ? -_piO2 - _tiny : _piO2 + _tiny;

  // when x is INF
  if (ix == 0x7ff00000) {
    if (iy == 0x7ff00000) {
      switch (m) {
        case 0:
          return _piO4 + _tiny; // atan(+INF,+INF)
        case 1:
          return -_piO4 - _tiny; // atan(-INF,+INF)
        case 2:
          return 3.0 * _piO4 + _tiny; //atan(+INF,-INF)
        case 3:
          return -3.0 * _piO4 - _tiny; //atan(-INF,-INF)
      }
    } else {
      switch (m) {
        case 0:
          return _zero; // atan(+...,+INF)
        case 1:
          return -_zero; // atan(-...,+INF)
        case 2:
          return _pi + _tiny; // atan(+...,-INF)
        case 3:
          return -_pi - _tiny; // atan(-...,-INF)
      }
    }
  }
  // when y is INF
  if (iy == 0x7ff00000) return (hy < 0) ? -_piO2 - _tiny : _piO2 + _tiny;

  // compute y/x
  final k = ((iy - ix) >> 20).toSigned(32);
  if (k > 60) {
    z = _piO2 + 0.5 * _piLo; // |y/x| >  2**60
    // Not in netlib fdlibm 5.3: V8 returns +-pi/2 here also when x < 0,
    // where netlib returns +-(pi/2 + 1 ulp) (fdlibm_atan_test.dart).
    m &= 1;
  } else if (hx < 0 && k < -60) {
    z = 0.0; // |y|/x < -2**60
  } else {
    z = atan((y / x).abs()); // safe to do y/x
  }
  switch (m) {
    case 0:
      return z; // atan(+,+)
    case 1:
      // __HI(z) ^= 0x80000000
      return -z; // atan(-,+)
    case 2:
      return _pi - (z - _piLo); // atan(+,-)
    default: // case 3
      return (z - _piLo) - _pi; // atan(-,-)
  }
}
