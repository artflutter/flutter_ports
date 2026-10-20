// Original code, not ported from Chart.js: theme precedence reference generator.
//
// It writes test/port/theme/precedence_reference.dart, the data of
// test/port/theme/precedence_test.dart: theming.md section 8 test 1 at the
// chart level and the rows of test 2 that need no palette, on charts with
// test-registered components. The file has the Node.js version, V8 version
// and architecture in its header. The cases are fixed, so a rerun on the same
// Node.js writes the same file. Nothing in lib/ or test/ runs this script
// (porting-flow.md section 4).
//
// The script runs each case twice, in two child processes of the same
// Node.js:
//
// - `upstream`: the pinned src/core/core.controller.js and its imports, with
//   the upstream src/core/core.config.js. Upstream has no theme: it ignores
//   the `$theme` key of the configuration.
// - `prototype`: the same sources, with a JavaScript prototype of the hunks
//   H0-H3 of Chart.js ADR 0001 (theming.md section 3.1) in
//   src/core/core.config.js. A load hook adds the hunks to the source text in
//   memory, at the lines of the Dart hunks of lib/src/core/core.config.dart.
//   The file on disk does not change.
//
// Both runs use the type stripping of Node.js. A resolve hook maps the
// upstream `./x.js` imports to the `.ts` files, and `@kurkle/color` to
// third_party/kurkle-color/src/index.esm.js. A load hook gives the import of
// `package.json` (core.controller.js:12) the version of the pin. Check out the
// submodules first (`dart run melos run upstream`).
//
// The components are the ones that precedence_test.dart registers: the four
// element classes, two dataset controllers `themeTest` and `themeTest2` with
// a point element and the scale overrides `_index_` and `_value_` of the type
// `themeLinear`, the scale `themeLinear`, and the plugin `themeProbe`, which
// keeps the option `k` of its `afterUpdate` hook. A chart is made as
// `_acquireChart` of chartjs-test-utils makes it (src/utils.js:36-105): a
// 512 x 512 canvas, and `animation: false`, `responsive: false` and
// `locale: 'en-US'` in the options. Node.js has no DOM, so the chart gets
// BasicPlatform. The cases read only options, which do not depend on the
// platform. A canvas has the mock context of
// third_party/chartjs-test-utils/src/context.js.
//
// A row of a precedence table writes its sentinels into the global scopes
// (`defaults` and `overrides`) and removes them after the row, as the
// restore of the Dart harness does after each test.
//
// Each observation is one line `<label>: <value>`. A string value is the
// string. Another value is the JSON of JSON.stringify with a replacer:
// `undefined` is `"<undefined>"` and a function is `"<fn>"`.
//
// Usage, from packages/flutter_chartjs, with an x64 build of Node.js v24.12.0
// (on Apple silicon, the darwin-x64 build runs under Rosetta) and with the
// Dart SDK on the PATH (the script formats the output with `dart format`):
//
//   node tool/reference/theme_precedence_reference.mjs
//
// The reference is V8 13.6 on x64 (Chart.js ADR 0010), and the script stops
// on any other architecture.

import {execFileSync} from 'node:child_process';
import {existsSync, readFileSync, writeFileSync} from 'node:fs';
import {registerHooks} from 'node:module';
import {fileURLToPath} from 'node:url';

if (process.arch !== 'x64') {
  console.error(
    `The reference is V8 on x64; this Node.js is ${process.arch}. ` +
      'Run an x64 build of Node.js.',
  );
  process.exit(1);
}

const MODE = process.env.THEME_PRECEDENCE_MODE;

if (MODE === undefined) {
  // The parent process: run both modes, then write the Dart file.
  const run = (mode) =>
    JSON.parse(
      execFileSync(process.execPath, [fileURLToPath(import.meta.url)], {
        env: {...process.env, THEME_PRECEDENCE_MODE: mode},
        encoding: 'utf8',
        maxBuffer: 1 << 26,
      }),
    );
  writeDart(run('upstream'), run('prototype'));
  process.exit(0);
}

const THIRD_PARTY = new URL('../../../../third_party/', import.meta.url);
const SRC = new URL('Chart.js/src/', THIRD_PARTY);
const CONTROLLER = new URL('core/core.controller.js', SRC);
const CONFIG = new URL('core/core.config.js', SRC);
const DATASET_CONTROLLER = new URL('core/core.datasetController.js', SRC);
const SCALE = new URL('core/core.scale.js', SRC);
const DEFAULTS = new URL('core/core.defaults.js', SRC);
const ELEMENTS = new URL('elements/index.js', SRC);
const HELPERS_CORE = new URL('helpers/helpers.core.ts', SRC);
const HELPERS_OPTIONS = new URL('helpers/helpers.options.ts', SRC);
const PACKAGE = new URL('Chart.js/package.json', THIRD_PARTY);
const CONTEXT = new URL('chartjs-test-utils/src/context.js', THIRD_PARTY);
const KURKLE = new URL('kurkle-color/src/index.esm.js', THIRD_PARTY);

for (const url of [
  CONTROLLER,
  CONFIG,
  DATASET_CONTROLLER,
  SCALE,
  DEFAULTS,
  ELEMENTS,
  HELPERS_CORE,
  HELPERS_OPTIONS,
  PACKAGE,
  CONTEXT,
  KURKLE,
]) {
  if (!existsSync(fileURLToPath(url))) {
    console.error(
      `${fileURLToPath(url)} is missing. ` +
        'Check out the submodules with `dart run melos run upstream`.',
    );
    process.exit(1);
  }
}

const VERSION = JSON.parse(readFileSync(PACKAGE, 'utf8')).version;

/** Replaces [from] in [source] once. It fails when [from] is not unique. */
function patch(source, from, to) {
  const at = source.indexOf(from);
  if (at < 0 || source.indexOf(from, at + 1) >= 0) {
    throw new Error(`The anchor is not unique: ${from}`);
  }
  return source.slice(0, at) + to + source.slice(at + from.length);
}

/**
 * The JavaScript prototype of the hunks H0-H3 (theming.md section 3.1) on
 * the source of core.config.js.
 */
function withThemeHunks(source) {
  // H0, before `class Config` (core.config.js:158): the key and its reader.
  source = patch(
    source,
    'export default class Config {',
    `export const themeConfigKey = '$theme';
function _themeOf(config) {
  const theme = config[themeConfigKey];
  return theme && typeof theme === 'object' ? theme : null;
}

export default class Config {`,
  );
  // H1, mergeScaleConfig (core.config.js:109): the theme scale styles first.
  source = patch(
    source,
    '    mergeIf(scale, [defaults.scales[scale.type], defaults.scale]);',
    `    const theme = _themeOf(config);
    if (theme) {
      const themeScales = theme.scales;
      mergeIf(scale, [isObject(themeScales) ? themeScales[scale.type] : undefined, theme.scale]);
    }
    mergeIf(scale, [defaults.scales[scale.type], defaults.scale]);`,
  );
  // H2, getOptionScopes (core.config.js:312-313): the theme scopes before the
  // defaults.
  source = patch(
    source,
    '      keys.forEach(key => addIfFound(scopes, overrides[type] || {}, key));\n',
    `      keys.forEach(key => addIfFound(scopes, overrides[type] || {}, key));
      const theme = _themeOf(this._config);
      if (theme) {
        keys.forEach(key => addIfFound(scopes, theme, key));
      }
`,
  );
  // H3, chartOptionScopes (core.config.js:336-337): the theme scope after the
  // type overrides.
  source = patch(
    source,
    '      options,\n      overrides[type] || {},\n',
    `      options,
      overrides[type] || {},
      ...(_themeOf(this._config) ? [_themeOf(this._config)] : []),
`,
  );
  return source;
}

registerHooks({
  resolve(specifier, context, nextResolve) {
    if (
      specifier === '@kurkle/color' &&
      context.parentURL?.includes('/third_party/Chart.js/')
    ) {
      return nextResolve(KURKLE.href, context);
    }
    // The upstream sources import `../helpers/index.js` and the other
    // modules with a `.js` suffix; most files on disk are `.ts`.
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
  load(url, context, nextLoad) {
    // core.controller.js:12 imports `version` from package.json without an
    // import attribute.
    if (url === PACKAGE.href) {
      return {
        format: 'module',
        source: `export const version = ${JSON.stringify(VERSION)};`,
        shortCircuit: true,
      };
    }
    // context.js of chartjs-test-utils is an ES module in a package
    // without a `type`.
    if (url === CONTEXT.href) {
      return {
        format: 'module',
        source: readFileSync(new URL(url), 'utf8'),
        shortCircuit: true,
      };
    }
    if (MODE === 'prototype' && url === CONFIG.href) {
      return {
        format: 'module',
        source: withThemeHunks(readFileSync(new URL(url), 'utf8')),
        shortCircuit: true,
      };
    }
    return nextLoad(url, context);
  },
});

const {default: Chart} = await import(CONTROLLER.href);
const {default: DatasetController} = await import(DATASET_CONTROLLER.href);
const {default: Scale} = await import(SCALE.href);
const {default: defaults, overrides, descriptors} = await import(DEFAULTS.href);
const {ArcElement, BarElement, LineElement, PointElement} = await import(
  ELEMENTS.href
);
const {resolveObjectKey} = await import(HELPERS_CORE.href);
const {toFont} = await import(HELPERS_OPTIONS.href);
const {default: Context} = await import(CONTEXT.href);

// ---------------------------------------------------------------------------
// The observations.

/** The JSON text of [value] with the replacer of the observations. */
function json(value) {
  return JSON.stringify(value, (key, v) =>
    v === undefined ? '<undefined>' : typeof v === 'function' ? '<fn>' : v,
  );
}

/** The text of the observed [value]. */
function text(value) {
  return typeof value === 'string' ? value : json(value);
}

const scenarios = [];

/** Runs the scenario [name]. [body] gets the function `observe`. */
function scenario(name, body) {
  const lines = [];
  body((label, value) => lines.push(`${label}: ${text(value)}`));
  scenarios.push({name, lines});
}

// ---------------------------------------------------------------------------
// The fixtures.

/** The mock context with a recorded `resetTransform`. */
class FakeContext extends Context {
  resetTransform() {
    this.record('resetTransform', []);
  }
}

/** A canvas of [width] x [height] with a mock context. */
function fakeCanvas(width, height) {
  const ctx = new FakeContext();
  let w = width;
  let h = height;
  const canvas = {
    id: '',
    get width() {
      return w;
    },
    set width(value) {
      w = value >>> 0;
    },
    get height() {
      return h;
    },
    set height(value) {
      h = value >>> 0;
    },
    style: {},
    getContext(id) {
      return id === '2d' ? ctx : null;
    },
  };
  ctx.canvas = canvas;
  return canvas;
}

/**
 * The dataset controller [id]: a point element, and the scales `_index_` and
 * `_value_` of the type `themeLinear` in its overrides. It places each point
 * at its parsed x and y.
 */
function themeController(id) {
  return class extends DatasetController {
    static id = id;
    static defaults = {datasetElementType: false, dataElementType: 'point'};
    static overrides = {
      scales: {
        _index_: {type: 'themeLinear'},
        _value_: {type: 'themeLinear'},
      },
    };

    update(mode) {
      const meta = this._cachedMeta;
      this.updateElements(meta.data, 0, meta.data.length, mode);
    }

    updateElements(points, start, count, mode) {
      const {iScale, vScale} = this._cachedMeta;
      const {sharedOptions, includeOptions} = this._getSharedOptions(
        start,
        mode,
      );
      for (let i = start; i < start + count; ++i) {
        const point = points[i];
        const parsed = this.getParsed(i);
        const properties = {
          x: iScale.getPixelForValue(parsed.x, i),
          y: vScale.getPixelForValue(parsed.y, i),
        };
        if (includeOptions) {
          properties.options =
            sharedOptions ||
            this.resolveDataElementOptions(i, point.active ? 'active' : mode);
        }
        this.updateElement(point, i, properties, mode);
      }
    }
  };
}

/** The scale `themeLinear`: the range 0 to 10, with the ticks 0, 5, 10. */
class ThemeScale extends Scale {
  static id = 'themeLinear';
  static defaults = {};

  determineDataLimits() {
    this.min = 0;
    this.max = 10;
  }

  buildTicks() {
    return [{value: 0}, {value: 5}, {value: 10}];
  }

  getPixelForValue(value) {
    return this.getPixelForDecimal((value - this.min) / (this.max - this.min));
  }
}

/** The option `k` that the plugin `themeProbe` saw last. */
let probeK = 'unset';

/** The plugin `themeProbe`: it keeps its option `k` in `afterUpdate`. */
const themeProbe = {
  id: 'themeProbe',
  afterUpdate(chart, args, options) {
    probeK = options.k;
  },
};

Chart.register(ArcElement, BarElement, LineElement, PointElement);
Chart.register(
  themeController('themeTest'),
  themeController('themeTest2'),
  ThemeScale,
  themeProbe,
);

const charts = [];

/** `_acquireChart(config)` of src/utils.js:36-105, without the DOM. */
function acquireChart(config) {
  config.options = config.options || {};
  config.options.animation =
    config.options.animation === undefined ? false : config.options.animation;
  config.options.responsive =
    config.options.responsive === undefined
      ? false
      : config.options.responsive;
  config.options.locale = config.options.locale || 'en-US';
  const chart = new Chart(fakeCanvas(512, 512).getContext('2d'), config);
  charts.push(chart);
  return chart;
}

/** The steps that undo the writes of [put]. */
let undo = [];

/**
 * Writes [value] at the dot path [path] of the global scope [root]. It
 * creates the missing objects. [row] undoes the write.
 */
function put(root, path, value) {
  const keys = path.split('.');
  let node = root;
  for (let i = 0; i < keys.length - 1; i++) {
    const key = keys[i];
    if (node[key] === undefined) {
      const parent = node;
      undo.push(() => delete parent[key]);
      let created = (parent[key] = {});
      for (let j = i + 1; j < keys.length - 1; j++) {
        created = created[keys[j]] = {};
      }
      created[keys[keys.length - 1]] = value;
      return;
    }
    node = node[key];
  }
  const leaf = keys[keys.length - 1];
  const descriptor = Object.getOwnPropertyDescriptor(node, leaf);
  if (descriptor && descriptor.set) {
    // A route of `defaults.route`: the setter writes `_<name>`.
    const old = node[`_${leaf}`];
    node[leaf] = value;
    undo.push(() => {
      node[leaf] = old;
    });
  } else if (descriptor) {
    const old = node[leaf];
    node[leaf] = value;
    undo.push(() => {
      node[leaf] = old;
    });
  } else {
    node[leaf] = value;
    undo.push(() => delete node[leaf]);
  }
}

/** Runs [body], then undoes the writes of [put]. */
function row(body) {
  undo = [];
  try {
    return body();
  } finally {
    for (const step of undo.reverse()) step();
    undo = [];
  }
}

/** The data of a dataset: two points. */
function points() {
  return [
    {x: 1, y: 2},
    {x: 5, y: 8},
  ];
}

/** The label of a row of [levels]. */
function rowLabel(levels) {
  return levels.length === 0 ? 'none' : levels.join('+');
}

/** Each row of a table: the levels from the level [i] down. */
function rows(levels, body, observe) {
  for (let i = 0; i <= levels.length; i++) {
    const subset = levels.slice(i);
    observe(rowLabel(subset), row(() => body(subset)));
  }
}

// ---------------------------------------------------------------------------
// The precedence tables of theming.md section 3.2 (section 8, test 2).

scenario('elements', (observe) => {
  rows(
    [
      'dataset',
      'options',
      'overrides',
      'theme',
      'controllerDefaults',
      'elementDefaults',
      'rootDefaults',
    ],
    (levels) => {
      const dataset = {data: points()};
      const options = {};
      const theme = {};
      if (levels.includes('dataset')) dataset.backgroundColor = 'E1-dataset';
      if (levels.includes('options')) {
        options.elements = {point: {backgroundColor: 'E2-options'}};
      }
      if (levels.includes('overrides')) {
        put(overrides, 'themeTest.elements.point.backgroundColor', 'E3-overrides');
      }
      if (levels.includes('theme')) {
        theme.elements = {point: {backgroundColor: 'E4-theme'}};
      }
      if (levels.includes('controllerDefaults')) {
        put(
          defaults,
          'datasets.themeTest.backgroundColor',
          'E5-controller-defaults',
        );
      }
      if (levels.includes('elementDefaults')) {
        put(defaults, 'elements.point.backgroundColor', 'E6-element-defaults');
      }
      if (levels.includes('rootDefaults')) {
        put(defaults, 'backgroundColor', 'E7-root-defaults');
      }
      const config = {type: 'themeTest', data: {datasets: [dataset]}, options};
      if (levels.includes('theme')) config.$theme = theme;
      const chart = acquireChart(config);
      return chart.getDatasetMeta(0).data[0].options.backgroundColor;
    },
    observe,
  );
});

scenario('active', (observe) => {
  // The theme base color derives the hover color (theming.md section 3.2).
  const active = (themed, userHover) =>
    row(() => {
      const dataset = {data: points()};
      if (userHover) dataset.hoverBackgroundColor = 'E1-dataset-hover';
      const config = {
        type: 'themeTest',
        data: {datasets: [dataset]},
        options: {},
      };
      if (themed) {
        config.$theme = {
          elements: {point: {backgroundColor: 'rgb(200, 0, 0)'}},
        };
      }
      const meta = acquireChart(config).getDatasetMeta(0);
      return [
        meta.controller.resolveDataElementOptions(0, 'active').backgroundColor,
        meta.data[0].options.backgroundColor,
      ];
    });
  observe('unthemed', active(false, false));
  observe('themed', active(true, false));
  observe('themed with a user hover color', active(true, true));
});

scenario('scales', (observe) => {
  rows(
    [
      'user',
      'chartOverrides',
      'datasetOverrides',
      'themeType',
      'themeScale',
      'scaleDefaults',
      'scaleBase',
      'rootColor',
    ],
    (levels) => {
      // The user scale `x` is always there: the chart-type overrides merge
      // only into a scale of the user options (core.config.js:76-89).
      const options = {scales: {x: {}}};
      const theme = {};
      if (levels.includes('user')) {
        options.scales.x.ticks = {color: 'S1-user'};
      }
      if (levels.includes('chartOverrides')) {
        put(
          overrides,
          'themeTest.scales._index_.ticks.color',
          'S2-chart-overrides',
        );
      }
      if (levels.includes('datasetOverrides')) {
        put(
          overrides,
          'themeTest2.scales._index_.ticks.color',
          'S3-dataset-overrides',
        );
      }
      if (levels.includes('themeType')) {
        theme.scales = {themeLinear: {ticks: {color: 'S4-theme-type'}}};
      }
      if (levels.includes('themeScale')) {
        theme.scale = {ticks: {color: 'S5-theme-scale'}};
      }
      if (levels.includes('scaleDefaults')) {
        put(defaults, 'scales.themeLinear.ticks.color', 'S6-scale-defaults');
      }
      if (levels.includes('scaleBase')) {
        put(defaults, 'scale.ticks.color', 'S7-scale-base');
      }
      if (levels.includes('rootColor')) {
        put(defaults, 'color', 'S8-root-color');
      }
      const config = {
        type: 'themeTest',
        data: {datasets: [{type: 'themeTest2', data: points()}]},
        options,
      };
      if (levels.includes('themeType') || levels.includes('themeScale')) {
        config.$theme = theme;
      }
      const chart = acquireChart(config);
      return [
        chart.scales.x.options.ticks.color,
        Object.keys(chart.scales).join(','),
      ];
    },
    observe,
  );
});

scenario('plugins', (observe) => {
  rows(
    ['user', 'overrides', 'theme', 'defaults'],
    (levels) => {
      const options = {};
      const theme = {};
      if (levels.includes('user')) {
        options.plugins = {themeProbe: {k: 'P1-user'}};
      }
      if (levels.includes('overrides')) {
        put(overrides, 'themeTest.plugins.themeProbe.k', 'P2-overrides');
      }
      if (levels.includes('theme')) {
        theme.plugins = {themeProbe: {k: 'P3-theme'}};
      }
      if (levels.includes('defaults')) {
        put(defaults, 'plugins.themeProbe.k', 'P4-defaults');
      }
      const config = {
        type: 'themeTest',
        data: {datasets: [{data: points()}]},
        options,
      };
      if (levels.includes('theme')) config.$theme = theme;
      probeK = 'unset';
      acquireChart(config);
      return probeK;
    },
    observe,
  );
});

scenario('chart level', (observe) => {
  rows(
    ['user', 'overrides', 'theme', 'datasetDefaults', 'defaults'],
    (levels) => {
      const options = {};
      const theme = {};
      if (levels.includes('user')) options.color = 'C1-user';
      if (levels.includes('overrides')) {
        put(overrides, 'themeTest.color', 'C2-overrides');
      }
      if (levels.includes('theme')) theme.color = 'C3-theme';
      if (levels.includes('datasetDefaults')) {
        put(defaults, 'datasets.themeTest.color', 'C4-dataset-defaults');
      }
      if (levels.includes('defaults')) put(defaults, 'color', 'C5-defaults');
      const config = {
        type: 'themeTest',
        data: {datasets: [{data: points()}]},
        options,
      };
      if (levels.includes('theme')) config.$theme = theme;
      return acquireChart(config).options.color;
    },
    observe,
  );
});

// ---------------------------------------------------------------------------
// The resolved options of one chart (section 8, test 1).

/**
 * The compiled theme of the raw Map theme `_tokenTheme` of
 * precedence_test.dart: the result of `compileChartTheme` of
 * lib/src/theme/compile.dart. The Dart test compares the two.
 */
const compiledTheme = {
  color: 'rgba(51, 102, 153, 1)',
  scale: {
    ticks: {
      color: 'rgba(51, 102, 153, 1)',
      backdropColor: 'rgba(0, 0, 0, 0.75)',
      font: {family: 'Arial', size: 14},
    },
    title: {
      color: 'rgba(51, 102, 153, 1)',
      font: {family: 'Arial', size: 14},
    },
    grid: {color: 'rgba(0, 128, 0, 0.5)'},
    border: {color: 'rgba(0, 128, 0, 0.5)'},
  },
  elements: {
    point: {
      borderColor: 'rgba(0, 128, 0, 0.5)',
      backgroundColor: 'rgba(200, 0, 0, 1)',
    },
    line: {
      borderColor: 'rgba(0, 128, 0, 0.5)',
      backgroundColor: 'rgba(200, 0, 0, 1)',
    },
    bar: {
      borderColor: 'rgba(0, 128, 0, 0.5)',
      backgroundColor: 'rgba(200, 0, 0, 1)',
    },
    arc: {
      backgroundColor: 'rgba(200, 0, 0, 1)',
      borderColor: 'rgba(0, 0, 0, 1)',
    },
  },
  transitions: {
    theme: {animation: {duration: 200, easing: 'linear'}},
    themeFrame: {animation: {duration: 0}},
  },
};

/**
 * The scenario [name]: the options of a chart with the `$theme` value
 * [theme] (no key for `'absent'`). [user] adds user values.
 */
function snapshot(name, theme, user) {
  scenario(name, (observe) => {
    const dataset = {data: points()};
    const options = {};
    if (user) {
      dataset.backgroundColor = 'rgb(0, 0, 255)';
      options.scales = {x: {ticks: {color: 'user-ticks'}}};
      options.color = 'user-color';
    }
    const config = {type: 'themeTest', data: {datasets: [dataset]}, options};
    if (theme !== 'absent') config.$theme = theme;
    if (theme === compiledTheme) observe('theme', compiledTheme);
    probeK = 'unset';
    const chart = acquireChart(config);
    const meta = chart.getDatasetMeta(0);
    observe('element', meta.data[0].options);
    observe('same options', meta.data[0].options === meta.data[1].options);
    observe('active', meta.controller.resolveDataElementOptions(0, 'active'));
    observe('scales', chart.config.options.scales);
    const x = chart.scales.x.options;
    observe('scale x', [
      x.ticks.color,
      x.ticks.backdropColor,
      x.grid.color,
      x.border.color,
      x.title.color,
    ]);
    // The fonts of _resolveTickFontOptions (core.scale.js:1698-1701) and of
    // the title (core.scale.js:1595).
    const tickFont = chart.scales.x._resolveTickFontOptions(0);
    const titleFont = toFont(x.title.font);
    observe('scale x fonts', [
      tickFont.family,
      tickFont.size,
      tickFont.string,
      titleFont.family,
      titleFont.size,
      titleFont.string,
    ]);
    const o = chart.options;
    observe('chart', [
      o.color,
      o.backgroundColor,
      o.borderColor,
      o.font.family,
      o.font.size,
      o.font.style,
      o.font.weight,
      o.font.lineHeight,
    ]);
    observe('plugin', probeK);
  });
}

snapshot('no theme', 'absent', false);
snapshot('a null theme', null, false);
snapshot('a string theme', 'not a map', false);
snapshot('user values', 'absent', true);
snapshot('a compiled theme', compiledTheme, false);
snapshot('a compiled theme and user values', compiledTheme, true);

// ---------------------------------------------------------------------------
// The option scopes of one chart (section 8, test 1).

/** The label of each scope: a known object by name, another by its JSON. */
function labeller(named) {
  const names = new Map(named.filter(([value]) => value !== undefined));
  let fresh = 0;
  const seen = new Map();
  return (scope) => {
    if (names.has(scope)) return names.get(scope);
    if (seen.has(scope)) return seen.get(scope);
    const name =
      scope && typeof scope === 'object' && Object.keys(scope).length === 0
        ? `{}#${fresh++}`
        : `?${json(scope)}`;
    seen.set(scope, name);
    return name;
  };
}

/**
 * The scenario [name]: the scope lists of a chart with the `$theme` value
 * [theme] (no key for `'absent'`, the theme of the scenario for `'theme'`).
 */
function scopes(name, themeValue) {
  scenario(name, (observe) =>
    row(() => {
      put(overrides, 'themeTest.elements.point.radius', 4);
      put(overrides, 'themeTest.plugins.themeProbe.k', 'o');
      const dataset = {data: points()};
      const options = {
        datasets: {themeTest: {}},
        elements: {point: {}},
        plugins: {themeProbe: {}},
      };
      const theme = {
        datasets: {themeTest: {elements: {point: {}}}},
        elements: {point: {}},
        plugins: {themeProbe: {}},
        transitions: {theme: {}},
      };
      const config = {type: 'themeTest', data: {datasets: [dataset]}, options};
      if (themeValue === 'theme') config.$theme = theme;
      else if (themeValue !== 'absent') config.$theme = themeValue;
      const c = acquireChart(config).config;
      const at = resolveObjectKey;
      const label = labeller([
        [dataset, 'dataset'],
        [c.options, 'options'],
        [at(c.options, 'datasets.themeTest'), 'options.datasets.themeTest'],
        [at(c.options, 'elements.point'), 'options.elements.point'],
        [at(c.options, 'plugins.themeProbe'), 'options.plugins.themeProbe'],
        [overrides.themeTest, 'overrides.themeTest'],
        [
          at(overrides, 'themeTest.elements.point'),
          'overrides.themeTest.elements.point',
        ],
        [
          at(overrides, 'themeTest.plugins.themeProbe'),
          'overrides.themeTest.plugins.themeProbe',
        ],
        [theme, 'theme'],
        [at(theme, 'datasets.themeTest'), 'theme.datasets.themeTest'],
        [
          at(theme, 'datasets.themeTest.elements.point'),
          'theme.datasets.themeTest.elements.point',
        ],
        [at(theme, 'elements.point'), 'theme.elements.point'],
        [at(theme, 'plugins.themeProbe'), 'theme.plugins.themeProbe'],
        [at(theme, 'transitions.theme'), 'theme.transitions.theme'],
        [defaults, 'defaults'],
        [at(defaults, 'datasets.themeTest'), 'defaults.datasets.themeTest'],
        [at(defaults, 'elements.point'), 'defaults.elements.point'],
        [at(defaults, 'plugins.themeProbe'), 'defaults.plugins.themeProbe'],
        [descriptors, 'descriptors'],
      ]);
      const list = (array) => array.map(label).join(' ');
      observe(
        'element',
        list(
          c.getOptionScopes(
            dataset,
            c.datasetElementScopeKeys('themeTest', 'point'),
          ),
        ),
      );
      observe(
        'dataset',
        list(c.getOptionScopes(dataset, c.datasetScopeKeys('themeTest'))),
      );
      observe(
        'animation',
        list(
          c.getOptionScopes(
            dataset,
            c.datasetAnimationScopeKeys('themeTest', 'theme'),
          ),
        ),
      );
      observe(
        'plugin',
        list(
          c.getOptionScopes(
            c.options.plugins.themeProbe,
            c.pluginScopeKeys(themeProbe),
          ),
        ),
      );
      observe('chart', list(c.chartOptionScopes()));
    }),
  );
}

scopes('scopes without a theme', 'absent');
scopes('scopes with a null theme', null);
scopes('scopes with a string theme', 'not a map');
scopes('scopes with a theme', 'theme');

for (const chart of charts) chart.destroy();

process.stdout.write(
  JSON.stringify({
    node: process.version,
    v8: process.versions.v8,
    platform: process.platform,
    arch: process.arch,
    scenarios,
  }),
);

// ---------------------------------------------------------------------------
// The output.

/**
 * The observations as one multi-line Dart string, one observation on each
 * line. A long line in a multi-line string passes lines_longer_than_80_chars.
 */
function dartLines(lines) {
  const body = lines.join('\n');
  if (body.includes("'''")) throw new Error('An observation with three quotes');
  const raw = /[\\$]/.test(body) ? 'r' : '';
  return `${raw}'''\n${body}'''`;
}

/** The Dart Map of the [scenarios] of one run. */
function dartMap(scenarios) {
  return scenarios
    .map(({name, lines}) => `  '${name}': ${dartLines(lines)},\n`)
    .join('');
}

/** Writes the Dart file from the runs [upstream] and [prototype]. */
function writeDart(upstream, prototype) {
  for (const key of ['node', 'v8', 'platform', 'arch']) {
    if (upstream[key] !== prototype[key]) {
      throw new Error(`The two runs differ in ${key}.`);
    }
  }
  const out = fileURLToPath(
    new URL('../../test/port/theme/precedence_reference.dart', import.meta.url),
  );
  const {node, v8, platform, arch} = upstream;
  const dart = `// Original code, not ported from Chart.js: theme precedence reference data.

// Generated by tool/reference/theme_precedence_reference.mjs. Do not edit.
// Node.js ${node} (${platform}-${arch}), V8 ${v8}:
// src/core/core.controller.js at the pinned Chart.js, with the upstream
// src/core/core.config.js and with a JavaScript prototype of the hunks H0-H3.
// ${upstream.scenarios.length} scenarios.

/// The Node.js version that generated the data.
const String themePrecedenceReferenceNode = '${node}';

/// The V8 version that generated the data.
const String themePrecedenceReferenceV8 = '${v8}';

/// The architecture of the Node.js build that generated the data.
const String themePrecedenceReferenceArch = '${arch}';

/// The observations of each scenario with the upstream
/// src/core/core.config.js, by name, one on each line: \`<label>: <value>\`.
const Map<String, String> themePrecedenceUpstream = {
${dartMap(upstream.scenarios)}};

/// The observations of each scenario with the JavaScript prototype of the
/// hunks H0-H3 in src/core/core.config.js, by name, one on each line:
/// \`<label>: <value>\`.
const Map<String, String> themePrecedencePrototype = {
${dartMap(prototype.scenarios)}};
`;
  writeFileSync(out, dart);
  execFileSync('dart', ['format', out], {stdio: 'inherit'});
  console.log(`Wrote ${out}: ${upstream.scenarios.length} scenarios.`);
}
