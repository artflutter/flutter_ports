// Original code, not ported from Chart.js: V8 Math.sin and Math.cos reference generator.
//
// It writes test/port/js/trig_reference.dart, the data of
// test/port/js/fdlibm_trig_test.dart: 4,040 inputs, each with the bits of
// Math.sin(x) and Math.cos(x), and the Node.js version, V8 version and
// architecture in the header (Chart.js ADR 0032 section 2). The inputs are
// deterministic, so a rerun on the same Node.js writes the same file. Nothing
// in lib/ or test/ runs this script (porting-flow.md section 4).
//
// Usage, from packages/flutter_chartjs, with an x64 build of Node.js v24.12.0
// (on Apple silicon, the darwin-x64 build runs under Rosetta):
//
//   node tool/reference/trig_reference.mjs
//
// The reference is V8 13.6 on x64 (Chart.js ADR 0032), and the script stops
// on any other architecture. V8 on arm64 compiles fdlibm with fused
// multiply-add and differs in the last bit for some inputs.
//
// The input groups, in this order:
// - special (25): +-0, NaN, +-Infinity, the smallest subnormal and normal,
//   the largest double, +-1, multiples of pi/4 and 1e22;
// - ties (3): the half angles of the hit ties of phase 7;
// - bounds (180): each bound of the high-word tests of s_sin.c, s_cos.c,
//   k_sin.c, k_cos.c and e_rem_pio2.c, -4 to +4 ulp, both signs;
// - npio2_hw (640): D(hw) and D(hw + 1) of the 32 entries of the table
//   npio2_hw of e_rem_pio2.c, -2 to +2 ulp, both signs;
// - n*pi/2 (600): n = 1..100 and 20 random n up to 100,000, -2 to +2 ulp;
// - chart angles (800): the whole degrees -360..360 and 79 random half
//   angles (a + b) / 2 with a and b in [-pi/2, 3pi/2);
// - uniform 10 (600), uniform 1e6 (300), large (400: the __kernel_rem_pio2
//   path up to the largest double), small (250: [2**-30, pi/4)) and tiny
//   (202: subnormals and |x| < 2**-27);
// - reduced tiny (40): n*pi/2 + d with 2**-27 <= |d| < 2**-26, n = 1..10.
//   The reduced argument has a tail (iy = 1), so the 2**-27 bound of
//   __kernel_sin (k_sin.c) changes the result.

import {writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';

if (process.arch !== 'x64') {
  console.error(
    `The reference is V8 on x64; this Node.js is ${process.arch}. ` +
      'Run an x64 build of Node.js.',
  );
  process.exit(1);
}

const TOTAL = 4040;
const OUT = fileURLToPath(
  new URL('../../test/port/js/trig_reference.dart', import.meta.url),
);

const view = new DataView(new ArrayBuffer(8));

/** The double whose IEEE-754 words are `hi` and `lo`. */
function fromWords(hi, lo) {
  view.setUint32(0, hi >>> 0);
  view.setUint32(4, lo >>> 0);
  return view.getFloat64(0);
}

/** The 16 hex digits of the bits of `x`. */
function hex(x) {
  view.setFloat64(0, x);
  return (
    view.getUint32(0).toString(16).padStart(8, '0') +
    view.getUint32(4).toString(16).padStart(8, '0')
  );
}

/** The double `steps` units in the last place away from finite `x` > 0. */
function ulpStep(x, steps) {
  view.setFloat64(0, x);
  view.setBigUint64(0, view.getBigUint64(0) + BigInt(steps));
  return view.getFloat64(0);
}

/** Marsaglia's xorshift32, from a fixed seed. */
let state = 0x3c6ef372;
function next32() {
  state ^= state << 13;
  state ^= state >>> 17;
  state ^= state << 5;
  return state >>> 0;
}

/** A random double in [0, 1), from 53 random bits. */
function unit() {
  return ((next32() >>> 11) * 2 ** 32 + next32()) / 2 ** 53;
}

/** A random sign: 1 or -1. */
function sign() {
  return next32() & 1 ? -1 : 1;
}

/** A random double with the biased exponent `e` and a random sign. */
function random(e) {
  return fromWords(
    ((next32() & 1) << 31) | (e << 20) | (next32() & 0xfffff),
    next32(),
  );
}

const inputs = [];

/** Adds the inputs of one group and checks their count. */
function group(name, count, values) {
  if (values.length !== count) {
    throw new Error(`${name}: ${values.length} inputs, expected ${count}`);
  }
  inputs.push(...values);
}

// special
group('special', 25, [
  0, -0, NaN, Infinity, -Infinity, Number.MIN_VALUE, -Number.MIN_VALUE,
  2.2250738585072014e-308, -2.2250738585072014e-308, Number.MAX_VALUE,
  -Number.MAX_VALUE, 1, -1, Math.PI / 4, -Math.PI / 4, Math.PI / 2,
  -Math.PI / 2, Math.PI, -Math.PI, (3 * Math.PI) / 2, (-3 * Math.PI) / 2,
  2 * Math.PI, -2 * Math.PI, 1e22, -1e22,
]);

// ties: CI run 39544591156 (Windows), the second arc of the same case, and
// sin(7π/6), where the macOS libm gives another last bit.
group('ties', 3, [-0.7853981633974483, 2.356194490192345, 3.665191429188092]);

// bounds: D(H) for each high-word constant H of the tests, -4 to +4 ulp.
{
  const values = [];
  for (const h of [
    0x3e400000, 0x3fd33333, 0x3fe00000, 0x3fe90001, 0x3fe921fc, 0x3ff921fb,
    0x3ff921fc, 0x4002d97c, 0x413921fc, 0x3fe921fb,
  ]) {
    for (let steps = -4; steps <= 4; steps++) {
      const x = ulpStep(fromWords(h, 0), steps);
      values.push(x, -x);
    }
  }
  group('bounds', 180, values);
}

// npio2_hw: D(hw) and D(hw + 1), -2 to +2 ulp.
{
  const npio2Hw = [
    0x3ff921fb, 0x400921fb, 0x4012d97c, 0x401921fb, 0x401f6a7a, 0x4022d97c,
    0x4025fdbb, 0x402921fb, 0x402c463a, 0x402f6a7a, 0x4031475c, 0x4032d97c,
    0x40346b9c, 0x4035fdbb, 0x40378fdb, 0x403921fb, 0x403ab41b, 0x403c463a,
    0x403dd85a, 0x403f6a7a, 0x40407e4c, 0x4041475c, 0x4042106c, 0x4042d97c,
    0x4043a28c, 0x40446b9c, 0x404534ac, 0x4045fdbb, 0x4046c6cb, 0x40478fdb,
    0x404858eb, 0x404921fb,
  ];
  const values = [];
  for (const hw of npio2Hw) {
    for (const h of [hw, hw + 1]) {
      for (let steps = -2; steps <= 2; steps++) {
        const x = ulpStep(fromWords(h, 0), steps);
        values.push(x, -x);
      }
    }
  }
  group('npio2_hw', 640, values);
}

// n*pi/2: n = 1..100 and 20 random n up to 100,000, -2 to +2 ulp, a random
// sign.
{
  const ns = [];
  for (let n = 1; n <= 100; n++) ns.push(n);
  for (let k = 0; k < 20; k++) ns.push(1 + (next32() % 100000));
  const values = [];
  for (const n of ns) {
    for (let steps = -2; steps <= 2; steps++) {
      values.push(sign() * ulpStep(n * (Math.PI / 2), steps));
    }
  }
  group('n*pi/2', 600, values);
}

// chart angles: the whole degrees, and the half angles of random arcs.
{
  const values = [];
  for (let d = -360; d <= 360; d++) values.push(d * (Math.PI / 180));
  for (let k = 0; k < 79; k++) {
    const a = -Math.PI / 2 + unit() * 2 * Math.PI;
    const b = -Math.PI / 2 + unit() * 2 * Math.PI;
    values.push((a + b) / 2);
  }
  group('chart angles', 800, values);
}

// uniform 10: [-10, 10).
{
  const values = [];
  for (let k = 0; k < 600; k++) values.push(-10 + unit() * 20);
  group('uniform 10', 600, values);
}

// uniform 1e6: [-1e6, 1e6).
{
  const values = [];
  for (let k = 0; k < 300; k++) values.push(-1e6 + unit() * 2e6);
  group('uniform 1e6', 300, values);
}

// large: biased exponents 0x413 to 0x7fe, the __kernel_rem_pio2 path.
{
  const values = [];
  for (let k = 0; k < 400; k++) {
    values.push(random(0x413 + (next32() % (0x7fe - 0x413 + 1))));
  }
  group('large', 400, values);
}

// small: [2**-30, pi/4), a random sign.
{
  const values = [];
  for (let k = 0; k < 250; k++) {
    values.push(sign() * (2 ** -30 + unit() * (Math.PI / 4 - 2 ** -30)));
  }
  group('small', 250, values);
}

// tiny: biased exponents 0 to 0x3e3 (subnormals and |x| < 2**-27).
{
  const values = [];
  for (let k = 0; k < 202; k++) values.push(random(next32() % 0x3e4));
  group('tiny', 202, values);
}

// reduced tiny: n*pi/2 + d, with d = +-1.25 * 2**-27 (below 1e-8) and
// d = +-1.75 * 2**-27. The error of n * (Math.PI / 2) is below 2**-48 for
// these n, so the reduced argument stays in [2**-27, 2**-26). A mutation
// probe found that inputs of this group detect a move of the 2**-27 bound of
// __kernel_sin to 2**-26 or to 1e-8. The group uses no random numbers, so the
// inputs of the groups above do not change.
{
  const values = [];
  for (let n = 1; n <= 10; n++) {
    for (const k of [1.25, -1.25, 1.75, -1.75]) {
      values.push(n * (Math.PI / 2) + k * 2 ** -27);
    }
  }
  group('reduced tiny', 40, values);
}

if (inputs.length !== TOTAL) {
  throw new Error(`${inputs.length} inputs, expected ${TOTAL}`);
}

const lines = inputs.map(
  (x) => `${hex(x)} ${hex(Math.sin(x))} ${hex(Math.cos(x))}`,
);

const dart = `// Original code, not ported from Chart.js: V8 sine and cosine reference data.

// Generated by tool/reference/trig_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// fdlibm 5.3 without fused multiply-add. ${lines.length} inputs.

/// The Node.js version that generated [trigReference].
const String trigReferenceNode = '${process.version}';

/// The V8 version that generated [trigReference].
const String trigReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated [trigReference].
const String trigReferenceArch = '${process.arch}';

/// \`x\`, V8 \`Math.sin(x)\` and V8 \`Math.cos(x)\` as IEEE-754 bit patterns in
/// hex, one triple per line.
const String trigReference = '''
${lines.join('\n')}
''';
`;

writeFileSync(OUT, dart);
console.log(`Wrote ${lines.length} inputs to ${OUT}`);
