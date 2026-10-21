// Original code, not ported from Chart.js: the image fixtures of the upstream manifest.
//
// A fixture is a test/fixtures/**/*.js or *.json config with its *.png
// reference image, grouped by path without the extension, as the Karma files
// list gives them to chartjs-test-utils 0.4.0 `specsFromFixtures`
// (src/fixture.js:68-92). A `.js` config wins over a `.json` config of the
// same name, as in `specFromFixture` (src/fixture.js:36).
//
// The `.js` configs run in a node:vm context the way `loadConfig` runs them
// (src/fixture.js:22-24), with the real Chart object and stubs for the other
// globals (`document`, `moment`, `window`). A config is pure data when its
// value is a tree of plain objects, arrays, strings, finite numbers other
// than -0, booleans and null. Else the manifest lists the reasons: function,
// undefined, non-finite, negative-zero, hole, object (any other object),
// accessor, global (a value made from a stub, or a string that holds the
// conversion of a stub to a primitive) or cycle.

import {createHash} from 'node:crypto';
import {readdirSync, readFileSync} from 'node:fs';
import vm from 'node:vm';

import {compareStrings} from './json_writer.mjs';
import {runWithStubs} from './sandbox.mjs';

const EXTENSIONS = ['js', 'json', 'png'];

/** The files under `dir`, relative to it, with `/` separators, sorted. */
function filesUnder(dir) {
  const result = [];
  const visit = (relative) => {
    const entries = readdirSync(`${dir}/${relative}`, {withFileTypes: true});
    for (const entry of entries) {
      const path = relative ? `${relative}/${entry.name}` : entry.name;
      if (entry.isDirectory()) visit(path);
      else if (entry.isFile()) result.push(path);
    }
  };
  visit('');
  return result.sort(compareStrings);
}

const sha256 = (bytes) => createHash('sha256').update(bytes).digest('hex');

/**
 * The fixtures of the checkout at `root`. `groups` are the fixture groups of
 * the spec files: `{spec, prefix}`. Returns `{fixtures, orphans, configs}`:
 * the manifest records, the files that do not make a fixture, and the pure
 * configs by path.
 */
export function collectFixtures(root, groups, Chart, registry) {
  const dir = `${root}/test/fixtures`;
  const byName = new Map();
  const orphans = [];
  for (const path of filesUnder(dir)) {
    const match = /^(.+)\.([^./]+)$/.exec(path);
    if (!match || !EXTENSIONS.includes(match[2])) {
      orphans.push({path, reason: 'not a .js, .json or .png file'});
      continue;
    }
    const entry = byName.get(match[1]) ?? {};
    entry[match[2]] = path;
    byName.set(match[1], entry);
  }

  const fixtures = [];
  const configs = {};
  for (const name of [...byName.keys()].sort(compareStrings)) {
    const files = byName.get(name);
    const config = files.js ?? files.json;
    if (config === undefined) {
      orphans.push({path: files.png, reason: 'no config'});
      continue;
    }
    const text = readFileSync(`${dir}/${config}`, 'utf8');
    const record = {
      path: config,
      sha256: sha256(text),
      png: files.png ?? null,
      pngSha256: files.png ? sha256(readFileSync(`${dir}/${files.png}`)) : null,
      specs: [...new Set(groups
        .filter((g) => karmaPattern(g.prefix).test(`/base/test/fixtures/${config}`))
        .map((g) => g.spec))].sort(compareStrings),
    };
    if (files.js && files.json) record.shadows = files.json;
    let value;
    try {
      value = loadConfig(config, text, Chart, registry);
    } catch (error) {
      record.data = false;
      record.impure = ['error'];
      record.error = `${error?.name}: ${error?.message}`;
      fixtures.push(record);
      continue;
    }
    const reasons = impurities(value, registry);
    record.data = reasons.length === 0;
    if (reasons.length) record.impure = reasons;
    for (const key of ['threshold', 'tolerance']) {
      if (typeof value?.[key] === 'number') record[key] = value[key];
    }
    if (record.data) configs[config] = value;
    fixtures.push(record);
  }
  return {fixtures, orphans, configs};
}

/**
 * The regular expression of `specsFromFixtures(prefix)`
 * (chartjs-test-utils src/fixture.js:69). The prefix is a regular expression
 * source, so its dots match any character.
 */
export function karmaPattern(prefix) {
  return new RegExp(`(^/base/test/fixtures/${prefix}.+)\\.(png|json|js)`);
}

/** The value of the config `path` with the source `text`. */
function loadConfig(path, text, Chart, registry) {
  if (path.endsWith('.json')) return JSON.parse(text);
  const {result} = runWithStubs(
    registry,
    () => ({
      Chart,
      window: registry.make('window', {Chart}),
    }),
    (context) => {
      // src/fixture.js:24, with the Function constructor of the context.
      const make = vm.runInContext('Function', context);
      return make(`"use strict"; var module = {};${text}; return module.exports || fixture;`)();
    },
  );
  return result;
}

/**
 * The sorted reasons why `value` is not pure data, or an empty list. See the
 * comment at the top of this file.
 */
export function impurities(value, registry) {
  const reasons = new Set();
  const stack = new Set();
  const visit = (v) => {
    if (registry?.isStub(v)) {
      reasons.add('global');
      return;
    }
    switch (typeof v) {
      case 'string':
        // A string that a stub converted to, as `moment(...).valueOf()`.
        if (registry?.isStubText(v)) reasons.add('global');
        return;
      case 'boolean':
        return;
      case 'number':
        if (!Number.isFinite(v)) reasons.add('non-finite');
        else if (Object.is(v, -0)) reasons.add('negative-zero');
        return;
      case 'undefined':
        reasons.add('undefined');
        return;
      case 'function':
        reasons.add('function');
        return;
      case 'object':
        break;
      default:
        reasons.add('object');
        return;
    }
    if (v === null) return;
    if (stack.has(v)) {
      reasons.add('cycle');
      return;
    }
    const isArray = Array.isArray(v);
    const proto = Object.getPrototypeOf(v);
    const plain = isArray ||
      proto === null ||
      (Object.getPrototypeOf(proto) === null && proto.constructor?.name === 'Object');
    if (!plain) {
      reasons.add('object');
      return;
    }
    stack.add(v);
    if (isArray) {
      for (let i = 0; i < v.length; i++) {
        if (!Object.hasOwn(v, i)) reasons.add('hole');
        else visit(v[i]);
      }
    }
    for (const key of Object.keys(v)) {
      if (isArray && /^(0|[1-9]\d*)$/.test(key)) continue;
      if (isArray) {
        reasons.add('object');
        continue;
      }
      const descriptor = Object.getOwnPropertyDescriptor(v, key);
      if (descriptor.get || descriptor.set) reasons.add('accessor');
      else visit(descriptor.value);
    }
    if (Object.getOwnPropertySymbols(v).length) reasons.add('object');
    stack.delete(v);
  };
  visit(value);
  return [...reasons].sort(compareStrings);
}
