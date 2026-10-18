// Original code, not ported from Chart.js: the spec cases of the upstream manifest.
//
// Each test/specs/*.tests.js file runs in a node:vm context with stub
// describe, it, xit, fit, beforeEach, afterEach, beforeAll and afterAll
// functions. The describe bodies run, as in Jasmine, so the cases that a loop
// makes are found (for example one case for each key of
// Chart.helpers.easingEffects). The it and hook bodies do not run.
//
// For each case the manifest records:
// - describe: the describe names, outermost first; it: the it name.
// - test: the name of the Dart test (porting-flow.md section 1 step 5). A
//   full name (describe names and it name, joined with spaces) that an earlier
//   case of the same file has gets " #2", then " #3".
// - line: the line of the it call in the spec file. When a helper function of
//   the spec calls it, this is the line in the helper.
// - loop: true when the same it call site makes more than one case.
// - kind: "chart" when the it body, or a beforeEach or beforeAll body of its
//   describe chain, calls acquireChart, directly or through a function of the
//   spec file that calls it. Else "non-chart". chartVia names the first body,
//   from the outermost hook to the it body, that calls it.
// - constructsChart: true when one of these bodies calls `new Chart(` or
//   `new window.Chart(` itself. The kind does not change.
// - pending: true for xit, xdescribe and an it without a body (Jasmine skips
//   them).

import {readFileSync} from 'node:fs';
import vm from 'node:vm';

import {matchBracket, tokenize} from './js_tokens.mjs';
import {runWithStubs} from './sandbox.mjs';

const FIXTURE_GROUP = Symbol('fixture group');
const HOOKS = ['beforeAll', 'beforeEach', 'afterEach', 'afterAll'];

/**
 * The names of the functions in `tokens` that call `acquireChart`, directly
 * or through another function of the list. The definitions are `function
 * name(`, `name = function`, `name: function` and `name = (...) =>`.
 */
export function chartHelpers(tokens) {
  const bodies = new Map();
  for (let i = 0; i < tokens.length; i++) {
    const t = tokens[i];
    let name = null;
    let from = -1;
    if (t.type === 'name' && t.value === 'function' && tokens[i + 1]?.type === 'name' &&
        tokens[i + 2]?.value === '(') {
      name = tokens[i + 1].value;
      from = i + 2;
    } else if (t.type === 'name' && (tokens[i + 1]?.value === '=' || tokens[i + 1]?.value === ':') &&
        tokens[i - 1]?.value !== '.') {
      const next = tokens[i + 2];
      if (next?.value === 'function' || next?.value === 'async') {
        name = t.value;
        from = i + 2;
      } else if (next?.value === '(') {
        const close = matchBracket(tokens, i + 2);
        if (tokens[close + 1]?.value === '=>') {
          name = t.value;
          from = close + 1;
        }
      } else if (next?.type === 'name' && tokens[i + 3]?.value === '=>') {
        name = t.value;
        from = i + 3;
      }
    }
    if (name === null) continue;
    const body = functionBody(tokens, from);
    if (body !== null) {
      bodies.set(name, [...(bodies.get(name) ?? []), ...body]);
    }
  }
  const helpers = new Set();
  let changed = true;
  while (changed) {
    changed = false;
    for (const [name, body] of bodies) {
      if (!helpers.has(name) && callsChart(body, helpers)) {
        helpers.add(name);
        changed = true;
      }
    }
  }
  return helpers;
}

/**
 * The tokens of the body of the function whose parameter list or `=>` is at
 * or after `tokens[from]`: the block of the first `{`, or for an arrow
 * function with an expression body, the tokens up to the next `,`, `;` or
 * closing bracket at its depth.
 */
function functionBody(tokens, from) {
  let i = from;
  if (tokens[i]?.value !== '=>') {
    while (i < tokens.length && tokens[i].value !== '(') i++;
    i = matchBracket(tokens, i) + 1;
    if (tokens[i]?.value === '=>') i++;
  } else {
    i++;
  }
  if (i >= tokens.length) return null;
  if (tokens[i].value === '{') {
    return tokens.slice(i, matchBracket(tokens, i) + 1);
  }
  let end = i;
  while (end < tokens.length) {
    const v = tokens[end].value;
    if (tokens[end].type === 'punct' && ['(', '[', '{'].includes(v)) {
      end = matchBracket(tokens, end) + 1;
      continue;
    }
    if (tokens[end].type === 'punct' && [',', ';', ')', ']', '}'].includes(v)) break;
    end++;
  }
  return tokens.slice(i, end);
}

/**
 * Whether `tokens` name `acquireChart`, or call a function of `helpers`
 * that is not a property (`x.name(`).
 */
export function callsChart(tokens, helpers) {
  return tokens.some((t, i) =>
    t.type === 'name' &&
    (t.value === 'acquireChart' ||
      (helpers.has(t.value) && tokens[i + 1]?.value === '(' &&
        tokens[i - 1]?.value !== '.')));
}

/** The source line and column of the innermost frame in `filename`. */
function callSite(filename) {
  const previous = Error.prepareStackTrace;
  const previousLimit = Error.stackTraceLimit;
  Error.prepareStackTrace = (_, frames) => frames;
  Error.stackTraceLimit = 100;
  const holder = {};
  Error.captureStackTrace(holder);
  const frames = holder.stack;
  Error.prepareStackTrace = previous;
  Error.stackTraceLimit = previousLimit;
  const frame = frames.find((f) => f.getFileName() === filename);
  return frame ? {line: frame.getLineNumber(), column: frame.getColumnNumber()} : null;
}

/**
 * The cases, fixture groups and describe-time errors of the spec file `file`
 * (a name in `<root>/test/specs`). `Chart` is the object of `loadChart`.
 */
export function collectSpec(root, file, Chart, registry) {
  const filename = `test/specs/${file}`;
  const source = readFileSync(`${root}/${filename}`, 'utf8');
  const helpers = chartHelpers(tokenize(source));

  const run = (context) => {
    const cases = [];
    const fixtureGroups = [];
    const errors = [];
    // The describe chain: {name, hooks: {beforeEach: [fn...]}, pending}.
    const chain = [{name: null, hooks: {}, pending: false}];
    const path = () => chain.slice(1).map((s) => s.name);

    const describe = (pending) => (name, body) => {
      const site = callSite(filename);
      if (typeof body === 'function' && body[FIXTURE_GROUP] !== undefined) {
        fixtureGroups.push({
          describe: [...path(), String(name)],
          prefix: body[FIXTURE_GROUP],
          line: site?.line ?? null,
        });
        return;
      }
      const suite = {
        name: String(name),
        hooks: {},
        pending: pending || chain[chain.length - 1].pending,
      };
      chain.push(suite);
      try {
        body?.call({});
      } catch (error) {
        const missing = error?.name === 'ReferenceError' &&
          /is not defined$/.test(String(error.message));
        if (missing) throw error;
        errors.push({
          describe: path(),
          line: site?.line ?? null,
          error: `${error?.name}: ${error?.message}`,
        });
      } finally {
        chain.pop();
      }
    };

    const it = (pending) => (name, body) => {
      const site = callSite(filename);
      cases.push({
        describe: path(),
        it: String(name),
        site,
        body,
        hooks: chain.map((s) => s.hooks),
        pending: pending || chain[chain.length - 1].pending || typeof body !== 'function',
      });
    };

    const hook = (kind) => (body) => {
      const hooks = chain[chain.length - 1].hooks;
      (hooks[kind] ??= []).push(body);
    };

    context.describe = describe(false);
    context.fdescribe = describe(false);
    context.xdescribe = describe(true);
    context.it = it(false);
    context.fit = it(false);
    context.xit = it(true);
    for (const kind of HOOKS) context[kind] = hook(kind);

    vm.runInContext(source, context, {filename});
    return {cases, fixtureGroups, errors};
  };

  const {result, stubbed} = runWithStubs(
    registry,
    () => specGlobals(Chart, registry),
    run,
  );
  return {
    file,
    lines: source.split('\n').length - (source.endsWith('\n') ? 1 : 0),
    stubbed,
    fixtureGroups: result.fixtureGroups,
    errors: result.errors,
    cases: finishCases(result.cases, helpers),
  };
}

/** The globals of a spec context. */
function specGlobals(Chart, registry) {
  const chartTools = {
    acquireChart: registry.make('acquireChart'),
    releaseChart: registry.make('releaseChart'),
    afterEvent: registry.make('afterEvent'),
    waitForResize: registry.make('waitForResize'),
    createMockContext: registry.make('createMockContext'),
  };
  const fixture = {
    specs(prefix) {
      const group = () => {};
      group[FIXTURE_GROUP] = String(prefix);
      return group;
    },
  };
  return {
    ...chartTools,
    Chart,
    window: registry.make('window', {Chart, devicePixelRatio: 1, ...chartTools}),
    jasmine: registry.make('jasmine', {fixture}),
  };
}

/** The case records of the manifest, from the raw `cases` of one file. */
function finishCases(cases, helpers) {
  const siteCounts = new Map();
  const siteKey = (c) => (c.site ? `${c.site.line}:${c.site.column}` : null);
  for (const c of cases) {
    const key = siteKey(c);
    if (key !== null) siteCounts.set(key, (siteCounts.get(key) ?? 0) + 1);
  }
  const seen = new Map();
  return cases.map((c) => {
    const full = [...c.describe, c.it].join(' ');
    const count = (seen.get(full) ?? 0) + 1;
    seen.set(full, count);
    const chartVia = chartSource(c, helpers);
    const record = {
      describe: c.describe,
      it: c.it,
      test: count === 1 ? c.it : `${c.it} #${count}`,
      line: c.site?.line ?? null,
      loop: (siteCounts.get(siteKey(c)) ?? 0) > 1,
      kind: chartVia === null ? 'non-chart' : 'chart',
    };
    if (chartVia !== null) record.chartVia = chartVia;
    if (constructsChart(c)) record.constructsChart = true;
    if (c.pending) record.pending = true;
    return record;
  });
}

/**
 * The first body that calls acquireChart for case `c`: "beforeAll" or
 * "beforeEach" of its describe chain (outermost first), or "it". Null when
 * none calls it.
 */
function chartSource(c, helpers) {
  const calls = (fn) =>
    typeof fn === 'function' && callsChart(tokenize(Function.prototype.toString.call(fn)), helpers);
  for (const hooks of c.hooks) {
    if ((hooks.beforeAll ?? []).some(calls)) return 'beforeAll';
    if ((hooks.beforeEach ?? []).some(calls)) return 'beforeEach';
  }
  return calls(c.body) ? 'it' : null;
}

/** Whether `tokens` contain `new Chart(` or `new window.Chart(`. */
export function newChart(tokens) {
  return tokens.some((t, i) => {
    if (t.type !== 'name' || t.value !== 'new') return false;
    const rest = tokens.slice(i + 1, i + 5).map((x) => x.value);
    return (rest[0] === 'Chart' && rest[1] === '(') ||
      (rest[0] === 'window' && rest[1] === '.' && rest[2] === 'Chart' && rest[3] === '(');
  });
}

/** Whether a hook of the describe chain of `c`, or its it body, has `newChart`. */
function constructsChart(c) {
  const bodies = [
    ...c.hooks.flatMap((hooks) => [...(hooks.beforeAll ?? []), ...(hooks.beforeEach ?? [])]),
    c.body,
  ];
  return bodies.some((fn) =>
    typeof fn === 'function' && newChart(tokenize(Function.prototype.toString.call(fn))));
}
