// Ported from fdlibm 5.3 s_sin.c (SunPro, Sun Microsystems, Inc.).
// Ported from fdlibm 5.3 s_cos.c (SunPro, Sun Microsystems, Inc.).
// Ported from fdlibm 5.3 k_sin.c (SunPro, Sun Microsystems, Inc.).
// Ported from fdlibm 5.3 k_cos.c (SunPro, Sun Microsystems, Inc.).
// Ported from fdlibm 5.3 e_rem_pio2.c (SunPro, Sun Microsystems, Inc.).
// Ported from fdlibm 5.3 k_rem_pio2.c (SunPro, Sun Microsystems, Inc.).
// Ported from fdlibm 5.3 s_scalbn.c (SunPro, Sun Microsystems, Inc.).

// All seven source files carry this notice:
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
// Sources: https://www.netlib.org/fdlibm/ (s_sin.c, s_cos.c, k_sin.c,
// k_cos.c, k_rem_pio2.c and s_scalbn.c 1.3 95/01/18; e_rem_pio2.c 1.4
// 95/01/18), kept unchanged in third_party/fdlibm/.
//
// Port notes:
// - Every arithmetic statement of netlib stays, in its order. sin and cos
//   stay two functions with the four `switch (n & 3)` cases of the C code.
// - On the common path, a test of the high word ix against a constant H is
//   an exact comparison of |x| with D(H), the double whose high word is H
//   and whose low word is 0: `ix < H` is `|x| < D(H)`, `ix <= H` is
//   `|x| < D(H + 1)` and `ix > H` is `|x| >= D(H + 1)`. Each such line has
//   the C test as a comment (Chart.js ADR 0045 section 3). A NaN fails each
//   comparison. Thus ieee754Sin and ieee754Cos test
//   `!(|x| <= double.maxFinite)` (C: `ix >= 0x7ff00000`) before the
//   reduction.
// - In __kernel_cos, `__HI(qx) = ix-0x00200000; __LO(qx) = 0;` is
//   `(|x| * 2**22).floorToDouble() * 2**-24` for 0.3 <= |x| < 0.5 and
//   `(|x| * 2**21).floorToDouble() * 2**-23` for 0.5 <= |x| < D(0x3fe90001).
//   Each operation is exact.
// - The cold paths read the words of a double through a ByteData: the
//   second and third iterations of the medium reduction, `n >= 32`, the
//   reduction above 2**19*pi/2 with __kernel_rem_pio2, and scalbn. Thus
//   they give the same bits on the VM, dart2js and dart2wasm.
// - __kernel_rem_pio2 keeps only the `prec` that __ieee754_rem_pio2 passes
//   (2). Dart has no comma operator: the extra start values of the C `for`
//   loops come before the loop. The `goto recompute` is a loop.
// - dart2js makes the result of `|` and `>>` unsigned. The port calls
//   toSigned(32) where C relies on a signed int result. `n & 3` of a
//   negative n gives the C result on the three targets.
// - s_floor.c, s_fabs.c and s_copysign.c are not ported: floorToDouble(),
//   abs() and a sign test of the high word give the same exact results.
// - V8 13.6 has no line that netlib does not have in these functions.
// - The Dart VM AOT on arm64 does not contract the operations to fused
//   multiply-add (0 mismatches on 5,691,981 inputs).

// The C code assigns to its arguments.
// ignore_for_file: parameter_assignments

/// The fdlibm 5.3 sine and cosine (`Math.sin`, `Math.cos`), as V8 13.6 on
/// x64 computes them (Chart.js ADR 0045).
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

/// The double with the high word [hi] (a C `int`) and the low word [lo].
double _fromWords(int hi, int lo) {
  _words
    ..setInt32(4, hi, Endian.little)
    ..setUint32(0, lo, Endian.little);
  return _words.getFloat64(0, Endian.little);
}

// `y[0]` and `y[1]` of `__ieee754_rem_pio2(x, y)`: the reduced argument.
// One list for all calls, so a call allocates nothing.
final Float64List _y = Float64List(2);

// The bounds of the high-word tests as doubles: D(H) is the double whose
// high word is H and whose low word is 0.

/// D(0x3fe921fc): `ix <= 0x3fe921fb` (|x| ~<= pi/4) is `|x| < _pio4Hi1`.
const double _pio4Hi1 = 0.7853984832763672;

/// D(0x3e400000): `ix < 0x3e400000` (|x| < 2**-27) is `|x| < _twoM27`.
const double _twoM27 = 7.450580596923828e-9;

/// D(0x3fd33333): `ix < 0x3FD33333` (|x| < 0.3) is `|x| < _c03`.
const double _c03 = 0.2999999523162842;

/// D(0x3fe90001): `ix > 0x3fe90000` (|x| > 0.78125) is
/// `|x| >= _c078125`.
const double _c078125 = 0.7812504768371582;

/// D(0x4002d97c): `ix < 0x4002d97c` (|x| < 3pi/4) is `|x| < _threePio4`.
const double _threePio4 = 2.3561935424804688;

/// D(0x3ff921fb): `ix != 0x3ff921fb` is
/// `|x| < _pio2Hi || |x| >= _pio2Hi1`.
const double _pio2Hi = 1.570796012878418;

/// D(0x3ff921fc), the upper end of the test of [_pio2Hi].
const double _pio2Hi1 = 1.5707969665527344;

/// D(0x413921fc): `ix <= 0x413921fb` (|x| ~<= 2**19*(pi/2)) is
/// `|x| < _medium`.
const double _medium = 1647100;

// s_sin.c

/* sin(x)
 * Return sine function of x.
 *
 * kernel function:
 *	__kernel_sin		... sine function on [-pi/4,pi/4]
 *	__kernel_cos		... cose function on [-pi/4,pi/4]
 *	__ieee754_rem_pio2	... argument reduction routine
 *
 * Method.
 *      Let S,C and T denote the sin, cos and tan respectively on
 *	[-PI/4, +PI/4]. Reduce the argument x to y1+y2 = x-k*pi/2
 *	in [-pi/4 , +pi/4], and let n = k mod 4.
 *	We have
 *
 *          n        sin(x)      cos(x)        tan(x)
 *     ----------------------------------------------------------
 *	    0	       S	   C		 T
 *	    1	       C	  -S		-1/T
 *	    2	      -S	  -C		 T
 *	    3	      -C	   S		-1/T
 *     ----------------------------------------------------------
 *
 * Special cases:
 *      Let trig be any of sin, cos, or tan.
 *      trig(+-INF)  is NaN, with signals;
 *      trig(NaN)    is that NaN;
 *
 * Accuracy:
 *	TRIG(x) returns trig(x) nearly rounded
 */

/// fdlibm 5.3 `sin(x)` (`s_sin.c`).
double ieee754Sin(double x) {
  final ax = x.abs();
  // |x| ~< pi/4
  // ix <= 0x3fe921fb <=> |x| < 0x3fe921fc_00000000
  if (ax < _pio4Hi1) return _kernelSin(x, 0, 0);
  // sin(Inf or NaN) is NaN
  // ix >= 0x7ff00000 <=> !(|x| <= 0x7fefffff_ffffffff)
  if (!(ax <= double.maxFinite)) return x - x;
  // argument reduction needed
  final n = _ieee754RemPio2(x, _y);
  switch (n & 3) {
    case 0:
      return _kernelSin(_y[0], _y[1], 1);
    case 1:
      return _kernelCos(_y[0], _y[1]);
    case 2:
      return -_kernelSin(_y[0], _y[1], 1);
    default:
      return -_kernelCos(_y[0], _y[1]);
  }
}

// s_cos.c

/// fdlibm 5.3 `cos(x)` (`s_cos.c`).
double ieee754Cos(double x) {
  final ax = x.abs();
  // |x| ~< pi/4
  // ix <= 0x3fe921fb <=> |x| < 0x3fe921fc_00000000
  if (ax < _pio4Hi1) return _kernelCos(x, 0);
  // cos(Inf or NaN) is NaN
  // ix >= 0x7ff00000 <=> !(|x| <= 0x7fefffff_ffffffff)
  if (!(ax <= double.maxFinite)) return x - x;
  // argument reduction needed
  final n = _ieee754RemPio2(x, _y);
  switch (n & 3) {
    case 0:
      return _kernelCos(_y[0], _y[1]);
    case 1:
      return -_kernelSin(_y[0], _y[1], 1);
    case 2:
      return -_kernelCos(_y[0], _y[1]);
    default:
      return _kernelSin(_y[0], _y[1], 1);
  }
}

// k_sin.c

/* __kernel_sin( x, y, iy)
 * kernel sin function on [-pi/4, pi/4], pi/4 ~ 0.7854
 * Input x is assumed to be bounded by ~pi/4 in magnitude.
 * Input y is the tail of x.
 * Input iy indicates whether y is 0. (if iy=0, y assume to be 0).
 *
 * Algorithm
 *	1. Since sin(-x) = -sin(x), we need only to consider positive x.
 *	2. if x < 2^-27 (hx<0x3e400000 0), return x with inexact if x!=0.
 *	3. sin(x) is approximated by a polynomial of degree 13 on
 *	   [0,pi/4]
 *	   	sin(x) ~ x + S1*x^3 + ... + S6*x^13
 *	4. sin(x+y) = sin(x) + sin'(x')*y
 *		    ~ sin(x) + (1-x*x/2)*y
 *	   For better accuracy, let
 *		r = x^3*(S2+x^2*(S3+x^2*(S4+x^2*(S5+x^2*S6))))
 *	   then
 *		sin(x) = x + (S1*x^3 + (x^2*(r-y/2)+y))
 */

const double _half = 5.00000000000000000000e-01; // 0x3FE00000, 0x00000000
const double _s1 = -1.66666666666666324348e-01; // 0xBFC55555, 0x55555549
const double _s2 = 8.33333333332248946124e-03; // 0x3F811111, 0x1110F8A6
const double _s3 = -1.98412698298579493134e-04; // 0xBF2A01A0, 0x19C161D5
const double _s4 = 2.75573137070700676789e-06; // 0x3EC71DE3, 0x57B1FE7D
const double _s5 = -2.50507602534068634195e-08; // 0xBE5AE5E6, 0x8A2B9CEB
const double _s6 = 1.58969099521155010221e-10; // 0x3DE5D93A, 0x5ACFD57C

/// `__kernel_sin(x, y, iy)`: the sine on [-pi/4, pi/4]. [y] is the tail of
/// [x]. [iy] is 0 when [y] is 0.
double _kernelSin(double x, double y, int iy) {
  // ix < 0x3e400000 <=> |x| < 0x3e400000_00000000 (|x| < 2**-27)
  if (x.abs() < _twoM27) {
    if (x.toInt() == 0) return x; // generate inexact
  }
  final z = x * x;
  final v = z * x;
  final r = _s2 + z * (_s3 + z * (_s4 + z * (_s5 + z * _s6)));
  if (iy == 0) {
    return x + v * (_s1 + z * r);
  } else {
    return x - ((z * (_half * y - v * r) - y) - v * _s1);
  }
}

// k_cos.c

/*
 * __kernel_cos( x,  y )
 * kernel cos function on [-pi/4, pi/4], pi/4 ~ 0.785398164
 * Input x is assumed to be bounded by ~pi/4 in magnitude.
 * Input y is the tail of x.
 *
 * Algorithm
 *	1. Since cos(-x) = cos(x), we need only to consider positive x.
 *	2. if x < 2^-27 (hx<0x3e400000 0), return 1 with inexact if x!=0.
 *	3. cos(x) is approximated by a polynomial of degree 14 on
 *	   [0,pi/4]
 *	   	cos(x) ~ 1 - x*x/2 + C1*x^4 + ... + C6*x^14
 *	4. let r = C1*x^4 +C2*x^6 +C3*x^8 +C4*x^10 +C5*x^12 +C6*x^14, then
 *	       cos(x) = 1 - x*x/2 + r
 *	   since cos(x+y) ~ cos(x) - sin(x)*y
 *			  ~ cos(x) - x*y,
 *	   a correction term is necessary in cos(x) and hence
 *		cos(x+y) = 1 - (x*x/2 - (r - x*y))
 *	   For better accuracy when x > 0.3, let qx = |x|/4 with
 *	   the last 32 bits mask off, and if x > 0.78125, let qx = 0.28125.
 *	   Then
 *		cos(x+y) = (1-qx) - ((x*x/2-qx) - (r-x*y)).
 *	   Note that 1-qx and (x*x/2-qx) is EXACT here, and the
 *	   magnitude of the latter is at least a quarter of x*x/2,
 *	   thus, reducing the rounding error in the subtraction.
 */

const double _one = 1; // 0x3FF00000, 0x00000000
const double _c1 = 4.16666666666666019037e-02; // 0x3FA55555, 0x5555554C
const double _c2 = -1.38888888888741095749e-03; // 0xBF56C16C, 0x16C15177
const double _c3 = 2.48015872894767294178e-05; // 0x3EFA01A0, 0x19CB1590
const double _c4 = -2.75573143513906633035e-07; // 0xBE927E4F, 0x809C52AD
const double _c5 = 2.08757232129817482790e-09; // 0x3E21EE9E, 0xBDB4B1C4
const double _c6 = -1.13596475577881948265e-11; // 0xBDA8FAE9, 0xBE8838D4

/// `__kernel_cos(x, y)`: the cosine on [-pi/4, pi/4]. [y] is the tail of
/// [x].
double _kernelCos(double x, double y) {
  final ax = x.abs();
  // ix < 0x3e400000 <=> |x| < 0x3e400000_00000000 (|x| < 2**-27)
  if (ax < _twoM27) {
    if (x.toInt() == 0) return _one; // generate inexact
  }
  final z = x * x;
  final r = z * (_c1 + z * (_c2 + z * (_c3 + z * (_c4 + z * (_c5 + z * _c6)))));
  // ix < 0x3FD33333 <=> |x| < 0x3fd33333_00000000 (|x| < 0.3)
  if (ax < _c03) {
    return _one - (0.5 * z - (z * r - x * y));
  } else {
    final double qx;
    // ix > 0x3fe90000 <=> |x| >= 0x3fe90001_00000000 (|x| > 0.78125)
    if (ax >= _c078125) {
      qx = 0.28125;
    } else {
      // __HI(qx) = ix-0x00200000; __LO(qx) = 0; (x/4)
      // |x| without its low word, divided by 4. The low word of |x| holds
      // the bits below 2**-22 (|x| < 0.5) or 2**-21 (|x| >= 0.5).
      qx = ax < 0.5
          ? (ax * 4194304.0).floorToDouble() * 5.9604644775390625e-8
          : (ax * 2097152.0).floorToDouble() * 1.1920928955078125e-7;
    }
    final hz = 0.5 * z - qx;
    final a = _one - qx;
    return a - (hz - (z * r - x * y));
  }
}

// e_rem_pio2.c

/* __ieee754_rem_pio2(x,y)
 *
 * return the remainder of x rem pi/2 in y[0]+y[1]
 * use __kernel_rem_pio2()
 */

// Table of constants for 2/pi, 396 Hex digits (476 decimal) of 2/pi
const List<int> _twoOverPi = [
  0xA2F983, 0x6E4E44, 0x1529FC, 0x2757D1, 0xF534DD, 0xC0DB62, //
  0x95993C, 0x439041, 0xFE5163, 0xABDEBB, 0xC561B7, 0x246E3A, //
  0x424DD2, 0xE00649, 0x2EEA09, 0xD1921C, 0xFE1DEB, 0x1CB129, //
  0xA73EE8, 0x8235F5, 0x2EBB44, 0x84E99C, 0x7026B4, 0x5F7E41, //
  0x3991D6, 0x398353, 0x39F49C, 0x845F8B, 0xBDF928, 0x3B1FF8, //
  0x97FFDE, 0x05980F, 0xEF2F11, 0x8B5A0A, 0x6D1F6D, 0x367ECF, //
  0x27CB09, 0xB74F46, 0x3F669E, 0x5FEA2D, 0x7527BA, 0xC7EBE5, //
  0xF17B3D, 0x0739F7, 0x8A5292, 0xEA6BFB, 0x5FB11F, 0x8D5D08, //
  0x560330, 0x46FC7B, 0x6BABF0, 0xCFBC20, 0x9AF436, 0x1DA9E3, //
  0x91615E, 0xE61B08, 0x659985, 0x5F14A0, 0x68408D, 0xFFD880, //
  0x4D7327, 0x310606, 0x1556CA, 0x73A8C9, 0x60E27B, 0xC08C6B, //
];

// The C table npio2_hw holds the high words of n*pi/2 for n = 1..32. The
// test `ix != npio2_hw[n-1]` is `|x| < _npio2Lo[n - 1] ||
// |x| >= _npio2Hi1[n - 1]`.

/// `D(npio2_hw[i])` for each entry of the C table `npio2_hw`.
const List<double> _npio2Lo = [
  1.570796012878418, // 0x3FF921FB
  3.141592025756836, // 0x400921FB
  4.7123870849609375, // 0x4012D97C
  6.283184051513672, // 0x401921FB
  7.853981018066406, // 0x401F6A7A
  9.424774169921875, // 0x4022D97C
  10.995567321777344, // 0x4025FDBB
  12.566368103027344, // 0x402921FB
  14.137161254882812, // 0x402C463A
  15.707962036132812, // 0x402F6A7A
  17.27874755859375, // 0x4031475C
  18.84954833984375, // 0x4032D97C
  20.42034912109375, // 0x40346B9C
  21.991134643554688, // 0x4035FDBB
  23.561935424804688, // 0x40378FDB
  25.132736206054688, // 0x403921FB
  26.703536987304688, // 0x403AB41B
  28.274322509765625, // 0x403C463A
  29.845123291015625, // 0x403DD85A
  31.415924072265625, // 0x403F6A7A
  32.9866943359375, // 0x40407E4C
  34.5574951171875, // 0x4041475C
  36.1282958984375, // 0x4042106C
  37.6990966796875, // 0x4042D97C
  39.2698974609375, // 0x4043A28C
  40.8406982421875, // 0x40446B9C
  42.4114990234375, // 0x404534AC
  43.982269287109375, // 0x4045FDBB
  45.553070068359375, // 0x4046C6CB
  47.123870849609375, // 0x40478FDB
  48.694671630859375, // 0x404858EB
  50.265472412109375, // 0x404921FB
];

/// `D(npio2_hw[i] + 1)` for each entry of the C table `npio2_hw`.
const List<double> _npio2Hi1 = [
  1.5707969665527344, // 0x3FF921FC
  3.1415939331054688, // 0x400921FC
  4.712390899658203, // 0x4012D97D
  6.2831878662109375, // 0x401921FC
  7.853984832763672, // 0x401F6A7B
  9.424781799316406, // 0x4022D97D
  10.995574951171875, // 0x4025FDBC
  12.566375732421875, // 0x402921FC
  14.137168884277344, // 0x402C463B
  15.707969665527344, // 0x402F6A7B
  17.278762817382812, // 0x4031475D
  18.849563598632812, // 0x4032D97D
  20.420364379882812, // 0x40346B9D
  21.99114990234375, // 0x4035FDBC
  23.56195068359375, // 0x40378FDC
  25.13275146484375, // 0x403921FC
  26.70355224609375, // 0x403AB41C
  28.274337768554688, // 0x403C463B
  29.845138549804688, // 0x403DD85B
  31.415939331054688, // 0x403F6A7B
  32.986724853515625, // 0x40407E4D
  34.557525634765625, // 0x4041475D
  36.128326416015625, // 0x4042106D
  37.699127197265625, // 0x4042D97D
  39.269927978515625, // 0x4043A28D
  40.840728759765625, // 0x40446B9D
  42.411529541015625, // 0x404534AD
  43.9822998046875, // 0x4045FDBC
  45.5531005859375, // 0x4046C6CC
  47.1239013671875, // 0x40478FDC
  48.6947021484375, // 0x404858EC
  50.2655029296875, // 0x404921FC
];

/*
 * invpio2:  53 bits of 2/pi
 * pio2_1:   first  33 bit of pi/2
 * pio2_1t:  pi/2 - pio2_1
 * pio2_2:   second 33 bit of pi/2
 * pio2_2t:  pi/2 - (pio2_1+pio2_2)
 * pio2_3:   third  33 bit of pi/2
 * pio2_3t:  pi/2 - (pio2_1+pio2_2+pio2_3)
 */

const double _zero = 0; // 0x00000000, 0x00000000
const double _two24 = 16777216; // 0x41700000, 0x00000000
const double _invpio2 = 6.36619772367581382433e-01; // 0x3FE45F30, 0x6DC9C883
const double _pio2_1 = 1.57079632673412561417e+00; // 0x3FF921FB, 0x54400000
const double _pio2_1t = 6.07710050650619224932e-11; // 0x3DD0B461, 0x1A626331
const double _pio2_2 = 6.07710050630396597660e-11; // 0x3DD0B461, 0x1A600000
const double _pio2_2t = 2.02226624879595063154e-21; // 0x3BA3198A, 0x2E037073
const double _pio2_3 = 2.02226624871116645580e-21; // 0x3BA3198A, 0x2E000000
const double _pio2_3t = 8.47842766036889956997e-32; // 0x397B839A, 0x252049C1

// `tx` of __ieee754_rem_pio2: the three 24-bit parts of a large |x|.
final Float64List _tx = Float64List(3);

/// `__ieee754_rem_pio2(x, y)`: writes the remainder of [x] rem pi/2 in
/// `y[0] + y[1]` and returns the quadrant.
int _ieee754RemPio2(double x, Float64List y) {
  final ax = x.abs();
  // |x| ~<= pi/4, no need for reduction
  // ix <= 0x3fe921fb <=> |x| < 0x3fe921fc_00000000
  if (ax < _pio4Hi1) {
    y[0] = x;
    y[1] = 0;
    return 0;
  }
  // |x| < 3pi/4, special case with n=+-1
  // ix < 0x4002d97c <=> |x| < 0x4002d97c_00000000
  if (ax < _threePio4) {
    // hx > 0 <=> x > 0 (|x| > pi/4 here)
    if (x > 0) {
      var z = x - _pio2_1;
      // ix != 0x3ff921fb <=> |x| < 0x3ff921fb_00000000 ||
      // |x| >= 0x3ff921fc_00000000
      if (ax < _pio2Hi || ax >= _pio2Hi1) {
        // 33+53 bit pi is good enough
        y[0] = z - _pio2_1t;
        y[1] = (z - y[0]) - _pio2_1t;
      } else {
        // near pi/2, use 33+33+53 bit pi
        z -= _pio2_2;
        y[0] = z - _pio2_2t;
        y[1] = (z - y[0]) - _pio2_2t;
      }
      return 1;
    } else {
      // negative x
      var z = x + _pio2_1;
      // ix != 0x3ff921fb, as above
      if (ax < _pio2Hi || ax >= _pio2Hi1) {
        // 33+53 bit pi is good enough
        y[0] = z + _pio2_1t;
        y[1] = (z - y[0]) + _pio2_1t;
      } else {
        // near pi/2, use 33+33+53 bit pi
        z += _pio2_2;
        y[0] = z + _pio2_2t;
        y[1] = (z - y[0]) + _pio2_2t;
      }
      return -1;
    }
  }
  // |x| ~<= 2^19*(pi/2), medium size
  // ix <= 0x413921fb <=> |x| < 0x413921fc_00000000
  if (ax < _medium) {
    var t = ax;
    final n = (t * _invpio2 + _half).toInt();
    final fn = n.toDouble();
    var r = t - fn * _pio2_1;
    var w = fn * _pio2_1t; // 1st round good to 85 bit
    // n<32 && ix != npio2_hw[n-1]
    if (n < 32 && (ax < _npio2Lo[n - 1] || ax >= _npio2Hi1[n - 1])) {
      y[0] = r - w; // quick check no cancellation
    } else {
      final j = (_hi(x) & 0x7fffffff) >> 20;
      y[0] = r - w;
      var i = j - ((_hi(y[0]) >> 20) & 0x7ff);
      if (i > 16) {
        // 2nd iteration needed, good to 118
        t = r;
        w = fn * _pio2_2;
        r = t - w;
        w = fn * _pio2_2t - ((t - r) - w);
        y[0] = r - w;
        i = j - ((_hi(y[0]) >> 20) & 0x7ff);
        if (i > 49) {
          // 3rd iteration need, 151 bits acc
          t = r; // will cover all possible cases
          w = fn * _pio2_3;
          r = t - w;
          w = fn * _pio2_3t - ((t - r) - w);
          y[0] = r - w;
        }
      }
    }
    y[1] = (r - y[0]) - w;
    // hx < 0 <=> x < 0 (|x| > pi/4 here)
    if (x < 0) {
      y[0] = -y[0];
      y[1] = -y[1];
      return -n;
    } else {
      return n;
    }
  }
  // all other (large) arguments
  final hx = _hi(x);
  final ix = hx & 0x7fffffff;
  if (ix >= 0x7ff00000) {
    // x is inf or NaN
    y[0] = y[1] = x - x;
    return 0;
  }
  // set z = scalbn(|x|,ilogb(x)-23)
  final e0 = (ix >> 20) - 1046; // e0 = ilogb(z)-23;
  var z = _fromWords(ix - (e0 << 20), _lo(x));
  for (var i = 0; i < 2; i++) {
    _tx[i] = z.toInt().toDouble();
    z = (z - _tx[i]) * _two24;
  }
  _tx[2] = z;
  var nx = 3;
  while (_tx[nx - 1] == _zero) {
    nx--; // skip zero term
  }
  final n = _kernelRemPio2(_tx, y, e0, nx, 2, _twoOverPi);
  if (hx < 0) {
    y[0] = -y[0];
    y[1] = -y[1];
    return -n;
  }
  return n;
}

// k_rem_pio2.c

/*
 * __kernel_rem_pio2(x,y,e0,nx,prec,ipio2)
 * double x[],y[]; int e0,nx,prec; int ipio2[];
 *
 * __kernel_rem_pio2 return the last three digits of N with
 *		y = x - N*pi/2
 * so that |y| < pi/2.
 *
 * The method is to compute the integer (mod 8) and fraction parts of
 * (2/pi)*x without doing the full multiplication. In general we
 * skip the part of the product that are known to be a huge integer (
 * more accurately, = 0 mod 8 ). Thus the number of operations are
 * independent of the exponent of the input.
 *
 * (The full description of the parameters and of the local variables
 * is in third_party/fdlibm/k_rem_pio2.c.)
 */

// initial value for jk
const List<int> _initJk = [2, 3, 4, 6];

const List<double> _pio2 = [
  1.57079625129699707031e+00, // 0x3FF921FB, 0x40000000
  7.54978941586159635335e-08, // 0x3E74442D, 0x00000000
  5.39030252995776476554e-15, // 0x3CF84698, 0x80000000
  3.28200341580791294123e-22, // 0x3B78CC51, 0x60000000
  1.27065575308067607349e-29, // 0x39F01B83, 0x80000000
  1.22933308981111328932e-36, // 0x387A2520, 0x40000000
  2.73370053816464559624e-44, // 0x36E38222, 0x80000000
  2.16741683877804819444e-51, // 0x3569F31D, 0x00000000
];

const double _twon24 = 5.96046447753906250000e-08; // 0x3E700000, 0x00000000

/// `__kernel_rem_pio2(x, y, e0, nx, prec, ipio2)`: the reduction of a large
/// argument. The port keeps only the `prec` 2 of the only caller.
int _kernelRemPio2(
  Float64List x,
  Float64List y,
  int e0,
  int nx,
  int prec,
  List<int> ipio2,
) {
  final iq = Int32List(20);
  final f = Float64List(20);
  final fq = Float64List(20);
  final q = Float64List(20);

  // initialize jk
  final jk = _initJk[prec];
  final jp = jk;

  // determine jx,jv,q0, note that 3>q0
  final jx = nx - 1;
  var jv = (e0 - 3) ~/ 24;
  if (jv < 0) jv = 0;
  var q0 = e0 - 24 * (jv + 1);

  // set up f[0] to f[jx+jk] where f[jx+jk] = ipio2[jv+jk]
  var j = jv - jx;
  final m = jx + jk;
  for (var i = 0; i <= m; i++, j++) {
    f[i] = (j < 0) ? _zero : ipio2[j].toDouble();
  }

  // compute q[0],q[1],...q[jk]
  for (var i = 0; i <= jk; i++) {
    var fw = 0.0;
    for (j = 0; j <= jx; j++) {
      fw += x[j] * f[jx + i - j];
    }
    q[i] = fw;
  }

  var jz = jk;
  double z;
  int n;
  int ih;
  int i;
  int carry;
  // recompute:
  for (;;) {
    // distill q[] into iq[] reversingly
    i = 0;
    j = jz;
    z = q[jz];
    for (; j > 0; i++, j--) {
      final fw = (_twon24 * z).toInt().toDouble();
      iq[i] = (z - _two24 * fw).toInt();
      z = q[j - 1] + fw;
    }

    // compute n
    z = _scalbn(z, q0); // actual value of z
    z -= 8.0 * (z * 0.125).floorToDouble(); // trim off integer >= 8
    n = z.toInt();
    z -= n.toDouble();
    ih = 0;
    if (q0 > 0) {
      // need iq[jz-1] to determine n
      i = iq[jz - 1] >> (24 - q0);
      n += i;
      iq[jz - 1] -= i << (24 - q0);
      ih = iq[jz - 1] >> (23 - q0);
    } else if (q0 == 0) {
      ih = iq[jz - 1] >> 23;
    } else if (z >= 0.5) {
      ih = 2;
    }

    if (ih > 0) {
      // q > 0.5
      n += 1;
      carry = 0;
      for (i = 0; i < jz; i++) {
        // compute 1-q
        j = iq[i];
        if (carry == 0) {
          if (j != 0) {
            carry = 1;
            iq[i] = 0x1000000 - j;
          }
        } else {
          iq[i] = 0xffffff - j;
        }
      }
      if (q0 > 0) {
        // rare case: chance is 1 in 12
        switch (q0) {
          case 1:
            iq[jz - 1] &= 0x7fffff;
          case 2:
            iq[jz - 1] &= 0x3fffff;
        }
      }
      if (ih == 2) {
        z = _one - z;
        if (carry != 0) z -= _scalbn(_one, q0);
      }
    }

    // check if recomputation is needed
    if (z == _zero) {
      j = 0;
      for (i = jz - 1; i >= jk; i--) {
        j |= iq[i];
      }
      if (j == 0) {
        // need recomputation
        var k = 1;
        while (iq[jk - k] == 0) {
          k++; // k = no. of terms needed
        }

        for (i = jz + 1; i <= jz + k; i++) {
          // add q[jz+1] to q[jz+k]
          f[jx + i] = ipio2[jv + i].toDouble();
          var fw = 0.0;
          for (j = 0; j <= jx; j++) {
            fw += x[j] * f[jx + i - j];
          }
          q[i] = fw;
        }
        jz += k;
        continue; // goto recompute
      }
    }
    break;
  }

  // chop off zero terms
  if (z == 0.0) {
    jz -= 1;
    q0 -= 24;
    while (iq[jz] == 0) {
      jz--;
      q0 -= 24;
    }
  } else {
    // break z into 24-bit if necessary
    z = _scalbn(z, -q0);
    if (z >= _two24) {
      final fw = (_twon24 * z).toInt().toDouble();
      iq[jz] = (z - _two24 * fw).toInt();
      jz += 1;
      q0 += 24;
      iq[jz] = fw.toInt();
    } else {
      iq[jz] = z.toInt();
    }
  }

  // convert integer "bit" chunk to floating-point value
  var fw = _scalbn(_one, q0);
  for (i = jz; i >= 0; i--) {
    q[i] = fw * iq[i].toDouble();
    fw *= _twon24;
  }

  // compute PIo2[0,...,jp]*q[jz,...,0]
  for (i = jz; i >= 0; i--) {
    fw = 0.0;
    for (var k = 0; k <= jp && k <= jz - i; k++) {
      fw += _pio2[k] * q[i + k];
    }
    fq[jz - i] = fw;
  }

  // compress fq[] into y[]: the case 1 and 2 of `switch (prec)`
  fw = 0.0;
  for (i = jz; i >= 0; i--) {
    fw += fq[i];
  }
  y[0] = (ih == 0) ? fw : -fw;
  fw = fq[0] - fw;
  for (i = 1; i <= jz; i++) {
    fw += fq[i];
  }
  y[1] = (ih == 0) ? fw : -fw;
  return n & 7;
}

// s_scalbn.c

/*
 * scalbn (double x, int n)
 * scalbn(x,n) returns x* 2**n  computed by  exponent
 * manipulation rather than by actually performing an
 * exponentiation or a multiplication.
 */

const double _two54 = 18014398509481984; // 0x43500000, 0x00000000
const double _twom54 = 5.55111512312578270212e-17; // 0x3C900000, 0x00000000
const double _huge = 1.0e+300;
const double _tiny = 1.0e-300;

/// `scalbn(x, n)`: [x] times 2**[n], by a change of the exponent.
double _scalbn(double x, int n) {
  var hx = _hi(x);
  final lx = _lo(x);
  var k = (hx & 0x7ff00000) >> 20; // extract exponent
  if (k == 0) {
    // 0 or subnormal x
    if ((lx | (hx & 0x7fffffff)) == 0) return x; // +-0
    x *= _two54;
    hx = _hi(x);
    k = ((hx & 0x7ff00000) >> 20) - 54;
    if (n < -50000) return _tiny * x; // underflow
  }
  if (k == 0x7ff) return x + x; // NaN or Inf
  k = k + n;
  if (k > 0x7fe) return _huge * _copysign(_huge, x); // overflow
  if (k > 0) {
    // normal result
    return _fromWords(((hx & 0x800fffff) | (k << 20)).toSigned(32), _lo(x));
  }
  if (k <= -54) {
    if (n > 50000) {
      // in case integer overflow in n+k
      return _huge * _copysign(_huge, x); // overflow
    } else {
      return _tiny * _copysign(_tiny, x); // underflow
    }
  }
  k += 54; // subnormal result
  x = _fromWords(((hx & 0x800fffff) | (k << 20)).toSigned(32), _lo(x));
  return x * _twom54;
}

/// `copysign(x, y)` of `s_copysign.c`, which is not ported: [x] with the
/// sign of [y].
double _copysign(double x, double y) => (_hi(y) < 0) == (x < 0) ? x : -x;
