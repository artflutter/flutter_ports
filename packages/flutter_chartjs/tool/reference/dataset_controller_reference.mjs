// Original code, not ported from Chart.js: core.datasetController reference generator.
//
// It writes test/port/core/dataset_controller_reference.dart, the data of
// test/port/core/core.datasetController_test.dart: scenarios of a test
// controller on a fake chart with fake scales, the steps of each scenario,
// the observations after the steps, and the Node.js version, V8 version and
// architecture in the header. The scenarios are fixed, so a rerun on the
// same Node.js writes the same file. Nothing in lib/ or test/ runs this
// script (porting-flow.md section 4).
//
// The script runs the pinned upstream sources
// third_party/Chart.js/src/core/core.datasetController.js, core.config.js,
// core.registry.js and the element classes of src/elements/ with the type
// stripping of Node.js. A resolve hook maps the upstream `./x.js` imports to
// the `.ts` files, and `@kurkle/color` to
// third_party/kurkle-color/src/index.esm.js. The registry registers the
// element classes and a custom element class. The fake chart, metas and
// scales have only the members that core.datasetController.js reads. The
// test controller follows the option calls of controller.line.js:41-120.
// The Dart test runs the same scenarios with the same fakes. Check out the
// submodules first (`dart run melos run upstream`).
//
// Usage, from packages/flutter_chartjs, with an x64 build of Node.js v24.12.0
// (on Apple silicon, the darwin-x64 build runs under Rosetta) and with the
// Dart SDK on the PATH (the script formats the output with `dart format`):
//
//   node tool/reference/dataset_controller_reference.mjs
//
// The reference is V8 13.6 on x64 (Chart.js ADR 0010), and the script stops
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
const SRC = new URL('Chart.js/src/', THIRD_PARTY);
const SOURCE = new URL('core/core.datasetController.js', SRC);
const CONFIG = new URL('core/core.config.js', SRC);
const REGISTRY = new URL('core/core.registry.js', SRC);
const ANIMATION = new URL('core/core.animation.js', SRC);
const ANIMATIONS = new URL('core/core.animations.js', SRC);
const ANIMATOR = new URL('core/core.animator.js', SRC);
const ELEMENT = new URL('core/core.element.ts', SRC);
const POINT = new URL('elements/element.point.ts', SRC);
const LINE = new URL('elements/element.line.js', SRC);
const BAR = new URL('elements/element.bar.js', SRC);
const ARC = new URL('elements/element.arc.ts', SRC);
const OPTIONS = new URL('helpers/helpers.options.ts', SRC);
const KURKLE = new URL('kurkle-color/src/index.esm.js', THIRD_PARTY);
const OUT = fileURLToPath(
  new URL(
    '../../test/port/core/dataset_controller_reference.dart',
    import.meta.url,
  ),
);

for (const url of [
  SOURCE,
  CONFIG,
  REGISTRY,
  ANIMATION,
  ANIMATIONS,
  ANIMATOR,
  ELEMENT,
  POINT,
  LINE,
  BAR,
  ARC,
  OPTIONS,
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
});

const {default: DatasetController} = await import(SOURCE.href);
const {default: Config, getIndexAxis} = await import(CONFIG.href);
const {default: registry} = await import(REGISTRY.href);
const {default: Animation} = await import(ANIMATION.href);
const {default: Animations} = await import(ANIMATIONS.href);
const {default: animator} = await import(ANIMATOR.href);
const {default: Element} = await import(ELEMENT.href);
const {default: PointElement} = await import(POINT.href);
const {default: LineElement} = await import(LINE.href);
const {default: BarElement} = await import(BAR.href);
const {default: ArcElement} = await import(ARC.href);
const {createContext} = await import(OPTIONS.href);

// The promises of the animations have no listener.
process.on('unhandledRejection', () => {});

// --- The fakes ----------------------------------------------------------

/** The element counter of the current scenario. */
let counter = 0;

/** The draw calls of the current scenario. */
let trace = [];

/** The ids of the objects that the observations name, by object. */
let ids = new Map();

/** The id of [object]: `<prefix>#<k>` in the order of the first sight. */
function idOf(prefix, object) {
  if (!ids.has(object)) ids.set(object, `${prefix}#${ids.size}`);
  return ids.get(object);
}

/** A custom element class with its own id and defaults. */
class CustomElement extends Element {
  static id = 'custom';

  static defaults = {size: 3, label: 'c'};
}

/** The tag of a new element of [kind]: `<kind>#<n>`. */
function tag(element, kind) {
  Object.defineProperty(element, '$tag', {value: `${kind}#${counter++}`});
}

class SpyPoint extends PointElement {
  constructor(cfg) {
    super(cfg);
    tag(this, 'point');
  }

  draw() {
    trace.push(`${this.$tag}.draw`);
  }
}

class SpyLine extends LineElement {
  constructor(cfg) {
    super(cfg);
    tag(this, 'line');
  }

  draw(ctx, area, start, count) {
    trace.push(`${this.$tag}.draw(${String(start)},${String(count)})`);
  }
}

class SpyBar extends BarElement {
  constructor(cfg) {
    super(cfg);
    tag(this, 'bar');
  }

  draw() {
    trace.push(`${this.$tag}.draw`);
  }
}

class SpyArc extends ArcElement {
  constructor(cfg) {
    super(cfg);
    tag(this, 'arc');
  }

  draw() {
    trace.push(`${this.$tag}.draw`);
  }
}

class SpyCustom extends CustomElement {
  constructor(cfg) {
    super(cfg);
    tag(this, 'custom');
  }

  draw() {
    trace.push(`${this.$tag}.draw`);
  }
}

const ELEMENT_TYPES = {
  point: SpyPoint,
  line: SpyLine,
  bar: SpyBar,
  arc: SpyArc,
  custom: SpyCustom,
};

registry.addElements(
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  CustomElement,
);

/** The `enableOptionSharing` of the test controller in this scenario. */
let sharing = true;

/** The `getMaxOverflow` result of the test controller, or undefined. */
let maxOverflow;

/**
 * The test controller: the option calls of controller.line.js:41-120. The
 * pixels are 10 times the parsed values.
 */
class TestController extends DatasetController {
  initialize() {
    this.enableOptionSharing = sharing;
    super.initialize();
  }

  getMaxOverflow() {
    return maxOverflow === undefined ? super.getMaxOverflow() : maxOverflow;
  }

  update(mode) {
    const meta = this._cachedMeta;
    const line = meta.dataset;
    const points = meta.data || [];
    if (line) {
      const options = this.resolveDatasetElementOptions(mode);
      this.updateElement(line, undefined, {options}, mode);
    }
    this.updateElements(points, 0, points.length, mode);
  }

  updateElements(points, start, count, mode) {
    const {iScale, vScale, _stacked} = this._cachedMeta;
    const {sharedOptions, includeOptions} = this._getSharedOptions(
      start,
      mode,
    );
    const iAxis = iScale.axis;
    const vAxis = vScale.axis;
    for (let i = start; i < start + count; ++i) {
      const point = points[i];
      const parsed = this.getParsed(i);
      const properties = {};
      properties[iAxis] = iScale.getPixelForValue(parsed[iAxis], i);
      properties[vAxis] = vScale.getPixelForValue(
        _stacked ? this.applyStack(vScale, parsed, _stacked) : parsed[vAxis],
        i,
      );
      if (includeOptions) {
        properties.options =
          sharedOptions ||
          this.resolveDataElementOptions(i, point.active ? 'active' : mode);
      }
      this.updateElement(point, i, properties, mode);
    }
  }
}

/**
 * A fake scale: a linear, category or raw parse, labels and user bounds. The
 * raw parse returns the value as it is, for the `<` of the sorted test.
 */
class FakeScale {
  constructor(chart, spec) {
    this.chart = chart;
    this.id = spec.id;
    this.axis = spec.axis;
    this.kind = spec.kind;
    this.options = materialize(spec.options || {});
    this.labels = spec.labels === undefined ? undefined : materialize(spec.labels);
    this.bounds = spec.bounds || {
      min: 0,
      max: 0,
      minDefined: false,
      maxDefined: false,
    };
  }

  parse(raw, index) {
    if (this.kind === 'raw') {
      return raw;
    }
    if (raw === null || raw === undefined) {
      return null;
    }
    if (this.kind === 'category') {
      if (typeof raw === 'string') {
        const i = this.getLabels().indexOf(raw);
        return i === -1 ? index : i;
      }
      return typeof raw === 'number' ? raw : null;
    }
    if (typeof raw === 'number' && !isFinite(raw)) {
      return null;
    }
    return +raw;
  }

  getLabels() {
    return this.labels || this.chart.data.labels;
  }

  getLabelForValue(value) {
    if (this.kind === 'category') {
      const labels = this.getLabels();
      if (Number.isInteger(value) && value >= 0 && value < labels.length) {
        return labels[value];
      }
    }
    return value;
  }

  getUserBounds() {
    return {...this.bounds};
  }

  getMatchingVisibleMetas(type) {
    const metas = this.chart.getSortedVisibleDatasetMetas();
    const result = [];
    for (const meta of metas) {
      if (meta[this.axis + 'AxisID'] === this.id && (!type || meta.type === type)) {
        result.push(meta);
      }
    }
    return result;
  }

  getPixelForValue(value) {
    return +value * 10;
  }
}

/** A fake chart: the members that core.datasetController.js reads. */
class FakeChart {
  constructor(config, spec) {
    this.config = config;
    this.ctx = {};
    this.data = config.data;
    this.scales = {};
    for (const scale of spec.scales) {
      this.scales[scale.id] = new FakeScale(this, scale);
    }
    this.chartArea = {left: 0, top: 0, right: 100, bottom: 100, width: 100, height: 100};
    this._stacks = undefined;
    this._dataChanges = [];
    this._animationsDisabled = spec.animationsDisabled;
    this._metasets = [];
    this._plugins = spec.plugins || [];
    this.options = config.createResolver(config.chartOptionScopes(), this.getContext());
  }

  getContext() {
    return this.$context || (this.$context = createContext(null, {chart: this, type: 'chart'}));
  }

  // core.controller.js:829-853.
  getDatasetMeta(datasetIndex) {
    const dataset = this.data.datasets[datasetIndex];
    const metasets = this._metasets;
    let meta = metasets.filter((x) => x && x._dataset === dataset).pop();
    if (!meta) {
      meta = {
        type: null,
        data: [],
        dataset: null,
        controller: null,
        hidden: null,
        xAxisID: null,
        yAxisID: null,
        order: (dataset && dataset.order) || 0,
        index: datasetIndex,
        _dataset: dataset,
        _parsed: [],
        _sorted: false,
      };
      metasets.push(meta);
    }
    return meta;
  }

  // core.controller.js:737-750, with the sort of :397.
  _getSortedDatasetMetas(filterVisible) {
    const metasets = this._metasets
      .slice(0)
      .sort((a, b) => (a.order === b.order ? a.index - b.index : a.order - b.order));
    return metasets.filter((meta) => !filterVisible || meta.visible);
  }

  getSortedVisibleDatasetMetas() {
    return this._getSortedDatasetMetas(true);
  }

  // core.controller.js:866-875.
  isDatasetVisible(datasetIndex) {
    const dataset = this.data.datasets[datasetIndex];
    if (!dataset) {
      return false;
    }
    const meta = this.getDatasetMeta(datasetIndex);
    return typeof meta.hidden === 'boolean' ? !meta.hidden : !dataset.hidden;
  }

  isPluginEnabled(pluginId) {
    return this._plugins.includes(pluginId);
  }
}

/** The functions of the `{$fn: name}` markers. */
const FUNCTIONS = {
  colorByIndex: (ctx) => (ctx.dataIndex === 1 ? 'red' : 'blue'),
  typeIsDataset: (ctx) => (ctx.type === 'dataset' ? 75 : 0),
};

/**
 * A new JS value from a spec value: `{$fn: name}` gives a function,
 * `{$undefined: true}` gives undefined, and the arrays and objects are new.
 */
function materialize(value) {
  if (Array.isArray(value)) return value.map(materialize);
  if (value !== null && typeof value === 'object') {
    if ('$fn' in value) return FUNCTIONS[value.$fn];
    if ('$undefined' in value) return undefined;
    const out = {};
    for (const key of Object.keys(value)) out[key] = materialize(value[key]);
    return out;
  }
  return value;
}

/** The text of a JS value in the observations. */
function enc(v) {
  if (v === undefined) return 'undefined';
  if (v === null) return 'null';
  if (typeof v === 'boolean') return String(v);
  if (typeof v === 'number') return Number.isNaN(v) ? 'NaN' : String(v);
  if (typeof v === 'string') return JSON.stringify(v);
  if (typeof v === 'function') {
    return /^class\b/.test(Function.prototype.toString.call(v)) ? `class:${v.name}` : 'fn';
  }
  if (v instanceof Element) return v.$tag || 'element';
  if (v instanceof Animation) return 'animation';
  if (v instanceof Animations) return idOf('anims', v);
  if (Array.isArray(v)) return `[${v.map(enc).join(',')}]`;
  return `{${Object.keys(v)
    .map((k) => `${JSON.stringify(k)}:${enc(v[k])}`)
    .join(',')}}`;
}

/** The text of a resolved options object: its id, frozen state and value. */
function encOptions(options) {
  if (options === undefined) return 'undefined';
  return `${idOf('opt', options)} frozen=${Object.isFrozen(options)} ${enc(options)}`;
}

/** An id or scale of a meta: `'none'` for JS `null` and `undefined`. */
function none(value) {
  return value === null || value === undefined ? 'none' : value;
}

// --- The interpreter --------------------------------------------------------

/** Runs [spec] and returns the observations. */
function run(spec) {
  counter = 0;
  trace = [];
  ids = new Map();
  sharing = spec.sharing !== false;
  maxOverflow = spec.maxOverflow;
  const elements = spec.elements || {dataset: 'line', data: 'point'};
  const config = new Config({
    type: spec.chartType || 'test',
    data: {
      labels: materialize(spec.labels || []),
      datasets: materialize(spec.datasets),
    },
    options: materialize(spec.options || {}),
  });
  const chart = new FakeChart(config, spec);
  const out = [];
  const controller = (i) => chart.getDatasetMeta(i).controller;
  const dataOf = (i) => chart.data.datasets[i].data;

  const step = (s) => {
    const [op, ...args] = s;
    switch (op) {
      case 'build': {
        // core.controller.js:415-451, without the registry.
        const datasets = chart.data.datasets;
        for (let i = 0; i < datasets.length; i++) {
          const dataset = datasets[i];
          const meta = chart.getDatasetMeta(i);
          const type = dataset.type || config.type;
          meta.type = type;
          meta.indexAxis = dataset.indexAxis || getIndexAxis(type, chart.options);
          meta.order = dataset.order || 0;
          meta.index = i;
          meta.label = '' + dataset.label;
          meta.visible = chart.isDatasetVisible(i);
          if (meta.controller) {
            meta.controller.updateIndex(i);
            meta.controller.linkScales();
          } else {
            Object.assign(TestController, {
              dataElementType: ELEMENT_TYPES[elements.data],
              datasetElementType:
                elements.dataset === false
                  ? false
                  : elements.dataset === null
                    ? null
                    : ELEMENT_TYPES[elements.dataset],
            });
            meta.controller = new TestController(chart, i);
          }
        }
        return;
      }
      case 'elements':
        for (let i = 0; i < chart.data.datasets.length; i++) {
          controller(i).buildOrUpdateElements(args[0]);
        }
        return;
      case 'update':
        for (let i = 0; i < chart.data.datasets.length; i++) {
          controller(i)._update(args[0]);
        }
        return;
      case 'updateIndex':
        controller(args[0]).updateIndex(args[1]);
        return;
      case 'linkScales':
        controller(args[0]).linkScales();
        return;
      case 'configure':
        controller(args[0]).configure();
        return;
      case 'destroy':
        controller(args[0])._destroy();
        return;
      case 'draw':
        controller(args[0]).draw();
        return;
      case 'drawRange':
        controller(args[0])._drawStart = args[1] === null ? undefined : args[1];
        controller(args[0])._drawCount = args[2] === null ? undefined : args[2];
        return;
      case 'push':
        dataOf(args[0]).push(...materialize(args.slice(1)));
        return;
      case 'pop':
        dataOf(args[0]).pop();
        return;
      case 'shift':
        dataOf(args[0]).shift();
        return;
      case 'splice':
        dataOf(args[0]).splice(args[1], args[2], ...materialize(args.slice(3)));
        return;
      case 'unshift':
        dataOf(args[0]).unshift(...materialize(args.slice(1)));
        return;
      case 'setData':
        chart.data.datasets[args[0]].data = materialize(args[1]);
        return;
      case 'setItemKey':
        dataOf(args[0])[args[1]][args[2]] = materialize(args[3]);
        return;
      case 'setDataset':
        chart.data.datasets[args[0]][args[1]] = materialize(args[2]);
        return;
      case 'hidden':
        chart.getDatasetMeta(args[0]).hidden = args[1];
        chart.getDatasetMeta(args[0]).visible = chart.isDatasetVisible(args[0]);
        return;
      case 'setActive':
        chart.getDatasetMeta(args[0]).data[args[1]].active = args[2];
        return;
      case 'setHidden':
        chart.getDatasetMeta(args[0]).data[args[1]].hidden = materialize(args[2]);
        return;
      case 'hover':
        controller(args[0]).setHoverStyle(
          chart.getDatasetMeta(args[0]).data[args[1]],
          args[0],
          args[1],
        );
        return;
      case 'unhover':
        controller(args[0]).removeHoverStyle(
          chart.getDatasetMeta(args[0]).data[args[1]],
          args[0],
          args[1],
        );
        return;
      case 'hoverDataset':
        controller(args[0])._setDatasetHoverStyle();
        return;
      case 'unhoverDataset':
        controller(args[0])._removeDatasetHoverStyle();
        return;
      case 'writeOptions': {
        const [ds, index, mode, key, value] = args;
        const options =
          index === null
            ? controller(ds).resolveDatasetElementOptions(mode === null ? undefined : mode)
            : controller(ds).resolveDataElementOptions(index, mode === null ? undefined : mode);
        options[key] = value;
        return;
      }
      case 'writeElementOptions': {
        const [ds, index, key, value] = args;
        const meta = chart.getDatasetMeta(ds);
        const element = index === null ? meta.dataset : meta.data[index];
        element.options[key] = value;
        return;
      }
      // Observations.
      case 'throws':
        try {
          step(args[0]);
          out.push(`throws ${args[0][0]}: none`);
        } catch (e) {
          out.push(`throws ${args[0][0]}: ${e.name}`);
        }
        return;
      case 'parsed':
        out.push(`parsed ${args[0]}: ${enc(chart.getDatasetMeta(args[0])._parsed)}`);
        return;
      case 'sorted':
        out.push(`sorted ${args[0]}: ${enc(chart.getDatasetMeta(args[0])._sorted)}`);
        return;
      case 'stacked':
        out.push(`stacked ${args[0]}: ${enc(chart.getDatasetMeta(args[0])._stacked)}`);
        return;
      case 'stacks':
        out.push(`stacks: ${enc(chart._stacks)}`);
        return;
      case 'minmax': {
        const [ds, scaleId, canStack] = args;
        const range = controller(ds).getMinMax(
          chart.scales[scaleId],
          canStack === null ? undefined : canStack,
        );
        out.push(`minmax ${ds} ${scaleId} ${String(canStack)}: ${enc(range)}`);
        return;
      }
      case 'applyStack': {
        const [ds, scaleId, index, mode] = args;
        const c = controller(ds);
        const value = c.applyStack(
          chart.scales[scaleId],
          c.getParsed(index),
          mode === null ? undefined : mode,
        );
        out.push(`applyStack ${ds} ${scaleId} ${index} ${String(mode)}: ${enc(value)}`);
        return;
      }
      case 'labelAndValue':
        out.push(
          `labelAndValue ${args[0]} ${args[1]}: ${enc(controller(args[0]).getLabelAndValue(args[1]))}`,
        );
        return;
      case 'allParsed':
        out.push(
          `allParsed ${args[0]} ${args[1]}: ${enc(controller(args[0]).getAllParsedValues(chart.scales[args[1]]))}`,
        );
        return;
      case 'meta': {
        const meta = chart.getDatasetMeta(args[0]);
        const scale = (s) => (s ? s.id : 'none');
        out.push(
          `meta ${args[0]}: ${enc({
            xAxisID: none(meta.xAxisID),
            yAxisID: none(meta.yAxisID),
            rAxisID: none(meta.rAxisID),
            iAxisID: none(meta.iAxisID),
            vAxisID: none(meta.vAxisID),
            xScale: scale(meta.xScale),
            yScale: scale(meta.yScale),
            rScale: scale(meta.rScale),
            iScale: scale(meta.iScale),
            vScale: scale(meta.vScale),
            indexAxis: meta.indexAxis,
            stack: meta.stack,
            stacked: meta._stacked,
          })}`,
        );
        return;
      }
      case 'clip': {
        const clip = chart.getDatasetMeta(args[0])._clip;
        out.push(
          `clip ${args[0]}: ${enc({
            top: clip.top,
            right: clip.right,
            bottom: clip.bottom,
            left: clip.left,
            disabled: clip.disabled,
          })}`,
        );
        return;
      }
      case 'elementsList': {
        const meta = chart.getDatasetMeta(args[0]);
        out.push(`elements ${args[0]}: ${enc(meta.dataset)} ${enc(meta.data)}`);
        return;
      }
      case 'elementProps': {
        const [ds, index, props] = args;
        const meta = chart.getDatasetMeta(ds);
        const element = index === null ? meta.dataset : meta.data[index];
        out.push(
          `props ${ds} ${String(index)}: ${enc(props.map((p) => element[p]))}`,
        );
        return;
      }
      case 'dataChanges':
        out.push(`dataChanges: ${enc(chart._dataChanges)}`);
        return;
      case 'trace':
        out.push(`trace: ${enc(trace)}`);
        trace = [];
        return;
      case 'options': {
        const [ds, index, mode] = args;
        const c = controller(ds);
        const options =
          index === null
            ? c.resolveDatasetElementOptions(mode === null ? undefined : mode)
            : c.resolveDataElementOptions(index, mode === null ? undefined : mode);
        out.push(`options ${ds} ${String(index)} ${String(mode)}: ${encOptions(options)}`);
        return;
      }
      case 'style': {
        const [ds, index, active] = args;
        const options = controller(ds).getStyle(
          index === null ? undefined : index,
          active === null ? undefined : active,
        );
        out.push(`style ${ds} ${String(index)} ${String(active)}: ${encOptions(options)}`);
        return;
      }
      case 'elementOptions': {
        const [ds, index] = args;
        const meta = chart.getDatasetMeta(ds);
        const element = index === null ? meta.dataset : meta.data[index];
        out.push(`elementOptions ${ds} ${String(index)}: ${encOptions(element.options)}`);
        return;
      }
      case 'sharedOptions':
        out.push(`sharedOptions ${args[0]}: ${encOptions(controller(args[0])._sharedOptions)}`);
        return;
      case 'getSharedOptions': {
        const [ds, start, mode] = args;
        const {sharedOptions, includeOptions} = controller(ds)._getSharedOptions(start, mode);
        out.push(
          `getSharedOptions ${ds} ${start} ${mode}: ${encOptions(sharedOptions)} include=${!!includeOptions}`,
        );
        return;
      }
      case 'includeOptions': {
        const [ds, mode, withShared] = args;
        const value = controller(ds).includeOptions(mode, withShared ? {} : undefined);
        // The callers test the truthiness of the result.
        out.push(`includeOptions ${ds} ${mode} ${withShared}: ${enc(!!value)}`);
        return;
      }
      case 'context': {
        const [ds, index, active, mode] = args;
        const context = controller(ds).getContext(
          index === null ? undefined : index,
          active === null ? undefined : active,
          mode === null ? undefined : mode,
        );
        out.push(
          `context ${ds} ${String(index)} ${String(active)} ${String(mode)}: ${idOf('ctx', context)} ${enc(context)}`,
        );
        return;
      }
      case 'animations': {
        const [ds, index, transition, active] = args;
        const anims = controller(ds)._resolveAnimations(
          index === null ? undefined : index,
          transition === null ? undefined : transition,
          active === null ? undefined : active,
        );
        out.push(
          `animations ${ds} ${String(index)} ${String(transition)}: ${idOf('anims', anims)} ${enc([...anims._properties.entries()])}`,
        );
        return;
      }
      default:
        throw new Error(`Unknown step ${op}`);
    }
  };

  for (const s of spec.steps) step(s);
  animator.remove(chart);
  return out;
}

// --- The scenarios ------------------------------------------------------

const CATEGORY_X = {id: 'x', axis: 'x', kind: 'category'};
const LINEAR_X = {id: 'x', axis: 'x', kind: 'linear'};
const LINEAR_Y = {id: 'y', axis: 'y', kind: 'linear'};
const UNDEFINED = {$undefined: true};

const SCENARIOS = [
  {
    name: 'parsePrimitiveData with labels',
    labels: ['a', 'b', 'c', 'd'],
    scales: [CATEGORY_X, LINEAR_Y],
    datasets: [{data: [1, '2', null, 'x', 5]}],
    steps: [
      ['build'],
      ['elements', false],
      ['parsed', 0],
      ['sorted', 0],
      ['elementsList', 0],
      ['minmax', 0, 'y', false],
      ['minmax', 0, 'x', false],
      ['allParsed', 0, 'y'],
      ['allParsed', 0, 'x'],
      ['labelAndValue', 0, 0],
      ['labelAndValue', 0, 4],
      ['throws', ['labelAndValue', 0, 9]],
    ],
  },
  {
    name: 'parsePrimitiveData with one scale',
    labels: ['a', 'b'],
    scales: [{id: 'r', axis: 'r', kind: 'linear'}],
    datasets: [{data: [3, 4], indexAxis: 'r'}],
    steps: [['build'], ['elements', false], ['meta', 0], ['parsed', 0], ['sorted', 0]],
  },
  {
    name: 'parseArrayData and the user bounds',
    scales: [
      {...LINEAR_X, bounds: {min: 1, max: 3, minDefined: true, maxDefined: true}},
      LINEAR_Y,
    ],
    datasets: [{data: [[0, 1], [2, '3'], [1, null], [3, 7], [5, 9]]}],
    steps: [
      ['build'],
      ['elements', false],
      ['parsed', 0],
      ['sorted', 0],
      ['minmax', 0, 'y', false],
      ['minmax', 0, 'x', false],
    ],
  },
  {
    name: 'parseObjectData sorted',
    scales: [
      LINEAR_X,
      {...LINEAR_Y, bounds: {min: 2, max: 6, minDefined: true, maxDefined: true}},
    ],
    datasets: [{data: [{x: 1, y: 5}, {x: 2, y: 3}, {x: 4, y: 8}, {x: 6, y: 1}]}],
    steps: [
      ['build'],
      ['elements', false],
      ['parsed', 0],
      ['sorted', 0],
      ['minmax', 0, 'x', false],
      ['minmax', 0, 'y', false],
      ['labelAndValue', 0, 2],
    ],
  },
  {
    name: 'parseObjectData with parsing keys',
    scales: [LINEAR_X, LINEAR_Y],
    options: {parsing: {xAxisKey: 'a.b', yAxisKey: 'v'}},
    datasets: [{data: [{a: {b: 1}, v: 2}, {a: {b: 0}, v: '3'}, {v: 4}]}],
    steps: [['build'], ['elements', false], ['parsed', 0], ['sorted', 0]],
  },
  {
    name: 'object data',
    scales: [{...CATEGORY_X, labels: ['a', 'b', '10']}, LINEAR_Y],
    datasets: [{data: {a: 1, b: 2, 10: 3}}],
    steps: [
      ['build'],
      ['elements', false],
      ['parsed', 0],
      ['sorted', 0],
      ['elementsList', 0],
      ['labelAndValue', 0, 0],
    ],
  },
  {
    name: 'parsing false and the array listener',
    scales: [LINEAR_X, LINEAR_Y],
    options: {parsing: false},
    datasets: [{data: [{x: 0, y: 1}, {x: 1, y: 2}]}],
    steps: [
      ['build'],
      ['elements', false],
      ['parsed', 0],
      ['sorted', 0],
      ['push', 0, {x: 2, y: 3}, {x: 3, y: 4}],
      ['dataChanges'],
      ['elementsList', 0],
      ['parsed', 0],
      ['pop', 0],
      ['shift', 0],
      ['splice', 0, 1, 0, {x: 9, y: 9}],
      ['unshift', 0, {x: -1, y: 0}],
      ['dataChanges'],
      ['elementsList', 0],
      ['parsed', 0],
      ['elements', false],
      ['elementsList', 0],
    ],
  },
  {
    name: 'array listener with parsing',
    labels: ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l'],
    scales: [CATEGORY_X, LINEAR_Y],
    datasets: [{data: [0, 1, 2, 3, 4, 5]}],
    steps: [
      ['build'],
      ['elements', true],
      ['elementsList', 0],
      ['push', 0, 6, 7, 8],
      ['push', 0, 9],
      ['dataChanges'],
      ['elementsList', 0],
      ['elements', true],
      ['elementsList', 0],
      ['parsed', 0],
      ['pop', 0],
      ['shift', 0],
      ['splice', 0, 1, 2, 10, 11],
      ['splice', 0, 0, 0],
      ['unshift', 0, 12, 13],
      ['dataChanges'],
      ['elements', true],
      ['elementsList', 0],
      ['parsed', 0],
      ['setData', 0, [7, 8]],
      ['elements', true],
      ['elementsList', 0],
      ['parsed', 0],
      ['push', 0, 9],
      ['elements', true],
      ['elementsList', 0],
      ['dataChanges'],
    ],
  },
  {
    name: 'stacks and getMinMax',
    labels: ['a', 'b', 'c'],
    scales: [CATEGORY_X, {...LINEAR_Y, options: {stacked: true}}],
    datasets: [{data: [1, 2, -1]}, {data: [3, -4, 5]}, {data: [2, 2, 2], stack: 's'}],
    steps: [
      ['build'],
      ['elements', false],
      ['stacked', 0],
      ['stacks'],
      ['parsed', 1],
      ['minmax', 0, 'y', true],
      ['minmax', 1, 'y', true],
      ['minmax', 1, 'y', false],
      ['minmax', 1, 'y', null],
      ['minmax', 2, 'y', true],
      ['minmax', 1, 'x', true],
      ['applyStack', 1, 'y', 0, true],
      ['applyStack', 1, 'y', 1, true],
      ['applyStack', 1, 'y', 1, 'single'],
      ['applyStack', 0, 'y', 2, null],
      ['setDataset', 2, 'stack', UNDEFINED],
      ['elements', false],
      ['meta', 2],
      ['stacks'],
      ['hidden', 0, true],
      ['minmax', 1, 'y', true],
      ['applyStack', 1, 'y', 1, true],
      ['update', 'none'],
      ['elementProps', 1, 1, ['x', 'y']],
    ],
  },
  {
    name: 'stacks of the stack option',
    labels: ['a', 'b'],
    scales: [CATEGORY_X, LINEAR_Y],
    datasets: [{data: [1, 10], stack: '1'}, {data: [2, 20], stack: '2'}, {data: [3, 30], stack: '1'}],
    steps: [
      ['build'],
      ['elements', false],
      ['stacked', 0],
      ['stacks'],
      ['setDataset', 2, 'stack', '2'],
      ['elements', false],
      ['stacks'],
      ['setData', 2, [4]],
      ['elements', false],
      ['stacks'],
    ],
  },
  {
    name: 'stacked single and null values',
    labels: ['a', 'b'],
    scales: [CATEGORY_X, {...LINEAR_Y, options: {stacked: 'single'}}],
    datasets: [{data: [1, null]}, {data: [-3, 4]}, {data: ['5', 1]}],
    steps: [
      ['build'],
      ['elements', false],
      ['stacked', 1],
      ['stacks'],
      ['minmax', 1, 'y', true],
      ['minmax', 2, 'y', true],
      ['applyStack', 1, 'y', 0, 'single'],
      ['applyStack', 1, 'y', 0, true],
      ['applyStack', 0, 'y', 1, 'single'],
      ['update', 'none'],
      ['elementProps', 2, 0, ['x', 'y']],
    ],
  },
  {
    // With parsing false, a string value stays a string. The JavaScript `+`
    // of applyStack appends the text of the other value.
    name: 'stacked strings with parsing false',
    scales: [LINEAR_X, {...LINEAR_Y, options: {stacked: 'single'}}],
    options: {parsing: false},
    datasets: [{data: [{x: 0, y: 2}]}, {data: [{x: 0, y: '5'}]}, {data: [{x: 0, y: -1}]}],
    steps: [
      ['build'],
      ['elements', false],
      ['applyStack', 1, 'y', 0, 'single'],
      ['applyStack', 2, 'y', 0, 'single'],
      ['applyStack', 2, 'y', 0, true],
      ['minmax', 1, 'y', true],
      ['minmax', 2, 'y', true],
    ],
  },
  {
    // clearStacks continues after a parsed item without a value
    // (core.datasetController.js:220, ledger row #12155). v4.5.1 returns
    // there and keeps the values of the next items in the stacks.
    name: 'clearStacks continues after an item without a value',
    scales: [LINEAR_X, {...LINEAR_Y, options: {stacked: true}}],
    options: {parsing: false},
    datasets: [{data: [{x: 0}, {x: 1, y: 2}]}, {data: [{x: 0, y: 1}, {x: 1, y: 3}]}],
    steps: [
      ['build'],
      ['elements', false],
      ['stacks'],
      ['setData', 0, [{x: 0, y: 5}]],
      ['elements', false],
      ['stacks'],
    ],
  },
  {
    name: 'updateIndex and destroy',
    labels: ['a', 'b'],
    scales: [CATEGORY_X, {...LINEAR_Y, options: {stacked: true}}],
    datasets: [{data: [1, 2]}, {data: [3, 4]}],
    steps: [
      ['build'],
      ['elements', false],
      ['stacks'],
      ['updateIndex', 0, 0],
      ['stacks'],
      ['updateIndex', 0, 5],
      ['stacks'],
      ['destroy', 1],
      ['stacks'],
      ['push', 1, 5],
      ['dataChanges'],
    ],
  },
  {
    name: 'linkScales',
    scales: [
      {id: 'x1', axis: 'x', kind: 'linear'},
      {id: 'x2', axis: 'x', kind: 'linear'},
      {id: 'y1', axis: 'y', kind: 'linear'},
      {id: 'r1', axis: 'r', kind: 'linear'},
    ],
    datasets: [{data: [1], xAxisID: 'x2'}, {data: [1], indexAxis: 'y'}, {data: [1], indexAxis: 'r'}],
    steps: [
      ['build'],
      ['meta', 0],
      ['meta', 1],
      ['meta', 2],
      ['setDataset', 0, 'xAxisID', null],
      ['linkScales', 0],
      ['meta', 0],
      ['setDataset', 1, 'yAxisID', 'nope'],
      ['linkScales', 1],
      ['meta', 1],
    ],
  },
  {
    name: 'clip with an overflow',
    scales: [
      {...LINEAR_X, options: {min: 0}},
      {...LINEAR_Y, options: {reverse: true}},
    ],
    maxOverflow: 5,
    datasets: [
      {data: [1]},
      {data: [1], clip: 3},
      {data: [1], clip: {top: 1, left: 2}},
      {data: [1], clip: false},
    ],
    steps: [['build'], ['elements', false], ['update', 'none'], ['clip', 0], ['clip', 1], ['clip', 2], ['clip', 3]],
  },
  {
    name: 'clip without an overflow',
    scales: [LINEAR_X, LINEAR_Y],
    datasets: [{data: [1]}, {data: [1], clip: 4}],
    steps: [['build'], ['elements', false], ['update', null], ['clip', 0], ['clip', 1]],
  },
  {
    name: 'draw',
    labels: ['a', 'b', 'c', 'd'],
    scales: [CATEGORY_X, LINEAR_Y],
    datasets: [{data: [1, 2, 3, 4]}],
    steps: [
      ['build'],
      ['elements', true],
      ['setActive', 0, 1, true],
      ['setHidden', 0, 2, true],
      ['draw', 0],
      ['trace'],
      ['drawRange', 0, 1, 2],
      ['draw', 0],
      ['trace'],
      ['drawRange', 0, 0, 0],
      ['setDataset', 0, 'drawActiveElementsOnTop', false],
      ['configure', 0],
      ['draw', 0],
      ['trace'],
    ],
  },
  {
    // core.datasetController.js:730 `if (element.hidden)`: the ToBoolean of
    // any value that a user writes into `hidden`.
    name: 'draw with hidden values',
    labels: ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
    scales: [CATEGORY_X, LINEAR_Y],
    elements: {dataset: null, data: 'point'},
    datasets: [{data: [1, 2, 3, 4, 5, 6, 7, 8]}],
    steps: [
      ['build'],
      ['elements', true],
      ['setHidden', 0, 0, 1],
      ['setHidden', 0, 1, 'a'],
      ['setHidden', 0, 2, {}],
      ['setHidden', 0, 3, 0],
      ['setHidden', 0, 4, ''],
      ['setHidden', 0, 5, null],
      ['setHidden', 0, 6, UNDEFINED],
      ['setHidden', 0, 7, false],
      ['draw', 0],
      ['trace'],
    ],
  },
  {
    name: 'draw without a dataset element',
    labels: ['a', 'b'],
    scales: [CATEGORY_X, LINEAR_Y],
    elements: {dataset: null, data: 'bar'},
    datasets: [{data: [1, 2]}],
    steps: [
      ['build'],
      ['elements', true],
      ['elementsList', 0],
      ['setActive', 0, 0, true],
      ['draw', 0],
      ['trace'],
      ['options', 0, 0, null],
    ],
  },
  {
    name: 'shared options of a line chart',
    labels: ['a', 'b', 'c'],
    scales: [CATEGORY_X, LINEAR_Y],
    datasets: [{data: [1, 2, 3]}],
    steps: [
      ['build'],
      ['elements', false],
      ['options', 0, 0, null],
      ['options', 0, 1, 'default'],
      ['options', 0, null, null],
      ['options', 0, null, null],
      ['options', 0, 0, 'active'],
      ['options', 0, 1, 'active'],
      ['style', 0, null, null],
      ['style', 0, 1, true],
      ['sharedOptions', 0],
      ['getSharedOptions', 0, 0, 'default'],
      ['sharedOptions', 0],
      ['includeOptions', 0, 'default', false],
      ['includeOptions', 0, 'reset', true],
      ['includeOptions', 0, 'default', true],
      ['update', 'reset'],
      ['elementOptions', 0, 0],
      ['elementOptions', 0, 1],
      ['elementOptions', 0, null],
      ['update', 'default'],
      ['sharedOptions', 0],
      ['elementOptions', 0, 0],
      ['throws', ['writeOptions', 0, 0, null, 'radius', 9]],
      ['throws', ['writeElementOptions', 0, 0, 'radius', 9]],
      ['elementOptions', 0, 0],
      ['hover', 0, 0],
      ['elementOptions', 0, 0],
      ['elementProps', 0, 0, ['active']],
      ['unhover', 0, 0],
      ['elementOptions', 0, 0],
      ['hoverDataset', 0],
      ['elementOptions', 0, null],
      ['unhoverDataset', 0],
      ['elementOptions', 0, null],
    ],
  },
  {
    name: 'options without sharing',
    labels: ['a', 'b'],
    scales: [CATEGORY_X, LINEAR_Y],
    sharing: false,
    datasets: [{data: [1, 2]}],
    steps: [
      ['build'],
      ['elements', false],
      ['options', 0, 0, null],
      ['options', 0, 1, null],
      ['options', 0, null, null],
      ['getSharedOptions', 0, 0, 'default'],
      ['update', 'reset'],
      ['elementOptions', 0, 0],
      ['elementOptions', 0, 1],
      ['update', 'default'],
      ['elementOptions', 0, 0],
    ],
  },
  {
    name: 'scriptable options',
    labels: ['a', 'b'],
    scales: [CATEGORY_X, LINEAR_Y],
    datasets: [{data: [1, 2], backgroundColor: {$fn: 'colorByIndex'}, fill: {value: {$fn: 'typeIsDataset'}}}],
    steps: [
      ['build'],
      ['elements', false],
      ['options', 0, 0, null],
      ['options', 0, 1, null],
      ['options', 0, 1, null],
      ['options', 0, null, null],
      ['context', 0, 1, false, 'x'],
    ],
  },
  {
    name: 'custom element options',
    labels: ['a'],
    scales: [CATEGORY_X, LINEAR_Y],
    elements: {dataset: false, data: 'custom'},
    datasets: [{data: [1], size: 4}],
    steps: [
      ['build'],
      ['elements', true],
      ['elementsList', 0],
      ['options', 0, 0, null],
      ['options', 0, 0, null],
      ['sharedOptions', 0],
      ['style', 0, null, null],
    ],
  },
  {
    name: 'arc element options',
    labels: ['a'],
    scales: [CATEGORY_X, LINEAR_Y],
    elements: {dataset: null, data: 'arc'},
    datasets: [{data: [1]}],
    steps: [['build'], ['elements', false], ['options', 0, 0, null]],
  },
  {
    // Chart.js ADR 0021, section 5, case 6: the dataset element and the data
    // elements have the type point.
    name: 'frozen options with $shared false',
    labels: ['a', 'b'],
    scales: [CATEGORY_X, LINEAR_Y],
    elements: {dataset: 'point', data: 'point'},
    datasets: [{data: [1, 2]}],
    steps: [
      ['build'],
      ['elements', false],
      ['update', 'reset'],
      ['elementOptions', 0, 0],
      ['elementOptions', 0, null],
      // A point as the dataset element ignores the start and the count.
      ['draw', 0],
      ['trace'],
      ['throws', ['update', 'default']],
    ],
  },
  {
    name: 'animations',
    labels: ['a'],
    scales: [CATEGORY_X, LINEAR_Y],
    options: {
      animation: {delay: 100},
      animations: {x: {delay: 200}},
      transitions: {show: {x: {delay: 300}}},
    },
    datasets: [{data: [1], animation: {duration: 200}}],
    steps: [
      ['build'],
      ['elements', false],
      ['animations', 0, 0, 'default', false],
      ['animations', 0, 0, 'default', false],
      ['animations', 0, null, 'show', null],
      ['animations', 0, null, null, null],
      ['animations', 0, 0, 'active', true],
    ],
  },
  {
    name: 'animations disabled',
    labels: ['a'],
    scales: [CATEGORY_X, LINEAR_Y],
    options: {animation: false},
    datasets: [{data: [1], animation: {test: {duration: 10}}}, {data: [1], animation: false}],
    steps: [
      ['build'],
      ['elements', false],
      ['animations', 0, 0, null, null],
      ['animations', 1, 0, null, null],
    ],
  },
  {
    name: 'getContext',
    scales: [LINEAR_X, LINEAR_Y],
    datasets: [{data: [{x: 1, y: 0}, {x: 2, y: '1'}], label: 'd'}],
    steps: [
      ['build'],
      ['elements', true],
      ['context', 0, null, true, 'test'],
      ['context', 0, 1, false, 'datatest'],
      ['setItemKey', 0, 1, 'y', 5],
      ['elements', false],
      ['context', 0, 1, false, 'datatest'],
      ['context', 0, 5, null, null],
      ['context', 0, 0, true, null],
    ],
  },
  {
    name: 'sorted raw values',
    scales: [{id: 'x', axis: 'x', kind: 'raw'}, LINEAR_Y],
    datasets: [
      {data: [{x: 'b', y: 1}, {x: 'a', y: 2}]},
      {data: [{x: 'a', y: 1}, {x: 'b', y: 2}]},
      {data: [{x: '9', y: 1}, {x: '10', y: 2}]},
      {data: [{x: 9, y: 1}, {x: '10', y: 2}]},
      {data: [{x: [2], y: 1}, {x: [10], y: 2}]},
      {data: [{x: {a: 1}, y: 1}, {x: {b: 2}, y: 2}]},
      {data: [{x: true, y: 1}, {x: false, y: 2}]},
      {data: [{x: 'é', y: 1}, {x: '😀', y: 2}]},
      {data: [{x: '😀', y: 1}, {x: 'é', y: 2}]},
      {data: [{x: 2, y: 1}, {x: null, y: 2}]},
      {data: [{x: 2, y: 1}, {x: 1, y: 2}]},
      {data: [{x: 'a', y: 1}, {y: 2}]},
    ],
    steps: [
      ['build'],
      ['elements', false],
      ['sorted', 0],
      ['sorted', 1],
      ['sorted', 2],
      ['sorted', 3],
      ['sorted', 4],
      ['sorted', 5],
      ['sorted', 6],
      ['sorted', 7],
      ['sorted', 8],
      ['sorted', 9],
      ['sorted', 10],
      ['sorted', 11],
      ['minmax', 1, 'y', false],
      ['minmax', 0, 'x', false],
    ],
  },
  {
    name: 'stacked removals',
    labels: ['a', 'b', 'c', 'd'],
    scales: [CATEGORY_X, {...LINEAR_Y, options: {stacked: true}}],
    datasets: [{data: [1, 2, 3]}, {data: [4, 5, 6]}],
    steps: [
      ['build'],
      ['elements', false],
      ['stacks'],
      ['pop', 1],
      ['elements', false],
      ['stacks'],
      ['minmax', 1, 'y', true],
      ['shift', 0],
      ['elements', false],
      ['stacks'],
      ['minmax', 0, 'y', true],
      ['minmax', 1, 'y', true],
      ['splice', 1, 0, 1, 9],
      ['elements', false],
      ['stacks'],
      ['parsed', 1],
      ['minmax', 1, 'y', true],
      ['unshift', 0, 7],
      ['elements', false],
      ['stacks'],
      ['applyStack', 1, 'y', 0, true],
    ],
  },
  {
    name: 'parsing false with primitive data',
    scales: [LINEAR_X, LINEAR_Y],
    options: {parsing: false},
    datasets: [{data: [1, 2, 3]}],
    steps: [
      ['build'],
      ['elements', false],
      ['parsed', 0],
      ['sorted', 0],
      ['minmax', 0, 'y', false],
      ['minmax', 0, 'x', false],
      ['allParsed', 0, 'y'],
      ['labelAndValue', 0, 0],
      ['throws', ['update', 'none']],
      ['context', 0, 1, false, 'x'],
    ],
  },
  {
    name: 'parsing false with stacked primitive data',
    scales: [LINEAR_X, {...LINEAR_Y, options: {stacked: true}}],
    options: {parsing: false},
    datasets: [{data: [1, 2]}],
    steps: [['build'], ['throws', ['elements', false]], ['parsed', 0]],
  },
  {
    name: 'a null data item',
    scales: [LINEAR_X, LINEAR_Y],
    datasets: [{data: [[0, 1], null]}],
    steps: [['build'], ['throws', ['elements', false]]],
  },
];

// --- The output ---------------------------------------------------------

/** The Dart literal of a number: always a double literal. */
function num(v) {
  if (Object.is(v, -0)) return '-0.0';
  const text = String(v);
  return /[.e]/.test(text) ? text : `${text}.0`;
}

/** The Dart literal of a JSON spec value. */
function dart(v) {
  if (v === null) return 'null';
  if (typeof v === 'number') return num(v);
  if (typeof v === 'boolean') return String(v);
  if (typeof v === 'string') {
    // Single quotes, or double quotes for a string with a single quote
    // (prefer_single_quotes, avoid_escaping_inner_quotes).
    const quote = v.includes("'") && !v.includes('"') ? '"' : "'";
    // A raw string for a `$` or a backslash (use_raw_strings).
    if (/[\\$]/.test(v) && !v.includes(quote)) return `r${quote}${v}${quote}`;
    const escaped = v.replace(/[\\$]/g, '\\$&').replaceAll(quote, `\\${quote}`);
    return `${quote}${escaped}${quote}`;
  }
  if (Array.isArray(v)) return `<Object?>[${v.map(dart).join(', ')}]`;
  if (typeof v === 'object') {
    const entries = Object.keys(v).map((k) => `${dart(k)}: ${dart(v[k])}`);
    return `<String, Object?>{${entries.join(', ')}}`;
  }
  throw new Error(`No Dart literal for ${String(v)}`);
}

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

const body = SCENARIOS.map((spec) => {
  const observations = run(spec);
  return `  (\n    spec: ${dart(spec)},\n    observations: ${dartLines(observations)},\n  ),\n`;
}).join('');

const out = `// Original code, not ported from Chart.js: dataset controller reference data.

// Generated by tool/reference/dataset_controller_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// src/core/core.datasetController.js at the pinned Chart.js. ${SCENARIOS.length} scenarios.

/// The Node.js version that generated the data.
const String datasetControllerReferenceNode = '${process.version}';

/// The V8 version that generated the data.
const String datasetControllerReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated the data.
const String datasetControllerReferenceArch = '${process.arch}';

/// A scenario: the spec of the fake chart and the steps, and the
/// observations that the steps give upstream, one on each line, in order.
///
/// The spec keys: \`name\`, \`chartType\`, \`labels\`, \`scales\` (each with
/// \`id\`, \`axis\`, \`kind\`, \`options\`, \`labels\` and \`bounds\`), \`datasets\`,
/// \`options\`, \`elements\` (\`dataset\` and \`data\`), \`sharing\`,
/// \`maxOverflow\`, \`animationsDisabled\`, \`plugins\` and \`steps\`. A value
/// \`{$fn: name}\` is a function of the test, and \`{$undefined: true}\` is
/// \`undefined\`.
typedef DatasetControllerScenario = ({
  Map<String, Object?> spec,
  String observations,
});

/// The scenarios.
const List<DatasetControllerScenario> datasetControllerReference = [
${body}];
`;

writeFileSync(OUT, out);
execFileSync('dart', ['format', OUT], {stdio: 'inherit'});
console.log(`Wrote ${SCENARIOS.length} scenarios to ${OUT}`);
