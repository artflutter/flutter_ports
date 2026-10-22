// Original code, not ported from Chart.js: tests of the upstream manifest generator.
//
// Run from packages/flutter_chartjs_port with
// `node --test tool/upstream_manifest/test/*.test.mjs`.

import assert from 'node:assert/strict';
import {mkdirSync, mkdtempSync, rmSync, writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {test} from 'node:test';

import {flatten} from '../src/defaults_values.mjs';
import {impurities, karmaPattern} from '../src/fixtures.mjs';
import {matchBracket, objectKeys, stringValue, tokenize} from '../src/js_tokens.mjs';
import {stringify} from '../src/json_writer.mjs';
import {StubRegistry, undefinedGlobal} from '../src/sandbox.mjs';
import {callsChart, chartHelpers, collectSpec, newChart} from '../src/spec_cases.mjs';

const names = (source) => tokenize(source).filter((t) => t.type === 'name').map((t) => t.value);

test('tokenize drops comments and keeps strings, templates and regular expressions', () => {
  const tokens = tokenize('a /* Math.max */ = `x${Math.min(1)}y` / 2; // Math.abs\nb = /c\\/d/g;');
  assert.deepEqual(names('a /* Math.max */ // Math.abs\n b'), ['a', 'b']);
  assert.deepEqual(
    tokens.map((t) => [t.type, t.value]),
    [
      ['name', 'a'], ['punct', '='], ['template', '`x${'], ['name', 'Math'], ['punct', '.'],
      ['name', 'min'], ['punct', '('], ['number', '1'], ['punct', ')'], ['template', '}y`'],
      ['punct', '/'], ['number', '2'], ['punct', ';'], ['name', 'b'], ['punct', '='],
      ['regex', '/c\\/d/g'], ['punct', ';'],
    ],
  );
  const b = tokens.find((t) => t.value === 'b');
  assert.deepEqual([b.line, b.column], [2, 1]);
});

test('tokenize keeps line numbers after an unterminated string', () => {
  const tokens = tokenize("'open\nnext");
  assert.equal(tokens[1].value, 'next');
  assert.equal(tokens[1].line, 2);
});

test('objectKeys lists the top-level keys of an object literal', () => {
  const tokens = tokenize("x = {a: 1, 'b-c': {d: 2}, e, f() {}, ...g, [h]: 3, get i() {}}");
  const open = tokens.findIndex((t) => t.value === '{');
  assert.deepEqual(objectKeys(tokens, open), ['a', 'b-c', 'e', 'f', '[h]', 'i']);
  assert.equal(tokens[matchBracket(tokens, open)].value, '}');
  assert.equal(stringValue(tokenize("'a\\'b\\n\\u0041'")[0]), "a'b\nA");
});

test('chartHelpers follows calls to functions that acquire a chart', () => {
  const tokens = tokenize(`
    function make() { return window.acquireChart({}); }
    var build = function() { return make(); };
    const viaArrow = () => build();
    function plain() { return 1; }
    obj.method = function() { return acquireChart(); };
  `);
  const helpers = chartHelpers(tokens);
  assert.deepEqual([...helpers].sort(), ['build', 'make', 'viaArrow']);
  assert.equal(callsChart(tokenize('x = viaArrow();'), helpers), true);
  assert.equal(callsChart(tokenize('x = this.make();'), helpers), false);
  assert.equal(callsChart(tokenize('x = plain();'), helpers), false);
  assert.equal(callsChart(tokenize('// acquireChart()\nx = "acquireChart";'), helpers), false);
  assert.equal(newChart(tokenize('new Chart(ctx)')), true);
  assert.equal(newChart(tokenize('new window.Chart(ctx)')), true);
  assert.equal(newChart(tokenize('new Chart.Animation()')), false);
});

test('impurities lists why a value is not JSON data', () => {
  const registry = new StubRegistry();
  assert.deepEqual(impurities({a: [1, 'x', null, true], b: {c: 2}}, registry), []);
  const cyclic = {};
  cyclic.self = cyclic;
  assert.deepEqual(
    impurities({
      f() {},
      u: undefined,
      n: NaN,
      z: -0,
      h: [1, , 3], // eslint-disable-line no-sparse-arrays
      d: new Date(0),
      s: registry.make('moment')('2000'),
      cyclic,
      get g() {
        return 1;
      },
    }, registry),
    ['accessor', 'cycle', 'function', 'global', 'hole', 'negative-zero', 'non-finite', 'object',
      'undefined'],
  );
});

test('impurities finds a string that a stub converted to', () => {
  const registry = new StubRegistry();
  const moment = registry.make('moment');
  // scale.time/autoskip-major.js: `{x: date.valueOf(), y: i}`.
  assert.deepEqual(impurities({x: moment('2000').valueOf(), y: 1}, registry), ['global']);
  assert.deepEqual(impurities({x: `a ${moment()}`}, registry), ['global']);
  assert.deepEqual(impurities({x: '[stub moment()]'}, new StubRegistry()), []);
});

test('karmaPattern matches the prefix as a regular expression, as specsFromFixtures does', () => {
  const pattern = karmaPattern('scale.time');
  assert.equal(pattern.test('/base/test/fixtures/scale.time/a.js'), true);
  assert.equal(pattern.test('/base/test/fixtures/scale.timeseries/a.json'), true);
  assert.equal(pattern.test('/base/test/fixtures/scale.linear/a.js'), false);
  assert.equal(karmaPattern('helpers').test('/base/test/fixtures/plugin.filler/a.js'), false);
});

test('stringify keeps flat records on one line and ends with a newline', () => {
  const text = stringify({
    list: [{name: 'a'.repeat(130), tags: ['x', 'y']}, {name: 'b'}],
    nested: {deep: {deeper: {deepest: 'x'.repeat(120)}}},
  });
  assert.equal(text, [
    '{',
    '  "list": [',
    `    {"name":"${'a'.repeat(130)}","tags":["x","y"]},`,
    '    {"name":"b"}',
    '  ],',
    '  "nested": {',
    '    "deep": {',
    `      "deeper": {"deepest":"${'x'.repeat(120)}"}`,
    '    }',
    '  }',
    '}',
    '',
  ].join('\n'));
});

test('flatten maps key paths to leaves, with routes and sorted keys', () => {
  const root = Object.create(null);
  root.b = {list: ['x', 1], nested: [{c: 1}], empty: {}, none: undefined, nan: NaN};
  root.a = () => 1;
  Object.defineProperty(root.b, 'routed', {enumerable: true, get: () => 'value'});
  const flat = flatten(root);
  assert.deepEqual(Object.keys(flat), [
    'a', 'b.empty', 'b.list', 'b.nan', 'b.nested[0].c', 'b.none', 'b.routed',
  ]);
  assert.match(flat.a.function, /^[0-9a-f]{12}$/);
  assert.deepEqual(flat['b.list'], ['x', 1]);
  assert.deepEqual(flat['b.nan'], {number: 'NaN'});
  assert.deepEqual(flat['b.none'], {undefined: true});
  assert.deepEqual(flat['b.routed'], {route: 'value'});
});

test('undefinedGlobal reads the name of a missing global', () => {
  assert.equal(undefinedGlobal(new ReferenceError('moment is not defined')), 'moment');
  assert.equal(undefinedGlobal(new ReferenceError("Cannot access 'x' before initialization")), null);
  assert.equal(undefinedGlobal(new TypeError('moment is not defined')), null);
});

test('collectSpec records each case of a spec file', (t) => {
  const root = mkdtempSync(join(tmpdir(), 'upstream-manifest-'));
  t.after(() => rmSync(root, {recursive: true, force: true}));
  mkdirSync(join(root, 'test/specs'), {recursive: true});
  const lines = [
    'function makeChart() {', // 1
    '  return window.acquireChart({});',
    '}',
    'var later = moment;',
    "describe('Plain', function() {", // 5
    "  it('one', function() {});",
    "  it('one', function() {});",
    "  it('one', function() {});",
    '  Object.keys(Chart.helpers.easingEffects).forEach(function(key) {',
    "    it('eases ' + key, function() {});", // 10
    '  });',
    "  xit('skipped', function() {});",
    "  it('no body');",
    "  it('uses a helper', function() { makeChart(); });",
    "  describe('Charted', function() {", // 15
    "    it('runs the hook', function() {});",
    '    beforeEach(function() { this.chart = acquireChart({}); });',
    "    describe('Deeper', function() {",
    "      it('inherits the hook', function() {});",
    '    });', // 20
    '  });',
    "  xdescribe('Off', function() {",
    "    it('is pending', function() {});",
    '  });',
    "  describe('auto', jasmine.fixture.specs('plain'));", // 25
    '});',
    "describe('Built', function() {",
    "  beforeAll(function() { this.chart = new Chart('ctx', {}); });",
    "  it('constructs', function() {});",
    '});', // 30
    "describe('Broken', function() {",
    '  null.x;',
    '});',
  ];
  writeFileSync(join(root, 'test/specs/x.tests.js'), `${lines.join('\n')}\n`);
  const Chart = {helpers: {easingEffects: {linear: 1, easeInQuad: 2}}};

  const spec = collectSpec(root, 'x.tests.js', Chart, new StubRegistry());

  const plain = (it, line, extra = {}) =>
    ({describe: ['Plain'], it, test: it, line, loop: false, kind: 'non-chart', ...extra});
  const chart = (describe, it, line, chartVia) =>
    ({describe, it, test: it, line, loop: false, kind: 'chart', chartVia});
  assert.equal(spec.file, 'x.tests.js');
  assert.equal(spec.lines, 33);
  // The describe-time read of `moment` adds a stub and runs the file again.
  assert.deepEqual(spec.stubbed, ['moment']);
  assert.deepEqual(spec.fixtureGroups, [{describe: ['Plain', 'auto'], prefix: 'plain', line: 25}]);
  assert.deepEqual(spec.errors, [{
    describe: ['Broken'],
    line: 31,
    error: "TypeError: Cannot read properties of null (reading 'x')",
  }]);
  assert.deepEqual(spec.cases, [
    plain('one', 6),
    plain('one', 7, {test: 'one #2'}),
    plain('one', 8, {test: 'one #3'}),
    plain('eases linear', 10, {loop: true}),
    plain('eases easeInQuad', 10, {loop: true}),
    plain('skipped', 12, {pending: true}),
    plain('no body', 13, {pending: true}),
    chart(['Plain'], 'uses a helper', 14, 'it'),
    // The beforeEach comes after the it call, and still runs before it.
    chart(['Plain', 'Charted'], 'runs the hook', 16, 'beforeEach'),
    chart(['Plain', 'Charted', 'Deeper'], 'inherits the hook', 19, 'beforeEach'),
    {...plain('is pending', 23, {pending: true}), describe: ['Plain', 'Off']},
    {...plain('constructs', 29, {constructsChart: true}), describe: ['Built']},
  ]);
});
