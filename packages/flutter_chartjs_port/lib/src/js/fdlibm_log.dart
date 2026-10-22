// Ported from fdlibm 5.3 e_log.c (SunPro, Sun Microsystems, Inc.).
// Ported from fdlibm 5.3 e_log10.c (SunPro, Sun Microsystems, Inc.).

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
// Sources: https://www.netlib.org/fdlibm/e_log.c (@(#)e_log.c 1.3 95/01/18)
// and https://www.netlib.org/fdlibm/e_log10.c (@(#)e_log10.c 1.3 95/01/18),
// kept unchanged in third_party/fdlibm/.
//
// Port notes:
// - __HI(x) and __LO(x) read the words of x through a ByteData, so the code
//   gives the same bits on the VM, dart2js and dart2wasm.
// - dart2js makes the result of `|` unsigned. The `i |= j` sign test in
//   __ieee754_log uses toSigned(32) to keep the C int semantics.
// - The C files each define two54 and zero. This file defines them once.

// The C code assigns to its argument x.
// ignore_for_file: parameter_assignments

/// The fdlibm 5.3 natural and base-10 logarithms (`Math.log`, `Math.log10`).
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

/// `__HI(x) = hi`: [x] with its high word replaced by [hi].
double _setHi(double x, int hi) {
  _words
    ..setFloat64(0, x, Endian.little)
    ..setInt32(4, hi, Endian.little);
  return _words.getFloat64(0, Endian.little);
}

// e_log.c

/* __ieee754_log(x)
 * Return the logrithm of x
 *
 * Method :
 *   1. Argument Reduction: find k and f such that
 *			x = 2^k * (1+f),
 *	   where  sqrt(2)/2 < 1+f < sqrt(2) .
 *
 *   2. Approximation of log(1+f).
 *	Let s = f/(2+f) ; based on log(1+f) = log(1+s) - log(1-s)
 *		 = 2s + 2/3 s**3 + 2/5 s**5 + .....,
 *	     	 = 2s + s*R
 *      We use a special Reme algorithm on [0,0.1716] to generate
 * 	a polynomial of degree 14 to approximate R The maximum error
 *	of this polynomial approximation is bounded by 2**-58.45. In
 *	other words,
 *		        2      4      6      8      10      12      14
 *	    R(z) ~ Lg1*s +Lg2*s +Lg3*s +Lg4*s +Lg5*s  +Lg6*s  +Lg7*s
 *  	(the values of Lg1 to Lg7 are listed in the program)
 *	and
 *	    |      2          14          |     -58.45
 *	    | Lg1*s +...+Lg7*s    -  R(z) | <= 2
 *	    |                             |
 *	Note that 2s = f - s*f = f - hfsq + s*hfsq, where hfsq = f*f/2.
 *	In order to guarantee error in log below 1ulp, we compute log
 *	by
 *		log(1+f) = f - s*(f - R)	(if f is not too large)
 *		log(1+f) = f - (hfsq - s*(hfsq+R)).	(better accuracy)
 *
 *	3. Finally,  log(x) = k*ln2 + log(1+f).
 *			    = k*ln2_hi+(f-(hfsq-(s*(hfsq+R)+k*ln2_lo)))
 *	   Here ln2 is split into two floating point number:
 *			ln2_hi + ln2_lo,
 *	   where n*ln2_hi is always exact for |n| < 2000.
 *
 * Special cases:
 *	log(x) is NaN with signal if x < 0 (including -INF) ;
 *	log(+INF) is +INF; log(0) is -INF with signal;
 *	log(NaN) is that NaN with no signal.
 *
 * Accuracy:
 *	according to an error analysis, the error is always less than
 *	1 ulp (unit in the last place).
 *
 * Constants:
 * The hexadecimal values are the intended ones for the following
 * constants. The decimal values may be used, provided that the
 * compiler will convert from decimal to binary accurately enough
 * to produce the hexadecimal values shown.
 */

const double _ln2Hi = 6.93147180369123816490e-01; // 3fe62e42 fee00000
const double _ln2Lo = 1.90821492927058770002e-10; // 3dea39ef 35793c76
// The C literal, kept for comparison with the source.
// ignore: prefer_int_literals
const double _two54 = 1.80143985094819840000e+16; // 43500000 00000000
const double _lg1 = 6.666666666666735130e-01; // 3FE55555 55555593
const double _lg2 = 3.999999999940941908e-01; // 3FD99999 9997FA04
const double _lg3 = 2.857142874366239149e-01; // 3FD24924 94229359
const double _lg4 = 2.222219843214978396e-01; // 3FCC71C5 1D8E78AF
const double _lg5 = 1.818357216161805012e-01; // 3FC74664 96CB03DE
const double _lg6 = 1.531383769920937332e-01; // 3FC39A09 D078C69F
const double _lg7 = 1.479819860511658591e-01; // 3FC2F112 DF3E5244

const double _zero = 0;

/// e_log.c:86 `__ieee754_log`, the natural logarithm of [x].
double ieee754Log(double x) {
  double dk;
  int i;

  var hx = _hi(x); // high word of x
  final lx = _lo(x); // low  word of x

  var k = 0;
  if (hx < 0x00100000) {
    // x < 2**-1022
    if (((hx & 0x7fffffff) | lx) == 0) {
      return -_two54 / _zero; // log(+-0)=-inf
    }
    if (hx < 0) return (x - x) / _zero; // log(-#) = NaN
    k -= 54;
    x *= _two54; // subnormal number, scale up x
    hx = _hi(x); // high word of x
  }
  if (hx >= 0x7ff00000) return x + x;
  k += (hx >> 20) - 1023;
  hx &= 0x000fffff;
  i = (hx + 0x95f64) & 0x100000;
  x = _setHi(x, hx | (i ^ 0x3ff00000)); // normalize x or x/2
  k += i >> 20;
  final f = x - 1.0;
  if ((0x000fffff & (2 + hx)) < 3) {
    // |f| < 2**-20
    if (f == _zero) {
      if (k == 0) {
        return _zero;
      } else {
        dk = k.toDouble();
        return dk * _ln2Hi + dk * _ln2Lo;
      }
    }
    final r = f * f * (0.5 - 0.33333333333333333 * f);
    if (k == 0) {
      return f - r;
    } else {
      dk = k.toDouble();
      return dk * _ln2Hi - ((r - dk * _ln2Lo) - f);
    }
  }
  final s = f / (2.0 + f);
  dk = k.toDouble();
  final z = s * s;
  i = hx - 0x6147a;
  final w = z * z;
  final j = 0x6b851 - hx;
  final t1 = w * (_lg2 + w * (_lg4 + w * _lg6));
  final t2 = z * (_lg1 + w * (_lg3 + w * (_lg5 + w * _lg7)));
  i = (i | j).toSigned(32);
  final r = t2 + t1;
  if (i > 0) {
    final hfsq = 0.5 * f * f;
    if (k == 0) {
      return f - (hfsq - s * (hfsq + r));
    } else {
      return dk * _ln2Hi - ((hfsq - (s * (hfsq + r) + dk * _ln2Lo)) - f);
    }
  } else {
    if (k == 0) {
      return f - s * (f - r);
    } else {
      return dk * _ln2Hi - ((s * (f - r) - dk * _ln2Lo) - f);
    }
  }
}

// e_log10.c

/* __ieee754_log10(x)
 * Return the base 10 logarithm of x
 *
 * Method :
 *	Let log10_2hi = leading 40 bits of log10(2) and
 *	    log10_2lo = log10(2) - log10_2hi,
 *	    ivln10   = 1/log(10) rounded.
 *	Then
 *		n = ilogb(x),
 *		if(n<0)  n = n+1;
 *		x = scalbn(x,-n);
 *		log10(x) := n*log10_2hi + (n*log10_2lo + ivln10*log(x))
 *
 * Note 1:
 *	To guarantee log10(10**n)=n, where 10**n is normal, the rounding
 *	mode must set to Round-to-Nearest.
 * Note 2:
 *	[1/log(10)] rounded to 53 bits has error  .198   ulps;
 *	log10 is monotonic at all binary break points.
 *
 * Special cases:
 *	log10(x) is NaN with signal if x < 0;
 *	log10(+INF) is +INF with no signal; log10(0) is -INF with signal;
 *	log10(NaN) is that NaN with no signal;
 *	log10(10**N) = N  for N=0,1,...,22.
 *
 * Constants:
 * The hexadecimal values are the intended ones for the following constants.
 * The decimal values may be used, provided that the compiler will convert
 * from decimal to binary accurately enough to produce the hexadecimal values
 * shown.
 */

const double _ivln10 = 4.34294481903251816668e-01; // 0x3FDBCB7B, 0x1526E50E
// log10_2hi
const double _log10Of2Hi = 3.01029995663611771306e-01; // 0x3FD34413, 0x509F6000
// log10_2lo
const double _log10Of2Lo = 3.69423907715893078616e-13; // 0x3D59FEF3, 0x11F12B36

/// e_log10.c:62 `__ieee754_log10`, the base-10 logarithm of [x].
double ieee754Log10(double x) {
  var hx = _hi(x); // high word of x
  final lx = _lo(x); // low word of x

  var k = 0;
  if (hx < 0x00100000) {
    // x < 2**-1022
    if (((hx & 0x7fffffff) | lx) == 0) {
      return -_two54 / _zero; // log(+-0)=-inf
    }
    if (hx < 0) return (x - x) / _zero; // log(-#) = NaN
    k -= 54;
    x *= _two54; // subnormal number, scale up x
    hx = _hi(x); // high word of x
  }
  if (hx >= 0x7ff00000) return x + x;
  k += (hx >> 20) - 1023;
  final i = (k & 0x80000000) >> 31; // ((unsigned)k&0x80000000)>>31
  hx = (hx & 0x000fffff) | ((0x3ff - i) << 20);
  final y = (k + i).toDouble();
  x = _setHi(x, hx);
  final z = y * _log10Of2Lo + _ivln10 * ieee754Log(x);
  return z + y * _log10Of2Hi;
}
