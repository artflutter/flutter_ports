// Original code, not ported from Chart.js: core.controller reference generator.
//
// It writes test/port/core/controller_reference.dart, the data of
// test/port/core/core.controller_test.dart: the observations of fixed
// scenarios of the class Chart of core.controller.js, with the Node.js
// version, V8 version and architecture in the header. The scenarios are
// fixed, so a rerun on the same Node.js writes the same file. Nothing in
// lib/ or test/ runs this script (porting-flow.md section 4).
//
// The script runs the pinned upstream source
// third_party/Chart.js/src/core/core.controller.js and its imports with the
// type stripping of Node.js. A resolve hook maps the upstream `./x.js`
// imports to the `.ts` files, and `@kurkle/color` to
// third_party/kurkle-color/src/index.esm.js. A load hook gives the import of
// `package.json` (core.controller.js:12) the version of the pin.
//
// A chart draws on a fake canvas with the mock context of
// third_party/chartjs-test-utils/src/context.js. The mock measures a text as
// 10 px for each character. Node.js has no DOM, so `_detectPlatform` gives
// BasicPlatform, which disables the animations. The mock has no
// `resetTransform`: the fake context adds it, with a record. The scenarios
// register the four element classes, a dataset controller `test` and a
// scale `testlinear`. The Dart test builds the same classes.
//
// Each observation is one line `<label>: <value>`. A value is a text of the
// observation, or the JSON of JSON.stringify with a replacer: a labelled
// object is `"<label>"`, `undefined` is `"<undefined>"` and another function
// is `"<fn>"`. An error is `TypeError` for a TypeError and
// `Error: <message>` for an Error. `ok` is no error.
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js v24.12.0
// (on Apple silicon, the darwin-x64 build runs under Rosetta) and with the
// Dart SDK on the PATH (the script formats the output with `dart format`):
//
//   node tool/reference/controller_reference.mjs
//
// The reference is V8 13.6 on x64 (Chart.js ADR 0032), and the script stops
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

const THIRD_PARTY = new URL('../../../../third_party/', import.meta.url);
const SRC = new URL('Chart.js/src/', THIRD_PARTY);
const CONTROLLER = new URL('core/core.controller.js', SRC);
const DATASET_CONTROLLER = new URL('core/core.datasetController.js', SRC);
const SCALE = new URL('core/core.scale.js', SRC);
const INTERACTION = new URL('core/core.interaction.js', SRC);
const ELEMENTS = new URL('elements/index.js', SRC);
const PLATFORM = new URL('platform/index.js', SRC);
const PACKAGE = new URL('Chart.js/package.json', THIRD_PARTY);
const CONTEXT = new URL('chartjs-test-utils/src/context.js', THIRD_PARTY);
const KURKLE = new URL('kurkle-color/src/index.esm.js', THIRD_PARTY);
const OUT = fileURLToPath(
  new URL('../../test/port/core/controller_reference.dart', import.meta.url),
);

for (const url of [
  CONTROLLER,
  DATASET_CONTROLLER,
  SCALE,
  INTERACTION,
  ELEMENTS,
  PLATFORM,
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
    return nextLoad(url, context);
  },
});

const {default: Chart} = await import(CONTROLLER.href);
const {default: DatasetController} = await import(DATASET_CONTROLLER.href);
const {default: Scale} = await import(SCALE.href);
const {default: Interaction} = await import(INTERACTION.href);
const {ArcElement, BarElement, LineElement, PointElement} = await import(
  ELEMENTS.href
);
const {BasicPlatform} = await import(PLATFORM.href);
const {default: Context} = await import(CONTEXT.href);

// ---------------------------------------------------------------------------
// The observations.

/** The labels of the known objects of the current scenario. */
let labels = new Map();

/** Gives [value] the label [name] and returns [value]. */
function label(value, name) {
  labels.set(value, name);
  return value;
}

/** The JSON text of [value] with the replacer of the observations. */
function json(value) {
  return JSON.stringify(value, function (key, v) {
    if ((typeof v === 'object' && v !== null) || typeof v === 'function') {
      if (labels.has(v)) return `<${labels.get(v)}>`;
    }
    if (v === undefined) return '<undefined>';
    if (typeof v === 'function') return '<fn>';
    return v;
  });
}

/** The observation of the call [body]: `ok`, `TypeError` or `Error: ...`. */
function error(body) {
  try {
    body();
    return 'ok';
  } catch (e) {
    if (e instanceof TypeError) return 'TypeError';
    if (e.constructor === Error) return `Error: ${e.message}`;
    return `${e.constructor.name}: ${e.message}`;
  }
}

const scenarios = [];

/** Runs the scenario [name]. [body] gets the function `observe`. */
function scenario(name, body) {
  labels = new Map();
  const lines = [];
  const charts = [];
  body((what, value) => lines.push(`${what}: ${value}`), charts);
  for (const chart of charts) chart.destroy();
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

/**
 * A canvas of [width] x [height] with a mock context. As a DOM canvas, it
 * has the `id` `''`, and a write of `width` or `height` takes the
 * `ToUint32` of the value.
 */
function fakeCanvas(width = 300, height = 150) {
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

/** The dataset controller `test`: it places each point at its parsed x, y. */
class TestController extends DatasetController {
  static id = 'test';
  static defaults = {datasetElementType: false, dataElementType: 'point'};

  update(mode) {
    const meta = this._cachedMeta;
    this.updateElements(meta.data, 0, meta.data.length, mode);
  }

  updateElements(points, start, count, mode) {
    const {iScale, vScale} = this._cachedMeta;
    const {sharedOptions, includeOptions} = this._getSharedOptions(start, mode);
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
}

/** The scale `testlinear`: the range 0 to 10, with the ticks 0, 5 and 10. */
class TestScale extends Scale {
  static id = 'testlinear';
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

Chart.register(ArcElement, BarElement, LineElement, PointElement);
Chart.register(TestController, TestScale);

/** The hooks that the spy plugin logs. */
const HOOKS = [
  'install',
  'start',
  'stop',
  'uninstall',
  'beforeInit',
  'afterInit',
  'resize',
  'reset',
  'beforeUpdate',
  'beforeElementsUpdate',
  'beforeLayout',
  'beforeDataLimits',
  'afterDataLimits',
  'beforeBuildTicks',
  'afterBuildTicks',
  'afterLayout',
  'beforeDatasetsUpdate',
  'beforeDatasetUpdate',
  'afterDatasetUpdate',
  'afterDatasetsUpdate',
  'afterUpdate',
  'beforeRender',
  'beforeDraw',
  'beforeDatasetsDraw',
  'beforeDatasetDraw',
  'afterDatasetDraw',
  'afterDatasetsDraw',
  'afterDraw',
  'afterRender',
  'beforeEvent',
  'afterEvent',
  'beforeDestroy',
  'afterDestroy',
];

/** The text of a value of a hook argument. */
function argText(value) {
  if (value === null || value === undefined) return String(value);
  if (typeof value === 'function') return '<fn>';
  if (typeof value === 'object') {
    if (labels.has(value)) return `<${labels.get(value)}>`;
    return '<obj>';
  }
  return String(value);
}

/** The text `hook(key=value,...)` of one hook call. */
function hookText(hook, args) {
  const keys = Object.keys(args);
  return `${hook}(${keys.map((k) => `${k}=${argText(args[k])}`).join(',')})`;
}

/**
 * A plugin `{id}` that logs each hook of [HOOKS] into [log]. [results] gives
 * the result of a hook by name.
 */
function spy(id, log, results = {}) {
  const plugin = {id};
  for (const hook of HOOKS) {
    plugin[hook] = function (chart, args) {
      log.push(hookText(hook, args));
      return results[hook];
    };
  }
  return plugin;
}

/** The config of a `test` chart with [datasets] on two `testlinear` scales. */
function testConfig(datasets, extra = {}) {
  return {
    type: 'test',
    data: {datasets},
    ...extra,
    options: {
      scales: {x: {type: 'testlinear'}, y: {type: 'testlinear'}},
      ...extra.options,
    },
  };
}

/** The dataset `{label, data}` of three points. */
function points(name, order) {
  const dataset = {
    label: name,
    data: [
      {x: 1, y: 2},
      {x: 5, y: 8},
      {x: 9, y: 4},
    ],
  };
  if (order !== undefined) dataset.order = order;
  return dataset;
}

/** The text of a chart area or a box: `left,top,right,bottom`. */
function edges(area) {
  return area === undefined
    ? 'undefined'
    : `${area.left},${area.top},${area.right},${area.bottom}`;
}

/** The text of the metas of [list]: `index/order/label/type` for each. */
function metas(list) {
  return list
    .map((m) => (m === undefined ? 'hole' : `${m.index}/${m.order}/${m.label}`))
    .join(' ');
}

/** The text of the active elements of [chart]. */
function activeText(items) {
  return items
    .map((item) => `${item.datasetIndex}:${item.index}:${labels.get(item.element) ?? (item.element === undefined ? 'undefined' : '?')}`)
    .join(' ');
}

/** Labels the data elements of the metas of [chart] `d<i>p<j>`. */
function labelElements(chart) {
  chart._metasets.forEach((meta, i) => {
    if (meta) meta.data.forEach((el, j) => label(el, `d${i}p${j}`));
  });
}

/** A chart event of [type] at ([x], [y]). */
function event(type, x, y) {
  return {type, native: {type}, x, y};
}

// ---------------------------------------------------------------------------
// The scenarios.

scenario('construction', (observe, charts) => {
  const log = [];
  const canvas = fakeCanvas();
  const chart = new Chart(canvas, testConfig([points('a')], {plugins: [spy('spy', log)]}));
  charts.push(chart);
  label(chart, 'chart');
  observe('hooks', log.join(' '));
  observe('platform', chart.platform.constructor.name);
  observe('attached', chart.attached);
  observe('size', `${chart.width}x${chart.height}`);
  observe('canvas', `${canvas.width}x${canvas.height}`);
  observe('style', `${canvas.style.width} ${canvas.style.height}`);
  observe('currentDevicePixelRatio', chart.currentDevicePixelRatio);
  observe('aspectRatio', chart.aspectRatio);
  observe('chartArea', edges(chart.chartArea));
  observe('boxes', chart.boxes.map((b) => `${b.id}@${b.position}:${edges(b)}`).join(' '));
  observe('scales', Object.keys(chart.scales).join(','));
  const meta = chart.getDatasetMeta(0);
  labelElements(chart);
  observe('meta', `${meta.type} ${meta.index} ${meta.order} ${meta.label} ${meta.visible} ${meta.indexAxis} ${meta.xAxisID} ${meta.yAxisID}`);
  observe('elements', meta.data.map((el) => `${el.x},${el.y}`).join(' '));
  observe('dataset element', String(meta.dataset));
  observe('context', `${chart.getContext().type} ${chart.getContext().chart === chart}`);
  observe('same context', chart.getContext() === chart.getContext());
  observe('instances', Chart.instances[chart.id] === chart);
  observe('visible count', chart.getVisibleDatasetCount());
  observe('draw calls', canvas.getContext('2d').getCalls().map((c) => c.name).join(','));
});

scenario('update modes', (observe, charts) => {
  const log = [];
  const chart = new Chart(fakeCanvas(), testConfig([points('a'), points('b')], {plugins: [spy('spy', log)]}));
  charts.push(chart);
  log.length = 0;
  chart.update('none');
  observe('none', log.join(' '));
  log.length = 0;
  chart.update((ctx) => (ctx.datasetIndex === 0 ? 'resize' : 'active'));
  observe('function', log.filter((l) => l.startsWith('beforeDatasetUpdate') || l.startsWith('beforeUpdate') || l.startsWith('afterUpdate')).join(' '));
  log.length = 0;
  chart.reset();
  observe('reset', log.join(' '));
  log.length = 0;
  chart.render();
  observe('render', log.join(' '));
});

scenario('plugin cancel', (observe, charts) => {
  const log = [];
  const chart = new Chart(fakeCanvas(), testConfig([points('a')], {plugins: [spy('spy', log)]}));
  charts.push(chart);
  for (const hook of ['beforeUpdate', 'beforeLayout', 'beforeDatasetsUpdate', 'beforeDatasetUpdate', 'beforeRender', 'beforeDraw', 'beforeDatasetsDraw', 'beforeDatasetDraw']) {
    // The plugin cancels the hook from the second update on: a cancel of
    // beforeDatasetUpdate in the first update leaves no `_clip` for draw.
    const cancelLog = [];
    const results = {};
    const cancel = new Chart(fakeCanvas(), testConfig([points('a')], {plugins: [spy('spy', cancelLog, results)]}));
    charts.push(cancel);
    results[hook] = false;
    cancelLog.length = 0;
    cancel.update();
    observe(hook, cancelLog.join(' '));
  }
  observe('notify', String(chart.notifyPlugins('beforeUpdate', {cancelable: true})));
  const falseLog = [];
  const falsy = new Chart(fakeCanvas(), testConfig([], {plugins: [spy('spy', falseLog, {beforeUpdate: false})]}));
  charts.push(falsy);
  observe('notify false cancelable', String(falsy.notifyPlugins('beforeUpdate', {cancelable: true})));
  observe('notify false', String(falsy.notifyPlugins('beforeUpdate', {})));
  observe('notify no args', String(falsy.notifyPlugins('beforeUpdate')));
  observe('enabled spy', chart.isPluginEnabled('spy'));
  observe('enabled other', chart.isPluginEnabled('other'));
  const failed = new Chart({}, {});
  charts.push(failed);
  observe('failed notify', String(failed.notifyPlugins('beforeUpdate', {cancelable: true})));
  observe('failed isPluginEnabled', error(() => failed.isPluginEnabled('spy')));
});

scenario('metasets', (observe, charts) => {
  const chart = new Chart(
    fakeCanvas(),
    testConfig([points('1', 2), points('2', 1), points('3', 4), points('4', 3)]),
  );
  charts.push(chart);
  observe('metasets', metas(chart._metasets));
  observe('sorted', metas(chart._sortedMetasets));
  observe('visible', metas(chart.getSortedVisibleDatasetMetas()));
  const orig = chart.data.datasets.slice();
  chart.data.datasets.splice(0, 2);
  chart.update();
  observe('removed from beginning', metas(chart._metasets));
  chart.data.datasets = orig.slice();
  chart.update();
  observe('restored', metas(chart._metasets));
  chart.data.datasets.splice(1, 2);
  chart.update();
  observe('removed from middle', metas(chart._metasets));
  chart.data.datasets = orig.slice();
  chart.update();
  chart.data.datasets.splice(1, 0, points('1.5', 5));
  chart.update();
  observe('inserted', metas(chart._metasets));
  chart.data.datasets.splice(1, 1, points('r', 6));
  chart.update();
  observe('replaced', metas(chart._metasets));
  chart.data.datasets = [orig[3], orig[2], orig[1], points('new', 10)];
  chart.update();
  observe('swapped', metas(chart._metasets));
  observe('sorted swapped', metas(chart._sortedMetasets));
  chart.data.datasets[0].type = 'test';
  chart.data.datasets[1].hidden = true;
  chart.update();
  observe('hidden', metas(chart.getSortedVisibleDatasetMetas()));
  observe('meta 5', `${chart.getDatasetMeta(5).index} ${chart.getDatasetMeta(5) === chart.getDatasetMeta(5)} ${chart._metasets.length}`);
});

scenario('destroy', (observe) => {
  const log = [];
  const canvas = fakeCanvas();
  const chart = new Chart(canvas, testConfig([points('1'), points('2')], {plugins: [spy('spy', log)]}));
  const id = String(chart.id);
  log.length = 0;
  chart.destroy();
  observe('hooks', log.join(' '));
  observe('metasets', json(chart._metasets));
  observe('canvas', `${chart.canvas} ${chart.ctx}`);
  observe('instances', id in Chart.instances);
  observe('getChart', String(Chart.getChart(canvas)));
  observe('style', `${canvas.style.width} ${canvas.style.height}`);
  log.length = 0;
  observe('again', error(() => chart.destroy()));
  observe('hooks again', log.join(' '));
  const second = new Chart(canvas, testConfig([]));
  observe('reuse', second.canvas === canvas);
  second.destroy();
});

scenario('getChart', (observe, charts) => {
  const canvas = fakeCanvas();
  const chart = new Chart(canvas, testConfig([]));
  charts.push(chart);
  label(chart, 'chart');
  const ctx = canvas.getContext('2d');
  observe('canvas', json(Chart.getChart(canvas)));
  observe('context', json(Chart.getChart(ctx)));
  observe('chart', json(Chart.getChart(chart)));
  observe('array', json(Chart.getChart([canvas])));
  observe('object', json(Chart.getChart({canvas})));
  observe('number', json(Chart.getChart(1)));
  observe('string', json(Chart.getChart('abc')));
  observe('null', json(Chart.getChart(null)));
  observe('in use', error(() => new Chart(canvas, testConfig([]))).replace(`'${chart.id}'`, "'<id>'"));
  observe('in use by context', error(() => new Chart(ctx, testConfig([]))).replace(`'${chart.id}'`, "'<id>'"));
});

scenario('visibility', (observe, charts) => {
  const chart = new Chart(fakeCanvas(), testConfig([points('a'), {...points('b'), hidden: true}]));
  charts.push(chart);
  observe('visible', `${chart.isDatasetVisible(0)} ${chart.isDatasetVisible(1)} ${chart.isDatasetVisible(5)}`);
  chart.setDatasetVisibility(1, true);
  observe('set visible', `${chart.isDatasetVisible(1)} ${chart.getDatasetMeta(1).hidden}`);
  chart.hide(0);
  observe('hide', `${chart.isDatasetVisible(0)} ${chart.getDatasetMeta(0).visible} ${chart.getDatasetMeta(0).hidden}`);
  chart.show(0);
  observe('show', `${chart.isDatasetVisible(0)} ${chart.getDatasetMeta(0).visible} ${chart.getDatasetMeta(0).hidden}`);
  chart.hide(0, 1);
  observe('hide element', `${chart.getDatasetMeta(0).data[1].hidden} ${chart.getDatasetMeta(0).data[0].hidden}`);
  chart.show(0, 1);
  observe('show element', `${chart.getDatasetMeta(0).data[1].hidden}`);
  observe('hide missing element', error(() => chart.hide(0, 7)));
  chart.toggleDataVisibility(1);
  chart.toggleDataVisibility(2);
  chart.toggleDataVisibility(2);
  observe('data visibility', [0, 1, 2, 3].map((i) => chart.getDataVisibility(i)).join(' '));
  chart.toggleDataVisibility(3);
  chart._dataChanges.push([0, '_insertElements', 0, 1], [1, '_insertElements', 0, 1]);
  chart.update();
  observe('after insert', [0, 1, 2, 3, 4].map((i) => chart.getDataVisibility(i)).join(' '));
  chart._dataChanges.push([0, '_removeElements', 1, 1], [1, '_removeElements', 1, 1]);
  chart.update();
  observe('after remove', [0, 1, 2, 3, 4].map((i) => chart.getDataVisibility(i)).join(' '));
  chart._dataChanges.push([0, '_insertElements', 0, 1], [1, '_removeElements', 0, 1]);
  chart.update();
  observe('not uniform', [0, 1, 2, 3, 4].map((i) => chart.getDataVisibility(i)).join(' '));
  observe('changes cleared', chart._dataChanges.length);
});

scenario('events', (observe, charts) => {
  const log = [];
  const hover = [];
  const options = {
    onHover(e, active, chart) {
      hover.push(`hover ${e.type} ${activeText(active)} ${this === chart}`);
    },
    onClick(e, active) {
      hover.push(`click ${e.type} ${activeText(active)}`);
    },
    // The plugin `clicks` gets the click events only (the event filter of
    // core.controller.js:1170).
    plugins: {clicks: {events: ['click']}},
  };
  const chart = new Chart(
    fakeCanvas(),
    testConfig([points('a'), points('b')], {plugins: [spy('spy', log), {id: 'clicks', beforeEvent(c, args) { log.push(`clicks ${args.event.type}`); }}], options}),
  );
  charts.push(chart);
  labelElements(chart);
  const meta = chart.getDatasetMeta(0);
  const p1 = meta.data[1];
  const run = (name, e) => {
    log.length = 0;
    hover.length = 0;
    chart._eventHandler(e);
    observe(name, `${log.join(' ')} | ${hover.join(' ')} | ${activeText(chart.getActiveElements())} | ${[0, 1].map((d) => chart.getDatasetMeta(d).data.map((el) => el.active).join(',')).join(' ')}`);
  };
  run('move on point', event('mousemove', p1.x, p1.y));
  run('move same', event('mousemove', p1.x, p1.y));
  run('move outside area', event('mousemove', -50, -50));
  run('move away', event('mousemove', chart.chartArea.left + 1, chart.chartArea.top + 1));
  run('click on point', event('click', p1.x, p1.y));
  run('move back', event('mousemove', p1.x, p1.y));
  log.length = 0;
  chart.update();
  observe('replay', log.filter((l) => l.includes('Event')).join(' '));
  run('mouseout', event('mouseout', p1.x, p1.y));
  log.length = 0;
  chart.setActiveElements([{datasetIndex: 1, index: 2}]);
  observe('set active', `${activeText(chart.getActiveElements())} | ${[0, 1].map((d) => chart.getDatasetMeta(d).data.map((el) => el.active).join(',')).join(' ')}`);
  chart.update();
  observe('update keeps active', `${activeText(chart.getActiveElements())} | ${log.filter((l) => l.includes('Event')).join(' ')}`);
  // An index without an element: setActiveElements keeps the item, and the
  // hover style of `undefined` throws.
  observe('set missing', error(() => chart.setActiveElements([{datasetIndex: 0, index: 7}])));
  observe('missing active', activeText(chart.getActiveElements()));
  observe('set missing update', error(() => chart.update()));
  chart._active = [];
  chart.setActiveElements([]);
  observe('cleared', `${activeText(chart.getActiveElements())}`);
  chart.options.hover.mode = 'dataset';
  run('dataset mode', event('mousemove', p1.x, p1.y));
});

scenario('interaction modes', (observe, charts) => {
  const chart = new Chart(fakeCanvas(), testConfig([points('a'), points('b')]));
  charts.push(chart);
  labelElements(chart);
  const p1 = chart.getDatasetMeta(0).data[1];
  const items = (list) => list.map((i) => `${i.datasetIndex}:${i.index}:${labels.get(i.element)}`).join(' ');
  for (const mode of ['point', 'nearest', 'index', 'dataset', 'x', 'y', 'nope']) {
    for (const intersect of [true, false]) {
      const e = event('mousemove', p1.x + 2, p1.y + 2);
      observe(`${mode} ${intersect}`, items(chart.getElementsAtEventForMode(e, mode, {intersect}, false)));
    }
  }
  observe('axis xy', items(chart.getElementsAtEventForMode(event('mousemove', p1.x + 30, p1.y), 'nearest', {intersect: false, axis: 'xy'}, false)));
  observe('axis y', items(chart.getElementsAtEventForMode(event('mousemove', p1.x + 30, p1.y), 'nearest', {intersect: false, axis: 'y'}, false)));
  observe('in area', `${chart.isPointInArea({x: p1.x, y: p1.y})} ${chart.isPointInArea({x: -1, y: -1})}`);
});

scenario('resize', (observe, charts) => {
  const log = [];
  const sizes = [];
  const canvas = fakeCanvas(400, 200);
  const chart = new Chart(
    canvas,
    testConfig([points('a')], {
      plugins: [spy('spy', log)],
      options: {
        onResize(c, size) {
          sizes.push(`${size.width}x${size.height} ${this === c}`);
        },
      },
    }),
  );
  charts.push(chart);
  observe('initial', `${chart.width}x${chart.height} ${canvas.width}x${canvas.height} ${sizes.join(' ')}`);
  log.length = 0;
  sizes.length = 0;
  chart.resize(200, 100);
  observe('resize 200x100', `${chart.width}x${chart.height} ${canvas.width}x${canvas.height} ${canvas.style.width} ${canvas.style.height} ${sizes.join(' ')} | ${log.join(' ')}`);
  log.length = 0;
  sizes.length = 0;
  chart.resize(200, 100);
  observe('same size', `${sizes.join(' ')} | ${log.join(' ')}`);
  chart.options.maintainAspectRatio = false;
  chart.resize(250.4, 125.6);
  observe('fraction', `${chart.width}x${chart.height} ${canvas.width}x${canvas.height} ${canvas.style.width} ${canvas.style.height}`);
  chart.options.devicePixelRatio = 2;
  chart.resize(100, 50);
  observe('ratio 2', `${chart.width}x${chart.height} ${canvas.width}x${canvas.height} ${chart.currentDevicePixelRatio}`);
  chart.options.aspectRatio = 4;
  chart.options.maintainAspectRatio = true;
  chart.resize(200);
  observe('aspect ratio', `${chart.width}x${chart.height} ${chart.aspectRatio}`);
});

scenario('options and data', (observe, charts) => {
  const config = testConfig([points('a')]);
  const chart = new Chart(fakeCanvas(), config);
  charts.push(chart);
  observe('data alias', chart.data === config.data);
  const data = {datasets: [points('b')]};
  chart.data = data;
  observe('set data', `${chart.data === data} ${config.data === data} ${json(Object.keys(chart.data))}`);
  chart.data = null;
  observe('set null', json(chart.data));
  chart.data = {datasets: [points('c')]};
  const before = chart.options;
  // A new options object has the animations of the defaults: BasicPlatform
  // disabled them in the options of the constructor only.
  chart.options = {animation: false, scales: {y: {type: 'testlinear', position: 'bottom'}, x2: {type: 'testlinear', axis: 'x'}}, layout: {padding: 10}};
  observe('options before update', `${chart.options === before} ${json(chart.options.layout.padding)}`);
  chart.update();
  observe('options after update', `${chart.options === before} ${json(chart.options.layout.padding)}`);
  observe('scale ids', Object.keys(chart.scales).map((id) => `${id}:${chart.scales[id].options.id}:${chart.scales[id].position}`).join(' '));
  observe('boxes', chart.boxes.map((b) => b.id).join(','));
  observe('chartArea', edges(chart.chartArea));
  observe('scale type error', error(() => {
    chart.options = {animation: false, scales: {x: {type: 'nope'}}};
    chart.update();
  }));
  observe('controller type error', error(() => new Chart(fakeCanvas(), {type: 'nope', data: {datasets: [{}]}})));
});

scenario('statics', (observe, charts) => {
  observe('version', Chart.version);
  observe('register forms', error(() => Chart.register([[{id: 'x'}]])));
  const log = [];
  const chart = new Chart(fakeCanvas(), testConfig([]));
  charts.push(chart);
  chart.notifyPlugins('afterRender');
  const plugin = spy('late', log);
  Chart.register(plugin);
  observe('cache after register', String(chart._plugins._cache));
  chart.notifyPlugins('afterDraw');
  observe('late plugin', log.join(' '));
  Chart.unregister(plugin);
  log.length = 0;
  chart.notifyPlugins('afterDraw');
  observe('after unregister', log.join(' '));
  observe('getElementsAtEventForMode modes', Object.keys(Interaction.modes).join(','));
  observe('BasicPlatform', chart.platform instanceof BasicPlatform);
  const own = new Chart(fakeCanvas(), {platform: BasicPlatform, type: 'test'});
  charts.push(own);
  observe('config platform', own.platform.constructor.name);
});

// ---------------------------------------------------------------------------
// The output.

/**
 * The observations as one multi-line Dart string, one observation on each
 * line. A long line in a multi-line string passes lines_longer_than_80_chars.
 */
function dartLines(lines) {
  const text = lines.join('\n');
  if (text.includes("'''")) throw new Error('An observation with three quotes');
  const raw = /[\\$]/.test(text) ? 'r' : '';
  return `${raw}'''\n${text}'''`;
}

const body = scenarios
  .map(({name, lines}) => `  '${name}': ${dartLines(lines)},\n`)
  .join('');

const out = `// Original code, not ported from Chart.js: core.controller reference data.

// Generated by tool/reference/controller_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// src/core/core.controller.js at the pinned Chart.js. ${scenarios.length} scenarios.

/// The Node.js version that generated the data.
const String controllerReferenceNode = '${process.version}';

/// The V8 version that generated the data.
const String controllerReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated the data.
const String controllerReferenceArch = '${process.arch}';

/// The observations of each scenario, by name, one on each line:
/// \`<label>: <value>\`.
const Map<String, String> controllerReference = {
${body}};
`;

writeFileSync(OUT, out);
execFileSync('dart', ['format', OUT], {stdio: 'inherit'});
console.log(`Wrote ${OUT}: ${scenarios.length} scenarios.`);
