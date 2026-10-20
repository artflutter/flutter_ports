// Original code, not ported from Chart.js: phase 7 probe harness.
//
// Runs run_spec.mjs for one spec file in the modes `all` and `none`, each in
// its own process. For the cases whose result differs, it also runs
// `without:<id>` for each plugin id. It writes one JSON with, for each case:
// the full name, the describe path, the it name, the line, the status in each
// mode, the error text, the recorded values of `all` and `none`, `equal`
// (all vs none) and `changedBy` (the plugin ids whose removal changes the
// result of the case).
//
// Usage:
//   /usr/bin/arch -x86_64 <node-v24.12.0-darwin-x64>/bin/node compare.mjs \
//     <dist/chart.js> <spec file name or path> [--out <json>] \
//     [--filter <substring of the full case name>] [--moment <node_modules>] \
//     [--keep <folder for the JSON of each mode>]

import {spawnSync} from 'node:child_process';
import {mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync, writeSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname, join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const RUN_SPEC = join(HERE, 'run_spec.mjs');

function usage(message) {
  console.error(message);
  console.error(
    'Usage: node compare.mjs <dist/chart.js> <spec> [--out <json>] [--filter <text>] ' +
      '[--moment <node_modules>] [--keep <folder>]',
  );
  process.exit(2);
}

const argv = process.argv.slice(2);
const positional = [];
const opts = {out: null, filter: null, moment: null, keep: null};
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
const [dist, spec] = positional;

const work = opts.keep ? resolve(opts.keep) : mkdtempSync(join(tmpdir(), 'chartjs-probe-'));
mkdirSync(work, {recursive: true});

/** Runs one mode in its own process and returns its JSON. */
function runMode(mode) {
  const out = join(work, `${mode.replace(':', '-')}.json`);
  const args = [RUN_SPEC, dist, spec, '--mode', mode, '--out', out];
  if (opts.filter) args.push('--filter', opts.filter);
  if (opts.moment) args.push('--moment', opts.moment);
  const started = Date.now();
  const r = spawnSync(process.execPath, args, {encoding: 'utf8', maxBuffer: 1 << 28});
  if (r.status !== 0) {
    console.error(r.stdout);
    console.error(r.stderr);
    console.error(`run_spec.mjs --mode ${mode} exited with ${r.status}.`);
    process.exit(1);
  }
  const json = JSON.parse(readFileSync(out, 'utf8'));
  console.error(`${mode}: ${JSON.stringify(json.counts)} (${Date.now() - started} ms)`);
  return json;
}

/** The key of each case: the full name and its occurrence number. */
function keyed(json) {
  const seen = new Map();
  const map = new Map();
  for (const c of json.cases) {
    const n = seen.get(c.fullName) || 0;
    seen.set(c.fullName, n + 1);
    map.set(`${c.fullName}#${n}`, c);
  }
  return map;
}

/** What the comparison compares: the status, the values and the error. */
const signature = (c) => (c ? JSON.stringify({status: c.status, values: c.values, error: c.error}) : 'missing');

const all = runMode('all');
const none = runMode('none');
const allCases = keyed(all);
const noneCases = keyed(none);

const differing = [...allCases.keys()].filter((k) => signature(allCases.get(k)) !== signature(noneCases.get(k)));
const without = {};
const withoutRuns = {};
if (differing.length) {
  for (const id of all.plugins) {
    withoutRuns[id] = runMode(`without:${id}`);
    without[id] = keyed(withoutRuns[id]);
  }
}

/** The status of a case that a run does not have: the file did not load, or the case is not declared. */
const missing = (run) => (run && run.loadError ? 'load-error' : 'missing');

const cases = [];
for (const [key, a] of allCases) {
  const n = noneCases.get(key);
  const equal = signature(a) === signature(n);
  const status = {all: a.status, none: n ? n.status : missing(none)};
  const changedBy = [];
  if (!equal) {
    for (const [id, map] of Object.entries(without)) {
      const w = map.get(key);
      status[`without:${id}`] = w ? w.status : missing(withoutRuns[id]);
      if (signature(w) !== signature(a)) changedBy.push(id);
    }
  }
  cases.push({
    fullName: a.fullName,
    describe: a.describe,
    it: a.it,
    line: a.line,
    status,
    reason: {all: a.reason ?? null, none: n?.reason ?? null},
    error: {all: a.error, none: n ? n.error : none.loadError},
    notes: a.notes,
    values: {all: a.values, none: n ? n.values : null},
    equal,
    changedBy,
  });
}
for (const key of noneCases.keys()) {
  if (!allCases.has(key)) {
    const n = noneCases.get(key);
    cases.push({fullName: n.fullName, describe: n.describe, it: n.it, line: n.line, status: {all: 'missing', none: n.status}, equal: false, changedBy: []});
  }
}

const tally = {};
for (const c of cases) for (const id of c.changedBy) tally[id] = (tally[id] || 0) + 1;
const output = {
  spec: all.spec,
  filter: opts.filter,
  plugins: all.plugins,
  node: all.node,
  arch: all.arch,
  counts: {all: all.counts, none: none.counts},
  equal: cases.filter((c) => c.equal).length,
  different: cases.filter((c) => !c.equal).length,
  changedBy: tally,
  fixtureGroups: all.fixtureGroups,
  loadError: {all: all.loadError, none: none.loadError, ...Object.fromEntries(Object.entries(withoutRuns).map(([id, r]) => [`without:${id}`, r.loadError]))},
  declarationErrors: {all: all.declarationErrors, none: none.declarationErrors},
  orphanErrors: {all: all.orphanErrors, none: none.orphanErrors},
  cases,
};
const text = JSON.stringify(output, null, 1) + '\n';
if (opts.out) writeFileSync(opts.out, text);
else writeSync(1, text);
if (!opts.keep) rmSync(work, {recursive: true, force: true});
