// Original code, not ported from chartjs-chart-sankey: the fixture reference generator.
//
// It writes test/fixtures/fixtures_reference.dart, the expected
// observations of the 44 upstream fixtures of test/fixtures/ and
// test/fixtures/issues/, and test/fixtures/manifest.json, the list of the
// fixture files with their SHA-256 for the fixture runner of
// package:chartjs_test_utils (row harness-fixture-observations of
// doc/differences.md). Nothing in lib/ or test/ runs this script.
//
// The method. Upstream compares each fixture with a PNG image. The port
// compares no image (Chart.js ADR 0034, section 4). The script builds each
// fixture chart, runs its `run` hook, and records one observation of the
// chart. An observation has:
// - `chartArea`: `[left, top, right, bottom]`;
// - `width` and `height`: the size of the chart;
// - `nodes`: for each node of the Map `_nodes` of the controller of dataset
//   0, in its iteration order, `[key, x, y, in, out, size]`;
// - `flows`: for each data element of dataset 0,
//   `[x, y, x2, y2, height, width]`;
// - `draw`: the calls of one `chart.draw()` that draw a rectangle, a text
//   or a filled path: `['fillRect', x, y, width, height, fill]` (a node, or
//   the background of a label), `['strokeRect', x, y, width, height,
//   stroke]` (the border of a node), `['fillText', text, x, y, textAlign,
//   fill]` (a line of a label) and `['fill', fill]` (the path of a flow, or
//   the rounded background of a label). `fill` and `stroke` are the style
//   in effect: a color as `#rrggbbaa` (@kurkle/color of the pin parses the
//   CSS color), the gradient of a flow as `['linearGradient', x0, y0, x1,
//   y1, [offset, color], ...]`, or null for another style. `textAlign` is
//   the align in effect. The script follows `save` and `restore` for the
//   three states. The path of a flow is not in the data: the positions of
//   `flows` give it.
// test/fixtures/observe.dart records the same observation in Dart, and
// test/fixtures/index.dart compares the two.
//
// The script runs the pinned upstream sources with the type stripping of
// Node.js: src/index.ts of Chart.js (the module of `chart.js`, with
// src/helpers/index.ts as `chart.js/helpers`) and src/index.ts of
// chartjs-chart-sankey, which registers the controller and the element
// (test/setup.js:3). Resolve hooks map the `.js` and extensionless imports
// to the `.ts` files, and `@kurkle/color` to
// third_party/kurkle-color/src/index.esm.js. A load hook gives each
// `package.json` import its version as a module. Each fixture file is an ES
// module: the script imports it and reads its default export.
//
// Node.js has no DOM. The chart gets BasicPlatform, as in the generators of
// packages/flutter_chartjs_port/tool/reference/. The canvas is the fake
// canvas of packages/flutter_chartjs_port/tool/reference/
// scale_chart_common.mjs with its LiberationContext (the widths of
// Liberation Sans 2.1.5, the test font of the harness) and a
// `createLinearGradient` that draws nothing. A chart is made as `buildChart`
// of test/utils/chart.js:30-60 makes it: the canvas of `options.canvas`
// (512 x 512 by default), `animation: false`, `responsive: false` and
// `locale: 'en-US'`. `prepareConfig` of test/utils/fixtures.js:52-60 turns
// the plugins off. `spriteText` only changes how a browser draws the text:
// the script does not read it. The set-up is test/setup.js: each component
// of Chart.js, the device pixel ratio 1 and the colors plugin off.
//
// Usage, from packages/flutter_chartjs_chart_sankey_port, with the
// darwin-arm64 build of Node.js v24.22.1 (Chart.js ADR 0045) and the Dart
// SDK on the PATH (the script formats the output with `dart format`):
//
//   node tool/reference/fixtures_reference.mjs
//
// The script stops unless each of third_party/Chart.js,
// third_party/kurkle-color, third_party/chartjs-test-utils and
// third_party/chartjs-chart-sankey is at the `commit` of its entry in the
// tool/port_sources.yaml of its port, with no change in the folders that the
// script reads. Check out the submodules with `dart run melos run upstream`.

import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {existsSync, readFileSync, readdirSync, writeFileSync} from 'node:fs';
import {registerHooks} from 'node:module';
import {fileURLToPath} from 'node:url';

const THIRD_PARTY = new URL('../../../../third_party/', import.meta.url);
const CHARTJS = new URL('Chart.js/', THIRD_PARTY);
const SANKEY = new URL('chartjs-chart-sankey/', THIRD_PARTY);
const KURKLE = new URL('kurkle-color/src/index.esm.js', THIRD_PARTY);
const FIXTURES = new URL('test/fixtures/', SANKEY);
const HOST_SOURCES = new URL('../../../flutter_chartjs_port/tool/port_sources.yaml', import.meta.url);
const SANKEY_SOURCES = new URL('../port_sources.yaml', import.meta.url);
const COMMON = new URL(
  '../../../flutter_chartjs_port/tool/reference/scale_chart_common.mjs',
  import.meta.url,
);
const OUT = fileURLToPath(new URL('../../test/fixtures/fixtures_reference.dart', import.meta.url));
const MANIFEST = fileURLToPath(new URL('../../test/fixtures/manifest.json', import.meta.url));

/** The count of the fixture files at the pin. */
const FIXTURE_COUNT = 44;

/** Writes [message] to stderr and stops the process. */
function stop(message) {
  console.error(message);
  process.exit(1);
}

// ---------------------------------------------------------------------------
// The pins.

/**
 * The submodules that the script reads: the port_sources.yaml file of the
 * entry, its header, the folder in third_party/ and the folders that the
 * script reads.
 */
const PINNED = [
  {sources: HOST_SOURCES, header: 'Chart.js', folder: 'Chart.js', paths: ['src', 'package.json']},
  {sources: HOST_SOURCES, header: '@kurkle/color', folder: 'kurkle-color', paths: ['src']},
  {sources: HOST_SOURCES, header: 'chartjs-test-utils', folder: 'chartjs-test-utils', paths: ['src']},
  {
    sources: SANKEY_SOURCES,
    header: 'chartjs-chart-sankey',
    folder: 'chartjs-chart-sankey',
    paths: ['src', 'test'],
  },
];

/** The `commit` of the entry [header] of the port_sources.yaml file [sources]. */
function pinnedCommit(sources, header) {
  const path = fileURLToPath(sources);
  const entries = readFileSync(path, 'utf8').split(/^ {2}- header: /m);
  const entry = entries.find((e) => e.startsWith(`${header}\n`) || e.startsWith(`"${header}"\n`));
  const commit = entry?.match(/^ {6}commit: "?([0-9a-f]{40})"?\s*$/m)?.[1];
  if (!commit) stop(`${path} has no commit for ${header}.`);
  return commit;
}

/**
 * Stops unless each submodule of PINNED is at its pinned commit, with no
 * change in the folders that the script reads. Returns the commits by
 * folder. The form of checkPin in the generators of flutter_chartjs_port.
 */
function checkPins() {
  const commits = {};
  for (const {sources, header, folder, paths} of PINNED) {
    const commit = pinnedCommit(sources, header);
    const checkout = fileURLToPath(new URL(folder, THIRD_PARTY));
    const git = (...args) => {
      try {
        return execFileSync('git', ['-C', checkout, ...args], {
          encoding: 'utf8',
          stdio: ['ignore', 'pipe', 'pipe'],
        }).trim();
      } catch (error) {
        stop(
          `git ${args.join(' ')} failed in ${checkout}: ${error.message.trim()}\n` +
            'Check out the submodules with `dart run melos run upstream`.',
        );
      }
    };
    const head = git('rev-parse', 'HEAD');
    if (head !== commit) {
      stop(
        `${checkout} is at ${head}, not at the pin ${commit} of ${header}. ` +
          'Check out the submodules with `dart run melos run upstream`.',
      );
    }
    if (git('status', '--porcelain', '--', ...paths) !== '') {
      stop(`${checkout} has changes in ${paths.join(', ')}. The script reads the pin.`);
    }
    commits[folder] = head;
  }
  return commits;
}

const COMMITS = checkPins();

/**
 * The version of the sankey pin, `v0.19.1` without its "v". The package.json
 * of the pin has the version `0.0.0-development`: the release job writes the
 * version of a release.
 */
const SANKEY_VERSION = readFileSync(SANKEY_SOURCES, 'utf8').match(
  /^ {4}version: "?v([^"\s]+)"?\s*$/m,
)[1];
const CHARTJS_VERSION = JSON.parse(readFileSync(new URL('package.json', CHARTJS), 'utf8')).version;

// ---------------------------------------------------------------------------
// The module hooks.

/** Whether [url] is a file of a folder in [folders] (URLs). */
const inside = (url, ...folders) => folders.some((f) => url?.startsWith(f.href));

registerHooks({
  resolve(specifier, context, nextResolve) {
    const parent = context.parentURL;
    if (inside(parent, SANKEY)) {
      if (specifier === 'chart.js') {
        return nextResolve(new URL('src/index.ts', CHARTJS).href, context);
      }
      if (specifier === 'chart.js/helpers') {
        return nextResolve(new URL('src/helpers/index.ts', CHARTJS).href, context);
      }
    }
    if (specifier === '@kurkle/color' && inside(parent, CHARTJS)) {
      return nextResolve(KURKLE.href, context);
    }
    // The upstream sources import `./x.js` or `./x` where the file is `./x.ts`.
    if (specifier.startsWith('.') && inside(parent, CHARTJS, new URL('src/', SANKEY))) {
      const url = new URL(specifier, parent);
      if (!existsSync(fileURLToPath(url))) {
        const ts = new URL(`${url.href.replace(/\.js$/, '')}.ts`);
        if (existsSync(fileURLToPath(ts))) return nextResolve(ts.href, context);
      }
    }
    return nextResolve(specifier, context);
  },
  load(url, context, nextLoad) {
    // core.controller.js:12 imports `version` from package.json without an
    // import attribute.
    if (url.endsWith('/package.json') && inside(url, CHARTJS)) {
      const {version} = JSON.parse(readFileSync(new URL(url), 'utf8'));
      return {
        format: 'module',
        source: `export const version = ${JSON.stringify(version)};`,
        shortCircuit: true,
      };
    }
    return nextLoad(url, context);
  },
});

// The fake canvas of the host generators, with its Liberation Sans context.
// Its import checks the chartjs-test-utils pin again.
const {fakeCanvas, dartLiteral} = await import(COMMON.href);

const chartjs = await import(new URL('src/index.ts', CHARTJS).href);
const {Chart} = chartjs;
const {Color} = await import(KURKLE.href);

// test/setup.js:3 `import '../src/index'`: the entry registers the
// controller and the element.
const sankey = await import(new URL('src/index.ts', SANKEY).href);
if (Chart.registry.getController('sankey') !== sankey.SankeyController) {
  stop('src/index.ts did not register the controller.');
}
if (Chart.registry.getElement('flow') !== sankey.Flow) {
  stop('src/index.ts did not register the element.');
}

// test/setup.js:7 `Chart.register(...registerables)`: the four namespaces
// of src/index.ts:17-22 of Chart.js. `each` does not walk a module namespace
// (helpers.core.ts:53-54), so the script registers their values, in the key
// order of the namespaces, as test/flutter_test_config.dart registers the
// namespaces of the port (Chart.js ADR 0041, section 1 item 3).
for (const namespace of chartjs.registerables) {
  Chart.register(...Object.values(namespace));
}
{
  const ids = Object.keys(Chart.registry.plugins.items).join();
  if (ids !== 'colors,decimation,filler,legend,subtitle,title,tooltip') {
    stop(`The registry has the plugins ${ids}, not the seven of src/plugins/index.js.`);
  }
}

// test/setup.js:16-20.
Chart.defaults.devicePixelRatio = 1;
// Disable colors plugin for tests.
Chart.defaults.plugins.colors.enabled = false;

// ---------------------------------------------------------------------------
// The chart.

/**
 * `buildChart(config, options)` of test/utils/chart.js:30-60 on a fake
 * canvas. `spriteText` (:51-53) has no effect on the observations.
 */
function buildChart(config = {}, options = {}) {
  if (options.wrapper || options.persistent) {
    stop('A fixture with wrapper options: extend buildChart.');
  }
  const attributes = options.canvas || {height: 512, width: 512};
  for (const key of Object.keys(attributes)) {
    if (key !== 'width' && key !== 'height') stop(`buildChart has no canvas attribute ${key}.`);
  }
  // A canvas without an attribute has the default size of a canvas.
  const canvas = fakeCanvas(attributes.width ?? 300, attributes.height ?? 150);
  const ctx = canvas.getContext('2d');
  // flow.ts:62-66: the gradient of a flow. The mock context has no gradient.
  ctx.createLinearGradient = (x0, y0, x1, y1) => ({
    x0,
    y0,
    x1,
    y1,
    stops: [],
    addColorStop(offset, color) {
      this.stops.push([offset, color]);
    },
  });

  // by default, remove chart animation and auto resize
  config.options = config.options || {};
  config.options.animation = config.options.animation === undefined ? false : config.options.animation;
  config.options.responsive =
    config.options.responsive === undefined ? false : config.options.responsive;
  config.options.locale = config.options.locale || 'en-US';

  return new Chart(ctx, config);
}

/** `prepareConfig(name, json)` of test/utils/fixtures.js:52-60. */
function prepareConfig(name, json) {
  const config = json.config;
  config.options = config.options || {};
  // plugins are disabled by default, except if the path contains 'plugin' or
  // there are instance plugins
  if (!name.includes('plugin') && config.plugins === undefined) {
    config.options.plugins = config.options.plugins || false;
  }
  return config;
}

// ---------------------------------------------------------------------------
// The observations.

/** A number of the data: `undefined` (a node without a layout) is null. */
const number = (v) => (v === undefined ? null : v);

/**
 * The style [style] of the canvas: a CSS color as `#rrggbbaa`, a gradient
 * of `createLinearGradient` of buildChart as `['linearGradient', x0, y0,
 * x1, y1, [offset, color], ...]`, or null for another style: a pattern, or
 * a string that does not parse.
 */
function hex(style) {
  if (style && Array.isArray(style.stops)) {
    const {x0, y0, x1, y1, stops} = style;
    return ['linearGradient', x0, y0, x1, y1, ...stops.map(([offset, color]) => [offset, hex(color)])];
  }
  if (typeof style !== 'string') return null;
  const color = new Color(style);
  if (!color.valid) return null;
  const {r, g, b, a} = color.rgb;
  const byte = (v) => Math.round(v).toString(16).padStart(2, '0');
  return `#${byte(r)}${byte(g)}${byte(b)}${byte(a * 255)}`;
}

/**
 * The rectangle, text and fill calls of one `chart.draw()` (see the header).
 * `drawCalls` of observe.dart reduces the calls of its recording context in
 * the same way.
 */
function drawCalls(chart) {
  const ctx = chart.ctx;
  ctx.resetCalls();
  chart.draw();
  const calls = ctx.getCalls();
  ctx.resetCalls();

  // A canvas starts with black styles and the text align `start`.
  let state = {fill: '#000000', stroke: '#000000', align: 'start'};
  const stack = [];
  const draw = [];
  for (const {name, args} of calls) {
    switch (name) {
      case 'save':
        stack.push({...state});
        break;
      case 'restore':
        if (stack.length) state = stack.pop();
        break;
      case 'setFillStyle':
        state.fill = args[0];
        break;
      case 'setStrokeStyle':
        state.stroke = args[0];
        break;
      case 'setTextAlign':
        state.align = args[0];
        break;
      case 'fillRect':
        draw.push(['fillRect', ...args.slice(0, 4), hex(state.fill)]);
        break;
      case 'strokeRect':
        draw.push(['strokeRect', ...args.slice(0, 4), hex(state.stroke)]);
        break;
      case 'fillText':
        draw.push(['fillText', ...args.slice(0, 3), state.align, hex(state.fill)]);
        break;
      case 'fill':
        draw.push(['fill', hex(state.fill)]);
        break;
      default:
        break;
    }
  }
  return draw;
}

/** The observation of [chart] (see the header). */
function observe(chart) {
  if (chart.data.datasets.length !== 1) {
    stop('A fixture without exactly one dataset: extend observe.');
  }
  const area = chart.chartArea;
  const meta = chart.getDatasetMeta(0);
  return {
    chartArea: [area.left, area.top, area.right, area.bottom],
    width: chart.width,
    height: chart.height,
    nodes: [...meta.controller._nodes.values()].map((node) => [
      node.key,
      number(node.x),
      number(node.y),
      node.in,
      node.out,
      node.size,
    ]),
    flows: meta.data.map((flow) => [flow.x, flow.y, flow.x2, flow.y2, flow.height, flow.width]),
    draw: drawCalls(chart),
  };
}

// ---------------------------------------------------------------------------
// The fixtures.

/** The fixture files of [folder] (a URL), relative to test/fixtures/. */
function fixtureFiles(folder, prefix = '') {
  const files = [];
  for (const entry of readdirSync(folder, {withFileTypes: true})) {
    const path = `${prefix}${entry.name}`;
    if (entry.isDirectory()) {
      files.push(...fixtureFiles(new URL(`${entry.name}/`, folder), `${path}/`));
    } else if (path.endsWith('.js') || path.endsWith('.json')) {
      files.push(path);
    }
  }
  return files;
}

// Code unit order, as the manifest of tool 4.
const paths = fixtureFiles(FIXTURES).sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
if (paths.length !== FIXTURE_COUNT) {
  stop(`${fileURLToPath(FIXTURES)} has ${paths.length} fixtures, not ${FIXTURE_COUNT}.`);
}

const sha256 = (url) => createHash('sha256').update(readFileSync(url)).digest('hex');

const reference = {};
const items = [];
for (const path of paths) {
  if (!path.endsWith('.js')) stop(`${path}: a JSON config. Extend the script.`);
  const url = new URL(path, FIXTURES);
  const png = path.replace(/\.js$/, '.png');
  if (!existsSync(fileURLToPath(new URL(png, FIXTURES)))) stop(`${png} is missing.`);
  items.push({
    path,
    sha256: sha256(url),
    png,
    pngSha256: sha256(new URL(png, FIXTURES)),
    specs: ['fixtures.spec.js'],
    data: false,
  });

  // test/utils/fixtures.js:16 and :83-108.
  const {default: json} = await import(url.href);
  const name = path.replace(/\.js$/, '');
  const chart = buildChart(prepareConfig(name, json), json.options);
  const run = json.options?.run;
  if (typeof run === 'function') await run(chart);
  reference[path] = observe(chart);
  // test/utils/chart.js:62-68.
  chart.destroy();
}

// ---------------------------------------------------------------------------
// The output.

const manifest = {
  schema: 1,
  source: {
    project: 'chartjs-chart-sankey',
    version: SANKEY_VERSION,
    commit: COMMITS['chartjs-chart-sankey'],
  },
  fixtures: {items},
};
writeFileSync(MANIFEST, `${JSON.stringify(manifest, null, 2)}\n`);

/** The Dart literal of the observation [o]: one line for each list item. */
function observation(o) {
  const state = {undefined: false};
  const list = (items) => `<Object?>[\n${items.map((item) => `${dartLiteral(item, state)},\n`).join('')}]`;
  const text =
    '<String, Object?>{\n' +
    `'chartArea': ${dartLiteral(o.chartArea, state)},\n` +
    `'width': ${dartLiteral(o.width, state)},\n` +
    `'height': ${dartLiteral(o.height, state)},\n` +
    `'nodes': ${list(o.nodes)},\n` +
    `'flows': ${list(o.flows)},\n` +
    `'draw': ${list(o.draw)},\n` +
    '}';
  if (state.undefined) stop('An observation with the value undefined.');
  return text;
}

const body = paths.map((path) => `  ${dartLiteral(path)}: ${observation(reference[path])},\n`).join('');
const count = (key) => paths.reduce((n, path) => n + reference[path][key].length, 0);
const out = `// Original code, not ported from chartjs-chart-sankey: fixture reference data.

// Generated by tool/reference/fixtures_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}.
// Chart.js v${CHARTJS_VERSION} src at
// ${COMMITS['Chart.js']},
// chartjs-chart-sankey v${SANKEY_VERSION} src at
// ${COMMITS['chartjs-chart-sankey']},
// @kurkle/color src at
// ${COMMITS['kurkle-color']}, and
// the Liberation Sans context of scale_chart_common.mjs.
// ${paths.length} fixtures: ${count('nodes')} nodes, ${count('flows')} flows and ${count('draw')} draw calls.

/// The Node.js version that generated the data.
const String fixturesReferenceNode = '${process.version}';

/// The V8 version that generated the data.
const String fixturesReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated the data.
const String fixturesReferenceArch = '${process.arch}';

/// The chartjs-chart-sankey commit of the data.
const String fixturesReferenceSankeyCommit = '${COMMITS['chartjs-chart-sankey']}';

/// The Chart.js commit of the data.
const String fixturesReferenceChartJsCommit = '${COMMITS['Chart.js']}';

/// The observation of each fixture, by its path in \`test/fixtures/\`, after
/// the chart is made and its \`run\` hook ran. Each observation has these
/// keys:
///
/// - \`chartArea\`: \`[left, top, right, bottom]\`;
/// - \`width\` and \`height\`: the size of the chart;
/// - \`nodes\`: \`[key, x, y, in, out, size]\` for each node, in the order of
///   the node Map of the controller;
/// - \`flows\`: \`[x, y, x2, y2, height, width]\` for each flow element;
/// - \`draw\`: the rectangle, text and fill calls of one \`chart.draw()\`:
///   \`['fillRect', x, y, width, height, fill]\`,
///   \`['strokeRect', x, y, width, height, stroke]\`,
///   \`['fillText', text, x, y, textAlign, fill]\` and \`['fill', fill]\` (the
///   path of a flow). \`fill\` and \`stroke\` are the style in effect: a color
///   as \`#rrggbbaa\`, the gradient of a flow as
///   \`['linearGradient', x0, y0, x1, y1, [offset, color], ...]\`, or null
///   for another style.
const Map<String, Map<String, Object?>> fixturesReference = {
${body}};
`;
writeFileSync(OUT, out);
execFileSync('dart', ['format', OUT], {stdio: 'inherit'});
console.log(
  `Wrote ${paths.length} fixtures (${count('nodes')} nodes, ${count('flows')} flows, ` +
    `${count('draw')} draw calls) to ${OUT}, and ${MANIFEST}.`,
);
