// Original code, not ported from Chart.js: core.interaction reference generator.
//
// It writes test/port/core/interaction_reference.dart, the data of
// test/port/core/core.interaction_test.dart: scenes of fake charts with
// metas of upstream elements, the queries of the interaction modes on them,
// the items that each query returns, the element methods that it calls in
// order, and the Node.js version, V8 version and architecture in the header.
// The scenes are fixed, so a rerun on the same Node.js writes the same file.
// Nothing in lib/ or test/ runs this script (porting-flow.md section 4).
//
// The script runs the pinned upstream source
// third_party/Chart.js/src/core/core.interaction.js and the element classes
// of src/elements/ with the type stripping of Node.js. A resolve hook maps
// the upstream `./x.js` imports to the `.ts` files, and `@kurkle/color` to
// third_party/kurkle-color/src/index.esm.js (helpers/index.js imports
// helpers.color.ts). The fake chart, metas, controllers and scales have only
// the members that core.interaction.js reads. `isPointInArea` of the fake
// chart is `_isPointInArea(point, chartArea, minPadding)`, as
// core.controller.js:816-818. Check out the submodules first
// (`dart run melos run upstream`).
//
// Usage, from packages/flutter_chartjs_port, with the darwin-arm64 build of
// Node.js v24.22.1 (Chart.js ADR 0045) and with the
// Dart SDK on the PATH (the script formats the output with `dart format`):
//
//   node tool/reference/interaction_reference.mjs
//
// The reference is V8 13.6 on arm64 (Chart.js ADR 0045). The script does not
// stop on another architecture.

import {execFileSync} from 'node:child_process';
import {existsSync, writeFileSync} from 'node:fs';
import {registerHooks} from 'node:module';
import {fileURLToPath} from 'node:url';

const THIRD_PARTY = new URL('../../../../third_party/', import.meta.url);
const SRC = new URL('Chart.js/src/', THIRD_PARTY);
const SOURCE = new URL('core/core.interaction.js', SRC);
const POINT = new URL('elements/element.point.ts', SRC);
const BAR = new URL('elements/element.bar.js', SRC);
const ARC = new URL('elements/element.arc.ts', SRC);
const CANVAS = new URL('helpers/helpers.canvas.ts', SRC);
const KURKLE = new URL('kurkle-color/src/index.esm.js', THIRD_PARTY);
const OUT = fileURLToPath(
  new URL('../../test/port/core/interaction_reference.dart', import.meta.url),
);

for (const url of [SOURCE, POINT, BAR, ARC, CANVAS, KURKLE]) {
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
    // The upstream sources import `./helpers.math.js` and the other modules
    // with a `.js` suffix; most files on disk are `.ts`.
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

const {default: Interaction} = await import(SOURCE.href);
const {default: PointElement} = await import(POINT.href);
const {default: BarElement} = await import(BAR.href);
const {default: ArcElement} = await import(ARC.href);
const {_isPointInArea} = await import(CANVAS.href);

/** The element method calls of the current query, in order. */
let trace = [];

/**
 * A subclass of [Base] that records the calls of `inRange`, `inXRange`,
 * `inYRange` and `getCenterPoint` with the name of the element.
 */
function spy(Base) {
  return class extends Base {
    inRange(x, y, useFinalPosition) {
      trace.push(`inRange ${this.$name}`);
      return super.inRange(x, y, useFinalPosition);
    }

    inXRange(x, useFinalPosition) {
      trace.push(`inXRange ${this.$name}`);
      return super.inXRange(x, useFinalPosition);
    }

    inYRange(y, useFinalPosition) {
      trace.push(`inYRange ${this.$name}`);
      return super.inYRange(y, useFinalPosition);
    }

    getCenterPoint(useFinalPosition) {
      trace.push(`getCenterPoint ${this.$name}`);
      return super.getCenterPoint(useFinalPosition);
    }
  };
}

const CLASSES = {
  point: spy(PointElement),
  bar: spy(BarElement),
  arc: spy(ArcElement),
};

/**
 * A new element of [type] from [cfg], with the name `<datasetIndex>:<index>`
 * and an animation `{active: () => active, _to: to}` for each entry
 * `[prop, active, to]` of [animations]. ArcElement has no `inXRange` and no
 * `inYRange`: the subclass of [spy] adds them only for the other types.
 */
function element(type, cfg, name, animations) {
  const Class = CLASSES[type];
  const el = new Class(cfg);
  if (type === 'arc') {
    // Upstream ArcElement has no inXRange and no inYRange. The spy adds
    // them through the subclass; remove them again, so that
    // `element[rangeMethod]` is undefined, as for an upstream arc.
    Object.defineProperty(el, 'inXRange', {value: undefined});
    Object.defineProperty(el, 'inYRange', {value: undefined});
  }
  el.$name = name;
  if (animations.length) {
    el.$animations = Object.fromEntries(
      animations.map(([prop, active, to]) => [prop, {active: () => active, _to: to}]),
    );
  }
  return el;
}

/** The fake chart of a [scene]. */
function chart(scene) {
  const [left, top, right, bottom] = scene.chartArea;
  const chartArea = {left, top, right, bottom, width: right - left, height: bottom - top};
  const metas = scene.metas.map((m) => {
    const meta = {
      index: m.index,
      _sorted: m.sorted,
      _parsed: m.parsed,
      dataset: m.spanGaps === undefined ? null : {options: {spanGaps: m.spanGaps}},
      data: m.data.map((e, i) => element(e.type, e.cfg, `${m.index}:${i}`, e.animations ?? [])),
      iScale: m.iAxis === null ? undefined : {axis: m.iAxis, _reversePixels: m.reversePixels},
      vScale: {axis: m.vAxis},
    };
    meta.controller = {
      _cachedMeta: meta,
      _sharedOptions: m.sharedOptions ? {} : undefined,
    };
    return meta;
  });
  return {
    chartArea,
    getSortedVisibleDatasetMetas: () => metas.slice(),
    getDatasetMeta: (i) => metas.find((m) => m.index === i),
    isPointInArea: (point) => _isPointInArea(point, chartArea, scene.minPadding),
  };
}

const scenes = [];

/**
 * Adds the scene [name] with its chart area, minimum padding and metas, and
 * runs each query `[mode, options, useFinalPosition, x, y]` of [queries].
 */
function addScene(name, base, queries) {
  const scene = {name, ...base, queries: []};
  for (const [mode, options, useFinalPosition, x, y] of queries) {
    const c = chart(scene);
    const e = {type: 'click', native: true, chart: c, x, y};
    trace = [];
    let result = [];
    let error = null;
    try {
      result = Interaction.modes[mode](c, e, options, useFinalPosition).map((item) => [
        item.datasetIndex,
        item.index,
        item.element.$name,
      ]);
    } catch (err) {
      error = err.constructor.name;
    }
    scene.queries.push({mode, options, useFinalPosition, x, y, result, error, trace});
  }
  scenes.push(scene);
}

/** The queries of each mode and option set at each position of [positions]. */
function grid(modes, positions, useFinalPosition = undefined) {
  const queries = [];
  for (const [mode, options] of modes) {
    for (const [x, y] of positions) {
      queries.push([mode, options, useFinalPosition, x, y]);
    }
  }
  return queries;
}

const ALL_MODES = [
  ['point', {}],
  ['point', {includeInvisible: true}],
  ['index', {intersect: true}],
  ['index', {intersect: false}],
  ['index', {intersect: false, axis: 'y'}],
  ['index', {intersect: false, axis: 'xy'}],
  ['dataset', {intersect: true}],
  ['dataset', {intersect: false}],
  ['dataset', {intersect: false, axis: 'x'}],
  ['nearest', {intersect: true}],
  ['nearest', {intersect: false}],
  ['nearest', {intersect: false, axis: 'x'}],
  ['nearest', {intersect: false, axis: 'y'}],
  ['nearest', {intersect: false, includeInvisible: true}],
  ['x', {intersect: false}],
  ['x', {intersect: true}],
  ['y', {intersect: false}],
  ['y', {intersect: true}],
];

/** A point element with the options of a line chart. */
function point(x, y, extra = {}) {
  return {type: 'point', cfg: {x, y, options: {radius: 3, hitRadius: 1}, ...extra}};
}

// Two line datasets on a category x axis: sorted, the index scale is x.
const LINES = {
  chartArea: [20, 10, 480, 290],
  minPadding: 3,
  metas: [
    {
      index: 0,
      sorted: true,
      iAxis: 'x',
      vAxis: 'y',
      reversePixels: false,
      sharedOptions: false,
      spanGaps: undefined,
      data: [point(50, 200), point(150, 100), point(250, 150), point(350, 60), point(450, 280)],
      parsed: [{x: 0, y: 1}, {x: 1, y: 3}, {x: 2, y: 2}, {x: 3, y: 4}, {x: 4, y: 0}],
    },
    {
      index: 1,
      sorted: true,
      iAxis: 'x',
      vAxis: 'y',
      reversePixels: false,
      sharedOptions: false,
      spanGaps: undefined,
      data: [
        point(50, 150),
        point(150, 100),
        point(250, 150, {skip: true}),
        point(350, 200),
        point(450, 5),
      ],
      parsed: [{x: 0, y: 2}, {x: 1, y: 3}, {x: 2, y: null}, {x: 3, y: 1}, {x: 4, y: 5}],
    },
  ],
};

const LINE_POSITIONS = [
  [50, 200],
  [151, 101],
  [150, 100],
  [250, 150],
  [200, 125],
  [349, 58],
  [452, 4],
  [470, 150],
  [10, 150],
  [600, 150],
  [250, 300],
  [null, 150],
  [150, null],
];

addScene('two line datasets', LINES, grid(ALL_MODES, LINE_POSITIONS));

addScene(
  'two line datasets, final positions',
  {
    ...LINES,
    metas: [
      {
        ...LINES.metas[0],
        data: [
          point(50, 200),
          {...point(150, 100), animations: [['x', true, 160], ['y', true, 90]]},
          {...point(250, 150), animations: [['y', false, 10]]},
          point(350, 60),
          point(450, 280),
        ],
      },
      LINES.metas[1],
    ],
  },
  [
    ...grid([['point', {}], ['nearest', {intersect: false}], ['x', {intersect: true}]], [
      [160, 90],
      [150, 100],
      [250, 10],
    ], true),
    ...grid([['point', {}], ['nearest', {intersect: false}]], [[160, 90], [150, 100]]),
  ],
);

// The metas come in another order than their indices.
addScene(
  'metas out of index order',
  {...LINES, metas: [{...LINES.metas[1], index: 3}, {...LINES.metas[0], index: 1}]},
  grid(
    [
      ['index', {intersect: true}],
      ['index', {intersect: false}],
      ['dataset', {intersect: true}],
      ['dataset', {intersect: false}],
      ['nearest', {intersect: false}],
    ],
    [[150, 100], [250, 150], [452, 4]],
  ),
);

// Datasets of different lengths: the index of the first item is outside the
// data of the second dataset.
addScene(
  'datasets of different lengths',
  {
    ...LINES,
    metas: [
      LINES.metas[0],
      {...LINES.metas[1], data: LINES.metas[1].data.slice(0, 2), parsed: LINES.metas[1].parsed.slice(0, 2)},
    ],
  },
  grid([['index', {intersect: true}], ['index', {intersect: false}]], [
    [350, 60],
    [450, 280],
    [150, 100],
  ]),
);

// Unsorted data and a meta without an index scale: no binary search.
addScene(
  'unsorted data and no index scale',
  {
    ...LINES,
    metas: [
      {...LINES.metas[0], sorted: false},
      {...LINES.metas[1], iAxis: null},
    ],
  },
  grid([['point', {}], ['nearest', {intersect: false, axis: 'x'}], ['x', {intersect: false}]], [
    [150, 100],
    [250, 150],
    [452, 4],
  ]),
);

// A reversed index scale: rlookupByKey over x that falls.
addScene(
  'reversed index scale',
  {
    ...LINES,
    metas: [
      {
        ...LINES.metas[0],
        reversePixels: true,
        data: [point(450, 200), point(350, 100), point(250, 150), point(150, 60), point(50, 280)],
      },
    ],
  },
  grid(
    [
      ['nearest', {intersect: false, axis: 'x'}],
      ['nearest', {intersect: false}],
      ['index', {intersect: false}],
      ['x', {intersect: false}],
    ],
    [[150, 60], [300, 125], [460, 200], [40, 280]],
  ),
);

// The index scale is y: a horizontal chart.
addScene(
  'index scale y',
  {
    ...LINES,
    metas: [
      {
        ...LINES.metas[0],
        iAxis: 'y',
        vAxis: 'x',
        data: [point(200, 50), point(100, 120), point(150, 190), point(60, 260)],
        parsed: [{x: 1, y: 0}, {x: 3, y: 1}, {x: 2, y: 2}, {x: 4, y: 3}],
      },
    ],
  },
  grid(
    [
      ['index', {intersect: false, axis: 'y'}],
      ['nearest', {intersect: false, axis: 'y'}],
      ['y', {intersect: false}],
      ['y', {intersect: true}],
      ['point', {}],
    ],
    [[100, 120], [10, 150], [150, 191], [400, 280]],
  ),
);

// spanGaps: the cases of core.interaction.tests.js:916-1024. A null value
// is a skipped point, and its parsed y is null.
const GAP_DATA = [
  [[12, 19, null, null, null, null, 5, 2], [0, 1, 2, 3, 4, 5, 6, 7]],
  [[12, 0, null, null, null, null, 0, 2], [3, 4]],
  [[12, -1, null, null, null, null, -1, 2], [3, 4]],
  [[null, 2], [0]],
  [[2, null], [1]],
  [[null, null, 2], [0]],
  [[2, null, null], [2]],
];
for (const [spanGaps, label] of [[true, 'spanGaps true'], [false, 'spanGaps false'], [2, 'spanGaps 2']]) {
  GAP_DATA.forEach(([values, clicks], k) => {
    const data = values.map((v, i) =>
      point(30 + i * 60, v === null ? 150 : 200 - v * 5, v === null ? {skip: true} : {}),
    );
    addScene(
      `${label}, data ${k + 1}`,
      {
        chartArea: [20, 10, 480, 290],
        minPadding: 0,
        metas: [
          {
            index: 0,
            sorted: true,
            iAxis: 'x',
            vAxis: 'y',
            reversePixels: false,
            sharedOptions: false,
            spanGaps,
            data,
            parsed: values.map((v, i) => ({x: i, y: v})),
          },
        ],
      },
      clicks.map((i) => ['nearest', {axis: 'x', intersect: false}, undefined, data[i].cfg.x, data[i].cfg.y]),
    );
  });
}

// Shared options: the ranged binary search of intersect mode. The bars
// have getRange. The arcs do not, which gives the full range.
const BAR_DATA = [0, 1, 2, 3, 4, 5, 6, 7].map((i) => ({
  type: 'bar',
  cfg: {x: 40 + i * 55, y: 100 + i * 10, base: 280, width: 30, height: 180 - i * 10, horizontal: false},
}));
const BARS = {
  chartArea: [20, 10, 480, 290],
  minPadding: 0,
  metas: [
    {
      index: 0,
      sorted: true,
      iAxis: 'x',
      vAxis: 'y',
      reversePixels: false,
      sharedOptions: true,
      spanGaps: undefined,
      data: BAR_DATA,
      parsed: BAR_DATA.map((_, i) => ({x: i, y: i})),
    },
  ],
};
const BAR_QUERIES = grid(
  [
    ['point', {}],
    ['index', {intersect: true}],
    ['nearest', {intersect: true}],
    ['nearest', {intersect: false}],
    ['x', {intersect: false}],
    ['y', {intersect: true}],
  ],
  [[95, 200], [124, 150], [149, 280], [40, 99], [480, 200], [300, 50]],
);
addScene('bars with shared options', BARS, BAR_QUERIES);
addScene(
  'bars without shared options',
  {...BARS, metas: [{...BARS.metas[0], sharedOptions: false}]},
  BAR_QUERIES,
);
// A JS null coordinate of the event position. The modes pass it to
// inRange, inXRange and inYRange unchanged (core.interaction.js:125, :174,
// :234, :236), and a bar reads it as "ignore this axis"
// (element.bar.js:103-111).
const NULL_POSITIONS = [[95, null], [124, null], [null, 200], [null, 150], [null, null]];
addScene(
  'bars with a null coordinate',
  {...BARS, metas: [{...BARS.metas[0], sharedOptions: false}]},
  grid(ALL_MODES, NULL_POSITIONS),
);
addScene('bars with shared options and a null coordinate', BARS, grid(ALL_MODES, NULL_POSITIONS));
addScene(
  'points with shared options',
  {...LINES, metas: [{...LINES.metas[0], sharedOptions: true}]},
  grid([['point', {}], ['index', {intersect: true}], ['nearest', {intersect: true}]], [
    [150, 100],
    [152, 102],
    [154, 104],
    [350, 60],
  ]),
);
addScene(
  'points with shared options and no radius',
  {
    ...LINES,
    metas: [
      {
        ...LINES.metas[0],
        sharedOptions: true,
        data: LINES.metas[0].data.map((e) => ({...e, cfg: {...e.cfg, options: {}}})),
      },
    ],
  },
  grid([['point', {}], ['index', {intersect: true}]], [[150, 100]]),
);

// Arcs: a polar area chart. axis 'r' without intersect is the radial
// search. The arcs have no getRange and no inXRange or inYRange.
const ARC_DATA = [0, 1, 2, 3].map((i) => ({
  type: 'arc',
  cfg: {
    x: 250,
    y: 150,
    startAngle: -Math.PI / 2 + i * (Math.PI / 2),
    endAngle: i * (Math.PI / 2),
    innerRadius: 0,
    outerRadius: 40 + i * 20,
    circumference: Math.PI / 2,
    options: {spacing: 0, borderWidth: 2, offset: 0},
  },
}));
addScene(
  'arcs',
  {
    chartArea: [20, 10, 480, 290],
    minPadding: 0,
    metas: [
      {
        index: 0,
        sorted: true,
        iAxis: 'r',
        vAxis: 'r',
        reversePixels: false,
        sharedOptions: true,
        spanGaps: undefined,
        data: ARC_DATA,
        parsed: ARC_DATA.map((_, i) => ({r: i})),
      },
    ],
  },
  grid(
    [
      ['nearest', {intersect: false, axis: 'r'}],
      ['nearest', {intersect: true, axis: 'r'}],
      ['point', {}],
      ['point', {axis: 'r'}],
      ['index', {intersect: false, axis: 'r'}],
      ['dataset', {intersect: false, axis: 'r'}],
      ['x', {intersect: false}],
      ['y', {intersect: false}],
    ],
    [[270, 120], [300, 170], [200, 200], [230, 120], [250, 150], [250, 20], [470, 280]],
  ),
);

// Arcs with a null coordinate: the arithmetic of getAngleFromPoint reads
// JS null as 0.
addScene(
  'arcs with a null coordinate',
  {
    chartArea: [20, 10, 480, 290],
    minPadding: 0,
    metas: [
      {
        index: 0,
        sorted: true,
        iAxis: 'r',
        vAxis: 'r',
        reversePixels: false,
        sharedOptions: true,
        spanGaps: undefined,
        data: ARC_DATA.map((e) => ({...e, cfg: {...e.cfg, x: 30, y: 30}})),
        parsed: ARC_DATA.map((_, i) => ({r: i})),
      },
    ],
  },
  grid(
    [
      ['point', {}],
      ['point', {includeInvisible: true}],
      ['nearest', {intersect: true, axis: 'r'}],
      ['nearest', {intersect: false, axis: 'xy'}],
      ['x', {intersect: false}],
    ],
    [[null, 30], [30, null], [null, null]],
  ),
);

// Arcs along a sorted x index scale with shared options: an element
// without getRange gives the full range of an intersect search.
const ROW_ARCS = [0, 1, 2, 3].map((i) => ({
  type: 'arc',
  cfg: {...ARC_DATA[i].cfg, x: 60 + i * 120, startAngle: 0, endAngle: 2 * Math.PI, circumference: 2 * Math.PI},
}));
addScene(
  'arcs on an x index scale with shared options',
  {
    chartArea: [20, 10, 480, 290],
    minPadding: 0,
    metas: [
      {
        index: 0,
        sorted: true,
        iAxis: 'x',
        vAxis: 'y',
        reversePixels: false,
        sharedOptions: true,
        spanGaps: undefined,
        data: ROW_ARCS,
        parsed: ROW_ARCS.map((_, i) => ({x: i, y: 1})),
      },
    ],
  },
  grid([['index', {intersect: true}], ['index', {intersect: false}]], [[180, 150], [60, 150], [400, 30]]),
);

// An axis option that is not a string.
addScene('axis option of another type', LINES, [
  ['point', {axis: 5}, undefined, 150, 100],
  ['nearest', {axis: 5, intersect: false}, undefined, 150, 100],
  ['nearest', {axis: true, intersect: false}, undefined, 150, 100],
  ['nearest', {axis: {}, intersect: false}, undefined, 150, 100],
  ['point', {axis: ['x']}, undefined, 150, 100],
  ['nearest', {axis: ['x'], intersect: false}, undefined, 200, 125],
  ['nearest', {axis: ['xy'], intersect: false}, undefined, 200, 125],
  ['index', {axis: ['x'], intersect: false}, undefined, 200, 125],
]);

/** The Dart literal of a number. */
function num(v) {
  if (Number.isNaN(v)) return 'double.nan';
  if (v === Infinity) return 'double.infinity';
  if (v === -Infinity) return 'double.negativeInfinity';
  if (Object.is(v, -0)) return '-0.0';
  return String(v);
}

/** Whether the data has an `undefined` literal, which needs its import. */
let usesUndefined = false;

/** The Dart literal of a value. */
function dart(v) {
  if (v === null) return 'null';
  if (v === undefined) {
    usesUndefined = true;
    return 'undefined';
  }
  if (typeof v === 'number') return num(v);
  if (typeof v === 'boolean') return String(v);
  if (typeof v === 'string' && /^[\w :]*$/.test(v)) return `'${v}'`;
  if (Array.isArray(v)) return `<Object?>[${v.map(dart).join(', ')}]`;
  if (typeof v === 'object' && Object.getPrototypeOf(v) === Object.prototype) {
    const entries = Object.keys(v).map((k) => `${dart(k)}: ${dart(v[k])}`);
    return `<String, Object?>{${entries.join(', ')}}`;
  }
  throw new Error(`No Dart literal for ${String(v)}`);
}

/** The Dart literal of an optional number: null for JS null. */
function optNum(v) {
  return v === null ? 'null' : num(v);
}

function dartMeta(m) {
  return `(
        index: ${num(m.index)},
        sorted: ${m.sorted},
        iAxis: ${m.iAxis === null ? 'null' : dart(m.iAxis)},
        vAxis: ${dart(m.vAxis)},
        reversePixels: ${m.reversePixels},
        sharedOptions: ${m.sharedOptions},
        spanGaps: ${dart(m.spanGaps)},
        data: [
${m.data
  .map(
    (e) =>
      `          (type: '${e.type}', cfg: ${dart(e.cfg)}, animations: [${(e.animations ?? [])
        .map(([prop, active, to]) => `('${prop}', ${active}, ${num(to)})`)
        .join(', ')}]),\n`,
  )
  .join('')}        ],
        parsed: <Map<String, Object?>>[${m.parsed.map(dart).join(', ')}],
      )`;
}

function dartQuery(q) {
  return `      (
        mode: '${q.mode}',
        options: ${dart(q.options)},
        useFinalPosition: ${q.useFinalPosition === undefined ? 'null' : q.useFinalPosition},
        x: ${optNum(q.x)},
        y: ${optNum(q.y)},
        result: [${q.result.map(([d, i, n]) => `(${num(d)}, ${num(i)}, '${n}')`).join(', ')}],
        error: ${q.error === null ? 'null' : `'${q.error}'`},
        trace: [${q.trace.map((t) => `'${t}'`).join(', ')}],
      ),
`;
}

const body = scenes
  .map(
    (s) => `  (
    name: '${s.name}',
    chartArea: (${s.chartArea.map(num).join(', ')}),
    minPadding: ${num(s.minPadding)},
    metas: [
${s.metas.map((m) => `      ${dartMeta(m)},\n`).join('')}    ],
    queries: [
${s.queries.map(dartQuery).join('')}    ],
  ),
`,
  )
  .join('');

const queryCount = scenes.reduce((n, s) => n + s.queries.length, 0);

const out = `// Original code, not ported from Chart.js: core.interaction reference data.

// Generated by tool/reference/interaction_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// src/core/core.interaction.js at the pinned Chart.js. ${scenes.length} scenes,
// ${queryCount} queries.
${usesUndefined ? "\nimport 'package:flutter_chartjs_port/src/js/js_undefined.dart';\n" : ''}
/// The Node.js version that generated the data.
const String interactionReferenceNode = '${process.version}';

/// The V8 version that generated the data.
const String interactionReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated the data.
const String interactionReferenceArch = '${process.arch}';

/// An animation \`{active: () => active, _to: to}\` of the property \`prop\`
/// in \`$animations\`.
typedef InteractionReferenceAnimation = (String prop, bool active, double to);

/// A data element: \`new XElement(cfg)\` of the type \`'point'\`, \`'bar'\` or
/// \`'arc'\`, with its animations.
typedef InteractionReferenceElement = ({
  String type,
  Map<String, Object?> cfg,
  List<InteractionReferenceAnimation> animations,
});

/// A meta of the fake chart. \`iAxis\` is the axis of the index scale, or
/// null for a meta without an index scale. \`spanGaps\` is the \`spanGaps\`
/// option of the dataset element, or the \`undefined\` sentinel for a meta
/// without a dataset element. \`sharedOptions\` gives the controller an empty
/// \`_sharedOptions\` object.
typedef InteractionReferenceMeta = ({
  double index,
  bool sorted,
  String? iAxis,
  String vAxis,
  bool reversePixels,
  bool sharedOptions,
  Object? spanGaps,
  List<InteractionReferenceElement> data,
  List<Map<String, Object?>> parsed,
});

/// A query \`Interaction.modes[mode](chart, e, options, useFinalPosition)\`
/// of the event \`{type: 'click', native: true, x, y}\`, with the items
/// \`(datasetIndex, index, element name)\` that it returns, the name of the
/// error class that it throws (or null), and the calls of the element
/// methods \`inRange\`, \`inXRange\`, \`inYRange\` and \`getCenterPoint\` in
/// order. An element name is \`<dataset index>:<data index>\`. Null for
/// \`useFinalPosition\` is an absent argument. Null for \`x\` or \`y\` is JS
/// \`null\`.
typedef InteractionReferenceQuery = ({
  String mode,
  Map<String, Object?> options,
  bool? useFinalPosition,
  double? x,
  double? y,
  List<(double, double, String)> result,
  String? error,
  List<String> trace,
});

/// A fake chart: the chart area \`(left, top, right, bottom)\`, the minimum
/// padding of \`isPointInArea\`, the metas in the order of
/// \`getSortedVisibleDatasetMetas\`, and the queries.
typedef InteractionReferenceScene = ({
  String name,
  (double, double, double, double) chartArea,
  double minPadding,
  List<InteractionReferenceMeta> metas,
  List<InteractionReferenceQuery> queries,
});

/// The scenes.
const List<InteractionReferenceScene> interactionReference = [
${body}];
`;

writeFileSync(OUT, out);
execFileSync('dart', ['format', OUT], {stdio: 'inherit'});
console.log(`Wrote ${OUT}: ${scenes.length} scenes, ${queryCount} queries.`);
