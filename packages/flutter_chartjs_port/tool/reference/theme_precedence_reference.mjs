// Original code, not ported from Chart.js: theme precedence reference generator.
//
// It writes test/port/theme/precedence_reference.dart, the data of
// test/port/theme/precedence_test.dart: theming.md section 8 test 1 at the
// chart level, the rows of test 2 that need no palette, the hunk H1 with the
// real category, linear and radial linear scales (theming.md section 10,
// phase 6), test 5 with the test controllers and with the bar and doughnut
// controllers of phase 7, the singleton read at scale.radialLinear.js:14
// (theming.md section 9), a radial chart without a theme that has the values
// that the tokens replace in `defaults` (theming.md section 4), and the
// hover steps on the 8 chart types of phase 7 (Chart.js ADR 0030, section
// 10). Phase 8 adds the palette rows of test 2 and test 3 with the colors
// plugin (Chart.js ADR 0042, theming.md section 8): the scenarios
// `palette <row>` and `light palette <type>`. The file has the Node.js version,
// V8 version and architecture in its header. The cases are fixed, so a rerun on the same
// Node.js writes the same file. Nothing in lib/ or test/ runs this script
// (porting-flow.md section 4).
//
// The script runs each case twice, in two child processes of the same
// Node.js:
//
// - `upstream`: the pinned src/core/core.controller.js and its imports, with
//   the upstream src/core/core.config.js and src/plugins/plugin.colors.ts.
//   Upstream has no theme: it ignores the `$theme` key of the configuration.
// - `prototype`: the same sources, with a JavaScript prototype of the hunks
//   H0-H3 of Chart.js ADR 0042 (theming.md section 3.1) in
//   src/core/core.config.js, and of the hunks H4a, H4b, H4c and H5 of
//   Chart.js ADR 0042 in src/plugins/plugin.colors.ts. A load hook adds the hunks to the source
//   text in memory, at the lines of the Dart hunks of
//   lib/src/core/core.config.dart and lib/src/plugins/plugin.colors.dart.
//   The files on disk do not change.
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
// keeps the option `k` of its `afterUpdate` hook. For the hunk H1 with real
// scales, it also registers the pinned src/scales/scale.category.js,
// scale.linear.js and scale.radialLinear.js, two dataset controllers
// `themeReal` and `themeReal2` with the scale overrides `_index_` of the type
// `category` and `_value_` of the type `linear`, and the radial test
// controller `themeRadial`: the index axis `r` and the scale override `r` of
// the type `radialLinear`, as controller.radar.js:11-34 has them. For test 5
// on real charts and for the hover steps, it also registers the pinned
// src/controllers/controller.{bar,bubble,doughnut,line,pie,polarArea,radar,
// scatter}.js, as the Dart harness registers them (flutter_test_config.dart).
// After the element classes, it registers the seven plugins of
// src/plugins/index.js by name, in the order of its lines 1-7, and then sets
// `defaults.plugins.colors.enabled = false`, as flutter_test_config.dart
// does before main() of precedence_test.dart (src/index.umd.ts:28 and
// test/index.js:25-28, Chart.js ADR 0041 section 1 item 3). The script does
// not give the module namespace to `Chart.register`: `each` does not walk a
// module namespace (helpers.core.ts:53-54, :152), so the call registers
// nothing. The script stops unless the registry then has the seven plugin
// ids. Each palette scenario sets `plugins.colors.enabled: true` in the
// options of its charts. The colors plugin imports `../index.js`
// (plugin.colors.ts:1), so the run loads all of src/index.ts. In the
// `prototype` run, the load hook of the hunks H4a-H5 applies to
// plugin.colors.ts through the import of src/plugins/index.js (the same
// URL).
// A chart is
// made as `_acquireChart` of chartjs-test-utils makes it
// (src/utils.js:36-105): a 512 x 512 canvas, and `animation: false`,
// `responsive: false` and `locale: 'en-US'` in the options. Node.js has no
// DOM, so the chart gets BasicPlatform. The cases read options, and the
// width and the height of a radial scale. These values do not depend on the
// platform or on a text measurement. A canvas has the mock context of
// third_party/chartjs-test-utils/src/context.js.
//
// The hover steps (Chart.js ADR 0030, section 10): for each of the 8 chart
// types, `chart._eventHandler(e)` gets a `mousemove` at the rounded center
// of the element 0 of the dataset 0, then a `mousemove` at the rounded
// center of the element 1, then a `mouseout` at the same point. After each
// step, the scenario records the active elements and some options of both
// elements. The `upstream` run writes the values that the hover theme
// replaces into `defaults` (theming.md section 4) and removes them after the
// scenario. The `prototype` run gives the chart the compiled hover theme
// under `$theme` and writes nothing into `defaults`. The script stops when
// the two runs give other lines. The element positions come from the mock
// `measureText` of chartjs-test-utils. Thus they are not the positions of
// the Dart charts, and the scenario records no position.
//
// A row of a precedence table writes its sentinels into the global scopes
// (`defaults` and `overrides`) and removes them after the row, as the
// restore of the Dart harness does after each test.
//
// Each observation is one line `<label>: <value>`. A string value is the
// string. Another value is the JSON of JSON.stringify with a replacer:
// `undefined` is `"<undefined>"` and a function is `"<fn>"`.
//
// Usage, from packages/flutter_chartjs_port, with the darwin-arm64 build of
// Node.js v24.22.1 (Chart.js ADR 0045) and with the
// Dart SDK on the PATH (the script formats the output with `dart format`):
//
//   node tool/reference/theme_precedence_reference.mjs
//
// The reference is V8 13.6 on arm64 (Chart.js ADR 0045). The script does not
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
 * script imports from. The script also reads the package.json of Chart.js
 * (core.controller.js:12), but the load hook gives it the version of the pin.
 */
const PINNED = [
  {header: 'Chart.js', folder: 'Chart.js', paths: ['src']},
  {header: '@kurkle/color', folder: 'kurkle-color', paths: ['src']},
  {header: 'chartjs-test-utils', folder: 'chartjs-test-utils', paths: ['src']},
];

/**
 * Stops unless each submodule of PINNED is at the `commit` of its entry in
 * tool/port_sources.yaml, with no change in the folders that the script
 * imports from. The read of a commit is the one of readPin in
 * scale_chart_common.mjs. A folder that is not a git checkout also stops the
 * script.
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

const MODE = process.env.THEME_PRECEDENCE_MODE;

if (MODE === undefined) {
  // The parent process: check the pin, run both modes, then write the Dart
  // file.
  checkPin();
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
const CATEGORY = new URL('scales/scale.category.js', SRC);
const LINEAR = new URL('scales/scale.linear.js', SRC);
const RADIAL_LINEAR = new URL('scales/scale.radialLinear.js', SRC);
const CONTROLLERS = [
  'bar',
  'bubble',
  'doughnut',
  'line',
  'pie',
  'polarArea',
  'radar',
  'scatter',
].map((name) => new URL(`controllers/controller.${name}.js`, SRC));
const DEFAULTS = new URL('core/core.defaults.js', SRC);
const ELEMENTS = new URL('elements/index.js', SRC);
const HELPERS_CORE = new URL('helpers/helpers.core.ts', SRC);
const HELPERS_OPTIONS = new URL('helpers/helpers.options.ts', SRC);
const COLORS = new URL('plugins/plugin.colors.ts', SRC);
const PLUGINS = new URL('plugins/index.js', SRC);
const PACKAGE = new URL('Chart.js/package.json', THIRD_PARTY);
const CONTEXT = new URL('chartjs-test-utils/src/context.js', THIRD_PARTY);
const KURKLE = new URL('kurkle-color/src/index.esm.js', THIRD_PARTY);

for (const url of [
  CONTROLLER,
  CONFIG,
  DATASET_CONTROLLER,
  SCALE,
  CATEGORY,
  LINEAR,
  RADIAL_LINEAR,
  ...CONTROLLERS,
  DEFAULTS,
  ELEMENTS,
  HELPERS_CORE,
  HELPERS_OPTIONS,
  COLORS,
  PLUGINS,
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

/**
 * The JavaScript prototype of the hunks H4a, H4b, H4c and H5 (Chart.js ADR
 * 0042, theming.md section 3.5) on the source of plugin.colors.ts. Each hunk
 * has the form of its Dart hunk in lib/src/plugins/plugin.colors.dart: the
 * upstream lines stay, and the hunks add lines only.
 */
function withColorsHunks(source) {
  // H4a, after BACKGROUND_COLORS (plugin.colors.ts:25): the palette keys,
  // the two variables and their reader `_themePalette`.
  source = patch(
    source,
    "color.replace('rgb(', 'rgba(').replace(')', ', 0.5)'));\n",
    `color.replace('rgb(', 'rgba(').replace(')', ', 0.5)'));

// DIVERGES(chartjs): theme-H4a, the theme palette keys, variables and reader.
const themeBorderColorsKey = '$borderColors';
const themeBackgroundColorsKey = '$backgroundColors';
let themeBorderColors = null;
let themeBackgroundColors = null;
function themePalette(chart, key) {
  const value = chart.config._config.$theme?.plugins?.colors?.[key];
  return Array.isArray(value) && value.length > 0 ? value : null;
}
`,
  );
  // H4b, getBorderColor (plugin.colors.ts:27-29): the theme branch before
  // the unchanged upstream line.
  source = patch(
    source,
    '  return BORDER_COLORS[i % BORDER_COLORS.length];',
    `  // DIVERGES(chartjs): theme-H4b, the theme palette comes first.
  if (themeBorderColors !== null) return themeBorderColors[i % themeBorderColors.length];
  return BORDER_COLORS[i % BORDER_COLORS.length];`,
  );
  // H4c, getBackgroundColor (plugin.colors.ts:31-33).
  source = patch(
    source,
    '  return BACKGROUND_COLORS[i % BACKGROUND_COLORS.length];',
    `  // DIVERGES(chartjs): theme-H4c, the theme palette comes first.
  if (themeBackgroundColors !== null) return themeBackgroundColors[i % themeBackgroundColors.length];
  return BACKGROUND_COLORS[i % BACKGROUND_COLORS.length];`,
  );
  // H5, beforeLayout directly before the colorizer (plugin.colors.ts:123):
  // both variables at each run, null included.
  source = patch(
    source,
    '    const colorizer = getColorizer(chart);',
    `    // DIVERGES(chartjs): theme-H5, the palette of the chart theme for this run.
    themeBorderColors = themePalette(chart, themeBorderColorsKey);
    themeBackgroundColors = themePalette(chart, themeBackgroundColorsKey);

    const colorizer = getColorizer(chart);`,
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
    if (MODE === 'prototype' && url === COLORS.href) {
      return {
        format: 'module-typescript',
        source: withColorsHunks(readFileSync(new URL(url), 'utf8')),
        shortCircuit: true,
      };
    }
    return nextLoad(url, context);
  },
});

const {default: Chart} = await import(CONTROLLER.href);
const {default: DatasetController} = await import(DATASET_CONTROLLER.href);
const {default: Scale} = await import(SCALE.href);
const {default: CategoryScale} = await import(CATEGORY.href);
const {default: LinearScale} = await import(LINEAR.href);
const {default: RadialLinearScale} = await import(RADIAL_LINEAR.href);
const {default: defaults, overrides, descriptors} = await import(DEFAULTS.href);
const {ArcElement, BarElement, LineElement, PointElement} = await import(
  ELEMENTS.href
);
const {resolveObjectKey} = await import(HELPERS_CORE.href);
const {toFont} = await import(HELPERS_OPTIONS.href);
const {default: Context} = await import(CONTEXT.href);
const controllerClasses = [];
for (const url of CONTROLLERS) {
  controllerClasses.push((await import(url.href)).default);
}
const pluginExports = await import(PLUGINS.href);

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
 * `_value_` of the types [indexType] and [valueType] in its overrides. It
 * places each point at its parsed x and y.
 */
function themeController(
  id,
  indexType = 'themeLinear',
  valueType = 'themeLinear',
) {
  return class extends DatasetController {
    static id = id;
    static defaults = {datasetElementType: false, dataElementType: 'point'};
    static overrides = {
      scales: {
        _index_: {type: indexType},
        _value_: {type: valueType},
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

/**
 * The radial test controller `themeRadial`: a point element, the index axis
 * `r` and the scale `r` of the type `radialLinear` in its overrides, as
 * controller.radar.js:11-34 has them. It places each point at the position
 * of `getPointPositionForValue` (controller.radar.js:81-103 without the
 * line).
 */
class RadialController extends DatasetController {
  static id = 'themeRadial';
  static defaults = {
    datasetElementType: false,
    dataElementType: 'point',
    indexAxis: 'r',
  };
  static overrides = {scales: {r: {type: 'radialLinear'}}};

  update(mode) {
    const meta = this._cachedMeta;
    this.updateElements(meta.data, 0, meta.data.length, mode);
  }

  updateElements(points, start, count, mode) {
    const scale = this._cachedMeta.rScale;
    for (let i = start; i < start + count; i++) {
      const position = scale.getPointPositionForValue(i, this.getParsed(i).r);
      this.updateElement(
        points[i],
        i,
        {
          x: position.x,
          y: position.y,
          angle: position.angle,
          options: this.resolveDataElementOptions(i, mode),
        },
        mode,
      );
    }
  }
}

Chart.register(ArcElement, BarElement, LineElement, PointElement);
// src/index.umd.ts:28 registers the namespace `plugins`. A module namespace
// is not a plain object for helpers.core.ts:53-54, so `each` (:152) does not
// walk it. Thus the script registers the exports by name, in the order of
// src/plugins/index.js:1-7 (Chart.js ADR 0041, section 1 item 3).
Chart.register(
  pluginExports.Colors,
  pluginExports.Decimation,
  pluginExports.Filler,
  pluginExports.Legend,
  pluginExports.SubTitle,
  pluginExports.Title,
  pluginExports.Tooltip,
);
// Disable colors plugin for tests (test/index.js:25-28).
defaults.plugins.colors.enabled = false;
{
  const ids = Object.keys(Chart.registry.plugins.items).join();
  if (ids !== 'colors,decimation,filler,legend,subtitle,title,tooltip') {
    console.error(`The registry has the plugins ${ids}, not the seven of src/plugins/index.js.`);
    process.exit(1);
  }
}
Chart.register(
  themeController('themeTest'),
  themeController('themeTest2'),
  ThemeScale,
  themeProbe,
);
Chart.register(CategoryScale, LinearScale, RadialLinearScale);
Chart.register(
  themeController('themeReal', 'category', 'linear'),
  themeController('themeReal2', 'category', 'linear'),
  RadialController,
);
Chart.register(...controllerClasses);

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
// The hunk H1 with the real scales (theming.md section 10, phase 6).

/**
 * The data of a chart with the real scales: two labels and two values, in a
 * dataset of the type [type] (no key for undefined).
 */
function realData(type) {
  const dataset = {data: [2, 8]};
  if (type !== undefined) dataset.type = type;
  return {labels: ['a', 'b'], datasets: [dataset]};
}

/** The data of a radial chart: three labels and three values. */
function radialData() {
  return {labels: ['a', 'b', 'c'], datasets: [{data: [1, 2, 3]}]};
}

scenario('real scales', (observe) => {
  // The category scale `x` and the linear scale `y`. Each level sets a
  // sentinel for both axes. The theme type and the scale defaults have one
  // sentinel for each scale type.
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
      // The user scales are always there: the chart-type overrides merge
      // only into a scale of the user options (core.config.js:76-89).
      const options = {scales: {x: {}, y: {}}};
      const theme = {};
      if (levels.includes('user')) {
        options.scales.x.ticks = {color: 'S1-user-x'};
        options.scales.y.ticks = {color: 'S1-user-y'};
      }
      if (levels.includes('chartOverrides')) {
        put(overrides, 'themeReal.scales._index_.ticks.color', 'S2-chart-x');
        put(overrides, 'themeReal.scales._value_.ticks.color', 'S2-chart-y');
      }
      if (levels.includes('datasetOverrides')) {
        put(overrides, 'themeReal2.scales._index_.ticks.color', 'S3-dataset-x');
        put(overrides, 'themeReal2.scales._value_.ticks.color', 'S3-dataset-y');
      }
      if (levels.includes('themeType')) {
        theme.scales = {
          category: {ticks: {color: 'S4-theme-category'}},
          linear: {ticks: {color: 'S4-theme-linear'}},
        };
      }
      if (levels.includes('themeScale')) {
        theme.scale = {ticks: {color: 'S5-theme-scale'}};
      }
      if (levels.includes('scaleDefaults')) {
        put(defaults, 'scales.category.ticks.color', 'S6-category-defaults');
        put(defaults, 'scales.linear.ticks.color', 'S6-linear-defaults');
      }
      if (levels.includes('scaleBase')) {
        put(defaults, 'scale.ticks.color', 'S7-scale-base');
      }
      if (levels.includes('rootColor')) {
        put(defaults, 'color', 'S8-root-color');
      }
      const config = {type: 'themeReal', data: realData('themeReal2'), options};
      if (levels.includes('themeType') || levels.includes('themeScale')) {
        config.$theme = theme;
      }
      const chart = acquireChart(config);
      return [
        chart.scales.x.options.ticks.color,
        chart.scales.y.options.ticks.color,
        Object.keys(chart.scales).join(','),
      ];
    },
    observe,
  );
});

/**
 * A radial chart with the user scale options [r], the theme [theme] (no key
 * for null) and the type `themeRadial`.
 */
function radialChart(r, theme) {
  const config = {
    type: 'themeRadial',
    data: radialData(),
    options: {scales: {r}},
  };
  if (theme) config.$theme = theme;
  return acquireChart(config);
}

scenario('radial point labels', (observe) => {
  // pointLabels.color: the route of scale.radialLinear.js:400-404 reads
  // Defaults.color.
  rows(
    [
      'user',
      'chartOverrides',
      'themeType',
      'themeScale',
      'scaleDefaults',
      'rootColor',
    ],
    (levels) => {
      const r = {};
      const theme = {};
      if (levels.includes('user')) r.pointLabels = {color: 'R1-user'};
      if (levels.includes('chartOverrides')) {
        put(overrides, 'themeRadial.scales.r.pointLabels.color', 'R2-chart');
      }
      if (levels.includes('themeType')) {
        theme.scales = {radialLinear: {pointLabels: {color: 'R3-theme-type'}}};
      }
      if (levels.includes('themeScale')) {
        theme.scale = {pointLabels: {color: 'R4-theme-scale'}};
      }
      if (levels.includes('scaleDefaults')) {
        put(
          defaults,
          'scales.radialLinear.pointLabels.color',
          'R5-scale-defaults',
        );
      }
      if (levels.includes('rootColor')) put(defaults, 'color', 'R6-root-color');
      const themed =
        levels.includes('themeType') || levels.includes('themeScale');
      const chart = radialChart(r, themed ? theme : null);
      return [
        chart.scales.r.options.pointLabels.color,
        Object.keys(chart.scales).join(','),
      ];
    },
    observe,
  );
});

scenario('radial angle lines', (observe) => {
  // angleLines.color: the route of scale.radialLinear.js:400-404 reads
  // Defaults.borderColor. The descriptor `_fallback: 'grid'`
  // (scale.radialLinear.js:406-410) adds the grid scopes after the angle
  // line scopes.
  rows(
    [
      'user',
      'userGrid',
      'themeType',
      'themeGrid',
      'scaleDefaults',
      'rootBorderColor',
    ],
    (levels) => {
      const r = {};
      const theme = {};
      if (levels.includes('user')) r.angleLines = {color: 'A1-user'};
      if (levels.includes('userGrid')) r.grid = {color: 'A2-user-grid'};
      if (levels.includes('themeType')) {
        theme.scales = {radialLinear: {angleLines: {color: 'A3-theme-type'}}};
      }
      if (levels.includes('themeGrid')) {
        theme.scale = {grid: {color: 'A4-theme-grid'}};
      }
      if (levels.includes('scaleDefaults')) {
        put(
          defaults,
          'scales.radialLinear.angleLines.color',
          'A5-scale-defaults',
        );
      }
      if (levels.includes('rootBorderColor')) {
        put(defaults, 'borderColor', 'A6-root-border-color');
      }
      const themed =
        levels.includes('themeType') || levels.includes('themeGrid');
      const o = radialChart(r, themed ? theme : null).scales.r.options;
      return [o.angleLines.color, o.grid.color];
    },
    observe,
  );
});

scenario('radial point label fonts', (observe) => {
  // pointLabels.font: the size 10 of scale.radialLinear.js:383-385, and the
  // toFont fallback to Defaults.font (helpers.options.ts:115-117).
  rows(
    ['user', 'themeType', 'themeScale', 'scaleDefaults', 'rootFont'],
    (levels) => {
      const r = {};
      const theme = {};
      if (levels.includes('user')) {
        r.pointLabels = {font: {family: 'F1-user', size: 31}};
      }
      if (levels.includes('themeType')) {
        theme.scales = {
          radialLinear: {
            pointLabels: {font: {family: 'F2-theme-type', size: 32}},
          },
        };
      }
      if (levels.includes('themeScale')) {
        theme.scale = {pointLabels: {font: {family: 'F3-theme-scale', size: 33}}};
      }
      if (levels.includes('scaleDefaults')) {
        put(
          defaults,
          'scales.radialLinear.pointLabels.font.family',
          'F4-scale-defaults',
        );
        put(defaults, 'scales.radialLinear.pointLabels.font.size', 34);
      }
      if (levels.includes('rootFont')) {
        put(defaults, 'font.family', 'F5-root-font');
        put(defaults, 'font.size', 35);
      }
      const themed =
        levels.includes('themeType') || levels.includes('themeScale');
      const o = radialChart(r, themed ? theme : null).scales.r.options;
      const font = toFont(o.pointLabels.font);
      return [font.family, font.size, font.string];
    },
    observe,
  );
});

scenario('radial ticks', (observe) => {
  // ticks.color: the route of scale.radialLinear.js:400-404 reads
  // Defaults.color. The hunk H1 merges the theme `scale` before
  // defaults.scales.radialLinear.
  rows(
    [
      'user',
      'themeType',
      'themeScale',
      'scaleDefaults',
      'scaleBase',
      'rootColor',
    ],
    (levels) => {
      const r = {};
      const theme = {};
      if (levels.includes('user')) r.ticks = {color: 'T1-user'};
      if (levels.includes('themeType')) {
        theme.scales = {radialLinear: {ticks: {color: 'T2-theme-type'}}};
      }
      if (levels.includes('themeScale')) {
        theme.scale = {ticks: {color: 'T3-theme-scale'}};
      }
      if (levels.includes('scaleDefaults')) {
        put(defaults, 'scales.radialLinear.ticks.color', 'T4-scale-defaults');
      }
      if (levels.includes('scaleBase')) {
        put(defaults, 'scale.ticks.color', 'T5-scale-base');
      }
      if (levels.includes('rootColor')) put(defaults, 'color', 'T6-root-color');
      const themed =
        levels.includes('themeType') || levels.includes('themeScale');
      return radialChart(r, themed ? theme : null).scales.r.options.ticks.color;
    },
    observe,
  );
});

scenario('radial tick backdrop', (observe) => {
  // The singleton read of scale.radialLinear.js:14 (theming.md section 9):
  // `getTickBackdropHeight` reads `defaults.font.size` when the tick font
  // has no size. setDimensions (scale.radialLinear.js:426-434) gives the
  // backdrop height as the padding of the scale. Thus the width and the
  // height of the scale show it, without a text measurement.
  const backdrop = (theme, fontSize) =>
    row(() => {
      if (fontSize !== undefined) put(defaults, 'font.size', fontSize);
      const scale = radialChart({}, theme).scales.r;
      const font = scale.options.ticks.font;
      return [font && font.size, scale.width, scale.height];
    });
  observe('no theme', backdrop(null));
  observe('no theme, defaults.font.size 30', backdrop(null, 30));
  observe(
    'a theme tick font with a size',
    backdrop({scale: {ticks: {font: {size: 20}}}}, 30),
  );
  observe(
    'a theme tick font without a size',
    backdrop({scale: {ticks: {font: {family: 'serif'}}}}, 30),
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
  scales: {
    radialLinear: {
      pointLabels: {
        color: 'rgba(51, 102, 153, 1)',
        font: {family: 'Arial', style: 'italic', size: 11},
      },
      angleLines: {color: 'rgba(0, 128, 0, 0.5)'},
    },
  },
  plugins: {
    title: {color: 'rgba(51, 102, 153, 1)', font: {family: 'Arial', size: 14}},
    subtitle: {
      color: 'rgba(51, 102, 153, 1)',
      font: {family: 'Arial', size: 14},
    },
    legend: {
      labels: {font: {family: 'Arial', size: 14}},
      title: {font: {family: 'Arial', size: 14}},
    },
    tooltip: {
      titleFont: {family: 'Arial', size: 14},
      bodyFont: {family: 'Arial', size: 14},
      footerFont: {family: 'Arial', size: 14},
    },
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
    // The fonts of _resolveTickFontOptions (core.scale.js:1700-1703) and of
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

/**
 * The compiled light preset: the result of
 * `compileChartTheme(ChartThemes.light)` of lib/src/theme/compile.dart. The
 * Dart test compares the two.
 */
const compiledLight = {
  color: 'rgba(102, 102, 102, 1)',
  scale: {
    ticks: {
      color: 'rgba(102, 102, 102, 1)',
      backdropColor: 'rgba(255, 255, 255, 0.75)',
      font: {
        family: "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
        size: 12,
        style: 'normal',
        lineHeight: 1.2,
      },
    },
    title: {
      color: 'rgba(102, 102, 102, 1)',
      font: {
        family: "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
        size: 12,
        style: 'normal',
        lineHeight: 1.2,
      },
    },
    grid: {color: 'rgba(0, 0, 0, 0.1)'},
    border: {color: 'rgba(0, 0, 0, 0.1)'},
  },
  scales: {
    radialLinear: {
      pointLabels: {
        color: 'rgba(102, 102, 102, 1)',
        font: {
          family: "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
          style: 'normal',
          lineHeight: 1.2,
          size: 10,
        },
      },
      angleLines: {color: 'rgba(0, 0, 0, 0.1)'},
    },
  },
  plugins: {
    title: {
      color: 'rgba(102, 102, 102, 1)',
      font: {
        family: "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
        size: 12,
        style: 'normal',
        lineHeight: 1.2,
      },
    },
    subtitle: {
      color: 'rgba(102, 102, 102, 1)',
      font: {
        family: "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
        size: 12,
        style: 'normal',
        lineHeight: 1.2,
      },
    },
    legend: {
      labels: {
        font: {
          family: "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
          size: 12,
          style: 'normal',
          lineHeight: 1.2,
        },
      },
      title: {
        font: {
          family: "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
          size: 12,
          style: 'normal',
          lineHeight: 1.2,
        },
      },
    },
    tooltip: {
      backgroundColor: 'rgba(0, 0, 0, 0.8)',
      titleColor: 'rgba(255, 255, 255, 1)',
      bodyColor: 'rgba(255, 255, 255, 1)',
      footerColor: 'rgba(255, 255, 255, 1)',
      multiKeyBackground: 'rgba(255, 255, 255, 1)',
      titleFont: {
        family: "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
        size: 12,
        style: 'normal',
        lineHeight: 1.2,
      },
      bodyFont: {
        family: "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
        size: 12,
        style: 'normal',
        lineHeight: 1.2,
      },
      footerFont: {
        family: "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
        size: 12,
        style: 'normal',
        lineHeight: 1.2,
      },
    },
    colors: {
      $borderColors: [
        'rgba(54, 162, 235, 1)',
        'rgba(255, 99, 132, 1)',
        'rgba(255, 159, 64, 1)',
        'rgba(255, 205, 86, 1)',
        'rgba(75, 192, 192, 1)',
        'rgba(153, 102, 255, 1)',
        'rgba(201, 203, 207, 1)',
      ],
      $backgroundColors: [
        'rgba(54, 162, 235, 0.5)',
        'rgba(255, 99, 132, 0.5)',
        'rgba(255, 159, 64, 0.5)',
        'rgba(255, 205, 86, 0.5)',
        'rgba(75, 192, 192, 0.5)',
        'rgba(153, 102, 255, 0.5)',
        'rgba(201, 203, 207, 0.5)',
      ],
    },
  },
  elements: {
    point: {
      borderColor: 'rgba(0, 0, 0, 0.1)',
      backgroundColor: 'rgba(0, 0, 0, 0.1)',
    },
    line: {
      borderColor: 'rgba(0, 0, 0, 0.1)',
      backgroundColor: 'rgba(0, 0, 0, 0.1)',
    },
    bar: {
      borderColor: 'rgba(0, 0, 0, 0.1)',
      backgroundColor: 'rgba(0, 0, 0, 0.1)',
    },
    arc: {
      backgroundColor: 'rgba(0, 0, 0, 0.1)',
      borderColor: 'rgba(255, 255, 255, 1)',
    },
  },
  transitions: {
    theme: {animation: {duration: 200, easing: 'linear'}},
    themeFrame: {animation: {duration: 0}},
  },
};

/**
 * The compiled theme of the raw Map theme `_fontTheme` of
 * precedence_test.dart: the font token without the token `pointLabels`.
 * The point-label font is the base font without size (theming.md section
 * 3.4).
 */
const compiledFont = {
  scale: {
    ticks: {font: {family: 'serif', size: 14}},
    title: {font: {family: 'serif', size: 14}},
  },
  scales: {radialLinear: {pointLabels: {font: {family: 'serif'}}}},
  plugins: {
    title: {font: {family: 'serif', size: 14}},
    subtitle: {font: {family: 'serif', size: 14}},
    legend: {
      labels: {font: {family: 'serif', size: 14}},
      title: {font: {family: 'serif', size: 14}},
    },
    tooltip: {
      titleFont: {family: 'serif', size: 14},
      bodyFont: {family: 'serif', size: 14},
      footerFont: {family: 'serif', size: 14},
    },
  },
  transitions: {
    theme: {animation: {duration: 200, easing: 'linear'}},
    themeFrame: {animation: {duration: 0}},
  },
};

/**
 * The scenario [name]: the options of the radial scale of a chart with the
 * `$theme` value [theme] (no key for `'absent'`). [replace] writes into the
 * global scopes before the chart, and the scenario undoes the writes.
 */
function radialSnapshot(name, theme, replace) {
  scenario(name, (observe) => row(() => {
    if (replace) replace();
    if (theme !== 'absent') observe('theme', theme);
    const chart = radialChart({}, theme === 'absent' ? null : theme);
    const r = chart.scales.r;
    const o = r.options;
    observe('scales', Object.keys(chart.scales).join(','));
    observe('colors', [
      o.pointLabels.color,
      o.angleLines.color,
      o.ticks.color,
      o.ticks.backdropColor,
      o.grid.color,
      o.pointLabels.backdropColor,
    ]);
    // The fonts of fitWithPointLabels (scale.radialLinear.js:96-97) and of
    // _resolveTickFontOptions (core.scale.js:1700-1703).
    const pointLabelFont = toFont(o.pointLabels.font);
    const tickFont = r._resolveTickFontOptions(0);
    observe('fonts', [
      pointLabelFont.family,
      pointLabelFont.size,
      pointLabelFont.string,
      tickFont.family,
      tickFont.size,
      tickFont.string,
    ]);
    observe('size', [r.width, r.height]);
  }));
}

/**
 * The scenario [name] of test 5: the scales of a chart of the type [type]
 * with the `$theme` value [theme] (no key for null). A theme key
 * `scales.<scale type>` creates no axis (theming.md section 3.3).
 */
function axes(name, type, theme) {
  scenario(name, (observe) => {
    if (theme) observe('theme', theme);
    const config =
      type === 'themeRadial'
        ? {type, data: radialData(), options: {}}
        : {type, data: realData(undefined), options: {}};
    if (theme) config.$theme = theme;
    const chart = acquireChart(config);
    observe('scales', Object.keys(chart.scales).join(','));
    observe('option scales', Object.keys(chart.options.scales).join(','));
    observe('config scales', chart.config.options.scales);
  });
}

snapshot('no theme', 'absent', false);
snapshot('a null theme', null, false);
snapshot('a string theme', 'not a map', false);
snapshot('user values', 'absent', true);
snapshot('a compiled theme', compiledTheme, false);
snapshot('a compiled theme and user values', compiledTheme, true);
radialSnapshot('a radial chart without a theme', 'absent');
radialSnapshot('a radial chart with a compiled theme', compiledTheme);
radialSnapshot('a radial chart with the light preset', compiledLight);
radialSnapshot('a radial chart with a theme font without size', compiledFont);
// theming.md section 4, the column "Replaces": a chart without a theme, with
// the values that the tokens replace in the global scopes. A theme must give
// the same options as the replaced values.
radialSnapshot(
  'a radial chart with the values that the tokens replace',
  'absent',
  () => {
    put(defaults, 'color', 'rgba(51, 102, 153, 1)');
    put(defaults, 'borderColor', 'rgba(0, 128, 0, 0.5)');
    put(defaults, 'scale.ticks.backdropColor', 'rgba(0, 0, 0, 0.75)');
    put(defaults, 'font.family', 'Arial');
    put(defaults, 'font.size', 14);
    put(defaults, 'scales.radialLinear.pointLabels.font.style', 'italic');
    put(defaults, 'scales.radialLinear.pointLabels.font.size', 11);
  },
);
radialSnapshot(
  'a radial chart with the font that the theme font replaces',
  'absent',
  () => {
    put(defaults, 'font.family', 'serif');
    put(defaults, 'font.size', 14);
  },
);

axes('axes of a cartesian chart without a theme', 'themeReal', null);
axes('axes of a cartesian chart with a radialLinear theme key', 'themeReal', {
  scales: {
    radialLinear: {pointLabels: {color: 'red'}, angleLines: {color: 'red'}},
  },
});
axes('axes of a cartesian chart with the light preset', 'themeReal', compiledLight);
axes('axes of a radial chart without a theme', 'themeRadial', null);
axes('axes of a radial chart with cartesian theme keys', 'themeRadial', {
  scales: {
    category: {ticks: {color: 'red'}},
    linear: {ticks: {color: 'red'}},
  },
});
// Test 5 on the bar and doughnut controllers of phase 7 (Chart.js ADR 0030,
// section 9). The bar chart has the scales x and y of its overrides
// (controller.bar.js:44-55). The doughnut chart has no scale.
axes('axes of a bar chart without a theme', 'bar', null);
axes('axes of a bar chart with a radialLinear theme key', 'bar', {
  scales: {
    radialLinear: {pointLabels: {color: 'red'}, angleLines: {color: 'red'}},
  },
});
axes('axes of a bar chart with the light preset', 'bar', compiledLight);
axes('axes of a doughnut chart without a theme', 'doughnut', null);
axes('axes of a doughnut chart with cartesian theme keys', 'doughnut', {
  scale: {ticks: {color: 'red'}},
  scales: {
    category: {ticks: {color: 'red'}},
    linear: {ticks: {color: 'red'}},
  },
});
axes('axes of a doughnut chart with the light preset', 'doughnut', compiledLight);

// ---------------------------------------------------------------------------
// The hover steps on the 8 chart types (Chart.js ADR 0030, section 10).

/**
 * The compiled theme of the raw Map theme `_hoverTheme` of
 * precedence_test.dart: the color tokens `color`, `borderColor` and
 * `backgroundColor`. The Dart test compares it with the result of
 * `compileChartTheme`.
 */
const compiledHover = {
  color: 'rgba(51, 102, 153, 1)',
  scale: {
    ticks: {color: 'rgba(51, 102, 153, 1)'},
    title: {color: 'rgba(51, 102, 153, 1)'},
    grid: {color: 'rgba(0, 128, 0, 0.5)'},
    border: {color: 'rgba(0, 128, 0, 0.5)'},
  },
  scales: {
    radialLinear: {
      pointLabels: {color: 'rgba(51, 102, 153, 1)'},
      angleLines: {color: 'rgba(0, 128, 0, 0.5)'},
    },
  },
  plugins: {
    title: {color: 'rgba(51, 102, 153, 1)'},
    subtitle: {color: 'rgba(51, 102, 153, 1)'},
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
    arc: {backgroundColor: 'rgba(200, 0, 0, 1)'},
  },
  transitions: {
    theme: {animation: {duration: 200, easing: 'linear'}},
    themeFrame: {animation: {duration: 0}},
  },
};

/**
 * The values that the tokens of the hover theme replace (theming.md section
 * 4, the column "Replaces"), by the dot path in `defaults`.
 */
const hoverReplaced = {
  backgroundColor: 'rgba(200, 0, 0, 1)',
  borderColor: 'rgba(0, 128, 0, 0.5)',
  color: 'rgba(51, 102, 153, 1)',
};

/** The data of the hover chart of the type [type]: one dataset. */
function hoverData(type) {
  switch (type) {
    case 'scatter':
      return {
        datasets: [
          {
            data: [
              {x: 1, y: 2},
              {x: 5, y: 8},
              {x: 9, y: 4},
            ],
          },
        ],
      };
    case 'bubble':
      return {
        datasets: [
          {
            data: [
              {x: 1, y: 2, r: 5},
              {x: 5, y: 8, r: 5},
              {x: 9, y: 4, r: 5},
            ],
          },
        ],
      };
    default:
      return {labels: ['a', 'b', 'c'], datasets: [{data: [3, 5, 2]}]};
  }
}

/** The observed options of [element]. */
function hoverOptions(element) {
  const o = element.options;
  const result = {
    backgroundColor: o.backgroundColor,
    borderColor: o.borderColor,
    borderWidth: o.borderWidth,
    hoverBackgroundColor: o.hoverBackgroundColor,
    hoverBorderColor: o.hoverBorderColor,
  };
  if (element instanceof PointElement) result.radius = o.radius;
  return result;
}

/** The scenario `hover <type>`. */
function hover(type) {
  scenario(`hover ${type}`, (observe) =>
    row(() => {
      const config = {type, data: hoverData(type), options: {}};
      if (MODE === 'upstream') {
        for (const [path, value] of Object.entries(hoverReplaced)) {
          put(defaults, path, value);
        }
      } else {
        config.$theme = compiledHover;
      }
      const chart = acquireChart(config);
      const meta = chart.getDatasetMeta(0);
      const center = (index) => {
        const {x, y} = meta.data[index].getCenterPoint();
        return {x: Math.round(x), y: Math.round(y)};
      };
      const step = (eventType, point) => {
        chart._eventHandler({
          type: eventType,
          x: point.x,
          y: point.y,
          native: {type: eventType},
        });
        observe(
          'active',
          chart
            .getActiveElements()
            .map(({datasetIndex, index}) => [datasetIndex, index]),
        );
        observe('element 0', hoverOptions(meta.data[0]));
        observe('element 1', hoverOptions(meta.data[1]));
      };
      step('mousemove', center(0));
      const second = center(1);
      step('mousemove', second);
      step('mouseout', second);
    }),
  );
}

scenario('hover theme', (observe) => observe('theme', compiledHover));
for (const type of [
  'bar',
  'bubble',
  'doughnut',
  'line',
  'pie',
  'polarArea',
  'radar',
  'scatter',
]) {
  hover(type);
}

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

// ---------------------------------------------------------------------------
// The palette of plugin.colors (Chart.js ADR 0042; theming.md section 8,
// the palette rows of test 2 and test 3).

/** The theme palette P1: three border and three background sentinels. */
const paletteP1 = {
  $borderColors: ['P1-b0', 'P1-b1', 'P1-b2'],
  $backgroundColors: ['P1-g0', 'P1-g1', 'P1-g2'],
};

/** The theme palette P2: two border and two background sentinels. */
const paletteP2 = {
  $borderColors: ['P2-b0', 'P2-b1'],
  $backgroundColors: ['P2-g0', 'P2-g1'],
};

/** The theme element colors of the bar and arc elements. */
function elementColors() {
  return {
    bar: {backgroundColor: 'T-bg', borderColor: 'T-bc'},
    arc: {backgroundColor: 'T-bg', borderColor: 'T-bc'},
  };
}

/**
 * The data of a palette chart of the type [type]: [count] datasets with
 * three values each, or three points for bubble and scatter.
 */
function paletteData(type, count) {
  const values = [
    [3, 5, 2],
    [4, 1, 6],
  ];
  const data = (d) => {
    const v = values[d % 2];
    if (type === 'bubble') return v.map((y, i) => ({x: i * 4 + 1, y, r: 5}));
    if (type === 'scatter') return v.map((y, i) => ({x: i * 4 + 1, y}));
    return [...v];
  };
  const datasets = Array.from({length: count}, (_, d) => ({data: data(d)}));
  return type === 'bubble' || type === 'scatter'
    ? {datasets}
    : {labels: ['a', 'b', 'c'], datasets};
}

/**
 * A palette chart of the type [type] with [count] datasets, the colors
 * plugin on, the user [options] (merged into the plugin options for
 * `plugins.colors`), the dataset values [datasets] and the theme [theme]
 * (no key for null).
 */
function paletteChart(
  type,
  {count = 2, theme = null, options = {}, datasets = []} = {},
) {
  const data = paletteData(type, count);
  datasets.forEach((values, d) => Object.assign(data.datasets[d], values));
  const {plugins = {}, ...rest} = options;
  const {colors: colorOptions = {}, ...otherPlugins} = plugins;
  const config = {
    type,
    data,
    options: {
      ...rest,
      plugins: {...otherPlugins, colors: {enabled: true, ...colorOptions}},
    },
  };
  if (theme !== null) config.$theme = theme;
  return acquireChart(config);
}

/** The colors `[borderColor, backgroundColor]` of the options [o]. */
function colorPair(o) {
  return [o.borderColor, o.backgroundColor];
}

/**
 * The palette observations of [chart] with the label prefix [prefix]: for
 * each dataset, its raw colors and the colors of the options of its data
 * elements 0 and 1.
 */
function observePalette(observe, prefix, chart) {
  chart.data.datasets.forEach((dataset, d) => {
    observe(`${prefix}dataset ${d}`, colorPair(dataset));
    const meta = chart.getDatasetMeta(d);
    for (const i of [0, 1]) {
      observe(`${prefix}element ${d}.${i}`, colorPair(meta.data[i].options));
    }
  });
}

scenario('palette 1', (observe) => {
  // Row 1: the theme palette beats the theme element colors.
  for (const [type, count] of [
    ['bar', 4],
    ['doughnut', 2],
    ['polarArea', 2],
  ]) {
    const theme = {elements: elementColors(), plugins: {colors: paletteP1}};
    observePalette(observe, `${type} `, paletteChart(type, {count, theme}));
  }
});

scenario('palette 2', (observe) => {
  // Row 2: user colors disable the theme palette. With forceOverride, the
  // theme palette writes over the dataset color.
  const theme = () => ({
    elements: elementColors(),
    plugins: {colors: paletteP1},
  });
  observePalette(
    observe,
    'dataset color ',
    paletteChart('bar', {theme: theme(), datasets: [{borderColor: 'U'}]}),
  );
  observePalette(
    observe,
    'root color ',
    paletteChart('bar', {theme: theme(), options: {backgroundColor: 'U'}}),
  );
  observePalette(
    observe,
    'elements color ',
    paletteChart('bar', {
      theme: theme(),
      options: {elements: {bar: {borderColor: 'U'}}},
    }),
  );
  observePalette(
    observe,
    'forceOverride ',
    paletteChart('bar', {
      theme: theme(),
      datasets: [{borderColor: 'U'}],
      options: {plugins: {colors: {forceOverride: true}}},
    }),
  );
});

scenario('palette 3', (observe) => {
  // Row 3: a theme without a palette keeps the upstream palette. The bar
  // chart has 8 datasets: the palette of 7 colors wraps.
  const theme = () => ({elements: elementColors()});
  observePalette(
    observe,
    'bar ',
    paletteChart('bar', {count: 8, theme: theme()}),
  );
  observePalette(
    observe,
    'doughnut ',
    paletteChart('doughnut', {theme: theme()}),
  );
});

scenario('palette 4', (observe) => {
  // Row 4: two interleaved charts keep their own palettes. The charts A
  // (palette P1), B (palette P2) and C (no theme) colorize at each update
  // (forceOverride).
  const options = {plugins: {colors: {forceOverride: true}}};
  const a = paletteChart('bar', {theme: {plugins: {colors: paletteP1}}, options});
  const b = paletteChart('bar', {theme: {plugins: {colors: paletteP2}}, options});
  const c = paletteChart('bar', {options});
  observePalette(observe, 'A ', a);
  observePalette(observe, 'B ', b);
  observePalette(observe, 'C ', c);
  a.update();
  observePalette(observe, 'A after A.update ', a);
  c.update();
  observePalette(observe, 'C after C.update ', c);
  b.update();
  observePalette(observe, 'B after B.update ', b);
});

scenario('palette 5', (observe) => {
  // No theme: a palette key in the user options, in `defaults` or in
  // `overrides[type]` has no effect, as upstream.
  observePalette(
    observe,
    'user ',
    row(() =>
      paletteChart('bar', {
        options: {plugins: {colors: {...paletteP2}}},
      }),
    ),
  );
  observePalette(
    observe,
    'defaults ',
    row(() => {
      put(defaults, 'plugins.colors.$borderColors', ['D-b0']);
      put(defaults, 'plugins.colors.$backgroundColors', ['D-g0']);
      return paletteChart('bar');
    }),
  );
  observePalette(
    observe,
    'overrides ',
    row(() => {
      put(overrides, 'bar.plugins.colors.$borderColors', ['O-b0']);
      put(overrides, 'bar.plugins.colors.$backgroundColors', ['O-g0']);
      return paletteChart('bar');
    }),
  );
});

scenario('palette 6', (observe) => {
  // A raw theme with an empty or non-List palette keeps the upstream
  // palette.
  for (const [name, value] of [
    ['empty', []],
    ['string', 'red'],
    ['map', {a: 'P1-b0'}],
  ]) {
    const theme = {
      plugins: {colors: {$borderColors: value, $backgroundColors: value}},
    };
    observePalette(observe, `${name} `, paletteChart('bar', {theme}));
  }
});

scenario('palette 8', (observe) => {
  // A removed theme gives the upstream palette at the next colorize: hunk
  // H5 sets both variables at each run.
  const chart = paletteChart('bar', {
    theme: {plugins: {colors: paletteP1}},
    options: {plugins: {colors: {forceOverride: true}}},
  });
  observePalette(observe, 'themed ', chart);
  delete chart.config._config.$theme;
  chart.update();
  observePalette(observe, 'theme removed ', chart);
});

/**
 * The style setters `fillStyle` and `strokeStyle` of one draw of each
 * dataset controller of [chart], in the dataset order, as `[name, value]`.
 */
function styleSetters(chart) {
  const ctx = chart.ctx;
  const setters = [];
  chart.data.datasets.forEach((_, d) => {
    ctx.resetCalls();
    chart.getDatasetMeta(d).controller.draw();
    for (const {name, args} of ctx.getCalls()) {
      if (name === 'setFillStyle' || name === 'setStrokeStyle') {
        setters.push([name, args[0]]);
      }
    }
  });
  ctx.resetCalls();
  return setters;
}

/**
 * The scenario `light palette <type>` of test 3: a chart of the type [type]
 * with two datasets, the colors plugin on, no user color and the compiled
 * light preset. The upstream run ignores the theme: its lines are the lines
 * of the chart without a theme. For each dataset: the raw colors, the colors
 * of the dataset element (line and radar), and the colors of the data
 * elements 0 and 1 in the modes `default` and `active`. Then the style
 * setters of one draw of the datasets.
 */
function lightPalette(type) {
  scenario(`light palette ${type}`, (observe) => {
    const chart = paletteChart(type, {theme: compiledLight});
    chart.data.datasets.forEach((dataset, d) => {
      observe(`dataset ${d}`, colorPair(dataset));
      const meta = chart.getDatasetMeta(d);
      if (meta.dataset) {
        observe(`dataset ${d} line`, colorPair(meta.dataset.options));
      }
      for (const i of [0, 1]) {
        observe(`element ${d}.${i}`, colorPair(meta.data[i].options));
        observe(
          `element ${d}.${i} active`,
          colorPair(meta.controller.resolveDataElementOptions(i, 'active')),
        );
      }
    });
    observe('draw', styleSetters(chart));
  });
}

for (const type of [
  'bar',
  'bubble',
  'doughnut',
  'line',
  'pie',
  'polarArea',
  'radar',
  'scatter',
]) {
  lightPalette(type);
}

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
  // The hover steps: the compiled theme must give the options of the
  // replaced values (Chart.js ADR 0030, section 10).
  const lines = (run, name) =>
    run.scenarios.find((s) => s.name === name).lines.join('\n');
  // The palette rows 5 and 6: a palette key outside the theme, and a theme
  // palette that is not a List with at least one item, keep the upstream
  // palette (Chart.js ADR 0042).
  for (const {name} of upstream.scenarios) {
    if (!name.startsWith('hover ') && name !== 'palette 5' && name !== 'palette 6') {
      continue;
    }
    if (lines(upstream, name) !== lines(prototype, name)) {
      throw new Error(`The two runs differ in the scenario ${name}.`);
    }
  }
  const out = fileURLToPath(
    new URL('../../test/port/theme/precedence_reference.dart', import.meta.url),
  );
  const {node, v8, platform, arch} = upstream;
  const dart = `// Original code, not ported from Chart.js: theme precedence reference data.

// Generated by tool/reference/theme_precedence_reference.mjs. Do not edit.
// Node.js ${node} (${platform}-${arch}), V8 ${v8}:
// src/core/core.controller.js, the category, linear and radial linear
// scales, the 8 controllers and the colors plugin at the pinned Chart.js,
// with the upstream src/core/core.config.js and src/plugins/plugin.colors.ts,
// and with a JavaScript prototype of the hunks H0-H3 and H4a-H5.
// ${upstream.scenarios.length} scenarios.

/// The Node.js version that generated the data.
const String themePrecedenceReferenceNode = '${node}';

/// The V8 version that generated the data.
const String themePrecedenceReferenceV8 = '${v8}';

/// The architecture of the Node.js build that generated the data.
const String themePrecedenceReferenceArch = '${arch}';

/// The observations of each scenario with the upstream
/// src/core/core.config.js and src/plugins/plugin.colors.ts, by name, one on
/// each line: \`<label>: <value>\`.
const Map<String, String> themePrecedenceUpstream = {
${dartMap(upstream.scenarios)}};

/// The observations of each scenario with the JavaScript prototype of the
/// hunks H0-H3 in src/core/core.config.js and H4a-H5 in
/// src/plugins/plugin.colors.ts, by name, one on each line:
/// \`<label>: <value>\`.
const Map<String, String> themePrecedencePrototype = {
${dartMap(prototype.scenarios)}};
`;
  writeFileSync(out, dart);
  execFileSync('dart', ['format', out], {stdio: 'inherit'});
  console.log(`Wrote ${out}: ${upstream.scenarios.length} scenarios.`);
}
