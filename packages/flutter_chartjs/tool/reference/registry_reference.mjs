// Original code, not ported from Chart.js: core.registry reference generator.
//
// It writes test/port/core/registry_reference.dart, the data of
// test/port/core/core.typedRegistry_test.dart, core.registry_test.dart and
// core.plugins_test.dart: the observations of fixed scenarios of
// TypedRegistry, Registry and PluginService, with the Node.js version, V8
// version and architecture in the header. The scenarios are fixed, so a
// rerun on the same Node.js writes the same file. Nothing in lib/ or test/
// runs this script (porting-flow.md section 4).
//
// The script runs the pinned upstream sources
// third_party/Chart.js/src/core/core.typedRegistry.js, core.registry.js,
// core.plugins.js, core.config.js, core.defaults.js, core.datasetController.js,
// core.scale.js and the element classes of src/elements/ with the type
// stripping of Node.js. A resolve hook maps the upstream `./x.js` imports to
// the `.ts` files, and `@kurkle/color` to
// third_party/kurkle-color/src/index.esm.js. The Dart tests build the same
// scenarios with class values (Chart.js ADR 0020, section 8) and Map
// plugins, and compare their observations with these lines.
//
// Each observation is one line `<label>: <value>`. A value is the JSON of
// JSON.stringify with a replacer: a labelled object is `"<label>"`,
// `undefined` is `"<undefined>"` and another function is `"<fn>"`. An error
// is `TypeError` for a TypeError and `Error: <message>` for an Error. `ok`
// is no error.
//
// The registry scenarios register the namespace `elements` as the bundle of
// Chart.js has it: a frozen object with a null prototype and the export
// names in code unit order (Chart.js ADR 0020, probe 2). The type-stripped
// module namespace of `src/elements/index.js` has the tag `Module`, which
// `isObject` of helpers.core rejects.
//
// Usage, from packages/flutter_chartjs, with an x64 build of Node.js v24.12.0
// (on Apple silicon, the darwin-x64 build runs under Rosetta) and with the
// Dart SDK on the PATH (the script formats the output with `dart format`):
//
//   node tool/reference/registry_reference.mjs
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
const SRC = new URL('Chart.js/src/', THIRD_PARTY);
const TYPED_REGISTRY = new URL('core/core.typedRegistry.js', SRC);
const REGISTRY = new URL('core/core.registry.js', SRC);
const PLUGINS = new URL('core/core.plugins.js', SRC);
const CONFIG = new URL('core/core.config.js', SRC);
const DEFAULTS = new URL('core/core.defaults.js', SRC);
const CONTROLLER = new URL('core/core.datasetController.js', SRC);
const SCALE = new URL('core/core.scale.js', SRC);
const ELEMENT = new URL('core/core.element.ts', SRC);
const ELEMENTS = new URL('elements/index.js', SRC);
const OPTIONS = new URL('helpers/helpers.options.ts', SRC);
const KURKLE = new URL('kurkle-color/src/index.esm.js', THIRD_PARTY);
const OUT = fileURLToPath(
  new URL('../../test/port/core/registry_reference.dart', import.meta.url),
);

for (const url of [
  TYPED_REGISTRY,
  REGISTRY,
  PLUGINS,
  CONFIG,
  DEFAULTS,
  CONTROLLER,
  SCALE,
  ELEMENT,
  ELEMENTS,
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

const {default: TypedRegistry} = await import(TYPED_REGISTRY.href);
const {default: registry, Registry} = await import(REGISTRY.href);
const {default: PluginService} = await import(PLUGINS.href);
const {default: Config} = await import(CONFIG.href);
const {
  default: defaults,
  overrides,
  descriptors,
} = await import(DEFAULTS.href);
const {default: DatasetController} = await import(CONTROLLER.href);
const {default: Scale} = await import(SCALE.href);
const {default: Element} = await import(ELEMENT.href);
const {ArcElement, BarElement, LineElement, PointElement} = await import(
  ELEMENTS.href
);
const {createContext} = await import(OPTIONS.href);

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
      // The holder is the object itself for the root (key ''): a labelled
      // root gives its label.
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
  body((what, value) => lines.push(`${what}: ${value}`));
  scenarios.push({name, lines});
}

/** `key in object` as an observation. */
function has(object, key) {
  return object !== undefined && object !== null && key in object
    ? 'true'
    : 'false';
}

// The stand-in base class of the controllers in the pure test: a class with
// the static `defaults` and no `id`, as DatasetController
// (core.datasetController.js:239-249).
class TBase {
  static defaults = {};
}

// ---------------------------------------------------------------------------
// TypedRegistry (test/port/core/core.typedRegistry_test.dart)

scenario('typedRegistry isForType', (observe) => {
  const elements = new TypedRegistry(Element, 'telements');
  const controllers = new TypedRegistry(TBase, 'tdatasets', true);
  const plugins = new TypedRegistry(Object, 'tplugins');
  class TPointSub extends PointElement {}
  class TPlain {}
  class TSub extends TBase {}
  const values = [
    ['Element', Element],
    ['PointElement', PointElement],
    ['TPointSub', TPointSub],
    ['TPlain', TPlain],
    ['TBase', TBase],
    ['TSub', TSub],
    ['Object', Object],
    ['map', {id: 'x'}],
    ['string', 'str'],
    ['number', 5],
    ['boolean', true],
    ['arrow', () => 1],
    ['null', null],
    ['undefined', undefined],
  ];
  for (const [name, value] of values) {
    const results = [elements, controllers, plugins].map((reg) => {
      try {
        return String(reg.isForType(value));
      } catch (e) {
        return e instanceof TypeError ? 'TypeError' : 'Error';
      }
    });
    observe(name, results.join(' '));
  }
});

scenario('typedRegistry parent first', (observe) => {
  const reg = new TypedRegistry(Element, 'elements');
  class TParent extends Element {}
  TParent.id = 'tparent';
  TParent.defaults = {a: 1, nested: {b: 2}};
  class TChild extends TParent {}
  TChild.id = 'tchild';
  TChild.defaults = {nested: {c: 3}, d: 4};
  label(TParent, 'TParent');
  label(TChild, 'TChild');
  observe('scope', reg.register(TChild));
  observe('items', json(Object.keys(reg.items)));
  observe('tparent', json(reg.get('tparent')));
  observe('tchild', json(reg.get('tchild')));
  observe('defaults.elements.tparent', json(defaults.elements.tparent));
  observe('defaults.elements.tchild', json(defaults.elements.tchild));
  observe('again', reg.register(TChild));
  observe('parent again', reg.register(TParent));
  observe('items after', json(Object.keys(reg.items)));
});

scenario('typedRegistry inherited statics', (observe) => {
  const reg = new TypedRegistry(TBase, 'tdatasets', true);
  class TCtl extends TBase {}
  TCtl.id = 'tctl';
  TCtl.defaults = {x: 1, sub: {y: 2}};
  TCtl.overrides = {o: 1};
  TCtl.descriptors = {_scriptable: false, sub: {_indexable: false}};
  class TPie extends TCtl {}
  TPie.id = 'tpie';
  label(TCtl, 'TCtl');
  label(TPie, 'TPie');
  observe('scope', reg.register(TPie));
  observe('items', json(Object.keys(reg.items)));
  observe('defaults.tdatasets', json(defaults.tdatasets));
  observe('overrides.tctl', json(overrides.tctl));
  observe('overrides.tpie', json(overrides.tpie));
  observe('descriptors.tdatasets', json(descriptors.tdatasets));
  observe(
    'overrides.tpie is TCtl.overrides',
    String(overrides.tpie === TCtl.overrides),
  );
});

scenario('typedRegistry duplicate id', (observe) => {
  const reg = new TypedRegistry(Element, 'elements');
  class TDupA extends Element {}
  TDupA.id = 'tdup';
  TDupA.defaults = {a: 1};
  class TDupB extends Element {}
  TDupB.id = 'tdup';
  TDupB.defaults = {b: 2};
  label(TDupA, 'TDupA');
  label(TDupB, 'TDupB');
  observe('first', reg.register(TDupA));
  observe('second', reg.register(TDupB));
  observe('get', json(reg.get('tdup')));
  observe('defaults.elements.tdup', json(defaults.elements.tdup));
});

scenario('typedRegistry routes and descriptors', (observe) => {
  const reg = new TypedRegistry(Element, 'elements');
  class TRouted extends Element {}
  TRouted.id = 'trouted';
  TRouted.defaults = {own: 1};
  TRouted.defaultRoutes = {
    backgroundColor: 'color',
    'sub.borderColor': 'elements.trouted.own',
  };
  TRouted.descriptors = {_scriptable: true, sub: {_indexable: false}};
  reg.register(TRouted);
  const scope = defaults.elements.trouted;
  observe('keys', json(Object.keys(scope)));
  observe('defaults.elements.trouted', json(scope));
  observe('backgroundColor', json(scope.backgroundColor));
  observe('sub.borderColor', json(scope.sub.borderColor));
  observe('descriptors.elements.trouted', json(descriptors.elements.trouted));
  const color = defaults.color;
  defaults.color = 'red';
  scope.own = 7;
  observe('backgroundColor after', json(scope.backgroundColor));
  observe('sub.borderColor after', json(scope.sub.borderColor));
  defaults.color = color;
});

scenario('typedRegistry routes of other values', (observe) => {
  const reg = new TypedRegistry(Element, 'elements');
  for (const [name, routes] of [
    ['list', ['color']],
    ['string', 'ab'],
    ['number', 5],
    ['not a string', {backgroundColor: 5}],
  ]) {
    class TR extends Element {}
    TR.id = `troutes-${name}`;
    TR.defaults = {};
    TR.defaultRoutes = routes;
    observe(name, error(() => reg.register(TR)));
    observe(`${name} keys`, json(Object.keys(defaults.elements[TR.id])));
  }
});

scenario('typedRegistry existing defaults', (observe) => {
  const reg = new TypedRegistry(Element, 'elements');
  defaults.set('elements.tpre', {z: 0, a: 9});
  const before = defaults.elements.tpre;
  class TPre extends Element {}
  TPre.id = 'tpre';
  TPre.defaults = {a: 1, b: 2};
  reg.register(TPre);
  observe('defaults.elements.tpre', json(defaults.elements.tpre));
  observe('same object', String(defaults.elements.tpre === before));
});

scenario('typedRegistry key order', (observe) => {
  const reg = new TypedRegistry(Object, 'tplugins');
  const plugins = [{id: 'zz'}, {id: '7'}, {id: 'a'}, {id: 10}];
  plugins.forEach((p, i) => label(p, `p${i}`));
  for (const plugin of plugins) {
    observe(`register ${json(plugin.id)}`, reg.register(plugin));
  }
  observe('items', json(Object.keys(reg.items)));
  observe('defaults.tplugins', json(defaults.tplugins));
  observe('get 10', json(reg.get(10)));
  observe('get "10"', json(reg.get('10')));
  observe('get 7', json(reg.get(7)));
  observe('get absent', json(reg.get('absent')));
  observe('get undefined', json(reg.get(undefined)));
});

scenario('typedRegistry register errors', (observe) => {
  const reg = new TypedRegistry(Object, 'tplugins');
  class NoId {}
  for (const [name, value] of [
    ['null', null],
    ['undefined', undefined],
    ['number', 5],
    ['string', 'str'],
    ['empty map', {}],
    ['empty id', {id: ''}],
    ['zero id', {id: 0}],
    ['class without id', NoId],
    ['list', [{id: 'x'}]],
  ]) {
    observe(name, error(() => reg.register(value)));
  }
  observe('items', json(Object.keys(reg.items)));
});

scenario('typedRegistry unregister', (observe) => {
  const reg = new TypedRegistry(TBase, 'tunreg', true);
  class TU extends TBase {}
  TU.id = 'tu';
  TU.defaults = {a: 1};
  TU.overrides = {o: 1};
  reg.register(TU);
  observe('items before', json(Object.keys(reg.items)));
  observe('defaults before', has(defaults.tunreg, 'tu'));
  observe('overrides before', has(overrides, 'tu'));
  observe('unregister', error(() => reg.unregister(TU)));
  observe('items after', json(Object.keys(reg.items)));
  observe('defaults after', has(defaults.tunreg, 'tu'));
  observe('overrides after', has(overrides, 'tu'));
  observe('again', error(() => reg.unregister(TU)));
  observe('not registered', error(() => reg.unregister({id: 'other'})));
  observe('null', error(() => reg.unregister(null)));
  observe('undefined', error(() => reg.unregister(undefined)));
  observe(
    'missing scope',
    error(() => new TypedRegistry(TBase, 'tmissing').unregister({id: 'x'})),
  );
  observe(
    'empty scope',
    error(() => new TypedRegistry(TBase, '').unregister({id: 'x'})),
  );
  defaults.tprim = 5;
  observe(
    'number scope',
    error(() => new TypedRegistry(TBase, 'tprim').unregister({id: 'x'})),
  );
  delete defaults.tprim;
  defaults.tarr = [];
  observe(
    'list scope',
    error(() => new TypedRegistry(TBase, 'tarr').unregister({id: 'x'})),
  );
  delete defaults.tarr;
});

scenario('typedRegistry plugin map', (observe) => {
  const reg = new TypedRegistry(Object, 'tplugins2');
  const plugin = {
    id: 'tmap',
    defaults: {x: 1},
    defaultRoutes: {y: 'color'},
    descriptors: {_scriptable: false},
  };
  observe('scope', reg.register(plugin));
  observe('keys', json(Object.keys(defaults.tplugins2.tmap)));
  observe('defaults.tplugins2.tmap', json(defaults.tplugins2.tmap));
  observe('descriptors.tplugins2', json(descriptors.tplugins2));
});

scenario('typedRegistry parent without defaults', (observe) => {
  const reg = new TypedRegistry(Object, 'tplugins3');
  class TNoDef {}
  TNoDef.id = 'tnodef';
  class TKid extends TNoDef {}
  TKid.id = 'tkid';
  observe('scope', reg.register(TKid));
  observe('items', json(Object.keys(reg.items)));
});

// ---------------------------------------------------------------------------
// Registry (test/port/core/core.registry_test.dart)

scenario('registry routing', (observe) => {
  const reg = new Registry();
  class RCtl extends DatasetController {}
  RCtl.id = 'rctl';
  class RScale extends Scale {}
  RScale.id = 'rscale';
  class RElem extends Element {}
  RElem.id = 'relem';
  class RPlug {}
  RPlug.id = 'rplug';
  const rMap = {id: 'rmap'};
  reg.add(RCtl, RScale, RElem, RPlug, rMap);
  observe('controllers', json(Object.keys(reg.controllers.items)));
  observe('scales', json(Object.keys(reg.scales.items)));
  observe('elements', json(Object.keys(reg.elements.items)));
  observe('plugins', json(Object.keys(reg.plugins.items)));
  observe('overrides.rctl', json(overrides.rctl));
  observe('defaults.datasets.rctl', json(defaults.datasets.rctl));
  observe('defaults.scales.rscale', json(defaults.scales.rscale));
  reg.remove(RCtl, RScale, RElem, RPlug, rMap);
  observe('controllers after', json(Object.keys(reg.controllers.items)));
  observe('plugins after', json(Object.keys(reg.plugins.items)));
  observe('overrides.rctl after', has(overrides, 'rctl'));
});

scenario('registry base classes', (observe) => {
  const reg = new Registry();
  for (const [name, value] of [
    ['DatasetController', DatasetController],
    ['Scale', Scale],
    ['Element', Element],
  ]) {
    const result = error(() => reg.add(value));
    // The message has the source text of the class: only its start is the
    // same in Dart (differences.md js-semantics-class-source).
    const start = `Error: class does not have id: class ${name}`;
    observe(name, result.startsWith(start) ? start : result);
  }
  observe('plugins', json(Object.keys(reg.plugins.items)));
});

scenario('registry loopables', (observe) => {
  const reg = new Registry();
  const ids = ['ra', 'rb', 'rc', 'rd', 're'];
  const [ra, rb, rc, rd, re] = ids.map((id) => label({id}, id));
  reg.add([ra, rb], {k2: rc, 10: rd, k1: re});
  observe('plugins', json(Object.keys(reg.plugins.items)));
  const withId = label({id: 'rwithid', k: label({id: 'rf'}, 'rf')}, 'rwithid');
  reg.add(withId);
  observe('with id', json(Object.keys(reg.plugins.items)));
  class RCtl2 extends DatasetController {}
  RCtl2.id = 'rctl2';
  const rplug2 = label({id: 'rplug2'}, 'rplug2');
  reg.add({a: RCtl2, b: rplug2});
  observe('mixed controllers', json(Object.keys(reg.controllers.items)));
  observe('mixed plugins', json(Object.keys(reg.plugins.items)));
  reg.remove([ra, rb], {k2: rc, 10: rd, k1: re}, withId, {a: RCtl2, b: rplug2});
  observe('controllers after', json(Object.keys(reg.controllers.items)));
  observe('plugins after', json(Object.keys(reg.plugins.items)));
});

scenario('registry items of other values', (observe) => {
  const reg = new Registry();
  for (const [name, value] of [
    ['number', 5],
    ['string', 'ab'],
    ['boolean', true],
    ['empty map', {}],
    ['arrow', () => 1],
    ['null', null],
    ['undefined', undefined],
    ['map of a string', {foo: 'bar'}],
    ['map of a number', {n: 5}],
    ['list of null', [null]],
    ['nested list', [[{id: 'rn1'}]]],
    ['list', [{id: 'rn2'}]],
  ]) {
    observe(name, error(() => reg.add(value)));
  }
  observe('plugins', json(Object.keys(reg.plugins.items)));
  observe('remove null', error(() => reg.remove(null)));
  observe('remove map', error(() => reg.remove({id: 'rnone'})));
});

scenario('registry callbacks', (observe) => {
  const reg = new Registry();
  const log = [];
  function callbacks(target) {
    for (const name of [
      'beforeRegister',
      'afterRegister',
      'beforeUnregister',
      'afterUnregister',
    ]) {
      target[name] = function () {
        const id = this.id;
        log.push(
          `${name} ${labels.get(this)} ${has(reg.plugins.items, id)}` +
            ` ${has(reg.elements.items, id)}`,
        );
      };
    }
  }
  class RCb {}
  RCb.id = 'rcb';
  callbacks(RCb);
  class RCbSub extends RCb {}
  RCbSub.id = 'rcbsub';
  label(RCb, 'RCb');
  label(RCbSub, 'RCbSub');
  const map = label({id: 'rcbmap'}, 'rcbmap');
  callbacks(map);
  class RCbP extends Element {}
  RCbP.id = 'rcbp';
  callbacks(RCbP);
  class RCbC extends RCbP {}
  RCbC.id = 'rcbc';
  label(RCbP, 'RCbP');
  label(RCbC, 'RCbC');
  reg.add(RCbSub, RCb, map, RCbC);
  reg.remove(RCbSub, map, RCbC);
  for (const line of log) observe('log', line);
  observe('elements', json(Object.keys(reg.elements.items)));
  observe('plugins', json(Object.keys(reg.plugins.items)));
  reg.remove(RCb, RCbP);
});

scenario('registry getters', (observe) => {
  const reg = new Registry();
  observe('controller', error(() => reg.getController('nope')));
  observe('element', error(() => reg.getElement(undefined)));
  observe('plugin', error(() => reg.getPlugin(5)));
  observe('scale', error(() => reg.getScale(null)));
  class RExt {}
  RExt.id = 'rext';
  RExt.defaults = {prop: true};
  label(RExt, 'RExt');
  for (const [name, add, get, remove] of [
    ['controller', 'addControllers', 'getController', 'removeControllers'],
    ['element', 'addElements', 'getElement', 'removeElements'],
    ['plugin', 'addPlugins', 'getPlugin', 'removePlugins'],
    ['scale', 'addScales', 'getScale', 'removeScales'],
  ]) {
    reg[add](RExt);
    observe(`${name} get`, json(reg[get]('rext')));
    reg[remove](RExt);
    observe(`${name} after`, error(() => reg[get]('rext')));
  }
});

scenario('registry elements namespace', (observe) => {
  const reg = new Registry();
  // The namespace of the bundle: a frozen object with a null prototype and
  // the export names in code unit order.
  const namespace = (object) =>
    Object.freeze(
      Object.assign(
        Object.create(null),
        Object.fromEntries(
          Object.keys(object)
            .sort()
            .map((key) => [key, object[key]]),
        ),
      ),
    );
  const elements = namespace({
    ArcElement,
    LineElement,
    PointElement,
    BarElement,
  });
  const empty = namespace({});
  observe('keys', json(Object.keys(elements)));
  reg.add(empty, empty, elements, empty);
  observe('elements', json(Object.keys(reg.elements.items)));
  observe('as a list', error(() => reg.add([empty, empty, elements, empty])));
});

scenario('registry singleton', (observe) => {
  observe('is a Registry', String(registry instanceof Registry));
  const plugin = {id: 'rsingle'};
  registry.add(plugin);
  observe('get', String(registry.getPlugin('rsingle') === plugin));
  registry.remove(plugin);
  observe('after', error(() => registry.getPlugin('rsingle')));
});

// ---------------------------------------------------------------------------
// PluginService (test/port/core/core.plugins_test.dart)

/** A fake chart with the configuration [config]. */
function fakeChart(config) {
  const chart = {config: new Config(config)};
  chart.getContext = () =>
    chart.$context ||
    (chart.$context = createContext(null, {chart, type: 'chart'}));
  label(chart, 'chart');
  return chart;
}

/**
 * A plugin Map with the label [name] and the properties [extra], whose hooks
 * [hooks] add the record `{hook, plugin, chart, args, options}` of each call
 * to [log]: the labels of `this` and of the chart, and the JSON of the
 * arguments.
 */
function logPlugin(log, name, hooks, extra = {}) {
  const plugin = {...extra};
  for (const hook of hooks) {
    plugin[hook] = function (chart, args, options) {
      log.push({
        hook,
        plugin: labels.get(this),
        chart: labels.get(chart),
        args: json(args),
        options: json(options),
      });
    };
  }
  return label(plugin, name);
}

/** The record [r] of [logPlugin] as an observation: all fields. */
function full(r) {
  return `${r.hook} ${r.plugin} ${r.chart} ${r.args} ${r.options}`;
}

/** The record [r] of [logPlugin] as an observation: the hook and plugin. */
function short(r) {
  return `${r.hook} ${r.plugin}`;
}

scenario('plugins cancel', (observe) => {
  const results = [undefined, null, 0, true, 1, false, 'x'];
  function run(values, args, before) {
    const called = [];
    const plugins = values.map((value, i) => ({
      hook(chart, a) {
        called.push(i);
        if (before && i === 0) a.cancelable = false;
        return value;
      },
    }));
    const chart = fakeChart({plugins});
    const service = new PluginService();
    service.notify(chart, 'beforeInit');
    const result = service.notify(chart, 'hook', args);
    return `${json(called)} ${String(result)}`;
  }
  observe('cancelable', run(results, {cancelable: true}));
  observe('not cancelable', run(results, {cancelable: false}));
  observe('no args', run(results, undefined));
  observe('truthy cancelable', run([false, 'x'], {cancelable: 1}));
  observe('cleared cancelable', run([false, 'x'], {cancelable: true}, true));
  observe('string false', run(['false', false], {cancelable: true}));
});

scenario('plugins late hook', (observe) => {
  const log = [];
  const plugin = label({id: 'late'}, 'late');
  const chart = fakeChart({plugins: [plugin]});
  const service = new PluginService();
  service.notify(chart, 'beforeInit');
  observe('before', String(service.notify(chart, 'hook')));
  plugin.hook = function () {
    log.push(`first ${labels.get(this)}`);
  };
  observe('first', String(service.notify(chart, 'hook')));
  plugin.hook = function () {
    log.push(`second ${labels.get(this)}`);
    return false;
  };
  observe('second', String(service.notify(chart, 'hook', {cancelable: true})));
  for (const line of log) observe('log', line);
});

scenario('plugins this', (observe) => {
  const log = [];
  const map = label({id: 'pmap'}, 'pmap');
  map.hook = function () {
    log.push(`map ${labels.get(this)}`);
  };
  class PClass {}
  PClass.id = 'pclass';
  PClass.hook = function () {
    log.push(`class ${labels.get(this)}`);
  };
  label(PClass, 'PClass');
  const chart = fakeChart({plugins: [map, PClass]});
  const service = new PluginService();
  service.notify(chart, 'beforeInit');
  service.notify(chart, 'hook');
  for (const line of log) observe('log', line);
});

scenario('plugins hook values', (observe) => {
  const plugins = [5, 'str', {}, null, true].map((hook, i) =>
    label({id: `pv${i}`, hook}, `pv${i}`),
  );
  const chart = fakeChart({plugins});
  const service = new PluginService();
  service.notify(chart, 'beforeInit');
  observe('values', error(() => service.notify(chart, 'hook')));
  class PHook {}
  const classHook = {id: 'pclasshook', hook: PHook};
  const chart2 = fakeChart({plugins: [classHook]});
  const service2 = new PluginService();
  service2.notify(chart2, 'beforeInit');
  observe('class value', error(() => service2.notify(chart2, 'hook')));
});

scenario('plugins order', (observe) => {
  const log = [];
  const registered = ['zz', '7', 'a'].map((id) =>
    logPlugin(log, id, ['hook'], {id}),
  );
  registry.add(...registered);
  const local1 = logPlugin(log, 'local1', ['hook'], {id: 'local1'});
  const local0 = logPlugin(log, 'local0', ['hook'], {id: 'local0'});
  const chart = fakeChart({plugins: [local1, registered[0], local0, local1]});
  const service = new PluginService();
  service.notify(chart, 'beforeInit');
  service.notify(chart, 'hook');
  for (const record of log) observe('log', short(record));
  observe('cache', json(service._cache.map((d) => d.plugin.id)));
  registry.remove(...registered);
});

scenario('plugins lifecycle', (observe) => {
  const log = [];
  const hooks = [
    'install',
    'start',
    'stop',
    'uninstall',
    'beforeInit',
    'afterDestroy',
    'hook',
  ];
  const a = logPlugin(log, 'a', hooks, {id: 'a'});
  const b = logPlugin(log, 'b', hooks, {id: 'b'});
  const chart = fakeChart({plugins: [a, b], options: {plugins: {b: false}}});
  const service = new PluginService();
  const step = (name, body) => {
    const result = body();
    observe(name, String(result));
    for (const record of log.splice(0)) observe('log', full(record));
  };
  step('hook before init', () => service.notify(chart, 'hook'));
  step('beforeInit', () => service.notify(chart, 'beforeInit'));
  step('hook', () => service.notify(chart, 'hook'));
  step('cache', () => json(service._cache.map((d) => d.plugin.id)));
  chart.config.options.plugins = {a: false};
  service.invalidate();
  step('hook after a change', () => service.notify(chart, 'hook'));
  service.invalidate();
  service.invalidate();
  step('hook after a double invalidate', () => service.notify(chart, 'hook'));
  step('afterDestroy', () => service.notify(chart, 'afterDestroy'));
  step('hook after destroy', () => service.notify(chart, 'hook'));
});

scenario('plugins options', (observe) => {
  const log = [];
  const popt = logPlugin(log, 'popt', ['hook'], {
    id: 'popt',
    defaults: {a: 1, nested: {b: 2}},
  });
  registry.add(popt);
  const plocal = logPlugin(log, 'plocal', ['hook'], {
    id: 'plocal',
    defaults: {c: 3},
  });
  const padd = logPlugin(log, 'padd', ['hook'], {
    id: 'padd',
    additionalOptionScopes: ['interaction'],
  });
  const pfn = logPlugin(log, 'pfn', ['hook'], {id: 'pfn'});
  const anon1 = logPlugin(log, 'anon1', ['hook'], {defaults: {x: 1}});
  const anon2 = logPlugin(log, 'anon2', ['hook'], {defaults: {y: 2}});
  const run = (name, pluginOptions) => {
    const chart = fakeChart({
      type: 'tplug',
      plugins: [plocal, padd, pfn, anon1, anon2],
      options: {plugins: pluginOptions},
    });
    const service = new PluginService();
    service.notify(chart, 'beforeInit');
    observe(name, String(service.notify(chart, 'hook')));
    for (const record of log.splice(0)) {
      observe('log', `${record.plugin} ${record.options}`);
    }
  };
  run('object', {
    popt: {a: 5},
    plocal: {d: 4},
    pfn: {f: () => 1},
  });
  run('true', {popt: true, plocal: true});
  run('undefined', undefined);
  run('false', false);
  run('false for one id', {popt: false, padd: false});
  run('null for one id', {plocal: null});
  registry.remove(popt);
});

scenario('plugins filter', (observe) => {
  const log = [];
  const a = logPlugin(log, 'a', ['hook'], {id: 'a'});
  const b = logPlugin(log, 'b', ['hook'], {id: 'b'});
  const chart = fakeChart({plugins: [a, b]});
  const service = new PluginService();
  service.notify(chart, 'beforeInit');
  observe(
    'result',
    String(service.notify(chart, 'hook', {}, (d) => d.plugin.id === 'b')),
  );
  for (const record of log) observe('log', short(record));
});

scenario('plugins config options', (observe) => {
  for (const [name, value] of [
    ['undefined', undefined],
    ['false', false],
    ['null', null],
  ]) {
    const log = [];
    const a = logPlugin(log, 'a', ['hook'], {id: 'a'});
    const chart = fakeChart({plugins: [a]});
    const service = new PluginService();
    service.notify(chart, 'beforeInit');
    chart.config.options = value;
    service.invalidate();
    observe(name, error(() => service.notify(chart, 'hook')));
    observe(`${name} calls`, String(log.length));
  }
});

scenario('plugins local errors', (observe) => {
  for (const [name, value] of [
    ['null', [null]],
    ['undefined', [undefined]],
    ['number', [5]],
  ]) {
    const chart = fakeChart({plugins: value});
    const service = new PluginService();
    observe(name, error(() => service.notify(chart, 'beforeInit')));
  }
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

const out = `// Original code, not ported from Chart.js: core.registry reference data.

// Generated by tool/reference/registry_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// src/core/core.typedRegistry.js, core.registry.js and core.plugins.js at
// the pinned Chart.js. ${scenarios.length} scenarios.

/// The Node.js version that generated the data.
const String registryReferenceNode = '${process.version}';

/// The V8 version that generated the data.
const String registryReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated the data.
const String registryReferenceArch = '${process.arch}';

/// The observations of each scenario, by name, one on each line:
/// \`<label>: <value>\`. A value is a JSON text: a labelled object is
/// \`"<label>"\`, \`undefined\` is \`"<undefined>"\` and another function is
/// \`"<fn>"\`. An error is \`TypeError\` or \`Error: <message>\`, and \`ok\`
/// is no error.
const Map<String, String> registryReference = {
${body}};
`;

writeFileSync(OUT, out);
execFileSync('dart', ['format', OUT], {stdio: 'inherit'});
console.log(`Wrote ${OUT}: ${scenarios.length} scenarios.`);
