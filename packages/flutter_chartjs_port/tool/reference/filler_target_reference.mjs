// Original code, not ported from Chart.js: filler target reference generator.
//
// It writes test/port/plugins/plugin.filler/filler_target_reference.dart,
// the data of test/port/plugins/plugin.filler/filler.target_test.dart: the
// results of the pinned source functions of src/plugins/plugin.filler/ for
// fixed inputs (Chart.js ADR 0041, section 3 item 8; Chart.js ADR 0040).
// The header records the Node.js version, the V8 version and the
// architecture. The cases are fixed, so a rerun on the same Node.js writes
// the same file. Nothing in lib/ or test/ runs this script
// (porting-flow.md section 4).
//
// The script runs the pinned upstream sources with the type stripping of
// Node.js, as scale_autoskip_reference.mjs and theme_light_reference.mjs
// do: src/plugins/plugin.filler/filler.options.js, filler.target.js,
// filler.segment.js and filler.drawing.js, src/elements/index.js and the
// mock context of third_party/chartjs-test-utils/src/context.js. A resolve
// hook maps the upstream `./x.js` imports to the `.ts` files, and
// `@kurkle/color` to third_party/kurkle-color/src/index.esm.js. Check out
// the submodules first (`dart run melos run upstream`).
//
// The inputs are plain descriptions, and the Dart test builds the same
// objects from them:
// - `decodeFill`: a `LineElement` with the plain options `options`, and
//   `_decodeFill(line, index, count)`.
// - `resolveTarget`: the sources `{visible, fill}` (or `null`) and
//   `_resolveTarget(sources, index, propagate)`.
// - `targetPixel` and `targetValue`: `_getTargetPixel` and
//   `_getTargetValue` with a fake scale (below), or `{}` for `scale: null`.
// - `target`: a fake chart of lines (`chart`), the source of the dataset
//   `source.index`, `_getTarget(source)`, and `_segments(line, target,
//   property)` of the source line with that target.
// - `drawfill`: the same chart and source, and `_drawfill(ctx, source,
//   area)` on the mock context. The calls before a throw stay in the data:
//   the radar fill without a layout records `save` and `beginPath`
//   upstream, and the port records them not (the difference
//   `adapt-filler-target-classes`).
//
// The fake chart: `getDatasetMeta(i)` gives the meta `{index, type,
// hidden, dataset, iScale, _clip: {disabled: true}}` of line `i`, and
// `isDatasetVisible(i)` its `visible`. A line is `new LineElement({points,
// options, _loop, _fullLoop})` with `new PointElement({x, y, ...})` points,
// or `new PointElement({x: 1, y: 2})` for `element: 'point'`. The fake
// linear scale has `top`, `bottom`, `left`, `right`, `isHorizontal()`,
// `getPixelForValue(v)` (`50 + 40 * v` on a horizontal scale, else `400 -
// 40 * v`, with `ToNumber` of `v`), `getBasePixel()`, `getBaseValue()`,
// `min`, `max`, `options: {reverse}`, `chart` and `getMatchingVisibleMetas
// (type)`. The fake radial scale has `getPointPositionForValue(i, v)` (the
// distance `d` of `v`, `x: 256 + d * (i - 2) / 2`, `y: 280 - d * (3 - i) /
// 3`, `angle: i * 1.25 - 1.5`), `getDistanceFromCenterForValue(v)` (`(v -
// min) * 20`, or `(max - v) * 20` with `reverse`), `getLabels()`, `min`,
// `max`, `getBaseValue()` and `options: {reverse, grid: {circular}}`. The
// fakes use only `+`, `-`, `*` and `/`, so the Dart fakes give the same
// bits.
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js
// v24.12.0 (on Apple silicon, the darwin-x64 build runs under Rosetta) and
// with the Dart SDK on the PATH (the script formats the output with `dart
// format`):
//
//   node tool/reference/filler_target_reference.mjs
//
// The reference is V8 13.6 on x64 (Chart.js ADR 0032). The script does not
// stop on another architecture. It also stops unless each of the checkouts
// third_party/Chart.js, third_party/kurkle-color and
// third_party/chartjs-test-utils is at the `commit` of its entry in
// tool/port_sources.yaml and has no change in src/.

import {execFileSync} from 'node:child_process';
import {existsSync, readFileSync, writeFileSync} from 'node:fs';
import {registerHooks} from 'node:module';
import {fileURLToPath} from 'node:url';

/**
 * The submodules that the script reads: the header of the entry in
 * tool/port_sources.yaml, the folder in third_party/ and the folders that the
 * script imports from.
 */
const PINNED = [
  {header: 'Chart.js', folder: 'Chart.js', paths: ['src']},
  {header: '@kurkle/color', folder: 'kurkle-color', paths: ['src']},
  {header: 'chartjs-test-utils', folder: 'chartjs-test-utils', paths: ['src']},
];

/**
 * Stops unless each submodule of PINNED is at the `commit` of its entry in
 * tool/port_sources.yaml, with no change in the folders that the script
 * imports from. It is a copy of checkPin in theme_light_reference.mjs.
 */
function checkPin() {
  const sources = fileURLToPath(new URL('../port_sources.yaml', import.meta.url));
  const entries = readFileSync(sources, 'utf8').split(/^ {2}- header: /m);
  for (const {header, folder, paths} of PINNED) {
    const entry = entries.find(
      (e) => e.startsWith(`${header}\n`) || e.startsWith(`"${header}"\n`),
    );
    const commit = entry?.match(/^ {6}commit: "?([0-9a-f]{40})"?\s*$/m)?.[1];
    if (!commit) {
      console.error(`${sources} has no commit for ${header}.`);
      process.exit(1);
    }
    const checkout = fileURLToPath(
      new URL(`../../../../third_party/${folder}`, import.meta.url),
    );
    const git = (...args) => {
      try {
        return execFileSync('git', ['-C', checkout, ...args], {
          encoding: 'utf8',
          stdio: ['ignore', 'pipe', 'pipe'],
        }).trim();
      } catch (error) {
        console.error(
          `git ${args.join(' ')} failed in ${checkout}: ` +
            `${error.message.trim()}\n` +
            'Check out the submodules with `dart run melos run upstream`.',
        );
        process.exit(1);
      }
    };
    const head = git('rev-parse', 'HEAD');
    if (head !== commit) {
      console.error(
        `${checkout} is at ${head}, not at the pin ${commit} of ${header}. ` +
          'Check out the submodules with `dart run melos run upstream`.',
      );
      process.exit(1);
    }
    if (git('status', '--porcelain', '--', ...paths) !== '') {
      console.error(
        `${checkout} has changes in ${paths.join(', ')}. ` +
          'The script reads the pin.',
      );
      process.exit(1);
    }
  }
}

const THIRD_PARTY = new URL('../../../../third_party/', import.meta.url);
const FILLER = new URL('Chart.js/src/plugins/plugin.filler/', THIRD_PARTY);
const ELEMENTS = new URL('Chart.js/src/elements/index.js', THIRD_PARTY);
const KURKLE = new URL('kurkle-color/src/index.esm.js', THIRD_PARTY);
const CONTEXT = new URL('chartjs-test-utils/src/context.js', THIRD_PARTY);
const OUT = fileURLToPath(
  new URL(
    '../../test/port/plugins/plugin.filler/filler_target_reference.dart',
    import.meta.url,
  ),
);

for (const url of [FILLER, ELEMENTS, KURKLE, CONTEXT]) {
  if (!existsSync(fileURLToPath(url))) {
    console.error(
      `${fileURLToPath(url)} is missing. ` +
        'Check out the submodules with `dart run melos run upstream`.',
    );
    process.exit(1);
  }
}

checkPin();

registerHooks({
  resolve(specifier, context, nextResolve) {
    if (specifier === '@kurkle/color' && context.parentURL?.includes('/third_party/Chart.js/')) {
      return nextResolve(KURKLE.href, context);
    }
    // The upstream sources import `../helpers/helpers.core.js` and the
    // other modules with a `.js` suffix; most files on disk are `.ts`.
    if (specifier.endsWith('.js') && context.parentURL?.includes('/third_party/Chart.js/')) {
      const js = new URL(specifier, context.parentURL);
      const ts = new URL(specifier.replace(/\.js$/, '.ts'), context.parentURL);
      if (!existsSync(fileURLToPath(js)) && existsSync(fileURLToPath(ts))) {
        return nextResolve(ts.href, context);
      }
    }
    return nextResolve(specifier, context);
  },
});

const {_decodeFill, _resolveTarget, _getTargetPixel, _getTargetValue} = await import(
  new URL('filler.options.js', FILLER).href
);
const {_getTarget} = await import(new URL('filler.target.js', FILLER).href);
const {_segments} = await import(new URL('filler.segment.js', FILLER).href);
const {_drawfill} = await import(new URL('filler.drawing.js', FILLER).href);
const {simpleArc} = await import(new URL('simpleArc.js', FILLER).href);
const {LineElement, PointElement} = await import(ELEMENTS.href);
const {default: Context} = await import(CONTEXT.href);

// ---------------------------------------------------------------------------
// The fakes.

/** The fake scale of the description [d] for the chart [chart]. */
function makeScale(d, chart) {
  if (d === null) return undefined;
  if (d.kind === 'radial') {
    const dist = (v) => (d.reverse ? (d.max - v) * 20 : (v - d.min) * 20);
    return {
      id: 'r',
      min: d.min,
      max: d.max,
      chart,
      options: {reverse: d.reverse, grid: {circular: d.circular}},
      getLabels: () => Array.from({length: d.n}, (_, i) => `l${i}`),
      getBaseValue: () => d.baseValue,
      getDistanceFromCenterForValue: (v) => dist(v),
      getPointPositionForValue(i, v) {
        const r = dist(v);
        return {x: 256 + (r * (i - 2)) / 2, y: 280 - (r * (3 - i)) / 3, angle: i * 1.25 - 1.5};
      },
    };
  }
  const pixel = (v) => (d.horizontal ? 50 + 40 * v : 400 - 40 * v);
  return {
    id: d.horizontal ? 'x' : 'y',
    min: d.min,
    max: d.max,
    top: d.top,
    bottom: d.bottom,
    left: d.left,
    right: d.right,
    chart,
    options: {reverse: d.reverse},
    isHorizontal: () => d.horizontal,
    getPixelForValue: (v) => pixel(v),
    getBasePixel: () => pixel(d.baseValue),
    getBaseValue: () => d.baseValue,
    getMatchingVisibleMetas: (type) =>
      chart._metas.filter((m) => m.type === type && chart.isDatasetVisible(m.index)),
  };
}

/** The element of the line description [d]. */
function makeLine(d) {
  if (d.element === 'point') return new PointElement({x: 1, y: 2});
  const points = d.points.map((p) => new PointElement({...p}));
  return new LineElement({points, options: {...d.options}, _loop: d.loop, _fullLoop: d.loop});
}

/** The fake chart, the source and the area of a `target` or `drawfill` case. */
function makeChart(c) {
  const chart = {
    chartArea: c.chart.area === null ? undefined : {...c.chart.area},
    isDatasetVisible: (i) => c.chart.lines[i].visible,
    getDatasetMeta: (i) => chart._metas[i],
  };
  const scale = makeScale(c.chart.scale, chart);
  const iScale = makeScale(c.chart.iScale, chart);
  chart._metas = c.chart.lines.map((d, index) => ({
    index,
    type: d.type,
    hidden: d.hidden,
    dataset: makeLine(d),
    iScale,
    _clip: {disabled: true},
  }));
  const index = c.source.index;
  const source = {
    visible: chart.isDatasetVisible(index),
    index,
    fill: c.source.fill,
    chart,
    axis: c.source.axis,
    scale,
    line: chart._metas[index].dataset,
  };
  return {chart, source};
}

// ---------------------------------------------------------------------------
// The results.

/** A number, or NaN for `undefined` (the WebIDL `ToNumber` of a canvas). */
const toNumber = (v) => Number(v);

/** The canvas methods whose arguments are numbers. */
const NUMBER_METHODS = new Set(['moveTo', 'lineTo', 'rect', 'bezierCurveTo', 'quadraticCurveTo']);

/** The calls of the mock context, with the WebIDL `ToNumber` of numbers. */
function calls(ctx) {
  return ctx.getCalls().map(({name, args}) => [
    name,
    ...args.map((a, i) =>
      NUMBER_METHODS.has(name) || (name === 'arc' && i < 5) ? toNumber(a) : a,
    ),
  ]);
}

/** A point read by name: `[x, y, angle]`. */
const byName = (p) => [p.x, p.y, p.angle];

/** A segment: `[start, end, loop]`. */
const seg = (s) => [s.start, s.end, s.loop];

/** The description of the target [target] of `_getTarget`. */
function describeTarget(target) {
  if (target === true) return 'shape';
  if (!target) return null;
  if (target instanceof simpleArc) {
    return {kind: 'simpleArc', x: target.x, y: target.y, radius: target.radius};
  }
  if (target.segments === undefined) return {kind: 'element'};
  return {
    kind: 'line',
    loop: target._loop,
    fullLoop: target._fullLoop,
    points: target.points.map(byName),
    segments: target.segments.map(seg),
  };
}

/** The description of the parts of `_segments`. */
function describeParts(parts) {
  return parts.map(({source, target, start, end}) => ({
    source: seg(source),
    target:
      target === undefined
        ? undefined
        : 'property' in target
          ? {property: target.property, start: target.start, end: target.end}
          : seg(target),
    start: byName(start),
    end: byName(end),
  }));
}

/** The name of the class of the thrown value [e]. */
const errorName = (e) => e?.name ?? e?.constructor?.name ?? typeof e;

/** The result of [fn], or `{error}` with the name of its error. */
function attempt(fn) {
  try {
    return fn();
  } catch (e) {
    return {error: errorName(e)};
  }
}

const cases = [];

/** Adds a case with the result of its kind. */
function add(c) {
  switch (c.kind) {
    case 'decodeFill': {
      const line = new LineElement({options: {...c.options}});
      c.result = attempt(() => _decodeFill(line, c.index, c.count));
      break;
    }
    case 'resolveTarget':
      c.result = attempt(() =>
        _resolveTarget(
          c.sources.map((s) => (s === null ? null : {...s})),
          c.index,
          c.propagate,
        ),
      );
      break;
    case 'targetPixel':
      c.result = attempt(() =>
        _getTargetPixel(c.fill, c.scale === null ? {} : makeScale(c.scale, {})),
      );
      break;
    case 'targetValue':
      c.result = attempt(() => _getTargetValue(c.fill, makeScale(c.scale, {}), c.startValue));
      break;
    case 'target': {
      const {source} = makeChart(c);
      c.result = attempt(() => {
        const target = _getTarget(source);
        return {
          target: describeTarget(target),
          parts: target ? attempt(() => describeParts(_segments(source.line, target, c.property))) : [],
        };
      });
      break;
    }
    case 'drawfill': {
      const {chart, source} = makeChart(c);
      const ctx = new Context();
      let error = null;
      try {
        _drawfill(ctx, source, chart.chartArea);
      } catch (e) {
        error = errorName(e);
      }
      c.result = {calls: calls(ctx), error};
      break;
    }
    default:
      throw new Error(`Not a case kind: ${c.kind}`);
  }
  cases.push(c);
}

// ---------------------------------------------------------------------------
// decodeFill (filler.options.js:46-73).

const FILLS = [
  ['undefined with a backgroundColor', {backgroundColor: 'red'}],
  ['undefined without a backgroundColor', {}],
  ['undefined with an empty backgroundColor', {backgroundColor: ''}],
  ['null', {fill: null}],
  ['false', {fill: false}],
  ['true', {fill: true}],
  ['0', {fill: 0}],
  ['-0', {fill: -0}],
  ['1', {fill: 1}],
  ['2', {fill: 2}],
  ['3', {fill: 3}],
  ['4', {fill: 4}],
  ['-1', {fill: -1}],
  ['1.5', {fill: 1.5}],
  ['NaN', {fill: NaN}],
  ['Infinity', {fill: Infinity}],
  ['-Infinity', {fill: -Infinity}],
  ["'0'", {fill: '0'}],
  ["'-0'", {fill: '-0'}],
  ["'+0'", {fill: '+0'}],
  ["''", {fill: ''}],
  ["'+1'", {fill: '+1'}],
  ["'-1'", {fill: '-1'}],
  ["'+2'", {fill: '+2'}],
  ["'-2'", {fill: '-2'}],
  ["'2'", {fill: '2'}],
  ["'2.0'", {fill: '2.0'}],
  ["'1.5'", {fill: '1.5'}],
  ["' 2'", {fill: ' 2'}],
  ["'2e0'", {fill: '2e0'}],
  ["'+1foo'", {fill: '+1foo'}],
  ["'origin'", {fill: 'origin'}],
  ["'start'", {fill: 'start'}],
  ["'end'", {fill: 'end'}],
  ["'stack'", {fill: 'stack'}],
  ["'shape'", {fill: 'shape'}],
  ["'foo'", {fill: 'foo'}],
  ['[]', {fill: []}],
  ['[2]', {fill: [2]}],
  ["['+1']", {fill: ['+1']}],
  ['{value: 2}', {fill: {value: 2}}],
  ['{value: NaN}', {fill: {value: NaN}}],
  ["{value: 'a'}", {fill: {value: 'a'}}],
  ["{value: '3'}", {fill: {value: '3'}}],
  ['{value: null}', {fill: {value: null}}],
  ['{}', {fill: {}}],
  ["{target: 'origin'}", {fill: {target: 'origin'}}],
  ['{target: 2}', {fill: {target: 2}}],
  ["{target: '+1'}", {fill: {target: '+1'}}],
  ['{target: {value: 2}}', {fill: {target: {value: 2}}}],
  ['{target: false}', {fill: {target: false}}],
  ['{target: null}', {fill: {target: null}}],
  ['{target: true}', {fill: {target: true}}],
  ["{target: 0, above: 'red'}", {fill: {target: 0, above: 'red'}}],
];
for (const [name, options] of FILLS) {
  add({name: `decodeFill ${name}`, kind: 'decodeFill', options, index: 1, count: 4});
}
add({name: "decodeFill '-1' at index 0", kind: 'decodeFill', options: {fill: '-1'}, index: 0, count: 4});
add({name: "decodeFill '+3' at index 0", kind: 'decodeFill', options: {fill: '+3'}, index: 0, count: 4});
add({name: 'decodeFill 0 at index 0', kind: 'decodeFill', options: {fill: 0}, index: 0, count: 4});

// ---------------------------------------------------------------------------
// resolveTarget (filler.options.js:10-39).

const src = (fill, visible = true) => ({fill, visible});
const RESOLVE = [
  ['a visible target', [src('origin'), src(0)], 1],
  ['a hidden target with a mode', [src('start', false), src(0)], 1],
  ['a hidden target with false', [src(false, false), src(0)], 1],
  ['a chain of hidden targets', [src('end', false), src(0, false), src(1, false), src(2)], 3],
  ['a loop of hidden targets', [src(2, false), src(0, false), src(1, false), src(1)], 3],
  ['a loop back to the source', [src(1, false), src(0)], 1],
  ['a null source as the target', [null, src(0)], 1],
  ['an index past the end', [src(5)], 0],
  ['an option object', [src({value: 2}), src(0)], 0],
  ['a hidden target with an option object', [src({value: 2}, false), src(0)], 1],
];
for (const [name, sources, index] of RESOLVE) {
  for (const propagate of [true, false]) {
    add({name: `resolveTarget ${name}, propagate ${propagate}`, kind: 'resolveTarget', sources, index, propagate});
  }
}

// ---------------------------------------------------------------------------
// getTargetPixel and getTargetValue (filler.options.js:80-115).

const VERTICAL = {kind: 'linear', horizontal: false, top: 32, bottom: 480, left: 40, right: 500, min: -2, max: 8, reverse: false, baseValue: 0};
const HORIZONTAL = {...VERTICAL, horizontal: true};
for (const [name, fill] of [
  ['start', 'start'],
  ['end', 'end'],
  ['origin', 'origin'],
  ['a number', 1],
  ['{value: 3}', {value: 3}],
  ["{value: '3'}", {value: '3'}],
  ['{value: null}', {value: null}],
]) {
  add({name: `targetPixel ${name}, vertical`, kind: 'targetPixel', fill, scale: VERTICAL});
  add({name: `targetPixel ${name}, horizontal`, kind: 'targetPixel', fill, scale: HORIZONTAL});
  add({name: `targetPixel ${name}, no scale`, kind: 'targetPixel', fill, scale: null});
}
const RADIAL = {kind: 'radial', n: 5, min: -1, max: 4, reverse: false, circular: false, baseValue: 0};
for (const [name, fill] of [
  ['start', 'start'],
  ['end', 'end'],
  ['origin', 'origin'],
  ['{value: 3}', {value: 3}],
]) {
  for (const reverse of [false, true]) {
    add({
      name: `targetValue ${name}, reverse ${reverse}`,
      kind: 'targetValue',
      fill,
      scale: {...RADIAL, reverse},
      startValue: reverse ? RADIAL.max : RADIAL.min,
    });
  }
}

// ---------------------------------------------------------------------------
// getTarget and _segments (filler.target.js:13-94, filler.segment.js:3-49),
// and drawfill (filler.drawing.js:5-206).

const AREA = {left: 40, top: 32, right: 500, bottom: 480};
const pts = (...xy) => xy.map(([x, y]) => ({x, y}));
const line = (points, extra = {}) => ({
  type: 'line',
  visible: true,
  hidden: false,
  points,
  options: {backgroundColor: 'blue'},
  loop: undefined,
  ...extra,
});
const SOURCE = line(pts([60, 300], [160, 200], [260, 250], [360, 100]));
const BELOW = line(pts([60, 400], [160, 350], [260, 380], [360, 300]));
const BELOW2 = line(pts([60, 440], [160, 420], [260, 430], [360, 410]));
const GAP = line([
  {x: 60, y: 300},
  {x: 160, y: 200},
  {x: 260, y: NaN, skip: true},
  {x: 360, y: 100},
]);
const BACK = line(pts([60, 400], [260, 350], [160, 380], [360, 300]));
const EMPTY = line([]);
const POINT = {type: 'bar', visible: true, hidden: false, element: 'point'};

/** A radar line of 5 points with the angles of the fake radial scale. */
const radarLine = (gap) =>
  line(
    [0, 1, 2, 3, 4].map((i) => ({
      x: 256 + 10 * i,
      y: 280 - 10 * i,
      angle: i * 1.25 - 1.5,
      ...(gap && i === 2 ? {skip: true, y: NaN} : {}),
    })),
    {type: 'radar', loop: true, options: {backgroundColor: 'blue', spanGaps: false}},
  );

const chart = (lines, scale = VERTICAL, {area = AREA, iScale = HORIZONTAL} = {}) => ({
  area,
  lines,
  scale,
  iScale,
});

const TARGETS = [
  ['linear origin', chart([SOURCE]), 'origin', 'x'],
  ['linear start', chart([SOURCE]), 'start', 'x'],
  ['linear end', chart([SOURCE]), 'end', 'x'],
  ['linear value', chart([SOURCE]), {value: 3}, 'x'],
  ['linear origin on a horizontal scale', chart([SOURCE], HORIZONTAL), 'origin', 'y'],
  ['linear origin with a gap', chart([GAP]), 'origin', 'x'],
  ['no scale origin', chart([SOURCE], null), 'origin', 'x'],
  ['no scale start', chart([SOURCE], null), 'start', 'x'],
  ['no scale value', chart([SOURCE], null), {value: 3}, 'x'],
  ['a visible dataset', chart([SOURCE, BELOW]), 1, 'x'],
  ['a hidden dataset', chart([SOURCE, {...BELOW, visible: false}]), 1, 'x'],
  ['a dataset with a gap', chart([SOURCE, GAP]), 1, 'x'],
  ['a dataset with a point element', chart([SOURCE, POINT]), 1, 'x'],
  ['an empty dataset', chart([SOURCE, EMPTY]), 1, 'x'],
  ['shape', chart([SOURCE]), 'shape', 'x'],
  ['stack over two lines', chart([BELOW2, BELOW, SOURCE]), 'stack', 'x'],
  ['stack over a hidden line', chart([BELOW2, {...BELOW, hidden: true}, SOURCE]), 'stack', 'x'],
  ['stack over a line whose x goes back', chart([BACK, SOURCE]), 'stack', 'x'],
  ['stack over a line with a gap', chart([GAP, SOURCE]), 'stack', 'x'],
  ['stack without a scale', chart([SOURCE], null), 'stack', 'x'],
  ['radial origin', chart([radarLine(false)], RADIAL), 'origin', 'angle'],
  ['radial start', chart([radarLine(false)], RADIAL), 'start', 'angle'],
  ['radial end', chart([radarLine(false)], RADIAL), 'end', 'angle'],
  ['radial start reverse', chart([radarLine(false)], {...RADIAL, reverse: true}), 'start', 'angle'],
  ['radial value', chart([radarLine(false)], RADIAL), {value: 3}, 'angle'],
  ['radial origin with a gap', chart([radarLine(true)], RADIAL), 'origin', 'angle'],
  ['radial circular origin', chart([radarLine(false)], {...RADIAL, circular: true}), 'origin', 'angle'],
  ['radial circular value', chart([radarLine(false)], {...RADIAL, circular: true}), {value: 3}, 'angle'],
  [
    'radial circular origin with a gap',
    chart([radarLine(true)], {...RADIAL, circular: true}),
    'origin',
    'angle',
  ],
];
// The source is the last line of a stack case and the first line of each
// other case.
for (const [name, c, fill, property] of TARGETS) {
  add({
    name: `target ${name}`,
    kind: 'target',
    chart: c,
    source: {
      index: name.startsWith('stack') ? c.lines.length - 1 : 0,
      fill,
      axis: property === 'y' ? 'y' : 'x',
    },
    property,
  });
}

const withFill = (l, fill) => ({...l, options: {...l.options, fill}});
const DRAWS = [
  ['radar without a layout', chart([radarLine(false)], RADIAL, {area: null, iScale: RADIAL}), 'origin', 'x'],
  ['line without a layout', chart([SOURCE], VERTICAL, {area: null}), 'origin', 'x'],
  ['a point element as the target', chart([SOURCE, POINT]), 1, 'x'],
  [
    'an empty target with above and below on x',
    chart([withFill(SOURCE, {target: 1, above: 'red', below: 'green'}), EMPTY]),
    1,
    'x',
  ],
  [
    'an empty target with above and below on y',
    chart([withFill(SOURCE, {target: 1, above: 'red', below: 'green'}), EMPTY], HORIZONTAL, {
      iScale: VERTICAL,
    }),
    1,
    'y',
  ],
  [
    'shape with two colors',
    chart([withFill(SOURCE, {target: 'shape', above: 'red', below: 'green'})]),
    'shape',
    'x',
  ],
  ['shape with one color', chart([withFill(SOURCE, 'shape')]), 'shape', 'x'],
  ['the index bounds of a horizontal index scale', chart([SOURCE], VERTICAL, {iScale: {...HORIZONTAL, min: 1, max: 9}}), 'origin', 'x'],
  ['the index bounds of a vertical index scale', chart([SOURCE], HORIZONTAL, {iScale: {...VERTICAL, min: 1, max: 9}}), 'origin', 'y'],
  ['no index scale', chart([SOURCE], VERTICAL, {iScale: null}), 'origin', 'x'],
  [
    'above and below between two lines',
    chart([withFill(SOURCE, {target: 1, above: 'red', below: 'green'}), BELOW]),
    1,
    'x',
  ],
  ['radial polygon with a gap', chart([radarLine(true)], RADIAL, {iScale: RADIAL}), 'origin', 'x'],
  [
    'radial circular with a gap',
    chart([radarLine(true)], {...RADIAL, circular: true}, {iScale: RADIAL}),
    'origin',
    'x',
  ],
  ['radial circular', chart([radarLine(false)], {...RADIAL, circular: true}, {iScale: RADIAL}), 'origin', 'x'],
  ['stack over a line whose x goes back', chart([BACK, SOURCE]), 'stack', 'x'],
];
for (const [name, c, fill, axis] of DRAWS) {
  add({
    name: `drawfill ${name}`,
    kind: 'drawfill',
    chart: c,
    source: {index: name.startsWith('stack') ? c.lines.length - 1 : 0, fill, axis},
  });
}

// ---------------------------------------------------------------------------
// The Dart file.

/** The Dart literal of a number. */
function num(v) {
  if (Number.isNaN(v)) return 'double.nan';
  if (v === Infinity) return 'double.infinity';
  if (v === -Infinity) return 'double.negativeInfinity';
  if (Object.is(v, -0)) return '-0.0';
  return Number.isInteger(v) ? `${v}.0` : String(v);
}

/** The Dart literal of a value. */
function dart(v) {
  if (v === null) return 'null';
  if (v === undefined) return 'undefined';
  if (typeof v === 'number') return num(v);
  if (typeof v === 'boolean') return String(v);
  if (typeof v === 'string') return v.includes("'") ? `"${v}"` : `'${v}'`;
  if (Array.isArray(v)) return `<Object?>[${v.map(dart).join(', ')}]`;
  if (typeof v === 'object') {
    const entries = Object.keys(v).map((k) => `${dart(k)}: ${dart(v[k])}`);
    return `<String, Object?>{${entries.join(', ')}}`;
  }
  throw new Error(`No Dart literal for ${String(v)}`);
}

const body = cases
  .map((c) => {
    const {name, kind, result, ...input} = c;
    return `  (name: ${dart(name)}, kind: '${kind}', input: ${dart(input)}, result: ${dart(result)}),\n`;
  })
  .join('');

const out = `// Original code, not ported from Chart.js: filler target reference data.

// Generated by tool/reference/filler_target_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// src/plugins/plugin.filler/ at the pinned Chart.js. ${cases.length} cases.

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

/// The Node.js version that generated the data.
const String fillerTargetReferenceNode = '${process.version}';

/// The V8 version that generated the data.
const String fillerTargetReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated the data.
const String fillerTargetReferenceArch = '${process.arch}';

/// One call of a source function of src/plugins/plugin.filler/.
///
/// \`kind\` names the function: \`decodeFill\`, \`resolveTarget\`,
/// \`targetPixel\`, \`targetValue\`, \`target\` (\`_getTarget\` and
/// \`_segments\`) or \`drawfill\`. \`input\` is the description of the
/// arguments (see the header of the generator). \`result\` is the result,
/// or \`{error}\` with the name of the error class.
typedef FillerTargetReferenceCase = ({
  String name,
  String kind,
  Map<String, Object?> input,
  Object? result,
});

/// The cases.
const List<FillerTargetReferenceCase> fillerTargetReference = [
${body}];
`;

writeFileSync(OUT, out);
execFileSync('dart', ['format', OUT], {stdio: 'inherit'});
console.log(`Wrote ${cases.length} cases to ${OUT}`);
