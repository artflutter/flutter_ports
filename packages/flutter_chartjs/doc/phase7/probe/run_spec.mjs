// Original code, not ported from Chart.js: phase 7 probe harness.
//
// Runs one upstream spec file (third_party/Chart.js/test/specs/<name>.tests.js)
// in the x64 Node.js against the build of Chart.js at the pin, with a small
// Jasmine stand-in (jasmine.mjs), and records what each case asserts.
//
// Usage:
//   /usr/bin/arch -x86_64 <node-v24.12.0-darwin-x64>/bin/node run_spec.mjs \
//     <dist/chart.js> <spec file name or path> --mode <mode> \
//     [--filter <substring of the full case name>] [--out <json>] \
//     [--moment <node_modules of moment>]
//
// Modes:
//   all            Chart.register(...registerables) and, as test/index.js:25-28,
//                  Chart.defaults.plugins.colors.enabled = false.
//   none           the registerables without the plugins.
//   without:<id>   all registerables minus the plugin <id>.
//   only:<id>      the controllers, elements and scales, and the plugin <id>.
//
// The moment packages come from --moment, MOMENT_NODE_MODULES, or
// <dist>/../../moment/node_modules (the layout of doc/phase7/env-setup.sh).
// See README.md for the limits.

import {existsSync, readFileSync, writeFileSync, writeSync} from 'node:fs';
import {dirname, isAbsolute, join, resolve} from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';
import vm from 'node:vm';
import {Unsupported, createJasmine, makeSerializer, note} from './jasmine.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const PACKAGE = resolve(HERE, '../../..');
const REPO = resolve(PACKAGE, '../..');
const SPECS = join(REPO, 'third_party/Chart.js/test/specs');
const CONTEXT_JS = join(REPO, 'third_party/chartjs-test-utils/src/context.js');

// ---------------------------------------------------------------------------
// Arguments. process.argv[2] is the dist: loadChartJs() reads it.

function usage(message) {
  console.error(message);
  console.error(
    'Usage: node run_spec.mjs <dist/chart.js> <spec> --mode <all|none|without:<id>|only:<id>> ' +
      '[--filter <text>] [--out <json>] [--moment <node_modules>]',
  );
  process.exit(2);
}

const argv = process.argv.slice(2);
const positional = [];
const opts = {mode: null, filter: null, out: null, moment: null};
for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (a.startsWith('--')) {
    const key = a.slice(2);
    if (!(key in opts)) usage(`Unknown option ${a}.`);
    opts[key] = argv[++i];
    if (opts[key] === undefined) usage(`${a} needs a value.`);
  } else {
    positional.push(a);
  }
}
if (positional.length !== 2) usage('Give the dist and the spec.');
if (!opts.mode) usage('Give --mode.');
const [distArg, specArg] = positional;
const dist = resolve(distArg);
process.argv[2] = dist;

function specPath(arg) {
  if (existsSync(arg)) return resolve(arg);
  let name = arg;
  if (!name.endsWith('.js')) name = name.endsWith('.tests') ? `${name}.js` : `${name}.tests.js`;
  const p = isAbsolute(name) ? name : join(SPECS, name);
  if (!existsSync(p)) usage(`No spec file ${p}.`);
  return p;
}
const SPEC = specPath(specArg);

const momentDir = opts.moment ?? process.env.MOMENT_NODE_MODULES ?? resolve(dirname(dist), '../../moment/node_modules');
process.env.MOMENT_NODE_MODULES = momentDir;

// ---------------------------------------------------------------------------
// window, before the dist loads: helpers.extras reads
// window.requestAnimationFrame at load time.

globalThis.window = globalThis;
globalThis.devicePixelRatio = 1;
let rafSeq = 0;
const rafs = new Map();
globalThis.requestAnimationFrame = (cb) => {
  const id = ++rafSeq;
  rafs.set(
    id,
    setTimeout(() => {
      rafs.delete(id);
      cb(performance.now());
    }, 16),
  );
  return id;
};
globalThis.cancelAnimationFrame = (id) => {
  clearTimeout(rafs.get(id));
  rafs.delete(id);
};
const windowListeners = new Map();
globalThis.addEventListener = (type, fn) => {
  if (!fn) return;
  if (!windowListeners.has(type)) windowListeners.set(type, new Set());
  windowListeners.get(type).add(fn);
};
globalThis.removeEventListener = (type, fn) => windowListeners.get(type)?.delete(fn);

// ---------------------------------------------------------------------------
// The DOM stand-in.

const camel = (p) => p.trim().replace(/-([a-z])/g, (_, c) => c.toUpperCase());
const kebab = (p) => p.replace(/[A-Z]/g, (c) => '-' + c.toLowerCase());

/** A CSSStyleDeclaration: '' for a property that has no value. */
function makeStyle() {
  const t = {};
  const parse = (text) => {
    for (const k of Object.keys(t)) delete t[k];
    for (const part of String(text).split(';')) {
      const i = part.indexOf(':');
      if (i < 0) continue;
      const v = part.slice(i + 1).trim();
      if (v) t[camel(part.slice(0, i))] = v;
    }
  };
  const methods = {
    getPropertyValue: (p) => t[camel(p)] ?? '',
    setProperty: (p, v) => {
      if (v === null || v === '') delete t[camel(p)];
      else t[camel(p)] = String(v);
    },
    removeProperty: (p) => {
      const old = t[camel(p)] ?? '';
      delete t[camel(p)];
      return old;
    },
  };
  return new Proxy(t, {
    get(target, k) {
      if (k === Symbol.toStringTag) return 'CSSStyleDeclaration';
      if (typeof k === 'symbol') return target[k];
      if (k === 'cssText') {
        return Object.entries(target)
          .map(([key, v]) => `${kebab(key)}: ${v};`)
          .join(' ');
      }
      if (k in methods) return methods[k];
      return Object.prototype.hasOwnProperty.call(target, k) ? target[k] : '';
    },
    set(target, k, v) {
      if (k === 'cssText') {
        parse(v);
        return true;
      }
      // A write of undefined is an invalid value: the declaration keeps
      // its value. null and '' remove the declaration.
      if (v === undefined) return true;
      if (v === null || v === '') delete target[k];
      else target[k] = String(v);
      return true;
    },
  });
}

class ProbeNode {
  constructor() {
    this.parentNode = null;
    this.childNodes = [];
  }
  get children() {
    return this.childNodes;
  }
  get firstChild() {
    return this.childNodes[0] ?? null;
  }
  appendChild(child) {
    if (child.parentNode) child.parentNode.removeChild(child);
    this.childNodes.push(child);
    child.parentNode = this;
    return child;
  }
  insertBefore(child, ref) {
    if (!ref) return this.appendChild(child);
    if (child.parentNode) child.parentNode.removeChild(child);
    this.childNodes.splice(this.childNodes.indexOf(ref), 0, child);
    child.parentNode = this;
    return child;
  }
  removeChild(child) {
    const i = this.childNodes.indexOf(child);
    if (i < 0) throw new Error("Failed to execute 'removeChild' on 'Node': The node to be removed is not a child of this node.");
    this.childNodes.splice(i, 1);
    child.parentNode = null;
    return child;
  }
  remove() {
    if (this.parentNode) this.parentNode.removeChild(this);
  }
  contains(node) {
    for (let n = node; n; n = n.parentNode) if (n === this) return true;
    return false;
  }
  get isConnected() {
    for (let n = this; n; n = n.parentNode) if (n === document) return true;
    return false;
  }
  // helpers.dom.ts reads getComputedStyle through
  // element.ownerDocument.defaultView.
  get ownerDocument() {
    return this === document ? null : document;
  }
}

/** The element methods, for the div elements and the canvas elements. */
const elementMethods = {
  setAttribute(name, value) {
    const v = String(value);
    this.$attrs.set(name, v);
    if (name === 'style') this.style.cssText = v;
    else if (name === 'id') this.id = v;
    else if (this.$onAttribute) this.$onAttribute(name, v);
  },
  getAttribute(name) {
    if (name === 'style') return this.style.cssText || (this.$attrs.has('style') ? '' : null);
    if (name === 'id') return this.id === '' && !this.$attrs.has('id') ? null : this.id;
    return this.$attrs.has(name) ? this.$attrs.get(name) : null;
  },
  hasAttribute(name) {
    return this.getAttribute(name) !== null;
  },
  removeAttribute(name) {
    this.$attrs.delete(name);
    if (name === 'style') this.style.cssText = '';
    else if (name === 'id') this.id = '';
    else if (this.$onAttribute) this.$onAttribute(name, null);
  },
  addEventListener(type, fn) {
    if (!fn) return;
    if (!this.$listeners.has(type)) this.$listeners.set(type, []);
    const list = this.$listeners.get(type);
    if (!list.includes(fn)) list.push(fn);
  },
  removeEventListener(type, fn) {
    const list = this.$listeners.get(type);
    if (list && list.includes(fn)) list.splice(list.indexOf(fn), 1);
  },
  dispatchEvent(event) {
    if (!('target' in event)) event.target = this;
    for (const fn of (this.$listeners.get(event.type) || []).slice()) fn.call(this, event);
    return true;
  },
  get clientWidth() {
    throw new Unsupported('clientWidth needs the DOM layout');
  },
  get clientHeight() {
    throw new Unsupported('clientHeight needs the DOM layout');
  },
  get offsetWidth() {
    throw new Unsupported('offsetWidth needs the DOM layout');
  },
  get offsetHeight() {
    throw new Unsupported('offsetHeight needs the DOM layout');
  },
  getBoundingClientRect() {
    throw new Unsupported('getBoundingClientRect of a non-canvas element needs the DOM layout');
  },
  attachShadow() {
    throw new Unsupported('shadow DOM');
  },
};

function initElement(el, tagName) {
  Object.defineProperties(el, {
    parentNode: {value: null, writable: true, enumerable: false},
    childNodes: {value: [], writable: true, enumerable: false},
    $attrs: {value: new Map(), enumerable: false},
    $listeners: {value: new Map(), enumerable: false},
    tagName: {value: tagName.toUpperCase(), enumerable: false},
    nodeName: {value: tagName.toUpperCase(), enumerable: false},
    nodeType: {value: 1, enumerable: false},
  });
  if (!('id' in el)) el.id = '';
  Object.defineProperty(el, 'style', {value: makeStyle(), writable: false, enumerable: true, configurable: true});
  if (!('className' in el)) el.className = '';
}

class ProbeElement extends ProbeNode {}
for (const [k, d] of Object.entries(Object.getOwnPropertyDescriptors(elementMethods))) {
  Object.defineProperty(ProbeElement.prototype, k, d);
}
class ProbeDivElement extends ProbeElement {
  get [Symbol.toStringTag]() {
    return 'HTMLDivElement';
  }
}
class ProbeCanvasElement extends ProbeElement {
  get [Symbol.toStringTag]() {
    return 'HTMLCanvasElement';
  }
}

/** HTML "rules for parsing non-negative integers", or the default. */
function canvasDimension(value, fallback) {
  if (value === null) return fallback;
  const m = String(value).match(/^[\t\n\f\r ]*\+?(\d+)/);
  return m ? Number(m[1]) >>> 0 : fallback;
}

let common = null;

/**
 * A canvas element: the fakeCanvas of scale_chart_common.mjs (a
 * LiberationContext and the font reset of a size write) with the element
 * methods, the reflected attributes width and height (default 300 x 150)
 * and the event listeners.
 */
function createCanvasElement() {
  const canvas = common.fakeCanvas(300, 150);
  const ctx = canvas.getContext('2d');
  Object.defineProperty(ctx, Symbol.toStringTag, {value: 'CanvasRenderingContext2D'});
  for (const name of ['createLinearGradient', 'createRadialGradient', 'createConicGradient', 'createPattern']) {
    ctx[name] = () => {
      throw new Unsupported(`${name}: the mock context has no gradients and patterns`);
    };
  }
  guardMeasure(ctx);
  const w = Object.getOwnPropertyDescriptor(canvas, 'width');
  const h = Object.getOwnPropertyDescriptor(canvas, 'height');
  Object.setPrototypeOf(canvas, ProbeCanvasElement.prototype);
  delete canvas.style;
  initElement(canvas, 'canvas');
  Object.defineProperties(canvas, {
    width: {
      get: w.get,
      set(v) {
        w.set.call(canvas, v);
        canvas.$attrs.set('width', String(w.get.call(canvas)));
      },
      enumerable: true,
      configurable: true,
    },
    height: {
      get: h.get,
      set(v) {
        h.set.call(canvas, v);
        canvas.$attrs.set('height', String(h.get.call(canvas)));
      },
      enumerable: true,
      configurable: true,
    },
    $onAttribute: {
      value(name, v) {
        if (name === 'width') w.set.call(canvas, canvasDimension(v, 300));
        if (name === 'height') h.set.call(canvas, canvasDimension(v, 150));
      },
    },
    getBoundingClientRect: {
      value() {
        const {width, height} = cssBox(canvas);
        return {left: 0, top: 0, x: 0, y: 0, width, height, right: width, bottom: height};
      },
    },
    transferControlToOffscreen: {
      value() {
        throw new Unsupported('OffscreenCanvas');
      },
    },
  });
  return canvas;
}

/**
 * The LiberationContext stops on a font or a text outside its limits (see
 * scale_chart_common.mjs). Then the probe takes the width of the upstream
 * mock (10 px a character) and adds a note to the case.
 */
function guardMeasure(ctx) {
  const measure = ctx.measureText;
  ctx.measureText = (text) => {
    try {
      return measure(text);
    } catch (e) {
      note(`measureText fallback (10 px a character): ${e.message}`);
      const s = String(text);
      return {
        actualBoundingBoxAscent: 4,
        actualBoundingBoxDescent: 8,
        actualBoundingBoxLeft: 15,
        actualBoundingBoxRight: 25,
        width: s.length * 10,
      };
    }
  };
}

/** A px length of an inline style, or [fallback] for no value. */
function pxStyle(el, prop, fallback) {
  const v = el.style[prop];
  if (!v) return fallback;
  const m = /^(-?\d+(?:\.\d+)?)px$/.exec(v);
  if (!m) throw new Unsupported(`the computed ${prop} of '${v}' needs CSS layout`);
  return v;
}

/** The CSS box of a canvas without CSS rules: the inline px size or the render size. */
function cssBox(canvas) {
  return {
    width: parseFloat(pxStyle(canvas, 'width', `${canvas.width}px`)),
    height: parseFloat(pxStyle(canvas, 'height', `${canvas.height}px`)),
  };
}

const ZERO_BOX = /^(margin|padding|border)/;

/**
 * getComputedStyle for a canvas without CSS rules (the wrapper CSS of
 * test/index.js has no border, margin or padding). Other elements need the
 * layout: Unsupported.
 */
globalThis.getComputedStyle = (el) => {
  if (!(el instanceof ProbeCanvasElement)) {
    throw new Unsupported('getComputedStyle of a non-canvas element needs CSS layout');
  }
  note('getComputedStyle approximated: a canvas without CSS rules');
  return new Proxy(
    {},
    {
      get(_, key) {
        if (typeof key !== 'string') return undefined;
        const k = camel(key);
        if (k === 'getPropertyValue') return (p) => this.get(_, camel(p));
        if (k === 'width') return el.isConnected ? pxStyle(el, 'width', `${el.width}px`) : '';
        if (k === 'height') return el.isConnected ? pxStyle(el, 'height', `${el.height}px`) : '';
        if (k === 'display') return el.style.display || 'inline';
        if (k === 'boxSizing') return el.style.boxSizing || 'content-box';
        if (k === 'maxWidth' || k === 'maxHeight') {
          if (el.style[k]) throw new Unsupported(`the computed ${k} needs CSS layout`);
          return 'none';
        }
        if (ZERO_BOX.test(k)) {
          if (el.style[k] || el.style[k.replace(/(Top|Right|Bottom|Left)/, '')]) {
            throw new Unsupported(`the computed ${k} of an inline style needs CSS layout`);
          }
          return k.startsWith('border') && !k.endsWith('Width') ? '' : '0px';
        }
        return el.style[k];
      },
    },
  );
};

class ProbeDocument extends ProbeNode {
  constructor() {
    super();
    const html = new ProbeDivElement();
    initElement(html, 'html');
    this.documentElement = html;
    this.appendChild(html);
    this.head = new ProbeDivElement();
    initElement(this.head, 'head');
    html.appendChild(this.head);
    this.body = new ProbeDivElement();
    initElement(this.body, 'body');
    html.appendChild(this.body);
  }
  get [Symbol.toStringTag]() {
    return 'HTMLDocument';
  }
  createElement(tag) {
    const t = String(tag).toLowerCase();
    if (t === 'canvas') return createCanvasElement();
    if (t === 'iframe') throw new Unsupported('iframe');
    const el = new ProbeDivElement();
    initElement(el, t);
    return el;
  }
  createTextNode(text) {
    const n = new ProbeNode();
    n.nodeType = 3;
    n.textContent = String(text);
    return n;
  }
  getElementById(id) {
    const walk = (n) => {
      if (n.id === id && n !== this) return n;
      for (const c of n.childNodes) {
        const r = walk(c);
        if (r) return r;
      }
      return null;
    };
    return walk(this);
  }
  getElementsByTagName(tag) {
    const out = [];
    const t = String(tag).toUpperCase();
    const walk = (n) => {
      for (const c of n.childNodes) {
        if (c.tagName === t) out.push(c);
        walk(c);
      }
    };
    walk(this);
    return out;
  }
  addEventListener() {}
  removeEventListener() {}
}

const document = new ProbeDocument();
document.defaultView = globalThis;
globalThis.document = document;
globalThis.Image = class {
  constructor() {
    throw new Unsupported('Image (image decoding)');
  }
};
globalThis.CanvasGradient = class CanvasGradient {};
globalThis.CanvasPattern = class CanvasPattern {};
globalThis.MutationObserver = class {
  constructor() {
    throw new Unsupported('MutationObserver');
  }
};
globalThis.ResizeObserver = class {
  constructor() {
    throw new Unsupported('ResizeObserver');
  }
};

// ---------------------------------------------------------------------------
// Chart.js, the moment adapter and the mock context.

common = await import(pathToFileURL(join(PACKAGE, 'tool/reference/scale_chart_common.mjs')).href);
const C = await common.loadChartJs();
const helpers = await import(new URL('helpers.js', pathToFileURL(dist)).href);
const timeCommon = await import(pathToFileURL(join(PACKAGE, 'tool/reference/scale_time_common.mjs')).href);
const moment = await timeCommon.loadMomentAdapter(C);
// loadMomentAdapter fixes Date.now at NOW. The animator needs a clock that
// moves: the probe clock starts at NOW and moves with the process clock.
const clockStart = performance.now();
Date.now = () => timeCommon.NOW + Math.floor(performance.now() - clockStart);
const {default: MockContext} = await import(
  'data:text/javascript;base64,' + Buffer.from(readFileSync(CONTEXT_JS, 'utf8')).toString('base64')
);

// ---------------------------------------------------------------------------
// The platform: a DomPlatform subclass (thus a BasePlatform) that overrides
// each method. It mirrors platform.dom.js on the DOM stand-in: the canvas
// initialization and restore, the throttled event proxies on the canvas
// listeners, and getMaximumSize for an explicit size. A responsive size
// (no explicit width and height), the resize, attach and detach observers
// are Unsupported.

const EVENT_TYPES = {
  touchstart: 'mousedown',
  touchmove: 'mousemove',
  touchend: 'mouseup',
  pointerenter: 'mouseenter',
  pointerdown: 'mousedown',
  pointermove: 'mousemove',
  pointerup: 'mouseup',
  pointerleave: 'mouseout',
  pointerout: 'mouseout',
};
const EXPANDO_KEY = '$chartjs';
const isNullOrEmpty = (v) => v === null || v === '';
const round1 = (v) => Math.round(v * 10) / 10;

function readUsedSize(element, property) {
  const value = getComputedStyle(element)[property];
  const matches = value && value.match(/^(\d+)(\.\d+)?px$/);
  return matches ? +matches[1] : undefined;
}

function initCanvas(canvas, aspectRatio) {
  const style = canvas.style;
  const renderHeight = canvas.getAttribute('height');
  const renderWidth = canvas.getAttribute('width');
  canvas[EXPANDO_KEY] = {
    initial: {
      height: renderHeight,
      width: renderWidth,
      style: {display: style.display, height: style.height, width: style.width},
    },
  };
  style.display = style.display || 'block';
  style.boxSizing = style.boxSizing || 'border-box';
  if (isNullOrEmpty(renderWidth)) {
    const displayWidth = readUsedSize(canvas, 'width');
    if (displayWidth !== undefined) canvas.width = displayWidth;
  }
  if (isNullOrEmpty(renderHeight)) {
    if (canvas.style.height === '') {
      canvas.height = canvas.width / (aspectRatio || 2);
    } else {
      const displayHeight = readUsedSize(canvas, 'height');
      if (displayHeight !== undefined) canvas.height = displayHeight;
    }
  }
  return canvas;
}

function throttled(fn, thisArg) {
  let argsToUse = [];
  let ticking = false;
  return function(...args) {
    argsToUse = args;
    if (!ticking) {
      ticking = true;
      window.requestAnimationFrame(() => {
        ticking = false;
        fn.apply(thisArg, argsToUse);
      });
    }
  };
}

/** getRelativePosition of helpers.dom.ts for a canvas without padding and border. */
function relativePosition(event, chart) {
  const {canvas, currentDevicePixelRatio} = chart;
  const useOffset = (event.offsetX > 0 || event.offsetY > 0) && !(event.target && event.target.shadowRoot);
  let x;
  let y;
  if (useOffset) {
    x = event.offsetX;
    y = event.offsetY;
  } else {
    const rect = canvas.getBoundingClientRect();
    x = event.clientX - rect.left;
    y = event.clientY - rect.top;
  }
  return {
    x: Math.round((x / chart.width) * canvas.width / currentDevicePixelRatio),
    y: Math.round((y / chart.height) * canvas.height / currentDevicePixelRatio),
  };
}

function fromNativeEvent(event, chart) {
  const type = EVENT_TYPES[event.type] || event.type;
  const {x, y} = relativePosition(event, chart);
  return {type, chart, native: event, x: x !== undefined ? x : null, y: y !== undefined ? y : null};
}

const OBSERVERS = new Set(['attach', 'detach', 'resize']);

class ProbePlatform extends C.DomPlatform {
  acquireContext(canvas, aspectRatio) {
    const context = canvas && canvas.getContext && canvas.getContext('2d');
    if (context && context.canvas === canvas) {
      if (typeof canvas.getAttribute === 'function') initCanvas(canvas, aspectRatio);
      return context;
    }
    return null;
  }

  releaseContext(context) {
    const canvas = context.canvas;
    if (!canvas[EXPANDO_KEY]) return false;
    const initial = canvas[EXPANDO_KEY].initial;
    ['height', 'width'].forEach((prop) => {
      const value = initial[prop];
      if (value === null || value === undefined) canvas.removeAttribute(prop);
      else canvas.setAttribute(prop, value);
    });
    const style = initial.style || {};
    Object.keys(style).forEach((key) => {
      canvas.style[key] = style[key];
    });
    // eslint-disable-next-line no-self-assign
    canvas.width = canvas.width;
    delete canvas[EXPANDO_KEY];
    return true;
  }

  addEventListener(chart, type, listener) {
    this.removeEventListener(chart, type);
    const proxies = chart.$proxies || (chart.$proxies = {});
    if (OBSERVERS.has(type)) {
      // No observer: the probe has no layout and no mutation records.
      proxies[type] = {observer: type, listener};
      return;
    }
    const canvas = chart.canvas;
    const proxy = throttled((event) => {
      if (chart.ctx !== null) listener(fromNativeEvent(event, chart));
    }, chart);
    if (canvas && canvas.addEventListener) canvas.addEventListener(type, proxy, {passive: true});
    proxies[type] = proxy;
  }

  removeEventListener(chart, type) {
    const proxies = chart.$proxies || (chart.$proxies = {});
    const proxy = proxies[type];
    if (!proxy) return;
    if (!OBSERVERS.has(type) && chart.canvas && chart.canvas.removeEventListener) {
      chart.canvas.removeEventListener(type, proxy, {passive: true});
    }
    proxies[type] = undefined;
  }

  getDevicePixelRatio() {
    return window.devicePixelRatio;
  }

  /**
   * getMaximumSize of helpers.dom.ts for a canvas without CSS rules. The
   * container size (no explicit width or height) is known for one
   * container only: a div in the body with at most an inline px width and
   * height and an inline position (static, relative or absolute), and no
   * other inline style. Its width is the inline width; with
   * the class chartjs-wrapper (`position: absolute` in test/index.js, no
   * border, margin or padding) it shrink-wraps the canvas, and the width
   * can be absent (then the CSS box of the canvas). Its height is the inline
   * height, else the CSS box of the canvas (a block canvas in an auto
   * height). A canvas outside the document gets 0 x 0, as in a browser.
   * Another container needs the DOM layout: Unsupported.
   */
  getMaximumSize(canvas, bbWidth, bbHeight, aspectRatio) {
    if (canvas.style) {
      for (const k of ['maxWidth', 'maxHeight', 'margin', 'padding', 'border']) {
        if (canvas.style[k]) throw new Unsupported(`getMaximumSize with the inline style ${k}`);
      }
    }
    let cw = bbWidth;
    let ch = bbHeight;
    if ((bbWidth === undefined || bbHeight === undefined) && (!canvas.parentNode || !canvas.parentNode.isConnected)) {
      // A canvas outside the document: its clientWidth (no container) or the
      // rect and the computed style of its container are all 0 in a browser.
      note('responsive size: a canvas outside the document has the size 0 x 0');
      cw = 0;
      ch = 0;
    } else if (bbWidth === undefined || bbHeight === undefined) {
      const container = canvas.parentNode;
      const div =
        container &&
        container.isConnected &&
        container.tagName === 'DIV' &&
        container.parentNode === document.body &&
        canvas.style.display !== 'none' &&
        Object.keys(container.style).every(
          (k) => k === 'width' || k === 'height' || (k === 'position' && /^(static|relative|absolute)$/.test(container.style.position)),
        );
      const absolute =
        div && String(container.getAttribute('class') || '').split(/\s+/).includes('chartjs-wrapper');
      if (!div || (!absolute && !container.style.width)) {
        throw new Unsupported('the size of a responsive chart needs the DOM layout of its container');
      }
      note('responsive size: the wrapper box from its inline px size or the canvas box');
      const box = cssBox(canvas);
      cw = parseFloat(pxStyle(container, 'width', `${box.width}px`));
      ch = parseFloat(pxStyle(container, 'height', `${box.height}px`));
    }
    let width = Math.max(0, cw);
    let height = Math.max(0, aspectRatio ? width / aspectRatio : ch);
    width = round1(width);
    height = round1(height);
    if (width && !height) height = round1(width / 2);
    const maintainHeight = bbWidth !== undefined || bbHeight !== undefined;
    if (maintainHeight && aspectRatio && ch && height > ch) {
      height = ch;
      width = round1(Math.floor(height * aspectRatio));
    }
    return {width, height};
  }

  isAttached(canvas) {
    let container = canvas && canvas.parentNode;
    if (container && String(container) === '[object ShadowRoot]') container = container.host;
    return !!(container && container.isConnected);
  }
}

// The default platform. The Chart constructor takes
// `config.platform || _detectPlatform(canvas)` (core.controller.js:136), and
// `config.platform` is a getter of the Config class (core.config.js:165).
// The getter now gives ProbePlatform when the user config has no platform.
{
  const probe = new C.Chart(common.fakeCanvas(10, 10).getContext('2d'), {platform: C.BasicPlatform});
  const proto = Object.getPrototypeOf(probe.config);
  probe.destroy();
  const desc = Object.getOwnPropertyDescriptor(proto, 'platform');
  Object.defineProperty(proto, 'platform', {
    get() {
      return desc.get.call(this) || ProbePlatform;
    },
    configurable: true,
  });
}

// ---------------------------------------------------------------------------
// The global Chart: the UMD build (src/index.umd.ts) on the module.

const Chart = C.Chart;
Chart.helpers = {...helpers};
Chart._adapters = C._adapters;
Chart.Animation = C.Animation;
Chart.Animations = C.Animations;
Chart.animator = C.animator;
Chart.controllers = C.registry.controllers.items;
Chart.DatasetController = C.DatasetController;
Chart.Element = C.Element;
Chart.elements = C.elements;
Chart.Interaction = C.Interaction;
Chart.layouts = C.layouts;
const platforms = {
  _detectPlatform: C._detectPlatform,
  BasePlatform: C.BasePlatform,
  BasicPlatform: C.BasicPlatform,
  DomPlatform: C.DomPlatform,
};
Chart.platforms = platforms;
Chart.Scale = C.Scale;
Chart.Ticks = C.Ticks;
Object.assign(Chart, C.controllers, C.scales, C.elements, C.plugins, platforms);
Chart.Chart = Chart;
globalThis.Chart = Chart;

// ---------------------------------------------------------------------------
// The mode.

const pluginEntries = Object.entries(C.plugins);
const pluginIds = pluginEntries.map(([, p]) => p.id);

function pluginsWhere(keep) {
  const out = {};
  for (const [name, p] of pluginEntries) if (keep(p.id)) out[name] = p;
  return out;
}

function register(mode) {
  const [kind, id] = mode.split(':');
  if ((kind === 'without' || kind === 'only') && !pluginIds.includes(id)) {
    usage(`Unknown plugin id ${id}. The ids: ${pluginIds.join(', ')}.`);
  }
  // registerables = [controllers, elements, plugins, scales] (src/index.ts).
  let plugins;
  if (mode === 'all') plugins = C.plugins;
  else if (mode === 'none') plugins = null;
  else if (kind === 'without') plugins = pluginsWhere((p) => p !== id);
  else if (kind === 'only') plugins = pluginsWhere((p) => p === id);
  else usage(`Unknown mode ${mode}.`);
  if (mode === 'all') Chart.register(...C.registerables);
  else Chart.register(...[C.controllers, C.elements, plugins, C.scales].filter(Boolean));
}
register(opts.mode);

// ---------------------------------------------------------------------------
// chartjs-test-utils: src/utils.js, src/index.js and the matchers.

const serialize = makeSerializer((v) => v instanceof Chart);
const jas = createJasmine({specFile: SPEC, serialize});
const charts = {};

function acquireChart(config, options) {
  const wrapper = document.createElement('div');
  const canvas = document.createElement('canvas');
  config = config || {};
  options = options || {};
  options.canvas = options.canvas || {height: 512, width: 512};
  options.wrapper = options.wrapper || {class: 'chartjs-wrapper'};
  for (const key in options.canvas) {
    if (Object.prototype.hasOwnProperty.call(options.canvas, key)) canvas.setAttribute(key, options.canvas[key]);
  }
  for (const key in options.wrapper) {
    if (Object.prototype.hasOwnProperty.call(options.wrapper, key)) wrapper.setAttribute(key, options.wrapper[key]);
  }
  config.options = config.options || {};
  config.options.animation = config.options.animation === undefined ? false : config.options.animation;
  config.options.responsive = config.options.responsive === undefined ? false : config.options.responsive;
  config.options.locale = config.options.locale || 'en-US';
  if (options.useShadowDOM) throw new Unsupported('acquireChart with useShadowDOM');
  wrapper.appendChild(canvas);
  window.document.body.appendChild(wrapper);
  let chart;
  try {
    if (options.useOffscreenCanvas) throw new Unsupported('acquireChart with useOffscreenCanvas');
    if (options.spriteText) note('acquireChart: spriteText is ignored');
    chart = new Chart(canvas.getContext('2d'), config);
  } catch (e) {
    window.document.body.removeChild(wrapper);
    throw e;
  }
  chart.$test = {persistent: options.persistent, wrapper};
  charts[chart.id] = chart;
  return chart;
}

function releaseChartRaw(chart) {
  chart.destroy();
  const wrapper = (chart.$test || {}).wrapper;
  if (wrapper && wrapper.parentNode) wrapper.parentNode.removeChild(wrapper);
}

function releaseChart(chart) {
  releaseChartRaw(chart);
  delete charts[chart.id];
}

function releaseCharts() {
  Object.keys(charts).forEach((id) => {
    const chart = charts[id];
    if (!(chart.$test || {}).persistent) releaseChartRaw(chart);
  });
}

function waitForResize() {
  throw new Unsupported('waitForResize: the probe has no resize observer');
}

function afterEvent(chart, type, callback) {
  const override = chart._eventHandler;
  chart._eventHandler = function(event) {
    override.call(this, event);
    if (event.type === type || (event.native && event.native.type === type)) {
      chart._eventHandler = override;
      callback();
    }
  };
}

function resolveElementPoint(el) {
  let point = {x: 0, y: 0};
  if (el) {
    if (typeof el.getCenterPoint === 'function') point = el.getCenterPoint();
    else if (el.x !== undefined && el.y !== undefined) point = el;
  }
  return point;
}

/**
 * utils.js triggerMouseEvent. The native event has offsetX and offsetY at
 * the point (a canvas without border, as Chrome gives them); the platform
 * rounds the position as getRelativePosition does.
 */
async function triggerMouseEvent(chart, type, el) {
  const node = chart.canvas;
  const rect = node.getBoundingClientRect();
  const point = resolveElementPoint(el);
  const event = {
    type,
    clientX: rect.left + point.x,
    clientY: rect.top + point.y,
    offsetX: point.x,
    offsetY: point.y,
    cancelable: true,
    bubbles: true,
    view: window,
    target: node,
  };
  const promise = new Promise((resolve) => afterEvent(chart, type, resolve));
  node.dispatchEvent(event);
  await promise;
  return event;
}

const chartjsMatchers = {
  toBeCloseToPixel: () => ({
    compare(actual, expected) {
      let result = false;
      if (!isNaN(actual) && !isNaN(expected)) {
        const diff = Math.abs(actual - expected);
        const A = Math.abs(actual);
        const B = Math.abs(expected);
        result = diff <= (A > B ? A : B) * 0.005 || diff < 2;
      }
      return {pass: result};
    },
  }),
  toBeCloseToPoint: () => {
    const rnd = (v) => Math.round(v * 100) / 100;
    return {compare: (a, e) => ({pass: rnd(a.x) === rnd(e.x) && rnd(a.y) === rnd(e.y)})};
  },
  toEqualOneOf: () => ({
    compare(actual, expecteds) {
      for (let i = 0; i < expecteds.length; i++) if (actual === expecteds[i]) return {pass: true};
      return {pass: false};
    },
  }),
  toBeValidChart: () => ({compare: validChart}),
  toBeChartOfSize: () => ({
    compare(actual, expected) {
      const res = validChart(actual);
      if (!res.pass) return res;
      let message = null;
      const canvas = actual.ctx.canvas;
      const style = getComputedStyle(canvas);
      const pixelRatio = actual.options.devicePixelRatio || window.devicePixelRatio;
      const dh = parseInt(style.height, 10) || 0;
      const dw = parseInt(style.width, 10) || 0;
      const rh = canvas.height;
      const rw = canvas.width;
      const orh = rh / pixelRatio;
      const orw = rw / pixelRatio;
      if (actual.height !== orh) message = `Expected chart height ${actual.height} to be equal to original render height ${orh}`;
      else if (actual.width !== orw) message = `Expected chart width ${actual.width} to be equal to original render width ${orw}`;
      if (dh !== expected.dh) message = `Expected display height ${dh} to be equal to ${expected.dh}`;
      else if (dw !== expected.dw) message = `Expected display width ${dw} to be equal to ${expected.dw}`;
      else if (rh !== expected.rh) message = `Expected render height ${rh} to be equal to ${expected.rh}`;
      else if (rw !== expected.rw) message = `Expected render width ${rw} to be equal to ${expected.rw}`;
      return {message: message || 'ok', pass: !message, recordActual: {dh, dw, rh, rw, height: actual.height, width: actual.width}};
    },
  }),
  toEqualImageData: () => ({
    compare() {
      throw new Unsupported('toEqualImageData needs pixels');
    },
  }),
  toEqualOptions: () => ({compare: (actual, expected) => compareObject(actual, expected)}),
};

function validChart(actual) {
  let message = null;
  if (!(actual instanceof Chart)) message = `Expected ${actual} to be an instance of Chart`;
  else if (Object.prototype.toString.call(actual.canvas) !== '[object HTMLCanvasElement]') {
    message = 'Expected canvas to be an instance of HTMLCanvasElement';
  } else if (Object.prototype.toString.call(actual.ctx) !== '[object CanvasRenderingContext2D]') {
    message = 'Expected context to be an instance of CanvasRenderingContext2D';
  } else if (typeof actual.height !== 'number' || !isFinite(actual.height)) {
    message = 'Expected height to be a strict finite number';
  } else if (typeof actual.width !== 'number' || !isFinite(actual.width)) {
    message = 'Expected width to be a strict finite number';
  }
  return {message: message || 'Expected chart to be valid chart', pass: !message, recordActual: actual instanceof Chart ? '[Chart]' : actual};
}

// src/matchers.options.js.
const isObjectO = (v) => Object.prototype.toString.call(v) === '[object Object]';
const isArrayO = (v) => Object.prototype.toString.call(v) === '[object Array]';
function fmt(val) {
  if (typeof val === 'string') return `"${val}"`;
  if (isArrayO(val) || isObjectO(val)) {
    try {
      return JSON.stringify(val);
    } catch {
      return String(val);
    }
  }
  return `${val}`;
}
function compareArray(actual, expected, path) {
  let ret = true;
  const diff = [];
  if (!isArrayO(actual)) {
    diff.push(`${path}: Expected ${fmt(actual)} to be an array`);
    ret = false;
    actual = {};
  }
  if (actual.length !== expected.length) {
    diff.push(`${path}.length: Expected ${actual.length} to equal ${expected.length}`);
    ret = false;
  }
  for (let i = 0; i < expected.length; i++) {
    const cmp = compareOption(actual[i], expected[i], `${path}[${i}]`);
    if (isObjectO(cmp)) {
      if (!cmp.pass) {
        diff.push(cmp.message);
        ret = false;
      }
    } else if (!cmp) {
      diff.push(`${path}[${i}]: Expected ${fmt(actual[i])} to equal ${fmt(expected[i])}`);
      ret = false;
    }
  }
  return {pass: ret, message: diff.join('\n')};
}
function compareObject(actual, expected, path = '') {
  let ret = true;
  const diff = [];
  if (!isObjectO(actual)) {
    diff.push(`${path}: Expected ${fmt(actual)} to be an object`);
    ret = false;
    actual = {};
  }
  if (path !== '') path = path + '.';
  for (const key in expected) {
    if (typeof key === 'string' && key.startsWith('_')) continue;
    if (!Object.prototype.hasOwnProperty.call(expected, key)) continue;
    const act = actual[key];
    const exp = expected[key];
    const cmp = compareOption(act, exp, `${path}${key}`);
    if (isObjectO(cmp)) {
      if (!cmp.pass) {
        diff.push(cmp.message);
        ret = false;
      }
    } else if (!cmp) {
      diff.push(`${path}${key}: Expected ${fmt(act)} to equal ${fmt(exp)}`);
      ret = false;
    }
  }
  return {pass: ret, message: diff.join('\n')};
}
function compareOption(actual, expected, path) {
  if (isObjectO(expected)) return compareObject(actual, expected, path);
  if (isArrayO(expected)) return compareArray(actual, expected, path);
  return actual === expected;
}

// ---------------------------------------------------------------------------
// The globals of the spec script (test/index.js).

const g = jas.globals;
Object.assign(globalThis, g);
g.jasmine.triggerMouseEvent = triggerMouseEvent;
const fixtureGroups = [];
g.jasmine.fixture = {
  // The image fixtures do not run: the probe has no pixels. The describe
  // body is empty.
  specs: (name) => {
    fixtureGroups.push(name);
    return () => {};
  },
};
Object.assign(window, {
  acquireChart,
  releaseChart,
  afterEvent,
  waitForResize,
  createMockContext: () => new MockContext(),
  moment,
});

g.beforeAll(() => {
  // test/index.js:25-28.
  if (Chart.defaults.plugins.colors) Chart.defaults.plugins.colors.enabled = false;
});
g.beforeEach(() => {
  g.jasmine.addMatchers(chartjsMatchers);
});
g.afterEach(() => {
  releaseCharts();
});

process.on('uncaughtException', (e) => jas.globalError(e));
process.on('unhandledRejection', (e) => jas.globalError(e));

// ---------------------------------------------------------------------------
// Load and run.

let written = false;
process.on('exit', () => {
  if (!written) {
    console.error('run_spec.mjs ended before it wrote its output.');
    process.exitCode = 1;
  }
});

// A spec file can throw at load time, for example when it reads a plugin
// that the mode does not register. Then no case runs, and `loadError` has
// the error.
let loadError = null;
try {
  vm.runInThisContext(readFileSync(SPEC, 'utf8'), {filename: SPEC});
} catch (e) {
  loadError = e instanceof Error ? `${e.name}: ${e.message}` : String(e);
}
const result = loadError ? {cases: [], declarationErrors: [], orphanErrors: []} : await jas.run(opts.filter);

const counts = {};
for (const c of result.cases) counts[c.status] = (counts[c.status] || 0) + 1;
const output = {
  spec: SPEC.slice(REPO.length + 1),
  mode: opts.mode,
  filter: opts.filter,
  plugins: pluginIds,
  node: process.version,
  arch: process.arch,
  counts,
  loadError,
  fixtureGroups,
  declarationErrors: result.declarationErrors,
  orphanErrors: result.orphanErrors,
  cases: result.cases,
};
const text = JSON.stringify(output, null, 1);
if (opts.out) writeFileSync(opts.out, text + '\n');
else writeSync(1, text + '\n');
written = true;
process.exit(0);
