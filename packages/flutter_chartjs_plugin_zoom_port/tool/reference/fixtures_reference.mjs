// Original code, not ported from chartjs-plugin-zoom: the fixture reference generator.
//
// It writes test/fixtures/fixtures_reference.dart, the expected
// observations of the 12 upstream fixtures of test/fixtures/{pan,zoom}/, and
// test/fixtures/manifest.json, the list of the fixture files with their
// SHA-256 for the fixture runner of package:chartjs_test_utils (seam H24,
// row harness-fixture-observations of doc/differences.md). Nothing in lib/
// or test/ runs this script.
//
// The method. Upstream compares each fixture with a PNG image. The port
// compares no image (Chart.js ADR 0034, section 4). Each fixture draws its
// chart into a sprite canvas after each step: `ctx.drawImage(chart.canvas,
// ...)` (update-reset.js calls it in `snapshot`). The script records an
// observation of the chart at each of these points, and once more after
// `run`. An observation has:
// - `chartArea`: `[left, top, right, bottom]`;
// - `scales`: for each id of `Object.keys(chart.scales)`, `[id, min, max,
//   options.min, options.max]`; a Date is `{date: <time value>}`;
// - `zoomLevel`, `zoomedOrPanned` and `zoomingOrPanning`: the results of
//   `chart.getZoomLevel()`, `chart.isZoomedOrPanned()` and
//   `chart.isZoomingOrPanning()`;
// - `dragRect`: `[left, top, width, height]` of `computeDragRect` of
//   src/handlers.ts for the drag of the state, as `draw` of src/plugin.ts
//   computes it, or null without a drag.
// test/fixtures/index.dart records the same observations in Dart and
// compares them.
//
// The script runs the pinned upstream sources with the type stripping of
// Node.js: src/index.ts of Chart.js (the module of `chart.js`, with
// src/helpers/index.ts as `chart.js/helpers`), src/index.umd.ts of
// chartjs-plugin-zoom (the file of karma.conf.cjs, which registers the
// plugin), and test/index.js of chartjs-plugin-zoom, which defines the event
// helpers of `jasmine`. Each fixture file runs as a function with the
// globals `module`, `document`, `jasmine`, `Chart` and `window` of the Karma
// page. Resolve hooks map the `.js` and extensionless imports to the `.ts`
// files, `@kurkle/color` to third_party/kurkle-color/src/index.esm.js, and
// `chartjs-test-utils` to a stub with the parts that test/index.js reads:
// `triggerMouseEvent` is src/utils.js:163-184 of the pinned
// chartjs-test-utils without the promise, as the zoom port has it
// (row harness-trigger-mouse-event-sync). A load hook gives each
// `package.json` import its version as a module.
//
// Node.js has no DOM. The chart gets BasicPlatform, as in the generators of
// packages/flutter_chartjs_port/tool/reference/: no global `document`, so
// `_isDomSupported()` is false. The chart canvas is a fake with the DOM parts
// that the plugin reads: `addEventListener`, `removeEventListener`,
// `dispatchEvent` (the canvas listeners, then the listeners of the document
// for a bubbling event), `getBoundingClientRect()` (the canvas at 0, 0),
// `ownerDocument`, `style` (`touchAction`, `userSelect`, `setProperty`,
// `removeProperty`) and the `getComputedStyle` of `ownerDocument.defaultView`
// with no padding and no border. The events are the DOM classes
// `MouseEvent`, `WheelEvent` and `PointerEvent` with the members of their
// init dictionaries, `offsetX` and `offsetY` from the client point and the
// canvas box, `preventDefault` and `stopPropagation`. The global `window`
// comes after Chart.js loads: `requestAnimFrame` of helpers.extras.ts reads
// it at load time, and the charts have no animation. The context of the
// chart is the LiberationContext of
// packages/flutter_chartjs_port/tool/reference/scale_chart_common.mjs (the
// widths of Liberation Sans 2.1.5, the test font of the harness), with a
// no-op `drawImage`. A chart is made as `_acquireChart` of chartjs-test-utils
// makes it: a 512 x 512 canvas, `animation: false`, `responsive: false` and
// `locale: 'en-US'`. The runner rules of src/fixture.js:43-50 apply.
//
// The time fixtures need a date adapter. The upstream tests load
// chartjs-adapter-date-fns 3.0.0 with date-fns 2.30.0 (the versions of the
// package-lock.json of the pin). Install them in a scratch folder outside
// the repository:
//
//   npm install --prefix <dir> --no-save --legacy-peer-deps \
//     --ignore-scripts chartjs-adapter-date-fns@3.0.0 date-fns@2.30.0
//
// The script maps `chart.js` in the adapter to the same src/index.ts, and
// `date-fns` to its `module` entry (esm/index.js), as the bundler of the
// adapter does. The zone is UTC (the script sets TZ), as the default date
// zone of the zoom tests (row harness-date-zone).
//
// Usage, from packages/flutter_chartjs_plugin_zoom_port, with the
// darwin-arm64 build of Node.js v24.22.1 (Chart.js ADR 0045) and the Dart
// SDK on the PATH (the script formats the output with `dart format`):
//
//   DATE_FNS_NODE_MODULES=<dir>/node_modules \
//     node tool/reference/fixtures_reference.mjs
//
// The first argument can also give the node_modules folder. The script
// stops unless each of third_party/Chart.js, third_party/kurkle-color,
// third_party/chartjs-test-utils and third_party/chartjs-plugin-zoom is at
// the `commit` of its entry in the tool/port_sources.yaml of its port, with
// no change in the folders that the script reads, and unless the
// node_modules folder has the two versions above. Check out the submodules
// with `dart run melos run upstream`.

import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {existsSync, readFileSync, readdirSync, writeFileSync} from 'node:fs';
import {registerHooks} from 'node:module';
import {fileURLToPath, pathToFileURL} from 'node:url';

process.env.TZ = 'UTC';

const THIRD_PARTY = new URL('../../../../third_party/', import.meta.url);
const CHARTJS = new URL('Chart.js/', THIRD_PARTY);
const ZOOM = new URL('chartjs-plugin-zoom/', THIRD_PARTY);
const KURKLE = new URL('kurkle-color/src/index.esm.js', THIRD_PARTY);
const FIXTURES = new URL('test/fixtures/', ZOOM);
const HOST_SOURCES = new URL('../../../flutter_chartjs_port/tool/port_sources.yaml', import.meta.url);
const ZOOM_SOURCES = new URL('../port_sources.yaml', import.meta.url);
const COMMON = new URL(
  '../../../flutter_chartjs_port/tool/reference/scale_chart_common.mjs',
  import.meta.url,
);
const OUT = fileURLToPath(new URL('../../test/fixtures/fixtures_reference.dart', import.meta.url));
const MANIFEST = fileURLToPath(new URL('../../test/fixtures/manifest.json', import.meta.url));
const STUB = 'file:///chartjs-test-utils-stub.mjs';

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
    sources: ZOOM_SOURCES,
    header: 'chartjs-plugin-zoom',
    folder: 'chartjs-plugin-zoom',
    paths: ['src', 'test', 'package.json', 'package-lock.json'],
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

/** The version of the zoom pin, `v2.2.0+fb81d331` without its "v". */
const ZOOM_VERSION = readFileSync(ZOOM_SOURCES, 'utf8').match(
  /^ {4}version: "?v([^"\s]+)"?\s*$/m,
)[1];
const CHARTJS_VERSION = JSON.parse(readFileSync(new URL('package.json', CHARTJS), 'utf8')).version;

// ---------------------------------------------------------------------------
// The date adapter.

const NODE_MODULES = process.argv[2] ?? process.env.DATE_FNS_NODE_MODULES;
if (!NODE_MODULES || !existsSync(NODE_MODULES)) {
  stop(
    'Give the node_modules folder of chartjs-adapter-date-fns 3.0.0 and date-fns 2.30.0 ' +
      'as the first argument, or set DATE_FNS_NODE_MODULES (see the header).',
  );
}
const MODULES = pathToFileURL(`${NODE_MODULES.replace(/\/$/, '')}/`);
const ADAPTER = new URL('chartjs-adapter-date-fns/dist/chartjs-adapter-date-fns.esm.js', MODULES);
const DATE_FNS = new URL('date-fns/esm/index.js', MODULES);

/** The versions of the upstream package-lock.json at the pin. */
const LOCK = JSON.parse(readFileSync(new URL('package-lock.json', ZOOM), 'utf8'));
for (const name of ['chartjs-adapter-date-fns', 'date-fns']) {
  const want = LOCK.packages[`node_modules/${name}`]?.version;
  const file = new URL(`${name}/package.json`, MODULES);
  const have = existsSync(fileURLToPath(file))
    ? JSON.parse(readFileSync(file, 'utf8')).version
    : 'missing';
  if (have !== want) {
    stop(`${fileURLToPath(file)}: ${name} ${have}; the upstream lock has ${want}.`);
  }
}
const ADAPTER_VERSION = LOCK.packages['node_modules/chartjs-adapter-date-fns'].version;
const DATE_FNS_VERSION = LOCK.packages['node_modules/date-fns'].version;

// ---------------------------------------------------------------------------
// The module hooks.

/** The source of the chartjs-test-utils stub that test/index.js imports. */
const STUB_SOURCE = `
// src/utils.js:142-161 of chartjs-test-utils v0.4.0.
function _resolveElementPoint(el) {
  let point = {x: 0, y: 0};
  if (el) {
    if (typeof el.getCenterPoint === 'function') {
      point = el.getCenterPoint();
    } else if (el.x !== undefined && el.y !== undefined) {
      point = el;
    }
  }
  return point;
}

// src/utils.js:163-184 without the promise: the zoom port dispatches the
// event and returns it (row harness-trigger-mouse-event-sync).
export function triggerMouseEvent(chart, type, el) {
  var node = chart.canvas;
  var rect = node.getBoundingClientRect();
  var point = _resolveElementPoint(el);
  var event = new MouseEvent(type, {
    clientX: rect.left + point.x,
    clientY: rect.top + point.y,
    cancelable: true,
    bubbles: true,
    view: window
  });
  node.dispatchEvent(event);
  return event;
}

export function acquireChart() {
  throw new Error('The fixture runner of the generator acquires the charts.');
}
export function releaseChart() {}
export function specsFromFixtures() {}
export function addMatchers() {}
export function releaseCharts() {}
`;

/** Whether [url] is a file of a folder in [folders] (URLs). */
const inside = (url, ...folders) => folders.some((f) => url?.startsWith(f.href));

registerHooks({
  resolve(specifier, context, nextResolve) {
    const parent = context.parentURL;
    if (specifier === 'chartjs-test-utils' && inside(parent, ZOOM)) {
      return {url: STUB, shortCircuit: true};
    }
    if (inside(parent, ZOOM, MODULES)) {
      if (specifier === 'chart.js') {
        return nextResolve(new URL('src/index.ts', CHARTJS).href, context);
      }
      if (specifier === 'chart.js/helpers') {
        return nextResolve(new URL('src/helpers/index.ts', CHARTJS).href, context);
      }
    }
    if (specifier === 'date-fns' && inside(parent, MODULES)) {
      return nextResolve(DATE_FNS.href, context);
    }
    if (specifier === '@kurkle/color' && inside(parent, CHARTJS)) {
      return nextResolve(KURKLE.href, context);
    }
    // The upstream sources import `./x.js` or `./x` where the file is `./x.ts`.
    if (specifier.startsWith('.') && inside(parent, CHARTJS, new URL('src/', ZOOM))) {
      const url = new URL(specifier, parent);
      if (!existsSync(fileURLToPath(url))) {
        const ts = new URL(`${url.href.replace(/\.js$/, '')}.ts`);
        if (existsSync(fileURLToPath(ts))) return nextResolve(ts.href, context);
      }
    }
    return nextResolve(specifier, context);
  },
  load(url, context, nextLoad) {
    if (url === STUB) {
      return {format: 'module', source: STUB_SOURCE, shortCircuit: true};
    }
    // core.controller.js:12 and src/plugin.ts:18 import `version` from
    // package.json without an import attribute.
    if (url.endsWith('/package.json') && inside(url, CHARTJS, ZOOM)) {
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

// The Liberation Sans context of the host generators. Its import checks the
// chartjs-test-utils pin again.
const {LiberationContext, dartLiteral} = await import(COMMON.href);

const chartjs = await import(new URL('src/index.ts', CHARTJS).href);
const helpers = await import(new URL('src/helpers/index.ts', CHARTJS).href);
const {Chart} = chartjs;

// src/index.umd.ts:28 of Chart.js registers the four namespaces. `each` does
// not walk a module namespace (helpers.core.ts:53-54), so the script
// registers their values, in the key order of the namespaces, as
// test/flutter_test_config.dart registers the namespaces of the port
// (Chart.js ADR 0041, section 1 item 3).
for (const name of ['controllers', 'scales', 'elements', 'plugins']) {
  Chart.register(...Object.values(await import(new URL(`src/${name}/index.js`, CHARTJS).href)));
}
{
  const ids = Object.keys(Chart.registry.plugins.items).join();
  if (ids !== 'colors,decimation,filler,legend,subtitle,title,tooltip') {
    stop(`The registry has the plugins ${ids}, not the seven of src/plugins/index.js.`);
  }
}
// src/index.umd.ts:30 of Chart.js: `Chart.helpers` of the fixtures.
Chart.helpers = {...helpers};

// The date adapter (karma.conf.cjs loads its bundle after Chart.js).
await import(ADAPTER.href);
if (chartjs._adapters._date.prototype._id !== 'date-fns') {
  stop('The date adapter did not override the adapter of src/index.ts.');
}

// ---------------------------------------------------------------------------
// The fake DOM.

/** The listeners of an event target, by type. */
function eventTarget() {
  const listeners = new Map();
  return {
    addEventListener(type, listener) {
      const list = listeners.get(type) ?? [];
      if (!list.includes(listener)) list.push(listener);
      listeners.set(type, list);
    },
    removeEventListener(type, listener) {
      const list = listeners.get(type) ?? [];
      const i = list.indexOf(listener);
      if (i >= 0) list.splice(i, 1);
    },
    _listeners: (type) => [...(listeners.get(type) ?? [])],
  };
}

/** The DOM `Event` with the members that the plugin reads. */
class FakeEvent {
  constructor(type, init = {}) {
    this.type = type;
    this.bubbles = init.bubbles ?? false;
    this.cancelable = init.cancelable ?? false;
    this.defaultPrevented = false;
    this.target = null;
    this._stopped = false;
  }
  preventDefault() {
    if (this.cancelable) this.defaultPrevented = true;
  }
  stopPropagation() {
    this._stopped = true;
  }
}

/** `MouseEvent`: the members of `MouseEventInit` and the offsets. */
class MouseEvent extends FakeEvent {
  constructor(type, init = {}) {
    super(type, init);
    this.clientX = init.clientX ?? 0;
    this.clientY = init.clientY ?? 0;
    this.button = init.button ?? 0;
    this.buttons = init.buttons ?? 0;
    this.ctrlKey = init.ctrlKey ?? false;
    this.altKey = init.altKey ?? false;
    this.shiftKey = init.shiftKey ?? false;
    this.metaKey = init.metaKey ?? false;
    this.view = init.view ?? null;
    this.offsetX = 0;
    this.offsetY = 0;
  }
}

/** `WheelEvent`. */
class WheelEvent extends MouseEvent {
  constructor(type, init = {}) {
    super(type, init);
    this.deltaX = init.deltaX ?? 0;
    this.deltaY = init.deltaY ?? 0;
    this.deltaZ = init.deltaZ ?? 0;
    this.deltaMode = init.deltaMode ?? 0;
  }
}

/** `PointerEvent`. */
class PointerEvent extends MouseEvent {
  constructor(type, init = {}) {
    super(type, init);
    this.pointerId = init.pointerId ?? 0;
    this.pointerType = init.pointerType ?? '';
    this.isPrimary = init.isPrimary ?? false;
  }
}

/** The document of the page: an event target that makes sprite canvases. */
const document = {
  ...eventTarget(),
  defaultView: {
    // No padding and no border: getRelativePosition of helpers.dom.ts.
    getComputedStyle: () => ({}),
  },
  documentElement: {},
  body: {},
  createElement(tag) {
    if (tag !== 'canvas') throw new Error(`createElement('${tag}')`);
    return spriteCanvas();
  },
};

/** The chart of the running fixture and its observations. */
let current = null;

/**
 * A canvas of a fixture (the sprite sheet). Its `drawImage` of the chart
 * canvas is an observation point; the rest of its context draws nothing.
 */
function spriteCanvas() {
  const ctx = {
    drawImage(source) {
      if (current && source === current.chart.canvas) {
        current.observations.push(observe(current.chart));
      }
    },
    fillText() {},
  };
  const canvas = {width: 300, height: 150, getContext: () => ctx};
  ctx.canvas = canvas;
  return canvas;
}

/** The canvas style with the members that src/gestures.ts writes. */
function canvasStyle() {
  const props = new Map();
  return {
    touchAction: '',
    userSelect: '',
    setProperty(name, value) {
      props.set(String(name), String(value));
    },
    removeProperty(name) {
      const value = props.get(String(name)) ?? '';
      props.delete(String(name));
      return value;
    },
    getPropertyValue: (name) => props.get(String(name)) ?? '',
  };
}

/** The 512 x 512 chart canvas of `_acquireChart`, at 0, 0 of the page. */
function chartCanvas() {
  const ctx = new LiberationContext();
  // The fixtures draw the sprite sheet into the chart (image only).
  ctx.drawImage = () => {};
  const target = eventTarget();
  let width = 512;
  let height = 512;
  const canvas = {
    id: '',
    get width() {
      return width;
    },
    set width(value) {
      width = value >>> 0;
      ctx.resetFontState();
    },
    get height() {
      return height;
    },
    set height(value) {
      height = value >>> 0;
      ctx.resetFontState();
    },
    style: canvasStyle(),
    ownerDocument: document,
    getContext: (id) => (id === '2d' ? ctx : null),
    getBoundingClientRect: () => ({
      x: 0,
      y: 0,
      left: 0,
      top: 0,
      right: width,
      bottom: height,
      width,
      height,
    }),
    addEventListener: target.addEventListener,
    removeEventListener: target.removeEventListener,
    // The DOM dispatch: the target and the offsets, the listeners of the
    // canvas, then those of the document for a bubbling event.
    dispatchEvent(event) {
      const rect = canvas.getBoundingClientRect();
      event.target = canvas;
      if (event instanceof MouseEvent) {
        event.offsetX = event.clientX - rect.left;
        event.offsetY = event.clientY - rect.top;
      }
      for (const listener of target._listeners(event.type)) listener(event);
      if (event.bubbles && !event._stopped) {
        for (const listener of document._listeners(event.type)) listener(event);
      }
      return !event.defaultPrevented;
    },
  };
  ctx.canvas = canvas;
  return canvas;
}

// The globals of the Karma page that test/index.js and the plugin read
// (src/handlers.ts:110 reads `window.document`).
const window = {document, devicePixelRatio: 1, Chart};
const jasmine = {};
Object.assign(globalThis, {
  window,
  jasmine,
  MouseEvent,
  WheelEvent,
  PointerEvent,
  beforeEach: () => {},
  afterEach: () => {},
  // test/index.js:140-143 runs before the first spec.
  beforeAll: (fn) => fn(),
});

// karma.conf.cjs: test/index.js, then src/index.umd.ts of the plugin.
await import(new URL('test/index.js', ZOOM).href);
const {default: zoomPlugin} = await import(new URL('src/index.umd.ts', ZOOM).href);
const {computeDragRect} = await import(new URL('src/handlers.ts', ZOOM).href);
const {getState} = await import(new URL('src/state.ts', ZOOM).href);
if (Chart.registry.plugins.get('zoom') !== zoomPlugin) {
  stop('src/index.umd.ts did not register the plugin.');
}
if (Chart.defaults.plugins.colors.enabled !== false) {
  stop('test/index.js did not turn off the colors plugin.');
}

// ---------------------------------------------------------------------------
// The observations.

/** A value of the options of a scale: a Date as `{date: <time value>}`. */
const value = (v) => (v instanceof Date ? {date: v.getTime()} : v);

/** The observation of [chart] (see the header). */
function observe(chart) {
  const area = chart.chartArea;
  const state = getState(chart);
  let dragRect = null;
  if (state.dragStart && state.dragEnd) {
    const options = state.options;
    const {left, top, width, height} = computeDragRect(
      chart,
      options.zoom?.mode,
      {dragStart: state.dragStart, dragEnd: state.dragEnd},
      options.zoom?.drag?.maintainAspectRatio,
    );
    dragRect = [left, top, width, height];
  }
  return {
    chartArea: [area.left, area.top, area.right, area.bottom],
    scales: Object.keys(chart.scales).map((id) => {
      const scale = chart.scales[id];
      return [id, scale.min, scale.max, value(scale.options.min), value(scale.options.max)];
    }),
    zoomLevel: chart.getZoomLevel(),
    zoomedOrPanned: chart.isZoomedOrPanned(),
    zoomingOrPanning: chart.isZoomingOrPanning(),
    dragRect,
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
    } else if (path.endsWith('.js')) {
      files.push(path);
    }
  }
  return files;
}

// Code unit order, as the manifest of tool 4.
const paths = fixtureFiles(FIXTURES).sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
if (paths.length !== 12) stop(`${fileURLToPath(FIXTURES)} has ${paths.length} fixtures, not 12.`);

const sha256 = (url) => createHash('sha256').update(readFileSync(url)).digest('hex');

/** `_acquireChart(config, options)` of src/utils.js:36-105 on a fake canvas. */
function acquireChart(config, options = {}) {
  if (options.canvas || options.wrapper || options.useOffscreenCanvas || options.useShadowDOM) {
    stop('A fixture with canvas or wrapper options: extend acquireChart.');
  }
  const canvas = chartCanvas();
  config = config || {};
  config.options = config.options || {};
  config.options.animation = config.options.animation === undefined ? false : config.options.animation;
  config.options.responsive = config.options.responsive === undefined ? false : config.options.responsive;
  config.options.locale = config.options.locale || 'en-US';
  return new Chart(canvas.getContext('2d'), config);
}

const reference = {};
const items = [];
for (const path of paths) {
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

  // The module body of the fixture, with the globals of the Karma page.
  const module = {exports: {}};
  new Function('module', 'exports', 'document', 'jasmine', 'Chart', 'window', readFileSync(url, 'utf8'))(
    module,
    module.exports,
    document,
    jasmine,
    Chart,
    window,
  );
  const json = module.exports;

  // src/fixture.js:41-50.
  const config = json.config;
  const options = config.options || (config.options = {});
  if (path.indexOf('plugin') === -1 && config.plugins === undefined) {
    options.plugins = options.plugins || false;
  }
  const chart = acquireChart(config, json.options);
  current = {chart, observations: []};
  const run = json.options && json.options.run;
  if (typeof run === 'function') await Promise.resolve(run(chart));
  current.observations.push(observe(chart));
  reference[path] = current.observations;
  current = null;
  // src/utils.js:108-111.
  chart.destroy();
}

// ---------------------------------------------------------------------------
// The output.

const manifest = {
  schema: 1,
  source: {project: 'chartjs-plugin-zoom', version: ZOOM_VERSION, commit: COMMITS['chartjs-plugin-zoom']},
  fixtures: {items},
};
writeFileSync(MANIFEST, `${JSON.stringify(manifest, null, 2)}\n`);

const state = {undefined: false};
const body = paths
  .map((path) => `  ${dartLiteral(path, state)}: ${dartLiteral(reference[path], state)},\n`)
  .join('');
const count = paths.reduce((n, path) => n + reference[path].length, 0);
const out = `// Original code, not ported from chartjs-plugin-zoom: fixture reference data.

// Generated by tool/reference/fixtures_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8},
// TZ=UTC. Chart.js v${CHARTJS_VERSION} src at
// ${COMMITS['Chart.js']},
// chartjs-plugin-zoom v${ZOOM_VERSION} src at
// ${COMMITS['chartjs-plugin-zoom']},
// chartjs-adapter-date-fns ${ADAPTER_VERSION}, date-fns ${DATE_FNS_VERSION}, and
// the Liberation Sans context of scale_chart_common.mjs.
// ${paths.length} fixtures, ${count} observations.
${state.undefined ? "\nimport 'package:flutter_chartjs_port/chartjs.dart' show undefined;\n" : ''}
/// The Node.js version that generated the data.
const String fixturesReferenceNode = '${process.version}';

/// The V8 version that generated the data.
const String fixturesReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated the data.
const String fixturesReferenceArch = '${process.arch}';

/// The chartjs-plugin-zoom commit of the data.
const String fixturesReferenceZoomCommit = '${COMMITS['chartjs-plugin-zoom']}';

/// The Chart.js commit of the data.
const String fixturesReferenceChartJsCommit = '${COMMITS['Chart.js']}';

/// The observations of each fixture, by its path in \`test/fixtures/\`: one
/// at each draw of the chart canvas into the sprite canvas of the fixture,
/// and one after \`run\`. Each observation has the keys \`chartArea\`,
/// \`scales\` (\`[id, min, max, options.min, options.max]\` for each scale in
/// the key order of \`chart.scales\`; a Date is \`{'date': <time value>}\`),
/// \`zoomLevel\`, \`zoomedOrPanned\`, \`zoomingOrPanning\` and \`dragRect\`
/// (\`[left, top, width, height]\`, or null).
const Map<String, List<Object?>> fixturesReference = {
${body}};
`;
writeFileSync(OUT, out);
execFileSync('dart', ['format', OUT], {stdio: 'inherit'});
console.log(`Wrote ${paths.length} fixtures and ${count} observations to ${OUT}, and ${MANIFEST}.`);
