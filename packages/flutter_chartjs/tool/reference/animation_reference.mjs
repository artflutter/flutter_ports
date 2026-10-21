// Original code, not ported from Chart.js: core.animation reference generator.
//
// It writes test/port/core/animation_reference.dart, the data of
// test/port/core/core.animation_test.dart and
// test/port/core/core.animations_test.dart:
// - scenarios of one Animation on a plain object: the config, the start
//   value, the target value and a list of steps (a tick, a write of _from
//   or _to as the specs make, or an update). After each step, the data holds
//   the active state, the value of the property, the error name, and _from,
//   _to, _duration, _total and _start relative to the first start;
// - the color interpolation of pairs of values at 11 factors, and a list of
//   steps that change _from and _to of one color animation between ticks;
// - the background color of the 400 ms hover transition at each frame of
//   16 ms, and at 200 ms;
// - cases of cancel() on a fake Date.now: the constructor reads a fixed
//   date, and each cancel() reads `_start + offset`. After each step, the
//   data holds the active state, the value of the property, the error name,
//   and the result of the promise of wait() with the value and the active
//   state that its handler sees.
// The header records the Node.js version, the V8 version and the
// architecture. A seeded generator makes the scenarios, so a rerun on the
// same Node.js writes the same file. Nothing in lib/ or test/ runs this
// script (porting-flow.md section 4).
//
// The script runs the pinned upstream source
// third_party/Chart.js/src/core/core.animation.js with the type stripping of
// Node.js. A resolve hook maps the upstream `./x.js` imports to the `.ts`
// files, and `@kurkle/color` to third_party/kurkle-color/src/index.esm.js.
// The ticks use dates relative to `_start` and whole milliseconds, so the
// results do not depend on Date.now(). The cancel() cases replace Date.now
// with a fake clock, and they restore it at the end. The easings of the scenarios have no
// Math.sin, Math.cos or Math.pow: the port does not emulate their last bit
// (Chart.js ADR 0034). Check out the submodules first
// (`dart run melos run upstream`).
//
// Usage, from packages/flutter_chartjs, with an x64 build of Node.js v24.12.0
// (on Apple silicon, the darwin-x64 build runs under Rosetta) and with the
// Dart SDK on the PATH (the script formats the output with `dart format`):
//
//   node tool/reference/animation_reference.mjs
//
// The reference is V8 13.6 on x64 (Chart.js ADR 0032), and the script stops
// on any other architecture.

import {execFileSync} from 'node:child_process';
import {existsSync, writeFileSync} from 'node:fs';
import {registerHooks} from 'node:module';
import {fileURLToPath} from 'node:url';

if (process.arch !== 'x64') {
  console.error(
    `The reference is V8 on x64; this Node.js is ${process.arch}. ` +
      'Run an x64 build of Node.js.',
  );
  process.exit(1);
}

const THIRD_PARTY = new URL('../../../../third_party/', import.meta.url);
const SOURCE = new URL('Chart.js/src/core/core.animation.js', THIRD_PARTY);
const KURKLE = new URL('kurkle-color/src/index.esm.js', THIRD_PARTY);
const OUT = fileURLToPath(
  new URL('../../test/port/core/animation_reference.dart', import.meta.url),
);

for (const url of [SOURCE, KURKLE]) {
  if (!existsSync(fileURLToPath(url))) {
    console.error(
      `${fileURLToPath(url)} is missing. ` +
        'Check out the submodules with `dart run melos run upstream`.',
    );
    process.exit(1);
  }
}

registerHooks({
  resolve(specifier, context, nextResolve) {
    if (
      specifier === '@kurkle/color' &&
      context.parentURL?.includes('/third_party/Chart.js/')
    ) {
      return nextResolve(KURKLE.href, context);
    }
    // The upstream sources import `../helpers/helpers.easing.js` and the
    // other modules with a `.js` suffix; most files on disk are `.ts`.
    if (
      specifier.endsWith('.js') &&
      context.parentURL?.includes('/third_party/Chart.js/')
    ) {
      const js = new URL(specifier, context.parentURL);
      const ts = new URL(specifier.replace(/\.js$/, '.ts'), context.parentURL);
      if (!existsSync(fileURLToPath(js)) && existsSync(fileURLToPath(ts))) {
        return nextResolve(ts.href, context);
      }
    }
    return nextResolve(specifier, context);
  },
});

const {default: Animation} = await import(SOURCE.href);

// The promises of a test animation have no listener. An update rejects them.
process.on('unhandledRejection', () => {});

/** An absent key: the target has no property, or the step has no value. */
const ABSENT = Symbol('absent');

/** The test gradient: helpers.color returns it unchanged. */
const GRADIENT = {
  toString() {
    return '[object CanvasGradient]';
  },
};

/** The mulberry32 generator with the seed [seed]: a number in [0, 1). */
function generator(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const random = generator(20261019);

/** One item of [list]. */
function pick(list) {
  return list[Math.floor(random() * list.length)];
}

/** The Dart literal of a number: always a double literal. */
function num(v) {
  if (Number.isNaN(v)) return 'double.nan';
  if (v === Infinity) return 'double.infinity';
  if (v === -Infinity) return 'double.negativeInfinity';
  if (Object.is(v, -0)) return '-0.0';
  const text = String(v);
  return /[.e]/.test(text) ? text : `${text}.0`;
}

/** The Dart literal of a JS value. */
function dart(v) {
  if (v === ABSENT) return 'animationAbsent';
  if (v === GRADIENT) return 'animationGradient';
  if (v === null) return 'null';
  if (v === undefined) return 'undefined';
  if (typeof v === 'number') return num(v);
  if (typeof v === 'boolean') return String(v);
  if (typeof v === 'string') {
    // Single quotes, or double quotes for a string with a single quote
    // (prefer_single_quotes, avoid_escaping_inner_quotes).
    const quote = v.includes("'") && !v.includes('"') ? '"' : "'";
    const escaped = v.replace(/[\\$]/g, '\\$&').replaceAll(quote, `\\${quote}`);
    return `${quote}${escaped}${quote}`;
  }
  if (typeof v === 'object') {
    const entries = Object.keys(v).map((k) => `${dart(k)}: ${dart(v[k])}`);
    return `<String, Object?>{${entries.join(', ')}}`;
  }
  throw new Error(`No Dart literal for ${String(v)}`);
}

/** A copy of [object] without the keys whose value is ABSENT. */
function present(object) {
  const out = {};
  for (const key of Object.keys(object)) {
    if (object[key] !== ABSENT) out[key] = object[key];
  }
  return out;
}

// --- Scenarios ------------------------------------------------------------

const NUMBERS = [0, 1.5, -3, 10, 100.25, 0.1, -0, NaN, Infinity, -Infinity];
const OTHERS = [undefined, null, true, false];
const STRINGS = ['5', '', 'a'];
// No easing with Math.sin, Math.cos or Math.pow (see the header).
const EASINGS = [
  ABSENT,
  'linear',
  'easeInQuad',
  'easeOutQuart',
  'easeInOutCubic',
  'easeOutBounce',
  'unknown',
];
const DURATIONS = [100, 250.7, 1000, 0, -10, undefined, '300'];
const LOOPS = [ABSENT, undefined, true, false, 0, 1];
const DELAYS = [ABSENT, 0, 50, -20, 12.6, undefined, null];
const OFFSETS = [-50, -1, 0, 1, 10, 50, 99, 100, 101, 150, 250, 300, 400, 1000, 1500];

/**
 * The kinds of the scenarios: the interpolator type, and the values that
 * the scenario uses. The number interpolator gets no String: for a String
 * operand, the JS `+` appends text, and the port gives a number (Chart.js
 * ADR 0019, section 5).
 */
const KINDS = [
  {type: 'number', values: [...NUMBERS, ...OTHERS]},
  {type: ABSENT, values: [...NUMBERS, ...OTHERS]},
  {type: 'boolean', values: [...NUMBERS, ...OTHERS, ...STRINGS]},
  {type: 'number', values: [...NUMBERS, undefined]},
  {type: ABSENT, values: [...NUMBERS, undefined]},
  // A typeof without an interpolator throws a TypeError at the first
  // interpolation: a loop of 1000 ms reaches it.
  {
    type: ABSENT,
    values: [null, undefined, true, false, 5, 1.5, NaN],
    fixed: {duration: 1000, loop: true},
  },
];

/** Whether each value of [values] is a number or `undefined`. */
function numeric(values) {
  return values.every(
    (v) => v === ABSENT || v === undefined || typeof v === 'number',
  );
}

/** The own value of [key] in [object], or ABSENT. */
function own(object, key) {
  return Object.hasOwn(object, key) ? object[key] : ABSENT;
}

/** A random config of [kind]. */
function config(kind, withValues) {
  const cfg = {
    duration: pick(DURATIONS),
    easing: pick(EASINGS),
    loop: pick(LOOPS),
    delay: pick(DELAYS),
    type: kind.type,
    from: withValues && random() < 0.25 ? pick(kind.values) : ABSENT,
    to: withValues && random() < 0.2 ? pick(kind.values) : ABSENT,
    ...kind.fixed,
  };
  return present(cfg);
}

/** The state of [anim] and of `target.prop` after a step. */
function state(anim, target, startBase, error) {
  return {
    active: anim.active(),
    value: target.prop,
    error,
    from: anim._from,
    to: anim._to,
    duration: anim._duration,
    total: anim._total,
    start: anim._start - startBase,
  };
}

const scenarios = [];
for (let n = 0; n < 168; n++) {
  const kind = KINDS[n % KINDS.length];
  const cfg = config(kind, true);
  const current = random() < 0.15 ? ABSENT : pick(kind.values);
  const to = random() < 0.15 ? ABSENT : pick(kind.values);
  const target = current === ABSENT ? {} : {prop: current};
  const anim =
    to === ABSENT
      ? new Animation(cfg, target, 'prop')
      : new Animation(cfg, target, 'prop', to);
  const startBase = anim._start;
  const used = [current, to, own(cfg, 'from'), own(cfg, 'to')];
  const steps = [];
  const count = 4 + Math.floor(random() * 6);
  for (let s = 0; s < count; s++) {
    const r = random();
    let step;
    if (r < 0.6) {
      step = {op: 'tick', offset: pick(OFFSETS), value: ABSENT, cfg: ABSENT};
    } else if (r < 0.7) {
      step = {op: 'from', offset: 0, value: pick(kind.values), cfg: ABSENT};
    } else if (r < 0.8) {
      step = {op: 'to', offset: 0, value: pick(kind.values), cfg: ABSENT};
    } else {
      const update = present({
        duration: pick(DURATIONS),
        loop: pick(LOOPS),
        from: random() < 0.25 ? pick(kind.values) : ABSENT,
        to: random() < 0.2 ? pick(kind.values) : ABSENT,
      });
      step = {op: 'update', offset: pick(OFFSETS), value: pick(kind.values), cfg: update};
      used.push(own(update, 'from'), own(update, 'to'));
    }
    if (step.op !== 'tick') used.push(step.value);
    let error = null;
    try {
      switch (step.op) {
        case 'tick':
          anim.tick(anim._start + step.offset);
          break;
        case 'from':
          anim._from = step.value;
          break;
        case 'to':
          anim._to = step.value;
          break;
        case 'update':
          anim.update(step.cfg, step.value, anim._start + step.offset);
          break;
      }
    } catch (e) {
      error = e.constructor.name;
    }
    steps.push({step, state: state(anim, target, startBase, error)});
  }
  scenarios.push({
    name: `scenario ${n}`,
    cfg,
    current,
    to,
    numeric: numeric(used),
    steps,
  });
}

// --- Colors ---------------------------------------------------------------

const COLORS = [
  '#FF0000',
  '#36A2EB80',
  '#0008',
  'rgb(255, 99, 132)',
  'rgba(54, 162, 235, 0.5)',
  'hsla(240, 50%, 50%, 0.3)',
  'blue',
  'transparent',
  'invalid',
  '',
  null,
  undefined,
  0,
  5,
  {r: 255, g: 0, b: 0, a: 0.5},
  GRADIENT,
];

/** The factors k / 10: a tick at `_start + 100 * k` of a 1000 ms loop. */
const FACTORS = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

/**
 * The results of the color interpolation from [from] to [to] at each
 * factor. The animation loops, so the factor 1 interpolates too.
 */
function colorResults(from, to) {
  const target = {color: 'black'};
  const anim = new Animation({duration: 1000, loop: true, type: 'color'}, target, 'color', 'red');
  anim._from = from;
  anim._to = to;
  return FACTORS.map((k) => {
    anim.tick(anim._start + 100 * k);
    return target.color;
  });
}

const colorPairs = [];
for (const from of COLORS) {
  for (const to of COLORS) {
    colorPairs.push({from, to, results: colorResults(from, to)});
  }
}
// The 256 alpha bytes of a hex color, and every eighth byte in the other
// direction.
for (let alpha = 0; alpha < 256; alpha++) {
  const hex = `#336699${alpha.toString(16).padStart(2, '0')}`;
  colorPairs.push({from: hex, to: '#FF0000', results: colorResults(hex, '#FF0000')});
  if (alpha % 8 === 7) {
    colorPairs.push({from: '#FF0000', to: hex, results: colorResults('#FF0000', hex)});
  }
}
// The rgba() alphas from 0 to 1, in both directions.
for (let k = 0; k <= 10; k++) {
  const rgba = `rgba(255, 99, 132, ${k / 10})`;
  colorPairs.push({from: rgba, to: 'blue', results: colorResults(rgba, 'blue')});
  colorPairs.push({from: 'blue', to: rgba, results: colorResults('blue', rgba)});
}

/** One color animation whose _from and _to change between the ticks. */
const colorSequence = [];
{
  const target = {color: 'black'};
  const anim = new Animation({duration: 1000, loop: true, type: 'color'}, target, 'color', 'red');
  for (let s = 0; s < 120; s++) {
    const r = random();
    const step = {from: ABSENT, to: ABSENT, offset: 100 * pick(FACTORS)};
    if (r < 0.3) step.from = pick(COLORS);
    else if (r < 0.6) step.to = pick(COLORS);
    else if (r < 0.7) {
      step.from = pick(COLORS);
      step.to = pick(COLORS);
    }
    if (step.from !== ABSENT) anim._from = step.from;
    if (step.to !== ABSENT) anim._to = step.to;
    anim.tick(anim._start + step.offset);
    colorSequence.push({...step, result: target.color});
  }
}

// --- The 400 ms hover transition ------------------------------------------

const HOVER_FROM = 'rgba(54, 162, 235, 0.5)';
const HOVER_TO = '#36A2EB';
const hoverFrames = [];
{
  const target = {backgroundColor: HOVER_FROM};
  const anim = new Animation(
    {duration: 400, easing: 'easeOutQuart', type: 'color'},
    target,
    'backgroundColor',
    HOVER_TO,
  );
  for (let k = 1; k <= 26; k++) {
    if (!anim.active()) break;
    anim.tick(anim._start + 16 * k);
    hoverFrames.push(target.backgroundColor);
  }
}
let hoverAt200;
{
  const target = {backgroundColor: HOVER_FROM};
  const anim = new Animation(
    {duration: 400, easing: 'easeOutQuart', type: 'color'},
    target,
    'backgroundColor',
    HOVER_TO,
  );
  anim.tick(anim._start + 200);
  hoverAt200 = target.backgroundColor;
}

// --- cancel() -------------------------------------------------------------

// cancel() ticks at Date.now() before it stops (core.animation.js:67-74).
// The constructor reads Date.now() too (:37). The cases replace Date.now:
// the constructor reads CANCEL_NOW, and a cancel step reads
// `_start + offset`. After each step, the script waits for a macrotask. Thus
// the promise jobs of the step run before the next step, as at a checkpoint.
// The cases use no random(), so the data above does not change.

/** The fake Date.now() of the constructor of each cancel case. */
const CANCEL_NOW = 1792411200000;

/**
 * The cancel cases: `[op, offset]` for a tick at `_start + offset` and for a
 * cancel() at `Date.now() = _start + offset`, `[op, 0, value]` for a write
 * of `_to` (`to`). `wait()` is called after the constructor.
 */
const CANCEL_CASES = [
  {name: 'linear at 250 ms', cfg: {duration: 1000}, current: 0, to: 10, steps: [['cancel', 250]]},
  {
    name: 'easeOutQuart at 400 ms',
    cfg: {duration: 1000, easing: 'easeOutQuart'},
    current: 0,
    to: 10,
    steps: [['tick', 100], ['cancel', 400]],
  },
  {
    name: 'easeOutBounce at 333 ms',
    cfg: {duration: 700, easing: 'easeOutBounce'},
    current: -3,
    to: 100.25,
    steps: [['cancel', 333]],
  },
  {
    name: 'a loop at 1500 ms',
    cfg: {duration: 1000, loop: true},
    current: 0,
    to: 10,
    steps: [['tick', 1200], ['cancel', 1500]],
  },
  {
    name: 'before the start of a delay',
    cfg: {duration: 1000, delay: 50, from: 7},
    current: 3,
    to: 10,
    steps: [['cancel', -20]],
  },
  {
    name: 'a fractional delay',
    cfg: {duration: 1000, delay: 12.6},
    current: 1.5,
    to: -3,
    steps: [['cancel', 100]],
  },
  {
    name: 'at the end',
    cfg: {duration: 1000},
    current: 0,
    to: 10,
    steps: [['tick', 500], ['cancel', 1000]],
  },
  {name: 'after the end', cfg: {duration: 250.7}, current: 1.5, to: -3, steps: [['cancel', 1500]]},
  {
    name: 'after an end tick',
    cfg: {duration: 1000},
    current: 0,
    to: 10,
    steps: [['tick', 1000], ['to', 0, 20], ['cancel', 1200]],
  },
  {
    name: 'two cancels',
    cfg: {duration: 1000},
    current: 0,
    to: 10,
    steps: [['cancel', 250], ['to', 0, 20], ['cancel', 500]],
  },
  {
    name: 'NaN to a number',
    cfg: {duration: 1000},
    current: NaN,
    to: 10,
    steps: [['cancel', 250]],
  },
  {
    name: 'null to a number',
    cfg: {duration: 1000, type: 'number'},
    current: null,
    to: 10,
    steps: [['cancel', 250]],
  },
  {
    name: 'a color at 500 ms',
    cfg: {duration: 1000, type: 'color'},
    current: '#FF0000',
    to: 'blue',
    steps: [['cancel', 500]],
  },
  {
    name: 'a boolean at 600 ms',
    cfg: {duration: 1000, type: 'boolean'},
    current: true,
    to: false,
    steps: [['cancel', 600]],
  },
  {
    name: 'a typeof without an interpolator',
    cfg: {duration: 1000},
    current: 'a',
    to: 'b',
    steps: [['cancel', 500], ['tick', 1000]],
  },
];

const cancelCases = [];
{
  const realDateNow = Date.now;
  let fakeNow = CANCEL_NOW;
  Date.now = () => fakeNow;
  try {
    for (const c of CANCEL_CASES) {
      const target = c.current === ABSENT ? {} : {prop: c.current};
      fakeNow = CANCEL_NOW;
      const anim = new Animation(c.cfg, target, 'prop', c.to);
      let settled = null;
      anim.wait().then(
        () => {
          settled = {kind: 'resolved', value: target.prop, active: anim.active()};
        },
        () => {
          settled = {kind: 'rejected', value: target.prop, active: anim.active()};
        },
      );
      const used = [c.current, c.to, own(c.cfg, 'from'), own(c.cfg, 'to')];
      const steps = [];
      for (const [op, offset, value = ABSENT] of c.steps) {
        if (op === 'to') used.push(value);
        let error = null;
        try {
          switch (op) {
            case 'tick':
              anim.tick(anim._start + offset);
              break;
            case 'cancel':
              fakeNow = anim._start + offset;
              anim.cancel();
              break;
            case 'to':
              anim._to = value;
              break;
          }
        } catch (e) {
          error = e.constructor.name;
        }
        await new Promise((resolve) => setImmediate(resolve));
        steps.push({
          step: {op, offset, value},
          state: {active: anim.active(), value: target.prop, error, settled},
        });
      }
      cancelCases.push({...c, numeric: numeric(used), steps});
    }
  } finally {
    Date.now = realDateNow;
  }
}

// --- Output ---------------------------------------------------------------

function stateLiteral(s, op) {
  const fields =
    op === 'tick'
      ? 'null'
      : `(from: ${dart(s.from)}, to: ${dart(s.to)}, ` +
        `duration: ${num(s.duration)}, total: ${num(s.total)}, ` +
        `start: ${num(s.start)})`;
  const error = s.error === null ? 'null' : dart(s.error);
  return `(${s.active}, ${dart(s.value)}, ${error}, ${fields})`;
}

function stepLiteral(s) {
  const cfg = s.cfg === ABSENT ? 'null' : dart(s.cfg);
  return `('${s.op}', ${num(s.offset)}, ${dart(s.value)}, ${cfg})`;
}

const scenarioBody = scenarios
  .map(
    (s) =>
      `  (name: '${s.name}', cfg: ${dart(s.cfg)}, current: ${dart(s.current)}, ` +
      `to: ${dart(s.to)}, numeric: ${s.numeric}, steps: [\n` +
      s.steps
        .map((t) => `    (${stepLiteral(t.step)}, ${stateLiteral(t.state, t.step.op)}),\n`)
        .join('') +
      '  ]),\n',
  )
  .join('');

const colorBody = colorPairs
  .map((p) => `  (${dart(p.from)}, ${dart(p.to)}, [${p.results.map(dart).join(', ')}]),\n`)
  .join('');

const sequenceBody = colorSequence
  .map(
    (s) =>
      `  (from: ${dart(s.from)}, to: ${dart(s.to)}, offset: ${num(s.offset)}, ` +
      `result: ${dart(s.result)}),\n`,
  )
  .join('');

function settledLiteral(s) {
  if (s === null) return 'null';
  return `('${s.kind}', ${dart(s.value)}, ${s.active})`;
}

const cancelBody = cancelCases
  .map(
    (c) =>
      `  (name: '${c.name}', cfg: ${dart(c.cfg)}, current: ${dart(c.current)}, ` +
      `to: ${dart(c.to)}, numeric: ${c.numeric}, steps: [\n` +
      c.steps
        .map((t) => {
          const error = t.state.error === null ? 'null' : dart(t.state.error);
          return (
            `    (('${t.step.op}', ${num(t.step.offset)}, ${dart(t.step.value)}), ` +
            `(${t.state.active}, ${dart(t.state.value)}, ${error}, ` +
            `${settledLiteral(t.state.settled)})),\n`
          );
        })
        .join('') +
      '  ]),\n',
  )
  .join('');

const stepCount = scenarios.reduce((acc, s) => acc + s.steps.length, 0);
const cancelStepCount = cancelCases.reduce((acc, c) => acc + c.steps.length, 0);

const out = `// Original code, not ported from Chart.js: core.animation reference data.

// Generated by tool/reference/animation_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// src/core/core.animation.js at the pinned Chart.js. ${scenarios.length} scenarios with
// ${stepCount} steps, ${colorPairs.length} color pairs, ${colorSequence.length} color steps and
// ${cancelCases.length} cancel cases with ${cancelStepCount} steps.

import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/color.dart';

/// The Node.js version that generated this file.
const String animationReferenceNode = '${process.version}';

/// The V8 version that generated this file.
const String animationReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated this file.
const String animationReferenceArch = '${process.arch}';

/// The type of [animationAbsent].
final class AnimationAbsent {
  const AnimationAbsent._();
}

/// An absent value: a target without the property, an omitted \`to\`
/// argument, or a step without a value.
const AnimationAbsent animationAbsent = AnimationAbsent._();

/// The test gradient of the data. \`helpers.color\` returns it unchanged.
final class AnimationGradient implements CanvasGradient {
  const AnimationGradient._();

  @override
  void addColorStop(double offset, String color) {}
}

/// The gradient of [animationColorReference] and [animationColorSequence].
const AnimationGradient animationGradient = AnimationGradient._();

/// One step of a scenario, \`(op, offset, value, cfg)\`: \`tick\` at
/// \`_start + offset\`, a write of \`_from\` or \`_to\` with \`value\` (\`from\`,
/// \`to\`), or \`update(cfg, value, _start + offset)\` (\`update\`).
typedef AnimationStep = (
  String op,
  double offset,
  Object? value,
  Map<String, Object?>? cfg,
);

/// The fields of an animation after a step that is not a tick: \`_from\`,
/// \`_to\`, \`_duration\`, \`_total\` and \`_start\` minus the first \`_start\`.
typedef AnimationFields = ({
  Object? from,
  Object? to,
  double duration,
  double total,
  double start,
});

/// The state after a step, \`(active, value, error, fields)\`:
/// \`active()\`, \`target.prop\`, the name of the error that the step threw,
/// and the fields after a step that is not a tick.
typedef AnimationState = (
  bool active,
  Object? value,
  String? error,
  AnimationFields? fields,
);

/// \`new Animation(cfg, target, 'prop', to)\` on \`target = {prop: current}\`
/// (\`{}\` for an absent \`current\`), then the steps. \`numeric\` is true when
/// each value of the scenario is a number or \`undefined\`.
typedef AnimationScenario = ({
  String name,
  Map<String, Object?> cfg,
  Object? current,
  Object? to,
  bool numeric,
  List<(AnimationStep, AnimationState)> steps,
});

/// The scenarios.
const List<AnimationScenario> animationScenarioReference = [
${scenarioBody}];

/// \`(from, to, results)\`: a color animation of 1000 ms with \`loop: true\`,
/// \`_from = from\` and \`_to = to\`, then \`tick(_start + 100 * k)\` for k from
/// 0 to 10. \`results[k]\` is the value of the property after the tick.
const List<(Object?, Object?, List<Object?>)> animationColorReference = [
${colorBody}];

/// One color animation as [animationColorReference]: before each tick at
/// \`_start + offset\`, a present \`from\` or \`to\` is written to \`_from\` or
/// \`_to\`. \`result\` is the value of the property after the tick.
const List<({Object? from, Object? to, double offset, Object? result})>
animationColorSequence = [
${sequenceBody}];

/// The start color of the hover transition.
const String animationHoverFrom = ${dart(HOVER_FROM)};

/// The hover color.
const String animationHoverTo = ${dart(HOVER_TO)};

/// \`new Animation({duration: 400, easing: 'easeOutQuart', type: 'color'},
/// {backgroundColor: from}, 'backgroundColor', to)\`, then
/// \`tick(_start + 16 * k)\` for k from 1 to 25: the value after each tick.
const List<String> animationHoverFrames = [
${hoverFrames.map((c) => `  ${dart(c)},\n`).join('')}];

/// The same animation after \`tick(_start + 200)\`.
const String animationHoverAt200 = ${dart(hoverAt200)};

/// The fake \`Date.now()\` of the constructor of each case of
/// [animationCancelReference].
const double animationCancelNow = ${CANCEL_NOW};

/// One step of a cancel case, \`(op, offset, value)\`: \`tick\` at
/// \`_start + offset\`, \`cancel()\` with \`Date.now()\` at \`_start + offset\`
/// (\`cancel\`), or a write of \`_to\` with \`value\` (\`to\`).
typedef AnimationCancelStep = (String op, double offset, Object? value);

/// The result of the promise of \`wait()\`, \`(kind, value, active)\`:
/// \`resolved\` or \`rejected\`, and \`target.prop\` and \`active()\` in the
/// handler.
typedef AnimationSettled = (String kind, Object? value, bool active);

/// The state after a cancel step and its promise jobs,
/// \`(active, value, error, settled)\`: \`active()\`, \`target.prop\`, the name
/// of the error that the step threw, and the result of the promise of
/// \`wait()\`. \`settled\` is Dart \`null\` while the promise is pending.
typedef AnimationCancelState = (
  bool active,
  Object? value,
  String? error,
  AnimationSettled? settled,
);

/// \`new Animation(cfg, target, 'prop', to)\` on \`target = {prop: current}\`
/// at \`Date.now()\` [animationCancelNow], then \`wait()\`, then the steps.
/// \`numeric\` is true when each value of the case is a number or
/// \`undefined\`.
typedef AnimationCancelCase = ({
  String name,
  Map<String, Object?> cfg,
  Object? current,
  Object? to,
  bool numeric,
  List<(AnimationCancelStep, AnimationCancelState)> steps,
});

/// The cancel cases.
const List<AnimationCancelCase> animationCancelReference = [
${cancelBody}];
`;

writeFileSync(OUT, out);
execFileSync('dart', ['format', OUT], {stdio: 'inherit'});
console.log(
  `Wrote ${scenarios.length} scenarios, ${colorPairs.length} color pairs, ` +
    `${colorSequence.length} color steps and ${cancelCases.length} cancel cases to ${OUT}`,
);
