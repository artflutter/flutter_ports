// Original code, not ported from Chart.js: the src/ scans of the upstream manifest.
//
// Two token scans of src/**/*.js and src/**/*.ts (not the .d.ts files). The
// scans read a .ts file after Node.js strips its types (the types become
// white space, so lines and columns stay):
// - builtinSites: the calls and reads of JS builtins whose Dart translation
//   needs lib/src/js (Chart.js ADR 0010): Math.*, Number.*, Intl.*,
//   Date.now, the global parseFloat, parseInt, isNaN and isFinite, and the
//   methods .sort( and .toFixed(. A bare name that the file imports or
//   declares is a Chart.js function, not the builtin (core.scale.js imports
//   isFinite from helpers.core), so it is not a site.
// - defaultsSites: the places that register defaults, overrides, descriptors
//   and routes: the static class fields and the plugin object fields
//   defaults, defaultRoutes, overrides and descriptors; the calls
//   defaults.set, defaults.describe, defaults.route and defaults.override;
//   and the Defaults constructor of core.defaults.js. The keys are the top-level
//   keys of an object literal argument or value. A non-literal argument is
//   kept as its source text.

import {readdirSync, readFileSync} from 'node:fs';
import {stripTypeScriptTypes} from 'node:module';

import {compareStrings} from './json_writer.mjs';
import {matchBracket, objectKeys, stringValue, tokenize} from './js_tokens.mjs';

const GLOBAL_FUNCTIONS = new Set(['parseFloat', 'parseInt', 'isNaN', 'isFinite']);
const NAMESPACES = new Set(['Math', 'Number', 'Intl']);
const METHODS = new Set(['sort', 'toFixed']);
const DEFAULTS_FIELDS = new Set(['defaults', 'defaultRoutes', 'overrides', 'descriptors']);
const DEFAULTS_CALLS = new Set(['set', 'describe', 'route', 'override']);

/** The source files of `<root>/src`, relative to `root`, sorted. */
export function sourceFiles(root) {
  const result = [];
  const visit = (relative) => {
    for (const entry of readdirSync(`${root}/${relative}`, {withFileTypes: true})) {
      const path = `${relative}/${entry.name}`;
      if (entry.isDirectory()) visit(path);
      else if (/\.(js|ts)$/.test(entry.name) && !entry.name.endsWith('.d.ts')) {
        result.push(path);
      }
    }
  };
  visit('src');
  return result.sort(compareStrings);
}

/** The tokens of `file`, a path relative to `root`, without TypeScript types. */
function sourceTokens(root, file) {
  const text = readFileSync(`${root}/${file}`, 'utf8');
  return tokenize(file.endsWith('.ts') ? stripTypeScriptTypes(text, {mode: 'strip'}) : text);
}

/** The names that `tokens` import or declare at any level. */
function localNames(tokens) {
  const names = new Set();
  for (let i = 0; i < tokens.length; i++) {
    const t = tokens[i];
    if (t.type !== 'name') continue;
    if (['function', 'const', 'let', 'var', 'class'].includes(t.value) &&
        tokens[i + 1]?.type === 'name') {
      names.add(tokens[i + 1].value);
    }
    if (t.value === 'import' && tokens[i + 1]?.value === '{') {
      const close = matchBracket(tokens, i + 1);
      for (let j = i + 2; j < close; j++) {
        const next = tokens[j + 1]?.value;
        if (tokens[j].type === 'name' && (next === ',' || next === '}')) {
          names.add(tokens[j].value);
        }
      }
    }
  }
  return names;
}

/** The builtin sites of the checkout at `root`, sorted by file and place. */
export function builtinSites(root) {
  const sites = [];
  for (const file of sourceFiles(root)) {
    const tokens = sourceTokens(root, file);
    const local = localNames(tokens);
    tokens.forEach((t, i) => {
      if (t.type !== 'name') return;
      const before = tokens[i - 1];
      const afterDot = before?.type === 'punct' && (before.value === '.' || before.value === '?.');
      const next = tokens[i + 1];
      const member = tokens[i + 2];
      let api = null;
      if (!afterDot && NAMESPACES.has(t.value) && next?.value === '.' && member?.type === 'name') {
        api = `${t.value}.${member.value}`;
      } else if (!afterDot && t.value === 'Date' && next?.value === '.' && member?.value === 'now') {
        api = 'Date.now';
      } else if (!afterDot && GLOBAL_FUNCTIONS.has(t.value) && next?.value === '(' &&
          !local.has(t.value) && before?.value !== 'function') {
        api = t.value;
      } else if (afterDot && METHODS.has(t.value) && next?.value === '(') {
        api = `.${t.value}`;
      }
      if (api !== null) sites.push({file, line: t.line, column: t.column, api});
    });
  }
  return sites;
}

/** The text of `tokens[from..to)`, with one space between tokens. */
function text(tokens, from, to) {
  return tokens.slice(from, to).map((t) => t.value).join(' ')
    .replace(/ ([.,)\]]) ?/g, '$1').replace(/([([]) /g, '$1').replace(/\. /g, '.');
}

/**
 * The arguments of the call whose `(` is `tokens[open]`: each a string, the
 * object keys of a literal `{` (as `{keys: [...]}`), or the source text.
 */
function callArguments(tokens, open) {
  const close = matchBracket(tokens, open);
  const args = [];
  let start = open + 1;
  for (let j = open + 1; j <= close; j++) {
    const t = tokens[j];
    if (j < close && t.type === 'punct' && ['(', '[', '{'].includes(t.value)) {
      j = matchBracket(tokens, j);
      continue;
    }
    if (j === close || (t.type === 'punct' && t.value === ',')) {
      if (j > start) {
        const first = tokens[start];
        if (j === start + 1 && first.type === 'string') args.push(stringValue(first));
        else if (first.value === '{' && matchBracket(tokens, start) === j - 1) {
          args.push({keys: objectKeys(tokens, start)});
        } else args.push(text(tokens, start, j));
      }
      start = j + 1;
    }
  }
  return args;
}

/** The defaults registration sites of the checkout at `root`. */
export function defaultsSites(root) {
  const sites = [];
  for (const file of sourceFiles(root)) {
    const tokens = sourceTokens(root, file);
    // The open brackets around the current token, with the class name of a
    // class body.
    const stack = [];
    let pendingClass = null;
    tokens.forEach((t, i) => {
      if (t.type === 'name' && t.value === 'class' && tokens[i + 1]?.type === 'name') {
        pendingClass = tokens[i + 1].value;
      }
      if (t.type === 'punct' && ['(', '[', '{'].includes(t.value)) {
        stack.push({index: i, className: t.value === '{' ? pendingClass : null});
        if (t.value === '{') pendingClass = null;
      } else if (t.type === 'punct' && [')', ']', '}'].includes(t.value)) {
        stack.pop();
      }
      if (t.type !== 'name') return;
      const next = tokens[i + 1];
      const owner = () => ownerOf(tokens, stack);

      // static defaults = {...} in a class body.
      if (tokens[i - 1]?.value === 'static' && DEFAULTS_FIELDS.has(t.value) &&
          next?.value === '=') {
        sites.push(site(file, t, `static ${t.value}`, owner(), valueOf(tokens, i + 2)));
      }
      // defaults: {...} in an object literal with an id.
      if (DEFAULTS_FIELDS.has(t.value) && next?.value === ':' && tokens[i + 2]?.value === '{' &&
          stack.length && tokens[stack[stack.length - 1].index].value === '{' &&
          ['{', ','].includes(tokens[i - 1]?.value)) {
        sites.push(site(file, t, `field ${t.value}`, owner(), valueOf(tokens, i + 2)));
      }
      // defaults.set(...), defaults.describe(...), ...
      if (t.value === 'defaults' && tokens[i - 1]?.value !== '.' && next?.value === '.' &&
          DEFAULTS_CALLS.has(tokens[i + 2]?.value) && tokens[i + 3]?.value === '(') {
        sites.push({
          file,
          line: t.line,
          kind: `defaults.${tokens[i + 2].value}`,
          args: callArguments(tokens, i + 3),
        });
      }
      // this.key = ... in the constructor of class Defaults.
      if (t.value === 'this' && next?.value === '.' && tokens[i + 2]?.type === 'name' &&
          tokens[i + 3]?.value === '=' && file.endsWith('core.defaults.js') &&
          inConstructorOf(tokens, stack, 'Defaults')) {
        const last = sites[sites.length - 1];
        if (last?.kind === 'Defaults constructor' && last.file === file) {
          last.keys.push(tokens[i + 2].value);
        } else {
          sites.push({file, line: t.line, kind: 'Defaults constructor', keys: [tokens[i + 2].value]});
        }
      }
      // new Defaults({...}, [...]).
      if (t.value === 'Defaults' && tokens[i - 1]?.value === 'new' && next?.value === '(') {
        sites.push({file, line: t.line, kind: 'new Defaults', args: callArguments(tokens, i + 1)});
      }
    });
  }
  return sites;
}

/**
 * Whether the innermost open bracket of `stack` is the body of the
 * constructor of the class `name`, the next one out.
 */
function inConstructorOf(tokens, stack, name) {
  if (stack.length < 2) return false;
  const body = stack[stack.length - 1].index;
  if (tokens[body].value !== '{' || stack[stack.length - 2].className !== name) return false;
  let j = body - 1;
  if (tokens[j]?.value !== ')') return false;
  let depth = 0;
  for (; j >= 0; j--) {
    if (tokens[j].value === ')') depth++;
    else if (tokens[j].value === '(' && --depth === 0) break;
  }
  return tokens[j - 1]?.value === 'constructor';
}

/** A static or field site record. */
function site(file, token, kind, owner, value) {
  return {file, line: token.line, kind, ...owner, ...value};
}

/** `{keys}` for an object literal at `tokens[i]`, else `{value: text}`. */
function valueOf(tokens, i) {
  if (tokens[i]?.value === '{') return {keys: objectKeys(tokens, i)};
  let end = i;
  while (end < tokens.length && ![';', ','].includes(tokens[end].value) &&
      !(tokens[end].type === 'name' && tokens[end].value === 'static')) {
    if (['(', '[', '{'].includes(tokens[end].value) && tokens[end].type === 'punct') {
      end = matchBracket(tokens, end);
    }
    end++;
  }
  return {value: text(tokens, i, end)};
}

/**
 * The owner of a site: `{class}` for the innermost class body, `{id}` for the
 * innermost object literal with an `id: '<string>'` key, or both.
 */
function ownerOf(tokens, stack) {
  const result = {};
  for (let s = stack.length - 1; s >= 0; s--) {
    const open = stack[s].index;
    if (stack[s].className && result.class === undefined) {
      result.class = stack[s].className;
      const id = staticId(tokens, open);
      if (id !== null && result.id === undefined) result.id = id;
    } else if (tokens[open].value === '{' && result.id === undefined) {
      const id = fieldId(tokens, open);
      if (id !== null) result.id = id;
    }
  }
  return result;
}

/** The string of `static id = '<string>'` in the class body at `open`. */
function staticId(tokens, open) {
  const close = matchBracket(tokens, open);
  for (let j = open + 1; j < close - 3; j++) {
    if (tokens[j].value === 'static' && tokens[j + 1].value === 'id' &&
        tokens[j + 2].value === '=' && tokens[j + 3].type === 'string') {
      return stringValue(tokens[j + 3]);
    }
  }
  return null;
}

/** The string of a top-level `id: '<string>'` of the object literal at `open`. */
function fieldId(tokens, open) {
  const close = matchBracket(tokens, open);
  for (let j = open + 1; j < close - 2; j++) {
    const t = tokens[j];
    if (t.type === 'punct' && ['(', '[', '{'].includes(t.value)) {
      j = matchBracket(tokens, j);
      continue;
    }
    if (t.value === 'id' && tokens[j + 1].value === ':' && tokens[j + 2].type === 'string' &&
        ['{', ','].includes(tokens[j - 1].value)) {
      return stringValue(tokens[j + 2]);
    }
  }
  return null;
}
