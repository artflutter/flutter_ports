// Original code, not ported from Chart.js: the upstream manifest generator (porting-flow.md section 4, tool 4).
//
// It reads a Chart.js checkout and writes doc/upstream/manifest.json and
// doc/upstream/fixtures.json. The manifest holds:
// - specs: each test/specs/*.tests.js file with its cases (see
//   src/spec_cases.mjs) and its fixture groups;
// - fixtures: each test/fixtures config with its PNG and their sha256, the
//   spec files that run it, and whether it is pure data (see
//   src/fixtures.mjs). fixtures.json holds the pure-data configs;
// - defaults: the registration sites in src/ and a snapshot of the
//   registered defaults, overrides and descriptors (see src/source_scan.mjs
//   and src/defaults_values.mjs);
// - builtins: the JS builtin sites in src/ (see src/source_scan.mjs).
//
// The output depends only on the checkout: the same checkout gives the same
// bytes on any Node.js 24 and any architecture. Nothing in lib/ or test/
// runs this script, and it writes nothing into the checkout (Chart.js ADR
// 0035). spec_cases.dart (tool 5) reads the manifest.
//
// Usage, from packages/flutter_chartjs_port, with Node.js 22.18 or later:
//
//   node tool/upstream_manifest/upstream_manifest.mjs \
//     --src ../../third_party/Chart.js --out doc/upstream/manifest.json
//
// --fixtures <file> sets the path of the pure-data configs (default:
// fixtures.json next to --out). The script prints a summary of the counts.

import {execFileSync} from 'node:child_process';
import {mkdirSync, readdirSync, readFileSync, writeFileSync} from 'node:fs';
import * as nodeModule from 'node:module';
import {dirname, resolve} from 'node:path';

// The modules of src/ import registerHooks and stripTypeScriptTypes from
// node:module, and a static import of a missing export fails before any code
// runs. So the script checks the Node.js features first, and then loads the
// modules of src/ with dynamic imports.
if (typeof nodeModule.registerHooks !== 'function' ||
    typeof nodeModule.stripTypeScriptTypes !== 'function' ||
    !process.features.typescript) {
  console.error(`upstream_manifest: Node.js ${process.versions.node} cannot strip TypeScript ` +
    'types or register module hooks. Use Node.js 22.18 or later.');
  process.exit(2);
}

const {loadChart} = await import('./src/chart_loader.mjs');
const {flatten} = await import('./src/defaults_values.mjs');
const {collectFixtures, karmaPattern} = await import('./src/fixtures.mjs');
const {compareStrings, stringify} = await import('./src/json_writer.mjs');
const {StubRegistry} = await import('./src/sandbox.mjs');
const {builtinSites, defaultsSites} = await import('./src/source_scan.mjs');
const {collectSpec} = await import('./src/spec_cases.mjs');

// Node.js 24 marks node:module stripTypeScriptTypes as experimental, and melos
// shows each stderr line as an error. The scans call it on purpose, so its
// warning is dropped. Other warnings stay.
const emitWarning = process.emitWarning;
process.emitWarning = (warning, ...rest) => {
  if (String(warning?.message ?? warning).includes('stripTypeScriptTypes')) return;
  emitWarning.call(process, warning, ...rest);
};

/** The version of the manifest format. */
const SCHEMA = 1;

const USAGE = `Usage: node tool/upstream_manifest/upstream_manifest.mjs --src <Chart.js checkout> --out <manifest.json> [--fixtures <fixtures.json>]`;

function parseArgs(argv) {
  const options = {};
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--help' || arg === '-h') return {help: true};
    const match = /^--(src|out|fixtures)(?:=(.*))?$/.exec(arg);
    if (!match) throw new Error(`unknown argument ${arg}`);
    const value = match[2] ?? argv[++i];
    if (value === undefined) throw new Error(`${arg} needs a value`);
    options[match[1]] = value;
  }
  if (!options.src || !options.out) throw new Error('--src and --out are required');
  return options;
}

/** The commit of the checkout, or null when git cannot tell. */
function commitOf(root) {
  try {
    return execFileSync('git', ['-C', root, 'rev-parse', 'HEAD'], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch {
    return null;
  }
}

/** The number of lines of `text`, as `wc -l` counts them for a file. */
const lineCount = (text) => text.split('\n').length - (text.endsWith('\n') ? 1 : 0);

async function main() {
  let options;
  try {
    options = parseArgs(process.argv.slice(2));
  } catch (error) {
    console.error(`upstream_manifest: ${error.message}\n${USAGE}`);
    return 2;
  }
  if (options.help) {
    console.log(USAGE);
    return 0;
  }
  const root = resolve(options.src);
  const out = resolve(options.out);
  const fixturesOut = resolve(options.fixtures ?? `${dirname(out)}/fixtures.json`);
  const pkg = JSON.parse(readFileSync(`${root}/package.json`, 'utf8'));

  const {Chart, defaults, overrides, descriptors} = await loadChart(root);
  // Snapshot the defaults before a describe body can change them.
  const values = {
    defaults: flatten(defaults),
    overrides: flatten(overrides),
    descriptors: flatten(descriptors),
  };

  const registry = new StubRegistry();
  const specFiles = readdirSync(`${root}/test/specs`)
    .filter((name) => name.endsWith('.tests.js'))
    .sort(compareStrings);
  const specs = specFiles.map((file) => collectSpec(root, file, Chart, registry));

  const groups = specs.flatMap((spec) =>
    spec.fixtureGroups.map((group) => ({spec: spec.file, prefix: group.prefix})));
  const {fixtures, orphans, configs} = collectFixtures(root, groups, Chart, registry);
  for (const spec of specs) {
    for (const group of spec.fixtureGroups) {
      const pattern = karmaPattern(group.prefix);
      group.fixtures = fixtures
        .filter((f) => pattern.test(`/base/test/fixtures/${f.path}`)).length;
    }
  }

  const cases = specs.flatMap((spec) => spec.cases);
  const builtins = builtinSites(root);
  const apiCounts = {};
  for (const site of builtins) apiCounts[site.api] = (apiCounts[site.api] ?? 0) + 1;
  const defaultsSiteList = defaultsSites(root);

  const summary = {
    specFiles: specs.length,
    cases: cases.length,
    loopCases: cases.filter((c) => c.loop).length,
    chartCases: cases.filter((c) => c.kind === 'chart').length,
    nonChartCases: cases.filter((c) => c.kind === 'non-chart').length,
    pendingCases: cases.filter((c) => c.pending).length,
    suffixedNames: cases.filter((c) => c.test !== c.it).length,
    describeErrors: specs.reduce((n, s) => n + s.errors.length, 0),
    fixtures: fixtures.length,
    dataFixtures: fixtures.filter((f) => f.data).length,
    fixtureOrphans: orphans.length,
    fixturesWithoutSpec: fixtures.filter((f) => f.specs.length === 0).length,
    defaultsSites: defaultsSiteList.length,
    builtinSites: builtins.length,
  };

  const manifest = {
    schema: SCHEMA,
    source: {
      project: 'Chart.js',
      version: pkg.version,
      commit: commitOf(root),
    },
    summary,
    specs: specs.map((spec) => ({
      file: spec.file,
      lines: spec.lines,
      ...(spec.stubbed.length ? {stubbed: spec.stubbed} : {}),
      ...(spec.errors.length ? {errors: spec.errors} : {}),
      fixtureGroups: spec.fixtureGroups,
      cases: spec.cases,
    })),
    fixtures: {
      items: fixtures,
      orphans,
    },
    defaults: {
      sites: defaultsSiteList,
      values,
    },
    builtins: {
      counts: Object.fromEntries(Object.keys(apiCounts).sort(compareStrings)
        .map((api) => [api, apiCounts[api]])),
      sites: builtins,
    },
  };

  const manifestText = stringify(manifest);
  const fixturesText = `{\n${Object.keys(configs).sort(compareStrings)
    .map((path) => `${JSON.stringify(path)}: ${JSON.stringify(configs[path])}`)
    .join(',\n')}\n}\n`;
  mkdirSync(dirname(out), {recursive: true});
  writeFileSync(out, manifestText);
  mkdirSync(dirname(fixturesOut), {recursive: true});
  writeFileSync(fixturesOut, fixturesText);

  printSummary(manifest, specs, {
    manifest: [out, Buffer.byteLength(manifestText)],
    fixtures: [fixturesOut, Buffer.byteLength(fixturesText)],
  });
  return summary.describeErrors === 0 ? 0 : 1;
}

/** Prints the counts that porting-flow.md names, and the output sizes. */
function printSummary(manifest, specs, files) {
  const s = manifest.summary;
  const nonChart = (filter) => specs.filter((spec) => filter(spec.file))
    .map((spec) => [spec.file, spec.cases.filter((c) => c.kind === 'non-chart').length]);
  const line = (label, rows) => {
    const total = rows.reduce((n, [, count]) => n + count, 0);
    console.log(`${label}: ${total}`);
    console.log(`  ${rows.map(([file, count]) => `${file} ${count}`).join(', ')}`);
  };
  console.log(`Chart.js ${manifest.source.version} (${manifest.source.commit ?? 'no commit'})`);
  console.log(`spec files: ${s.specFiles}, cases: ${s.cases}, loop-generated: ${s.loopCases}, ` +
    `chart: ${s.chartCases}, non-chart: ${s.nonChartCases}, pending: ${s.pendingCases}, ` +
    `suffixed names: ${s.suffixedNames}`);
  const loops = specs.map((spec) => [spec.file, spec.cases.filter((c) => c.loop).length])
    .filter(([, count]) => count > 0);
  line('loop-generated cases', loops);
  line('non-chart cases, helpers.*.tests.js and core.helpers.tests.js',
    nonChart((f) => f.startsWith('helpers.') || f === 'core.helpers.tests.js'));
  line('non-chart cases, helpers.*.tests.js without helpers.canvas and helpers.dom',
    nonChart((f) => f.startsWith('helpers.') &&
      f !== 'helpers.canvas.tests.js' && f !== 'helpers.dom.tests.js'));
  line('non-chart cases, core.defaults.tests.js and core.ticks.tests.js',
    nonChart((f) => f === 'core.defaults.tests.js' || f === 'core.ticks.tests.js'));
  console.log(`fixtures: ${s.fixtures} (pure data: ${s.dataFixtures}, without a spec: ` +
    `${s.fixturesWithoutSpec}, orphan files: ${s.fixtureOrphans})`);
  console.log(`defaults sites: ${s.defaultsSites}, builtin sites: ${s.builtinSites}`);
  for (const spec of specs) {
    for (const error of spec.errors) {
      console.error(`error: test/specs/${spec.file}:${error.line}: ${error.error}`);
    }
  }
  for (const [label, [path, bytes]] of Object.entries(files)) {
    console.log(`wrote ${label}: ${path} (${bytes} bytes)`);
  }
}

process.exitCode = await main();
