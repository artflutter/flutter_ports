// Original code, not ported from Chart.js: Intl.NumberFormat reference generator.
//
// It writes test/port/js/intl_reference.dart, the data of
// test/port/js/js_intl_test.dart: V8 strings of the upstream formatNumber
// (third_party/Chart.js/src/helpers/helpers.intl.ts) in the value ranges of
// the guards of lib/src/js/js_intl.dart (Chart.js ADR 0026):
// - `large`: numbers at and above 2^53 in the standard notation, where
//   package:intl writes other digits and the VM overflows above 2^63;
// - `nonfinite`: NaN and the infinities in each style and notation;
// - `scientific`: scientific notation around each power of ten, where the
//   rounding of the mantissa carries into the exponent;
// - `compact`: compact notation from 2^53 units, where package:intl writes
//   other digits, and the VM overflows from 2^63 units;
// - `fraction`: the standard notation below 2^53 with more than 15
//   fraction digits, where the adapter gives package:intl only 15.
// The option sets are the options that Chart.js passes: no options
// (getLabelForValue with the default ticks.format, scale.linearbase.js:311,
// and the doughnut and polar area labels), the options of
// formatters.numeric (core.ticks.js:56-57) and some ticks.format objects of
// a user. Each group is one locale and one option set.
//
// The sets keep out the known differences of differences.md row
// adapt-intl-number-format: the binary rounding of package:intl below 2^53,
// the CLDR data, the grouping of compact notation, the unit that
// package:intl selects for compact notation, and the cap of 15 fraction
// digits for significant digits and compact notation below 2^53. The
// compact sets turn off the grouping, and use only digit options with which
// package:intl selects the unit of V8 on each platform. Thus the port gives
// the V8 string for every case.
//
// The header records the Node.js version, the V8, ICU and CLDR versions and
// the architecture. The values are deterministic, so a rerun on the same
// Node.js writes the same file. Nothing in lib/ or test/ runs this script
// (porting-flow.md section 4). Check out the submodules first
// (`dart run melos run upstream`).
//
// Usage, from packages/flutter_chartjs, with an x64 build of Node.js v24.12.0
// (on Apple silicon, the darwin-x64 build runs under Rosetta):
//
//   node tool/reference/intl_reference.mjs
//
// The reference is V8 13.6 with ICU 77.1 on x64 (Chart.js ADR 0010), and
// the script stops on any other architecture.

import {existsSync, writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';

if (process.arch !== 'x64') {
  console.error(
    `The reference is V8 on x64; this Node.js is ${process.arch}. ` +
      'Run an x64 build of Node.js.',
  );
  process.exit(1);
}

const SOURCE = new URL(
  '../../../../third_party/Chart.js/src/helpers/helpers.intl.ts',
  import.meta.url,
);
const OUT = fileURLToPath(
  new URL('../../test/port/js/intl_reference.dart', import.meta.url),
);

if (!existsSync(fileURLToPath(SOURCE))) {
  console.error(
    `${fileURLToPath(SOURCE)} is missing. ` +
      'Check out the submodules with `dart run melos run upstream`.',
  );
  process.exit(1);
}

// Node.js strips the types of the upstream TypeScript file.
const {formatNumber} = await import(SOURCE.href);

const view = new DataView(new ArrayBuffer(8));

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
let state = 0x2545f491;
function next32() {
  state ^= state << 13;
  state ^= state >>> 17;
  state ^= state << 5;
  return state >>> 0;
}

/** The distinct values of `list`, by their bits, in their order. */
function distinct(list) {
  const seen = new Set();
  return list.filter((x) => {
    const key = hex(x);
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

/** Every `n`th value of `list`. */
const every = (list, n) => list.filter((_, i) => i % n === 0);

/** The options of formatters.numeric with `digits` fraction digits. */
const ticks = (digits, notation) => ({
  notation,
  minimumFractionDigits: digits,
  maximumFractionDigits: digits,
});

// The standard notation at and above 2^53.
const largePositive = [];
// The powers of two from 2^52 to 2^80. Next to 2^52, 2^53, 2^63 and 2^64,
// also their neighbours. Below 2^53, the fractions are halves: package:intl
// writes them as V8 does.
for (let k = 52; k <= 80; k++) {
  const steps = [52, 53, 63, 64].includes(k) ? [-3, -2, -1, 0, 1, 2, 3] : [0];
  for (const step of steps) largePositive.push(ulpStep(2 ** k, step));
}
// 1e15, and the powers of ten from 1e16 to 1e25 with their neighbours. The
// neighbours of 1e15 have binary fractions, which package:intl writes.
largePositive.push(1e15);
for (let e = 16; e <= 25; e++) {
  for (const steps of [-1, 0, 1]) {
    largePositive.push(ulpStep(Number(`1e${e}`), steps));
  }
}
// Values whose rounding to one or three significant digits carries, and
// some long numbers.
largePositive.push(
  9.2e18, 9.3e18, 9.995e18, 9.9951e18, 9.9949e18, 9.5e20, 9.9999e22,
  1.2345678901234568e20, 9.999999999999999e22, 1e21 - 65536, 2 ** 100,
  1e50, 1e100, Number.MAX_VALUE,
);
// Random values from 2^53 to 2^90.
for (let n = 0; n < 16; n++) {
  const mantissa = 1 + next32() / 2 ** 32 + next32() / 2 ** 64;
  largePositive.push(mantissa * 2 ** (53 + (next32() % 38)));
}
const large = distinct([
  ...largePositive,
  ...every(largePositive, 3).map((x) => -x),
]);

/**
 * The values of scientific notation with `digits` digits: each power of
 * ten from 1e-12 to 1e25 and its neighbours, the values below it whose
 * mantissa rounds up to 10 (9.5, 9.95, ... at the precision) or not
 * (9.4999...), and a tie above it. Then the subnormal numbers, the smallest
 * normal number, the largest number and zero.
 */
function scientificValues(digits) {
  const nines = '9'.repeat(digits - 1);
  const carry = `9.${nines}5`;
  const below = `9.${nines}4999`;
  const tie = `1.${'0'.repeat(digits - 1)}5`;
  const list = [];
  for (let e = -12; e <= 25; e++) {
    for (const steps of [-1, 0, 1]) list.push(ulpStep(Number(`1e${e}`), steps));
    list.push(Number(`${carry}e${e - 1}`), Number(`${below}e${e - 1}`));
    list.push(Number(`${tie}e${e}`));
  }
  list.push(
    5e-324, 1e-320, 1.5e-320, 2.2250738585072014e-308, 2.3e-308, 9.99e20,
    9.5e-7, Number.MAX_VALUE, 0,
  );
  return distinct([...list, ...every(list, 4).map((x) => -x)]);
}

// From 9.5e14 to 1.05e15 in steps of 1e12.
const dense = [];
for (let i = 950; i <= 1050; i++) dense.push(i * 1e12);

const nonFinite = [NaN, Infinity, -Infinity];

/**
 * The values of compact notation from 2^53 units of `locale`: the first
 * three doubles from 2^53 units, values whose rounding to one or three
 * significant digits carries, random values from 2^53 units to 2^1000, and
 * the largest number. The unit is the unit of V8 for 1e18, the largest unit
 * of the locale.
 */
function compactValues(locale) {
  const count = new Intl.NumberFormat(locale, {
    notation: 'compact',
    useGrouping: false,
    numberingSystem: 'latn',
  })
    .formatToParts(1e18)
    .filter((part) => part.type === 'integer')
    .map((part) => part.value)
    .join('');
  const unit = 19 - count.length;
  const start = 2 ** 53 * 10 ** unit;
  const list = [0, 1, 2].map((steps) => ulpStep(start, steps));
  for (const e of [16, 17, 20, 25]) {
    list.push(
      Number(`9.5e${e + unit}`),
      Number(`9.95e${e + unit}`),
      Number(`9.9951e${e + unit}`),
      Number(`1.2345678e${e + unit}`),
    );
  }
  for (let n = 0; n < 8; n++) {
    const mantissa = 1 + next32() / 2 ** 32;
    list.push(mantissa * 2 ** (100 + (next32() % 900)));
  }
  list.push(Number.MAX_VALUE);
  const values = list.filter((x) => x >= start);
  return distinct([...values, ...every(values, 3).map((x) => -x)]);
}

/**
 * The values of the standard notation below 2^53 with more than 15 fraction
 * digits: the ticks of data with rounding errors (0.1 + 0.2 and 0.3), small
 * values, values whose digits after the last fraction digit round to 0 or
 * to 1 in the last place, long numbers, random values from 1e-20 to 1e16,
 * and zero.
 */
function fractionValues() {
  const list = [
    0.1 + 0.2, 0.3, 0.1 * 7, 0.7, 1.1000000000000001, 0.010000000000000002,
    0.00100000000000001, 1e-17, 1.2345678e-17, 5e-21, 4.9999e-21, 9.5e-21,
    1.5e-20, 2.5e-20, 0.5, 1 / 3, 2 / 3, 123.456, 999999999999999.9,
    4503599627370495.5, 2 ** 53 - 1,
  ];
  for (let n = 0; n < 24; n++) {
    list.push((next32() / 2 ** 32) * 10 ** ((next32() % 36) - 20));
  }
  return distinct([0, -0, ...list, ...every(list, 3).map((x) => -x)]);
}

/** The groups: a section, a locale, an option set and a list of values. */
const groups = [
  ...[
    {},
    ticks(0),
    ticks(2),
    {maximumSignificantDigits: 1},
    {maximumSignificantDigits: 3},
    {minimumSignificantDigits: 21},
    {style: 'percent'},
    {style: 'currency', currency: 'USD'},
    {style: 'currency', currency: 'JPY'},
    {useGrouping: false},
    {minimumIntegerDigits: 21},
  ].map((options) => ['large', 'en-US', options, large]),
  // More than 15 fraction digits from 2^53. The section `fraction` has
  // these options below 2^53.
  [
    'large',
    'en-US',
    {minimumFractionDigits: 20},
    large.filter((x) => Math.abs(x) >= 2 ** 53),
  ],
  ...[
    ['de-DE', {}],
    ['de-DE', {style: 'currency', currency: 'EUR'}],
    ['en-IN', {}],
    ['en-IN', {style: 'percent'}],
    ['fr', {}],
    ['ar-EG', {}],
    ['ja', {maximumSignificantDigits: 3}],
  ].map(([locale, options]) => ['large', locale, options, every(large, 4)]),
  ...[
    {},
    ticks(1),
    {style: 'percent'},
    {style: 'currency', currency: 'USD'},
    {style: 'currency', currency: 'EUR'},
    {style: 'currency', currency: 'JPY'},
    {notation: 'scientific'},
    {notation: 'compact'},
  ].map((options) => ['nonfinite', 'en-US', options, nonFinite]),
  ...['de-DE', 'fr', 'en-IN', 'ja', 'tr', 'ar-EG'].flatMap((locale) =>
    [
      {},
      {style: 'percent'},
      {style: 'currency', currency: 'EUR'},
      {notation: 'scientific'},
    ].map((options) => ['nonfinite', locale, options, nonFinite]),
  ),
  ...[
    ticks(0, 'scientific'),
    {notation: 'scientific', maximumSignificantDigits: 1},
    ticks(1, 'scientific'),
  ].map((options) => ['scientific', 'en-US', options, dense]),
  ...[
    [ticks(0, 'scientific'), 1],
    [ticks(1, 'scientific'), 2],
    [ticks(2, 'scientific'), 3],
    [ticks(5, 'scientific'), 6],
    [{notation: 'scientific'}, 4],
    [{notation: 'scientific', maximumSignificantDigits: 2}, 2],
  ].map(([options, digits]) => [
    'scientific',
    'en-US',
    options,
    scientificValues(digits),
  ]),
  // More than 15 fraction digits: formatters.numeric for a tick spacing
  // below 1e-15, and 21 significant digits. The sets leave out the values
  // whose shortest digits start with fifteen 9s, just below a power of ten.
  // There, V8 writes a mantissa below 1 from 17 significant digits:
  // '0.1000000000000000E-11' for 9.999999999999998e-13 with 16 fraction
  // digits.
  ...[
    ticks(16, 'scientific'),
    ticks(20, 'scientific'),
    {notation: 'scientific', minimumSignificantDigits: 21},
  ].map((options) => [
    'scientific',
    'en-US',
    options,
    every(scientificValues(4), 2).filter(
      (x) => !/^9{15}/.test(Math.abs(x).toExponential().replace('.', '')),
    ),
  ]),
  ...[
    ['de-DE', ticks(0, 'scientific'), 1],
    ['de-DE', {notation: 'scientific'}, 4],
    ['hi', {notation: 'scientific'}, 4],
    ['sv', {notation: 'scientific'}, 4],
  ].map(([locale, options, digits]) => [
    'scientific',
    locale,
    options,
    every(scientificValues(digits), 2),
  ]),
  // Without grouping: V8 groups compact numbers, and package:intl does not.
  // With fraction digits or many significant digits, package:intl on the VM
  // and dart2wasm can select a smaller unit than V8: `ja` with 2 minimum
  // fraction digits, `en-US` with 17 minimum significant digits.
  ...[
    ['en-US', {}],
    ['en-US', {maximumSignificantDigits: 1}],
    ['en-US', {maximumSignificantDigits: 3}],
    ['en-US', {minimumFractionDigits: 2}],
    ['en-US', {minimumIntegerDigits: 21}],
    ['de-DE', {}],
    ['ja', {}],
    ['ja', {maximumSignificantDigits: 3}],
    ['ja', {minimumIntegerDigits: 5}],
    ['ar-EG', {}],
    ['hi', {}],
  ].map(([locale, options]) => [
    'compact',
    locale,
    {notation: 'compact', useGrouping: false, ...options},
    compactValues(locale),
  ]),
  // formatters.numeric asks for up to 20 fraction digits.
  ...[
    ['en-US', ticks(16)],
    ['en-US', ticks(17)],
    ['en-US', ticks(20)],
    ['en-US', {maximumFractionDigits: 20}],
    ['en-US', {minimumFractionDigits: 18}],
    ['en-US', {style: 'percent', maximumFractionDigits: 20}],
    ['en-US', {style: 'currency', currency: 'USD', maximumFractionDigits: 20}],
    ['de-DE', ticks(17)],
    ['en-IN', ticks(17)],
    ['ar-EG', ticks(17)],
  ].map(([locale, options]) => ['fraction', locale, options, fractionValues()]),
];

/** A JSON string with every character outside ASCII as an escape. */
const ascii = (value) =>
  JSON.stringify(value).replace(
    /[^\x20-\x7e]/g,
    (c) => `\\u${c.charCodeAt(0).toString(16).padStart(4, '0')}`,
  );

const lines = [];
let cases = 0;
for (const [section, locale, options, values] of groups) {
  lines.push(`# ${section} ${locale} ${ascii(options)}`);
  for (const x of values) {
    lines.push(`${hex(x)} ${ascii(formatNumber(x, locale, options))}`);
    cases++;
  }
}

const dart = `// Original code, not ported from Chart.js: V8 Intl.NumberFormat reference data.

// Generated by tool/reference/intl_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8},
// ICU ${process.versions.icu}, CLDR ${process.versions.cldr}: formatNumber of
// helpers.intl.ts for ${cases} cases.

/// The Node.js version that generated [intlReference].
const String intlReferenceNode = '${process.version}';

/// The V8 version that generated [intlReference].
const String intlReferenceV8 = '${process.versions.v8}';

/// The ICU version that generated [intlReference].
const String intlReferenceIcu = '${process.versions.icu}';

/// The architecture of the Node.js build that generated [intlReference].
const String intlReferenceArch = '${process.arch}';

/// The cases in groups. A group starts with the line
/// \`# <section> <locale> <options as JSON>\`. Each next line is a value, as
/// an IEEE-754 bit pattern in hex, and the V8 string as JSON.
const String intlReference = r'''
${lines.join('\n')}
''';
`;

writeFileSync(OUT, dart);
console.log(`Wrote ${cases} cases to ${OUT}`);
