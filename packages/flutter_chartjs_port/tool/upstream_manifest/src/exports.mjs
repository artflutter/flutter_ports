// Original code, not ported from Chart.js: the export names of the code entries for the upstream manifest.
//
// The public API test of the port (test/tool/public_api_test.dart, Chart.js
// ADR 0048, sections 5 and 6) compares the public libraries with the names
// of the upstream entries:
// - `index`: the runtime exports of src/index.ts, with the re-exports of
//   the six index modules (:1-6), the four namespaces and `registerables`;
// - `helpers`: the runtime exports of src/helpers/index.ts;
// - `types`: the names that src/types/*.d.ts declare, exported or not, and
//   the names of their `export {...} from` lists.
//
// Each entry is `{count, names}`. The first two lists are the keys of the
// module namespaces, which the loader of chart_loader.mjs gives in code
// unit order. The type-only exports of a TypeScript module are not runtime
// exports. The third list is a scan of the declaration files: a top-level
// `interface`, `type`, `class`, `function`, `const`, `let`, `var`, `enum`,
// `const enum` or `namespace` (after `export`, `declare` or `abstract`),
// and each name of an `export {...}` list (the local name of `default as
// X` is X). The lists are sorted in code unit order, without duplicates.

import {readdirSync, readFileSync} from 'node:fs';
import {pathToFileURL} from 'node:url';

import {compareStrings} from './json_writer.mjs';

/** A top-level declaration of a `.d.ts` file and its name. */
const DECLARATION =
  /^(?:export\s+)?(?:default\s+)?(?:declare\s+)?(?:abstract\s+)?(?:interface|type|class|function|const\s+enum|enum|const|let|var|namespace)\s+([A-Za-z_$][\w$]*)/;

/** An `export {...}` list, also one that spans lines. */
const EXPORT_LIST = /^export\s+(?:type\s+)?\{([^}]*)\}/gm;

/** The names of the `.d.ts` source [text]: see the header. */
export function declarationNames(text) {
  const names = new Set();
  for (const line of text.split('\n')) {
    const match = DECLARATION.exec(line);
    if (match) names.add(match[1]);
  }
  for (const match of text.matchAll(EXPORT_LIST)) {
    for (const part of match[1].split(',')) {
      const name = part.trim().replace(/^type\s+/, '').split(/\s+as\s+/).pop().trim();
      if (name) names.add(name);
    }
  }
  return [...names].sort(compareStrings);
}

/**
 * The export names of the checkout at [root]. The loader hooks of
 * chart_loader.mjs must be registered (loadChart).
 */
export async function exportNames(root) {
  const load = (path) => import(pathToFileURL(`${root}/src/${path}`).href);
  const keys = (namespace) => Object.keys(namespace).sort(compareStrings);
  const types = new Set();
  const typesDir = `${root}/src/types`;
  for (const file of readdirSync(typesDir).filter((f) => f.endsWith('.d.ts')).sort(compareStrings)) {
    for (const name of declarationNames(readFileSync(`${typesDir}/${file}`, 'utf8'))) {
      types.add(name);
    }
  }
  const entry = (names) => ({count: names.length, names});
  return {
    index: entry(keys(await load('index.ts'))),
    helpers: entry(keys(await load('helpers/index.ts'))),
    types: entry([...types].sort(compareStrings)),
  };
}
