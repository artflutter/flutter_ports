// Original code, not ported from Chart.js: V8 Math.hypot reference generator.
//
// It writes test/port/js/hypot_reference.dart, the data of
// test/port/js/js_math_hypot_test.dart: 3,000 (a, b) inputs, each with the
// bits of Math.hypot(a, b), and the Node.js version, V8 version and
// architecture in the header. The inputs are deterministic, so a rerun on the
// same Node.js writes the same file. Nothing in lib/ or test/ runs this script
// (porting-flow.md section 4).
//
// Usage, from packages/flutter_chartjs_port, with the darwin-arm64 build of
// Node.js v24.22.1 (Chart.js ADR 0045):
//
//   node tool/reference/hypot_reference.mjs
//
// The reference is V8 13.6 on arm64 (Chart.js ADR 0045). The script does not
// stop on another architecture: the test pins the Node.js version and the
// architecture of the data. The V8 builtin MathHypot divides each operand by
// the larger magnitude, adds the squares and multiplies the square root by
// that magnitude. Each step is a correctly rounded IEEE operation, so other
// engines that compute the same form give the same bits. The plain form
// Math.sqrt(a * a + b * b) differs in the last bit for about one pair in
// three, and it overflows and underflows (Chart.js ADR 0108).

import {writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';

const TOTAL = 3000;
const OUT = fileURLToPath(
  new URL('../../test/port/js/hypot_reference.dart', import.meta.url),
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

/** Marsaglia's xorshift32, from a fixed seed. */
let state = 0x3c6ef372;
function next32() {
  state ^= state << 13;
  state ^= state >>> 17;
  state ^= state << 5;
  return state >>> 0;
}

/** A random double with the biased exponent `e` and a random sign. */
function random(e) {
  return fromWords(
    ((next32() & 1) << 31) | (e << 20) | (next32() & 0xfffff),
    next32(),
  );
}

const inputs = [];
const seen = new Set();
function add(a, b) {
  const key = `${hex(a)} ${hex(b)}`;
  if (seen.has(key) || inputs.length >= TOTAL) return;
  seen.add(key);
  inputs.push([a, b]);
}

// Every pair of special values: the infinities before NaN, the zeros, the
// subnormals, the bounds of the normal range and the overflow of the squares.
const special = [
  0, -0, Infinity, -Infinity, NaN, 1, -1, 2, 0.5, 3, 4, Math.PI,
  Number.MIN_VALUE, -Number.MIN_VALUE, 2 ** -1022, Number.MAX_VALUE,
  -Number.MAX_VALUE, 1e300, -1e300, 1e-300, 1e200, 1e-200,
];
for (const a of special) for (const b of special) add(a, b);

// Pythagorean triples, also scaled by powers of two: the result is exact.
const triples = [
  [3, 4], [5, 12], [8, 15], [7, 24], [20, 21], [12, 35], [9, 40], [28, 45],
  [11, 60], [33, 56], [16, 63], [48, 55], [13, 84], [36, 77], [39, 80],
  [65, 72],
];
for (const [a, b] of triples) {
  for (const k of [-1074, -1060, -600, -40, -1, 0, 1, 40, 600, 1000]) {
    add(a * 2 ** k, b * 2 ** k);
    add(-b * 2 ** k, a * 2 ** k);
  }
}

// Equal magnitudes, with both signs.
for (let n = 0; n < 60; n++) {
  const x = random(1 + (next32() % 2046));
  add(x, x);
  add(x, -x);
}

// Pointer deltas as the pinch and the pan of chartjs-plugin-zoom compute them
// (gestures.ts:38, :258): differences of client coordinates in CSS pixels,
// with fractions of a device pixel.
for (let n = 0; n < 700; n++) {
  const scale = [1, 2, 3, 4, 100][next32() % 5];
  const coordinate = () => (next32() % 400000) / scale / 100;
  add(coordinate() - coordinate(), coordinate() - coordinate());
}

// Small integers: the deltas of whole pixels.
for (let n = 0; n < 200; n++) {
  add((next32() % 2001) - 1000, (next32() % 2001) - 1000);
}

// Subnormal operands: both subnormal, or one subnormal and one normal.
for (let n = 0; n < 100; n++) {
  const sub = () =>
    fromWords(((next32() & 1) << 31) | (next32() & 0xfffff), next32());
  add(sub(), sub());
  add(sub(), random(1 + (next32() % 60)));
}

// Squares that overflow or underflow in the plain form.
for (let n = 0; n < 150; n++) {
  add(random(1900 + (next32() % 147)), random(1900 + (next32() % 147)));
  add(random(1 + (next32() % 140)), random(1 + (next32() % 140)));
}

// Exponents far apart, where the smaller square vanishes next to 1.
for (let n = 0; n < 150; n++) {
  const e = 100 + (next32() % 1800);
  const d = 26 + (next32() % 40);
  add(random(e), random(Math.max(1, e - d)));
}

// Random doubles over the whole range.
for (let n = 0; n < 200; n++) add(random(next32() % 2047), random(next32() % 2047));

// Random doubles with exponents within 30 of each other.
while (inputs.length < TOTAL) {
  const e = 1 + (next32() % 2045);
  const d = (next32() % 61) - 30;
  add(random(e), random(Math.min(2046, Math.max(1, e + d))));
}

const lines = inputs.map(([a, b]) => `${hex(a)} ${hex(b)} ${hex(Math.hypot(a, b))}`);

const dart = `// Original code, not ported from Chart.js: V8 Math.hypot reference data.

// Generated by tool/reference/hypot_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// Math.hypot(a, b) for ${lines.length} inputs.

/// The Node.js version that generated [hypotReference].
const String hypotReferenceNode = '${process.version}';

/// The V8 version that generated [hypotReference].
const String hypotReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated [hypotReference].
const String hypotReferenceArch = '${process.arch}';

/// \`a\`, \`b\` and V8 \`Math.hypot(a, b)\` as IEEE-754 bit patterns in hex, one
/// triple per line.
const String hypotReference = '''
${lines.join('\n')}
''';
`;

writeFileSync(OUT, dart);
console.log(`Wrote ${lines.length} inputs to ${OUT}`);
